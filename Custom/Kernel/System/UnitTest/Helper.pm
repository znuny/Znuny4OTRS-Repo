# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/18c50cfbdbec354d24076bf97c824582bbfc85da/Kernel/System/UnitTest/Helper.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Helper;
## nofilter(TidyAll::Plugin::OTRS::Perl::Time)

use strict;
use warnings;

use Kernel::System::SysConfig;
# ---
# Znuny4OTRS-Repo
# ---
use utf8;
use Kernel::System::VariableCheck qw(:all);

# for mocking purposes
use Kernel::GenericInterface::Transport;
# ---

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Cache',
    'Kernel::System::CustomerUser',
    'Kernel::System::Group',
    'Kernel::System::Main',
    'Kernel::System::UnitTest',
    'Kernel::System::User',
# ---
# Znuny4OTRS-Repo
# ---
    'Kernel::System::Service',
    'Kernel::System::SysConfig',
    'Kernel::System::Ticket',
    'Kernel::System::ZnunyHelper',
# ---
);

=head1 NAME

Kernel::System::UnitTest::Helper - unit test helper functions

=over 4

=cut

=item new()

construct a helper object.

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new(
        'Kernel::System::UnitTest::Helper' => {
            RestoreSystemConfiguration => 1,        # optional, save ZZZAuto.pm
                                                    # and restore it in the destructor
            RestoreDatabase            => 1,        # runs the test in a transaction,
                                                    # and roll it back in the destructor
        },
    );
    my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Debug} = $Param{Debug} || 0;

    $Self->{UnitTestObject} = $Kernel::OM->Get('Kernel::System::UnitTest');

    # make backup of system configuration if needed
    if ( $Param{RestoreSystemConfiguration} ) {
        $Self->{SysConfigObject} = Kernel::System::SysConfig->new();

        $Self->{SysConfigBackup} = $Self->{SysConfigObject}->Download();

        $Self->{UnitTestObject}->True( 1, 'Creating backup of the system configuration.' );
    }

    # set environment variable to skip SSL certificate verification if needed
    if ( $Param{SkipSSLVerify} ) {

        # remember original value
        $Self->{PERL_LWP_SSL_VERIFY_HOSTNAME} = $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};

        # set environment value to 0
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

        $Self->{RestoreSSLVerify} = 1;
        $Self->{UnitTestObject}->True( 1, 'Skipping SSL certificates verification' );
    }

    if ( $Param{RestoreDatabase} ) {
        $Self->{RestoreDatabase} = 1;
        my $StartedTransaction = $Self->BeginWork();
        $Self->{UnitTestObject}->True( $StartedTransaction, 'Started database transaction.' );

    }

    return $Self;
}

=item GetRandomID()

creates a random ID that can be used in tests as a unique identifier.

It is guaranteed that within a test this function will never return a duplicate.

Please note that these numbers are not really random and should only be used
to create test data.

=cut

sub GetRandomID {
    my ( $Self, %Param ) = @_;

    return 'test' . $Self->GetRandomNumber();
}

=item GetRandomNumber()

creates a random Number that can be used in tests as a unique identifier.

It is guaranteed that within a test this function will never return a duplicate.

Please note that these numbers are not really random and should only be used
to create test data.

=cut

# Use package variables here (instead of attributes in $Self)
# to make it work across several unit tests that run during the same second.
my $GetRandomNumberPreviousEpoch = 0;
my $GetRandomNumberCounter       = 0;

sub GetRandomNumber {
    my ( $Self, %Param ) = @_;

    my $Epoch = time();
    $GetRandomNumberPreviousEpoch //= 0;
    if ( $GetRandomNumberPreviousEpoch != $Epoch ) {
        $GetRandomNumberPreviousEpoch = $Epoch;
        $GetRandomNumberCounter       = 0;
    }

    return $Epoch . $GetRandomNumberCounter++;
}

=item TestUserCreate()
creates a test user that can be used in tests. It will
be set to invalid automatically during the destructor. Returns
the login name of the new user, the password is the same.
    my $TestUserLogin = $Helper->TestUserCreate(
        Groups => ['admin', 'users'],           # optional, list of groups to add this user to (rw rights)
        Language => 'de'                        # optional, defaults to 'en' if not set
# ---
# Znuny4OTRS-Repo
# ---
        KeepValid => 1, # optional, default 0
# ---
    );
=cut

