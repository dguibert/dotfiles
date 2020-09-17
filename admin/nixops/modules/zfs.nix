{ config, lib, pkgs, utils, ... }:
{
  services.zfs.autoSnapshot.enable = false;
  services.zfs.autoSnapshot.flags = "-k -p --utc";

  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "monthly";
  services.zfs.trim.enable = false;

  boot.kernelParams = [ "elevator=none" ];
  boot.extraModprobeConfig = ''
    #options zfs zfs_arc_max=16777216
    # https://github.com/archzfs/archzfs/issues/187
    # in 4.13.x noop was renamed to none
    options zfs zfs_vdev_scheduler="none"

    # https://www.svennd.be/tuning-of-zfs-module/
    # increase them so scrub/resilver is more quickly at the cost of other work
    #options zfs zfs_vdev_scrub_min_active=24
    #options zfs zfs_vdev_scrub_max_active=64

    ## sync write
    #options zfs zfs_vdev_sync_write_min_active=2
    #options zfs zfs_vdev_sync_write_max_active=32

    ## sync reads (normal)
    #options zfs zfs_vdev_sync_read_min_active=2
    #options zfs zfs_vdev_sync_read_max_active=32

    ## async reads : prefetcher
    #options zfs zfs_vdev_async_read_min_active=2
    #options zfs zfs_vdev_async_read_max_active=32

    ## async write : bulk writes
    #options zfs zfs_vdev_async_write_min_active=2
    #options zfs zfs_vdev_async_write_max_active=32

    # use the prefetch method
    #options zfs zfs_prefetch_disable=0

    options zfs zfs_dirty_data_max_percent=40
    options zfs zfs_txg_timeout=15
  '';
}

