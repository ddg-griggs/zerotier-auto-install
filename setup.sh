#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

NETWORK_ID=$1

if [ -z "$NETWORK_ID" ]; then
  echo "Usage: ./setup.sh <NETWORK_ID>"
  exit 1
fi

echo ">>> Updating system..."
apt-get update -y
apt-get install -y curl iptables-persistent

echo ">>> Installing ZeroTier..."
curl -s https://install.zerotier.com | bash

echo ">>> Joining Network $NETWORK_ID..."
zerotier-cli join $NETWORK_ID

echo ">>> Waiting for network interface..."
# Ждем, пока появится интерфейс zt*
while ! ip link | grep -q "zt"; do
  sleep 1
done

# Получаем имя интерфейса (например, zt6jysstvs)
ZT_IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^zt' | head -1)
echo ">>> Found ZeroTier interface: $ZT_IFACE"

# === ГЛАВНОЕ ИСПРАВЛЕНИЕ ДЛЯ GEMINI/YOUTUBE ===
echo ">>> Setting MTU to 1280 for better mobile compatibility..."
ip link set dev $ZT_IFACE mtu 1280

# Добавляем автозагрузку MTU через CRON (чтобы работало после ребута)
# Удаляем старые записи, если есть, чтобы не дублировать
crontab -l 2>/dev/null | grep -v "ip link set dev $ZT_IFACE mtu 1280" > /tmp/cron_bkp
echo "@reboot /usr/sbin/ip link set dev $ZT_IFACE mtu 1280" >> /tmp/cron_bkp
crontab /tmp/cron_bkp
rm /tmp/cron_bkp
echo ">>> MTU persistence enabled."
# ===============================================

echo ">>> Enabling IP Forwarding..."
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-zerotier.conf
sysctl -p /etc/sysctl.d/99-zerotier.conf

echo ">>> Configuring IPTables..."
# Очистка старых правил для чистоты эксперимента (опционально)
# iptables -F
# iptables -t nat -F

# Основной NAT (интернет через VPN)
PHY_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
iptables -t nat -A POSTROUTING -o $PHY_IFACE -j MASQUERADE
iptables -A FORWARD -i $PHY_IFACE -o $ZT_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $ZT_IFACE -o $PHY_IFACE -j ACCEPT

# Фикс для сайтов (TCP MSS Clamping) - был в оригинале
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Сохранение правил
netfilter-persistent save

echo "=========================================="
echo "   УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "=========================================="
echo "ZeroTier успешно настроен (MTU сервера зафиксирован на 1280)."
echo "Ваш IP в сети ZeroTier: $(ip -4 addr show $ZT_IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
echo "=========================================="
echo "Что нужно сделать сейчас в панели my.zerotier.com:"
echo "1. Поставьте галочку Auth напротив этого сервера."
echo "2. В разделе Routes добавьте маршрут: 0.0.0.0/0 через IP этого сервера (в колонке Managed IPs)."
echo "3. В разделе DNS укажите:"
echo "   - Server Address: 8.8.8.8 и 1.1.1.1"
echo "   - Search Domain: local или . (точка) (если панель требует заполнения этого поля)"
echo "=========================================="
echo "На вашем ТЕЛЕФОНЕ:"
echo "1. Включите галочку 'Default Route' (Route via ZeroTier)."
echo "2. Наслаждайтесь работающим YouTube и Gemini!"
echo "=========================================="
