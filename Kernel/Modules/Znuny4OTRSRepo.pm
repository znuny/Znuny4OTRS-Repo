
# Copyright (C) 2013 Znuny GmbH, http://znuny.com/

package Kernel::Modules::Znuny4OTRSRepo;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    # check needed objects
    for (qw(ParamObject DBObject LogObject ConfigObject)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }

    return $Self;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    return if $Self->{Action} !~ /^Admin/;

    return if $Self->{ConfigObject}->Get('Znuny4OTRSRepoDisable');

    my $RepositoryList = $Self->{ConfigObject}->Get('Package::RepositoryList');
    if ( !$RepositoryList ) {
        $RepositoryList = {};
    }

    my $Type = $Self->{ConfigObject}->Get('Znuny4OTRSRepoType') || 'https';
    $RepositoryList->{ $Type . '://portal.znuny.com/api/addon_repos/public'} = 'Addons - Znuny4OTRS / Public';

    my $PrivateRepost = $Self->{ConfigObject}->Get('Znuny4OTRSPrivatRepos');
    if ($PrivateRepost && ref $PrivateRepost eq 'HASH' ) {
        for my $Key ( keys %{ $PrivateRepost } ) {
            $RepositoryList->{ $Type . '://portal.znuny.com/api/addon_repos/' . $Key } = "Addons - Znuny4OTRS / Private $PrivateRepost->{$Key} ";
        }
    }

    $Self->{ConfigObject}->Set(
        Key   => 'Package::RepositoryList',
        Value => $RepositoryList,
    );

    return;
}

1;
