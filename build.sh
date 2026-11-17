#!/bin/bash
# Builds dotnet-<version>-aarch64.squashfs, the .NET runtime as a PortMaster runtime (it goes in PortMaster/libs/), from
# Microsoft's own release files:
#   the .NET runtime for linux-arm64 (builds.dotnet.microsoft.com), checked against the SHA-512 in Microsoft's release notes
#   crossgen2 for linux-arm64 (NuGet: Microsoft.NETCore.App.Crossgen2.linux-arm64), checked against the SHA-512 below
# Layout inside: dotnet, host/, shared/Microsoft.NETCore.App/<version>/, crossgen2/ (crossgen2 and the arm64 JIT it needs),
# LICENSE.txt, ThirdPartyNotices.txt. A port mounts it and runs "$mount/dotnet"; a setup compiles with "$mount/crossgen2/crossgen2".
# Usage: ./build.sh            -> out/dotnet-10.0.15-aarch64.squashfs (downloads are kept in cache/)
set -euo pipefail
VERSION=10.0.15
RUNTIME_URL=https://builds.dotnet.microsoft.com/dotnet/Runtime/$VERSION/dotnet-runtime-$VERSION-linux-arm64.tar.gz
RUNTIME_SHA512=e2e8b907d9eb6c239cccf5c1fe67fd9a72c56fddccedca9ba41c8a53ff034293b335fdd9f7ab504f09bf7b3f165e0d14e34fc9ea1f06cc0e86d0dfb06d274b6a
CG2_URL=https://api.nuget.org/v3-flatcontainer/microsoft.netcore.app.crossgen2.linux-arm64/$VERSION/microsoft.netcore.app.crossgen2.linux-arm64.$VERSION.nupkg
CG2_SHA512=6ed5dd9fc950e023e642333c4d040cc9369242528b71f4cf3958f406c6c964575b477e217289d6d5159d5df2a37d269f1c86473afdc8268eb2bbd1846d8812dc

HERE=$(cd "$(dirname "$0")" && pwd)
CACHE=$HERE/cache; STAGE=$HERE/build/stage; OUT=$HERE/out
SQ=$OUT/dotnet-$VERSION-aarch64.squashfs
for t in curl tar unzip sha512sum mksquashfs; do command -v $t >/dev/null || { echo "needs $t"; exit 1; }; done
mkdir -p "$CACHE" "$OUT"

fetch() {   # url sha512 file
  if [ ! -f "$3" ] || ! echo "$2  $3" | sha512sum -c --status; then
    echo "downloading $(basename "$3")"
    curl -fL --retry 3 -o "$3.part" "$1" && mv "$3.part" "$3"
  fi
  echo "$2  $3" | sha512sum -c --quiet || { echo "$(basename "$3"): checksum does not match"; exit 1; }
}
fetch "$RUNTIME_URL" "$RUNTIME_SHA512" "$CACHE/dotnet-runtime-$VERSION-linux-arm64.tar.gz"
fetch "$CG2_URL" "$CG2_SHA512" "$CACHE/crossgen2-$VERSION-linux-arm64.nupkg"

rm -rf "$STAGE"; mkdir -p "$STAGE/crossgen2"
tar -xzf "$CACHE/dotnet-runtime-$VERSION-linux-arm64.tar.gz" -C "$STAGE"
# crossgen2 itself and the JIT for arm64 targets (the package also carries JITs for other targets, which this does not compile for)
unzip -q -j "$CACHE/crossgen2-$VERSION-linux-arm64.nupkg" tools/crossgen2 tools/libjitinterface_arm64.so \
  tools/libclrjit_universal_arm64_arm64.so -d "$STAGE/crossgen2"
chmod 755 "$STAGE/dotnet" "$STAGE/crossgen2/crossgen2"

rm -f "$SQ"
mksquashfs "$STAGE" "$SQ" -comp xz -b 128K -all-root -no-xattrs -noappend -quiet
rm -rf "$HERE/build"
echo "built $SQ ($(du -h "$SQ" | cut -f1))"
(cd "$OUT" && sha256sum "$(basename "$SQ")" | tee "$(basename "$SQ").sha256")
