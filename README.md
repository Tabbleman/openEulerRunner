# openEulerRunner
openEuler qemu的自动化工作流

## 进度
- [x] x86下的自动化
- [x] aarch64下面的自动化
- [x] riscv64下面的自动化
- [x] 下载镜像
- [ ] 查看是否现有qemu以及支持的选项

## 使用手册：

```bash
make riscv64 # boot a riscv openeuler 2404
make x86 # boot a x86 openeuler 2404
make aarch64 # boot a arm openeuler 2404
# notice: you should make sure `make clean` everytime when you have a image installed but you want boot another arch.
```


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


从qemu官网下载源码直接编译：
```shell
wget https://download.qemu.org/qemu-9.0.1.tar.xz
tar xf qemu-9.0.1.tar.xz
cd qemu-9.0.1
make -j
sudo make install
```

如果你已经在对应的文件夹里面有那么你可以使用`make help`查看指北。
```shell
make clean && make x86 # or [aarch64|riscv64]

```
