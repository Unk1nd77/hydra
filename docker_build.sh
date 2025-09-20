#!/bin/bash

# ESP8266 Build Script using Docker for ARM64 compatibility
# This script creates a Docker container with x86_64 emulation to build ESP8266 projects

set -e

echo "🐳 Setting up ESP8266 build environment with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   sudo apt update && sudo apt install docker.io"
    echo "   sudo usermod -aG docker $USER"
    echo "   # Then logout and login again"
    exit 1
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo "❌ User is not in docker group. Please run:"
    echo "   sudo usermod -aG docker $USER"
    echo "   # Then logout and login again"
    exit 1
fi

# Create Dockerfile for ESP8266 build environment
cat > Dockerfile << 'EOF'
FROM --platform=linux/amd64 ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    wget \
    flex \
    bison \
    gperf \
    python3 \
    python3-pip \
    python3-setuptools \
    cmake \
    ninja-build \
    ccache \
    libffi-dev \
    libssl-dev \
    dfu-util \
    libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Set working directory
WORKDIR /workspace

# Copy ESP8266 RTOS SDK
COPY ESP8266_RTOS_SDK /workspace/ESP8266_RTOS_SDK

# Set environment variables
ENV IDF_PATH=/workspace/ESP8266_RTOS_SDK
ENV PATH=$IDF_PATH/tools:$PATH

# Install ESP-IDF tools
RUN cd $IDF_PATH && ./install.sh

# Source the environment
RUN echo "source $IDF_PATH/export.sh" >> /root/.bashrc

# Default command
CMD ["/bin/bash"]
EOF

echo "📦 Building Docker image..."

# Build the Docker image
docker build -t esp8266-build .

echo "✅ Docker image built successfully!"

# Create a build script that runs inside the container
cat > build_in_docker.sh << 'EOF'
#!/bin/bash

# Build script that runs inside Docker container
set -e

echo "🔨 Building ESP8266 project..."

# Source the ESP-IDF environment
source $IDF_PATH/export.sh

# Navigate to project directory
cd /workspace/my_project

# Clean previous build
if [ -d "build" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf build
fi

# Configure project
echo "⚙️ Configuring project..."
idf.py reconfigure

# Build project
echo "🔨 Building project..."
idf.py build

echo "✅ Build completed successfully!"
echo "📁 Binary files are in: /workspace/my_project/build/"
EOF

chmod +x build_in_docker.sh

echo "🚀 Starting build process..."

# Run the build in Docker container
docker run --rm -it \
    -v $(pwd):/workspace \
    -w /workspace \
    esp8266-build \
    /workspace/build_in_docker.sh

echo "🎉 Build process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Flash the firmware: docker run --rm -it -v $(pwd):/workspace -w /workspace esp8266-build idf.py -p /dev/ttyUSB0 flash"
echo "2. Monitor the device: docker run --rm -it -v $(pwd):/workspace -w /workspace esp8266-build idf.py -p /dev/ttyUSB0 monitor"
echo ""
echo "💡 To enter the container for manual work:"
echo "   docker run --rm -it -v $(pwd):/workspace -w /workspace esp8266-build /bin/bash"


