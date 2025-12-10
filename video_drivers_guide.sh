# ##############################################################
# ### ОБНОВЛЕННОЕ РУКОВОДСТВО ПО УСТАНОВКЕ ГРАФИЧЕСКИХ ДРАЙВЕРОВ
# ### (С акцентом на гибернацию и современные практики - 2025)
# ### + Визуальные тесты (включая glmark2)
# ### + Настройки для ноутбуков
# ##############################################################
# ВАЖНО:
# 1. Это РУКОВОДСТВО используется ВМЕСТО БЛОКА 12 из основного макета.
# 2. Выполняйте команды ИЗ ЭТОГО ФАЙЛА (в chroot или после) согласно вашей видеокарте.
# 3. КОПИРУЙТЕ и ВСТАВЛЯЙТЕ команды вручную в сессию chroot.
# 4. После перезагрузки в новой системе выполните проверки.
# 5. Для NVIDIA обязательно выполните проверку после перезагрузки!
# 6. Эта инструкция избегает настроек, ломающих гибернацию (например, PreserveVideoMemoryAllocations=1)
# 7. Инструкция учитывает использование Wayland и Prime Offloading.
# 8. ПРОЧИТАЙТЕ ВЕСЬ ФАЙЛ ПЕРЕД НАЧАЛОМ!
# 9. Разделы с визуальными тестами и настройками для ноутбуков находятся В КОНЦЕ этого файла.
# ##############################################################

# 0. ПОДГОТОВКА И ОПРЕДЕЛЕНИЕ ВИДЕОКАРТЫ
# В Live-среде или в установленной системе выполните:
# lspci | grep -e VGA -e 3D -e Display
# или
# inxi -G
# Запишите производителя (Intel, AMD, NVIDIA) и модель.

# 1. ВЫБОР ВАРИАНТА УСТАНОВКИ
# Ниже приведены 3 варианта. Выберите ОДИН, соответствующий вашей карте.
# КОПИРУЙТЕ команды ИЗ нужного варианта и ВСТАВЬТЕ ИХ в chroot-сессию (после arch-chroot /mnt /bin/bash).
# НЕ ЗАПУСКАЙТЕ ЭТОТ ФАЙЛ КАК СКРИПТ.
# ПЕРЕД ВЫПОЛНЕНИЕМ УБЕДИТЕСЬ, ЧТО ВЫ ВНУТРИ CHROOT.

##############################################################
### ВАРИАНТ 1: Intel Integrated Graphics
##############################################################
# БАЗОВАЯ УСТАНОВКА:
# pacman -S --noconfirm vulkan-intel intel-media-driver libva-intel-driver
# pacman -S --noconfirm lib32-vulkan-intel lib32-mesa

# Опционально: Для новых GPU (Gen12+/Alchemist/Xe)
# pacman -S --noconfirm onevpl-intel-gpu intel-compute-runtime

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ (в chroot или после):
# А. Для новейших GPU (если есть проблемы со стабильностью):
# echo 'options i915 enable_guc=2' > /etc/modprobe.d/i915.conf
# echo 'options i915 fastboot=1' >> /etc/modprobe.d/i915.conf

# Б. Настройка VA-API (обычно определяется автоматически):
#   - Для новых GPU (Gen8+):
#     echo 'LIBVA_DRIVER_NAME=iHD' >> /etc/environment
#   - Для старых GPU:
#     echo 'LIBVA_DRIVER_NAME=i965' >> /etc/environment


##############################################################
### ВАРИАНТ 2: AMD Radeon Graphics
##############################################################
# БАЗОВАЯ УСТАНОВКА:
# pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver
# pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon

# ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ (в chroot или после):
# А. Настройки энергопотребления (обычно не требуются):
# echo 'options amdgpu dpm=1' > /etc/modprobe.d/amdgpu.conf
# echo 'options amdgpu ppfeaturemask=0xffffffff' >> /etc/modprobe.d/amdgpu.conf


