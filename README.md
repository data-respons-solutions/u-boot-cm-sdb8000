# README
## Notes
- Increase DR BSP uboot section size from 1.3 to 1.5MB (binary including optee is 1.2 MB)

## Build container
```
# Build container for current user
docker build -t u-boot:$(id -un) --build-arg "USERNAME=$(id -un)" --build-arg "UID=$(id -u)" --build-arg "GID=$(id -g)" - < build.docker

# Enter the container as current user
docker run -it -v $(pwd):/usr/src/u-boot-cm -w /usr/src/u-boot-cm -t u-boot:$(id -un)
```

## Dependencies
### optee-os
- python3-pyelftools
	
## TODO
- Pass main repo git rev to uboot LOCALVERSION?

## Write
### SD card
```
sudo dd if=build/imx-mkimage/iMX8M/spl.img of=/dev/sdX bs=1024 seek=33
sudo dd if=build/imx-mkimage/iMX8M/u-boot.itb of=/dev/sdX bs=1024 seek=384
```