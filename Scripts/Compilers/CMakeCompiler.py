# ----------------------------------------------------------------------
# |
# |  CMakeCompiler.py
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-09-16 15:57:23
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
"""Compiles code using Cmake."""

import os
import re
import shutil

from pathlib import Path
from typing import Any, Dict, Generator, List as ListType, Tuple

import typer

from typer.core import TyperGroup

from Common_Foundation.ContextlibEx import ExitStack
from Common_Foundation import PathEx
from Common_Foundation.Shell.All import CurrentShell
from Common_Foundation.Streams.DoneManager import DoneManager
from Common_Foundation import SubprocessEx
from Common_Foundation.Types import overridemethod

from Common_FoundationEx.CompilerImpl.Compiler import Compiler as CompilerBase, CreateCleanCommandLineFunc, CreateCompileCommandLineFunc, CreateListCommandLineFunc, InputType
from Common_FoundationEx.CompilerImpl.Mixins.InputProcessorMixins.IndividualInputProcessorMixin import IndividualInputProcessorMixin
from Common_FoundationEx.CompilerImpl.Mixins.InvocationQueryMixins.ConditionalInvocationQueryMixin import ConditionalInvocationQueryMixin
from Common_FoundationEx.CompilerImpl.Mixins.InvokerMixins.CommandLineInvokerMixin import CommandLineInvokerMixin
from Common_FoundationEx.CompilerImpl.Mixins.OutputProcessorMixins.MultipleOutputProcessorMixin import MultipleOutputProcessorMixin

from Common_FoundationEx.InflectEx import inflect
from Common_FoundationEx import TyperEx


# ----------------------------------------------------------------------
class NaturalOrderGrouper(TyperGroup):
    # ----------------------------------------------------------------------
    def list_commands(self, *args, **kwargs):  # pylint: disable=unused-argument
        return self.commands.keys()


# ----------------------------------------------------------------------
app                                         = typer.Typer(
    cls=NaturalOrderGrouper,
    no_args_is_help=True,
    pretty_exceptions_show_locals=False,
)


