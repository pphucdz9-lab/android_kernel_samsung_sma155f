#!/bin/bash
set -e

echo "=== Thiết lập KernelSU Next (nhánh next-susfs, đã có SUSFS) ==="
cd kernel-5.10
if [ -d "KernelSU-Next" ]; then
    rm -rf KernelSU-Next
fi
# Sử dụng nhánh next-susfs từ pershoot – đã tích hợp SUSFS sẵn
curl -LSs https://raw.githubusercontent.com/pershoot/KernelSU-Next/next-susfs/kernel/setup.sh | bash -s next-susfs
cd ..

echo "=== Đảm bảo thư mục đích tồn tại ==="
mkdir -p kernel-5.10/fs
mkdir -p kernel-5.10/include/linux

echo "=== Copy file SUSFS từ local patches ==="
cp patches/susfs4ksu/kernel_patches/fs/* kernel-5.10/fs/ 2>/dev/null || true
cp patches/susfs4ksu/kernel_patches/include/linux/* kernel-5.10/include/linux/ 2>/dev/null || true

echo "=== Tải các bản vá sửa lỗi mới nhất từ WildKernels ==="
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_base.c.patch -O fix_base.c.patch
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_exec.c.patch -O fix_exec.c.patch
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_namespace.c.patch -O fix_namespace.c.patch

echo "=== Áp dụng các bản vá sửa lỗi của Samsung ==="
cd kernel-5.10
patch -p1 --forward < ../fix_base.c.patch || echo "Cảnh báo: fix_base.c thất bại"
patch -p1 --forward < ../fix_exec.c.patch || echo "Cảnh báo: fix_exec.c thất bại"
patch -p1 --forward < ../fix_namespace.c.patch || echo "Cảnh báo: fix_namespace.c thất bại"
cd ..

echo "=== Áp dụng SUSFS patch cho kernel ==="
cd kernel-5.10
patch -p1 --forward < ../patches/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch || echo "Cảnh báo: một số hunks thất bại"
cd ..

# Dọn dẹp file tạm
rm -f fix_base.c.patch fix_exec.c.patch fix_namespace.c.patch

echo "=== Tích hợp SUSFS hoàn tất! ==="
