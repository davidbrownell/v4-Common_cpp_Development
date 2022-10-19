# ----------------------------------------------------------------------
# |
# |  Catch2TestParser.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-09-24 13:29:24
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
"""Contains the TestParser object"""

import datetime
import re
import time

from pathlib import Path
from typing import Any, Callable, Dict, Generator, List, Optional

from Common_Foundation import RegularExpression
from Common_Foundation.Shell.All import CurrentShell
from Common_Foundation.Types import overridemethod

from Common_FoundationEx.CompilerImpl.CompilerImpl import CompilerImpl
from Common_FoundationEx.TesterPlugins.TestParserImpl import BenchmarkStat, TestParserImpl, TestResult, Units
from Common_FoundationEx import TyperEx


# ----------------------------------------------------------------------
class TestParser(TestParserImpl):
    # ----------------------------------------------------------------------
    # |
    # |  Public Methods
    # |
    # ----------------------------------------------------------------------
    def __init__(self):
        super(TestParser, self).__init__("Catch2", "Parses Catch2 output.")

    # ----------------------------------------------------------------------
    @overridemethod
    def GetCustomCommandLineArgs(self) -> TyperEx.TypeDefinitionsType:
        return {}

    # ----------------------------------------------------------------------
    @overridemethod
    def IsSupportedCompiler(
        self,
        compiler: CompilerImpl,
    ) -> bool:
        # Many compilers are supported
        return True

    # ----------------------------------------------------------------------
    @overridemethod
    def IsSupportedTestItem(
        self,
        item: Path,  # pylint: disable=unused-argument
    ) -> bool:
        if item.is_file():
            items = [item, ]
        elif item.is_dir():
            # Let the cmake test parsers handle things if the folder contains a cmake lists file
            if (item / "CMakeLists.txt").is_file():
                return False

            items = list(item.iterdir())
        else:
            assert False

        include_regex = re.compile(
            r"""(?#
            Start of line                   )^(?#
            Initial whitespace              )\s*(?#
            #include                        )\#\s*include\s*(?#
            < or "                          )[<\"](?#
            catch                           )catch(?#
            )""",
        )

        for item in items:
            if not (item.is_file() and item.suffix == ".cpp"):
                continue

            with item.open() as f:
                for line in f.readlines():
                    if include_regex.match(line):
                        return True

        return False

    # ----------------------------------------------------------------------
    @overridemethod
    def GetNumSteps(
        self,
        command_line: str,
        compiler: CompilerImpl,
        compiler_context: Dict[str, Any],
    ) -> Optional[int]:
        num_tests = sum(1 for _ in self.__class__._EnumTests(compiler_context))

        if self.__class__._ShouldRunBenchmarks(compiler_context):
            num_tests *= 2

        return num_tests

    # ----------------------------------------------------------------------
    @overridemethod
    def CreateInvokeCommandLine(
        self,
        compiler: CompilerImpl,             # pylint: disable=unused-argument
        context: Dict[str, Any],
        *,
        debug_on_error: bool=False,         # pylint: disable=unused-argument
    ) -> str:
        if "output_filename" in context and context["output_filename"]:
            output_filename = context["output_filename"]
        elif "output_filenames" in context and context["output_filenames"]:
            assert len(context["output_filenames"]) == 1, context["output_filenames"]
            output_filename = context["output_filenames"][0]
        else:
            assert False, context

        run_benchmarks = self.__class__._ShouldRunBenchmarks(context)

        commands: List[str] = []
        output_dir: Optional[Path] = None

        for output_filename in self.__class__._EnumTests(context):
            if not commands:
                commands.append('cd "{}"'.format(output_filename.parent))

                output_dir = output_filename.parent / "{}TestParserOutput".format(self.name)
                output_dir.mkdir(parents=True, exist_ok=True)

            assert output_dir is not None

            for log_suffix, flags in [
                ("", "~[benchmark] --durations yes --success --verbosity high"),
                ("-benchmarks", "[benchmark] --allow-running-no-tests"),
            ]:
                if log_suffix and not run_benchmarks:
                    continue

                commands.append(
                    '{} {} > "{}"'.format(
                        output_filename.name,
                        flags,
                        output_dir / "{}{}.log".format(output_filename.name, log_suffix),
                    ),
                )

        return " && ".join(commands)

    # ----------------------------------------------------------------------
    @overridemethod
    def Parse(
        self,
        compiler: CompilerImpl,
        compiler_context: Dict[str, Any],
        test_data: str,
        on_progress_func: Callable[
            [
                int,                        # Step (0-based)
                str,                        # Status
            ],
            bool,                           # True to continue, False to terminate
        ],
    ) -> TestResult:
        run_benchmarks = self.__class__._ShouldRunBenchmarks(compiler_context)

        start_time = time.perf_counter()

        result = 0
        short_desc: Optional[str] = None
        benchmarks: Dict[str, List[BenchmarkStat]] = {}

        for index, test_filename in enumerate(self.__class__._EnumTests(compiler_context)):
            for type_offset, (log_suffix, desc) in enumerate(
                [
                    ("", ""),
                    ("-benchmarks", " (benchmarks)"),
                ],
            ):
                if log_suffix and not run_benchmarks:
                    continue

                on_progress_func(
                    index * (2 if run_benchmarks else 1) + type_offset,
                    "Processing '{}'{}".format(test_filename.name, desc),
                )

                log_filename = test_filename.parent / "{}TestParserOutput".format(self.name) / "{}{}.log".format(test_filename.name, log_suffix)
                if not log_filename.is_file():
                    if result >= 0:
                        result = -1
                    if not short_desc:
                        short_desc = "'{}' does not exist".format(log_filename.name)

                    continue

                with log_filename.open() as f:
                    test_data = f.read()

                if (
                    "All tests passed" not in test_data
                    and "No tests ran" not in test_data
                ):
                    if result >= 0:
                        result = -1
                    if not short_desc:
                        short_desc = "Failures in '{}'".format(test_filename.name)

                    continue

                # Extract the benchmarks
                for k, v in (ExtractBenchmarkOutput(test_data) or {}).items():
                    assert k not in benchmarks, k
                    benchmarks[k] = v

        return TestResult(
            result,
            datetime.timedelta(seconds=time.perf_counter() - start_time),
            short_desc,
            None,
            benchmarks or None,
        )

    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    @staticmethod
    def _ShouldRunBenchmarks(
        context: Dict[str, Any],
    ) -> bool:
        return not context.get("debug_build", False)

    # ----------------------------------------------------------------------
    @staticmethod
    def _EnumTests(
        context: Dict[str, Any],
    ) -> Generator[Path, None, None]:
        if "output_filename" in context and context["output_filename"]:
            output_filename = context["output_filename"]
        elif "output_filenames" in context and context["output_filenames"]:
            assert len(context["output_filenames"]) == 1, context["output_filenames"]
            output_filename = context["output_filenames"][0]
        else:
            assert False, context

        output_dir = output_filename.parent

        if CurrentShell.executable_extensions is None:
            is_binary_func = lambda item: not item.suffix
        else:
            is_binary_func = lambda item: item.suffix in CurrentShell.executable_extensions

        for item in output_dir.iterdir():
            if item.is_file() and is_binary_func(item):
                yield item


