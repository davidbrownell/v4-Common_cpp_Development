# ----------------------------------------------------------------------
# |
# |  CodeCoverageExecutor.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-10-03 14:57:26
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
"""Contains the CodeCoverageExecutor object"""

import datetime
import time

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, Dict, Tuple

from Common_Foundation.Streams.DoneManager import DoneManager
from Common_Foundation import SubprocessEx
from Common_Foundation.Types import extensionmethod

from Common_FoundationEx.TesterPlugins.TestExecutorImpl import ExecuteResult


# ----------------------------------------------------------------------
class CodeCoverageExecutor(ABC):
    """Object that is able to execute a command line that extracts code coverage information."""

    # ----------------------------------------------------------------------
    def __init__(
        self,
        default_filename: str,
        display_units: str,
    ):
        self.default_filename               = default_filename
        self.display_units                  = display_units

    # ----------------------------------------------------------------------
    @extensionmethod
    def InstrumentBinary(
        self,
        dm: DoneManager,                    # pylint: disable=unused-argument
        binary_filename: Path,              # pylint: disable=unused-argument
    ) -> None:
        """Decorate the binary prior to execution (if necessary)."""

        # No decoration required by default
        dm.WriteLine("No instrumentation is required.")

    # ----------------------------------------------------------------------
    @extensionmethod
    def StartCoverage(
        self,
        dm: DoneManager,                    # pylint: disable=unused-argument
        coverage_filename: Path,            # pylint: disable=unused-argument
    ) -> None:
        """Initialize coverage (if necessary)."""

        # No initialization required by default
        pass

    # ----------------------------------------------------------------------
    @extensionmethod
    def Execute(
        self,
        command_line: str,
    ) -> Tuple[ExecuteResult, str]:
        """Custom execution"""

        start_time = time.perf_counter()

        result = SubprocessEx.Run(command_line)

        return (
            ExecuteResult(
                result.returncode,
                datetime.timedelta(seconds=time.perf_counter() - start_time),
                None,
                None,
            ),
            result.output,
        )

    # ----------------------------------------------------------------------
    @extensionmethod
    def StopCoverage(
        self,
        dm: DoneManager,                    # pylint; disable=unused-argument
        coverage_filename: Path,            # pylint: disable=unused-argument
    ) -> None:
        """Stop coverage (if necessary)."""

        # Nothing to stop by default
        pass

    # ----------------------------------------------------------------------
    @abstractmethod
    def ExtractCoverageInfo(
        self,
        dm: DoneManager,
        compiler_context: Dict[str, Any],
        coverage_filename: Path,
        binary_filename: Path,
    ) -> Tuple[
        int,                                # Covered
        int,                                # Not Covered
    ]:
        """Returns coverage information"""
        raise Exception("Abstract method")
