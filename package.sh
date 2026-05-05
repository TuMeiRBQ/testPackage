#!/usr/bin/env bash
set -euo pipefail

########################################

# 默认配置

########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

BUILD_DIR=""
APPDIR="${PROJECT_ROOT}/package"

TOOLS_DIR="${SCRIPT_DIR}/tools"
LINUXDEPLOY="${TOOLS_DIR}/linuxdeployqt"
PATCHELF="${TOOLS_DIR}/patchelf"

QMAKE="/home/liuzhipeng/Qt5.15.2/5.15.2/gcc_64/bin/qmake"
BUNDLE_NON_QT=true

########################################

# 日志

########################################

log() {
echo "[INFO] $*"
}

err() {
echo "[ERROR] $*" >&2
exit 1
}

########################################

# 自动推断构建目录

########################################

detect_build_dir() {
if [[ -n "${BUILD_DIR}" ]]; then
return
fi


if [[ -d build/release ]]; then
    BUILD_DIR="build/release"
elif [[ -d build ]]; then
    BUILD_DIR="build"
else
    err "未找到构建目录，请使用 --build-dir 指定"
fi

}

########################################

# 参数解析

########################################

while [[ $# -gt 0 ]]; do
case "$1" in
--build-dir)
BUILD_DIR="$2"
shift 2
;;
--appdir)
APPDIR="$2"
shift 2
;;
--qmake)
QMAKE="$2"
shift 2
;;
--no-bundle-non-qt)
BUNDLE_NON_QT=false
shift
;;
*)
err "未知参数: $1"
;;
esac
done

detect_build_dir

########################################

# 检查工具

########################################

[[ -x "$LINUXDEPLOY" ]] || err "linuxdeployqt 不存在或不可执行: $LINUXDEPLOY"
[[ -x "$PATCHELF" ]] || err "patchelf 不存在或不可执行: $PATCHELF"
[[ -x "$QMAKE" ]] || err "qmake 不存在或不可执行: $QMAKE"

export PATCHELF

########################################

# 清理输出目录

########################################

rm -rf "$APPDIR"
mkdir -p "$APPDIR"

########################################

# 安装

########################################

log "安装到 AppDir..."
cmake --install "$BUILD_DIR" --prefix "$APPDIR"

########################################

# 打包所有可执行文件

########################################

APP_BIN_DIR="${APPDIR}/bin"

[[ -d "$APP_BIN_DIR" ]] || err "未找到安装后的 bin 目录: $APP_BIN_DIR"

log "开始打包所有可执行文件..."

find "$APP_BIN_DIR" -maxdepth 1 -type f -executable | while read -r exe; do
log "处理 $(basename "$exe")"

```
ARGS=(
    "$exe"
    "-qmake=$QMAKE"
)

if [[ "$BUNDLE_NON_QT" == true ]]; then
    ARGS+=("-bundle-non-qt-libs")
fi

"$LINUXDEPLOY" "${ARGS[@]}"
```

done

log "完成"
log "输出目录: $APPDIR"
