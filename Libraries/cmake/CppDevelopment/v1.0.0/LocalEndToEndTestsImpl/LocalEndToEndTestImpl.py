# ----------------------------------------------------------------------
# |
# |  LocalEndToEndTestImpl.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-10-05 13:39:13
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2019-22
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
"""Tests that verify cmake functionality for a compiler"""

import os
import sys
import unittest

from contextlib import contextmanager
from pathlib import Path
from typing import Generator, Tuple

from Common_Foundation.ContextlibEx import ExitStack
from Common_Foundation import PathEx
from Common_Foundation.Shell.All import CurrentShell
from Common_Foundation import SubprocessEx
from Common_Foundation import Types


# ----------------------------------------------------------------------
_this_dir                                   = Path(__file__).parent


# ----------------------------------------------------------------------
class LibSuite(unittest.TestCase):
    # ----------------------------------------------------------------------
    def test_Debug(self):
        self._TestImpl(is_debug_build=True)

    # ----------------------------------------------------------------------
    def test_Release(self):
        self._TestImpl(is_debug_build=False)

    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    def _TestImpl(
        self,
        *,
        is_debug_build: bool,
    ):
        for test_type in ["standard", "build_helper"]:
            with _BuildGenerator(
                _this_dir / test_type / "lib",
                is_debug_build=is_debug_build,
            ) as (temp_dir, result, output):
                self.assertTrue(
                    result == 0,
                    msg=output,
                )

                self.assertTrue(
                    os.path.isfile(os.path.join(temp_dir, "Lib.lib"))
                    or os.path.isfile(os.path.join(temp_dir, "libLib.a")),
                    msg=temp_dir,
                )


# ----------------------------------------------------------------------
class ExeSuite(unittest.TestCase):
    # ----------------------------------------------------------------------
    def test_Debug(self):
        self._TestImpl(is_debug_build=True)

    # ----------------------------------------------------------------------
    def test_Release(self):
        self._TestImpl(is_debug_build=False)

    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    def _TestImpl(
        self,
        *,
        is_debug_build: bool,
    ):
        for test_type in ["standard", "build_helper"]:
            with _BuildGenerator(
                _this_dir / test_type / "exe",
                is_debug_build=is_debug_build,
            ) as (temp_dir, result, output):
                self.assertTrue(
                    result == 0,
                    msg=output,
                )

                found = False

                for potential_exe_name in ["Exe", "Exe.exe"]:
                    exe_name = os.path.join(temp_dir, potential_exe_name)
                    if os.path.isfile(exe_name):
                        found = True

                        result = SubprocessEx.Run('"{}" --success'.format(exe_name))
                        self.assertTrue(
                            result.returncode == 0,
                            msg=result.output,
                        )

                        break

                self.assertTrue(found)


# ----------------------------------------------------------------------
class SharedSuite(unittest.TestCase):
    # ----------------------------------------------------------------------
    def test_Debug(self):
        self._TestImpl(is_debug_build=True)

    # ----------------------------------------------------------------------
    def test_Release(self):
        self._TestImpl(is_debug_build=False)

    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    def _TestImpl(
        self,
        *,
        is_debug_build: bool,
    ):
        for test_type in ["standard", "build_helper"]:
            with _BuildGenerator(
                _this_dir / test_type / "shared",
                is_debug_build=is_debug_build,
            ) as (temp_dir, result, output):
                self.assertTrue(
                    result == 0,
                    msg=output,
                )

                self.assertTrue(
                    os.path.isfile(os.path.join(temp_dir, "Shared.dll"))
                    or os.path.isfile(os.path.join(temp_dir, "libShared.so"))
                    or os.path.isfile(os.path.join(temp_dir, "libShared.dll")),
                    msg=temp_dir,
                )


# ----------------------------------------------------------------------
class SharedExeSuite(unittest.TestCase):
    # ----------------------------------------------------------------------
    def test_Debug(self):
        self._TestImpl(is_debug_build=True)

    # ----------------------------------------------------------------------
    def test_Release(self):
        self._TestImpl(is_debug_build=False)

    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    def _TestImpl(
        self,
        *,
        is_debug_build: bool,
    ):
        for test_type in ["standard", "build_helper"]:
            with _BuildGenerator(
                _this_dir / test_type / "shared_exe",
                is_debug_build=is_debug_build,
            ) as (temp_dir, result, output):
                self.assertTrue(
                    result == 0,
                    msg=output,
                )

                found = False

                for potential_exe_name in ["SharedExe", "SharedExe.exe"]:
                    exe_name = os.path.join(temp_dir, potential_exe_name)
                    if os.path.isfile(exe_name):
                        found = True

                        result = SubprocessEx.Run('"{}" --success'.format(exe_name))

                        self.assertTrue(
                            result.returncode == 0,
                            msg=result.output,
                        )

                        break

                self.assertTrue(found)


# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
@contextmanager
def _BuildGenerator(
    source_dir: Path,
    *,
    is_debug_build: bool,
) -> Generator[Tuple[Path, int, str], None, None]:
    temp_dir = CurrentShell.CreateTempDirectory()

    should_delete_dir = False

    # ----------------------------------------------------------------------
    def OnExit():
        if should_delete_dir:
            PathEx.RemoveTree(temp_dir)

    # ----------------------------------------------------------------------

    with ExitStack(OnExit):
        command_line = 'CMakeCompiler Compile "{source_dir}" "{build_dir}" --cmake-debug-output{debug_build}'.format(
            source_dir=source_dir,
            build_dir=temp_dir,
            debug_build=" --debug-build" if is_debug_build else "",
        )

        result = SubprocessEx.Run(command_line)
        if result.returncode != 0:
            should_delete_dir = False

        yield temp_dir, result.returncode, result.output

        should_delete_dir = True


# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
if __name__ == "__main__":
    try:
        sys.exit(
            unittest.main(
                verbosity=2,
            ),
        )
    except KeyboardInterrupt:
        pass
