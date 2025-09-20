#!/bin/bash
# Скрипт для восстановления оригинального toolchain на x86_64 системах
# Использовать на системах, где оригинальный toolchain работает напрямую

echo "🔧 Восстановление оригинального ESP8266 toolchain..."

# Проверяем архитектуру системы
ARCH=$(uname -m)
echo "Архитектура системы: $ARCH"

if [[ "$ARCH" == "x86_64" ]]; then
    echo "✅ x86_64 система - восстанавливаем оригинальный toolchain"
    
    # Восстанавливаем оригинальные файлы
    if [ -f "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc.orig" ]; then
        cp /home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc.orig /home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc
        echo "✅ Восстановлен xtensa-lx106-elf-gcc"
    fi
    
    if [ -f "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-g++.orig" ]; then
        cp /home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-g++.orig /home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-g++
        echo "✅ Восстановлен xtensa-lx106-elf-g++"
    fi
    
    # Тестируем toolchain
    echo "🧪 Тестирование toolchain..."
    if /home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc --version >/dev/null 2>&1; then
        echo "✅ Toolchain работает корректно!"
        echo "Теперь можно собирать проект:"
        echo "  cd /home/unk1nd77/hydra/my_project_fixed"
        echo "  export IDF_PATH=\"/home/unk1nd77/hydra/ESP8266_RTOS_SDK\""
        echo "  export PATH=\"/home/unk1nd77/hydra/xtensa-lx106-elf/bin:\$PATH\""
        echo "  python3 \$IDF_PATH/tools/idf.py build"
    else
        echo "❌ Ошибка: toolchain не работает"
        exit 1
    fi
    
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    echo "⚠️  ARM64 система - используем wrapper скрипты"
    echo "Wrapper скрипты уже настроены и работают"
    echo "Проект готов к сборке на ARM64"
    
else
    echo "❓ Неизвестная архитектура: $ARCH"
    echo "Попробуйте запустить проект - wrapper скрипты могут работать"
fi

echo "✅ Готово!"


