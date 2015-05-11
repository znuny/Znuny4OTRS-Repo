# --
# Kernel/Config/Files/Znuny4OTRSRepo.pm - overloads the file system check function to use the Znuny service for package verification
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use Kernel::System::Package;
use Kernel::System::CloudService;

our $ObjectManagerDisabled = 1;

# disable redefine warnings in this scope
{
no warnings 'redefine';

# backup original PackageVerify()
my $PackageVerifyOld = \&Kernel::System::Package::PackageVerify;

# redefine PackageVerify() of Kernel::System::Package
*Kernel::System::Package::PackageVerify = sub {
    my ( $Self, %Param ) = @_;

    my $PackageVerification = $Kernel::OM->Get('Kernel::Config')->Get('PackageVerification');
    return 'verified' if !$PackageVerification;

    # execute original function
    return &{$PackageVerifyOld}( $Self, %Param );
};

# backup original PackageVerifyAll()
my $PackageVerifyAllOld = \&Kernel::System::Package::PackageVerifyAll;

# redefine PackageVerifyAll() of Kernel::System::Package
*Kernel::System::Package::PackageVerifyAll = sub {
    my ( $Self, %Param ) = @_;

    my $PackageVerification = $Kernel::OM->Get('Kernel::Config')->Get('PackageVerification');
    if ( !$PackageVerification ) {
        # get installed package list
        my @PackageList = $Self->RepositoryList(
            Result => 'Short',
        );

        # and take the short way ;)
        my %Result;
        for my $Package (@PackageList) {
            $Result{ $Package->{Name} } = 'verified';
        }

        return %Result;
    }

    # execute original function
    return &{$PackageVerifyAllOld}( $Self, %Param );
};


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
    $Self->{CloudServiceURL} = $Schema .'://'. $Kernel::OM->Get('Kernel::Config')->Get('Znuny4OTRSCloudServiceProxyURL');
# ---

    return $Self;
}

}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
