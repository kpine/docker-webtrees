# Building a webtrees container image

This project uses a [Nix flake](https://nixos.wiki/wiki/Flakes) to build the container image.

## Build a local image

```shell
nix build .#docker
./result | docker load
```

The image is tagged `ghcr.io/kpine/caddy-webtrees:<version>`.

## Push to the GitHub Container Registry

```shell
docker push ghcr.io/kpine/caddy-webtrees:2.2.6
```

## Build a different version of webtrees

The webtrees and fan chart module versions are set in `flake.nix`, alongside the
hashes of their release archives. To change a version, update `version` (or
`fanchartVersion`) and the matching `hash`. Get the new hash with:

```shell
nix store prefetch-file --unpack https://github.com/fisharebest/webtrees/releases/download/<version>/webtrees-<version>.zip
```

## Validate the Caddyfile

```shell
nix flake check
```

## Update PHP and Caddy

PHP and Caddy come from nixpkgs. Update them with:

```shell
nix flake update
```

If the Caddy version changes, the `hash` for `caddy.withPlugins` must be updated too;
the build fails and prints the expected value.
