## Btrfs Assistant
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo systemctl enable --now snapper-cleanup.timer
sudo btrfs balance start -dusage=50 /

## HardInfo
sudo systemctl enable --now hardinfo2.service
sudo usermod -a -G hardinfo2 $USER
sudo modprobe at24
sudo modprobe ee1004
sudo modprobe spd5118
echo -e "at24\nee1004\nspd5118" | sudo tee /etc/modules-load.d/hardinfo.conf > /dev/null

## XFCE4
## Beautiful flags of countries
# mkdir -p ~/.local/share/xfce4/xkb/flags/
# cd ~/.local/share/xfce4/xkb/flags/
# wget https://upload.wikimedia.org/wikipedia/commons/5/53/Nuvola_USA_flag.svg
# wget https://upload.wikimedia.org/wikipedia/commons/a/ac/Nuvola_Russian_flag.svg
# mv -i Nuvola_USA_flag.svg us.svg
# mv -i Nuvola_Russian_flag.svg ru.svg
# cd


## Mate
## Включить мозаику окон
# gsettings set org.mate.Marco.general allow-tiling false
## Скрыть все значки на рабочем столе
# gsettings set org.mate.background show-desktop-icons false
## Скрыть значок компьютера
# gsettings set org.mate.caja.desktop computer-icon-visible false
## Скрыть значок каталога пользователя
# gsettings set org.mate.caja.desktop home-icon-visible false
## Скрыть значок сети
# gsettings set org.mate.caja.desktop network-icon-visible false
## Скрыть значок корзины
# gsettings set org.mate.caja.desktop trash-icon-visible false
## Скрыть смонтированные тома
# gsettings set org.mate.caja.desktop volumes-visible false
## Отключение автоматического открытия файлового менеджера
# gsettings set org.mate.media-handling automount-open false
## Отключение автомонтирования
# gsettings set org.mate.media-handling automount false
