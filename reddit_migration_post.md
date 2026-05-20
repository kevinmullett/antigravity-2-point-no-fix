# Fixing Antigravity IDE Update: How to Migrate/Restore Past Sessions, Settings, and Recent Projects

If you recently experienced a failed upgrade or installation of **Antigravity IDE** and lost your recent projects list, settings, or agent conversation history, you can manually restore and migrate all of your past states using a set of migration helper scripts.

I have packaged the PowerShell automation and Python helper scripts I used into a Git repository so you can review the code directly instead of bloating this post.

**GitHub Repository:** `https://github.com/kevinmullett/antigravity-2-point-no-fix`

---

### ⚠️ IMPORTANT DISCLAIMER & CAUTION
* **Do your own research**: These scripts were created for a Windows environment migrating Protobuf states to SQLite.
* **Verify before running**: Do NOT execute any scripts blindly. Review the code, use your own LLM instance to analyze and verify what each script does, and test them on backup copies of your files.
* **Safety Backups & Manual Cleanup**: Before any file modifications occur, the scripts automatically duplicate your active folders to prevent data loss. **We have purposely omitted automated cleanup of these backups.** This is to ensure you retain working copies of your files; you must manually delete them once you've verified everything works.

---

### What the Scripts Restore
1. **Recent Projects List**: Restores your pinned or recent workspaces list inside the SQLite database located at `%APPDATA%\Antigravity IDE\User\globalStorage\state.vscdb` under the key `history.recentlyOpenedPathsList`.
2. **Conversation History**: Old `.pb` files are copied from `%USERPROFILE%\.gemini\antigravity\conversations\` to `%USERPROFILE%\.gemini\antigravity-ide\conversations\`.
3. **Trigger Conversation Migration**: Resets the flag in `%USERPROFILE%\.gemini\antigravity-ide\antigravity_state.pbtxt` from `MIGRATION_STATUS_COMPLETED` to `MIGRATION_STATUS_UNSPECIFIED`. When the IDE starts, the language server automatically migrates the `.pb` files into SQLite `.db` databases.

---

### Step-by-Step Instructions

#### Step 1: Clone/Download the Migration Tool
Clone the tool repository or download the scripts:
* `migrate_antigravity.ps1` (powershell script orchestrating process checks, profile backups, and file operations)
* `reset_migration.py` (python script updating migration status in `antigravity_state.pbtxt`)
* `restore_recents.py` (python script updating SQLite `state.vscdb`)

#### Step 2: Configure Your Workspace Paths
Open `restore_recents.py` in a text editor and add the absolute paths to your projects inside the `projects` list, formatting them as URIs (e.g. `file:///c%3A/Users/Username/Documents/MyProject`).

#### Step 3: Close the IDE Completely
**Make sure the Antigravity IDE is completely closed.** If it is running, it will lock the databases or overwrite configurations on shutdown.

#### Step 4: Run the Migration Script
Open an external PowerShell window and run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process
.\migrate_antigravity.ps1
```
The script will confirm the IDE is closed, back up your profile and agent directories, move state files, run the status reset, and update the recent projects list in the SQLite database.

#### Step 5: Verify and Clean Up
1. Relaunch the Antigravity IDE and confirm that your settings, past chat conversations, and projects load correctly.
2. Once verified, manually delete the backup folders printed in your terminal (located under `%APPDATA%\Antigravity IDE` and `%USERPROFILE%\.gemini`).
