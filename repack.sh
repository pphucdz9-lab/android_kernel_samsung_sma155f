#!/bin/bash
# Giải nén boot.img.lz4 nếu cần
if [ -f boot.img.lz4 ]; then
    lz4 -d boot.img.lz4 boot.img
fi
# Tạo workspace
mkdir -p workspace
cd workspace
# Unpack boot.img
../scripts/bin/magiskboot unpack ../boot.img
# Thay kernel (giải nén Image.gz nếu cần)
if [ -f ../out/target/product/a15/obj/KERNEL_OBJ/kernel-5.10/arch/arm64/boot/Image.gz ]; then
    gunzip -c ../out/target/product/a15/obj/KERNEL_OBJ/kernel-5.10/arch/arm64/boot/Image.gz > kernel
else
    cp ../out/target/product/a15/obj/KERNEL_OBJ/kernel-5.10/arch/arm64/boot/Image kernel
fi
# Repack
../scripts/bin/magiskboot repack ../boot.img new-boot.img
cd ..
cp workspace/new-boot.img boot-repacked.img
echo "Done! Output: boot-repacked.img"
