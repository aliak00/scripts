#!/bin/bash

# This scripts takes a project name and then does the following:
#   1) Creates a directory structure that looks like
#       project-name/
#           |- src/
#           |- include/project-name
#           |- examples/
#   2) Creates one src and header file with a sample function
#   3) Creates a hello world applications in examples that uses the sample function
#   4) Creates a cmake script, and then runs it and builds the hello world app 

if [ -z "$1" ]; then
    echo "usage: $(basename "$0") <project-name>"
    exit 1
fi

PROJECT_NAME=$1

if [ -d "$PROJECT_NAME" ]; then
    echo "Directory named '$PROJECT_NAME' already exists"
    exit 1
fi

mkdir $PROJECT_NAME

BUILD_DIR=$PROJECT_NAME/build
SRC_DIR=$PROJECT_NAME/src
INCLUDE_DIR=$PROJECT_NAME/include
EXAMPLES_DIR=$PROJECT_NAME/examples
mkdir $BUILD_DIR
mkdir $SRC_DIR
mkdir $INCLUDE_DIR
mkdir $EXAMPLES_DIR
mkdir $INCLUDE_DIR/$PROJECT_NAME

cat > $SRC_DIR/lib.cpp << EOF
#include <iostream>
#include "$PROJECT_NAME/lib.hpp"
void lib() {
    std::cout << "Hello $PROJECT_NAME" << std::endl;
} 
EOF

cat > $INCLUDE_DIR/$PROJECT_NAME/lib.hpp << EOF
#ifndef ${PROJECT_NAME}_LIB_HPP
#define ${PROJECT_NAME}_LIB_HPP

void lib();

#endif
EOF

cat > $EXAMPLES_DIR/hello.cpp << EOF
#include "$PROJECT_NAME/lib.hpp"
int main(int argc, char **argv) {
  lib();
  return 0;
}
EOF

cat > $BUILD_DIR/CMakeLists.txt << EOF
cmake_minimum_required(VERSION 2.6)
project($PROJECT_NAME)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "../bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "../lib")

# Add library sources here
set(${PROJECT_NAME}_SRC_DIR ../src)
set(${PROJECT_NAME}_SRCS
    \${${PROJECT_NAME}_SRC_DIR}/lib.cpp
)
add_library($PROJECT_NAME STATIC \${${PROJECT_NAME}_SRCS})
include_directories(../include)

# Examples
set(EXAMPLES_SRC_DIR ../examples)
set(EXAMPLES_HELLO \${EXAMPLES_SRC_DIR}/hello.cpp)
add_executable(hello \${EXAMPLES_HELLO})
target_link_libraries(hello $PROJECT_NAME)

# Compiler options
add_definitions(-std=c++1y)
add_definitions(-stdlib=libc++)
EOF

cmake "$PROJECT_NAME/build/CMakeLists.txt"
make -C "$PROJECT_NAME/build"
