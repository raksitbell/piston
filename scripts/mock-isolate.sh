#!/bin/bash
# Mock isolate for ARM Mac development - Bypasses sandboxing to avoid 'clone failed' errors
# This script mimics the basic behavior of the isolate binary but runs commands directly.

COMMAND=""
BOX_ID="0"
META_FILE=""
CHDIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --init)
      # Extract box ID if present (e.g., -b10)
      for arg in "$@"; do [[ $arg == -b* ]] && BOX_ID=${arg#-b}; done
      DIR="/tmp/isolate-$BOX_ID"
      
      # Clean up old data if it exists
      rm -rf "$DIR"
      
      mkdir -p "$DIR/box" # ONLY create the box directory. Piston will create 'submission' inside it.
      chmod -R 777 "$DIR"
      
      # Pre-create the metadata file Piston expects to avoid ENOENT during cleanup
      touch "/tmp/$BOX_ID-metadata.txt"
      chmod 666 "/tmp/$BOX_ID-metadata.txt"
      
      echo "$DIR" # Piston expects the path to the box root
      exit 0
      ;;
    --cleanup)
      for arg in "$@"; do [[ $arg == -b* ]] && BOX_ID=${arg#-b}; done
      rm -rf "/tmp/isolate-$BOX_ID"
      rm -f "/tmp/$BOX_ID-metadata.txt"
      exit 0
      ;;
    --run)
      # Process flags before the -- separator
      while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--" ]]; then
          shift
          COMMAND="$@"
          break
        fi
        
        case $1 in
          --meta=*)
            META_FILE=${1#--meta=}
            ;;
          -E)
            shift
            # Export the environment variable
            export "$1"
            ;;
          -b*)
            BOX_ID=${1#-b}
            ;;
          -c)
            shift
            CHDIR="$1"
            ;;
        esac
        shift
      done
      
      # Handle working directory
      if [[ "$CHDIR" == "/box/submission" ]]; then
        cd "/tmp/isolate-$BOX_ID/box/submission" || exit 1
      elif [[ -n "$CHDIR" ]]; then
        cd "$CHDIR" || exit 1
      fi
      
      # Execute the command
      if [[ -n "$COMMAND" ]]; then
        eval "$COMMAND"
        EXIT_CODE=$?
      else
        EXIT_CODE=0
      fi
      
      # Mock the metadata file Piston expects
      if [[ -n "$META_FILE" ]]; then
        echo "exitcode:$EXIT_CODE" > "$META_FILE"
        echo "status:OK" >> "$META_FILE"
        echo "time:0.1" >> "$META_FILE"
        echo "time-wall:0.1" >> "$META_FILE"
        echo "cg-mem:1024" >> "$META_FILE"
      fi
      exit 0
      ;;
    *) shift ;;
  esac
done
