#!/usr/bin/env bash

# iosctl.sh - A Linux-based command-line utility for managing iOS devices.
#
# Copyright (C) 2025 Davide Celentano
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

CURRENT_DIR=$(pwd)
VENV_DIR="./resources/python/pymobiledevice3"
BACKUP_BASE_DIR="$CURRENT_DIR/resources/backups"

# Function: Display header
display_header() {
    clear
    printf "\n"
    printf " _   ___  __     ___            _             _ \n"
    printf "(_) /___\\/ _\\   / __\\___  _ __ | |_ _ __ ___ | |\n"
    printf "| |//  //\\ \\   / /  / _ \\| '_ \\| __| '__/ _ \\| |\n"
    printf "| / \\_// _\\ \\ / /__| (_) | | | | |_| | | (_) | |\n"
    printf "|_\\___/  \\__/ \\____/\\___/|_| |_|\\__|_|  \\___/|_|\n"
    printf "                                                \n"
}

# Function: Initialize Usbmuxd service
init_usbmuxd() {
    echo "[+] Initializing Usbmuxd service ..."

    # Check if the usbmuxd service or socket exists (quietly)
    if systemctl list-unit-files | grep -q usbmuxd; then
        if ! systemctl restart usbmuxd; then
            printf "    [-] ERROR: Failed to restart usbmuxd service. Please check the service status.\n" >&2
            exit 1
        fi
    else
        printf "    [-] ERROR: usbmuxd is not installed on the system.\n" >&2
        exit 1
    fi
}



# Function: Initialize resources
init_resources() {
    echo '[+] Loading resources ...'

    if ! jq --version >/dev/null 2>&1; then
        printf "    [-] ERROR: jq is not installed on the system.\n" >&2
        exit 1
    fi
    
    if ! python --version >/dev/null 2>&1; then
        printf "    [-] ERROR: Python is not installed on the system.\n" >&2
        exit 1
    fi    

    # Define the required directory structure
    local resources_dir="./resources"
    local backups_dir="$resources_dir/backups"
    local python_dir="$resources_dir/python"

    # Check if the resources folder exists, if not, create it
    if [ ! -d "$resources_dir" ]; then
        mkdir -p "$resources_dir" || {
            printf "    [-] ERROR: Failed to create the '.resources/' folder.\n" >&2
            exit 1
        }
    fi

    # Check if the backups folder exists, if not, create it
    if [ ! -d "$backups_dir" ]; then
        mkdir -p "$backups_dir" || {
            printf "    [-] ERROR: Failed to create the './resources/backups/' folder.\n" >&2
            exit 1
        }
    fi

    # Check if the python folder exists, if not, create it
    if [ ! -d "$python_dir" ]; then
        mkdir -p "$python_dir" || {
            printf "    [-] ERROR: Failed to create the './resources/python' folder.\n" >&2
            exit 1
        }
    fi

}

# Function: Activate Python virtual environment
init_python_venv() {
    echo '[+] Setting up Python venv ...'
    
    # Check if the virtual environment exists
    if [ ! -d "$VENV_DIR" ]; then
        python -m venv "$VENV_DIR" || {
            printf "    [-] ERROR: Failed to create Python virtual environment.\n" >&2
            exit 1
        }
    fi

    # Activate the virtual environment
    source "$VENV_DIR/bin/activate"
    if [ -z "$VIRTUAL_ENV" ]; then
        printf "    [-] ERROR: Failed to activate Python virtual environment, delete \"%s\" and try again.\n" "$VENV_DIR" >&2
        exit 1
    fi

    # Update pymobiledevice3
    echo "   [+] Updating pymobiledevice3 ..."
    if ! python3 -m pip install -U pymobiledevice3 >/dev/null 2>&1; then
        printf "    [-] WARNING: Failed to update pymobiledevice3. Please check your network connection and ensure you have installed 'python3-devel' package.\n" >&2
    fi
}


