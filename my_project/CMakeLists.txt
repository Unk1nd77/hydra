cmake_minimum_required(VERSION 3.5)

# Set ESP8266 specific settings
set(ESP8266 1)
set(ESP8266_RTOS 1)

# Set ESP8266 RTOS SDK path
set(ESP8266_RTOS_SDK_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../ESP8266_RTOS_SDK)
set(IDF_PATH ${ESP8266_RTOS_SDK_PATH})

include(${IDF_PATH}/tools/cmake/project.cmake)
project(hydra_l)