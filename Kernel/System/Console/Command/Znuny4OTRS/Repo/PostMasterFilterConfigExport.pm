# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::Repo::PostMasterFilterConfigExport;

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
        'Exports configuration of all postmaster filter. Output can formatted as YAML or Perl '
            . 'which can be used as parameter for ZnunyHelper::_PostMasterFilterConfigExport().',
    );

    $Self->AddArgument(
        Name        => 'format',
        Description => 'Specify the format of the export: yml or perl.',
        Required    => 1,
        ValueRegex  => qr/\A(yml|perl)\z/smxi,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $ConfigString = $ZnunyHelperObject->_PostMasterFilterConfigExport(
        Format => $Self->GetArgument('format'),
    );

    $Self->Print("$ConfigString\n");

    return $Self->ExitCodeOk();
}

1;
