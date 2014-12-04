# --
# Kernel/Znuny4OTRSRepo.pm - overloads the file system check function to use the Znuny service for package verification
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

use strict;
use warnings;

use Kernel::System::CloudService;

# disable redefine warnings in this scope
{
no warnings 'redefine';

sub Kernel::System::CloudService::new {
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
    my $Schema               = $Kernel::OM->Get('Kernel::Config')->Get('Znuny4OTRSRepoType') || 'https';
    $Self->{CloudServiceURL} = $Schema .'://portal.znuny.com/api/otrs_cloud_service/';
# ---

    return $Self;
}

}

1;
