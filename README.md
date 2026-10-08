# x6100_build_docker

Build R1CBU/R2RFE alternative firmware for X6100 Xiegu transceiver with docker

Compiling no longer works with some newer Linux distributions, but a docker container can be used instead.

> [!NOTE]
You'll need about 24 GB of free disk space

## How to use

- Install [docker](https://www.docker.com/)
- Create a new subdirectory in your home directory e.g. `xiegu` and change to it.
- Clone this repository
```
git clone https://github.com/dl2zw/x6100_build_docker.git
```
Copy the files `docker-compose.yml`, `docker-compose.yml` and `Dockerfile` from the `x6100_build_docker` directory to the previously created `xiegu` directory so that the directory tree now looks like this:
```
└── xiegu
    |──x6100_build_docker
    |──Dockerfile
    |──docker-compose.yml
    |──entrypoint.sh
```

- To build the docker Image run the following console command:
```
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)
docker compose build
```
Now the docker Image will be created.
The `export HOST_UID=$(id -u)` and `export HOST_GID=$(id -g)` will give you full access later to the buildroot and x6100_gui files in the check-out directory, which points to a local path that you can select in the next step

- When the process is complete run the following console commands:
```
export HOST_BUILD_DIR=<check-out directory>  # e.g. /home/<your-user-name>/x6100_build  -- here you will find the AetherX6100Buildroot and x6100_gui Directories after the build --
export GUI_BRANCH=v1.0.2                     # e.g. v1.0.2 for the latest release
export IMAGE_TAG=v1.0.2                      # e.g. v1.0.2 for the latest release
mkdir -p "$HOST_BUILD_DIR"
```
The `export GUI_BRANCH=v1.0.2` and `export IMAGE_TAG=v1.0.2` you can always change for every new build to the latest or your preferred version

- Build the AetherX6100Buildroot and x6100_gui with console output:
```
docker compose up
```

- Or build in the Background
```
docker compose up -d
```
To see the log from the Background build:
```
docker compose logs -f
```

It will take a while...

- After the build finished you should find the file `sdcard-<IMAGE_TAG>.img` and `sdcard-<IMAGE_TAG>.zip` in the directory `<HOST_BUILD_DIR>/AetherX6100Buildroot/build/images` which you can copy to an SD card (under /dev/sdX) e.g.
```
sudo dd if=<HOST_BUILD_DIR>/AetherX6100Buildroot/build/images/sdcard-<IMAGE_TAG>.img of=/dev/sdX bs=8M
sync
sudo eject /dev/sdX
```

> [!NOTE]
It may happen that the SD card does not boot on newer x6100 devices because the bootloader u-boot is not executed. I have created a version that **_should_** boot on all x6100 devices.  
This can be replaced in the sdcard.img with the following console command:
```
dd if=u-boot.bin of=<HOST_BUILD_DIR>/AetherX6100Buildroot/build/images/sdcard-<IMAGE_TAG>.img seek=8K bs=1 conv=notrunc
```
Even if the image is already on the SD card, you can replace it directly there:
```
dd if=u-boot.bin of=/dev/sdX bs=1024 seek=8
```
## Credits

- Олег Белоусов (Oleg Belusov) R1CBU
- Георгий Дюльдин (Georgy Dyuldin) R2RFE