# Function: Initialize device info
init_device_info() {
    echo "[+] Retrieving device info ..."
    echo "    [!] IMPORTANT : Device must be unlocked"
    echo "    [*] INFO : If retrieving device command hangs without any result, reboot your mobile device"
    pymobiledevice3 lockdown pair >/dev/null 2>&1

    DEVICE_NAME=$(pymobiledevice3 lockdown device-name 2>&1)
    if printf "%s" "$DEVICE_NAME" | grep -q "pymobiledevice3."; then
        echo "[-] ERROR: Device not detected. Is the device in Recovery or DFU mode?"
        echo "1. Yes"
        echo "2. No"
        echo "3. Exit"
        printf "Enter your choice: "
        read -r recovery_choice

        case $recovery_choice in
            1)
                while true; do
                    display_header
                    echo "[+] Device is in Recovery/DFU mode."
                    echo "[!] IMPORTANT: Ensure that 'libusb' package is installed on your system."
                    echo "[+] Choose one of the following actions:"
                    echo "1. Exit from Recovery"
                    echo "2. Software Update"
                    echo "3. Restore Device"
                    echo "0. Exit"
                    printf "Enter your choice: "
                    read -r mode_choice

                    case $mode_choice in
                        1)
                            echo "[+] Exiting Recovery mode ..."
                            
                            # Deactivate the virtual environment
                            deactivate 2>/dev/null || true

                            # Run the recovery exit command as sudo
                            if sudo bash -c "
                                source \"$VENV_DIR/bin/activate\" &&
                                pymobiledevice3 restore exit
                            "; then
                                echo "[+] Device successfully exited Recovery mode."
                                exit 1
                            else
                                echo "[-] ERROR: Failed to exit Recovery mode. Please check the device connection." >&2
                                exit 1
                            fi
                            ;;
                        2)
                            software_update_menu  # Reuse the software_update_menu function
                            return
                            ;;
                        3)
                            restore_device_menu   # Call the existing restore device menu function
                            return
                            ;;
                        0)
                            exit 1  # Go back to the main menu
                            ;;
                        *)
                            echo "[-] ERROR: Invalid choice. Please try again." >&2
                            ;;
                    esac
                done
                ;;
            2)
		display_header
		init_usbmuxd
		init_resources
		init_python_venv
		init_device_info
                ;;    

            3)
		echo "[+] Exiting." >&2
                exit 1
                ;;    

            *)
                echo "[-] ERROR: Invalid choice. Exiting." >&2
                exit 1
                ;;
        esac
    fi

    # Retrieve device diagnostics
    DEVICE_INFO=$(pymobiledevice3 lockdown info 2>&1)
    if printf "%s" "$DEVICE_INFO" | grep -q "pymobiledevice3."; then
        printf "[-] ERROR: %s\n" "$DEVICE_INFO" >&2
        exit 1
    fi

    # Parse device info
    PRODUCT_TYPE=$(printf "%s" "$DEVICE_INFO" | jq -r '.ProductType // "N/A"')
    PRODUCT_VERSION=$(printf "%s" "$DEVICE_INFO" | jq -r '.ProductVersion // "N/A"')
    HARDWARE_MODEL=$(printf "%s" "$DEVICE_INFO" | jq -r '.HardwareModel // "N/A"')
    PHONE_NUMBER=$(printf "%s" "$DEVICE_INFO" | jq -r '.PhoneNumber // "N/A"')
    SERIAL_NUMBER=$(printf "%s" "$DEVICE_INFO" | jq -r '.SerialNumber // "N/A"')
    UNIQUE_DEVICE_ID=$(printf "%s" "$DEVICE_INFO" | jq -r '.UniqueDeviceID // "N/A"')

    # Parse ModelNumber and RegionInfo to form MODEL_NUMBER
    MODEL_NUMBER=$(printf "%s" "$DEVICE_INFO" | jq -r '.ModelNumber // empty')
    REGION_INFO=$(printf "%s" "$DEVICE_INFO" | jq -r '.RegionInfo // empty')
    if [[ -n "$MODEL_NUMBER" && -n "$REGION_INFO" ]]; then
        MODEL_NUMBER="${MODEL_NUMBER}${REGION_INFO}"
    else
        MODEL_NUMBER="N/A"
    fi

    # Retrieve additional information
    find_latest_backup
    check_encryption_status
}


