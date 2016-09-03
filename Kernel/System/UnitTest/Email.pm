# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::CacheCleanup)

package Kernel::System::UnitTest::Email;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Email',
    'Kernel::System::Email::Test',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

=head1 NAME

Kernel::System::UnitTest::Email - email lib

=head1 SYNOPSIS

All email functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestEmailObject = $Kernel::OM->Get('Kernel::System::UnitTest::Email');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->MailBackendSetup();
    $Self->MailCleanup();

    return $Self;
}

=item MailCleanup()

This function:
    - removes existing mails from Email::Test Backend Object

    my $Success = $UnitTestEmailObject->MailCleanup();

Returns:

    my $Success = 1;

=cut

sub MailCleanup {
    my ( $Self, %Param ) = @_;

    my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
    $TestEmailObject->CleanUp();

    return 1;
}

=item MailObjectDiscard()

This function:
    - discards the objects:
        'Kernel::System::Ticket',
        'Kernel::System::Email::Test',
        'Kernel::System::Email',
      triggering Transaction notifications
    - reinitializes the above objects

    my $Success = $UnitTestEmailObject->MailObjectDiscard();

Returns:

    my $Success = 1;

=cut

sub MailObjectDiscard {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->ObjectsDiscard(
        Objects => [
            'Kernel::System::Ticket',
            'Kernel::System::Email::Test',
            'Kernel::System::Email',
        ],
    );

    my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
    my $EmailObject     = $Kernel::OM->Get('Kernel::System::Email');

    return 1;
}

=item MailBackendSetup()

This function:
    - sets Kernel::System::Email::Test as MailBackend
    - turns SysConfig option CHeckEmailAddresses off

    my $Success = $UnitTestEmailObject->MailBackendSetup();

Returns:

    my $Success = 1;

=cut

sub MailBackendSetup {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $ConfigObject->Set(
        Key   => 'SendmailModule',
        Value => 'Kernel::System::Email::Test',
    );

    $ConfigObject->Set(
        Key   => 'CheckEmailAddresses',
        Value => 0,
    );

    return 1;
}

=item EmailGet()

This function:
    - Fetches mails from TestMailBackend
    - returns array of hashes containing mails:

    my @Emails = $UnitTestEmailObject->EmailGet();

Returns:

    @Emails = (
        {
            Header => "Email1 Header text...",
            Body => "Email1 Header text...",
            ToArray => ['email1realrecipient1@test.com', 'email1realrecipient2@test.com', 'email1realrecipient1@test.com', ],
        },
        {
            Header => "Email2 Header text...",
            Body => "Email2 Header text...",
            ToArray => ['email2realrecipient1@test.com'],
        },
        ...
    );

=cut

sub EmailGet {
    my ( $Self, %Param ) = @_;

    my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');

    my $Emails = $TestEmailObject->EmailsGet();

    my @AllEmails;

    return @AllEmails if !IsArrayRefWithData($Emails);

    for my $Email ( @{$Emails} ) {

        my $Header  = ${ $Email->{Header} };
        my $Body    = ${ $Email->{Body} };
        my @ToArray = @{ $Email->{ToArray} };

        push @AllEmails, {
            Header  => $Header,
            Body    => $Body,
            ToArray => \@ToArray,
        };
    }
    return @AllEmails;
}

=item EmailSentCount()

This function counts the number of send emails.

    $UnitTestEmailObject->EmailSentCount(
        UnitTestObject => $Self,
        Count          => 3,
        Message        => '3 emails send', # optional
    );

=cut

sub EmailSentCount {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(UnitTestObject Count)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{Message} ||= "$Param{Count} email(s) sent";

    my @SendEmails = $Self->EmailGet();
    $Param{UnitTestObject}->Is(
        scalar @SendEmails,
        $Param{Count},
        $Param{Message},
    );

    return 1;
}

=item EmailValidate()

This function:
    - Takes an Array (result of EmailGet())
    - Takes check parameter (regex or strings for Header, Body and ToArray)
    - checks if the check routine matches one of the found Mails
    - returns 1 or 0 (for found or not found)

Example:

    my $Success = $UnitTestEmailObject->EmailValidate(
        UnitTestObject => $Self,
        Message        => 'Email send verification',       # optional
        Email          => \@Email,                         # optional, result of EmailGet will used by default
        Header         => qr{To\:\sto\@test.com}xms,       # Regex or Array of Regexes that all have to matche
                                                           # in the Header of one single email
                                                           # example: [qr{To\:\sto\@test.com}xms, qr{To\:\scc\@test.com}xms ],

        Body    => qr{Hello [ ] World}xms,          # Regex or string 'Hello World'

        ToArray => 'email1realrecipient1@test.com', # or Array with all real recipients
                                                    # example: ['email1realrecipient1@test.com', 'email1realrecipient2@test.com', ],
                                                    #
                                                    # instead of String or Array of Strings
                                                    # a Regex or an Array of Regexes is possible too
    );

Returns:

    my $Success = 1; # or 0 if not fount

=cut

