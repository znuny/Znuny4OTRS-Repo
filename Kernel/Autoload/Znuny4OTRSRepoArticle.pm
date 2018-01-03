# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
# nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)
# nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::DeprecatedArticleFunctions)
package Kernel::System::Ticket::Article;    ## no critic

=head1 NAME

Kernel::System::Ticket::Article

=head1 SYNOPSIS

Article helpers.

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

=head2 ArticleIndex()

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

=head2 ArticleAttachmentIndex()

returns an array with article IDs

    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => 123,
        ArticleID        => 123,
        ExcludePlainText => 1,       # (optional) Exclude plain text attachment
        ExcludeHTMLBody  => 1,       # (optional) Exclude HTML body attachment
        ExcludeInline    => 1,       # (optional) Exclude inline attachments
        OnlyHTMLBody     => 1,       # (optional) Return only HTML body attachment, return nothing if not found
    );

Returns:

    my %AttachmentIndex = (
        '1' => {
            'FilesizeRaw'        => '804764',
            'Disposition'        => 'attachment',
            'ContentType'        => 'image/jpeg',
            'ContentAlternative' => '',
            'Filename'           => 'blub.jpg',
            'ContentID'          => ''
        },
        # ...
    );

=cut

sub ArticleAttachmentIndex {
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID}
    );
    return if !$ArticleBackendObject;

    my %AttachmentIndex = $ArticleBackendObject->ArticleAttachmentIndex(
        %Param,
    );

    return %AttachmentIndex;
}

=head2 ArticleAttachment()

Get article attachment from storage. This is a delegate method from active backend.

    my %Attachment = $ArticleBackendObject->ArticleAttachment(
        TicketID  => 123,
        ArticleID => 123,
        FileID    => 1,   # as returned by ArticleAttachmentIndex
    );

Returns:

    %Attachment = (
        Content            => 'xxxx',     # actual attachment contents
        ContentAlternative => '',
        ContentID          => '',
        ContentType        => 'application/pdf',
        Filename           => 'StdAttachment-Test1.pdf',
        FilesizeRaw        => 4722,
        Disposition        => 'attachment',
    );

=cut

sub ArticleAttachment {    ## no critic;
    my ( $Self, %Param ) = @_;

    my $ArticleBackendObject = $Self->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID}
    );
    return if !$ArticleBackendObject;

    my %Attachment = $ArticleBackendObject->ArticleAttachment(
        %Param,
    );

    return %Attachment;
}

1;
