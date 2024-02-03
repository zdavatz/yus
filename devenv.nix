# Please look at the file [oddb.org/devenv.README.md](https://github.com/zdavatz/oddb.org/blob/ruby-3.2/devenv.README.md)
{ pkgs, ... }:

{
  env.GREET = "devenv";
  packages = [ pkgs.git pkgs.libyaml ]; #  after I added pkgs.openssl here, I could no longer call devenup because of a glibc mismatch
  # therefore I ${pkgs.openssl}/bin/openssl in the enterShell

  enterShell = ''
    echo This is the devenv shell for oddb2xml
    git --version
    ruby --version
    psql --version
    OLD_YUS_CRT=`git status --porcelain data;`
    if [[ -z $OLD_YUS_CRT ]]; then
      echo Must replace old yus certificat from 2006
      cd data
      pwd
      ${pkgs.openssl}/bin/openssl req -nodes -new -x509 -key yus.key -out yus.crt -subj "/C=CH/ST=Zurich/L=Zurich/O=ywesee GmbH/OU=IT Department CI/CN=ywesee.com"
    else
      echo Found changed data/yus.key
    fi
    bundle install
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
