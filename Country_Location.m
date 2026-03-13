# 🔧 ИНСТРУКЦИЯ ПО ОПРЕДЕЛЕНИЮ БЛИЖАЙШИХ СТРАН ПО IP-АДРЕСУ

# ⚠️ ВНИМАНИЕ: Выполняйте команды по порядку в терминале.
# Не запускайте как единый скрипт!
# Для Live Arch Linux: Все изменения будут потеряны после перезагрузки!

# 📦 ЧАСТЬ 1: ПОДГОТОВКА СИСТЕМЫ И ПРОВЕРКА ИНТЕРНЕТА

# 1.1 Проверка подключения к интернету
# 🌐 Это критически важно для работы скрипта (API и загрузка карт).

ping -c 3 archlinux.org

# ℹ️ Если нет ответа — настройте сеть через nmtui или iwctl.

# 1.2 Обновление пакетной базы (рекомендуется)
# 🔄 Гарантирует установку актуальных версий пакетов.

sudo pacman -Syu

# 1.3 Установка необходимых зависимостей Python
# 📦 Эти пакеты нужны для геолокации и работы с географическими данными.

sudo pacman -S --noconfirm python python-requests python-geopandas python-shapely

# ⚠️ Установка geopandas может занять время (много зависимостей).

# 🔍 ЧАСТЬ 2: СОЗДАНИЕ СКРИПТА
# 2.1 Создание файла скрипта nearest_countries.py
# 📝 Используйте heredoc для быстрого создания файла.

cat > nearest_countries.py << 'EOF'
import requests
import geopandas as gpd
from shapely.geometry import Point
import sys

# Функция получения координат по IP
def get_ip_location():
    try:
        # Используем бесплатный API без ключа
        response = requests.get('http://ip-api.com/json/')
        data = response.json()
        if data['status'] == 'fail':
            raise Exception("Не удалось определить местоположение по IP")
        return float(data['lat']), float(data['lon']), data.get('countryCode', 'Unknown')
    except Exception as e:
        print(f"Ошибка геолокации IP: {e}")
        sys.exit(1)

# Функция загрузки границ стран
def get_world_data():
    url = "https://raw.githubusercontent.com/johan/world.geo.json/master/countries.geo.json"
    try:
        gdf = gpd.read_file(url)
        return gdf
    except Exception as e:
        print(f"Ошибка загрузки данных карты: {e}")
        sys.exit(1)

# Основная функция
def main():
    print("1. Определение местоположения по IP...")
    lat, lon, user_country_code = get_ip_location()
    print(f"   Ваше местоположение (IP): {lat}, {lon} (Страна: {user_country_code})")

    print("2. Загрузка данных о границах стран...")
    world = get_world_data()
    print(f"   Загружено границ: {len(world)}")

    # Создаем гео-объект пользователя
    user_point = Point(lon, lat)
    user_geo = gpd.GeoDataFrame([{'geometry': user_point}], crs="EPSG:4326")

    # Проецируем в метры (Mercator) для точного расчета расстояния
    world_proj = world.to_crs(epsg=3395)
    user_proj = user_geo.to_crs(epsg=3395)
    user_point_proj = user_proj.geometry[0]

    print("3. Расчет расстояний до границ стран...")
    # Считаем минимальное расстояние до полигона каждой страны
    world_proj['distance'] = world_proj.geometry.distance(user_point_proj)
    nearest = world_proj.sort_values(by='distance')

    print("\n--- 10 ближайших стран (географически) ---")
    print(f"{'#':<3} {'Страна':<20} {'Расстояние (км)':<15} {'Код'}")
    print("-" * 50)

    count = 0
    for index, row in nearest.iterrows():
        name = row.get('name', 'Unknown')
        dist_km = row['distance'] / 1000
        print(f"{count + 1:<3} {name:<20} {dist_km:<15.2f} {row.get('id', 'N/A')}")
        count += 1
        if count >= 10:
            break

if __name__ == "__main__":
    main()
EOF

# 2.2 Проверка создания файла
# ✅ Убедитесь, что файл создан и имеет правильный размер.

ls -l nearest_countries.py

