# --
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::PriorityUpdate;

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
    for my $Needed (qw(Priority)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Output = <<OUTPUT;
\$Success = \$TicketObject->TicketPrioritySet(
    Priority => '$Param{Priority}',
    TicketID  => \$TicketID,
    UserID    => \$UserID,
);

\$Self->True(
    \$Success,
    'TicketPrioritySet "$Param{Priority}" was successfull.',
);

OUTPUT

    return $Output;
}

1;
