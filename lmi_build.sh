#!/bin/bash

# 添加 KernelSU
read -p "是否添加 KernelSU？(y/n): " choice
if [ "$choice" = "y" ]; then
  rm -rf KernelSU
  # 提示用户选择版本
  read -p "请选择版本（开发版/稳定版）：(1/0): " channel
  
  if [ "$channel" = "1" ]; then
    echo "您选择了开发版"
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
  elif [ "$channel" = "0" ]; then
    echo "您选择了稳定版"
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
  else
    echo "无效的选择"
    exit 1
  fi
fi

# 内核工作目录
export KERNEL_DIR=$(pwd)

# 内核 defconfig 文件
export KERNEL_DEFCONFIG=lmi_defconfig

# 编译临时目录，避免污染根目录
export OUT=out

# clang 和 gcc 绝对路径
export CLANG_PATH=/mnt/disk2/tool2/zyc-clang
export PATH=${CLANG_PATH}/bin:${PATH}
# export GCC_PATH=/mnt/disk2/tool2/gcc
export SUBARCH=arm64
export ARCH=arm64

# 编译参数
export DEF_ARGS="O=${OUT} \
                      CC=clang \
                      ARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      NM=llvm-nm \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip "

export BUILD_ARGS="-j$(nproc --all) ${DEF_ARGS}"

# 开始编译内核
make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
make ${BUILD_ARGS}

# 复制编译出的文件到外部目录
if [[ -f out/arch/arm64/boot/Image.gz-dtb ]]; then
  cp out/arch/arm64/boot/Image.gz-dtb /mnt/disk/lmiput/Image.gz-dtb
elif [[ -f out/arch/arm64/boot/Image-dtb ]]; then
  cp out/arch/arm64/boot/Image-dtb /mnt/disk/lmiout/Image-dtb
elif [[ -f out/arch/arm64/boot/Image.gz ]]; then
  cp out/arch/arm64/boot/Image.gz /mnt/disk/lmiout/Image.gz
elif [[ -f out/arch/arm64/boot/Image ]]; then
  cp out/arch/arm64/boot/Image /mnt/disk/lmiout/Image
fi

if [ -f out/arch/arm64/boot/dtbo.img ]; then
  cp out/arch/arm64/boot/dtbo.img /mnt/disk/lmiout/dtbo.img
fi

# 清理目录
rm -rf AnyKernel3
rm -rf KernelSU
rm -rf out
