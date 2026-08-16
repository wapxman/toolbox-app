# Taketool — публикация в Google Play (шпаргалка)

Обновлено 16.08.2026. Тексты карточки — в `store_listing_ru.md`.

## Артефакты
| Что | Где |
|---|---|
| AAB (релиз, подписан upload-ключом) | `build/app/outputs/bundle/release/app-release.aab` (сборка: `flutter build appbundle --release`, JDK 17 `C:\Java\jdk-17`) |
| Иконка 512×512 | `assets/images/play_store_512.png` |
| Feature graphic 1024×500 | `assets/branding/feature_1024x500.png` (генератор `make_feature.py`) |
| Скриншоты телефона 1080×2400 (8 шт.) | `shots/01_map.png … 08_search.png` |
| Upload keystore | `android/upload-keystore.jks` + `android/key.properties` (НЕ в git). SHA-256 upload-сертификата: `B1:67:1F:1A:E2:73:B2:2E:95:F0:E9:7C:33:6C:14:30:54:80:DE:46:48:56:71:29:D6:81:5F:06:59:0F:56:29`. **Сделать резервную копию keystore вне ПК!** |

## Идентификаторы
- Package name: **`uz.taketool.app`** (совпадает с iOS bundle id). Менять после публикации нельзя.
- Версия: `pubspec.yaml` `version: 1.0.5+6` → versionName 1.0.5, versionCode 6. Каждый новый AAB — +1 к versionCode.
- minSdk 26, targetSdk/compileSdk 36 (требование Play с 31.08.2026).

## Публичные страницы (уже задеплоены, проект Vercel `tools24`)
- Политика конфиденциальности: https://www.taketool.uz/privacy.html
- Пользовательское соглашение: https://www.taketool.uz/terms.html
- Удаление аккаунта: https://www.taketool.uz/delete-account.html
- Сайт: https://taketool.uz
- Исходники: `Desktop\GitHub\taketool-landing` → `npx vercel --prod`

## Доступ для ревьюеров (App access → «Всё или часть функций ограничены»)
Вход по SMS. Тестовый аккаунт (SMS не отправляется, код фиксированный, env `REVIEW_ACCOUNTS` на Vercel):
- Телефон: **+998 90 000 00 01** (в приложении вводится `900000001` после `+998`)
- Код: **1234**
Инструкция для Google (EN): *Login: tap "Начать" → "Уже есть аккаунт? Войти" (or register) → enter phone 900000001 → tap "Получить код" → enter code 1234. Payments require a real Uzbek card and are not needed to review the app.*

## Data safety (Безопасность данных) — ответы
Собираем и передаём (по HTTPS, шифруется при передаче; пользователь может запросить удаление — да, через приложение/сайт):
| Тип | Собирается | Передаётся | Цель | Обязательно |
|---|---|---|---|---|
| Personal info → Phone number | да | нет | Управление аккаунтом, работа приложения (вход по SMS) | да |
| Personal info → Name | да | нет | Управление аккаунтом | нет (опционально) |
| Financial info → Purchase history | да | нет | Работа приложения (история аренд/платежей) | да (создаётся при аренде) |
| App activity → Other user-generated content | нет | | | |
| App info & performance → Crash logs / Diagnostics | нет (Firebase/Crashlytics не подключены) | | | |
| Device or other IDs | нет | | | |
| Location | **нет** (разрешения геолокации из манифеста удалены) | | | |
| Photos/Camera | камера используется только для сканирования QR в реальном времени, изображения не собираются → «не собирается» | | | |
Платёжные данные (карта) обрабатываются Payme/Click в их приложениях/страницах — мы не собираем.
Практики безопасности: данные шифруются при передаче — да; пользователь может запросить удаление — да; независимый аудит — нет.

## Content rating (IARC)
Категория: Utility/Productivity/Communication/Other. Все ответы «Нет» (нет насилия, секса, наркотиков, азартных игр, UGC-обмена, покупок цифрового контента). Оплата — реальные услуги (аренда), не in-app purchases. Ожидаемый рейтинг: 3+ / Everyone.

## Остальные декларации
- Категория приложения: **Инструменты (Tools)** или «Покупки»; тип — Приложение, бесплатное.
- Реклама: нет. Целевая аудитория: 18+ (только взрослые). Не предназначено для детей.
- Приложение для новостей: нет. COVID: нет. Финансовые функции: нет (не кошелёк/не кредит; оплата через внешние Payme/Click). Government app: нет. Health: нет.
- Разрешения, требующие декларации: нет (нет SMS/Call log/фоновой геолокации/AllFiles). Камера — обычная.
- Deep link `taketool://payment` — custom scheme, верификация App Links не нужна.
- Контакты в карточке: e-mail **support@taketool.uz** (⚠️ ящик должен реально существовать — сейчас MX-записей на taketool.uz нет), тел. +998 93 523 60 60, сайт https://taketool.uz.

## Порядок в Play Console (новое приложение)
1. Create app → название «Taketool: аренда инструмента», язык по умолчанию ru-RU, App, Free.
2. Set up your app: Privacy policy URL, App access (тест-аккаунт выше), Ads (нет), Content rating, Target audience (18+), News (нет), Data safety, Government apps (нет), Financial features (нет), Health (нет), App category + contacts.
3. Main store listing: тексты из `store_listing_ru.md`, иконка 512, feature graphic, 8 скриншотов.
4. Testing → Internal testing → Create release → загрузить AAB (Play App Signing — принять, Google хранит app signing key, наш ключ = upload key) → Release notes → Rollout. Добавить тестировщиков (e-mail список).
5. Production → Create release → тот же AAB → Countries: Uzbekistan (+ по желанию) → Send for review.
   ⚠️ Если аккаунт разработчика **личный и создан после 13.11.2023** — перед Production обязателен closed test с 12 тестировщиками 14 дней подряд. Аккаунт организации — без этого ограничения.
