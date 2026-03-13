# ##########################################################################
# 📘           ПОСТУСТАНОВОЧНАЯ НАСТРОЙКА Arch Linux
# ##########################################################################
# ################################################################
# 🔍 ЧАСТЬ 1: ПРЕДВАРИТЕЛЬНЫЕ ПРОВЕРКИ И ИНФОРМАЦИЯ
# ################################################################

# 1.1 Информация о дисках и разделах
# 💾 Полезно перед настройкой файловых систем (например, Btrfs) и Snapper.
#    Показывает путь к устройству, тип таблицы разделов, тип файловой системы и т.д.

lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,SIZE,MOUNTPOINTS

# 1.2 Список явно установленных пакетов (без зависимостей)
# 📦 Показывает пакеты, которые вы установили вручную (не как зависимости).

pacman -Qqet

# 1.3 (Опционально) Проверка "висячих" зависимостей
# 🧹 Найдите пакеты, которые больше не требуются.

pacman -Qtd






# ################################################################
# 🔊 ЧАСТЬ 2: НАСТРОЙКА АУДИО/ВИДЕО ПОДСИСТЕМЫ (PipeWire)
# ################################################################

# 2.1 Включение и запуск сервисов PipeWire
# 🎵 PipeWire — современная аудио/видео подсистема.

systemctl --user enable --now pipewire pipewire-pulse wireplumber

# 2.2 Проверка установки
# 🔁 После выполнения команды выше, выйдите из сеанса и войдите снова.
#    Затем проверьте, что PipeWire используется как сервер:

pactl info | grep "Server Name" # вывод должен содержать "PipeWire"






# ################################################################
# 📦 ЧАСТЬ 3: УСТАНОВКА ПРИЛОЖЕНИЙ
# ################################################################




clear
sudo pacman -Syy
sudo pacman -S --noconfirm \
doublecmd-qt6 vlc vlc-plugins-all \
fastfetch hyfetch inxi \
htop cpu-x gparted qbittorrent \
libreoffice-still-ru \
hardinfo2
sudo systemctl enable --now hardinfo2.service
sudo modprobe -a at24 ee1004 spd5118
sudo usermod -aG hardinfo2 $USER
yay -S --noconfirm \
octopi ventoy-bin grub-customizer \
grub2-theme-arch-leap update-grub stacer-bin
clear
# ###




# ################################################################
# 🐚 ЧАСТЬ 4: НАСТРОЙКА Zsh И Oh My Zsh
# ################################################################




clear
sudo pacman -Sy
sudo pacman -S --noconfirm zsh
export CHSH=no
export RUNZSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/^plugins=(.*)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' >> ~/.zshrc
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' >> ~/.zshrc
source ~/.zshrc
chsh -s $(which zsh)
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc
clear





# ##############################################
# ## 🖋️  ЧАСТЬ 5: НАСТРОЙКА NANO
# ##############################################
#
# Зачем: Глубокая настройка редактора nano.
# Включает: Цвета, подсветку, автоотступы, табы, softwrap, поддержку мыши.

clear

# Объединяем все изменения sed в одну команду для эффективности
sudo sed -i '
s/# set autoindent/set autoindent/g;
s/# set constantshow/set constantshow/g;
s/# set indicator/set indicator/g;
s/# set linenumbers/set linenumbers/g;
s/# set multibuffer/set multibuffer/g;
s/# set quickblank/set quickblank/g;
s/# set smarthome/set smarthome/g;
s/# set softwrap/set softwrap/g;
s/# set tabsize 8/set tabsize 4/g;
s/# set tabstospaces/set tabstospaces/g;
s/# set trimblanks/set trimblanks/g;
s/# set unix/set unix/g;
s/# set wordbounds/set wordbounds/g;
s/# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/g;
s/# set promptcolor black,yellow/set promptcolor black,yellow/g;
s/# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/g;
s/# set errorcolor bold,white,red/set errorcolor bold,white,red/g;
s/# set spotlightcolor black,orange/set spotlightcolor black,orange/g;
s/# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/g;
s/# set stripecolor ,yellow/set stripecolor ,yellow/g;
s/# set scrollercolor magenta/set scrollercolor magenta/g;
s/# set numbercolor magenta/set numbercolor magenta/g;
s/# set keycolor lightmagenta/set keycolor lightmagenta/g;
s/# set functioncolor magenta/set functioncolor magenta/g;
s/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g;
#s/# set mouse/set mouse/g; # Включаем поддержку мыши
# Добавим строку для отключения строки справки, если это нужно пользователю
# s/# set nohelp/set nohelp/g;
' /etc/nanorc