# 2.3 (Опционально) Добавление прав на выполнение
# 🔐 Хотя это не обязательно для запуска через python.

chmod +x nearest_countries.py

# 🚀 ЧАСТЬ 3: ЗАПУСК И ВЕРИФИКАЦИЯ
# 3.1 Запуск скрипта
# ⚡ Это запустит определение местоположения и расчет расстояний.

python nearest_countries.py

# ⚠️ ВНИМАНИЕ: Первый запуск может занять 30-60 секунд (загрузка карты мира).

# 3.2 Проверка вывода
# 📊 Убедитесь, что вы видите:
#    • Ваши координаты (широта, долгота)
#    • Код вашей страны
#    • Список из 10 ближайших стран с расстояниями

# 3.3 (Опционально) Сохранение результатов в файл
# 💾 Полезно для документирования или последующего анализа.

python nearest_countries.py > results_$(date +%Y%m%d_%H%M%S).txt

# 📝 ЧАСТЬ 4: СОХРАНЕНИЕ ДАННЫХ (LIVE SYSTEM)
# ⚠️ КРИТИЧЕСКИ ВАЖНО для Live Arch Linux!
# 4.1 Проверка подключенных накопителей
# 💾 Найдите вашу флешку или внешний диск.

lsblk

# ℹ️ Ищите устройство по размеру (например, sdb1 на 16G).

# 4.2 Создание точки монтирования и монтирование
# 📁 Смонтируйте внешний носитель для сохранения файлов.

sudo mkdir -p /mnt/usb
sudo mount /dev/sdX1 /mnt/usb

# ⚠️ ЗАМЕНИТЕ /dev/sdX1 на ваше устройство (например, /dev/sdb1)!

# 4.3 Копирование скрипта на внешний носитель
# 💾 Сохраните скрипт для будущего использования.

cp nearest_countries.py /mnt/usb/
cp Country_Location.txt /mnt/usb/

# 4.4 Копирование результатов (если есть)
# 📊 Сохраните полученные данные.

cp results_*.txt /mnt/usb/ 2>/dev/null

# 4.5 Безопасное размонтирование
# ⏹️ Обязательно перед извлечением флешки!

sudo umount /mnt/usb




# 🛠️ ЧАСТЬ 5: ИНСТРУКЦИЯ ДЛЯ ДРУГИХ ДИСТРИБУТИВОВ

# 5.1 Ubuntu / Debian / Linux Mint
# 📦 Используйте apt вместо pacman.

sudo apt update
sudo apt install python3 python3-requests python3-geopandas python3-shapely
python3 nearest_countries.py

# ℹ️ В Ubuntu 20.04+ требуется universe-репозиторий.




# 5.2 Fedora / RHEL / CentOS
# 📦 Используйте dnf или yum.

sudo dnf install python3 python3-requests python3-geopandas python3-shapely
python3 nearest_countries.py

# ⚠️ В RHEL/CentOS может потребоваться: sudo dnf install epel-release




# 5.3 openSUSE / SUSE Linux Enterprise
# 📦 Используйте zypper.

sudo zypper install python3 python3-requests python3-geopandas python3-shapely
python3 nearest_countries.py

# ℹ️ Некоторые пакеты могут быть доступны через Open Build Service.

# 5.4 Универсальный способ (через pip)
# 🔧 Если пакеты недоступны в репозитории дистрибутива.
# Установка pip
# Arch:     sudo pacman -S python-pip
# Ubuntu:   sudo apt install python3-pip
# Fedora:   sudo dnf install python3-pip
# openSUSE: sudo zypper install python3-pip

# Установка зависимостей через pip

pip3 install --user requests geopandas shapely

# Запуск скрипта

python3 nearest_countries.py

# 📊 ЧАСТЬ 6: ТАБЛИЦА СОВМЕСТИМОСТИ
# ┌──────────────────┬──────────────────┬──────────────────┬─────────────────────┐
# │  Компонент       │  Arch Linux      │  Ubuntu/Debian   │  Fedora/RHEL        │
# ├──────────────────┼──────────────────┼──────────────────┼─────────────────────┤
# │  Python          │  python          │  python3         │  python3            │
# │  Requests        │  python-requests │  python3-requests│  python3-requests   │
# │  Geopandas       │  python-geopandas│ python3-geopandas│  python3-geopandas  │
# │  Shapely         │  python-shapely  │  python3-shapely │  python3-shapely    │
# │  Менеджер        │  pacman          │  apt             │  dnf/yum            │
# └──────────────────┴──────────────────┴──────────────────┴─────────────────────┘

