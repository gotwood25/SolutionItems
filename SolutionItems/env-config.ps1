#quick little script to update the config files
#used by the framework because I'm too lazy to
#change the files manually :-)
#R. PECKETT 23/09/2015
#HOW TO USE
#open powershell command prompt
#type:
#Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#(if you don't have admin this won't work and you can
#stop reading now)
#hit Y
#Type:
#Test-Path $profile
#Should return false
#New-Item -path $profile -type file –force
#open your newly created profile, profile file path:
#C:\Users\your.username\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#edit the file in some kind of text editor or powershell ISE if you have it
#add a line like so:
#New-Item alias:envcfg -value C:\TFS\vNext\TestPlans\VPC4PMasterLibrary\SolutionItems\env-config.ps1
#the alias is the command you want to type into your powershell prompt to switch environments, example
#about I've set mine to be 'envcfg'
#note - the PATH to the env-config.ps1 script will be different to the above, it depends on where you've
#got the solution checked out, modify the above accordingly

Function Get-ScriptDirectory {
    
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    If($Invocation.PSScriptRoot)
    {
        $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        Split-Path $Invocation.MyCommand.Path
    }
    Else
    {
        $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
    }
}

Function Remove-Crlf {

    param([string]$filepath)
    $stream = [IO.File]::OpenWrite($filepath)
    $stream.SetLength($stream.Length - 2)
    $stream.Close()
    $stream.Dispose()

}

Function Create-HtmlLink {
	param([string]$url)
	$link = "<p><a href=""$url"">$url</a></p>"
	return $link
}

Function Create-HtmlLine {
	param([string]$pline)
	$newpline = "<p>$pline</p>"
	return $newpline
}

Function Html-Writer {
	param([string]$doctitle, [string]$content, [string]$htmloutfile)
	
	$arrHtml = @()
	$arrHtml += "<!doctype html>"
	$arrHtml += "<html lang=""en"">"
	$arrHtml += "<head>"
	$arrHtml += "<meta charset=""utf-8"">"
	$arrHtml += "<title>$doctitle</title>"
	$arrHtml += "<meta name=""description"" content=""$doctitle"">"
	$arrHtml += "<meta name=""author"" content=""SitePoint"">"
	$arrHtml += "</head>"
	$arrHtml += "<body>"
	$arrHtml += "$content"
	$arrHtml += "</body>"
	$arrHtml += "</html>"
	
	$arrHtml | out-file -filepath $htmloutfile
	
	}

Function Open-Html{
    
    param([string]$htmlfile)
    Start-Process "chrome.exe" "$htmlfile"
    Main-Menu
}

Function Environment-Report {

    $URLList = Get-Content $global:EnvListFile -ErrorAction SilentlyContinue
    $Result = @()
    
    Foreach($Uri in $URLList) {
        $time = try{
            $request = $null
            ## Request the URI, and measure how long the response took.
            $result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri
            }
            $result1.TotalMilliseconds
    }
        catch
    {
    
    <# If the request generated an exception (i.e.: 500 server
    error or 404 not found), we can pull the status code from the 
    Exception.Response property #>
    
    $request = $_.Exception.Response
    
    $time = -1
    
    }

      $result += [PSCustomObject] @{
        Time = Get-Date;
        Uri = $uri;
        StatusCode = [int]$request.StatusCode;
        StatusDescription = $request.StatusDescription;
        ResponseLength = $request.RawContentLength;
        TimeTaken =  $time;
        }
        
    }
    
    if($result -ne $null) {
    
    $Outputreport = "<HTML><TITLE>Environment Availability Report</TITLE><BODY background-color:peachpuff><font color =""#99000"" face=""Microsoft Tai le""><H2> Environment & API Availability Report </H2></font><Table border=1 cellpadding=0 cellspacing=0><TR bgcolor=gray align=center><TD><B>URL</B></TD><TD><B>StatusCode</B></TD><TD><B>StatusDescription</B></TD><TD><B>ResponseLength</B></TD><TD><B>TimeTaken</B></TD</TR>" 
    
    Foreach($Entry in $Result)
    
    { 
        if($Entry.StatusCode -eq "0")
        {
            $Outputreport += "<TR bgcolor=red>"
        }
        elseif ($Entry.StatusCode -eq "503")
        {
            $Outputreport += "<TR bgcolor=red>"
        }
		elseif ($Entry.StatusCode -eq "500")
        {
            $Outputreport += "<TR bgcolor=red>"
        }
        elseif($Entry.StatusCode -eq "403")
        {
            $Outputreport += "<TR bgcolor=green>"
        }
        elseif ($Entry.StatusCode -eq "200")
        {
            $Outputreport += "<TR bgcolor=green>"
        }
        else
        {
            $Outputreport += "<TR>"
        }
        
        if ($Entry.StatusDescription -eq "Forbidden")
        {
            $Entry.StatusDescription = "API Available"
        }
        elseif ($Entry.StatusDescription -eq $null)
        {
            $Entry.StatusDescription = "Unreachable"
        }

        $Outputreport += "<TD>$($Entry.uri)</TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.timetaken)</TD></TR>" 
    }
    
    $Outputreport += "</Table></BODY></HTML>"

    }
    
    $Outputreport | Out-File $global:reportfile
    Invoke-Expression $global:reportfile
    Main-Menu
}

