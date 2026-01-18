# lix quick install action

[![ci/cd pipeline static](https://img.shields.io/github/actions/workflow/status/canidae-solutions/lix-quick-install-action/cicd.yml)](https://github.com/canidae-solutions/lix-quick-install-action/actions/workflows/cicd.yml) [![latest release](https://img.shields.io/github/v/release/canidae-solutions/lix-quick-install-action)](https://github.com/canidae-solutions/lix-quick-install-action/releases/latest) ![trans rights](https://pride-badges.pony.workers.dev/static/v1?label=trans%20rights&stripeWidth=6&stripeColors=5BCEFA,F5A9B8,FFFFFF,F5A9B8,5BCEFA)

sets up [lix](https://lix.systems/) in single-user mode on github actions, really fast.

- how fast? ~5 seconds tops, in our testing
- deterministic installs - get the same lix install, every time
- supports all linux and macos runners
- lets you configure the lix install exactly how you need it

getting started only takes one extra line in your workflows:

```yaml
steps:
  - uses: canidae-solutions/lix-quick-install-action@v4
```

## notes

to keep the install super-speedy, the action doesn't do much more than just setup lix in single user mode. that means there's no multi-user daemon, no channels configured, and nothing in `NIX_PATH`. notably, this means references to eg. `<nixpkgs>` in your code won't work - you'll need to manage dependencies yourself. we recommend using [npins](https://github.com/andir/npins) for this, but any other solution will work just fine, including [niv](https://github.com/nmattia/niv) or [flakes](https://nixos.wiki/wiki/Flakes). check out the [examples directory](https://github.com/canidae-solutions/lix-quick-install-action/tree/main/examples) to see how it all works.

if you need something other than single-user lix in your pipelines, here's some suggestions:
- need multi-user lix? [samueldr/lix-gha-installer-action](https://github.com/samueldr/lix-gha-installer-action) does a full install of lix in multi-user mode (ie. with a daemon) using the official lix installer.
- want nix instead? [nixbuild/nix-quick-install-action](https://github.com/nixbuild/nix-quick-instal-action) is what we forked to create this action, and it works just as well for setting up nix.
- there's also cachix's [cachix/install-nix-action](https://github.com/cachix/install-nix-action) if you need a multi-user nix install.

caching your builds is a great way to speed up your ci runs even further! you can use [cachix/cachix-action](https://github.com/cachix/cachix-action) to upload all your built derivation outputs to a remote [cachix](https://cachix.org) store, or [nix-community/cache-nix-action](https://github.com/nix-community/cache-nix-action) to store the final nix store in github actions' built-in cache. both options work great alongside this action - just set them up to run after the install.

## local testing

we expose a nix expression from this repo that contains derivations for the exact same copies of lix that we install in runners with this action, so you can use them to quickly run local tests against the environment in actions with `nix run`, like so:

```
$ nix run -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/main.zip lixVersions.v2_94_0 -- --version
nix (Lix, like Nix) 2.94.0
```

all of the lix derivations live under `lixVersions`, keyed by version. if you need to see what versions we have available, you can run:

```
$ nix eval -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/main.zip lixVersions --apply builtins.attrNames
[ "v2_93_3" "v2_94_0" ]
```

you can also specify a specific version of the action, to see what lix versions are available in that release. just replace `main` in the url with the version.

```
$ nix build -f https://github.com/canidae-solutions/lix-quick-install-action/archive/refs/heads/v1.zip lixVersions.v2_90_0
nix (Lix, like Nix) 2.90.0
```

## reference

the action supports a few optional configurations, to fine-tune the installation behaviour. [action.yml](action.yml) is where all the options are defined, but here's a quick reference:

| option              | description                                                                                                                                                   | default                                                                |
|---------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------|
| `lix_version`       | the version of lix to install. check the [releases](https://github.com/canidae-solutions/lix-quick-install-action/releases) for a list of supported versions. | 2.94.0                                                                 |
| `lix_conf`          | extra configuration options to add to `/etc/nix/nix.conf`.                                                                                                    | `<empty>`                                                                     |
| `github_access_token` | the access token to use when fetching github repositories.                                                                                                    | `${{ github.token }}` (ie. the same token exposed during actions runs) |
| `lix_on_tmpfs`      | whether to install the lix store on a tmpfs. this can speed up lix builds a little bit, at the expense of using extra memory in the runner.                   | `false`                                                                |
| `enable_kvm`        | whether to enable kvm on linux runners if supported. this helps builds run a lot faster - we recommend leaving this on unless you run into issues with it.    | `true`                                                                 |
