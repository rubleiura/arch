# ################################################################
# #### Макет блочной установки Arch Linux (BTRFS + SNAPPER) ######
# ################################################################
#
# 🔹 Назначение: Быстрая, гибкая и понятная установка Arch Linux
# 🔹 Метод: Копируйте и вставляйте по одному блоку за раз
# 🔹 Важно: Не запускайте как скрипт! Выполняйте вручную.
#
# Структура:
#   1. Диагностика и разметка диска
#   2. Монтирование и установка базовой системы
#   3. Конфигурация внутри chroot
#   4. Установка DE и пост-установочные действия
#
# Примечание: Данная установка предназначена для компьютеров
# с прошивкой UEFI и предполагает использование Wayland.
# Пользователь должен выполнить установку видеодрайверов отдельно,
# следуя инструкции video_drivers_guide.txt после Блока 11 и до
# установки графической оболочки.
# Trinity Desktop не включён в эту инструкцию из-за использования стороннего репозитория.







# ########################################################
# ## ⚙️ БЛОК 1: ПОДГОТОВКА LIVE-СРЕДЫ ####################
# ########################################################
#
# Зачем: Подготовка системы: часы, клавиатура, зеркала, обновление.
# Важно: Выполняется в Live-среде (до chroot).
# Включает: Обновление зеркал, утилиты для диагностики.

clear
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
pacman -Syy
timedatectl set-ntp true
pacman -Syy
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm haveged archlinux-keyring inxi util-linux lshw
pacman -S --noconfirm lshw
systemctl enable haveged.service --now
clear
echo ""
echo "##############################################"
echo "## <<< ПОДГОТОВКА К УСТАНОВКЕ ЗАВЕРШЕНА >>> ##"
echo "##############################################"
echo ""






# ######################################################
# ## 🔍 БЛОК 2: ДИАГНОСТИКА ОБОРУДОВАНИЯ ###############
# ######################################################
#
# Зачем: Проверка железа перед установкой и настройкой.
# Важно: Сравните с переменными в следующем блоке.
# Показывает: Процессор, материнка, диски, разделы.