Function Wait-ForUser {
    param([string]$message)
    
    Write-Host ""
    Write-Host $message -ForegroundColor Cyan
    Read-Host -Prompt "Press Enter to continue"
    Write-Host ""
}

Function Check-EnterpriseListExists {

    If(!(Test-Path -Path $global:myentlist)) #if enterprise list doesn't exist, create one
    {
        Write-Host ""
        Write-Host "No Default Enterprise list exists, creating a new one."
        New-Item -path $global:myentlist -type "file"
        #add the content into the file
        Echo "1,AUTO TEST ENTERPRISE" | Set-Content $global:myentlist
        Remove-Crlf -filepath $global:myentlist
    }

}

Function Check-EnterpriseListNotBlank
{
        If((Get-Content $global:myentlist) -eq $null)
        {
            Write-Host "Default Enterprise list is blank, adding a default enterprise '1,AUTO TEST ENTERPRISE' to list" -ForegroundColor Red
            Echo "1,AUTO TEST ENTERPRISE" | Set-Content $global:myentlist
            Remove-Crlf -filepath $global:myentlist
        }       
}

Function Update-DefaultEnt
{
    param([string]$default_enterprise)

    (Get-Content $global:configfile) |
    Foreach-Object {$_ -replace "<add key=""DefaultEnterprise"" value="".*""/>", "<add key=""DefaultEnterprise"" value=""$default_enterprise""/>"} |
    Set-Content $global:configfile

    (Get-Content $global:debug_configfile) |
    Foreach-Object {$_ -replace "<add key=""DefaultEnterprise"" value="".*""/>", "<add key=""DefaultEnterprise"" value=""$default_enterprise""/>"} |
    Set-Content $global:debug_configfile
}

Function Prompt-Timeout
{
	$timeout = Read-Host "Enter a numeric timeout value"
	if($timeout -match "[0-9]")
	{
		Edit-Timeouts -timeout_value $timeout
	}
	else
	{
		Write-Host "Enter numeric values only." -ForegroundColor Red
		Read-Host -Prompt "[press any key to continue]"
		Prompt-Timeout
	}
}

Function Edit-Timeouts
{	
	param([string]$timeout_value)
	#<add key="ExplicitWaitTimeOut" value="20"/>
    #<add key="ImplicitWaitTimeOut" value="20"/>
	
	(Get-Content $global:configfile) |
    Foreach-Object {$_ -replace "<add key=""ExplicitWaitTimeOut"" value="".*""/>", "<add key=""ExplicitWaitTimeOut"" value=""$timeout_value""/>"} |
    Set-Content $global:configfile
	
	(Get-Content $global:debug_configfile) |
    Foreach-Object {$_ -replace "<add key=""ExplicitWaitTimeOut"" value="".*""/>", "<add key=""ExplicitWaitTimeOut"" value=""$timeout_value""/>"} |
    Set-Content $global:debug_configfile
	
	(Get-Content $global:configfile) |
    Foreach-Object {$_ -replace "<add key=""ImplicitWaitTimeOut"" value="".*""/>", "<add key=""ImplicitWaitTimeOut"" value=""$timeout_value""/>"} |
    Set-Content $global:configfile
	
	(Get-Content $global:debug_configfile) |
    Foreach-Object {$_ -replace "<add key=""ImplicitWaitTimeOut"" value="".*""/>", "<add key=""ImplicitWaitTimeOut"" value=""$timeout_value""/>"} |
    Set-Content $global:debug_configfile
	
	Write-Host "WebDriver timeouts set to $timeout_value seconds" -ForegroundColor Green
	Read-Host -Prompt "[press any key to continue]"
	Main-Menu
}

