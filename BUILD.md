# Building a webtrees container image

This project uses [Earthly](https://github.com/earthly/earthly) to build and push the container images.

## Build local images

```shell
earthly +docker
```

## Build and push to a remote image repository

```shell
earthly --push +docker
```

## Build a specific version of webtrees

```shell
earthly +docker --VERSION=2.1.15
```