##############################################################
### ВАРИАНТ 3: NVIDIA Graphics (ПОЛНАЯ И БЕЗОПАСНАЯ НАСТРОЙКА)
##############################################################
# ВНИМАНИЕ: Эта конфигурация избегает параметров, конфликтующих с гибернацией!
# ==============================================
# ШАГ 1: ВЫБЕРИТЕ ДРАЙВЕР (в chroot). Установите ТОЛЬКО ОДИН:
# A. Для стандартного ядра (linux):
#    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils
# B. Для LTS-ядра (linux-lts):
#    pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings lib32-nvidia-utils
# C. Универсальный DKMS-драйвер (если стандартный не подходит или кастомное ядро):
#    pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils
#    # Убедитесь, что установлены dkms и соответствующие linux-headers
#    # dkms install -m nvidia -v <версия_драйвера> # Если нужно вручную

# ШАГ 2: ДОПОЛНИТЕЛЬНО (только для гибридной графики Intel/AMD + NVIDIA в chroot):
# pacman -S --noconfirm nvidia-prime libva-nvidia-driver
# ==============================================

# ШАГ 3: КОНФИГУРАЦИЯ СИСТЕМЫ (в chroot):
# Создание файла настройки модуля:
# echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia.conf
# # echo 'options nvidia NVreg_PreserveVideoMemoryAllocations=1' >> /etc/modprobe.d/nvidia.conf # НЕ РЕКОМЕНДУЕТСЯ, ЛОМАЕТ ГИБЕРНАЦИЮ!
# # echo 'options nvidia NVreg_DynamicPowerManagement=0x02' >> /etc/modprobe.d/nvidia.conf # Для ноутбуков (опционально)
# echo 'nvidia-drm' > /etc/modules-load.d/nvidia-drm.conf

# Настройка переменных окружения для Prime Offloading в /etc/environment:
# echo -e '__NV_PRIME_RENDER_OFFLOAD=1\n__VK_LAYER_NV_optimus=NVIDIA_only' >> /etc/environment
# ==============================================

# ШАГ 4: НАСТРОЙКА INITRAMFS (mkinitcpio) (в chroot):
# Обычно не требуется вручную добавлять модули NVIDIA в MODULES=().
# mkinitcpio сам находит их, если установлены драйверы.
# Если возникают ошибки загрузки, можно вручно добавить:
# # sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
# Убедитесь, что в HOOKS присутствует 'kms'.
# Пример HOOKS (если использовали 'resume' для гибернации):
# HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap block resume btrfs filesystems fsck)
# ==============================================

# ШАГ 5: НАСТРОЙКА ГИБЕРНАЦИИ (в chroot):
# НЕ добавляйте nvidia.NVreg_PreserveVideoMemoryAllocations=1 в /etc/default/grub!
# Убедитесь, что в GRUB_CMDLINE_LINUX_DEFAULT есть 'resume=UUID=...' (см. fstab) (Только при установке в BIOS).
# Убедитесь, что 'resume' есть в HOOKS mkinitcpio.conf (Только при установке в BIOS).
# ==============================================

# ШАГ 6: ДОПОЛНИТЕЛЬНО ДЛЯ GNOME (в chroot, если ставите GNOME на гибридную графику):
# pacman -S --noconfirm switcheroo-control
# systemctl enable switcheroo-control.service
# ==============================================

# ШАГ 7: ФИНАЛЬНАЯ СБОРКА (в chroot):
# grub-mkconfig -o /boot/grub/grub.cfg
# mkinitcpio -P
# ==============================================


