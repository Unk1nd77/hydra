#!/bin/bash

echo "🚀 Настройка проекта ESP8266..."

# Проверяем, что мы в правильной директории
if [ ! -d "ESP8266_RTOS_SDK" ]; then
    echo "❌ Ошибка: ESP8266_RTOS_SDK не найден. Запустите скрипт из корня проекта."
    exit 1
fi

# Настраиваем ESP8266_RTOS_SDK
echo "📦 Настройка ESP8266_RTOS_SDK..."
cd ESP8266_RTOS_SDK
if [ -f "install.sh" ]; then
    ./install.sh
fi
if [ -f "export.sh" ]; then
    source export.sh
fi
cd ..

# Настраиваем my_project
echo "🔧 Настройка my_project..."
if [ -d "my_project" ]; then
    cd my_project
    if [ -f "Makefile" ]; then
        echo "✅ my_project готов к использованию"
    fi
    cd ..
fi

# Настраиваем my_project_fixed
echo "🔧 Настройка my_project_fixed..."
if [ -d "my_project_fixed" ]; then
    cd my_project_fixed
    if [ -f "setup.sh" ]; then
        ./setup.sh
    fi
    cd ..
fi

echo "✅ Настройка завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Перейдите в папку вашего проекта: cd my_project или cd my_project_fixed"
echo "2. Настройте конфигурацию: make menuconfig"
echo "3. Соберите проект: make"
echo "4. Загрузите на устройство: make flash"
echo ""
echo "📖 Подробная инструкция в файле DEVELOPMENT_SETUP.md"
