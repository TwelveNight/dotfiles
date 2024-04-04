# 手动挂载子卷
mount -t btrfs -o subvol=/@,compress=zstd /dev/nvme1n1p4 /mnt
mount /dev/nvme0n1p1 /mnt/boot
# chroot
arch-chroot /mnt
# 更新内核和软件包
pacman -Syyu
# 重启
reboot
