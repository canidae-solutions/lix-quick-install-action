let
  pins = import ./npins;
  nixpkgs = import pins.nixpkgs {
    config = { };
    overlays = [ ];
  };
in

{
  pkgs ? nixpkgs,
  system ? pkgs.stdenv.hostPlatform.system,
}:

let
  archives = pkgs.callPackage ./nix/archives.nix { };
in
rec {
  # The nixpkgs set we build everything with, in case you wanted that.
  inherit pkgs;

  # All versions of Lix supported by the given system (default: the system being built on).
  lixVersions = archives.lixVersionsFor system;
  # Archives for all supported Lix versions.
  lixArchives = archives.lixArchivesFor system;

  # All Lix archives for the given system.
  combinedArchives = archives.combinedArchivesFor system;

  # The release script used in CI/CD to cut a new release.
  releaseScript = pkgs.callPackage ./nix/release-script.nix {
    inherit (archives) lixArchivesFor;
  };
}
