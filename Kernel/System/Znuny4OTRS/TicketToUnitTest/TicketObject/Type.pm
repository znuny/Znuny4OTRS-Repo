# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketObject::Type;

use strict;
use warnings;

our @ObjectDependencies = (
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    return '' if !IsArrayRefWithData( $Param{Type} );

    my $Output = <<OUTPUT;

# Type setup

OUTPUT

    for my $Type ( @{ $Param{Type} } ) {

        $Output .= <<OUTPUT;
## Type '$Type'

\$ZnunyHelperObject->_TypeCreateIfNotExists(
    Name => '$Type',
);

OUTPUT

    }

    return $Output;

}

1;
