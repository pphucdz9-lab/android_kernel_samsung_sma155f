#!/usr/bin/env bash
set -euo pipefail

echo ">>> Bắt đầu quy trình sửa lỗi vá SUSFS..."

# 1. Sửa fs/exec.c
if [ -f "kernel-5.10/fs/exec.c.rej" ]; then
    echo ">>> Đã tìm thấy exec.c.rej. Đang áp dụng sửa lỗi thủ công..."
    sed -i '/#include <linux\/uaccess.h>/a\#ifdef CONFIG_KSU_SUSFS\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/exec.c
    if grep -q 'susfs_def.h' kernel-5.10/fs/exec.c; then
        echo " -> Đã xác minh sửa lỗi exec.c!"
        rm -f kernel-5.10/fs/exec.c.rej
    else
        echo " [-] CẢNH BÁO: Sửa lỗi exec.c không thành công! Dòng neo có thể đã thay đổi." >&2
    fi
fi

# 2. Sửa fs/proc/base.c
if [ -f "kernel-5.10/fs/proc/base.c.rej" ]; then
    echo ">>> Đã tìm thấy base.c.rej. Đang áp dụng sửa lỗi thủ công..."
    sed -i '/#include "internal.h"/a\#if defined(CONFIG_KSU_SUSFS_SUS_MAP) || defined(CONFIG_KSU_SUSFS_OPEN_REDIRECT)\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/proc/base.c
    if grep -q 'susfs_def.h' kernel-5.10/fs/proc/base.c; then
        echo " -> Đã xác minh sửa lỗi base.c!"
        rm -f kernel-5.10/fs/proc/base.c.rej
    else
        echo " [-] CẢNH BÁO: Sửa lỗi base.c không thành công! Dòng neo có thể đã thay đổi." >&2
    fi
fi

# 3. Sửa fs/namespace.c
if [ -f "kernel-5.10/fs/namespace.c.rej" ]; then
    echo ">>> Đã tìm thấy namespace.c.rej. Đang áp dụng sửa lỗi thủ công..."
    sed -i '/#include "pnode.h"/i\#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\n#include <linux/susfs_def.h>\n#endif // #ifdef CONFIG_KSU_SUSFS_SUS_MOUNT' kernel-5.10/fs/namespace.c
    sed -i '/#include <trace\/hooks\/blk.h>/a\\n#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\nextern bool susfs_is_current_ksu_domain(void);\nextern bool susfs_is_sdcard_android_data_decrypted __read_mostly;\n#define CL_COPY_MNT_NS BIT(25) \/* used by copy_mnt_ns() *\/\n#endif // #ifdef CONFIG_KSU_SUSFS_SUS_MOUNT' kernel-5.10/fs/namespace.c
    if grep -q 'susfs_is_sdcard_android_data_decrypted' kernel-5.10/fs/namespace.c; then
        echo " -> Đã xác minh sửa lỗi namespace.c!"
        rm -f kernel-5.10/fs/namespace.c.rej
    else
        echo " [-] CẢNH BÁO: Sửa lỗi namespace.c không thành công! Dòng neo có thể đã thay đổi." >&2
    fi
fi

# 4. Sửa fs/open.c
if [ -f "kernel-5.10/fs/open.c.rej" ]; then
    echo ">>> Đã tìm thấy open.c.rej. Đang áp dụng sửa lỗi thủ công..."
    sed -i '/#include <linux\/dnotify.h>/a\#ifdef CONFIG_KSU_SUSFS\n#include <linux/susfs_def.h>\n#endif' kernel-5.10/fs/open.c
    if grep -q 'susfs_def.h' kernel-5.10/fs/open.c; then
        echo " -> Đã xác minh sửa lỗi open.c!"
        rm -f kernel-5.10/fs/open.c.rej
    fi
fi

# 5. Kiểm tra cuối cùng
echo ">>> Đang kiểm tra các lỗi vá chưa được giải quyết..."
mapfile -t REMAINING_REJ < <(find kernel-5.10 -type f -name '*.rej')
if [ ${#REMAINING_REJ[@]} -gt 0 ]; then
    echo "[-] NGHIÊM TRỌNG: Vẫn còn lỗi vá chưa được giải quyết!" >&2
    for f in "${REMAINING_REJ[@]}"; do
        echo " - $f" >&2
        echo "=== Nội dung $f ===" >&2
        cat "$f" >&2
    done
    exit 1
else
    echo ">>> Tất cả các lỗi vá đã được giải quyết thành công!"
fi
