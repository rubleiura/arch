#!/bin/bash

##############################################################
### ОБЩЕЕ РУКОВОДСТВО ПО УСТАНОВКЕ ГРАФИЧЕСКИХ ДРАЙВЕРОВ
##############################################################
# ВАЖНО: 
# 1. Если вы в CHROOT (устанавливаете систему) - выполните только установку драйверов
# 2. После перезагрузки в новой системе выполните проверки и настройки
# 3. Для NVIDIA обязательно выполните проверку после перезагрузки!

# 1. Определите тип видеокарты:
#    lspci | grep -e VGA -e 3D
# 2. Выберите ТОЛЬКО ОДИН вариант ниже
# 3. После установки драйверов В CHROOT:
#    - Установите графическую оболочку
#    - Выполните перезагрузку
#    - После загрузки в новой системе проверьте работу драйверов

##############################################################
### ВАРИАНТ 1: Intel Integrated Graphics
##############################################################
# БАЗОВАЯ УСТАНОВКА:
# pacman -S --noconfirm vulkan-intel intel-media-driver libva-utils
# pacman -S --noconfirm lib32-vulkan-intel lib32-mesa

# Для новых GPU (Gen12+/Alchemist/Xe):
# pacman -S --noconfirm onevpl-intel-gpu intel-compute-runtime

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ:
# ---------------------------------------------
# А. Для новейших GPU:
# echo "options i915 enable_guc=2" > /etc/modprobe.d/i915.conf
# echo "options i915 fastboot=1" >> /etc/modprobe.d/i915.conf

# Б. Настройка VA-API:
#   - Для новых GPU (Gen8+):
#     echo "LIBVA_DRIVER_NAME=iHD" >> /etc/environment
#   - Для старых GPU:
#     echo "LIBVA_DRIVER_NAME=i965" >> /etc/environment

##############################################################
### ВАРИАНТ 2: AMD Radeon Graphics
##############################################################
# БАЗОВАЯ УСТАНОВКА:
# pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver libva-utils
# pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ:
# ---------------------------------------------
# А. Настройки энергопотребления:
# echo "options amdgpu dpm=1" > /etc/modprobe.d/amdgpu.conf
# echo "options amdgpu ppfeaturemask=0xffffffff" >> /etc/modprobe.d/amdgpu.conf

##############################################################
### ВАРИАНТ 3: NVIDIA Graphics (ПОЛНАЯ НАСТРОЙКА)
##############################################################
# 1. ВЫБОР ДРАЙВЕРА (раскомментировать ОДИН вариант)
# Для стандартного ядра:
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# Для LTS-ядра:
# pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# Универсальный DKMS-драйвер:
# pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# 2. КОНФИГУРАЦИЯ СИСТЕМЫ
# А. Настройка модулей ядра:
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
echo "options nvidia NVreg_DynamicPowerManagement=0x02" >> /etc/modprobe.d/nvidia.conf  # Для ноутбуков
echo "nvidia-drm" > /etc/modules-load.d/nvidia-drm.conf

# Б. Конфиг для Wayland:
echo -e 'Section "OutputClass"\n    Identifier "nvidia"\n    MatchDriver "nvidia-drm"\n    Driver "nvidia"\n    Option "AllowExternalGpus" "true"\n    Option "PrimaryGPU" "yes"\nEndSection' > /etc/X11/xorg.conf.d/10-nvidia-wayland.conf

# В. Переменные среды для гибридной графики:
echo -e '__NV_PRIME_RENDER_OFFLOAD=1\n__VK_LAYER_NV_optimus=NVIDIA_only' >> /etc/environment

# 3. НАСТРОЙКА INITRAMFS
# А. Редактируем mkinitcpio.conf:
sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

# Б. Для старых карт (до Kepler) или при проблемах с загрузкой:
sed -i '/^HOOKS=/ s/\<kms\>//g' /etc/mkinitcpio.conf

# 4. НАСТРОЙКА ГИБЕРНАЦИИ
mkdir -p /tmp/nvidia
chmod 1777 /tmp/nvidia
sed -i '/^GRUB_CMDLINE_LINUX=/ s/"$/ nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia.NVreg_TemporaryFilePath=\/tmp\/nvidia"/' /etc/default/grub

# 5. ФИНАЛЬНАЯ СБОРКА
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

##############################################################
### ЧАСТЬ 4: ПРОВЕРКА ПОСЛЕ УСТАНОВКИ
##############################################################
# ДЛЯ NVIDIA:
echo "Проверка драйвера NVIDIA:"
nvidia-smi

# ДЛЯ ВСЕХ СИСТЕМ:
echo "Проверка Vulkan:"
vulkaninfo --summary 2>/dev/null || echo "Vulkan не настроен"

echo "Проверка VA-API:"
vainfo 2>/dev/null || echo "VA-API не настроен"

##############################################################
### ЧАСТЬ 5: ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ ДЛЯ НОУТБУКОВ
##############################################################
# А. Управление питанием:
# pacman -S --noconfirm tlp tlp-rdw
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Б. Оптимизация энергопотребления:
# echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
# systemctl enable fstrim.timer

##############################################################
### ЧАСТЬ 6: ФИНАЛЬНЫЕ ШАГИ
##############################################################
echo "УСТАНОВКА ЗАВЕРШЕНА! СИСТЕМА БУДЕТ ПЕРЕЗАГРУЖЕНА ЧЕРЕЗ 10 СЕКУНД"
sleep 10
reboot
