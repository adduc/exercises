# Backing up to an luks-encrypted squashfs image

This exercise shows how a backup can be created using an LUKS-encrypted squashfs image for secure storage.

## Context

I would like to start backing up some data periodically to optical media, but would prefer not to store the files unencrypted. While solutions exist like duplicity that can encrypt, compress, and deduplicate data, I would like to use a simple solution that can be easily mounted and accessed.

## Requirements

- rsync: used to copy files to the backup directory
- squashfs-tools: used to create a squashfs image from the backup directory
- cryptsetup: used to create and manage the LUKS-encrypted image
- openssl (optional): used to create a random key for the LUKS-encrypted image
- growisofs (optional): used to burn the LUKS-encrypted image to a DVD or Blu-ray disc

## Steps

1. Copy `.dist.env` to `.env` and edit the variables to match your system.
2. Copy `rsync.dist.exclude` to `rsync.exclude` to accommodate the files you want to exclude from the backup.
3. Run `make backup` to create the backup directory and copy the files to it using `rsync`.
4. Run `make create-squashfs-image` to create a squashfs image from the backup directory.
5. (Optional) Run `generate-luks-keyfile` to generate a random key for the LUKS-encrypted image using OpenSSL.
6. Run `make create-encrypted-image` to create a LUKS-encrypted image from the squashfs image.
7. (Optional) Run `make burn-disc` to burn the LUKS-encrypted image to a DVD or Blu-ray disc.