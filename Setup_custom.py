# ----------------------------------------------------------------------
# |
# |  Setup_custom.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-09-16 13:41:13
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
# pylint: disable=missing-module-docstring

import os
import sys
import uuid

from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

from semantic_version import Version as SemVer          # pylint: disable=unused-import

from Common_Foundation import PathEx                                        # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation.Shell.All import CurrentShell                        # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation.Shell import Commands                                # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation.Streams.DoneManager import DoneManager               # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation import SubprocessEx                                  # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation import Types                                         # type: ignore  # pylint: disable=import-error,unused-import

from RepositoryBootstrap import Configuration                                                               # type: ignore  # pylint: disable=import-error,unused-import
from RepositoryBootstrap import Constants                                                                   # type: ignore  # pylint: disable=import-error,unused-import
from RepositoryBootstrap.SetupAndActivate.Installers.LocalSevenZipInstaller import LocalSevenZipInstaller   # type: ignore  # pylint: disable=import-error,unused-import


# ----------------------------------------------------------------------
from _install_data import CCACHE_VERSIONS, CMAKE_VERSIONS, NINJA_VERSIONS
del sys.modules["_install_data"]


# ----------------------------------------------------------------------
# Uncomment the decorator below to make this repository a mixin repository.
# Mixin repositories can not be activated on their own and cannot have tool
# or version specifications. Mixin repositories are valuable because they
# can provide scripts or tools that augment other repositories when activated.
#
# @Configuration.MixinRepository
def GetConfigurations() -> Union[
    Configuration.Configuration,
    Dict[
        str,                                # configuration name
        Configuration.Configuration,
    ],
]:
    if CurrentShell.family_name == "Windows":
        architectures = ["x64", "x86"]
    else:
        architectures = [CurrentShell.current_architecture, ]

    d = {}

    for architecture in architectures:
        d[architecture] = Configuration.Configuration(
        "Tools targeting '{}' for development.".format(architecture),
        [
            Configuration.Dependency(
                uuid.UUID("DD6FCD30-B043-4058-B0D5-A6C8BC0374F4"),
                "Common_Foundation",
                "python310",
                "https://github.com/davidbrownell/v4-Common_Foundation.git",
            ),
        ],
        Configuration.VersionSpecs(
            [],                             # tools
            {},                             # libraries
        ),
    )

    return d


# ----------------------------------------------------------------------
# Note that it is safe to remove this function if it will never be used.
def GetCustomActions(
    # Note that it is safe to remove any parameters that are not used
    dm: DoneManager,                                    # pylint: disable=unused-argument
    explicit_configurations: Optional[List[str]],       # pylint: disable=unused-argument
    force: bool,
) -> List[Commands.Command]:
    """Return custom actions invoked as part of the setup process for this repository"""

    commands: List[Commands.Command] = []

    root_dir = Path(__file__).parent
    assert root_dir.is_dir(), root_dir

    tools_dir = root_dir / Constants.TOOLS_SUBDIR
    assert tools_dir.is_dir(), tools_dir

    with dm.Nested("\nProcessing 'Common_cpp_Development' tools...") as extract_dm:
        tools = [
            ("ccache", CCACHE_VERSIONS),
            ("cmake", CMAKE_VERSIONS),
            ("ninja", NINJA_VERSIONS),
        ]

        for tool_index, (tool_name, versions) in enumerate(tools):
            with extract_dm.Nested(
                "'{}' ({} of {})...".format(tool_name, tool_index + 1, len(tools)),
            ) as tool_dm:
                for version_index, (version, install_data) in enumerate(versions.items()):
                    with tool_dm.Nested(
                        "'{}' ({} of {})...".format(
                            version,
                            version_index + 1,
                            len(versions),
                        ),
                    ) as this_dm:
                        install_data.installer.Install(
                            this_dm,
                            force=force,
                        )

    # Create a link to the foundation's .pylintrc file
    foundation_root_file = Path(Types.EnsureValid(os.getenv(Constants.DE_FOUNDATION_ROOT_NAME))) / ".pylintrc"
    assert foundation_root_file.is_file(), foundation_root_file

    commands.append(
        Commands.SymbolicLink(
            root_dir / foundation_root_file.name,
            foundation_root_file,
            remove_existing=True,
            relative_path=True,
        ),
    )

    return commands
