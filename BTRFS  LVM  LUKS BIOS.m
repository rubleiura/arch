# #############################################################################
# ## 🐧 МАКЕТ БЛОЧНОЙ УСТАНОВКИ ARCH LINUX (BIOS + GPT + BTRFS + LVM + LUKS) ##
# #############################################################################
#
# ℹ️ Назначение: Пошаговая установка Arch Linux с BTRFS, LVM и LUKS на систему с BIOS и GPT.
# 💡 Метод: Копируйте и вставляйте блоки команд по одному.
# ❗ Важно: Не запускайте как скрипт! Выполняйте вручную.
# 🌐 Требуется: Интернет, загрузочная среда Arch Linux (свежий ISO).
#
# 💡 Примечание:
#   - Используется Legacy BIOS с таблицей разделов GPT.
#   - Требуется BIOS Boot Partition (EF02, 4 МБ).
#   - Создаётся ОТДЕЛЬНЫЙ НЕЗАШИФРОВАННЫЙ раздел /boot (ext4, 1 ГБ).
#   - Весь остальной диск шифруется через LUKS.
#   - LVM используется поверх LUKS.
#   - Btrfs — на логическом томе LVM с подтомами (@, @home, @snapshots).
#   - Поддержка grub-btrfs и snapper.
# Структура:
#   1. Подготовка Live-среды
#   2. Диагностика оборудования
#   3. Настройка переменных
#   4. Разметка диска (GPT + BIOS Boot + /boot + LUKS)
#   5. LUKS, LVM, Btrfs, монтирование
#   6. Установка базовых пакетов
#   7–9. Локаль, пользователь, хост
#   10. Установка ядра, GRUB, mkinitcpio ← ИСПРАВЛЕН!
#   11–16. Утилиты, драйверы, DE/WM, завершение





# #######################################################
# ## ℹ️ [LIVE] ВАЖНО: ПЕРВЫЙ ШАГ ПЕРЕД УСТАНОВКОЙ #######
# #######################################################
#
# ℹ️ Зачем: Быстрая команда для синхронизации метаданных
#          Выполняется командой 'pacman -Sy'
# ℹ️ Важно: Выполняется в загрузочной среде (до chroot).
# 💡 ИНСТРУКЦИЯ:
# ЭТАП 1 (СЕЙЧАС, до Блока 1):
#   • Запустите команду 'pacman -Sy'.
#   • В случае успешной синхронизации перейти к БЛОКУ 1.
#   • В случае ошибок перейдите к ЭТАПУ 2.
#
# ЭТАП 2 (ПОСЛЕ ЭТАПА 1) Применить инструмент второго уровня:
#   • Запустите команду 'pacman -Syy'.
#   • В случае успешной синхронизации с помощью текстового редактора
#   • проведите групповую замену в макете блочной установки.
#   • с 'pacman -Sy' на 'pacman -Syy'.
#   • Это гарантирует вас от проблем при установке пакетов.
#   • Выполнив вышеуказанные шаги перейдите к БЛОКУ 1.
#
clear
echo ""
pacman -Sy





