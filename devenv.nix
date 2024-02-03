# Please look at the file [oddb.org/devenv.README.md](https://github.com/zdavatz/oddb.org/blob/ruby-3.2/devenv.README.md)
{ pkgs, ... }:

{

  packages = [ pkgs.git pkgs.libyaml ];

  enterShell = ''
    echo This is the devenv shell for oddb2xml
    git --version
    ruby --version
    psql --version
  '';

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
      \i ../22:20-postgresql_database-yus-backup
    '';
  };
}
