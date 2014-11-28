# --
# Kernel/Znuny4OTRSRepo.pm - PreApplication module to add the Znuny repository to the repository list
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

package Kernel::Modules::Znuny4OTRSRepo;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    # check needed objects
    NEEDED:
    for my $Needed (qw(ParamObject DBObject LogObject ConfigObject)) {

        next NEEDED if $Self->{$Needed};

        $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
    }

    return $Self;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    return if $Self->{Action} !~ /^Admin/;

    return if $Self->{ConfigObject}->Get('Znuny4OTRSRepoDisable');

    my $RepositoryList = $Self->{ConfigObject}->Get('Package::RepositoryList');
    if ( !IsHashRefWithData( $RepositoryList ) ) {
        $RepositoryList = {};
    }

    my $RepositoryURL = $Self->{ConfigObject}->Get('Znuny4OTRSRepoType');
    $RepositoryURL  ||= 'https';
    $RepositoryURL   .= '://portal.znuny.com/api/addon_repos/';

    # add public repository
    $RepositoryList->{ $RepositoryURL . 'public'} = 'Addons - Znuny4OTRS / Public';

    # check for and add configured private repositories
    my $PrivateRepost = $Self->{ConfigObject}->Get('Znuny4OTRSPrivatRepos');

    if ( IsHashRefWithData( $PrivateRepost ) ) {
        for my $Key ( keys %{ $PrivateRepost } ) {
            $RepositoryList->{ $RepositoryURL . $Key } = "Addons - Znuny4OTRS / Private '$PrivateRepost->{$Key}'";
        }
    }

    # set temporary config entry
    $Self->{ConfigObject}->Set(
        Key   => 'Package::RepositoryList',
        Value => $RepositoryList,
    );

    return;
}

1;
