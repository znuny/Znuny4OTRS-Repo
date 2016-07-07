# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)

package Kernel::System::ZnunyHelper;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::Group',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::NotificationEvent',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::SLA',
    'Kernel::System::Service',
    'Kernel::System::State',
    'Kernel::System::SysConfig',
    'Kernel::System::Type',
    'Kernel::System::User',
    'Kernel::System::Valid',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::ZnunyHelper

=head1 SYNOPSIS

All ZnunyHelper functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    # rebuild ZZZ* files
    $Kernel::OM->Get('Kernel::System::SysConfig')->WriteDefault();

    # define the ZZZ files
    my @ZZZFiles = (
        'ZZZAAuto.pm',
        'ZZZAuto.pm',
    );

    # disable redefine warnings in this scope
    {
        no warnings 'redefine';

        # reload the ZZZ files (mod_perl workaround)
        for my $ZZZFile (@ZZZFiles) {

            PREFIX:
            for my $Prefix (@INC) {
                my $File = $Prefix . '/Kernel/Config/Files/' . $ZZZFile;
                next PREFIX if !-f $File;
                do $File;
                last PREFIX;
            }
        }

        # reset all warnings
    }

    return $Self;
}

=item _ItemReverseListGet()

checks if a item (for example a service name) is in a reverse item list (for example reverse %ServiceList)
with case sensitive check

    my $ItemID = $ZnunyHelperObject->_ItemReverseListGet($ServiceName, %ServiceListReverse);

Returns:

    my $ItemID = 123;

=cut

sub _ItemReverseListGet {
    my ( $Self, $ItemName, %ItemListReverse ) = @_;

    return if !$ItemName;

    $ItemName =~ s{\A\s*}{}g;
    $ItemName =~ s{\s*\z}{}g;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $ItemID;
    if ( $DBObject->{Backend}->{'DB::CaseSensitive'} ) {
        $ItemID = $ItemListReverse{$ItemName};
    }
    else {
        my %ItemListReverseLC = map { lc $_ => $ItemListReverse{$_} } keys %ItemListReverse;

        $ItemID = $ItemListReverseLC{ lc $ItemName };
    }

    return $ItemID;
}

=item _PostmasterXHeaderAdd()

This function adds a Postmaster X-Header to the list of Postmaster X-Headers to the SysConfig.

    my $Success = $ZnunyHelperObject->_PostmasterXHeaderAdd(
        Header => 'X-OTRS-OwnHeader'
    );

    or

    my $Success = $ZnunyHelperObject->_PostmasterXHeaderAdd(
        Header => [
            'X-OTRS-OwnHeader',
            'AnotherHeader',
        ]
    );

=cut

sub _PostmasterXHeaderAdd {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Header)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @HeadersToAdd;
    if ( IsArrayRefWithData( $Param{Header} ) ) {
        @HeadersToAdd = @{ $Param{Header} };
    }
    elsif ( IsStringWithData( $Param{Header} ) ) {
        push @HeadersToAdd, $Param{Header};
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Header' should be an ArrayRef of String with data!",
        );
        return;
    }

    my $ConfiguredHeaders = $ConfigObject->Get('PostmasterX-Header');
    return if ref $ConfiguredHeaders ne 'ARRAY';

    my %ConfiguredHeaders = map { $_ => 1 } @{$ConfiguredHeaders};

    HEADER:
    for my $HeaderToAdd (@HeadersToAdd) {
        $ConfiguredHeaders{$HeaderToAdd} = 1;
    }

    return $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => 'PostmasterX-Header',
        Value => [ sort keys %ConfiguredHeaders ],
    );
}

=item _PostmasterXHeaderRemove()

This function removes a Postmaster X-Header from the list of Postmaster X-Headers in the SysConfig.

    my $Success = $ZnunyHelperObject->_PostmasterXHeaderRemove(
        Header => 'X-OTRS-OwnHeader'
    );

    or

    my $Success = $ZnunyHelperObject->_PostmasterXHeaderRemove(
        Header => [
            'X-OTRS-OwnHeader',
            'AnotherHeader',
        ]
    );

=cut

sub _PostmasterXHeaderRemove {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Header)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @HeadersToRemove;
    if ( IsArrayRefWithData( $Param{Header} ) ) {
        @HeadersToRemove = @{ $Param{Header} };
    }
    elsif ( IsStringWithData( $Param{Header} ) ) {
        push @HeadersToRemove, $Param{Header};
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Header' should be an ArrayRef of String with data!",
        );
        return;
    }

    my $ConfiguredHeaders = $ConfigObject->Get('PostmasterX-Header');
    return if ref $ConfiguredHeaders ne 'ARRAY';

    my %ConfiguredHeaders = map { $_ => 1 } @{$ConfiguredHeaders};

    HEADER:
    for my $HeaderToRemove (@HeadersToRemove) {
        delete $ConfiguredHeaders{$HeaderToRemove};
    }

    return $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => 'PostmasterX-Header',
        Value => [ sort keys %ConfiguredHeaders ],
    );
}

=item _EventAdd()

This function adds an Event to the list of Events of an Object to the SysConfig.

    my $Success = $ZnunyHelperObject->_EventAdd(
        Object => 'Ticket', # Ticket, Article, Queue...
        Event  => 'MyCustomEvent'
    );

    or

    my $Success = $ZnunyHelperObject->_EventAdd(
        Object => 'Ticket',
        Event  => [
            'MyCustomEvent',
            'AnotherCustomEvent',
        ]
    );

=cut

sub _EventAdd {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Object Event)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @AddEvents;
    if ( IsArrayRefWithData( $Param{Event} ) ) {
        @AddEvents = @{ $Param{Event} };
    }
    elsif ( IsStringWithData( $Param{Event} ) ) {
        push @AddEvents, $Param{Event};
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Event' should be an ArrayRef of String with data!",
        );
        return;
    }

    my $Events = $ConfigObject->Get('Events');

    return if !IsHashRefWithData($Events);

    $Events->{ $Param{Object} } ||= [];

    my @ConfigEvents = @{ $Events->{ $Param{Object} } };

    EVENT:
    for my $AddEvent (@AddEvents) {
        next EVENT if grep { $AddEvent eq $_ } @ConfigEvents;
        push @ConfigEvents, $AddEvent;
    }

    return $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => "Events###" . $Param{Object},
        Value => \@ConfigEvents,
    );
}

=item _EventRemove()

This function removes an Event to the list of Events of an Object to the SysConfig.

    my $Success = $ZnunyHelperObject->_EventRemove(
        Object => 'Ticket', # Ticket, Article, Queue...
        Event  => 'MyCustomEvent'
    );

    or

    my $Success = $ZnunyHelperObject->_EventRemove(
        Object => 'Ticket',
        Event  => [
            'MyCustomEvent',
            'AnotherCustomEvent',
        ]
    );

=cut

sub _EventRemove {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Object Event)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @RemoveEvents;
    if ( IsArrayRefWithData( $Param{Event} ) ) {
        @RemoveEvents = @{ $Param{Event} };
    }
    elsif ( IsStringWithData( $Param{Event} ) ) {
        push @RemoveEvents, $Param{Event};
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Event' should be an ArrayRef of String with data!",
        );
        return;
    }

    my $Events = $ConfigObject->Get('Events');

    return if !IsHashRefWithData($Events);

    $Events->{ $Param{Object} } ||= [];

    my @ConfigEvents;
    EVENT:
    for my $CurrentEvent ( @{ $Events->{ $Param{Object} } } ) {
        next EVENT if grep { $CurrentEvent eq $_ } @RemoveEvents;
        push @ConfigEvents, $CurrentEvent;
    }

    return $SysConfigObject->ConfigItemUpdate(
        Valid => 1,
        Key   => "Events###" . $Param{Object},
        Value => \@ConfigEvents,
    );
}

=item _LoaderAdd()

This function adds JavaScript and CSS files to the load of defined screens.

    my %LoaderConfig = (
        AgentTicketPhone => [
            'Core.Agent.WPTicketOEChange.css',
            'Core.Agent.WPTicketOEChange.js'
        ],
    );

    my $Success = $ZnunyHelperObject->_LoaderAdd(%LoaderConfig);

Returns:

    my $Success = 1;

=cut

