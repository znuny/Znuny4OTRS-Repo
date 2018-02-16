# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketObject::DynamicField;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
);

use Kernel::System::VariableCheck qw(:all);
use base qw( Kernel::System::Znuny4OTRS::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    return '' if !IsArrayRefWithData( $Param{DynamicField} );

    my $Output = sprintf <<OUTPUT;

# DynamicField setup

OUTPUT

    for my $DynamicField ( @{ $Param{DynamicField} } ) {

        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicField,
        );

        $Output .= <<OUTPUT;
## DynamicField '$DynamicFieldConfig->{Name}'

\$ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
    {
        Name       => '$DynamicFieldConfig->{Name}',
        Label      => '$DynamicFieldConfig->{Label}',
        ObjectType => '$DynamicFieldConfig->{ObjectType}',
        FieldType  => '$DynamicFieldConfig->{FieldType}',
        Config     =>  {
OUTPUT

        for my $Config ( sort keys %{ $DynamicFieldConfig->{Config} } ) {

            $Output .= <<CONFIG;
            $Config => '$DynamicFieldConfig->{Config}->{$Config}',
CONFIG
        }

        $Output .= <<OUTPUT;
        }
    },
);

OUTPUT

    }

    return $Output;

}

1;