sub TestUserCreate {
    my ( $Self, %Param ) = @_;

# ---
# Znuny4OTRS-Repo
# ---
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
# ---

    # create test user
    my $TestUserLogin = $Self->GetRandomID();

    # disable email checks to create new user
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

# ---
# Znuny4OTRS-Repo
# ---
#     my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserAdd(
#         UserFirstname => $TestUserLogin,
#         UserLastname  => $TestUserLogin,
#         UserLogin     => $TestUserLogin,
#         UserPw        => $TestUserLogin,
#         UserEmail     => $TestUserLogin . '@localunittest.com',
#         ValidID       => 1,
#         ChangeUserID  => 1,
#     ) || die "Could not create test user";

    my $TestUserID = $ZnunyHelperObject->_UserCreateIfNotExists(
        UserFirstname => $TestUserLogin,
        UserLastname  => $TestUserLogin,
        UserLogin     => $TestUserLogin,
        UserPw        => $TestUserLogin,
        UserEmail     => $TestUserLogin . '@localunittest.com',
        ValidID       => 1,
        ChangeUserID  => 1,
        %Param,
    );
# ---

    # Remember UserID of the test user to later set it to invalid
    #   in the destructor.
    $Self->{TestUsers} ||= [];
    push( @{ $Self->{TestUsers} }, $TestUserID );
# ---
# Znuny4OTRS-Repo
# ---
    if ( $Param{KeepValid} ) {
        $Self->{TestUsersKeepValid} ||= [];
        push( @{ $Self->{TestUsersKeepValid} }, $TestUserID );
    }
# ---

    $Self->{UnitTestObject}->True( 1, "Created test user $TestUserID" );

    # Add user to groups
    GROUP_NAME:
    for my $GroupName ( @{ $Param{Groups} || [] } ) {

        # get group object
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        my $GroupID = $GroupObject->GroupLookup( Group => $GroupName );
        die "Cannot find group $GroupName" if ( !$GroupID );

        $GroupObject->PermissionGroupUserAdd(
            GID        => $GroupID,
            UID        => $TestUserID,
            Permission => {
                ro        => 1,
                move_into => 1,
                create    => 1,
                owner     => 1,
                priority  => 1,
                rw        => 1,
            },
            UserID => 1,
        ) || die "Could not add test user $TestUserLogin to group $GroupName";

        $Self->{UnitTestObject}->True( 1, "Added test user $TestUserLogin to group $GroupName" );
    }

    # set user language
    my $UserLanguage = $Param{Language} || 'en';
    $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
        UserID => $TestUserID,
        Key    => 'UserLanguage',
        Value  => $UserLanguage,
    );
    $Self->{UnitTestObject}->True( 1, "Set user UserLanguage to $UserLanguage" );

    return $TestUserLogin;
}

=item TestCustomerUserCreate()
creates a test customer user that can be used in tests. It will
be set to invalid automatically during the destructor. Returns
the login name of the new customer user, the password is the same.
    my $TestUserLogin = $Helper->TestCustomerUserCreate(
        Language => 'de',   # optional, defaults to 'en' if not set
# ---
# Znuny4OTRS-Repo
# ---
        KeepValid => 1, # optional, default 0
# ---
    );
=cut

sub TestCustomerUserCreate {
    my ( $Self, %Param ) = @_;

# ---
# Znuny4OTRS-Repo
# ---
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
# ---

    # disable email checks to create new user
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    # create test user
    my $TestUserLogin = $Self->GetRandomID();

# ---
# Znuny4OTRS-Repo
# ---
#     my $TestUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
#         Source         => 'CustomerUser',
#         UserFirstname  => $TestUserLogin,
#         UserLastname   => $TestUserLogin,
#         UserCustomerID => $TestUserLogin,
#         UserLogin      => $TestUserLogin,
#         UserPassword   => $TestUserLogin,
#         UserEmail      => $TestUserLogin . '@localunittest.com',
#         ValidID        => 1,
#         UserID         => 1,
#     ) || die "Could not create test user";
    my $TestUser = $ZnunyHelperObject->_CustomerUserCreateIfNotExists(
        Source         => 'CustomerUser',
        UserFirstname  => $TestUserLogin,
        UserLastname   => $TestUserLogin,
        UserCustomerID => $TestUserLogin,
        UserLogin      => $TestUserLogin,
        UserPassword   => $TestUserLogin,
        UserEmail      => $TestUserLogin . '@localunittest.com',
        ValidID        => 1,
        UserID         => 1,
        %Param,
    );
# ---

    # Remember UserID of the test user to later set it to invalid
    #   in the destructor.
    $Self->{TestCustomerUsers} ||= [];
    push( @{ $Self->{TestCustomerUsers} }, $TestUser );
# ---
# Znuny4OTRS-Repo
# ---
    if ( $Param{KeepValid} ) {
        $Self->{TestCustomerUsersKeepValid} ||= [];
        push( @{ $Self->{TestCustomerUsersKeepValid} }, $TestUser );
    }
# ---

    $Self->{UnitTestObject}->True( 1, "Created test customer user $TestUser" );

    # set customer user language
    my $UserLanguage = $Param{Language} || 'en';
    $Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(
        UserID => $TestUser,
        Key    => 'UserLanguage',
        Value  => $UserLanguage,
    );
    $Self->{UnitTestObject}->True( 1, "Set customer user UserLanguage to $UserLanguage" );

    return $TestUser;
}

=item BeginWork()

    $Helper->BeginWork()

Starts a database transaction (in order to isolate the test from the static database).

=cut

sub BeginWork {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Connect();
    return $DBObject->{dbh}->begin_work();
}

=item Rollback()

    $Helper->Rollback()

Rolls back the current database transaction.

=cut

sub Rollback {
    my ( $Self, %Param ) = @_;
    my $DatabaseHandle = $Kernel::OM->Get('Kernel::System::DB')->{dbh};

    # if there is no database handle, there's nothing to rollback
    if ($DatabaseHandle) {
        return $DatabaseHandle->rollback();
    }
    return 1;
}

=item GetTestHTTPHostname()

returns a hostname for HTTP based tests, possibly including the port.

