# PortMaster .NET runtime

`dotnet-10.0.15-aarch64.squashfs`: Microsoft's .NET 10 runtime for linux-arm64 with crossgen2, packed as a PortMaster
runtime. It goes in `PortMaster/libs/`. Ports mount it (Terraria mounts it at `$HOME/dotnet10`), run `dotnet` from it and
compile ReadyToRun code at setup with `crossgen2/crossgen2`.

## Build

```bash
./build.sh
```

The script downloads two files from Microsoft and checks them against pinned SHA-512 hashes:

- `dotnet-runtime-10.0.15-linux-arm64.tar.gz` from builds.dotnet.microsoft.com (the hash from Microsoft's release notes)
- `Microsoft.NETCore.App.Crossgen2.linux-arm64` 10.0.15 from NuGet

It unpacks them into one tree and packs it with gzip in 128 KB blocks, like PortMaster's own runtimes: the 4.4 kernels of dArkOS on RK3326 handhelds cannot mount an xz squashfs. The result is `out/dotnet-10.0.15-aarch64.squashfs`
with a `.sha256` file next to it. Downloads stay in `cache/`.

Needs `curl`, `tar`, `unzip`, `sha512sum` and `mksquashfs` (squashfs-tools).

## Contents

| Path | What |
|---|---|
| `dotnet`, `host/`, `shared/Microsoft.NETCore.App/10.0.15/` | the .NET runtime, as Microsoft ships it |
| `crossgen2/crossgen2`, `crossgen2/libjitinterface_arm64.so`, `crossgen2/libclrjit_universal_arm64_arm64.so` | the ReadyToRun compiler and its arm64 JIT |
| `LICENSE.txt`, `ThirdPartyNotices.txt` | .NET's licence (MIT) and notices |

## Another version

Change `VERSION` and the two hashes in `build.sh`. The runtime's SHA-512 is in
`https://builds.dotnet.microsoft.com/dotnet/release-metadata/<major>/releases.json`. Compute the crossgen2 package's hash
from the downloaded `.nupkg`.
