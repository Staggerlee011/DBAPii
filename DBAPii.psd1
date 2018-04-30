@{
	
	# Script module or binary module file associated with this manifest.
	RootModule = 'DBAPii.psm1'
	
	# Version number of this module.
	ModuleVersion = '0.0.02'
	
	# ID used to uniquely identify this module
	GUID = '9d139310-ce45-41ce-8e8b-d76335aa1786'
	
	# Author of this module
	Author = 'Stephen Bennett'
	
	# Company or vendor of this module
	CompanyName = ''
	
	# Description of the functionality provided by this module
	Description = 'Provides functionality for finding and removing PII from SQL Server databases.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = ''
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = ''
	
	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules        = @(
      @{ ModuleName = 'dbatools'; ModuleVersion = '0.9.317' }
    )
	
	# Script files () that are run in the caller's environment prior to importing this module
	ScriptsToProcess = @()
	
	# Type files (xml) to be loaded when importing this module
	TypesToProcess = @()
	
	# Format files (xml) to be loaded when importing this module
	FormatsToProcess = @()
	
	# Modules to import as nested modules of the module specified in ModuleToProcess
	NestedModules = @()
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Find-PiiColumn',
		'Find-PiiEmailAddress',
		'Update-PiiEmailAddress'
        'Update-EmailAddress'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport = '*'
	
	# Variables to export from this module
	VariablesToExport = '*'
	
	# Aliases to export from this module
	# Aliases are stored in dbatools.psm1
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = ''
	
	PrivateData = @{
		# PSData is module packaging and gallery metadata embedded in PrivateData
		# It's for rebuilding PowerShellGet (and PoshCode) NuGet-style packages
		# We had to do this because it's the only place we're allowed to extend the manifest
		# https://connect.microsoft.com/PowerShell/feedback/details/421837
		PSData = @{
			# The primary categorization of this module (from the TechNet Gallery tech tree).
			Category = "SQL Server"
			
			# Keyword tags to help users find this module via navigations and search.
			Tags = @('DBA', 'SQL Server', 'PII', 'Personally identifiable information', 'GDPR' )
			
			# The web address of an icon which can be used in galleries to represent this module
			
			# The web address of this module's project or support homepage.
			
			# The web address of this module's license. Points to a page that's embeddable and linkable.
			
			# Release notes for this particular version of the module
			# ReleaseNotes = False
			
			# If true, the LicenseUrl points to an end-user license (not just a source license) which requires the user agreement before use.
			# RequireLicenseAcceptance = ""
			
			# Indicates this is a pre-release/testing version of the module.
			IsPrerelease = 'True'
		}
	}
}