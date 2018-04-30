function Find-PiiEmailAddress {
<#

.SYNOPSIS
Searchs top X number of rows from each table for email addresses uses regex.

.DESCRIPTION
Loops every tables thouse ommited with the ignoreTable parameter then based on a "SELECT TOP ($SearchRows) * FROM <TABLE>" runs a regex on every returned column to look for email address's.

.PARAMETER SqlInstance
SQL Server name or SMO object representing the SQL Server to connect to. This can be a collection and receive pipeline input

.PARAMETER SqlCredential
PSCredential object to connect as. If not specified, current Windows login will be used.

.PARAMETER Database
The database(s) to process - this list is auto-populated from the server. If unspecified, all databases will be processed.

.PARAMETER ExcludeDatabase
The database(s) to exclude - this list is auto-populated from the server

.PARAMETER SearchRows
Used for the SELECT TOP command ran against each row.

.PARAMETER IgnoreTable
Array to ignore tables from the search, can help speed up things, or stop you getting notified of emails in columns if its known false postive.

.NOTES
Author: Stephen Bennett 

Website: https://sqlnotesfromtheunderground.wordpress.com/
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.LINK


.EXAMPLE
Find-EmailAddress -SqlInstance localhost -Database myDB -SearchRows 10
Returns any tables columns with email addresses found in the top 10 rows of the search for the localhost myDB database.

.EXAMPLE
$it = "dbo.tbl1","dbo.tbl2","dbo.tbl3",
Find-EmailAddress -SqlInstance localhost -Database myDB, myDB2 -SearchRows 10 -IgnoreTable $it
Returns any tables columns with email addresses found in the top 10 rows of the search. looking at both mydb and mydb2 databases and ignore the tables in $it array 

#>

    [CmdletBinding()]
    Param (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $True)]
        [Alias("ServerInstance", "SqlServer", "SqlServers")]
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [Alias("Databases")]
        [object[]]$Database,
        [object[]]$ExcludeDatabase,
        [int]$SearchRows = 10,
        [string[]]$ignoreTable
    )
    begin {
        $output = @()
        try {
            #$server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $SqlCredential -MinimumVersion 9
            Write-Verbose "connecting to SQL Server instance: $SqlInstance"
            $server = Connect-DbaInstance -SqlInstance $SqlInstance -Credential $SqlCredential
        }
        catch {
            Write-Warning "Failed to connect to instance"
        }
    }
    process {

            #Use IsAccessible instead of Status -eq 'normal' because databases that are on readable secondaries for AG or mirroring replicas will cause errors to be thrown
            Write-Verbose "Collecting databases to query"
            $dbs = $server.Databases | Where-Object { $_.IsAccessible -eq $true -and $_.IsSystemObject -eq $false }
            if ($Database) {
                $dbs = $server.Databases | Where-Object Name -In $Database
            }

            if ($ExcludeDatabase) {
                $dbs = $dbs | Where-Object Name -NotIn $ExcludeDatabase
            }

            if (!($dbs)){
                Write-Warning "No databases found meeting critera please check spelling"
                break
            }
            foreach ($db in $dbs) {
                Write-Verbose "reading from database: $db"
                #Write-Message -Level Verbose -Message "Searching on database $db"
                $Tables = $server.databases[$db.Name].Tables
                if ($ignoreTable){
                    $tblsWithRows = $Tables | Where-object {$_.RowCount -gt 0 -and $_.Name -notcontains $ignoreTable }
                } else {
                    $tblsWithRows = $Tables | Where-object {$_.RowCount -gt 0}
                }
                
                foreach ($tbl in $tblsWithRows){
                    Write-Verbose "reading from table: $($tbl.Schema).$($tbl.Name)"
                    #$query = $server.databases[$db.Name].ExecuteWithResults("SELECT TOP ($SearchRows) * FROM $($tbl.Schema).$($tbl.Name)")             
                    try {
                        $query = $server.Databases[$db.NAme].executeWithResults("SELECT TOP ($SearchRows) * FROM $($tbl.Schema).$($tbl.Name)").Tables[0].Rows 
                    }
                    catch {
                        Write-Warning "Failed to connect or get results from: $($tbl.Schema).$($tbl.Name)"
                    }
                    if ($query){
                        $query | Get-Member -MemberType Property | foreach {
                            $prop = $_.Name
                            $search = $query.$prop
                            if((Select-String -InputObject $search -Pattern '\w+@\w+\.\w+' -AllMatches).Matches){
                                $object = [PSCustomObject]@{
                                    Database = $db
                                    Schema = $tbl.Schema
                                    Table = $tbl.Name
                                    Column = $prop
                                    Example = $search
                                }
                                $output+= $object
                                }
                        }
                    }
                } # FOREACH
            }
    } # process end
    end {
        $output
    }
} # function end

