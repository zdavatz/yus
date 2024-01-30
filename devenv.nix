{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.git pkgs.libyaml ];

  enterShell = ''
    echo This is the devenv shell for oddb2xml
    git --version
    ruby --version
    psql --version
  '';

  # env.FREEDESKTOP_MIME_TYPES_PATH = "${pkgs.shared-mime-info}/share/mime/packages/freedesktop.org.xml";

  # https://devenv.sh/languages/
  # languages.nix.enable = true;

  languages.ruby.enable = true;
  languages.ruby.versionFile = ./.ruby-version;
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
    listen_addresses = "0.0.0.0";
    port = 5435;

    initialDatabases = [
      { name = "yus"; }
    ];

    initdbArgs =
      [
        "--locale=C"
        "--encoding=UTF8"
      ];

    initialScript = ''
      create role yus superuser login password null;
      \connect yus;
      \i 22:20-postgresql_database-yus-backup
    '';
  };
  # See full reference at https://devenv.sh/reference/options/
}
