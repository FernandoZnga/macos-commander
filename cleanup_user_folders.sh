#!/bin/zsh
#
# cleanup_user_folders.sh
# 
# Purpose: List and optionally delete files from the Desktop or Downloads folder that are 
#          older than or equal to 4 days.
#
# Usage: ./cleanup_user_folders.sh [OPTIONS]
#        Options:
#          --target VALUE        Target folder to clean: 'desktop' or 'downloads' (REQUIRED)
#          --delete              Delete files (if not specified, files will only be listed)
#          --include-subfolders  Include files in subfolders (by default, only files directly
#                               in the target folder are processed)
#          --help                Display this help message

# Display help/usage information
show_help() {
    echo "Clean up user folders by listing or deleting files older than 4 days."
    echo ""
    echo "Usage: ./cleanup_user_folders.sh [OPTIONS]"
    echo "Options:"
    echo "  --target VALUE        Target folder to clean: 'desktop' or 'downloads' (REQUIRED)"
    echo "  --delete              Delete files (if not specified, files will only be listed)"
    echo "  --include-subfolders  Include files in subfolders"
    echo "  --help                Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./cleanup_user_folders.sh --target desktop            # List files in Desktop"
    echo "  ./cleanup_user_folders.sh --target downloads          # List files in Downloads"
    echo "  ./cleanup_user_folders.sh --target desktop --delete   # Delete files from Desktop"
    echo "  ./cleanup_user_folders.sh --target downloads --delete --include-subfolders"
    echo "                                                        # Delete files from Downloads including subfolders"
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
deleted_file_count=0
deleted_folder_count=0

# Count folders and files
if [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
    # Exclude the root directory from folder count
    folder_count=$(find "$TARGET_DIR" -type d ! -path "$TARGET_DIR" | wc -l | tr -d ' ')
    total_file_count=$(find "$TARGET_DIR" -type f | wc -l | tr -d ' ')
    hidden_file_count=$(find "$TARGET_DIR" -type f -name ".*" | wc -l | tr -d ' ')
    delete_candidate_count=$(find "$TARGET_DIR" -type f -mtime +3 | wc -l | tr -d ' ')
else
    # Same logic, excluding the root directory from folder count
    folder_count=$(find "$TARGET_DIR" -maxdepth 1 -type d ! -path "$TARGET_DIR" | wc -l | tr -d ' ')
    total_file_count=$(find "$TARGET_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
    hidden_file_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -name ".*" | wc -l | tr -d ' ')
    delete_candidate_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -mtime +3 | wc -l | tr -d ' ')
fi

# Display mode info
if [ $DELETE_MODE -eq 1 ]; then
    echo "WARNING: Running in DELETE mode. Files will be permanently removed."
    echo "Total files found: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files eligible for deletion: $delete_candidate_count"
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

# Remove empty folders in DELETE mode (only if subfolders included)
if [ $DELETE_MODE -eq 1 ] && [ $INCLUDE_SUBFOLDERS -eq 1 ]; then
    EMPTY_FOLDERS=$(find "$TARGET_DIR" -type d -empty -print0)
    echo "$EMPTY_FOLDERS" | while IFS= read -r -d '' dir; do
        if [ "$dir" != "$TARGET_DIR" ]; then
            rmdir "$dir" && ((deleted_folder_count++))
        fi
    done
fi

# Summary
echo "----------------------------"
if [ $DELETE_MODE -eq 1 ]; then
    echo "Cleanup Summary:"
    echo "Total files found: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files deleted: $deleted_file_count"
    echo "Empty folders deleted: $deleted_folder_count"
else
    echo "Summary:"
    echo "Folders counted: $folder_count"
    echo "Total files counted: $total_file_count"
    echo "Hidden files found: $hidden_file_count"
    echo "Files that would be deleted: $delete_candidate_count"
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