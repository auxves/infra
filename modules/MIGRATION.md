# Dendritic prototype migration map

Prototype branch: `dendritic-prototype`. The flake entry uses flake-parts.
Every file under `modules/` is a flake-parts module, auto-imported by
import-tree. Each file declares its own contributions to the right outputs
(`flake.modules.<class>.<aspect>`), and hosts assemble from those
declarations. Hosts are features under `modules/hosts/`.

## Layout

- `flake.nix`: inputs plus `mkFlake`, imports `./modules` through import-tree.
  Hand-written; nothing regenerates it.
- `modules/flake/`: flake-level plumbing. `dendritic.nix` imports the
  flake-parts `modules` extra and sets `systems`. `pkgs.nix`,
  `packages.nix`, `checks.nix`, `shells.nix` are the per-system outputs.
  `lib.nix` sets `flake.lib` (extended nixpkgs lib plus `mkNixos`/`mkDarwin`
  builders) and `flake.overlays`. `hosts.nix` builds the `flake.hosts`
  registry (`{ name, variant, cfg }`) from the configurations.
- `modules/system/`: nix daemon settings, remote builders, meta addresses,
  monitoring registry, emulation, gitops, plus the `nixos.default` and
  `darwin.default` compositions.
- `modules/users/`: home-manager wiring, shell, home-manager modules.
- `modules/networking/`: tailscale, traefik.
- `modules/services/`: one folder per application service, each file
  declaring the host or hosts it runs on by contributing to their host
  aspects (`flake.modules.nixos.<host>`). Multi-host services live in one
  file or folder: forgejo and its runner share `forgejo/`, alloy and
  traefik name both hosts in one file, and alloy's folder holds its
  exporters as a second file on the same aspect. `framework/` holds the apps
  machinery (`apps` option, containers, volumes, prepull, db helper,
  podman runtime, oci-containers override).
- `modules/security/`: ssh, kernel modprobe blocks.
- `modules/hosts/`: one directory per host. `configuration.nix` defines the
  host aspect and imports its class default. `flake-parts.nix` is the
  one-line `mkNixos`/`mkDarwin` boilerplate. `hardware.nix` contributes to
  the same host aspect. Application services live in `modules/services/`,
  not per host.

## How a module declares its target

- `flake.modules.nixos.<aspect>` for NixOS-only config.
- `flake.modules.darwin.<aspect>` for nix-darwin-only config.
- `flake.modules.generic.<aspect>` for config shared across classes,
  imported by the `nixos` and `darwin` aspects. Class differences stay in
  the class aspects, or use `pkgs.stdenv.isLinux`/`isDarwin` inside the
  shared body, never `specialArgs`.
- `flake.modules.homeManager.<aspect>` for home-manager config, imported
  into the user config by the `nixos.home`/`darwin.home` aspects.

## Enabling

A feature enables by import, not by flag. Hosts import the aspects they
use in `configuration.nix`; application services contribute to the host
aspects they run on from their own files in `modules/services/`; the class
`default` compositions hold only what every host of that class uses.
The `presets.*` enable flags are gone: `emulation`, `gitops`, `home`,
`traefik`, `alloy`, `forgejo-runner` are plain imports now, the exporters
folded into the alloy aspect, `podman` activates when `config.apps` is non-empty, and the
`development`/`graphical` relay (system aspect plus `presets.home.modules`)
is gone, with blaze importing the home-manager aspects into its user
config directly. The `presets` namespace is gone entirely: the builders
roles and host-key data are `builders.*` options declared on the builders
aspect, and the username is the `home.user` option declared on the home
aspect.
- A host is a feature: its files each set `flake.modules.<class>.<host>`,
  and the module system merges the contributions.

## Why import-tree is safe

No file under `modules/` is ever added to a NixOS or Darwin `imports` list
except through an explicit aspect reference
(`inputs.self.modules.<class>.<aspect>`). Each aspect declares its class in
its `flake.modules.<class>` key, and the flake-parts `modules` extra wraps
it with that class, so a home-manager aspect imported into a system
configuration errors instead of silently loading. The old auto-import bug
(home-manager modules loading as system modules) is fixed by this scoping,
not by avoiding import-tree: the earlier `default.nix` files that listed
members explicitly are gone, and `lib.internal.readModules` survives only
for the deploy-dns zone data files under `overlays/`.

## Abstractions

- `flake.lib.mkNixos` / `mkDarwin` (`modules/flake/lib.nix`): build a host
  configuration from its aspect plus host platform and overlays. Override a
  host by editing its aspect; remove a builder by deleting its use in the
  host `flake-parts.nix` files.
- `flake.modules.nixos.default` / `darwin.default`
  (`modules/system/default.nix`): the aspect list every host of a class
  imports. Add an aspect to a class by adding one line here; a host that
  needs a different set imports aspects directly instead of the default.
- `flake.hosts` (`modules/flake/hosts.nix`): the host registry, built from
  the configurations. Cross-host reads go through
  `inputs.self.hosts.<name>.cfg` (alloy, forgejo-runner, gatus, builders,
  deploy-dns, docker-images check). Delete the registry by deleting this
  file and the reads that use it.
- `lib.internal.collectContainerImages` (`overlays/lib/overlay.nix`): takes
  an `apps` attrset and a predicate, returns sorted unique images. The
  prepull aspect and the docker-images check pass `config.apps` /
  `host.cfg.apps`. The old host-record argument is gone with `host`.
- `lib.internal.filterHosts`, `prefixAttrs`, `readModules`, `replaceAll`
  (`overlays/lib/overlay.nix`): unchanged helpers. `readModules` serves
  only the deploy-dns zones now.

## Replaced bespoke code

- `lib.internal.forAllSystems`, `buildPackages`, `buildChecks`, `pkgsFor`:
  deleted. flake-parts `systems` plus `perSystem` cover them.
- `lib.internal.variants`, `buildVariant`, `platformOf`, and the `host`
  specialArg record: deleted. Class scoping, `mkNixos`/`mkDarwin`, and
  `pkgs.stdenv.isLinux`/`isDarwin` cover them. `host.name` is
  `networking.hostName` in the host aspect; `host.system` is
  `nixpkgs.hostPlatform` from the builder; `host.platform` is class
  scoping; `host.cfg` cross-host reads are `inputs.self.hosts.<name>.cfg`.
- `home-manager.extraSpecialArgs`: deleted. Home modules take no `self` or
  `host`; shared values reach them through the aspect closures.
- `shells/default.nix` (the `forAllSystems` wrapper): deleted.
  `modules/flake/shells.nix` wires the shell definition per system.
- `parts/`: deleted. `modules/flake/` holds the same plumbing.
- `hosts/`: moved to `modules/hosts/`. The old `hosts/default.nix` host
  map is gone; hosts register themselves through `flake-parts.nix`.
- `presets.*`: deleted entirely. Enabling is importing the aspect
  (see Enabling above). Builders roles and the home user are aspect
  options (`builders.*`, `home.user`).

## Remainder (not moved)

- `overlays/`: package, check, script, and tool overlays stay.
- `shells/default/`: the shell definition stays;
  `modules/flake/shells.nix` wires it.
- `deploy`: unchanged.
