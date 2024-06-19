# openEulerRunner
openEuler qemu的自动化工作流

## 进度
- [x] x86下的自动化
- [x] aarch64下面的自动化
- [x] riscv64下面的自动化
- [ ] 下载镜像
- [ ] 查看是否现有qemu以及支持的选项

## 使用手册：
理想的项目文件结构是这样的：
```text
.
├── LICENSE
├── Makefile
├── README.md
├── RISCV_VIRT_CODE.fd
├── RISCV_VIRT_VARS.fd
├── imgs
│   ├── openEuler-24.03-LTS-aarch64.qcow2
│   ├── openEuler-24.03-LTS-riscv64.qcow2
│   └── openEuler-24.03-LTS-x86_64.qcow2

```

请确保你的qemu包含kvm的feature。
如果不确定可以从qemu官网下载源码直接编译：
```shell
wget https://download.qemu.org/qemu-9.0.1.tar.xz
tar xf qemu-9.0.1.tar.xz
cd qemu-9.0.1
./configure -enable-kvm 
make -j
sudo make install
```
