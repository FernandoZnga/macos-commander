#!/bin/zsh
#
# cleanup_user_folders.sh
# 
# Purpose: List and optionally delete files from the Desktop or Downloads folder that are 
#          older than or equal to 4 days. When --include-subfolders is used, also removes
#          empty folders that were created more than 4 days ago.
#
# Usage: ./cleanup_user_folders.sh [OPTIONS]
#        Options:
#          --target VALUE        Target folder to clean: 'desktop' or 'downloads' (REQUIRED)
#          --delete              Delete files (if not specified, files will only be listed)
#          --include-subfolders  Include files in subfolders and check for empty folders to delete
#                               (folders are evaluated by creation date, not modification date)
#          --help                Display this help message

# Display help/usage information
show_help() {
    echo "Clean up user folders by listing or deleting files older than 4 days."
    echo "When --include-subfolders is used, also removes empty folders created more than 4 days ago."
    echo ""
    echo "Usage: ./cleanup_user_folders.sh [OPTIONS]"
    echo "Options:"
    echo "  --target VALUE        Target folder to clean: 'desktop' or 'downloads' (REQUIRED)"
    echo "  --delete              Delete files (if not specified, files will only be listed)"
    echo "  --include-subfolders  Include files in subfolders and empty folder cleanup"
    echo "                       (folders are evaluated by creation date, not modification date)"
    echo "  --help                Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./cleanup_user_folders.sh --target desktop            # List files in Desktop"
    echo "  ./cleanup_user_folders.sh --target downloads          # List files in Downloads"
    echo "  ./cleanup_user_folders.sh --target desktop --delete   # Delete files from Desktop"
    echo "  ./cleanup_user_folders.sh --target downloads --delete --include-subfolders"
    echo "                                                        # Delete files from Downloads including subfolders"
    echo "                                                        # and empty folders created more than 4 days ago"
    echo ""
    exit 0
}

# Initialize variables
TARGET=""

# Process command line arguments
DELETE_MODE=0
INCLUDE_SUBFOLDERS=0

for arg in "$@"; do
    if [[ "$prev_arg" == "--target" ]]; then
        TARGET="${arg:l}"  # Convert to lowercase using Zsh syntax
        if [[ "$TARGET" != "desktop" && "$TARGET" != "downloads" ]]; then
            echo "Error: Invalid target '$TARGET'. Valid targets are 'desktop' or 'downloads'."
            echo "Usage: ./cleanup_user_folders.sh [--target VALUE] [--delete] [--include-subfolders]"
            exit 1
        fi
        prev_arg=""
        continue
    fi
    
    case $arg in
        --target)
            prev_arg="--target"
            ;;
        --delete)
            DELETE_MODE=1
            ;;
        --include-subfolders)
            INCLUDE_SUBFOLDERS=1
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: ./cleanup_user_folders.sh [--target VALUE] [--delete] [--include-subfolders]"
            echo "       VALUE can be 'desktop' or 'downloads'"
            echo "Run './cleanup_user_folders.sh --help' for more information."
            exit 1
            ;;
    esac
    prev_arg=$arg
done

# Check if we're still waiting for a target value
if [[ "$prev_arg" == "--target" ]]; then
    echo "Error: --target requires a value ('desktop' or 'downloads')."
    echo "Usage: ./cleanup_user_folders.sh [--target VALUE] [--delete] [--include-subfolders]"
    echo "Run './cleanup_user_folders.sh --help' for more information."
    exit 1
fi

