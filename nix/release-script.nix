{
  lib,
  writeShellApplication,
  writeText,

  coreutils,
  gitMinimal,
  github-cli,

  lixArchivesFor,
}:

let
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # Generate a markdown file containing a list of Lix versions that the action supports, for all supported systems
  # listed above. This gets included into the release's description.
  supportedVersions = writeText "supportedVersions" (
    lib.concatMapStringsSep "\n" (
      system:
      let
        inherit (lib) attrValues naturalSort reverseList;

        mkMarkdownList = map (s: "- ${s}");
        sortedVersions = reverseList (
          naturalSort (map (archive: archive.version) (attrValues (lixArchivesFor system)))
        );
      in
      ''
        ## Supported Lix versions on ${system}:
        ${lib.concatStringsSep "\n" (mkMarkdownList sortedVersions)}
      ''
    ) supportedSystems
  );

  # Produce a list of all Lix archives for all systems, to pass to the GitHub CLI when making a release.
  releaseAssets =
    let
      allSystemsArchives = lib.concatMap (
        system: lib.attrValues (lixArchivesFor system)
      ) supportedSystems;
    in
    lib.concatMapStringsSep " " (archive: "\"$lix_archives/${archive.fileName}\"") allSystemsArchives;
in

# Create a shell script to cut a new release. The script runs at the end of the CI/CD workflow, and creates a new tagged
# release if the first line of RELEASE contains a newer version than the last release. The release notes come from the
# rest of RELEASE and the supportedVersions list above, and all Lix archives for all systems are included as assets.
writeShellApplication {
  name = "release";

  runtimeInputs = [
    coreutils
    gitMinimal
    github-cli
  ];

  text = ''
    if [ "$GITHUB_ACTIONS" != "true" ]; then
      echo >&2 "not running in GitHub, exiting"
      exit 1
    fi

    lix_archives="$1"
    release_file="$2"
    release="$(head -n1 "$release_file")"
    prev_release="$(gh release list -L 1 | cut -f 3)"

    if [ "$release" = "$prev_release" ]; then
      echo >&2 "Release tag not updated ($release)"
      exit
    else
      release_notes="$(mktemp)"
      tail -n+2 "$release_file" > "$release_notes"

      echo "" | cat >>"$release_notes" - "${supportedVersions}"

      echo >&2 "New release: $prev_release -> $release"

      gh release create "$release" ${releaseAssets} \
          --title "$GITHUB_REPOSITORY@$release" \
          --notes-file "$release_notes"
    fi
  '';
}
