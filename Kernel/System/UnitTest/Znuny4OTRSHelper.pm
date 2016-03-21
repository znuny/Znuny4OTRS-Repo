# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Znuny4OTRSHelper;

use strict;
use warnings;

use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerUser',
    'Kernel::System::Service',
    'Kernel::System::SysConfig',
    'Kernel::System::Ticket',
    'Kernel::System::User',
    'Kernel::System::ZnunyHelper',
);

use base qw( Kernel::System::UnitTest::Helper );

use Kernel::System::VariableCheck qw(:all);

=item TestUserCreate()

creates a test user that can be used in tests. It will
be set to invalid automatically during the destructor. Returns
the login name of the new user, the password is the same.

    my $TestUserLogin = $Helper->TestUserCreate(
        Groups => ['admin', 'users'],           # optional, list of groups to add this user to (rw rights)
        Language => 'de'                        # optional, defaults to 'en' if not set
    );

=cut

sub TestUserCreate {
    my ( $Self, %Param ) = @_;

    # create test user
    my $TestUserLogin = $Self->GetRandomID();

    # disable email checks to create new user
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserAdd(
        UserFirstname => $TestUserLogin,
        UserLastname  => $TestUserLogin,
        UserLogin     => $TestUserLogin,
        UserPw        => $TestUserLogin,
        UserEmail     => $TestUserLogin . '@localunittest.com',
        ValidID       => 1,
        ChangeUserID  => 1,
# ---
# Znuny4OTRS-Repo
# ---
        %Param,
# ---
    ) || die "Could not create test user";

    # Remember UserID of the test user to later set it to invalid
    #   in the destructor.
    $Self->{TestUsers} ||= [];
    push( @{ $Self->{TestUsers} }, $TestUserID );

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
    );

=cut

sub TestCustomerUserCreate {
    my ( $Self, %Param ) = @_;

    # disable email checks to create new user
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    # create test user
    my $TestUserLogin = $Self->GetRandomID();

    my $TestUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
        Source         => 'CustomerUser',
        UserFirstname  => $TestUserLogin,
        UserLastname   => $TestUserLogin,
        UserCustomerID => $TestUserLogin,
        UserLogin      => $TestUserLogin,
        UserPassword   => $TestUserLogin,
        UserEmail      => $TestUserLogin . '@localunittest.com',
        ValidID        => 1,
        UserID         => 1,
# ---
# Znuny4OTRS-Repo
# ---
        %Param,
# ---
    ) || die "Could not create test user";

    # Remember UserID of the test user to later set it to invalid
    #   in the destructor.
    $Self->{TestCustomerUsers} ||= [];
    push( @{ $Self->{TestCustomerUsers} }, $TestUser );

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


=item CheckNumberOfEventExecution()

This function checks the number of executions of an Event via the TicketHistory

    my $Result = $Znuny4OTRSHelperObject->CheckNumberOfEventExecution(
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

        my $NumEvents = $Param{Events}->{ $Event };

        my @EventLines = grep { $_->{Name} =~ m{\s*\Q$Event\E$} } @Lines;

        $Self->Is(
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

    my $Result = $Znuny4OTRSHelperObject->SetupTestEnvironment(
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

    my $Result = $Znuny4OTRSHelperObject->ConfigureViews(
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

        next VIEW if !IsStringWithData( $View );

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

    $Znuny4OTRSHelperObject->ActivateDynamicFields(
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

    my $Result = $Znuny4OTRSHelperObject->ActivateDefaultDynamicFields();

    $Result = {
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
    };

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

    $Znuny4OTRSHelperObject->FullFeature();
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
    my $Result = $Znuny4OTRSHelperObject->FillTestEnvironment(
        User         => 0, # optional, default 5
        CustomerUser => 0, # optional, default 5
        Service      => 0, # optional, default 1 (true)
        SLA          => 0, # optional, default 1 (true)
        Type         => 0, # optional, default 1 (true)
        Queue        => 0, # optional, default 1 (true)
    );

    # create everything with defaults, except Type
    my $Result = $Znuny4OTRSHelperObject->FillTestEnvironment(
        Type => {
            'Type 1::Sub Type ÄÖÜ' => 1,
            ...
        }
    );

    # create everything with defaults, except 20 agents
    my $Result = $Znuny4OTRSHelperObject->FillTestEnvironment(
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
    for my $Attribute ( @PossibleTicketAttributes ) {

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
        for my $ServiceID ( @ServiceIDs ) {

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

    my %UserData = $Znuny4OTRSHelperObject->TestUserDataGet(
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

    my %CustomerUserData = $Znuny4OTRSHelperObject->TestCustomerUserDataGet(
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

    my $TicketID = $Znuny4OTRSHelperObject->TicketCreate();

    is equals:

    my $TicketID = $Znuny4OTRSHelperObject->TicketCreate(
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

    my $TicketID = $Znuny4OTRSHelperObject->TicketCreate(
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

    my $ArticleID = $Znuny4OTRSHelperObject->ArticleCreate(
        TicketID => 1337,
    );

    is equals:

    my $ArticleID = $Znuny4OTRSHelperObject->ArticleCreate(
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

    my $ArticleID = $Znuny4OTRSHelperObject->ArticleCreate(
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

=item DESTROY()

Calls the DESTROY function of the framework UnitTest Helper object and undos changes made by this module.

    $Object->DESTROY();
=cut

sub DESTROY {
    my ( $Self, %Param ) = @_;

    $Self->SUPER::DESTROY(@_);

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

    return 1;
}

1;
