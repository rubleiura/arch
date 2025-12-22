# ################################################################
# #### Макет блочной установки Arch Linux (BTRFS + SNAPPER) ######
# ################################################################
#
# 🔹 Назначение: Быстрая, гибкая и понятная установка Arch Linux
# 🔹 Метод: Копируйте и вставляйте по одному блоку за раз
# 🔹 Важно: Не запускайте как скрипт! Выполняйте вручную.
# 🔹 Требуется: Интернет, Live-среда Arch Linux (предпочтительно последняя)
#
# Структура:
#   1. Диагностика и разметка диска
#   2. Монтирование и установка базовой системы
#   3. Конфигурация внутри chroot
#   4. Установка DE и пост-установочные действия
#
# Примечание: Данная установка предназначена для компьютеров
# с прошивкой UEFI
# ################################################################






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
sudo pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm haveged archlinux-keyring inxi util-linux lshw
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
echo "=== ДИАГНОСТИКА ОБОРУДОВАНИЯ ==="
echo ""
echo "Замените переменную sdx на ваш жесткий диск для разметки диска"
echo "Пример: если ваш диск /dev/sda, замените ВСЕ 'sdx' на 'sda' в макете."
echo ""
lsblk
echo ""
echo ""
echo "Замените или оставьте переменную amd-ucode в зависимости от типа вашего процессора"
echo "Для Intel: замените 'amd-ucode' на 'intel-ucode'"
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
echo "Пример: для 8GB swap, замените '4G' на '8G'"
echo ""
echo "Общая информация о системе:"
inxi -I
echo ""
echo ""
echo "=== РЕКОМЕНДУЕМЫЕ ПАРАРАМЕТРЫ МОНТИРОВАНИЯ FSTAB ==="
echo "Определение типа дисков (HDD/SSD) для параметров монтирования:"
{ \
echo; \
for DEVICE in $(lsblk -dno NAME 2>/dev/null | grep -v -e '^loop' -e '^sr'); do \
    DEVICE_PATH="/dev/$DEVICE"; \
    [[ ! -b "$DEVICE_PATH" ]] && continue; \
    ROTA=$(lsblk -d -o ROTA --noheadings "$DEVICE_PATH" 2>/dev/null | awk '{print $1}'); \
    if [[ "$ROTA" == "1" ]]; then \
        DISK_TYPE="HDD (Замените 'defaults' в БЛОКЕ 3 на):"; \
        MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:2,autodefrag"; \
    else \
        DISK_TYPE="SSD (Замените 'defaults' в БЛОКЕ 3 на):"; \
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
# ВАЖНО: ПРОЧИТАЙТЕ ВНИМАТЕЛЬНО.
# 1. ИЗМЕНИТЕ значения, если они не совпадают с тестом в БЛОКЕ 2.
# 2. ИСПОЛЬЗУЙТЕ ФУНКЦИЮ ГРУППОВОГО ПОИСКА И ЗАМЕНЫ ВАШЕГО ТЕКСТОВОГО РЕДАКТОРА!
# 3. Замените ВСЕ вхождения каждой переменной по всему файлу макета.

##############################################################################
##                    ВАЖНО: Настройка Переменных                           ##
##############################################################################
## Этот раздел ОБЯЗАТЕЛЕН для изменения переменных перед установкой.        ##
## Несоблюдение этого требования может привести к ошибкам установки.        ##
##                                                                          ##
## ПЕРЕД НАЧАЛОМ:                                                           ##
## 1.  Сравните параметры из БЛОКА 2 "Тестирование" с параметрами в         ##
##     таблице переменных ниже.                                             ##
## 2.  Если они НЕ совпадают, ОБЯЗАТЕЛЬНО используйте функцию группового    ##
##     поиска и замены в вашем текстовом редакторе (например, mousepad,     ##
##     kwrite или kate либо gedit), чтобы переменные в таблице и по всему   ##
##     файлу макета соответствовали результатам тестирования.               ##
##     Пример: Если ваш диск /dev/nvme0n1, замените ВСЕ 'sdx' на 'nvme0n1'. ##
## 3.  После замены переменных, ПРОВЕРЬТЕ ВСЕ БЛОКИ, чтобы убедиться,       ##
##     что все старые значения заменены.                                    ##
##                                                                          ##
## ДОПОЛНИТЕЛЬНО (по желанию):                                              ##
## Вы можете изменить параметры пользователя, компьютера и ядра.            ##
##############################################################################
##                    Разметка Диска                                        ##
##############################################################################
## Для разметки дисков используется отдельная переменная `sdx`              ##
## (например, `sda`, `nvme0n1`).                                            ##
##                                                                          ##
## ПОРЯДОК ДЕЙСТВИЙ:                                                        ##
## 1.  СНАЧАЛА измените переменную `sdx` на нужный диск (например, `sda`).  ##
## 2.  ЗАТЕМ выполните поиск и замену ВСЕХ вхождений 'sdx' на ваш диск.     ##
## 3.  ПОСЛЕ разметки диска изменяйте переменные разделов                   ##
##     (например, `sda1`, `sda2`, `sda3`).                                  ##
##                                                                          ##
## ТЕСТИРОВАНИЕ:                                                            ##
## Вы можете использовать тестирование из БЛОКА 2 ДО заполнения всех        ##
## переменных.                                                              ##
## ПОСЛЕ заполнения всех переменных вы можете С УВЕРЕННОСТЬЮ приступить     ##
## к установке ArchLinux!                                                   ##
##############################################################################

#####################################################################
#                      Настройки языка                              #
#                     Language settings                             #
# Замените переменные XXXX, YYYY, ZZZZ на нужные языковые параметры #
# Пример для русского языка: ru_RU, ru, cyr-sun16.                  #
# Найдите и замените ВСЕ вхождения XXXX, YYYY, ZZZZ.                #
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
#             Объект             #  Переменная              #
#############################################################
#             Имя                #  forename                #
#############################################################
#             Полное имя         #  User Name               #
#############################################################
#             HOSTNAME 	         #  Sony                    #
#############################################################
#             Microcode	         #  amd-ucode               #
#############################################################
#             Ядро	             #  linux-lts               #
#############################################################
#             bootloader-id      #  Grub Arch Linux         #
#############################################################
#             размер SWAP        #  4G                      #
#############################################################
#         Диск для разметки      #  sdx                     #
#############################################################
# Разделы диска для монтирования #  sda1 sda2 sda3          #
# (После разметки sgdisk, замените sda на ваше значение sdx)#
#############################################################

############################################################################
#           Переменная BTRFS (SSD/HDD) FSTAB                               #
# Замените 'defaults' на параметры из БЛОКА 2                              #
# Пример для SSD: ssd,noatime,space_cache=v2,compress=zstd:2,discard=async #
# Пример для HDD: noatime,space_cache=v2,compress=zstd:2,autodefrag        #
############################################################################
#                        defaults                                          #
############################################################################






# ################################################
# ## 🗂️ БЛОК 4: РАЗМЕТКА ДИСКА (GPT + EFI) #######
# ################################################
#
# Зачем: Создание разделов: UEFI Boot, root, swap.
# ВАЖНО: Все данные на /dev/sdx будут УДАЛЕНЫ!
# Используется: sgdisk для точной разметки.
# ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sdx' заменен на ваш диск!

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
echo "##########################################################"
echo "##            <<< РАЗМЕТКА ДИСКА ЗАВЕРШЕНА >>>          ##"
echo "##      <<< ЗАМЕНИТЕ ПЕРЕМЕННЫЕ sda1 sda2 sda3 >>>      ##"
echo "## <<< НА ИМЯ РАЗДЕЛОВ ПОСЛЕ РАЗМЕТКИ ДИСКА SSD/HDD >>> ##"
echo "##########################################################"
echo ""






# #######################################################
# ## 💾 БЛОК 5: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ###########
# #######################################################
#
# Зачем: Форматирование, создание подтомов Btrfs, монтирование.
# Важно: Выполняется до chroot.
# Подтомы: @, @home, @log, @pkg.
# ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sda1', 'sda2', 'sda3' заменены на правильные разделы (например, 'nvme0n1p1')!

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
pacstrap /mnt amd-ucode iucode-tool
pacstrap /mnt memtest86+-efi
pacstrap /mnt nano
pacstrap /mnt reflector pacman-contrib curl
genfstab -pU /mnt >> /mnt/etc/fstab
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
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,defaults/g'  /etc/fstab
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
echo "KEYMAP=YYYY" > /etc/vconsole.conf
echo "FONT=ZZZZ" >> /etc/vconsole.conf
echo "LANG=XXXX.UTF-8" > /etc/locale.conf
sed -i "s/#XXXX/XXXX/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=XXXX.UTF-8
time_zone=$(curl -s https://ipinfo.io/timezone        )
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
# Настройка reflector
# Создание скрипта обновления зеркал
echo '#!/bin/bash' > /usr/local/bin/update-mirrors.sh
echo "" >> /usr/local/bin/update-mirrors.sh
echo "reflector --latest 20 --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist" >> /usr/local/bin/update-mirrors.sh
chmod +x /usr/local/bin/update-mirrors.sh
# Создание юнита сервиса systemd
echo "[Unit]" > /etc/systemd/system/reflector.service
echo "Description=Update mirrorlist with reflector" >> /etc/systemd/system/reflector.service
echo "Documentation=man:reflector(1)" >> /etc/systemd/system/reflector.service
echo "Wants=network-online.target" >> /etc/systemd/system/reflector.service
echo "After=network-online.target" >> /etc/systemd/system/reflector.service
echo "" >> /etc/systemd/system/reflector.service
echo "[Service]" >> /etc/systemd/system/reflector.service
echo "Type=oneshot" >> /etc/systemd/system/reflector.service
echo "ExecStart=/usr/local/bin/update-mirrors.sh" >> /etc/systemd/system/reflector.service
echo "SuccessExitStatus=2 3 4" >> /etc/systemd/system/reflector.service
echo "Restart=on-failure" >> /etc/systemd/system/reflector.service
echo "RestartSec=10s" >> /etc/systemd/system/reflector.service
echo "" >> /etc/systemd/system/reflector.service
echo "[Install]" >> /etc/systemd/system/reflector.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/reflector.service
# Создание юнита таймера systemd
echo "[Unit]" > /etc/systemd/system/reflector.timer
echo "Description=Weekly Reflector Timer" >> /etc/systemd/system/reflector.timer
echo "Requires=reflector.service" >> /etc/systemd/system/reflector.timer
echo "" >> /etc/systemd/system/reflector.timer
echo "[Timer]" >> /etc/systemd/system/reflector.timer
echo "OnCalendar=weekly" >> /etc/systemd/system/reflector.timer
echo "Persistent=true" >> /etc/systemd/system/reflector.timer
echo "" >> /etc/systemd/system/reflector.timer
echo "[Install]" >> /etc/systemd/system/reflector.timer
echo "WantedBy=timers.target" >> /etc/systemd/system/reflector.timer
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
# Включает: GRUB, grub-btrfs, plymouth, resume из swap.

clear
pacman -Syy
pacman -S --noconfirm linux-lts linux-lts-headers linux-firmware
pacman -S --noconfirm grub grub-btrfs efibootmgr os-prober # <-- Добавлен os-prober
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools
pacman -S --noconfirm openssh
pacman -S --noconfirm plymouth
systemctl enable NetworkManager.service grub-btrfsd.service sshd.service
grub-install --efi-directory=/boot --boot-directory=/boot --bootloader-id="Grub Arch Linux"
sed -i s/'quiet'/'quiet splash'/g /etc/default/grub
sed -i "s/#GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/" /etc/default/grub-btrfs/config
sed -i "s/#GRUB_BTRFS_TITLE_FORMAT=(\"date\" \"snapshot\" \"type\" \"description\")/GRUB_BTRFS_TITLE_FORMAT=(\"description\" \"date\")/" /etc/default/grub-btrfs/config
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






# ########################################################
# ## 🧰 БЛОК 11: СИСТЕМНЫЕ УТИЛИТЫ И НАСТРОЙКИ (chroot) ##
# ########################################################
#
# Зачем: Установка системных утилит, PipeWire, шрифтов.
# Включает: Bluetooth, CUPS, xdg, PipeWire, Сhromium.

clear
pacman -Syy
pacman -S --noconfirm haveged
systemctl enable haveged.service
pacman -S --noconfirm wget usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
pacman -S --noconfirm dosfstools ntfs-3g exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
pacman -S --noconfirm ntfs3 # <-- Добавлено
pacman -S --noconfirm cronie
systemctl enable cronie.service systemd-timesyncd.service
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
pacman -S --noconfirm cups cups-pdf ghostscript gsfonts avahi system-config-printer simple-scan
systemctl enable cups.service avahi-daemon.service
pacman -S --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
pacman -S --noconfirm udisks2 udiskie polkit
pacman -S --noconfirm pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
pacman -S --noconfirm wireplumber
systemctl --global enable pipewire pipewire-pulse wireplumber
pacman -S --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss vlc taglib
pacman -S --noconfirm man-db man-pages man-pages-YYYY
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-dejavu
pacman -S --noconfirm iproute2 inetutils dnsutils
pacman -S --noconfirm fastfetch hyfetch inxi
pacman -S --noconfirm htop cpu-x chromium qbittorrent libreoffice-fresh-ru archlinux-wallpaper
clear
echo ""
echo "######################################################################"
echo "##   <<<  УСТАНОВКА СИСТЕМНЫХ ПРОГРАММ И НАСТРОЙКИ ЗАВЕРШЕНЫ >>>    ##"
echo "## <<< ВНИМАНИЕ: УСТАНОВКА ВИДЕОДРАЙВЕРОВ ВЫПОЛНЯЕТСЯ ОТДЕЛЬНО! >>> ##"
echo "##    <<< СЛЕДУЙТЕ ИНСТРУКЦИИ video_drivers_guide.m >>>             ##"
echo "######################################################################"
echo ""
echo "##############################################"
echo "## <<<  ВИДЕОКАРТЫ  ДАННОГО КОМПЬЮТЕРА  >>> ##"
echo "## <<< ВЫБЕРИТЕ ДРАЙВЕРА СОГЛАСНО ТЕСТУ >>> ##"
echo "##############################################"
echo ""
lspci -nn | grep -i 'vga'
lsmod | grep -iE 'nvidia|amdgpu|i915'






# ########################################################
# ## 🖥️ БЛОК 12: УСТАНОВКА ВИДЕО-ДРАЙВЕРА (chroot) #######
# ########################################################
#
# ВАЖНО: ЭТОТ БЛОК ЗАМЕНЕН НА ОТДЕЛЬНУЮ ИНСТРУКЦИЮ.
#        СЛЕДУЙТЕ ИНСТРУКЦИИ ИЗ ФАЙЛА:
#        video_drivers_guide.m
#        ЭТА ИНСТРУКЦИЯ СОДЕРЖИТ ПОЛНЫЕ ШАГИ ДЛЯ INTEL, AMD И NVIDIA.
#        ОНА УЧИТЫВАЕТ ГИБЕРНАЦИЮ И ГИБРИДНУЮ ГРАФИКУ.
# ----------------------------------------------------------
# 1. Скопируйте команды из выбранного вами раздела (Intel/AMD/NVIDIA)
#    из файла 'video_drivers_guide.m'.
# 2. ВСТАВЬТЕ ИХ И ВЫПОЛНИТЕ В ТЕРМИНАЛЕ CHROOT.
# 3. Следуйте всем инструкциям из руководства, включая настройку
#    mkinitcpio и GRUB (grub-mkconfig -o /boot/grub/grub.cfg, mkinitcpio -P).
# 4. После УСПЕШНОЙ установки драйверов и выполнения финальных команд
#    из руководства, ВЕРНИТЕСЬ К ЭТОМУ МАКЕТУ.
# 5. ПРОДОЛЖИТЕ УСТАНОВКУ: выберите и выполните БЛОКИ УСТАНОВКИ DE/WM.
# 6. ПОСЛЕ УСТАНОВКИ DE/WM ВЫПОЛНИТЕ 'exit' В ЭТОМ ТЕРМИНАЛЕ CHROOT.
#    ТОЛЬКО ТОГДА продолжайте копирование команд из основного макета
#    для размонтирования и выключения.
# ----------------------------------------------------------






# ############################################
# ## УСТАНОВКА VIRTUALBOX (chroot) ###########
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
#        (см. video_drivers_guide.m) перед установкой DE/WM.
#        ПЕРЕД УСТАНОВКОЙ DE/WM: выполните 'exit' из chroot, затем снова arch-chroot /mnt /bin/bash






# #######################################################
# ## 🌌 УСТАНОВКА KDE PLASMA ############################
# #######################################################
#
# Зачем: Установка среды KDE Plasma.
# Включает: Все компоненты, SDDM, kde-apps.

clear
#### Plasma ####
pacman -Syy
pacman -S --noconfirm plasma-meta kde-system-meta dolphin-plugins kate konsole skanpage skanlite gwenview elisa okular ark
pacman -S --noconfirm ffmpegthumbs poppler-qt6
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
## Питание ноутбука (раскомментируйте в случае необходимости)
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
pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
pacman -S --noconfirm mugshot pavucontrol xdg-user-dirs xdg-desktop-portal-gtk ristretto thunar-archive-plugin tumbler tumbler-plugins-extra
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
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
# Включает: LightDM.

clear
pacman -Syy
pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -S --noconfirm cinnamon cinnamon-translations blueberry lightdm lightdm-gtk-greeter
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -S --noconfirm ffmpegthumbnailer poppler-qt6
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
pacman -S --noconfirm lxde openbox mousepad lightdm lightdm-slick-greeter blueman thunar-archive-plugin ffmpegthumbnailer udiskie xfce4-notifyd dunst picom
pacman -S --noconfirm ffmpegthumbnailer poppler-glib gnome-themes-extra
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
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
pacman -S --noconfirm budgie-desktop budgie-screensaver gnome-control-center dconf-editor budgie-desktop-view budgie-backgrounds
pacman -S --noconfirm lightdm lightdm-gtk-greeter
pacman -S --noconfirm gnome-terminal nautilus vlc eog evince gedit
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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






# ########################################################
# ## ЗАВЕРШЕНИЕ ВСЕХ ПРОЦЕССОВ ###########################
# ########################################################
#
# Отмонтирование разделов диска
umount -R /mnt
swapoff -a
poweroff





# Очистка конфигурации ssh соединения (При необходимости)
rm -r .ssh/
