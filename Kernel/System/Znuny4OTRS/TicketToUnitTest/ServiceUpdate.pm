# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::ServiceUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest::ServiceUpdate

=head1 SYNOPSIS

All TicketToUnitTest::ServiceUpdate functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestServiceUpdateObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest::ServiceUpdate');

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

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
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
    TicketID => \$Param{TicketID},
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