# ########################################################
# ## ⚙️ [LIVE] БЛОК 1: ПОДГОТОВКА LIVE-СРЕДЫ #############
# ########################################################
#
# ℹ️ Зачем: Настройка системных часов, обновление зеркал, установка
#          вспомогательных утилит.
# ℹ️ Важно: Выполняется в загрузочной среде (до chroot).
# 💡 Включает: `reflector`, `haveged`, `inxi`, `lshw`, `lvm2`, `cryptsetup`.

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
reflector --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
pacman -S --noconfirm haveged inxi util-linux lshw lvm2 cryptsetup
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
printf "║  Диск: %-60s
" "/dev/$DEVICE"; \
echo "╠══════════════════════════════════════════════════════════════════════════════════╣"; \
printf "║  Тип: %-60s
" "$DISK_TYPE"; \
printf "║  параметры монтирования: %-60s
" "$MOUNT_OPTIONS"; \
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
#     (sda1, sda2) на реальные имена разделов.
#   • Используйте вывод `lsblk` из Блока 4 для определения имён.
#   • Имя зашифрованного LUKS-устройства будет cryptlvm (если не измените вручную).
#   • Имя группы томов LVM будет vg_main (если не измените вручную).
#   • Имена логических томов будут lv_root, lv_home, lv_swap.
#
# 📌 Примечание: Порядок замены критичен! Не меняйте sda1/sda2 до
#                завершения Блока 4 — иначе установка завершится ошибкой.
# #################################################################################
# # Назначение                 # Значение (шаблон)      # Когда менять?           #
# #################################################################################
# # Имя диска                  # sdx                    # ЭТАП 1 (сейчас)         #
# # BIOS Boot Partition        # sda1                   # ЭТАП 2 (после Блока 4)  #
# # LUKS раздел                # sda2                   # ЭТАП 2 (после Блока 4)  #
# # Размер SWAP                # 4G                     # ЭТАП 1 (сейчас)         #
# # Имя компьютера (HOSTNAME)  # Sony                   # ЭТАП 1 (сейчас)         #
# # Имя пользователя           # forename               # ЭТАП 1 (сейчас)         #
# # Полное имя пользователя    # User Name              # ЭТАП 1 (сейчас)         #
# # Microcode                  # amd-ucode              # ЭТАП 1 (сейчас)         #
# # Ядро                       # linux-lts              # ЭТАП 1 (сейчас)         #
# # Параметры монтирования     # defaults               # ЭТАП 1 (сейчас)         #
# #################################################################################
#
# "#####################################################"
# "## ✅ ПЕРЕМЕННЫЕ НАСТРОЕНЫ. ПРОДОЛЖАЙТЕ К БЛОКУ 4  ##"
# "#####################################################"





# ################################################################
# ## 💾  [LIVE] БЛОК 4: РАЗМЕТКА ДИСКА (GPT + BIOS)             ##
# ################################################################
#
# ℹ️ Зачем: Создание разделов: BIOS Boot, зашифрованный раздел для LVM.
# ❗ ВАЖНО: Все данные на /dev/sdx будут УДАЛЕНЫ!
# 💡 Используется: `sgdisk` для GPT, `cryptsetup` для LUKS, `pvcreate/vgcreate/lvcreate` для LVM.
# 💡 Файловая система Btrfs будет на логических томах (LV) LVM.
# ℹ️ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sdx' заменен на ваш диск!

clear
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
sgdisk -a 2048 -o /dev/sdx
sgdisk -n 1:0:+4M   --typecode=1:ef02 --change-name=1:'BIOS Boot' /dev/sdx
sgdisk -n 2:0:+1G   --typecode=2:8300 --change-name=2:'Boot' /dev/sdx
sgdisk -n 3:0:0     --typecode=3:8309 --change-name=3:'LUKS Crypt' /dev/sdx
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
#   После разметки проверьте, что разделы "sda1", "sda2" , "sda3"(или другие)
#   Соответствуют имени своего диска "sdx".





# ################################################################
# ## 💾  [LIVE] БЛОК 5: ФОРМАТИРОВАНИЕ, LUKS, LVM, МОНТИРОВАНИЕ ##
# ################################################################
#
# ℹ️ Зачем: Форматируем /boot (НЕ шифруем!), создание LUKS-контейнера, настройка LVM, создание подтомов Btrfs, монтирование.
# ℹ️ Важно: Выполняется до chroot.
# 💡 Подтомы: `@`, `@home`, `@log`, `@pkg`, `@snapshots`.
# ❗ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sda1', 'sda2' заменены на правильные разделы (например, 'nvme0n1p1', 'nvme0n1p2')!
# ❗ ВАЖНО: Запомните пароль, который вы введете для LUKS!

