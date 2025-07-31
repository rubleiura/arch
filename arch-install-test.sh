################################################################
# #### Макет блочной установки Arch Linux (BTRFS + SNAPPER) ####
################################################################
#
# 🔹 Назначение: Быстрая, гибкая и понятная установка Arch Linux
# 🔹 Метод: Копируйте и вставляйте по одному блоку за раз
# 🔹 Важно: Не запускайте как скрипт! Выполняйте вручную.
#
# Структура:
#   1. Подготовка (SSH, Live-среда)
#   2. Диагностика и разметка диска
#   3. Монтирование и установка базовой системы
#   4. Конфигурация внутри chroot
#   5. Установка DE и пост-установочные действия
#
# Все комментарии — сверху. Команды — чистые, без справа.









################################################################
## 🔐 БЛОК 1: ОПТИМИЗАЦИЯ SSH (ТОЛЬКО ПРИ УСТАНОВКЕ ЧЕРЕЗ SSH) ##
################################################################
#
# Зачем: Ускорение и стабильность при удалённой установке.
# Важно: Только если вы подключены по SSH. Необязательно при локальной установке.
# Эффект: Уменьшение задержек, отключение DNS, ускорение сессии.






clear
# 1. Резервное копирование конфигурации
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
# 2. Настройка параметров производительности
# Включение сжатия данных - уменьшает объем передаваемых данных
sed -i 's/^#*Compression .*/Compression yes/' /etc/ssh/sshd_config
# Поддержание TCP-соединения - предотвращает разрыв неактивных соединений
sed -i 's/^#*TCPKeepAlive .*/TCPKeepAlive yes/' /etc/ssh/sshd_config
# Проверка активности клиента - отправляет запросы каждые 60 секунд
sed -i 's/^#*ClientAliveInterval .*/ClientAliveInterval 60/' /etc/ssh/sshd_config
# Макс. число проверок - разрывает соединение после 3 неудачных проверок
sed -i 's/^#*ClientAliveCountMax .*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
# Отключение DNS-проверок - ускоряет подключение
sed -i 's/^#*UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
# 3. Дополнительные улучшения для установки
# Увеличение лимита подключений - позволяет больше одновременных подключений
sed -i 's/^#*MaxStartups .*/MaxStartups 10:30:100/' /etc/ssh/sshd_config
# Быстрые шифры - использует наиболее производительные алгоритмы шифрования
sed -i 's/^#*Ciphers .*/Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com/' /etc/ssh/sshd_config
# 4. Применение изменений
systemctl restart sshd
#
clear
echo "#####################################"
echo "## <<< НАСТРОЙКА SSH ЗАВЕРШЕНА >>> ##"
echo "#####################################"
# 5. Проверка изменений
echo "Текущая конфигурация:"
grep -E 'Compression|TCPKeepAlive|ClientAlive|UseDNS|MaxStartups|Ciphers' /etc/ssh/sshd_config
echo ""






############################################################
## 🛠️ БЛОК 2: ПОДГОТОВКА К УСТАНОВКЕ (СИСТЕМНЫЕ НАСТРОЙКИ) ##
############################################################
#
# Зачем: Базовая настройка системы перед установкой.
# Важно: Выполняется в live-среде перед разметкой диска.
# Эффект: Корректное время, русская раскладка, оптимизированный pacman.
#





