#!/bin/bash
echo "Debug linker called with args: $@" >> /tmp/linker_debug.log
exec /home/jnix/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang "$@"
