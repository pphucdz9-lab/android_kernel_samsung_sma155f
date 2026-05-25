#!/bin/bash
set -e

echo "=== Setting up KernelSU Next ==="
cd kernel-5.10
if [ -d "KernelSU-Next" ]; then
    rm -rf KernelSU-Next
fi
curl -LSs https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh | bash -s next
cd ..

echo "=== Ensuring target directories exist ==="
mkdir -p kernel-5.10/fs
mkdir -p kernel-5.10/include/linux
if [ ! -d kernel-5.10/fs ]; then
    echo "ERROR: kernel-5.10/fs does not exist"
    exit 1
fi
if [ ! -d kernel-5.10/include/linux ]; then
    echo "ERROR: kernel-5.10/include/linux does not exist"
    exit 1
fi

echo "=== Applying SUSFS patch to kernel (latest from GitLab) ==="
cd kernel-5.10
curl -LSs "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch" | patch -p1 --forward || echo "Warning: some hunks failed"
cd ..

echo "=== Applying SUSFS patch to KernelSU Next (latest from GitLab) ==="
cd kernel-5.10/KernelSU-Next
curl -LSs "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch" | patch -p1 --forward || echo "Warning: some hunks failed"
cd ../../..

echo "=== Copying SUSFS source files ==="
# Sử dụng wget với khả năng xử lý lỗi tốt hơn, nếu thất bại sẽ thử lại bằng curl
wget -q "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/fs/susfs.c" -O kernel-5.10/fs/susfs.c || {
    echo "wget failed for susfs.c, trying curl..."
    curl -LSs "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/fs/susfs.c" -o kernel-5.10/fs/susfs.c
}
wget -q "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/include/linux/susfs.h" -O kernel-5.10/include/linux/susfs.h || {
    echo "wget failed for susfs.h, trying curl..."
    curl -LSs "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/include/linux/susfs.h" -o kernel-5.10/include/linux/susfs.h
}
wget -q "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/include/linux/susfs_def.h" -O kernel-5.10/include/linux/susfs_def.h || {
    echo "wget failed for susfs_def.h, trying curl..."
    curl -LSs "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android12-5.10/kernel_patches/include/linux/susfs_def.h" -o kernel-5.10/include/linux/susfs_def.h
}

echo "=== SUSFS integration completed! ==="
