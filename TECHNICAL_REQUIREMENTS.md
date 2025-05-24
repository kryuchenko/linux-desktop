# Техническое задание: Расширение ai-dock/linux-desktop для запуска Windows-приложений

## Цель проекта

Расширить функциональность форка ai-dock/linux-desktop, добавив возможность запуска Windows-приложений (.exe файлов) через Proton GE с автоматической интеграцией в KDE Plasma Desktop.

## Исходные данные

- Базовый проект: https://github.com/ai-dock/linux-desktop
- Целевая ОС: Ubuntu 22.04 (контейнер Docker)
- Desktop Environment: KDE Plasma 5
- Streaming: WebRTC (selkies-gstreamer) и VNC (KasmVNC)

## Требования к реализации

### 1. Настройка GitHub репозитория

#### 1.1. Форк и настройка
```bash
# Форкнуть ai-dock/linux-desktop в свой GitHub аккаунт
# Клонировать форк локально
git clone https://github.com/YOUR_USERNAME/linux-desktop.git
cd linux-desktop
```

#### 1.2. Настройка GitHub Actions

**Переменные окружения (Settings → Secrets and variables → Actions):**

- `DOCKERHUB_USER` - имя пользователя Docker Hub
- `DOCKERHUB_TOKEN` - токен доступа Docker Hub
- `GITHUB_TOKEN` - автоматически доступен, не требует настройки

**Обновить версии actions в `.github/workflows/`:**
```yaml
# Заменить устаревшие версии:
actions/checkout@v3 → actions/checkout@v4
actions/github-script@v6 → actions/github-script@v7
docker/setup-buildx-action@v2 → docker/setup-buildx-action@v3
docker/login-action@v2 → docker/login-action@v3
docker/metadata-action@v4 → docker/metadata-action@v5
docker/build-push-action@v4 → docker/build-push-action@v5
```

### 2. Создание Gaming Layer

#### 2.1. Структура директорий
```bash
mkdir -p build/COPY_ROOT_99/opt/ai-dock/bin/build/layer99/
```

#### 2.2. Создать основной скрипт установки
Файл: `build/COPY_ROOT_99/opt/ai-dock/bin/build/layer99/init.sh`

### 3. Установка базовых компонентов

#### 3.1. Wine и базовые инструменты

```bash
# Добавить Wine репозиторий
mkdir -pm755 /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/winehq-archive.key "https://dl.winehq.org/wine-builds/winehq.key"

# Установить Wine (с fallback на системный)
apt-get install --install-recommends -y winehq-stable || \
apt-get install --install-recommends -y wine wine64 wine32:i386

# Установить Lutris
LUTRIS_VERSION="$(curl -fsSL "https://api.github.com/repos/lutris/lutris/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')"
curl -fsSL -O "https://github.com/lutris/lutris/releases/download/v${LUTRIS_VERSION}/lutris_${LUTRIS_VERSION}_all.deb"
apt-get install --no-install-recommends -y ./lutris_${LUTRIS_VERSION}_all.deb

# Установить Winetricks
curl -fsSL -o /usr/bin/winetricks "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
chmod 755 /usr/bin/winetricks
```

#### 3.2. Proton GE

```bash
# Скачать и установить Proton GE 10-3
mkdir -p /opt/proton-ge
cd /opt/proton-ge
PROTON_GE_VERSION="GE-Proton10-3"
curl -fsSL -o proton-ge.tar.gz \
  "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_GE_VERSION}/${PROTON_GE_VERSION}.tar.gz"
tar -xzf proton-ge.tar.gz
rm proton-ge.tar.gz
ln -sf /opt/proton-ge/${PROTON_GE_VERSION} /opt/proton-ge/current
```

### 4. Установка библиотек и зависимостей

#### 4.1. Мультиархитектурная поддержка
```bash
dpkg --add-architecture i386
apt-get update
```

#### 4.2. Графические библиотеки
```bash
# OpenGL (64-bit и 32-bit)
apt-get install --no-install-recommends -y \
    libgl1-mesa-dri:amd64 \
    libgl1-mesa-dri:i386 \
    libgl1-mesa-glx:amd64 \
    libgl1-mesa-glx:i386

# Vulkan
apt-get install --no-install-recommends -y \
    vulkan-tools \
    mesa-vulkan-drivers \
    libvulkan1 \
    libvulkan1:i386
```

#### 4.3. Steam (для Protontricks)
```bash
# Добавить multiverse репозиторий
add-apt-repository multiverse -y
apt-get update

# Установить Steam
apt-get install --no-install-recommends -y \
    steam-installer \
    libc6:i386
```

#### 4.4. Инструменты оптимизации
```bash
apt-get install --no-install-recommends -y \
    gamemode \        # Оптимизация производительности
    mangohud \        # Overlay мониторинга
    zenity            # GUI диалоги для Wine
```

#### 4.5. Python зависимости
```bash
# КРИТИЧНО: ограничить версию websockets для совместимости с selkies-gstreamer
export PIP_BREAK_SYSTEM_PACKAGES=1
pip3 install protontricks 'websockets<14.0'
```

### 5. Создание wrapper-скриптов

#### 5.1. Proton wrapper (`/opt/ai-dock/bin/proton-run`)
```bash
#!/bin/bash
# Wrapper для запуска .exe файлов через Proton GE
# - Автоматическое создание префиксов
# - Интеграция с GameMode
# - Поддержка относительных путей
```

