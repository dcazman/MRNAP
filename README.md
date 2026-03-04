# MRNAP — Mold Report Name And Path

[![PSGallery Version](https://img.shields.io/powershellgallery/v/MRNAP)](https://www.powershellgallery.com/packages/MRNAP)
[![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/MRNAP)](https://www.powershellgallery.com/packages/MRNAP)

Generates a timestamped report file name and full path with flexible formatting options.
Handles custom directories, extensions, UTC or local time, a configurable archive folder,
and automatic archival of existing files. Accepts pipeline input by value and by property name.

**Function alias:** `MoldReportNameAndPath`  |  **Repo:** https://github.com/dcazman/MRNAP

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Parameters](#parameters)
- [Timestamp Format Reference](#timestamp-format-reference)
- [Examples](#examples)
- [Notes](#notes)

---

## Requirements

| Environment  | Requirement     |
|--------------|-----------------|
| Windows      | PowerShell 5.1+ |
| Linux / macOS | PowerShell 7+  |

No external dependencies. Uses only built-in PowerShell cmdlets.

---

## Installation

### PowerShell Gallery

```powershell
Install-Module -Name MRNAP
```

### Manual

Copy `MRNAP.psm1` (and optionally `MRNAP.psd1`) to a folder in your `$PSModulePath`, then import:

```powershell
Import-Module MRNAP
```

Or dot-source for one-off use:

```powershell
. .\MRNAP.psm1
```

---

## Parameters

All parameters accept pipeline input by property name. `-ReportName` additionally accepts pipeline input by value.

| Parameter | Alias(es) | Type | Default | Description |
|---|---|---|---|---|
| `-ReportName` | `-RN` | String | Script name or random word | Base name for the report file. If omitted, the calling script name is used; falls back to a random word when running interactively. |
| `-DirectoryName` | `-DN` | String | `~/Reports` | Destination directory for the report file. Relative paths are rooted with the platform path separator. |
| `-Extension` | `-EXT`, `-E` | String | `csv` | File extension. A leading dot is added automatically if omitted. |
| `-OldFolderName` | `-OFN` | String | `old` | Name of the archive subdirectory used by `-Move`. Change to `archive`, `backup`, etc. as needed. |
| `-TimestampFormat` | `-TF` | String | `DateOnly` | Controls the timestamp prepended to the filename. See [Timestamp Format Reference](#timestamp-format-reference) below. |
| `-UTC` | — | Switch | — | Use UTC instead of local time for the timestamp. |
| `-NoSeparators` | `-NoSep`, `-NX` | Switch | — | Remove underscores and dashes from the timestamp portion of the filename. |
| `-Move` | `-M` | Switch | — | Before returning the path, move any file matching `<ReportName>.<Extension>` to the archive subdirectory. Creates directories if they do not exist. |
| `-FlatName` | `-FL` | Switch | — | Return just the file name — no directory path, no timestamp. Combine with `-NoExtension` for a bare name. |
| `-NoExtension` | `-NE` | Switch | — | Omit the file extension from the output. |

---

## Timestamp Format Reference

The `-TimestampFormat` parameter accepts these values:

| Value | Format | Example filename |
|---|---|---|
| `DateOnly` *(default)* | `yyyy_MM_dd-` | `2025_01_15-Report.csv` |
| `DateTime` | `yyyy_MM_ddTHHmmss-` | `2025_01_15T143022-Report.csv` |
| `DateTimeNoSec` | `yyyy_MM_ddTHHmm-` | `2025_01_15T1430-Report.csv` |
| `TimeOnly` | `HHmmss-` | `143022-Report.csv` |
| `TimeOnlyNoSec` | `HHmm-` | `1430-Report.csv` |
| `JustDate` | `yyyy_MM_dd` | `2025_01_15.csv` (no report name) |
| `None` | *(no timestamp)* | `Report.csv` |

Add `-UTC` to any format to use UTC time instead of local time. Add `-NoSeparators` to strip underscores and dashes from the timestamp.

---

## Examples

> Path separators in results are platform-specific (`/` on Linux/macOS, `\` on Windows).
> `~` expands to `$HOME` on all platforms.

#### Default — date prefix, csv extension, default directory

```powershell
MRNAP -ReportName 'SalesReport'
# Result: ~/Reports/2025_01_15-SalesReport.csv
```

#### Custom directory and extension, move old file, UTC

```powershell
MRNAP -ReportName 'SalesReport' -DirectoryName '/srv/data' -Extension 'txt' -UTC -Move
# Result: /srv/data/2025_01_15T213022-SalesReport.txt
# (any existing /srv/data/SalesReport.txt is moved to /srv/data/old/)
```

#### Custom archive folder name

```powershell
MRNAP -ReportName 'SalesReport' -Move -OldFolderName 'archive'
# Result: ~/Reports/2025_01_15-SalesReport.csv
# (existing SalesReport.csv is moved to ~/Reports/archive/)
```

#### Full datetime in filename

```powershell
MRNAP -ReportName 'Audit' -DirectoryName '~/Logs' -TimestampFormat DateTime
# Result: ~/Logs/2025_01_15T143022-Audit.csv
```

#### Date and time, no seconds

```powershell
MRNAP -ReportName 'Audit' -DirectoryName '~/Logs' -TimestampFormat DateTimeNoSec
# Result: ~/Logs/2025_01_15T1430-Audit.csv
```

#### No separators (compact format)

```powershell
MRNAP -ReportName 'MonthlyReport' -UTC -NoSeparators
# Result: ~/Reports/20250115T213022MonthlyReport.csv
```

#### Time only, no date

```powershell
MRNAP -ReportName 'Snapshot' -DirectoryName '/tmp' -TimestampFormat TimeOnly
# Result: /tmp/143022-Snapshot.csv
```

#### Date only as filename (no report name)

```powershell
MRNAP -DirectoryName '~/Archive' -TimestampFormat JustDate
# Result: ~/Archive/2025_01_15.csv
```

#### No timestamp at all

```powershell
MRNAP -TimestampFormat None
# Result: ~/Reports/<ScriptName>.csv
#     or: ~/Reports/<RandomWord>.csv  (when run interactively)
```

#### Pipeline — pipe a string directly as the report name

```powershell
'DailyReport' | MRNAP -DirectoryName '~/Reports'
# Result: ~/Reports/2025_01_15-DailyReport.csv
```

#### Pipeline — pipe an object with named properties

```powershell
[PSCustomObject]@{ ReportName = 'Sales'; DirectoryName = '/tmp/reports'; Move = $true } | MRNAP
# Result: /tmp/reports/2025_01_15-Sales.csv
# (any existing /tmp/reports/Sales.csv is moved to /tmp/reports/old/)
```

#### Pipeline — generate multiple paths from an array

```powershell
'Users', 'Groups', 'Devices' | MRNAP -DirectoryName '~/Reports'
# Results:
#   ~/Reports/2025_01_15-Users.csv
#   ~/Reports/2025_01_15-Groups.csv
#   ~/Reports/2025_01_15-Devices.csv
```

#### Typical usage inside a script

```powershell
$reportPath = MRNAP -ReportName 'UserExport' -DirectoryName '~/Reports' -Move
Get-ADUser -Filter * | Export-Csv -Path $reportPath -NoTypeInformation
```

---

## Notes

- **Auto report name** — When `-ReportName` is not provided, MRNAP attempts to detect the calling script's filename (without extension). If called interactively (no script file), a random word from a built-in list is used instead.
- **Directory creation** — The `-Move` switch creates the target directory and the archive subdirectory automatically if they do not exist.
- **Move filter** — `-Move` archives files that match the exact pattern `<ReportName>.<Extension>` (e.g., `Report.csv`). Timestamped variants from previous runs are not matched. This is by design: archival targets files that share the same base name, typically those created with `-TimestampFormat None`.
- **Relative paths** — If `-DirectoryName` is not an absolute path (as determined by `[IO.Path]::IsPathRooted()`), a platform path separator is prepended to root it. On Windows this roots to the current drive (`\folder`); on Linux/macOS it roots to `/folder`.
- **Extension dot** — A leading dot is added to `-Extension` automatically. Passing `csv` and `.csv` both produce `.csv`.
- **Cross-platform** — Uses `[IO.Path]::IsPathRooted()` and `Join-Path` throughout for portability. Tested on Windows (PS 5.1 and 7) and designed to work on Linux and macOS (PS 7+).
- **Pipeline efficiency** — Helper functions are initialized in the `begin` block so they are defined only once per pipeline run, not once per input object.

---

*Author: Dan Casmas — 03/2026. Tested on Windows PowerShell 5.1 and PowerShell 7 (Windows, Linux, macOS).*
