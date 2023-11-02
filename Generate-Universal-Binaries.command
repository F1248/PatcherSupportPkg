#!/usr/bin/env python3.13

"""
Build PatcherSupportPkg Disk Image.
Note password encryption required to pass Apple's notarization.
"""

import os, subprocess

UB_DIRECTORY:     str = "Universal-Binaries"
DMG_NAME:         str = "Universal-Binaries.dmg"
TMP_NAME:         str = "tmp.dmg"
DMG_VOLNAME:      str = "OpenCore Legacy Patcher Resources (Root Patching)"
DMG_SIZE:         str = "4096"
DMG_FORMAT:       str = "UDRO"
DMG_PASSPHRASE:   str = "password"


class GenerateDiskImage:

    def __init__(self) -> None:
        print("Generating DMG")
        self._set_working_directory()
        self._strip_extended_attributes()
        self._remove_ds_store()
        self._create_dmg()
        self._convert_dmg()
        self._remove_tmp_dmg()
        self._move_dmg()


    def _set_working_directory(self) -> None:
        print("  - Setting working directory")
        os.chdir(os.path.dirname(os.path.realpath(__file__)))


    def _reset_hdiutil(self) -> None:
        """
        Attempt to reset hdiutil
        On some instances, "hdiutil: create failed - Resource busy" is thrown
        """
        print("  - Resetting hdiutil")
        subprocess.run(["killall", "hdiutil"], capture_output=True)


    def _strip_extended_attributes(self) -> None:
        print("  - Stripping extended attributes")
        subprocess.run(["xattr", "-rc", UB_DIRECTORY], capture_output=True)


    def _remove_ds_store(self) -> None:
        print("  - Removing .DS_Store files")
        subprocess.run(["find", UB_DIRECTORY, "-name", ".DS_Store", "-delete"], capture_output=True)


    def _create_dmg(self, raise_on_error: bool = False) -> None:
        """
        raise_on_error: If false, attempts to reset hdiutil and try again
        """
        print("  - Creating DMG")
        result = subprocess.run([
            "hdiutil",
            "create",
            "-srcfolder", UB_DIRECTORY,
            TMP_NAME,
            "-format", DMG_FORMAT,
            "-fs", "HFS+",
            "-volname", DMG_VOLNAME,
            "-megabytes", DMG_SIZE,
            "-ov",            
        ], capture_output=True)
        if result.returncode != 0:
            print("    - Failed to create DMG")
            print(f"STDOUT:\n{result.stdout.decode('utf-8')}")
            print(f"STDERR:\n{result.stderr.decode('utf-8')}")
            if raise_on_error:
                raise Exception("Failed to create DMG")
            if "Resource busy" in result.stderr.decode("utf-8"):
                self._reset_hdiutil()
                self._create_dmg(raise_on_error=True)
            else:
                raise Exception("Failed to create DMG")


    def _convert_dmg(self, raise_on_error: bool = False) -> None:
        """
        raise_on_error: If false, attempts to reset hdiutil and try again
        """
        print("  - Converting DMG")
        result = subprocess.run([
            "hdiutil",
            "convert",
            TMP_NAME,
            "-o", DMG_NAME,
            "-format", "ULMO",
            "-encryption", "-passphrase", DMG_PASSPHRASE,
            "-ov"
        ], capture_output=True)
        if result.returncode != 0:
            print("    - Failed to convert DMG")
            print(f"STDOUT:\n{result.stdout.decode('utf-8')}")
            print(f"STDERR:\n{result.stderr.decode('utf-8')}")
            if raise_on_error:
                raise Exception(f"Failed to convert DMG")
            if "Resource busy" in result.stderr.decode("utf-8"):
                self._reset_hdiutil()
                self._convert_dmg(raise_on_error=True)
            else:
                raise Exception("Failed to convert DMG")


    def _remove_tmp_dmg(self) -> None:
        print(f"  - Remove {TMP_NAME}")
        subprocess.run(["rm", TMP_NAME], capture_output=True)

    def _move_dmg(self) -> None:
        print(f"  - Move {DMG_NAME}")
        subprocess.run(["mv", DMG_NAME, "../OpenCore-Legacy-Patcher"], capture_output=True)



if __name__ == "__main__":
    GenerateDiskImage()