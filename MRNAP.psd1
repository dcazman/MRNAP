#
# Module manifest for module 'MRNAP'
#
# Generated on: 2026-03-03
#
@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'MRNAP.psm1'
    # Version number of this module.
    ModuleVersion     = '11.0'
    # Unique identifier for this module.
    GUID              = 'ef2729bf-1767-40ff-93a8-9700d5208043'
    # Author of this module.
    Author            = 'Dan Casmas'
    # Copyright statement for this module.
    Copyright         = '(c) 2026 Dan Casmas. Licensed under the GNU General Public License v2.0.'
    # Description of the functionality provided by this module.
    Description       = 'Generates a timestamped report file name and full path with flexible formatting options. Supports pipeline input by value and by property name, custom directory, extension, UTC or local time, configurable archive folder, and automatic archival of existing files. Works on Windows, Linux, and macOS with PowerShell 5.1 and 7+.'
    # Minimum version of the Windows PowerShell engine required by this module.
    PowerShellVersion = '5.1'
    # Functions to export from this module.
    FunctionsToExport = @('MRNAP')
    # Aliases to export from this module.
    AliasesToExport   = @('MoldReportNameAndPath')
    # Cmdlets to export from this module.
    CmdletsToExport   = @()
    # Variables to export from this module.
    VariablesToExport = @()
    # Private data to pass to the module specified in RootModule.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module for PSGallery discoverability.
            Tags         = @(
                'Report', 'Filename', 'Path', 'Timestamp', 'CSV', 'Automation',
                'Utility', 'CrossPlatform', 'FileManagement', 'Naming', 'Logging'
            )
            # URL to the license for this module.
            LicenseUri   = 'https://github.com/dcazman/MRNAP/blob/main/LICENSE'
            # URL to the main website for this project.
            ProjectUri   = 'https://github.com/dcazman/MRNAP'
            # Release notes for this version of the module.
            ReleaseNotes = 'Version 11.0. Replaced 6 timestamp switches (NoDateTimeSeconds, AddTime, NoSeconds, NoDate, JustDate, UTC-implied-format) with a single -TimestampFormat parameter accepting a validated set: DateOnly, DateTime, DateTimeNoSec, TimeOnly, TimeOnlyNoSec, JustDate, None. Added -OldFolderName parameter (alias OFN, default: old) so the archive subfolder used by -Move can be customized. UTC and NoSeparators remain as switches. Simplified internal timestamp logic.'
        }
    }
}
