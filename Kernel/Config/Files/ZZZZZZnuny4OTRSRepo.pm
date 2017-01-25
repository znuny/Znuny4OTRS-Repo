# VERSION:1.1
# --
# Kernel/Config/Files/ZZZZZZnuny4OTRSRepo.pm - overloads the file system check function to use the Znuny service for package verification
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/b681f86310169c535e16742f0138bee21a2a3cd6/Kernel/System/CloudService.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Config::Files::ZZZZZZnuny4OTRSRepo;

use strict;
use warnings;

use Kernel::System::CloudService;

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
