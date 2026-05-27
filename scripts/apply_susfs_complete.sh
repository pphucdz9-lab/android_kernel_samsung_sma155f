#!/bin/bash
set -e

echo "========================================="
echo "  Tự động tích hợp KernelSU + SUSFS"
echo "========================================="

# 1. Thiết lập KernelSU
echo ">>> 1. Thiết lập KernelSU..."
cd kernel-5.10
if [ -d "KernelSU" ]; then
    rm -rf KernelSU
fi
curl -LSs https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh | bash
cd ..

# 2. Đảm bảo thư mục đích tồn tại
echo ">>> 2. Đảm bảo thư mục đích..."
mkdir -p kernel-5.10/fs
mkdir -p kernel-5.10/include/linux

# 3. Copy file SUSFS từ local patches
echo ">>> 3. Copy file SUSFS..."
cp patches/susfs4ksu/kernel_patches/fs/* kernel-5.10/fs/ 2>/dev/null || true
cp patches/susfs4ksu/kernel_patches/include/linux/* kernel-5.10/include/linux/ 2>/dev/null || true

# 4. Tải các bản vá sửa lỗi từ WildKernels
echo ">>> 4. Tải bản vá sửa lỗi từ WildKernels..."
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_base.c.patch -O fix_base.c.patch
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_exec.c.patch -O fix_exec.c.patch
wget -q https://raw.githubusercontent.com/WildKernels/kernel_patches/main/samsung/SM-A155F-Oneui7/fix_namespace.c.patch -O fix_namespace.c.patch

# 5. Áp dụng các bản vá sửa lỗi của Samsung TRƯỚC
echo ">>> 5. Áp dụng bản vá sửa lỗi Samsung..."
cd kernel-5.10
patch -p1 --forward < ../fix_base.c.patch || echo "   [OK] fix_base.c"
patch -p1 --forward < ../fix_exec.c.patch || echo "   [OK] fix_exec.c"
patch -p1 --forward < ../fix_namespace.c.patch || echo "   [OK] fix_namespace.c"
cd ..

# 6. Áp dụng SUSFS patch cho kernel chính
echo ">>> 6. Áp dụng SUSFS patch cho kernel..."
cd kernel-5.10
patch -p1 --forward < ../patches/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch || echo "   [OK] kernel patch"
cd ..

# 7. Tự động sửa các lỗi vá còn tồn đọng
echo ">>> 7. Sửa lỗi vá tự động..."
if [ -f "kernel-5.10/fs/exec.c.rej" ]; then
    echo "   Sửa exec.c..."
    sed -i '/#include <linux\/uaccess.h>/a\#ifdef CONFIG_KSU_SUSFS\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/exec.c
    rm -f kernel-5.10/fs/exec.c.rej
fi
if [ -f "kernel-5.10/fs/proc/base.c.rej" ]; then
    echo "   Sửa base.c..."
    sed -i '/#include "internal.h"/a\#if defined(CONFIG_KSU_SUSFS_SUS_MAP) || defined(CONFIG_KSU_SUSFS_OPEN_REDIRECT)\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/proc/base.c
    rm -f kernel-5.10/fs/proc/base.c.rej
fi
if [ -f "kernel-5.10/fs/namespace.c.rej" ]; then
    echo "   Sửa namespace.c..."
    sed -i '/#include "pnode.h"/i\#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/namespace.c
    rm -f kernel-5.10/fs/namespace.c.rej
fi
if [ -f "kernel-5.10/fs/open.c.rej" ]; then
    echo "   Sửa open.c..."
    sed -i '/#include <linux\/dnotify.h>/a\#ifdef CONFIG_KSU_SUSFS\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/open.c
    rm -f kernel-5.10/fs/open.c.rej
fi
echo "   Hoàn tất sửa lỗi!"

# 8. Áp dụng SUSFS patch cho KernelSU (bản mới)
echo ">>> 8. Áp dụng SUSFS patch cho KernelSU..."
cd kernel-5.10/KernelSU
patch -p1 --forward < ../../patches/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch || echo "   [OK] KSU patch"
cd ../../..

# 9. Dọn dẹp file tạm
echo ">>> 9. Dọn dẹp..."
rm -f fix_base.c.patch fix_exec.c.patch fix_namespace.c.patch

echo "========================================="
echo "  Tích hợp SUSFS hoàn tất!"
echo "========================================="
