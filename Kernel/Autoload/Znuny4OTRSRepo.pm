# --
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 6114661c44c9ca9dec45364b54bfab036ce6e34e - Kernel/System/CloudService/Backend/Run.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use Kernel::System::CloudService::Backend::Run;

package Kernel::System::CloudService::Backend::Run; ## no critic

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SystemData',
);

# disable redefine warnings in this scope
{
no warnings 'redefine';  ## no critic

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # set system registration data
    %{ $Self->{RegistrationData} } =
        $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGroupGet(
        Group  => 'Registration',
        UserID => 1,
        );

# ---
# Znuny4OTRS-Repo
# ---
#     # set URL for calling cloud services
#     $Self->{CloudServiceURL} = 'https://cloud.otrs.com/otrs/public.pl';
    # set new cloud service url
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $Schema               = $ConfigObject->Get('Znuny4OTRSRepoType') || 'https';
    $Self->{CloudServiceURL} = $Schema .'://'. $ConfigObject->Get('Znuny4OTRSCloudServiceProxyURL');
# ---

    return $Self;
}

}

1;