# ----------------------------------------------------------------------
# |
# |  Public Types
# |
# ----------------------------------------------------------------------
class Compiler(
    IndividualInputProcessorMixin,
    ConditionalInvocationQueryMixin,
    CommandLineInvokerMixin,
    MultipleOutputProcessorMixin,
    CompilerBase,
):
    # ----------------------------------------------------------------------
    def __init__(self):
        CompilerBase.__init__(
            self,
            "CMake",
            "Compiles code using cmake.",
            InputType.Directories,

            # Don't allow the parallel execution of cmake files, as each of them will
            # internally use all threads on the machine.
            can_execute_in_parallel=False,
        )

        ConditionalInvocationQueryMixin.__init__(self, self, self)
        MultipleOutputProcessorMixin.__init__(self, self)

    # ----------------------------------------------------------------------
    @overridemethod
    def GetCustomCommandLineArgs(self) -> TyperEx.TypeDefinitionsType:
        return {
            "generator": (str, typer.Option("Ninja", help="CMake Generator to use.")),
            "debug_build": (bool, typer.Option(False, "--debug-build", help="Create a debug build.")),
            "profile_build": (bool, typer.Option(False, "--profile-build", help="Create a build suitable for use with benchmarking/code coverage.")),
            "cmake_debug_output": (bool, typer.Option(False, "--cmake-debug-output", help="Generate CMake debug output.")),
            "utf_16": (bool, typer.Option(False, "--utf-16", help="Use wide characters.")),
            "static_crt": (bool, typer.Option(False, "--static-crt", help="Link with the static C-Runtime.")),
            "benchmark": (bool, typer.Option(False, "--benchmark", help="Run benchmark tests.")),
            "disable_debug_info": (bool, typer.Option(False, "--disable-debug-info", help="Generate binaries without debug information used during post-mortem debugging.")),
            "disable_aslr": (bool, typer.Option(False, "--disable-aslr", help="Do not link with Address Space Layout Randomization (ASLR).")),
            "preprocessor_output": (bool, typer.Option(False, "--preprocessor-output", help="Create preprocessor output when compiling.")),
            "overwrite": (bool, typer.Option(False, "--overwrite", help="Overwrite the output directory if it already exists.")),
        }

    # ----------------------------------------------------------------------
    @overridemethod
    def IsSupported(
        self,
        filename_or_directory: Path,
    ) -> bool:
        """Return True if the filename provided is valid for compilation by this compiler"""

        return (
            filename_or_directory.is_dir()
            and (filename_or_directory / "CMakeLists.txt").is_file()
        )

    # ----------------------------------------------------------------------
    @overridemethod
    def RemoveTemporaryArtifacts(
        self,
        context: Dict[str, Any],
    ) -> None:
        output_dir = context["output_dir"]

        # Move GCC-generated profile data to the output dir
        for root, _, filenames in os.walk(output_dir):
            for filename in filenames:
                filename = Path(filename)

                if filename.suffix in [".gcno", ".gcda"]:
                    source_filename = root / filename
                    dest_filename = output_dir / filename

                    if dest_filename != source_filename:
                        shutil.copyfile(source_filename, dest_filename)

        # Remove unwanted dirs
        for potential_dir in [
            "CMakeFiles",
            "Testing",
        ]:
            PathEx.RemoveTree(output_dir / potential_dir)

        # Remove unwanted files
        for potential_file in [
            "CMakeCache.txt",
            "cmake_install.cmake",
            "Makefile",
        ]:
            fullpath = output_dir / potential_file

            if fullpath.is_file():
                fullpath.unlink()

        # Remove unwanted file extensions
        for item in output_dir.iterdir():
            if item.suffix in [".ilk"]:
                item.unlink()

    # ----------------------------------------------------------------------
    @overridemethod
    def CreateInvokeCommandLine(
        self,
        dm: DoneManager,
        context: Dict[str, Any],
    ) -> str:
        return 'cmake --build "{}"'.format(context["output_dir"])

    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    # ----------------------------------------------------------------------
    @overridemethod
    def _EnumerateOptionalMetadata(self) -> Generator[Tuple[str, Any], None, None]:
        for name, (_, typer_option) in self.GetCustomCommandLineArgs().items():
            assert isinstance(typer_option, typer.models.OptionInfo), typer_option
            yield name, typer_option.default

        yield from super(Compiler, self)._EnumerateOptionalMetadata()

    # ----------------------------------------------------------------------
    @overridemethod
    def _GetRequiredMetadataNames(self) -> ListType[str]:
        return super(Compiler, self)._GetRequiredMetadataNames()

    # ----------------------------------------------------------------------
    @overridemethod
    def _GetRequiredContextNames(self) -> ListType[str]:
        return [
            "output_dir",
        ] + super(Compiler, self)._GetRequiredContextNames()

    # ----------------------------------------------------------------------
    @overridemethod
    def _CreateContext(
        self,
        dm: DoneManager,
        metadata: Dict[str, Any],
    ) -> Dict[str, Any]:
        if "output_dir" not in metadata:
            return metadata

        if metadata["output_dir"].exists() and metadata["overwrite"]:
            PathEx.RemoveTree(metadata["output_dir"])

        output_filenames: ListType[Path] = []

        with dm.Nested(
            "Extracting output filenames...",
            lambda: "{} found".format(inflect.no("output filename", len(output_filenames))),
            suffix="\n" if dm.is_verbose else "",
        ) as extract_dm:
            # Invoke cmake to get a list of the generated files. The best way that I have found
            # to do this is to parse generated dot files (as we don't want to get into the business
            # of parsing cmake files).
            temp_directory = CurrentShell.CreateTempDirectory()

            should_delete_dir = True

            # ----------------------------------------------------------------------
            def OnExit():
                if should_delete_dir:
                    PathEx.RemoveTree(temp_directory)

            # ----------------------------------------------------------------------

            with ExitStack(OnExit):
                dot_filename = temp_directory / "generated.dot"

                command_line_options: ListType[str] = [
                    '-S "{}"'.format(metadata["input"]),
                    '-B "{}"'.format(metadata["output_dir"]),
                    '-G "{}"'.format(metadata["generator"]),
                    '"--graphviz={}"'.format(dot_filename),
                    "-DCMAKE_BUILD_TYPE={}".format(
                        "Debug" if metadata["debug_build"] else "Release",
                    ),
                    "-DCMAKE_VERBOSE_MAKEFILE:BOOL={}".format(
                        "ON" if metadata["cmake_debug_output"] else "OFF",
                    ),
                    "-DCppDevelopment_CODE_COVERAGE={}".format(
                        "ON" if metadata["profile_build"] else "OFF",
                    ),
                    "-DCppDevelopment_CMAKE_DEBUG_OUTPUT={}".format(
                        "ON" if metadata["cmake_debug_output"] else "OFF",
                    ),
                    "-DCppDevelopment_UTF_16={}".format(
                        "ON" if metadata["utf_16"] else "OFF",
                    ),
                    "-DCppDevelopment_STATIC_CRT={}".format(
                        "ON" if metadata["static_crt"] else "OFF",
                    ),
                    "-DCppDevelopment_NO_DEBUG_INFO={}".format(
                        "ON" if metadata["disable_debug_info"] else "OFF",
                    ),
                    "-DCppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION={}".format(
                        "ON" if metadata["disable_aslr"] else "OFF",
                    ),
                    "-DCppDevelopment_PREPROCESSOR_OUTPUT={}".format(
                        "ON" if metadata["preprocessor_output"] else "OFF",
                    ),
                ]

                command_line = "cmake {}".format(" ".join(command_line_options))

                extract_dm.WriteVerbose("Command line: {}\n\n".format(command_line))

                result = SubprocessEx.Run(command_line)

                extract_dm.result = result.returncode

                if extract_dm.result != 0:
                    should_delete_dir = False

                    extract_dm.WriteError(result.output)
                    return metadata

                extract_dm.WriteVerbose("{}\n\n".format(result.output.rstrip()))

                # Parse the dot file to extract the output filenames. This regular expression has
                # been tested with dot files generated by:
                #
                #   - CMake 3.24.2
                #
                regex = re.compile(
                    r"""(?#
                    start of line                       )^(?#
                    node                                )\s*\"node\d+\"\s*(?#
                    lbracket                            )\[\s*(?#
                    label key                           )label\s*=\s*(?#
                    name                                )\"(?P<name>.+?)\"(?#
                    [optional] comma delimiter          ),?(?#
                    shape key                           )\s*shape\s*=\s*(?#
                    value                               )(?P<shape>\"house\"|egg)\s*(?#
                    rbracket                            )\]\s*(?#
                    terminator                          );\s*(?#
                    end of line                         )$(?#
                    )""",
                    re.MULTILINE,
                )

                with dot_filename.open() as f:
                    content = f.read()

                output_filenames: ListType[Path] = []

                for match in regex.finditer(content):
                    output_filename = metadata["output_dir"] / match.group("name")

                    if CurrentShell.executable_extensions is not None:
                        output_filename = output_filename.with_suffix(CurrentShell.executable_extensions[0])

                    output_filenames.append(output_filename)
                    extract_dm.WriteVerbose("Output filename: {}\n".format(output_filename))

                metadata["output_filenames"] = output_filenames

        return super(Compiler, self)._CreateContext(dm, metadata)


# ----------------------------------------------------------------------
# |
# |  Public Functions
# |
# ----------------------------------------------------------------------
_compiler                                   = Compiler()

Compile                                     = CreateCompileCommandLineFunc(app, _compiler)
Clean                                       = CreateCleanCommandLineFunc(app, _compiler)
List                                        = CreateListCommandLineFunc(app, _compiler)


# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
if __name__ == "__main__":
    app()
