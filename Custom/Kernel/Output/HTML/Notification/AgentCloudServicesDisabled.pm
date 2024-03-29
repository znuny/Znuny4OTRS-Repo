# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 8207d0f681adcdeb5c1b497ac547a1d9749838d5 - Kernel/Output/HTML/Notification/AgentCloudServicesDisabled.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::PerlCritic)

package Kernel::Output::HTML::Notification::AgentCloudServicesDisabled;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
);

sub Run {
    my ( $Self, %Param ) = @_;
# ---
# Znuny4OTRS-Repo
# ---
    return '';
# ---

    my $Output = '';

    # check if cloud services are disabled
    my $CloudServicesDisabled = $Kernel::OM->Get('Kernel::Config')->Get('CloudServices::Disabled') || 0;

    return '' if !$CloudServicesDisabled;
    return '' if $Param{Type} ne 'Admin';

    my $Group = $Param{Config}->{Group} || 'admin';

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $HasPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $Self->{UserID},
        GroupName => $Group,
        Type      => 'rw',
    );

    # notification should only be visible for administrators
    if ( !$HasPermission ) {
        return '';
    }

    my $Text = '<a href="'
        . $LayoutObject->{Baselink}
        . 'Action=AdminSystemConfiguration;Subaction=View;Setting=CloudServices::Disabled'
        . '">';
    $Text .= $LayoutObject->{LanguageObject}->Translate('Enable cloud services to unleash all OTRS features!');
    $Text .= '</a>';

    return $LayoutObject->Notify(
        Data     => $Text,
        Priority => 'Info',
    );
}
1;
