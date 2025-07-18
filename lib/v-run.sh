#!/bin/bash

arg="$1"
arg2="$2"

# Function to find next available SSH port starting from 2222
find_available_ssh_port() {
    local start_port=2222
    local port=$start_port
    
    while [ $port -lt 9999 ]; do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo $port
            return 0
        fi
        
        # Increment by 1111 (2222, 3333, 4444, etc.)
        port=$((port + 1111))
    done
    
    # Fallback to sequential ports if pattern ports are taken
    port=2222
    while [ $port -lt 9999 ]; do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo "2222"  # Default fallback
}

# Check if no arguments provided
if [ -z "$arg" ]; then
  echo "Usage: $0 <vm_name> [--daemon|-d]"
  echo "       $0 list"
  echo "       $0 status"
  echo ""
  echo "Examples:"
  echo "  $0 ubuntu         # Run VM named 'ubuntu'"
  echo "  $0 ubuntu -d      # Run VM named 'ubuntu' as daemon"
  echo "  $0 list           # List available VMs"
  echo "  $0 status         # Show running daemon VMs"
  exit 1
fi

# If user wants to list available VM disk names
if [ "$arg" == "list" ]; then
  for disk in disks/*.qcow2; do
    basename "$disk" .qcow2
  done
  exit 0
fi

# If user wants to check daemon status
if [ "$arg" == "status" ]; then
  echo "Running VM Daemons:"
  echo "===================="
  
  if [ ! -d "daemons" ] || [ -z "$(ls -A daemons/ 2>/dev/null)" ]; then
    echo "No daemon VMs are currently running."
    exit 0
  fi
  
  printf "%-15s %-8s %-10s %-8s %s\n" "VM NAME" "PID" "STATUS" "SSH PORT" "COMMAND"
  printf "%-15s %-8s %-10s %-8s %s\n" "-------" "---" "------" "--------" "-------"
  
  for pid_file in daemons/*.pid; do
    if [ -f "$pid_file" ]; then
      vm_name=$(basename "$pid_file" .pid)
      pid=$(cat "$pid_file" 2>/dev/null)
      
      if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
        # Process is running - get SSH port from port file
        port_file="daemons/$vm_name.port"
        ssh_port="N/A"
        if [ -f "$port_file" ]; then
          ssh_port=$(cat "$port_file" 2>/dev/null)
        fi
        cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
        printf "%-15s %-8s %-10s %-8s %s\n" "$vm_name" "$pid" "RUNNING" "$ssh_port" "$cmd"
      else
        # Process is not running, clean up stale files
        printf "%-15s %-8s %-10s %-8s %s\n" "$vm_name" "$pid" "STOPPED" "N/A" "N/A"
        rm -f "$pid_file"
        rm -f "daemons/$vm_name.port"
      fi
    fi
  done
  exit 0
fi

disk_path="./disks/$arg.qcow2"

# Check if the disk file exists
if [ ! -f "$disk_path" ]; then
  echo "Disk '$disk_path' does not exist!"
  exit 1
fi


# Find available SSH port and build QEMU command
ssh_port=$(find_available_ssh_port)

# Base QEMU command with SSH port forwarding
QEMU_CMD="sudo qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 2 \
  -cpu host \
  -drive file=\"$disk_path\",format=qcow2 \
  -boot order=c \
  -netdev user,id=net0,hostfwd=tcp::$ssh_port-:22 \
  -device e1000,netdev=net0"

# Add daemonize flags if requested
if [ "$arg2" == "--daemon" ] || [ "$arg2" == "-d" ]; then
  mkdir -p "daemons"
  pid_file_path="./daemons/$arg.pid"
  port_file_path="./daemons/$arg.port"

  QEMU_CMD+=" -pidfile \"$pid_file_path\" -daemonize -display none"
  # Modifying ownership and permission for reading in v-kill.sh
  QEMU_CMD+=" && sudo chown $USER:$USER \"$pid_file_path\""
  QEMU_CMD+=" && chmod 644 \"$pid_file_path\""
  # Store SSH port for status display
  QEMU_CMD+=" && echo $ssh_port > \"$port_file_path\""
  QEMU_CMD+=" && chown $USER:$USER \"$port_file_path\""
  QEMU_CMD+=" && chmod 644 \"$port_file_path\""
  
  echo "Starting VM '$arg' as daemon with SSH forwarded to port $ssh_port"
  echo "Connect via: ssh -p $ssh_port ubuntu@localhost"
else
  echo "Starting VM '$arg' with SSH forwarded to port $ssh_port"
  echo "Connect via: ssh -p $ssh_port ubuntu@localhost"
fi


# Execute the command
eval "$QEMU_CMD"
