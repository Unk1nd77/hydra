#!/bin/bash

# Hydra-L Build Script
set -e

# Активируем окружение
source /home/unk1nd77/hydra/setup_env.sh

# Переходим в директорию проекта
cd /home/unk1nd77/hydra/my_project

echo "Building Hydra-L project..."

# Очищаем предыдущую сборку
idf.py fullclean

# Конфигурируем проект
idf.py menuconfig

# Собираем проект
idf.py build

echo "Build completed successfully!"
echo "Firmware: build/hydra-l.bin"