=cut

sub GetTestHTTPHostname {
    my ( $Self, %Param ) = @_;

    my $Host = $Kernel::OM->Get('Kernel::Config')->Get('TestHTTPHostname');
    return $Host if $Host;

    my $FQDN = $Kernel::OM->Get('Kernel::Config')->Get('FQDN');

    # try to resolve fqdn host
    if ( $FQDN ne 'yourhost.example.com' && gethostbyname($FQDN) ) {
        $Host = $FQDN;
    }

    # try to resolve localhost instead
    if ( !$Host && gethostbyname('localhost') ) {
        $Host = 'localhost';
    }

    # use hardcoded localhost ip address
    if ( !$Host ) {
        $Host = '127.0.0.1';
    }

    return $Host;
}

my $FixedTime;

=item FixedTimeSet()

makes it possible to override the system time as long as this object lives.
You can pass an optional time parameter that should be used, if not,
the current system time will be used.

All regular perl calls to time(), localtime() and gmtime() will use this
fixed time afterwards. If this object goes out of scope, the 'normal' system
time will be used again.

=cut

sub FixedTimeSet {
    my ( $Self, $TimeToSave ) = @_;

    $FixedTime = $TimeToSave // CORE::time();

    # This is needed to reload objects that directly use the time functions
    #   to get a hold of the overrides.
    my @Objects = (
        'Kernel::System::Time',
        'Kernel::System::Cache::FileStorable',
        'Kernel::System::PID',
    );

    for my $Object (@Objects) {
        my $FilePath = $Object;
        $FilePath =~ s{::}{/}xmsg;
        $FilePath .= '.pm';
        if ( $INC{$FilePath} ) {
            no warnings 'redefine';
            delete $INC{$FilePath};
            $Kernel::OM->Get('Kernel::System::Main')->Require($Object);
        }
    }

    return $FixedTime;
}

=item FixedTimeUnset()

restores the regular system time behaviour.

=cut

sub FixedTimeUnset {
    my ($Self) = @_;

    undef $FixedTime;

    return;
}

=item FixedTimeAddSeconds()

adds a number of seconds to the fixed system time which was previously
set by FixedTimeSet(). You can pass a negative value to go back in time.

=cut

sub FixedTimeAddSeconds {
    my ( $Self, $SecondsToAdd ) = @_;

    return if ( !defined $FixedTime );
    $FixedTime += $SecondsToAdd;
    return;
}

# See http://perldoc.perl.org/5.10.0/perlsub.html#Overriding-Built-in-Functions
BEGIN {
    *CORE::GLOBAL::time = sub {
        return defined $FixedTime ? $FixedTime : CORE::time();
    };
    *CORE::GLOBAL::localtime = sub {
        my ($Time) = @_;
        if ( !defined $Time ) {
            $Time = defined $FixedTime ? $FixedTime : CORE::time();
        }
        return CORE::localtime($Time);
    };
    *CORE::GLOBAL::gmtime = sub {
        my ($Time) = @_;
        if ( !defined $Time ) {
            $Time = defined $FixedTime ? $FixedTime : CORE::time();
        }
        return CORE::gmtime($Time);
    };
}

sub DESTROY {
    my $Self = shift;
# ---
# Znuny4OTRS-Repo
# ---
    # some Users or CustomerUsers should be kept valid (development)
    USERTYPE:
    for my $UserType ( qw( User CustomerUser ) ) {

        my $Key          = "Test$UserType";
        my $KeyKeepValid = "${Key}KeepValid";

        next USERTYPE if !IsArrayRefWithData( $Self->{$KeyKeepValid} );

        my @SetInvalid;
        USER:
        for my $User ( @{ $Self->{$Key} } ) {

            next USER if grep { $_ eq $User } @{ $Self->{$KeyKeepValid} };

            push @SetInvalid, $User;
        }

        $Self->{$Key} = \@SetInvalid;
    }
# ---

    # Reset time freeze
    FixedTimeUnset();

    #
    # Restore system configuration if needed
    #
    if ( $Self->{SysConfigBackup} ) {
        $Self->{SysConfigObject}->Upload( Content => $Self->{SysConfigBackup} );
        $Self->{UnitTestObject}->True( 1, 'Restored the system configuration' );
    }

    #
    # Restore environment variable to skip SSL certificate verification if needed
    #
    if ( $Self->{RestoreSSLVerify} ) {

        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = $Self->{PERL_LWP_SSL_VERIFY_HOSTNAME};

        $Self->{RestoreSSLVerify} = 0;

        $Self->{UnitTestObject}->True( 1, 'Restored SSL certificates verification' );
    }

    # Restore database, clean caches
    if ( $Self->{RestoreDatabase} ) {
        my $RollbackSuccess = $Self->Rollback();
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
        $Self->{UnitTestObject}->True( $RollbackSuccess, 'Rolled back all database changes and cleaned up the cache.' );
    }

    # disable email checks to create new user
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    # invalidate test users
    if ( ref $Self->{TestUsers} eq 'ARRAY' && @{ $Self->{TestUsers} } ) {
        TESTUSERS:
        for my $TestUser ( @{ $Self->{TestUsers} } ) {

            my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
                UserID => $TestUser,
            );

            if ( !$User{UserID} ) {

                # if no such user exists, there is no need to set it to invalid;
                # happens when the test user is created inside a transaction
                # that is later rolled back.
                next TESTUSERS;
            }

            # make test user invalid
            my $Success = $Kernel::OM->Get('Kernel::System::User')->UserUpdate(
                %User,
                ValidID      => 2,
                ChangeUserID => 1,
            );

            $Self->{UnitTestObject}->True( $Success, "Set test user $TestUser to invalid" );
        }
    }

    # invalidate test customer users
    if ( ref $Self->{TestCustomerUsers} eq 'ARRAY' && @{ $Self->{TestCustomerUsers} } ) {
        TESTCUSTOMERUSERS:
        for my $TestCustomerUser ( @{ $Self->{TestCustomerUsers} } ) {

            my %CustomerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
                User => $TestCustomerUser,
            );

            if ( !$CustomerUser{UserLogin} ) {

                # if no such customer user exists, there is no need to set it to invalid;
                # happens when the test customer user is created inside a transaction
                # that is later rolled back.
                next TESTCUSTOMERUSERS;
            }

            my $Success = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserUpdate(
                %CustomerUser,
                ID      => $CustomerUser{UserID},
                ValidID => 2,
                UserID  => 1,
            );

            $Self->{UnitTestObject}->True(
                $Success, "Set test customer user $TestCustomerUser to invalid"
            );
        }
    }
