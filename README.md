# README

## Notes on generating stand-alone spl and fit image for SDP
```
cd imx-mkimage/iMX8M

# spl
./mkimage_imx8 -version v1 -fit -loader u-boot-spl-ddr.bin 0x7E1000 -out spl.bin

# u-boot,atf,dtb fit
./mkimage_imx8 -version v1 -fit -loader u-boot.itb 0x40200000 -out u-boot-itb.bin
```