# 🚨 ЧАСТЬ 7: ВОЗМОЖНЫЕ ОШИБКИ И РЕШЕНИЯ
# 7.1 Ошибка: ModuleNotFoundError: No module named 'geopandas'
# 🔧 Причина: Пакет не установлен.
# ✅ Решение:

sudo pacman -S python-geopandas

# или через pip

pip3 install geopandas

# 7.2 Ошибка: Permission denied при запуске
# 🔧 Причина: Нет прав на выполнение (редко).
# ✅ Решение:

chmod +x nearest_countries.py
./nearest_countries.py

# 7.3 Ошибка: Не удалось определить местоположение по IP
# 🔧 Причина: Нет интернета или API недоступен.
# ✅ Решение:
# Проверьте интернет

ping -c 3 google.com

# Попробуйте позже или используйте VPN

# 7.4 Ошибка: Ошибка загрузки данных карты
# 🔧 Причина: Нет доступа к GitHub или проблемы с сетью.
# ✅ Решение:
# Проверьте интернет

ping -c 3 github.com

# Или скачайте файл вручную:

curl -o countries.geo.json https://raw.githubusercontent.com/johan/world.geo.json/master/countries.geo.json

# 7.5 Скрипт работает очень медленно
# 🔧 Причина: Загрузка карты мира или слабое железо.
# ✅ Решение:
# Подождите, первый запуск всегда медленный
# Последующие запуски будут быстрее (кэширование)

# ✅ ЧАСТЬ 8: ФИНАЛЬНАЯ ПРОВЕРКА
# 8.1 Контрольный список перед завершением
# [ ] Скрипт nearest_countries.py создан
# [ ] Зависимости установлены
# [ ] Скрипт успешно выполнен
# [ ] Увидели список из 10 стран
# [ ] Результаты сохранены (опционально)
# [ ] Файлы скопированы на внешний носитель (для Live системы)

# 8.2 Полезные команды для будущего
# 📋 Добавьте в ~/.bashrc для быстрого доступа:

echo "alias countries='python ~/nearest_countries.py'" >> ~/.bashrc
source ~/.bashrc

# Теперь можно запускать просто: countries

# 📚 ЧАСТЬ 9: ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ
# 9.1 API для геолокации (альтернативы)
# 🌐 ip-api.com (используется в скрипте) — бесплатно, без ключа
# 🌐 ipinfo.io — требуется регистрация для большого объёма
# 🌐 ipstack.com — бесплатный тариф с ограничениями

# 9.2 Источники данных о границах
# 🗺️ https://github.com/johan/world.geo.json (используется в скрипте)
# 🗺️ https://naturalneearthdata.com — более подробные данные
# 🗺️ https://gadm.org — административные границы

# 9.3 Документация библиотек
# 📖 Geopandas: https://geopandas.org
# 📖 Shapely: https://shapely.readthedocs.io
# 📖 Arch Wiki: https://wiki.archlinux.org

# ================================================================================
#   ЗАКЛЮЧЕНИЕ
# ================================================================================
# ✅ <<< СКРИПТ ГОТОВ К ИСПОЛЬЗОВАНИЮ >>> ✅

# 💡 Советы:
# - 📋 Точность зависит от IP-геолокации (ошибка 10-100 км)
# - 🌍 Первая страна в списке — обычно ваша (расстояние ~0 км)
# - 🔄 Для Live Arch: сохраняйте файлы на внешний носитель!
# - 📊 Результаты приблизительные, не используйте для критических задач

# 📝 Версия инструкции: 1.0
# 👤 Для: Юрий
# 📅 Дата: $(date +%Y.%m.%d)
# 🖥️ Дистрибутив: Arch Linux (Live/Install)
# ================================================================================
