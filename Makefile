# global files, config
HDD_FILE := sys.img
MEMORY := 2048M
HDD_SIZE := 1G
# RNG := /dev/urandom
NET_PORT := 12058
# ref: https://mirrors.nju.edu.cn/openeuler/openEuler-24.03-LTS/virtual_machine_img/riscv64/start_vm.sh
RISCV_FIRMWARE_CODE="RISCV_VIRT_CODE.fd"
RISCV_FIRMWARE_VARS="RISCV_VIRT_VARS.fd"
RISCV_SPECIFIC=
# detect platform for clean tool.
# TODO: add window support.
ifeq ($(OS),Windows_NT)
  # on Windows
  RM = del
else
  # on Unix/Linux
  RM = rm -rf
endif

# different images
X86_IMG="./imgs/openEuler-24.03-LTS-x86_64.qcow2"
AARCH64_IMG="./imgs/openEuler-24.03-LTS-aarch64.qcow2"
RISCV64_IMG="./imgs/openEuler-24.03-LTS-riscv64.qcow2"

# detect which platform 
prepare_x86:
	@if [ ! -f $(X86_IMG) ]; then \
		echo "fetching file..." \
	else \
		echo "$(X86_IMG) already exists, skipping creation"; \
	fi
x86: prepare_x86
	$(MAKE) arch_run QEMU=qemu-system-x86_64 ISO_FILE=./imgs/openEuler-24.03-LTS-x86_64.qcow2 MACHINE=pc ACCEL=kvm CPU=host BIOS_OPTION=""

prepare_aarch64:
	@echo "TODO"

aarch64: prepare_aarch64
	$(MAKE) arch_run QEMU=qemu-system-aarch64 ISO_FILE=./imgs/openEuler-24.03-LTS-aarch64.qcow2 MACHINE=virt ACCEL=tcg CPU=cortex-a57 BIOS_OPTION="-bios ./QEMU_EFI.fd"

prepare_riscv64:
	@echo "TODO"

riscv64: prepare_riscv64
	$(MAKE) res QEMU=qemu-system-riscv64 ISO_FILE=./imgs/openEuler-24.03-LTS-riscv64.qcow2 MACHINE=virt ACCEL=tcg CPU=rv64 

.PHONY: all run clean help x86 aarch64 riscv64 arch_run

help: 
	@echo "Usage: make [x86|aarch64|riscv64]"

all: help
	@echo "please run: Please choose an arch, e.g. : make x86"

# create hard disk.
$(HDD_FILE):
	@if [ ! -f $(HDD_FILE) ]; then \
		qemu-img create $(HDD_FILE) $(HDD_SIZE); \
	else \
		echo "$(HDD_FILE) already exists, skipping creation"; \
	fi

check_hdd:
	@if [ ! -f $(HDD_FILE) ] || [ $$(hexdump -n 2 -e '2/1 "%02x"' $(HDD_FILE)) = "0000" ]; then \
		echo "HDD_FILE not exists or operating system not installed. Installing operating system..."; \
		dd if=$(ISO_FILE) of=$(HDD_FILE); \
	else \
		echo "Booting operating system"; \
	fi

boot_exists: check_hdd
	sudo $(QEMU) \
		-nographic -M pc -accel $(ACCEL) \
		-cpu host \
		-smp 8 -m 8G \
		-drive file="$(HDD_FILE)",format=qcow2,id=hd0,if=none \
		-device virtio-vga \
		-device virtio-blk,drive=hd0 \
		-device virtio-net,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::$(NET_PORT)-:22 \
		-device qemu-xhci -usb -device usb-kbd -device usb-tablet \
		-device virtio-rng \
		-drive if=pflash,format=raw

# ref https://wiki.debian.org/Arm64Qemu
arch_run: check_hdd
	sudo $(QEMU) \
		-nographic -M $(MACHINE) \
		-accel $(ACCEL) \
		-cpu $(CPU) \
		-smp 8 -m 8G \
		-drive file="$(HDD_FILE)",format=qcow2,id=hd0,if=none \
		-device virtio-gpu \
		-device virtio-blk,drive=hd0 \
		-device virtio-net,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::$(NET_PORT)-:22 \
		-device qemu-xhci -usb -device usb-kbd -device usb-tablet \
		$(BIOS_OPTION) \
		-device virtio-rng 


# TODO: merge with upper target
res: check_hdd
	sudo $(QEMU) \
		-nographic -M virt,pflash0=pflash0,pflash1=pflash1,acpi=off \
		-accel $(ACCEL) \
		-cpu $(CPU) \
		-smp 8 -m 8G \
		-drive file="$(HDD_FILE)",format=qcow2,id=hd0,if=none \
		-device virtio-gpu \
		-device virtio-net,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::$(NET_PORT)-:22 \
		-device qemu-xhci -usb -device usb-kbd -device usb-tablet \
		$(BIOS_OPTION) \
		-device virtio-rng \
		-blockdev node-name=pflash0,driver=file,read-only=on,filename=$(RISCV_FIRMWARE_CODE) \
		-blockdev node-name=pflash1,driver=file,filename=$(RISCV_FIRMWARE_VARS) \
		-object memory-backend-ram,size=4G,id=ram1 \
		-numa node,memdev=ram1 \
		-object memory-backend-ram,size=4G,id=ram2 \
		-numa node,memdev=ram2 \
		-device virtio-blk-device,drive=hd0,bootindex=1 
		
# Clean up the virtual hard disk
clean:
	@$(RM) *.img
