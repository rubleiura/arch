# ################################################################
# #### Макет блочной установки Arch Linux (BTRFS + SNAPPER) ######
# ################################################################
#
# 🔹 Назначение: Быстрая, гибкая и понятная установка Arch Linux
# 🔹 Метод: Копируйте и вставляйте по одному блоку за раз
# 🔹 Важно: Не запускайте как скрипт! Выполняйте вручную.
#
# Структура:
#   1. Подготовка (SSH, Live-среда)
#   2. Диагностика и разметка диска
#   3. Монтирование и установка базовой системы
#   4. Конфигурация внутри chroot
#   5. Установка DE и пост-установочные действия
#
# Все комментарии — сверху. Команды — чистые, без справа.






## ################################################################
# ## 🔐 БЛОК 1: ОПТИМИЗАЦИЯ SSH (ТОЛЬКО ПРИ УСТАНОВКЕ ЧЕРЕЗ SSH) ##
# #################################################################
#
# Зачем: Ускорение и стабильность при удалённой установке.
# Важно: Только если вы подключены по SSH. Необязательно при локальной установке.
# Эффект: Уменьшение задержек, отключение DNS, ускорение сессии.





clear
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/^#*Compression .*/Compression yes/' /etc/ssh/sshd_config
sed -i 's/^#*TCPKeepAlive .*/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveInterval .*/ClientAliveInterval 60/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveCountMax .*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
sed -i 's/^#*UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#*MaxStartups .*/MaxStartups 10:30:100/' /etc/ssh/sshd_config
sed -i 's/^#*Ciphers .*/Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com/' /etc/ssh/sshd_config
systemctl restart sshd
clear
echo ""
echo "#####################################"
echo "## <<< НАСТРОЙКА SSH ЗАВЕРШЕНА >>> ##"
echo "#####################################"
echo ""
grep -E 'Compression|TCPKeepAlive|ClientAlive|UseDNS|MaxStartups|Ciphers' /etc/ssh/sshd_config
echo ""






##########################################################
# ## ⚙️ БЛОК 2: ПОДГОТОВКА LIVE-СРЕДЫ ####################
# ########################################################
#
# Зачем: Подготовка системы: часы, клавиатура, зеркала, обновление.
# Важно: Выполняется в Live-среде (до chroot).
# Включает: Русская раскладка, обновление зеркал, haveged.





clear
timedatectl set-ntp true
loadkeys ru
setfont cyr-sun16
sed -i "s/#\(en_US\.UTF-8\)/\1/" /etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
sed -i 's/ParallelDownloads = 5/ParallelDownloads = 15/' /etc/pacman.conf
pacman -Syy
pacman -S --noconfirm pacman-contrib curl haveged archlinux-keyring inxi util-linux lshw
systemctl enable haveged.service --now
clear
echo ""
echo "##############################################"
echo "## <<< ПОДГОТОВКА К УСТАНОВКЕ ЗАВЕРШЕНА >>> ##"
echo "##############################################"
echo ""





# ######################################################
# ## 🔍 БЛОК 3: ДИАГНОСТИКА ОБОРУДОВАНИЯ ###############
# ######################################################
#
# Зачем: Проверка железа перед установкой и настройкой.
# Важно: Сравните с переменными в следующем блоке.
# Показывает: Процессор, материнка, диски, разделы.




