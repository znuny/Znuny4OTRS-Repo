# Funktionalität

## Einbindung von Znuny-OPM-Repositorys
Mit diesem Paket können Znuny-OPM-Repositorys im OTRS-Paketmanager eingebunden werden, um Zugriff auf öffentliche Znuny-OTRS-Pakete zu erhalten. Sofern Sie einen API-Key von Znuny erhalten haben, erhalten Sie über diesen Zugriff auf die Ihnen zusätzlich zur Verfügung gestellten Pakete.

## API-Key
Falls Sie einen API-Key von Znuny erhalten haben, hinterlegen Sie diesen bitte in der SysConfig-Option __Znuny4OTRSPrivatRepos__.

## Paketverifizierung auch für Znuny-Pakete
Znuny-Pakete werden als verifiziert angezeigt.

## Deaktivierung der Paketverifizierung
In OTRS ist es nicht möglich, Pakete ohne Anbindung an das Internet als verifiziert anzeigen zu lassen. Dies kann zu einer langen, unübersichtlichen Liste von Fehlermeldungen in der Paketverwaltung führen. Dieses Paket ermöglicht es, die Paketverifizierung über die SysConfig-Option __PackageVerification__ zu steuern und zu deaktivieren. Ist die Paketverifizierung deaktiviert, werden alle Pakete als verifiziert angezeigt. Generell ist es ratsam, die Paketverifizierung nur in Sonderfällen zu deaktivieren.

## Ausgehende Kommunikation des Paketmanagers
Mit der SysConfig-Option __Znuny4OTRSRepoDisable__ kann ausgehende Kommunikation des Paketmanagers deaktiviert werden.

### Installation eines ggf. fehlenden Perl-Moduls
Bei der Nutzung von HTTPS als Protokoll - was nach der Installation des Paketes automatisch aktiviert wird - besteht die Möglichkeit, dass ein Fehler 500 beim Zugriff auf das Repository gemeldet wird. Das Problem wird mit der Installation des Perl-Moduls __LWP::Protocol::https__ beseitigt, alternativ kann auch in der SysConfig die Einstellung __Znuny4OTRSRepoType__ auf __HTTP__ umgeschaltet werden.

#### Installation unter CentOS/Enterprise Linux
```
yum install perl-LWP-Protocol-https
```
#### Installation unter Ubuntu
```
apt-get install liblwp-protocol-https-perl
```
#### Installation unter macOS
```
cpan install LWP::Protocol::https
```
#### Installation via CPAN
```
perl -MCPAN -e 'install LWP::Protocol::https'
```

### Deaktivierte SysConfig-Optionen
Folgende SysConfig-Optionen werden mit der Installation dieses Pakets deaktiviert.

- Frontend::Module###AdminRegistration
- Package::ShowFeatureAddons
- Daemon::SchedulerCronTaskManager::Task###OTRSBusinessEntitlementCheck
- Daemon::SchedulerCronTaskManager::Task###OTRSBusinessAvailabilityCheck
- Notification::Transport###NotificationView
- Notification::Transport###SMS
- Frontend::Module###AdminCloudServices
- Frontend::Module###AdminOTRSBusiness
- Frontend::NotifyModule###100-OTRSBusiness
- CustomerFrontend::NotifyModule###1-OTRSBusiness
- Daemon::SchedulerCronTaskManager::Task###RegistrationUpdateSend
- Daemon::SchedulerCronTaskManager::Task###SupportDataCollectAsynchronous
