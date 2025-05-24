[![Docker Build](https://github.com/kryuchenko/linux-desktop/actions/workflows/docker-build.yml/badge.svg)](https://github.com/kryuchenko/linux-desktop/actions/workflows/docker-build.yml)

# Linux Desktop with Gaming Stack

Run a hardware accelerated KDE desktop with comprehensive gaming support in a container. This is a fork of [ai-dock/linux-desktop](https://github.com/ai-dock/linux-desktop) enhanced with gaming and creative tools.

## Features

This image extends the base ai-dock/linux-desktop with:

### Gaming Components
- **Wine (Staging)** - Windows compatibility layer
- **Lutris** - Game launcher and manager
- **Proton GE 10-3** - Custom Proton build for enhanced game compatibility
- **Protontricks** - Tool for managing Proton prefixes
- **GameMode** - Automatic performance optimization for games
- **MangoHud** - Vulkan/OpenGL overlay for monitoring performance
- **Vulkan drivers** - Full 32-bit and 64-bit support

### Creative & Productivity Tools
- **LibreOffice** - Full office suite with KDE integration
- **Blender 4.2.0** - 3D creation suite
- **Krita 5.2.3** - Digital painting application
- **GIMP** - Image manipulation program
- **Inkscape** - Vector graphics editor
- **Google Chrome** - Web browser

### Custom Scripts
- `proton-run` - Easy execution of Windows .exe files
- `proton-ge` - Proton GE wrapper
- `protontricks` - Protontricks wrapper

This image is based on [Selkies Project](https://github.com/selkies-project) to provide an accelerated desktop environment for NVIDIA, AMD and Intel machines.  

Please see this [important notice](#selkies-notice) from the Selkies development team.


## Documentation

All AI-Dock containers share a common base which is designed to make running on cloud services such as [vast.ai](https://link.ai-dock.org/vast.ai) as straightforward and user friendly as possible.

Common features and options are documented in the [base wiki](https://github.com/ai-dock/base-image/wiki) but any additional features unique to this image will be detailed below.


#### Version Tags

The `:latest` tag points to `:latest-cuda`

Tags follow these patterns:

##### _CUDA_
- `:cuda-[x.x.x]{-cudnn[x]}-[base|runtime|devel]-[ubuntu-version]`

- `:latest-cuda` &rarr; `:cuda-12.1.1-cudnn8-runtime-22.04`

##### _ROCm_
- `:rocm-[x.x.x]-[core|runtime|devel]-[ubuntu-version]`

- `:latest-rocm` &rarr; `:rocm-6.0-runtime-22.04`

ROCm builds are experimental. Please give feedback.

##### _CPU (iGPU)_
- `:cpu-[ubuntu-version]`

- `:latest-cpu` &rarr; `:cpu-22.04`

Browse [here](https://github.com/kryuchenko/linux-desktop/pkgs/container/linux-desktop) for an image suitable for your target environment. 

Images are also available on Docker Hub at [kryuchenko/linux-desktop](https://hub.docker.com/r/kryuchenko/linux-desktop). 

Supported Desktop Environments: `KDE Plasma`

Supported Platforms: `NVIDIA CUDA`, `AMD ROCm`, `CPU/iGPU`


## Quick Start

### Docker Run
```bash
# For NVIDIA GPUs
docker run -it --gpus all \
  -p 6100:6100 \
  -p 1111:1111 \
  -e WEB_USER=user \
  -e WEB_PASSWORD=password \
  kryuchenko/linux-desktop:latest-cuda

# For AMD GPUs
docker run -it --device /dev/kfd --device /dev/dri \
  -p 6100:6100 \
  -p 1111:1111 \
  -e WEB_USER=user \
  -e WEB_PASSWORD=password \
  kryuchenko/linux-desktop:latest-rocm

# For CPU/iGPU
docker run -it \
  -p 6100:6100 \
  -p 1111:1111 \
  -e WEB_USER=user \
  -e WEB_PASSWORD=password \
  kryuchenko/linux-desktop:latest-cpu
```

Access the desktop at: `http://localhost:6100`

### Running Windows Games
```bash
# Inside the container, use proton-run to execute .exe files
proton-run /path/to/game.exe

# Or use Lutris GUI for game management
lutris
```

## Pre-Configured Templates

**Vast.​ai**

[linux-desktop:latest](https://link.ai-dock.org/template-vast-linux-desktop)


---

## Selkies Notice

This project has been developed and is supported in part by the National Research Platform (NRP) and the Cognitive Hardware and Software Ecosystem Community Infrastructure (CHASE-CI) at the University of California, San Diego, by funding from the National Science Foundation (NSF), with awards #1730158, #1540112, #1541349, #1826967, #2138811, #2112167, #2100237, and #2120019, as well as additional funding from community partners, infrastructure utilization from the Open Science Grid Consortium, supported by the National Science Foundation (NSF) awards #1836650 and #2030508, and infrastructure utilization from the Chameleon testbed, supported by the National Science Foundation (NSF) awards #1419152, #1743354, and #2027170. This project has also been funded by the Seok-San Yonsei Medical Scientist Training Program (MSTP) Song Yong-Sang Scholarship, College of Medicine, Yonsei University, the MD-PhD/Medical Scientist Training Program (MSTP) through the Korea Health Industry Development Institute (KHIDI), funded by the Ministry of Health & Welfare, Republic of Korea, and the Student Research Bursary of Song-dang Institute for Cancer Research, College of Medicine, Yonsei University.

---

_The author ([@robballantyne](https://github.com/robballantyne)) may be compensated if you sign up to services linked in this document. Testing multiple variants of GPU images in many different environments is both costly and time-consuming; This helps to offset costs_