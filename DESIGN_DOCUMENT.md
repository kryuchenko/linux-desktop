# Дизайн-документ: Расширение ai-dock/linux-desktop для игровых и креативных задач

## Обзор проекта

Данный проект является форком [ai-dock/linux-desktop](https://github.com/ai-dock/linux-desktop) - контейнеризированного Linux-десктопа с KDE Plasma, доступного через WebRTC и VNC. Мы существенно расширили функциональность, добавив полноценную поддержку запуска Windows-приложений через Proton GE, а также набор инструментов для креативных и игровых задач.

## Архитектурные изменения

### 1. Базовая архитектура (оригинальный проект)

Оригинальный ai-dock/linux-desktop предоставляет:
- KDE Plasma Desktop в Docker-контейнере
- Доступ через WebRTC (selkies-gstreamer) и VNC (KasmVNC)
- Supervisor для управления процессами
- Базовый набор Linux-приложений

### 2. Наши расширения

#### 2.1. Gaming Layer (Layer 99)

Мы добавили новый слой сборки (`COPY_ROOT_99`), который устанавливается последним и содержит все игровые и креативные компоненты:

```
/build/COPY_ROOT_99/opt/ai-dock/bin/build/layer99/init.sh
```

Этот подход позволяет:
- Изолировать игровые компоненты от базовой системы
- Легко отключать gaming layer при необходимости
- Упрощать отладку и обновление компонентов

## Компоненты расширения

### 1. Proton GE Integration

#### 1.1. Что такое Proton GE

Proton GE (GloriousEggroll) - это кастомная версия Valve Proton с дополнительными патчами и улучшениями для запуска Windows-игр и приложений на Linux. В отличие от обычного Wine, Proton включает:

- **DXVK** - трансляция DirectX 9/10/11 в Vulkan
- **VKD3D** - трансляция DirectX 12 в Vulkan
- **FAudio** - реализация XAudio2
- **Дополнительные патчи** для совместимости с играми

#### 1.2. Установка Proton GE

```bash
# Установка Proton GE 10-3
mkdir -p /opt/proton-ge
cd /opt/proton-ge
PROTON_GE_VERSION="GE-Proton10-3"
curl -fsSL -o proton-ge.tar.gz "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_GE_VERSION}/${PROTON_GE_VERSION}.tar.gz"
tar -xzf proton-ge.tar.gz
ln -sf /opt/proton-ge/${PROTON_GE_VERSION} /opt/proton-ge/current
```

#### 1.3. Wrapper-скрипт proton-run

Мы создали универсальный wrapper для запуска .exe файлов:

```bash
/opt/ai-dock/bin/proton-run
```

Особенности:
- Автоматическое создание Wine prefix для каждого приложения
- Интеграция с GameMode для оптимизации производительности
- Поддержка относительных путей
- Сохранение состояния между запусками

### 2. Protontricks

#### 2.1. Назначение

Protontricks - это инструмент для настройки Wine prefix'ов, созданных Proton. Он позволяет:
- Устанавливать дополнительные Windows-компоненты (vcredist, dotnet и т.д.)
- Настраивать параметры Wine для конкретных приложений
- Управлять DLL overrides
- Запускать winecfg и regedit для префиксов Proton

#### 2.2. Установка и конфигурация

```bash
# Установка с ограничением версии websockets для совместимости с selkies-gstreamer
pip3 install protontricks 'websockets<14.0'
```

Критически важное исправление: версия websockets >=14.0 несовместима с selkies-gstreamer 1.6.2, что приводит к падению WebRTC-стриминга.

#### 2.3. Wrapper для Protontricks

```bash
/opt/ai-dock/bin/protontricks
```

Wrapper обеспечивает:
- Инициализацию Steam-директорий при первом запуске
- Регистрацию Proton GE в Steam compatibility tools
- Корректную работу без установленного Steam client

### 3. Steam Integration

#### 3.1. Зачем нужен Steam

Хотя основная цель - запуск произвольных .exe файлов, Steam необходим для:
- Полноценной работы Protontricks
- Управления префиксами
- Совместимости с играми, требующими Steam Runtime

#### 3.2. Установка

```bash
apt-get install --no-install-recommends -y \
    steam-installer \
    libgl1-mesa-dri:amd64 \
    libgl1-mesa-dri:i386 \
    libgl1-mesa-glx:amd64 \
    libgl1-mesa-glx:i386 \
    libc6:i386
```

### 4. Библиотеки и зависимости

#### 4.1. Графические библиотеки

**Mesa/OpenGL:**
```bash
libgl1-mesa-dri:amd64
libgl1-mesa-dri:i386
libgl1-mesa-glx:amd64
libgl1-mesa-glx:i386
```

**Vulkan:**
```bash
vulkan-tools
mesa-vulkan-drivers
libvulkan1
libvulkan1:i386
```

Двойная архитектура (amd64 + i386) необходима для запуска как 64-битных, так и 32-битных Windows-приложений.

#### 4.2. Системные библиотеки

```bash
libc6:i386         # Базовая C библиотека для 32-бит
zenity             # GUI диалоги для Wine
```

### 5. Оптимизация производительности

#### 5.1. GameMode

GameMode автоматически оптимизирует систему при запуске игр:

```ini
[general]
renice = 10                    # Повышение приоритета процесса
inhibit_screensaver = 1        # Отключение screensaver

[gpu]
apply_gpu_optimisations = accept-responsibility
gpu_device = 0
amd_performance_level = high   # Максимальная производительность AMD GPU
nv_powermizer_mode = 1         # Максимальная производительность NVIDIA GPU
```

#### 5.2. MangoHud

Overlay для мониторинга производительности в играх:
- FPS counter
- CPU/GPU загрузка
- Температуры
- Frame timing

### 6. Интеграция с рабочим столом

#### 6.1. MIME-типы и ассоциации

Регистрация .exe файлов для автоматического запуска через Proton:

```xml
<mime-type type="application/x-ms-dos-executable">
    <glob pattern="*.exe"/>
</mime-type>
```

#### 6.2. Desktop Entry

```desktop
[Desktop Entry]
Type=Application
Name=Run with Proton GE
Exec=/opt/ai-dock/bin/proton-run %f
MimeType=application/x-wine-extension-msp;application/x-msi;...
```

#### 6.3. KDE Service Menu

Контекстное меню для запуска через правый клик:

```desktop
[Desktop Action RunWithProton]
Name=Run with Proton
Icon=wine
Exec=/opt/ai-dock/bin/proton-run %f
```

### 7. Креативные приложения

Помимо игровых компонентов, добавлены профессиональные приложения:

- **Blender 4.2.0** - 3D моделирование и анимация
- **Krita 5.2.3** - растровая графика и цифровая живопись
- **GIMP** - редактирование изображений
- **Inkscape** - векторная графика
- **LibreOffice** - офисный пакет с KDE/Plasma интеграцией

### 8. Исправления и улучшения

#### 8.1. Переход на root-only режим

Оригинальный проект использовал сложную систему с переключением пользователей. Мы упростили это, переведя всё на работу от root:

- Устранены проблемы с правами доступа
- Упрощена отладка
- Улучшена совместимость с различными хостинг-платформами

#### 8.2. Исправление KDE startup

Решена проблема "Configuration file not writable":

```bash
mkdir -p /root/.config /root/.local/share /root/.cache
touch /root/.config/startplasma-x11rc
```

#### 8.3. PATH для GameMode

```bash
# GameMode устанавливается в /usr/games
ln -sf /usr/games/gamemoderun /usr/local/bin/gamemoderun
```

## Тестирование

### DirectX Args Debugger

Для тестирования интеграции добавлен DirectX Args Debugger:

```bash
/root/Desktop/directx-args-debugger.exe
```

Это простое приложение показывает:
- Корректность запуска через Proton
- Передачу аргументов командной строки
- Работу DirectX через DXVK

## Известные проблемы и решения

### 1. Websockets версия

**Проблема:** websockets >=14.0 ломает selkies-gstreamer  
**Решение:** `pip3 install 'websockets<14.0'`

### 2. GitHub Actions

**Проблема:** Устаревшие версии actions  
**Решение:** Обновлены все actions до актуальных версий

### 3. Черный экран в KDE

**Проблема:** KDE процессы запущены, но экран черный  
**Решение:** Создан environment.sh с правильными переменными окружения

## Заключение

Данное расширение превращает базовый Linux-десктоп в полноценную платформу для запуска Windows-приложений и игр через современный Proton с аппаратным ускорением. Архитектура позволяет легко добавлять новые компоненты и поддерживать совместимость с upstream-проектом.