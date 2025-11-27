##############################################################
### РУКОВОДСТВО ПО УСТАНОВКЕ ГРАФИЧЕСКИХ ДРАЙВЕРОВ В CHROOT
### (Для Arch Linux, с акцентом на Wayland, гибридную графику и гибернацию - 2025)
##############################################################

# ВАЖНО:
# 1. Эта инструкция выполняется ВНУТРИ CHROOT на этапе установки Arch Linux.
# 2. Она устанавливает драйверы и делает минимальные настройки, совместимые с гибернацией.
# 3. После перезагрузки в новой системе выполните проверки и настройки при необходимости.
# 4. Всегда используйте ТОЛЬКО ОДИН из вариантов (Intel, AMD, NVIDIA)!

# Определите тип своей видеокарты (сделайте это на хост-системе или в chroot с монтированными /dev, /proc, /sys):
# lspci | grep -e VGA -e 3D

##############################################################
### ВАРИАНТ 1: Intel Integrated Graphics
##############################################################

# Установка базовых драйверов для Intel:
pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva-utils lib32-intel-media-driver

# Объяснение:
# - `mesa`: Основной драйвер Mesa (включает OpenGL, DRI, и базовый VA-API i965).
# - `lib32-mesa`: 32-битная версия Mesa (для игр через Proton/Wine).
# - `vulkan-intel`: Vulkan драйвер для Intel GPU.
# - `lib32-vulkan-intel`: 32-битная версия Vulkan драйвера.
# - `intel-media-driver`: Драйвер для аппаратного кодирования/декодирования видео (VA-API/VDPAU) для Gen8+.
# - `lib32-intel-media-driver`: 32-битная версия.
# - `libva-utils`: Утилиты для проверки VA-API (vainfo).

# Для старых GPU (до Gen8), может потребоваться также:
# pacman -S --noconfirm libva-intel-driver lib32-libva-intel-driver
# Обычно `intel-media-driver` покрывает большинство современных задач.

# Опционально (для новых GPU Gen12+/Xe и выше, если есть проблемы):
# echo "options i915 enable_guc=2" > /etc/modprobe.d/i915.conf
# echo "options i915 fastboot=1" >> /etc/modprobe.d/i915.conf

# VA-API (обычно определяется автоматически, но можно указать явно):
# Для новых GPU (Gen8+), добавьте в /etc/environment:
# echo "LIBVA_DRIVER_NAME=iHD" >> /etc/environment # Использует intel-media-driver
# Для старых GPU (до Gen8):
# echo "LIBVA_DRIVER_NAME=i965" >> /etc/environment # Использует mesa i965


##############################################################
### ВАРИАНТ 2: AMD Radeon Graphics
##############################################################

# Установка базовых драйверов для AMD:
pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-utils lib32-vulkan-mesa-layers

# Объяснение:
# - `mesa`, `lib32-mesa`: Основные драйверы Mesa (включают OpenGL, DRI, и VA-API radeon/radeonsi).
# - `vulkan-radeon`: Vulkan драйвер для AMD GPU.
# - `lib32-vulkan-radeon`: 32-битная версия Vulkan драйвера.
# - `lib32-vulkan-mesa-layers`: 32-битные слои Vulkan (например, MangoHud, OBS Vulkan Capture).
# - `libva-utils`: Утилиты для проверки VA-API (vainfo).

# Опционально (управление питанием, редко нужно):
# echo "options amdgpu dpm=1" > /etc/modprobe.d/amdgpu.conf
# echo "options amdgpu ppfeaturemask=0xffffffff" >> /etc/modprobe.d/amdgpu.conf


##############################################################
### ВАРИАНТ 3: NVIDIA Graphics (ПОЛНАЯ И БЕЗОПАСНАЯ НАСТРОЙКА)
##############################################################

# ВНИМАНИЕ: Избегаем параметров, конфликтующих с гибернацией!

# 1. ВЫБОР ДРАЙВЕРА (установите ТОЛЬКО ОДИН вариант)
# --------------------------------------------------
# Для стандартного ядра (рекомендуется для большинства пользователей):
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils

# Для LTS-ядра (если вы используете lts-ядро):
# pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings lib32-nvidia-utils

# Универсальный DKMS-драйвер (если стандартный не подходит или вы часто меняете ядро):
# pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils

# *Если у вас гибридная графика (Intel/AMD + NVIDIA), добавьте пакеты для переключения:*
# pacman -S --noconfirm nvidia-prime libva-nvidia-driver

# Объяснение:
# - `nvidia*`: Основные драйверы.
# - `nvidia-utils`: Утилиты для настройки и проверки.
# - `nvidia-settings`: Графический интерфейс для настройки (необязательно).
# - `lib32-*`: 32-битные версии для совместимости.
# - `nvidia-prime`: Инструмент для переключения GPU (`prime-run`).
# - `libva-nvidia-driver`: VA-API драйвер для NVIDIA GPU (полезно в Wayland для аппаратного декодирования).

# 2. НАСТРОЙКА ПАРАМЕТРОВ ЯДРА ДЛЯ ГИБРИДНОЙ ГРАФИКИ (Только если установили nvidia-prime)
# ----------------------------------------------------------------------------------------
# Эти переменные окружения помогают приложениям на Wayland/OpenGL/Vulkan понять, что нужно использовать NVIDIA GPU.
# Они не вредят, даже если nvidia-prime не установлен, но полезны для гибридных систем.
echo -e '__NV_PRIME_RENDER_OFFLOAD=1\n__GLX_VENDOR_LIBRARY_NAME=nvidia\n__VK_LAYER_NV_optimus=NVIDIA_only' >> /etc/environment

