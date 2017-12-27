# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::AddNote;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest::AddNote

=head1 SYNOPSIS

All TicketToUnitTest::AddNote functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestAddNoteObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest::AddNote');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

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
\$ArticleID = \$HelperObject->ArticleCreate(
    TicketID       => \$Param{TicketID},
    Subject        => '$Article{Subject}',
    Body           => '$Article{Body}',
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

# trigger Transaction events
\$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);
\$TicketObject = \$Kernel::OM->Get('Kernel::System::Ticket');

OUTPUT

    return $Output;

}

1;
