# ----------------------------------------------------------------------
# |
# |  _install_data.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-10-17 10:20:12
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
"""Contains data used during setup and activation"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict

from Common_Foundation.Shell.All import CurrentShell                        # type: ignore  # pylint: disable=import-error,unused-import

from RepositoryBootstrap import Constants                                   # type: ignore  # pylint: disable=import-error,unused-import

from RepositoryBootstrap.SetupAndActivate.Installers.Installer import Installer                                     # type: ignore  # pylint: disable=import-error,unused-import
from RepositoryBootstrap.SetupAndActivate.Installers.LocalSevenZipInstaller import LocalSevenZipInstaller           # type: ignore  # pylint: disable=import-error,unused-import


# ----------------------------------------------------------------------
@dataclass(frozen=True)
class InstallData(object):
    name: str
    installer: Installer
    prompt_for_interactive: bool            = field(kw_only=True)


# ----------------------------------------------------------------------
_root_dir                                   = Path(__file__).parent


# ----------------------------------------------------------------------
def _CreateInstallData(
    tool_name: str,
    tool_version: str,
) -> InstallData:
    tool_dir = _root_dir / Constants.TOOLS_SUBDIR / tool_name / "v{}".format(tool_version) / CurrentShell.family_name
    assert tool_dir.is_dir(), tool_dir

    potential_tool_dir = tool_dir / CurrentShell.current_architecture
    if potential_tool_dir.is_dir():
        tool_dir = potential_tool_dir

    return InstallData(
        tool_name,
        LocalSevenZipInstaller(
            tool_dir / "install.7z",
            tool_dir,
            tool_version,
        ),
        prompt_for_interactive=False,
    )


# ----------------------------------------------------------------------
CCACHE_VERSIONS: Dict[str, InstallData]     = {
    "4.7.0": _CreateInstallData("ccache", "4.7.0"),
}


# ----------------------------------------------------------------------
CMAKE_VERSIONS: Dict[str, InstallData]      = {
    "3.24.2": _CreateInstallData("cmake", "3.24.2"),
}


# ----------------------------------------------------------------------
NINJA_VERSIONS: Dict[str, InstallData]      = {
    "1.11.1": _CreateInstallData("ninja", "1.11.1"),
}