# Function: Find latest backup
find_latest_backup() {
    LAST_BACKUP_FILE=""
    LAST_BACKUP_TIME=0

    # Define the path to search for Status.plist specific to the UNIQUE_DEVICE_ID
    DEVICE_BACKUP_DIR="$BACKUP_BASE_DIR/$UNIQUE_DEVICE_ID"

    # Check if the directory for the specific device exists
    if [[ -d "$DEVICE_BACKUP_DIR" ]]; then
        # Search for the most recent Status.plist file
        while IFS= read -r -d '' status_plist_file; do
            # Get the modification time of the Status.plist file
            plist_file_date=$(stat -c %Y "$status_plist_file")
            if [[ $plist_file_date -gt $LAST_BACKUP_TIME ]]; then
                LAST_BACKUP_FILE="$status_plist_file"
                LAST_BACKUP_TIME=$plist_file_date
            fi
        done < <(find "$DEVICE_BACKUP_DIR" -type f -name "Status.plist" -print0)

        # If no Status.plist file is found, show the default message
        if [[ -z "$LAST_BACKUP_FILE" ]]; then
            LAST_BACKUP_TIME="Your device has never been backed up to this computer."
        else
            # If a Status.plist file is found, format the date
            LAST_BACKUP_TIME=$(date -d "@$LAST_BACKUP_TIME" "+%Y-%m-%d %H:%M:%S")
            LAST_BACKUP_TIME=$(printf "%s to this computer." "$LAST_BACKUP_TIME")
        fi
    else
        # If the backup directory does not exist, show the default message
        LAST_BACKUP_TIME="Your device has never been backed up to this computer."
    fi
}


# Function: Check encryption status
check_encryption_status() {
    ENCRY_STAT_OUTPUT=$(pymobiledevice3 backup2 change-password EncryptionChecker999! EncryptionChecker999! 2>&1)
    if printf "%s" "$ENCRY_STAT_OUTPUT" | grep -q "Encryption is not turned on!"; then
        ENCRY_STAT="OFF"
    else
        ENCRY_STAT="ON"
    fi
}

# Function: Display device info
display_device_info() {
    printf "\n"
    printf "############################################\n"
    printf "%s\n" "$DEVICE_NAME"
    printf "%s\n" "$PRODUCT_TYPE"
    printf "iOS %s\n" "$PRODUCT_VERSION"
    printf "\n"
    printf "Hardware Model: %s\n" "$HARDWARE_MODEL"    
    printf "Phone Number: %s\n" "$PHONE_NUMBER"
    printf "Model Number: %s\n" "$MODEL_NUMBER"
    printf "Serial Number: %s\n" "$SERIAL_NUMBER"
    printf "Unique Device ID: %s\n" "$UNIQUE_DEVICE_ID"
    printf "\n"
    printf "Latest Backup: %s\n" "$LAST_BACKUP_TIME"
    printf "Encrypt local backup: %s\n" "$ENCRY_STAT"
    printf "############################################\n"
    printf "\n"
}

