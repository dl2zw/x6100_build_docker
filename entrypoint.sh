#!/bin/bash
set -euo pipefail

WORKDIR="${WORKDIR:-/home/build}"
GUI_REPO="${GUI_REPO:-https://github.com/OpenX6100/x6100_gui.git}"
GUI_BRANCH="${GUI_BRANCH:-v1.2.0}"
BR_REPO="${BR_REPO:-https://github.com/OpenX6100/AetherX6100Buildroot.git}"
BR_BRANCH="${BR_BRANCH:-master}"
IMAGE_TAG="${IMAGE_TAG:-v1.2.0}"
UBOOT_BRANCH="${UBOOT_BRANCH:-2023.01}"
BR2_CCACHE_DIR="${BR2_CCACHE_DIR:-/home/builder/.buildroot-ccache}"

GUI_DIR="${WORKDIR}/x6100_gui"
BR_DIR="${WORKDIR}/AetherX6100Buildroot"

# Ccache
export BR2_CCACHE_DIR
mkdir -p "${BR2_CCACHE_DIR}"

cd "${WORKDIR}"

echo "=== X6100 GUI / Buildroot Build Container ==="
echo "User         : $(whoami) (uid=$(id -u) gid=$(id -g))"
echo "Workdir      : ${WORKDIR}"
echo "Ccache       : ${BR2_CCACHE_DIR}"
echo "GUI          : ${GUI_REPO} (${GUI_BRANCH})"
echo "BR           : ${BR_REPO} (${BR_BRANCH})"
echo "Tag          : ${IMAGE_TAG}"

# u-boot status
if [ "${ENABLE_UBOOT:-0}" = "1" ] || [ "${ENABLE_UBOOT:-}" = "yes" ] || [ "${ENABLE_UBOOT:-}" = "true" ]; then
  echo "u-boot       : ${UBOOT_BRANCH} (patched)"
else
  echo "u-boot       : 2023.01 (default)"
fi

# show midnight commander build status
if [ "${ENABLE_MC:-0}" = "1" ] || [ "${ENABLE_MC:-}" = "yes" ] || [ "${ENABLE_MC:-}" = "true" ]; then
  echo "mc           : enabled"
else
  echo "mc           : disabled"
fi

# show procps_ng build status
if [ "${ENABLE_PROCPS_NG:-0}" = "1" ] || [ "${ENABLE_PROCPS_NG:-}" = "yes" ] || [ "${ENABLE_PROCPS_NG:-}" = "true" ]; then
  echo "procps-ng    : enabled"
else
  echo "procps-ng    : disabled"
fi

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

# --- patch u-boot Version in defconfig ---
DEFCONFIG="${BR_DIR}/br2_external/configs/X6100_defconfig"
EXTERNAL_MK="${BR_DIR}/br2_external/external.mk"

if [ "${ENABLE_UBOOT:-0}" = "1" ] || [ "${ENABLE_UBOOT:-}" = "yes" ] || [ "${ENABLE_UBOOT:-}" = "true" ]; then
  echo ">>> Patch u-boot version in X6100_defconfig → ${UBOOT_BRANCH} ..."
  if [ -f "${DEFCONFIG}" ]; then
    sed -i "s|^BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE=\"2023.01\"|BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE=\"${UBOOT_BRANCH}\"|" "${DEFCONFIG}"
    echo ">>> u-boot version patched to ${UBOOT_BRANCH}"
  else
    echo "ERROR: ${DEFCONFIG} not found"
    exit 1
  fi

  # Patch for u-boot >= 2025.10 (COPYING → Licenses/gpl-2.0.txt)
  # Version Comparison: 2025.10 or later
  if [ "$(printf '%s\n' "2025.10" "${UBOOT_BRANCH}" | sort -V | head -n1)" = "2025.10" ] && [ "${UBOOT_BRANCH}" != "2025.10" ] || [ "${UBOOT_BRANCH}" = "2025.10" ]; then
    # Always use it when >= 2025.10
    if [ "$(printf '%s\n%s\n' "2025.10" "${UBOOT_BRANCH}" | sort -V | tail -n1)" = "${UBOOT_BRANCH}" ]; then
      echo ">>> Apply u-boot license patch for version >= 2025.10 ..."
      if [ -f "${EXTERNAL_MK}" ]; then
        # Add this only if it isn't already there
        if ! grep -q 'UBOOT_COPY_OLD_LICENSE_FILE' "${EXTERNAL_MK}"; then
          cat >> "${EXTERNAL_MK}" << 'EOF'

define UBOOT_COPY_OLD_LICENSE_FILE
	if [ -f $(@D)/COPYING ] && [ ! -f $(@D)/Licenses/gpl-2.0.txt ]; then \
		$(INSTALL) -m 0644 -D $(@D)/COPYING $(@D)/Licenses/gpl-2.0.txt; \
	fi
endef
UBOOT_POST_EXTRACT_HOOKS += UBOOT_COPY_OLD_LICENSE_FILE
EOF
          echo ">>> u-boot license patch applied."
        else
          echo ">>> u-boot license patch already present."
        fi
      else
        echo "WARNING: ${EXTERNAL_MK} not found – license patch skipped."
      fi
    fi
  fi
else
  echo ">>> u-boot version remains 2023.01 (set ENABLE_UBOOT=1 to override)."
fi
echo ""