Function Edit-Enterprises
{
    notepad $global:myentlist
    Main-Menu
}

Function Set-DefaultEnterprise
{
    Check-EnterpriseListNotBlank

    Write-Host "============================================================================================================"
    Write-Host ""
    Write-Host "You have the following default enterprises configured:"
    Write-Host ""

    $lines = Get-Content $global:myentlist | Measure-Object -Line
    [int32]$max = $lines.Lines

    foreach ($ent in Get-Content $global:myentlist)
        {
            Write-Host $ent.Split(",")[0] $ent.Split(",")[1]
        }

    do {
            Write-Host "Enter a value:"
            $user_ent = read-host
            $value = $user_ent -as [Double]
            $ok = $value -ne $NULL
            if ( -not $ok ) { write-host "You must enter a numeric value" }
        }
        
        until ( $ok )

    Write-Host "You entered: $user_ent"
            
            If ($user_ent -le $max)
                {
                    [int32]$user_ent_index = $user_ent -1
                    $ent_selection = Get-Content $global:myentlist | Select -Index $user_ent_index
                    $ent_selection = $ent_selection.Split(",")[1]
                    Update-DefaultEnt -default_enterprise $ent_selection
                    Wait-ForUser -message "Default Enterprise updated to $ent_selection"
                    Main-Menu
                }
            
            Else {
                    Write-Host "Invalid enterprise added, please enter a value between 1 and $max " -ForegroundColor Red
                    Set-DefaultEnterprise
                 }
}

Function Tools-Options
{
    Param([ValidateSet(1, 2, 3)][int]$option)

    Process
    {

    switch ($option){
        1 { #edit my enterprise list
        Edit-Enterprises
        }
        
        2 { #set my default enterprise in the config files
        Set-DefaultEnterprise
        }
        
        3 { #set the browser
        Set-DefaultBrowser
        }
       }
    }
}

Function Check-EnterpriseNotNull {
    
    $files = $global:configfile, $global:debug_configfile
    
    foreach ($file in $files) {
    
    $null_ent = $null
    
    $null_ent = Get-Content $file | Select-String -Pattern "<add key=""DefaultEnterprise"" value=""""/>"
    
    If ($null_ent)
        {
            Write-Host $file " - NO DEFAULT ENTERPRISE IN CONFIG, SETTING DEFAULT 'AUTO TEST ENTERPRISE'" -ForegroundColor Red
        
            (Get-Content $file) |
            Foreach-Object {$_ -replace "<add key=""DefaultEnterprise"" value=""""/>", "<add key=""DefaultEnterprise"" value=""AUTO TEST ENTERPRISE""/>"} |
            Set-Content $file
        }
    }
}

