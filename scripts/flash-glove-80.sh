#!/bin/bash

set -eu

# Available mountpoint
MOUNTPOINT='/mnt'

if [ ! -d "$MOUNTPOINT" ]; then
	echo "Mountpoint '$MOUNTPOINT' is not a directory" >&2
	exit 1
fi

if [ "$(ls -A "$MOUNTPOINT")" != "" ]; then
	echo "Mountpoint '$MOUNTPOINT' is not empty" >&2
	exit 1
fi

list_block_devices() {
	lsblk --raw --noheadings --output=PATH | sort
}

wait_for_block_device() {
	prompt="${1:-}"
	if [ -z "$prompt" ]; then
		echo 'No prompt provided!' >&2
		exit 1
	fi

	original_blks="$(list_block_devices)"

	echo -n "$prompt" >&2

	new_blks=''

	while [ -z "$new_blks" ]; do
		sleep 1
		current_blks="$(list_block_devices)"
		new_blks="$(comm -1 -3 <(echo "$original_blks") <(echo "$current_blks"))"
		echo -n '.' >&2
	done
	echo >&2

	if [ "$(echo "$new_blks" | wc -l)" != '1' ]; then
		echo 'Found multiple block devices' >&2
		exit 1;
	fi;

	echo "$new_blks"
}

upload_firmware() {
	firmware_file="${1:-}"
	if [ -z "$firmware_file" ]; then
		echo 'No firmware_file provided!' >&2
		exit 1
	fi

	block_device="${2:-}"
	if [ -z "$block_device" ]; then
		echo 'No block_device provided!' >&2
		exit 1
	fi

	echo "mounting '$block_device' to '$MOUNTPOINT'" >&2
	sudo mount "$block_device" "$MOUNTPOINT"

	if [ ! -f "$MOUNTPOINT/current.uf2" ] && [ ! -f "$MOUNTPOINT/CURRENT.UF2" ]; then
		echo 'Could not find current firmware on device. Did it connect to the correct device?' >&2
		echo "WARNING: Leaving '$block_device' mounted to '$MOUNTPOINT'. 'sudo umount $MOUNTPOINT' to unmount." >&2
		exit 1
	fi

	echo -n "copying '$firmware_file' to '$MOUNTPOINT'" >&2
	sudo cp "$firmware_file" "$MOUNTPOINT"
	sync

	while [ "$(ls -A "$MOUNTPOINT")" != '' ]; do
		echo -n '.' >&2
		sleep 1
	done
	echo >&2
}

firmware_file_input="${1:-}"

if [ -z "$firmware_file_input" ]; then
	echo 'No firmware file provided!' >&2
	exit 1
fi

if ! file "$firmware_file_input" | grep -i uf2 -q; then
	echo 'Invalid file type! Should be uf2.' >&2
	exit 1
fi

rh_block_device="$(wait_for_block_device 'Plug in the RIGHT half and put it in bootloader mode (Magic + Æ)')"
upload_firmware "$firmware_file_input" "$rh_block_device"

lh_block_device="$(wait_for_block_device 'Plug in the LEFT half and put it in bootloader mode (Magic + Tab)')"
upload_firmware "$firmware_file_input" "$lh_block_device"
