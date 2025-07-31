#!/bin/bash

##############################################################
### ОБЩЕЕ РУКОВОДСТВО ПО УСТАНОВКЕ ГРАФИЧЕСКИХ ДРАЙВЕРОВ
##############################################################
# 1. Определите тип видеокарты:
#    lspci | grep -e VGA -e 3D
# 2. Выберите ТОЛЬКО ОДИН вариант (Intel/AMD/NVIDIA)
# 3. Для гибридных систем (Intel/AMD + NVIDIA) используйте ВАРИАНТ 3
# 4. Инструкция разделена на:
#    - ОБЯЗАТЕЛЬНЫЕ шаги (базовая установка)
#    - ОПЦИОНАЛЬНЫЕ настройки (при проблемах)
#    - СПЕЦИФИЧНЫЕ для NVIDIA (критически важны)
#
# ВАЖНО:
# - Команды с 'nano' требуют ручного редактирования
# - После установки ОБЯЗАТЕЛЬНО перезагрузитесь
# - Для NVIDIA выполните проверку swap после перезагрузки

##############################################################
### ВАРИАНТ 1: Intel Integrated Graphics
### (ОБЯЗАТЕЛЬНАЯ УСТАНОВКА + ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ)
##############################################################
# БАЗОВАЯ УСТАНОВКА (раскомментировать):
# pacman -S --noconfirm vulkan-intel intel-media-driver libva-utils
# pacman -S --noconfirm lib32-vulkan-intel lib32-mesa

# Для новых GPU (Gen12+/Alchemist/Xe - Tiger Lake и новее):
# pacman -S --noconfirm onevpl-intel-gpu intel-compute-runtime

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ (только при проблемах):
# ---------------------------------------------
# А. Для новейших GPU (ускорение и аппаратное декодирование):
# echo "options i915 enable_guc=2" > /etc/modprobe.d/i915.conf
# echo "options i915 fastboot=1" >> /etc/modprobe.d/i915.conf

# Б. Если не работает аппаратное декодирование:
#   - Для новых GPU (Gen8+): 
#     echo "LIBVA_DRIVER_NAME=iHD" >> /etc/environment
#   - Для старых GPU (до Gen8):
#     echo "LIBVA_DRIVER_NAME=i965" >> /etc/environment

# В. Для гибридных систем (Intel + NVIDIA) - НЕ НАСТРАИВАЕМ INTEL!

##############################################################
### ВАРИАНТ 2: AMD Radeon Graphics
### (ОБЯЗАТЕЛЬНАЯ УСТАНОВКА + ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ)
##############################################################
# БАЗОВАЯ УСТАНОВКА (раскомментировать):
# pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver libva-utils
# pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ (только при проблемах):
# ---------------------------------------------
# А. Принудительное включение RADV (обычно не требуется):
# echo "AMD_VULKAN_ICD=RADV" >> /etc/environment

# Б. Управление энергопотреблением (для ноутбуков):
# echo "options amdgpu dpm=1" > /etc/modprobe.d/amdgpu.conf
# echo "options amdgpu ppfeaturemask=0xffffffff" >> /etc/modprobe.d/amdgpu.conf

# В. Для гибридных систем (AMD + NVIDIA) - НЕ НАСТРАИВАЕМ AMD!

##############################################################
### ВАРИАНТ 3: NVIDIA Graphics (ОБЯЗАТЕЛЬНАЯ ПОЛНАЯ НАСТРОЙКА)
##############################################################
# 1. ВЫБОР ДРАЙВЕРА (раскомментировать ОДИН вариант)
# Для стандартного ядра (linux):
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# Для LTS-ядра (linux-lts):
# pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# Универсальный DKMS-драйвер:
# pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# 2. КОНФИГУРАЦИЯ СИСТЕМЫ (обязательно!)
# А. Настройка модулей ядра:
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
echo "options nvidia NVreg_DynamicPowerManagement=0x02" >> /etc/modprobe.d/nvidia.conf  # Для ноутбуков!
echo "nvidia-drm.modeset=1" > /etc/modules-load.d/nvidia-drm.conf