# Function: Software Update menu
software_update_menu() {
    while true; do
        display_header
        echo "[+] Chosen Software Update ..."
        echo "[!] IMPORTANT: It is HIGHLY recommended to perform this operation while the device is in Recovery Mode."        
        echo "1. Perform Software Update"
        echo "2. Enter in Recovery"
        echo "0. Go Back to Main Menu"
        printf "Enter your choice: "
        read -r update_choice

        case $update_choice in
            1)
                display_header
                echo "[+] Starting Software Update ..."
                printf "[+] Download signed iOS firmware for your device from https://ipsw.me (https://ipsw.dev for Beta Releases), then paste here the full path to file:\n"
                
                # Prompt for firmware file path
                read -r fw_update_path

                # Ensure the path is not empty
                if [[ -z "$fw_update_path" ]]; then
                    echo "[-] ERROR: Firmware path cannot be empty. Please try again."
                    continue
                fi

                # Exit from the virtual environment
                deactivate 2>/dev/null || true

                # Run the command as sudo with the virtual environment reloaded
                sudo bash -c "
                    source \"$VENV_DIR/bin/activate\" &&
                    pymobiledevice3 restore update --ipsw \"$fw_update_path\"
                "

                # Notify user that the update process has completed
                echo "[+] Software update process has finished. Please check the above output for any errors."

                # Exit the script
                exit 1
                ;;
            2)
                display_header
                echo "[+] Booting into Recovery mode ..."

                # Exit from the virtual environment
                deactivate 2>/dev/null || true

                # Run the recovery enter command as sudo
                if sudo bash -c "
                    source \"$VENV_DIR/bin/activate\" &&
                    pymobiledevice3 restore enter
                "; then
                    echo "[+] Device successfully booted into Recovery mode."
                    exit 1
                else
                    echo "[-] ERROR: Failed to boot into Recovery mode. Please check the device connection." >&2
                    exit 1
                fi
                ;;
            0)
                return  # Go back to main menu
                ;;
            *)
                echo "[-] ERROR: Invalid choice. Please try again." >&2
                ;;
        esac
    done
}


# Function: Restore Device menu
restore_device_menu() {
    while true; do
        display_header
        echo "[+] Chosen Restore Device ..."
        echo "[!] IMPORTANT 1: Find My iPhone must be disabled before restoring."
        echo "[!] IMPORTANT 2: Your device will be FACTORY-RESET."
        echo "[!] IMPORTANT 3: It is HIGHLY recommended to perform this operation while the device is in Recovery Mode."
        echo "1. Perform Restore"
        echo "2. Enter in Recovery"
        echo "0. Go Back to Main Menu"
        printf "Enter your choice: "

        read -r restore_choice

        case $restore_choice in
            1)
                display_header
                echo "[+] Starting Restore Process ..."
                printf "[+] Download signed iOS firmware for your device from https://ipsw.me (https://ipsw.dev for Beta Releases), then paste here the full path to file:\n"
                
                # Prompt for firmware file path
                read -r firmware_path

                # Ensure the path is not empty
                if [[ -z "$firmware_path" ]]; then
                    echo "[-] ERROR: Firmware path cannot be empty. Please try again."
                    continue
                fi

                # Deactivate virtual environment
                deactivate 2>/dev/null || true

                # Run the restore command as sudo
                sudo bash -c "
                    source \"$VENV_DIR/bin/activate\" &&
                    pymobiledevice3 restore update --ipsw \"$firmware_path\" --erase
                "

                # Notify user of completion and exit the script
                echo "[+] Restore process has finished. Please check the above output for any errors."
                exit 1
                ;;
            2)
                display_header
                echo "[+] Booting into Recovery mode ..."

                # Deactivate virtual environment
                deactivate 2>/dev/null || true

                # Run the recovery enter command as sudo
                if sudo bash -c "
                    source \"$VENV_DIR/bin/activate\" &&
                    pymobiledevice3 restore enter
                "; then
                    echo "[+] Device successfully booted into Recovery mode."
                    exit 1
                else
                    echo "[-] ERROR: Failed to boot into Recovery mode. Please check the device connection." >&2
                    exit 1
                fi
                ;;
            0)
                return  # Go back to the main menu
                ;;
            *)
                echo "[-] ERROR: Invalid choice. Please try again." >&2
                ;;
        esac
    done
}


