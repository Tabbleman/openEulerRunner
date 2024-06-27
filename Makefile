# TODO: 
# 检查qemu启动器编译选项
# 在已经安装了某个arch的sys.img之后，如果make另一个会出问题。
# 下载qemu并且直接按照对应编译选项进行安装。（不建议加）
# window的support
HDD_FILE := sys.img
MEMORY := 16G
HDD_SIZE := 50G
NET_PORT := 12059

RISCV_FIRMWARE_CODE="RISCV_VIRT_CODE.fd"
RISCV_FIRMWARE_VARS="RISCV_VIRT_VARS.fd"

ifeq ($(OS),Windows_NT)
  RM = del
else
  RM = rm -rf
endif

X86_IMG="./imgs/openEuler-24.03-LTS-x86_64.qcow2"
AARCH64_IMG="./imgs/openEuler-24.03-LTS-aarch64.qcow2"
RISCV64_IMG="./imgs/openEuler-24.03-LTS-riscv64.qcow2"

prepare_x86:
	@if [ ! -f $(X86_IMG) ]; then \
		echo "fetching file...\n"; \
		wget -P ./imgs/ https://mirror.sjtu.edu.cn/openeuler/openEuler-24.03-LTS/virtual_machine_img/x86_64/openEuler-24.03-LTS-x86_64.qcow2.xz; \
		cd ./imgs/ && unxz openEuler-24.03-LTS-x86_64.qcow2.xz && cd .. \
	else \
		echo "$(X86_IMG) already exists, skipping creation"; \
	fi

prepare_aarch64:
	@if [ ! -f $(AARCH64_IMG) ]; then \
		echo "fetching file...\n"; \
		wget -P ./imgs/ https://mirror.sjtu.edu.cn/openeuler/openEuler-24.03-LTS/virtual_machine_img/aarch64/openEuler-24.03-LTS-aarch64.qcow2.xz; \
		cd ./imgs/ && unxz openEuler-24.03-LTS-aarch64.qcow2.xz && cd .. \
	else \
		echo "$(AARCH64_IMG) already exists, skipping creation"; \
	fi

prepare_riscv64:
	@if [ ! -f $(RISCV64_IMG) ]; then \
		echo "fetching file...\n"; \
		wget -P ./imgs/ https://mirror.sjtu.edu.cn/openeuler/openEuler-24.03-LTS/virtual_machine_img/riscv64/openEuler-24.03-LTS-riscv64.qcow2.xz; \
		cd ./imgs/ && unxz openEuler-24.03-LTS-riscv64.qcow2.xz && cd .. \
	else \
		echo "$(RISCV64_IMG) already exists, skipping creation"; \
	fi

x86: prepare_x86
	$(MAKE) arch_run QEMU=qemu-system-x86_64 ISO_FILE=$(X86_IMG) MACHINE=pc ACCEL=tcg CPU=EPYC BIOS_OPTION=""

aarch64: prepare_aarch64
	$(MAKE) arch_run QEMU=qemu-system-aarch64 ISO_FILE=$(AARCH64_IMG) MACHINE=virt ACCEL=tcg CPU=cortex-a57 BIOS_OPTION="-bios ./QEMU_EFI.fd"

riscv64: prepare_riscv64
	$(MAKE) arch_riscv QEMU=qemu-system-riscv64 ISO_FILE=$(RISCV64_IMG) MACHINE=virt ACCEL=tcg CPU=rv64


help: 
	@echo "Usage: make [x86|aarch64|riscv64]"

all: help
	@echo "please run: Please choose an arch, e.g. : make x86"

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

arch_riscv: check_hdd
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

clean:
	rm -rf ./*.img

.PHONY: all run clean help x86 aarch64 riscv64 arch_run