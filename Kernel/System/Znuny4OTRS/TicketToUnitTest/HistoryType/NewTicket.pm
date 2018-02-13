# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::NewTicket;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Ticket',
);

use Kernel::System::VariableCheck qw(:all);
use base qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Queue Priority State Type OwnerID ResponsibleID CustomerUser CustomerID Service SLA )) {
        $Param{$Needed} //= '';
    }

    my $Output = <<OUTPUT;
\$Param{TicketID} = \$HelperObject->TicketCreate(
    Queue         => '$Param{Queue}',
    Priority      => '$Param{Priority}',
    State         => '$Param{State}',
    Type          => '$Param{Type}',
    OwnerID       => '$Param{OwnerID}',
    ResponsibleID => '$Param{ResponsibleID}',
    CustomerUser  => '$Param{CustomerUser}',
    CustomerID    => '$Param{CustomerID}',
    Service       => '$Param{Service}',
    SLA           => '$Param{SLA}',
);

# trigger transaction events
\$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);
\$TicketObject = \$Kernel::OM->Get('Kernel::System::Ticket');

OUTPUT

    return $Output;

}

1;
