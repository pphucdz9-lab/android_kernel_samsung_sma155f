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

echo "=== Copying SUSFS source files from local patches ==="
cp patches/susfs4ksu/kernel_patches/fs/* kernel-5.10/fs/ 2>/dev/null || true
cp patches/susfs4ksu/kernel_patches/include/linux/* kernel-5.10/include/linux/ 2>/dev/null || true

echo "=== Applying SUSFS patch to kernel (local) ==="
cd kernel-5.10
patch -p1 --forward < ../patches/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch || echo "Warning: some hunks failed"
cd ..

echo "=== Applying SUSFS patch to KernelSU Next (local) ==="
cd kernel-5.10/KernelSU-Next
patch -p1 --forward < ../../patches/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch || echo "Warning: some hunks failed"
cd ../../..

echo "=== SUSFS integration completed! ==="