clear
# Синхронизация системных часов с NTP-серверами - критически важно для работы системы
timedatectl set-ntp true
# Установка русской раскладки клавиатуры - позволяет вводить русские символы во время установки
loadkeys ru
# Установка шрифта с поддержкой кириллицы - обеспечивает корректное отображение русских букв
setfont cyr-sun16
# Активация локалей (убираем комментарии в конфигурационном файле)
sed -i "s/#\(en_US\.UTF-8\)/\1/" /etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
# Генерация активированных локалей - создает файлы локалей на основе locale.gen
locale-gen
# Оптимизация pacman (параллельная загрузка пакетов) - ускоряет установку пакетов
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
# Включение цветного вывода pacman - делает вывод более информативным
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
# Добавление визуальных улучшений в pacman - анимация прогресс-бара
echo "[options]" >> /etc/pacman.conf
echo "ILoveCandy" >> /etc/pacman.conf
# Обновление списка пакетов
# Обновляем базу данных пакетов
pacman -Syy
# Настройка зеркал
# Установка необходимых зависимостей (pacman-contrib для rankmirrors и curl)
# pacman-contrib  - доп. утилиты
# curl - клиент url
sudo pacman -S --noconfirm pacman-contrib curl
# Автоматически определяем код страны по вашему IP
COUNTRY=$(curl -s https://ipapi.co/country_code)
# Скачиваем актуальный список зеркал для вашей страны
sudo curl -L "https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=https" -o /etc/pacman.d/mirrorlist.raw
# Раскомментируем все репозитории в списке
sudo sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.raw
# Ранжируем зеркала по скорости (топ-5) и сохраняем основной конфиг
sudo rankmirrors -n 5 /etc/pacman.d/mirrorlist.raw > /etc/pacman.d/mirrorlist
# Очищаем временные файлы
sudo rm /etc/pacman.d/mirrorlist.raw
# Обновляем базу данных пакетов
#pacman -Syy
#Установка необходимых компонентов:
# haveged - генератор энтропии для ускорения криптоопераций
# archlinux-keyring - актуальные ключи подписи пакетов
# inxi - система диагностики
# util-linux - дополнительные системные утилиты
# lshw - информация об аппаратном обеспечении
pacman -S --noconfirm  haveged archlinux-keyring inxi util-linux lshw
# Запуск haveged для генерации энтропии
systemctl enable haveged.service --now
#
clear
echo ""
echo "################################################"
echo "## <<< ПОДГОТОВКА К УСТАНОВКЕ ЗАВЕРШИЛАСЬ >>> ##"
echo "################################################"
echo ""






#########################################
##  НАСТРОЙКА ПЕРЕМЕННЫХ ДЛЯ УСТАНОВКИ ##
#########################################
#
# Зачем: Определение ключевых параметров установки.
# Важно: Обязательно для корректной установки, проверьте соответствие тестам.
# Эффект: Настройка дисков, пользователя, хостнейма, микрокода, ядра.


#########################################################################
## Этот пункт предназначен для изменения переменных.                   ##
## Он обязателен.Иначе установка системы  может пойти с ошибками.      ##
## Если параметры из раздела Тестирования не совпадают с параметрами   ##
## раздела Переменные, необходимо с помощью текстового редактора       ##
## провести групповое переименование переменных в таблице ниже,        ##
## чтобы они соответствовали результатам тестирования.                 ##
#########################################################################



###############################################
## 🧪 БЛОК 3: ТЕСТИРОВАНИЕ ДИСКОВ И РАЗМЕТКА ##
###############################################
#
# Зачем: Анализ дискового пространства.
# Важно: Помогает определить жесткий диск для разметки.
# Эффект: Информация о дисках.
#
#
# Протестируйте дисковоепространство.
№ Выберите свой жесткий диск или SSD.
# Выделите его, и замените переменную диска
# путём группового переименования






clear
echo ""
echo ""
# Просмотр информации о блочных устройствах с детализацией:
# PATH - путь к устройству
# PTTYPE - тип таблицы разделов
# PARTTYPE - тип раздела (GUID)
# FSTYPE - файловая система
# PARTTYPENAME - человеко-читаемое название типа раздела
clear
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME
echo ""
echo ""
echo "#################################################"
echo "## <<< ТЕСТИРОВАНИЕ КОМПЬЮТЕРА ЗАКОНЧИЛОСЬ >>> ##"
echo "#################################################"
echo ""





############################################
#  Объект           #   Переменная         #
############################################
#  Ваш диск         #   DISK               #
# К примеру sda     #                      #
############################################





############################################
## 🔪 БЛОК 4: РАЗМЕТКА ДИСКА (GPT + BTRFS) ##
############################################
#
# Зачем: Подготовка диска к установке системы.
# Важно: Удаляет все данные на диске, будьте осторожны!
# Эффект: Создает разделы для BIOS, системы и SWAP.






clear
# ===================================================
# 1. ПОЛНАЯ ОЧИСТКА ДИСКА ОТ ПРЕДЫДУЩИХ РАЗМЕТОК
# ===================================================
# Удаляем все файловые системы и сигнатуры разделов
wipefs --all --force /dev/DISK
# Стираем GPT/MBR структуры и создаем новую пустую таблицу
sgdisk -Z /dev/DISK
# ===================================================
# 2. СОЗДАНИЕ НОВОЙ GPT-ТАБЛИЦЫ С ВЫРАВНИВАНИЕМ
# ===================================================
# -a 2048: выравнивание по 2048 секторам (1M) для SSD
# -o: создаем новую пустую GPT-таблицу
sgdisk -a 2048 -o /dev/DISK
# ===================================================
# 3. СОЗДАНИЕ РАЗДЕЛА ДЛЯ ЗАГРУЗЧИКА BIOS (GRUB)
# ===================================================
# -n 1:0:+1M: раздел 1, начало автоматически, размер 1M
# -t 1:ef02: тип EF02 (BIOS Boot Partition)
# -c 1:"BIOS Boot Arch": имя раздела (метка)
sgdisk -n 1:0:+1M -t 1:ef02 -c 1:'BIOS Boot Arch' /dev/DISK
# ===================================================
# 4. СОЗДАНИЕ КОРНЕВОГО РАЗДЕЛА (/)
# ===================================================
# -n 2:0:-4G: раздел 2, начало после предыдущего, размер до последних 4ГБ
# -t 2:8300: тип 8300 (Linux Filesystem)
# -c 2:"System Arch Linux": имя раздела (метка)
sgdisk -n 2:0:-4G -t 2:8300 -c 2:'System Arch Linux' /dev/DISK
# ===================================================
# 5. СОЗДАНИЕ SWAP-РАЗДЕЛА
# ===================================================
# -n 3:0:0: раздел 3, начало после предыдущего, размер весь остаток
# -t 3:8200: тип 8200 (Linux Swap)
# -c 3:"Swap Arch Linux": имя раздела (метка)
sgdisk -n 3:0:0 -t 3:8200 -c 3:'Swap Arch Linux' /dev/DISK
echo ""
echo ""
# ===================================================
# 6. ПРОВЕРКА СОЗДАННОЙ РАЗМЕТКИ
# ===================================================
# Просмотр GPT-таблицы в gdisk
gdisk -l /dev/DISK
echo ""
echo ""
# Альтернативный просмотр в fdisk
fdisk -l /dev/DISK
echo ""
echo ""
echo "######################################"
echo "## <<< РАЗМЕТКА ДИСКА ЗАВЕРШЕНА >>> ##"
echo "######################################"






#######################################################
## 🧪 БЛОК 5: ТЕСТИРОВАНИЕ ОБОРУДОВАНИЯ И ДИАГНОСТИКА ##
#######################################################
#
# Зачем: Анализ оборудования перед установкой.
# Важно: Помогает определить правильные параметры для установки.
# Эффект: Информация о процессоре, материнской плате, дисках.






clear
echo ""
# Определение типа диска (SSD или HDD)
if lsblk -d -o rota /dev/DISK | grep -q 1; then
    clear
    DISK_TYPE="HDD"
    MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:2,autodefrag"
else
    DISK_TYPE="SSD"
    MOUNT_OPTIONS="ssd,noatime,space_cache=v2,compress=zstd:2,discard=async"
fi
# Отображение информации о типе диска
echo "Обнаружен DISK_TYPE. Используются параметры монтирования: MOUNT_OPTIONS"

if [ "DISK_TYPE" = "HDD" ]; then
    echo "Если система ставится на HDD, необходимо изменить переменную btrfs на:"
    echo "noatime,space_cache=v2,compress=zstd:2,autodefrag"
else
    echo "Если система ставится на SSD, необходимо изменить переменную btrfs на:"
    echo "ssd,noatime,space_cache=v2,compress=zstd:2,discard=async"
fi
echo ""
# Определение производителя процессора
sudo lshw -C cpu 2>/dev/null | grep 'vendor:' | uniq
echo ""
echo ""
# Получение информации о материнской плате
sudo inxi -M
echo ""
echo ""
# Получение информации о системе
sudo inxi -I
echo ""
echo ""
# Просмотр информации о блочных устройствах с детализацией:
# PATH - путь к устройству
# PTTYPE - тип таблицы разделов
# PARTTYPE - тип раздела (GUID)
# FSTYPE - файловая система
# PARTTYPENAME - человеко-читаемое название типа раздела
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME
echo ""
echo ""
echo "#################################################"
echo "## <<< ТЕСТИРОВАНИЕ КОМПЬЮТЕРА ЗАКОНЧИЛОСЬ >>> ##"
echo "#################################################"
echo ""





############################################
#  Объект           #   Переменная         #
############################################
#  Разд. и диск     #   sdx1 sdx2 sdx3 sdx #
############################################
#  Имя пользователя #   login	           #
############################################
#  Имя менедж.входа #  	User Name          #
############################################
#   Hostname 	    #   Sony               #
############################################
#   Microcode	    #   amd-ucode          #
############################################
#   Ядро	        #   linux-lts          #
############################################
#   размер SWAP	    #	sgdisk -n 2::-4G   #
#############################################
#   btrfs   	    #	MOUNT_OPTIONS      #
############################################





##############################################################
## 📦 БЛОК 6: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ РАЗДЕЛОВ (BTRFS) ##
##############################################################
#
# Зачем: Подготовка файловых систем и структуры каталогов.
# Важно: Создает подтома Btrfs для гибкости и снапшотов.
# Эффект: Готовая структура для установки системы.






clear
# Создание swap-раздела
mkswap /dev/sdx3
# Активация swap-раздела
swapon /dev/sdx3
# Форматирование раздела в Btrfs с принудительным пересозданием (-f)
mkfs.btrfs -f /dev/sdx2
# Монтирование корневого раздела
mount /dev/sdx2 /mnt
# Создание подтомов Btrfs:
# @ - корневая система
btrfs su cr /mnt/@
# @home - домашние каталоги
btrfs su cr /mnt/@home
# @log - системные логи
btrfs su cr /mnt/@log
# @pkg - кэш пакетов pacman
btrfs su cr /mnt/@pkg
# Размонтирование корневого раздела
umount /mnt
# Монтирование корневого подтома с оптимизациями для соответствующего типа диска
mount -o MOUNT_OPTIONS,subvol=@ /dev/sdx2 /mnt
# Создание структуры каталогов для монтирования
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
# Монтирование подтома домашних каталогов
mount -o MOUNT_OPTIONS,subvol=@home /dev/sdx2 /mnt/home
# Монтирование подтома системных логов
mount -o MOUNT_OPTIONS,subvol=@log /dev/sdx2 /mnt/var/log
# Монтирование подтома кэша пакетов
mount -o MOUNT_OPTIONS,subvol=@pkg /dev/sdx2 /mnt/var/cache/pacman/pkg
#
clear
echo ""
echo ""
# Просмотр информации о разделах (проверка)
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/DISK
echo ""
echo ""
# Просмотр созданных подтомов (после монтирования)
lsblk /dev/DISK
echo ""
echo ""
# Просмотр созданных подтомов (после монтирования)
btrfs subvolume list /mnt
echo ""
echo ""
echo "##############################################################"
echo "## <<< ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ РАЗДЕЛОВ ЗАВЕРШЕНО >>> ##"
echo "##############################################################"





#########################################################
## 📥 БЛОК 7: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ И ВХОД В CHROOT ##
#########################################################
#
# Зачем: Установка минимальной системы и переход в нее.
# Важно: База для дальнейшей настройки системы.
# Эффект: Готовая минимальная система Arch Linux.





clear
# БАЗОВАЯ СИСТЕМА: минимальный набор + инструменты разработки
pacstrap /mnt base base-devel
# БЕЗОПАСНОСТЬ: актуальные ключи пакетов
pacstrap /mnt archlinux-keyring
# ФАЙЛОВАЯ СИСТЕМА: утилиты для Btrfs
pacstrap /mnt btrfs-progs
# ОБОРУДОВАНИЕ: микрокод процессоров
pacstrap /mnt amd-ucode
# ДИАГНОСТИКА: тестер оперативной памяти
pacstrap /mnt memtest86+
# РЕДАКТОР: текстовый редактор
pacstrap /mnt nano
# PACMAN: оптимизация зеркал, доп. утилиты и клиент url
pacstrap /mnt reflector pacman-contrib curl
# Генерация файла fstab (таблицы файловых систем)
genfstab -pU /mnt >> /mnt/etc/fstab
#
clear
echo "##################################################"
echo "## <<< УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА, >>> ##"
echo "##################################################"
echo "##################################################"
echo "## <<< СОВЕРШЕН ВХОД в СИСТЕМУ CHROOT       >>> ##"
echo "##################################################"
# Переход в только что установленную систему с помощью chroot
# Важно: после выполнения этой команды все последующие команды
# будут выполняться внутри установленной системы, а не в live-окружении
arch-chroot /mnt /bin/bash
echo ""






#############################################################
## 🧩 БЛОК 8: НАСТРОЙКА ВНУТРИ CHROOT (СИСТЕМНЫЕ ПАРАМЕТРЫ) ##
#############################################################
#
# Зачем: Глобальная настройка системы после установки.
# Важно: Критически важные параметры системы.
# Эффект: Настроенные локали, часовой пояс, pacman, fstab.





clear
# Редактирование параметров монтирования Btrfs (для соответствующего типа диска):
sed -i "s/\S*subvol=\(\S*\)/subvol=\1,MOUNT_OPTIONS/g"  /etc/fstab
# Активация multilib репозитория (для 32-битных приложений):
# Раскомментирует все строки между [multilib] и Include включительно
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
# Увеличение количества параллельных загрузок пакетов с 5 до 15
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
# Включение цветного вывода в pacman
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
# Добавление графических улучшений в pacman (анимация прогресс-бара)
echo "[options]" >> /etc/pacman.conf
echo "ILoveCandy" >> /etc/pacman.conf
# Настройка раскладки клавиатуры и шрифта консоли
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
# Установка системных локалей (русский язык)
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "LC_MESSAGES=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_TIME=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_NUMERIC=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_MONETARY=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_COLLATE=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_CTYPE=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_NAME=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_ADDRESS=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_TELEPHONE=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_MEASUREMENT=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_PAPER=ru_RU.UTF-8" >> /etc/locale.conf
echo "LC_IDENTIFICATION=ru_RU.UTF-8" >> /etc/locale.conf
# Генерация локалей: раскомментирует en_US и ru_RU в locale.gen
sed -i "s/#\(en_US\.UTF-8\)/\1/" /etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
# Генерация локалей системы
locale-gen
# Экспорт локалей для текущей сессии (временная настройка)
export LANG=ru_RU.UTF-8
# Автоматическое определение временной зоны по IP
time_zone=$(curl -s https://ipinfo.io/timezone)
# Установка символьной ссылки на файл зоны
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
# Синхронизация аппаратных часов
hwclock --systohc
# Обновляем базу данных пакетов
pacman -Syy
# Настройка зеркал
# Автоматически определяем код страны по вашему IP
COUNTRY=$(curl -s https://ipapi.co/country_code)
# Скачиваем актуальный список зеркал для вашей страны
sudo curl -L "https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=https" -o /etc/pacman.d/mirrorlist.raw
# Раскомментируем все репозитории в списке
sudo sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.raw
# Ранжируем зеркала по скорости (топ-5) и сохраняем основной конфиг
sudo rankmirrors -n 5 /etc/pacman.d/mirrorlist.raw > /etc/pacman.d/mirrorlist
# Очищаем временные файлы
sudo rm /etc/pacman.d/mirrorlist.raw
# Обновляем базу данных пакетов
#pacman -Syy
# Включение автоматического обновления зеркал (таймер systemd)
systemctl enable reflector.timer
#
clear
echo "############################################"
echo "## <<< ПЕРВОНАЧАЛЬНАЯ НАСТРОЙКА ЗАВЕРШЕНА ##"
echo "############################################"





###################################################
## ✏️ БЛОК 9: НАСТРОЙКА ТЕКСТОВОГО РЕДАКТОРА NANO ##
###################################################
#
# Зачем: Улучшение пользовательского опыта в консоли.
# Важно: Делает работу с nano более удобной и визуально привлекательной.
# Эффект: Цветовая схема, номера строк, автоотступы и другие улучшения.





clear
# ==============================================================================
# НАСТОЙКА РЕДАКТОРА NANO В ARCH LINUX
# ==============================================================================
# Основные функциональные настройки
# ==============================================================================
# Активация автоотступов (копирует отступ предыдущей строки)
sed -i 's/# set autoindent/set autoindent/g' /etc/nanorc
# Постоянное отображение позиции курсора (строка/столбец)
sed -i 's/# set constantshow/set constantshow/g' /etc/nanorc
# Показывать индикатор прокрутки в правом верхнем углу
sed -i 's/# set indicator/set indicator/g' /etc/nanorc
# Включить номера строк (левая панель)
sed -i 's/# set linenumbers/set linenumbers/g' /etc/nanorc
# Разрешить открытие нескольких файлов в буферах
sed -i 's/# set multibuffer/set multibuffer/g' /etc/nanorc
# Очищать строку статуса после коротких сообщений
sed -i 's/# set quickblank/set quickblank/g' /etc/nanorc
# Умное поведение Home (переход к первому непустому символу)
sed -i 's/# set smarthome/set smarthome/g' /etc/nanorc
# Включить мягкое перенос длинных строк
sed -i 's/# set softwrap/set softwrap/g' /etc/nanorc
# Изменение размера табуляции с 8 на 4 пробела
sed -i 's/# set tabsize 8/set tabsize 4/g' /etc/nanorc
# Автоматическое преобразование табов в пробелы
sed -i 's/# set tabstospaces/set tabstospaces/g' /etc/nanorc
# Удаление пробелов в конце строк при сохранении
sed -i 's/# set trimblanks/set trimblanks/g' /etc/nanorc
# Принудительное использование Unix-формата окончаний строк (LF)
sed -i 's/# set unix/set unix/g' /etc/nanorc
# Умное определение границ слов для выделения текста
sed -i 's/# set wordbounds/set wordbounds/g' /etc/nanorc
# ==============================================================================
# ЕДИНАЯ ЦВЕТОВАЯ СХЕМА (ПУРПУРНО-ЖЕЛТАЯ ГАММА)
# ==============================================================================
# Заголовок окна: жирный, белый текст на пурпурном фоне
sed -i 's/# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/g' /etc/nanorc
# Подсказки: черный текст на желтом фоне
sed -i 's/# set promptcolor black,yellow/set promptcolor black,yellow/g' /etc/nanorc
# Строка статуса: жирный, белый текст на пурпурном фоне
sed -i 's/# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/g' /etc/nanorc
# Сообщения об ошибках: жирный, белый текст на красном фоне
sed -i 's/# set errorcolor bold,white,red/set errorcolor bold,white,red/g' /etc/nanorc
# Поисковые совпадения: черный текст на оранжевом фоне
sed -i 's/# set spotlightcolor black,orange/set spotlightcolor black,orange/g' /etc/nanorc
# Выделенный текст: светло-белый текст на голубом фоне
sed -i 's/# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/g' /etc/nanorc
# Полоса прокрутки: желтый фон
sed -i 's/# set stripecolor ,yellow/set stripecolor ,yellow/g' /etc/nanorc
# Скроллбар: пурпурный цвет
sed -i 's/# set scrollercolor magenta/set scrollercolor magenta/g' /etc/nanorc
# Номера строк: пурпурный цвет
sed -i 's/# set numbercolor magenta/set numbercolor magenta/g' /etc/nanorc
# Горячие клавиши: светло-пурпурный
sed -i 's/# set keycolor lightmagenta/set keycolor lightmagenta/g' /etc/nanorc
# Функциональные клавиши: пурпурный
sed -i 's/# set functioncolor magenta/set functioncolor magenta/g' /etc/nanorc
# ==============================================================================
# ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ
# ==============================================================================
# Включение подсветки синтаксиса для всех поддерживаемых языков
sed -i 's/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g' /etc/nanorc
clear
echo "######################################"
echo "## <<< НАСТРОЙКА NANO ЗАВЕРШЕНА >>> ##"
echo "######################################"





##################################################
## 🖥️ БЛОК 10: НАСТРОЙКА ХОСТНЕЙМА И ПАРОЛЯ ROOT ##
##################################################
# Зачем: Базовая идентификация системы и безопасность.
# Важно: Необходимо установить пароль root для доступа к системе.
# Эффект: Настроенное имя системы и безопасный доступ.






clear
# Установка имени компьютера (hostname)
echo "Sony" > /etc/hostname
# Создание файла hosts (база данных локальных узлов)
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Sony.localdomain   Sony" >> /etc/hosts
#
clear
echo "###################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ROOT >>> ##"
echo "###################################"
# Задаём пароль (root)
passwd
#
clear
echo "##############################################"
echo "## <<<  НАСТРОЙКА ROOT И HOST ЗАВЕРШЕНА >>> ##"
echo "##############################################"





#######################################################
## 👤 БЛОК 11: СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ И НАСТРОЙКА SUDO ##
#######################################################
#
# Зачем: Создание обычного пользователя с правами администратора.
# Важно: Не рекомендуется использовать root для повседневной работы.
# Эффект: Безопасная работа с системой через обычного пользователя.





clear
# Создание нового пользователя с указанными параметрами
useradd login -m -c "User Name" -s /bin/bash
# Добавление пользователя в системные группы
usermod -aG wheel,users login
# Разрешение sudo для группы wheel
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
#
clear
echo "###########################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ >>> ##"
echo "###########################################"
# Задаём пароль для пользователя (login)
passwd login
#
clear
echo "###############################################"
echo "## <<<  НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ ЗАВЕРШЕНА >>> ##"
echo "###############################################"





##################################################
## ⚙️ БЛОК 12: УСТАНОВКА ЯДРА, GRUB И MKINITCPIO ##
##################################################
#
# Зачем: Настройка загрузчика и ядра системы.
# Важно: Критически важный этап для успешной загрузки системы.
# Эффект: Работающий загрузчик с анимацией и поддержкой снапшотов.





clear
# 1. Установка пакетов
pacman -Syy
# Ядро Linux и компоненты
pacman -S --noconfirm linux-lts linux-lts-headers linux-firmware
# Загрузчик и управление загрузкой
pacman -S --noconfirm grub grub-btrfs os-prober
# Сетевое управление
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools
# Удалённый доступ
pacman -S --noconfirm openssh
# Интерфейс загрузки (Plymouth) - добавляем темы для анимации
pacman -S --noconfirm plymouth plymouth-theme-breeze
# 2. Включение служб
systemctl enable NetworkManager.service grub-btrfsd.service sshd.service
# 3. Установка GRUB
grub-install --recheck /dev/DISK  # Используем переменную DISK вместо жесткого /dev/sda
# 4. Получение UUID SWAP раздела (/dev/sdx3)
SWAP_UUID=$(blkid -s UUID -o value /dev/sdx3)
# 5. Настройка параметров GRUB
sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\".*\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash plymouth.resume=UUID=${SWAP_UUID} udev.log_priority=3 rootflags=subvol=@\"|" /etc/default/grub
# 6. Настройка grub-btrfs
sed -i "s/#GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/" /etc/default/grub-btrfs/config
sed -i "s/#GRUB_BTRFS_TITLE_FORMAT=(\"timedatectl status\" \"snapshot\" \"type\" \"description\")/GRUB_BTRFS_TITLE_FORMAT=(\"description\" \"date\")/" /etc/default/grub-btrfs/config
# 7. Исправление службы shutdown ramfs
sed -i 's/ProtectSystem=strict/ProtectSystem=full/' /usr/lib/systemd/system/mkinitcpio-generate-shutdown-ramfs.service
# 8. Настройка mkinitcpio
sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's|^HOOKS=.*|HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap block grub-btrfs-overlayfs btrfs filesystems fsck resume)|' /etc/mkinitcpio.conf
# 9. Генерация конфигурации GRUB
grub-mkconfig -o /boot/grub/grub.cfg
# 10. Пересборка образов initramfs
mkinitcpio -P
# 11. Настройка и активация Plymouth
plymouth-set-default-theme -R breeze  # Устанавливаем и применяем тему Plymouth
clear
echo "##################################################"
echo "##    УСТАНОВКА БАЗОВОЙ СИСТЕМЫ ЗАВЕРШЕНА       ##"
echo "##         И ГОТОВА К ИСПОЛЬЗОВАНИЮ.            ##"
echo "##  ПРИ ЖЕЛАНИИ ВЫ МОЖЕТЕ ВЫЙТИ ИЗ УСТАНОВЩИКА, ##"
echo "##         ЛИБО ПРОДОЛЖИТЬ УСТАНОВКУ.           ##"
echo "##################################################"





#####################################################
## 🧰 БЛОК 13: УСТАНОВКА СИСТЕМНЫХ УТИЛИТ И WAYLAND ##
#####################################################
#
# Зачем: Расширение функциональности системы.
# Важно: Устанавливает необходимые компоненты для работы системы.
# Эффект: Готовая к использованию система с базовыми утилитами.





clear
pacman -Syy
# Установка и активация haveged для ускорения генерации энтропии, особенно важно на виртуальных машинах и системах с низкой активностью
pacman -S --noconfirm haveged
systemctl enable haveged.service
# Установка базовых утилит для повседневного использования: wget, vim, утилиты для работы с USB, архивами и диагностики системы. Включая sudo для прав администратора и mlocate для поиска файлов
pacman -S --noconfirm wget vim usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
# Установка поддержки файловых систем: FAT, NTFS, Btrfs, exFAT, GPT, сетевые файловые системы (NFS, CIFS) для работы с сетевыми ресурсами
pacman -S --noconfirm dosfstools ntfs-3g btrfs-progs exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
# Установка системных сервисов для планирования задач и синхронизации времени.
pacman -S --noconfirm cronie chrony
systemctl enable cronie.service chronyd.service
# Установка Bluetooth стека с автоматической активацией устройств.
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
# Установка CUPS для печати и PDF, с поддержкой обнаружения сетевых принтеров через Avahi и виртуальный PDF-принтер)
pacman -S --noconfirm cups cups-pdf ghostscript gsfonts avahi hplip system-config-printer
systemctl enable cups.service avahi-daemon.service
# Настройка стандартных каталогов пользователя (Документы, Загрузки и др.) и утилит для работы с рабочим столом
pacman -S --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
# Управление устройствами
pacman -S --noconfirm udisks2 udiskie polkit
# Установка PipeWire в качестве основного звукового сервера с поддержкой PulseAudio, JACK и видеозахвата. Настройка автозапуска для всех пользователей после первой загрузки
pacman -S --noconfirm wireplumber pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
systemctl --global enable pipewire pipewire-pulse wireplumber
# Установка мультимедиа кодеков для программной обработки аудио/видео форматов
pacman -S --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss vlc
# Установка документации: man-страницы на русском и английском языках для справки по командам и конфигурационным файлам
pacman -S --noconfirm man-db man-pages man-pages-ru
# Установка базовых шрифтов для корректного отображения текста в графической оболочке, включая поддержку эмодзи
pacman -S --noconfirm ttf-dejavu noto-fonts noto-fonts-emoji
# Установка дополнительных сетевых утилит для диагностики и настройки сети (iproute2, dig, traceroute)
pacman -S --noconfirm iproute2 inetutils dnsutils
# Установка утилит для диагностики системы: fastfetch и hyfetch для отображения информации о системе, inxi для детальной диагностики оборудования
pacman -S --noconfirm fastfetch hyfetch inxi
clear
# БАЗОВЫЕ ГРАФИЧЕСКИЕ КОМПОНЕНТЫ (Wayland)
# Современный стек вместо устаревшего Xorg
pacman -S --noconfirm mesa vulkan-icd-loader libglvnd
pacman -S --noconfirm wayland wayland-protocols
pacman -S --noconfirm libinput libxkbcommon seatd
systemctl enable seatd.service  # Для управления правами доступа к GPU
mkinitcpio -P
clear
echo "###############################################################"
echo "## <<<  УСТАНОВКА СИСТЕМНЫХ ПРОГРАММ И WAYLAND ЗАВЕРШЕНА >>> ##"
echo "###############################################################"
echo "##############################################"
echo "## <<<  ВИДЕОКАРТЫ  ДАННОГО КОМПЬЮТЕРА  >>> ##"
echo "##############################################"
echo "## <<< ВЫБЕРИТЕ ДРАЙВЕРА СОГЛАСНО ТЕСТУ >>> ##"
echo "##############################################"
echo ""
echo ""
echo "Видеокарты:" && lspci -nn | grep -i 'vga' ; echo "Драйверы:" && lsmod | grep -iE 'nvidia|amdgpu|i915'
echo ""
echo ""





##################################################################
## 💻 БЛОК 14: УСТАНОВКА ДОПОЛНИТЕЛЬНЫХ КОМПОНЕНТОВ (VIRTUALBOX) ##
##################################################################
#
# Зачем: Установка гостевых дополнений VirtualBox для лучшей интеграции.
# Важно: Выполняйте этот блок только при установке в VirtualBox.
# Эффект: Улучшенная производительность, общие папки, правильное разрешение экрана.





clear
# 1. Обновить базу данных пакетов и установить зависимости:
pacman -Syy --noconfirm
pacman -S --needed --noconfirm virtualbox-guest-utils
# 2. Загрузить модули ядра для VirtualBox:
modprobe -a vboxguest vboxsf vboxvideo
# 3. Включить сервисы интеграции:
systemctl enable vboxservice.service
systemctl start vboxservice.service
# 4. Разрешить общие папки для текущего пользователя:
usermod -aG vboxsf $USER
# 5. Добавить модули в initramfs:
echo "vboxguest vboxsf vboxvideo" | tee /etc/modules-load.d/virtualbox.conf
# 6. Пересборка образов initramfs
mkinitcpio -P
clear
echo "#############################################"
echo "## <<<  НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""





################################################################
## 🖥️ БЛОК 15: УСТАНОВКА KDE PLASMA ##
################################################################
#
# Зачем: Установка современной и функциональной графической оболочки KDE Plasma.
# Важно: Требует достаточных ресурсов системы (рекомендуется минимум 4 ГБ ОЗУ).
# Эффект: Полноценная рабочая среда с множеством настроек и возможностей.





clear
pacman -Syy
# Plasma
# Рабочий стол/Окна:
pacman -S --noconfirm plasma-desktop plasma-workspace kwin kwin-x11 kwayland libplasma kdecoration layer-shell-qt plasma5support
# Виджеты/Дополнения:
pacman -S --noconfirm kdeplasma-addons plasma-systemmonitor plasma-sdk
# Темы/Оформление:
pacman -S --noconfirm breeze breeze-gtk aurorae oxygen qqc2-breeze-style oxygen-sounds ocean-sound-theme kgamma
# Системные службы/Инфо:
pacman -S --noconfirm kactivitymanagerd plasma-activities plasma-activities-stats kinfocenter ksystemstats libksysguard powerdevil kmenuedit kde-cli-tools kwrited milou
# Настройки (KCM):
pacman -S --noconfirm systemsettings kde-gtk-config kscreen libkscreen plasma-nm plasma-pa plasma-firewall sddm-kcm plymouth-kcm krdp flatpak-kcm wacomtablet plasma-disks plasma-thunderbolt
# Безопасность:
pacman -S --noconfirm kscreenlocker polkit-kde-agent kwallet-pam ksshaskpass plasma-vault
# Аппаратура:
pacman -S --noconfirm bluedevil plasma-disks plasma-thunderbolt kpipewire
# Приложения:
pacman -S --noconfirm discover spectacle drkonqi print-manager plasma-welcome
# Сеть:
pacman -S --noconfirm plasma-nm krdp
# Звук:
pacman -S --noconfirm plasma-pa oxygen-sounds ocean-sound-theme
# Загрузка:
pacman -S --noconfirm breeze-plymouth plymouth-kcm sddm-kcm
# Интеграция:
pacman -S --noconfirm plasma-integration kde-gtk-config flatpak-kcm plasma-browser-integration xdg-desktop-portal-kde
# kde-system
pacman -S --noconfirm khelpcenter ksystemlog
# kde-utilities
pacman -S --noconfirm ark filelight kate kcalc kfind yakuake
# kde-sdk
pacman -S --noconfirm dolphin-plugins
# kde-multimedia
pacman -S --noconfirm audiocd-kio elisa
# kde-graphics
pacman -S --noconfirm gwenview okular
clear
systemctl enable sddm
clear
echo "#############################################"
echo "## <<<  УСТАНОВКА KDE PLASMA ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""





################################################################
## 🖥️ БЛОК 16: КОНФИГУРАЦИЯ ПОЛЬЗОВАТЕЛЯ (KDE) ##
################################################################
#
# Зачем: Настройка пользовательского окружения после установки DE.
# Важно: Выполняется после установки графической оболочки.
# Эффект: Готовая к использованию рабочая среда с настроенными параметрами.





clear
# xinitrc
echo "export DESKTOP_SESSION=plasma" > ~/.xinitrc
echo "exec startplasma-x11" >> ~/.xinitrc
sudo cp ~/.xinitrc /root/.xinitrc
systemctl --user --now enable pipewire pipewire-pulse wireplumber
clear


# zsh
sudo pacman -S --noconfirm zsh git curl
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#
clear
# ohmyzsh-congig
chsh -s $(which zsh)
sed -i s/'ZSH_THEME=\"robbyrussell\"'/'ZSH_THEME=\"agnoster\"'/g ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
mv zsh-syntax-highlighting ~/.oh-my-zsh/plugins
echo "source ~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
git clone https://github.com/zsh-users/zsh-autosuggestions
mv zsh-autosuggestions ~/.oh-my-zsh/custom/plugins
sed -i s/'plugins=(git)'/'plugins=(git archlinux extract themes zsh-navigation-tools zsh-autosuggestions)'/g ~/.zshrc
echo "hyfetch" >> ~/.zshrc
clear
echo "#############################################"
echo "## <<<  КОНФИГУРАЦИЯ ПОЛЬЗОВАТЕЛЯ ГОТОВА >>> ##"
echo "#############################################"
echo ""





#######################################
## 🖥️ БЛОК 17: УСТАНОВКА ARCH TRINITY ##
######################################
#
# Зачем: Установка легковесной классической графической оболочки Trinity.
# Важно: Хорошо подходит для старых компьютеров с ограниченными ресурсами.
# Эффект: Классический интерфейс с современными возможностями.





clear
pacman -Syy
# Xorg
pacman -S --noconfirm xorg
echo "#" >> /etc/pacman.conf
echo "#" >> /etc/pacman.conf
echo "# Official Trinity ArchLinux repository" >> /etc/pacman.conf
echo "[trinity]" >> /etc/pacman.conf
echo "Server = https://mirror.ppa.trinitydesktop.org/trinity/archlinux/x86_64/" >> /etc/pacman.conf
pacman-key --recv-key  D6D6FAA25E9A3E4ECD9FBDBEC93AF1698685AD8B
pacman-key --lsign-key D6D6FAA25E9A3E4ECD9FBDBEC93AF1698685AD8B
pacman -Syy
pacman -S --noconfirm tde-meta gdb blueman
#
systemctl enable tdm.service
#
clear
echo "###############################################"
echo "## <<<  УСТАНОВКА ARCH TRINITY ЗАВЕРШЕНА >>> ##"
echo "###############################################"
echo ""





################################
## 🖥️ БЛОК 18: УСТАНОВКА XFCE4 ##
################################
#
# Зачем: Установка легковесной и гибкой графической оболочки XFCE4.
# Важно: Хорошее сочетание производительности и функциональности.
# Эффект: Быстрая и настраиваемая рабочая среда.





clear
pacman -Syy
pacman -S --noconfirm xfce4
pacman -S --noconfirm mousepad thunar-archive-plugin thunar-media-tags-plugin xfburn xfce4-artwork xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpufreq-plugin xfce4-cpugraph-plugin xfce4-dict xfce4-diskperf-plugin xfce4-eyes-plugin xfce4-fsguard-plugin xfce4-genmon-plugin xfce4-mailwatch-plugin xfce4-mount-plugin xfce4-mpc-plugin xfce4-netload-plugin xfce4-notes-plugin xfce4-notifyd xfce4-places-plugin xfce4-pulseaudio-plugin xfce4-screensaver  xfce4-screenshooter xfce4-sensors-plugin xfce4-smartbookmark-plugin xfce4-systemload-plugin  xfce4-taskmanager xfce4-time-out-plugin xfce4-timer-plugin xfce4-verve-plugin xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin xdg-user-dirs
pacman -S --noconfirm mugshot pavucontrol archlinux-xdg-menu xdg-desktop-portal-gtk menulibre network-manager-applet
update-menus
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm blueman engrampa ffmpegthumbnailer libgsf udiskie evince
pacman -S --noconfirm catfish galculator libopenraw mtpfs ntp numlockx perl-file-mimeinfo pidgin powertop unace xcursor-simpleandsoft xcursor-vanilla-dmz-aa gcolor3 xiccd
systemctl enable lightdm.service
clear
echo "########################################"
echo "## <<<  УСТАНОВКА XFCE4 ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""





#################################
## 🖥️ БЛОК 19: УСТАНОВКА GNOME ##
#################################
#
# Зачем: Установка современной и интуитивно понятной графической оболочки GNOME.
# Важно: Требует достаточно ресурсов системы (рекомендуется минимум 4 ГБ ОЗУ).
# Эффект: Современный интерфейс с акцентом на простоту и удобство использования.





clear
pacman -Syy
#  Gnome
# Базовый рабочий стол GNOME
pacman -S --noconfirm gnome-shell gdm gnome-session gnome-control-center gnome-settings-daemon gnome-settings-daemon
# Системные компоненты и сервисы
pacman -S --noconfirm gnome-keyring gvfs grilo-plugins xdg-desktop-portal-gnome xdg-user-dirs-gtk
# Основные приложения
pacman -S --noconfirm nautilus gnome-software epiphany gnome-console gnome-text-editor
# Мультимедиа
pacman -S --noconfirm gnome-music totem loupe eog gnome-snapshot simple-scan
# Утилиты и инструменты
pacman -S --noconfirm gnome-calculator gnome-calendar gnome-clocks gnome-characters gnome-contacts gnome-weather gnome-maps gnome-disk-utility gnome-font-viewer gnome-logs gnome-color-manager baobab
# Сетевая интеграция
pacman -S --noconfirm gnome-connections gnome-remote-desktop gnome-user-share
# Документация и доступность
pacman -S --noconfirm gnome-user-docs yelp orca gnome-tour
# Дополнительные сервисы
pacman -S --noconfirm rygel sushi malcontent
# Бэкенды GVFS (для устройств и облаков)
pacman -S --noconfirm gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-smb gvfs-nfs gvfs-google gvfs-onedrive gvfs-goa gvfs-dnssd gvfs-wsdd
systemctl enable gdm
echo "[User]" > /var/lib/AccountsService/users/root
echo "SystemAccount=true" > /var/lib/AccountsService/users/root
#  Gnome-extra
pacman -S --noconfirm dconf-editor eog file-roller gnome-devel-docs gnome-multi-writer gnome-notes gnome-sound-recorder gnome-terminal gnome-tweaks seahorse sysprof
pacman -S --noconfirm gnome-browser-connector gnome-firmware gnome-shell-extension-appindicator gnome-shell-extension-arc-menu gnome-shell-extension-dash-to-panel gnuchess power-profiles-daemon squashfs-tools
pacman -S --noconfirm gthumb gtkmm3 system-config-printer deja-dup
pacman -S --noconfirm adw-gtk-theme gnome-themes-extra
pacman -S --noconfirm ffmpegthumbnailer
clear
echo "########################################"
echo "## <<<  УСТАНОВКА GNOME ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""





###################################
## 🖥️ БЛОК 20: УСТАНОВКА CINNAMON ##
###################################
#
# Зачем: Установка графической оболочки Cinnamon с классическим интерфейсом.
# Важно: Хорошо подходит для пользователей, привыкших к традиционному расположению элементов.
# Эффект: Удобный и настраиваемый рабочий стол с современными возможностями.





clear
pacman -Syy
pacman -S --noconfirm cinnamon cinnamon-translations blueman dconf-editor ffmpegthumbnailer gcolor3 gnome-disk-utility gnome-keyring gnome-online-accounts gnome-screenshot gnome-system-monitor gnome-terminal gnome-themes-extra mousetweaks onboard pavucontrol powertop system-config-printer  xreader xdg-desktop-portal-gnome evince
pacman -S --noconfirm nemo-fileroller nemo-preview nemo-python nemo-share
pacman -S --noconfirm kvantum
pacman -S --noconfirm icon-naming-utils
pacman -S --noconfirm baobab galculator netctl numlockx python-pyxdg qt5ct redshift squashfs-tools tree udiskie
pacman -S --noconfirm lightdm lightdm-slick-greeter
systemctl enable lightdm.service
sed -i s/'#greeter-session=example-gtk-gnome'/'greeter-session=lightdm-slick-greeter'/g /etc/lightdm/lightdm.conf
clear
echo "##################################"
echo "## <<<  УСТАНОВКА ЗАВЕРШЕНА >>> ##"
echo "##################################"
echo ""





###############################
## 🖥️ БЛОК 21: УСТАНОВКА MATE ##
###############################
#
# Зачем: Установка легковесной графической оболочки MATE.
# Важно: Основана на классическом GNOME 2, подходит для старых компьютеров.
# Эффект: Стабильная и эффективная рабочая среда с классическим интерфейсом.





clear
pacman -Syy
pacman -S --noconfirm mate mate-extra
pacman -S --noconfirm mate-themes
pacman -S --noconfirm plank
pacman -S --noconfirm lightdm lightdm-slick-greeter
systemctl enable lightdm.service
sed -i s/'#greeter-session=example-gtk-gnome'/'greeter-session=lightdm-slick-greeter'/g /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
clear
echo "#######################################"
echo "## <<<  УСТАНОВКА MATE ЗАВЕРШЕНА >>> ##"
echo "#######################################"
echo ""





###############################
## 🖥️ БЛОК 22: УСТАНОВКА LXQT ##
###############################
#
# Зачем: Установка современной легковесной графической оболочки LXQt.
# Важно: Очень низкие требования к ресурсам системы.
# Эффект: Быстрый и современный интерфейс с минимальным потреблением ресурсов.





clear
pacman -Syy
pacman -S --noconfirm lxqt lxqt-themes xscreensaver picom libstatgrab libsysstat breeze-icons kvantum-qt5 blueman featherpad
pacman -S --noconfirm  kwin kwin-x11 discover bluedevil systemsettings plasma-sdk aurorae breeze breeze-gtk flatpak-kcm kde-gtk-config kpipewire kscreen kscreenlocker gnome-keyring milou plasma-desktop plasma-pa print-manager qqc2-breeze-style xdg-desktop-portal-kde
pacman -S --noconfirm sddm sddm-kcm
systemctl enable sddm.service
clear
echo "######################################"
echo "## <<< УСТАНОВКА LXQT ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""





################################
## 🖥️ БЛОК 23: УСТАНОВКА LXDE ##
################################
#
# Зачем: Установка максимально легковесной графической оболочки LXDE.
# Важно: Минимальные требования к ресурсам, подходит для очень старых компьютеров.
# Эффект: Максимально быстрая работа даже на слабых системах.





clear
pacman -Syy
pacman -S --noconfirm lxde leafpad openbox pavucontrol alsa-utils xfce4-notifyd
pacman -S --noconfirm xscreensaver picom libstatgrab libsysstat mugshot dunst
pacman -S --noconfirm lxqt-archiver ffmpegthumbnailer
pacman -S --noconfirm thunar-archive-plugin  thunar-media-tags-plugin thunar-shares-plugin ffmpegthumbnailer libgsf udiskie
update-menus
pacman -S --noconfirm lightdm lightdm-slick-greeter
pacman -S --noconfirm blueman lxqt-archiver ffmpegthumbnailer
sed -i s/'#greeter-session=example-gtk-gnome'/'greeter-session=lightdm-slick-greeter'/g /etc/lightdm/lightdm.conf
sed -i s/'#display-setup-script='/'display-setup-script=xrandr --output Virtual-1 --mode 1920x1080'/g /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
#
clear
echo "######################################"
echo "## <<< УСТАНОВКА LXDE ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""





######################################
## 🏁 БЛОК 24: ЗАВЕРШЕНИЕ УСТАНОВКИ ##
######################################
#
# Зачем: Завершение установки и подготовка к первому запуску.
# Важно: Последний этап установки, после которого система готова к использованию.
# Эффект: Готовая к работе система Arch Linux с выбранным окружением.





clear
echo "############################################################"
echo "## <<<  УСТАНОВКА ARCH LINUX ЗАВЕРШЕНА УСПЕШНО! >>>       ##"
echo "##                                                        ##"
echo "##  1. Выход из chroot: exit                              ##"
echo "##  2. Размонтирование: umount -R /mnt                    ##"
echo "##  3. Перезагрузка: poweroff                             ##"
echo "##                                                        ##"
echo "##  После перезагрузки войдите в систему с вашим          ##"
echo "##  пользователем и запустите графическую оболочку.       ##"
echo "##                                                        ##"
echo "##  Приятного использования Arch Linux!                   ##"
echo "############################################################"
#
