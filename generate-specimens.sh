#!/bin/bash
#
# Script to generate EWF test files

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1;

	which ${BINARY} > /dev/null 2>&1;
	if test $? -ne ${EXIT_SUCCESS};
	then
		echo "Missing binary: ${BINARY}";
		echo "";

		exit ${EXIT_FAILURE};
	fi
}

# Creates test file entries.
#
# Arguments:
#   a string containing the mount point
#
create_test_file_entries()
{
	MOUNT_POINT=$1;

	# Create a directory
	mkdir ${MOUNT_POINT}/a_directory;

	cat >${MOUNT_POINT}/a_directory/a_file <<EOT
This is a text file.

We should be able to parse it.
EOT

	cat >${MOUNT_POINT}/passwords.txt <<EOT
place,user,password
bank,joesmith,superrich
alarm system,-,1234
treasure chest,-,1111
uber secret laire,admin,admin
EOT

	cat >${MOUNT_POINT}/a_directory/another_file <<EOT
This is another file.
EOT

	(cd ${MOUNT_POINT} && ln -s a_directory/another_file a_link);
}

assert_availability_binary dd;
assert_availability_binary ewfacquire;

set -e;

mkdir -p test_data;

SPECIMENS_PATH="specimens";

mkdir -p ${SPECIMENS_PATH};

MOUNT_POINT="/mnt/ewf";

sudo mkdir -p ${MOUNT_POINT};


IMAGE_SIZE=$(( 4096 * 1024 ));
SECTOR_SIZE=512;

sudo mkdir -p ${MOUNT_POINT};

# Create test image with an EXT2 file system
IMAGE_FILE="${SPECIMENS_PATH}/ext2.raw";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

mke2fs -q -t ext2 -L "ext2_test" ${IMAGE_FILE};

sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT};

sudo chown ${USERNAME} ${MOUNT_POINT};

create_test_file_entries ${MOUNT_POINT};

sudo umount ${MOUNT_POINT};

# Create test E01 image with an ext2 file system
ewfacquire -u -c best -C case -D description -e examiner -E evidence -M logical -N notes -t ${SPECIMENS_PATH}/single ${SPECIMENS_PATH}/ext2.raw

# Create test split E01 image with an ext2 file system
ewfacquire -u -c none -C case -D description -e examiner -E evidence -M logical -N notes -S 3145728 -t ${SPECIMENS_PATH}/split ${SPECIMENS_PATH}/ext2.raw

# TODO: Create test Ex01 image with an ext2 file system

rm -f ${IMAGE_FILE}