# 2. ВАЖНО: ВОЗВРАТ К ОСНОВНОМУ МАКЕТУ
# После выполнения команд выбранного варианта (в chroot), включая финальную сборку (grub-mkconfig, mkinitcpio):
# 1. Убедитесь, что все шаги из руководства выполнены *внутри chroot*.
# 2. НЕ ВЫХОДИТЕ из chroot.
# 3. ВЕРНИТЕСЬ к основному макету.
# 4. ПРОЧИТАЙТЕ РАЗДЕЛ "ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ ДЛЯ НОУТБУКОВ" (см. ниже) и выполните его *в chroot*.
# 5. Продолжайте выполнение основного макета: выберите и выполните команды для установки
#    нужной вам графической среды (DE/WM) - это БЛОКИ 14-... внутри *той же* chroot-сессии.
# 6. После завершения установки DE/WM *внутри chroot*, ВЕРНИТЕСЬ К ЭТОМУ РУКОВОДСТВУ.
# 7. ПРОЧИТАЙТЕ и ВЫПОЛНИТЕ РАЗДЕЛ "ВИЗУАЛЬНЫЕ ТЕСТЫ" (см. ниже).
# 8. Затем выполните команду 'exit' в chroot.
# 9. Теперь продолжайте основной макет: выполните размонтирование и выключение.
# 10. После перезагрузки вернитесь к ЭТОМУ файлу для проверок.


# 3. ПРОВЕРКА ПОСЛЕ ПЕРЕЗАГРУЗКИ
# ВЫПОЛНИТЕ ЭТИ КОМАНДЫ ТОЛЬКО ПОСЛЕ ПЕРЕЗАГРУЗКИ В НОВУЮ СИСТЕМУ И ВХОДА КАК ПОЛЬЗОВАТЕЛЬ!
# Убедитесь, что пакеты для проверки установлены (они входят в основной макет или должны быть установлены дополнительно).

# Проверка драйвера NVIDIA (только для NVIDIA):
# nvidia-smi

# Проверка Vulkan (для всех):
# vulkaninfo --summary

# Проверка VA-API (для всех):
# vainfo

# Проверка Prime Offloading (Wayland, для NVIDIA с гибридной графикой):
# DRI_PRIME=1 vkcube --c 1 # Запустит Vulkan-кубик на дискретной карте

# Проверка Prime Offloading (Xorg, для NVIDIA с гибридной графикой):
# __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep 'OpenGL renderer string'


# 4. ОПЦИОНАЛЬНЫЕ НАСТРОЙКИ ДЛЯ НОУТБУКОВ (в chroot - после установки драйверов, до DE/WM)
# ============================================================== 
# Выполните этот раздел *внутри chroot*, *после* установки драйверов и финальной сборки (grub-mkconfig, mkinitcpio),
# но *перед* установкой DE/WM.
# ==============================================================

# # А. Управление питанием (TLP - популярный выбор):
# pacman -S --noconfirm tlp tlp-rdw
# systemctl enable tlp.service
# systemctl mask systemd-rfkill.service systemd-rfkill.socket

# # Б. Оптимизация энергопотребления:
# echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
# systemctl enable fstrim.timer # Для SSD

# # Настройки завершены. Теперь вернитесь к основному макету и продолжайте установку DE/WM.


# 5. ВИЗУАЛЬНЫЕ ТЕСТЫ (в chroot - после установки DE/WM)
# ============================================================== 
# Выполните этот раздел *внутри chroot*, *после* установки DE/WM, но *перед* командой 'exit'.
# ВНИМАНИЕ: ФАКТИЧЕСКИЕ ВИЗУАЛЬНЫЕ ТЕСТЫ (glxgears, vkcube, glmark2) 
# НЕЛЬЗЯ запустить напрямую из chroot без активного сеанса отображения (X/Wayland).
# ==============================================================

# pacman -S --noconfirm mesa-utils vulkan-tools glmark2 mesa-demos
# # glmark2 - более сложный OpenGL бенчмарк

# # Установка завершена. Теперь вернитесь к основному макету и выполните 'exit' из chroot.
# # После перезагрузки и входа в систему:
# # 1. Откройте терминал в графической оболочке.
# # 2. Выполните команды для проверки:
# #    - glxgears (должны вращаться шестерёнки)
# #    - vkcube (должен вращаться 3D куб)
# #    - glmark2 (запустит бенчмарк OpenGL)
# #    - glxinfo | grep 'renderer string' (проверка драйвера)
# #    - Для NVIDIA с Prime: DRI_PRIME=1 vkcube или DRI_PRIME=1 glmark2
# # Если изображение появляется и анимируется, драйвер работает корректно!
