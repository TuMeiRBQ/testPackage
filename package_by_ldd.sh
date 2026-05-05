
#!/bin/bash

# 配置路径
BUILD_DIR="build"
DEPLOY_DIR="deploy"
LIB_DEST="$DEPLOY_DIR/lib"

# 1. 执行安装
cmake --install "$BUILD_DIR" --prefix "$DEPLOY_DIR"

# 2. 创建存放库的目录
mkdir -p "$LIB_DEST"

# 定义要排除的系统库模式
EXCLUDE_LIBS=(
    # "libc.so"
    # "libm.so"
    # "libstdc++.so"
    # "libgcc_s.so"
    # "libpthread.so"
    # "libdl.so"
    # "librt.so"
    # "libz.so"
    # "libGL.so"
    # "libX11.so"
    # "libxcb.so"
    # "libsystemd.so"
    # "libselinux.so"
    # "libgcrypt.so"
    # "libdw.so"
    # "libelf.so"
    # "libattr.so"
    # "libbz2.so"
    # "libcap.so"
    # "liblz4.so"
    # "liblzma.so"
)

# 4. 核心逻辑：从 BUILD 目录的可执行程序中提取依赖
# 我们需要处理 build/bin 下的所有 ELF 可执行文件
echo "Analyzing dependencies from $BUILD_DIR/bin..."

TEMP_LIB_LIST=$(mktemp)

# 遍历 build/bin 下的所有文件
for file in "$BUILD_DIR/bin/"*; do
    # 确保是可执行文件且是 ELF 格式（排除脚本）
    if [ -x "$file" ] && file "$file" | grep -q "ELF"; then
        # 提取 ldd 输出中 => 后面的绝对路径
        # 只有在 build 目录下运行，ldd 才能根据 build-time RPATH 找到这些库
        ldd "$file" | grep "=> /" | awk '{print $3}' >> "$TEMP_LIB_LIST"
    fi
done

# 5. 去重并过滤，然后复制
sort -u "$TEMP_LIB_LIST" | while read -r lib_path; do
    lib_name=$(basename "$lib_path")
    
    exclude=false
    for exclude_lib in "${EXCLUDE_LIBS[@]}"; do
        if [[ "$lib_name" == *"$exclude_lib"* ]]; then
            exclude=true
            break
        fi
    done

    if [ "$exclude" = false ] && [ -f "$lib_path" ]; then
        # 使用 -n (no-clobber) 避免重复复制，-v 显示过程
        cp -nv "$lib_path" "$LIB_DEST/"
    fi
done

# 清理临时文件
rm "$TEMP_LIB_LIST"

# 6. 可选：对部署后的库进行 strip
if [ -d "$LIB_DEST" ]; then
    echo "Stripping symbols to reduce size..."
    strip --strip-unneeded "$LIB_DEST"/*.so* 2>/dev/null || true
fi


QT5_PLUGINS="/home/liuzhipeng/Qt5.15.2/5.15.2/gcc_64/plugins"
PLUGIN_DEST="$DEPLOY_DIR/plugins"
mkdir -p "$PLUGIN_DEST"
cp -r "$QT5_PLUGINS/platforms" "$PLUGIN_DEST/"

# 2. 拷贝必须的平台插件（xcb，Linux GUI唯一必需）
mkdir -p "$PLUGIN_DEST"
cp -r "$QT5_PLUGINS/platforms" "$PLUGIN_DEST/"


echo "---------------------------------------"
echo "Deployment completed at: $DEPLOY_DIR"