# Б. Конфиг для Wayland:
echo -e "Section \"OutputClass\"\n    Identifier \"nvidia\"\n    MatchDriver \"nvidia-drm\"\n    Driver \"nvidia\"\n    Option \"AllowExternalGpus\" \"true\"\n    Option \"PrimaryGPU\" \"yes\"\nEndSection" > /etc/X11/xorg.conf.d/10-nvidia-wayland.conf

# В. Переменные среды для гибридной графики:
echo -e "__NV_PRIME_RENDER_OFFLOAD=1\n__VK_LAYER_NV_optimus=NVIDIA_only" >> /etc/environment

# 3. ИНИЦИАЛИЗАЦИЯ RAMDISK (КРИТИЧЕСКИ ВАЖНО!)
# nano /etc/mkinitcpio.conf
# ДОБАВЬТЕ в секцию MODULES:
#   nvidia nvidia_modeset nvidia_uvm nvidia_drm

# 4. НАСТРОЙКА ГИБЕРНАЦИИ
mkdir -p /tmp/nvidia
chmod 1777 /tmp/nvidia

# nano /etc/default/grub
# ДОБАВЬТЕ в GRUB_CMDLINE_LINUX:
#   nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia.NVreg_TemporaryFilePath=/tmp/nvidia

# 5. ПРОВЕРЬТЕ РЕЗЕРВИРОВАНИЕ ПАМЯТИ
# nano /etc/mkinitcpio.conf
# УБЕДИТЕСЬ что присутствует хук 'resume'

# 6. ФИНАЛЬНАЯ СБОРКА
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

##############################################################
### ЧАСТЬ 4: ПРОВЕРКА SWAP (ТОЛЬКО ДЛЯ NVIDIA ПОСЛЕ ПЕРЕЗАГРУЗКИ!)
##############################################################
# ВЫПОЛНИТЕ ПОСЛЕ ПЕРЕЗАГРУЗКИ!
# RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}')
# VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{sum += $1} END {print sum}')
# MIN_SWAP=$((RAM_MB + VRAM_MB + 512))
# CURRENT_SWAP=$(free -m | awk '/Swap:/ {print $2}')
# echo "Текущий swap: ${CURRENT_SWAP}MB"
# echo "Рекомендуемый минимум: ${MIN_SWAP}MB"
# [ $CURRENT_SWAP -lt $MIN_SWAP ] && echo "ВНИМАНИЕ! Увеличьте swap до ${MIN_SWAP}MB"

##############################################################
### ЧАСТЬ 5: УНИВЕРСАЛЬНЫЕ НАСТРОЙКИ ДЛЯ НОУТБУКОВ
### (рекомендуется для всех систем)
##############################################################
# А. Управление питанием:
# pacman -S --noconfirm tlp tlp-rdw
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Б. Жесты и датчики:
# pacman -S --noconfirm libinput-gestures iio-sensor-proxy acpid lm_sensors power-profiles-daemon
# gpasswd -a $USER input  # ЗАМЕНИТЕ $USER НА ВАШЕ ИМЯ!
# systemctl enable acpid.service iio-sensor-proxy.service
# sensors-detect --auto

# В. Оптимизация SSD:
# systemctl enable fstrim.timer
# echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf

# Г. Энергосбережение аудио:
#   - Для Intel: 
#     echo 'options snd_hda_intel power_save=1' > /etc/modprobe.d/audio_powersave.conf
#   - Для AMD: 
#     echo 'options snd_hda_codec power_save=1' > /etc/modprobe.d/audio_powersave.conf

##############################################################
### ЧАСТЬ 6: ФИНАЛЬНЫЕ ШАГИ ДЛЯ ВСЕХ СИСТЕМ
##############################################################
# 1. Настройка сети:
# nmtui

# 2. Проверка драйверов перед перезагрузкой:
#   - Intel:    vainfo
#   - AMD:      vulkaninfo --summary
#   - NVIDIA:   nvidia-smi

# 3. ОБЯЗАТЕЛЬНАЯ ПЕРЕЗАГРУЗКА:
echo "УСТАНОВКА ЗАВЕРШЕНА! СИСТЕМА БУДЕТ ПЕРЕЗАГРУЖЕНА ЧЕРЕЗ 10 СЕКУНД"
sleep 10
reboot