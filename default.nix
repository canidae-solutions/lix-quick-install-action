let
  pins = import ./npins;

  nixpkgs = import pins.nixpkgs { };
in

{
  pkgs ? nixpkgs,
}:

let
  archives = pkgs.callPackage ./nix/archives.nix { };
in
rec {
  # The nixpkgs set we build everything with, in case you wanted that.
  inherit pkgs;

  # All versions of Lix supported by the running system.
  lixVersions = archives.lixVersionsFor pkgs.system;
  # Archives for all supported Lix versions.
  lixArchives = archives.lixArchivesFor pkgs.system;

  # All Lix archives for the running system.
  combinedArchives = archives.combinedArchivesFor pkgs.system;

  # The release script used in CI/CD to cut a new release.
  releaseScript = pkgs.callPackage ./nix/release-script.nix {
    inherit (archives) lixArchivesFor;
  };
}
