# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::ServiceUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Service)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Output = <<OUTPUT;
\$Success = \$TicketObject->TicketServiceSet(
    Service  => '$Param{Service}',
    TicketID => \$TicketID,
    UserID   => \$UserID,
);

\$Self->True(
    \$Success,
    'TicketServiceSet to "$Param{Service}" was successfull.',
);

OUTPUT

    return $Output;
}

1;