sub EmailValidate {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(UnitTestObject)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if (
        !$Param{Header}
        && !$Param{Body}
        && !$Param{ToArray}
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need at least Header OR Body OR ToArray!",
        );
        return;
    }

    # Header allows only Regexes
    if (
        $Param{Header}
        && ref $Param{Header} ne 'Regexp'
        && !IsArrayRefWithData( $Param{Header} )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need Regex or Array of Regexes in Header!",
        );
        return;
    }

    # Body allows only Regexes or Strings - if ref is defined and not Regex its false
    if (
        $Param{Body}
        && ref $Param{Body}
        && ref $Param{Body} ne 'Regexp'
        && ref $Param{Body} ne 'ARRAY'
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Just Regex, String or Array of Strings or Regexes allowed in Body!",
        );
        return;
    }

    my @Emails;
    if ( IsArrayRefWithData( $Param{Email} ) ) {
        @Emails = @{ $Param{Email} };
    }
    else {
        @Emails = $Self->EmailGet();
    }

    my $Result;
    EMAIL:
    for my $Email (@Emails) {

        # Found will contains Header and/or Body and/or ToArray as keys,
        # if the submitted Header and/or Body and/or ToArray search matched
        my %Found;

        # Counter will hold the amount of SearchParams (1 to 3 depending on Header, Body, ToArray)
        my $SearchParamCount = 0;

        SEARCH:
        for my $SearchParam (qw(Header Body ToArray)) {

            next SEARCH if !$Param{$SearchParam};

            $SearchParamCount++;

            # If the SearchParam contained an array (e.g. ToArray or Header)
            if ( IsArrayRefWithData( $Param{$SearchParam} ) ) {

                # Counter for each sucessfully found search term item
                my $FoundCount = 0;

                # Loop through the search term items of Header or ToArray
                SEARCHTERM:
                for my $SearchTerm ( @{ $Param{$SearchParam} } ) {

                    if (
                        $SearchParam eq 'Header'
                        && ref $Param{$SearchParam} ne 'Regexp'
                        && ref $Param{$SearchParam} ne 'ARRAY'
                        )
                    {
                        $LogObject->Log(
                            Priority => 'error',
                            Message  => "Just a Regex or an Array of Regexes are allowed in Header!",
                        );
                        return;
                    }

                    # If we had multiple Header or Body Regexes
                    # the Emails' Header/Body is a String -> just one compare necessary
                    if ( !ref $Email->{$SearchParam} ) {

                        # If matched increase the FoundCount
                        next SEARCHTERM if !$Self->_SearchStringOrRegex(
                            Search => $SearchTerm,
                            Data   => $Email->{$SearchParam},
                        );

                        $FoundCount++;

                        next SEARCHTERM;
                    }

                    # Check this Mails' SearchParam (e.g. ToArray entries) if the current Search Term matches
                    EMAILSEARCHPARAM:
                    for my $EmailParam ( @{ $Email->{$SearchParam} } ) {

                        # If matched increase the FoundCount
                        next EMAILSEARCHPARAM if !$Self->_SearchStringOrRegex(
                            Search => $SearchTerm,
                            Data   => $EmailParam,
                        );

                        $FoundCount++;

                        # If the searchterm (e.g. the Regex or search String)
                        # matched one ToArrayEntry, we can continue to the next searchterm
                        #
                        # (Regexes may match multiple ToArrayEntries -> matched once is enough)
                        next SEARCHTERM;
                    }

                    # No Guard-Clause :)
                }

                # If no match in this Email go to the next Mail
                next EMAIL if !$FoundCount;

                # If the amount of search params matches the amount of founds *success*
                if ( $FoundCount == scalar @{ $Param{$SearchParam} } ) {
                    $Found{$SearchParam} = 1;
                }
                next SEARCH;
            }

            # If we had an email with an ArrayRef (e.g. multiple ToArray entries)
            # but only one search term for the ToArray
            if ( IsArrayRefWithData( $Email->{$SearchParam} ) ) {

                # Go through the ToArray entries and check against our single search param
                EMAILPART:
                for my $EmailPart ( @{ $Email->{$SearchParam} } ) {

                    next EMAILPART if !$Self->_SearchStringOrRegex(
                        Search => $Param{$SearchParam},
                        Data   => $EmailPart,
                    );

                    $Found{$SearchParam} = 1;
                    next SEARCH;
                }

                # If no match in this Email go to the next Mail
                next EMAIL;
            }

            # For everything else, just compare SearchParam against EmailParam
            next SEARCH if !$Self->_SearchStringOrRegex(
                Search => $Param{$SearchParam},
                Data   => $Email->{$SearchParam},
            );

            $Found{$SearchParam} = 1;
        }

        # If the amount of SearchParams matches the amount of found SearchParams
        # this email matched => *success*
        next EMAIL if $SearchParamCount != scalar keys %Found;

        $Result = 1;

        last EMAIL;
    }

    $Param{UnitTestObject}->True(
        $Result,
        $Param{Message} || 'Email send verification',
    );

    return $Result;
}

sub _SearchStringOrRegex {
    my ( $Self, %Param ) = @_;

    return if !$Param{Search} && !$Param{Data};

    my $Search = $Param{Search};

    if ( !ref $Search ) {
        return 1 if $Param{Data} eq $Search;
    }

    if ( ref $Search eq 'Regexp' ) {
        return 1 if $Param{Data} =~ m{$Search};
    }

    return;
}

1;
