# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)

package Kernel::System::UnitTest::WebUserAgent;

use strict;
use warnings;

use HTTP::Response;
use Sub::Override;
use Test::LWP::UserAgent;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::UnitTest::WebUserAgent - WebUserAgent lib

=head1 SYNOPSIS

All WebUserAgent functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestWebUserAgentObject = $Kernel::OM->Get('Kernel::System::UnitTest::WebUserAgent');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{RiggedUserAgent}      = Test::LWP::UserAgent->new();
    $Self->{OverwrittenUserAgent} = undef;

    return $Self;
}

=item Mock()

Mocks all outgoing requests to a given mapping.

    my $Success = $UnitTestWebUserAgentObject->Mock(
        URL            => qr/testserver\/success/,
        Status         => 'OK',
        StatusCode     => '200',
        Header         => [ 'Content-Type' => 'application/json' ],
        Body           => '{ "access_token": "123", "token_type": "ABC" }',
    );

Returns:

    my $Success = 1;

=cut

sub Mock {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(URL Status StatusCode Header Body)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in !",
        );
        return;
    }

    my $URL        = $Param{URL};
    my $Status     = $Param{Status};
    my $StatusCode = $Param{StatusCode};
    my $Header     = $Param{Header};
    my $Body       = $Param{Body};

    $Self->{RiggedUserAgent}->map_response(
        $URL => HTTP::Response->new(
            $StatusCode,
            $Status,
            $Header,
            $Body,
        ),
    );

    $Self->_OverwrittenUserAgentRestore();

    $Self->{OverwrittenUserAgent} = Sub::Override->new(
        'LWP::UserAgent::new' => sub { return $Self->{RiggedUserAgent} }
    );

    return 1;
}

=item Reset()

This function will remove all mocks and mocking status.

    my $Success = $UnitTestWebUserAgentObject->Reset();

Returns:

    my $Success = 1;

=cut

sub Reset {
    my ( $Self, %Param ) = @_;

    $Self->_OverwrittenUserAgentRestore();
    $Self->{RiggedUserAgent}->unmap_all();

    return 1;
}

=item _OverwrittenUserAgentRestore()

Restores overwritten useragent.

    my $Success = $UnitTestWebUserAgentObject->_OverwrittenUserAgentRestore();

Returns:

    my $Success = 1;

=cut

sub _OverwrittenUserAgentRestore {
    my ( $Self, %Param ) = @_;

    return 1 if !defined $Self->{OverwrittenUserAgent};

    $Self->{OverwrittenUserAgent}->restore();
    $Self->{OverwrittenUserAgent} = undef;

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
