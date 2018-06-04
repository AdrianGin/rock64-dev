# rock64-dev
Development for the Rock64

To remove all old images run:

docker system prune -a

docker build -f ./Dockerfile .

Ensure that images are deleted after they are used:
docker run --rm image_name





To enter Docker shell, enter:
make shell

Then get all the sources:
make sync

Configure & Build Linux:
make menuconfig
make kernel-build

Configure & Build  uboot:
make uboot-menuconfig
make uboot-build

Configure & Build the rootfs:
make root-config
make build-root

If you get a LIBTOOLIZE Version mismatch, you need to edit the version number of libtoolise
Change this in the libtoolise script in the output/host/usr/bin
scriptversion='(GNU libtool) 2.4.6'

You might get an error trying to compile openssl.
In this situation, navigate to the host-openssl directory and do a manual 

./config --prefix=/home/rock64dev/rock64-buildroot/output/host/usr --openssldir=/home/rock64dev/rock64-buildroot/output/host/etc/ssl --libdir=/lib shared zlib-dynamic

ensure zlib1g-dev is installed. (sudo apt-get install zlib1g-dev)

then rerun the buildroot.

If vboot-utils is giving you trouble with undefined references to dl_close etc,

You can either 1) remove vboot-utils from the buildroot config or
2) add -ldl to the ld flags where -lcrypto is


Create ARM Trusted firmware
make atf

Generate SD Card Image:
./make.sh

Resources on Building uboot for Rockchip:
http://opensource.rock-chips.com/wiki_U-Boot