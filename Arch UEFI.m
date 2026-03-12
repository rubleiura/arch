# ################################################################
# ## 🐧 МАКЕТ БЛОЧНОЙ УСТАНОВКИ ARCH LINUX (BTRFS)              ##
# ################################################################
#
# ℹ️ Назначение: Пошаговая установка Arch Linux с BTRFS.
# 💡 Метод: Копируйте и вставляйте блоки команд по одному.
# ❗ Важно: Не запускайте как скрипт! Выполняйте вручную.
# 🌐 Требуется: Интернет, загрузочная среда Arch Linux (свежий ISO).
#
# 💡 Примечание: Данная установка предназначена для компьютеров с UEFI.

# Структура:
#   1. Подготовка Live-среды
#   2. Диагностика оборудования
#   3. Настройка переменных (обязательно!)
#   4. Разметка диска (GPT + UEFI)
#   5. Форматирование и монтирование
#   6. Установка базовых пакетов
#   7. Настройки внутри системы (chroot)
#   8. Hostname и пароль root (chroot)
#   9. Пользователь и sudo (chroot)
#   10. Установка ядра, GRUB, mkinitcpio (chroot)
#   11. Системные утилиты и настройки (chroot)
#   12. Установка видеодрайвера (chroot)
#   13. Установка в VirtualBox (chroot) (опционально)
#   14. Установка графической среды (DE/WM) (chroot)
#   15. Завершение процесса
#   16. Рекомендации после установки





## ########################################################
# ## ⚙️ [LIVE] БЛОК 1: ПОДГОТОВКА LIVE-СРЕДЫ #############
# ########################################################
#
# ℹ️ Зачем: Настройка системных часов, обновление зеркал, установка
#          вспомогательных утилит.
# ℹ️ Важно: Выполняется в загрузочной среде (до chroot).
# 💡 Включает: `haveged`, `inxi`, `lshw`.

clear
loadkeys ru
setfont cyr-sun16
timedatectl set-ntp true
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
timedatectl set-ntp true
# Reflector
echo "--country Belarus,Estonia,Finland,Germany,Latvia,Lithuania,Norway,Russia,Sweden" > /etc/xdg/reflector/reflector.conf
echo "--protocol https" >> /etc/xdg/reflector/reflector.conf
echo "--age 24" >> /etc/xdg/reflector/reflector.conf
echo "--sort rate" >> /etc/xdg/reflector/reflector.conf
echo "--latest 20" >> /etc/xdg/reflector/reflector.conf
echo "--connection-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--download-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--save /etc/pacman.d/mirrorlist" >> /etc/xdg/reflector/reflector.conf
systemctl restart reflector
clear
echo ""
pacman -Syy
pacman -Sy --noconfirm haveged inxi util-linux
pacman -Sy --noconfirm lshw
systemctl enable haveged.service --now
clear
echo ""
echo "#####################################################"
echo "## ✅ ПОДГОТОВКА LIVE-СРЕДЫ ЗАВЕРШЕНА              ##"
echo "#####################################################"
echo ""






