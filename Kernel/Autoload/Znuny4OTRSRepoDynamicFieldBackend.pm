# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 09b7361cd0b8244087a5189f337559efa981bd7b - Kernel/System/DynamicField/Backend.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
package Kernel::Autoload::Znuny4OTRSRepoDynamicFieldBackend;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use Kernel::System::DynamicField::Backend;

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
);

# disable redefine warnings in this scope
{
no warnings 'redefine';  ## no critic

=head2 ValueSet()

sets a dynamic field value.

    my $Success = $BackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,      # complete config of the DynamicField
# ---
# Znuny4OTRS-Repo
# ---
        # OR
        DynamicFieldName => 'MyField', # Implicitly fetches config of dynamic field
# ---
        ObjectID           => $ObjectID,                # ID of the current object that the field
                                                        # must be linked to, e. g. TicketID
        ObjectName         => $ObjectName,              # Name of the current object that the field
                                                        # must be linked to, e. g. CustomerUserLogin
                                                        # You have to give either ObjectID OR ObjectName
        Value              => $Value,                   # Value to store, depends on backend type
        UserID             => 123,
    );

=cut

my $OriginalValueSet = \&Kernel::System::DynamicField::Backend::ValueSet;

*Kernel::System::DynamicField::Backend::ValueSet = sub {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    if ( !$Param{DynamicFieldConfig} && $Param{DynamicFieldName} ) {
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $Param{DynamicFieldName},
        );

        if ( IsHashRefWithData($DynamicFieldConfig) ) {
            $Param{DynamicFieldConfig} = $DynamicFieldConfig;
            delete $Param{DynamicFieldName};
        }
    }

    return &{$OriginalValueSet}( $Self, %Param );
}

}

1;