# ---
# Znuny4OTRS-Repo
# ---
    my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    if ( IsArrayRefWithData( $Self->{TestTickets} ) ) {

        TICKET:
        for my $TicketID ( sort @{ $Self->{TestTickets} } ) {

            next TICKET if !$TicketID;

            $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => 1,
            );
        }
    }

    return if !IsArrayRefWithData( $Self->{TestDynamicFields} );

    $ZnunyHelperObject->_DynamicFieldsDelete( @{ $Self->{TestDynamicFields} } );
# ---
}
# ---
# Znuny4OTRS-Repo
# ---

=item CheckNumberOfEventExecution()

This function checks the number of executions of an Event via the TicketHistory

    my $Result = $HelperObject->CheckNumberOfEventExecution(
        TicketID => $TicketID,
        Events   => {
            AnExampleHistoryEntry      => 2,
            AnotherExampleHistoryEntry => 0,
        },
        Comment  => 'after article create',
    );
=cut

sub CheckNumberOfEventExecution {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Comment = $Param{Comment} || '';

    my @Lines = $TicketObject->HistoryGet(
        TicketID => $Param{TicketID},
        UserID   => 1,
    );

    for my $Event ( sort keys %{ $Param{Events} } ) {

        my $NumEvents = $Param{Events}->{$Event};

        my @EventLines = grep { $_->{Name} =~ m{\s*\Q$Event\E$} } @Lines;

        $Self->{UnitTestObject}->Is(
            scalar @EventLines,
            $NumEvents,
            "check num of $Event events, $Comment",
        );

        # keep current number for reference
        $Param{Events}->{$Event} = scalar @EventLines;
    }

    return 1;
}

=item SetupTestEnvironment()

This function calls a list of other helper functions to setup a test environment with various test data.

    my $Result = $HelperObject->SetupTestEnvironment(
        ... # Parameters get passed to the FillTestEnvironment and ConfigureViews function
    );

    $Result = {
        ... # Combined result of the ActivateDefaultDynamicFields, FillTestEnvironment and ConfigureViews functions
    }
=cut

sub SetupTestEnvironment {
    my ( $Self, %Param ) = @_;

    $Self->FullFeature();

    my %Result;
    $Result{DynamicFields} = $Self->ActivateDefaultDynamicFields();

    my $TestSystemData = $Self->FillTestEnvironment(%Param);

    if ( IsHashRefWithData($TestSystemData) ) {

        %Result = (
            %Result,
            %{$TestSystemData},
        );
    }

    my $ViewData = $Self->ConfigureViews(
        AgentTicketNote => {
            Note             => 1,
            NoteMandatory    => 1,
            Owner            => 1,
            OwnerMandatory   => 1,
            Priority         => 1,
            PriorityDefault  => 1,
            Queue            => 1,
            Responsible      => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLAMandatory     => 1,
            State            => 1,
            StateType        => 1,
            TicketType       => 1,
            Title            => 1,
        },
        %Param
    );

    if ( IsHashRefWithData($ViewData) ) {

        %Result = (
            %Result,
            %{$ViewData},
        );
    }

    return \%Result;
}

=item ConfigureViews()

Toggles settings for a given view like AgentTicketNote or CustomerTicketMessage.

    my $Result = $HelperObject->ConfigureViews(
        AgentTicketNote => {
            Note             => 1,
            NoteMandatory    => 1,
            Owner            => 1,
            OwnerMandatory   => 1,
            Priority         => 1,
            PriorityDefault  => 1,
            Queue            => 1,
            Responsible      => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLAMandatory     => 1,
            State            => 1,
            StateType        => 1,
            TicketType       => 1,
            Title            => 1,
        },
        CustomerTicketMessage => {
            Priority         => 1,
            Queue            => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLA              => 1,
            SLAMandatory     => 1,
            TicketType       => 1,
        },
    );

    $Result = {
        AgentTicketNote => {
            Note             => 1,
            NoteMandatory    => 1,
            Owner            => 1,
            OwnerMandatory   => 1,
            Priority         => 1,
            PriorityDefault  => 1,
            Queue            => 1,
            Responsible      => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLAMandatory     => 1,
            State            => 1,
            StateType        => 1,
            TicketType       => 1,
            Title            => 1,
            HistoryType      => 'Phone',
            ...
        },
        CustomerTicketMessage => {
            Priority         => 1,
            Queue            => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLA              => 1,
            SLAMandatory     => 1,
            TicketType       => 1,
            ArticleType      => 'note-external',
            ...
        },

    }