# Function: Encryption settings menu
encryption_settings_menu() {
    display_header
    echo "[+] Chosen Encryption Settings ..."
    printf "[+] This will allow account passwords, Health, and HomeKit data to be backed up.\n\n"

    if [[ "$ENCRY_STAT" == "OFF" ]]; then
        echo "Encryption is currently OFF. Please choose an option:"
        echo "1. Enable Encryption"
        echo "0. Go Back to Main Menu"
        printf "Enter your choice: "
        read -r enc_choice

        case $enc_choice in
            1)
                display_header
                echo "[+] Enabling Encryption..."
                printf "Please enter a password for encryption: "
                read -rs enc_password
                echo
                if output=$(pymobiledevice3 backup2 encryption on "$enc_password" 2>&1); then
                    if [[ -z "$output" ]]; then
                        echo "[+] Encryption has been enabled successfully."
                    else
                        echo "[-] ERROR: $output" >&2
                    fi
                else
                    echo "[-] ERROR: An unexpected error occurred while enabling encryption." >&2
                fi
                ;;
            0) return ;;  # Return to main menu
            *)
                echo "[-] ERROR: Invalid choice. Please try again." >&2
                ;;
        esac
    else
        echo "Encryption is currently ON. Please choose an option:"
        echo "1. Disable Encryption"
        echo "2. Change Encryption Password"
        echo "0. Go Back to Main Menu"
        printf "Enter your choice: "
        read -r enc_choice

        case $enc_choice in
            1)
                display_header
                echo "[+] Disabling Encryption..."
                printf "Please enter the current encryption password: "
                read -rs enc_password
                echo
                if output=$(pymobiledevice3 backup2 encryption off "$enc_password" 2>&1); then
                    if [[ -z "$output" ]]; then
                        echo "[+] Encryption has been disabled successfully."
                    else    
                        echo "[-] ERROR: $output" >&2
                    fi
                else
                    echo "[-] ERROR: An unexpected error occurred while disabling encryption." >&2
                fi
                ;;
            2)
                display_header
                echo "[+] Changing Encryption Password..."
                printf "Please enter the current encryption password: "
                read -rs current_password
                echo
                printf "Please enter a new encryption password: "
                read -rs new_password
                echo
                if output=$(pymobiledevice3 backup2 change-password "$current_password" "$new_password" 2>&1); then
                    if [[ -z "$output" ]]; then
                        echo "[+] Encryption password has been updated successfully."
                    else
                        echo "[-] ERROR: $output" >&2
                    fi
                else
                    echo "[-] ERROR: An unexpected error occurred while changing encryption password." >&2
                fi
                ;;
            0) return ;;  # Return to main menu
            *)
                echo "[-] ERROR: Invalid choice. Please try again." >&2
                ;;
        esac
    fi

    printf "\nPress any key to go back to Main Menu."
    read -rn1
    return  # Redirect to main menu
}