# ----------------------------------------------------------------------
def ExtractBenchmarkOutput(
    test_data: str,
) -> Optional[Dict[str, List[BenchmarkStat]]]:
    benchmarks: Dict[str, List[BenchmarkStat]] = {}

    for match in _benchmark_output_regex.finditer(test_data):
        name = match.group("name")
        catch_version = "Catch v{}".format(match.group("catch_version"))
        content = match.group("content")

        these_benchmarks: List[BenchmarkStat] = []

        dest_units = Units.Nanoseconds

        for match in RegularExpression.Generate(
            _benchmark_regex,
            content,
            leading_delimiter=True,
        ):
            assert isinstance(match, dict)

            # If there is only one match, it means that nothing was found
            if len(match) == 1:
                assert None in match
                continue

            test_line = match["test_line_windows"]
            if test_line is None:
                test_line = match["test_line_linux"]
                if test_line is None:
                    assert False

            for stats in _benchmark_stats_regex.finditer(match[None]):
                these_benchmarks.append(
                    BenchmarkStat(
                        "{} - {}".format(match["test_name"], stats.group("name")),
                        Path(match["test_filename"]),
                        int(test_line),
                        catch_version,
                        BenchmarkStat.ConvertTime(
                            float(stats.group("low_mean")),
                            Units(stats.group("low_mean_units")),
                            dest_units,
                        ),
                        BenchmarkStat.ConvertTime(
                            float(stats.group("high_mean")),
                            Units(stats.group("high_mean_units")),
                            dest_units,
                        ),
                        BenchmarkStat.ConvertTime(
                            float(stats.group("mean")),
                            Units(stats.group("mean_units")),
                            dest_units,
                        ),
                        BenchmarkStat.ConvertTime(
                            float(stats.group("deviation")),
                            Units(stats.group("deviation_units")),
                            dest_units,
                        ),
                        int(stats.group("samples")),
                        dest_units,
                        int(stats.group("iterations")),
                    ),
                )

            if these_benchmarks:
                benchmarks[name] = these_benchmarks

    return benchmarks or None


# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
_benchmark_output_regex                     = re.compile(
    r"""(?#
    Header                                  )~~~~+\r?\n(?#
    Name                                    )(?P<name>[^\n]+)(?#
    text                                    ) is a Catch2 v(?#
    Version                                 )(?P<catch_version>[\d\.]+)(?#
    text                                    ) host application.\s*(?#
    Content                                 )(?P<content>.+?)(?#
    Footer                                  )====+\r?\n(?#
    )""",
    re.DOTALL | re.MULTILINE,
)

_benchmark_regex                            = re.compile(
    r"""(?#
    Header 1                                )----+\r?\n(?#
    Test Name                               )(?P<test_name>[^\r\n]+)\r?\n(?#
    Header 2                                )----+\r?\n(?#
    Test Filename                           )(?P<test_filename>[^\r\n]+)(?#
    Test Line                               )(?:(?#
        Windows                             )\((?P<test_line_windows>\d+)\)(?#
                                            )|(?#
        Linux                               ):(?P<test_line_linux>\d+)(?#
                                            ))\r?\n(?#
    Header 3                                )\.\.\.\.+\r?\n(?#
    Benchmark Header                        )\s+benchmark name\s+samples.+?(?#
    Header 4                                )----+\r?\n(?#
    )""",
    re.DOTALL | re.MULTILINE,
)

_benchmark_stats_regex                      = re.compile(
    r"""(?#
    Name                                    )(?P<name>[^\n]+?)(?#
    Samples                                 )\s+(?P<samples>\d+)(?#
    Iterations                              )\s+(?P<iterations>\d+)(?#
    Estimated                               )\s+(?P<estimated>[\d\.]+) (?P<estimated_units>\S+)(?#
    newline                                 )\s*\r?\n(?#
    Mean                                    )\s+(?P<mean>[\d\.]+) (?P<mean_units>\S+)(?#
    Low Mean                                )\s+(?P<low_mean>[\d\.]+) (?P<low_mean_units>\S+)(?#
    High Mean                               )\s+(?P<high_mean>[\d\.]+) (?P<high_mean_units>\S+)(?#
    newline                                 )\s*\r?\n(?#
    Deviation                               )\s+(?P<deviation>[\d\.]+) (?P<deviation_units>\S+)(?#
    Low Deviation                           )\s+(?P<low_deviation>[\d\.]+) (?P<low_deviation_units>\S+)(?#
    High Deviation                          )\s+(?P<high_deviation>[\d\.]+) (?P<high_deviation_units>\S+)(?#
    newline                                 )\s*\r?\n(?#
    )""",
    re.DOTALL | re.MULTILINE,
)
