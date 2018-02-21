# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketObject::State;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::State',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    return '' if !IsArrayRefWithData( $Param{State} );

    my $Output = <<OUTPUT;

# State setup

OUTPUT

    for my $State ( @{ $Param{State} } ) {

        my %StateData = $StateObject->StateGet(
            Name => $State,
        );

        $Output .= <<OUTPUT;
## State '$StateData{Name}'

\$ZnunyHelperObject->_StateCreateIfNotExists(
    Name   => '$StateData{Name}',
    TypeID => $StateData{TypeID},
);

OUTPUT

    }

    return $Output;

}

1;
