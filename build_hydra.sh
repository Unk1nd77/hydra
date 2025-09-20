#!/bin/bash

# Universal ESP8266 Build Script for Hydra Project
# Tries multiple methods to build the project on different architectures

set -e

echo "🚀 Hydra ESP8266 Build Script"
echo "=============================="

# Detect architecture
ARCH=$(uname -m)
echo "🏗️  Detected architecture: $ARCH"

# Set up basic environment
export PATH="$HOME/.local/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PYTHONPATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK/tools"

# Function to test toolchain
test_toolchain() {
    echo "🧪 Testing toolchain..."
    if xtensa-lx106-elf-gcc --version &> /dev/null; then
        echo "✅ Toolchain is working!"
        return 0
    else
        echo "❌ Toolchain test failed!"
        return 1
    fi
}

# Function to build with native toolchain
build_native() {
    echo "🔨 Building with native toolchain..."
    
    # Set up toolchain path
    export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
    
    if test_toolchain; then
        cd /home/unk1nd77/hydra/my_project
        if [ -d "build" ]; then
            rm -rf build
        fi
        
        # Try CMake build
        if command -v cmake &> /dev/null; then
            mkdir -p build
            cd build
            cmake .. -DCMAKE_TOOLCHAIN_FILE=$IDF_PATH/tools/cmake/toolchain-esp8266.cmake
            make -j$(nproc)
            echo "✅ Native build completed!"
            return 0
        else
            echo "❌ CMake not found!"
            return 1
        fi
    else
        return 1
    fi
}

# Function to build with QEMU emulation
build_qemu() {
    echo "🔨 Building with QEMU emulation..."
    
    # Check if QEMU is available
    if ! command -v qemu-x86_64 &> /dev/null; then
        echo "❌ QEMU not available. Please install:"
        echo "   sudo apt install qemu-user-static binfmt-support"
        return 1
    fi
    
    # Create QEMU wrapper if it doesn't exist
    if [ ! -f "/home/unk1nd77/hydra/toolchain_wrapper/xtensa-lx106-elf-gcc" ]; then
        echo "🔧 Creating QEMU wrapper..."
        mkdir -p /home/unk1nd77/hydra/toolchain_wrapper
        
        cat > /home/unk1nd77/hydra/toolchain_wrapper/xtensa-lx106-elf-gcc << 'EOF'
#!/bin/bash
exec qemu-x86_64 -L /lib/x86_64-linux-gnu /home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc "$@"
EOF
        chmod +x /home/unk1nd77/hydra/toolchain_wrapper/xtensa-lx106-elf-gcc
        
        # Create wrappers for other tools
        for tool in xtensa-lx106-elf-g++ xtensa-lx106-elf-ld xtensa-lx106-elf-objcopy xtensa-lx106-elf-objdump xtensa-lx106-elf-ar xtensa-lx106-elf-nm xtensa-lx106-elf-strip; do
            cat > "/home/unk1nd77/hydra/toolchain_wrapper/$tool" << EOF
#!/bin/bash
exec qemu-x86_64 -L /lib/x86_64-linux-gnu /home/unk1nd77/hydra/xtensa-lx106-elf/bin/$tool "\$@"
EOF
            chmod +x "/home/unk1nd77/hydra/toolchain_wrapper/$tool"
        done
    fi
    
    # Add wrapper to PATH
    export PATH="/home/unk1nd77/hydra/toolchain_wrapper:$PATH"
    
    if test_toolchain; then
        cd /home/unk1nd77/hydra/my_project
        if [ -d "build" ]; then
            rm -rf build
        fi
        
        if command -v cmake &> /dev/null; then
            mkdir -p build
            cd build
            cmake .. -DCMAKE_TOOLCHAIN_FILE=$IDF_PATH/tools/cmake/toolchain-esp8266.cmake
            make -j$(nproc)
            echo "✅ QEMU build completed!"
            return 0
        else
            echo "❌ CMake not found!"
            return 1
        fi
    else
        return 1
    fi
}

# Function to build with Docker
build_docker() {
    echo "🔨 Building with Docker..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker not available. Please install Docker first."
        return 1
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        echo "❌ User not in docker group. Please run:"
        echo "   sudo usermod -aG docker $USER"
        echo "   # Then logout and login again"
        return 1
    fi
    
    # Run the Docker build script
    if [ -f "/home/unk1nd77/hydra/docker_build.sh" ]; then
        /home/unk1nd77/hydra/docker_build.sh
        return $?
    else
        echo "❌ Docker build script not found!"
        return 1
    fi
}

# Main build logic
echo "🔍 Starting build process..."

# Try different build methods based on architecture
if [ "$ARCH" = "x86_64" ]; then
    echo "📋 x86_64 architecture detected - trying native build..."
    if build_native; then
        echo "🎉 Build successful with native toolchain!"
        exit 0
    fi
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo "📋 ARM64 architecture detected - trying multiple methods..."
    
    # Try QEMU first (faster)
    if build_qemu; then
        echo "🎉 Build successful with QEMU emulation!"
        exit 0
    fi
    
    # Try Docker as fallback
    if build_docker; then
        echo "🎉 Build successful with Docker!"
        exit 0
    fi
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

echo "❌ All build methods failed!"
echo ""
echo "💡 Troubleshooting:"
echo "1. For ARM64: Install QEMU: sudo apt install qemu-user-static binfmt-support"
echo "2. For Docker: Install Docker and add user to docker group"
echo "3. Check if ESP8266 RTOS SDK is properly installed"
echo "4. Verify toolchain files are present in xtensa-lx106-elf/bin/"

exit 1