=cut

sub ConfigureViews {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    return if !%Param;

    my %Result;
    VIEW:
    for my $View ( sort %Param ) {

        next VIEW if !IsStringWithData($View);

        my $ConfigKey = "Ticket::Frontend::$View";
        my $OldConfig = $ConfigObject->Get($ConfigKey);
        my $NewConfig = $Param{$View};

        next VIEW if !IsHashRefWithData($OldConfig);
        next VIEW if !IsHashRefWithData($NewConfig);

        my %UpdatedConfig = (
            %{$OldConfig},
            %{$NewConfig},
        );

        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => $ConfigKey,
            Value => \%UpdatedConfig,
        );

        $Result{$View} = \%UpdatedConfig;
    }

    return \%Result;
}

=item ActivateDynamicFields()

This function activates the given DynamicFields in each agent view.

    $HelperObject->ActivateDynamicFields(
        'UnitTestDropdown',
        'UnitTestCheckbox',
        'UnitTestText',
        'UnitTestMultiSelect',
        'UnitTestTextArea',
    );
=cut

sub ActivateDynamicFields {
    my ( $Self, @DynamicFields ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my %ActivateDynamicFields = map { $_ => 1 } @DynamicFields;

    my %Screens = (
        AgentTicketClose                              => \%ActivateDynamicFields,
        AgentTicketFreeText                           => \%ActivateDynamicFields,
        AgentTicketNote                               => \%ActivateDynamicFields,
        AgentTicketOwner                              => \%ActivateDynamicFields,
        AgentTicketPending                            => \%ActivateDynamicFields,
        AgentTicketPriority                           => \%ActivateDynamicFields,
        AgentTicketResponsible                        => \%ActivateDynamicFields,
        AgentTicketBounce                             => \%ActivateDynamicFields,
        AgentTicketCompose                            => \%ActivateDynamicFields,
        AgentTicketCustomer                           => \%ActivateDynamicFields,
        AgentTicketEmail                              => \%ActivateDynamicFields,
        AgentTicketEmailOutbound                      => \%ActivateDynamicFields,
        AgentTicketForward                            => \%ActivateDynamicFields,
        AgentTicketMerge                              => \%ActivateDynamicFields,
        AgentTicketMove                               => \%ActivateDynamicFields,
        AgentTicketPhone                              => \%ActivateDynamicFields,
        AgentTicketPhoneCommon                        => \%ActivateDynamicFields,
        AgentTicketSearch                             => \%ActivateDynamicFields,
        'AgentTicketSearch###Defaults###DynamicField' => \%ActivateDynamicFields,

    );

    $ZnunyHelperObject->_DynamicFieldsScreenEnable(%Screens);

    return 1;
}

=item ActivateDefaultDynamicFields()

This function adds one of each default dynamic fields to the system and activates them for each agent view.

    my $Result = $HelperObject->ActivateDefaultDynamicFields();

    $Result = [
        {
            Name          => 'UnitTestText',
            Label         => "UnitTestText",
            ObjectType    => 'Ticket',
            FieldType     => 'Text',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Link         => '',
            },
        },
        {
            Name          => 'UnitTestCheckbox',
            Label         => "UnitTestCheckbox",
            ObjectType    => 'Ticket',
            FieldType     => 'Checkbox',
            InternalField => 0,
            Config        => {
                DefaultValue => "0",
            },
        },
        {
            Name          => 'UnitTestDropdown',
            Label         => "UnitTestDropdown",
            ObjectType    => 'Ticket',
            FieldType     => 'Dropdown',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
                Link               => '',
            },
        },
        {
            Name          => 'UnitTestTextArea',
            Label         => "UnitTestTextArea",
            ObjectType    => 'Ticket',
            FieldType     => 'TextArea',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Rows         => '',
                Cols         => '',
            },
        },
        {
            Name          => 'UnitTestMultiSelect',
            Label         => "UnitTestMultiSelect",
            ObjectType    => 'Ticket',
            FieldType     => 'Multiselect',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
            },
        },
    ];

=cut

