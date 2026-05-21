# Antigravity IDE Profile and Agent Data Migration Script
# Stop on errors
$ErrorActionPreference = "Stop"

$SCRIPT_VERSION = "2.0.0"

Write-Host "=============================================" -ForegroundColor Red -BackgroundColor Black
Write-Host " !!! WARNING: USE AT YOUR OWN RISK !!!" -ForegroundColor Red -BackgroundColor Black
Write-Host " This script modifies configuration databases and profiles." -ForegroundColor Red
Write-Host " Make sure you have backed up any critical directories." -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red -BackgroundColor Black
Write-Host

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Antigravity IDE Migration Script v$SCRIPT_VERSION" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host

# 1. Process Detection
Write-Host "Checking for running Antigravity IDE processes..." -ForegroundColor Yellow
while ($true) {
    $processes = Get-Process | Where-Object { $_.Name -like "*Antigravity IDE*" }
    if ($processes) {
        Write-Host "Warning: Antigravity IDE is currently running." -ForegroundColor Red
        Write-Host "Please save your work, close the IDE application completely, and press Enter to check again." -ForegroundColor Yellow
        Read-Host "Press [Enter] to continue..."
    } else {
        Write-Host "No running Antigravity IDE processes detected. Continuing..." -ForegroundColor Green
        break
    }
}
Write-Host

# Paths Setup
$AppDataRoam = $env:APPDATA
$ActiveUserDir = Join-Path $AppDataRoam "Antigravity IDE\User"
$BackupZip = Join-Path $AppDataRoam "Antigravity IDE\Antigravity IDE.zip"
$OldGeminiDir = Join-Path $env:USERPROFILE ".gemini\antigravity"
$NewGeminiDir = Join-Path $env:USERPROFILE ".gemini\antigravity-ide"
$ScratchDir = $PSScriptRoot
$TempExtractPath = Join-Path $ScratchDir "extracted_temp"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupUserDir = Join-Path $AppDataRoam "Antigravity IDE\User_Backup_$Timestamp"
$BackupAgentDir = Join-Path $env:USERPROFILE ".gemini\antigravity-ide_Backup_$Timestamp"

# 1.5 Paths Verification & Confirmation
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host " Path Configuration Summary" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "Source Paths:" -ForegroundColor White
Write-Host " - Old Gemini Agent Dir (Source): $OldGeminiDir [Exists: $(Test-Path $OldGeminiDir)]" -ForegroundColor Gray
Write-Host " - Profile Backup Archive (Source): $BackupZip [Exists: $(Test-Path $BackupZip)]" -ForegroundColor Gray
Write-Host "Target Paths:" -ForegroundColor White
Write-Host " - Active User Profile (Target): $ActiveUserDir [Exists: $(Test-Path $ActiveUserDir)]" -ForegroundColor Gray
Write-Host " - Active Gemini Agent Dir (Target): $NewGeminiDir [Exists: $(Test-Path $NewGeminiDir)]" -ForegroundColor Gray
Write-Host "Backup Destinations:" -ForegroundColor White
Write-Host " - User Profile Backup: $BackupUserDir" -ForegroundColor Gray
Write-Host " - Agent Folder Backup: $BackupAgentDir" -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host

$confirmation = Read-Host "Are these paths correct? Do you wish to proceed with the migration? [Y/N]"
if ($confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Host "Migration cancelled by user. Exiting." -ForegroundColor Red
    exit 0
}
Write-Host

# 2. Safety Backups
Write-Host "Creating safety backups of target folders..." -ForegroundColor Yellow

# User folder backup
if (Test-Path $ActiveUserDir) {
    Write-Host "Backing up current active User folder to: $BackupUserDir" -ForegroundColor Yellow
    Copy-Item -Path $ActiveUserDir -Destination $BackupUserDir -Recurse -Force
    Write-Host "User folder backup completed." -ForegroundColor Green
} else {
    Write-Host "Note: No active User folder found to backup." -ForegroundColor Yellow
}

