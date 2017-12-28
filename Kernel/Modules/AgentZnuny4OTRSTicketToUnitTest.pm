# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentZnuny4OTRSTicketToUnitTest;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Email',
    'Kernel::System::Log',
    'Kernel::System::Time',
    'Kernel::System::Web::Request',
    'Kernel::System::Znuny4OTRS::TicketToUnitTest',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketToUnitTestObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest');
    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject              = $Kernel::OM->Get('Kernel::System::Log');
    my $ParamObject            = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeObject             = $Kernel::OM->Get('Kernel::System::Time');
    my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
    my $EmailObject            = $Kernel::OM->Get('Kernel::System::Email');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(TicketID)) {

        $Param{$Needed} = $ParamObject->GetParam( Param => $Needed );
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in AgentZnuny4OTRSTicketToUnitTest!",
        );
        return $LayoutObject->ErrorScreen();
    }

    my $UnitTestContent = $TicketToUnitTestObject->CreateUnitTest(
        TicketID => $Param{TicketID},
    );

    my $Organization = $ConfigObject->Get('Organization') || 'Znuny';
    my $Filename = "UnitTest-$Organization-$Param{TicketID}.t";

    my $UnitTestFile = $LayoutObject->Attachment(
        ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
        Content     => $UnitTestContent,
        Type        => 'attachment',
        Filename    => $Filename,
        NoCache     => 1,
    );

    if ( $Self->{Subaction} eq 'CreateFile' ) {
        return $UnitTestFile if $UnitTestFile;
    }
    elsif ( $Self->{Subaction} eq 'SendEmail' ) {

        # todo maybe additional sysconfigs
        my $From = $ConfigObject->Get('NotificationSenderEmail');
        my $Sent = $EmailObject->Send(
            From       => $From,
            To         => 'support@znuny.com',
            Subject    => "UnitTest $Organization",
            Charset    => 'utf-8',
            MimeType   => 'text/plain',
            Body       => "UnitTest $Organization",
            Attachment => [
                {
                    Filename    => $Filename,
                    Content     => $UnitTestContent,
                    ContentType => "text/html",
                },
            ],
        );
    }

    return $LayoutObject->Redirect( OP => "Action=AgentTicketZoom;TicketID=$Param{TicketID}" );
}

1;
