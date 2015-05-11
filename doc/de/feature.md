# Einbindung Znuny OPM Repositories

Über dieses Paket können Znuny OPM Repositories eingebunden werden. Per Default wird das öffentliche Znuny Repository aktiviert. Es besteht auch der Zugriff auf private Repositories.


# Paketverifizierung auch von Znuny Paketen

Mit diesem Paket können Znuny Paketen über OTRS verifiziert werden.


# Deaktivieren der Paketverifizierung

Im OTRS Standard ist es nicht möglich Pakete ohne Anbindung an das Internet als verifiziert anzeigen zu lassen. Das kann zu einer langen, unübersichtlichen Liste von Fehlermeldungen in der Paketverwaltung führen. Dieses Paket ermöglicht es die Paketverifizierung über die SysConfig 'PackageVerification' zu steuern und zu deaktivieren. Ist die Paketverifizierung deaktiviert, werden alle Pakete als verifiziert angezeigt. Generell ist es ratsam die Paketverifizierung nur in Sonderfällen zu deaktivieren.