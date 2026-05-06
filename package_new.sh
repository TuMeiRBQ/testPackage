#!/usr/bin/env bash
set -euo pipefail

# =========================
# 默认配置（固定相对路径）
# =========================
# 打包工具
LINUXDEPLOY="./tools/linuxdeployqt"
PATCHELF="./tools/patchelf"

# 核心路径
BUILD_DIR=""
APPDIR="./package"
DEFAULT_MAIN_APP="gui_app"

# 可选参数
MAIN_APP=""
ALL_APPS=false
QMAKE="/home/liuzhipeng/Qt5.15.2/5.15.2/gcc_64/bin/qmake"
BUNDLE_NON_QT=true

# =========================
# 日志工具
# =========================
info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# =========================
# 自动检测构建目录
# =========================
detect_build_dir() {
    [[ -n "${BUILD_DIR}" ]] && return

    if [[ -d "build/release" ]]; then
        BUILD_DIR="build/release"
    elif [[ -d "build" ]]; then
        BUILD_DIR="build"
    else
        error "Build directory not found! Use --build-dir to specify"
    fi
}

# =========================
# 命令行参数解析（兼容短参数 -a）
# =========================
while [[ $# -gt 0 ]]; do
case "$1" in
    --build-dir)      BUILD_DIR="$2"; shift 2 ;;
    --appdir)         APPDIR="$2"; shift 2 ;;
    --qmake)          QMAKE="$2"; shift 2 ;;
    --no-bundle-non-qt) BUNDLE_NON_QT=false; shift ;;
    --main-app)       MAIN_APP="$2"; shift 2 ;;
    -a|--all)         ALL_APPS=true; shift ;;  # 修复：支持 -a / --all
    *)                error "Unknown option: $1" ;;
esac
done

detect_build_dir

# =========================
# 工具检查
# =========================
info "============================================="
info "linuxdeployqt: ${LINUXDEPLOY}"
info "patchelf:      ${PATCHELF}"
info "qmake:         ${QMAKE}"
info "============================================="

[[ -x "$LINUXDEPLOY" ]] || error "linuxdeployqt not found: $LINUXDEPLOY"
[[ -x "$PATCHELF" ]] || error "patchelf not found: $PATCHELF"
[[ -x "$QMAKE" ]] || error "qmake not found! Use --qmake to specify"

# =========================
# 清理打包目录
# =========================
info "Cleaning package directory: ${APPDIR}"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# =========================
# 安装产物
# =========================
info "Installing project to AppDir"
cmake --install "$BUILD_DIR" --prefix "$APPDIR"

APP_BIN_DIR="${APPDIR}/bin"
[[ -d "$APP_BIN_DIR" ]] || error "bin directory not found after installation"

# =========================
# 打包函数
# =========================
package_executable() {
    local exe="$1"
    info "Packaging: $(basename "$exe")"
    local args=("$exe" "-qmake=$QMAKE")
    [[ "$BUNDLE_NON_QT" == true ]] && args+=("-bundle-non-qt-libs")
    info "$LINUXDEPLOY ${args[*]}"
    "$LINUXDEPLOY" "${args[@]}"
}

# =========================
# 打包模式
# =========================
if [[ "$ALL_APPS" == true ]]; then
    info "Mode: Packaging ALL executables (auto set RPATH by tool)"
    find "$APP_BIN_DIR" -maxdepth 1 -type f -executable | while read -r exe; do
        package_executable "$exe"
    done
else
    TARGET_MAIN="${MAIN_APP:-$DEFAULT_MAIN_APP}"
    MAIN_EXE_PATH="${APP_BIN_DIR}/${TARGET_MAIN}"
    [[ -x "$MAIN_EXE_PATH" ]] || error "Main executable not found: $TARGET_MAIN"

    info "Mode: Packaging ONLY main app: [${TARGET_MAIN}]"
    package_executable "$MAIN_EXE_PATH"
    info "CLI tools preserved, will fix RPATH manually"
fi

# =========================
# 清理唯一的 AppRun（无论哪种模式）
# =========================
info "Cleaning up auto-generated AppRun file"
APPRUN_PATH="./AppRun"
if [[ -f "${APPRUN_PATH}" ]]; then
    rm -f "${APPRUN_PATH}"
    info "Removed AppRun: ${APPRUN_PATH}"
fi

# =========================
# 🚀 核心修复：--all 模式跳过 patchelf（工具已设置RPATH）
# =========================
if [[ "$ALL_APPS" == false ]]; then
    info "Setting RPATH for all executables: \$ORIGIN/../lib"
    find "$APP_BIN_DIR" -maxdepth 1 -type f -executable | while read -r exe; do
        info "Fixing RPATH: $(basename "$exe")"
        "$PATCHELF" --set-rpath '$ORIGIN/../lib' "$exe"
    done
else
    info "Skip RPATH fix: ALL mode, linuxdeployqt already handled it"
fi

# =========================
# 完成
# =========================
echo "============================================="
info "Packaging completed successfully!"
info "Output directory: ${APPDIR}"
echo "============================================="