#### 5.2. Protontricks wrapper (`/opt/ai-dock/bin/protontricks`)
```bash
#!/bin/bash
# Wrapper для Protontricks
# - Инициализация Steam директорий
# - Регистрация Proton GE в Steam
```

### 6. Интеграция с KDE Plasma

#### 6.1. MIME типы
Создать `/usr/share/mime/packages/proton-exe.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-ms-dos-executable">
    <glob pattern="*.exe"/>
  </mime-type>
  <!-- Другие Windows MIME типы -->
</mime-info>
```

#### 6.2. Desktop Entry
Создать `/usr/share/applications/proton-run.desktop`:
```desktop
[Desktop Entry]
Type=Application
Name=Run with Proton GE
Exec=/opt/ai-dock/bin/proton-run %f
MimeType=application/x-wine-extension-msp;application/x-msi;application/x-ms-dos-executable;
NoDisplay=true
```

#### 6.3. Ассоциации файлов
```bash
# Обновить MIME базу
update-mime-database /usr/share/mime

# Установить обработчик по умолчанию
xdg-mime default proton-run.desktop application/x-ms-dos-executable
```

#### 6.4. KDE Service Menu
Создать `/usr/share/kservices5/ServiceMenus/proton-run.desktop` для контекстного меню.

### 7. Настройка GameMode

Создать `/etc/gamemode.ini`:
```ini
[general]
renice = 10
inhibit_screensaver = 1

[gpu]
apply_gpu_optimisations = accept-responsibility
gpu_device = 0
amd_performance_level = high
nv_powermizer_mode = 1
```

### 8. Исправления для корректной работы

#### 8.1. Переход на root-режим
Изменить все supervisor конфиги:
```ini
# Было:
user=$USER_NAME
environment=HOME=/home/$USER_NAME

# Стало:
user=root
environment=HOME=/root
```

#### 8.2. Исправление путей GameMode
```bash
# GameMode устанавливается в /usr/games
if [ -f /usr/games/gamemoderun ]; then
    ln -sf /usr/games/gamemoderun /usr/local/bin/gamemoderun
fi
```

#### 8.3. Создание необходимых файлов KDE
```bash
mkdir -p /root/.config
touch /root/.config/startplasma-x11rc
echo "[General]" > /root/.config/kdeglobals
```

### 9. Добавление креативных приложений

```bash
# Графические редакторы
apt-get install --no-install-recommends -y gimp inkscape

# Blender
cd /opt
wget https://ftp.halifax.rwth-aachen.de/blender/release/Blender4.2/blender-4.2.0-linux-x64.tar.xz
tar xvf blender-4.2.0-linux-x64.tar.xz
ln -s /opt/blender-4.2.0-linux-x64/blender /opt/ai-dock/bin/blender

# Krita (AppImage)
mkdir -p /opt/krita
wget -O /opt/krita/krita.appimage https://download.kde.org/stable/krita/5.2.3/krita-5.2.3-x86_64.appimage
chmod +x /opt/krita/krita.appimage
/opt/krita/krita.appimage --appimage-extract

# LibreOffice с KDE интеграцией
apt-get install --install-recommends -y \
    libreoffice \
    libreoffice-kf5 \
    libreoffice-plasma
```

### 10. Тестирование

#### 10.1. Добавить тестовое приложение
```bash
# DirectX Args Debugger для проверки
mkdir -p /root/Desktop
cd /root/Desktop
wget https://github.com/kryuchenko/directx-args-debugger/raw/main/build/directx-args-debugger.exe
chmod +x directx-args-debugger.exe

# Создать desktop файл
cat > /root/Desktop/directx-debugger.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=DirectX Args Debugger
Exec=/opt/ai-dock/bin/proton-run /root/Desktop/directx-args-debugger.exe
Icon=wine
Terminal=true
EOF
```

#### 10.2. Пометить как доверенные
```bash
gio set /root/Desktop/directx-debugger.desktop metadata::trusted true
gio set /root/Desktop/directx-args-debugger.exe metadata::trusted true
```

### 11. Финальные шаги

#### 11.1. Обновить Dockerfile
Добавить в конец:
```dockerfile
# Gaming and creative tools layer
COPY --chown=0:0 ./COPY_ROOT_99/ /
RUN /opt/ai-dock/bin/build/layer99/init.sh
```

#### 11.2. Создать вспомогательные файлы
- `/opt/ai-dock/etc/environment.sh` - переменные окружения
- `/opt/ai-dock/bin/venv-set.sh` - заглушка для venv
- `/opt/ai-dock/bin/debug-display.sh` - диагностика дисплея

#### 11.3. Пересобрать образ
```bash
docker build -t your-username/linux-desktop-gaming:latest .
```

## Критические моменты

1. **Версия websockets** - ОБЯЗАТЕЛЬНО `<14.0` для совместимости с selkies-gstreamer
2. **Права доступа** - все файлы должны быть доступны root
3. **32-битные библиотеки** - необходимы для многих Windows-приложений
4. **PATH** - добавить `/usr/games` для GameMode

## Результат

После выполнения всех шагов:
- Двойной клик на .exe файл запустит его через Proton GE
- Правый клик покажет "Run with Proton" в контекстном меню
- Protontricks позволит настраивать префиксы
- GameMode автоматически оптимизирует производительность
- Все креативные приложения доступны из меню KDE