{
  lib,
  callPackage,
  pkgs,

  editline,
  lixVersions,
  ncurses,
}:

let
  pins = import ../npins;

  inherit (lib) listToAttrs nameValuePair replaceStrings;

  makeStoreArchive = callPackage ./make-store-archive.nix { };

  # Makes a set of Lix packages, where the version is the key and the package is the value.
  #
  # Accepts:
  # - f: A function that accepts a system, and a Lix package, that produces the final value assigned to the version in
  #   the set.
  # - lixen: A function that accepts a system, and returns a list of Lix packages to include in the set.
  # - system: The system to produce a set for.
  mkLixSet =
    f: lixen: system:
    listToAttrs (
      map (lix: nameValuePair "v${replaceStrings [ "." ] [ "_" ] lix.version}" (f system lix)) (
        lixen system
      )
    );

  # Accepts a system, and returns a list of Lix derivations that are supported on that system.
  # Currently there's no variation between systems (ie. all systems support all versions), but that may change in the
  # future.
  lixVersionsForSystem =
    system:
    let
      # The Lix repo doesn't give us a good way to override nixpkgs when consuming it from outside a flake, so we can
      # do some hacks with the overlay instead.
      lix_2_92 = ((import pins.lix-2_92).overlays.default pkgs pkgs).nix.override {
        # From <https://git.lix.systems/lix-project/nixos-module/pulls/59>:
        # Do not override editline-lix
        # according to the upstream packaging.
        # This was fixed in nixpkgs directly.
        editline-lix = editline.overrideAttrs (old: {
          propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ ncurses ];
        });
      };
    in
    [
      lix_2_92
      lixVersions.lix_2_91
      lixVersions.lix_2_90
    ];
in
rec {
  # Accepts a system, and returns an attribute set from supported versions to Lix derivations.
  lixVersionsFor = mkLixSet (_: lix: lix) lixVersionsForSystem;
  # Accepts a system, and returns an attribute set from supported versions to a Lix archive for that version.
  lixArchivesFor = mkLixSet makeStoreArchive lixVersionsForSystem;

  # Accepts a system, and returns a derivation producing a folder containing Lix archives for all Lix versions
  # supported by the given system.
  combinedArchivesFor =
    system:
    pkgs.symlinkJoin {
      name = "lix-archives";
      paths = builtins.attrValues (lixArchivesFor system);
    };
}
