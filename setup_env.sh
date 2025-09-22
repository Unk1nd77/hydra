#!/bin/bash
# Hydra-L Environment Setup

export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK_official"
export ESP8266_RTOS_SDK_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK_official"

# Активируем Python виртуальное окружение
source /home/unk1nd77/hydra/venv/bin/activate

echo "Hydra-L environment activated!"
echo "IDF_PATH: $IDF_PATH"
echo "Toolchain: $(which xtensa-lx106-elf-gcc)"
