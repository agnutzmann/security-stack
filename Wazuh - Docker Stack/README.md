# Wazuh Docker: Automated and Robust Installation

This repository contains an automated installation script to deploy a complete Wazuh stack (Manager, Indexer, Dashboard) using Docker. The goal is to provide a fast, secure, and low-maintenance method to bring up a single-node Wazuh environment on any Linux machine with Docker.

The script is designed to be run once, preparing the entire environment with security best practices and generating tools for future maintenance.

## ✨ Features

  - **Full Automation:** Zero-to-hero installation with a single command.
  - **Intelligent Prerequisite Check:** Automatically detects missing dependencies and provides the exact installation command for Debian/Ubuntu and Fedora/RHEL-based systems.
  - **Clean Structure:** Creates a stack directory containing only the essential files for operation, without the clutter from the Git repository.
  - **Secure by Default:**
      - Generates strong, random passwords for all internal components.
      - Applies restrictive file permissions (`chmod 700/600`) to certificates and configurations, as required by the Wazuh Indexer security plugin.
  - **Simplified Maintenance:**
      - Automatically creates ready-to-use `backup.sh`, `restore.sh`, and a template `upgrade.sh` script.
      - The `backup.sh` script performs a full backup of both configuration files and Docker data volumes.
      - The `restore.sh` script automates the restoration of the latest data backup.
  - **Persistent Configuration:** Ensures that necessary kernel settings (`vm.max_map_count`) survive a server reboot.
  - **Compatibility:** Automatically detects and uses the correct version of `docker compose` (v2) or `docker-compose` (v1) present on the system.

## 📋 Prerequisites

The script is designed to run on modern Linux systems and requires the following tools to function: Docker, Git, and Python 3.

**Don't worry about checking everything manually.** If any dependency is missing, the script itself will detect it and provide the exact command you need to run to install it.

## 🚀 How to Use

1.  **Download the script**
    Save the `install.sh` file to your home directory or wherever you prefer.

2.  **Make it executable**

    ```bash
    chmod +x install.sh
    ```

3.  **Run the script**

    ```bash
    ./install.sh
    ```

      - If any dependencies are missing, the script will stop and provide the exact installation command for your system. Simply copy, paste, run the suggested command, and then run `./install.sh` again.
      - If all prerequisites are met, the installation will proceed automatically to completion.

## 📁 Post-Installation File Structure

After execution, the destination directory (`~/stacks/wazuh` by default) will contain:

  - `docker-compose.yml`: The container orchestration file, already adapted to use secure passwords.
  - `.env`: A file with all the generated passwords. **Treat this file as confidential.**
  - `config/`: A directory containing all certificates and configuration files (`internal_users.yml`, etc.).
  - `backups/`: The directory where backups will be saved.
  - `backup.sh`: A script to perform a full backup of the stack.
  - `restore.sh`: A script to restore the latest data backup.
  - `upgrade.sh`: A helper script to facilitate the version upgrade process.

## 🔧 Maintenance

The following scripts are generated automatically and should be run from within the stack directory.

### Backup

To create a full backup of the configuration and data:

```bash
./backup.sh
```

Two `.tgz` files will be created in the `backups/` directory.

### Restore

To restore the latest data backup (this will stop the containers and overwrite the current data):

```bash
./restore.sh
```

### Upgrade

To upgrade the Wazuh version:

1.  Edit the `.env` file and change the `WAZUH_VERSION` variable.
2.  Run the upgrade script:
    ```bash
    ./upgrade.sh
    ```
    The script will perform a backup before starting the upgrade process.

## 🛡️ Security Considerations

  - **Passwords in Docker Inspect:** This installation method uses environment variables to pass passwords to the containers, as per the official Wazuh documentation. Be aware that any user with access to the Docker socket on the host can inspect the containers (`docker inspect`) and see the passwords in plaintext. Secure access to your Docker host.
  - **Backup Encryption:** The backup script does not encrypt the `.tgz` files by default. For production environments, consider adding an encryption step using `gpg` or `age` after the backup is created.

## 📄 License

This project is open-source. Feel free to use and modify it.