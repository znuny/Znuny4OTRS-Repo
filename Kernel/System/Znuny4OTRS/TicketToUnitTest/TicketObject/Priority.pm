# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketObject::Priority;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Priority',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    return '' if !IsArrayRefWithData( $Param{Priority} );

    my $Output = <<OUTPUT;

# Priority setup

OUTPUT

    for my $Priority ( @{ $Param{Priority} } ) {

        my $PriorityID = $PriorityObject->PriorityLookup(
            Priority => $Priority,
        );

        my %PriorityData = $PriorityObject->PriorityGet(
            PriorityID => $PriorityID,
            UserID     => 1,
        );

        $Output .= <<OUTPUT;
## Priority '$PriorityData{Name}'

\$ZnunyHelperObject->_PriorityCreateIfNotExists(
    Name => "$PriorityData{Name}",
);

OUTPUT
    }

    return $Output;

}

1;
