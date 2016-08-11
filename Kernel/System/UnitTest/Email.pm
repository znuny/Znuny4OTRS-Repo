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

    my @Email = $UnitTestEmailObject->EmailGet();

Returns:

    @Email = (
        {
            Header => "Email1 Header text...",
            Body => "Email1 Header text...",
            TOArray => ['email1realrecipient1@test.com', 'email1realrecipient2@test.com', 'email1realrecipient1@test.com', ],
        },
        {
            Header => "Email2 Header text...",
            Body => "Email2 Header text...",
            TOArray => ['email2realrecipient1@test.com'],
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

    EMAILLOOP:
    for my $Email ( @{$Emails} ) {

        my $Header  = ${ $Email->{Header} };
        my $Body    = ${ $Email->{Body} };
        my @TOArray = @{ $Email->{ToArray} };

        push @AllEmails, {
            Header  => $Header,
            Body    => $Body,
            TOArray => \@TOArray,
        };
    }
    return @AllEmails;
}

=item EmailValidate()

This function:
    - Takes an Array (result of EmailGet())
    - Takes check parameter (regex or strings for Header, Body and TOArray)
    - checks if the check routine matches one of the found Mails
    - returns 1 or 0 (for found or not found)

Example:

    my $Success = $UnitTestEmailObject->EmailValidate(
        Email   => \@Email,
        Header  => qr{To\:\sto\@test.com}xms,       # Regex or Array of Regexes that all have to matche
                                                    # in the Header of one single email
                                                    # example: [qr{To\:\sto\@test.com}xms, qr{To\:\scc\@test.com}xms ],

        Body    => qr{Hello [ ] World}xms,          # Regex or string 'Hello World'

        TOArray => 'email1realrecipient1@test.com', # or Array with all real recipients
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

    NEEDEDLOOP:
    for my $Needed (qw(Email)) {
        next NEEDEDLOOP if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if (
        !$Param{Header}
        && !$Param{Body}
        && !$Param{TOArray}
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

    if ( !IsArrayRefWithData( $Param{Email} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Email has to be an array ref!",
        );
        return;
    }

    my @Emails = @{ $Param{Email} };

    EMAILLOOP:
    for my $Email (@Emails) {

        # Found will contains Header and/or Body and/or TOArray as keys,
        # if the submitted Header and/or Body and/or TOArray search matched
        my %Found;

        # Counter will hold the amount of SearchParams (1 to 3 depending on Header, Body, TOArray)
        my $SearchParamCount = 0;

        SEARCHLOOP:
        for my $SearchParam (qw(Header Body TOArray)) {

            next SEARCHLOOP if !$Param{$SearchParam};

            $SearchParamCount++;

            # If the SearchParam contained an array (e.g. TOArray or Header)
            if ( IsArrayRefWithData( $Param{$SearchParam} ) ) {

                # Counter for each sucessfully found search term item
                my $FoundCount = 0;

                # Loop through the search term items of Header or TOArray
                SEARCHTERMLOOP:
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
                        next SEARCHTERMLOOP if !$Self->_SearchStringOrRegex(
                            Search => $SearchTerm,
                            Data   => $Email->{$SearchParam},
                        );

                        $FoundCount++;

                        next SEARCHTERMLOOP;
                    }

                    # Check this Mails' SearchParam (e.g. TOArray entries) if the current Search Term matches
                    EMAILSEARCHPARAMLOOP:
                    for my $EmailParam ( @{ $Email->{$SearchParam} } ) {

                        # If matched increase the FoundCount
                        next EMAILSEARCHPARAMLOOP if !$Self->_SearchStringOrRegex(
                            Search => $SearchTerm,
                            Data   => $EmailParam,
                        );

                        $FoundCount++;

                        # If the searchterm (e.g. the Regex or search String)
                        # matched one TOArrayEntry, we can continue to the next searchterm
                        #
                        # (Regexes may match multiple ToArrayEntries -> matched once is enough)
                        next SEARCHTERMLOOP;
                    }

                    # No Guard-Clause :)
                }

                # If no match in this Email go to the next Mail
                next EMAILLOOP if !$FoundCount;

                # If the amount of search params matches the amount of founds *success*
                if ( $FoundCount == scalar @{ $Param{$SearchParam} } ) {
                    $Found{$SearchParam} = 1;
                }
                next SEARCHLOOP;
            }

            # If we had an email with an ArrayRef (e.g. multiple TOArray entries)
            # but only one search term for the TOArray
            if ( IsArrayRefWithData( $Email->{$SearchParam} ) ) {

                # Go through the TOArray entries and check against our single search param
                EMAILPARTLOOP:
                for my $EmailPart ( @{ $Email->{$SearchParam} } ) {

                    next EMAILPARTLOOP if !$Self->_SearchStringOrRegex(
                        Search => $Param{$SearchParam},
                        Data   => $EmailPart,
                    );

                    $Found{$SearchParam} = 1;
                    next SEARCHLOOP;
                }

                # If no match in this Email go to the next Mail
                next EMAILLOOP;
            }

            # For everything else, just compare SearchParam against EmailParam
            next SEARCHLOOP if !$Self->_SearchStringOrRegex(
                Search => $Param{$SearchParam},
                Data   => $Email->{$SearchParam},
            );

            $Found{$SearchParam} = 1;
        }

        # If the amount of SearchParams matches the amount of found SearchParams
        # this email matched => *success*
        return 1 if $SearchParamCount == scalar keys %Found;
    }

    return;
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