sub _LoaderAdd {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    my %LoaderConfig = %Param;

    my $ExtensionRegExp = '\.(css|js)$';
    VIEW:
    for my $View ( sort keys %LoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $LoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

        # get existing config for each View
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( $CustomerInterfacePrefix . "Frontend::Module" )->{$View};

        if ( !IsHashRefWithData($Config) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while getting '${CustomerInterfacePrefix}Frontend::Module' for view '$View'.",
            );
            next VIEW;
        }

        my @JSLoaderFiles;
        my @CSSLoaderFiles;
        if ( IsHashRefWithData( $Config->{Loader} ) ) {

            if ( IsArrayRefWithData( $Config->{Loader}->{JavaScript} ) ) {
                @JSLoaderFiles = @{ $Config->{Loader}->{JavaScript} };
            }
            if ( IsArrayRefWithData( $Config->{Loader}->{CSS} ) ) {
                @CSSLoaderFiles = @{ $Config->{Loader}->{CSS} };
            }
        }

        LOADERFILE:
        for my $NewLoaderFile ( sort @{ $LoaderConfig{$View} } ) {

            next LOADERFILE if $NewLoaderFile !~ m{$ExtensionRegExp}i;

            if ( lc $1 eq 'css' ) {

                next LOADERFILE if grep { $NewLoaderFile eq $_ } @CSSLoaderFiles;

                push @CSSLoaderFiles, $NewLoaderFile;
            }
            elsif ( lc $1 eq 'js' ) {

                next LOADERFILE if grep { $NewLoaderFile eq $_ } @JSLoaderFiles;

                push @JSLoaderFiles, $NewLoaderFile;
            }
        }

        $Config->{Loader}->{JavaScript} = \@JSLoaderFiles;
        $Config->{Loader}->{CSS}        = \@CSSLoaderFiles;

        # update the sysconfig
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => $CustomerInterfacePrefix . "Frontend::Module###" . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _LoaderRemove()

This function removes JavaScript and CSS files to the load of defined screens.

    my %LoaderConfig = (
        AgentTicketPhone => [
            'Core.Agent.WPTicketOEChange.css',
            'Core.Agent.WPTicketOEChange.js'
        ],
    );

    my $Success = $ZnunyHelperObject->_LoaderRemove(%LoaderConfig);

Returns:

    my $Success = 1;

=cut

sub _LoaderRemove {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %LoaderConfig = %Param;

    VIEW:
    for my $View ( sort keys %LoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $LoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

        # get existing config for each View
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( $CustomerInterfacePrefix . "Frontend::Module" )->{$View};

        if ( !IsHashRefWithData($Config) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while getting '${CustomerInterfacePrefix}Frontend::Module' for view '$View'.",
            );
            next VIEW;
        }

        my @JSLoaderFiles;
        my @CSSLoaderFiles;
        if ( IsHashRefWithData( $Config->{Loader} ) ) {

            if ( IsArrayRefWithData( $Config->{Loader}->{JavaScript} ) ) {
                @JSLoaderFiles = @{ $Config->{Loader}->{JavaScript} };
            }
            if ( IsArrayRefWithData( $Config->{Loader}->{CSS} ) ) {
                @CSSLoaderFiles = @{ $Config->{Loader}->{CSS} };
            }
        }

        if (
            !scalar @JSLoaderFiles
            && !scalar @CSSLoaderFiles
            )
        {
            next VIEW;
        }

        if ( scalar @JSLoaderFiles ) {

            my @NewJSLoaderFiles;
            LOADERFILE:
            for my $JSLoaderFile (@JSLoaderFiles) {

                next LOADERFILE if grep { $JSLoaderFile eq $_ } @{ $LoaderConfig{$View} };

                push @NewJSLoaderFiles, $JSLoaderFile;
            }

            $Config->{Loader}->{JavaScript} = \@NewJSLoaderFiles;
        }

        if ( scalar @CSSLoaderFiles ) {

            my @NewCSSLoaderFiles;
            LOADERFILE:
            for my $CSSLoaderFile (@CSSLoaderFiles) {

                next LOADERFILE if grep { $CSSLoaderFile eq $_ } @{ $LoaderConfig{$View} };

                push @NewCSSLoaderFiles, $CSSLoaderFile;
            }

            $Config->{Loader}->{CSS} = \@NewCSSLoaderFiles;
        }

        # update the sysconfig
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => $CustomerInterfacePrefix . 'Frontend::Module###' . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _DefaultColumnsGet()

This function returns the DefaultColumn Attributes of the requested SysConfigs.

    my @Configs = (
        'Ticket::Frontend::AgentTicketStatusView###DefaultColumns',
        'Ticket::Frontend::AgentTicketQueue###DefaultColumns',
        'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns',
        'Ticket::Frontend::AgentTicketWatchView###DefaultColumns',
        'Ticket::Frontend::AgentTicketLockedView###DefaultColumns',
        'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns',
        'Ticket::Frontend::AgentTicketSearch###DefaultColumns',
        'Ticket::Frontend::AgentTicketService###DefaultColumns',

        # substructure of DefaultColumns
        'DashboardBackend###0100-TicketPendingReminder',
        'DashboardBackend###0110-TicketEscalation',
        'DashboardBackend###0120-TicketNew',
        'DashboardBackend###0130-TicketOpen',

        # substructure of DefaultColumns
        'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder',
        'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation',
        'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew',
        'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen',
    );

    my %Configs = $ZnunyHelperObject->_DefaultColumnsGet(@Configs);

Returns:

    my %Configs = (
        'Ticket::Frontend::AgentTicketStatusView###DefaultColumns' => {
            Title                     => 2,
            CustomerUserID            => 1
            DynamicField_DropdownTest => 1,
            DynamicField_Anotherone   => 2,
        },
        'DashboardBackend###0100-TicketPendingReminder' => {
            Title                     => 2,
            CustomerUserID            => 1
            DynamicField_DropdownTest => 1,
            DynamicField_Anotherone   => 2,
        },
    );

=cut

sub _DefaultColumnsGet {
    my ( $Self, @ScreenConfig ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    return 1 if !@ScreenConfig;
    my %Configs;

    VIEW:
    for my $View (@ScreenConfig) {

        my $FrontendPath = $View;

        if (
            $View !~ m{(DashboardBackend|AgentCustomerInformationCenter::Backend)}xmsi
            && $View !~ m{(\w+::)+\w+}xmsi
            )
        {
            $FrontendPath = "Ticket::Frontend::$View";
        }

        my @Keys = split '###', $FrontendPath;
        my $Config = $ConfigObject->Get( $Keys[0] );

        # check if config has DefaultColumns attribute and set it
        if ( !$#Keys && $Config->{DefaultColumns} ) {
            push @Keys, 'DefaultColumns';
        }

        INDEX:
        for my $Index ( 1 ... $#Keys ) {
            last INDEX if !IsHashRefWithData($Config);
            $Config = $Config->{ $Keys[$Index] };
        }

        next VIEW if ref $Config ne 'HASH';

        my %ExistingSetting = %{$Config};
        $Configs{$View} ||= {};

        # checks if substructure of DefaultColumns exists in settings
        if ( $ExistingSetting{DefaultColumns} ) {
            $Configs{$View} = $ExistingSetting{DefaultColumns},
        }
        else {
            $Configs{$View} = \%ExistingSetting,
        }
    }

    return %Configs;
}

=item _DefaultColumnsEnable()

This function enables the given Attributes for the requested DefaultColumns.

    my %Configs = (
        'Ticket::Frontend::AgentTicketStatusView###DefaultColumns' => {
            Title                     => 2,
            CustomerUserID            => 1
            DynamicField_DropdownTest => 1,
            DynamicField_Anotherone   => 2,
        },
        'DashboardBackend###0100-TicketPendingReminder' => {
            Title                     => 2,
            CustomerUserID            => 1
            DynamicField_DropdownTest => 1,
            DynamicField_Anotherone   => 2,
        },
        'Ticket::Frontend::AgentTicketQueue###DefaultColumns'           => {},
        'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns' => {},
        'Ticket::Frontend::AgentTicketWatchView###DefaultColumns'       => {},
        'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'      => {},
        'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns'  => {},
        'Ticket::Frontend::AgentTicketSearch###DefaultColumns'          => {},
        'Ticket::Frontend::AgentTicketService###DefaultColumns'         => {},

        'DashboardBackend###0110-TicketEscalation'                                 => {},
        'DashboardBackend###0120-TicketNew'                                        => {},
        'DashboardBackend###0130-TicketOpen'                                       => {},
        'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => {},
        'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation'      => {},
        'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => {},
        'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen'            => {},
    );

    my $Success = $ZnunyHelperObject->_DefaultColumnsEnable(%Configs);

Returns:

    my $Success = 1;

=cut

sub _DefaultColumnsEnable {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

    my %ScreenConfig = %Param;

    VIEW:
    for my $View (%ScreenConfig) {

        next VIEW if !IsHashRefWithData( $ScreenConfig{$View} );

        my $FrontendPath = $View;

        if (
            $View !~ m{(DashboardBackend|AgentCustomerInformationCenter::Backend)}xmsi
            && $View !~ m{(\w+::)+\w+}xmsi
            )
        {
            $FrontendPath = "Ticket::Frontend::$View";
        }

        my @Keys = split '###', $FrontendPath;
        my $Config = $ConfigObject->Get( $Keys[0] );

        # check if config has DefaultColumns attribute and set it
        if ( !$#Keys && $Config->{DefaultColumns} ) {
            push @Keys, 'DefaultColumns';
        }

        INDEX:
        for my $Index ( 1 ... $#Keys ) {
            last INDEX if !IsHashRefWithData($Config);
            $Config = $Config->{ $Keys[$Index] };
        }

        next VIEW if ref $Config ne 'HASH';

        my %ExistingSetting = %{$Config};

        # add the new settings
        my %NewDynamicFieldConfig;

        # checks if DefaultColumns exists in settings (DashboardBackend###0130-TicketOpen)
        if ( $ExistingSetting{DefaultColumns} ) {

            %{ $ExistingSetting{DefaultColumns} } = (
                %{ $ExistingSetting{DefaultColumns} },
                %{ $ScreenConfig{$View} }
            );

            %NewDynamicFieldConfig = %ExistingSetting;
        }
        else {
            %NewDynamicFieldConfig = (
                %ExistingSetting,
                %{ $ScreenConfig{$View} }
            );
        }

        # update the SysConfig
        my $SysConfigKey = join '###', @Keys;
        my $Success = $SysConfigObject->ConfigItemUpdate(
            Key   => $SysConfigKey,
            Value => \%NewDynamicFieldConfig,
            Valid => 1,
        );
    }

    return 1;
}

=item _DefaultColumnsDisable()

This function disables the given Attributes for the requested DefaultColumns.

    my %Configs = (
        'Ticket::Frontend::AgentTicketStatusView###DefaultColumns' => {
            Title                     => 2,
            CustomerUserID            => 1
            DynamicField_DropdownTest => 1,
            DynamicField_Anotherone   => 2,
        },
        'DashboardBackend###0100-TicketPendingReminder' => {
            Title                     => 2,
            CustomerUserID            => 1
            DynamicField_DropdownTest => 1,
            DynamicField_Anotherone   => 2,
        },
        'Ticket::Frontend::AgentTicketQueue###DefaultColumns'           => {},
        'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns' => {},
        'Ticket::Frontend::AgentTicketWatchView###DefaultColumns'       => {},
        'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'      => {},
        'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns'  => {},
        'Ticket::Frontend::AgentTicketSearch###DefaultColumns'          => {},
        'Ticket::Frontend::AgentTicketService###DefaultColumns'         => {},

        'DashboardBackend###0110-TicketEscalation'                                 => {},
        'DashboardBackend###0120-TicketNew'                                        => {},
        'DashboardBackend###0130-TicketOpen'                                       => {},
        'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => {},
        'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation'      => {},
        'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => {},
        'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen'            => {},
    );

    my $Success = $ZnunyHelperObject->_DefaultColumnsDisable(%Configs);

Returns:

    my $Success = 1;

=cut

sub _DefaultColumnsDisable {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

    my %ScreenConfig = %Param;

    VIEW:
    for my $View (%ScreenConfig) {

        next VIEW if !IsHashRefWithData( $ScreenConfig{$View} );

        my $FrontendPath = $View;

        if (
            $View !~ m{(DashboardBackend|AgentCustomerInformationCenter::Backend)}xmsi
            && $View !~ m{(\w+::)+\w+}xmsi
            )
        {
            $FrontendPath = "Ticket::Frontend::$View";
        }

        my @Keys = split '###', $FrontendPath;
        my $Config = $ConfigObject->Get( $Keys[0] );

        # check if config has DefaultColumns attribute and set it
        if ( !$#Keys && $Config->{DefaultColumns} ) {
            push @Keys, 'DefaultColumns';
        }

        INDEX:
        for my $Index ( 1 ... $#Keys ) {
            last INDEX if !IsHashRefWithData($Config);
            $Config = $Config->{ $Keys[$Index] };
        }

        next VIEW if ref $Config ne 'HASH';

        my %ExistingSetting = %{$Config};

        # add the new settings
        my %NewDynamicFieldConfig;
        if ( $ExistingSetting{DefaultColumns} ) {

            %NewDynamicFieldConfig = %ExistingSetting;
            delete $NewDynamicFieldConfig{DefaultColumns};

            SETTING:
            for my $ExistingSettingKey ( sort keys %{ $ExistingSetting{DefaultColumns} } ) {

                next SETTING if $ScreenConfig{$View}->{$ExistingSettingKey};
                $NewDynamicFieldConfig{DefaultColumns}->{$ExistingSettingKey}
                    = $ExistingSetting{DefaultColumns}->{$ExistingSettingKey};
            }
        }
        else {

            SETTING:
            for my $ExistingSettingKey ( sort keys %ExistingSetting ) {

                next SETTING if $ScreenConfig{$View}->{$ExistingSettingKey};
                $NewDynamicFieldConfig{$ExistingSettingKey} = $ExistingSetting{$ExistingSettingKey};
            }
        }

        my $SysConfigKey = join '###', @Keys;
        my $Success = $SysConfigObject->ConfigItemUpdate(
            Key   => $SysConfigKey,
            Value => \%NewDynamicFieldConfig,
            Valid => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsScreenEnable()

This function enables the defined dynamic fields in the needed screens.

    my %Screens = (
        AgentTicketFreeText => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        },
        'CustomerTicketZoom###FollowUpDynamicField' => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        },
        'AgentTicketSearch###Defaults###DynamicField' => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        },
        'ITSMChange::Frontend::AgentITSMChangeEdit###DynamicField' => {
            ChangeFreeText1 => 1,
            ChangeFreeText2 => 1,
            ChangeFreeText3 => 1,
            ChangeFreeText4 => 1,
            ChangeFreeText5 => 1,
        },
        'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit###DynamicField' => {
            WorkOrderFreeText1 => 1,
            WorkOrderFreeText2 => 1,
            WorkOrderFreeText3 => 1,
            WorkOrderFreeText4 => 1,
            WorkOrderFreeText5 => 1,
        },
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsScreenEnable(%Screens);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsScreenEnable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    VIEW:
    for my $View ( sort keys %ScreenDynamicFieldConfig ) {

        next VIEW if !IsHashRefWithData( $ScreenDynamicFieldConfig{$View} );

        # There are special cases for defining the visibility of DynamicFields
        # Ticket::Frontend::AgentTicketSearch###Defaults###DynamicField
        # Ticket::Frontend::CustomerTicketZoom###FollowUpDynamicField
        # Ticket::Frontend::AgentTicketSearch###SearchCSVDynamicField
        #
        # on regular calls $View contains for examlpe "AgentTicketEmail"
        #
        # for the three special cases $View contains:
        # AgentTicketSearch###Defaults###DynamicField
        # CustomerTicketZoom###FollowUpDynamicField
        # AgentTicketSearch###SearchCSVDynamicField
        #
        # or calls for itsm change management for example
        #
        # ITSMChange::Frontend::AgentITSMChangeEdit###DynamicField
        # ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit###DynamicField
        #
        # so split on '###'
        # and put the values in the @Keys array
        #
        # for regular cases we put in the View name on $Keys[0] and 'DynamicField' on $Keys[1]

        my $FrontendPath = "Ticket::Frontend::$View";
        if ( $View =~ m{(\w+::)+\w+}xmsi ) {
            $FrontendPath = $View;
        }
        my @Keys = split '###', $FrontendPath;

        if ( !$#Keys ) {
            push @Keys, 'DynamicField';
        }

        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( $Keys[0] );
        INDEX:
        for my $Index ( 1 ... $#Keys ) {
            last INDEX if !IsHashRefWithData($Config);
            $Config = $Config->{ $Keys[$Index] };
        }
        next VIEW if ref $Config ne 'HASH';
        my %ExistingSetting = %{$Config};

        # add the new settings
        my %NewDynamicFieldConfig = ( %ExistingSetting, %{ $ScreenDynamicFieldConfig{$View} } );

        # update the sysconfig
        my $SysConfigKey = join '###', @Keys;
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Key   => $SysConfigKey,
            Value => \%NewDynamicFieldConfig,
            Valid => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsScreenDisable()

This function disables the defined dynamic fields in the needed screens.

    my %Screens = (
        AgentTicketFreeText => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        },
        'CustomerTicketZoom###FollowUpDynamicField' => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        },
        'AgentTicketSearch###Defaults###DynamicField' => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        },
        'ITSMChange::Frontend::AgentITSMChangeEdit###DynamicField' => {
            ChangeFreeText1 => 1,
            ChangeFreeText2 => 1,
            ChangeFreeText3 => 1,
            ChangeFreeText4 => 1,
            ChangeFreeText5 => 1,
        },
        'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit###DynamicField' => {
            WorkOrderFreeText1 => 1,
            WorkOrderFreeText2 => 1,
            WorkOrderFreeText3 => 1,
            WorkOrderFreeText4 => 1,
            WorkOrderFreeText5 => 1,
        },
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsScreenDisable(%Screens);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsScreenDisable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    VIEW:
    for my $View ( sort keys %ScreenDynamicFieldConfig ) {

        next VIEW if !IsHashRefWithData( $ScreenDynamicFieldConfig{$View} );

        # There are special cases for defining the visibility of DynamicFields
        # Ticket::Frontend::AgentTicketSearch###Defaults###DynamicField
        # Ticket::Frontend::CustomerTicketZoom###FollowUpDynamicField
        # Ticket::Frontend::AgentTicketSearch###SearchCSVDynamicField
        #
        # on regular calls $View contains for examlpe "AgentTicketEmail"
        #
        # for the three special cases $View contains:
        # AgentTicketSearch###Defaults###DynamicField
        # CustomerTicketZoom###FollowUpDynamicField
        # AgentTicketSearch###SearchCSVDynamicField
        #
        # or calls for itsm change management for example
        #
        # ITSMChange::Frontend::AgentITSMChangeEdit###DynamicField
        # ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit###DynamicField
        #
        # so split on '###'
        # and put the values in the @Keys array
        #
        # for regular cases we put in the View name on $Keys[0] and 'DynamicField' on $Keys[1]

        my $FrontendPath = "Ticket::Frontend::$View";
        if ( $View =~ m{(\w+::)+\w+}xmsi ) {
            $FrontendPath = $View;
        }
        my @Keys = split '###', $FrontendPath;

        if ( !$#Keys ) {
            push @Keys, 'DynamicField';
        }

        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( $Keys[0] );
        INDEX:
        for my $Index ( 1 ... $#Keys ) {
            last INDEX if !IsHashRefWithData($Config);
            $Config = $Config->{ $Keys[$Index] };
        }
        next VIEW if ref $Config ne 'HASH';
        my %ExistingSetting = %{$Config};

        my %NewDynamicFieldConfig;
        SETTING:
        for my $ExistingSettingKey ( sort keys %ExistingSetting ) {

            next SETTING if $ScreenDynamicFieldConfig{$View}->{$ExistingSettingKey};

            $NewDynamicFieldConfig{$ExistingSettingKey} = $ExistingSetting{$ExistingSettingKey};
        }

        my $SysConfigKey = join '###', @Keys;
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Key   => $SysConfigKey,
            Value => \%NewDynamicFieldConfig,
            Valid => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsDelete()

This function delete the defined dynamic fields

    my @DynamicFields = (
        'TestDynamicField1',
        'TestDynamicField2',
        'TestDynamicField3',
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsDelete(@DynamicFields);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsDelete {
    my ( $Self, @DynamicFields ) = @_;

    return 1 if !@DynamicFields;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    return 1 if !IsArrayRefWithData($DynamicFieldList);

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # delete the dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldName (@DynamicFields) {

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicFieldLookup{$DynamicFieldName} );

        my $ValuesDeleteSuccess = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->AllValuesDelete(
            DynamicFieldConfig => $DynamicFieldLookup{$DynamicFieldName},
            UserID             => 1,
        );

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldDelete(
            %{ $DynamicFieldLookup{$DynamicFieldName} },
            Reorder => 0,
            UserID  => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsDisable()

This function disables the defined dynamic fields

    my @DynamicFields = (
        'TestDynamicField1',
        'TestDynamicField2',
        'TestDynamicField3',
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsDisable(@DynamicFields);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsDisable {
    my ( $Self, @DynamicFields ) = @_;

    return 1 if !@DynamicFields;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    return 1 if !IsArrayRefWithData($DynamicFieldList);

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'invalid',
    );

    # disable the dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldName (@DynamicFields) {

        next DYNAMICFIELD if !$DynamicFieldLookup{$DynamicFieldName};

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldUpdate(
            %{ $DynamicFieldLookup{$DynamicFieldName} },
            ValidID => $InvalidID,
            Reorder => 0,
            UserID  => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsCreateIfNotExists()

creates all dynamic fields that are necessary

Usable Snippets (SublimeTextAdjustments):
    otrs.dynamicfield.config.text
    otrs.dynamicfield.config.checkbox
    otrs.dynamicfield.config.datetime
    otrs.dynamicfield.config.dropdown
    otrs.dynamicfield.config.textarea
    otrs.dynamicfield.config.multiselect

    my @DynamicFields = (
        {
            Name       => 'TestDynamicField1',
            Label      => "TestDynamicField1",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
        {
            Name       => 'TestDynamicField2',
            Label      => "TestDynamicField2",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
    );

    my $Result = $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists( @DynamicFields );

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsCreateIfNotExists {
    my ( $Self, @Definition ) = @_;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    if ( !IsArrayRefWithData($DynamicFieldList) ) {
        $DynamicFieldList = [];
    }

    my @DynamicFieldExistsNot;
    DYNAMICFIELD:
    for my $NewDynamicField (@Definition) {

        next DYNAMICFIELD if !IsHashRefWithData($NewDynamicField);

        next DYNAMICFIELD if grep { $NewDynamicField->{Name} eq $_->{Name} } @{$DynamicFieldList};

        push @DynamicFieldExistsNot, $NewDynamicField;
    }

    return 1 if !@DynamicFieldExistsNot;

    return $Self->_DynamicFieldsCreate(@DynamicFieldExistsNot);
}

=item _DynamicFieldsCreate()

creates all dynamic fields that are necessary

Usable Snippets (SublimeTextAdjustments):
    otrs.dynamicfield.config.text
    otrs.dynamicfield.config.checkbox
    otrs.dynamicfield.config.datetime
    otrs.dynamicfield.config.dropdown
    otrs.dynamicfield.config.textarea
    otrs.dynamicfield.config.multiselect

    my @DynamicFields = (
        {
            Name       => 'TestDynamicField1',
            Label      => "TestDynamicField1",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
        {
            Name       => 'TestDynamicField2',
            Label      => "TestDynamicField2",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsCreate( @DynamicFields );

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsCreate {
    my ( $Self, @DynamicFields ) = @_;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    # get all current dynamic fields
    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid => 0,
    );

    if ( !IsArrayRefWithData($DynamicFieldList) ) {
        $DynamicFieldList = [];
    }

    # get the last element from the order list and add 1
    my $NextOrderNumber = 1;
    if (
        IsArrayRefWithData($DynamicFieldList)
        && IsHashRefWithData( $DynamicFieldList->[-1] )
        && $DynamicFieldList->[-1]->{FieldOrder}
        )
    {
        $NextOrderNumber = $DynamicFieldList->[-1]->{FieldOrder} + 1;
    }

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # create or update dynamic fields
    DYNAMICFIELD:
    for my $NewDynamicField (@DynamicFields) {

        my $CreateDynamicField;

        # check if the dynamic field already exists
        if ( !IsHashRefWithData( $DynamicFieldLookup{ $NewDynamicField->{Name} } ) ) {
            $CreateDynamicField = 1;
        }

        # if the field exists check if the type match with the needed type
        elsif (
            $DynamicFieldLookup{ $NewDynamicField->{Name} }->{FieldType}
            ne $NewDynamicField->{FieldType}
            )
        {
            my %OldDynamicFieldConfig = %{ $DynamicFieldLookup{ $NewDynamicField->{Name} } };

            # rename the field and create a new one
            my $Success = $DynamicFieldObject->DynamicFieldUpdate(
                %OldDynamicFieldConfig,
                Name   => $OldDynamicFieldConfig{Name} . 'Old',
                UserID => 1,
            );

            $CreateDynamicField = 1;
        }

        # otherwise if the field exists and the type matches, update it as defined
        else {
            my %OldDynamicFieldConfig = %{ $DynamicFieldLookup{ $NewDynamicField->{Name} } };

            my $Success = $DynamicFieldObject->DynamicFieldUpdate(
                %{$NewDynamicField},
                ID         => $OldDynamicFieldConfig{ID},
                FieldOrder => $OldDynamicFieldConfig{FieldOrder},
                ValidID    => $NewDynamicField->{ValidID} || $ValidID,
                Reorder    => 0,
                UserID     => 1,
            );
        }

        # check if new field has to be created
        next DYNAMICFIELD if !$CreateDynamicField;

        # create a new field
        my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
            Name       => $NewDynamicField->{Name},
            Label      => $NewDynamicField->{Label},
            FieldOrder => $NextOrderNumber,
            FieldType  => $NewDynamicField->{FieldType},
            ObjectType => $NewDynamicField->{ObjectType},
            Config     => $NewDynamicField->{Config},
            ValidID    => $NewDynamicField->{ValidID} || $ValidID,
            UserID     => 1,
        );
        next DYNAMICFIELD if !$FieldID;

        # increase the order number
        $NextOrderNumber++;
    }

    return 1;
}

=item _GroupCreateIfNotExists()

creates group if not exists

    my $Success = $ZnunyHelperObject->_GroupCreateIfNotExists(
        Name => 'Some Group Name',
    );

Returns:

    my $Success = 1;

=cut

sub _GroupCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %GroupsReversed = $Kernel::OM->Get('Kernel::System::Group')->GroupList(
        Valid => 0,
    );
    %GroupsReversed = reverse %GroupsReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %GroupsReversed );
    return $ItemID if $ItemID;

    return $Kernel::OM->Get('Kernel::System::Group')->GroupAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _RoleCreateIfNotExists()

creates role if not exists

    my $Success = $ZnunyHelperObject->_RoleCreateIfNotExists(
        Name => 'Some Role Name',
    );

Returns:

    my $Success = 1;

=cut

sub _RoleCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %RolesReversed = $Kernel::OM->Get('Kernel::System::Group')->RoleList(
        Valid => 0,
    );
    %RolesReversed = reverse %RolesReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %RolesReversed );
    return $ItemID if $ItemID;

    return $Kernel::OM->Get('Kernel::System::Group')->RoleAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _TypeCreateIfNotExists()

creates Type if not exists

    my $Success = $ZnunyHelperObject->_TypeCreateIfNotExists(
        Name => 'Some Type Name',
    );

Returns:

    my $Success = 1;

=cut

sub _TypeCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %TypesReversed = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
        Valid => 0,
    );
    %TypesReversed = reverse %TypesReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %TypesReversed );
    return $ItemID if $ItemID;

    return $Kernel::OM->Get('Kernel::System::Type')->TypeAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _PriorityCreateIfNotExists()

creates Priority if not exists

    my $Success = $ZnunyHelperObject->_PriorityCreateIfNotExists(
        Name => 'Some Priority Name',
    );

Returns:

    my $Success = 1;

=cut

sub _PriorityCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %PrioritysReversed = $Kernel::OM->Get('Kernel::System::Priority')->PriorityList(
        Valid => 0,
    );
    %PrioritysReversed = reverse %PrioritysReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %PrioritysReversed );
    return $ItemID if $ItemID;

    return $Kernel::OM->Get('Kernel::System::Priority')->PriorityAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _StateCreateIfNotExists()

creates State if not exists

    my $Success = $ZnunyHelperObject->_StateCreateIfNotExists(
        Name => 'Some State Name',
        # e.g. new|open|closed|pending reminder|pending auto|removed|merged
        TypeID => $StateObject->StateTypeLookup( StateType => 'pending auto' ),
    );

Returns:

    my $Success = 1;

=cut

sub _StateCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %StatesReversed = $Kernel::OM->Get('Kernel::System::State')->StateList(
        Valid  => 0,
        UserID => 1
    );
    %StatesReversed = reverse %StatesReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %StatesReversed );
    return $ItemID if $ItemID;

    return $Kernel::OM->Get('Kernel::System::State')->StateAdd(
        %Param,
        ValidID => 1,
        UserID  => 1,
    );
}

=item _StateDisable()

disables a given state

    my @States = (
        'State1',
        'State2',
    );

    my $Success = $ZnunyHelperObject->_StateDisable(@States);

Returns:

    my $Success = 1;

=cut

sub _StateDisable {
    my ( $Self, @States ) = @_;

    return 1 if !@States;

    #get current invalid id
    my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'invalid',
    );

    my $Success = 1;

    # disable the states
    STATE:
    for my $StateName (@States) {

        my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet(
            Name => $StateName,
        );
        next STATE if !%State;

        my $UpdateSuccess = $Kernel::OM->Get('Kernel::System::State')->StateUpdate(
            %State,
            ValidID => $InvalidID,
            UserID  => 1,
        );

        if ( !$UpdateSuccess ) {
            $Success = 0;
        }
    }

    return $Success;
}

=item _StateTypeCreateIfNotExists()

creates statetypes if not exists

    my $StateTypeID = $ZnunyHelperObject->_StateTypeCreateIfNotExists(
        Name    => 'New StateType',
        Comment => 'some comment',
        UserID  => 123,
    );

=cut

sub _StateTypeCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if exists
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => 'SELECT name FROM ticket_state_type WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Exists = 1;
    }
    return 1 if $Exists;

    # create new
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO ticket_state_type (name, comments,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name},   \$Param{Comment},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new statetype id
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => 'SELECT id FROM ticket_state_type WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return if !$ID;

    return $ID;

}

=item _ServiceCreateIfNotExists()

creates Service if not exists

    my $Success = $ZnunyHelperObject->_ServiceCreateIfNotExists(
        Name => 'Some ServiceName',
        %ITSMParams,                        # optional params for Criticality or TypeID if ITSM is installed
    );

Returns:

    my $Success = 1;

=cut

sub _ServiceCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Name = $Param{Name};

    # ITSMParams
    $Param{TypeID}      ||= '2';
    $Param{Criticality} ||= '3 normal';

    my %ServiceReversed = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
        Valid  => 0,
        UserID => 1
    );
    %ServiceReversed = reverse %ServiceReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Name, %ServiceReversed );
    return $ItemID if $ItemID;

    # split string to check for possible sub services
    my @ServiceArray = split( '::', $Name );

    # create service with parent
    my $CompleteServiceName = '';
    my $ServiceID;

    SERVICE:
    for my $ServiceName (@ServiceArray) {

        my $ParentID;
        if ($CompleteServiceName) {

            $ParentID = $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
                Name   => $CompleteServiceName,
                UserID => 1,
            );

            if ( !$ParentID ) {

                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Error while getting ServiceID for parent service "
                        . "'$CompleteServiceName' for new service '" . $Name . "'.",
                );
                return;
            }

            $CompleteServiceName .= '::';
        }

        $CompleteServiceName .= $ServiceName;

        my $ItemID = $Self->_ItemReverseListGet( $CompleteServiceName, %ServiceReversed );
        if ($ItemID) {
            $ServiceID = $ItemID;
            next SERVICE;
        }

        $ServiceID = $Kernel::OM->Get('Kernel::System::Service')->ServiceAdd(
            %Param,
            Name     => $ServiceName,
            ParentID => $ParentID,
            ValidID  => 1,
            UserID   => 1,
        );

        if ( !$ServiceID ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while adding new service '$ServiceName' ($ParentID).",
            );
            return;
        }

        %ServiceReversed = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
            Valid  => 0,
            UserID => 1
        );
        %ServiceReversed = reverse %ServiceReversed;
    }

    return $ServiceID;
}

