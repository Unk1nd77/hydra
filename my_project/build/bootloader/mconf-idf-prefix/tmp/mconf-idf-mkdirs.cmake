# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/Users/dmitriy/Downloads/esp/ESP8266_RTOS_SDK/tools/kconfig")
  file(MAKE_DIRECTORY "/Users/dmitriy/Downloads/esp/ESP8266_RTOS_SDK/tools/kconfig")
endif()
file(MAKE_DIRECTORY
  "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/kconfig_bin"
  "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix"
  "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix/tmp"
  "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix/src/mconf-idf-stamp"
  "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix/src"
  "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix/src/mconf-idf-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix/src/mconf-idf-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/Users/dmitriy/Downloads/esp/my_project/build/bootloader/mconf-idf-prefix/src/mconf-idf-stamp${cfgdir}") # cfgdir has leading slash
endif()