clear
echo ""
echo "Замените переменную sdx на ваш жесткий диск для разметки диска"
echo ""
lsblk
echo ""
echo ""
echo "Замените или оставьте переменную amd-ucode от типа вашего процессора"
echo ""
echo "Производитель процессора:"
lshw -C cpu 2>/dev/null | grep 'vendor:' | uniq
echo ""
echo ""
echo "Замените переменную Sony на имя вашего компьютера "
echo ""
echo "Материнская плата:"
inxi -M
echo ""
echo ""
echo "Замените переменную 4G на необходимый размер SWAP"
echo ""
echo "Общая информация о системе:"
inxi -I
echo ""
echo ""
{ \
echo "Параметры монтирования FSTAB:"; \
echo; \
for DEVICE in $(lsblk -dno NAME 2>/dev/null | grep -v -e '^loop' -e '^sr'); do \
    DEVICE_PATH="/dev/$DEVICE"; \
    [[ ! -b "$DEVICE_PATH" ]] && continue; \
    ROTA=$(lsblk -d -o ROTA --noheadings "$DEVICE_PATH" 2>/dev/null | awk '{print $1}'); \
    if [[ "$ROTA" == "1" ]]; then \
        DISK_TYPE="HDD Замените переменную defaults на"; \
        MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:2,autodefrag"; \
    else \
        DISK_TYPE="SSD Замените переменную defaults на"; \
        MOUNT_OPTIONS="ssd,noatime,space_cache=v2,compress=zstd:2,discard=async"; \
    fi; \
    echo "╔═══════════════════════════════════════════════════════════════════════════════════════════════════╗"; \
    printf "║  Диск: %-60s\n" "/dev/$DEVICE"; \
    echo "╠═══════════════════════════════════════════════════════════════════════════════════════════════════╣"; \
    printf "║  Тип: %-60s\n" "$DISK_TYPE"; \
    printf "║  параметры монтирования: %-60s\n" "$MOUNT_OPTIONS"; \
    echo "╚═══════════════════════════════════════════════════════════════════════════════════════════════════╝"; \
    echo; \
done; \
}
echo ""
echo "#################################################"
echo "## <<< ТЕСТИРОВАНИЕ КОМПЬЮТЕРА ЗАКОНЧИЛОСЬ >>> ##"
echo "#################################################"
echo ""





# ########################################################
# ## 🔧 БЛОК 3: НАСТРОЙКА ПЕРЕМЕННЫХ (ОБЯЗАТЕЛЬНО!) ######
# ########################################################
#
# Зачем: Настройка под ваше оборудование.
# Важно: Измените значения, если они не совпадают с тестом выше.
# Особое внимание ко всем переменным

##############################################################################
##                    ВАЖНО: Настройка Переменных                           ##
##############################################################################
## Этот раздел ОБЯЗАТЕЛЕН для изменения переменных перед установкой.        ##
## Несоблюдение этого требования может привести к ошибкам установки.        ##
##                                                                          ##
## ПЕРЕД НАЧОЛОМ:                                                           ##
## 1.  Сравните параметры из раздела "Тестирование" с параметрами в         ##
##     таблице переменных ниже.                                             ##
## 2.  Если они НЕ совпадают, ОБЯЗАТЕЛЬНО используйте функцию группового    ##
##     переименования вашего текстового редактора, чтобы переменные в       ##
##     таблице соответствовали результатам тестирования.                    ##
##                                                                          ##
## ДОПОЛНИТЕЛЬНО (по желанию):                                              ##
## Вы можете изменить параметры пользователя, компьютера и ядра.            ##
##############################################################################
##                    Разметка Диска                                        ##
##############################################################################
## Для разметки дисков используется отдельная переменная `sdx`              ##
## (например, `sda`, `sdb` и т.д.), соответствующая выбранному диску.       ##
##                                                                          ##
## ЗАЧЕМ ЭТО НУЖНО:                                                         ##
## Это позволяет избежать конфликтов параметров переменных до и после       ##
## разметки (создания разделов и их монтирования).                          ##
##                                                                          ##
## ПОРЯДОК ДЕЙСТВИЙ:                                                        ##
## 1.  СНАЧАЛА измените переменную `sdx` на нужный диск (например, `sda`).  ##
## 2.  ЗАТЕМ выполните разметку диска.                                      ##
## 3.  ПОСЛЕ разметки диска изменяйте переменные разделов                   ##
##     (например, `sda1`, `sda2`, `sda3`).                                  ##
##                                                                          ##
## ТЕСТИРОВАНИЕ:                                                            ##
## Вы можете использовать тестирование из блока 3 ДО заполнения всех        ##
## переменных.                                                              ##
## ПОСЛЕ заполнения всех переменных вы можете С УВЕРЕННОСТЬЮ приступить     ##
## к установке ArchLinux!                                                   ##
##############################################################################

#####################################################################
#                      Настройки языка                              #
#                     Language settings                             #
# Замените переменные XXXX, YYYY, ZZZZ на нужные языковые параметры #
# Пример для русского языка: ru_RU, ru, cyr-sun16.                  #
#####################################################################
#                       Переменная                                  #
#                        Variable                                   #
#####################################################################
#         #  locale.gen # loadkeys, keymap #  font                  #
#####################################################################
# Country #  XXXX       #  YYYY            #  ZZZZ                  #
#####################################################################
# Russia  #  ru_RU      #  ru              #  cyr-sun16             #
# Ukraine #  uk_UA      #  uk              #  UniCyr_8x16           #
# Belarus #  be_BY      #  by              #  cyr-sun16             #
# Germany #  de_DE      #  de              #  lat9w-16              #
# France  #  fr_FR      #  fr              #  lat9w-16              #
# Spain   #  es_ES      #  es              #  lat9w-16              #
# Italy   #  it_IT      #  it              #  lat9w-16              #
# USA     #  en_US      #  en              #  lat9w-16              #
# Türkiye #  tr_TR      #  trq             #  latarcyrheb-sun16     #
# Israel  #  he_IL      #  il              #  latarcyrheb-sun16     #
# Japan   #  ja_JP      #  jp106           #  jiskp16               #
# China   #  zh_CN      #  cn              #  ter-v16n              #
#####################################################################

#############################################################
#             Объект             #   Переменная             #
#############################################################
#             Имя                #  forename                #
#############################################################
#             Полное имя         #  User Name               #
#############################################################
#             HOSTNAME 	         #  Sony                    #
#############################################################
#             Microcode	         #  amd-ucode               #
#############################################################
#               Ядро	         #  linux-lts               #
#############################################################
#            размер SWAP         #	4G                      #
#############################################################
#         Диск для разметки      #  sdx                     #
#############################################################
# Разделы диска для монтирования #  sda1 sda2 sda3          #
#############################################################

#############################################################
#           Переменная BTRFS (SSD/HDD) FSTAB                #
#############################################################
#                        defaults                           #
#############################################################






clear
loadkeys YYYY
setfont ZZZZ
sed -i "s/#XXXX/XXXX/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=XXXX.UTF-8
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
sgdisk -a 2048 -o /dev/sdx
sgdisk -n 1::+1024M --typecode=1:ef00 --change-name=1:'Раздел Efi Arch Linux' /dev/sdx
sgdisk -n 2::-4G --typecode=2:8300 --change-name=2:'Системный раздел Arch Linux' /dev/sdx
sgdisk -n 3::-0 --typecode=3:8200 --change-name=3:'Раздел подкачки Arch Linux' /dev/sdx
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
# ## 💾 БЛОК 5: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ###########
# #######################################################
#
# Зачем: Форматирование, создание подтомов Btrfs, монтирование.
# Важно: Выполняется до chroot.
# Подтомы: @, @home, @log, @pkg.

clear
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda3
swapon /dev/sda3
mkfs.btrfs -f /dev/sda2
mount /dev/sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
umount /mnt
mount -o defaults,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
mount -o defaults,subvol=@home /dev/sda2 /mnt/home
mount -o defaults,subvol=@log /dev/sda2 /mnt/var/log
mount -o defaults,subvol=@pkg /dev/sda2 /mnt/var/cache/pacman/pkg
mount /dev/sda1 /mnt/boot
clear
echo ""
# Просмотр информации о разделах (проверка)
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/sdx
echo ""
# Просмотр созданных подтомов (после монтирования)
lsblk /dev/sdx
echo ""
# Просмотр созданных подтомов (после монтирования)
btrfs subvolume list /mnt
echo ""
echo "##############################################################"
echo "## <<< ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ РАЗДЕЛОВ ЗАВЕРШЕНО >>> ##"
echo "##############################################################"
echo ""






# ########################################################
# ## 🧱 БЛОК 6: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ################
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
pacstrap /mnt memtest86+-efi
pacstrap /mnt nano
pacstrap /mnt reflector pacman-contrib curl
genfstab -pU /mnt >> /mnt/etc/fstab
echo ""
clear
echo ""
echo "##################################################"
echo "## <<< УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА  >>> ##"
echo "## <<< СОВЕРШАЕМ ВХОД В СИСТЕМУ (chroot)    >>> ##"
echo "##################################################"
echo ""
arch-chroot /mnt /bin/bash
echo ""






# ########################################################
# ## 🔁 БЛОК 7: НАСТРОЙКИ ВНУТРИ СИСТЕМЫ (chroot) ########
# ########################################################
#
# Зачем: Настройка системы: локали, fstab, время, зеркала.
# Важно: Выполняется внутри chroot.
# Автоматизация: Временная зона по IP, зеркала по стране.

clear
# Пример корректировки fstab для BTRFS subvolumes
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,defaults/g'  /etc/fstab
# Включаем multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
# Дополнительные настройки pacman.conf
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
# Настройка консоли
echo "KEYMAP=YYYY" > /etc/vconsole.conf
echo "FONT=ZZZZ" >> /etc/vconsole.conf
# Настройка локали
echo "LANG=XXXX.UTF-8" > /etc/locale.conf
sed -i "s/#XXXX/XXXX/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=XXXX.UTF-8
# Настройка времени
time_zone=$(curl -s https://ipinfo.io/timezone)
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
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






# ########################################################
# ## 🔐 БЛОК 8: HOSTNAME И ПАРОЛЬ ROOT (chroot) ##########
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
# ## 👤 БЛОК 9: ПОЛЬЗОВАТЕЛЬ И SUDO (chroot) ############
# #######################################################
#
# Зачем: Создание пользователя и настройка sudo.
# Важно: Без wheel — sudo не будет работать.

clear
useradd forename -m -c "User Name" -s /bin/bash
usermod -aG wheel,users forename
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
clear
echo ""
echo "###########################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ >>> ##"
echo "###########################################"
echo ""
passwd forename
clear
echo ""
echo "###############################################"
echo "## <<<  НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ ЗАВЕРШЕНА >>> ##"
echo "###############################################"
echo ""






# #######################################################
# ## 🔧 БЛОК 10: УСТАНОВКА ЯДРА, GRUB, MKINITCPIO #######
# #######################################################
#
# Зачем: Настройка загрузчика и initramfs.
# Включает: GRUB, grub-btrfs, plymouth.

clear
pacman -Syy
# Установка ядра и прошивки
pacman -S --noconfirm linux-lts linux-lts-headers linux-firmware
# Установка загрузчика и утилит
pacman -S --noconfirm grub grub-btrfs efibootmgr # os-prober убран по умолчанию
# Установка сетевых и других сервисов
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools
pacman -S --noconfirm openssh
# Установка Plymouth (опционально)
pacman -S --noconfirm plymouth
# Включение сервисов
systemctl enable NetworkManager.service grub-btrfsd.service sshd.service
# Установка GRUB
grub-install --efi-directory=/boot --boot-directory=/boot --bootloader-id="Arch Linux"
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\".*\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash plymouth udev.log_priority=3 rootflags=subvol=@\"|" /etc/default/grub
sed -i "s/#GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/" /etc/default/grub-btrfs/config
sed -i "s/#GRUB_BTRFS_TITLE_FORMAT=(\"date\" \"snapshot\" \"type\" \"description\")/GRUB_BTRFS_TITLE_FORMAT=(\"description\" \"date\")/" /etc/default/grub-btrfs/config
# Настройка mkinitcpio
sed -i 's/ProtectSystem=strict/ProtectSystem=full/' /usr/lib/systemd/system/mkinitcpio-generate-shutdown-ramfs.service
sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
# Генерация конфигурации GRUB и initramfs
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
# ## 🧰 БЛОК 11: СИСТЕМНЫЕ УТИЛИТЫ И WAYLAND (chroot) ###
# #######################################################
#
# Зачем: Установка системных утилит, PipeWire, шрифтов.
# Включает: Bluetooth, CUPS, xdg, PipeWire, Wayland.

clear
pacman -Syy
pacman -S --noconfirm haveged
systemctl enable haveged.service
pacman -S --noconfirm wget usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
pacman -S --noconfirm dosfstools ntfs-3g exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
pacman -S --noconfirm cronie chrony
systemctl enable cronie.service chronyd.service
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
pacman -S --noconfirm cups cups-pdf ghostscript gsfonts avahi system-config-printer simple-scan
systemctl enable cups.service avahi-daemon.service
pacman -S --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
pacman -S --noconfirm udisks2 udiskie polkit
pacman -S --noconfirm wireplumber pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
systemctl --global enable pipewire pipewire-pulse wireplumber
pacman -S --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss vlc taglib
pacman -S --noconfirm man-db man-pages man-pages-YYYY
pacman -S --noconfirm ttf-dejavu noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-dejavu
pacman -S --noconfirm iproute2 inetutils dnsutils
pacman -S --noconfirm fastfetch hyfetch inxi
clear
# ========================================================
# УСТАНОВКА БАЗОВЫХ КОМПОНЕНТОВ WAYLAND И ГРАФИЧЕСКОЙ ПОДСИСТЕМЫ
# Включает: Mesa, Vulkan, Wayland, libinput, seatd
# ========================================================
pacman -S --noconfirm mesa vulkan-icd-loader libglvnd
pacman -S --noconfirm wayland wayland-protocols
pacman -S --noconfirm libinput libxkbcommon seatd
systemctl enable seatd.service  # Для управления правами доступа к GPU под Wayland
clear
echo ""
echo "###############################################################"
echo "## <<<  УСТАНОВКА СИСТЕМНЫХ ПРОГРАММ И WAYLAND ЗАВЕРШЕНА >>> ##"
echo "## <<< ВНИМАНИЕ: УСТАНОВКА ВИДЕОДРАЙВЕРОВ ВЫПОЛНЯЕТСЯ ОТДЕЛЬНО! >>> ##"
echo "## <<< СЛЕДУЙТЕ ИНСТРУКЦИИ video_drivers_guide.txt >>> ##"
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
# ## 🖥️ БЛОК 12: УСТАНОВКА ВИДЕО-ДРАЙВЕРА (chroot) #######
# ########################################################
#
# ВАЖНО: ЭТОТ БЛОК ЯВЛЯЕТСЯ ЗАМЕНОЙ ИНСТРУКЦИИ video_drivers_guide.sh ВНУТРИ CHROOT.
#        РЕКОМЕНДУЕТСЯ ВЫЙТИ ИЗ CHROOT И СЛЕДОВАТЬ ОТДЕЛЬНОЙ ИНСТРУКЦИИ.
#        ОСТАВЛЕН ЗДЕСЬ ТОЛЬКО КАК ПРИМЕР БАЗОВОГО ВАРИАНТА ДЛЯ ОТКРЫТЫХ ДРАЙВЕРОВ.
#        ДЛЯ NVIDIA И ГИБРИДНОЙ ГРАФИКИ СЛЕДУЙТЕ ОТДЕЛЬНОЙ ИНСТРУКЦИИ!
# ----------------------------------------------------------
# Минимальные драйверы (ТОЛЬКО для Intel/AMD с открытыми драйверами):
#   • Intel:        vulkan-intel
#   • AMD:          vulkan-radeon
#   • NVIDIA:       ТРЕБУЕТ ОТДЕЛЬНОЙ НАСТРОЙКИ (см. video_drivers_guide.sh)
# ----------------------------------------------------------

# Пример установки для Intel:
# pacman -S --noconfirm mesa vulkan-intel intel-media-driver libva-intel-driver
# pacman -S --noconfirm lib32-mesa lib32-vulkan-intel

# Пример установки для AMD:
# pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver
# pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon

# НЕ УСТАНАВЛИВАЙТЕ ПАКЕТЫ NVIDIA (nvidia, nvidia-lts, nvidia-dkms) БЕЗ СЛЕДОВАНИЯ
# ОТДЕЛЬНОЙ ИНСТРУКЦИИ video_drivers_guide.sh.







# ############################################
# ## ИНТЕГРАЦИЯ VIRTUALBOX (chroot) ##########
# ############################################
#
# Зачем: Настройка интеграции с VirtualBox.
# Важно: Только если установка в VirtualBox.

clear
pacman -S --needed --noconfirm virtualbox-guest-utils
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice.service
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
usermod -aG vboxsf forename
clear
echo ""
echo "#############################################"
echo "## <<<  НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""






# ########################################################
# ## 🌌 БЛОК 13: УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ ###########
# ######################################################
#
# Зачем: Установка предпочитаемой графической оболочки.
# Включает: Различные DE/WM. Ниже следуют подблоки для каждой среды.
# ВАЖНО: Убедитесь, что видеодрайверы установлены и настроены правильно
#        (см. video_drivers_guide.txt) перед установкой DE/WM.







# #######################################################
# ## 🌌 УСТАНОВКА KDE PLASMA ############################
# #######################################################
#
# Зачем: Установка среды KDE Plasma.
# Включает: Все компоненты, SDDM, kde-apps.

clear
#### Plasma ####
pacman -Syy
pacman -S --noconfirm plasma dolphin dolphin-plugins kate konsole skanpage skanlite gwenview elisa okular ark
pacman -S --noconfirm ffmpegthumbs poppler-glib
systemctl enable sddm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "#############################################"
echo "## <<<  УСТАНОВКА KDE PLASMA ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""
# Выход из chroot
exit


# #######################################################
# ## 🌐 УСТАНОВКА GNOME #################################
# #######################################################
#
# Зачем: Установка GNOME с полной интеграцией.
# Включает: GDM, portal, apps, extensions.

clear
###  GNOME  ##
pacman -Syy
pacman -S --noconfirm gnome
###  gnome-extra  ###
pacman -S --noconfirm dconf-editor
pacman -S --noconfirm file-roller
pacman -S --noconfirm gnome-tweaks
#
pacman -S --noconfirm gnome-themes-extra
pacman -S --noconfirm gnome-browser-connector
pacman -S --noconfirm gnome-shell-extensions
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable gdm
echo "[User]" > /var/lib/AccountsService/users/root
echo "SystemAccount=true" >> /var/lib/AccountsService/users/root
## Питание ноутбука (раскоменируйте в случае необходимости)
## Настройки действий кнопок питания и крышки ноутбука, а также режимов сна и гибернации

## Вариант 1
## Кнопка питания выключает компьютер, а закрытие крышки переводит его в сон:
# mkdir -p /etc/systemd/logind.conf.d
# echo "[Login]" > /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandlePowerKey=poweroff" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitch=suspend" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf.d/50-power-options.conf

## Вариант 2
## Кнопка питания выключает компьютер, а закрытие крышки переводит в гибернацию:
# mkdir -p /etc/systemd/logind.conf.d
# echo "[Login]" > /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandlePowerKey=poweroff" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitch=hibernate" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchExternalPower=hibernate" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchDocked=hibernate" >> /etc/systemd/logind.conf.d/50-power-options.conf

## Вариант 3
## Кнопка питания выключает компьютер, а закрытие крышки ничего не происходит:
# mkdir -p /etc/systemd/logind.conf.d
# echo "[Login]" > /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandlePowerKey=poweroff" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitch=suspend" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf.d/50-power-options.conf
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "########################################"
echo "## <<<  УСТАНОВКА GNOME ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""
# Выход из chroot
exit


# ########################################################
# ## 🪟 УСТАНОВКА XFCE4 ##################################
# ########################################################
#
# Зачем: Установка XFCE4 с расширенными компонентами.
# Включает: LightDM, plugins, apps.

clear
pacman -Syy
pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm network-manager-applet blueman
pacman -S --noconfirm gnome-keyring mugshot pavucontrol xdg-user-dirs xdg-desktop-portal-gtk ristretto thunar-archive-plugin ffmpegthumbnailer
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
# sed -i 's/#display-setup-script=/display-setup-script=xrandr --output Virtual-1 --mode 1920x1080/' /etc/lightdm/lightdm.conf # Опционально, закомментировано
systemctl enable lightdm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "########################################"
echo "## <<<  УСТАНОВКА XFCE4 ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""
# Выход из chroot
exit


# #######################################################
# ## 🍃 БЛОК 18: УСТАНОВКА MATE #########################
# #######################################################
#
# Зачем: Установка MATE с темами и greeter.
# Включает: LightDM, slick-greeter.

clear
pacman -Syy
pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm network-manager-applet blueman
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
# sed -i 's/#display-setup-script=/display-setup-script=xrandr --output Virtual-1 --mode 1920x1080/' /etc/lightdm/lightdm.conf # Опционально, закомментировано
systemctl enable lightdm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "#######################################"
echo "## <<<  УСТАНОВКА MATE ЗАВЕРШЕНА >>> ##"
echo "#######################################"
echo ""
# Выход из chroot
exit


# #######################################################
# ## 🕯️ УСТАНОВКА CINNAMON ##############################
# #######################################################
#
# Зачем: Установка Cinnamon с дополнительными пакетами.
# Включает: LightDM, greeter, themes.

clear
pacman -Syy
pacman -S --noconfirm cinnamon cinnamon-translations blueberry lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings gnome-terminal evince
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
# sed -i 's/#display-setup-script=/display-setup-script=xrandr --output Virtual-1 --mode 1920x1080/' /etc/lightdm/lightdm.conf # Опционально, закомментировано
systemctl enable lightdm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "###########################################"
echo "## <<<  УСТАНОВКА CINNAMON ЗАВЕРШЕНА >>> ##"
echo "###########################################"
echo ""
# Выход из chroot
exit


# ########################################################
# ## 🧩 УСТАНОВКА LXQT ###################################
# ########################################################
#
# Зачем: Установка LXQt с KWin и SDDM.
# Включает: Themes, breeze, sddm.

clear
pacman -Syy
pacman -S --noconfirm lxqt sddm breeze breeze-icons blueman featherpad libstatgrab libsysstat
pacman -S --noconfirm network-manager-applet blueman
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable sddm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "######################################"
echo "## <<< УСТАНОВКА LXQT ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""
# Выход из chroot
exit


# ########################################################
# ## 🖼️ УСТАНОВКА LXDE ###################################
# ########################################################
#
# Зачем: Установка LXDE с Openbox и LightDM.
# Включает: Notifyd, dunst, plugins.

clear
pacman -Syy
pacman -S --noconfirm lxde openbox leafpad lightdm lightdm-slick-greeter blueman thunar-archive-plugin ffmpegthumbnailer udiskie xfce4-notifyd dunst picom
pacman -S --noconfirm network-manager-applet blueman
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm ffmpegthumbnailer poppler-glib gnome-themes-extra
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
# sed -i 's/#display-setup-script=/display-setup-script=xrandr --output Virtual-1 --mode 1920x1080/' /etc/lightdm/lightdm.conf # Опционально, закомментировано
systemctl enable lightdm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "######################################"
echo "## <<< УСТАНОВКА LXDE ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""
# Выход из chroot
exit


# ########################################################
# ## 🪟 УСТАНОВКА BUDGIE #################################
# ########################################################
#
# Зачем: Установка BUDGIE с расширенными компонентами.
# Включает: LightDM, audacious, evince.

clear
pacman -Syy
pacman -S --noconfirm budgie-desktop budgie-screensaver budgie-control-center dconf-editor budgie-desktop-view budgie-backgrounds
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm materia-gtk-theme papirus-icon-theme
pacman -S --noconfirm gnome-terminal nautilus vlc eog evince gedit
pacman -S --noconfirm network-manager-applet blueman
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
# sed -i 's/#display-setup-script=/display-setup-script=xrandr --output Virtual-1 --mode 1920x1080/' /etc/lightdm/lightdm.conf # Опционально, закомментировано
systemctl enable lightdm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "#########################################"
echo "## <<<  УСТАНОВКА BUDGIE ЗАВЕРШЕНА >>> ##"
echo "#########################################"
echo ""
# Выход из chroot
exit


# Отмонтирование разделов диска (выполняется после выхода из chroot)
# umount -R /mnt
# swapoff -a
# poweroff


# Очистка конфигурации ssh соединения
# rm -r .ssh/  # Раскомментировать, если нужно очистить SSH-сессию