Function Current-Config {


	. $scriptdir\cfg-regex.ps1
	$rgx = Get-ConfigFileRegexHashTable

	$arrCurrentConfig = @()
    
	#explanation of regex - `$(?<!\-->) means ignore it if it has "\-->" on the end
	
    $arrCurrentConfig += "==============================================================="
    $title = Create-HtmlLine -pline "Automation Framework - Current Config:"
    $arrCurrentConfig += $title
    $arrCurrentConfig += "==============================================================="

    $urlsHtml = Create-HtmlLine -pline "Web and Api Urls:"
    $arrCurrentConfig += $urlsHtml
	
    #main config file
	[string]$current_url = Get-Content $global:configfile | Select-String -Pattern $rgx."WebUri"
	$current_url = $Matches[1]
	$arrCurrentConfig += Create-HtmlLink -url $current_url
	    
    #api config file
    [string]$current_api_config = Get-Content $global:apiconfigfile | Select-String -Pattern "(<add key=""BaseURI"" value="".*""\s?/>)`$(?<!\-->)"
	$current_api_config -match '(?<=value=)"(.*?)"' | Out-Null
	$current_api_config = $Matches[1]
	$arrCurrentConfig += Create-HtmlLink -url $Matches[1]
	
    [string]$current_browser = Get-Content $global:configfile | Select-String -Pattern "<add key=""BrowserType"" value="".*""/>"
	$current_browser -match '(?<=value=)"(.*?)"' | Out-Null
	$current_browser = $Matches[1]
	$arrCurrentConfig += Create-HtmlLine -pline "Browser = $current_browser"
    
	[string]$current_enterprise = Get-Content $global:configfile | Select-String -Pattern "<add key=""DefaultEnterprise"" value="".*""/>"
	$current_enterprise -match '(?<=value=)"(.*?)"' | Out-Null
	$current_enterprise = $Matches[1]
	$arrCurrentConfig += Create-HtmlLine -pline "Default Enterprise = $current_enterprise"

    #debug config file
    [string]$current_url_debug = Get-Content $global:debug_configfile | Select-String -Pattern "(<add key=""BaseVpc4PWebUri"" value="".*""/>)`$(?<!\-->)"
	$current_url_debug -match '(?<=value=)"(.*?)"' | Out-Null
	$current_url_debug = $Matches[1]
    
	[string]$current_browser_debug = Get-Content $global:debug_configfile | Select-String -Pattern "<add key=""BrowserType"" value="".*""/>"
	$current_browser_debug -match '(?<=value=)"(.*?)"' | Out-Null
	$current_browser_debug = $Matches[1]
    
	[string]$current_enterprise_debug = Get-Content $global:debug_configfile | Select-String -Pattern "<add key=""DefaultEnterprise"" value="".*""/>"
	$current_enterprise_debug -match '(?<=value=)"(.*?)"' | Out-Null
	$current_enterprise_debug = $Matches[1]
	
	[string]$current_exp_debug = Get-Content $global:debug_configfile | Select-String -Pattern "<add key=""ExplicitWaitTimeOut"" value="".*""/>"
	$current_exp_debug -match '(?<=value=)"(.*?)"' | Out-Null
	$current_exp_debug = $Matches[1]
	
	[string]$current_imp_debug = Get-Content $global:debug_configfile | Select-String -Pattern "<add key=""ImplicitWaitTimeOut"" value="".*""/>"
	$current_imp_debug -match '(?<=value=)"(.*?)"' | Out-Null
	$current_imp_debug = $Matches[1]
    
	#debug api config file
    [string]$current_api_debug = Get-Content $global:debug_apiconfigfile | Select-String -Pattern "(<add key=""BaseURI"" value="".*""\s?/>)`$(?<!\-->)"
	$current_api_debug -match '(?<=value=)"(.*?)"' | Out-Null
	$current_api_debug = $Matches[1]
    
    #path file    
    [string]$current_path_debug = Get-Content $global:debug_configpathfile
	
	#Write-Host $arrCurrentConfig -ForegroundColor Red
	
	Html-Writer -doctitle "Current Config" -content $arrCurrentConfig -htmloutfile $global:confightml
	
	Write-Host "CURRENT CONFIG (type 'boom' to open in Chrome):" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Main Config File = $global:configfile :" -ForegroundColor Cyan
    Write-Host "Url = $current_url" -ForegroundColor Green
    Write-Host "Default Browser = $current_browser" -ForegroundColor Green
    Write-Host "Default Enterprise = $current_enterprise" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------------------------------------------"
    Write-Host "Debug Config File = $global:debug_configfile :" -ForegroundColor Cyan
    Write-Host "Url = $current_url_debug" -ForegroundColor Yellow
    Write-Host "Default Browser = $current_browser_debug" -ForegroundColor Yellow
    Write-Host "Default Enterprise = $current_enterprise_debug" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------------------------------"
    Write-Host "Main Api Config File = $global:apiconfigfile :" -ForegroundColor Cyan
    Write-Host "Api Url = $current_api_config" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------------------------------------------"
    Write-Host "Api Debug Config File = $global:debug_apiconfigfile :" -ForegroundColor Cyan
    Write-Host "Api Url = $current_api_debug" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------------------------------"
    Write-Host "Debug Config Path = $global:debug_configpathfile :"
    Write-Host "Path to Config File = $current_path_debug"
	Write-Host "------------------------------------------------------------------------------------------------------------"
	Write-Host "WebDriver Timeouts (Seconds):"
	Write-Host "Implicit = $current_imp_debug"
	Write-Host "Explicit = $current_exp_debug"
	Write-Host "!Consider upping these values if tests are repeatidly failing or the VPC system is slow (Option 99 Jeff)!" -ForegroundColor Yellow
	Write-Host "------------------------------------------------------------------------------------------------------------"
}