sub ActivateDefaultDynamicFields {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my @DynamicFields = (
        {
            Name          => 'UnitTestText',
            Label         => "UnitTestText",
            ObjectType    => 'Ticket',
            FieldType     => 'Text',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Link         => '',
            },
        },
        {
            Name          => 'UnitTestCheckbox',
            Label         => "UnitTestCheckbox",
            ObjectType    => 'Ticket',
            FieldType     => 'Checkbox',
            InternalField => 0,
            Config        => {
                DefaultValue => "0",
            },
        },
        {
            Name          => 'UnitTestDropdown',
            Label         => "UnitTestDropdown",
            ObjectType    => 'Ticket',
            FieldType     => 'Dropdown',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
                Link               => '',
            },
        },
        {
            Name          => 'UnitTestTextArea',
            Label         => "UnitTestTextArea",
            ObjectType    => 'Ticket',
            FieldType     => 'TextArea',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Rows         => '',
                Cols         => '',
            },
        },
        {
            Name          => 'UnitTestMultiSelect',
            Label         => "UnitTestMultiSelect",
            ObjectType    => 'Ticket',
            FieldType     => 'Multiselect',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
            },
        },
    );

    $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(@DynamicFields);

    my @DynamicFieldNames = map { $_->{Name} } @DynamicFields;

    $Self->{TestDynamicFields} ||= [];
    for my $DynamicFieldName (@DynamicFieldNames) {
        push @{ $Self->{TestDynamicFields} }, $DynamicFieldName;
    }

    $Self->ActivateDynamicFields(@DynamicFieldNames);

    return \@DynamicFields;
}

=item FullFeature()

Activates Type, Service and Responsible feature.

    $HelperObject->FullFeature();
=cut

sub FullFeature {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => 'Ticket::Type',
        Value => 1,
    );
    $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => 'Ticket::Service',
        Value => 1,
    );
    $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => 'Ticket::Responsible',
        Value => 1
    );

    return 1;
}

=item FillTestEnvironment()

Fills the system with test data. Data creation can be manipulated with own parameters passed.
Default parameters contain various special chars.

    # would do nothing -> return an empty HashRef
    my $Result = $HelperObject->FillTestEnvironment(
        User         => 0, # optional, default 5
        CustomerUser => 0, # optional, default 5
        Service      => 0, # optional, default 1 (true)
        SLA          => 0, # optional, default 1 (true)
        Type         => 0, # optional, default 1 (true)
        Queue        => 0, # optional, default 1 (true)
    );

    # create everything with defaults, except Type
    my $Result = $HelperObject->FillTestEnvironment(
        Type => {
            'Type 1::Sub Type ÄÖÜ' => 1,
            ...
        }
    );

    # create everything with defaults, except 20 agents
    my $Result = $HelperObject->FillTestEnvironment(
        User => 20,
    );

    Return structure looks like this:

    $Result = {
        User => [
        ],
        CustomerUser => [
        ],
        Queue => [
        ],
        Service => [
        ],
        SLA => [
        ],
        Type => [
        ]
    };

=cut

sub FillTestEnvironment {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $ServiceObject     = $Kernel::OM->Get('Kernel::System::Service');

    # first the user creation
    my %UserTypeCountsDefault = (
        User         => 5,
        CustomerUser => 5,
    );

    my %UserTypeCounts;
    for my $UserType ( sort keys %UserTypeCountsDefault ) {

        if (
            !defined $Param{$UserType}
            || !IsPositiveInteger( $Param{$UserType} )
            )
        {
            $UserTypeCounts{$UserType} = $UserTypeCountsDefault{$UserType};
        }
        elsif ( IsPositiveInteger( $Param{$UserType} ) ) {
            $UserTypeCounts{$UserType} = $Param{$UserType};
        }
    }

    my %AdditionalUserCreateData = (
        User => {
            Groups => ['users'],
            }
    );

    my %Result;
    USERTYPE:
    for my $UserType ( sort keys %UserTypeCounts ) {

        my $UserTypeCount = $UserTypeCounts{$UserType};

        next USERTYPE if !$UserTypeCount;

        my $FunctionName = "Test${UserType}DataGet";
        $Result{$UserType} = [];

        my %CreateData;
        if ( IsHashRefWithData( $AdditionalUserCreateData{$UserType} ) ) {
            %CreateData = %{ $AdditionalUserCreateData{$UserType} };
        }

        for my $Counter ( 1 .. $UserTypeCount ) {

            my %UserTypeData = $Self->$FunctionName(%CreateData);

            push @{ $Result{$UserType} }, \%UserTypeData;
        }

        # no GuardClause :)
    }

    # now the ticket attributes
    my %AttributeTestStructure = (
        'A::Level - 1::A'  => 0,
        'A::Level - 1::B'  => 0,
        'A::Level - 2::Ä' => 0,
        'A::Level - 2::Ö' => 0,
        'B::Level - !::Ü' => 0,
        'B::Level - !::ß' => 0,
        'B::Level - ?::Y'  => 0,
        'B::Level - ?::Z'  => 0,
        'C::Level - &::%'  => 0,
        'C::Level - &::$'  => 0,
        'C::Level - "::^'  => 0,
        'C::Level - "::\'' => 0,
        'D::Level - #::>'  => 0,
        'D::Level - #::<'  => 0,
        'D::Level - "::+'  => 0,
        'D::Level - "::='  => 0,
        'E::Level - *::@'  => 0,
        'E::Level - *::"'  => 0,
        'E::Level - "::()' => 0,
        'E::Level - "::{}' => 0,
        'F'                => 0,
    );

    my %WantedTicketAttributes;
    my @PossibleTicketAttributes = qw(Service SLA Type Queue);
    for my $WantedTicketAttribute (@PossibleTicketAttributes) {

        if (
            !defined $Param{$WantedTicketAttribute}
            || !IsHashRefWithData( $Param{$WantedTicketAttribute} )
            )
        {
            my %TmpAttributeTestStructure = %AttributeTestStructure;
            $WantedTicketAttributes{$WantedTicketAttribute} = \%TmpAttributeTestStructure;
        }
        elsif ( IsHashRefWithData( $Param{$WantedTicketAttribute} ) ) {
            $WantedTicketAttributes{$WantedTicketAttribute} = $Param{$WantedTicketAttribute};
        }
    }

    my %AdditionalAttributeCreateData = (
        Queue => {
            GroupID => 1,    # users
        },
        SLA => {
            ServiceIDs => [],
        },
    );

    ATTRIBUTE:
    for my $Attribute (@PossibleTicketAttributes) {

        next ATTRIBUTE if !IsHashRefWithData( $WantedTicketAttributes{$Attribute} );

        my %AttributeCreateData = %{ $WantedTicketAttributes{$Attribute} };

        my %AttributeResultData;
        ITEM:
        for my $AttributeCreateItem ( sort keys %AttributeCreateData ) {

            my $AttributeEntry = "$Attribute $AttributeCreateItem";
            my $FunctionName   = "_${Attribute}CreateIfNotExists";

            my %CreateData = (
                Name => $AttributeEntry,
            );
            if ( IsHashRefWithData( $AdditionalAttributeCreateData{$Attribute} ) ) {

                %CreateData = (
                    %CreateData,
                    %{ $AdditionalAttributeCreateData{$Attribute} },
                );
            }

            $AttributeResultData{$AttributeEntry} = $ZnunyHelperObject->$FunctionName(%CreateData);
        }

        $Result{$Attribute} = \%AttributeResultData;

        next ATTRIBUTE if $Attribute ne 'Service';

        my %ServiceList = $ServiceObject->ServiceList(
            UserID => 1,
        );
        my @ServiceIDs = keys %ServiceList;

        $AdditionalAttributeCreateData{SLA}->{ServiceIDs} = \@ServiceIDs;

        # add services as defalut service for all customers
        for my $ServiceID (@ServiceIDs) {

            $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => '<DEFAULT>',
                ServiceID         => $ServiceID,
                Active            => 1,
                UserID            => 1,
            );
        }
    }

    return \%Result;
}

