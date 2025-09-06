#!/bin/bash
# Workaround for NDK clang posix_spawn issue in WSL
# This script calls the linker directly

# Extract the linker command from clang arguments
ARGS=("$@")
LINKER_ARGS=()
SHARED_LIB=""
TARGET=""

for arg in "${ARGS[@]}"; do
    case "$arg" in
        -shared)
            SHARED_LIB="-shared"
            ;;
        -o)
            # Next argument will be the output file
            NEXT_IS_OUTPUT=1
            ;;
        *)
            if [[ $NEXT_IS_OUTPUT == 1 ]]; then
                OUTPUT_FILE="$arg"
                NEXT_IS_OUTPUT=0
            else
                LINKER_ARGS+=("$arg")
            fi
            ;;
    esac
done

# Use lld directly to avoid the posix_spawn issue
exec /home/jnix/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/bin/lld -flavor gnu "${LINKER_ARGS[@]}" $SHARED_LIB -o "$OUTPUT_FILE"
