# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/6114661c44c9ca9dec45364b54bfab036ce6e34e/Kernel/Output/HTML/Notification/CustomerOTRSBusiness.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Notification::CustomerOTRSBusiness;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::System::OTRSBusiness',
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

# ---
# Znuny4OTRS-Repo
# ---
    return '';
# ---
    my $Output = '';

    # get OTRS business object
    my $OTRSBusinessObject = $Kernel::OM->Get('Kernel::System::OTRSBusiness');

    return '' if !$OTRSBusinessObject->OTRSBusinessIsInstalled();

    # ----------------------------------------
    # check entitlement status
    # ----------------------------------------
    my $EntitlementStatus = $OTRSBusinessObject->OTRSBusinessEntitlementStatus(
        CallCloudService => 0,
    );

    if ( $EntitlementStatus eq 'forbidden' ) {

        my $OTRSBusinessLabel = '<b>OTRS Business Solution</b>™';

        # get layout object
        my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

        my $Text = $LayoutObject->{LanguageObject}->Translate(
            'This system uses the %s without a proper license! Please make contact with %s to renew or activate your contract!',
            $OTRSBusinessLabel,
            'sales@otrs.com',    # no mailto link as these are currently not displayed in the CI
        );
        $Output .= $LayoutObject->Notify(
            Data     => $Text,
            Priority => 'Error',
        );
    }

    return $Output;
}

1;
