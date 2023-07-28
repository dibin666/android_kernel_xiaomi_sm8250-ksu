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

# 开始的时间
start=`date +%s`

# 原 boot 目录,请重命名为 boot.img
export BOOT_DIR=/mnt/disk/boot/boot.img

# 新 boot 输出目录
export NEW_BOOT_DIR=/mnt/disk/out

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

# 获取 magiskbootx86_64
cd out/arch/arm64/boot
wget https://github.com/dibin666/toolchains/releases/download/magiskboot/magiskbootx86_64
chmod +x magiskbootx86_64

#复制原 boot 到 out 目录
cp $BOOT_DIR ./

# 替换原 boot 的内核
./magiskbootx86_64 unpack boot.img
mv -f Image kernel
./magiskbootx86_64 repack boot.img

# 复制替换后的 boot 到外部目录
cp new-boot.img $NEW_BOOT_DIR

# 清理目录
rm -rf out

# 结束时间
end=`date +%s`

# 总耗时
time=`echo $start $end | awk '{print $2-$1}'`
echo "---------------------------------------"
echo "内核编译完成！编译总耗时：${time}s"
echo "---------------------------------------"
