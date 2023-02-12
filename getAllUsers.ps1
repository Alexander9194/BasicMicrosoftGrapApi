# Install microsoft.graph module if not installed
if (!(Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Start-Process powershell "Install-Module Microsoft.Graph" -Verb runas -Wait;
}

# Reads in the env variables from the .env file
$tempEnv = @{};
get-content .env | ForEach-Object {
    $name, $value = $_.split('=');
    $tempEnv.add($name, $value);
}
$localEnv = New-Object -TypeName PSObject -Property $tempEnv;

Function AddLocalEnv
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$key,
        [Parameter(Mandatory=$true)]
        [String]$value
    )
    $localEnv|Add-Member -NotePropertyName $key -NotePropertyValue $value;
}

# https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0
#app call function
Function ApiCall
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Url,
        [String]$Method="GET",
        $Headers=@{},
        $Body=$null
    )
    $Headers.Add("Authorization", "Bearer $($localEnv.access_token)");
    $response = Invoke-WebRequest -Uri $Url -Method $Method -Body $Body -Headers $Headers;
    return $response|ConvertFrom-Json;
}

#auth
$authUrl="https://login.microsoftonline.com/{0}/oauth2/v2.0/token" -f $localEnv.TENANT_ID;

$body = @{
    client_id=$localEnv.APP_ID
    scope="https://graph.microsoft.com/.default"
    client_secret=$localEnv.CLIENT_SECRET
    grant_type="client_credentials"
};
$out = Invoke-WebRequest -Uri $authURL -Method "POST" -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing;

$return=$out|ConvertFrom-Json;

AddLocalEnv -key "access_token" -value $return.access_token;

$users = ApiCall -Url "https://graph.microsoft.com/v1.0/users";
foreach ($user in $users.value) {
    write-host("$($user.displayName) ($($user.mail))");
}