=item _SLACreateIfNotExists()

creates SLA if not exists

    my $Success = $ZnunyHelperObject->_SLACreateIfNotExists(
        Name => 'Some ServiceName',
        ServiceIDs          => [ 1, 5, 7 ],  # (optional)
        FirstResponseTime   => 120,          # (optional)
        FirstResponseNotify => 60,           # (optional) notify agent if first response escalation is 60% reached
        UpdateTime          => 180,          # (optional)
        UpdateNotify        => 80,           # (optional) notify agent if update escalation is 80% reached
        SolutionTime        => 580,          # (optional)
        SolutionNotify      => 80,           # (optional) notify agent if solution escalation is 80% reached
    );

Returns:

    my $Success = 1;

=cut

sub _SLACreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # ITSMParams
    $Param{TypeID}      ||= '2';
    $Param{Criticality} ||= '3 normal';

    my %SLAReversed = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
        UserID => 1
    );
    %SLAReversed = reverse %SLAReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %SLAReversed );
    return $ItemID if $ItemID;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );
    my $SLAID = $Kernel::OM->Get('Kernel::System::SLA')->SLAAdd(
        %Param,
        ValidID => $ValidID,
        UserID  => 1,
    );

    return $SLAID;
}

=item _UserCreateIfNotExists()