# ################################################################
# ## 🔍  [LIVE] БЛОК 2: ДИАГНОСТИКА ОБОРУДОВАНИЯ                ##
# ################################################################
#
# ℹ️ Зачем: Вывод информации об оборудовании (процессор, материнская
#          плата, диски) для корректной настройки переменных.
# ❗ Важно: Сравните вывод с переменными в БЛОКЕ 3.
# 💡 Показывает: Производителя CPU, модель MB, список дисков/разделов,
#                рекомендованные параметры монтирования FSTAB.

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
echo "=== РЕКОМЕНДУЕМЫЕ ПАРАМЕТРЫ МОНТИРОВАНИЯ FSTAB ==="
echo "Определение типа дисков (HDD/SSD) для параметров монтирования:"
{ \
echo; \
for DEVICE in $(lsblk -dno NAME 2>/dev/null | grep -v -e '^loop' -e '^sr'); do \
    DEVICE_PATH="/dev/$DEVICE"; \
    [[ ! -b "$DEVICE_PATH" ]] && continue; \
    ROTA=$(lsblk -d -o ROTA --noheadings "$DEVICE_PATH" 2>/dev/null | awk '{print $1}'); \
    if [[ "$ROTA" == "1" ]]; then \
        DISK_TYPE="HDD (Замените 'defaults' в БЛОКЕ 3 на):"; \
        MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:3,autodefrag"; \
    else \
        DISK_TYPE="SSD (Замените 'defaults' в БЛОКЕ 3 на):"; \
        MOUNT_OPTIONS="ssd,noatime,space_cache=v2,compress=zstd:3,discard=async"; \
    fi; \
    echo "╔══════════════════════════════════════════════════════════════════════════════════╗"; \
    printf "║  Диск: %-60s\n" "/dev/$DEVICE"; \
    echo "╠══════════════════════════════════════════════════════════════════════════════════╣"; \
    printf "║  Тип: %-60s\n" "$DISK_TYPE"; \
    printf "║  параметры монтирования: %-60s\n" "$MOUNT_OPTIONS"; \
    echo "╚══════════════════════════════════════════════════════════════════════════════════╝"; \
    echo; \
done; \
}
echo ""
echo "#####################################################"
echo "## ✅ ДИАГНОСТИКА ОБОРУДОВАНИЯ ЗАВЕРШЕНА           ##"
echo "#####################################################"
echo ""





# ################################################################
# ## 🔧  [EDIT] БЛОК 3: НАСТРОЙКА ПЕРЕМЕННЫХ (ОБЯЗАТЕЛЬНО!)  #####
# ################################################################
#
# ℹ️ Зачем: Настроить макет под ваше оборудование.
# ❗ ВАЖНО: Замена переменных происходит в ДВА ЭТАПА (см. таблицу ниже)!
#
# 💡 ИНСТРУКЦИЯ:
# ЭТАП 1 (СЕЙЧАС, до Блока 4):
#   • Замените переменные, отмеченные как "ЭТАП 1".
#   • Это необходимо для корректной разметки диска.
#
# ЭТАП 2 (ПОСЛЕ Блока 4 — разметки диска):
#   • После создания разделов замените переменные "ЭТАП 2"
#     (sda1, sda2, sda3) на реальные имена разделов.
#   • Используйте вывод `lsblk` из Блока 4 для определения имён.
#
# 📌 Примечание: Порядок замены критичен! Не меняйте sda1/sda2/sda3 до
#                завершения Блока 4 — иначе установка завершится ошибкой.

# #################################################################################
# # Назначение                 # Значение (шаблон)      # Когда менять?           #
# #################################################################################
# # Имя диска                  # sdx                    # ЭТАП 1 (сейчас)         #
# # BIOS BOOT / ESP раздел     # sda1                   # ЭТАП 2 (после Блока 4)  #
# # Root раздел                # sda2                   # ЭТАП 2 (после Блока 4)  #
# # Swap раздел                # sda3                   # ЭТАП 2 (после Блока 4)  #
# # Размер SWAP                # 4G                     # ЭТАП 1 (сейчас)         #
# # Имя компьютера (HOSTNAME)  # Sony                   # ЭТАП 1 (сейчас)         #
# # Имя пользователя           # forename               # ЭТАП 1 (сейчас)         #
# # Полное имя пользователя    # User Name              # ЭТАП 1 (сейчас)         #
# # Microcode                  # amd-ucode              # ЭТАП 1 (сейчас)         #
# # Ядро                       # linux-lts              # ЭТАП 1 (сейчас)         #
# # bootloader-id              # Grub Arch Linux        # ЭТАП 1 (сейчас)         #
# # Параметры монтирования     # defaults               # ЭТАП 1 (сейчас)         #
# #################################################################################

# 💡 СОВЕТ: После ЭТАПА 1 проверьте, что в файле больше нет строки "sdx".
#          После ЭТАПА 2 — проверьте, что разделы "sda1", "sda2", "sda3"
#          Соответствуют имени своего диска "sdx".

#
#
# "#####################################################"
# "## ✅ ПЕРЕМЕННЫЕ НАСТРОЕНЫ. ПРОДОЛЖАЙТЕ К БЛОКУ 4  ##"
# "#####################################################"







# ################################################################
# ## 💾  [LIVE] БЛОК 4: РАЗМЕТКА ДИСКА (GPT + UEFI)             ##
# ################################################################
#
# ℹ️ Зачем: Создание разделов: EFI System Partition (ESP), root, swap.
# ❗ ВАЖНО: Все данные на /dev/sdx будут УДАЛЕНЫ!
# 💡 Используется: `sgdisk` для создания таблицы разделов GPT.
# ℹ️ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sdx' заменен на ваш диск!

clear
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
sgdisk -a 2048 -o /dev/sdx
sgdisk -n 1::+1024M --typecode=1:ef00 --change-name=1:'EFI System Partition' /dev/sdx
sgdisk -n 2::-4G --typecode=2:8300 --change-name=2:'Root Arch Linux' /dev/sdx
sgdisk -n 3::-0 --typecode=3:8200 --change-name=3:'Swap Arch Linux' /dev/sdx
clear
echo ""
fdisk -l /dev/sdx
echo ""
lsblk -a /dev/sdx
echo ""
echo "#####################################################"
echo "## ✅ РАЗМЕТКА ДИСКА ЗАВЕРШЕНА                     ##"
echo "#####################################################"
echo ""
echo ""

# 💡 ОБЯЗАТЕЛЬНО:
#   После разметки проверьте, что разделы "sda1", "sda2", "sda3"
#   Соответствуют имени своего диска "sdx".





# ################################################################
# ## 💾  [LIVE] БЛОК 5: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ           ##
# ################################################################
#
# ℹ️ Зачем: Форматирование, создание подтомов Btrfs, монтирование.
# ℹ️ Важно: Выполняется до chroot.
# 💡 Подтомы: `@`, `@home`, `@log`, `@pkg`.
# ❗ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sda1', 'sda2', 'sda3' заменены на правильные разделы (например, 'nvme0n1p1')!

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
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/sdx
echo ""
lsblk /dev/sdx
echo ""
btrfs subvolume list /mnt
echo ""
echo "#####################################################"
echo "## ✅ ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ЗАВЕРШЕНО      ##"
echo "#####################################################"
echo ""





# ################################################################
# ## 🧱  [LIVE] БЛОК 6: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ               ##
# ################################################################
#
# ℹ️ Зачем: Установка минимальной системы и переход в chroot.
# ℹ️ Важно: После этого — вход в chroot.
# 💡 Включает: `base`, `btrfs`, `nano`, `pacman-contrib`.

clear
pacstrap /mnt base base-devel
pacstrap /mnt btrfs-progs
pacstrap /mnt amd-ucode iucode-tool
pacstrap /mnt memtest86+-efi
pacstrap /mnt nano
pacstrap /mnt pacman-contrib curl reflector
genfstab -pU /mnt >> /mnt/etc/fstab
clear
echo ""
echo "#####################################################"
echo "## ✅ УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА          ##"
echo "#####################################################"
echo ""
arch-chroot /mnt /bin/bash
echo ""





# ################################################################
# ## 🛠️  [CHROOT] БЛОК 7: НАСТРОЙКИ ВНУТРИ СИСТЕМЫ              ##
# ################################################################
#
# ℹ️ Зачем: Настройка системы: локали, fstab, время, зеркала.
# ℹ️ Важно: Выполняется внутри chroot.
# 💡 Автоматизация: Временная зона по IP, зеркала по стране.
# 💡 Шрифты: Установлены (Noto, DejaVu, Liberation, Terminus).

clear
# ... (остальные команды sed для pacman.conf остаются без изменений) ...
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,defaults/g'  /etc/fstab
pacman-key --init
pacman-key --populate archlinux
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
# --- НАСТРОЙКА КОНСОЛЬНОГО ШРИФТА (TTY) И РАСКЛАДКИ ---
# ℹ️ Устанавливаем русскую раскладку и шрифт для текстового терминала (TTY).
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf # <-- Убедитесь, что 'cyr-sun16' доступен, если возникнут проблемы.
# --- Конец настройки TTY ---
# --- НАСТРОЙКА ЛОКАЛИ ---
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
# --- Конец настройки локали ---
# --- НАСТРОЙКА ВРЕМЕНИ ---
time_zone=$(curl -s https://ipinfo.io/timezone                    )
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
# --- Конец настройки времени ---
# --- НАСТРОЙКА REFLCTOR (зеркала) ---
echo "--country Belarus,Estonia,Finland,Germany,Latvia,Lithuania,Norway,Russia,Sweden" > /etc/xdg/reflector/reflector.conf
echo "--protocol https" >> /etc/xdg/reflector/reflector.conf
echo "--age 24" >> /etc/xdg/reflector/reflector.conf
echo "--sort rate" >> /etc/xdg/reflector/reflector.conf
echo "--latest 20" >> /etc/xdg/reflector/reflector.conf
echo "--connection-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--download-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--save /etc/pacman.d/mirrorlist" >> /etc/xdg/reflector/reflector.conf
systemctl enable reflector.timer
clear
# --- Конец настройки reflector ---
clear
echo ""
timedatectl status
echo ""
date
echo ""
echo "#####################################################"
echo "## ✅ БАЗОВАЯ КОНФИГУРАЦИЯ ЗАВЕРШЕНА               ##"
echo "#####################################################"
echo ""





# ################################################################
# ## 🔐  [CHROOT] БЛОК 8: НАСТРОЙКА HOST И ROOT                 ##
# ################################################################
#
# ℹ️ Зачем: Настройка имени системы и пароля root.
# ❗ Важно: Без этого система не загрузится корректно.

clear
echo "Sony" > /etc/hostname
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Sony.localdomain   Sony" >> /etc/hosts
clear
echo ""
echo "###################################"
echo "## 🔑 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ ROOT   ##"
echo "###################################"
echo ""
passwd
clear
echo ""
echo "#####################################################"
echo "## ✅ НАСТРОЙКА ROOT И HOST ЗАВЕРШЕНА              ##"
echo "#####################################################"
echo ""





# ################################################################
# ## 👤  [CHROOT] БЛОК 9: ПОЛЬЗОВАТЕЛЬ И SUDO                   ##
# ################################################################
#
# ℹ️ Зачем: Создание пользователя и настройка sudo.
# ❗ Важно: Без wheel — sudo не будет работать.

clear
useradd forename -m -c "User Name" -s /bin/bash
usermod -aG wheel,users forename
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
clear
echo ""
echo "###########################################"
echo "## 👤 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ ПОЛЬЗОВАТЕЛЯ   ##"
echo "###########################################"
echo ""
passwd forename
clear
echo ""
echo "#####################################################"
echo "## ✅ НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ И SUDO ЗАВЕРШЕНА      ##"
echo "#####################################################"
echo ""





# ################################################################
# ## 🔧  [CHROOT] БЛОК 10: УСТАНОВКА ЯДРА, GRUB, MKINITCPIO     ##
# ################################################################
#
# ℹ️ Зачем: Настройка загрузчика и initramfs.
# 💡 Включает: `GRUB`, `grub-btrfs`, `plymouth`, `resume` из swap.

clear
pacman -Syy
pacman -Sy --noconfirm linux-lts linux-lts-headers linux-firmware
pacman -Sy --noconfirm grub grub-btrfs efibootmgr os-prober
pacman -Sy --noconfirm networkmanager wpa_supplicant wireless_tools
pacman -Sy --noconfirm openssh
pacman -Sy --noconfirm plymouth
systemctl enable NetworkManager.service grub-btrfsd.service sshd.service
grub-install --efi-directory=/boot --boot-directory=/boot --bootloader-id="Grub Arch Linux"
sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/quiet/quiet splash/' /etc/default/grub
sed -i "s/#GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/" /etc/default/grub-btrfs/config
sed -i "s/#GRUB_BTRFS_TITLE_FORMAT=(\"date\" \"snapshot\" \"type\" \"description\")/GRUB_BTRFS_TITLE_FORMAT=(\"description\" \"date\")/" /etc/default/grub-btrfs/config
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
echo "#####################################################"
echo "## ✅ ЗАГРУЗЧИК И ЯДРО УСТАНОВЛЕНЫ                 ##"
echo "#####################################################"
echo ""





# ################################################################
# ## 🛠️  [CHROOT] БЛОК 11: СИСТЕМНЫЕ УТИЛИТЫ И НАСТРОЙКИ        ##
# ################################################################
#
# ℹ️ Зачем: Установка системных утилит, PipeWire, шрифтов.
# 💡 Включает: `Bluetooth`, `CUPS`, `xdg`, `PipeWire`, `Chromium`.
# 💡 Расширено: Добавлены утилиты для администрирования, просмотра файлов, сжатия, мониторинга и обслуживания.

clear
pacman -Syy
pacman -Sy --noconfirm haveged
systemctl enable haveged.service
# Добавлены: neovim, ripgrep, bat, zstd, lz4, btop, smartmontools, lm_sensors, rsync, git, fwupd
pacman -Sy --noconfirm wget usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
pacman -Sy --noconfirm neovim ripgrep bat zstd lz4 btop smartmontools lm_sensors rsync git fwupd
systemctl enable fwupd.service
pacman -Sy --noconfirm dosfstools ntfs-3g exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
pacman -Sy --noconfirm dbus-broker
systemctl enable dbus-broker.service
pacman -Sy --noconfirm cronie
systemctl enable cronie.service systemd-timesyncd.service
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
pacman -Sy --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
pacman -Sy --noconfirm cups cups-pdf ghostscript gsfonts avahi system-config-printer simple-scan
systemctl enable cups.service avahi-daemon.service
pacman -Sy --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
pacman -Sy --noconfirm udisks2 udiskie polkit
pacman -Sy --noconfirm pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
pacman -Sy --noconfirm wireplumber
systemctl --global enable pipewire pipewire-pulse wireplumber
pacman -Sy --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss taglib
pacman -Sy --noconfirm man-db man-pages man-pages-ru
pacman -Sy --noconfirm iproute2 inetutils dnsutils
# ШАГ 1/8 — ОБНОВЛЕНИЕ БАЗЫ ПАКЕТОВ
pacman -Syyy --noconfirm
# ШАГ 2/8 — УСТАНОВКА БАЗОВЫХ ШРИФТОВ
pacman -Sy --noconfirm noto-fonts noto-fonts-emoji ttf-dejavu ttf-liberation terminus-font
# ШАГ 3/8 — УСТАНОВКА CJK ШРИФТОВ (ВЫБЕРИТЕ ОДИН ВАРИАНТ)
pacman -Sy --noconfirm wqy-zenhei wqy-bitmapfont
# ШАГ 4/8 — УСТАНОВКА КОМПОНЕНТОВ РЕНДЕРИНГА
pacman -Sy --noconfirm fontconfig freetype2 harfbuzz libxft
# ШАГ 5/8 — ОБНОВЛЕНИЕ КЭША ШРИФТОВ
fc-cache -fv
clear
echo ""
echo "######################################"
echo "## ✅ СИСТЕМНЫЕ УТИЛИТЫ НАСТРОЕНЫ   ##"
echo "######################################"
echo ""
echo "##############################################"
echo "## 🎮 ОПРЕДЕЛЕНИЕ ВИДЕОКАРТЫ ДЛЯ ДРАЙВЕРОВ  ##"
echo "##############################################"
echo ""
lspci -nn | grep -i 'vga\|3d\|display'
lsmod | grep -iE 'nvidia|amdgpu|i915|nouveau'





# #########################################################################
# ## 🖥️  [CHROOT] БЛОК 12: УСТАНОВКА ГРАФИЧЕСКИХ ДРАЙВЕРОВ (ОПЦИОНАЛЬНО) ##
# #########################################################################
#
# 💡 Цель: Установить драйверы для Intel, AMD, NVIDIA (включая nouveau).
# ⚠️  ВАЖНО: **ЕСЛИ УСТАНОВКА В VIRTUALBOX — ПРОПУСТИТЕ ЭТОТ БЛОК!**
#            Перейдите напрямую к БЛОКУ 13.
# 🔧  Следуйте инструкциям ниже шаг за шагом.
# 📥  Результат: Готовая к работе графическая подсистема.
# 🧪  Проверка: Информация о GPU и загруженных модулях отображена в БЛОКЕ 11.
# 🔄 СЛЕДУЮЩИЙ ШАГ: После завершения — БЛОК 14 (установка DE/WM).

# ###################################################################
# ## 📦 ШАГ 1: УСТАНОВКА ДРАЙВЕРОВ (РАСКОММЕНТИРУЙТЕ ОДИН ВАРИАНТ) ##
# ###################################################################
##
# ℹ️ Зачем: Установить драйверы, соответствующие вашей видеокарте.
# ❗ Важно: Раскомментируйте ТОЛЬКО ОДИН вариант ниже!
# 💡 Все команды закомментированы. Уберите '#' перед нужными строками.
# 💡 Проверьте вывод из БЛОКА 11, чтобы определить GPU и его архитектуру (см. инструкции по lspci выше).

clear
#### === Intel Integrated Graphics ===
# pacman -Sy --noconfirm mesa vulkan-intel lib32-mesa lib32-vulkan-intel

#### === AMD Radeon Graphics или Open-Source NVIDIA (nouveau) ===
# pacman -Sy --noconfirm mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon


#### === NVIDIA (Проприетарные драйверы) ===
# 📌 ВАЖНО: Этот раздел делится на два подраздела: современные и устаревшие драйверы.
#          Определите архитектуру вашей карты (например, GM204 = Maxwell, TU104 = Turing) через lspci.

# --- C1. Современные GPU (Pascal, Turing, Ampere, Ada Lovelace и новее): ---
# 💡 ОФИЦИАЛЬНАЯ РЕКОМЕНДАЦИЯ NVIDIA:
# «Многие дистрибутивы Linux предоставляют собственные пакеты драйвера NVIDIA...»

# 📌 ВЕТКИ ДРАЙВЕРОВ:
# 1. **Production Branch (рекомендовано для большинства):**

# A. Для стандартного ядра (linux):
# pacman -Sy --noconfirm nvidia-open nvidia-utils lib32-nvidia-utils

# B. Для LTS-ядра (linux-lts):
# pacman -Sy --noconfirm nvidia-open-lts nvidia-utils lib32-nvidia-utils

# C. Универсальный DKMS-драйвер (для кастомных ядер):
# pacman -Sy --noconfirm nvidia-open-dkms nvidia-utils lib32-nvidia-utils

# 📌 ГИБРИДНАЯ ГРАФИКА (Intel/AMD + NVIDIA):
# pacman -Sy --noconfirm switcheroo-control
# systemctl enable switcheroo-control.service

# 📌 ТОЛЬКО ДЛЯ СИСТЕМ С ОДНОЙ СОВРЕМЕННОЙ NVIDIA-КАРТОЙ:
# pacman -Sy --noconfirm libva-nvidia-driver


# ###################################################
# ## 🧰 ШАГ 2: УСТАНОВКА ДОПОЛНИТЕЛЬНЫХ БИБЛИОТЕК  ##
# ###################################################
#
# ℹ️ Зачем: Обеспечить совместимость с Vulkan и VA-API.
# 💡 Обязательно для всех типов GPU.
# pacman -Sy --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader


# ########################################################
# ## 🔧 ШАГ 3: КОНФИГУРАЦИЯ МОДУЛЕЙ И INITRAMFS  #########
# ########################################################
#
# ℹ️ Зачем: Включить режим модсета для NVIDIA (требуется для Wayland).
# ❗ ВАЖНО: Выполняется ТОЛЬКО при установке NVIDIA драйверов (любой ветки, включая устаревшие).
# 💡 Этот шаг применяется ТОЛЬКО если вы выбрали ВАРИАНТ C (NVIDIA Proprietary).

# === ТОЛЬКО ДЛЯ NVIDIA (ПРОПРИЕТАРНЫЕ): Настройка модулей и initramfs ===
# 📌 РАСКОММЕНТИРУЙТЕ СЛЕДУЮЩИЕ СТРОКИ, ЕСЛИ ВЫ УСТАНАВЛИВАЕТЕ NVIDIA-ДРАЙВЕР:
# echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia.conf
# Для ноутбуков (опционально)
# echo 'options nvidia NVreg_DynamicPowerManagement=0x02' >> /etc/modprobe.d/nvidia.conf
# echo 'nvidia-drm' > /etc/modules-load.d/nvidia-drm.conf

# 🔄 Пересобираем initramfs — ОБЯЗАТЕЛЬНО!
mkinitcpio -P

# ########################################################
# ## 🔋 ШАГ 4: ОПЦИОНАЛЬНО — НАСТРОЙКИ ДЛЯ НОУТБУКОВ  ####
# ########################################################
#
# ℹ️ Зачем: Улучшить энергоэффективность на ноутбуках.
# 💡 Используется TLP — современный инструмент управления питанием.
# ❗ ВАЖНО: Если у вас гибридная графика с NVIDIA, прочитайте инструкции по настройке TLP.

#### === ТОЛЬКО ДЛЯ НОУТБУКОВ (БЕЗ ГИБРИДНОЙ ГРАФИКИ NVIDIA) ===
# pacman -Sy --noconfirm tlp tlp-rdw
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

#### === ТОЛЬКО ДЛЯ НОУТБУКОВ (С ГИБРИДНОЙ ГРАФИКОЙ NVIDIA) ===
# pacman -Sy --noconfirm tlp tlp-rdw
# --- Настройка TLP для совместимости с NVIDIA ---
# 1. Определите PCI-адрес NVIDIA-видеокарты:
# lspci -nn | grep -i nvidia
# (Пример вывода: 01:00.0 3D controller: NVIDIA Corporation TU104 [GeForce RTX 2080 Rev. A] [10de:1e82] (rev a1))
# (PCI ID: 10de:1e82, Адрес: 01:00.0)
# 2. Отредактируйте конфигурационный файл TLP:
# nano /etc/tlp.conf
# Найдите строку RUNTIME_PM_DENYLIST= и добавьте туда **адрес** вашей NVIDIA-видеокарты (в примере это `01:00.0`). Также часто добавляют аудиоконтроллер, связанный с dGPU (например, `01:00.1`).
# RUNTIME_PM_DENYLIST="01:00.0 01:00.1"
# Сохраните файл и закройте редактор.
# 3. Включите службу TLP:
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

clear
echo ""
echo "# ################################################################"
echo "# ## 🧭 ЗАВЕРШЕНИЕ БЛОКА 12                                     ##"
echo "# ################################################################"
echo "#"
echo "# ✅ ВСЕ ДЕЙСТВИЯ ВЫПОЛНЕНЫ."
echo "# ⚠️ НЕ ВЫХОДИТЕ из chroot!"
echo "# 📌 Убедитесь, что все команды из выбранных шагов выполнены."
echo "#"
echo "# ➡️ ПРОДОЛЖИТЕ УСТАНОВКУ:"
echo "# Выполните следующий БЛОК 14 в этом же файле:"
echo "#   [CHROOT] УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ (DE/WM)"
echo ""






# ################################################################
# ## 🖥️  [CHROOT] БЛОК 13: УСТАНОВКА В VIRTUALBOX               ##
# ################################################################
#
# ℹ️ Зачем: Настройка интеграции с VirtualBox.
# ❗ Важно: Только если установка в VirtualBox.

clear
pacman -Sy --needed --noconfirm virtualbox-guest-utils
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice.service
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
usermod -aG vboxsf forename
clear
echo ""
echo "#####################################################"
echo "## ✅ НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА               ##"
echo "#####################################################"
echo ""
# ➡️ ПРОДОЛЖИТЕ: перейдите к БЛОКУ 14 или завершите установку без DE





# ################################################################
# ## 🖥️  [CHROOT] БЛОК 14: УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ (DE/WM)  ##
# ################################################################
#
# ℹ️ Зачем: Установка выбранного окружения рабочего стола или
#          менеджера окон.
# 💡 Включает: Подблоки для KDE Plasma, GNOME, XFCE4 и других.
# 💡 Расширено: Добавлены подблоки для тайлинговых оконных менеджеров Sway и Hyprland.
# ❗ Важно: Убедитесь, что видеодрайверы установлены (см. БЛОК 12).

#### "=== УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ ==="
#### "Выберите и выполните один из следующих подблоков:"
####   - KDE PLASMA
####   - GNOME
####   - XFCE4
####   - MATE
####   - CINNAMON
####   - LXQT
####   - LXDE
####   - BUDGIE





# ################################################################
# ## 🌐 УСТАНОВКА KDE PLASMA                                    ##
# ################################################################
#
# ℹ️ Зачем: Установка среды KDE Plasma.
# 💡 Включает: Все компоненты, SDDM, kde-apps.
# 💡 Комментарий: KDE использует собственную систему KIO, но GVFS добавляет
#                совместимость с GTK+ приложениями и расширенную интеграцию
#                с GNOME Online Accounts и другими сервисами.
# 💡 Рекомендация: Установка GVFS рекомендуется для лучшей совместимости.

clear
#### Plasma ####
pacman -Syy
pacman -Sy --noconfirm plasma kde-system-meta dolphin-plugins kate konsole skanpage skanlite gwenview elisa okular ark
pacman -Sy --noconfirm ffmpegthumbs poppler-glib
pacman -Sy --noconfirm packagekit packagekit-qt6
# Установка GVFS для KDE Plasma (рекомендуется для полной совместимости)
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm sddm
systemctl enable sddm.service
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ KDE PLASMA УСТАНОВЛЕНА УСПЕШНО               ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🌐 УСТАНОВКА GNOME                                         ##
# ################################################################
#
# ℹ️ Зачем: Установка GNOME с полной интеграцией.
# 💡 Включает: `GDM`, `portal`, `apps`, `extensions`.
# 💡 Комментарий: GVFS является неотъемлемой частью GNOME.
#                Установка адаптеров обеспечивает полную функциональность.

clear
###  GNOME  ##
pacman -Syy
pacman -Sy --noconfirm gnome
###  gnome-extra  ###
pacman -Sy --noconfirm dconf-editor
pacman -Sy --noconfirm file-roller
pacman -Sy --noconfirm gnome-tweaks
#
pacman -Sy --noconfirm gnome-themes-extra
pacman -Sy --noconfirm gnome-browser-connector
pacman -Sy --noconfirm gnome-shell-extensions
# GVFS и его адаптеры являются основой файловой системы в GNOME
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
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
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ GNOME УСТАНОВЛЕНА УСПЕШНО                    ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🪟 УСТАНОВКА XFCE4                                         ##
# ################################################################
#
# ℹ️ Зачем: Установка XFCE4 с расширенными компонентами.
# 💡 Включает: `LightDM`, `plugins`, `apps`.
# 💡 Комментарий: XFCE4 основан на GTK+, поэтому GVFS критически важна
#                для доступа к сетевым ресурсам, облачным хранилищам
#                и внешним устройствам.

clear
pacman -Syyy
pacman -Sy --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --noconfirm network-manager-applet blueman
pacman -Sy --noconfirm mugshot pavucontrol xdg-user-dirs xdg-desktop-portal-gtk ristretto thunar-archive-plugin ffmpegthumbnailer
# Установка GVFS и адаптеров для полной функциональности XFCE4
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ XFCE4 УСТАНОВЛЕНА УСПЕШНО                    ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🍃 УСТАНОВКА MATE                                          ##
# ################################################################
#
# ℹ️ Зачем: Установка MATE с темами и greeter.
# 💡 Включает: `LightDM`.
# 💡 Комментарий: MATE, как наследник GNOME 2, тесно интегрирован с GNOME-технологиями.
#                GVFS необходима для доступа к онлайн-аккаунтам и сетевым ресурсам.

clear
pacman -Syyy
pacman -Sy --noconfirm mate mate-extra lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --noconfirm network-manager-applet blueman
# Установка GVFS и адаптеров для полной функциональности MATE
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
clear
echo ""
# echo "#####################################################"
# echo "## ✅ MATE УСТАНОВЛЕНА УСПЕШНО                     ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🕯️ УСТАНОВКА CINNAMON                                      ##
# ################################################################
#
# ℹ️ Зачем: Установка Cinnamon с дополнительными пакетами.
# 💡 Включает: `LightDM`, `greeter`, `themes`.
# 💡 Комментарий: Cinnamon также использует GTK+ и зависит от GVFS
#                для аналогичных функций, как XFCE4 и MATE.

clear
pacman -Syyy
pacman -Sy --noconfirm cinnamon cinnamon-translations blueman lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings gnome-terminal evince
# Установка GVFS и адаптеров для полной функциональности Cinnamon
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ CINNAMON УСТАНОВЛЕНА УСПЕШНО                 ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🧩 УСТАНОВКА LXQT                                          ##
# ################################################################
#
# ℹ️ Зачем: Установка LXQt с KWin и SDDM.
# 💡 Включает: `Themes`, `breeze`, `sddm`.
# 💡 Комментарий: LXQt основан на Qt, но для совместимости с GTK+ приложениями
#                и обеспечения полного функционала подключения устройств
#                рекомендуется установка GVFS.

clear
pacman -Syyy
pacman -Sy --noconfirm lxqt sddm breeze breeze-icons blueman featherpad libstatgrab libsysstat
pacman -Sy --noconfirm network-manager-applet blueman
# Установка GVFS и адаптеров для расширенной совместимости и функциональности LXQt
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable sddm.service
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ LXQT УСТАНОВЛЕНА УСПЕШНО                     ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🖼️ УСТАНОВКА LXDE                                          ##
# ################################################################
#
# ℹ️ Зачем: Установка LXDE с Openbox и LightDM.
# 💡 Включает: `Notifyd`, `dunst`, `plugins`.
# 💡 Комментарий: LXDE — самое легковесное окружение. Установка GVFS
#                противоречит его философии. Она не включена здесь,
#                так как может увеличить нагрузку на систему.
# 💡 Рекомендация: Устанавливать GVFS в LXDE только при крайней необходимости.

clear
pacman -Syyy
pacman -Sy --noconfirm lxde openbox mousepad lightdm lightdm-slick-greeter blueman thunar-archive-plugin ffmpegthumbnailer udiskie xfce4-notifyd dunst picom
pacman -Sy --noconfirm network-manager-applet blueman
# GVFS НЕ устанавливается для LXDE по умолчанию в соответствии с философией легковесности.
# Если необходимо, установите вручную: pacman -Sy gvfs gvfs-afc gvfs-smb gvfs-mtp ...
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib gnome-themes-extra
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ LXDE УСТАНОВЛЕНА УСПЕШНО                     ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🪟 УСТАНОВКА BUDGIE                                        ##
# ################################################################
#
# ℹ️ Зачем: Установка Budgie с расширенными компонентами.
# 💡 Включает: `LightDM`, `audacious`, `evince`.
# 💡 Комментарий: Budgie, как и другие среды на основе GTK+, полагается
#                на GVFS для доступа к различным типам хранилищ.

clear
pacman -Syyy
pacman -Sy --noconfirm budgie-desktop budgie-screensaver budgie-control-center dconf-editor budgie-desktop-view budgie-backgrounds
pacman -Sy --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --noconfirm materia-gtk-theme papirus-icon-theme
pacman -Sy --noconfirm gnome-terminal nautilus eog evince gedit
pacman -Sy --noconfirm network-manager-applet blueman
# Установка GVFS и адаптеров для полной функциональности Budgie
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
clear
echo ""
# echo "#####################################################"
# echo "## ✅ BUDGIE УСТАНОВЛЕНА УСПЕШНО                   ##"
# echo "#####################################################"
echo ""
# Выход из chroot
exit





# ################################################################
# ## 🧹  [LIVE] БЛОК 15: ЗАВЕРШЕНИЕ УСТАНОВКИ                   ##
# ################################################################
#
# 🎯 Зачем: Корректное размонтирование разделов и выключение системы.
# ⚠️ Важно: Выполняется ПОСЛЕ выхода из chroot (после установки DE/WM).
# 🔒 Безопасность: Гарантирует целостность файловой системы.

umount -R /mnt
swapoff -a
poweroff



# 🧹 Очистка конфигурации ssh соединения (При необходимости)
rm -r .ssh/





# ################################################################
# ## 📋  [USER] БЛОК 16: РЕКОМЕНДАЦИИ ПОСЛЕ УСТАНОВКИ           ##
# ################################################################
#
# 🎯 Зачем: Завершение настройки системы после первой загрузки.
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.

# Установка snapper, btrfsmaintenance и snap-pac (для снапшотов)
sudo pacman -Syyy
sudo pacman -Sy --noconfirm snapper snap-pac btrfsmaintenance btrfs-assistant
# 1. Установка AUR-хелпера (yay):
clear
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay
clear
# 2. Установка GUI-утилит для BTRFS и Snapper:
yay -Sy
yay -S --noconfirm snapper-support snapper-tools
clear
# Включаем службу snapper для автоматического создания снапшотов по расписанию
sudo systemctl enable snapper-timeline.timer
# НАСТРОЙКА ШРИФТОВ ДЛЯ CHROOT ARCH LINUX

# 4. Настройка Btrfs Assistant:
#    - Запустите Btrfs Assistant из меню приложений.
#    - Он может запросить права администратора для выполнения действий.
#    - Используйте его для управления снапшотами, балансировки и т.д.

# 5. Проверка работы grub-btrfs и snapper-tools:
#    - После перезагрузки и создания снапшота, в меню GRUB
#      должны появиться пункты для старых снапшотов.
#    - При выборе снапшота в GRUB может быть предложено
#      восстановить систему до этого снапшота (функция rollback из snapper-tools).

# ################################################################