Function Check-Framework {

    Write-Host "Checking framework..." -ForegroundColor Cyan

    If ( -Not (Test-Path $global:configfile)) {     
            Throw "File $global:configfile does not exist, solution is missing a file?"
        }
    Else { 
            Write-Host "Config file location = "$global:configfile -ForegroundColor Green
    }

    If ( -Not(Test-Path $global:debug_configfile)) {
        Throw "File $global:debug_configfile does not exist, you may need to build solution is Visual Studio first."
    }
    Else {
        Write-Host "Debug folder config file location = "$global:debug_configfile -ForeGroundColor Green
    }
    
    If ( -Not (Test-Path $global:debug_apiconfigfile)) {        
            Throw "File $global:debug_apiconfigfile does not exist, you may need to build solution is Visual Studio first."
            }
    Else {
            Write-Host "API config file location = "$global:apiconfigfile -ForegroundColor Green
            Write-Host "Debug folder API config file location = "$global:debug_apiconfigfile -ForegroundColor Green
    }

    If( -Not (Test-Path -Path $global:debug_configpathfile)) #if config path file doesn't exist, create it.
    {
        Write-Host "No default config path file exists, creating a new one (maybe the first time the solution has been setup?)"
        New-Item -path $global:debug_configpathfile -type "file"
        Echo ".\TestConfigFiles\VPC4P.config" | Set-Content $global:debug_configpathfile
        Remove-Crlf -filepath $global:debug_configpathfile
    }
    Else
    {
        Write-Host "Config path file exists." -ForegroundColor Green
    }
	
	If(!(Test-Path -Path $global:EnvListFile)) #if config path file doesn't exist, create it.
    {
		New-Item $global:EnvListFile -type file
    }
	Update-EnvListFile
}

Function Update-EnvListFile
{
	Clear-Content $global:EnvListFile
	
	$uris = $global:xmlenvcfg.SelectNodes("//ENV/URI").InnerText
	$apis = $global:xmlenvcfg.SelectNodes("//ENV/API").InnerText

	foreach($uri in $uris)
	{
		if($uri -ne "")
		{
			$uri | Add-Content $global:EnvListFile
		}
	}

	foreach($api in $apis)
	{
		if($api -ne "")
		{
			$api | Add-Content $global:EnvListFile
		}	
	}    
		Remove-Crlf -filepath $global:EnvListFile
}

##################################### DISPLAY ALL AVAILABLE BROWSERS FROM XML FILE #############################################
Function Set-DefaultBrowser
{
        Write-Host "============================================================================================================"
        Write-Host "Choose Default Browser:" -ForegroundColor Cyan
        $global:xmlenvcfg.selectNodes('/Settings/BROWSERS/BROW') | select Name, Option | Format-List

        $arrValidBrowsers = @()
        foreach ($node in $global:xmlenvcfg.Settings.Browsers.BROW) { $arrValidBrowsers += $node.Option }
        
        #foreach ($opt in $arrValidBrowsers) { Write-Host $opt }
        
        $browserChoice = Read-Host "(Select a browser)"

        if ($arrValidBrowsers.Contains($browserChoice))
        {
            $selectedBrowser = $global:xmlenvcfg.SelectSingleNode("//BROW[@Option='$browserChoice']/Name").InnerText

            Update-Browser -browser $selectedBrowser
        }
        else
        {
            Write-Host "Invalid option entered, please enter a valid browser option." -ForegroundColor Red
            Write-Host "(press any key to continue)"
            Read-Host
            Set-DefaultBrowser
        }
}

