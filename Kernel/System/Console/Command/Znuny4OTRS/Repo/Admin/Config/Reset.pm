# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - https://github.com/OTRS/otrs/pull/1971 - Kernel/System/Console/Command/Admin/Config/Reset.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::Repo::Admin::Config::Reset;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::SysConfig',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Reset the value of a setting.');
    $Self->AddOption(
        Name        => 'setting-name',
        Description => "The name of the setting.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );
    $Self->AddOption(
        Name        => 'no-deploy',
        Description => "Specify that the update of this setting should not be deployed.",
        Required    => 0,
        HasValue    => 0,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    # Perform any custom validations here. Command execution can be stopped with die().

    my %Setting = $Kernel::OM->Get('Kernel::System::SysConfig')->SettingGet(
        Name    => $Self->GetOption('setting-name'),
        Default => 1,
    );

    if ( !%Setting ) {
        die "setting-name is invalid!";
    }

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Updating setting value...</yellow>\n\n");

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $SettingName = $Self->GetOption('setting-name');

    # Get default setting
    my %Setting = $Kernel::OM->Get('Kernel::System::SysConfig')->SettingGet(
        Name    => $SettingName,
        Default => 1,
    );

    if ( !%Setting ) {
        $Self->PrintError("Setting doesn't exists!");
        return $Self->ExitCodeError();
    }

    my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
        UserID    => 1,
        Force     => 1,
        DefaultID => $Setting{DefaultID},
    );

    my $Success = $SysConfigObject->SettingReset(
        Name              => $SettingName,
        TargetUserID      => 1,
        ExclusiveLockGUID => $ExclusiveLockGUID,
        UserID            => 1,
    );

    if ( !$Success ) {
        $Self->PrintError("Setting could not be resetted!");
        return $Self->ExitCodeError();
    }

    $Success = $SysConfigObject->SettingUnlock(
        UserID    => 1,
        DefaultID => $Setting{DefaultID},
    );

    if ( $Self->GetOption('no-deploy') ) {
        $Self->Print("<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
        Comments      => "Admin::Config::Reset $SettingName",
        UserID        => 1,
        Force         => 1,
        DirtySettings => [$SettingName],
    );

    if ( !$DeploymentResult{Success} ) {
        $Self->PrintError("Deployment failed!\n");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
