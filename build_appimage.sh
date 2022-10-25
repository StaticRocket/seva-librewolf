#!/bin/bash
printf "\n\n------------------------------------ APPIMAGE BUILD -----------------------------------------\n"

# Aborts the script upon any faliure
set -e

# Sets up script variables
PKGVER=106.0.1
PKGREL=1
BINARY_TARBALL=LibreWolf-${PKGVER}-${PKGREL}.${CARCH}.tar.bz2
APPIMAGE_FILE=LibreWolf-${PKGVER}-${PKGREL}.${CARCH}.AppImage
_SCRIPT_FOLDER=$(realpath "$(dirname "$0")")
_BINARY_TARBALL_EXTRACTED_FOLDER=$_SCRIPT_FOLDER/librewolf
_BUILD_APPIMAGE_FILE=$_SCRIPT_FOLDER/LibreWolf.${CARCH}.AppImage
_APPIMAGETOOL_DOWNLOAD_URL=https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-${CARCH}.AppImage
_APPIMAGETOOL_EXTRACTED_FOLDER=$_SCRIPT_FOLDER/squashfs-root
_APPIMAGETOOL_FILE=$_SCRIPT_FOLDER/appimagetool
_APPIMAGE_CONTENT_FOLDER=$_SCRIPT_FOLDER/content

# Installs needed dependencies
apt-get update && apt-get -y install file wget bzip2 libdbus-glib-1-2 gnupg2

wget "https://gitlab.com/api/v4/projects/12829184/packages/generic/librewolf/${PKGVER}-${PKGREL}/${BINARY_TARBALL}"

if [[ ! -f "${BINARY_TARBALL}" ]]; then
  echo "Tarball not provided via pipeline or download."
  exit 1
fi

if [[ $CARCH == 'aarch64' ]]; then
  apt install -y zlib1g-dev
fi

# Extracts the binary tarball
printf "\nExtracting librewolf binary tarball\n"
mkdir "$_BINARY_TARBALL_EXTRACTED_FOLDER"
tar -xvf "$BINARY_TARBALL" -C "$_BINARY_TARBALL_EXTRACTED_FOLDER"

# Copy appimage resources to main tarball
printf "Copying AppImage resources to binary tarball folder\n"
cp -vrT "$_APPIMAGE_CONTENT_FOLDER" "$_BINARY_TARBALL_EXTRACTED_FOLDER"

# Downloads appimage tool
printf "\nDownloading AppImage Tool\n"
apt -qq update && apt -qqy install wget
wget "$_APPIMAGETOOL_DOWNLOAD_URL" -O "$_APPIMAGETOOL_FILE"
chmod +x "$_APPIMAGETOOL_FILE"

# add appstream metadata
install -Dvm644 "$_BINARY_TARBALL_EXTRACTED_FOLDER/io.gitlab.librewolf-community.appdata.xml" "$_BINARY_TARBALL_EXTRACTED_FOLDER/usr/share/metainfo/io.gitlab.librewolf-community.appdata.xml"
rm -f "$_BINARY_TARBALL_EXTRACTED_FOLDER/io.gitlab.librewolf-community.appdata.xml"

# provide icons for appimage-launcher
install -D -m644 "$_BINARY_TARBALL_EXTRACTED_FOLDER/browser/chrome/icons/default/default128.png" "$_BINARY_TARBALL_EXTRACTED_FOLDER/usr/share/icons/hicolor/128x128/apps/librewolf.png"

# add libdbus-glib-1.so.2, just in case
install -Dvm644 "/usr/lib/${CARCH}-linux-gnu/libdbus-glib-1.so.2" "$_BINARY_TARBALL_EXTRACTED_FOLDER/usr/lib/libdbus-glib-1.so.2"

# add x11 libs
apt-get -o Dir="$_BINARY_TARBALL_EXTRACTED_FOLDER" -o Debug::NoLocking=1 install libX11

# import signing key
#gpg2 --import "${SIGNING_KEY}"

# Generate AppImage
printf "\nGenerating AppImage\n"
ARCH=${CARCH} "$_APPIMAGETOOL_FILE" --appimage-extract-and-run \
  -u "zsync|https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/latest/LibreWolf.${CARCH}.AppImage.zsync" \
  "$_BINARY_TARBALL_EXTRACTED_FOLDER" "$_BUILD_APPIMAGE_FILE"
chmod +x "$_BUILD_APPIMAGE_FILE"

# Move AppImage to specified location
printf "\nMoving AppImage to specified location\n"
mv "${_BUILD_APPIMAGE_FILE}" "${APPIMAGE_FILE}"
mv "${_BUILD_APPIMAGE_FILE}.zsync" "${APPIMAGE_FILE}.zsync"

# Cleanup files
printf "\nCleaning up AppImage files\n"
rm -rf "$_BINARY_TARBALL_EXTRACTED_FOLDER"
rm -f "$_APPIMAGETOOL_FILE"
rm -rf "$_APPIMAGETOOL_EXTRACTED_FOLDER"
