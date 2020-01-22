#Requires -Version 4
#Requires -Modules PKI
#----------------------------------------------------------------------------------------------------------------------#
# Install-RemoteDesktopCertificate.ps1
# by Robert M. Toups, Jr.
# robert@toups.io
# (c) 2019 Toups Design Bureau
#----------------------------------------------------------------------------------------------------------------------#
param(
  # The Path to the Let's Encrypt PFX file.
  [Parameter(
    Position = 0,
    Mandatory = $true,
    HelpMessage = "The Path to the Let's Encrypt PFX file."
  )]
  [Alias('f')]
  [ValidateScript(
    { Test-Path -Path $_ -PathType 'Leaf' -Filter '*.pfx' }
  )]
  [String]
  $Path,

  # The password for the private key. This is a secure string.
  [Parameter(
    Position = 1,
    Mandatory = $false,
    HelpMessage = 'The password for the private key. This is a secure string.'
  )]
  [Alias('p')]
  [ValidateNotNull()]
  [SecureString]
  $Password = (Read-Host -Prompt 'Certificate PFX Password' -AsSecureString),

  # The fully qualified domain name of the system.
  [Parameter(
    Position = 2,
    Mandatory = $false,
    HelpMessage = 'The fully qualified domain name of the system.'
  )]
  [ValidateNotNull()]
  [String]
  $LocalFqdn = $((([System.Net.Dns]::GetHostByName(($env:COMPUTERNAME))).Hostname).ToLower()),

  # The location to store the Let's Encrypt PFX certificate.
  [Parameter(
    Position = 3,
    Mandatory = $false,
    HelpMessage = "The location to store the Let's Encrypt PFX certificate."
  )]
  [ValidateNotNull()]
  [String]
  $CertificateStoreLocation = 'Cert:\LocalMachine\My',

  # The distinguished name for Let's Encrypt.
  [Parameter(
    Position = 4,
    Mandatory = $false,
    HelpMessage = "The distinguished name for Let's Encrypt."
  )]
  [ValidateNotNull()]
  [String]
  $LetsEncryptDistinguishedName = "CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US"
)
#----------------------------------------------------------------------------------------------------------------------#
# Let's Be Strict About This
#----------------------------------------------------------------------------------------------------------------------#
Set-StrictMode -Version Latest
#----------------------------------------------------------------------------------------------------------------------#
# Start the Clock
#----------------------------------------------------------------------------------------------------------------------#
$RunTime = [System.Diagnostics.Stopwatch]::StartNew()
#----------------------------------------------------------------------------------------------------------------------#
# Set the Subject
#----------------------------------------------------------------------------------------------------------------------#
$Subject = "CN=$LocalFqdn"
#----------------------------------------------------------------------------------------------------------------------#
# Install Let's Encrypt PFX Certificate into $CertificateStoreLocation
#----------------------------------------------------------------------------------------------------------------------#
$ArgumentCollection = @{
  FilePath          = $Path
  Password          = $Password
  CertStoreLocation = $CertificateStoreLocation
}
try {
  $null = Import-PfxCertificate @ArgumentCollection
} catch {
  $SpecificReason = "Failed to import certificate: $Path"
  $ErrorMessage = $PSItem.Exception.Message
  throw "($ErrorMessage): $SpecificReason Exiting."
}
#----------------------------------------------------------------------------------------------------------------------#
# Obtain Current Remote Desktop Configuration
#----------------------------------------------------------------------------------------------------------------------#
$ArgumentCollection = @{
  Class       = 'Win32_TSGeneralSetting'
  Namespace   = 'ROOT/cimv2/terminalservices'
  Filter      = "TerminalName='RDP-tcp'"
  ErrorAction = 'Stop'
}
try {
  $RemoteDesktopSetting = Get-WmiObject @ArgumentCollection
} catch {
  $SpecificReason = "Failed to obtain the Remote Desktop Configuration."
  $ErrorMessage = $PSItem.Exception.Message
  throw "($ErrorMessage): $SpecificReason Exiting."
}
#----------------------------------------------------------------------------------------------------------------------#
# Locate Newly Installed Certificate Thumbprint
#----------------------------------------------------------------------------------------------------------------------#
$CertificateThumbprint = Get-ChildItem -Path $CertificateStoreLocation |
  Where-Object { $_.Issuer -eq $LetsEncryptDistinguishedName -and $_.Subject -eq $Subject } |
  Select-Object -ExpandProperty 'Thumbprint'
if($null -eq $CertificateThumbprint) {
  throw "Unable to locate Let's Encrypt Certificate that was imported."
}
#----------------------------------------------------------------------------------------------------------------------#
# Assign Certificate Thumbprint to Remote Desktop Configuration
#----------------------------------------------------------------------------------------------------------------------#
$ArgumentCollection = @{
  Path        = $RemoteDesktopSetting.__path
  Argument    = @{ SSLCertificateSHA1Hash = "$CertificateThumbprint" }
  ErrorAction = 'Stop'
}
try {
  $null = Set-WmiInstance @ArgumentCollection
} catch {
  $SpecificReason = "Unable to apply the new certificate to the Remote Desktop configuration."
  $ErrorMessage = $PSItem.Exception.Message
  throw "($ErrorMessage): $SpecificReason Exiting."
}
#----------------------------------------------------------------------------------------------------------------------#
# Validate Install
#----------------------------------------------------------------------------------------------------------------------#
$ArgumentCollection = @{
  Class       = 'Win32_TSGeneralSetting'
  Namespace   = 'ROOT/cimv2/terminalservices'
  Filter      = "TerminalName='RDP-tcp'"
  ErrorAction = 'Stop'
}
try {
  $RemoteDesktopSetting = Get-WmiObject @ArgumentCollection
} catch {
  $SpecificReason = "Failed to obtain the Remote Desktop Configuration."
  $ErrorMessage = $PSItem.Exception.Message
  throw "($ErrorMessage): $SpecificReason Exiting."
}
if($RemoteDesktopSetting.SSLCertificateSHA1Hash -eq $CertificateThumbprint) {
  Write-Host "Successfully imported and installed $Path" -ForegroundColor 'Green'
} else {
  Write-Host "Failed to import and install $Path" -ForegroundColor 'Yellow'
}
#----------------------------------------------------------------------------------------------------------------------#
# Stop the Clock
#----------------------------------------------------------------------------------------------------------------------#
Write-Host "Run Time: $($RunTime.Elapsed.ToString().Split('.')[0])" -ForegroundColor 'Green'
