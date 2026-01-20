![ZeroTier](https://img.shields.io/badge/ZeroTier-VPN-blue)
![Shell Script](https://img.shields.io/badge/Shell_Script-Bash-green)

# ZeroTier Router - Автоматическая настройка VPN маршрутизатора

Полная автоматизация настройки ZeroTier в качестве VPN-шлюза для доступа к интернету через виртуальную машину или сервер.

## Особенности
- Автоматическая установка и подключение к сети ZeroTier.
- Настройка IP-форвардинга и NAT (маскарадинг).
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
## Пример:
```bash
curl -s https://raw.githubusercontent.com/ddg-griggs/zerotier-auto-install/main/setup.sh | sudo bash -s a1a2a3a4a5a6a7
```
## Что сделать после установки
1. Перейдите в панель управления https://my.zerotier.com/.
2. Найдите новое устройство в списке Members и поставьте галочку Auth (Авторизовать).
3. Прокрутите вверх до раздела Routes (Маршруты) и добавьте маршрут для выхода в интернет:
   * Destination: `0.0.0.0/0`
   * Via: `IP-адрес этого устройства` (возьмите IP из колонки Managed IPs в списке устройств).

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

## Решение проблем
Если интернет работает, но YouTube или Gemini "висят":

1. Убедитесь, что скрипт отработал без ошибок.
2. Попробуйте перезапустить скрипт еще раз.
