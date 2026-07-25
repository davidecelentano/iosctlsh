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

* Perform **iOS software updates** and **restores** using signed firmwares downloaded from [ipsw.me](https://ipsw.me).
* Create **full backups** or **delta (incremental) backups**.
* **Restore backups** from other iOS devices or encrypted backups.
* Enable **Developer Mode** for advanced debugging and development tools.
* Exit or enter **Recovery Mode**.
* Retrieve detailed **device diagnostics**, including model information and encryption backup status.

### Device Compatibility

Firmware updates and factory restores rely on the Image4 restore implementation provided by `pymobiledevice3`.

These operations are generally supported on:

* **iPhone 5s** and later.
* **iPad Air** and later.
* **iPad mini 2** and later.
* **iPod touch 6th generation** and later.

Older 32-bit devices using the IMG3 firmware format are not supported for firmware update or factory restore and may return:

```text
NotImplementedError: is_image4_supported is False
```

Backup and backup restore operations are separate from firmware restores and are not affected by this Image4 limitation.

---

### Built With

* [Bash](https://www.gnu.org/software/bash/) - Shell scripting language.
* [pymobiledevice3](https://github.com/doronz88/pymobiledevice3) - A Python library for managing iOS devices.
* [jq](https://stedolan.github.io/jq/) - Command-line JSON processor.

---

## Getting Started

To set up `iosctlsh` on your Linux system, follow these steps.

### Prerequisites

Ensure you have the following dependencies installed (package names may vary by distro):

* **usbmuxd**
* **libusb**
* **python3**
* **python3-devel**
* **python3-venv**
* **jq**
* **ca-certificates**

For Debian-based distros if python is not recognized, create a symbolic link to python3:

`sudo ln -s /usr/bin/python3 /usr/bin/python`

### Installation

1. Clone the repository: `git clone https://github.com/davidecelentano/iosctlsh.git`

2. Navigate to the project directory: `cd iosctlsh`

3. Make the script executable: `chmod +x iosctl.sh`

4. Run the script: `./iosctl.sh`

### Overview

![Screenshot From 2025-01-22 23-19-02](https://github.com/user-attachments/assets/439a51e0-84a2-406b-854d-674560da2dce)

### License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
