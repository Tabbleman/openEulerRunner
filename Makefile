# global files, config
HDD_FILE := sys.img
MEMORY := 2048M
HDD_SIZE := 10G
# RNG := /dev/urandom
NET_PORT := 12058

# detect platform for clean tool.
ifeq ($(OS),Windows_NT)
  # on Windows
  RM = del
else
  # on Unix/Linux
  RM = rm -rf
endif

# detect which platform 
x86:
	$(MAKE) arch_run QEMU=qemu-system-x86_64 ISO_FILE=./imgs/openEuler-24.03-LTS-x86_64.qcow2 MACHINE=pc ACCEL=kvm CPU=host BIOS_OPTION=""

aarch64: 
	$(MAKE) arch_run QEMU=qemu-system-aarch64 ISO_FILE=./imgs/openEuler-24.03-LTS-aarch64.qcow2 MACHINE=virt ACCEL=tcg CPU=cortex-a57 BIOS_OPTION="-bios ./QEMU_EFI.fd"

riscv64:
	$(MAKE) arch_run QEMU=qemu-system-riscv64 ISO_FILE=./imgs/openEuler-24.03-LTS-riscv64.qcow2 MACHINE=virt ACCEL=tcg CPU=rv64 BIOS_OPTION=""

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
		-netdev user,id=usernet,hostfwd=tcp::12057-:22 \
		-device qemu-xhci -usb -device usb-kbd -device usb-tablet \
		-device virtio-rng \
		-drive if=pflash,format=raw,file=OVMF.fd

# ref https://wiki.debian.org/Arm64Qemu
arch_run: check_hdd
	sudo $(QEMU) \
		-nographic -M $(MACHINE) -accel $(ACCEL) \
		-cpu $(CPU) \
		-smp 8 -m 8G \
		-drive file="$(HDD_FILE)",format=qcow2,id=hd0,if=none \
		-device virtio-gpu \
		-device virtio-blk,drive=hd0 \
		-device virtio-net,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::12057-:22 \
		-device qemu-xhci -usb -device usb-kbd -device usb-tablet \
		$(BIOS_OPTION) \
		-device virtio-rng 

# 	-bios ./QEMU_EFI.fd \

# Clean up the virtual hard disk
clean:
	$(RM) $(HDD_FILE)
