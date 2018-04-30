function Update-PiiEmailAddress {
    [CmdletBinding()]
    Param (
        [parameter(Position = 0, Mandatory = $true)]
        [Alias("ServerInstance", "SqlServer", "SqlServers")]
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [array[]]$Tables,
        [string]$Database,
        [string]$Newdomain = "@test.co.uk"
    )
    begin {
        ## test connection to sql instance

        $results=@()

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
            $columnLenth = $table.Columns | Where {$_.Name -eq $tb.Column } | select parent, name, datatype, @{Name='Length'; Expression = {$_.Properties['Length'].Value}}
            if ($columnLenth.Length -eq -1){
                $columnLenth.Name
            } else {
                #$columnLenth.Parent.Name
                $tsqlTable = $table.Name
                $tsqlCol = $columnLenth.Name
        
                $tsql = "
                    UPDATE $tsqlTable
                    SET [$tsqlCol] = right(newid(),24)+'$Newdomain'
                    WHERE substring($tsqlCol,charindex('@',$tsqlCol),50) not in ('@axelos.com','@mmtdigital.co.uk','$Newdomain')
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
                    Write-Warning $_.Exception
                }
            } # end of else
        
        } # end of foreach
    } # end process

} # end function