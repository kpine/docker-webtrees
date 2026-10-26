{
  description = "Webtrees online genealogy with Caddy Server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      version = "2.2.6";

      # UID/GID the container runs as; www-data in the earlier Alpine-based images
      uid = "82";

      # Custom version of Caddy with Supervisor plugin
      caddy = pkgs.caddy.withPlugins {
        plugins = [ "github.com/baldinof/caddy-supervisor@v0.7.0" ];
        hash = "sha256-gz7+rL6kef52DBj9LV111azr/nUjGeQo3BdF1rgCHXw=";
      };

      php = pkgs.php85.buildEnv {
        extensions =
          { enabled, all }:
          enabled
          # Required and recommended by webtrees; json, pcre and xml are built into PHP
          ++ (with all; [
            ctype
            curl
            exif
            fileinfo
            gd
            iconv
            intl
            mbstring
            pdo
            pdo_mysql
            session
            zip
            zlib
          ]);
        extraConfig = ''
          ; The webtrees code is fixed in the image, so never check for changed files
          opcache.validate_timestamps = 0

          ; Allow uploading full-size photos (PHP defaults are 2M and 8M)
          upload_max_filesize = 32M
          post_max_size = 64M
        '';
      };

      webtrees = pkgs.stdenvNoCC.mkDerivation {
        pname = "webtrees";
        inherit version;

        src = pkgs.fetchzip {
          url = "https://github.com/fisharebest/webtrees/releases/download/${version}/webtrees-${version}.zip";
          hash = "sha256-9DI86LOADdaEbwR3L/3/xuXvrSL96DYAkNdzpQ7b9OU=";
        };

        installPhase = ''
          cp -r . $out
        '';
      };

      # Convert the flake's last-modified timestamp (YYYYMMDDHHMMSS) to RFC 3339
      created =
        let
          d = self.lastModifiedDate;
          s = start: len: builtins.substring start len d;
        in
        "${s 0 4}-${s 4 2}-${s 6 2}T${s 8 2}:${s 10 2}:${s 12 2}Z";

      docker = pkgs.dockerTools.streamLayeredImage {
        name = "ghcr.io/kpine/caddy-webtrees";
        tag = version;
        inherit created;
        maxLayers = 10;

        contents = [
          pkgs.dockerTools.fakeNss
          pkgs.dockerTools.caCertificates
          pkgs.busybox
          caddy
          php
        ];

        fakeRootCommands = ''
          mkdir -p tmp run srv var/lib/caddy
          chmod 1777 tmp
          chown ${uid}:${uid} run var/lib/caddy

          cp ${./Caddyfile} etc/Caddyfile
          cp ${./php-fpm.conf} etc/php-fpm.conf

          cp -r ${webtrees} srv/webtrees
          chmod -R u+w srv/webtrees
          chown -R ${uid}:${uid} srv/webtrees/data
        '';

        config = {
          User = "${uid}:${uid}";
          Entrypoint = [
            "/bin/caddy"
            "run"
            "--config"
            "/etc/Caddyfile"
          ];
          WorkingDir = "/srv/webtrees";
          Volumes."/srv/webtrees/data" = { };
          ExposedPorts."2015/tcp" = { };
          Env = [
            # Use the default production configuration
            "PHPRC=${php.unwrapped}/etc"
            "HOME=/var/lib/caddy"
          ];
          Labels = {
            "org.opencontainers.image.created" = created;
            "org.opencontainers.image.description" = "Webtrees online genealogy with Caddy Server";
            "org.opencontainers.image.revision" = self.shortRev or self.dirtyShortRev or "unknown";
            "org.opencontainers.image.source" = "https://github.com/kpine/docker-webtrees";
            "org.opencontainers.image.title" = "Webtrees";
            "org.opencontainers.image.version" = version;
          };
        };
      };
    in
    {
      packages.${system} = {
        inherit
          caddy
          php
          webtrees
          docker
          ;
        default = docker;
      };

      checks.${system} = {
        caddyfile = pkgs.runCommand "caddyfile-validate" { nativeBuildInputs = [ caddy ]; } ''
          HOME=$TMPDIR caddy validate --config ${./Caddyfile} --adapter caddyfile
          touch $out
        '';

        php-fpm-conf = pkgs.runCommand "php-fpm-conf-validate" { nativeBuildInputs = [ php ]; } ''
          php-fpm --test --fpm-config ${./php-fpm.conf}
          touch $out
        '';
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
