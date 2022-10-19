# ----------------------------------------------------------------------
# |
# |  CMakeTestParser.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-09-24 13:29:01
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
import os
import re
import sys
import time

from enum import auto, Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

from Common_Foundation.ContextlibEx import ExitStack
from Common_Foundation import PathEx
from Common_Foundation.Types import overridemethod

from Common_FoundationEx.CompilerImpl.CompilerImpl import CompilerImpl
from Common_FoundationEx.TesterPlugins.TestParserImpl import BenchmarkStat, TestParserImpl, TestResult
from Common_FoundationEx import TyperEx


# ----------------------------------------------------------------------
sys.path.insert(0, str(Path(__file__).parent))
with ExitStack(lambda: sys.path.pop(0)):
    assert os.path.isdir(sys.path[0]), sys.path[0]

    from Catch2TestParser import ExtractBenchmarkOutput as ExtractCatch2BenchmarkOutput


# ----------------------------------------------------------------------
class TestParser(TestParserImpl):
    # ----------------------------------------------------------------------
    # |
    # |  Public Types
    # |
    # ----------------------------------------------------------------------
    class Steps(Enum):
        Scrubbing                           = 0
        ExtractingBenchmarks                = auto()

    # ----------------------------------------------------------------------
    # |
    # |  Public Methods
    # |
    # ----------------------------------------------------------------------
    def __init__(self):
        super(TestParser, self).__init__("CMake", "Parses CMake's CTest output.")

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
        return compiler.name == "CMake"

    # ----------------------------------------------------------------------
    @overridemethod
    def IsSupportedTestItem(
        self,
        item: Path,
    ) -> bool:
        return (
            item.is_dir()
            and item.name.lower().endswith("tests")
            and (item / "CMakeLists.txt").is_file()
        )

    # ----------------------------------------------------------------------
    @overridemethod
    def GetNumSteps(
        self,
        command_line: str,
        compiler: CompilerImpl,
        compiler_context: Dict[str, Any],
    ) -> Optional[int]:
        return len(self.__class__.Steps)

    # ----------------------------------------------------------------------
    @overridemethod
    def CreateInvokeCommandLine(
        self,
        compiler: CompilerImpl,             # pylint: disable=unused-argument
        context: Dict[str, Any],
        *,
        debug_on_error: bool=False,         # pylint: disable=unused-argument
    ) -> str:
        is_profile_or_benchmark = (
            context.get("is_profile", False)
            or context.get("profile_build", False)
            or context.get("is_benchmark", False)
            or context.get("benchmark", False)
        )

        return 'cd "{output_dir}" && ctest --verbose{parallel}'.format(
            output_dir=context["output_dir"],
            parallel="" if is_profile_or_benchmark else " --parallel",
        )

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
        start_time = time.perf_counter()

        result: Optional[int] = None
        short_desc: Optional[str] = None
        benchmarks: Optional[Dict[str, List[BenchmarkStat]]] = None

        if "100% tests passed" not in test_data:
            result = -1
        else:
            on_progress_func(self.__class__.Steps.Scrubbing.value, "Scrubbing output")

            # ctest will append an index before each line of the test output; remove that if it exists.
            line_regex = re.compile(r"^\d+: (?P<content>.*)")

            lines = test_data.split("\n")
            for index, line in enumerate(lines):
                match = line_regex.match(line)
                if not match:
                    continue

                lines[index] = match.group("content")

            scrubbed_test_data = "\n".join(lines)

            # ctest can wrap many individual test frameworks; attempt to extract benchmark data from
            # well-known frameworks.
            on_progress_func(self.__class__.Steps.ExtractingBenchmarks.value, "Extracting Benchmarks")

            for extract_func in [
                ExtractCatch2BenchmarkOutput,
            ]:
                benchmarks = extract_func(scrubbed_test_data)
                if benchmarks is not None:
                    break

            result = 0

        assert result is not None

        return TestResult(
            result,
            datetime.timedelta(seconds=time.perf_counter() - start_time),
            short_desc,
            None,
            benchmarks,
        )

    # ----------------------------------------------------------------------
    @overridemethod
    def RemoveTemporaryArtifacts(
        self,
        context: Dict[str, Any],
    ) -> None:
        for potential_dir in ["Testing"]:
            potential_dir = context["output_dir"] / potential_dir
            PathEx.RemoveTree(potential_dir)
