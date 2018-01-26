# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::NewTicket;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Ticket',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest::NewTicket

=head1 SYNOPSIS

All TicketToUnitTest::NewTicket functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestNewTicketObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest::NewTicket');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Queue Priority State Type OwnerID ResponsibleID CustomerUser CustomerID Service SLA )) {
        $Param{$Needed} //= '';
    }

    my $Output = <<OUTPUT;
my \$Param{TicketID} = \$HelperObject->TicketCreate(
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

# trigger Transaction events
\$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);
\$TicketObject = \$Kernel::OM->Get('Kernel::System::Ticket');

OUTPUT

    return $Output;

}

1;