clear && { \
echo "Таблица дисков и разделов:"; \
echo; \
for DEVICE in $(lsblk -dno NAME 2>/dev/null | grep -v -e '^loop' -e '^sr'); do \
    DEVICE_PATH="/dev/$DEVICE"; \
    [[ ! -b "$DEVICE_PATH" ]] && continue; \
    ROTA=$(lsblk -d -o ROTA --noheadings "$DEVICE_PATH" 2>/dev/null | awk '{print $1}'); \
    if [[ "$ROTA" == "1" ]]; then \
        DISK_TYPE="HDD"; \
        MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:2,autodefrag"; \
    else \
        DISK_TYPE="SSD"; \
        MOUNT_OPTIONS="ssd,noatime,space_cache=v2,compress=zstd:2,discard=async"; \
    fi; \
    echo "╔═══════════════════════════════════════════════════════════════════════════════════════════════════╗"; \
    printf "║  Диск: %-60s\n" "/dev/$DEVICE"; \
    echo "╠═══════════════════════════════════════════════════════════════════════════════════════════════════╣"; \
    printf "║  Тип: %-60s\n" "$DISK_TYPE"; \
    printf "║  Параметры: %-60s\n" "$MOUNT_OPTIONS"; \
    echo "╚═══════════════════════════════════════════════════════════════════════════════════════════════════╝"; \
    echo; \
done; \
}
echo ""
lsblk
echo ""
echo "Производитель процессора:"
lshw -C cpu 2>/dev/null | grep 'vendor:' | uniq
echo ""
echo "Материнская плата:"
inxi -M
echo ""
echo "Общая информация о системе:"
inxi -I
echo ""
echo "#################################################"
echo "## <<< ТЕСТИРОВАНИЕ КОМПЬЮТЕРА ЗАКОНЧИЛОСЬ >>> ##"
echo "#################################################"
echo ""





# ########################################################
# ## 🔧 БЛОК 4: НАСТРОЙКА ПЕРЕМЕННЫХ (ОБЯЗАТЕЛЬНО!) ######
# ########################################################
#
# Зачем: Настройка под ваше оборудование.
# Важно: Измените значения, если они не совпадают с тестом выше.
# Особое внимание ко всем переменным




##########################################################################
## Этот пункт предназначен для изменения переменных.                    ##
## Он обязателен.Иначе установка системы  может пойти с ошибками.       ##
## Если параметры из раздела Тестирования не совпадают с параметрами    ##
## раздела Переменные, необходимо с помощью текстового редактора        ##
## провести групповое переименование переменных в таблице ниже,         ##
## чтобы они соответствовали результатам тестирования.                  ##
## По желанию можно изменить параметры пользователя, компьютера и ядра. ##
##########################################################################
## Разметка Диска                                                       ##
## Для разиетки дисков ипользуется отдельная переменная sdx, что        ##
## тождественно выбранному для разметки диска sda, sdb итд.             ##
## Для чего это делается? Для того, чтоб не затрагивать параметры       ##
## переменых после разметки(разделов монтирования).                     ##
## Изменение переменной разметки и саму размету делать в первую очередь ##
## Изменение переменых разделов, только после разметки диска, причём    ##
## Изменять переменные разделов(sda1,sda2,sda3) необходимо в первую     ##
## очередь, после чего можно изменить переменную самого диска(sda)      ##
## Тестирование из блока 3 можно производить пока не заполним все       ##
## переменные, после чего можно с уверенностью выполнять установку      ##
## ArchLinux!!!                                                         ##
##########################################################################



########################################################
#             Объект             #   Переменная        #
########################################################
#             Имя                #  login	           #
########################################################
#             Полное имя         #  User Name          #
########################################################
#             HOSTNAME 	         #  Sony               #
########################################################
#             Microcode	         #  amd-ucode          #
########################################################
#               Ядро	         #  linux-lts          #
########################################################
#            размер SWAP	     #	4G                 #
########################################################
#         Диск для разметки      #  sdx                #
########################################################
# Разделы диска для монтирования #  sda1 sda2 sda3 sda #
########################################################
#############################################################
#                     BTRFS (SSD/HDD)                       #
#############################################################
# Если система ставится на SSD, ни чего не делайте          #
# Если система ставится на HDD, необходимо                  #
# изменить параметры btrfs прямо здесь c SSD                #
# ssd,noatime,space_cache=v2,compress=zstd:2,discard=async  #
# на HDD :                                                  #
# noatime,space_cache=v2,compress=zstd:2,autodefrag         #
#############################################################







# #################################################
# ## 🗂️ БЛОК 5: РАЗМЕТКА ДИСКА (GPT + BIOS) #######
# #################################################
#
# Зачем: Создание разделов: BIOS Boot, root, swap.
# Важно: Все данные будут удалены!
# Используется: sgdisk для точной разметки.





clear
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
sgdisk -a 2048 -o /dev/sdx
sgdisk -n 1:0:+1M -t 1:ef02 -c 1:'BIOS Boot Arch' /dev/sdx
sgdisk -n 2:0:-4G -t 2:8300 -c 2:'System Arch Linux' /dev/sdx
sgdisk -n 3:0:0 -t 3:8200 -c 3:'Swap Arch Linux' /dev/sdx
clear
echo ""
gdisk -l /dev/sdx
fdisk -l /dev/sdx
echo ""
echo ""
echo "######################################"
echo "## <<< РАЗМЕТКА ДИСКА ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""






# #######################################################
# ## 💾 БЛОК 6: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ###########
# #######################################################
#
# Зачем: Форматирование, создание подтомов Btrfs, монтирование.
# Важно: Выполняется до chroot.
# Подтомы: @, @home, @log, @pkg.





clear
mkswap /dev/sda3
swapon /dev/sda3
mkfs.btrfs -f /dev/sda2
mount /dev/sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
umount /mnt
mount -o ssd,noatime,space_cache=v2,compress=zstd:2,discard=async,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
mount -o ssd,noatime,space_cache=v2,compress=zstd:2,discard=async,subvol=@home /dev/sda2 /mnt/home
mount -o ssd,noatime,space_cache=v2,compress=zstd:2,discard=async,subvol=@log /dev/sda2 /mnt/var/log
mount -o ssd,noatime,space_cache=v2,compress=zstd:2,discard=async,subvol=@pkg /dev/sda2 /mnt/var/cache/pacman/pkg
clear
echo ""
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/sda
echo ""
lsblk /dev/sda
echo ""
btrfs subvolume list /mnt
echo ""
echo "##############################################################"
echo "## <<< ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ РАЗДЕЛОВ ЗАВЕРШЕНО >>> ##"
echo "##############################################################"
echo ""







# ########################################################
# ## 🧱 БЛОК 7: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ###############
# ########################################################
#
# Зачем: Установка минимальной системы и переход в chroot.
# Важно: После этого — вход в chroot.
# Включает: base, btrfs, nano, reflector, pacman-contrib.







clear
pacstrap /mnt base base-devel
pacstrap /mnt archlinux-keyring
pacstrap /mnt btrfs-progs
pacstrap /mnt amd-ucode
pacstrap /mnt memtest86+
pacstrap /mnt nano
pacstrap /mnt reflector pacman-contrib curl
genfstab -pU /mnt >> /mnt/etc/fstab
clear
echo ""
echo "##################################################"
echo "## <<< УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА >>> ##"
echo "## <<< СОВЕРШАЕМ ВХОД В СИСТЕМУ (chroot)    >>> ##"
echo "##################################################"
echo ""
arch-chroot /mnt /bin/bash
echo ""






# ########################################################
# ## 🔁 БЛОК 8: НАСТРОЙКИ ВНУТРИ СИСТЕМЫ (chroot) #######
# ########################################################
#
# Зачем: Настройка системы: локали, fstab, время, зеркала.
# Важно: Выполняется внутри chroot.
# Автоматизация: Временная зона по IP, зеркала по стране.







clear
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,ssd,noatime,space_cache=v2,compress=zstd:2,discard=async/g'  /etc/fstab
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "LC_MESSAGES=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_TIME=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_NUMERIC=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_MONETARY=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_COLLATE=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_CTYPE=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_NAME=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_ADDRESS=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_TELEPHONE=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_MEASUREMENT=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_PAPER=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_IDENTIFICATION=ru_RU.UTF-8" >> /etc/locale.conf
sed -i "s/#\(en_US\.UTF-8\)/\1/" /etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
time_zone=$(curl -s https://ipinfo.io/timezone)
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
pacman -Syy
COUNTRY=$(curl -s https://ipapi.co/country_code)
sudo curl -L "https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=https" -o /etc/pacman.d/mirrorlist.raw
sudo sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.raw
sudo rankmirrors -n 5 /etc/pacman.d/mirrorlist.raw > /etc/pacman.d/mirrorlist
sudo rm /etc/pacman.d/mirrorlist.raw
systemctl enable reflector.timer
clear
echo ""
timedatectl status
echo ""
date
echo ""
echo "############################################"
echo "## <<< ПЕРВОНАЧАЛЬНАЯ НАСТРОЙКА ЗАВЕРШЕНА ##"
echo "############################################"
echo ""





# #######################################################
# ## 🖋️ БЛОК 9: НАСТРОЙКА NANO (chroot) #################
# #######################################################
#
# Зачем: Глубокая настройка редактора nano.
# Включает: Цвета, подсветку, автоотступы, табы, softwrap.






clear
sed -i 's/# set autoindent/set autoindent/g' /etc/nanorc
sed -i 's/# set constantshow/set constantshow/g' /etc/nanorc
sed -i 's/# set indicator/set indicator/g' /etc/nanorc
sed -i 's/# set linenumbers/set linenumbers/g' /etc/nanorc
sed -i 's/# set multibuffer/set multibuffer/g' /etc/nanorc
sed -i 's/# set quickblank/set quickblank/g' /etc/nanorc
sed -i 's/# set smarthome/set smarthome/g' /etc/nanorc
sed -i 's/# set softwrap/set softwrap/g' /etc/nanorc
sed -i 's/# set tabsize 8/set tabsize 4/g' /etc/nanorc
sed -i 's/# set tabstospaces/set tabstospaces/g' /etc/nanorc
sed -i 's/# set trimblanks/set trimblanks/g' /etc/nanorc
sed -i 's/# set unix/set unix/g' /etc/nanorc
sed -i 's/# set wordbounds/set wordbounds/g' /etc/nanorc
sed -i 's/# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/g' /etc/nanorc
sed -i 's/# set promptcolor black,yellow/set promptcolor black,yellow/g' /etc/nanorc
sed -i 's/# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/g' /etc/nanorc
sed -i 's/# set errorcolor bold,white,red/set errorcolor bold,white,red/g' /etc/nanorc
sed -i 's/# set spotlightcolor black,orange/set spotlightcolor black,orange/g' /etc/nanorc
sed -i 's/# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/g' /etc/nanorc
sed -i 's/# set stripecolor ,yellow/set stripecolor ,yellow/g' /etc/nanorc
sed -i 's/# set scrollercolor magenta/set scrollercolor magenta/g' /etc/nanorc
sed -i 's/# set numbercolor magenta/set numbercolor magenta/g' /etc/nanorc
sed -i 's/# set keycolor lightmagenta/set keycolor lightmagenta/g' /etc/nanorc
sed -i 's/# set functioncolor magenta/set functioncolor magenta/g' /etc/nanorc
sed -i 's/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g' /etc/nanorc
clear
echo ""
echo "######################################"
echo "## <<< НАСТРОЙКА NANO ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""








# ########################################################
# ## 🔐 БЛОК 10: HOSTNAME И ПАРОЛЬ ROOT (chroot) #########
# ########################################################
#
# Зачем: Настройка имени системы и пароля root.
# Важно: Без этого система не загрузится корректно.





clear
echo "Sony" > /etc/hostname
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Sony.localdomain   Sony" >> /etc/hosts
clear
echo ""
echo "###################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ROOT >>> ##"
echo "###################################"
echo ""
passwd
clear
echo ""
echo "##############################################"
echo "## <<<  НАСТРОЙКА ROOT И HOST ЗАВЕРШЕНА >>> ##"
echo "##############################################"
echo ""





# #######################################################
# ## 👤 БЛОК 11: ПОЛЬЗОВАТЕЛЬ И SUDO (chroot) ###########
# #######################################################
#
# Зачем: Создание пользователя и настройка sudo.
# Важно: Без wheel — sudo не будет работать.






clear
useradd login -m -c "User Name" -s /bin/bash
usermod -aG wheel,users login
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
clear
echo ""
echo "###########################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ >>> ##"
echo "###########################################"
echo ""
passwd login
clear
echo ""
echo "###############################################"
echo "## <<<  НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ ЗАВЕРШЕНА >>> ##"
echo "###############################################"
echo ""





# #######################################################
# ## 🔧 БЛОК 12: УСТАНОВКА ЯДРА, GRUB, MKINITCPIO #######
# #######################################################
#
# Зачем: Настройка загрузчика и initramfs.
# Включает: GRUB, grub-btrfs, plymouth, resume из swap.






clear
pacman -Syy
pacman -S --noconfirm linux-lts linux-lts-headers linux-firmware
pacman -S --noconfirm grub grub-btrfs os-prober
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools
pacman -S --noconfirm openssh
pacman -S --noconfirm plymouth
systemctl enable NetworkManager.service grub-btrfsd.service sshd.service
grub-install --recheck /dev/sda
SWAP_UUID=$(blkid -s UUID -o value /dev/sda3)
sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\".*\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash plymouth resume=UUID=${SWAP_UUID} udev.log_priority=3 rootflags=subvol=@\"|" /etc/default/grub
sed -i "s/#GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/" /etc/default/grub-btrfs/config
sed -i "s/#GRUB_BTRFS_TITLE_FORMAT=(\"timedatectl status\" \"snapshot\" \"type\" \"description\")/GRUB_BTRFS_TITLE_FORMAT=(\"description\" \"date\")/" /etc/default/grub-btrfs/config
sed -i 's/ProtectSystem=strict/ProtectSystem=full/' /usr/lib/systemd/system/mkinitcpio-generate-shutdown-ramfs.service
sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's|^HOOKS=.*|HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap block grub-btrfs-overlayfs btrfs filesystems fsck resume)|' /etc/mkinitcpio.conf
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "##################################################"
echo "##    УСТАНОВКА БАЗОВОЙ СИСТЕМЫ ЗАВЕРШЕНА       ##"
echo "##         И ГОТОВА К ИСПОЛЬЗОВАНИЮ.            ##"
echo "##  ПРИ ЖЕЛАНИИ ВЫ МОЖЕТЕ ВЫЙТИ ИЗ УСТАНОВЩИКА, ##"
echo "##         ЛИБО ПРОДОЛЖИТЬ УСТАНОВКУ.           ##"
echo "##################################################"
echo ""







# #######################################################
# ## 🧰 БЛОК 13: СИСТЕМНЫЕ УТИЛИТЫ И WAYLAND (chroot) ###
# #######################################################
#
# Зачем: Установка системных утилит, PipeWire, шрифтов.
# Включает: Bluetooth, CUPS, xdg, PipeWire, Wayland.






clear
pacman -Syy
pacman -S --noconfirm haveged
systemctl enable haveged.service
pacman -S --noconfirm wget vim usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
pacman -S --noconfirm dosfstools ntfs-3g btrfs-progs exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
pacman -S --noconfirm cronie chrony
systemctl enable cronie.service chronyd.service
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
pacman -S --noconfirm cups cups-pdf ghostscript gsfonts avahi hplip system-config-printer
systemctl enable cups.service avahi-daemon.service
pacman -S --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
pacman -S --noconfirm udisks2 udiskie polkit
pacman -S --noconfirm wireplumber pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
systemctl --global enable pipewire pipewire-pulse wireplumber
pacman -S --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss vlc
pacman -S --noconfirm man-db man-pages man-pages-ru
pacman -S --noconfirm ttf-dejavu noto-fonts noto-fonts-emoji
pacman -S --noconfirm iproute2 inetutils dnsutils
pacman -S --noconfirm fastfetch hyfetch inxi
clear
pacman -S --noconfirm mesa vulkan-icd-loader libglvnd
pacman -S --noconfirm wayland wayland-protocols
pacman -S --noconfirm libinput libxkbcommon seatd
systemctl enable seatd.service  # Для управления правами доступа к GPU
mkinitcpio -P
clear
echo ""
echo "###############################################################"
echo "## <<<  УСТАНОВКА СИСТЕМНЫХ ПРОГРАММ И WAYLAND ЗАВЕРШЕНА >>> ##"
echo "###############################################################"
echo ""
echo "##############################################"
echo "## <<<  ВИДЕОКАРТЫ  ДАННОГО КОМПЬЮТЕРА  >>> ##"
echo "## <<< ВЫБЕРИТЕ ДРАЙВЕРА СОГЛАСНО ТЕСТУ >>> ##"
echo "##############################################"
echo ""
echo "Видеокарты:" && lspci -nn | grep -i 'vga' ; echo "Драйверы:" && lsmod | grep -iE 'nvidia|amdgpu|i915'
echo ""
echo ""







# ########################################################
# ## 🖥️ БЛОК 14: УСТАНОВКА VIRTUALBOX (chroot) ###########
# ########################################################
#
# Зачем: Настройка интеграции с VirtualBox.
# Важно: Только если установка в VirtualBox.




clear
pacman -S --needed --noconfirm virtualbox-guest-utils
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice.service
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
mkinitcpio -P
usermod -aG vboxsf $USERNAME
clear
echo ""
echo "#############################################"
echo "## <<<  НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""





########################################################
############### Установка графической оболочки #########
########################################################




# #######################################################
# ## 🌌 БЛОК 15: УСТАНОВКА KDE PLASMA ###################
# #######################################################
#
# Зачем: Установка полной среды KDE Plasma.
# Включает: Все компоненты, SDDM, kde-apps.



clear
pacman -Syy
pacman -S --noconfirm plasma-desktop plasma-workspace kwin kwin-x11 kwayland libplasma kdecoration layer-shell-qt plasma5support
pacman -S --noconfirm kdeplasma-addons plasma-systemmonitor plasma-sdk
pacman -S --noconfirm breeze breeze-gtk aurorae oxygen qqc2-breeze-style oxygen-sounds ocean-sound-theme kgamma
pacman -S --noconfirm kactivitymanagerd plasma-activities plasma-activities-stats kinfocenter ksystemstats libksysguard powerdevil kmenuedit kde-cli-tools kwrited milou
pacman -S --noconfirm systemsettings kde-gtk-config kscreen libkscreen plasma-nm plasma-pa plasma-firewall sddm-kcm plymouth-kcm krdp flatpak-kcm wacomtablet plasma-disks plasma-thunderbolt
pacman -S --noconfirm kscreenlocker polkit-kde-agent kwallet-pam ksshaskpass plasma-vault
pacman -S --noconfirm bluedevil plasma-disks plasma-thunderbolt kpipewire
pacman -S --noconfirm discover spectacle drkonqi print-manager plasma-welcome
pacman -S --noconfirm ark filelight kate kcalc kfind yakuake
pacman -S --noconfirm audiocd-kio elisa gwenview okular
systemctl enable sddm
clear
echo ""
echo "#############################################"
echo "## <<<  УСТАНОВКА KDE PLASMA ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""





# #######################################################
# ## 🌐 БЛОК 16: УСТАНОВКА GNOME ########################
# #######################################################
#
# Зачем: Установка GNOME с полной интеграцией.
# Включает: GDM, portal, apps, extensions.




clear
pacman -Syy
pacman -S --noconfirm gnome-shell gdm gnome-session gnome-control-center gnome-settings-daemon
pacman -S --noconfirm gnome-keyring gvfs grilo-plugins xdg-desktop-portal-gnome xdg-user-dirs-gtk
pacman -S --noconfirm nautilus gnome-software epiphany gnome-console gnome-text-editor
pacman -S --noconfirm gnome-music totem loupe eog gnome-snapshot simple-scan
pacman -S --noconfirm gnome-calculator gnome-calendar gnome-clocks gnome-characters gnome-contacts gnome-weather gnome-maps gnome-disk-utility gnome-font-viewer gnome-logs gnome-color-manager baobab
pacman -S --noconfirm gnome-connections gnome-remote-desktop gnome-user-share
pacman -S --noconfirm gnome-user-docs yelp orca gnome-tour
pacman -S --noconfirm rygel sushi malcontent
pacman -S --noconfirm gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-smb gvfs-nfs gvfs-google gvfs-onedrive gvfs-goa gvfs-dnssd gvfs-wsdd
systemctl enable gdm
echo "[User]" > /var/lib/AccountsService/users/root
echo "SystemAccount=true" >> /var/lib/AccountsService/users/root
pacman -S --noconfirm dconf-editor eog file-roller gnome-devel-docs gnome-multi-writer gnome-notes gnome-sound-recorder gnome-terminal gnome-tweaks seahorse sysprof
pacman -S --noconfirm gnome-browser-connector gnome-firmware gnome-shell-extension-appindicator gnome-shell-extension-arc-menu gnome-shell-extension-dash-to-panel gnuchess power-profiles-daemon squashfs-tools
pacman -S --noconfirm gthumb gtkmm3 system-config-printer deja-dup
pacman -S --noconfirm adw-gtk-theme gnome-themes-extra
pacman -S --noconfirm ffmpegthumbnailer
clear
echo ""
echo "########################################"
echo "## <<<  УСТАНОВКА GNOME ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""





# ########################################################
# ## 🪟 БЛОК 17: УСТАНОВКА XFCE4 #########################
# ########################################################
#
# Зачем: Установка XFCE4 с расширенными компонентами.
# Включает: LightDM, plugins, apps.




clear
pacman -Syy
pacman -S --noconfirm xfce4 mousepad thunar-archive-plugin thunar-media-tags-plugin xfburn xfce4-artwork xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpufreq-plugin xfce4-cpugraph-plugin xfce4-dict xfce4-diskperf-plugin xfce4-eyes-plugin xfce4-fsguard-plugin xfce4-genmon-plugin xfce4-mailwatch-plugin xfce4-mount-plugin xfce4-mpc-plugin xfce4-netload-plugin xfce4-notes-plugin xfce4-notifyd xfce4-places-plugin xfce4-pulseaudio-plugin xfce4-screensaver xfce4-screenshooter xfce4-sensors-plugin xfce4-smartbookmark-plugin xfce4-systemload-plugin xfce4-taskmanager xfce4-time-out-plugin xfce4-timer-plugin xfce4-verve-plugin xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin xdg-user-dirs
pacman -S --noconfirm mugshot pavucontrol archlinux-xdg-menu xdg-desktop-portal-gtk menulibre network-manager-applet
update-menus
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm blueman engrampa ffmpegthumbnailer libgsf udiskie evince
pacman -S --noconfirm catfish galculator libopenraw mtpfs ntp numlockx perl-file-mimeinfo pidgin powertop unace xcursor-simpleandsoft xcursor-vanilla-dmz-aa gcolor3 xiccd
systemctl enable lightdm.service
clear
echo ""
echo "########################################"
echo "## <<<  УСТАНОВКА XFCE4 ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""





# #######################################################
# ## 🍃 БЛОК 18: УСТАНОВКА MATE #########################
# #######################################################
#
# Зачем: Установка MATE с темами и greeter.
# Включает: LightDM, slick-greeter.




clear
pacman -Syy
pacman -S --noconfirm mate mate-extra mate-themes plank lightdm lightdm-slick-greeter
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
clear
echo ""
echo "#######################################"
echo "## <<<  УСТАНОВКА MATE ЗАВЕРШЕНА >>> ##"
echo "#######################################"
echo ""





# #######################################################
# ## 🕯️ БЛОК 19: УСТАНОВКА CINNAMON #####################
# #######################################################
#
# Зачем: Установка Cinnamon с дополнительными пакетами.
# Включает: LightDM, greeter, themes.




clear
pacman -Syy
pacman -S --noconfirm cinnamon cinnamon-translations blueman dconf-editor ffmpegthumbnailer gcolor3 gnome-disk-utility gnome-keyring gnome-online-accounts gnome-screenshot gnome-system-monitor gnome-terminal gnome-themes-extra mousetweaks onboard pavucontrol powertop system-config-printer xreader xdg-desktop-portal-gnome evince
pacman -S --noconfirm nemo-fileroller nemo-preview nemo-python nemo-share kvantum icon-naming-utils baobab galculator netctl numlockx python-pyxdg qt5ct redshift squashfs-tools tree udiskie
pacman -S --noconfirm lightdm lightdm-slick-greeter
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
clear
echo ""
echo "##################################"
echo "## <<<  УСТАНОВКА ЗАВЕРШЕНА >>> ##"
echo "##################################"
echo ""





# ########################################################
# ## 🧩 БЛОК 20: УСТАНОВКА LXQT ##########################
# ########################################################
#
# Зачем: Установка LXQt с KWin и SDDM.
# Включает: Themes, breeze, sddm.




clear
pacman -Syy
pacman -S --noconfirm lxqt lxqt-themes xscreensaver picom libstatgrab libsysstat breeze-icons kvantum-qt5 blueman featherpad
pacman -S --noconfirm kwin kwin-x11 discover bluedevil systemsettings plasma-sdk aurorae breeze breeze-gtk flatpak-kcm kde-gtk-config kpipewire kscreen kscreenlocker gnome-keyring milou plasma-desktop plasma-pa print-manager qqc2-breeze-style xdg-desktop-portal-kde
pacman -S --noconfirm sddm sddm-kcm
systemctl enable sddm.service
clear
echo ""
echo "######################################"
echo "## <<< УСТАНОВКА LXQT ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""





# ########################################################
# ## 🖼️ БЛОК 21: УСТАНОВКА LXDE ##########################
# ########################################################
#
# Зачем: Установка LXDE с Openbox и LightDM.
# Включает: Notifyd, dunst, plugins.




clear
pacman -Syy
pacman -S --noconfirm lxde leafpad openbox pavucontrol alsa-utils xfce4-notifyd xscreensaver picom libstatgrab libsysstat mugshot dunst lxqt-archiver ffmpegthumbnailer thunar-archive-plugin thunar-media-tags-plugin thunar-shares-plugin libgsf udiskie
update-menus
pacman -S --noconfirm lightdm lightdm-slick-greeter blueman
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
sed -i 's/#display-setup-script=/display-setup-script=xrandr --output Virtual-1 --mode 1920x1080/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
clear
echo ""
echo "######################################"
echo "## <<< УСТАНОВКА LXDE ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""





# ########################################################
# ## 🌳 БЛОК 22: УСТАНОВКА TRINITY DESKTOP ###############
# ########################################################
#
# Зачем: Установка Trinity Desktop (KDE3-подобный).
# Включает: Добавление репозитория, TDM.




clear
pacman -Syy
pacman -S --noconfirm xorg
echo "#" >> /etc/pacman.conf
echo "# Official Trinity ArchLinux repository" >> /etc/pacman.conf
echo "[trinity]" >> /etc/pacman.conf
echo "Server = https://mirror.ppa.trinitydesktop.org/trinity/archlinux/x86_64/" >> /etc/pacman.conf
pacman-key --recv-key D6D6FAA25E9A3E4ECD9FBDBEC93AF1698685AD8B
pacman-key --lsign-key D6D6FAA25E9A3E4ECD9FBDBEC93AF1698685AD8B
pacman -Syy
pacman -S --noconfirm tde-meta gdb blueman
systemctl enable tdm.service
clear
echo ""
echo "###############################################"
echo "## <<<  УСТАНОВКА ARCH TRINITY ЗАВЕРШЕНА >>> ##"
echo "###############################################"
echo ""





# #######################################################
# ## 🧱 БЛОК 23: ВЫХОД ИЗ УСТАНОВКИ #####################
# #######################################################
#
# Зачем: Завершение установки, отмонтирование, выключение.
# Важно: Выполняется после chroot.




exit
umount -R /mnt
swapoff -a
poweroff
# rm -r .ssh/  # Раскомментировать, если нужно очистить SSH-сессию





# ##################################################################
# ## 🧩 БЛОК 24: КОНФИГУРАЦИЯ ПОЛЬЗОВАТЕЛЯ (ПОСЛЕ ПЕРВОЙ ЗАГРУЗКИ) ##
# ##################################################################
#
# Зачем: Настройка zsh, oh-my-zsh, xinitrc, флагов.
# Важно: Выполняется после входа в систему.




clear
echo "exec startplasma-x11" > ~/.xinitrc
sudo cp ~/.xinitrc /root/.xinitrc
systemctl --user --now enable pipewire pipewire-pulse wireplumber

sudo pacman -S --noconfirm zsh git curl
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

chsh -s $(which zsh)
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sed -i 's/plugins=(git)/plugins=(git archlinux extract zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
echo "hyfetch" >> ~/.zshrc

sudo reboot



