# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
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

    return 1;
}

1;
