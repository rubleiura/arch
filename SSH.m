##########################################
# ПОДГОТОВКА К УСТАНОВКЕ ARCH LINUX      #
# (SSH-доступ и сетевая настройка)       #
##########################################

### 1. ПОДКЛЮЧЕНИЕ К СЕТИ ###

# [Ethernet]
# Проверить интерфейс:

ip link

# Включить интерфейс:

ip link set eth0 up  # замените eth0 на ваш интерфейс

# Получить IP:

dhcpcd eth0

# [Wi-Fi]
# Показать доступные устройства:

iwctl device list

# Запустить интерактивный менеджер:

iwctl

--- Внутри iwd ---
# Сканировать сети:

station wlan0 scan

# Показать доступные сети:

station wlan0 get-networks

# Подключиться:

station wlan0 connect "Имя_Сети"

# Выйти:

exit

#########-

# [Проверка]

ping -c 3 archlinux.org

### 2. УСТАНОВКА SSH ###

pacman -Sy openssh

### 3. НАСТРОЙКА SSH (ВРЕМЕННАЯ!) ###

# Разрешить root-вход через sed:

sed -i 's/^#*\s*PermitRootLogin\s.*/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Установить пароль root:

passwd  # Введите надежный пароль!

### 4. ЗАПУСК SSH ###

systemctl start sshd

### 5. ОПРЕДЕЛЕНИЕ IP ###

ip -brief address

# Пример: eth0 UP 192.168.1.100/24

### 6. ПОДКЛЮЧЕНИЕ С ДРУГОГО УСТРОЙСТВА ###

ssh root@ВАШ_IP  # Пример: ssh root@192.168.1.100

### 7. КОМАНДЫ ДЛЯ ПРОСМОТРА УСТРОЙСТВ ###

# [Диски]

lsblk

# [Сеть]

ip -c addr

# [Wi-Fi]

iwctl device list

# [USB]

lsusb

# [PCI]

lspci

### 8. ПОСЛЕДУЮЩИЕ ДЕЙСТВИЯ ###

1. Запретить root-вход после установки:
   sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

2. Создать пользователя:
   useradd -m -G wheel username
   passwd username

3. Настроить sudo:
   pacman -S sudo
   EDITOR=nano visudo  # Раскомментируйте %wheel ALL=(ALL) ALL

### ОБЪЯСНЕНИЕ КОМАНДЫ SED ###
Исходная команда:

  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

Заменена на:
  sed -i 's/^#*\s*PermitRootLogin\s.*/PermitRootLogin yes/g' /etc/ssh/sshd_config

Что это делает:
1. -i       - Изменяет файл напрямую
2. s/old/new/ - Заменяет 'old' на 'new'
3. ^        - Начало строки
4. #*       - Любое количество символов '#' (для комментариев)
5. \s*      - Любое количество пробельных символов
6. .*       - Любой текст до конца строки
7. /g       - Глобальная замена (все вхождения)

Это:
- Раскомментирует строку, если она закомментирована
- Заменит любые существующие значения (no/prohibit-password) на yes
- Гарантирует правильный синтаксис без дублирования

### АЛЬТЕРНАТИВНЫЙ ВАРИАНТ ###
Если требуется только раскомментировать строку:
  sed -i 's/^#\s*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

Для полной безопасности:
  grep -q "PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

#############################################
# Сгенерировано: $(date)
# Для Arch Linux 2024.07.01
#############################################
