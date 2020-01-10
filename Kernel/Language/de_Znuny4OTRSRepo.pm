# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Znuny4OTRSRepo;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    # TicketToUnitTest - SysConfig
    $Self->{Translation}->{'Create analysis file'} = 'Erstelle Analysedatei';
    $Self->{Translation}->{'Send analysis file'}   = 'Sende Analysedatei';

    $Self->{Translation}->{'Creates a analysis file from this ticket.'}                    = 'Erstellt einen Analysedatei von diesem Ticket.';
    $Self->{Translation}->{'Creates a analysis file from this ticket and sends to Znuny.'} = 'Erstellt einen Analysedatei von diesem Ticket und sendet ihn an Znuny.';

    # AdminZnuny4OTRSFiles
    $Self->{Translation}->{'Manage system files.'} = 'Systemdateien verwalten';
    $Self->{Translation}->{'System file support'}  = 'Systemdatei-Support';
    $Self->{Translation}->{'Package'}              = 'Paket';
    $Self->{Translation}->{'Package files - %s'}   = 'Paketdateien - %s';
    $Self->{Translation}->{'Custom files'}         = 'Angepasste Dateien';
    $Self->{Translation}->{'Changed files'}        = 'Geänderte Dateien';
    $Self->{Translation}->{'FullPath'}             = 'Voller Pfad';
    $Self->{Translation}->{'StateMessage'}         = 'Statusmeldung';
    $Self->{Translation}->{'OriginalMD5'}          = 'Original-MD5';
    $Self->{Translation}->{'Delete cache'}         = 'Cache löschen';

    return 1;
}

1;