creates user if not exists

    my $UserID = $ZnunyHelperObject->_UserCreateIfNotExists(
        UserFirstname => 'Huber',
        UserLastname  => 'Manfred',
        UserLogin     => 'mhuber',
        UserPw        => 'some-pass', # not required
        UserEmail     => 'email@example.com',
        UserMobile    => '1234567890', # not required
        ValidID       => 1,
        ChangeUserID  => 123,
    );

Returns:

    my $User = 123;

=cut

sub _UserCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(UserLogin)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %UserListReversed = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type   => 'Short',
        UserID => 1,
    );
    %UserListReversed = reverse %UserListReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{UserLogin}, %UserListReversed );
    return $ItemID if $ItemID;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );
    my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserAdd(
        %Param,
        ValidID => $ValidID,
        UserID  => 1,
    );

    return $UserID;
}

=item _CustomerUserCreateIfNotExists()

creates CustomerUser if not exists

    my $CustomerUserLogin = $ZnunyHelperObject->_CustomerUserCreateIfNotExists(
        Source         => 'CustomerUser', # CustomerUser source config
        UserFirstname  => 'Huber',
        UserLastname   => 'Manfred',
        UserCustomerID => 'A124',
        UserLogin      => 'mhuber',
        UserPassword   => 'some-pass', # not required
        UserEmail      => 'email@example.com',
    );

