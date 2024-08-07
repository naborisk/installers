#!/bin/bash
# Run this after you mount target disk to /mnt and EFI to /mnt/efi

#set -x

fdisk -l

read -p 'Disk to install to: ' DISK_DEVICE
echo "Selected disk: $DISK_DEVICE"
fdisk -l $DISK_DEVICE

read -p 'Hostname: ' HOSTNAME
read -p 'Username: ' USERNAME

is_mounted() {
  mount | grep $1 > /dev/null
}

if is_mounted $DISK_DEVICE; then
  echo "Disk is mounted. Please unmount it first"
  exit 1
fi

# partition disk with 512M EFI partition and the rest for root
fdisk $DISK_DEVICE <<EOF
g
n
1
2048
+512M
t
1
n
2


t
2
23
w
EOF

# determine partitions using sed and "lsblk -nlpo NAME ${DISK_DEVICE}"
PARTITION_1=$(lsblk -nlpo NAME ${DISK_DEVICE} | sed -n 2p)
PARTITION_2=$(lsblk -nlpo NAME ${DISK_DEVICE} | sed -n 3p)

# make EFI partition
mkfs -t msdos $PARTITION_1

# make root partition
mkfs.btrfs $PARTITION_2

mkdir -p /mnt
mount $PARTITION_2 /mnt

mkdir -p /mnt/efi
mount $PARTITION_1 /mnt/efi

FS_TYPE=$(df -Th /mnt/ | awk 'END{print $2}')
DEVICE=$(df /mnt/ | awk 'END{print $1}')

# prepare folder for kernel install
mkdir /mnt/efi/arch
mkdir /mnt/boot
mount --bind /mnt/efi/arch /mnt/boot

pacstrap /mnt base linux linux-firmware neovim sudo zsh networkmanager intel-ucode

# Set local time
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Japan /etc/localtime
arch-chroot /mnt hwclock --systohc

# Generate locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
sed -i 's/#ja_JP.UTF-8/ja_JP.UTF-8/g' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

# Set hostname and hosts file
echo $HOSTNAME > /mnt/etc/hostname

echo 127.0.0.1	localhost >> /mnt/etc/hosts
echo ::1		localhost >> /mnt/etc/hosts
echo 127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME >> /mnt/etc/hosts

# Enable NetworkManager
arch-chroot /mnt systemctl enable NetworkManager

# Copy boot files to EFI
#mkdir /mnt/efi/arch
#cp /mnt/boot/* /mnt/efi/arch/

# Installing and configuring systemd-boot
arch-chroot /mnt bootctl install --no-variables
echo 'title	Arch Linux
linux	arch/vmlinuz-linux
initrd	arch/intel-ucode.img
initrd	arch/initramfs-linux.img
options	root="LABEL=arch" intel_iommu=on iommu=pt rw' >> /mnt/efi/loader/entries/arch.conf
echo 'default	arch.conf
console-mode	max' >> /mnt/efi/loader/loader.conf

# Labeling the boot drive
case $FS_TYPE in
  ext4)
    e2label $DEVICE arch
    ;;
  btrfs)
    btrfs filesystem label /mnt arch
    ;;
esac

# Configure admin user
arch-chroot /mnt useradd -m -s /usr/bin/zsh $USERNAME
arch-chroot /mnt usermod -aG wheel $USERNAME

# Edit sudoers file and add user to group wheel
echo '%wheel ALL=(ALL:ALL) ALL' > /mnt/etc/sudoers.d/wheel

# unmount before generating fstab so that the bind mount wont stick
umount /mnt/boot

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "# bind /efi/arch to /boot to allow for kernel upgrades" >> /mnt/etc/fstab
echo "/efi/arch /boot none bind 0 0" >> /mnt/etc/fstab

# Set password for the admin user
arch-chroot /mnt passwd $USERNAME