# Function: Backup Now menu
backup_now_menu() {
    while true; do
        display_header
        echo "[+] Chosen Backup Now ..."
        echo "[+] Latest Backup: $LAST_BACKUP_TIME"
        BACKUP_DIR="$BACKUP_BASE_DIR/"

        if [[ "$LAST_BACKUP_TIME" == *"never"* ]]; then
            # Only full backup is allowed if there's no previous backup
            echo "1. Start Full Backup"
            echo "0. Go Back to Main Menu"
            printf "Enter your choice: "
            read -r backup_choice

            case $backup_choice in
                1)
                    display_header
                    echo "[+] Starting Full Backup ..."
                    
                    # Run the full backup command
                    pymobiledevice3 backup2 backup "$BACKUP_DIR" --full

                    # Notify user that the backup has finished
                    echo "[+] Full backup process has finished."
                    echo "[+] Ignore any backup_manifest.db related error: https://github.com/doronz88/pymobiledevice3/issues/755"

                    printf "\nPress any key to go back to Main Menu."
                    read -rn1
                    return  # Return to main menu
                    ;;
                0) return ;;  # Go back to main menu
                *)
                    echo "[-] ERROR: Invalid choice. Please try again." >&2
                    ;;
            esac
        else
            # Both full and delta backups are available
            echo "1. Start Full Backup"
            echo "2. Sync Now (Delta)"
            echo "0. Go Back to Main Menu"
            printf "Enter your choice: "
            read -r backup_choice

            case $backup_choice in
                1)
                    display_header
                    echo "[+] Starting Full Backup ..."

                    # Run the full backup command
                    pymobiledevice3 backup2 backup "$BACKUP_DIR" --full --udid $UNIQUE_DEVICE_ID

                    # Notify user that the backup has finished
                    echo "[+] Full backup process has finished."
                    echo "[+] Ignore any backup_manifest.db related error: https://github.com/doronz88/pymobiledevice3/issues/755"

                    printf "\nPress any key to go back to Main Menu."
                    read -rn1
                    return  # Return to main menu
                    ;;
                2)
                    display_header
                    echo "[+] Starting Delta Sync ..."

                    # Run the delta backup command
                    pymobiledevice3 backup2 backup "$BACKUP_DIR" --udid $UNIQUE_DEVICE_ID

                    # Notify user that the sync has finished
                    echo "[+] Delta sync process has finished."
                    echo "[+] Ignore any backup_manifest.db related error: https://github.com/doronz88/pymobiledevice3/issues/755"

                    printf "\nPress any key to go back to Main Menu."
                    read -rn1
                    return  # Return to main menu
                    ;;
                0) return ;;  # Go back to main menu
                *)
                    echo "[-] ERROR: Invalid choice. Please try again." >&2
                    ;;
            esac
        fi
    done
}

