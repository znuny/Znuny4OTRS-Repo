# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::Repo::DynamicFieldsConfigExport;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::ZnunyHelper',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Exports configuration of all dynamic fields. Output can formatted as YAML or Perl '
            . 'which can be used as parameter for ZnunyHelper::_DynamicFieldsCreate().',
    );

    $Self->AddArgument(
        Name        => 'format',
        Description => 'Specify the format of the export: yml or perl.',
        Required    => 1,
        ValueRegex  => qr/\A(yml|perl)\z/smxi,
    );

    $Self->AddOption(
        Name        => 'include-internal-fields',
        Description => 'Includes dynamic fields with flag "InternalField" (e. g. process management).',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name => 'include-all-config-keys',
        Description =>
            'Additionally includes the following config keys: ChangeTime, CreateTime, ID, InternalField, ValidID.',
        Required => 0,
        HasValue => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $ConfigString = $ZnunyHelperObject->_DynamicFieldsConfigExport(
        Format                => $Self->GetArgument('format'),
        IncludeInternalFields => $Self->GetOption('include-internal-fields') // 0,
        IncludeAllConfigKeys  => $Self->GetOption('include-all-config-keys') // 0,
    );

    $Self->Print("$ConfigString\n");

    return $Self->ExitCodeOk();
}

1;
