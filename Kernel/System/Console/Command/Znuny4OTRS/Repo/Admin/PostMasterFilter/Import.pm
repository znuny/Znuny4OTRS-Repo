# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::Perl::ZnunyHelper)

package Kernel::System::Console::Command::Znuny4OTRS::Repo::Admin::PostMasterFilter::Import;

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
        'Imports configuration of postmaster filter. Input should be formatted as YAML.',
    );

    $Self->AddArgument(
        Name        => 'source-path',
        Description => "Specify the source location of the config YAML file.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');

    my $SourcePath = $Self->GetArgument('source-path');

    my $Content = $MainObject->FileRead(
        Location        => $SourcePath,
        Mode            => 'utf8',
        Type            => 'Local',
        Result          => 'SCALAR',
        DisableWarnings => 1,
    );

    my $Success = $ZnunyHelperObject->_PostMasterFilterConfigImport(
        Filter => $Content,
        Format => 'yml'
    );

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
