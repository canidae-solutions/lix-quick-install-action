{
  lib,
  callPackage,
  pkgs,

  lixPackageSets,
}:

let
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
  lixVersionsForSystem = system: [
    lixPackageSets.lix_2_94.lix
    lixPackageSets.lix_2_93.lix
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
