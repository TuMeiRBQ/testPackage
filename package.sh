#!/usr/bin/env bash

# 如果当前不是 bash，自动切换为 bash 执行（解决 sh 调用的问题）
[ -z "$BASH_VERSION" ] && exec /usr/bin/env bash "$0" "$@"

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 固定配置
BUILD_DIR=""
PACKAGE_ROOT="./package"
TARGET_BIN="${PACKAGE_ROOT}/bin"
TARGET_LIB="${PACKAGE_ROOT}/lib"
TARGET_PLUGINS="${PACKAGE_ROOT}/plugins"
DEFAULT_MAIN_APP="gui_app"
MAIN_APP=""
ALL_APPS=false
QMAKE="/home/liuzhipeng/Qt5.15.2/5.15.2/gcc_64/bin/qmake"
declare -A GLOBAL_DEP_LIBS

# 日志
info()  { echo -e "${GREEN}[INFO] $*${NC}"; }
error() { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }

# 检查工具
check_tools() {
    command -v patchelf || error "缺少patchelf"
    QT_PATH=$($QMAKE -query QT_INSTALL_PREFIX)
    info "Qt路径: $QT_PATH"
}

# 检测构建目录
detect_build() {
    if [ -z "$BUILD_DIR" ]; then
        [ -d "build/release/bin" ] && BUILD_DIR="build/release"
        [ -d "build/bin" ]        && BUILD_DIR="build"
        [ -z "$BUILD_DIR" ]       && error "无构建目录"
    fi
    info "构建目录: $BUILD_DIR"
}

# 参数解析
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --build-dir) BUILD_DIR="$2"; shift 2 ;;
            --main-app)  MAIN_APP="$2";  shift 2 ;;
            -a|--all)    ALL_APPS=true;  shift    ;;
            *) shift ;;
        esac
    done
}

# 复制可执行文件
copy_exe() {
    info "复制可执行文件"
    mkdir -p "$TARGET_BIN"
    local src_bin="${BUILD_DIR}/bin"

    if [ "$ALL_APPS" = true ]; then
        for file in "$src_bin"/*; do
            [ -f "$file" ] && [ -x "$file" ] && cp -f "$file" "$TARGET_BIN/"
        done
    else
        local exe="${src_bin}/${MAIN_APP:-$DEFAULT_MAIN_APP}"
        cp -f "$exe" "$TARGET_BIN/"
    fi
}

# 递归解析依赖（修复了 set -u 下关联数组报错的问题）
resolve_lib() {
    local lib
    while IFS= read -r lib; do
        # 关键修复：用 "+x" 检查键是否存在，避免 unbound variable
        if [ -f "$lib" ] && [ -z "${GLOBAL_DEP_LIBS[$lib]+x}" ]; then
            GLOBAL_DEP_LIBS[$lib]=1
            resolve_lib "$lib"
        fi
    done < <(ldd "$1" 2>/dev/null | awk '$3 ~ /^\// {print $3}')
}

# 复制依赖库
copy_libs() {
    info "收集依赖库"
    mkdir -p "$TARGET_LIB"
    unset GLOBAL_DEP_LIBS
    declare -A GLOBAL_DEP_LIBS

    local exe
    for exe in "$TARGET_BIN"/*; do
        [ -x "$exe" ] && resolve_lib "$exe"
    done

    local lib
    for lib in "${!GLOBAL_DEP_LIBS[@]}"; do
        cp -f "$lib" "$TARGET_LIB/"
    done
}

# 复制Qt平台插件
copy_qt() {
    info "复制Qt插件"
    mkdir -p "${TARGET_PLUGINS}/platforms"
    local xcb="${QT_PATH}/plugins/platforms/libqxcb.so"
    [ -f "$xcb" ] && cp -f "$xcb" "${TARGET_PLUGINS}/platforms/"
}

# 设置 RPATH
set_rpath() {
    info "设置RPATH"
    local exe
    for exe in "$TARGET_BIN"/*; do
        [ -x "$exe" ] && patchelf --force-rpath --set-rpath '$ORIGIN/../lib' "$exe"
    done
    local lib
    for lib in "$TARGET_LIB"/*.so*; do
        [ -f "$lib" ] && patchelf --force-rpath --set-rpath '$ORIGIN' "$lib"
    done
}

# 生成 qt.conf
qt_conf() {
    echo "[Paths]"           >  "${TARGET_BIN}/qt.conf"
    echo "Plugins=../plugins" >> "${TARGET_BIN}/qt.conf"
}

# 主流程
main() {
    info "======== 打包启动 ========"
    parse_args "$@"
    detect_build
    check_tools

    rm -rf "$PACKAGE_ROOT"
    mkdir -p "$PACKAGE_ROOT"

    copy_exe
    copy_qt
    copy_libs
    set_rpath
    qt_conf

    info "======== 打包完成 ========"
    info "运行：cd package/bin && ./gui_app"
}

main "$@"


# 缺少黑名单机制过滤系统库 排除libpthread.so.0 libstdc++.so.6  libdl.so.2 libm.so.6 libgcc_s.so.1, qt相关的可以不打包， 之后使用打包工具打包即可。混合打包。