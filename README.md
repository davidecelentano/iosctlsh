# `iOS Control` - Manage iOS devices on Linux via USB

*A Linux-based command-line utility for managing iOS devices, including backups, restores, updates, and more.*

### Disclaimer

This project is an independent, open-source tool and is **not affiliated with, endorsed by, or sponsored by Apple Inc.** iOS, iPhone, and other related trademarks are the property of Apple Inc. This tool is provided as-is for managing iOS devices on Linux systems.

---

## Table of Contents

* [About the Project](#about-the-project)

  * [Features](#features)
  * [Device Compatibility](#device-compatibility)
  * [Built With](#built-with)
* [Getting Started](#getting-started)

  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Overview](#overview)
* [License](#license)

---

## About the Project

`iosctlsh` is a Linux-based command-line utility designed to manage iOS devices effortlessly. From performing software updates to creating backups, restoring encrypted backups, and enabling developer mode, this tool simplifies complex iOS management tasks for Linux users.

### Features

* Perform **iOS software updates** and **factory restores** using signed firmware downloaded from [ipsw.me](https://ipsw.me).
* Support firmware restores on both **Image4** and legacy **IMG3** devices.
* Create **full backups** or **delta (incremental) backups**.
* **Restore backups** from other iOS devices or encrypted backups.
* Enable **Developer Mode** for advanced debugging and development tools.
* Enter or exit **Recovery Mode**.
* Retrieve detailed **device information**, including model information and backup encryption status.

### Device Compatibility

Firmware updates and factory restores support both modern Image4 devices and older devices using the IMG3 firmware format.

`iosctlsh` automatically selects the appropriate restore backend:

* **Image4 devices** use `pymobiledevice3`.
* **IMG3 devices** use the bundled static `idevicerestore` binary.
* If the device capability cannot be determined, `pymobiledevice3` is attempted first.

The bundled `idevicerestore` binaries support:

* **Linux x86_64 / AMD64**
* **Linux AArch64 / ARM64**

Backup and backup restore operations are separate from firmware restores and are not affected by the Image4 or IMG3 format.

---

### Built With

* [Bash](https://www.gnu.org/software/bash/) - Shell scripting language.
* [pymobiledevice3](https://github.com/doronz88/pymobiledevice3) - Python library for managing iOS devices.
* [idevicerestore](https://github.com/libimobiledevice/idevicerestore) - Firmware update and restore utility.
* [jq](https://jqlang.github.io/jq/) - Command-line JSON processor.

---

## Getting Started

To set up `iosctlsh` on your Linux system, follow these steps.

### Prerequisites

Ensure you have the following dependencies installed. Package names may vary by distribution:

* **usbmuxd**
* **libusb**
* **python3**
* **python3-devel**
* **python3-venv**
* **jq**
* **ca-certificates**

`usbmuxd` must be installed and available as a system service.

For Debian-based distributions, if the `python` command is not available, install:

```bash
sudo apt install python-is-python3
```

Alternatively, create a symbolic link to Python 3:

```bash
sudo ln -s /usr/bin/python3 /usr/local/bin/python
```

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/davidecelentano/iosctlsh.git
   ```

2. Navigate to the project directory:

   ```bash
   cd iosctlsh
   ```

3. Make the script and bundled binaries executable:

   ```bash
   chmod +x iosctl.sh
   chmod +x bin/linux-x86_64/idevicerestore
   chmod +x bin/linux-aarch64/idevicerestore
   ```

4. Run the script:

   ```bash
   ./iosctl.sh
   ```

### Overview

![Screenshot From 2025-01-22 23-19-02](https://github.com/user-attachments/assets/439a51e0-84a2-406b-854d-674560da2dce)

### License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