# Function: Restore Backup menu
restore_backup_menu() {
    while true; do
        display_header
        echo "[+] Chosen Restore Backup ..."
        echo "[!] IMPORTANT: Find My iPhone must be disabled before restoring."
        echo "1. Restore Backup"
        echo "2. Restore Encrypted Backup"
        echo "3. Restore Backup from Other Device"
        echo "4. Restore Encrypted Backup from Other Device"
        echo "0. Go Back to Main Menu"
        printf "Enter your choice: "
        read -r restore_choice

        case $restore_choice in
            1)
                display_header
                echo "[+] Starting Restore Process ..."

                # Define the backup directory
                BACKUP_DIR="$BACKUP_BASE_DIR/"
                echo "[+] Restoring backup from $BACKUP_DIR ..."

                # Run the restore command and display output
                pymobiledevice3 backup2 restore "$BACKUP_DIR" --system --settings --source "$UNIQUE_DEVICE_ID"

                # Notify user that the restore process has completed
                echo "[+] Restore process has finished. Please check the above output for any errors."

                printf "\nPress any key to go back to Main Menu."
                read -rn1
                return  # Return to main menu
                ;;
            2)
                display_header
                echo "[+] Starting Restore Process (Encrypted Backup) ..."

                # Define the backup directory
                BACKUP_DIR="$BACKUP_BASE_DIR/"
                echo "[+] Restoring encrypted backup from $BACKUP_DIR ..."

                # Prompt the user for the encryption password
                printf "Please enter the encryption password: "
                read -rs enc_password
                echo

                # Run the restore command with the password and display output
                pymobiledevice3 backup2 restore "$BACKUP_DIR" --system --settings --password "$enc_password" --source "$UNIQUE_DEVICE_ID"

                # Notify user that the restore process has completed
                echo "[+] Encrypted restore process has finished. Please check the above output for any errors."

                printf "\nPress any key to go back to Main Menu."
                read -rn1
                return  # Return to main menu
                ;;
            3)
                display_header
                echo "[+] Starting Restore Process (Backup from Other Device) ..."

                # Prompt the user for the original device UDID
                echo "[+] The available backups are stored in the following directory: $BACKUP_BASE_DIR"
                echo "[+] Each folder is named with the device's UDID."
                printf "Please paste the UDID of the original device backup to restore from: "
                read -r source_udid

                # Ensure the source UDID is not empty
                if [[ -z "$source_udid" ]]; then
                    echo "[-] ERROR: UDID cannot be empty. Please try again."
                    continue
                fi

                # Define the backup directory
                BACKUP_DIR="$BACKUP_BASE_DIR"
                echo "[+] Restoring backup from $BACKUP_DIR (source: $source_udid) ..."

                # Run the restore command and display output
                pymobiledevice3 backup2 restore --system --settings --source "$source_udid" "$BACKUP_DIR" 

                # Notify user that the restore process has completed
                echo "[+] Restore process has finished. Please check the above output for any errors."

                printf "\nPress any key to go back to Main Menu."
                read -rn1
                return  # Return to main menu
                ;;
            4)
                display_header
                echo "[+] Starting Restore Process (Encrypted Backup from Other Device) ..."

                # Prompt the user for the original device UDID
                echo "[+] The available backups are stored in the following directory: $BACKUP_BASE_DIR"
                echo "[+] Each folder is named with the device's UDID."
                printf "Please paste the UDID of the original device backup to restore from: "
                read -r source_udid

                # Ensure the source UDID is not empty
                if [[ -z "$source_udid" ]]; then
                    echo "[-] ERROR: UDID cannot be empty. Please try again."
                    continue
                fi

                # Prompt the user for the encryption password
                printf "Please enter the encryption password: "
                read -rs enc_password
                echo

                # Define the backup directory
                BACKUP_DIR="$BACKUP_BASE_DIR"
                echo "[+] Restoring encrypted backup from $BACKUP_DIR (source: $source_udid) ..."

                # Run the restore command with the password and display output
                pymobiledevice3 backup2 restore --system --settings --source "$source_udid" --password "$enc_password" "$BACKUP_DIR"

                # Notify user that the restore process has completed
                echo "[+] Encrypted restore process has finished. Please check the above output for any errors."

                printf "\nPress any key to go back to Main Menu."
                read -rn1
                return  # Return to main menu
                ;;
            0)
                return  # Go back to main menu
                ;;
            *)
                echo "[-] ERROR: Invalid choice. Please try again." >&2
                ;;
        esac
    done
}


# Function: Enable Developer Mode
enable_developer_mode() {
    display_header
    echo "[+] Chosen Enable Developer Mode ..."
    echo "[!] IMPORTANT: iPhone passcode must be disabled before enabling Developer Mode."

    pymobiledevice3 amfi enable-developer-mode

    echo "[+] Enable Developer Mode command has been executed. Please check the above output for any errors."

    printf "\nPress any key to go back to Main Menu."
    read -rn1
    return
}

# Main menu
main_menu() {
    while true; do
        display_header
        display_device_info
        printf "Select an option from the following functionalities:\n"
        printf "1. Software Update\n"
        printf "2. Restore Device\n"
        printf "3. Encryption Settings\n"
        printf "4. Backup Now\n"
        printf "5. Restore Backup\n"
        printf "6. Enable Developer Mode\n"
        printf "0. Exit\n\n"
        printf "Enter your choice: "

        read -r choice

        case $choice in
            1) software_update_menu ;;
            2) restore_device_menu ;;
            3) encryption_settings_menu ;;
            4) backup_now_menu ;;
            5) restore_backup_menu ;;
            6) enable_developer_mode ;;
            0) echo "[+] Exiting. Goodbye!"; break ;;
            *) printf "[-] ERROR: Invalid choice. Try again.\n" >&2 ;;
        esac

        # Reload device info after each operation
        init_device_info
    done
}

# Main execution flow
display_header
init_usbmuxd
init_resources
init_python_venv
init_device_info
main_menu

