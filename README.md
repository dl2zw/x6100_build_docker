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
Copy the files `entrypoint.sh`, `docker-compose.yml` and `Dockerfile` (optional `.env` if you want to build with env File) from the `x6100_build_docker` directory to the previously created `xiegu` directory so that the directory tree now looks like this:
```
└── xiegu
    |──x6100_build_docker
    |──.env    (optional)
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
This **must** be set with console command:
```
export HOST_BUILD_DIR=<check-out directory>  # e.g. /home/<your-user-name>/x6100_build  -- here you will find the AetherX6100Buildroot and x6100_gui Directories after the build --
mkdir -p "$HOST_BUILD_DIR"
```
> [!NOTE]
You can also build using a [.env](https://github.com/dl2zw/x6100_build_docker/blob/main/.env) File, in that case the following `export ...` commands aren't necessary

Optional: Repos / Branches — only if you want to use different ones:
```
export GUI_BRANCH=v1.0.0                     # e.g. for a previous or own release
export IMAGE_TAG=v1.0.0                      # e.g. for a previous or own release
export BR_REPO=<your_other_repo>             # Replace <your_other_repo> with your preferred buildroot repository
export GUI_REPO=<your_other_repo>            # Replace <your_other_repo> with your preferred x6100_gui repository
```

The standard and current version is `GUI_BRANCH=v1.0.2, IMAGE_TAG=v1.0.2, BR_REPO=https://github.com/OpenX6100/AetherX6100Buildroot.git, GUI_REPO=https://github.com/OpenX6100/x6100_gui.git`.  
The `export GUI_BRANCH=xxx` and `export IMAGE_TAG=xxx` you can always change for every new build to the latest or your preferred version.  
You can also switch to another Repo for the buildroot with `export BR_REPO=<your_other_repo>` and for the gui `export GUI_REPO=<your_other_repo>` however, these should be based on the standard repos, otherwise the build might fail.

- Optional switches, if you don't enable them with =1, they are disabled by default =0:
```
export ENABLE_UBOOT=0/1      # Change the u-boot bootloader if you have a x6100 devices that won't boot or switch from the older version to the current one 
export ENABLE_MC=0/1         # Builds midnight commander
export ENABLE_PROCPS_NG=0/1  # Builds procps-ng programs and uses them instead of the busybox programs
```
Then you can check your build configuration for the right Values using `docker compose config`

> [!NOTE]
It may happen that the SD card does not boot on some x6100 devices because the bootloader u-boot is not executed.  
I have created a version that **_should_** boot on all x6100 devices, i tested it with the second and third revisions, the second revision is causing the problems.  
This can be replaced in the sdcard.img with the following console command before the build command `docker compose up`:
```
export ENABLE_UBOOT=1
```
or with `ENABLE_UBOOT=1` in the .env File

> [!NOTE]
Even if the image boots from an SD card, you can use the commands described above to update u-boot and switch from the older version (2023.01) to the current (2026.10) one.


- Build the AetherX6100Buildroot and x6100_gui with console output:
```
docker compose up
```

or build in the Background
```
docker compose up -d
```
To see the log from the Background build:
```
docker compose logs -f
```

It will take a while...

- After the build finished you should find the file `sdcard-<IMAGE_TAG>.img` and `sdcard-<IMAGE_TAG>.zip` in the directory `<HOST_BUILD_DIR>/AetherX6100Buildroot/build/images` which you can write to an SD card (e.g. under /dev/sdX)
```
sudo dd if=<HOST_BUILD_DIR>/AetherX6100Buildroot/build/images/sdcard-<IMAGE_TAG>.img of=/dev/sdX bs=8M
sync
sudo eject /dev/sdX
```
You can also use a program like Balena Etcher or something similar to write on the SD card.


## Credits

- Олег Белоусов (Oleg Belusov) R1CBU
- Георгий Дюльдин (Georgy Dyuldin) R2RFE
- and all the Contributors
