#!/bin/bash
OUT_FILE=susfs4ksu-module.zip
OLD_CWD=$(pwd)

cd ksu_module_susfs
# Xóa file zip cũ nếu có
rm -f "${OUT_FILE}" 2>/dev/null || true
# Tạo file zip, loại trừ bất kỳ file .zip nào đã tồn tại
zip -r9 ../"${OUT_FILE}" * -x "*.zip"
cd "${OLD_CWD}"