clear
# 1. Форматируем /boot (НЕ шифруем!)
mkfs.ext4 -L BOOT /dev/sda2
clear
echo ""
echo "###################################"
echo "## 🔑 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ        ##"
echo "##   ДЛЯ ЗАЩИТЫ ДИСКА КОМПЬЮТЕРА ##"
echo "###################################"
echo ""
# 2. Шифруем sda3
cryptsetup luksFormat /dev/sda3
# 3. Открываем LUKS-контейнер (создает /dev/mapper/cryptlvm)
cryptsetup open /dev/sda3 cryptlvm
# 4. Создаем физический том LVM на открытом LUKS-устройстве
pvcreate /dev/mapper/cryptlvm
# 5. Создаем группу томов (VG)
vgcreate vg_main /dev/mapper/cryptlvm
# 6. Создаем логические тома (LV) внутри VG
lvcreate -L 4G vg_main -n lv_swap
lvcreate -l 100%FREE vg_main -n lv_root
# 7. Форматируем логический том root под Btrfs
mkfs.btrfs -f /dev/vg_main/lv_root
# 8. Монтируем root
mount /dev/vg_main/lv_root /mnt
# 9. Создаем подтомы Btrfs
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
# 10. Размонтируем временный root
umount /mnt
# 11. Монтируем подтом @ как корень
mount -o defaults,subvol=@ /dev/vg_main/lv_root /mnt
# 12. Создаем директории для монтирования других подтомов
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
# 13. Монтируем остальные подтома
mount -o defaults,subvol=@home /dev/vg_main/lv_root /mnt/home
mount -o defaults,subvol=@log /dev/vg_main/lv_root /mnt/var/log
mount -o defaults,subvol=@pkg /dev/vg_main/lv_root /mnt/var/cache/pacman/pkg
mount -o defaults,subvol=@snapshots /dev/vg_main/lv_root /mnt/.snapshots
# 14. Монтируем ОТДЕЛЬНЫЙ /boot
mount /dev/sda2 /mnt/boot
# 15. Подключаем swap
mkswap /dev/vg_main/lv_swap
swapon /dev/vg_main/lv_swap
clear
echo ""
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/sdx
echo ""
lsblk /dev/sdx
echo ""
btrfs subvolume list /mnt
echo ""
echo "################################################################"
echo "## ✅ ФОРМАТИРОВАНИЕ, LUKS, LVM И МОНТИРОВАНИЕ ЗАВЕРШЕНО      ##"
echo "################################################################"
echo ""





# ################################################################
# ## 🧱  [LIVE] БЛОК 6: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ               ##
# ################################################################
#
# ℹ️ Зачем: Установка минимальной системы и переход в chroot.
# ℹ️ Важно: После этого — вход в chroot.
# 💡 Включает: `base`, `btrfs`, `lvm2`, `nano`, `reflector`, `pacman-contrib`.
# 💡 Правильный fstab критически важен для загрузки.

