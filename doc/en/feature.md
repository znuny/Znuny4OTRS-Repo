# Functionality

## Integration of Znuny OPM repositories
With this package, Znuny OPM repositories can be included in the OTRS package manager to get access to public Znuny OTRS packages. If you have received an API key from Znuny, this gives you access to the additional packages provided to you.

## API key
If you have received an API key from Znuny, please store it in the SysConfig option __Znuny4OTRSPrivatRepos__.

## Package verification also for Znuny packages
Znuny packages are displayed as verified.

## Disabling package verification
In OTRS it is not possible to display packages as verified without connection to the Internet. This can lead to a long, confusing list of error messages in package management. This package allows you to control and disable package verification using the __PackageVerification__ SysConfig option. If package verification is disabled, all packages are displayed as verified. In general, it is advisable to deactivate package verification only in special cases.

## Outgoing communication of the package manager
With the SysConfig option __Znuny4OTRSRepoDisable__ outgoing communication of the package manager can be deactivated.

### Installation of a possibly missing Perl module
When using HTTPS as a protocol - which is automatically activated after the installation of the package - there is the possibility that an error 500 is reported when accessing the repository. The problem is solved by installing the Perl module __LWP::Protocol::https__, alternatively the setting __Znuny4OTRSRepoType__ can be switched to __HTTP__ in SysConfig.

#### Installation on CentOS/Enterprise Linux
```
yum install perl-LWP-Protocol-https
```
#### Installation on Ubuntu
```
apt-get install liblwp-protocol-https-perl
```
#### Installation on macOS
```
cpan install LWP::Protocol::https
```
#### Installation via CPAN
```
perl -MCPAN -e 'install LWP::Protocol::https'
```

### Disabled SysConfig options
The following SysConfig options will be disabled when you install this package.

- Frontend::Modules####AdminRegistration
- Package::ShowFeatureAddons
- Daemon::SchedulerCronTaskManager::Task####OTRSBusinessEntitlementCheck
- Daemon::SchedulerCronTaskManager::Task####OTRSBusinessAvailabilityCheck
- Notification::Transport####NotificationView
- Notification::Transport####SMS
- Frontend::Modules####AdminCloudServices
- Frontend::Modules####AdminOTRSBusiness
- Frontend::NotifyModule####100-OTRSBusiness
- CustomerFrontend::NotifyModule####1-OTRSBusiness
- Daemon::SchedulerCronTaskManager::Task###RegistrationUpdateSend
- Daemon::SchedulerCronTaskManager::Task###SupportDataCollectAsynchronous