# Show help if no parameters were provided or target wasn't specified
if [[ $# -eq 0 || -z "$TARGET" ]]; then
    show_help
fi

# Set target directory path based on selected target
if [[ "$TARGET" == "desktop" ]]; then
    TARGET_DIR="$HOME/Desktop"
    TARGET_NAME="Desktop"
elif [[ "$TARGET" == "downloads" ]]; then
    TARGET_DIR="$HOME/Downloads"
    TARGET_NAME="Downloads"
fi

# Check if target directory exists and is accessible
if [ ! -d "$TARGET_DIR" ] || [ ! -r "$TARGET_DIR" ]; then
    echo "Error: $TARGET_NAME directory ($TARGET_DIR) doesn't exist or is not readable."
    exit 1
fi

# Initialize counters
folder_count=0
total_file_count=0
hidden_file_count=0
delete_candidate_count=0
delete_folder_candidate_count=0
deleted_file_count=0
deleted_folder_count=0
deleted_junk_file_count=0

# Define junk files that should be deleted immediately and excluded from folder analysis
# These are system/application files that regular users don't see or care about
JUNK_FILES=(
    ".DS_Store"
    "Thumbs.db"
    "desktop.ini"
    "._.DS_Store"
    "__MACOSX"
)

# Count folders and files
if [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
    # Exclude the root directory from folder count
    folder_count=$(find "$TARGET_DIR" -type d ! -path "$TARGET_DIR" | wc -l | tr -d ' ')
    total_file_count=$(find "$TARGET_DIR" -type f | wc -l | tr -d ' ')
    hidden_file_count=$(find "$TARGET_DIR" -type f -name ".*" | wc -l | tr -d ' ')
    delete_candidate_count=$(find "$TARGET_DIR" -type f -mtime +3 | wc -l | tr -d ' ')
    
    # Count folders older than 4 days that would be deleted (by creation date)
    # Process folders from deepest to shallowest for hierarchical cleanup
    delete_folder_candidate_count=0
    while IFS= read -r dir; do
        if [ -n "$dir" ]; then
            # Check creation date using stat -f %B (birth time in seconds since epoch)
            folder_birth_time=$(stat -f "%B" "$dir" 2>/dev/null)
            current_time=$(date +%s)
            days_old=$(( (current_time - folder_birth_time) / 86400 ))
            if [ "$days_old" -gt 3 ]; then
                # Count folders that are old enough, regardless of content initially
                # The actual deletion will handle the hierarchical cleanup
                ((delete_folder_candidate_count++))
            fi
        fi
    done < <(find "$TARGET_DIR" -type d ! -path "$TARGET_DIR" | sort -r)
else
    # Same logic, excluding the root directory from folder count
    folder_count=$(find "$TARGET_DIR" -maxdepth 1 -type d ! -path "$TARGET_DIR" | wc -l | tr -d ' ')
    total_file_count=$(find "$TARGET_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
    hidden_file_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -name ".*" | wc -l | tr -d ' ')
    delete_candidate_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -mtime +3 | wc -l | tr -d ' ')
    delete_folder_candidate_count=0
fi

# Display mode info
if [ $DELETE_MODE -eq 1 ]; then
    echo "WARNING: Running in DELETE mode. Files will be permanently removed."
    echo "Total files found: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files eligible for deletion: $delete_candidate_count"
    if [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
        echo "Empty folders eligible for deletion: $delete_folder_candidate_count"
    fi
    echo -n "Are you sure you want to proceed? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo "Operation cancelled. No files will be deleted."
        DELETE_MODE=0
    fi
else
    echo "Running in TEST mode. No files will be deleted."
    echo "Folders found: $folder_count"
    echo "Total files found: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files that would be deleted (older than 4 days): $delete_candidate_count"
    if [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
        echo "Empty folders that would be deleted (older than 4 days): $delete_folder_candidate_count"
    fi
fi

if [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
    echo "Including files in subfolders in the analysis."
else
    echo "Only processing files directly in the $TARGET_NAME folder (excluding subfolders)."
fi

# Current date for reference in output
CURRENT_DATE=$(date "+%Y-%m-%d")
echo "Current date: $CURRENT_DATE"
echo "Processing files in $TARGET_NAME older than 4 days..."

# Use find to identify files (not directories) older than or equal to 4 days
# -mtime +3 means: modified more than 3*24 hours ago (i.e., 4 or more days ago)
if [ $INCLUDE_SUBFOLDERS -eq 0 ]; then
    # Only include files directly in the target folder (maxdepth 1)
    FILE_LIST=$(find "$TARGET_DIR" -maxdepth 1 -type f -mtime +3 -print0)
else
    # Include files in all subdirectories (recursive search)
    FILE_LIST=$(find "$TARGET_DIR" -type f -mtime +3 -print0)
fi

echo "$FILE_LIST" | while IFS= read -r -d '' file; do
    # Get the file's modification date
    mod_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
    file_size=$(du -h "$file" | cut -f1)
    
    echo "File: $(basename "$file")"
    # echo "  Path: $file"
    # echo "  Modified: $mod_date"
    # echo "  Size: $file_size"

    # Delete if in delete mode
    if [ $DELETE_MODE -eq 1 ]; then
        rm "$file"
        echo "  Status: DELETED"
        ((deleted_file_count++))
    else
        echo "  Status: Would be deleted (test mode)"
    fi
    echo ""
done

# Clean up junk files immediately (regardless of age)
echo "Cleaning up system junk files..."
for junk_pattern in "${JUNK_FILES[@]}"; do
    if [ $INCLUDE_SUBFOLDERS -eq 0 ]; then
        # Only check directly in the target folder
        find "$TARGET_DIR" -maxdepth 1 -name "$junk_pattern" -type f -print0 | while IFS= read -r -d '' junk_file; do
            echo "Junk file: $(basename "$junk_file")"
            if [ $DELETE_MODE -eq 1 ]; then
                rm "$junk_file"
                echo "  Status: DELETED (system junk)"
                ((deleted_junk_file_count++))
            else
                echo "  Status: Would be deleted (system junk)"
            fi
        done
    else
        # Check recursively in all subdirectories
        find "$TARGET_DIR" -name "$junk_pattern" -type f -print0 | while IFS= read -r -d '' junk_file; do
            echo "Junk file: $(basename "$junk_file")"
            if [ $DELETE_MODE -eq 1 ]; then
                rm "$junk_file"
                echo "  Status: DELETED (system junk)"
                ((deleted_junk_file_count++))
            else
                echo "  Status: Would be deleted (system junk)"
            fi
        done
    fi
done

# Check folders that would be cleaned up in TEST mode (only if subfolders included)
if [ $DELETE_MODE -eq 0 ] && [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
    echo "Checking for folders that would be cleaned up..."
    
    # Show all old folders that would be processed
    find "$TARGET_DIR" -type d ! -path "$TARGET_DIR" | awk '{print length($0), $0}' | sort -nr | cut -d' ' -f2- | while IFS= read -r dir; do
        # Get the directory's creation date (birth time)
        dir_birth_date=$(stat -f "%SB" -t "%Y-%m-%d" "$dir" 2>/dev/null)
        folder_birth_time=$(stat -f "%B" "$dir" 2>/dev/null)
        current_time=$(date +%s)
        days_old=$(( (current_time - folder_birth_time) / 86400 ))
        
        # Check if directory is older than 4 days by creation date
        if [ "$days_old" -gt 3 ]; then
            # Count files excluding junk files
            total_files=$(find "$dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
            junk_file_count=0
            for junk_pattern in "${JUNK_FILES[@]}"; do
                junk_file_count=$((junk_file_count + $(find "$dir" -maxdepth 1 -name "$junk_pattern" -type f | wc -l | tr -d ' ')))
            done
            
            # Calculate non-junk files
            file_count=$((total_files - junk_file_count))
            new_file_count=0
            if [ "$file_count" -gt 0 ]; then
                # Count new non-junk files
                for file in "$dir"/*; do
                    if [ -f "$file" ]; then
                        is_junk=0
                        basename_file=$(basename "$file")
                        for junk_pattern in "${JUNK_FILES[@]}"; do
                            if [[ "$basename_file" == $junk_pattern ]]; then
                                is_junk=1
                                break
                            fi
                        done
                        if [ "$is_junk" -eq 0 ]; then
                            # Check if file is newer than 4 days
                            if ! find "$file" -mtime +3 -print | grep -q .; then
                                ((new_file_count++))
                            fi
                        fi
                    fi
                done
            fi
            
            subdir_count=$(find "$dir" -maxdepth 1 -type d ! -path "$dir" | wc -l | tr -d ' ')
            
            echo "Folder: $(basename "$dir") (created: $dir_birth_date)"
            echo "  Path: $dir"
            
            # Show folder contents for debugging
            if [ "$total_files" -gt 0 ]; then
                echo "  Files: $total_files total ($junk_file_count junk, $file_count real, $new_file_count new)"
            fi
            if [ "$subdir_count" -gt 0 ]; then
                echo "  Subdirectories: $subdir_count"
            fi
            
            # Determine status (now based on non-junk files)
            if [ "$subdir_count" -eq 0 ] && [ "$new_file_count" -eq 0 ]; then
                if [ "$file_count" -eq 0 ]; then
                    echo "  Status: Would be deleted (empty or contains only junk files)"
                else
                    echo "  Status: Would be deleted (contains only old files and junk)"
                fi
            else
                echo "  Status: Would be processed in hierarchical cleanup"
            fi
            echo ""
        fi
    done
fi

# Remove folders hierarchically in DELETE mode (only if subfolders included)
if [ $DELETE_MODE -eq 1 ] && [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
    echo "Performing hierarchical cleanup of old folders..."
    
    # Multiple passes to clean up folders hierarchically
    max_passes=10
    pass=1
    folders_deleted_this_pass=1
    
    while [ $folders_deleted_this_pass -gt 0 ] && [ $pass -le $max_passes ]; do
        folders_deleted_this_pass=0
        echo "Cleanup pass $pass..."
        
        # Process folders from deepest to shallowest (reverse sort by path length, then alphabetically)
        find "$TARGET_DIR" -type d ! -path "$TARGET_DIR" | awk '{print length($0), $0}' | sort -nr | cut -d' ' -f2- | while IFS= read -r dir; do
            # Check if directory exists (may have been deleted in previous iteration)
            if [ -d "$dir" ]; then
                # Get the directory's creation date (birth time)
                folder_birth_time=$(stat -f "%B" "$dir" 2>/dev/null)
                current_time=$(date +%s)
                days_old=$(( (current_time - folder_birth_time) / 86400 ))
                
                # Only process directories older than 4 days
                if [ "$days_old" -gt 3 ]; then
                    dir_birth_date=$(stat -f "%SB" -t "%Y-%m-%d" "$dir" 2>/dev/null)
                    
                    # Count files excluding junk files
                    total_files=$(find "$dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
                    junk_file_count=0
                    for junk_pattern in "${JUNK_FILES[@]}"; do
                        junk_file_count=$((junk_file_count + $(find "$dir" -maxdepth 1 -name "$junk_pattern" -type f | wc -l | tr -d ' ')))
                    done
                    
                    # Calculate non-junk files
                    real_file_count=$((total_files - junk_file_count))
                    real_new_file_count=0
                    if [ "$real_file_count" -gt 0 ]; then
                        # Count new non-junk files
                        for file in "$dir"/*; do
                            if [ -f "$file" ]; then
                                is_junk=0
                                basename_file=$(basename "$file")
                                for junk_pattern in "${JUNK_FILES[@]}"; do
                                    if [[ "$basename_file" == $junk_pattern ]]; then
                                        is_junk=1
                                        break
                                    fi
                                done
                                if [ "$is_junk" -eq 0 ]; then
                                    # Check if file is newer than 4 days
                                    if ! find "$file" -mtime +3 -print | grep -q .; then
                                        ((real_new_file_count++))
                                    fi
                                fi
                            fi
                        done
                    fi
                    
                    subdir_count=$(find "$dir" -maxdepth 1 -type d ! -path "$dir" | wc -l | tr -d ' ')
                    
                    # If no subdirectories and no new non-junk files, we can delete this folder
                    if [ "$subdir_count" -eq 0 ] && [ "$real_new_file_count" -eq 0 ]; then
                        echo "Old folder: $(basename "$dir") (created: $dir_birth_date)"
                        
                        # First remove any junk files
                        for junk_pattern in "${JUNK_FILES[@]}"; do
                            find "$dir" -maxdepth 1 -name "$junk_pattern" -type f -exec rm {} \; 2>/dev/null
                        done
                        
                        # Then try to remove the directory
                        if rmdir "$dir" 2>/dev/null; then
                            echo "  Status: DELETED (old folder with no recent non-junk content)"
                            ((deleted_folder_count++))
                            ((folders_deleted_this_pass++))
                        else
                            # Try to remove any remaining old files
                            if [ "$real_file_count" -gt 0 ]; then
                                find "$dir" -maxdepth 1 -type f -mtime +3 -exec rm {} \; 2>/dev/null
                                # Try rmdir again
                                if rmdir "$dir" 2>/dev/null; then
                                    echo "  Status: DELETED (after removing remaining old files)"
                                    ((deleted_folder_count++))
                                    ((folders_deleted_this_pass++))
                                else
                                    echo "  Status: KEPT (contains files that couldn't be deleted)"
                                fi
                            else
                                echo "  Status: FAILED to delete (permission issue or special files)"
                            fi
                        fi
                    fi
                fi
            fi
        done
        
        ((pass++))
    done
    
    if [ $pass -gt $max_passes ]; then
        echo "Reached maximum cleanup passes ($max_passes). Some nested folders may remain."
    fi
fi

# Summary
echo "----------------------------"
if [ $DELETE_MODE -eq 1 ]; then
    echo "Cleanup Summary:"
    echo "Total files found: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files deleted: $deleted_file_count"
    echo "Junk files deleted: $deleted_junk_file_count"
    echo "Empty folders deleted: $deleted_folder_count"
else
    echo "Summary:"
    echo "Folders counted: $folder_count"
    echo "Total files counted: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files that would be deleted: $delete_candidate_count"
    if [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
        echo "Empty folders that would be deleted: $delete_folder_candidate_count"
    fi
    echo "No files were deleted in test mode."
    echo "----------------------------"
    echo "Listing files is completed."
    echo "Run with --delete parameter to actually delete the files."
    echo "Examples:"
    echo "  ./cleanup_user_folders.sh --target desktop                       # List files in Desktop"
    echo "  ./cleanup_user_folders.sh --target desktop --delete              # Delete files directly in Desktop"
    echo "  ./cleanup_user_folders.sh --target downloads                     # List files in Downloads"
    echo "  ./cleanup_user_folders.sh --target downloads --delete            # Delete files directly in Downloads"
    echo "  ./cleanup_user_folders.sh --target desktop --delete --include-subfolders  # Delete files in Desktop and subfolders"
    echo "  ./cleanup_user_folders.sh --target downloads --delete --include-subfolders # Delete files in Downloads and subfolders"
fi
