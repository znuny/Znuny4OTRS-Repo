# VERSION:1.1
# --
# Kernel/Config/Files/ZZZZZZnuny4OTRSRepo.pm - overloads the file system check function to use the Znuny service for package verification
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/6114661c44c9ca9dec45364b54bfab036ce6e34e/Kernel/System/Package.pm
# $origin: https://github.com/OTRS/otrs/blob/6114661c44c9ca9dec45364b54bfab036ce6e34e/Kernel/System/CloudService/Backend/Run.pm
# $origin: https://github.com/OTRS/otrs/blob/6114661c44c9ca9dec45364b54bfab036ce6e34eKernel/System/Package.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Config::Files::ZZZZZZnuny4OTRSRepo;

use strict;
use warnings;

use Kernel::System::Package;
use Kernel::System::CloudService::Backend::Run;

use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub Load {
    my ($File, $Self) = @_;

    # add the Znuny repository to the repository list
    if ( !$Self->{'Znuny4OTRSRepoDisable'} ) {

        my $RepositoryList = $Self->{'Package::RepositoryList'};
        if ( !IsHashRefWithData($RepositoryList) ) {
            $RepositoryList = {};
        }

        my $RepositoryURL = $Self->{'Znuny4OTRSRepoType'};
        $RepositoryURL ||= 'https';
        $RepositoryURL .= '://portal.znuny.com/api/addon_repos/';

        # add public repository
        $RepositoryList->{ $RepositoryURL . 'public' } = 'Addons - Znuny4OTRS / Public';

        # check for and add configured private repositories
        my $PrivateRepost = $Self->{'Znuny4OTRSPrivatRepos'};

        if ( IsHashRefWithData($PrivateRepost) ) {
            for my $Key ( sort keys %{$PrivateRepost} ) {
                $RepositoryList->{ $RepositoryURL . $Key } = "Addons - Znuny4OTRS / Private '$PrivateRepost->{$Key}'";
            }
        }

        # set temporary config entry
        $Self->{'Package::RepositoryList'} = $RepositoryList;
    }

    return 1;
}

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


sub Kernel::System::CloudService::Backend::Run::new {
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

sub Kernel::System::Package::_Download { ## no critic
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !defined $Param{URL} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'URL not defined!',
        );
        return;
    }

    my $WebUserAgentObject = Kernel::System::WebUserAgent->new(
        Timeout => $Self->{ConfigObject}->Get('Package::Timeout'),
        Proxy   => $Self->{ConfigObject}->Get('Package::Proxy'),
    );

# ---
# Znuny4OTRS-Repo
# ---
#     my %Response = $WebUserAgentObject->Request(
#         URL => $Param{URL},
#     );
#
    # strip out the API token from portal.znuny.com repository calls
    # and add it to the 'Authorization' header
    my %Header;
    my $ZnunyPortalRegex = '(portal\.znuny\.com\/api\/addon_repos\/)([^\/]+)\/';
    if (
        $Param{URL} =~ m{$ZnunyPortalRegex}xms
        && $2 ne 'public'
    ) {
        my $APIToken           = $2;
        $Param{URL}            =~ s{$ZnunyPortalRegex}{$1}xms;
        $Header{Authorization} = "Token token=$APIToken";
    }

    my %Response = $WebUserAgentObject->Request(
        URL    => $Param{URL},
        Header => \%Header,
    );
# ---
    return if !$Response{Content};
    return ${ $Response{Content} };
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
