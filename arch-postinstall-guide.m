# 📘 ПОЛНАЯ ПОСТУСТАНОВОЧНАЯ НАСТРОЙКА Arch Linux  
(руководство для ручного выполнения)

# ⚠️ Важно:
# - Выполняйте команды **вручную**, по порядку.
# - Требуется: Arch Linux, интернет, sudo-доступ.

#############################################################

## 🔍 ПРЕДВАРИТЕЛЬНЫЕ ПРОВЕРКИ

# 1. Информация о дисках и разделах (полезно перед настройкой Btrfs/Snapper):
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,SIZE,MOUNTPOINTS

# 2. Список явно установленных пакетов (без зависимостей):
pacman -Qqet

# (Опционально) Проверка "висячих" зависимостей:
# pacman -Qtd

#############################################################

clear
## 🔊 1. PipeWire — современная аудио/видео подсистема
systemctl --user enable --now pipewire pipewire-pulse wireplumber


# Перезапустите сеанс (выйдите и зайдите заново), затем проверьте:
pactl info | grep "Server Name" # должно содержать "PipeWire"

#############################################################

## 📦 2. Установка AUR-помощника: yay


clear
sudo pacman -Sy --noconfirm
sudo pacman -S --needed --noconfirm git base-devel
git clone --depth=1 https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin
clear


# Проверка:
yay --version

#############################################################

## 🐚 3. Zsh + Oh My Zsh + плагины


clear
### 3.1 Установка zsh
sudo pacman -S --noconfirm zsh
### 3.2 Установка Oh My Zsh
export CHSH=no
export RUNZSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
### 3.3 Установка плагинов
# zsh-syntax-highlighting (требует zsh ≥ 4.3.11)
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
# zsh-autosuggestions (требует zsh ≥ 4.3.11)
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
# 💡 Примечание:
# — Подсветка работает сразу после ввода команды.
# — Автодополнение появляется серым цветом после курсора.
### 3.4 Резервное копирование
cp ~/.zshrc ~/.zshrc.bak
### 3.5 Настройка .zshrc
# Тема
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
# Плагины (в одну строку)
sed -i 's/^plugins=(.*)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
# Настройка цвета подсказок (цвет 8 = bright black; замените на fg=7, если не видно)
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' ## ~/.zshrc
# Отключение автодополнения для длинных команд (рекомендуется)
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' ## ~/.zshrc
### 3.6 Применение и смена оболочки
source ~/.zshrc
chsh -s $(which zsh)
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc
clear


# 🔁 Выйдите из системы и войдите заново, чтобы изменения вступили в силу.

#############################################################

## 🧩 4. Установка приложений



### 4.1 Из официальных репозиториев
clear
sudo pacman -S --noconfirm \
    chromium htop qbittorrent libreoffice-fresh-ru \
    doublecmd-qt6 smplayer

### 4.2 Из AUR
yay -S --noconfirm \
    octopi gparted ventoy-bin grub-customizer user-admin \
    grub2-theme-arch-leap update-grub stacer-bin ocs-url
clear


#############################################################

## 🗃️ 5. Btrfs + Snapper (системные снимки)



### 5.1 Установка
clear
yay -S --noconfirm \
    grub-btrfs snapper snap-pac snapper-support \
    snapper-tools btrfsmaintenance btrfs-assistant
### 5.2 Инициализация
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo systemctl enable --now snapper-cleanup.timer
### 5.3 Балансировка (при заполнении #80%)
sudo btrfs balance start -dusage=50 /
clear


### 5.3 Настройка лимитов (рекомендуется)
sudo nano /etc/snapper/configs/root
# Раскомментируйте/установите:
# NUMBER_LIMIT="10"
# NUMBER_LIMIT_IMPORTANT="5"
# TIMELINE_CREATE="yes"
# TIMELINE_LIMIT_HOURLY="5"
# TIMELINE_LIMIT_DAILY="7"

# Повторите для /etc/snapper/configs/home



#############################################################

## 🖥️ 6. HardInfo2 — диагностика оборудования


clear
yay -S --noconfirm hardinfo2
sudo usermod -aG hardinfo2 $USER
# Загрузка модулей SPD
echo -e "at24\nee1004\nspd5118" | sudo tee /etc/modules-load.d/hardinfo.conf
sudo modprobe -a at24 ee1004 spd5118
# Включение службы
sudo systemctl enable --now hardinfo2.service
clear



# 🔁 После добавления в группу `hardinfo2` — перезайдите в систему.
# Запустите: hardinfo2 # раздел «Memory» # вкладка «SPD»

#############################################################

## 🔁 7. Финальное обновление


sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo mkinitcpio -P
## 🔄 8. Перезагрузка
sudo reboot



#############################################################

## 📌 Полезные команды (сохраните)

# Снимки
sudo snapper -c root create -d "Обновление"
sudo snapper -c root list
sudo snapper -c home undochange 15..20 ~/document.txt

# Обновление
yay -Syu
yay -Sc

#############################################################

✅ Готово! Система полностью настроена.
