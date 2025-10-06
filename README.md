
# YAML Directory Structure Creator

A robust Bash script that automatically creates complex directory structures from YAML configuration files, complete with permissions, ownership, and default files.

## Features

- **Recursive Directory Creation** - Build nested folder hierarchies of any depth
- **Permission Management** - Set Unix permissions (e.g., `755`, `644`) for each directory
- **Ownership Control** - Assign owners to directories (requires root/sudo)
- **Default Files** - Automatically create placeholder files in any directory
- **Robust Validation** - Checks for `yq` installation, YAML syntax, and file permissions
- **Color-Coded Output** - Easy-to-read INFO, WARNING, ERROR, and SUCCESS messages
- **Idempotent Operations** - Safe to run multiple times (skips existing files/folders)
- **Cross-Platform** - Works on macOS and Linux

## Prerequisites

- **Bash** 4.0+ (pre-installed on most systems)
- **yq v4+** - YAML processor ([installation guide](https://github.com/mikefarah/yq#install))

### Installing yq

**macOS (Homebrew):**
```bash
brew install yq
```

**Linux (Binary):**
```bash
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

**Verify installation:**
```bash
yq --version
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/kapileshRajput/yaml-directory-creator.git 
cd yaml-directory-creator
```

2. Make the script executable:
```bash
chmod +x create_dirs.sh
```

## Usage

### Basic Syntax
```bash
./create_dirs.sh <yaml_file> [base_directory]
```

### Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `yaml_file` | Yes | - | Path to YAML configuration file |
| `base_directory` | No | `.` (current directory) | Where to create the structure |

### Examples

**Create structure in current directory:**
```bash
./create_dirs.sh structure.yaml
```

**Create structure in specific location:**
```bash
./create_dirs.sh structure.yaml /path/to/project
```

**Using with sudo (for ownership changes):**
```bash
sudo ./create_dirs.sh structure.yaml /var/www
```

## YAML Configuration Format

### Basic Structure

```yaml
directory_name:
  permissions: "755"              # Optional: Unix permissions
  owner: "username"               # Optional: Owner (requires sudo)
  tags: ["tag1", "tag2"]         # Optional: Metadata (not used yet)
  notes: "Description here"       # Optional: Metadata (not used yet)
  default_files:                  # Optional: Files to create
    - README.md
    - .gitignore
  subdirs:                        # Optional: Nested directories
    subdirectory_name:
      permissions: "755"
      default_files:
        - file.txt
```

### Complete Example

```yaml
my-project:
  permissions: "755"
  owner: "developer"
  tags: ["web", "production"]
  notes: "Main project root"
  default_files:
    - README.md
    - .gitignore
    - LICENSE
  subdirs:
    src:
      permissions: "755"
      default_files:
        - main.py
        - config.py
        - __init__.py
      subdirs:
        components:
          permissions: "755"
          default_files:
            - header.py
            - footer.py
        utils:
          permissions: "755"
          default_files:
            - helpers.py
    
    docs:
      permissions: "755"
      default_files:
        - index.md
      subdirs:
        api:
          permissions: "755"
          default_files:
            - endpoints.md
        guides:
          permissions: "755"
    
    tests:
      permissions: "755"
      default_files:
        - test_main.py
        - conftest.py
    
    config:
      permissions: "750"
      owner: "root"
      default_files:
        - settings.yaml
        - secrets.env
```

This configuration creates the following directory structure:

```
my-project/
├── README.md
├── .gitignore
├── LICENSE
├── src/
│   ├── main.py
│   ├── config.py
│   ├── __init__.py
│   ├── components/
│   │   ├── header.py
│   │   └── footer.py
│   └── utils/
│       └── helpers.py
├── docs/
│   ├── index.md
│   ├── api/
│   │   └── endpoints.md
│   └── guides/
├── tests/
│   ├── test_main.py
│   └── conftest.py
└── config/
    ├── settings.yaml
    └── secrets.env
```

## Configuration Options

### Permissions
Standard Unix permission format (octal):
- `755` - rwxr-xr-x (common for directories)
- `644` - rw-r--r-- (common for files)
- `750` - rwxr-x--- (restricted access)
- `700` - rwx------ (owner only)

### Owner
- Requires **root/sudo privileges** to apply
- Can be username or `user:group` format
- If run without sudo, a warning is shown but script continues

### Default Files
- Creates empty files if they don't exist
- Skips files that already exist (safe to re-run)
- Preserves existing file content

### Tags & Notes
- Currently stored but not actively used
- Reserved for future features (filtering, documentation generation, etc.)

## Example YAML File

The repository includes `structure.yaml` as a comprehensive example demonstrating a complete development directory structure. This example showcases:

- Multi-level nested directories
- Different permission schemes
- Default file creation patterns
- Organization for various development workflows (iOS, Android, Web, Backend, DevOps, etc.)

You can use this file as a template and modify it according to your needs, or create your own YAML configuration from scratch.

## Output Example

```
INFO: Starting directory structure creation...
INFO: YAML file: /home/user/project-structure.yaml
INFO: Base directory: /home/user/projects

INFO: Using yq version: yq (https://github.com/mikefarah/yq/) version v4.47.2

INFO: Creating directory: /home/user/projects/my-project
INFO:   Setting permissions: 755
INFO:   Creating default files...
INFO:     Created: README.md
INFO:     Created: .gitignore
INFO: Creating directory: /home/user/projects/my-project/src
INFO:   Setting permissions: 755
INFO:   Creating default files...
INFO:     Created: main.py
INFO:     Created: config.py

SUCCESS: Directory structure created under: /home/user/projects
```

## Common Warnings

### Ownership Warning
```
WARNING: Cannot set owner (not root). Skipping chown for: /path/to/dir
```
**Solution:** Run with `sudo` if you need ownership changes, or remove the `owner` field from YAML.

### Permission Warning
```
WARNING: Failed to set permissions on: /path/to/dir
```
**Solution:** Check you have write access to the parent directory.

## Error Handling

The script validates:
- `yq` installation and version (v4+ required)
- YAML file existence and readability
- YAML syntax correctness
- Base directory existence and write permissions
- Directory creation success

The script is safe to run multiple times as existing directories and files are preserved.

## Use Cases

- **Project Scaffolding** - Quick setup for new software projects
- **Development Environments** - Standardize folder structures across teams
- **Server Setup** - Automated directory creation for web servers
- **Testing** - Create consistent test directory structures
- **Documentation** - Generate folder hierarchies for documentation systems
- **CI/CD** - Automated environment preparation in pipelines

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests and documentation as appropriate.

## Troubleshooting

### "yq is not installed" error
Install yq using the instructions in the [Prerequisites](#prerequisites) section.

### "YAML file not found" error
Ensure the path to your YAML file is correct. Use absolute paths if needed.

### "Base directory is not writable" error
Check directory permissions: `ls -ld /path/to/dir`

### Permissions not applying
Verify you're running the script with appropriate privileges for the target directory.

## Additional Resources

- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [Unix File Permissions Guide](https://www.guru99.com/file-permissions.html)
- [YAML Syntax Guide](https://yaml.org/spec/1.2.2/)

## Best Practices

1. **Test First** - Run on a test directory before production use
2. **Version Control** - Keep your YAML files in git for team collaboration
3. **Templates** - Create reusable YAML templates for common project types
4. **Automation** - Integrate into CI/CD pipelines or setup scripts
5. **Documentation** - Use `notes` field to document purpose of each directory
6. **Validation** - Always validate your YAML syntax before running the script

## Support

If you encounter any issues or have questions, please:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review existing [GitHub Issues](https://github.com/yourusername/yaml-directory-creator/issues)
3. Open a new issue with detailed information about your problem

---

## Disclaimer

This project was developed with the assistance of AI tools such as ChatGPT and Claude. While the generated scripts and code have been reviewed, it is recommended to **verify and test** them thoroughly before using them in production environments. The maintainers assume no responsibility for any issues arising from the use of this software. Always ensure you have proper backups and test in a safe environment first.
