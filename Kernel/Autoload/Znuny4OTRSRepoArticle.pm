# --
# Copyright (C) 2012-2021 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::Deprecated::CodePolicy)
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::Deprecated::ArticleFunctions)
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
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
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

    my %Attachment = $ArticleObject->ArticleAttachment(
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

=head2 ArticleCount()

Returns count of article.

    my $Count = $ArticleObject->ArticleCount(
        TicketID  => 123,
    );

Returns:

    my $Count = 1;

=cut

sub ArticleCount {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(TicketID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Count = 0;
    my $SQL   = '
        SELECT COUNT(*)
        FROM article
        WHERE ticket_id = ?';

    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => [ \$Param{TicketID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Count = $Row[0];
    }

    return $Count;
}

=head2 ArticleAttachmentCount()

Returns count of article attachment.

    my $Count = $ArticleObject->ArticleAttachmentCount(
        TicketID  => 123,
        ArticleID => 123,
    );

Returns:

    my $Count = 1;

=cut

sub ArticleAttachmentCount {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    NEEDED:
    for my $Needed (qw(TicketID ArticleID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    my $Count = 0;

    my $ArticleBackendObject = $Self->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID}
    );

    if (
        $ArticleBackendObject->{ArticleStorageModule} eq
        'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorageDB'
        )
    {

        my $SQL = '
            SELECT COUNT(*)
            FROM article_data_mime_attachment
            WHERE article_id = ?';

        return if !$DBObject->Prepare(
            SQL  => $SQL,
            Bind => [ \$Param{ArticleID} ],
        );

        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Count = $Row[0];
        }

    }
    elsif (
        $ArticleBackendObject->{ArticleStorageModule} eq
        'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorageFS'
        )
    {

        $Self->{ArticleDataDir} = $ConfigObject->Get('Ticket::Article::Backend::MIMEBase::ArticleDataDir');

        my $ContentPath = $Self->ArticleContentPathGet(
            ArticleID => $Param{ArticleID},
        );

        my @Filenames = $MainObject->DirectoryRead(
            Directory => "$Self->{ArticleDataDir}/$ContentPath/$Param{ArticleID}",
            Filter    => "*",
            Silent    => 1,
        );

        FILENAME:
        for my $Filename ( sort @Filenames ) {

            # do not use control file
            next FILENAME if $Filename =~ /\.content_alternative$/;
            next FILENAME if $Filename =~ /\.content_id$/;
            next FILENAME if $Filename =~ /\.content_type$/;
            next FILENAME if $Filename =~ /\.disposition$/;
            next FILENAME if $Filename =~ /\/plain.txt$/;
            $Count++;
        }
    }

    return $Count;
}

=head2 ArticleContentPathGet()

Get the stored content path of an article.

    my $Path = $BackendObject->ArticleContentPathGet(
        ArticleID => 123,
    );

=cut

sub ArticleContentPathGet {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');

    NEEDED:
    for my $Needed (qw(ArticleID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $CacheKey = 'ArticleContentPathGet::' . $Param{ArticleID};

    my $Cache = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return $Cache if $Cache;

    return if !$DBObject->Prepare(
        SQL  => 'SELECT content_path FROM article_data_mime WHERE article_id = ?',
        Bind => [ \$Param{ArticleID} ],
    );

    my $Result;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Result = $Row[0];
    }

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => $Result,
    );

    return $Result;
}

1;