Function Environment-Menu {
    
    Write-Host "============================================================================================================"
    Write-Host "Choose Environment (to add to add more environments update XML config file):" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "UK:" -ForegroundColor Green
    $global:xmlenvcfg.selectNodes('//UK/ENV') | select Name, URI, Option | Format-List
    Write-Host "North America:" -ForegroundColor Green
    $global:xmlenvcfg.selectNodes('//USA/ENV') | select Name, URI, Option | Format-List
    Write-Host "Australia:" -ForegroundColor Green
    $global:xmlenvcfg.selectNodes('//AUS/ENV') | select Name, URI, Option | Format-List
    Write-Host "Choose Environment (to add more environments update XML config file):" -ForegroundColor Cyan

    #read all options into an array in order to validate user input:
    $arrValidInputs = @()
    foreach ($node in $global:xmlenvcfg.Settings.TestEnvironments.UK.ENV)
    {
        $arrValidInputs += $node.Option
    }
    foreach ($node in $global:xmlenvcfg.Settings.TestEnvironments.USA.ENV)
    {
        $arrValidInputs += $node.Option
    }
    foreach ($node in $global:xmlenvcfg.Settings.TestEnvironments.AUS.ENV)
    {
        $arrValidInputs += $node.Option
    }
	
	Write-Host "($arrValidInputs):" -ForegroundColor Cyan

    $envinput = Read-Host "[choose option]"

    if ($arrValidInputs.Contains($envinput))
    {
        $name = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/Name").InnerText
        $uri = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/URI").InnerText
        $entguid = "" #enterprise guid not currently used...
        $guid = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/GUID").InnerText
        $clientid = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/ClientId").InnerText
        $clientpw = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/ClientPw").InnerText
        $clientsec = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/ClientSecret").InnerText
        $api = $global:xmlenvcfg.SelectSingleNode("//ENV[@Option='$envinput']/API").InnerText
        
        Environment-Switch -name $name -TestEnvUrl $uri -DefaultEnterpriseGUID $entguid -GUID $guid -IdentityServiceClientId $clientid -IdentityServicePW $clientpw -IdentityServiceClientSecret $clientsec -ApiUrl $api
    }
    else
    {
        Write-Host "Invalid environment selected, enter a valid option." -ForegroundColor Red
        Read-Host "(press any key to continue)"
        Environment-Menu
    }
}

Function Environment-Switch
{
    param(
    [string]$name, [string]$TestEnvUrl, [string]$DefaultEnterpriseGUID,
    [string]$GUID, [string]$IdentityServiceClientId, [string]$IdentityServicePW,
    [string]$IdentityServiceClientSecret, [string]$ApiUrl)

    $files = $global:configfile, $global:debug_configfile

    foreach ($file in $files)
    
    {

    (Get-Content $file) |
    Foreach-Object {$_ -replace "(<add key=""BaseVpc4PWebUri"" value="".*""/>)`$(?<!\-->)", "<add key=""BaseVpc4PWebUri"" value=""$TestEnvUrl""/>"} |
    Set-Content $file

    (Get-Content $file) |
    Foreach-Object {$_ -replace "(<add key=""DefaultEnterpriseGUID"" value="".*"".*/>)`$(?<!\-->)", "<add key=""DefaultEnterpriseGUID"" value=""$DefaultEnterpriseGUID""/>"} |
    Set-Content $file
    
    (Get-Content $file) |
    Foreach-Object {$_ -replace "(<add key=""GUID"" value="".*"".*/>)`$(?<!\-->)", "<add key=""GUID"" value=""$GUID""/>"} |
    Set-Content $file

    (Get-Content $file) |
    Foreach-Object {$_ -replace "(<add key=""IdentityServiceClientId"" value="".*"".*/>)`$(?<!\-->)", "<add key=""IdentityServiceClientId"" value=""$IdentityServiceClientId""/>"} |
    Set-Content $file

    (Get-Content $file) |
    Foreach-Object {$_ -replace "(<add key=""IdentityServicePW"" value="".*"".*/>)`$(?<!\-->)", "<add key=""IdentityServicePW"" value=""$IdentityServicePW""/>"} |
    Set-Content $file

    (Get-Content $file) |
    Foreach-Object {$_ -replace "(<add key=""IdentityServiceClientSecret"" value="".*"".*/>)`$(?<!\-->)", "<add key=""IdentityServiceClientSecret"" value=""$IdentityServiceClientSecret""/>"} |
    Set-Content $file
    
    }

    $files = $null

    $files = $global:apiconfigfile, $global:debug_apiconfigfile

    foreach ($file in $files)
    
    {

    (Get-Content $file) |
    ForEach-Object { $_ -replace "(<add key=""BaseURI"" value="".*""\s?/>)`$(?<!\-->)", "<add key=""BaseURI"" value=""$ApiUrl""/>" } |
    Set-Content $file
    
    }

    Wait-ForUser -message "Framework has been configured to use $name ($TestEnvUrl)"
    Main-Menu

}