Returns:

    my $CustomerUserLogin = 'mhuber';

=cut

sub _CustomerUserCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(UserLogin)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %CustomerUserReversedValid = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerSearch(
        UserLogin => $Param{UserLogin},
        Valid     => 1,
    );
    my %CustomerUserReversedInValid = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerSearch(
        UserLogin => $Param{UserLogin},
        Valid     => 0,
    );
    my %CustomerUserReversed = (
        %CustomerUserReversedValid,
        %CustomerUserReversedInValid,
    );

    # shitty solution for the check.
    # somebody should fix this and use the CustomerKey instead for the check.
    my $ItemID = $Self->_ItemReverseListGet( $Param{UserLogin}, %CustomerUserReversed );
    return $Param{UserLogin} if $ItemID;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );
    my $CustomerUserID = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
        %Param,
        ValidID => $ValidID,
        UserID  => 1,
    );

    return $CustomerUserID;
}

=item _QueueCreateIfNotExists()

creates Queue if not exists

    my $QueueID = $ZnunyHelperObject->_QueueCreateIfNotExists(
        Name    => 'Some Queue Name',
        GroupID => 1,
    );

Returns:

    my $QueueID = 123;

=cut

sub _QueueCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name GroupID)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Name = $Param{Name};

    my %QueueReversed = $Kernel::OM->Get('Kernel::System::Queue')->QueueList(
        UserID => 1
    );
    %QueueReversed = reverse %QueueReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Name, %QueueReversed );
    return $ItemID if $ItemID;

    # split string to check for possible sub Queues
    my @QueueArray = split( '::', $Name );

    # create Queue with parent
    my $CompleteQueueName = '';
    my $QueueID;

    QUEUE:
    for my $QueueName (@QueueArray) {

        if ($CompleteQueueName) {
            $CompleteQueueName .= '::';
        }

        $CompleteQueueName .= $QueueName;

        my $ItemID = $Self->_ItemReverseListGet( $CompleteQueueName, %QueueReversed );
        if ($ItemID) {
            $QueueID = $ItemID;
            next QUEUE;
        }

        $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
            %Param,
            Name          => $CompleteQueueName,
            ParentQueueID => $QueueID,
            ValidID       => 1,
            UserID        => 1,
        );

        if ( !$QueueID ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while adding new Queue '$QueueName' ($QueueID).",
            );
            return;
        }

        %QueueReversed = $Kernel::OM->Get('Kernel::System::Queue')->QueueList(
            UserID => 1,
        );
        %QueueReversed = reverse %QueueReversed;
    }

    return $QueueID;
}

