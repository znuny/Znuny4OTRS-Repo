# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::Perl::ZnunyHelper)

package Kernel::System::Console::Command::Znuny4OTRS::Repo::Admin::PostMasterFilter::Export;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
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

    $Self->AddOption(
        Name        => 'target-path',
        Description => "Specify the target location of the config YAML file. If not set, prints via STDOUT.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'target-name',
        Description => "Specify the target name of the config YAML file.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');

    my $Format     = $Self->GetArgument('format');
    my $TargetPath = $Self->GetOption('target-path');
    my $TargetName = $Self->GetOption('target-name') || 'PostMasterFilterConfig.yml';

    my $ConfigString = $ZnunyHelperObject->_PostMasterFilterConfigExport(
        Format => $Format,
    );

    if ($TargetPath) {
        my $FileLocation = $MainObject->FileWrite(
            Directory => $TargetPath,
            Filename  => $TargetName,
            Content   => \$ConfigString,
        );
        $Self->Print("<yellow>File stored: $FileLocation</yellow>\n");
        $Self->Print("<green>Done.</green>\n");
    }
    else {
        $Self->Print("$ConfigString\n");
    }

    return $Self->ExitCodeOk();
}

1;
