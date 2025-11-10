#!/bin/sh

rm -rf build

# define parameters
TARGET_WORKSPACE="$(pwd)/build" # 10 GB of free space should be sufficient, probably less
TARGET_DEBIAN_VERSION="stretch" # stretch or buster
TARGET_OPENJDK_VERSION="11" # 9, 10, 12, 13, 14 - retired, may not be working
                            # 11, 15 - most likely working
                            # loom or tip - experimental, may be broken

# clone repository
# git clone https://github.com/ev3dev-lang-java/openjdk-ev3.git
# cd openjdk-ev3

# prepare working directory
mkdir -p "$TARGET_WORKSPACE"
chmod -R 777 "$TARGET_WORKSPACE" # docker may not share UID with the current user

# build base system container
docker build --build-arg DEBIAN_RELEASE="$TARGET_DEBIAN_VERSION" \
             --build-arg ARCH="armel" \
             --tag "ev3dev-lang-java:jdk-cross-$TARGET_DEBIAN_VERSION" \
             --file ./system/Dockerfile.cross \
             ./system

# on top of that, create a build scripts container
docker build --build-arg commit="$(git rev-parse HEAD)" \
             --build-arg extra="Manual build by $(whoami)" \
             --build-arg DEBIAN_RELEASE="$TARGET_DEBIAN_VERSION" \
             --build-arg BUILD_TYPE="cross" \
             --tag "ev3dev-lang-java:jdk-cross-build" \
             ./scripts

# now run the build
docker run --rm \
           --interactive \
           --tty \
           --volume "$TARGET_WORKSPACE:/build" \
           --env JDKVER="$TARGET_OPENJDK_VERSION" \
           --env JDKVM="client" \
           --env JDKPLATFORM="ev3" \
           --env JDKDEBUG="release" \
           --env AUTOBUILD="1" \
           ev3dev-lang-java:jdk-cross-build

# finally, make workspace accessible for all users (i.e. current one too) and list files in its root
chmod -R 777 "$TARGET_WORKSPACE"
# and list the output directory (now it should contain three *-ev3.tar.gz files)
ls "$TARGET_WORKSPACE"