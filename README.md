# ELM327 Monitor (iOS, BLE) — Фаза 1 + 2 (локально)

Нативное iOS-приложение (SwiftUI + CoreBluetooth) для чтения OBD-II через ELM327 BLE-адаптер.
Первоочередной датчик — температура антифриза. Локальные уведомления без сервера.

## Сборка

1. Установите Xcode (из App Store).
2. Откройте `ELM327Monitor.xcodeproj`.
3. Выберите схему `ELM327Monitor` и устройство/симулятор.
4. Запустите (Cmd+R).

> Симулятор не поддерживает Bluetooth. Тестировать на реальном iPhone.

### Push-уведомления (настоящие, как SMS)

По умолчанию приложение шлёт **локальные** уведомления (работают офлайн).
Чтобы получать удалённые push (даже если приложение убито), нужен сервер + APNs:

1. **Apple Developer Program** ($99/год) — иначе APNs недоступен.
2. Создайте APNs Key (`.p8`) в Apple Developer → Certificates, Identifiers & Profiles → Keys → «+» → Apple Push Notifications service (APNs).
3. **Firebase** (рекомендуется) или напрямую APNs:
   - Firebase: создайте проект, скачайте `serviceAccount.json`.
   - Запустите сервер: `cd server && npm install && FIREBASE_SERVICE_ACCOUNT="$(cat serviceAccount.json)" npm run dev`
   - В приложении укажите адрес сервера в `ApiClient.baseURL` (сейчас `http://localhost:3000`; для теста на телефоне используйте IP компьютера или ngrok).
4. Добавьте Capability **Push Notifications** в Xcode (Signing & Capabilities → + Capability → Push Notifications), если приложение должно получать удалённые push-уведомления. Xcode создаст необходимые signing entitlements автоматически.
5. При первом запуске приложение зарегистрирует device token на сервере; сервер будет отправлять push при алертах.

> Без Apple Developer Program push не заработает — останутся локальные уведомления.

### Подпись (Signing) для запуска на iPhone

Xcode требует Apple ID. Один раз:

1. Xcode → **Settings…** → **Accounts** → **+** → **Apple ID** → войти.
2. В проекте: таргет **ELM327Monitor** → **Signing & Capabilities**.
3. **Team** → выбрать свой Apple ID (Personal Team).
4. **Bundle Identifier** можно оставить `com.elm327monitor.ELM327Monitor`; если Xcode ругается, добавьте в конец свои инициалы/цифры, например `com.elm327monitor.ELM327Monitor.egor`.
5. Cmd+R.

Бесплатный Apple ID: приложение работает 7 дней, потом переустановка. После первого запуска на iPhone:
**Настройки → Основные → VPN и управление устройством → Developer App → Доверять**.

Для проверки интерфейса без подписи можно собрать на симуляторе (Bluetooth там не работает):
`Product → Destination → iPhone 16` → Cmd+R.

## Использование

1. Вкладка «Устройства» → «Скан» → выберите ELM327-адаптер.
2. Вкладка «Дашборд» → «Старт мониторинга».
3. Температура антифриза отображается крупной карточкой.
4. Правила срабатывают автоматически, локальное уведомление приходит на заблокированный экран.

## Структура

- `Core/BLE` — BLE-менеджер, драйвер ELM327, декодеры PID/DTC
- `Core/Rules` — движок правил
- `Core/Notifications` — локальные уведомления + Telegram
- `Core/BLE/PIDDecoder` — 29 PID (температура ОЖ, RPM, напряжение, MAF и др.)
- `UI` — SwiftUI экраны

## Дальнейшие шаги

- Фаза 3: backend + FCM push
- Фаза 4: фоновый режим, экспорт отчётов, тесты