{
  pkgs ? import <nixpkgs> { },
}:
let
  imageName = "zot.bealv.io/public/action-runner-nix";
  entrypoint = pkgs.writeShellScriptBin "entrypoint.sh" ''
    export ORGANIZATION=$ORGANIZATION
    export ACCESS_TOKEN=$ACCESS_TOKEN
    export REG_TOKEN=$(curl -sX POST -H "Authorization: token $ACCESS_TOKEN" https://api.github.com/orgs/$ORGANIZATION/actions/runners/registration-token | jq .token --raw-output)
    config.sh --url https://github.com/$ORGANIZATION --token $REG_TOKEN
    cleanup() {
        echo "Removing runner..."
        config.sh remove --unattended --token $REG_TOKEN
    }
    trap 'cleanup; exit 130' INT
    trap 'cleanup; exit 143' TERM
    nix-daemon &
    run.sh & wait $!
  '';
  sources = import ./npins;
  # inherit (sources.runner) version;
  github-runner = pkgs.github-runner.overrideAttrs (oldAttrs: {
    src = sources.runner;
  });
in
pkgs.dockerTools.streamLayeredImage {
  name = "${imageName}";
  created = "now";
  fakeRootCommands = "
    mkdir -p home/runner nix/store tmp nix/var/nix
    chown 1001:1001 -R home/runner
    chmod 777 -R tmp
  ";

  contents = with pkgs; [
    (pkgs.dockerTools.fakeNss.override {
      extraPasswdLines = [
        "runner:x:1001:1001:Build user:/home/runner:/noshell"
      ];
      extraGroupLines = [
        "runner:!:1001:"
      ];
    })
    (pkgs.writeTextDir "etc/nix/nix.conf" ''
      experimental-features = nix-command flakes
    '')
    bash
    coreutils
    gnugrep
    glibc
    cacert
    github-runner
    lix
    npins
    curl
    git
    jq
    xz
    gzip
    gawk
    gnutar
    entrypoint
  ];
  config = {
    User = "1001:1001";
    EntryPoint = [ "entrypoint.sh" ];
    Env = [
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NIX_LINK=$HOME/.nix-profile"
    ];
  };
}
