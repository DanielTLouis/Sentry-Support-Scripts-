# Server Health Report

A Python utility that collects server health information using **IPMI** and **StorCLI**, then generates a text-based health report for hardware monitoring and support purposes.

## Overview

This script gathers hardware status information from a server, including:

- IPMI sensor readings
- System Event Log (SEL) entries
- Chassis status
- BMC (Baseboard Management Controller) information
- FRU (Field Replaceable Unit) inventory
- RAID controller information
- Physical disk status

The collected data is analyzed and formatted into a human-readable report that highlights potential hardware issues and component health.

---

## Requirements

### Operating System

- openSUSE Linux (tested with zypper package management)

### Required Utilities

The script automatically checks for and installs:

- `ipmitool`
- `StorCLI`

Additional utilities used:

- `curl`
- `unzip`
- `dmidecode`

### Python Version

- Python 3.13 or newer recommended

---

## Installation

Copy the script to the target server and make it executable if desired:

```bash
chmod +x Server_Health_Report.py
```

Run the script:

```bash
python3 Server_Health_Report.py
```

The script will:

1. Verify that `ipmitool` is installed.
2. Verify that `StorCLI` is installed.
3. Attempt to install missing dependencies automatically.

---

## Usage

Start the script:

```bash
python3 Server_Health_Report.py
```

You will be presented with the following menu:

```text
Choose what to do:
 1. Exit
 2. Generate Report
 3. Clean Up
```

### Generate Report

Select:

```text
2
```

The script will:

- Collect IPMI health information
- Collect RAID controller information
- Analyze hardware status
- Generate a formatted health report

### Cleanup

Select:

```text
3
```

This option is intended to remove downloaded and installed materials used by the script.

---

## Report Contents

### Alert Log

Displays critical and warning events detected from the IPMI System Event Log.

### ESM Log

Lists hardware events with severity classifications:

- OK
- Non-Critical
- Critical

### Chassis Report

Checks the health of:

- Fans
- Intrusion detection
- Memory
- Power supplies
- Power management
- Processors
- Temperatures
- Voltages
- Hardware logs
- RAID batteries / CacheVault modules

### Storage Controller Report

Displays:

- Controller ID
- Model
- Serial Number
- Firmware Version
- Controller Status
- Overall Health Status

### Disk Report

Displays:

- Slot Location
- Disk State
- Capacity
- Model
- Serial Number
- Media Type
- Predictive Error Information

---

## Output Location

Reports are stored under:

```text
/home/vcs/backups/<Month-Year>/
```

Example:

```text
/home/vcs/backups/June-2026/
```

Generated files are named using the system serial number:

```text
omreport_<serial_number>.txt
```

Example:

```text
omreport_ABC123456.txt
```

---

## Example

Run:

```bash
python3 Server_Health_Report.py
```

Select:

```text
2
```

Example output:

```text
Generating Report...
IPMI Sensor rows parsed
IPMI Sel List rows parsed
IPMI Fru rows parsed
Text report saved to /home/vcs/backups/June-2026/omreport_ABC123456.txt
```

---

## Notes

- Root or elevated privileges may be required to access IPMI and hardware management utilities.
- The script assumes StorCLI is installed at:

```text
/opt/MegaRAID/storcli/storcli64
```

- Internet access may be required for automatic StorCLI downloads.
- Reports are intended for server health reviews, diagnostics, and support investigations.

---

## Known Limitations

- Cleanup functionality is currently a placeholder and does not fully remove installed components.
- StorCLI download URLs may change over time.
- Some health determinations are based on keyword matching and may vary between hardware vendors.

---

## Author

**Daniel**

Created: 06/15/2026