clear
pacstrap /mnt base base-devel
pacstrap /mnt btrfs-progs
pacstrap /mnt lvm2 cryptsetup
pacstrap /mnt amd-ucode iucode-tool
pacstrap /mnt memtest86+
pacstrap /mnt nano reflector
genfstab -U /mnt >> /mnt/etc/fstab
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
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,defaults/g'  /etc/fstab
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
# --- НАСТРОЙКА КОНСОЛЬНОГО ШРИФТА (TTY) И РАСКЛАДКИ ---
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
# --- Конец настройки TTY ---
# --- НАСТРОЙКА ЛОКАЛИ ---
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
# --- Конец настройки локали ---
# --- НАСТРОЙКА ВРЕМЕНИ ---
time_zone=$(curl -s https://ipinfo.io/timezone)
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
# --- Конец настройки времени ---
# --- НАСТРОЙКА REFLCTOR (зеркала) ---
echo '#!/bin/bash' > /usr/local/bin/update-mirrors.sh
echo "" >> /usr/local/bin/update-mirrors.sh
echo "reflector --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist" >> /usr/local/bin/update-mirrors.sh
chmod +x /usr/local/bin/update-mirrors.sh
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
# ℹ️ Зачем: Настройка загрузчика и initramfs для LUKS+LVM+Btrfs.
# 💡 Включает: `GRUB`, `grub-btrfs`, `plymouth`, поддержку шифрования и LVM.
# ❗ КРИТИЧЕСКИ ВАЖНО: Без этих настроек система НЕ ЗАГРУЗИТСЯ.

clear
pacman -Sy
pacman -S --noconfirm linux-lts linux-lts-headers linux-firmware
pacman -S --noconfirm grub grub-btrfs os-prober
pacman -S --noconfirm networkmanager openssh plymouth
# --- MKINITCPIO ---
sed -i 's/HOOKS=(.*)/HOOKS=(base udev autodetect modconf block keyboard keymap encrypt lvm2 resume filesystems fsck)/' /etc/mkinitcpio.conf
echo 'MODULES=(btrfs dm_mod dm_crypt)' >> /etc/mkinitcpio.conf
# --- GRUB: УСТАНОВКА В MBR ---
grub-install --target=i386-pc --recheck /dev/sdx
# --- НАСТРОЙКА GRUB ДЛЯ LUKS + LVM + BTRFS ---
CRYPT_UUID=$(blkid -s UUID -o value /dev/sda3)          # LUKS-контейнер
SWAP_UUID=$(blkid -s UUID -o value /dev/vg_main/lv_swap) # своп-том в LVM
# Общие настройки
sed -i 's|^GRUB_DEFAULT=.*|GRUB_DEFAULT=0|' /etc/default/grub
sed -i 's|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=5|' /etc/default/grub
sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="Arch"|' /etc/default/grub
sed -i 's|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=menu|' /etc/default/grub
# Параметры ядра
sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash rd.shell=0 rd.emergency=halt"|' /etc/default/grub
# GRUB_CMDLINE_LINUX с UUID для cryptdevice и resume
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${CRYPT_UUID}:cryptlvm root=/dev/vg_main/lv_root rootflags=subvol=@ resume=UUID=${SWAP_UUID}\"|" /etc/default/grub
# Модули
sed -i 's|^GRUB_PRELOAD_MODULES=.*|GRUB_PRELOAD_MODULES="part_gpt part_msdos"|' /etc/default/grub
# ВАЖНО: убедитесь, что GRUB_ENABLE_CRYPTODISK ЗАКОММЕНТИРОВАН или отсутствует
sed -i 's|^GRUB_ENABLE_CRYPTODISK=.*|#GRUB_ENABLE_CRYPTODISK=y|' /etc/default/grub
# Отключить recovery
sed -i 's|^#*GRUB_DISABLE_RECOVERY=.*|GRUB_DISABLE_RECOVERY=true|' /etc/default/grub
# --- GRUB-BTRFS ---
sed -i 's/#GRUB_BTRFS_SUBMENUNAME=.*/GRUB_BTRFS_SUBMENUNAME="Arch Linux snapshots"/' /etc/default/grub-btrfs/config
sed -i 's/#GRUB_BTRFS_TITLE_FORMAT=.*/GRUB_BTRFS_TITLE_FORMAT=("description", "date")/' /etc/default/grub-btrfs/config
# --- ГЕНЕРАЦИЯ ---
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
# --- СЛУЖБЫ ---
systemctl enable NetworkManager grub-btrfsd sshd plymouth-quit
clear
echo "#####################################################"
echo "## ✅ GRUB НАСТРОЕН КОРРЕКТНО (BIOS + LUKS)        ##"
echo "##   Система загрузится и запросит пароль ОДИН раз ##"
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
pacman -Sy
pacman -S --noconfirm haveged
systemctl enable haveged.service
# Добавлены: neovim, ripgrep, bat, zstd, lz4, btop, smartmontools, lm_sensors, rsync, git, fwupd
pacman -S --noconfirm wget usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
pacman -S --noconfirm neovim ripgrep bat zstd lz4 btop smartmontools lm_sensors rsync git fwupd
systemctl enable fwupd.service
pacman -S --noconfirm dosfstools ntfs-3g exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
pacman -S --noconfirm dbus-broker
systemctl enable dbus-broker.service
pacman -S --noconfirm cronie
systemctl enable cronie.service systemd-timesyncd.service
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
pacman -S --noconfirm cups cups-pdf ghostscript gsfonts avahi system-config-printer simple-scan
systemctl enable cups.service avahi-daemon.service
# Межсетевой экран (безопасность + поддержка SSH)
pacman -S --noconfirm ufw gufw
# 🛡️ Всем входящим соединениям, не разрешенным явно, будет отказано.
ufw default deny incoming
# 🟢: Все исходящие соединения разрешены.
ufw default allow outgoing
# Разрешить SSH
# ufw allow 22/tcp
# Разрешение трафика для всей подсети (например, доступ к SSH из внутренней сети)
# ufw allow from 10.0.0.0/24 to any port 22 proto tcp
systemctl enable ufw.service
# 💡 Настройка UFW в chroot только сохраняет правила. Активация произойдёт при первой загрузке.
# 💡 Сброс настроек (после загрузки): `ufw reset`
pacman -S --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
pacman -S --noconfirm udisks2 udiskie polkit
pacman -S --noconfirm pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
pacman -S --noconfirm wireplumber
systemctl --global enable pipewire pipewire-pulse wireplumber
pacman -S --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss vlc vlc-plugins-all taglib
# Установка шрифтов: GUI + консольная поддержка (включая японский и китайский)
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-dejavu ttf-liberation terminus-font
pacman -S --noconfirm man-db man-pages man-pages-ru
pacman -S --noconfirm iproute2 inetutils dnsutils
pacman -S --noconfirm fastfetch hyfetch inxi
pacman -S --noconfirm chromium htop cpu-x gparted qbittorrent libreoffice-fresh-ru archlinux-wallpaper
# Установка snapper и snap-pac (для снапшотов)
pacman -S --noconfirm snapper snap-pac
# Включаем службу snapper для автоматического создания снапшотов по расписанию
systemctl enable snapper-timeline.timer
# --- Настройка шрифтов для улучшенного визуального восприятия в GUI ---
# Установка пакетов для рендеринга шрифтов
pacman -S --noconfirm fontconfig freetype2 lib32-freetype2 ttf-font-awesome # <-- УДАЛЕНЫ t1lib и noto-color-emoji-fontconfig
# Создание базовой конфигурации fontconfig для сглаживания и хинтинга
cat > /etc/fonts/local.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match target="font">
        <edit name="rgba" mode="assign">
            <const>rgb</const>
        </edit>
    </match>
    <match target="font">
        <edit name="hinting" mode="assign">
            <bool>true</bool>
        </edit>
    </match>
    <match target="font">
        <edit name="hintstyle" mode="assign">
            <const>hintmedium</const>
        </edit>
    </match>
    <match target="font">
        <edit name="antialias" mode="assign">
            <bool>true</bool>
        </edit>
    </match>
</fontconfig>
EOF
# Обновление кэша шрифтов
fc-cache -fv
# --- Конец настройки шрифтов ---
clear
echo ""
echo "#####################################################"
echo "## ✅ СИСТЕМНЫЕ УТИЛИТЫ, SNAPPER И UFW НАСТРОЕНЫ   ##"
echo "#####################################################"
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
# pacman -S --noconfirm mesa vulkan-intel lib32-mesa lib32-vulkan-intel

#### === AMD Radeon Graphics или Open-Source NVIDIA (nouveau) ===
# pacman -S --noconfirm mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon


#### === NVIDIA (Проприетарные драйверы) ===
# 📌 ВАЖНО: Этот раздел делится на два подраздела: современные и устаревшие драйверы.
#          Определите архитектуру вашей карты (например, GM204 = Maxwell, TU104 = Turing) через lspci.

# --- C1. Современные GPU (Pascal, Turing, Ampere, Ada Lovelace и новее): ---
# 💡 ОФИЦИАЛЬНАЯ РЕКОМЕНДАЦИЯ NVIDIA:
# «Многие дистрибутивы Linux предоставляют собственные пакеты драйвера NVIDIA...»

# 📌 ВЕТКИ ДРАЙВЕРОВ:
# 1. **Production Branch (рекомендовано для большинства):**

# A. Для стандартного ядра (linux):
# pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils

# B. Для LTS-ядра (linux-lts):
# pacman -S --noconfirm nvidia-lts nvidia-utils lib32-nvidia-utils

# C. Универсальный DKMS-драйвер (для кастомных ядер):
# pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils

# --- C2. Устаревшие GPU (Tesla, Fermi, Kepler, Maxwell): ---
# *   Эти драйверы НЕ находятся в официальных репозиториях Arch.
# # yay -S nvidia-390xx nvidia-390xx-utils nvidia-390xx-settings lib32-nvidia-390xx-utils

# 📌 ГИБРИДНАЯ ГРАФИКА (Intel/AMD + NVIDIA):
# pacman -S --noconfirm switcheroo-control
# systemctl enable switcheroo-control.service

# 📌 ТОЛЬКО ДЛЯ СИСТЕМ С ОДНОЙ СОВРЕМЕННОЙ NVIDIA-КАРТОЙ:
# pacman -S --noconfirm libva-nvidia-driver


# ###################################################
# ## 🧰 ШАГ 2: УСТАНОВКА ДОПОЛНИТЕЛЬНЫХ БИБЛИОТЕК  ##
# ###################################################
#
# ℹ️ Зачем: Обеспечить совместимость с Vulkan и VA-API.
# 💡 Обязательно для всех типов GPU.
# pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader


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
# echo 'options nvidia NVreg_DynamicPowerManagement=0x02' >> /etc/modprobe.d/nvidia.conf # Для ноутбуков (опционально)
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
# pacman -S --noconfirm tlp tlp-rdw
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

#### === ТОЛЬКО ДЛЯ НОУТБУКОВ (С ГИБРИДНОЙ ГРАФИКОЙ NVIDIA) ===
# pacman -S --noconfirm tlp tlp-rdw
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
pacman -S --needed --noconfirm virtualbox-guest-utils
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
pacman -Sy
pacman -S --noconfirm plasma-meta kde-system-meta dolphin-plugins kate konsole skanpage skanlite gwenview elisa okular ark
pacman -S --noconfirm ffmpegthumbs poppler-glib
# Установка GVFS для KDE Plasma (рекомендуется для полной совместимости)
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
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
pacman -Sy
pacman -S --noconfirm gnome
###  gnome-extra  ###
pacman -S --noconfirm dconf-editor
pacman -S --noconfirm file-roller
pacman -S --noconfirm gnome-tweaks
#
pacman -S --noconfirm gnome-themes-extra
pacman -S --noconfirm gnome-browser-connector
pacman -S --noconfirm gnome-shell-extensions
# GVFS и его адаптеры являются основой файловой системы в GNOME
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
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
pacman -Syy
pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm network-manager-applet blueman
pacman -S --noconfirm mugshot pavucontrol xdg-user-dirs xdg-desktop-portal-gtk ristretto thunar-archive-plugin ffmpegthumbnailer
# Установка GVFS и адаптеров для полной функциональности XFCE4
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Syy
pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm network-manager-applet blueman
# Установка GVFS и адаптеров для полной функциональности MATE
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Syy
pacman -S --noconfirm cinnamon cinnamon-translations blueman lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings gnome-terminal evince
# Установка GVFS и адаптеров для полной функциональности Cinnamon
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Syy
pacman -S --noconfirm lxqt sddm breeze breeze-icons blueman featherpad libstatgrab libsysstat
pacman -S --noconfirm network-manager-applet blueman
# Установка GVFS и адаптеров для расширенной совместимости и функциональности LXQt
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Syy
pacman -S --noconfirm lxde openbox mousepad lightdm lightdm-slick-greeter blueman thunar-archive-plugin ffmpegthumbnailer udiskie xfce4-notifyd dunst picom
pacman -S --noconfirm network-manager-applet blueman
# GVFS НЕ устанавливается для LXDE по умолчанию в соответствии с философией легковесности.
# Если необходимо, установите вручную: pacman -S gvfs gvfs-afc gvfs-smb gvfs-mtp ...
pacman -S --noconfirm ffmpegthumbnailer poppler-glib gnome-themes-extra
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
pacman -Syy
pacman -S --noconfirm budgie-desktop budgie-screensaver budgie-control-center dconf-editor budgie-desktop-view budgie-backgrounds
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm materia-gtk-theme papirus-icon-theme
pacman -S --noconfirm gnome-terminal nautilus vlc eog evince gedit
pacman -S --noconfirm network-manager-applet blueman
# Установка GVFS и адаптеров для полной функциональности Budgie
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -S --noconfirm ffmpegthumbnailer poppler-glib
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
yay -S --noconfirm snapper-support snapper-tools btrfs-assistant

# 3. Установка btrfsmaintenance:
sudo pacman -S --noconfirm btrfsmaintenance
clear

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
