# Virtual-Man

A comprehensive command-line tool for creating and managing Ubuntu virtual machines using **cloud-init autoinstall**, `qemu`, and automated provisioning.

## 📦 Features

- **Unified CLI**: Single `vman` command for all VM operations
- **Automated VM Creation**: Generate VMs with cloud-init autoinstall from Ubuntu Server ISOs
- **Daemon Support**: Run VMs in background with process management
- **Simple Networking**: Uses QEMU user-mode networking (NAT) - no bridge setup required
- **Flexible Configuration**: Customizable disk size, username, and password
- **VM Lifecycle Management**: Create, run, stop, and list VMs

## 🏗️ Project Structure

```
virtual-man/
├── vman                    # Main CLI tool
├── lib/                    # Backend scripts
│   ├── v-add.sh           # VM creation logic
│   ├── v-run.sh           # VM execution logic
│   └── v-kill.sh          # VM termination logic
├── disks/                 # VM disk images (*.qcow2)
├── daemons/              # PID files for daemon VMs
└── README.md
```

## 🔧 Prerequisites

- **Host OS**: Ubuntu 24.04+ (tested)
- **Required packages**:
  ```bash
  sudo apt update
  sudo apt install qemu-kvm qemu-utils cloud-image-utils whois uuid-runtime
  ```
- **ISO**: Ubuntu Live Server ISO (tested with 24.04.2)

---

> ⚠️ **Compatibility Note**:  
> This tool is designed specifically for **Ubuntu Live Server ISOs** and tested with:
>
> - **Host OS**: Ubuntu 24.04.2  
> - **ISO**: Ubuntu Live Server 24.04.2  
>
> Other distributions or desktop ISOs may not work correctly with this autoinstall setup.

---

## 🚀 Quick Start

1. **Make the CLI executable**:
   ```bash
   chmod +x vman
   ```

2. **Create your first VM**:
   ```bash
   ./vman create myvm ubuntu-24.04.2-live-server-amd64.iso
   ```

3. **Run the VM**:
   ```bash
   ./vman run myvm
   ```

## 📖 Usage

### Command Overview

```bash
./vman <command> [options]
```

| Command | Description |
|---------|-------------|
| `create` | Create a new VM from ISO |
| `run` | Run an existing VM |
| `stop` | Stop a running VM daemon |
| `list` | List available VMs |
| `status` | Show running daemon VMs with SSH ports |
| `help` | Show help information |

### 1. Creating VMs

```bash
./vman create <name> <iso> [disk_size] [username] [password]
```

#### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | VM name (required) | - |
| `iso` | Path to ISO file (required) | - |
| `disk_size` | Virtual disk size | `20G` |
| `username` | Default user | `ubuntu` |
| `password` | Default password | `ubuntu` |

#### Examples

```bash
# Basic VM creation
./vman create webserver ubuntu-24.04.2-live-server-amd64.iso

# Custom configuration
./vman create database ubuntu-24.04.2-live-server-amd64.iso 50G admin secretpass

# Get help
./vman create --help
```

### 2. Running VMs

```bash
./vman run <name> [--daemon|-d]
```

#### Options

| Option | Description |
|--------|-------------|
| `--daemon`, `-d` | Run VM as background daemon |

#### Examples

```bash
# Run VM interactively
./vman run webserver

# Run VM as daemon
./vman run webserver --daemon

# Get help
./vman run --help
```

### 3. Managing VMs

```bash
# List all available VMs
./vman list

# Check running daemon VMs and their SSH ports
./vman status

# Stop a running daemon VM
./vman stop webserver

# Get help for any command
./vman stop --help
```

## 🌐 Networking & SSH Access

VMs use QEMU's user-mode networking (NAT) with **automatic SSH port forwarding**:

### **Automatic SSH Setup**
- **SSH ports** automatically assigned: 2222, 3333, 4444, 5555...
- **No configuration needed** - SSH forwarding works out of the box
- **Multiple VMs supported** - each gets unique SSH port
- **Connection info** shown when starting VMs

### **Connecting to VMs**
```bash
# Start a VM and note the SSH port
./vman run myvm --daemon
# Output: Starting VM 'myvm' as daemon with SSH forwarded to port 2222
# Output: Connect via: ssh -p 2222 ubuntu@localhost

# Check SSH ports for all running VMs
./vman status
# VM NAME         PID      STATUS     SSH PORT COMMAND
# -------         ---      ------     -------- -------
# myvm            1234     RUNNING    2222     qemu-system-x86
# webserver       5678     RUNNING    3333     qemu-system-x86

# Connect via SSH
ssh -p 2222 ubuntu@localhost
```

### **Network Details**
- **VM IP range**: `10.0.2.0/24`
- **Internet access**: Full internet connectivity through host NAT
- **No root privileges** required for networking
- **No bridge configuration** needed

## 💡 Advanced Usage

### Running Multiple VMs

```bash
# Create multiple VMs
./vman create web1 ubuntu-server.iso 30G
./vman create web2 ubuntu-server.iso 30G
./vman create db1 ubuntu-server.iso 100G

# Run them as daemons (each gets unique SSH port)
./vman run web1 --daemon    # SSH on port 2222
./vman run web2 --daemon    # SSH on port 3333
./vman run db1 --daemon     # SSH on port 4444

# Check status with SSH ports
./vman status

# Connect to specific VMs
ssh -p 2222 ubuntu@localhost  # web1
ssh -p 3333 ubuntu@localhost  # web2
ssh -p 4444 ubuntu@localhost  # db1

# Stop specific VMs
./vman stop web1
./vman stop db1
```

### Custom VM Configurations

```bash
# Development server with custom user
./vman create dev-box ubuntu-server.iso 40G developer mypassword

# Large database server
./vman create postgres ubuntu-server.iso 200G postgres securepass
```

## 🔍 Troubleshooting

### Common Issues

1. **"Failed to create disk image"**: VM with same name already exists
   - Solution: Use a different name or remove existing disk from `disks/`

2. **"ISO file does not exist"**: Invalid path to ISO file
   - Solution: Check the ISO file path and ensure it exists

3. **"No PID file found"**: VM daemon not running
   - Solution: Start the VM with `--daemon` flag first

### Getting Help

```bash
# General help
./vman help

# Command-specific help
./vman create --help
./vman run --help
./vman stop --help
```

## 📁 File Locations

- **VM Disks**: `disks/<vm-name>.qcow2`
- **Daemon PIDs**: `daemons/<vm-name>.pid`
- **Temporary Files**: Created and cleaned up automatically during VM creation

## 🤝 Contributing

This is a homelab project for virtual machine management. Feel free to fork and customize for your own needs.

## 📄 License

This project is for personal/educational use. Ubuntu and QEMU are subject to their respective licenses.