# Integration of Znuny OPM Repositories

With this package you integrate Znuny repositories. Without any setting the public Znuny repository is enabled. As a Znuny customer you'll get an API key and have access to a private repostitory.


# Package verification for Znuny packages

With this package Znuny packages can be verified via OTRS.


# Option to disable package verification

With a default OTRS setup you're not able to verify packages without an internet connection. This results in a long list of error messages in the package manager. By setting the SysConfig 'PackageVerification' you enable or disable the package verification. All packages will be shown as verified when you disable the verification. You're encouraged  to disable the packet verification only in special cases.

# Hiding of non system notifications

Since version 5 of the free version of OTRS irrelevant notifications and messages occure more frequently. Those are systemwide disabled.

# Deactivation of unwanted and outbound connections

Since Version 5 OTRS opens outgoing unwanted and unauthorized network connections. These connections are often unnecessary or simply not possible through network connectivity restrictions or firewall rules and cause error entries in the log. Those connections are automatically deactivated.

## Tips
After the package installation the repository access via HTTPS is the default setting. It is possible that you get an error 500 while accessing the repository. This can be solved by installtin the Perl module LWP::Protocol::https or disabling the HTTPS access by changing the SysConfig Option 'Znuny4OTRSRepoType' to HTTP.

#### CentOS / Enterprise Linux
```
yum install perl-LWP-Protocol-https
```
#### Ubuntu
```
apt-get install liblwp-protocol-https-perl
```
#### OS X
```
cpan install LWP::Protocol::https
```
#### CPAN
```
perl -MCPAN -e 'install LWP::Protocol::https'
```
