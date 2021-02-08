SRC_VERSION := $(shell git describe --dirty --always --tags)

CROSS_COMPILE ?= aarch64-linux-gnu-

ATF ?= bl31.bin
ATF_PATH ?= ./imx-atf/build/imx8mm/release/$(ATF)

BUILD_DIR ?= build
FIRMWARE_IMX_VERSION ?= 8.8
FIRMWARE_IMX_NAME ?= firmware-imx-$(FIRMWARE_IMX_VERSION)
FIRMWARE_IMX_URL ?= https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/$(FIRMWARE_IMX_NAME).bin
FIRMWARE_IMX_BUILD ?= $(BUILD_DIR)/firmware-imx
U_BOOT_BUILD ?= $(BUILD_DIR)/u-boot
U_BOOT_SPL ?= u-boot-spl.bin
U_BOOT_SPL_PATH ?= $(U_BOOT_BUILD)/spl/$(U_BOOT_SPL)
U_BOOT ?= u-boot-nodtb.bin
U_BOOT_PATH ?= $(U_BOOT_BUILD)/$(U_BOOT)
U_BOOT_DTB ?= imx8mm-evk.dtb
U_BOOT_DTB_PATH ?= $(U_BOOT_BUILD)/arch/arm/dts/$(U_BOOT_DTB)
U_BOOT_MKIMAGE ?= mkimage
U_BOOT_MKIMAGE_PATH ?= $(U_BOOT_BUILD)/tools/$(U_BOOT_MKIMAGE)
IMAGE_BUILD ?= $(BUILD_DIR)/imx-mkimage
IMX8_FLASH_PATH ?= $(IMAGE_BUILD)/sdp-spl.bin $(IMAGE_BUILD)/u-boot.itb

all: $(IMX8_FLASH_PATH)
.PHONY: all

$(U_BOOT_PATH): uboot-imx-dr force
	make ARCH=arm KBUILD_OUTPUT=$(abspath $(U_BOOT_BUILD)) CROSS_COMPILE=$(CROSS_COMPILE) -C uboot-imx-dr imx8mm_evk_defconfig
	make ARCH=arm KBUILD_OUTPUT=$(abspath $(U_BOOT_BUILD)) CROSS_COMPILE=$(CROSS_COMPILE) -C uboot-imx-dr

force:
	true
	
$(U_BOOT_SPL_PATH) $(U_BOOT_DTB_PATH) $(U_BOOT_MKIMAGE_PATH): $(U_BOOT_PATH) ;

$(FIRMWARE_IMX_NAME):
	mkdir -p $(FIRMWARE_IMX_BUILD)
	cd $(FIRMWARE_IMX_BUILD) && \
	wget $(FIRMWARE_IMX_URL) && \
	chmod +x $(FIRMWARE_IMX_NAME).bin && \
	./$(FIRMWARE_IMX_NAME).bin --auto-accept --force
	
$(ATF_PATH):
	make PLAT=imx8mm CROSS_COMPILE=$(CROSS_COMPILE) bl31 -C imx-atf
	
$(IMX8_FLASH_PATH): $(U_BOOT_PATH) $(U_BOOT_SPL_PATH) $(U_BOOT_DTB_PATH) $(U_BOT_MKIMAGE_PATH) $(ATF_PATH) $(FIRMWARE_IMX_NAME)
	cp -r imx-mkimage/. $(IMAGE_BUILD)/
	echo "gitdir: ../../.git/modules/imx-mkimage" > $(IMAGE_BUILD)/.git
	cp -v $(U_BOOT_PATH) $(IMAGE_BUILD)/iMX8M/
	cp $(U_BOOT_SPL_PATH) $(IMAGE_BUILD)/iMX8M/
	cp $(U_BOOT_DTB_PATH) $(IMAGE_BUILD)/iMX8M/
	cp $(U_BOOT_MKIMAGE_PATH) $(IMAGE_BUILD)/iMX8M/mkimage_uboot
	cp $(ATF_PATH) $(IMAGE_BUILD)/iMX8M/
	cp $(FIRMWARE_IMX_BUILD)/$(FIRMWARE_IMX_NAME)/firmware/ddr/synopsys/lpddr4_pmu_train_* $(IMAGE_BUILD)/iMX8M/
	make -C $(IMAGE_BUILD) SOC=iMX8MM dtbs=$(U_BOOT_DTB) flash_evk
	cd $(IMAGE_BUILD)/iMX8M && ./mkimage_imx8 -version v1 -fit -loader u-boot-spl-ddr.bin 0x7E1000 -out sdp-spl.bin

.PHONY: clean
clean:
	make -C imx-atf clean
	rm -rf $(BUILD_DIR)
	rm -rf mkimage_imx8
