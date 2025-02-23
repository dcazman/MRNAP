#
# Module manifest for module 'MRNAP'
#
# Generated by: Dan Casmas
#
# Generated on: 7/7/2021
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'MRNAP.psm1'

    # Version number of this module.
    ModuleVersion     = '0.8.0'

    # Supported PowerShell editions
    CompatiblePSEditions = @('Core', 'Desktop')

    # ID used to uniquely identify this module
    GUID              = 'fb1283ed-eb68-450e-94c0-5c35f08b26b0'

    # Author of this module
    Author            = 'Dan Casmas'

    # Company or vendor of this module
    CompanyName       = 'Casmas Solutions'

    # Copyright statement for this module
    Copyright         = '(c) Dan Casmas. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Molds Report Name And Path.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('MRNAP', 'MoldReportNameAndPath')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('report', 'utilities', 'path')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/dcazman/MRNAP/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/dancasmas/MRNAP'

            # Release notes of this module
            ReleaseNotes = 'Updated release.'

            # Prerelease string of this module
            Prerelease = 'Prod'
        }
    }
}