=item TestUserDataGet()

Calls TestUserCreate and returns the whole UserData instead only the Login.

    my %UserData = $HelperObject->TestUserDataGet(
        Groups => ['admin', 'users'],           # optional, list of groups to add this user to (rw rights)
        Language => 'de'                        # optional, defaults to 'en' if not set
    );

    %UserData = {
        UserID        => 2,
        UserFirstname => $TestUserLogin,
        UserLastname  => $TestUserLogin,
        UserLogin     => $TestUserLogin,
        UserPw        => $TestUserLogin,
        UserEmail     => $TestUserLogin . '@localunittest.com',
    }

=cut

sub TestUserDataGet {
    my ( $Self, %Param ) = @_;

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # create test user and login
    $Self->TestUserCreate(%Param);

    # return user data of last created user
    return $UserObject->GetUserData(
        UserID => $Self->{TestUsers}->[-1],
    );
}

=item TestCustomerUserDataGet()

Calls TestCustomerUserCreate and returns the whole CustomerUserData instead only the Login.

    my %CustomerUserData = $HelperObject->TestCustomerUserDataGet(
        Language => 'de' # optional, defaults to 'en' if not set
    );

    %CustomerUserData = {
        CustomerUserID => 1,
        Source         => 'CustomerUser',
        UserFirstname  => $TestUserLogin,
        UserLastname   => $TestUserLogin,
        UserCustomerID => $TestUserLogin,
        UserLogin      => $TestUserLogin,
        UserPassword   => $TestUserLogin,
        UserEmail      => $TestUserLogin . '@localunittest.com',
        ValidID        => 1,
    }
=cut

sub TestCustomerUserDataGet {
    my ( $Self, %Param ) = @_;

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    # create test user and login
    $Self->TestCustomerUserCreate(%Param);

    # return customer user data of last created customer user
    return $CustomerUserObject->CustomerUserDataGet(
        User => $Self->{TestCustomerUsers}->[-1],
    );
}

=item TicketCreate()

Creates a Ticket with dummy data and tests the creation. All Ticket attributes are optional.

    my $TicketID = $HelperObject->TicketCreate();

    is equals:

    my $TicketID = $HelperObject->TicketCreate(
        Title        => 'UnitTest ticket',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'UnitTestCustomer',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
    );

    To overwrite:

    my $TicketID = $HelperObject->TicketCreate(
        CustomerUser => 'another_customer@example.com',
    );

    Result:
    $TicketID = 1337;
=cut

sub TicketCreate {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %TicketAttributes = (
        Title        => 'UnitTest ticket',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'UnitTestCustomer',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
        %Param,
    );

    # create test ticket
    my $TicketID = $TicketObject->TicketCreate(%TicketAttributes);

    $Self->{UnitTestObject}->True(
        $TicketID,
        "Ticket '$TicketAttributes{Title}' is created - ID $TicketID",
    );

    # store for later cleanup
    $Self->{TestTickets} ||= [];
    push @{ $Self->{TestTickets} }, $TicketID;

    return $TicketID;
}

