{
  pkgs ? import <nixpkgs> { },
}:
let
  imageName = "zot.bealv.io/public/action-runner-nix";
  entrypoint = pkgs.writeShellScriptBin "entrypoint.sh" ''
    #!/bin/sh
    sudo nix-daemon &
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
  fakeRootCommands = ''
    mkdir -p home/runner tmp nix
    chown 1001:1001 -R home/runner
    chmod 777 -R tmp
    chown -R 1001:1001 nix
    chown 0:0 usr/bin/sudo && chmod 4755 usr/bin/sudo
  '';
  extraCommands = ''
    mkdir -p usr/bin
    cp -L ${pkgs.sudo}/bin/sudo usr/bin
  '';

  contents = with pkgs; [
    (pkgs.dockerTools.fakeNss.override {
      extraPasswdLines = [
        "runner:x:1001:1001:Build user:/home/runner:/bin/bash"
        "nixbld1:x:30001:30001:Nix build user 1:/var/empty:/sbin/nologin"
        "nixbld2:x:30002:30002:Nix build user 2:/var/empty:/sbin/nologin"
        "nixbld3:x:30003:30003:Nix build user 3:/var/empty:/sbin/nologin"
        "nixbld4:x:30004:30004:Nix build user 4:/var/empty:/sbin/nologin"
        "nixbld5:x:30005:30005:Nix build user 5:/var/empty:/sbin/nologin"
        "nixbld6:x:30006:30006:Nix build user 6:/var/empty:/sbin/nologin"
        "nixbld7:x:30007:30007:Nix build user 7:/var/empty:/sbin/nologin"
        "nixbld8:x:30008:30008:Nix build user 8:/var/empty:/sbin/nologin"
        "nixbld9:x:30009:30009:Nix build user 9:/var/empty:/sbin/nologin"
        "nixbld10:x:30010:30010:Nix build user 10:/var/empty:/sbin/nologin"
        "nixbld11:x:30011:30011:Nix build user 11:/var/empty:/sbin/nologin"
        "nixbld12:x:30012:30012:Nix build user 12:/var/empty:/sbin/nologin"
        "nixbld13:x:30013:30013:Nix build user 13:/var/empty:/sbin/nologin"
        "nixbld14:x:30014:30014:Nix build user 14:/var/empty:/sbin/nologin"
        "nixbld15:x:30015:30015:Nix build user 15:/var/empty:/sbin/nologin"
        "nixbld16:x:30016:30016:Nix build user 16:/var/empty:/sbin/nologin"
        "nixbld17:x:30017:30017:Nix build user 17:/var/empty:/sbin/nologin"
        "nixbld18:x:30018:30018:Nix build user 18:/var/empty:/sbin/nologin"
        "nixbld19:x:30019:30019:Nix build user 19:/var/empty:/sbin/nologin"
        "nixbld20:x:30020:30020:Nix build user 20:/var/empty:/sbin/nologin"
        "nixbld21:x:30021:30021:Nix build user 21:/var/empty:/sbin/nologin"
        "nixbld22:x:30022:30022:Nix build user 22:/var/empty:/sbin/nologin"
        "nixbld23:x:30023:30023:Nix build user 23:/var/empty:/sbin/nologin"
        "nixbld24:x:30024:30024:Nix build user 24:/var/empty:/sbin/nologin"
        "nixbld25:x:30025:30025:Nix build user 25:/var/empty:/sbin/nologin"
        "nixbld26:x:30026:30026:Nix build user 26:/var/empty:/sbin/nologin"
        "nixbld27:x:30027:30027:Nix build user 27:/var/empty:/sbin/nologin"
        "nixbld28:x:30028:30028:Nix build user 28:/var/empty:/sbin/nologin"
        "nixbld29:x:30029:30029:Nix build user 29:/var/empty:/sbin/nologin"
        "nixbld30:x:30030:30030:Nix build user 30:/var/empty:/sbin/nologin"
      ];
      extraGroupLines = [
        "runner:!:1001:"
        "nixbld:!:30000:nixbld1,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld30"
      ];
    })
    (pkgs.writeTextDir "etc/nix/nix.conf" ''
      experimental-features = nix-command flakes
    '')
    (pkgs.writeTextDir "etc/sudoers" ''
      root     ALL=(ALL:ALL)    SETENV: ALL
      %wheel  ALL=(ALL:ALL)    NOPASSWD:SETENV: ALL
      runner ALL=(ALL) NOPASSWD:ALL
      Defaults:root,%wheel env_keep+=TERMINFO_DIRS
      Defaults:root,%wheel env_keep+=TERMINFO
    '')
    (pkgs.runCommand "config-sudo" { } ''
      mkdir -p $out/etc/pam.d/backup
      cat > $out/etc/pam.d/sudo <<EOF
      #%PAM-1.0
      auth        sufficient  pam_rootok.so
      auth        sufficient  pam_permit.so
      account     sufficient  pam_permit.so
      account     required    pam_warn.so
      session     required    pam_permit.so
      password    sufficient  pam_permit.so
      EOF
      cat > $out/etc/pam.d/su <<EOF
      #%PAM-1.0
      auth        sufficient  pam_rootok.so
      auth        sufficient  pam_permit.so
      account     sufficient  pam_permit.so
      account     required    pam_warn.so
      session     required    pam_permit.so
      password    sufficient  pam_permit.so
      EOF
      cat > $out/etc/pam.d/system-auth <<EOF
      #%PAM-1.0
      auth        required      pam_env.so
      auth        sufficient    pam_rootok.so
      auth        sufficient    pam_permit.so
      auth        sufficient    pam_unix.so try_first_pass nullok
      auth        required      pam_deny.so
      account     sufficient    pam_permit.so
      account     required      pam_unix.so
      password    sufficient    pam_permit.so
      password    required      pam_unix.so
      session     required      pam_unix.so
      session     optional      pam_permit.so
      EOF
      cat > $out/etc/pam.d/login <<EOF
      #%PAM-1.0
      auth        required      pam_env.so
      auth        sufficient    pam_rootok.so
      auth        sufficient    pam_permit.so
      auth        sufficient    pam_unix.so try_first_pass nullok
      auth        required      pam_deny.so
      account     sufficient    pam_permit.so
      account     required      pam_unix.so
      password    sufficient    pam_permit.so
      password    required      pam_unix.so
      session     required      pam_unix.so
      session     optional      pam_permit.so
      EOF
      cat >> $out/etc/sudoers <<EOF
      root     ALL=(ALL:ALL)    NOPASSWD:SETENV: ALL
      %wheel  ALL=(ALL:ALL)    NOPASSWD:SETENV: ALL
      EOF
    '')
    lix
    coreutils
    bashInteractive
    dockerTools.binSh
    dockerTools.usrBinEnv
    dockerTools.caCertificates
    gnugrep
    glibc
    cacert.out
    openssl
    github-runner
    npins
    wget
    curl
    git
    jq
    xz
    gzip
    gawk
    gnutar
    kustomize
    yq-go
    pkgs.kubectl
    entrypoint
  ];
  config = {
    User = "1001:1001";
    EntryPoint = [ "entrypoint.sh" ];
    Env = [
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NIX_REMOTE=daemon"
      "NIX_PATH=nixpkgs=https://releases.nixos.org/nixos/24.11/nixos-24.11.715401.20755fa05115/nixexprs.tar.xz"
    ];
  };
}