Function Update-Browser
{
    param([string]$browser)

    $files = $global:configfile, $global:debug_configfile

    foreach ($file in $files)
    
    { 

    (Get-Content $file) |
    Foreach-Object {$_ -replace "<add key=""BrowserType"" value="".*""/>", "<add key=""BrowserType"" value=""$browser""/>"} |
    Set-Content $file

    }

    Wait-ForUser -message "Default Browser Updated to $browser."
    
    Main-Menu
}

Function Install-NUnit
{
    Add-Type -assembly "system.io.compression.filesystem"

    if(!(Test-Path -path "c:\automation_tools"))
    {
        New-Item c:\automation_tools -type directory
    }

    $Source = 'http://github.com/nunit/nunitv2/releases/download/2.6.4/NUnit-2.6.4.zip'
    $LocalCopy = "c:\automation_tools\NUnit-2.6.4.zip"
    Invoke-WebRequest -uri $Source -OutFile $LocalCopy
    Write-Host "Dowloading NUnit..." -ForegroundColor Blue
    Unblock-File $LocalCopy

    Write-Host "Extracting NUnit..." -ForegroundColor Blue
    [io.compression.zipfile]::ExtractToDirectory($LocalCopy, "c:\automation_tools\nunit")

    Remove-Item $LocalCopy

    Read-Host "(NUnit installation complete, press any key to continue)"

    Hit-It

    Main-Menu
}

Function Hit-It()
{
    Process-Killer -process "NUnit-Agent" -waitflag $false
    Process-Killer -process "nunit" -waitflag $false
    
    $sln = "$global:solution_root\VPCRegression.sln"
    $vslocation = $global:xmlenvcfg.Settings.ToolSettings.VsLocation
    $nulocation = $global:xmlenvcfg.Settings.ToolSettings.NUnitLocation

    cd $global:solution_root

    Write-Host "Getting latest automation framework code..."
    & "$vslocation\TF.exe" get $/VCS/QA_Automation/vNext /recursive
        
    cd $vslocation

    .\devenv $sln /Clean
    .\devenv $sln /Rebuild

    Write-Host "******************* BUILD COMPLETE *******************" -ForegroundColor Green
    Read-Host "(press any key to start NUnit)"

    if (!(Test-Path -path $nulocation))
    {
        Write-Host "(couldn't find NUnit, will attempt to install...)" -ForegroundColor Yellow
        Install-NUnit
    }
    else
    {
    Write-Host "Starting NUnit..." -ForegroundColor Green

    $project = $global:xmlenvcfg.SelectSingleNode("/Settings/ToolSettings/NUnitProjectFile").InnerText

    & "$nulocation\nunit.exe" /config $project
    }
    
    Main-Menu
}

Function Edit-CfgXml()
{
    if(!(Test-Path -path "C:\Program Files (x86)\Notepad++"))
    {
        notepad "$global:scriptdir\env-config.xml"
    }
    else
    {
        & C:\"Program Files (x86)"\Notepad++\notepad++.exe $global:scriptdir\env-config.xml
    }

    Main-Menu
}

Function Process-Killer($process, [bool]$waitflag)
{
    $processActive = Get-Process -Name $process -ErrorAction SilentlyContinue
    
    if($processActive -eq $null)
    {
        Write-host "No $process instances running." -ForegroundColor Green
    }
    else
    {
        Write-host "Killing all active $process instances..." -ForegroundColor Red
        
        if ($process -eq "chromedriver")
        {
            Write-host "Any automated tests that are currently running will be stopped." -ForegroundColor Yellow
        }
        
        Get-Process -Name $process
        Get-Process -Name $process | Stop-Process -Force  
    }
    
    if ($waitflag -eq $true)
    {
        Read-Host "(press any key to continue)"
        Main-Menu
    }
}

