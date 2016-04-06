# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)

package Kernel::System::UnitTest::Webservice;

use strict;
use warnings;

# for mocking purposes
use Kernel::GenericInterface::Transport;

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::UnitTest::Webservice - webservice lib

=head1 SYNOPSIS

All webservice functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestWebserviceObject = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'UnitTestWebservice';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=item Mock()

Mocks all outgoing requests to a given mapping.

    my $Result = $UnitTestWebserviceObject->Mock(
        InvokerName123 => [
            {
                Data => {
                    OutgoingData => 'Value'
                },
                Result => {
                    Success      => 1,
                    ErrorMessage => '',
                    Data         => {
                        YAY => 'so true',
                    },
                }
            },
            ...
        ],
        ...
    );


    Now you can use the regular framework RequesterObject to perform this request like:

    my $RequesterObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');

    my $Result = $RequesterObject->Run(
        WebserviceID => 1,                      # ID of the configured remote web service to use
        Invoker      => 'InvokerName123',       # Name of the Invoker to be used for sending the request
        Data         => {                       # Data payload for the Invoker request (remote webservice)
            OutgoingData => 'Value'
        },
    );

    $Result = {
        Success => 1,
        Data    => {
            YAY => 'so true',
        },
    };

=cut

sub Mock {
    my ( $Self, %Param ) = @_;

    # temporary store the given request data
    for my $InvokerName ( sort keys %Param ) {

        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            Key   => $InvokerName,
            Value => $Param{$InvokerName},
            TTL   => $Self->{CacheTTL},
        );
    }

    {
        no warnings 'redefine';

        sub Kernel::GenericInterface::Transport::RequesterPerformRequest {    ## no critic
            my ( $Self, %Param ) = @_;

            my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

            my $CacheType       = 'UnitTestWebservice';
            my $CacheTTL        = 60 * 60 * 24 * 20;
            my $CacheKeyResults = 'Results';

            my $StoredResults = $CacheObject->Get(
                Type => $CacheType,
                Key  => $CacheKeyResults,
            );
            $StoredResults ||= [];

            if ( !$Param{Operation} ) {

                my $ErrorMessage = 'Missing parameter Operation.';

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $Kernel::OM->Get('Kernel::System::Cache')->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            if ( $Param{Data} && ref $Param{Data} ne 'HASH' ) {

                my $ErrorMessage = 'Data is not a hash reference.';

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $Kernel::OM->Get('Kernel::System::Cache')->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            my $InvokerData = $CacheObject->Get(
                Type => $CacheType,
                Key  => $Param{Operation},
            );

            if ( !IsArrayRefWithData($InvokerData) ) {

                my $ErrorMessage = "Can't find matching Mock data.";

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $Kernel::OM->Get('Kernel::System::Cache')->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            my $Counter = 0;
            my $Result;
            REQUEST:
            for my $PossibleRequest ( @{$InvokerData} ) {

                $Counter++;

                next REQUEST if DataIsDifferent(
                    Data1 => $PossibleRequest->{Data},
                    Data2 => $Param{Data},
                );

                $Result = $PossibleRequest->{Result};

                last REQUEST;
            }

            if ( !IsHashRefWithData($Result) ) {

                my $ErrorMessage = "Can't find Mock data matching the given request Data structure.";

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $Kernel::OM->Get('Kernel::System::Cache')->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            push @{$StoredResults}, {
                Success       => 1,
                Invoker       => $Param{Operation},
                Data          => $Param{Data},
                Result        => $Result,
                ResultCounter => $Counter,
            };

            $Kernel::OM->Get('Kernel::System::Cache')->Set(
                Type  => $CacheType,
                Key   => $CacheKeyResults,
                Value => $StoredResults,
                TTL   => $CacheTTL,
            );

            return $Result;
        }
    }

    return 1;
}

=item Result()

Returns the result of all requests since beginning or the last $UnitTestWebserviceObject->Result() call. Result cache gets cleared after calling this function.

    my $Result = $UnitTestWebserviceObject->Result();

    $Result = [
        {
            Success      => 0,
            ErrorMessage => "Can't find Mock data matching the given request Data structure.",
            Invoker      => 'UserDataGet',
            Data         => {
                Foo => 'Bar',
            },
        },
        {
            Success => 1,
            Invoker => 'Name',
            Data    => {
                UserID => 'han',
            },
            Result => {
                Success => 1,
                Data    => {
                    UserName => 'Han Solo',
                }
            },
            ResultCounter => 3,
        },
        ...
    ];

=cut

sub Result {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    my $CacheType       = 'UnitTestWebservice';
    my $CacheKeyResults = 'Results';

    my $StoredResults = $CacheObject->Get(
        Type => $CacheType,
        Key  => $CacheKeyResults,
    );
    $StoredResults ||= [];

    $CacheObject->Delete(
        Type => $CacheType,
        Key  => $CacheKeyResults,
    );

    return $StoredResults;
}

=item ValidateResult()

Processes the results of expected mocked webservice calls. If no webservice call was mocked an error is printed.

    my $Result = $UnitTestWebserviceObject->ValidateResult(
        UnitTestObject => $Self,
        RequestCount   => 1, # default, defines the number of requests that should have been processed
    );

    $Result = [
        {
            Success      => 0,
            ErrorMessage => "Can't find Mock data matching the given request Data structure.",
            Invoker      => 'UserDataGet',
            Data         => {
                Foo => 'Bar',
            },
        },
        {
            Success => 1,
            Invoker => 'Name',
            Data    => {
                UserID => 'han',
            },
            Result => {
                Success => 1,
                Data    => {
                    UserName => 'Han Solo',
                }
            },
            ResultCounter => 3,
        },
        ...
    ];

=cut

sub ValidateResult {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(UnitTestObject)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{RequestCount} ||= 1;

    my $MockResults        = $Self->Result();
    my $IsArrayRefWithData = IsArrayRefWithData($MockResults);

    $Param{UnitTestObject}->True(
        $IsArrayRefWithData,
        'Webservice calls were executed',
    );

    return if !$IsArrayRefWithData;

    my $Counter = 0;
    RESULT:
    for my $MockResult ( @{$MockResults} ) {

        $Counter++;

        my $IsHashRefWithData = IsHashRefWithData($MockResult);

        $Param{UnitTestObject}->True(
            $IsHashRefWithData,
            "$Counter - Mock result has the right structure",
        );

        next RESULT if !$IsHashRefWithData;

        my $LogMessage = "$Counter - Request mock data was found";
        if ( !$MockResult->{Success} ) {
            $LogMessage .= ". Error Message: $MockResult->{ErrorMessage}";
        }
        else {
            $LogMessage .= " for Invoker '$MockResult->{Invoker}'";
        }

        $Param{UnitTestObject}->True(
            $MockResult->{Success},
            $LogMessage,
        );
    }

    $Param{UnitTestObject}->Is(
        $Counter,
        $Param{RequestCount},
        "Number of processed webservice requests",
    );

    return $MockResults;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
