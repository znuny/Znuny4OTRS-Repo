# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::Unlock;

use strict;
use warnings;

our @ObjectDependencies = ();

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest::Unlock

=head1 SYNOPSIS

All TicketToUnitTest::Unlock functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestUnlockObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest::Unlock');

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
\$Success = \$TicketObject->TicketLockSet(
    Lock     => 'lock',
    TicketID => \$Param{TicketID},
    UserID   => \$UserID,
);

\$Self->True(
    \$Success,
    'TicketLockSet to "lock" was successfull.',
);

OUTPUT

    return $Output;

}

1;