=item ArticleCreate()

Creates an Article with dummy data and tests the creation. All Article attributes except the TicketID are optional.

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID => 1337,
    );

    is equals:

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID       => 1337,
        ArticleType    => 'note-internal',
        SenderType     => 'agent',
        Subject        => 'UnitTest subject test',
        Body           => 'UnitTest body test',
        ContentType    => 'text/plain; charset=ISO-8859-15',
        HistoryType    => 'OwnerUpdate',
        HistoryComment => 'Some free text!',
        UserID         => 1,
        NoAgentNotify  => 1,
    );

    To overwrite:

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID   => 1337,
        SenderType => 'customer',
    );

    Result:
    $ArticleID = 1337;
=cut

sub ArticleCreate {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %ArticleAttributes = (
        ArticleType    => 'note-internal',
        SenderType     => 'agent',
        Subject        => 'UnitTest subject test',
        Body           => 'UnitTest body test',
        ContentType    => 'text/plain; charset=ISO-8859-15',
        HistoryType    => 'OwnerUpdate',
        HistoryComment => 'Some free text!',
        UserID         => 1,
        NoAgentNotify  => 1,
        %Param,
    );

    # create test ticket
    my $ArticleID = $TicketObject->ArticleCreate(%ArticleAttributes);

    $Self->{UnitTestObject}->True(
        $ArticleID,
        "Article '$ArticleAttributes{Subject}' is created - ID $ArticleID",
    );

    return $ArticleID;
}

=item TestUserPreferencesSet()
sets preferences for a given Login or UserID
    my $Success = $HelperObject->TestUserPreferencesSet(
        UserID      => 123,
        Preferences => {                  # "Preferences" hashref is required
            OutOfOffice  => 1,            # example Key -> Value pair for User Preferences
            UserMobile   => undef,        # example for deleting a UserPreferences Key's value
            UserLanguage => '',           # example for deleting a UserPreferences Key's value
        },
    );
=cut

sub TestUserPreferencesSet {
    my ( $Self, %Param ) = @_;

    return if !$Param{UserID};
    return if !IsHashRefWithData( $Param{Preferences} );

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    for my $Key ( sort keys %{ $Param{Preferences} } ) {

        $UserObject->SetPreferences(
            Key    => $Key,
            Value  => $Param{Preferences}->{$Key} // '',
            UserID => $Param{UserID},
        );
    }

    return 1;
};

=item MockWebservice()

Mocks all outgoing requests to a given mapping.

    my $Result = $HelperObject->MockWebservice(
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

sub MockWebservice {
    my ( $Self, %Param ) = @_;

    # temporary store the given request data
    for my $InvokerName ( sort keys %Param ) {

        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => 'MockWebservice',
            Key   => $InvokerName,
            Value => $Param{ $InvokerName },
            TTL   => 60 * 60 * 24,
        );
    }

    {
        no warnings 'redefine';

        sub Kernel::GenericInterface::Transport::RequesterPerformRequest {
            my ( $Self, %Param ) = @_;

            my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

            if ( !$Param{Operation} ) {

                return $Self->{DebuggerObject}->Error(
                    Summary => 'Missing parameter Operation.',
                );
            }

            if ( $Param{Data} && ref $Param{Data} ne 'HASH' ) {

                return $Self->{DebuggerObject}->Error(
                    Summary => 'Data is not a hash reference.',
                    Data    => $Param{Data},
                );
            }

            my $InvokerData = $Kernel::OM->Get('Kernel::System::Cache')->Get(
                Type => 'MockWebservice',
                Key  => $Param{Operation},
            );

            if ( !IsArrayRefWithData($InvokerData) ) {

                my $RequestData  = $Kernel::OM->Get('Kernel::System::Main')->Dump($Param{Data});
                my $ErrorMessage = "Can't find Mock data for Invoker '$Param{Operation}' (Data:  $RequestData).";

                $HelperObject->{UnitTestObject}->_Print( 0, $ErrorMessage .  " Data: $RequestData" );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            my $Counter = 0;
            my $Result;
            REQUEST:
            for my $PossibleRequest ( @{ $InvokerData } ) {

                $Counter++;

                next REQUEST if DataIsDifferent(
                    Data1 => $PossibleRequest->{Data},
                    Data2 => $Param{Data},
                );

                $Result = $PossibleRequest->{Result};

                last REQUEST;
            }

            if ( !IsHashRefWithData( $Result ) ) {

               my $RequestData  = $Kernel::OM->Get('Kernel::System::Main')->Dump($Param{Data});
               my $ErrorMessage = "Can't find Mock data for Invoker '$Param{Operation}' matching the given request Data structure.";

                $HelperObject->{UnitTestObject}->_Print( 0, $ErrorMessage .  " Data: $RequestData" );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            my $RequestData = $Kernel::OM->Get('Kernel::System::Main')->Dump($Param{Data});
            $HelperObject->{UnitTestObject}->_Print( 1, "Invoker '$Param{Operation}' result #$Counter succcessfully executed (Data: $RequestData)." );

            return $Result;
        }
    }

    return 1;
}

# ---

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
