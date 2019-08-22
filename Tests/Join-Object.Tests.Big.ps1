#Requires -Modules Pester
#Requires -Modules PSSQLite

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
. "$ScriptRoot\TestHelpers.ps1"

$DataSetBig10k  = "$ScriptRoot\TestDataSetBig10k.db"
$DataSetBig100k = "$ScriptRoot\TestDataSetBig100k.db"

Describe -Name 'Join-Object' -Fixture {
    Context -Name ($DataSetName = 'DataSetBig100k') -Fixture {
        It -Name "Testing: <TestName>" -TestCases @(
            Format-Test @{
                Params = @{
                    Left              = @{ Table = 'authors' ; As = 'DataTable' }
                    Right             = @{ Table = 'posts' ; As = 'DataTable' }
                    LeftJoinProperty  = 'author_id'
                    RightJoinProperty = 'author_id'
                    #DataTable         = $true
                    #RightMultiMode    = 'SubGroups'
                }
            }
        ) -Test {
            param (
                $Params,
                $DataSet,
                $TestName,
                $RunScript,
                $ExpectedErrorMessage,
                [ValidateSet('Test', 'Run')]
                $ExpectedErrorOn
            )
            if ($RunScript) {
                . $RunScript
            }

            # Load Data
            try {
                $DbConnection = New-SQLiteConnection -DataSource $DataSet
                $Params.Left = Get-Params -Param $Params.Left -DbConnection $DbConnection
                $Params.Right = Get-Params -Param $Params.Right -DbConnection $DbConnection
            }
            finally {
                $DbConnection.Dispose()
            }

            # Execute Cmdlet
            $Measure = Measure-Command {
                $JoinedOutput = Join-Object @Params
            }

            if ($JoinedOutput -is [Data.DataTable]) {
                Write-Host ("Execution Time: {0}, Count: {1}, Type: {2}." -f $Measure, $JoinedOutput.Rows.Count, $JoinedOutput.GetType())
                Write-Host ('Sample:' + ($JoinedOutput.Rows[$JoinedOutput.Rows.Count - 1] | Out-String).TrimEnd())
            }
            else {
                Write-Host ("Execution Time: {0}, Count: {1}, Type: {2}." -f $Measure, $JoinedOutput.Count, $JoinedOutput.GetType())
                Write-Host ('Sample:' + ($JoinedOutput[-1] | Out-String).TrimEnd())
            }
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