=item _GeneralCatalogItemCreateIfNotExists()

adds a general catalog item if it does not exist

    my $ItemID = $ZnunyHelperObject->_GeneralCatalogItemCreateIfNotExists(
        Name    => 'Test Item',
        Class   => 'ITSM::ConfigItem::Test',
        Comment => 'Class for test item.',
    );

Returns:

    my $ItemID = 1234;

=cut

sub _GeneralCatalogItemCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name Class)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $MainObject  = $Kernel::OM->Get('Kernel::System::Main');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $Name        = $Param{Name};

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $MainObject->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    my $ValidID = $ValidObject->ValidLookup(
        Valid => 'valid',
    );

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # check if item already exists
    my $ItemListRef = $GeneralCatalogObject->ItemList(
        Class => $Param{Class},
        Valid => $ValidID,
    );

    my %ItemListReverse = reverse %{ $ItemListRef || {} };

    my $ItemID = $Self->_ItemReverseListGet( $Name, %ItemListReverse );
    return $ItemID if $ItemID;

    # add item if it does not exist
    $ItemID = $GeneralCatalogObject->ItemAdd(
        Class   => $Param{Class},
        Name    => $Name,
        ValidID => $ValidID,
        Comment => $Param{Comment},
        UserID  => 1,
    );

    return $ItemID;
}

=item _NotificationEventCreate()

create or update notification event

    my @NotificationList = (
        {
            Name => 'Agent::CustomerVIPPriorityUpdate',
            Data => {
                Events => [
                    'TicketPriorityUpdate',
                ],
                ArticleAttachmentInclude => [
                    '0'
                ],
                LanguageID => [
                    'en',
                    'de'
                ],
                NotificationArticleTypeID => [
                    1,
                ],
                Recipients => [
                    'Customer',
                ],
                TransportEmailTemplate => [
                    'Default',
                ],
                Transports => [
                    'Email',
                ],
                VisibleForAgent => [
                    '0',
                ],
            },
            Message => {
                en => {
                    Subject     => 'Priority for your ticket changed',
                    ContentType => 'text/html',
                    Body        => '...',
                },
                de => {
                    Subject     => 'Die Prioritaet Ihres Tickets wurde geaendert',
                    ContentType => 'text/html',
                    Body        => '...',
                },
            },
        },
        # ...
    );

    my $Success = $ZnunyHelperObject->_NotificationEventCreate( @NotificationList );

Returns:

    my $Success = 1;

=cut

sub _NotificationEventCreate {
    my ( $Self, @NotificationEvents ) = @_;

    my $Success = 1;

    NOTIFICATIONEVENT:
    for my $NotificationEvent (@NotificationEvents) {
        next NOTIFICATIONEVENT if !IsHashRefWithData($NotificationEvent);

        # check needed stuff
        NEEDED:
        for my $Needed (qw(Name)) {

            next NEEDED if defined $NotificationEvent->{$Needed};

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Parameter '$Needed' is needed!",
            );
            return;
        }

        my %NotificationEventReversed = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationList(
            UserID => 1
        );
        %NotificationEventReversed = reverse %NotificationEventReversed;

        my $ItemID = $Self->_ItemReverseListGet( $NotificationEvent->{Name}, %NotificationEventReversed );
        my $ValidID = $NotificationEvent->{ValidID} // $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
            Valid => 'valid',
        );

        if ($ItemID) {
            my $UpdateSuccess = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationUpdate(
                %{$NotificationEvent},
                ID      => $ItemID,
                ValidID => $ValidID,
                UserID  => 1,
            );

            if ( !$UpdateSuccess ) {
                $Success = 0;
            }
        }
        else {
            my $CreateID = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationAdd(
                %{$NotificationEvent},
                ValidID => $ValidID,
                UserID  => 1,
            );

            if ( !$CreateID ) {
                $Success = 0;
            }
        }
    }

    return $Success;
}

=item _NotificationEventCreateIfNotExists()

creates notification event if not exists

    my $NotificationID = $ZnunyHelperObject->_NotificationEventCreateIfNotExists(
        Name => 'Agent::CustomerVIPPriorityUpdate',
        Data => {
            Events => [
                'TicketPriorityUpdate',
            ],
            ArticleAttachmentInclude => [
                '0'
            ],
            LanguageID => [
                'en',
                'de'
            ],
            NotificationArticleTypeID => [
                1,
            ],
            Recipients => [
                'Customer',
            ],
            TransportEmailTemplate => [
                'Default',
            ],
            Transports => [
                'Email',
            ],
            VisibleForAgent => [
                '0',
            ],
        },
        Message => {
            en => {
                Subject     => 'Priority for your ticket changed',
                ContentType => 'text/html',
                Body        => '...',
            },
            de => {
                Subject     => 'Die Prioritaet Ihres Tickets wurde geaendert',
                ContentType => 'text/html',
                Body        => '...',
            },
        },
    );

Returns:

    my $NotificationID = 123;

=cut

sub _NotificationEventCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %NotificationEventReversed = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationList(
        UserID => 1
    );
    %NotificationEventReversed = reverse %NotificationEventReversed;

    my $ItemID = $Self->_ItemReverseListGet( $Param{Name}, %NotificationEventReversed );
    return $ItemID if $ItemID;

    my $ValidID = $Param{ValidID} // $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );
    my $NotificationEventID = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationAdd(
        %Param,
        ValidID => $ValidID,
        UserID  => 1,
    );

    return $NotificationEventID;
}

=item _ITSMVersionAdd()

adds or updates a config item version.

    my $VersionID = $ZnunyHelperObject->_ITSMVersionAdd(
        ConfigItemID  => 12345,
        Name          => 'example name',

        ClassID       => 1234,
        ClassName     => 'example class',
        DefinitionID  => 1234,

        DeplStateID   => 1234,
        DeplStateName => 'Production',

        InciStateID   => 1234,
        InciStateName => 'Operational',

        XMLData => {
            'Priority'    => 'high',
            'Product'     => 'test',
            'Description' => 'test'
        },
        XMLDataMultiple => 1, # default: 0, This option will save a more complex XMLData structure with multiple element data! Makes sense if you are using CountMin, CountMax etc..
    );

Returns:

    my $VersionID = 1234;

=cut

