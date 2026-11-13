# Dendritic prototype migration map

Prototype branch: `dendritic-prototype`. The flake entry uses flake-parts.
Modules group by function. Host wiring stays in `hosts/`.

## Layout

- `flake.nix`: inputs plus `mkFlake`, imports `./parts`.
- `parts/hosts.nix`: `hosts`, `nixosConfigurations`, `darwinConfigurations`.
- `parts/lib.nix`: `lib`, `overlays`.
- `parts/pkgs.nix`: the per-system package set for every `perSystem` block.
- `parts/packages.nix`, `parts/checks.nix`, `parts/shells.nix`: per-system outputs.
- `modules/system/`: nix daemon settings, host identity, remote builders, meta addresses, emulation, gitops.
- `modules/users/`: home-manager wiring, shell, development, graphical, home-manager modules.
- `modules/networking/`: tailscale, traefik.
- `modules/observability/`: monitoring checks option, alloy, exporters.
- `modules/services/`: the apps framework (`apps` option, containers, volumes, prepull, db helper, forgejo-runner, podman runtime, oci-containers override).
- `modules/security/`: ssh, kernel modprobe blocks.

## Moves

| Old | New |
| --- | --- |
| `modules/common/default.nix` (nix block) | `modules/system/nix.nix` |
| `modules/common/default.nix` (hostName, hostPlatform) | `modules/system/host.nix` |
| `modules/common/default.nix` (packages, fish, shells) | `modules/users/shell.nix` |
| `modules/common/builders.nix` | `modules/system/builders.nix` |
| `modules/common/meta.nix` | `modules/system/meta.nix` |
| `modules/common/monitoring.nix` | `modules/observability/monitoring.nix` |
| `modules/common/home.nix` | `modules/users/home.nix` |
| `modules/common/development.nix` | `modules/users/development.nix` |
| `modules/common/graphical.nix` | `modules/users/graphical.nix` |
| `modules/nixos/apps/default.nix` | `modules/services/default.nix` |
| `modules/nixos/apps/containers.nix` | `modules/services/containers.nix` |
| `modules/nixos/apps/volumes.nix` | `modules/services/volumes.nix` |
| `modules/nixos/apps/prepull.nix` | `modules/services/prepull.nix` |
| `modules/nixos/apps/presets/db.nix` | `modules/services/db.nix` |
| `modules/nixos/apps/presets/forgejo-runner.nix` | `modules/services/forgejo-runner.nix` |
| `modules/nixos/apps/presets/alloy/` | `modules/observability/alloy/` |
| `modules/nixos/apps/presets/exporters.nix` | `modules/observability/exporters.nix` |
| `modules/nixos/apps/presets/traefik.nix` | `modules/networking/traefik.nix` |
| `modules/nixos/networking.nix` | `modules/networking/tailscale.nix` |
| `modules/nixos/containers.nix` | `modules/services/podman.nix` |
| `modules/nixos/emulation.nix` | `modules/system/emulation.nix` |
| `modules/nixos/gitops.nix` | `modules/system/gitops.nix` |
| `modules/nixos/security.nix` | `modules/security/kernel.nix` |
| `modules/nixos/overrides/` | `modules/services/overrides/` |
| `modules/nixos/default.nix` (ssh, pam, root keys) | `modules/security/ssh.nix` |
| `modules/nixos/default.nix` (nix-ld, shells, cgroups) | `modules/system/nixos.nix` |
| `modules/darwin/default.nix` | `modules/system/darwin.nix` |
| `modules/darwin/home.nix` | `modules/users/darwin.nix` |
| `modules/home/` | `modules/users/home/` |

## Conventions

- `lib.internal.readModules` skips files named `nixos.nix` and `darwin.nix`.
  The variant assembly in `overlays/lib/overlay.nix` imports those leaves
  explicitly. A new platform-only file takes one of those two names and one
  line in the assembly.
- `modules/system/gitops.nix` guards its comin import on `host.platform`.
  The comin module is NixOS-only, and `modules/system/` is shared by both
  variants.
- Per-system `pkgs` comes from `parts/pkgs.nix`. It imports nixpkgs with the
  repo overlays and `allowUnfree`. Change the package set there.

## Replaced bespoke code

- `lib.internal.forAllSystems`, `buildPackages`, `buildChecks`, `pkgsFor`:
  deleted. flake-parts `systems` plus `perSystem` cover them.
- `shells/default.nix` (the `forAllSystems` wrapper): deleted.
  `parts/shells.nix` wires the shell definition per system.

## Remainder (not moved)

- `hosts/`: per-host wiring stays. Host service files enable presets and set
  host values. A full migration could move host service files into
  `modules/services/` as per-host instances, but that mixes instance data
  with module definitions.
- `overlays/`: package, check, script, and tool overlays stay. `lib.internal`
  keeps the host and container helpers (`filterHosts`,
  `collectContainerImages`, `replaceAll`, `platformOf`, `prefixAttrs`,
  `readModules`, `variants`, `buildVariant`).
- `shells/default/`: the shell definition stays; `parts/shells.nix` wires it.
- `deploy`: unchanged.
