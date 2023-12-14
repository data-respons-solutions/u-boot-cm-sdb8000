# README

## Build container
```
# Build container for current user
docker build -t u-boot-sdb8000:$(id -un) --build-arg "USERNAME=$(id -un)" --build-arg "UID=$(id -u)" --build-arg "GID=$(id -g)" - < build.docker

# Enter the container as current user
docker run -it -v $(pwd):/usr/src/u-boot-cm -w /usr/src/u-boot-cm -t u-boot-sdb8000:$(id -un)
```

## Build
```
# Init submodules
git submodule update --init --recursive

# Build (from build container)
make

# Artifacts in build/bin
```

## SDP boot
```
# Not from build container
# Install tool
sudo apt install imx-usb-loader
# Connect sdb8000 usb A port to host, i.e USB A male-to-male.
sudo imx_usb -c .
```
