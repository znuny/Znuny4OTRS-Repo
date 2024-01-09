# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::Validator)

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::TimeAccounting;

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
    TicketID  => \$TicketID,
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
