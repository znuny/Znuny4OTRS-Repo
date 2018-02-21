# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketObject::Queue;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Queue',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    return '' if !IsArrayRefWithData( $Param{Queue} );

    my $Output = <<OUTPUT;

# Queue setup

OUTPUT

    for my $Queue ( @{ $Param{Queue} } ) {

        my %QueueData = $QueueObject->QueueGet(
            Name => $Queue,
        );

        for my $Value ( sort keys %QueueData ) {
            $QueueData{$Value} //= '';
        }

        $Output .= <<OUTPUT;
## Queue '$QueueData{Name}'

\$ZnunyHelperObject->_QueueCreateIfNotExists(
    Name                => '$QueueData{Name}',
    GroupID             => 1,
    ValidID             => '$QueueData{ValidID}',
    Calendar            => '$QueueData{Calendar}',
    FirstResponseTime   => '$QueueData{FirstResponseTime}',
    FirstResponseNotify => '$QueueData{FirstResponseNotify}',
    UpdateTime          => '$QueueData{UpdateTime}',
    UpdateNotify        => '$QueueData{UpdateNotify}',
    SolutionTime        => '$QueueData{SolutionTime}',
    SolutionNotify      => '$QueueData{SolutionNotify}',
    UnlockTimeout       => '$QueueData{UnlockTimeout}',
    FollowUpID          => '$QueueData{FollowUpID}',
    FollowUpLock        => '$QueueData{FollowUpLock}',
    DefaultSignKey      => '$QueueData{DefaultSignKey}',
    SystemAddressID     => 1,
    SalutationID        => 1,
    SignatureID         => 1,
    Comment             => '$QueueData{Comment}',
    UserID              => \$UserID,
);

OUTPUT

    }

    return $Output;

}

1;
