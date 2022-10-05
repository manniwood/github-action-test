#!/bin/bash

set -e
set -u
set -o pipefail

# HOW TO RUN: $ ./debify.sh <<software-version>> <<archive-file-version>>
#          eg $ ./debify.sh 1.3.0 1

# All other dirs are relative this one, the one this script lives in
# (See https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
#  for the trick used to get the dir this script lives in)
STARTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Get the version from the first command-line argument. Something like "1.3.0".
VERSION=${1}
# Get the deb version from the second command-line argument. Almost always "1".
DEBVERSION=${2}
DEBDIRNAME=foo-${VERSION}-${DEBVERSION}
DEBFILENAME=${DEBDIRNAME}.deb

# The deb-stuff dir is also relative the library
DEBSTUFF=${STARTDIR}/deb-stuff
if [ ! -d "$DEBSTUFF" ]; then
	echo "Directory $DEBSTUFF does not exist" 1>&2
	exit 1
fi

# We will build the deb in a subdir of the start dir,
# relative the library.
DEB_BUILD_DIR=${STARTDIR}/${DEBDIRNAME}

# The control dir will end up inside the .deb as control.tar.gz
# as per the .deb file spec
CTRLDIR=${DEB_BUILD_DIR}/DEBIAN
echo "STARTDIR=${STARTDIR}"
echo "DEB_BUILD_DIR=${DEB_BUILD_DIR}"
echo "CTRLDIR=${CTRLDIR}"
mkdir -p $CTRLDIR
mkdir -p $DEB_BUILD_DIR
mkdir -p ${DEB_BUILD_DIR}/etc/foo.d
cp ${STARTDIR}/etc/foo.conf ${DEB_BUILD_DIR}/etc/foo.d

# Sadly, dpkg-deb does not create the md5sum file for us
# IMPORTANT! Must say "lib/", not "./lib", so that md5sums file 
# has correctly formatted file paths
# important to cd to the build dir so that the paths in the md5sums file look right
cd ${DEB_BUILD_DIR}
touch ${CTRLDIR}/md5sums
find etc/ -type f -exec md5sum {} \; >> ${CTRLDIR}/md5sums

# copy the shell scripts into the control dir
cp ${DEBSTUFF}/* ${CTRLDIR}
# overwrite the contol file we just copied into the control dir,
# transforming the string "$VERSION" into the actual value of
# $VERSION, and the string "$DEBVERSION" into the actual value of
# $DEBVERSION
sed -e "s/\$VERSION/$VERSION/" -e "s/\$DEBVERSION/$DEBVERSION/" ${DEBSTUFF}/control > ${CTRLDIR}/control
dpkg-deb --build ${DEB_BUILD_DIR}
rm -rf ${DEB_BUILD_DIR}

