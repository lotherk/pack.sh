# pack.sh - Encrypted Script Wrapper

A POSIX-compatible bash script that encrypts any executable script (bash, python, etc.) using GPG symmetric encryption and base64 encoding, producing a self-contained wrapper script for secure remote execution.

## Features

- Encrypts scripts with GPG symmetric encryption
- Supports any script with a shebang (bash, python, node.js, etc.)
- Generates a wrapper script that can be hosted on a web server
- Allows remote execution via `curl | sh` with password protection
- Automatic shebang detection and execution with appropriate interpreter
- Interactive TTY support using `script` (if available) or `sh -i` fallback
- Password input via stdin for automation or interactive prompts

## Requirements

### For pack.sh (encryption):
- `gpg` (GNU Privacy Guard)
- `base64` (standard Unix utility)
- Bash (for the pack.sh tool)

### For wrapper execution (decryption):
- `gpg`
- `base64`
- `mktemp` (standard on most systems)
- `script` (optional, for full TTY support)

## Installation

Clone or download `pack.sh` and make it executable:

```bash
chmod +x pack.sh
```

Create a symlink for convenience:

```bash
ln -s pack.sh ~/bin/pack.sh
```

## Usage

### Creating an Encrypted Script Wrapper

Interactive password prompt:

```bash
./pack.sh your-script.sh > encrypted-wrapper.sh
```

Automated with password via stdin:

```bash
echo 'yourpassword' | ./pack.sh your-script.sh > encrypted-wrapper.sh
```

For Python scripts:

```bash
./pack.sh your-script.py > encrypted-wrapper.sh
```

### Hosting and Remote Execution

1. Upload `encrypted-wrapper.sh` to your web server
2. Execute remotely:

```bash
curl https://your-server.com/encrypted-wrapper.sh | sh
```

3. Enter the password when prompted to decrypt and run the script

### Automated Execution (Environment Variable)

```bash
PASSWORD=yourpassword sh -c "$(curl https://your-server.com/encrypted-wrapper.sh)"
```

## How It Works

1. `pack.sh` validates the input script and encrypts it using GPG with your password
2. The encrypted data is base64-encoded and embedded in a POSIX sh wrapper script
3. The wrapper script, when executed, prompts for the password, decrypts the payload, detects the original script's shebang, and runs it with `script -c` (for full TTY) or `sh -i` (interactive fallback)

## Compatibility

- **Wrapper**: POSIX `/bin/sh` compatible
- **Platforms**: Linux, macOS, FreeBSD, OpenBSD, NetBSD, Solaris (with required dependencies)
- **Interactivity**: Full TTY support with `script`, partial with `sh -i`
- **Piped execution**: `curl | sh` works with interactive password prompt

## Security Notes

- Passwords are read silently (no echo) when TTY is available
- Encrypted data is handled in memory; temporary files are cleaned up automatically
- No sensitive information is exposed in error messages
- Use strong passwords for encryption
- Consider hosting over HTTPS for transport security

## Examples

### Bash Script Test

```bash
cat > test.sh << 'EOF'
#!/bin/sh
echo "=== Testing stdout ==="
echo "Normal output"

echo "=== Testing stdin ==="
echo "Enter your name:"
read name
echo "Hello, $name!"

echo "=== Testing tty ==="
echo "TTY available: $( [ -t 0 ] && echo yes || echo no )"

echo "=== All tests complete ==="
EOF

chmod +x test.sh
echo 'secret' | ./pack.sh test.sh > test-encrypted.sh
chmod +x test-encrypted.sh
```

**Local test**:
```bash
PASSWORD=secret sh test-encrypted.sh
```

**Remote test**:
```bash
PASSWORD=secret sh -c "$(curl http://your-server/test-encrypted.sh)"
```

### Complete Machine Setup Example

```bash
# Upload your setup script
echo 'foo' | ./pack.sh setup.sh > set-me-up.sh
# Upload set-me-up.sh to web server
# Run on remote machine:
curl https://your-server/set-me-up.sh | sh
# Enter 'foo' when prompted
```

## Troubleshooting

- **mktemp not found**: Install coreutils or use alternative temp file creation
- **Interactive commands fail**: Ensure `script` is installed for full TTY support, or modify payload to use non-interactive alternatives
- **Piped execution issues**: Download and run locally: `curl -o script.sh URL && sh script.sh`
- **GPG errors**: Ensure GPG version compatibility (2.x recommended)

## License

MIT License