sub _ITSMVersionAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(ConfigItemID Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( !$Param{DeplStateID} && !$Param{DeplStateName} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'DeplStateID' or 'DeplStateName' needed!",
        );
        return;
    }
    if ( !$Param{InciStateID} && !$Param{InciStateName} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'DeplStateID' or 'DeplStateName' needed!",
        );
        return;
    }
    if ( $Param{XMLData} && !IsHashRefWithData( $Param{XMLData} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'XMLData' as hash ref needed!",
        );
        return;
    }

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    # check if general catalog module is installed
    my $ITSMConfigItemLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::ITSMConfigItem',
        Silent => 1,
    );

    return if !$ITSMConfigItemLoaded;

    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');

    my $ConfigItemID = $Param{ConfigItemID};
    my %ConfigItem = %{ $Param{XMLData} || {} };

    my %Version = $Self->_ITSMVersionGet(
        ConfigItemID => $ConfigItemID,
    );

    # get deployment state list
    my %DeplStateList = %{
        $GeneralCatalogObject->ItemList(
            Class => 'ITSM::ConfigItem::DeploymentState',
            )
            || {}
    };
    my %DeplStateListReverse = reverse %DeplStateList;

    my %InciStateList = %{
        $GeneralCatalogObject->ItemList(
            Class => 'ITSM::Core::IncidentState',
            )
            || {}
    };
    my %InciStateListReverse = reverse %InciStateList;

    # get definition
    my $DefinitionID = $Param{DefinitionID};
    if ( !$DefinitionID ) {

        # get class id or name
        my $ClassID = $Param{ClassID};
        if ( $Param{ClassName} ) {

            # get valid id
            my $ValidID = $ValidObject->ValidLookup(
                Valid => 'valid',
            );

            my $ItemListRef = $GeneralCatalogObject->ItemList(
                Class => 'ITSM::ConfigItem::Class',
                Valid => $ValidID,
            );

            my %ItemList = reverse %{ $ItemListRef || {} };

            $ClassID = $ItemList{ $Param{ClassName} };
        }

        my $XMLDefinition = $ConfigItemObject->DefinitionGet(
            ClassID => $ClassID,
        );

        $DefinitionID = $XMLDefinition->{DefinitionID};
    }

    if ( $Param{Name} ) {
        $Version{Name} = $Param{Name};
    }
    if ( $Param{DefinitionID} || $Param{ClassID} || $Param{ClassName} ) {
        $Version{DefinitionID} = $DefinitionID;
    }
    if ( $Param{DeplStateID} ) {
        $Version{DeplStateID} = $Param{DeplStateID};
    }
    if ( $Param{InciStateID} ) {
        $Version{InciStateID} = $Param{InciStateID};
    }
    if ( $Param{DeplStateName} ) {
        $Version{DeplStateID} = $DeplStateListReverse{ $Param{DeplStateName} };
    }
    if ( $Param{InciStateName} ) {
        $Version{InciStateID} = $InciStateListReverse{ $Param{InciStateName} };
    }

    %ConfigItem = ( %{ $Version{XMLData} || {} }, %ConfigItem );

    my $XMLData = [
        undef,
        {
            'Version' => [
                undef,
                {},
            ],
        },
    ];
    $Self->_ParseData2XML(
        %Param,
        Result => $XMLData->[1]->{Version}->[-1],
        Data   => \%ConfigItem,
    );

    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ConfigItemID,
        Name         => $Version{Name},
        DefinitionID => $Version{DefinitionID},
        DeplStateID  => $Version{DeplStateID},
        InciStateID  => $Version{InciStateID},
        XMLData      => $XMLData,
        UserID       => 1,
    );

    return $VersionID;
}

=item _ITSMVersionExists()

checks if a version already exists without returning a error.


    my $Found = $ZnunyHelperObject->_ITSMVersionExists(
        VersionID  => 123,
    );

    or

    my $Found = $ZnunyHelperObject->_ITSMVersionExists(
        ConfigItemID => 123,
    );


Returns:

    my $Found = 1;

=cut

sub _ITSMVersionExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{VersionID} && !$Param{ConfigItemID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need VersionID or ConfigItemID!',
        );
        return;
    }

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    # check if general catalog module is installed
    my $ITSMConfigItemLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::ITSMConfigItem',
        Silent => 1,
    );

    return if !$ITSMConfigItemLoaded;

    if ( $Param{VersionID} ) {

        # get version
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => 'SELECT 1 FROM configitem_version WHERE id = ?',
            Bind  => [ \$Param{VersionID} ],
            Limit => 1,
        );
    }
    else {

        # get version
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => 'SELECT 1 FROM configitem_version WHERE configitem_id = ? ORDER BY id DESC',
            Bind  => [ \$Param{ConfigItemID} ],
            Limit => 1,
        );
    }

    # fetch the result
    my $Found;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Found = 1;
    }

    return $Found;
}

=item _ITSMVersionGet()

get a config item version.

    my %Version = $ZnunyHelperObject->_ITSMVersionGet(
        ConfigItemID    => 12345,
        XMLDataMultiple => 1,      # default: 0, This option will return a more complex XMLData structure with multiple element data! Makes sense if you are using CountMin, CountMax etc..
    );

Returns:

    my %Version = (
        ConfigItemID  => 12345,

        DefinitionID => 1234,
        DeplStateID  => 1234,
        DeplState    => 'Production',
        InciStateID  => 1234,
        InciState    => 'Operational',
        Name         => 'example name',
        XMLData      => {
            'Priority'    => 'high',
            'Product'     => 'test',
            'Description' => 'test'
        },
    );

=cut

sub _ITSMVersionGet {
    my ( $Self, %Param ) = @_;

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    # check if general catalog module is installed
    my $ITSMConfigItemLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::ITSMConfigItem',
        Silent => 1,
    );

    return if !$ITSMConfigItemLoaded;

    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    return if !$Self->_ITSMVersionExists(%Param);

    my $VersionRef = $ConfigItemObject->VersionGet(
        %Param,
        XMLDataGet => 1,
    );

    return if !IsHashRefWithData($VersionRef);

    my %VersionConfigItem;
    $VersionConfigItem{XMLData} ||= {};
    if ( IsHashRefWithData( $VersionRef->{XMLData}->[1]->{Version}->[1] ) ) {
        $Self->_ParseXML2Data(
            %Param,
            Result => $VersionConfigItem{XMLData},
            Data   => $VersionRef->{XMLData}->[1]->{Version}->[1],
        );
    }

    for my $Field (qw(ConfigItemID Name ClassID Class DefinitionID DeplStateID DeplState InciStateID InciState)) {
        $VersionConfigItem{$Field} = $VersionRef->{$Field};
    }

    return %VersionConfigItem;
}

=item _ParseXML2Data()

this is a internal function for _ITSMVersionGet to parse the additional data
stored in XMLData.

    my $Success = $ZnunyHelperObject->_ParseXML2Data(
        Parent          => $Identifier,          # optional: contains the field name of the parent xml
        Result          => $Result,              # contains the reference to the result hash
        Data            => $Data{$Field}->[1],   # contains the xml hash we want to parse
        XMLDataMultiple => 1,                    # default: 0, This option will return a more complex XMLData structure with multiple element data! Makes sense if you are using CountMin, CountMax etc..
    );

Returns:

    my $Success = 1;

=cut

sub _ParseXML2Data {
    my ( $Self, %Param ) = @_;

    my $Result          = $Param{Result};
    my $XMLDataMultiple = $Param{XMLDataMultiple};
    my $Parent          = $Param{Parent} || '';
    my %Data            = %{ $Param{Data} || {} };

    FIELD:
    for my $Field ( sort keys %Data ) {
        next FIELD if !IsArrayRefWithData( $Data{$Field} );

        if ($XMLDataMultiple) {
            $Result->{$Field} = [];

            for my $Index ( 1 .. $#{ $Data{$Field} } ) {
                my $Value = $Data{$Field}->[$Index]->{Content};

                my $CurrentResult = {};

                $Self->_ParseXML2Data(
                    %Param,
                    Parent => $Field,
                    Result => $CurrentResult,
                    Data   => $Data{$Field}->[$Index],
                );

                if ( defined $Value ) {
                    $CurrentResult->{Content} = $Value;

                    if ( keys %{$CurrentResult} ) {
                        push @{ $Result->{$Field} }, $CurrentResult;
                    }
                }
            }
        }
        else {
            my $Value = $Data{$Field}->[1]->{Content};

            next FIELD if !defined $Value;

            $Result->{$Field} = $Value;
        }
    }

    return 1;
}

=item _ParseData2XML()

this is a internal function for _ITSMVersionAdd to parse the additional data
for xml storage.

    my $Success = $ZnunyHelperObject->_ParseData2XML(
        Parent          => $Identifier,          # optional: contains the field name of the parent xml
        Result          => $Result,              # contains the reference to the result hash
        Data            => $Data{$Field}->[1],   # contains the xml hash we want to parse
        XMLDataMultiple => 1,                    # default: 0, This option will return a more complex XMLData structure with multiple element data! Makes sense if you are using CountMin, CountMax etc..
    );

Returns:

    my $Success = 1;

=cut

sub _ParseData2XML {
    my ( $Self, %Param ) = @_;

    my $XMLDataMultiple = $Param{XMLDataMultiple};
    my $Result          = $Param{Result};
    my $Parent          = $Param{Parent} || '';
    my %Data            = %{ $Param{Data} || {} };

    ITEM:
    for my $ItemID ( sort keys %Data ) {
        next ITEM if $ItemID eq $Parent;

        my $Item = $Data{$ItemID};

        if ( IsArrayRefWithData($Item) ) {

            $Result->{$ItemID} = [undef];

            for my $Index ( 0 .. $#{$Item} ) {
                my $ItemData = $Item->[$Index];

                push @{ $Result->{$ItemID} }, {
                    'Content' => $Item->[$Index]->{Content},
                };

                $Self->_ParseData2XML(
                    %Param,
                    Parent => $ItemID,
                    Result => $Result->{$ItemID}->[-1],
                    Data   => $Data{$ItemID}->[$Index],
                );
            }
        }
        elsif ( !$XMLDataMultiple ) {
            $Result->{$ItemID} = [
                undef,
                {
                    'Content' => $Item,
                }
            ];
        }
    }

    return 1;
}

=item _WebserviceCreateIfNotExists()

