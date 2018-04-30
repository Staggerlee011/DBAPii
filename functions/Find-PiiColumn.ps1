function Find-PiiColumn {
<#

.SYNOPSIS
Returns all columns that match with the -contains array you pass in.

.DESCRIPTION
Function to find columns with name matching values you pass in, can be used to help find PII information or checking data linage, name standardization.

.PARAMETER SqlInstance
SQL Server name or SMO object representing the SQL Server to connect to. This can be a collection and receive pipeline input

.PARAMETER SqlCredential
PSCredential object to connect as. If not specified, current Windows login will be used.

.PARAMETER Database
The database(s) to process - this list is auto-populated from the server. If unspecified, all databases will be processed.

.PARAMETER ExcludeDatabase
The database(s) to exclude - this list is auto-populated from the server

.PARAMETER Contains
String or array of text to search through all columns in database(s) 

.NOTES
Author: Stephen Bennett

Website: https://sqlnotesfromtheunderground.wordpress.com/
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.LINK

.EXAMPLE
$pii = "email", "firstname", "surname"
Find-DbaColumn -SqlInstance DEV01 -Contains $pii
Searches all user databases and returns any columns with email, firstname or surname

#>

    [CmdletBinding()]
    Param (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $True)]
        [Alias("ServerInstance", "SqlServer", "SqlServers")]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [Alias("Databases")]
        [object[]]$Database,
        [object[]]$ExcludeDatabase,
        [string[]]$Contains,
        [string[]]$WildCardSearch,
        [string[]]$ignoreTable
    )

    process {
        foreach ($Instance in $SqlInstance) {

            try {
                #$server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $SqlCredential -MinimumVersion 9
                $server = Connect-DbaInstance -SqlInstance $instance -Credential $SqlCredential
            }
            catch {
                #Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }


            #Use IsAccessible instead of Status -eq 'normal' because databases that are on readable secondaries for AG or mirroring replicas will cause errors to be thrown
            $dbs = $server.Databases | Where-Object { $_.IsAccessible -eq $true -and $_.IsSystemObject -eq $false }
            if ($Database) {
                $dbs = $server.Databases | Where-Object Name -In $Database
            }

            if ($ExcludeDatabase) {
                $dbs = $dbs | Where-Object Name -NotIn $ExcludeDatabase
            }

            foreach ($db in $dbs) {
                Write-Verbose "reading from database: $db"
                #Write-Message -Level Verbose -Message "Searching on database $db"
                foreach ($table in $db.Tables)
                {
                    Write-Verbose "reading table: $table"
                    foreach ($column in $table.Columns | Where-Object {$_.Name -notin $ignoreTable})
                    {
                        if ($Contains -contains $column.name )
                        {
                            write-verbose "column :$column"
                            [pscustomobject]@{
                                ComputerName             = $server.NetName
                                SqlInstance              = $server.ServiceName
                                Database                 = $db.Name
                                Schema                   = $table.Schema
                                Table                    = $table.Name
                                Column                   = $column.Name
                                ColumnType               = $column.DataType.Name + "(" + $column.DataType.MaximumLength  + ")"
                                Contains                 = 1
                                WildCardSearch           = 0
                            }
                        }
                        foreach ($wildcard in $WildCardSearch)
                        {
                            if ($column.name -like $wildcard)
                            {
                                [pscustomobject]@{
                                    ComputerName             = $server.NetName
                                    SqlInstance              = $server.ServiceName
                                    Database                 = $db.Name
                                    Schema                   = $table.Schema
                                    Table                    = $table.Name
                                    Column                   = $column.Name
                                    ColumnType               = $column.DataType.Name + "(" + $column.DataType.MaximumLength  + ")"
                                    Contains                 = 0
                                    WildCardSearch           = 1
                                }
                            }
                        }
                    }
                } 
            } 
        }
    }
}