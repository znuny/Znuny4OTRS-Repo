# Einbindung Znuny OPM Repositories

Über dieses Paket können Znuny OPM Repositories eingebunden werden. Per Default wird das öffentliche Znuny Repository aktiviert. Es besteht auch der Zugriff auf private Repositories.


# Paketverifizierung auch von Znuny Paketen

Mit diesem Paket können Znuny Pakete über OTRS verifiziert werden.


# Deaktivieren der Paketverifizierung

Im OTRS Standard ist es nicht möglich Pakete ohne Anbindung an das Internet als verifiziert anzeigen zu lassen. Das kann zu einer langen, unübersichtlichen Liste von Fehlermeldungen in der Paketverwaltung führen. Dieses Paket ermöglicht es die Paketverifizierung über die SysConfig 'PackageVerification' zu steuern und zu deaktivieren. Ist die Paketverifizierung deaktiviert, werden alle Pakete als verifiziert angezeigt. Generell ist es ratsam die Paketverifizierung nur in Sonderfällen zu deaktivieren.

## Hinweise
Bei der Nutzung von HTTPS als Protokoll, was nach der Installation des Paketes aktiviert ist, besteht die Möglichkeit das ein Fehler 500 beim Zugriff auf das Repository gemeldet wird. Das Problem wird mit der Installation des Perl-Modules LWP::Protocol::https beseitigt, alternativ kann auch in der SysConfig die Einstellung "Znuny4OTRSRepoType" auf HTTP umgeschaltet werden.

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

