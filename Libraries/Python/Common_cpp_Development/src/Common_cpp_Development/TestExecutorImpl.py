# ----------------------------------------------------------------------
# |
# |  TestExecutorImpl.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-10-03 14:52:18
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
"""Contains the TestExecutorImpl object"""

import datetime
import io
import multiprocessing
import textwrap
import threading
import time

from concurrent.futures import ThreadPoolExecutor
from enum import auto, Enum
from pathlib import Path
from typing import Any, Callable, cast, Dict, List, Optional, Tuple

from Common_Foundation.ContextlibEx import ExitStack
from Common_Foundation.Streams.DoneManager import DoneManager, DoneManagerFlags
from Common_Foundation import TextwrapEx
from Common_Foundation.Types import extensionmethod, overridemethod

from Common_FoundationEx.CompilerImpl.CompilerImpl import CompilerImpl
from Common_FoundationEx.InflectEx import inflect
from Common_FoundationEx.TesterPlugins.CodeCoverageValidatorImpl import CodeCoverageFilter
from Common_FoundationEx.TesterPlugins.TestExecutorImpl import CoverageResult, ExecuteResult, TestExecutorImpl as TestExecutorImplBase

from .CodeCoverageExecutor import CodeCoverageExecutor


# ----------------------------------------------------------------------
class TestExecutorImpl(TestExecutorImplBase):
    """Provides additional functionality helpful when extracting C++ code coverage information."""

    # ----------------------------------------------------------------------
    class Steps(Enum):
        Instrumenting                       = auto()
        StartingCoverage                    = auto()
        Testing                             = auto()
        StoppingCoverage                    = auto()
        Extracting                          = auto()
        Finalizing                          = auto()

    # ----------------------------------------------------------------------
    def __init__(
        self,
        name: str,
        description: str,
        code_coverage_executor: CodeCoverageExecutor,
        *,
        is_code_coverage_executor: bool,
    ):
        super(TestExecutorImpl, self).__init__(
            name,
            description,
            is_code_coverage_executor=is_code_coverage_executor,
        )

        self._code_coverage_executor        = code_coverage_executor

    # ----------------------------------------------------------------------
    @overridemethod
    def GetNumSteps(
        self,
        compiler: CompilerImpl,             # pylint: disable=unused-argument
        compiler_context: Dict[str, Any],   # pylint: disable=unused-argument
    ) -> Optional[int]:
        return len(self.__class__.Steps)

    # ----------------------------------------------------------------------
    @overridemethod
    def Execute(
        self,
        dm: DoneManager,                    # Writes to file
        compiler: CompilerImpl,
        context: Dict[str, Any],
        command_line: str,
        on_progress_func: Callable[         # UX status updates
            [
                int,                        # Step (0-based)
                str,                        # Status
            ],
            bool,                           # True to continue, False to terminate
        ],
    ) -> Tuple[
        ExecuteResult,
        str,                                # Execute output
    ]:
        start_time = time.perf_counter()

        assert "input" in context
        assert "output_dir" in context
        assert "output_filenames" in context

        output_filenames = context["output_filenames"]

        # ----------------------------------------------------------------------
        def Impl() -> Tuple[
            int,                            # Result
            Optional[str],                  # Short Desc
            Optional[ExecuteResult],
            Optional[str],                  # Execute output
            Optional[CoverageResult],
        ]:
            with dm.Nested(
                "Instrumenting Binaries...",
                suffix="\n",
            ) as instrument_dm:
                # ----------------------------------------------------------------------
                def Invoke(
                    task_index: int,
                    task_dm: DoneManager,
                ) -> None:
                    self._code_coverage_executor.InstrumentBinary(task_dm, output_filenames[task_index])

                # ----------------------------------------------------------------------

                instrument_dm.result, task_outputs = _ExecuteTasks(
                    [
                        lambda task_dm, task_index=task_index: Invoke(task_index, task_dm)
                        for task_index in range(len(output_filenames))
                    ],
                    lambda value: on_progress_func(self.__class__.Steps.Instrumenting.value, "Instrumenting Binaries ({})...".format(value)),
                )

                for output_filename, task_output in zip(output_filenames, task_outputs):
                    instrument_dm.WriteLine(
                        textwrap.dedent(
                            """\
                            {}
                            {}
                                {}
                            """,
                        ).format(
                            output_filename,
                            "-" * len(str(output_filename)),
                            TextwrapEx.Indent(
                                task_output,
                                4,
                                skip_first_line=True,
                            ),
                        ),
                    )

                if instrument_dm.result != 0:
                    return (
                        instrument_dm.result,
                        "Instrumentation Failed",
                        None,
                        None,
                        None,
                    )

            with dm.Nested(
                "Starting Coverage...",
                suffix="\n",
            ) as start_dm:
                on_progress_func(self.__class__.Steps.StartingCoverage.value, "Starting Coverage...")

                coverage_output_filename = context["output_dir"] / self._code_coverage_executor.default_filename
                start_dm.WriteInfo("Coverage Output Filename: {}\n".format(coverage_output_filename))

                self._code_coverage_executor.StartCoverage(start_dm, coverage_output_filename)

                if start_dm.result != 0:
                    return (
                        start_dm.result,
                        "Starting Coverage Failed",
                        None,
                        None,
                        None,
                    )


            with dm.Nested(
                "Executing Tests...",
                suffix="\n",
            ) as execute_dm:
                on_progress_func(self.__class__.Steps.Testing.value, "Executing Tests...")

                execute_result, execute_output = self._code_coverage_executor.Execute(command_line)

                execute_dm.result = execute_result.result

                if execute_dm.result != 0:
                    return (
                        execute_dm.result,
                        None,
                        execute_result,
                        execute_output,
                        None,
                    )

            with dm.Nested(
                "Stopping Coverage...",
                suffix="\n",
            ) as stop_dm:
                on_progress_func(self.__class__.Steps.StoppingCoverage.value, "Stopping Coverage...")

                self._code_coverage_executor.StopCoverage(stop_dm, coverage_output_filename)

                if stop_dm.result != 0:
                    return (
                        stop_dm.result,
                        "Stopping Coverage Failed",
                        execute_result,
                        execute_output,
                        None,
                    )

            with dm.Nested(
                "Extracting Coverage Results...",
                suffix="\n",
            ) as extract_dm:
                coverage_results: List[
                    Optional[
                        Tuple[
                            int,            # Covered
                            int,            # Not covered
                        ],
                    ],
                ] = [None for _ in range(len(output_filenames))]

                # ----------------------------------------------------------------------
                def Invoke(
                    task_index: int,
                    task_dm: DoneManager,
                ) -> None:
                    covered, uncovered = self._code_coverage_executor.ExtractCoverageInfo(
                        task_dm,
                        context,
                        coverage_output_filename,
                        output_filenames[task_index],
                    )

                    coverage_results[task_index] = (covered, uncovered)

                # ----------------------------------------------------------------------

                extract_dm.result, task_outputs = _ExecuteTasks(
                    [
                        lambda task_dm, task_index=task_index: Invoke(task_index, task_dm)
                        for task_index in range(len(output_filenames))
                    ],
                    lambda value: on_progress_func(self.__class__.Steps.Extracting.value, "Extracting Coverage Results ({})...".format(value)),
                )

                assert all(value for value in coverage_results)
                coverage_results = cast(List[Tuple[int, int]], coverage_results)  # type: ignore

                for output_filename, task_output in zip(output_filenames, task_outputs):
                    extract_dm.WriteLine(
                        textwrap.dedent(
                            """\
                            {}
                            {}
                                {}
                            """,
                        ).format(
                            output_filename,
                            "-" * len(str(output_filename)),
                            TextwrapEx.Indent(
                                task_output,
                                4,
                                skip_first_line=True,
                            ),
                        ),
                    )

                if extract_dm.result != 0:
                    return (
                        extract_dm.result,
                        "Coverage Extraction Failed",
                        execute_result,
                        execute_output,
                        None,
                    )

            with dm.Nested("Finalizing Coverage Results...") as finalize_dm:
                on_progress_func(self.__class__.Steps.Finalizing.value, "Finalizing Results...")

                total_covered = 0
                total_not_covered = 0

                coverage_percentages: Dict[
                    str,
                    Tuple[
                        float,              # Percentage
                        str,                # Short Desc
                    ],
                ] = {}

                for output_filename, (covered, not_covered) in zip(output_filenames, coverage_results):  # type: ignore
                    total_covered += covered
                    total_not_covered += not_covered

                    num_units = covered + not_covered

                    coverage_percentages[output_filename.name] = (
                        0.0 if not num_units else (float(covered) / num_units),
                        "{} of {} {} covered".format(covered, num_units, self._code_coverage_executor.display_units),
                    )

                total_units = total_covered + total_not_covered

                return (
                    0,
                    None,
                    execute_result,
                    execute_output,
                    CoverageResult(
                        finalize_dm.result,
                        datetime.timedelta(seconds=time.perf_counter() - start_time),
                        None,
                        coverage_output_filename,
                        0.0 if not total_units else float(total_covered) / total_units,
                        coverage_percentages,  # type: ignore
                    ),
                )

        # ----------------------------------------------------------------------

        (
            result,
            short_desc,
            execute_result,
            execute_output,
            coverage_result,
        ) = Impl()

        execution_time = datetime.timedelta(seconds=time.perf_counter() - start_time)

        if execute_result is None:
            assert execute_output is None

            execute_result = ExecuteResult(result, execution_time, short_desc, None)
            execute_output = ""
        else:
            assert execute_output is not None

            if coverage_result is None:
                coverage_result = CoverageResult(
                    result,
                    execution_time,
                    short_desc,
                    None,
                    None,
                    None,
                )

            execute_result = ExecuteResult(
                execute_result.result,
                execute_result.execution_time,
                execute_result.short_desc,
                coverage_result,
            )

        return execute_result, execute_output


# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
def _ExecuteTasks(
    funcs: List[Callable[[DoneManager], None]],
    on_progress: Callable[[str], bool],
    single_threaded: bool=False,
) -> Tuple[int, List[str]]:
    with ThreadPoolExecutor(
        1 if single_threaded else min(len(funcs), multiprocessing.cpu_count()),
    ) as executor:
        remaining = len(funcs)
        remaining_lock = threading.Lock()

        # ----------------------------------------------------------------------
        def OnProgress(
            *,
            decrement: bool=True,
        ):
            nonlocal remaining

            with remaining_lock:
                if decrement:
                    assert remaining
                    remaining -= 1

                on_progress("{} remaining".format(inflect.no("item", remaining)))

        # ----------------------------------------------------------------------
        def Impl(
            index: int,
        ) -> Tuple[int, str]:
            with ExitStack(OnProgress):
                sink = io.StringIO()

                with DoneManager.Create(
                    sink,
                    "",
                    display=False,
                    output_flags=DoneManagerFlags.Create(verbose=True),
                ) as dm:
                    funcs[index](dm)

                    result = dm.result

                return result, sink.getvalue()

        # ----------------------------------------------------------------------

        OnProgress(decrement=False)

        futures = [executor.submit(Impl, index) for index in range(len(funcs))]

        result = 0
        output_data: List[str] = []

        for future in futures:
            this_result, this_data = future.result()

            if this_result < 0 and result >= 0:
                result = this_result
            if this_result > 0 and result == 0:
                result = this_result

            output_data.append(this_data)

        return result, output_data
