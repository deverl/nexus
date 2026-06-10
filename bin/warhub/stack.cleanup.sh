#!/usr/bin/env bash

# 1. Verify .worktrees directory exists
if [ ! -d ".worktrees" ]; then
    echo "Error: .worktrees subdirectory not found in the current directory."
    exit 1
fi

# 2. Get list of subdirectories inside .worktrees
worktrees=()
while IFS= read -r -d '' dir; do
    dirname=$(basename "$dir")
    worktrees+=("$dirname")
done < <(find .worktrees -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

if [ ${#worktrees[@]} -eq 0 ]; then
    echo "No subdirectories found in .worktrees."
    exit 1
fi

# Add "all" option at the top
options=("-- delete all worktrees --" "${worktrees[@]}")

# Interactive menu
selected=0
while true; do
    clear
    echo "Select a worktree directory to clean up:"
    echo "======================================"
    
    for i in "${!options[@]}"; do
        if [ $i -eq $selected ]; then
            printf " -> %s\n" "${options[$i]}"
        else
            printf "    %s\n" "${options[$i]}"
        fi
    done
    
    echo ""
    echo "↑/↓ arrows to navigate | Enter to select | q to quit"

    # Read single keypress
    IFS= read -rsn1 key
    case "$key" in
        $'\x1b')  # ESC sequence for arrows
            read -rsn2 -t 0.1 key2
            case "$key2" in
                "[A")  # Up arrow
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$((${#options[@]}-1))
                    ;;
                "[B")  # Down arrow
                    ((selected++))
                    [ $selected -ge ${#options[@]} ] && selected=0
                    ;;
            esac
            ;;
        "")  # Enter key
            selected_name="${options[$selected]}"
            
            if [ "$selected_name" = "-- delete all worktrees --" ]; then
                echo "Selected: ALL worktrees"
                echo "Running cleanup on all subdirectories..."
                for dir in "${worktrees[@]}"; do
                    echo "→ Cleaning $dir"
                    ./stack cleanup "$dir"
                done
                echo "All cleanups completed."
            else
                echo "Selected: $selected_name"
                echo "Running: ./stack cleanup \"$selected_name\""
                ./stack cleanup "$selected_name"
            fi
            exit 0
            ;;
        "q"|"Q")
            echo "Quit."
            exit 0
            ;;
    esac
done