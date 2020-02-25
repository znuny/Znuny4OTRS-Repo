# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::AddNote;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

use Kernel::System::VariableCheck qw(:all);
use base qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(ArticleID TicketID HistoryType)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %Article = $TicketObject->ArticleGet(
        ArticleID => $Param{ArticleID},
        UserID    => 1,
    );

    my $Output = <<OUTPUT;
\$TempValue = <<'BODY';
$Article{Body}
BODY

\$ArticleID = \$HelperObject->ArticleCreate(
    TicketID       => \$TicketID,
    Subject        => '$Article{Subject}',
    Body           => \$TempValue,
    ArticleType    => '$Article{ArticleType}',
    SenderType     => '$Article{SenderType}',
    From           => '$Article{From}',
    To             => '$Article{To}',
    Charset        => '$Article{Charset}',
    MimeType       => '$Article{MimeType}',
    HistoryType    => '$Param{HistoryType}',
    HistoryComment => 'UnitTest',
    UserID         => \$UserID,
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
