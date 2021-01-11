SRC_VERSION := $(shell git describe --dirty --always --tags)

CROSS_COMPILE ?= aarch64-linux-gnu-

FIRMWARE_IMX_VERSION ?= 8.9
FIRMWARE_IMX_NAME ?= firmware-imx-$(FIRMWARE_IMX_VERSION)
FIRMWARE_IMX_URL ?= https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/$(FIRMWARE_IMX_NAME).bin

ATF ?= bl31.bin
ATF_PATH ?= ./imx-atf/build/fvp/release/$(ATF)

U_BOOT_BUILD ?= ./u-boot-build
U_BOOT_SPL ?= u-boot-spl.bin
U_BOOT_SPL_PATH ?= $(U_BOOT_BUILD)/spl/$(U_BOOT_SPL)
U_BOOT ?= u-boot-nodtb.bin
U_BOOT_PATH ?= $(U_BOOT_BUILD)/$(U_BOOT)
U_BOOT_DTB ?= imx8mm-evk.dtb
U_BOOT_DTB_PATH ?= $(U_BOOT_BUILD)/arch/arm/dts/$(U_BOOT_DTB)
U_BOOT_MKIMAGE ?= mkimage
U_BOOT_MKIMAGE_PATH ?= $(U_BOOT_BUILD)/tools/$(U_BOOT_MKIMAGE)
IMX8_FLASH_PATH ?= imx-mkimage/iMX8M/flash.bin

all: $(IMX8_FLASH_PATH)
.PHONY: all

$(U_BOOT_PATH):
	make KBUILD_OUTPUT=$(abspath $(U_BOOT_BUILD)) CROSS_COMPILE=$(CROSS_COMPILE) -C u-boot imx8mm_evk_defconfig
	make KBUILD_OUTPUT=$(abspath $(U_BOOT_BUILD)) CROSS_COMPILE=$(CROSS_COMPILE) -C u-boot

$(U_BOOT_SPL_PATH) $(U_BOOT_DTB_PATH) $(U_BOOT_MKIMAGE_PATH): $(U_BOOT_PATH) ;

$(FIRMWARE_IMX_NAME):
	wget $(FIRMWARE_IMX_URL)
	chmod +x $(FIRMWARE_IMX_NAME).bin
	./$(FIRMWARE_IMX_NAME).bin --auto-accept --force
	
$(ATF_PATH):
	make CROSS_COMPILE=$(CROSS_COMPILE) -C imx-atf
	
$(IMX8_FLASH_PATH): $(U_BOOT_PATH) $(U_BOOT_SPL_PATH) $(U_BOOT_DTB_PATH) $(U_BOT_MKIMAGE_PATH) $(ATF_PATH) $(FIRMWARE_IMX_NAME)
	cp $(U_BOOT_PATH) imx-mkimage/iMX8M/
	cp $(U_BOOT_SPL_PATH) imx-mkimage/iMX8M/
	cp $(U_BOOT_DTB_PATH) imx-mkimage/iMX8M/
	cp $(U_BOOT_MKIMAGE_PATH) imx-mkimage/iMX8M/mkimage_uboot
	cp $(ATF_PATH) imx-mkimage/iMX8M/
	cp $(FIRMWARE_IMX_NAME)/firmware/ddr/synopsys/lpddr4_pmu_train_* imx-mkimage/iMX8M/
	make -C imx-mkimage SOC=iMX8MM flash_evk

.PHONY: clean
clean:
	rm -f $(FIRMWARE_IMX_NAME).bin
	rm -rf $(FIRMWARE_IMX_NAME)
	rm -rf $(U_BOOT_BUILD)
	make -C imx-atf clean
	rm -f imx-mkimage/iMX8M/$(U_BOOT) 
	rm -f imx-mkimage/iMX8M/$(U_BOOT_SPL)
	rm -f imx-mkimage/iMX8M/$(U_BOOT_DTB)
	rm -f imx-mkimage/iMX8M/mkimage_uboot
	rm -f imx-mkimage/iMX8M/$(ATF)
	rm -f imx-mkimage/iMX8M/lpddr4_pmu_train_*
	make -C imx-mkimage clean
	rm -f mkimage_imx8
