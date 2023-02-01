# ----------------------------------------------------------------------
# |
# |  Activate_custom.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-09-16 13:41:26
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

import sys
import textwrap

from pathlib import Path
from typing import Generator, List, Optional

from Common_Foundation import DynamicPluginArchitecture                     # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation.Shell import Commands                                # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation.Shell.All import CurrentShell                        # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation.Streams.DoneManager import DoneManager               # type: ignore  # pylint: disable=import-error,unused-import
from Common_Foundation import TextwrapEx                                    # type: ignore  # pylint: disable=import-error,unused-import

from Common_FoundationEx.InflectEx import inflect

from RepositoryBootstrap import Configuration                               # type: ignore  # pylint: disable=import-error,unused-import
from RepositoryBootstrap import Constants                                   # type: ignore  # pylint: disable=import-error,unused-import
from RepositoryBootstrap import DataTypes                                   # type: ignore  # pylint: disable=import-error,unused-import
from RepositoryBootstrap.ActivateActivity import ActivateActivity           # type: ignore  # pylint: disable=import-error,unused-import


# ----------------------------------------------------------------------
from _install_data import CCACHE_VERSIONS, CMAKE_VERSIONS, NINJA_VERSIONS
del sys.modules["_install_data"]


# ----------------------------------------------------------------------
# Note that it is safe to remove this function if it will never be used.
def GetCustomActions(                                                       # pylint: disable=too-many-arguments
    # Note that it is safe to remove any parameters that are not used
    dm: DoneManager,                                                        # pylint: disable=unused-argument
    repositories: List[DataTypes.ConfiguredRepoDataWithPath],               # pylint: disable=unused-argument
    generated_dir: Path,                                                    # pylint: disable=unused-argument
    configuration: Optional[str],                                           # pylint: disable=unused-argument
    version_specs: Configuration.VersionSpecs,                              # pylint: disable=unused-argument
    force: bool,                                                            # pylint: disable=unused-argument
    is_mixin_repo: bool,                                                    # pylint: disable=unused-argument
) -> List[Commands.Command]:
    """Returns a list of actions that should be invoked as part of the activation process."""

    commands: List[Commands.Command] = []

    this_dir = Path(__file__).parent
    assert this_dir.is_dir(), this_dir

    tools_dir = this_dir / Constants.TOOLS_SUBDIR
    assert tools_dir.is_dir(), tools_dir

    # Validate the dynamically installed content
    dm.WriteLine("")

    tools = [
        ("ccache", CCACHE_VERSIONS),
        ("cmake", CMAKE_VERSIONS),
        ("ninja", NINJA_VERSIONS),
    ]

    for tool_index, (tool_name, versions) in enumerate(tools):
        with dm.Nested("Validating '{}' ({} of {})...".format(tool_name, tool_index + 1, len(tools))) as tool_dm:
            _, version = ActivateActivity.GetVersionedDirectoryEx(
                tools_dir / tool_name,
                version_specs.tools,
            )

            install_data_key = str(version)

            install_data = versions.get(install_data_key, None)
            assert install_data is not None

            install_data.installer.ShouldInstall(None, lambda reason: tool_dm.WriteError(reason))

    # Get the cmake path
    cmake_dirs: List[Path] = []

    with dm.VerboseNested(
        "\nLoading cmake libraries...",
        lambda: "{} found".format(inflect.no("library", len(cmake_dirs))),
        suffix="\n" if dm.is_verbose else "",
    ) as cmake_dm:
        version_info = version_specs.libraries.get("cmake", [])

        for repository in repositories:
            for library in _EnumLibraryDependencies("cmake", repository.root, version_info):
                cmake_dm.WriteVerbose(str(library))
                cmake_dirs.append(library)

        if cmake_dirs:
            commands.append(
                Commands.Augment(
                    "DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH",
                    # cmake requires posix paths
                    [cmake_dir.as_posix() for cmake_dir in cmake_dirs],
                ),
            )

    # Get the C++ libraries
    cpp_dirs: List[Path] = []

    with dm.VerboseNested(
        "Loading C++ libraries...",
        lambda: "{} found".format(inflect.no("library", len(cpp_dirs))),
        suffix="\n" if dm.is_verbose else "",
    ) as cpp_dm:
        version_info = version_specs.libraries.get("C++", [])

        for repository in repositories:
            for library in _EnumLibraryDependencies("C++", repository.root, version_info):
                cpp_dm.WriteVerbose(str(library))
                cpp_dirs.append(library)

                # Integration with catch2 is done via cmake, but cmake needs to be able to find it
                if library.parent.name == "Catch2":
                    catch2_dir = library / "catch2"
                    assert catch2_dir.is_dir(), catch2_dir

                    commands.append(Commands.Set("DEVELOPMENT_ENVIRONMENT_CMAKE_CATCH2_ROOT", str(catch2_dir)))

        if cpp_dirs:
            commands.append(Commands.Augment("INCLUDE", [str(cpp_dir) for cpp_dir in cpp_dirs]))

    # Add a compiler name (that will likely be overwritten by a repo that depends on this one)
    commands.append(Commands.Set("DEVELOPMENT_ENVIRONMENT_CPP_COMPILER_NAME", "SystemCompiler"))

    # Add the architecture
    assert configuration
    commands.append(Commands.Set("DEVELOPMENT_ENVIRONMENT_CPP_ARCHITECTURE", configuration))

    # Add the root for this repo (as other repos will need to reference it)
    commands.append(Commands.Set("DEVELOPMENT_ENVIRONMENT_CPP_DEVELOPMENT_ROOT", str(this_dir)))

    # Add compilers, test_parsers, etc.
    scripts_dir = this_dir / Constants.SCRIPTS_SUBDIR
    assert scripts_dir.is_dir(), scripts_dir

    with dm.VerboseNested(
        "Activating dynamic plugins from '{}'...".format(this_dir),
        suffix="\n" if dm.is_debug else "",
    ) as nested_dm:
        for env_name, subdir, name_suffixes in [
            ("DEVELOPMENT_ENVIRONMENT_COMPILERS", "Compilers", ["Compiler"]),
            ("DEVELOPMENT_ENVIRONMENT_TEST_PARSERS", Path("TesterPlugins") / "TestParsers", ["TestParser"]),
        ]:
            commands += DynamicPluginArchitecture.CreateRegistrationCommands(
                nested_dm,
                env_name,
                scripts_dir / subdir,
                lambda fullpath: (
                    fullpath.suffix == ".py"
                    and any(fullpath.stem.endswith(name_suffix) for name_suffix in name_suffixes)
                ),
            )

    commands.append(
        Commands.Augment(
            "DEVELOPMENT_ENVIRONMENT_TESTER_CONFIGURATIONS",
            [
                # <configuration name>-<plugin type>-<value>[-pri=<priority>]
                "cmake-compiler-CMake",
                "cmake-test_parser-CMake",
            ],
        ),
    )

    if CurrentShell.family_name == "Windows":
        # Compilers on Windows may have problems with long paths; set a warning if the root is long.
        max_path_length = 60

        for parent in generated_dir.parents:
            if parent.name == Constants.GENERATED_DIRECTORY_NAME:
                len_generated = len(str(parent))

                if len_generated > max_path_length:
                    commands += [
                        Commands.Message(
                            TextwrapEx.Indent(
                                TextwrapEx.CreateWarningText(
                                    textwrap.dedent(
                                        """\
                                        The root directory for this repository is long, which may cause problems for some compilers.
                                        If you experience abnormal compiler errors, create a short symbolic link to this root
                                        directory and use that link when compiling. Alternatively, enlist in this repository under
                                        a shorter path.

                                        Note that CMAKE precompiled header support will be disabled, as this is generally the first
                                        piece of functionality negatively impacted by long paths.

                                            Current Directory:          {} [{} characters]
                                            Max Recommended Length:     {} characters
                                        """,
                                    ).format(
                                        parent,
                                        len_generated,
                                        max_path_length,
                                    ),
                                ),
                                2,
                            ),
                        ),
                        Commands.Set("DEVELOPMENT_ENVIRONMENT_CPP_CMAKE_DISABLE_PRECOMPILE_HEADERS", "1"),
                    ]
                else:
                    commands.append(Commands.Set("DEVELOPMENT_ENVIRONMENT_CPP_CMAKE_DISABLE_PRECOMPILE_HEADERS", "0"))

                break

    return commands


