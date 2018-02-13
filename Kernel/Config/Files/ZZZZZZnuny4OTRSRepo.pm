# VERSION:1.1
# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Config::Files::ZZZZZZnuny4OTRSRepo;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub Load {
    my ($File, $Self) = @_;

    my $RepositoryList = $Self->{'Package::RepositoryList'};
    if ( !IsHashRefWithData($RepositoryList) ) {
        $RepositoryList = {};
    }

    # add the Znuny repository to the repository list
    if ( !$Self->{'Znuny4OTRSRepoDisable'} ) {

        my $RepositoryBasePath = 'addons.znuny.com/api/addon_repos/';

        # remove all repositories that contain our znuny.com domain
        # because otherwise repositories might get added multiple times
        # - once for each protocol
        # - obsolete URLs
        REPOSITORYURL:
        for my $RepositoryURL ( sort keys %{$RepositoryList} ) {
            next REPOSITORYURL if $RepositoryURL !~ m{znuny\.com};
            delete $RepositoryList->{$RepositoryURL};
        }

        my $RepositoryProtocol = $Self->{'Znuny4OTRSRepoType'} // 'https';
        my $RepositoryBaseURL  = $RepositoryProtocol . '://' . $RepositoryBasePath;

        # add public repository
        $RepositoryList->{ $RepositoryBaseURL . 'public' } = 'Addons - Znuny4OTRS / Public';

        # check for and add configured private repositories
        my $PrivateRepo = $Self->{'Znuny4OTRSPrivatRepos'};

        if ( IsHashRefWithData($PrivateRepo) ) {
            KEY:
            for my $Key ( sort keys %{$PrivateRepo} ) {

                # Ignore example API key.
                next KEY if $Key eq 'API-KEY';
                $RepositoryList->{ $RepositoryBaseURL . $Key } = "Addons - Znuny4OTRS / Private '$PrivateRepo->{$Key}'";
            }
        }

        # set temporary config entry
        $Self->{'Package::RepositoryList'} = $RepositoryList;
    }
    else {
        if ( $Self->{'Znuny4OTRSRepoDisable'} == 1 ) {
            delete $Self->{'Package::RepositoryList'};
        }
        elsif ( $Self->{'Znuny4OTRSRepoDisable'} == 2 ) {
            URL:
            for my $URL ( sort keys %{$RepositoryList} ) {
                next URL if $URL !~ m{znuny};
                delete $Self->{'Package::RepositoryList'}->{$URL};
            }
        }
    }

    return 1;
}

1;
