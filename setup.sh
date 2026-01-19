#!/bin/bash

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с правами root (sudo)."
  exit
fi

# Проверка наличия аргумента (Network ID)
NETWORK_ID=$1
if [ -z "$NETWORK_ID" ]; then
    echo "ОШИБКА: Не указан Network ID."
    echo "Пример использования: curl ... | sudo bash -s [ВАШ_NETWORK_ID]"
    exit 1
fi

echo "=========================================="
echo "   ZeroTier Auto-Install & VPN Config"
echo "=========================================="

# 1. Установка ZeroTier
if ! command -v zerotier-cli &> /dev/null; then
    echo "[+] Устанавливаем ZeroTier..."
    curl -s 'https://install.zerotier.com' | bash
else
    echo "[+] ZeroTier уже установлен."
fi

# 2. Подключение к сети
echo "[+] Подключаемся к сети: $NETWORK_ID"
zerotier-cli join "$NETWORK_ID"

echo "[i] Ждем 10 секунд для получения IP..."
sleep 10

# 3. Определение интерфейсов
# Ищем интерфейс, начинающийся на zt (ZeroTier)
ZT_INTERFACE=$(ip -o link show | grep 'zt' | awk -F': ' '{print $2}' | head -n 1)
# Ищем основной интерфейс интернета (куда идет маршрут default)
WAN_INTERFACE=$(ip route show default | awk '{print $5}' | head -n 1)

if [ -z "$ZT_INTERFACE" ]; then
    echo "ОШИБКА: Не удалось определить интерфейс ZeroTier."
    echo "Убедитесь, что вы авторизовали устройство в панели my.zerotier.com!"
    exit 1
fi

echo "[i] Интерфейс Интернет (WAN): $WAN_INTERFACE"
echo "[i] Интерфейс VPN (ZeroTier): $ZT_INTERFACE"

# 4. Включение IP Forwarding
echo "[+] Включаем IP Forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

# 5. Настройка iptables (NAT + Fix MSS)
echo "[+] Применяем правила iptables..."

# Очистка старых правил NAT
iptables -t nat -F
iptables -F

# NAT (Маскарадинг)
iptables -t nat -A POSTROUTING -o "$WAN_INTERFACE" -j MASQUERADE
iptables -A FORWARD -i "$ZT_INTERFACE" -o "$WAN_INTERFACE" -j ACCEPT
iptables -A FORWARD -i "$WAN_INTERFACE" -o "$ZT_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT

# !!! FIX ДЛЯ GEMINI / YOUTUBE !!!
# Корректировка размера пакета (MSS Clamping) для предотвращения зависаний
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 6. Сохранение правил (Persistence)
echo "[+] Устанавливаем iptables-persistent для сохранения правил..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install iptables-persistent -y
netfilter-persistent save

echo "=========================================="
echo "   УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "=========================================="
echo "Что нужно сделать сейчас:"
echo "1. Зайдите на https://my.zerotier.com"
echo "2. Поставьте галочку Auth напротив этого нового устройства."
echo "3. В разделе Routes добавьте маршрут: 0.0.0.0/0 через IP этого устройства (в колонке Managed IPs)."
