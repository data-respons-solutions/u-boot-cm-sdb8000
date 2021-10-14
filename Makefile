GTAG := android-$(shell git describe --always --tags --long --dirty)

CROSS_COMPILE ?= aarch64-linux-gnu-

BUILD_DIR ?= build
DL_DIR ?= downloads

FIRMWARE_IMX_BUILD = $(BUILD_DIR)/firmware-imx
FIRMWARE_IMX_DL_DIR = $(DL_DIR)/firmware-imx
FIRMWARE_IMX_BIN = firmware-imx-8.8.bin
FIRMWARE_IMX_URL = https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/$(FIRMWARE_IMX_BIN)
FIRMWARE_IMX_DIR = $(FIRMWARE_IMX_BUILD)/firmware-imx-8.8/firmware/ddr/synopsys
FIRMWARE_IMX_LPDDR4 = $(FIRMWARE_IMX_DIR)/lpddr4_pmu_train_1d_imem.bin
FIRMWARE_IMX_LPDDR4 += $(FIRMWARE_IMX_DIR)/lpddr4_pmu_train_1d_dmem.bin
FIRMWARE_IMX_LPDDR4 += $(FIRMWARE_IMX_DIR)/lpddr4_pmu_train_2d_imem.bin
FIRMWARE_IMX_LPDDR4 += $(FIRMWARE_IMX_DIR)/lpddr4_pmu_train_2d_dmem.bin

ATF_BIN = atf/build/imx8mm/release/bl31.bin

OPTEE_BUILD = $(BUILD_DIR)/optee-os
OPTEE_BIN = $(OPTEE_BUILD)/core/tee-pager_v2.bin

U_BOOT_BUILD ?= $(BUILD_DIR)/u-boot
U_BOOT_SPL = u-boot-spl.bin
U_BOOT_SPL_PATH = $(U_BOOT_BUILD)/spl/$(U_BOOT_SPL)
U_BOOT = u-boot-nodtb.bin
U_BOOT_PATH = $(U_BOOT_BUILD)/$(U_BOOT)
U_BOOT_DTB = sdb8000.dtb
U_BOOT_DTB_PATH = $(U_BOOT_BUILD)/arch/arm/dts/$(U_BOOT_DTB)
U_BOOT_MKIMAGE_PATH = $(U_BOOT_BUILD)/tools/mkimage

IMX_MKIMAGE_BUILD = $(BUILD_DIR)/imx-mkimage
IMX_MKIMAGE8 = $(IMX_MKIMAGE_BUILD)/iMX8M/mkimage_imx8

IMAGE_BUILD = $(IMX_MKIMAGE_BUILD)/iMX8M
IMAGE_SPL = $(IMAGE_BUILD)/spl.img
IMAGE_U_BOOT = $(IMAGE_BUILD)/u-boot.itb

ARTIFACT_BUILD = $(BUILD_DIR)/bin
ARTIFACT_SPL = $(ARTIFACT_BUILD)/spl-$(GTAG).img
ARTIFACT_U_BOOT = $(ARTIFACT_BUILD)/u-boot-$(GTAG).itb

all: image
.PHONY: all

firmware: $(FIRMWARE_IMX_DIR)
.PHONY: firmware

u-boot:
	echo "-$(GTAG)" > u-boot/.scmversion
	make -C u-boot ARCH=arm KBUILD_OUTPUT=$(abspath $(U_BOOT_BUILD)) CROSS_COMPILE=$(CROSS_COMPILE) sdb8000_android_defconfig
	make -C u-boot ARCH=arm KBUILD_OUTPUT=$(abspath $(U_BOOT_BUILD)) CROSS_COMPILE=$(CROSS_COMPILE)
.PHONY: u-boot
	
image: $(ARTIFACT_SPL) $(ARTIFACT_U_BOOT)
.PHONY: image

atf:
	make -C atf PLAT=imx8mm IMX_BOOT_UART_BASE=0x30a60000 CROSS_COMPILE=$(CROSS_COMPILE) SPD=opteed bl31
.PHONY: atf

optee:
	make -C optee-os PLATFORM=imx PLATFORM_FLAVOR=mx8mmevk CFG_UART_BASE=0x30a60000 CROSS_COMPILE64=$(CROSS_COMPILE) O=$(abspath $(OPTEE_BUILD))
.PHONE: optee

$(FIRMWARE_IMX_DL_DIR)/$(FIRMWARE_IMX_BIN):
	mkdir -p $(FIRMWARE_IMX_DL_DIR)
	wget -P $(FIRMWARE_IMX_DL_DIR) $(FIRMWARE_IMX_URL)

$(FIRMWARE_IMX_DIR): $(FIRMWARE_IMX_DL_DIR)/$(FIRMWARE_IMX_BIN)
	mkdir -p $(FIRMWARE_IMX_BUILD)
	cp $(FIRMWARE_IMX_DL_DIR)/$(FIRMWARE_IMX_BIN) ${FIRMWARE_IMX_BUILD}
	chmod +x $(FIRMWARE_IMX_BUILD)/$(FIRMWARE_IMX_BIN)
	cd $(FIRMWARE_IMX_BUILD) && ./$(FIRMWARE_IMX_BIN) --auto-accept --force

$(IMX_MKIMAGE_BUILD):
	mkdir -p $(BUILD_DIR)
	cp -r imx-mkimage/. $(IMX_MKIMAGE_BUILD)
	echo "gitdir: ../../.git/modules/imx-mkimage" > $(IMX_MKIMAGE_BUILD)/.git
	
$(IMX_MKIMAGE8): $(IMX_MKIMAGE_BUILD)
	make -C $(IMAGE_BUILD) -f soc.mak SOC=iMX8MM mkimage_imx8
	
$(IMAGE_SPL): $(IMX_MKIMAGE_BUILD) $(IMX_MKIMAGE8) firmware u-boot
	cp -v $(U_BOOT_SPL_PATH) $(IMAGE_BUILD)/
	cp -v $(FIRMWARE_IMX_LPDDR4) $(IMAGE_BUILD)/
	make -C $(IMAGE_BUILD) -f soc.mak SOC=iMX8MM u-boot-spl-ddr.bin
	cd $(IMAGE_BUILD) && ./mkimage_imx8 -version v1 -fit -loader u-boot-spl-ddr.bin 0x7E1000 -out spl.img
	
$(IMAGE_U_BOOT): $(IMX_MKIMAGE_BUILD) u-boot atf optee
	cp -v $(U_BOOT_PATH) $(IMAGE_BUILD)/
	cp -v $(U_BOOT_DTB_PATH) $(IMAGE_BUILD)/
	cp -v $(U_BOOT_MKIMAGE_PATH) $(IMAGE_BUILD)/mkimage_uboot
	cp -v $(ATF_BIN) $(IMAGE_BUILD)/
	cp -v $(OPTEE_BIN) $(IMAGE_BUILD)/tee.bin
	make -C $(IMAGE_BUILD) -f soc.mak SOC=iMX8MM dtbs=$(U_BOOT_DTB) u-boot.itb

$(ARTIFACT_BUILD):
	mkdir -p $(ARTIFACT_BUILD)

$(ARTIFACT_SPL): $(IMAGE_SPL) $(ARTIFACT_BUILD)
	
	cp -v $(IMAGE_SPL) $(ARTIFACT_SPL)

$(ARTIFACT_U_BOOT): $(IMAGE_U_BOOT) $(ARTIFACT_BUILD)
	cp -v $(IMAGE_U_BOOT) $(ARTIFACT_U_BOOT)

clean:
	rm -rf atf/build
	rm -rf $(BUILD_DIR)
.PHONY: clean
