# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::HistoryType::TicketDynamicFieldUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    $Param{Name} =~ /^\%\%FieldName\%\%(.+?)\%\%Value\%\%(.*?)(?:\%\%|$)/;

    my $FieldName = $1;
    my $Value = $2 || '';

    my $Output = <<OUTPUT;
\$TempValue = \$DynamicFieldObject->DynamicFieldGet(
    Name => '$FieldName',
);

\$Success = \$BackendObject->ValueSet(
    DynamicFieldConfig => \$TempValue,
    ObjectID           => \$TicketID,
    Value              => '$Value',
    UserID             => \$UserID,
);

\$Self->True(
    \$Success,
    'TicketDynamicFieldUpdate "$FieldName" was successfull.',
);

OUTPUT

    return $Output;
}

1;
