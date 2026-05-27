#!/bin/bash
set -e

echo "=== Thiết lập KernelSU ==="
cd kernel-5.10
if [ -d "KernelSU" ]; then
    rm -rf KernelSU
fi
curl -LSs https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh | bash
cd ..

echo "=== Đảm bảo thư mục đích tồn tại ==="
mkdir -p kernel-5.10/fs
mkdir -p kernel-5.10/include/linux

echo "=== Copy file SUSFS từ local patches ==="
cp patches/susfs4ksu/kernel_patches/fs/* kernel-5.10/fs/ 2>/dev/null || true
cp patches/susfs4ksu/kernel_patches/include/linux/* kernel-5.10/include/linux/ 2>/dev/null || true

echo "=== Tải các bản vá sửa lỗi từ WildKernels ==="
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_base.c.patch -O fix_base.c.patch
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_exec.c.patch -O fix_exec.c.patch
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_namespace.c.patch -O fix_namespace.c.patch

echo "=== Áp dụng các bản vá sửa lỗi của Samsung TRƯỚC ==="
cd kernel-5.10
patch -p1 --forward < ../fix_base.c.patch || echo "Cảnh báo: fix_base.c thất bại"
patch -p1 --forward < ../fix_exec.c.patch || echo "Cảnh báo: fix_exec.c thất bại"
patch -p1 --forward < ../fix_namespace.c.patch || echo "Cảnh báo: fix_namespace.c thất bại"
cd ..

echo "=== Áp dụng SUSFS patch cho kernel ==="
cd kernel-5.10
patch -p1 --forward < ../patches/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch || echo "Cảnh báo: một số hunks thất bại"
cd ..

echo "=== Sửa lỗi vá tự động ==="
./scripts/fix_susfs_rejections.sh

echo "=== Áp dụng SUSFS patch cho KernelSU ==="
cd kernel-5.10/KernelSU
patch -p1 --forward < ../../patches/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch || echo "Cảnh báo: một số hunks thất bại"
cd ../../..

rm -f fix_base.c.patch fix_exec.c.patch fix_namespace.c.patch

echo "=== Tích hợp SUSFS hoàn tất! ==="
