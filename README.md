# README

## Build container
```
# Build container for current user
docker build -t u-boot-sdb8000:$(id -un) --build-arg "USERNAME=$(id -un)" --build-arg "UID=$(id -u)" --build-arg "GID=$(id -g)" - < build.docker

# Enter the container as current user
docker run -it -v $(pwd):/usr/src/u-boot-cm -w /usr/src/u-boot-cm -t u-boot-sdb8000:$(id -un)
```

## Dependencies
### optee-os
- python3-pyelftools
- python3-pycryptodome
