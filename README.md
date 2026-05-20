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

---

## 🤖 LLM-Assisted Research & Customization (PRD + Prompt)

If you wish to follow the safety guidance and have your own LLM instance (Gemini, ChatGPT, Claude, etc.) review the codebase, explain the migration mechanics, or customize/rewrite the scripts for your environment, you can use the mini-PRD and prompt below.

### Mini-PRD: Antigravity IDE Restoration & Migration

#### 1. Context & Objective
Following a failed IDE upgrade, the user lost their recent workspaces list and past chat conversation history. The objective is to restore the user profile, recover past chat sessions (converting them from `.pb` to SQLite format), and restore the recent projects list in the IDE's database.

#### 2. Requirements & Execution Flow
1. **Safety First**: Must detect if `Antigravity IDE` is running and refuse to proceed until closed (preventing database locks or overrides).
2. **Directory Duplication**: Must clone the active `%APPDATA%\Antigravity IDE\User` and `%USERPROFILE%\.gemini\antigravity-ide` directories into timestamped backup folders before making edits.
3. **Settings Recovery**: If an `%APPDATA%\Antigravity IDE\Antigravity IDE.zip` backup archive exists, extract the `User` directory and copy files to the active profile location.
4. **Chat Migration Trigger**:
   - Copy old conversation `.pb` files from `%USERPROFILE%\.gemini\antigravity\conversations` to the new location `%USERPROFILE%\.gemini\antigravity-ide\conversations`.
   - Copy metadata state files (`agyhub_summaries_proto.pb`, `antigravity_state.pbtxt`, `user_settings.pb`).
   - Modify the `migrate_convos_into_projects` key in `antigravity_state.pbtxt` to `MIGRATION_STATUS_UNSPECIFIED`. (This signals the IDE server on next startup to automatically migrate `.pb` files to SQLite `.db` databases).
5. **Recent Projects Restore**:
   - Connect to the SQLite database at `%APPDATA%\Antigravity IDE\User\globalStorage\state.vscdb`.
   - Update/Insert the JSON array of workspace folder URIs into the `ItemTable` under the key `history.recentlyOpenedPathsList`.
6. **No Auto-Cleanup**: Print all backup directory paths at completion and instruct the user to verify functionality and delete backups manually.

---

### LLM Prompt for Analyzing / Customizing this Repository

Copy and paste this prompt into your own LLM instance along with the code files in this repository:

```text
You are an expert software engineer and systems administrator. I want to perform a manual state/profile migration for my Antigravity IDE, which broke after a recent upgrade. 

Here is the codebase for a migration tool:
- README.md: Explains the safety policies and overall flow.
- migrate_antigravity.ps1: Coordinates directory backups and file copying.
- reset_migration.py: Modifies state configuration flags.
- restore_recents.py: Inserts project paths into the SQLite database.

Please review these files and perform the following tasks:
1. Explain step-by-step how these scripts interact with my local files and databases (specifically 'state.vscdb' and 'antigravity_state.pbtxt').
2. Identify any potential security vulnerabilities, path issues, or edge cases that could cause data loss.
3. (Optional) Help me adapt or rewrite these scripts to work on my specific operating system or custom directory structure (e.g. macOS/Linux, custom profile paths, etc.).
4. Guide me through running this safely on my machine, ensuring I have correct manual backups.
```