# ################################################################
# 🖼️ ЧАСТЬ 6: СОЗДАНИЕ ISO ОБРАЗА С Archiso
# ################################################################

# 6.1 Установка archiso
clear
# 📦 Устанавливаем утилиту для создания ISO-образов.
sudo pacman -S archiso
clear


# 6.2 Создание образа
# 📁 Создаем рабочую директорию.
mkdir -p ~/ArchIso/ && cd ~/ArchIso/
# 🏗️ Запускаем mkarchiso с официальным профилем releng.
sudo mkarchiso -v /usr/share/archiso/configs/releng/
# 📁 Результат появится в ~/out/ (по умолчанию).
# 🧹 Удаляем временную директорию.
sudo rm -r ~/ArchIso/





clear
# ################################################################
# 🖥️ ЧАСТЬ 7: УСТАНОВКА VirtualBox
# ################################################################

# 7.1 Установка основного пакета
# 📦 Устанавливаем VirtualBox.
sudo pacman -S virtualbox

# 💡 Во время установки вам будет предложено выбрать версию драйвера ядра
#    (например, `virtualbox-host-modules-arch`, `virtualbox-host-modules-lts` или `virtualbox-host-dkms`).
#    Выберите подходящую версию для вашего ядра (например, `virtualbox-host-modules-lts` для linux-lts).

# 7.2 Установка дополнительных пакетов
# 💾 Устанавливаем образ гостевых дополнений.
sudo pacman -S virtualbox-guest-iso

# 7.3 Добавление пользователя в группу
# 🔐 Добавляем пользователя в группу vboxusers для доступа к VirtualBox.
sudo gpasswd -a $USER vboxusers
clear
# 🔁 Выйдите из системы и снова войдите, чтобы изменения вступили в силу.
# reboot # Раскомментируйте, если хотите перезагрузить сразу.

# ⚠️ ВАЖНО: Если вы используете Wayland (например, KDE Plasma под Wayland),
# уведомления VirtualBox могут быть неинтерактивны (нельзя закрыть кликом).
# Чтобы отключить эти уведомления, выполните следующие команды после установки
# и перезапустите VirtualBox:

# VBoxManage setextradata global GUI/ShowMiniToolBar 0
# VBoxManage setextradata global GUI/NotifyAboutUserInput 0
# VBoxManage setextradata global GUI/NotifyAbout3DUserInput 0
# VBoxManage setextradata global GUI/ShowNotificationIcons 0
# VBoxManage setextradata global GUI/ShowNotifications 0

# ################################################################
# 📌 ЧАСТЬ 8: ПОЛЕЗНЫЕ КОМАНДЫ И НАСТРОЙКИ
# ################################################################

# 8.1 Установка темы KDE Plasma
# 🎨 Установка темы оформления из архива.
# kpackagetool6 --type Plasma/LookAndFeel --install архив_с_темой.tar.xz

# 8.2 Обновление системы
# 🔄 Обновление всех пакетов и очистка кэша.
# yay -Syu
# yay -Sc






# ################################################################
# ✅ ЗАКЛЮЧЕНИЕ
# ################################################################
# ✅ <<< ПОСТУСТАНОВОЧНАЯ НАСТРОЙКА Arch Linux ЗАВЕРШЕНА >>> ✅
# 💡 Теперь ваша система готова к использованию.
#    Не забывайте регулярно обновлять пакеты и следить за безопасностью.
