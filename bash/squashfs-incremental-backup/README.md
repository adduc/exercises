# Full/Incremental Backups using SquashFS and OverlayFS

## Context

I previously created some scripts to create full backups using SquashFS. I want to build on those scripts to implement incremental backups through the use of OverlayFS.

## Notes

https://www.kernel.org/doc/Documentation/filesystems/overlayfs.txt


Goals:
- If no backups exist, or latest full backup is older than 7 days, create a full backup.
  - Rsync to backup directory, create squashfs image
- If latest full backup is less than 7 days old, create an incremental backup.
  - Remove working directory
  - mount latest full backup and incremental backups since the last full backup
  - Create overlayfs in backup directory
  - Rsync to backup directory, create squashfs image


- overlay has a 128 lower directory limit, so we need to be careful with incremental backups
  - consider a process to flatten images after a specific quantity to
    avoid exceeding the limit and to keep the number of images we need to mount at a time to a minimum
  - flatten image could be an "incremental checkpoint", where we only
    need to mount the latest full backup, the latest flattened image, and the incremental backups since the last flattened image

- consider storing backup images into separate directories
  - e.g. full, flattened, weekly, daily, hourly
  - this might make it easier to write retention processes







  overlay /var/lib/docker/overlay2/611a74271350bfca9a764ccab9752f465dde66652427722d589427a5a788c997/merged overlay rw,seclabel,relatime,lowerdir=/var/lib/docker/overlay2/l/6ZXLOVEPKN4ESFVTPZR3REWNF2:/var/lib/docker/overlay2/l/SLF6E6YC3EXM5UYUBSJSFQAYRZ:/var/lib/docker/overlay2/l/NWWV27XMJBKK4ORJT6LWR6WLXW:/var/lib/docker/overlay2/l/K4ITVNHYX7MRCCFFO2Y5QPGBMF:/var/lib/docker/overlay2/l/K3LLOA2UTUDTQJB3YMF74VPBRO,upperdir=/var/lib/docker/overlay2/611a74271350bfca9a764ccab9752f465dde66652427722d589427a5a788c997/diff,workdir=/var/lib/docker/overlay2/611a74271350bfca9a764ccab9752f465dde66652427722d589427a5a788c997/work 0 0