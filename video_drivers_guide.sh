##############################################################
### ОБНОВЛЕННОЕ РУКОВОДСТВО ПО УСТАНОВКЕ ГРАФИЧЕСКИХ ДРАЙВЕРОВ
### (С акцентом на гибернацию и современные практики - 2025)
##############################################################
# ВАЖНО:
# 1. Если вы в CHROOT (устанавливаете систему) - выполните только установку драйверов
# 2. После перезагрузки в новой системе выполните проверки и настройки
# 3. Для NVIDIA обязательно выполните проверку после перезагрузки!
# 4. Эта инструкция избегает настроек, ломающих гибернацию (например, PreserveVideoMemoryAllocations=1)
# 5. Инструкция учитывает использование Wayland и Prime Offloading

# 1. Определите тип видеокарты:
#    lspci | grep -e VGA -e 3D
# 2. Выберите ТОЛЬКО ОДИН подходящий вариант ниже
# 3. После установки драйверов В CHROOT:
#    - Выполните настройку (если применимо)
#    - Сгенерируйте GRUB и mkinitcpio
#    - Установите графическую оболочку
#    - Выполните перезагрузку
#    - После загрузки в новой системе проверьте работу драйверов

##############################################################
### ВАРИАНТ 1: Intel Integrated Graphics
##############################################################
# БАЗОВАЯ УСТАНОВКА:
# pacman -S --noconfirm vulkan-intel intel-media-driver libva-intel-driver
# pacman -S --noconfirm lib32-vulkan-intel lib32-mesa

# Для новых GPU (Gen12+/Alchemist/Xe):
# pacman -S --noconfirm onevpl-intel-gpu intel-compute-runtime

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ:
# ---------------------------------------------
# А. Для новейших GPU (если есть проблемы со стабильностью):
# echo "options i915 enable_guc=2" > /etc/modprobe.d/i915.conf
# echo "options i915 fastboot=1" >> /etc/modprobe.d/i915.conf

# Б. Настройка VA-API (обычно определяется автоматически):
#   - Для новых GPU (Gen8+):
#     echo "LIBVA_DRIVER_NAME=iHD" >> /etc/environment
#   - Для старых GPU:
#     echo "LIBVA_DRIVER_NAME=i965" >> /etc/environment

##############################################################
### ВАРИАНТ 2: AMD Radeon Graphics
##############################################################
# БАЗОВАЯ УСТАНОВКА:
# pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver
# pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ:
# ---------------------------------------------
# А. Настройки энергопотребления (обычно не требуются):
# echo "options amdgpu dpm=1" > /etc/modprobe.d/amdgpu.conf
# echo "options amdgpu ppfeaturemask=0xffffffff" >> /etc/modprobe.d/amdgpu.conf

##############################################################
### ВАРИАНТ 3: NVIDIA Graphics (ПОЛНАЯ И БЕЗОПАСНАЯ НАСТРОЙКА)
##############################################################
# ВНИМАНИЕ: Эта конфигурация избегает параметров, конфликтующих с гибернацией!
#           Учитывает использование Wayland и Prime Offloading.

# 1. ВЫБОР ДРАЙВЕРА (установите ТОЛЬКО ОДИН вариант)
# --------------------------------------------------
# Для стандартного ядра (рекомендуется для большинства):
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
# pacman -S --noconfirm lib32-nvidia-utils
# * Если у вас гибридная графика (Intel/AMD + NVIDIA): добавьте nvidia-prime и libva-nvidia-driver
#   pacman -S --noconfirm nvidia-prime libva-nvidia-driver

# Для LTS-ядра:
# pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings
# pacman -S --noconfirm lib32-nvidia-utils
# * Если у вас гибридная графика: добавьте nvidia-prime и libva-nvidia-driver
#   pacman -S --noconfirm nvidia-prime libva-nvidia-driver

# Универсальный DKMS-драйвер (если стандартный не подходит или вы используете кастомное ядро):
# pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings
# pacman -S --noconfirm lib32-nvidia-utils
# * Если у вас гибридная графика: добавьте nvidia-prime и libva-nvidia-driver
#   pacman -S --noconfirm nvidia-prime libva-nvidia-driver
# * Убедитесь, что установлен пакет 'dkms' и заголовки ядра.
# * После установки DKMS-пакета, драйвер должен быть скомпилирован под ваше ядро.
#   Это может произойти автоматически или потребовать ручного запуска:
#   sudo dkms install -m nvidia -v <версия_драйвера> (например, 550.90.07)
#   или перезагрузки для проверки.

# 2. КОНФИГУРАЦИЯ СИСТЕМЫ (в chroot или после)
# ------------------------
# А. Настройка модулей ядра в /etc/modprobe.d/nvidia.conf:
# ВАЖНО: Параметр NVreg_PreserveVideoMemoryAllocations=1 КОНФЛИКТУЕТ С ГИБЕРНАЦИЕЙ!
# Он закомментирован. Раскомментируйте ТОЛЬКО если вы точно знаете, зачем он нужен.
# echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
# echo "options nvidia NVreg_DynamicPowerManagement=0x02" >> /etc/modprobe.d/nvidia.conf  # Для ноутбуков, экономия энергии
echo "nvidia-drm" > /etc/modules-load.d/nvidia-drm.conf

