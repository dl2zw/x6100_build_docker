#!/bin/bash
set -euo pipefail

WORKDIR="${WORKDIR:-/home/build}"
GUI_REPO="${GUI_REPO:-https://github.com/gdyuldin/x6100_gui.git}"
GUI_BRANCH="${GUI_BRANCH:-v1.0.0}"
BR_REPO="${BR_REPO:-https://github.com/gdyuldin/AetherX6100Buildroot.git}"
BR_BRANCH="${BR_BRANCH:-master}"
IMAGE_TAG="${IMAGE_TAG:-v1.0.0}"
BR2_CCACHE_DIR="${BR2_CCACHE_DIR:-/home/builder/.buildroot-ccache}"

GUI_DIR="${WORKDIR}/x6100_gui"
BR_DIR="${WORKDIR}/AetherX6100Buildroot"

# Ccache
export BR2_CCACHE_DIR
mkdir -p "${BR2_CCACHE_DIR}"

cd "${WORKDIR}"

echo "=== X6100 GUI / Buildroot Build Container ==="
echo "User    : $(whoami) (uid=$(id -u) gid=$(id -g))"
echo "Workdir : ${WORKDIR}"
echo "Ccache  : ${BR2_CCACHE_DIR}"
echo "GUI     : ${GUI_REPO} (${GUI_BRANCH})"
echo "BR      : ${BR_REPO} (${BR_BRANCH})"
echo "Tag     : ${IMAGE_TAG}"
echo ""

# --- 1. GUI ckeckout (with Submodules) ---
if [ -d "${GUI_DIR}/.git" ]; then
  echo ">>> GUI: existent Repo – fetch/pull ..."
  cd "${GUI_DIR}"
  git fetch origin
  git checkout "${GUI_BRANCH}"
  git pull --ff-only origin "${GUI_BRANCH}" || true
  git submodule update --init --recursive
else
  echo ">>> GUI: clone ..."
  rm -rf "${GUI_DIR}" 2>/dev/null || true
  git clone --recurse-submodules --branch "${GUI_BRANCH}" "${GUI_REPO}" "${GUI_DIR}"
fi
echo ">>> GUI: $(cd "${GUI_DIR}" && git rev-parse --short HEAD)"
echo ""

# --- 2. Buildroot-Repo checkout (with Submodules) ---
if [ -d "${BR_DIR}/.git" ]; then
  echo ">>> Buildroot: existent Repo – fetch/pull ..."
  cd "${BR_DIR}"
  git fetch origin
  git checkout "${BR_BRANCH}"
  git pull --ff-only origin "${BR_BRANCH}" || true
  git submodule update --init --recursive
else
  echo ">>> Buildroot: clone ..."
  rm -rf "${BR_DIR}" 2>/dev/null || true
  git clone --recurse-submodules --branch "${BR_BRANCH}" "${BR_REPO}" "${BR_DIR}"
fi
echo ">>> Buildroot: $(cd "${BR_DIR}" && git rev-parse --short HEAD)"
echo ""

# --- 3. GUI-Package local Path ---
echo ">>> Patch x6100_gui.mk → local source ..."
MK="${BR_DIR}/br2_external/package/x6100-gui/x6100_gui.mk"
sed -i "s|^X6100_GUI_VERSION = v0.23.0-rc.3|X6100_GUI_VERSION = ${GUI_BRANCH}|g" "${MK}"
sed -i "s|https://github.com/gdyuldin/x6100_gui|${GUI_DIR}|g" "${MK}"
sed -i "s|^X6100_GUI_SITE_METHOD = git|X6100_GUI_SITE_METHOD = local|g" "${MK}"
sed -i "s|^X6100_GUI_GIT_SUBMODULES|# X6100_GUI_GIT_SUBMODULES|g" "${MK}"
echo ">>> Patch ok"
echo ""

# --- 4. Configure ---
echo ">>> br_config.sh ..."
cd "${BR_DIR}"
bash ./br_config.sh

# Buildroot midnight commander
if ! grep -q '^BR2_PACKAGE_MC=y' build/.config 2>/dev/null; then
  echo ">>> Enable midnight commander in .config ..."
  cd build
  if grep -q 'BR2_PACKAGE_MC' .config; then
    sed -i 's/^# BR2_PACKAGE_MC is not set/BR2_PACKAGE_MC=y/' .config || true
    sed -i 's/^BR2_PACKAGE_MC=n/BR2_PACKAGE_MC=y/' .config || true
  else
    echo 'BR2_PACKAGE_MC=y' >> .config
  fi
  make olddefconfig 2>/dev/null || true
  cd ..
fi
echo ""

# --- 5. Build ---
cd "${BR_DIR}/build"

# Marker for „first Build“
FIRST_BUILD_MARKER="${BR_DIR}/build/.first_build_done"

# build x6100_gui always new
echo ">>> Erase x6100_gui Package-Builddirectory ..."
rm -rf "${BR_DIR}/build/build/x6100-gui-"* 2>/dev/null || true

if [ ! -f "${FIRST_BUILD_MARKER}" ]; then
  echo ">>> First Build: make lame / mpg123 / libsndfile-dirclean / make ..."
  make lame
  make mpg123
  make libsndfile-dirclean
  make
  touch "${FIRST_BUILD_MARKER}"
  echo ">>> First Build done (Marker set)."
else
  echo ">>> Subsequent-Build: only make ..."
  make
fi

# --- GUI-Package back to original Path for successful git pull ---
sed -i "s|^X6100_GUI_VERSION = ${GUI_BRANCH}|X6100_GUI_VERSION = v0.23.0-rc.3|g" "${MK}"
sed -i "s|${GUI_DIR}|https://github.com/gdyuldin/x6100_gui|g" "${MK}"
sed -i "s|^X6100_GUI_SITE_METHOD = local|X6100_GUI_SITE_METHOD = git|g" "${MK}"
sed -i "s|^# X6100_GUI_GIT_SUBMODULES|X6100_GUI_GIT_SUBMODULES|g" "${MK}"
echo ""

# --- 6. Image ---
echo ">>> Compress image ..."
cd "${BR_DIR}/build/images"
OUT_NAME="sdcard.${IMAGE_TAG}.img"
mv -f sdcard.img "${OUT_NAME}"
zip -9 "${OUT_NAME}.zip" "${OUT_NAME}"
echo ""

echo "=== Build ready ==="
ls -lh "${BR_DIR}/build/images/"
echo ""
echo "Ccache-Status:"
du -sh "${BR2_CCACHE_DIR}" 2>/dev/null || true
echo ""
echo "Artifacts on the host under the volume path:"
echo "  .../AetherX6100Buildroot/build/images/${OUT_NAME}"
echo "  .../AetherX6100Buildroot/build/images/${OUT_NAME}.zip"
