# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
# nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)
package Kernel::System::Ticket::Article;    ## no critic

=head1 NAME

Kernel::System::Ticket::Article

=head1 SYNOPSIS

Article helpers.

=head1 PUBLIC INTERFACE

=over 4

=cut

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket::Article',
);

sub ArticleCreate {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForChannel( ChannelName => $Param{ChannelName} );
    return if !$ArticleBackendObject;

    my $ArticleID = $ArticleBackendObject->ArticleCreate(%Param);
    return $ArticleID;
}

sub ArticleGet {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID}
    );
    return if !$ArticleBackendObject;

    my %Article = $ArticleBackendObject->ArticleGet(%Param);
    return %Article;
}

sub ArticleUpdate {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID}
    );
    return if !$ArticleBackendObject;

    my $ArticleUpdated = $ArticleBackendObject->ArticleUpdate(%Param);
    return $ArticleUpdated;
}

sub ArticleSend {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForChannel( ChannelName => 'Email' );
    return if !$ArticleBackendObject;

    my $ArticleID = $ArticleBackendObject->ArticleSend(%Param);
    return $ArticleID;
}

sub ArticleBounce {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID}
    );
    return if !$ArticleBackendObject;

    my $ArticleBounced = $ArticleBackendObject->ArticleBounce(%Param);
    return $ArticleBounced;
}

sub SendAutoResponse {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForChannel( ChannelName => 'Email' );
    return if !$ArticleBackendObject;

    my $ArticleID = $ArticleBackendObject->SendAutoResponse(%Param);
    return $ArticleID;
}

=item ArticleIndex()

returns an array with article IDs

    my @ArticleIDs = $ArticleObject->ArticleIndex(
        TicketID => 123,
    );

    my @ArticleIDs = $ArticleObject->ArticleIndex(
        SenderType => 'customer',                   # optional, to limit to a certain sender type
        TicketID   => 123,
    );

=cut

sub ArticleIndex {
    my ( $Self, %Param ) = @_;

    my @Articles = $Self->ArticleList(
        TicketID   => $Param{TicketID},
        SenderType => $Param{SenderType},
    );

    my @ArticleIDs;
    return @ArticleIDs if !@Articles;

    @ArticleIDs = map { $_->{ArticleID} } @Articles;
    return @ArticleIDs;
}

1;

=back
