#Requires -Modules Pester
#Requires -Modules @{ ModuleName = 'Assert' ; ModuleVersion = '999.9.2' }
#Requires -Modules PSSQLite

$Verbose = @{ Verbose = $false }
#$Verbose = @{ Verbose = $true }

if ($PSScriptRoot) {
    $ScriptRoot = $PSScriptRoot
}
elseif ($psISE.CurrentFile.IsUntitled -eq $false) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
}
elseif ($null -ne $psEditor.GetEditorContext().CurrentFile.Path -and $psEditor.GetEditorContext().CurrentFile.Path -notlike 'untitled:*') {
    $ScriptRoot = Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path
}
else {
    $ScriptRoot = '.'
}

$TestDataSetBig10k = "$ScriptRoot\TestDataSetBig10k.db"
$TestDataSetBig100k = "$ScriptRoot\TestDataSetBig100k.db"

function Format-Test {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [Hashtable]$Test
    )
    if ($TestDataSetName, $Test.Params.Left, $Test.Params.Right, $Test.Description -contains $null) {
        Throw 'Missing param'
    }

    $Test.TestName = '{0}, {3}. {1} - {2}' -f $TestDataSetName, ($Test.Params.Left.Values -join ''), ($Test.Params.Right.Values -join ''), $Test.Description
    $Test
}

function Get-Params {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [Hashtable]$Param
    )
    $Output = Invoke-SqliteQuery -DataSource (Get-Variable -Name $TestDataSetName -ValueOnly) -Query ('SELECT * FROM {0}' -f $Param.Table) -As $Param.As
    , $Output
}

Describe -Name 'Join-Object' -Fixture {
    $TestDataSetName = 'TestDataSetBig100k'
    Context -Name $TestDataSetName -Fixture {
        It -name "Testing <TestName>" -TestCases @(
            Format-Test @{
                Description = 'Basic'
                Params      = @{
                    Left              = @{ Table = 'authors' ; As = 'DataTable' }
                    Right             = @{ Table = 'posts' ; As = 'DataTable' }
                    LeftJoinProperty  = 'author_id'
                    RightJoinProperty = 'author_id'
                    #DataTable         = $true
                    #RightMultiMode    = 'SubGroups'
                }
            }
        ) -test {
            param (
                $Params,
                #$TestDataSet,
                $TestName,
                $Description,
                $RunScript
            )
            #if ($TestName -ne 'Small: PSCustomObjects - DataTable, DataTable') { Continue }

            # Load Data
            if ($RunScript) {
                . $RunScript
            }
            $Params.Left = Get-Params -Param $Params.Left
            $Params.Right = Get-Params -Param $Params.Right

            # Execute Cmdlet
            $Measure = Measure-Command {
                $JoinedOutput = Join-Object @Params
            }
            Write-Host ("Execution Time: {0}, Count: {1}, Sample: {2}" -f $Measure, $JoinedOutput.Count, $JoinedOutput[-1])
        }
    }
}

<# http://filldb.info
CREATE TABLE `authors` (
	`author_id` INT(11) NOT NULL AUTO_INCREMENT,
	`first_name` VARCHAR(50) NOT NULL COLLATE 'utf8_unicode_ci',
	`last_name` VARCHAR(50) NOT NULL COLLATE 'utf8_unicode_ci',
	`email` VARCHAR(100) NOT NULL COLLATE 'utf8_unicode_ci',
	`birthdate` DATE NOT NULL,
	`added` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`author_id`),
	UNIQUE INDEX `email` (`email`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB;

CREATE TABLE `posts` (
	`post_id` INT(11) NOT NULL AUTO_INCREMENT,
	`author_id` INT(11) NOT NULL,
	`title` VARCHAR(255) NOT NULL COLLATE 'utf8_unicode_ci',
	`description` VARCHAR(500) NOT NULL COLLATE 'utf8_unicode_ci',
	`content` TEXT NOT NULL COLLATE 'utf8_unicode_ci',
	`date` DATE NOT NULL,
	PRIMARY KEY (`post_id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB;
#>
<# SQLite
DROP TABLE IF EXISTS `authors`;
CREATE TABLE `authors` (
  `author_id` int(11) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL UNIQUE,
  `birthdate` date NOT NULL,
  `added` timestamp NOT NULL DEFAULT current_timestamp,
  PRIMARY KEY (`author_id`)
);
DROP TABLE IF EXISTS `posts`;
CREATE TABLE `posts` (
  `post_id` int(11) NOT NULL,
  `author_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` varchar(500) NOT NULL,
  `content` text NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`post_id`)
);
#>