# ----------------------------------------------------------------------
# Note that it is safe to remove this function if it will never be used.
def GetCustomActionsEpilogue(                                               # pylint: disable=too-many-arguments
    # Note that it is safe to remove any parameters that are not used
    dm: DoneManager,                                                        # pylint: disable=unused-argument
    repositories: List[DataTypes.ConfiguredRepoDataWithPath],               # pylint: disable=unused-argument
    generated_dir: Path,                                                    # pylint: disable=unused-argument
    configuration: Optional[str],                                           # pylint: disable=unused-argument
    version_specs: Configuration.VersionSpecs,                              # pylint: disable=unused-argument
    force: bool,                                                            # pylint: disable=unused-argument
    is_mixin_repo: bool,                                                    # pylint: disable=unused-argument
) -> List[Commands.Command]:
    """\
    Returns a list of actions that should be invoked as part of the activation process. Note
    that this is called after `GetCustomActions` has been called for each repository in the dependency
    list.

    ********************************************************************************************
    Note that it is very rare to have the need to implement this method. In most cases, it is
    safe to delete the entire method. However, keeping the default implementation (that
    essentially does nothing) is not a problem.
    ********************************************************************************************
    """

    return []


# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
def _EnumLibraryDependencies(
    library_name: str,
    root: Path,
    version_infos: List[Configuration.VersionInfo],
) -> Generator[Path, None, None]:
    library_fullpath = root / Constants.LIBRARIES_SUBDIR / library_name

    if not library_fullpath.is_dir():
        return

    for item in library_fullpath.iterdir():
        if not item.is_dir():
            continue

        item = ActivateActivity.GetVersionedDirectory(item, version_infos)
        assert item.is_dir(), item

        yield item
