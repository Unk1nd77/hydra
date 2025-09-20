#!/bin/bash

# ESP8266 Build Script using QEMU for ARM64 compatibility
# This script uses QEMU to run x86_64 toolchain on ARM64

set -e

echo "🔧 Setting up ESP8266 build environment with QEMU..."

# Check if qemu-user-static is available
if ! command -v qemu-x86_64 &> /dev/null; then
    echo "❌ QEMU user emulation is not available."
    echo "Please install qemu-user-static:"
    echo "   sudo apt update && sudo apt install qemu-user-static binfmt-support"
    echo "   sudo systemctl restart systemd-binfmt"
    exit 1
fi

# Set up environment variables
export PATH="$HOME/.local/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
export PYTHONPATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK/tools"

# Create a wrapper script for the toolchain
mkdir -p /home/unk1nd77/hydra/toolchain_wrapper

cat > /home/unk1nd77/hydra/toolchain_wrapper/xtensa-lx106-elf-gcc << 'EOF'
#!/bin/bash
# Wrapper script to run x86_64 toolchain with QEMU

# Get the actual toolchain path
TOOLCHAIN_PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc"

# Run with QEMU x86_64 emulation
exec qemu-x86_64 -L /lib/x86_64-linux-gnu "$TOOLCHAIN_PATH" "$@"
EOF

chmod +x /home/unk1nd77/hydra/toolchain_wrapper/xtensa-lx106-elf-gcc

# Create wrapper for other tools
for tool in xtensa-lx106-elf-g++ xtensa-lx106-elf-ld xtensa-lx106-elf-objcopy xtensa-lx106-elf-objdump xtensa-lx106-elf-ar xtensa-lx106-elf-nm xtensa-lx106-elf-strip; do
    cat > "/home/unk1nd77/hydra/toolchain_wrapper/$tool" << EOF
#!/bin/bash
# Wrapper script to run x86_64 toolchain with QEMU

# Get the actual toolchain path
TOOLCHAIN_PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin/$tool"

# Run with QEMU x86_64 emulation
exec qemu-x86_64 -L /lib/x86_64-linux-gnu "\$TOOLCHAIN_PATH" "\$@"
EOF
    chmod +x "/home/unk1nd77/hydra/toolchain_wrapper/$tool"
done

# Add wrapper to PATH
export PATH="/home/unk1nd77/hydra/toolchain_wrapper:$PATH"

echo "✅ QEMU wrapper created successfully!"

# Test the toolchain
echo "🧪 Testing toolchain..."
if xtensa-lx106-elf-gcc --version; then
    echo "✅ Toolchain is working with QEMU!"
else
    echo "❌ Toolchain test failed!"
    exit 1
fi

# Navigate to project directory
cd /home/unk1nd77/hydra/my_project

echo "🔨 Building project..."

# Clean previous build
if [ -d "build" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf build
fi

# Try to build using CMake
echo "⚙️ Configuring project with CMake..."
if command -v cmake &> /dev/null; then
    mkdir -p build
    cd build
    cmake .. -DCMAKE_TOOLCHAIN_FILE=$IDF_PATH/tools/cmake/toolchain-esp8266.cmake
    make -j$(nproc)
    echo "✅ Build completed successfully!"
else
    echo "❌ CMake not found. Please install cmake:"
    echo "   sudo apt install cmake"
    exit 1
fi

echo "🎉 Build process completed!"
echo "📁 Binary files are in: /home/unk1nd77/hydra/my_project/build/"