creates webservices that not exist yet

    # installs all .yml files in $OTRS/scripts/webservices/
    # name of the file will be the name of the webservice
    my $Result = $ZnunyHelperObject->_WebserviceCreateIfNotExists(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

OR:

    my $Result = $ZnunyHelperObject->_WebserviceCreateIfNotExists(
        Webservices => {
            'New Webservice 1234' => '/path/to/Webservice.yml',
            ...
        }
    );

=cut

sub _WebserviceCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    my $Webservices = $Param{Webservices};
    if ( !IsHashRefWithData($Webservices) ) {
        $Webservices = $Self->_WebservicesGet(
            SubDir => $Param{SubDir},
        );
    }

    return 1 if !IsHashRefWithData($Webservices);

    my $WebserviceList = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    if ( ref $WebserviceList ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Error while getting list of Webservices!"
        );
        return;
    }

    WEBSERVICE:
    for my $WebserviceName ( sort keys %{$Webservices} ) {

        # stop if already added
        next WEBSERVICE if grep { $WebserviceName eq $_ } sort values %{$WebserviceList};

        my $WebserviceYAMLPath = $Webservices->{$WebserviceName};

        # read config
        my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $WebserviceYAMLPath,
        );

        if ( !$Content ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't read $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => ${$Content} );

        if ( !$Config ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while loading $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        # add webservice to the system
        my $WebserviceID = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceAdd(
            Name    => $WebserviceName,
            Config  => $Config,
            ValidID => 1,
            UserID  => 1,
        );

        if ( !$WebserviceID ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while adding Webservice '$WebserviceName' from $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }
    }

    return 1;
}

=item _WebserviceCreate()

creates or updates webservices

    # installs all .yml files in $OTRS/scripts/webservices/
    # name of the file will be the name of the webservice
    my $Result = $ZnunyHelperObject->_WebserviceCreate(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

OR:

    my $Result = $ZnunyHelperObject->_WebserviceCreate(
        Webservices => {
            'New Webservice 1234' => '/path/to/Webservice.yml',
            ...
        }
    );

=cut

sub _WebserviceCreate {
    my ( $Self, %Param ) = @_;

    my $Webservices = $Param{Webservices};
    if ( !IsHashRefWithData($Webservices) ) {
        $Webservices = $Self->_WebservicesGet(
            SubDir => $Param{SubDir},
        );
    }

    return 1 if !IsHashRefWithData($Webservices);

    my $WebserviceList = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    if ( ref $WebserviceList ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Error while getting list of Webservices!"
        );
        return;
    }
    my %WebserviceListReversed = reverse %{$WebserviceList};

    WEBSERVICE:
    for my $WebserviceName ( sort keys %{$Webservices} ) {

        my $WebserviceID = $Self->_ItemReverseListGet( $WebserviceName, %WebserviceListReversed );
        my $UpdateOrCreateFunction = 'WebserviceAdd';

        if ($WebserviceID) {
            $UpdateOrCreateFunction = 'WebserviceUpdate';
        }

        my $WebserviceYAMLPath = $Webservices->{$WebserviceName};

        # read config
        my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $WebserviceYAMLPath,
        );

        if ( !$Content ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't read $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => ${$Content} );

        if ( !$Config ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while loading $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        # add or update webservice
        my $Success = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->$UpdateOrCreateFunction(
            ID      => $WebserviceID,
            Name    => $WebserviceName,
            Config  => $Config,
            ValidID => 1,
            UserID  => 1,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while updating/adding Webservice '$WebserviceName' from $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }
    }

    return 1;
}

=item _WebserviceDelete()

deletes webservices

    # deletes all .yml files webservices in $OTRS/scripts/webservices/
    # name of the file will be the name of the webservice
    my $Result = $ZnunyHelperObject->_WebserviceDelete(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

OR:

    my $Result = $ZnunyHelperObject->_WebserviceDelete(
        Webservices => {
            'Not needed Webservice 1234' => 1, # value is not used
            ...
        }
    );

=cut

sub _WebserviceDelete {
    my ( $Self, %Param ) = @_;

    my $Webservices = $Param{Webservices};
    if ( !IsHashRefWithData($Webservices) ) {
        $Webservices = $Self->_WebservicesGet(
            SubDir => $Param{SubDir},
        );
    }

    return 1 if !IsHashRefWithData($Webservices);

    my $WebserviceList = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    if ( ref $WebserviceList ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Error while getting list of Webservices!"
        );
        return;
    }
    my %WebserviceListReversed = reverse %{$WebserviceList};

    WEBSERVICE:
    for my $WebserviceName ( sort keys %{$Webservices} ) {

        # stop if already deleted
        next WEBSERVICE if !$WebserviceListReversed{$WebserviceName};

        # delete webservice
        my $Success = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceDelete(
            ID     => $WebserviceListReversed{$WebserviceName},
            UserID => 1,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while deleting Webservice '$WebserviceName'!"
            );
            return;
        }
    }

    return 1;
}

=item _WebservicesGet()

gets a list of .yml files from $OTRS/scripts/webservices

    my $Result = $ZnunyHelperObject->_WebservicesGet(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

    $Result = {
        'Webservice'          => '$OTRS/scripts/webservices/Znuny4OTRSAssetDesk/Webservice.yml',
        'New Webservice 1234' => '$OTRS/scripts/webservices/Znuny4OTRSAssetDesk/New Webservice 1234.yml',
    }

=cut

sub _WebservicesGet {
    my ( $Self, %Param ) = @_;

    my $WebserviceDirectory = $Kernel::OM->Get('Kernel::Config')->Get('Home')
        . '/scripts/webservices';

    if ( IsStringWithData( $Param{SubDir} ) ) {
        $WebserviceDirectory .= '/' . $Param{SubDir};
    }

    my @FilesInDirectory = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => $WebserviceDirectory,
        Filter    => '*.yml',
    );

    my %Webservices;
    for my $FileWithPath (@FilesInDirectory) {

        my $WebserviceName = $FileWithPath;
        $WebserviceName =~ s{\A .+? \/ ([^\/]+) \. yml \z}{$1}xms;

        $Webservices{$WebserviceName} = $FileWithPath;
    }

    return \%Webservices;
}

=item _PackageSetupInit()

set up initial steps for package setup

    my $Success = $ZnunyHelperObject->_PackageSetupInit();

Returns:

    my $Success = 1;

=cut

sub _PackageSetupInit {
    my ( $Self, %Param ) = @_;

    # rebuild ZZZ* files
    $Kernel::OM->Get('Kernel::System::SysConfig')->WriteDefault();

    # define the ZZZ files
    my @ZZZFiles = (
        'ZZZAAuto.pm',
        'ZZZAuto.pm',
    );

    # disable redefine warnings in this scope
    {
        no warnings 'redefine';

        # reload the ZZZ files (mod_perl workaround)
        for my $ZZZFile (@ZZZFiles) {

            PREFIX:
            for my $Prefix (@INC) {
                my $File = $Prefix . '/Kernel/Config/Files/' . $ZZZFile;
                next PREFIX if !-f $File;
                do $File;
                last PREFIX;
            }
        }
    }

    # make sure to use a new config object
    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::Config'],
    );

    return 1;
}

=item UserRoles()

This function returns the Role IDs or Names of a given User.

    my @Roles = $ZnunyHelperObject->UserRoles(
        UserID     => 123,
        Result     => 'Name', # default 'ID', Name|ID
        Permission => 'rw',   # default ro, ro,move_into,priority,create,rw
    );

    @Roles = (1, 3, 6);

=cut

sub UserRoles {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(UserID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # get each directly linked role for current Agent
    my @Roles = $GroupObject->GroupUserRoleMemberList(
        UserID => $Param{UserID},
        Result => $Param{Result},
        Type   => $Param{Permission} || 'ro',
    );

    # get each Group for the current Agent
    # since OTRS doesn't provide a function
    # to get all Roles for a User
    my @UserGroups = $GroupObject->GroupMemberList(
        UserID => $Param{UserID},
        Result => 'ID',
        Type   => $Param{Permission} || 'ro',
    );

    my %Result;

    # loop over each Group a User is in
    for my $GroupID (@UserGroups) {

        # get all RoleIDs for the current group
        my @UserRoles = $GroupObject->GroupRoleMemberList(
            GroupID => $GroupID,
            Result  => 'ID',
            Type    => $Param{Permission} || 'ro',
        );

        # if the requested Result is 'Name' we need to look up
        # the RoleName for the ID since GroupRoleMemberList
        # returns the GroupName instead of the RoleName
        # when passing the parameter Hash or Name m(
        if (
            $Param{Result}
            && $Param{Result} eq 'Name'
            )
        {
            my @RoleNames;

            for my $RoleID (@UserRoles) {

                my $RoleName = $GroupObject->RoleLookup( RoleID => $RoleID );
                push @RoleNames, $RoleName;
            }

            @UserRoles = @RoleNames;
        }

        my %GroupRoles = map { $_ => 1 } @UserRoles;

        %Result = (
            %Result,
            %GroupRoles
        );
    }

    push @Roles, keys %Result;

    return @Roles;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
