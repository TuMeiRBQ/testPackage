#!/usr/bin/env bash
set -euo pipefail

# =========================
# 默认配置
# =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# 工具路径（与脚本同级目录）
LINUXDEPLOY="${SCRIPT_DIR}/tools/linuxdeployqt"
PATCHELF="${SCRIPT_DIR}/tools/patchelf"

# 打包相关路径配置
BUILD_DIR=""
APPDIR="${PROJECT_ROOT}/package"
DEFAULT_MAIN_APP="gui_app"
MAIN_APP=""
ALL_APPS=false
QMAKE="/home/liuzhipeng/Qt5.15.2/5.15.2/gcc_64/bin/qmake"
BUNDLE_NON_QT=true

# =========================
# 日志工具函数
# =========================
info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# =========================
# 自动检测构建目录
# =========================
detect_build_dir() {
    if [[ -n "${BUILD_DIR}" ]]; then
        return
    fi

    if [[ -d "${PROJECT_ROOT}/build/release" ]]; then
        BUILD_DIR="${PROJECT_ROOT}/build/release"
    elif [[ -d "${PROJECT_ROOT}/build" ]]; then
        BUILD_DIR="${PROJECT_ROOT}/build"
    else
        error "Build directory not found! Use --build-dir to specify"
    fi
}

# =========================
# 命令行参数解析
# =========================
while [[ $# -gt 0 ]]; do
case "$1" in
    --build-dir)      BUILD_DIR="$2"; shift 2 ;;
    --appdir)         APPDIR="$2"; shift 2 ;;
    --qmake)          QMAKE="$2"; shift 2 ;;
    --no-bundle-non-qt) BUNDLE_NON_QT=false; shift ;;
    --main-app)       MAIN_APP="$2"; shift 2 ;;
    --all)            ALL_APPS=true; shift ;;
    *)                error "Unknown option: $1" ;;
esac
done

detect_build_dir

# =========================
# 检查依赖工具是否存在
# =========================
[[ -x "$LINUXDEPLOY" ]] || error "linuxdeployqt not found: $LINUXDEPLOY"
[[ -x "$PATCHELF" ]] || error "patchelf not found: $PATCHELF"
[[ -x "$QMAKE" ]] || error "qmake not found! Use --qmake to specify"

# =========================
# 清理并创建打包目录
# =========================
info "Cleaning package directory: ${APPDIR}"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# =========================
# 安装编译产物到打包目录
# =========================
info "Installing project to AppDir"
cmake --install "$BUILD_DIR" --prefix "$APPDIR"

APP_BIN_DIR="${APPDIR}/bin"
[[ -d "$APP_BIN_DIR" ]] || error "bin directory not found after installation"

# =========================
# 可执行文件打包函数
# =========================
package_executable() {
    local exe="$1"
    info "Packaging: $(basename "$exe")"
    local args=("$exe" "-qmake=$QMAKE")
    [[ "$BUNDLE_NON_QT" == true ]] && args+=("-bundle-non-qt-libs")
    "$LINUXDEPLOY" "${args[@]}"
}

# =========================
# 打包模式选择
# =========================
if [[ "$ALL_APPS" == true ]]; then
    info "Packaging ALL executables"
    find "$APP_BIN_DIR" -maxdepth 1 -type f -executable | while read -r exe; do
        package_executable "$exe"
    done
else
    TARGET_MAIN="${MAIN_APP:-$DEFAULT_MAIN_APP}"
    MAIN_EXE_PATH="${APP_BIN_DIR}/${TARGET_MAIN}"
    [[ -x "$MAIN_EXE_PATH" ]] || error "Main executable not found: $TARGET_MAIN"

    info "Packaging ONLY main app: [${TARGET_MAIN}]"
    package_executable "$MAIN_EXE_PATH"
    info "CLI tools preserved, setting RPATH next"
fi

# =========================
# 清理FHS模式自动生成的AppRun文件
# =========================
info "Cleaning up auto-generated AppRun file"
APPRUN_PATH="${PROJECT_ROOT}/AppRun"
if [[ -f "${APPRUN_PATH}" ]]; then
    rm -f "${APPRUN_PATH}"
    info "Removed AppRun: ${APPRUN_PATH}"
fi

# =========================
# 为所有可执行文件统一设置RPATH
# =========================
info "Setting RPATH for all executables: \$ORIGIN/../lib"
find "$APP_BIN_DIR" -maxdepth 1 -type f -executable | while read -r exe; do
    info "Fixing RPATH: $(basename "$exe")"
    "$PATCHELF" --set-rpath '$ORIGIN/../lib' "$exe"
done

# =========================
# 打包完成
# =========================
echo "============================================="
info "Packaging completed successfully!"
info "Output directory: ${APPDIR}"
echo "============================================="