Function Utils-Menu
{
Write-Host "============================================================================================================"
Write-Host "                                         Test Automation Framework                                          " -ForegroundColor Cyan
Write-Host "                                              Config Utility                                                " -ForegroundColor Cyan
Write-Host "                                             (utilities menu)                                               " -ForegroundColor Cyan
Write-Host "============================================================================================================"
Write-Host ""
Write-Host "OPTIONS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1  Install NUnit"
Write-Host "2  Environments Report (can take a while to run, if you get bored of waiting hit ctrl-c)"
Write-Host "3  Modify Config Utility XML" -ForegroundColor Cyan
Write-Host "4  Modify Web Driver Timeouts" -ForegroundColor Yellow
Write-Host ""
Write-Host "0  (Main Menu)"
[int]$input = Read-Host "[choose option]"

if ($input -eq 1) {
    Install-NUnit
    }
elseif ($input -eq 2)
    {
    Environment-Report
    }
elseif ($input -eq 3)
    {
    Edit-CfgXml
    }
elseif ($input -eq 4)
	{
	Prompt-Timeout
	}
elseif ($input -eq 0)
    {
    Main-Menu
    }
else
    {
    Write-Host "(enter a valid option)" -ForegroundColor Red
    Utils-Menu
    }
}

Function Main-Menu
{
[System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
Write-Host "============================================================================================================"
Write-Host "                                         Test Automation Framework                                          " -ForegroundColor Cyan
Write-Host "                                              Config Utility                                                " -ForegroundColor Cyan
Write-Host "                                               (main menu)                                                  " -ForegroundColor Cyan
Write-Host "============================================================================================================"
Current-Config
Write-Host ""
Write-Host "OPTIONS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1  View/Edit My Default Enterprise List"
Write-Host "2  Set New Default Enterprise"
Write-Host "3  Set Default Browser"
Write-Host "4  Choose New Environment"
Write-Host "5  Kill Chrome Driver/NUnit Instances"
Write-Host "6  Get Latest, Clean, Build, Launch NUnit" -ForegroundColor Green
Write-Host ""
Write-Host "99  (Open Utilities Menu)"
Write-Host ""
Write-Host "0  Exit"
Write-Host ""

[int]$input = Read-Host "[choose option]"

if ($input -gt 0 -and $input -le 3) {
    Tools-Options -option $input
    }
elseif ($input -eq 4)
    {
    Environment-Menu
    }
elseif ($input -eq 5)
    {
    Process-Killer -process "chromedriver" -waitflag $true
    Process-Killer -process "NUnit-Agent" -waitflag $true
    }
elseif ($input -eq 6)
    {
    Hit-It
    }
elseif ($input -eq 99)
    {
    Utils-Menu
    }
elseif ($input -eq "boom")
    {
    Open-Html -htmlfile $global:confightml
    }
elseif ($input -eq 0) {
    Exit
    }
}

$global:scriptdir = Get-ScriptDirectory


$parent_dir = Split-Path $scriptdir -Parent

#yet another config file for the script
[xml]$global:xmlenvcfg = Get-Content "$global:scriptdir\env-config.xml"

#this is awful... find a better way
$global:solution_root = Split-Path $scriptdir -Parent
$global:solution_root = Split-Path $solution_root -Parent
$global:solution_root = Split-Path $solution_root -Parent

#make these global because we don't want to keep passing them all over the script:

#these files contain the URL for the application and parameters required to access the api
$global:configfile = "$solution_root\Adapters\VCS.Automation.VPC4PAdapter\VPC4P.config"
$global:debug_configfile = "$parent_dir\bin\Debug\VPC4P.config"

#these files contain the URL for the API only
$global:apiconfigfile = "$parent_dir\app.config" #(this file gets copied and renamed to the file below in debug folder):
$global:debug_apiconfigfile = "$parent_dir\bin\Debug\VPC4PMasterLibrary.dll.config"

#the path file that the framework relies on to tell it which config file to use
$global:debug_configpathfile = "$parent_dir\bin\Debug\ConfigFilePath.config"

#location of the file which allows the tester to specify their own list of enterprises
$global:myentlist = "$scriptdir\my-enterprises.txt"

#file which contains the env. urls for availability testing
$global:EnvListFile = "$scriptdir\TestEnvUrls.txt"
$global:reportfile = "$scriptdir\Report.htm"

#file for displaying current config in html format
$global:confightml = "$env:USERPROFILE\envcfg.html"

Check-Framework
Check-EnterpriseListExists
Check-EnterpriseNotNull
Main-Menu