# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::Repo::DynamicFieldConfigExport;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use base qw(Kernel::System::Console::BaseCommand);

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
        Name        => 'skip-internal-fields',
        Description => 'Skips dynamic fields with flag "InternalField" (e. g. process management).',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name => 'export-all-config-keys',
        Description =>
            'Additionally exports the following config keys: ChangeTime, CreateTime, ID, InternalField, ValidID.',
        Required => 0,
        HasValue => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $ConfigString = $ZnunyHelperObject->_DynamicFieldsConfigExport(
        Format              => $Self->GetArgument('format'),
        SkipInternalFields  => $Self->GetOption('skip-internal-fields') ? 1 : 0,
        ExportAllConfigKeys => $Self->GetOption('export-all-config-keys') ? [] : undef,
    );

    $Self->Print("$ConfigString\n");

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
