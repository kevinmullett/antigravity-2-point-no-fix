import os
import re

def main():
    # Dynamically find the user's home directory
    home_dir = os.path.expanduser("~")
    pbtxt_path = os.path.join(home_dir, ".gemini", "antigravity-ide", "antigravity_state.pbtxt")
    
    if not os.path.exists(pbtxt_path):
        print(f"File not found: {pbtxt_path}")
        return
        
    print(f"Reading: {pbtxt_path}")
    with open(pbtxt_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Create a local backup first (before inline modification)
    backup_path = pbtxt_path + ".user_restore_backup"
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Created local state file backup at: {backup_path}")
    print("Note: Automated cleanup is omitted. Delete this backup manually once verified.")
    
    # Replace the migration status line
    old_line = "migrate_convos_into_projects:  MIGRATION_STATUS_COMPLETED"
    new_line = "migrate_convos_into_projects:  MIGRATION_STATUS_UNSPECIFIED"
    
    if old_line in content:
        content = content.replace(old_line, new_line)
        print("Updated migration status to UNSPECIFIED.")
    else:
        # Try a more flexible replacement in case of whitespace differences
        content, count = re.subn(
            r'migrate_convos_into_projects:\s+MIGRATION_STATUS_COMPLETED',
            'migrate_convos_into_projects:  MIGRATION_STATUS_UNSPECIFIED',
            content
        )
        if count > 0:
            print(f"Updated migration status to UNSPECIFIED (matched using regex).")
        else:
            print("Migration status line not found or already modified.")
            
    with open(pbtxt_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("File saved successfully!")

if __name__ == '__main__':
    main()