# Б. Переменные среды для гибридной графики (Prime Offloading) и Wayland:
# Полезны ТОЛЬКО для гибридных систем. Не вредят, если установлен nvidia-prime.
# Эти переменные уже могут быть установлены в Блоке 11 основной инструкции.
echo -e '__NV_PRIME_RENDER_OFFLOAD=1\n__VK_LAYER_NV_optimus=NVIDIA_only' >> /etc/environment

# 3. НАСТРОЙКА INITRAMFS (mkinitcpio) (в chroot)
# -----------------------------------
# А. Модули: Обычно не требуется вручную добавлять модули NVIDIA в MODULES=().
# mkinitcpio сам находит их, если установлены драйверы и хуки настроены правильно.
# Добавляйте в MODULES= ТОЛЬКО если возникают специфические ошибки загрузки.
# Пример (использовать с осторожностью):
# sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

# Б. Хуки: Убедитесь, что в HOOKS присутствует kms (удаление вредно!).
# Для DKMS-драйверов может потребоваться специальный хук (обычно устанавливается с пакетом).
# Пример рекомендуемого порядка: HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap block btrfs filesystems fsck)
# Если вы использовали 'resume' для гибернации:
# HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap block resume btrfs filesystems fsck)

# 4. НАСТРОЙКА ГИБЕРНАЦИИ (ВАЖНО!)
# --------------------------------
# НЕ добавляйте nvidia.NVreg_PreserveVideoMemoryAllocations=1 в GRUB!
# Этот параметр ЛОМАЕТ стандартную гибернацию Linux.
# Если гибернация не нужна, игнорируйте этот раздел.

# Если вы хотите использовать гибернацию:
# A. Убедитесь, что в GRUB_CMDLINE_LINUX_DEFAULT есть 'resume=UUID=...' (см. основную инструкцию).
# B. Убедитесь, что 'resume' находится в HOOKS mkinitcpio.conf.
# C. Параметр NVreg_PreserveVideoMemoryAllocations=1 НЕ ДОЛЖЕН быть в /etc/default/grub или /etc/modprobe.d/nvidia.conf.
# D. Тестирование гибернации: systemctl hibernate (после перезагрузки и настройки DE).
#    Если гибернация не работает или система нестабильна, возможно, гибернация несовместима с вашей конфигурацией NVIDIA.

# 5. ДОПОЛНИТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ GNOME (ОПЦИОНАЛЬНО)
# * Если ставите Gnome на компьютер с гибридной графикой
# Вы можете запускать приложения с использованием дискретной видеокарты,
# щёлкнув правой кнопкой мыши по значку и выбрав
# пункт« Запустить с использованием дискретной видеокарты» .
# pacman -S --noconfirm switcheroo-control
# systemctl enable switcheroo-control.service

# 6. ФИНАЛЬНАЯ СБОРКА (в chroot)
# --------------------
# grub-mkconfig -o /boot/grub/grub.cfg
# mkinitcpio -P

##############################################################
### ЧАСТЬ 4: ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ ДЛЯ НОУТБУКОВ
##############################################################
# А. Управление питанием (TLP - популярный выбор):
# pacman -S --noconfirm tlp tlp-rdw
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Б. Оптимизация энергопотребления:
# echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
# systemctl enable fstrim.timer # Для SSD

##############################################################
### ЧАСТЬ 5: ПРОВЕРКА ПОСЛЕ УСТАНОВКИ И ПЕРЕЗАГРУЗКИ
##############################################################
# Выполните эти команды ТОЛЬКО ПОСЛЕ полной перезагрузки в новую систему!
# Убедитесь, что вы вошли в систему как обычный пользователь (не root).

# ДЛЯ NVIDIA:
echo "Проверка драйвера NVIDIA:"
nvidia-smi

# Проверка Vulkan:
vulkaninfo --summary 2>/dev/null || echo "Vulkan не настроен или недоступен"

# Проверка VA-API:
vainfo 2>/dev/null || echo "VA-API не настроен или недоступен"

# Проверка Prime Offloading (Wayland):
# glxinfo -c | grep "renderer string" # Может показать "NVIDIA" или "AMD"/"Intel" в зависимости от контекста
# Для принудительного запуска через NVIDIA: __NV_PRIME_RENDER_OFFLOAD=1 glxinfo -c | grep "renderer string"

# ДЛЯ Intel/AMD (проверка Vulkan и Mesa):
# vulkaninfo --summary
# vainfo

# Проверка VA-API через mpv (например):
# mpv --hwdec=auto --vo=gpu --gpu-api=vulkan <видеофайл> # Проверяет аппаратное декодирование