# Объяснение:
# - `__NV_PRIME_RENDER_OFFLOAD=1`: Включает offloading (перенаправление) на NVIDIA GPU.
# - `__GLX_VENDOR_LIBRARY_NAME=nvidia`: Указывает использовать OpenGL драйвер NVIDIA.
# - `__VK_LAYER_NV_optimus=NVIDIA_only`: Указывает использовать Vulkan драйвер NVIDIA.

# 3. НАСТРОЙКА ПАРАМЕТРОВ ЯДРА ДЛЯ РАБОТЫ С GRUB (Только для NVIDIA)
# -------------------------------------------------------------------
# ВАЖНО: Не добавляйте `nvidia.NVreg_PreserveVideoMemoryAllocations=1`! Это сломает гибернацию.
# Добавляем `nvidia-drm.modeset=1` в параметры ядра GRUB для включения режимсетинга.
# Найдите строку GRUB_CMDLINE_LINUX_DEFAULT в /etc/default/grub и добавьте nvidia-drm.modeset=1
# Пример (предполагая, что строка уже содержит другие параметры):
# sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia-drm.modeset=1/' /etc/default/grub

# 4. НАСТРОЙКА MKINITCPIO (Только для NVIDIA)
# -------------------------------------------
# Обычно mkinitcpio автоматически включает необходимые модули NVIDIA.
# Если возникают проблемы с загрузкой, можно вручную добавить модули в MODULES в /etc/mkinitcpio.conf:
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm) # Пример, используйте с осторожностью
# Убедитесь, что в HOOKS присутствует `kms` (после `modconf` или `block`). Порядок важен для гибернации:
# HOOKS=(base udev ... modconf kms ... resume ... filesystems fsck) # 'resume' перед 'filesystems fsck'

# 5. ФИНАЛЬНАЯ СБОРКА (Для всех вариантов, после установки драйверов)
# --------------------
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

##############################################################
### ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ ДЛЯ НОУТБУКОВ И НЕТБУКОВ
##############################################################

#### A. Управление питанием с помощью TLP (популярный и простой выбор) ####
# TLP автоматически применяет оптимальные настройки энергосбережения.
# 1. Установка:
#    pacman -S --noconfirm tlp tlp-rdw
#    # tlp-rdw отвечает за радиоустройства (Wi-Fi, Bluetooth).
# 2. Включение сервиса:
#    systemctl enable tlp.service
#    # Отключаем конфликты с systemd:
#    systemctl mask systemd-rfkill.service systemd-rfkill.socket
# 3. Настройка (опционально):
#    Редактируйте /etc/default/tlp для тонкой настройки под модель ноутбука.

#### B. Дополнительные оптимизации ####
# 1. Swappiness (настройка подкачки):
#    Для систем с достаточным RAM (16 ГБ+) уменьшите swappiness для экономии SSD.
#    echo 'vm.swappiness=10' | tee /etc/sysctl.d/99-swappiness.conf
#    # Применить сразу: sysctl -p /etc/sysctl.d/99-swappiness.conf

# 2. TRIM для SSD:
#    Включите автоматическую очистку SSD для поддержания производительности.
#    systemctl enable fstrim.timer

#### C. Особенности для NVIDIA (гибридная графика на ноутбуке) ####
# * Динамическое управление питанием:
#   Параметр NVreg_DynamicPowerManagement=0x02, добавленный в GRUB, может помочь с энергосбережением,
#   но иногда вызывает нестабильность. Если возникают проблемы, удалите его из /etc/default/grub
#   и пересоберите GRUB: grub-mkconfig -o /boot/grub/grub.cfg
# * TLP и NVIDIA:
#   TLP также может управлять питанием NVIDIA GPU. Проверьте /etc/default/tlp,
#   параметры NVIDIA_RUNTIME_PM (для runtime PM) и NVIDIA_OFFLOAD (для отключения GPU).


##############################################################
### ПРОВЕРКА ПОСЛЕ ПЕРЕЗАГРУЗКИ (В НОВОЙ СИСТЕМЕ)
##############################################################
# Выполните эти команды ТОЛЬКО ПОСЛЕ ПЕРЕЗАГРУЗКИ!

# Для NVIDIA:
echo "Проверка драйвера NVIDIA:"
nvidia-smi
echo "Проверка OpenGL:"
glxinfo | grep "OpenGL renderer string"
echo "Проверка Vulkan:"
vulkaninfo --summary 2>/dev/null || echo "Vulkan не установлен или недоступен"
echo "Проверка VA-API (для NVIDIA):"
vainfo -a 2>/dev/null || echo "VA-API не установлен или недоступен"

# Для гибридных систем:
# Запустите приложение через prime-run (например, glxgears):
# prime-run glxgears
# Вывод glxinfo внутри этого приложения должен показать NVIDIA GPU.

# Для Intel/AMD:
echo "Проверка Vulkan:"
vulkaninfo --summary 2>/dev/null || echo "Vulkan не установлен или недоступен"
echo "Проверка VA-API:"
vainfo -a 2>/dev/null || echo "VA-API не установлен или недоступен"
# Для Intel:
# vainfo # должен показать iHD или i965
# LIBVA_DRIVER_NAME=iHD vainfo # или i965 для старых GPU
# Для AMD:
# vainfo # должен показать radeonsi или r600



