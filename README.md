# README
## Notes
- Increase DR BSP uboot section size from 1.3 to 1.5MB (binary including optee is 1.2 MB)

## Dependencies
### optee-os
- python3-pyelftools
	
## TODO
- Rename sdp-spl.bin to spl.img?
- Pass main repo git rev to uboot LOCALVERSION?

## Write
### SD card
```
sudo dd if=build/imx-mkimage/iMX8M/sdp-spl.bin of=/dev/sdX bs=1024 seek=33
sudo dd if=build/imx-mkimage/iMX8M/u-boot.itb of=/dev/sdX bs=1024 seek=384
```