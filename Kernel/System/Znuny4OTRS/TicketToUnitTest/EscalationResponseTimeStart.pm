# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::EscalationResponseTimeStart;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Ticket',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest::EscalationResponseTimeStart

=head1 SYNOPSIS

All TicketToUnitTest::EscalationResponseTimeStart functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestEscalationResponseTimeStartObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest::EscalationResponseTimeStart');

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

    my $Output = <<OUTPUT;
\$GenericAgentObject->JobRun(
    Job    => 'trigger escalation events',
    Config => {
        Escalation => 1,
        New        => {
            Module => 'Kernel::System::GenericAgent::TriggerEscalationStartEvents',
        },
    },
    Limit  => 100_000_000,
    UserID => 1,
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
