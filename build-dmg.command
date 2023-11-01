#!/bin/zsh
set -e

cd $(dirname $0)

rm -f tmp.dmg
rm -f Universal-Binaries.dmg
xattr -rcs Universal-Binaries || true
find Universal-Binaries -name .DS_Store -delete || true

hdiutil create -srcfolder Universal-Binaries tmp.dmg -volname "OpenCore Patcher Resources (Root Patching)" -fs HFS+ -ov -format UDRO -megabytes 4096
hdiutil convert -format ULMO tmp.dmg -o Universal-Binaries.dmg -ov

rm -f tmp.dmg
