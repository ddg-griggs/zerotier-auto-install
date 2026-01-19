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
```
```bash
curl -s https://raw.githubusercontent.com/ddg-griggs/zerotier-auto-install/main/setup.sh | sudo bash -s [ВАШ_NETWORK_ID]
```
#Пример:
```bash
curl -s [https://raw.githubusercontent.com/ddg-griggs/zerotier-auto-install/main/setup.sh](https://raw.githubusercontent.com/ddg-griggs/zerotier-auto-install/main/setup.sh) | sudo bash -s a1a2a3a4a5a6a7
```
##Что сделать после установки
1. Перейдите в панель управления https://my.zerotier.com/.
2. Найдите новое устройство в списке Members и поставьте галочку Auth (Авторизовать).
3. Прокрутите вверх до раздела Routes (Маршруты) и добавьте маршрут для выхода в интернет:
   * Destination: `0.0.0.0/0`
   * Via: `IP-адрес этого устройства` (возьмите IP из колонки Managed IPs в списке устройств).

##Решение проблем
Если интернет работает, но YouTube или Gemini "висят":

1. Убедитесь, что скрипт отработал без ошибок.
2. Попробуйте перезапустить скрипт еще раз.
