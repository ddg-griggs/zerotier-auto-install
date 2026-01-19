# ZeroTier VPN Auto-Installer

Автоматический скрипт для настройки Linux-сервера (VPS) в качестве VPN-шлюза через ZeroTier.

## Особенности
- Автоматическая установка ZeroTier.
- Настройка NAT (IP Masquerade).
- **Fix для Gemini/YouTube:** Включает `TCPMSS clamp`, чтобы исправить проблемы с зависанием соединения и MTU на мобильных устройствах.
- Сохранение правил iptables после перезагрузки.

## Установка (одной командой)

Зайдите на свой VPS и выполните команду, подставив свой `Network ID`:

```bash
sudo apt update && sudo apt upgrade
curl -s https://raw.githubusercontent.com/ddg-griggs/zerotier-auto-install/main/setup.sh | sudo bash -s [ВАШ_NETWORK_ID]
