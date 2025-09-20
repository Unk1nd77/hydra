# Настройка проекта для разработки

## Быстрый старт

1. **Клонируйте репозиторий:**
   ```bash
   git clone <your-repo-url>
   cd esp
   ```

2. **Настройте ESP8266_RTOS_SDK:**
   ```bash
   cd ESP8266_RTOS_SDK
   ./install.sh
   source export.sh
   cd ..
   ```

3. **Настройте ваш проект:**
   ```bash
   cd my_project
   # Настройте конфигурацию под ваши нужды
   make menuconfig
   ```

## Структура проекта

- `ESP8266_RTOS_SDK/` - ESP-IDF SDK для ESP8266
- `my_project/` - Ваш основной проект
- `my_project_fixed/` - Исправленная версия проекта
- `scripts/` - Вспомогательные скрипты

## Работа с Git

### Если вы изменили файлы в ESP8266_RTOS_SDK:
```bash
cd ESP8266_RTOS_SDK
git add .
git commit -m "Update ESP8266_RTOS_SDK"
cd ..
git add ESP8266_RTOS_SDK/
git commit -m "Update ESP8266_RTOS_SDK in main project"
git push
```

### Если вы изменили файлы в my_project:
```bash
cd my_project
git add .
git commit -m "Update my_project"
cd ..
git add my_project/
git commit -m "Update my_project in main repository"
git push
```

## Проблемы и решения

### Если Git показывает "modified content, untracked content":
Это нормально - означает, что во вложенном репозитории есть локальные изменения.

### Если нужно обновить вложенные репозитории:
```bash
cd ESP8266_RTOS_SDK
git pull origin master
cd ../my_project_fixed
git pull origin master
```

## Рекомендации

1. **Всегда делайте коммиты в вложенных репозиториях перед коммитом в основном**
2. **Используйте понятные сообщения коммитов**
3. **Перед началом работы делайте `git pull` в основном репозитории**
