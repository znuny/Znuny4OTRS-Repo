# --
# Kernel/Znuny4OTRSRepo.pm - PreApplication module to add the Znuny repository to the repository list
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::Znuny4OTRSRepo;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

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
    if ( !IsHashRefWithData($RepositoryList) ) {
        $RepositoryList = {};
    }

    my $RepositoryURL = $Self->{ConfigObject}->Get('Znuny4OTRSRepoType');
    $RepositoryURL ||= 'https';
    $RepositoryURL .= '://portal.znuny.com/api/addon_repos/';

    # add public repository
    $RepositoryList->{ $RepositoryURL . 'public' } = 'Addons - Znuny4OTRS / Public';

    # check for and add configured private repositories
    my $PrivateRepost = $Self->{ConfigObject}->Get('Znuny4OTRSPrivatRepos');

    if ( IsHashRefWithData($PrivateRepost) ) {
        for my $Key ( sort keys %{$PrivateRepost} ) {
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

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
