# Antigravity IDE Profile and Session Migration Tool

<div align="center">

[![Antigravity IDE Migration](https://img.shields.io/badge/ANTIGRAVITY_IDE-MIGRATION_&_RESTORE-orange?style=for-the-badge)](#)

[![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python&style=flat-square)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell&style=flat-square)](#)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&style=flat-square)](#)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

</div>

This repository contains a collection of scripts used to manually migrate and restore user profiles, recent projects lists, and agent conversation history following a failed upgrade or installation of **Antigravity IDE**.

> [!CAUTION]
> **⚠️ USE AT YOUR OWN RISK**  
> This repository contains unofficial workaround scripts. Executing them will modify configuration settings, files, and databases. Always backup your critical files manually beforehand, review all script files, and verify the code yourself before running them.

> [!WARNING]  
> **DISCLAIMER & CAUTION**  
> * **Do your own research**: These scripts were created based on a specific migration scenario (Windows environment, upgrading to SQLite databases from Protobuf state).
> * **Verify before running**: Do NOT execute any script blindly. Review the code, use your own LLM instance to verify what each command does, and test on backup copies of your files.
> * **No Warranty**: This code is licensed under the MIT License and provided "as is", without warranty of any kind.

---

## 🛡️ Safety & Backups Policy

### Pre-execution Backups
To prevent data loss, the scripts are designed to automatically duplicate all target directories before any file writes or modifications take place:
1. **IDE User Profile**: The active `%APPDATA%\Antigravity IDE\User` directory will be duplicated as `User_Backup_<timestamp>`.
2. **Gemini Agent Folder**: The active `%USERPROFILE%\.gemini\antigravity-ide` directory will be duplicated as `antigravity-ide_Backup_<timestamp>`.

### Manual Cleanup Required (No Auto-Deletion)
**We have purposely not included any automated cleanup or deletion routines.** 
This is by design to ensure that you retain full custody of your backup files. After running the scripts:
1. Verify that your settings, recent projects list, and agent history load correctly in the IDE.
2. Manually navigate to the backup paths printed in the terminal.
3. Delete the backup folders once you are 100% satisfied that your IDE works perfectly.

---

## 📁 File Structure

* `migrate_antigravity.ps1`: The main PowerShell wrapper script that orchestrates the backup, profile restore, file copying, and Python helper execution.
* `reset_migration.py`: Replaces the conversation migration status flag in your `.pbtxt` file so the language server runs the database migration.
* `restore_recents.py`: Restores the "Recent Projects" list in your SQLite global storage.
* `LICENSE`: MIT License terms protecting you and detailing the limitation of liability.

---

## 🚀 Usage Instructions

### Prerequisite
Ensure Python 3 is installed on your machine and available in your environment path.

### Setup & Run
1. Clone this repository or download the scripts to a folder on your system.
2. Open `restore_recents.py` in a text editor. Update the `projects` list with the absolute path URIs of your own projects:
   ```python
   projects = [
       "file:///c%3A/Users/YourUsername/Documents/MyProject1",
       "file:///c%3A/Users/YourUsername/Documents/MyProject2",
   ]
   ```
3. Close the **Antigravity IDE** completely.
4. Open a standard external PowerShell terminal and run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\migrate_antigravity.ps1
   ```
5. Relaunch the Antigravity IDE.
6. Verify your workspaces and chats, and manually delete the backup directories.
