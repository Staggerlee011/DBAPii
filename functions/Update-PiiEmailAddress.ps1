function Update-PiiEmailAddress {
<#

.SYNOPSIS
Updates all rows in columns with a new random GUID for the username and parameter for the domain.

.DESCRIPTION
Meant to be used with Find-PiiEmailAddress (Which finds columns in your database that have email address in) to update those rows with a new email. Great for simple implementation for moving data from prod to dev.

.PARAMETER SqlInstance
SQL Server name or SMO object representing the SQL Server to connect to. This can be a collection and receive pipeline input

.PARAMETER SqlCredential
PSCredential object to connect as. If not specified, current Windows login will be used.

.PARAMETER Database
The database to run the update on

.PARAMETER Tables
This is the piped value from Find-PiiEmailAddress it should be an object in the format of: Database,Schema,Table,Column

.PARAMETER Newdomain
This sets the domain for the all the new email address that are updated. (SHould start @)

.PARAMETER IgnoreDomain
This is a array of strings (All should start @) of domains that you want to NOT over write.

.NOTES
Author: Stephen Bennett

Website: https://sqlnotesfromtheunderground.wordpress.com/
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.LINK


.EXAMPLE
$TablesAndColumns = Find-PiiEmailAddress -SqlInstance localhost -Database myDB -SearchRows 20
Update-PiiEmailAddress -SqlInstance "." -Database myDB -Newdomain "@myWorkdomain.com"
First we create a PSCustomobject with the output of Find-PiiEmailAddress, we then use that as our input for Update-PiiEmailAddress

.EXAMPLE
Find-PiiEmailAddress -SqlInstance "." -Database myDB | Update-PiiEmailAddress -SqlInstance "." -Database myDB -Newdomain "@myWorkdomain.com"
An example of piping from Find-PiiEmailAddress to Update-PiiEmailAddress

.EXAMPLE
FindPiiEmailAddress -SqlInstance "." -Database myDB -IgnoreDomain "@gmail.com", "@google.com" -NewDomain "Test-Google.com"
This will up the email addresses for every column unless they are in the gmail.com or google.com updating them to test-google.com
#>
    [CmdletBinding()]
    Param (
        [parameter(Position = 0, Mandatory = $true)]
        [Alias("ServerInstance", "SqlServer", "SqlServers")]
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [array[]]$Tables,
        [string]$Database,
        [string]$Newdomain = "@test.co.uk",
        [string[]]$IgnoreDomain
    )
    begin {
        ## test connection to sql instance
        try {
            $conn = Connect-DbaInstance -SqlInstance $SqlInstance
        } catch {
            Write-Warning "Failed to connect to instance"
            break
        }
        ## test input has correct formatting
        try {
            $Tables.Table | Out-Null
        } catch {
            Write-Warning "Input doesnt have a table field! this is needed please re-format correctly"
            break
        }

    }
    process {
        Write-Verbose "reading from input, Tables input has $($Tables.Count) rows"

        foreach ($tb in $Tables) {
            Write-Verbose "Updating table: $($tb.Table) Column: $($tb.Column)"
            $table = $conn.Databases[$Database].Tables[$($tb.Table)]
            $columnLenth = $table.Columns | Where-Object {$_.Name -eq $tb.Column } | Select-Object parent, name, datatype, @{Name='Length'; Expression = {$_.Properties['Length'].Value}}
            if ($columnLenth.Length -eq -1){
                $columnLenth.Name
            } else {
                #$columnLenth.Parent.Name
                $tsqlTable = $table.Name
                $tsqlCol = $columnLenth.Name
                $Ignore = ""
                foreach ($dom in $IgnoreDomain){
                    $ignore += "'$dom', "
                }
                $tsql = "
                    UPDATE $tsqlTable
                    SET [$tsqlCol] = right(newid(),24)+'$Newdomain'
                    WHERE substring($tsqlCol,charindex('@',$tsqlCol),50) not in ($ignore'$Newdomain')
                "
                try{
                    $conn.Databases[$Database].ExecuteWithResults($tsql) | Out-Null
                    [pscustomobject]@{
						SQLInstance = $SqlInstance
						Database = $Database
						Table = "$($tb.Schema).$($tb.Table)"
						Column = $($tb.Column)
						Updated = $true
                    }
                }
                catch {
                    Write-Warning "Error running: $tsql"
                }
            } # end of else

        } # end of foreach
    } # end process

} # end function