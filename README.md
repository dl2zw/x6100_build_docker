# x6100_build_docker

Build R1CBU/R2RFE alternative firmware for X6100 Xiegu transceiver with docker

Compiling no longer works with some newer Linux distributions, but a docker container can be used instead.

## How to use

- Install [docker](https://www.docker.com/)
- Create a new subdirectory in your home directory e.g. `xiegu` and change to it.
- Create a new subdirectory `x6100`
- Clone this repository
```
git clone https://github.com/dl2zw/x6100_build_docker.git
```
Copy the two files `docker-compose.yml` and `Dockerfile` from the `x6100_build_docker` directory to the previously created `xiegu` directory so that the directory tree now looks like this:
```
└── xiegu
    └──x6100
    |──x6100_build_docker
    |──Dockerfile
    |──docker-compose.yml
```

- Run the following console command:
```
docker compose up -d
```
Now the docker container will be created.
- When the process is complete run the following console command:
```
docker exec -it ubuntu-x6100 bash
```
This will switch to the container, and you should now see a prompt similar to:  
`x6100@248e6ab21602:~/build$`

- Clone the x6100 buildroot repository:
```
git clone --recurse-submodules https://github.com/gdyuldin/AetherX6100Buildroot.git
```
- Now you need to make one change to create the latest version of the R1CBU/R2RFE firmware, currently `V0.32.2` (ugly workaround..).
```
sed -i "s,^X6100_GUI_VERSION = v0.23.0-rc.3,X6100_GUI_VERSION = v0.32.2,g" AetherX6100Buildroot/br2_external/package/x6100-gui/x6100_gui.mk
```
> [!NOTE]
For future versions, you will need to adjust the command instead of  
_sed -i "s,^X6100_GUI_VERSION = v0.23.0-rc.3,X6100_GUI_VERSION = `v0.32.2`,g" AetherX6100Buildroot/br2_external/package/x6100-gui/x6100_gui.mk_  
use  
_sed -i "s,^X6100_GUI_VERSION = v0.23.0-rc.3,X6100_GUI_VERSION = `v0.33.0`,g" AetherX6100Buildroot/br2_external/package/x6100-gui/x6100_gui.mk_  
e.g. for Version 0.33.0

- Change to the buildroot directory:
```
cd AetherX6100Buildroot
```
- Run the following console command:
```
./br_config.sh
```
- Change to the build directory:
```
cd build
```
- Run the following console command:
```
make lame mpg123
```
It will take a while...
- When compilation is complete run the following console command:
```
make libsndfile-dirclean
```
- Run the following console command:
```
make
```
It will take a while...

> [!IMPORTANT]
When compilation is complete you need to revert the change to create the latest version of the R1CBU/R2RFE firmware (ugly workaround..)
```
cd ../..
sed -i "s,^X6100_GUI_VERSION = v0.32.2,X6100_GUI_VERSION = v0.23.0-rc.3,g" AetherX6100Buildroot/br2_external/package/x6100-gui/x6100_gui.mk
```

- Then change back to your `xiegu` directory:
```
exit
```

- You should find the file `sdcard.img` in the directory `x6100/AetherX6100Buildroot/build/images` which you can then copy to an SD card (under /dev/sdX) e.g.
```
sudo dd if=x6100/AetherX6100Buildroot/build/images/sdcard.img of=/dev/sdX bs=8M
sudo eject /dev/sdX
```

> [!NOTE]
It may happen that the SD card does not boot on newer x6100 devices because the bootloader u-boot is not executed. I have created a version that **_should_** boot on all x6100 devices.  
This can be replaced with the following console command:
```
dd if=x6100_build_docker/u-boot.bin of=x6100/AetherX6100Buildroot/build/images/sdcard.img seek=8K bs=1 conv=notrunc
```

## Credits

- Олег Белоусов (Oleg Belusov) R1CBU
- Георгий Дюльдин (Georgy Dyuldin) R2RFE
