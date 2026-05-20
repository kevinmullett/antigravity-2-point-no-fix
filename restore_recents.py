import os
import sqlite3
import json
import shutil

def backup_and_update(db_path):
    if not os.path.exists(db_path):
        print(f"Skipping {db_path} - not found.")
        return
        
    print(f"\nProcessing: {db_path}")
    
    # 1. Create backup
    backup_path = db_path + ".user_restore_backup"
    try:
        shutil.copy2(db_path, backup_path)
        print(f"  Backup created at: {backup_path}")
        print("  Note: Automated cleanup is omitted. Please delete this backup manually once verified.")
    except Exception as e:
        print(f"  Failed to create backup: {e}")
        return
        
    # 2. Modify database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        # Check if ItemTable exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='ItemTable'")
        if not cursor.fetchone():
            print("  Error: ItemTable table not found in database.")
            conn.close()
            return
            
        # =====================================================================
        # IMPORTANT: Replace these paths with the URIs to your own projects.
        # Format requirements:
        # - Use file:/// scheme
        # - Drive letter colon (:) must be URL encoded as %3A
        # Example format: "file:///c%3A/Users/Username/Documents/MyProject"
        # =====================================================================
        projects = [
            "file:///c%3A/Users/<YourUsername>/path/to/project-1",
            "file:///c%3A/Users/<YourUsername>/path/to/project-2",
        ]
        # =====================================================================
        
        # Format the JSON entries
        entries = [{"folderUri": p} for p in projects]
        recent_opened_json = json.dumps({"entries": entries})
        
        # Check if the key already exists
        cursor.execute("SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'")
        row = cursor.fetchone()
        
        if row:
            # Update key
            cursor.execute(
                "UPDATE ItemTable SET value = ? WHERE key = 'history.recentlyOpenedPathsList'",
                (recent_opened_json,)
            )
            print("  Updated existing 'history.recentlyOpenedPathsList' entry.")
        else:
            # Insert key
            cursor.execute(
                "INSERT INTO ItemTable (key, value) VALUES ('history.recentlyOpenedPathsList', ?)",
                (recent_opened_json,)
            )
            print("  Inserted new 'history.recentlyOpenedPathsList' entry.")
            
        conn.commit()
        print("  Database changes committed successfully!")
        
        # Verify the key
        cursor.execute("SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'")
        new_row = cursor.fetchone()
        if new_row:
            print("  Verified value in database:")
            print(f"    {new_row[0]}")
            
    except Exception as e:
        print(f"  Error modifying database: {e}")
    finally:
        conn.close()

def main():
    appdata = os.environ.get("APPDATA")
    if not appdata:
        print("APPDATA environment variable not found.")
        return
        
    # Path to the database
    active_db = os.path.join(appdata, "Antigravity IDE", "User", "globalStorage", "state.vscdb")
    backup_and_update(active_db)

if __name__ == '__main__':
    main()
