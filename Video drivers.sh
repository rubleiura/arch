#############################################
### ВАРИАНТ 1: Intel Integrated Graphics ###
#############################################
# Установите пакеты для Intel:
pacman -S --noconfirm vulkan-intel intel-media-driver libva-utils
pacman -S --noconfirm lib32-vulkan-intel lib32-mesa

# Для Gen12+ (Alchemist/Xe):
# pacman -S --noconfirm onevpl-intel-gpu intel-compute-runtime

#############################################
### ВАРИАНТ 2: AMD Radeon Graphics ###
#############################################
# Установите пакеты для AMD:
pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver libva-utils
pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon

#############################################
### ВАРИАНТ 3: NVIDIA Graphics ###
#############################################
# 1. Выберите драйвер по вашему ядру:
# Для стандартного ядра (linux):
pacman -S --noconfirm nvidia nvidia-utils nvidia-settings nvidia-prime
pacman -S --noconfirm lib32-nvidia-utils

# Для LTS-ядра (linux-lts):
# pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# Универсальный DKMS-драйвер:
# pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime
# pacman -S --noconfirm lib32-nvidia-utils

# 2. Настройки для Wayland
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
echo "options nvidia NVreg_DynamicPowerManagement=0x02" >> /etc/modprobe.d/nvidia.conf  # Для ноутбуков
echo "nvidia-drm.modeset=1" > /etc/modules-load.d/nvidia-drm.conf
echo -e "Section \"OutputClass\"\n    Identifier \"nvidia\"\n    MatchDriver \"nvidia-drm\"\n    Driver \"nvidia\"\n    Option \"AllowExternalGpus\" \"true\"\n    Option \"PrimaryGPU\" \"yes\"\nEndSection" > /etc/X11/xorg.conf.d/10-nvidia-wayland.conf

# Для гибридных систем (Intel/AMD + NVIDIA):
echo -e "__NV_PRIME_RENDER_OFFLOAD=1\n__VK_LAYER_NV_optimus=NVIDIA_only" >> /etc/environment

# 3. Добавление модулей в initramfs
nano /etc/mkinitcpio.conf  # Отредактируйте вручную!
# Добавьте: MODULES=(... nvidia nvidia_modeset nvidia_uvm nvidia_drm)

# 4. Настройка гибернации для NVIDIA
mkdir -p /tmp/nvidia
chmod 1777 /tmp/nvidia

nano /etc/default/grub  # Отредактируйте вручную!
# Добавьте параметры в конец: nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia.NVreg_TemporaryFilePath=/tmp/nvidia

# 5. Проверьте хук resume в mkinitcpio
nano /etc/mkinitcpio.conf  # Убедитесь, что есть хук 'resume'

# 6. Пересоберите конфигурации
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

# После перезагрузки проверьте:
# nvidia-smi
# glxinfo | grep "OpenGL renderer"
# prime-run glxgears

Часть 4: Проверка размера swap после установки NVIDIA

# Выполняется ПОСЛЕ перезагрузки!
RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}')
VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{sum += $1} END {print sum}')
MIN_SWAP=$((RAM_MB + VRAM_MB + 512))
CURRENT_SWAP=$(free -m | awk '/Swap:/ {print $2}')

echo "Текущий swap: ${CURRENT_SWAP}MB"
echo "Рекомендуемый минимум: ${MIN_SWAP}MB"

[ $CURRENT_SWAP -lt $MIN_SWAP ] && echo "ВНИМАНИЕ! Увеличьте swap до ${MIN_SWAP}MB"

Часть 5: Настройки для ноутбуков

# Управление питанием (универсальное)
pacman -S --noconfirm tlp tlp-rdw
systemctl enable tlp.service
systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Специальные функции (универсальное)
pacman -S --noconfirm libinput-gestures iio-sensor-proxy acpid lm_sensors power-profiles-daemon
gpasswd -a $USER input  # Замените $USER на имя пользователя
systemctl enable acpid.service iio-sensor-proxy.service
sensors-detect --auto

# Защита SSD и оптимизация
systemctl enable fstrim.timer  # Универсально для SSD
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf  # Универсально

# Настройка энергосбережения аудио (специфично для производителя)
# Для Intel HDA:
echo 'options snd_hda_intel power_save=1' > /etc/modprobe.d/audio_powersave.conf

# Для AMD (если используется snd_hda_codec):
# echo 'options snd_hda_codec power_save=1' > /etc/modprobe.d/audio_powersave.conf

# Для других аудиоконтроллеров уточните модуль:
# lsmod | grep snd

Часть 6: Финальные шаги

# Настройка сети
nmtui

# Перезагрузка системы
reboot