# New Gemini IDE folder backup
if (Test-Path $NewGeminiDir) {
    Write-Host "Backing up current agent folder to: $BackupAgentDir" -ForegroundColor Yellow
    Copy-Item -Path $NewGeminiDir -Destination $BackupAgentDir -Recurse -Force
    Write-Host "Agent folder backup completed." -ForegroundColor Green
} else {
    Write-Host "Note: No active agent folder found to backup." -ForegroundColor Yellow
}
Write-Host

# 3. Profile Restore (from Zip)
if (Test-Path $BackupZip) {
    Write-Host "Found profile backup archive: $BackupZip" -ForegroundColor Yellow
    
    # Clean temp extraction directory if exists
    if (Test-Path $TempExtractPath) {
        Remove-Item -Path $TempExtractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempExtractPath -Force | Out-Null
    
    Write-Host "Extracting profile backup archive... (This may take a moment)" -ForegroundColor Yellow
    Expand-Archive -Path $BackupZip -DestinationPath $TempExtractPath -Force
    
    $ExtractedUser = Join-Path $TempExtractPath "User"
    if (Test-Path $ExtractedUser) {
        Write-Host "Restoring User configuration and database files..." -ForegroundColor Yellow
        # Ensure the destination User directory exists
        if (-not (Test-Path $ActiveUserDir)) {
            New-Item -ItemType Directory -Path $ActiveUserDir -Force | Out-Null
        }
        # Copy the extracted User folder to the active User folder
        Copy-Item -Path "$ExtractedUser\*" -Destination $ActiveUserDir -Recurse -Force
        Write-Host "Restored User configuration successfully." -ForegroundColor Green
    } else {
        Write-Host "Error: Could not find 'User' folder inside the backup archive." -ForegroundColor Red
        throw "Missing User folder in backup ZIP."
    }
    
    # Clean up extraction temp path
    Write-Host "Cleaning up temporary extraction files..." -ForegroundColor Yellow
    Remove-Item -Path $TempExtractPath -Recurse -Force
    Write-Host "Cleanup completed." -ForegroundColor Green
} else {
    Write-Host "Note: No backup archive found at $BackupZip. Skipping Profile Restore step." -ForegroundColor Yellow
}
Write-Host

# 4. Agent State Migration
Write-Host "Migrating Agent states and conversation history..." -ForegroundColor Yellow

if (Test-Path $OldGeminiDir) {
    # Ensure new agent directory exists
    if (-not (Test-Path $NewGeminiDir)) {
        New-Item -ItemType Directory -Path $NewGeminiDir -Force | Out-Null
    }

    # Ensure new conversations directory exists
    $NewConvDir = Join-Path $NewGeminiDir "conversations"
    if (-not (Test-Path $NewConvDir)) {
        New-Item -ItemType Directory -Path $NewConvDir -Force | Out-Null
    }
    
    # Copy conversation history files (*.pb)
    $OldConvDir = Join-Path $OldGeminiDir "conversations"
    if (Test-Path $OldConvDir) {
        Write-Host "Copying old conversation .pb files..." -ForegroundColor Yellow
        $pbFiles = Get-ChildItem -Path $OldConvDir -Filter "*.pb"
        foreach ($file in $pbFiles) {
            $dest = Join-Path $NewConvDir $file.Name
            Copy-Item -Path $file.FullName -Destination $dest -Force
            Write-Host "Copied: $($file.Name)" -ForegroundColor Gray
        }
    }
    
    # Copy agent state and summary files
    $filesToCopy = @("agyhub_summaries_proto.pb", "antigravity_state.pbtxt", "user_settings.pb")
    foreach ($fileName in $filesToCopy) {
        $srcFile = Join-Path $OldGeminiDir $fileName
        if (Test-Path $srcFile) {
            $destFile = Join-Path $NewGeminiDir $fileName
            Copy-Item -Path $srcFile -Destination $destFile -Force
            Write-Host "Copied: $fileName" -ForegroundColor Gray
        } else {
            Write-Host "Note: $fileName not found in old agent folder. Skipping." -ForegroundColor Gray
        }
    }
    
    Write-Host "Agent state and conversation history files copied." -ForegroundColor Green
} else {
    Write-Host "Warning: Old agent directory not found at $OldGeminiDir. Skipping file migration step." -ForegroundColor Red
}
Write-Host

# 4.5 Migrate Additional Agent Subfolders (annotations / prompting / implicit)
# Added in v2.0.0: these folders are NOT touched by the new IDE's internal
# migration. Copying them preserves view-time annotations, custom prompts,
# and implicit context that would otherwise be orphaned in the old location.
Write-Host "Migrating additional agent subfolders (annotations, prompting, implicit)..." -ForegroundColor Yellow
if (Test-Path $OldGeminiDir) {
    foreach ($subfolder in @('annotations', 'prompting', 'implicit')) {
        $src = Join-Path $OldGeminiDir $subfolder
        $dst = Join-Path $NewGeminiDir $subfolder

        if (-not (Test-Path $src)) {
            Write-Host " - $subfolder : not present in old agent dir, skipping." -ForegroundColor Gray
            continue
        }
        if (-not (Test-Path $dst)) {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
        }

        $copied = 0; $kept = 0; $replaced = 0
        foreach ($file in Get-ChildItem -LiteralPath $src -Recurse -File) {
            $relativePath = $file.FullName.Substring($src.Length).TrimStart('\')
            $targetFile = Join-Path $dst $relativePath
            $targetDir  = Split-Path -Parent $targetFile
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            if (Test-Path $targetFile) {
                $existing = Get-Item -LiteralPath $targetFile
                if ($file.LastWriteTime -gt $existing.LastWriteTime) {
                    Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
                    $replaced++
                } else {
                    $kept++
                }
            } else {
                Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
                $copied++
            }
        }
        Write-Host (" - $subfolder : copied=$copied  replaced=$replaced  kept-newer-in-dst=$kept") -ForegroundColor Gray
    }
    Write-Host "Additional subfolders migrated." -ForegroundColor Green
} else {
    Write-Host "Warning: Old agent directory not found. Skipping additional subfolder migration." -ForegroundColor Red
}
Write-Host

# 5. Execute Python Helper Scripts
Write-Host "Executing database configuration modifications..." -ForegroundColor Yellow

# Run the migration status reset
$ResetScript = Join-Path $ScratchDir "reset_migration.py"
if (Test-Path $ResetScript) {
    Write-Host "Resetting conversation migration flag..." -ForegroundColor Yellow
    python $ResetScript
} else {
    Write-Host "Warning: reset_migration.py not found in script directory." -ForegroundColor Red
}
Write-Host

# Run the recent projects restoration
$RestoreScript = Join-Path $ScratchDir "restore_recents.py"
if (Test-Path $RestoreScript) {
    Write-Host "Updating recent projects list in state.vscdb..." -ForegroundColor Yellow
    python $RestoreScript
} else {
    Write-Host "Warning: restore_recents.py not found in script directory." -ForegroundColor Red
}
Write-Host

Write-Host "=============================================" -ForegroundColor Green
Write-Host " Migration Completed Successfully!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host
Write-Host "The following safety backups were created:" -ForegroundColor Yellow
if (Test-Path $BackupUserDir) {
    Write-Host " - User Profile Backup: $BackupUserDir" -ForegroundColor Cyan
}
if (Test-Path $BackupAgentDir) {
    Write-Host " - Agent Folder Backup: $BackupAgentDir" -ForegroundColor Cyan
}
Write-Host
Write-Host "IMPORTANT: Automated cleanup is purposely NOT included to guarantee that you have safe backups of all impacted folders." -ForegroundColor Yellow
Write-Host "Please verify that the restored projects list, configurations, and conversation histories load correctly in your IDE." -ForegroundColor Yellow
Write-Host "Once you are confident everything is working, you can manually delete the backup directories listed above." -ForegroundColor Yellow
Write-Host
Write-Host "You can now restart your Antigravity IDE." -ForegroundColor Green
Write-Host
