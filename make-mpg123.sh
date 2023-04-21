#!/bin/sh
set -e

# Clean
version=1.31.3
if [ -d ./mpg123 ]; then
    rm -rf mpg123
fi

# Download source
if [ ! -f mpg123-$version.tar.bz2 ]; then
    wget https://sourceforge.net/projects/mpg123/files/mpg123/$version/mpg123-$version.tar.bz2
fi

# Unpack
tar -xf mpg123-$version.tar.bz2 > /dev/null
mv mpg123-$version mpg123


# Configure NDK.
if [ -z $NDK ]; then
    echo "Please set NDK path variable." && exit 1
fi
if [ -z $ABI ]; then
    echo "Running adb to determine target ABI..."
    ABI=`adb shell uname -m`
    echo $ABI
fi
case $ABI in
    arm64) TARGET=aarch64-linux-android
           ABI=arm64-v8a ;;
    arm64-v8a) TARGET=aarch64-linux-android ;;
    aarch64) TARGET=aarch64-linux-android
             ABI=arm64-v8a ;;
    arm) TARGET=armv7a-linux-androideabi
         ABI=armeabi-v7a ;;
    armeabi-v7a) TARGET=armv7a-linux-androideabi ;;
    x86) TARGET=i686-linux-android ;;
    x86-64) TARGET=x86_64-linux-android
            ABI=x86_64 ;;
    x86_64) TARGET=x86_64-linux-android ;;
    all)
        ABI=arm64  ./make-mpg123.sh
        ABI=arm    ./make-mpg123.sh
        ABI=x86    ./make-mpg123.sh
        ABI=x86-64 ./make-mpg123.sh
        echo "Done."
        exit 0 ;;
    *) echo "Unsupported CPU ABI" && exit 1 ;;
esac

if [ -z $API ]; then
    echo "Android API not set. Using 21 by default."
    API=21
fi

# NDK boilerplate
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld.lld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

(
cd mpg123 ;
./configure --host $TARGET
make src/libmpg123/libmpg123.la
make src/libsyn123/libsyn123.la
make src/libout123/libout123.la
)

# Copy shared library
mkdir -p lib/$ABI
cp mpg123/src/libmpg123/.libs/libmpg123.so lib/$ABI/
cp mpg123/src/libsyn123/.libs/libsyn123.so lib/$ABI/
cp mpg123/src/libout123/.libs/libout123.so lib/$ABI/
# ...and headers
# no headers
