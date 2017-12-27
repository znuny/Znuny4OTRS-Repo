# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketDynamicFieldUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketDynamicFieldUpdate

=head1 SYNOPSIS

All TicketToUnitTest::TicketDynamicFieldUpdate functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestTicketDynamicFieldUpdateObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest::TicketDynamicFieldUpdate');

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

    $Param{Name} =~ /^\%\%FieldName\%\%(.+?)\%\%Value\%\%(.*?)(?:\%\%|$)/;

    my $FieldName = $1;
    my $Value = $2 || '';

    my $Output = <<OUTPUT;

my \$DynamicField = \$DynamicFieldObject->DynamicFieldGet(
    Name => '$FieldName',
);

\$Success = \$BackendObject->ValueSet(
    DynamicFieldConfig => \$DynamicField,
    ObjectID           => \$Param{TicketID},
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
