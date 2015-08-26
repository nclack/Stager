cmake_minimum_required(VERSION 2.8)
project(devices)
add_subdirectory(src)

set(STAGER_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
set(CMAKE_INSTALL_PREFIX ${STAGER_ROOT} CACHE PATH "Install to the stager root path" FORCE)