# --- 3. GUI-Package local Path and Version ---
echo ">>> Patch x6100_gui.mk → local source ..."
MK="${BR_DIR}/br2_external/package/x6100-gui/x6100_gui.mk"
sed -i "s|^X6100_GUI_VERSION = v0.23.0-rc.3|X6100_GUI_VERSION = ${GUI_BRANCH}|g" "${MK}"
sed -i "s|https://github.com/OpenX6100/x6100_gui|${GUI_DIR}|g" "${MK}"
sed -i "s|^X6100_GUI_SITE_METHOD = git|X6100_GUI_SITE_METHOD = local|g" "${MK}"
sed -i "s|^X6100_GUI_GIT_SUBMODULES|# X6100_GUI_GIT_SUBMODULES|g" "${MK}"
echo ">>> Patch ok"
echo ""

# --- 4. Configure ---
echo ">>> br_config.sh ..."
cd "${BR_DIR}"
bash ./br_config.sh

# --- Optional: Midnight Commander (only if ENABLE_MC=1) ---
if [ "${ENABLE_MC:-0}" = "1" ] || [ "${ENABLE_MC:-}" = "yes" ] || [ "${ENABLE_MC:-}" = "true" ]; then
  echo ">>> Enable midnight commander in .config ..."
  if ! grep -q '^BR2_PACKAGE_MC=y' build/.config 2>/dev/null; then
    cd build
    if grep -q 'BR2_PACKAGE_MC' .config; then
      sed -i 's/^# BR2_PACKAGE_MC is not set/BR2_PACKAGE_MC=y/' .config || true
      sed -i 's/^BR2_PACKAGE_MC=n/BR2_PACKAGE_MC=y/' .config || true
    else
      echo 'BR2_PACKAGE_MC=y' >> .config
    fi
    make olddefconfig 2>/dev/null || true
    cd ..
  else
    echo ">>> Midnight commander already enabled."
  fi
else
  echo ">>> Midnight commander skipped (set ENABLE_MC=1 to enable)."
fi
echo ""

# --- Optional: procps-ng (only if ENABLE_PROCPS_NG=1) ---
if [ "${ENABLE_PROCPS_NG:-0}" = "1" ] || [ "${ENABLE_PROCPS_NG:-}" = "yes" ] || [ "${ENABLE_PROCPS_NG:-}" = "true" ]; then
  echo ">>> Enable procps-ng in .config ..."
  if ! grep -q '^BR2_PACKAGE_PROCPS_NG=y' build/.config 2>/dev/null; then
    cd build
    if grep -q 'BR2_PACKAGE_PROCPS_NG' .config; then
      sed -i 's/^# BR2_PACKAGE_PROCPS_NG is not set/BR2_PACKAGE_PROCPS_NG=y/' .config || true
      sed -i 's/^BR2_PACKAGE_PROCPS_NG=n/BR2_PACKAGE_PROCPS_NG=y/' .config || true
    else
      echo 'BR2_PACKAGE_PROCPS_NG=y' >> .config
    fi
    make olddefconfig 2>/dev/null || true
    cd ..
  else
    echo ">>> procps-ng already enabled."
  fi
else
  echo ">>> procps-ng skipped (set ENABLE_PROCPS_NG=1 to enable)."
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
sed -i "s|${GUI_DIR}|https://github.com/OpenX6100/x6100_gui|g" "${MK}"
sed -i "s|^X6100_GUI_SITE_METHOD = local|X6100_GUI_SITE_METHOD = git|g" "${MK}"
sed -i "s|^# X6100_GUI_GIT_SUBMODULES|X6100_GUI_GIT_SUBMODULES|g" "${MK}"
echo ""

# --- u-boot back to original Version for successful git pull ---
if [ "${ENABLE_UBOOT:-0}" = "1" ] || [ "${ENABLE_UBOOT:-}" = "yes" ] || [ "${ENABLE_UBOOT:-}" = "true" ]; then
  echo ">>> Revert u-boot version in X6100_defconfig → 2023.01 ..."
  if [ -f "${DEFCONFIG}" ]; then
    sed -i "s|^BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE=\"${UBOOT_BRANCH}\"|BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE=\"2023.01\"|" "${DEFCONFIG}"
    echo ">>> u-boot version reverted to 2023.01"
  fi
fi

# --- Remove u-boot License-Patch external.mk for successful git pull ---
if [ "${ENABLE_UBOOT:-0}" = "1" ] || [ "${ENABLE_UBOOT:-}" = "yes" ] || [ "${ENABLE_UBOOT:-}" = "true" ]; then
  if [ -f "${EXTERNAL_MK}" ] && grep -q 'UBOOT_COPY_OLD_LICENSE_FILE' "${EXTERNAL_MK}"; then
    echo ">>> Remove u-boot license patch from external.mk ..."
    # remove Block (define + Hook)
    sed -i '/^define UBOOT_COPY_OLD_LICENSE_FILE$/,/^endef$/d' "${EXTERNAL_MK}"
    sed -i '/^UBOOT_POST_EXTRACT_HOOKS += UBOOT_COPY_OLD_LICENSE_FILE$/d' "${EXTERNAL_MK}"
    # Clean up blank lines at the end
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${EXTERNAL_MK}" 2>/dev/null || true
    echo ">>> u-boot license patch removed."
  fi
fi

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
