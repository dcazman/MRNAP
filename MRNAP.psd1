#
# Module manifest for module 'MRNAP'
#
# Generated on: 2026-02-25
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'MRNAP.psm1'

    # Version number of this module.
    ModuleVersion     = '9.5'

    # Unique identifier for this module.
    GUID              = 'ef2729bf-1767-40ff-93a8-9700d5208043'

    # Author of this module.
    Author            = 'Dan Casmas'

    # Copyright statement for this module.
    Copyright         = '(c) 2025 Dan Casmas. Licensed under the GNU General Public License v3.0.'

    # Description of the functionality provided by this module.
    Description       = 'Generates a timestamped report file name and full path with flexible formatting options. Supports custom directory, extension, UTC or local time, date-only, time-only, no-separator, and automatic archival of existing files to an old subdirectory. Works on Windows, Linux, and macOS with PowerShell 5.1 and 7+.'

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
            ReleaseNotes = 'Version 9.5. Supports flexible timestamped report path generation: local/UTC time, date-only, time-only, no-separator, custom extension, and automatic archival of matching files to an old subdirectory. Cross-platform: Windows, Linux, macOS. Tested with PowerShell 5.1 and 7.'

        }
    }
}
