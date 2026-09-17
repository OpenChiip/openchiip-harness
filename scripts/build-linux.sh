#!/usr/bin/env bash
# OpenChiip Harness — Linux 打包脚本
# 生成自包含 tar.gz + 可选 deb/rpm（需 fpm）
set -euo pipefail

VERSION="${1:-3.0.0}"
ARCH="$(uname -m)"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build/linux"
DIST_DIR="${PROJECT_DIR}/dist"
PKG_NAME="openchiip-harness-${VERSION}-linux-${ARCH}"

echo "═══ OpenChiip Harness Linux 打包 ═══"
echo "版本: ${VERSION}"
echo "架构: ${ARCH}"
echo ""

# ── 清理 ──
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${BUILD_DIR}/${PKG_NAME}" "${DIST_DIR}"

# ── 复制文件 ──
echo "[1/5] 复制项目文件..."
cp -r "${PROJECT_DIR}/agent_runtime" "${BUILD_DIR}/${PKG_NAME}/"
cp "${PROJECT_DIR}/pyproject.toml" "${BUILD_DIR}/${PKG_NAME}/"
cp -r "${PROJECT_DIR}/web/dist" "${BUILD_DIR}/${PKG_NAME}/web-dist" 2>/dev/null || true
cp "${PROJECT_DIR}/scripts/install.sh" "${BUILD_DIR}/${PKG_NAME}/"
cp "${PROJECT_DIR}/scripts/openchiip-harness.service" "${BUILD_DIR}/${PKG_NAME}/"

# ── 创建入口脚本 ──
echo "[2/5] 创建入口脚本..."
cat > "${BUILD_DIR}/${PKG_NAME}/start.sh" << 'STARTUP'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
export PYTHONPATH="${DIR}:${PYTHONPATH}"
export AGENT_RUNTIME_HOME="${HOME}/.openchiip-harness/data"
mkdir -p "${AGENT_RUNTIME_HOME}"
exec python3 -m uvicorn agent_runtime.server.app:create_app \
    --factory --host 0.0.0.0 --port "${PORT:-8900}" "$@"
STARTUP
chmod +x "${BUILD_DIR}/${PKG_NAME}/start.sh"

# ── 创建 Python venv ──
echo "[3/5] 创建 Python 虚拟环境..."
python3 -m venv "${BUILD_DIR}/${PKG_NAME}/venv"
source "${BUILD_DIR}/${PKG_NAME}/venv/bin/activate"
pip install --upgrade pip -q
pip install websockets psutil PyYAML fastapi "uvicorn[standard]" python-multipart aiofiles -q
pip install "${PROJECT_DIR}" --no-deps -q 2>/dev/null || pip install "${BUILD_DIR}/${PKG_NAME}" --no-deps -q 2>/dev/null || true
deactivate

# ── 前端构建（如果未预构建）──
if [[ ! -d "${BUILD_DIR}/${PKG_NAME}/web-dist" ]]; then
    echo "[3.5/5] 构建前端..."
    if command -v node &>/dev/null && [[ -d "${PROJECT_DIR}/web" ]]; then
        (cd "${PROJECT_DIR}/web" && npm install -q && npm run build)
        cp -r "${PROJECT_DIR}/web/dist" "${BUILD_DIR}/${PKG_NAME}/web-dist"
    else
        echo "  跳过前端构建（无 Node.js）"
    fi
fi

# ── 打包 tar.gz ──
echo "[4/5] 打包 tar.gz..."
(cd "${BUILD_DIR}" && tar czf "${DIST_DIR}/${PKG_NAME}.tar.gz" "${PKG_NAME}")
TAR_SIZE=$(du -sh "${DIST_DIR}/${PKG_NAME}.tar.gz" | cut -f1)
echo "  ✓ ${DIST_DIR}/${PKG_NAME}.tar.gz (${TAR_SIZE})"

# ── 可选：生成 deb/rpm ──
echo "[5/5] 检查 fpm..."
if command -v fpm &>/dev/null; then
    echo "  生成 deb 包..."
    fpm -s dir -t deb \
        -n openchiip-harness -v "${VERSION}" \
        --prefix /opt/openchiip-harness \
        -C "${BUILD_DIR}/${PKG_NAME}" . \
        -p "${DIST_DIR}/openchiip-harness_${VERSION}_${ARCH}.deb" \
        --description "OpenChiip Harness" \
        --url "https://github.com/openchiip/harness" \
        --license "AIGCGPL-1.0" \
        --maintainer "OpenChiip <https://github.com/openchiip>" \
        2>&1 || echo "  deb 打包失败（可忽略）"

    echo "  生成 rpm 包..."
    fpm -s dir -t rpm \
        -n openchiip-harness -v "${VERSION}" \
        --prefix /opt/openchiip-harness \
        -C "${BUILD_DIR}/${PKG_NAME}" . \
        -p "${DIST_DIR}/openchiip-harness-${VERSION}-1.${ARCH}.rpm" \
        --description "OpenChiip Harness" \
        --url "https://github.com/openchiip/harness" \
        --license "AIGCGPL-1.0" \
        --maintainer "OpenChiip <https://github.com/openchiip>" \
        2>&1 || echo "  rpm 打包失败（可忽略）"
else
    echo "  fpm 未安装，跳过 deb/rpm 生成"
    echo "  安装 fpm: gem install fpm"
    echo "  tar.gz 包仍可直接使用"
fi

echo ""
echo "═══ 打包完成 ═══"
ls -lh "${DIST_DIR}/"
echo ""
echo "使用方式："
echo "  tar.gz:  tar xzf ${PKG_NAME}.tar.gz && cd ${PKG_NAME} && ./start.sh"
echo "  deb:     sudo dpkg -i openchiip-harness_${VERSION}_*.deb"
echo "  rpm:     sudo rpm -i openchiip-harness-${VERSION}-1.*.rpm"
