# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::TimeAccounting;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);
use base qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(TimeAccounting)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Output = <<OUTPUT;
\$Success = \$TicketObject->TicketAccountTime(
    TicketID  => \$Param{TicketID},
    ArticleID => \$ArticleID,
    TimeUnit  => '$Param{TimeAccounting}',
    UserID    => \$UserID,
);

\$Self->True(
    \$Success,
    'TicketAccountTime "$Param{TimeAccounting}" was successfull.',
);

OUTPUT

    return $Output;
}

1;