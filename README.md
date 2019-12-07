# Install-RemoteDesktopCertificate.ps1

## Overview

The `Install-RemoteDesktopCertificate.ps1` PowerShell Script is my method for installing a [Let's Encrypt](https://letsencrypt.org) trusted certificate for Remote Desktop sessions (not RDP Gateway). This is cheap (as in free) way to get rid of the self-signed certificates that are automatically installed on Windows for securing RDP sessions and the annoying pop-ups all Windows administrators face when remoting to a Windows system. Let's Encrypt certificates are publicly trusted and are better method of securing than a self-signed certificate. The script makes the assumption you have a method for obtaining Let's Encrypt certificates. I personally use [acme.sh](https://github.com/Neilpang/acme.sh) and DNS to procure certificates. Please understand the requirements of Let's Encrypt usage before jumping into this process for the first time. If you make a mistake, you can be throttled from the service.

There is an effort on this script to test and verify that the certificate is installed for RDP sessions successfully. Because of the short term nature of Let's Encrypt certificates, you will be updating your local certificate at least every 90 days.

Because this PowerShell script modifies the local certificate store, you will require local Administrator rights in order to successfully execute it. If you do not have the required elevated privileges you will receive a similar error message as displayed below.

```powershell
(Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))): Failed to import certificate: C:\Users\Administrator\Desktop\test.ad.toups.io.pfx Exiting. At C:\Users\Administrator\Documents\git\Install-RemoteDesktopCertificate\Install-RemoteDesktopCertificate.ps1:80 char:3
+   throw "($ErrorMessage): $SpecificReason Exiting."
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: ((Access is deni...io.pfx Exiting.:String) [], RuntimeException
    + FullyQualifiedErrorId : (Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))): Failed to import certificate: C:\Users\Administrator\Desktop\test.toups.io.pfx Exiting.
```

## Syntax

```powershell
Install-RemoteDesktopCertificate.ps1 [-Path <String>] [-Password <SecureString>] [-CertificateStoreLocation] <String> [-LetsEncryptDistinguishedName] <String>
```

## Parameters

### -Path

The Path to the Let's Encrypt PFX file.

```yaml
Type: String
Parameter Sets: (ALL)
Aliases: f

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password

The password for the private key. This is a secure string.

```yaml
Type: SecureString
Parameter Sets: (ALL)
Aliases: p

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalFqdn

The location to store the Let's Encrypt PFX certificate.

```yaml
Type: String
Parameter Sets: (ALL)
Aliases:

Required: False
Position: 2
Default value: (([System.Net.Dns]::GetHostByName(($env:COMPUTERNAME))).Hostname).ToLower()
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateStoreLocation

The location to store the Let's Encrypt PFX certificate.

```yaml
Type: String
Parameter Sets: (ALL)
Aliases:

Required: False
Position: 3
Default value: 'Cert:\LocalMachine\My'
Accept pipeline input: False
Accept wildcard characters: False
```

### -LetsEncryptDistinguishedName

The distinguished name for Let's Encrypt.

```yaml
Type: String
Parameter Sets: (ALL)
Aliases:

Required: False
Position: 4
Default value: "CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US"
Accept pipeline input: False
Accept wildcard characters: False
```

## Examples

This example will allow you to type in the PFX certificate password manually as a secure string.

```powershell
PS > .\Install-RemoteDesktopCertificate.ps1 -Path .\test.toups.io.pfx
Certificate PFX Password: ***********
```

This example will allow you to type in the PFX certificate password manually as a secure string and set the local fully qualified domain name of the computer.

```powershell
PS > .\Install-RemoteDesktopCertificate.ps1 -Path .\test.toups.io.pfx -LocalFqdn 'test.ad.toups.io'
Certificate PFX Password: ***********
```

This example will take a plain text password string, convert it to a secure string and pass it to the script.

```powershell
PS > $CertificatePassword = ConvertTo-SecureString -String '$up3r$3cur3!' -Force -AsPlainText
PS > .\Install-RemoteDesktopCertificate.ps1 -Path .\test.toups.io.pfx -Password $CertificatePassword
```

## Tips

### Review PFX Certificate Created from a Let's Encrypt Certificate Request

```powershell
PS > $CertificatePassword = ConvertTo-SecureString -String '$up3r$3cur3!' -Force -AsPlainText
PS > Get-PfxData -FilePath .\test.ad.toups.io.pfx -Password $CertificatePassword | Select-Object -ExpandProperty 'EndEntityCertificates' | Format-List -Property '*'


EnhancedKeyUsageList     : {Server Authentication (1.3.6.1.5.5.7.3.1), Client Authentication (1.3.6.1.5.5.7.3.2)}
DnsNameList              : {test.ad.toups.io}
SendAsTrustedIssuer      : False
EnrollmentPolicyEndPoint : Microsoft.CertificateServices.Commands.EnrollmentEndPointProperty
EnrollmentServerEndPoint : Microsoft.CertificateServices.Commands.EnrollmentEndPointProperty
PolicyId                 :
Archived                 : False
Extensions               : {System.Security.Cryptography.Oid, System.Security.Cryptography.Oid,
                           System.Security.Cryptography.Oid, System.Security.Cryptography.Oid...}
FriendlyName             :
IssuerName               : System.Security.Cryptography.X509Certificates.X500DistinguishedName
NotAfter                 : 3/2/2020 4:59:07 PM
NotBefore                : 12/3/2019 4:59:07 PM
HasPrivateKey            : True
PrivateKey               :
PublicKey                : System.Security.Cryptography.X509Certificates.PublicKey
RawData                  : {48, 130, 6, 97...}
SerialNumber             : 04E1F84D8F8CAA7BED7E731692C9F2A84CDB
SubjectName              : System.Security.Cryptography.X509Certificates.X500DistinguishedName
SignatureAlgorithm       : System.Security.Cryptography.Oid
Thumbprint               : 4293D5FF5A2D18212D5868D24948E3557365BFA0
Version                  : 3
Handle                   : 1757146484560
Issuer                   : CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US
Subject                  : CN=test.ad.toups.io
```

### Create a PFX Certificate from Let's Encrypt using openssl

You will need access to openssl to generate a PFX certificate from a Let's Encrypt certificate request shown in this example. You can learn more about openssl for Windows at the [official GitHub site](https://github.com/openssl/openssl). I personally use Linux when generating PFX certificates.

#### Sample File Listing from a Let's Encrypt Certificate Request

```powershell
PS C:\Users\adm-toups\Desktop\test.ad.toups.io> Get-ChildItem


    Directory: C:\Users\adm-toups\Desktop\test.ad.toups.io


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        12/5/2019   1:41 PM           1648 ca.cer
-a----        12/5/2019   1:41 PM           3563 fullchain.cer
-a----        12/5/2019   1:41 PM           1915 test.ad.toups.io.cer
-a----        12/5/2019   1:41 PM            557 test.ad.toups.io.conf
-a----        12/5/2019   1:41 PM            980 test.ad.toups.io.csr
-a----        12/5/2019   1:41 PM            211 test.ad.toups.io.csr.conf
-a----        12/5/2019   1:41 PM           1675 test.ad.toups.io.key
```

#### Create a PFX Certificate using openssl

You will need to supply a password which you will need to remember for the import. This example is running in Linux but a similar procedure would be used when performing with the Win32 version of openssl.

```bash
[~/.acme.sh/test.ad.toups.io]
[14:22:20] test.ad.toups.io $ openssl pkcs12 -export -out test.ad.toups.io.pfx -inkey test.ad.toups.io.key -in test.ad.toups.io.cer -certfile fullchain.cer
Enter Export Password: ***********
Verifying - Enter Export Password: ***********
```

### How to Rollback from a Failed Installation

If for some reason the installation of the certificate causes your Remote Desktop Session to fail, you can roll back easily by deleting the newly installed Let's Encrypt certificate and restarting the **Remote Desktop Configuration** Windows Service.

#### Sample Code

You must know the Certificate thumbprint to insert into the variable.

##### Discover the Certificate Thumbprint

```powershell
Get-ChildItem -Path 'Cert:\LocalMachine\My' | Sort-Object -Property NotAfter -Descending | Format-Table -Property Thumbprint,Subject,NotAfter
```

##### Remove the Certificate & Restart Remote Desktop Configuration Windows Service

```powershell
$CertificateThumbprint = '4293D5FF5A2D18212D5868D24948E3557365BFA0'
Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object {$_.Thumbprint -eq $CertificateThumbprint } | Remove-Item
Restart-Service -Name 'SessionEnv'
```

## Project Tooling

The following tooling was used in the production of this project.

- [Let's Encrypt](https://letsencrypt.org)
- [acme.sh](https://github.com/Neilpang/acme.sh)
- [openssl](https://www.openssl.org)
- [Visual Studio Code](https://code.visualstudio.com/download)
- [Code Spell Checker Visual Studio Code Plugin](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)
- [Typora](https://typora.io)

(c) 2019 [Robert M. Toups, Jr.](mailto:robert@toups.io)
