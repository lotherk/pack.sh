# pack.sh - Encrypted Script Wrapper

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.2.0-blue)

A POSIX-compatible script that encrypts any executable file (scripts, binaries, compiled programs, etc.) using GPG symmetric encryption and base64 encoding, producing a self-contained wrapper script for secure remote execution.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Password Sources](#password-sources)
- [How It Works](#how-it-works)
- [Generated Wrapper](#generated-wrapper)
- [Security](#security)
- [Examples](#examples)
- [License](#license)

## Features

- Encrypts scripts with GPG AES256 symmetric encryption
- Encodes any executable (scripts, binaries, compiled programs, etc.)
- Generates a self-contained POSIX sh wrapper script
- Embeds SHA256 checksum for payload integrity verification
- Interactive shell detection - uses `sh -ci` when running in terminal
- Password via environment variable, stdin, or interactive prompt
- Temp files are automatically cleaned up on exit

## Requirements

### For pack.sh (encryption):
- `gpg` (GNU Privacy Guard)
- `base64` (standard Unix utility)
- `sha256sum` (for checksum generation)
- POSIX `/bin/sh` shell

### For wrapper execution (decryption):
- `gpg`
- `base64`
- `mktemp` (for temporary file creation)
- `sha256sum` (for checksum verification)

## Installation

Clone or download `pack.sh` and make it executable:

```bash
chmod +x pack.sh
```

## Usage

### Creating an Encrypted Script Wrapper

```bash
./pack.sh your-script.sh > encrypted.sh
```

### Password Sources (in order of precedence)

1. **PASSWORD environment variable** (recommended for automation):
   ```bash
   PASSWORD=yourpassword ./pack.sh your-script.sh > encrypted.sh
   ```

2. **stdin** (piped input):
   ```bash
   echo 'yourpassword' | ./pack.sh your-script.sh > encrypted.sh
   ```

3. **Interactive terminal prompt** (if stdin is a TTY):
   ```bash
   ./pack.sh your-script.sh > encrypted.sh
   # Enter password when prompted
   ```

### Running the Encrypted Wrapper

**Interactive** (password prompt):
```bash
./encrypted.sh
# Enter password when prompted
```

**Automated** (via environment variable):
```bash
PASSWORD=yourpassword ./encrypted.sh
```

**Remote execution**:
```bash
curl https://your-server.com/encrypted.sh | sh
```

**Automated remote execution**:
```bash
PASSWORD=yourpassword sh -c "$(curl https://your-server.com/encrypted.sh)"
```

## How It Works

1. `pack.sh` validates the input file
2. Encrypts the payload using GPG symmetric encryption with the provided password
3. Base64-encodes the encrypted payload (line-wrapped disabled)
4. Computes SHA256 checksum of the payload for integrity verification
5. Generates a self-contained POSIX sh wrapper with:
   - Embedded base64-encoded payload
   - SHA256 checksum for verification
   - Metadata (generator, date, version, user, machine)
   - Password prompt or PASSWORD env var support
   - Automatic temp file cleanup

## Generated Wrapper

The generated wrapper script includes:
- Embedded payload in `PAYLOAD` variable
- Payload SHA256 checksum for integrity verification
- Automatic password prompt (if PASSWORD env var not set)
- Interactive shell detection - uses `sh -ci` when running in terminal
- Temp file cleanup via trap

## Security

- Passwords are read silently (no echo) when TTY is available
- GPG uses AES256-CFB encryption
- SHA256 checksum verifies payload integrity before execution
- Encrypted data is decoded in memory; temporary files are cleaned up automatically
- No sensitive information exposed in error messages
- Use strong passwords for encryption
- Consider hosting over HTTPS for transport security

## Examples

### Encrypt a script

```bash
./pack.sh myscript.sh > encrypted.sh
chmod +x encrypted.sh
```

### Run locally with password

```bash
PASSWORD=secret ./encrypted.sh
```

### Remote execution

```bash
# Host encrypted.sh on your web server, then:
curl https://your-server.com/encrypted.sh | sh
```

### Test with included test script

```bash
./test.sh
```

## License

MIT License - See LICENSE file for details

---

Created by Konrad 'lotherk' Lother