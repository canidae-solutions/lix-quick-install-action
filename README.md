# Lix Quick Install Action

This GitHub Action installs [Lix](https://lix.systems/) in single-user mode, and adds almost no time at all to your workflow's running time.

The Lix installation is deterministic – for a given release of this action the resulting Lix setup will always be identical, no matter when you run the action.

- Supports all Linux and MacOS runners
- Single-user installation (no `nix-daemon`)
- Installs in ≈ 1 second on Linux, ≈ 5 seconds on MacOS
- Allows selecting Lix version via the `lix_version` input
- Allows specifying `nix.conf` contents via the `lix_conf` input

## Details

The main motivation behind this action is to install Lix as quickly as possible in your GitHub workflow. To achieve this, the installation is minimal: no daemon (ie. single-user Lix), no channels and no `NIX_PATH`. The nix store (`/nix/store`) is owned by the unprivileged runner user. If that's not what you're looking for...

- Need multi-user Lix? [samueldr/lix-gha-installer-action](https://github.com/samueldr/lix-gha-installer-action) does a full setup of Lix in multi-user mode (daemon mode) using the official Lix installer.
- Looking for Nix, not Lix? This action is a fork of [nixbuild/nix-quick-install-action](https://github.com/samueldr/lix-gha-installer-action)! We forked it to install Lix instead of Nix - if you need Nix, this one works in exactly the same way.
- There's also Cachix's [install-nix-action](https://github.com/cachix/install-nix-action) if you need a multi-user Nix install.

The action provides you with a fully working Lix setup, but since no `NIX_PATH` or channels are setup you need to handle this on your own. Flakes is great for this, and works perfectly with this action (see below). [niv](https://github.com/nmattia/niv) should also work fine, but has not been tested yet.

## Inputs

See [action.yml](action.yml) for documentation of the available inputs. The available Lix versions are listed in the [release notes](https://github.com/canidae-solutions/lix-quick-install-action/releases/latest).

## Usage

### Minimal example

The following workflow installs Lix and then just runs `nix-build --version`:

```yaml
name: Examples
on: push
jobs:
  minimal:
    runs-on: ubuntu-latest
    steps:
      - uses: canidae-solutions/lix-quick-install-action@v1
      - run: nix build --version
      - run: nix build ./examples/flakes-simple
      - name: hello
        run: ./result/bin/hello
```

![action-minimal](examples/action-minimal.png)

### Flakes

These settings are always set by default:

```conf
experimental-features = nix-command flakes
accept-flake-config = true
```

![action-minimal](examples/action-flakes-simple.png)

You can see the flake definition for the above example in [examples/flakes-simple/flake.nix](examples/flakes-simple/flake.nix).

### Using Cachix

You can use the [Cachix action](https://github.com/marketplace/actions/cachix) together with this action, just make sure you put it after this action in your workflow.

### Using specific Lix versions locally

Locally, you can use this repository to build or run any of the versions of Lix that this action supports. This is very convenient if you quickly need to compare the behavior between different Lix versions.

Build a specific version of Lix like this:

```
$ nix build -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/main.zip lixVersions.v2_92_0

$ ./result/bin/nix --version
nix (Lix, like Nix) 2.92.0
```

With `nix run` you can also directly run Lix like this:

```
$ nix run -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/main.zip lixVersions.v2_92_0 -- --version
nix (Lix, like Nix) 2.92.0
```

List all available Lix versions like this:

```
$ nix eval -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/main.zip lixVersions --apply builtins.attrNames
[ "v2_90_0" "v2_91_1" "v2_92_0" ]
```

If you want to make sure that the version of Lix you're trying to build hasn't been removed in the latest revision of `lix-quick-install-action`, you can specify a specific release of `lix-quick-install-action` like this:

```
$ nix build -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/v1.zip lixVersions.v2_92_0
```

Note that we've added `v1.zip` instead of `main.zip` to the url above.
