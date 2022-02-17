{ config, lib, pkgs, utils, ... }:
{
  services.zfs.autoSnapshot.enable = false;
  services.zfs.autoSnapshot.flags = "-k -p --utc";

  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "monthly";
  services.zfs.trim.enable = false; # per zpool?

  #boot.kernelParams = [ "elevator=none" ];
  # 64GB  = 68719476736
  # 32GB  = 34359738368
  # 24GB  = 25769803776
  # 16GB  = 17179869184
  # 8GB   = 8589934592
  # 4GB   = 4294967296
  # 2GB   = 2147483648
  # 1GB   = 1073741824
  # 500MB = 536870912
  # 250MB = 268435456
  #boot.initrd.extraModprobeConfig = ''
  #  # 24G
  #  options zfs zfs_arc_max=25769803776
  #  # https://github.com/archzfs/archzfs/issues/187
  #  # in 4.13.x noop was renamed to none
  #  # https://github.com/openzfs/zfs/commit/9e17e6f2541c69a7a5e0ed814a7f5e71cbf8b90a
  #  #options zfs zfs_vdev_scheduler="none"

  #  # https://www.svennd.be/tuning-of-zfs-module/
  #  # increase them so scrub/resilver is more quickly at the cost of other work
  #  #options zfs zfs_vdev_scrub_min_active=24
  #  #options zfs zfs_vdev_scrub_max_active=64

  #  ## sync write
  #  #options zfs zfs_vdev_sync_write_min_active=2
  #  #options zfs zfs_vdev_sync_write_max_active=32

  #  ## sync reads (normal)
  #  #options zfs zfs_vdev_sync_read_min_active=2
  #  #options zfs zfs_vdev_sync_read_max_active=32

  #  ## async reads : prefetcher
  #  #options zfs zfs_vdev_async_read_min_active=2
  #  #options zfs zfs_vdev_async_read_max_active=32

  #  ## async write : bulk writes
  #  #options zfs zfs_vdev_async_write_min_active=2
  #  #options zfs zfs_vdev_async_write_max_active=32

  #  # use the prefetch method
  #  options zfs zfs_prefetch_disable=0

  #  options zfs zfs_dirty_data_max_percent=40
  #  options zfs zfs_txg_timeout=15
  #'';
}

