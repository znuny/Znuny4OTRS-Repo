# Copyright (C) 2013 Znuny GmbH, http://znuny.com

package Kernel::System::ZnunyHelper;

use strict;
use warnings;

use Kernel::Config;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::Encode;
use Kernel::System::Time;
use Kernel::System::DB;

use Kernel::System::XML;
use Kernel::System::SysConfig;
use Kernel::System::Group;
use Kernel::System::User;
use Kernel::System::Valid;
use Kernel::System::DynamicField;
use Kernel::System::DynamicFieldValue;

use Kernel::System::Package;

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    # create needed objects
    $Self->{ConfigObject} = Kernel::Config->new();
    $Self->{LogObject}    = Kernel::System::Log->new(
        LogPrefix => 'Znuny4OTRS-Helper',
        %{$Self},
    );
    $Self->{EncodeObject} = Kernel::System::Encode->new( %{$Self} );
    $Self->{MainObject}   = Kernel::System::Main->new( %{$Self} );
    $Self->{TimeObject}   = Kernel::System::Time->new( %{$Self} );
    $Self->{DBObject}     = Kernel::System::DB->new( %{$Self} );

    $Self->{XMLObject}       = Kernel::System::XML->new( %{$Self} );
    $Self->{SysConfigObject} = Kernel::System::SysConfig->new( %{$Self} );

    # rebuild ZZZ* files
    $Self->{SysConfigObject}->WriteDefault();

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


    # create needed objects
    $Self->{ConfigObject}            = Kernel::Config->new();
    $Self->{GroupObject}             = Kernel::System::Group->new( %{$Self} );
    $Self->{UserObject}              = Kernel::System::User->new( %{$Self} );
    $Self->{ValidObject}             = Kernel::System::Valid->new( %{$Self} );
    $Self->{DynamicFieldObject}      = Kernel::System::DynamicField->new( %{$Self} );
    $Self->{DynamicFieldValueObject} = Kernel::System::DynamicFieldValue->new( %{$Self} );

    return $Self;
}

# File => '/path/to/file'

sub _PackageInstall {
    my ( $Self, %Param ) = @_;

    my $PackageObject = Kernel::System::Package->new( %{$Self} );

    # read
    my $ContentRef = $Self->{MainObject}->FileRead(
        Location => $Param{File},
        Mode     => 'utf8',      # optional - binmode|utf8
        Result   => 'SCALAR',    # optional - SCALAR|ARRAY
    );
    return if !$ContentRef;

    # parse
    my %Structure = $PackageObject->PackageParse( String => ${$ContentRef} );

    # execute actions
    # install code (pre)
    if ( $Structure{CodeInstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeInstall},
            Type      => 'pre',
            Structure => \%Structure,
        );
    }

    # install database (pre)
    if ( $Structure{DatabaseInstall} && $Structure{DatabaseInstall}->{pre} ) {
        $PackageObject->_Database( Database => $Structure{DatabaseInstall}->{pre} );
    }

    # install database (post)
    if ( $Structure{DatabaseInstall} && $Structure{DatabaseInstall}->{post} ) {
        $PackageObject->_Database( Database => $Structure{DatabaseInstall}->{post} );
    }

    # install code (post)
    if ( $Structure{CodeInstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeInstall},
            Type      => 'post',
            Structure => \%Structure,
        );
    }

    $PackageObject->{CacheObject}->CleanUp();
    $PackageObject->{LoaderObject}->CacheDelete();

    return 1;
}

# File => '/path/to/file'

sub _PackageUninstall {
    my ( $Self, %Param ) = @_;

    my $PackageObject = Kernel::System::Package->new( %{$Self} );

    # read
    my $ContentRef = $Self->{MainObject}->FileRead(
        Location => $Param{File},
        Mode     => 'utf8',      # optional - binmode|utf8
        Result   => 'SCALAR',    # optional - SCALAR|ARRAY
    );
    return if !$ContentRef;

    # parse
    my %Structure = $PackageObject->PackageParse( String => ${$ContentRef} );

    # uninstall code (pre)
    if ( $Structure{CodeUninstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeUninstall},
            Type      => 'pre',
            Structure => \%Structure,
        );
    }

    # uninstall database (pre)
    if ( $Structure{DatabaseUninstall} && $Structure{DatabaseUninstall}->{pre} ) {
        $PackageObject->_Database( Database => $Structure{DatabaseUninstall}->{pre} );
    }

    # uninstall database (post)
    if ( $Structure{DatabaseUninstall} && $Structure{DatabaseUninstall}->{post} ) {
        $PackageObject->_Database( Database => $Structure{DatabaseUninstall}->{post} );
    }

    # uninstall code (post)
    if ( $Structure{CodeUninstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeUninstall},
            Type      => 'post',
            Structure => \%Structure,
        );
    }

    $PackageObject->{CacheObject}->CleanUp();
    $PackageObject->{LoaderObject}->CacheDelete();

    return 1;
}

=item _JSLoaderAdd()

This function adds JavaScript files to the load of defined screens.

my $Result = $CodeObject->_JSLoaderAdd(
    AgentTicketPhone => ['Core.Agent.WPTicketOEChange.js'],
);

=cut

sub _JSLoaderAdd {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    my %JSLoaderConfig = %Param;

    VIEW:
    for my $View ( keys %JSLoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $JSLoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

       # get existing config for each View
        my $Config = $Self->{ConfigObject}->Get($CustomerInterfacePrefix ."Frontend::Module")->{$View};

        if ( !IsHashRefWithData($Config) ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Error while getting '${CustomerInterfacePrefix}Frontend::Module' for view '$View'.",
            );
            next VIEW;
        }

        my @JSLoaderFiles;
        if (
            IsHashRefWithData( $Config->{Loader} )
            && IsArrayRefWithData( $Config->{Loader}->{JavaScript} )
            )
        {
            @JSLoaderFiles = @{ $Config->{Loader}->{JavaScript} };
        }

        LOADERFILE:
        for my $NewJSLoaderFile ( sort @{ $JSLoaderConfig{$View} } ) {

            next LOADERFILE if grep { $NewJSLoaderFile eq $_ } @JSLoaderFiles;

            push @JSLoaderFiles, $NewJSLoaderFile;
        }

        $Config->{Loader}->{JavaScript} = \@JSLoaderFiles;

        # update the sysconfig
        my $Success = $Self->{SysConfigObject}->ConfigItemUpdate(
            Valid => 1,
            Key   => $CustomerInterfacePrefix ."Frontend::Module###" . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _JSLoaderRemove()
This function adds JavaScript files to the load of defined screens.

my $Result = $CodeObject->_JSLoaderRemove(
    AgentTicketPhone => ['Core.Agent.WPTicketOEChange.js'],
);

=cut

sub _JSLoaderRemove {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %JSLoaderConfig = %Param;

    VIEW:
    for my $View ( keys %JSLoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $JSLoaderConfig{$View} );


        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

       # get existing config for each View
        my $Config = $Self->{ConfigObject}->Get($CustomerInterfacePrefix ."Frontend::Module")->{$View};

        if ( !IsHashRefWithData($Config) ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Error while getting '${CustomerInterfacePrefix}Frontend::Module' for view '$View'.",
            );
            next VIEW;
        }

        my @JSLoaderFiles;
        if (
            IsHashRefWithData( $Config->{Loader} )
            && IsArrayRefWithData( $Config->{Loader}->{JavaScript} )
            )
        {
            @JSLoaderFiles = @{ $Config->{Loader}->{JavaScript} };
        }

        next VIEW if !@JSLoaderFiles;

        my @NewJSLoaderFiles;
        LOADERFILE:
        for my $JSLoaderFile ( sort @JSLoaderFiles ) {

            next LOADERFILE if grep { $JSLoaderFile eq $_ } @{ $JSLoaderConfig{$View} };

            push @NewJSLoaderFiles, $JSLoaderFile;
        }

        $Config->{Loader}->{JavaScript} = \@NewJSLoaderFiles;

        # update the sysconfig
        my $Success = $Self->{SysConfigObject}->ConfigItemUpdate(
            Valid => 1,
            Key   => $CustomerInterfacePrefix .'Frontend::Module###' . $View,
            Value => $Config,
        );
    }

    return 1;
}
=item _DynamicFieldsScreenEnable()

This function enables the defined dynamic fields in the needed screens.

my $Result = $CodeObject->_DynamicFieldsScreenEnable();

=cut

sub _DynamicFieldsScreenEnable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    for my $Screen ( keys %ScreenDynamicFieldConfig ) {

        # get existing config for each screen
        my $Config = $Self->{ConfigObject}->Get("Ticket::Frontend::$Screen");

        # get existing dynamic field config
        my %ExistingSetting = %{ $Config->{DynamicField} || {} };

        # add the new settings
        my %NewSetting = ( %ExistingSetting, %{ $ScreenDynamicFieldConfig{$Screen} } );

        # update the sysconfig
        my $Success = $Self->{SysConfigObject}->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Frontend::' . $Screen . '###DynamicField',
            Value => \%NewSetting,
        );
    }

    return 1;
}

=item _DynamicFieldsScreenDisable()

This function disables the defined dynamic fields in the needed screens.

my $Result = $CodeObject->_DynamicFieldsScreenDisable($Definition);

=cut

sub _DynamicFieldsScreenDisable {
    my ( $Self, %Param ) = @_;
    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    SCREEN:
    for my $Screen ( keys %ScreenDynamicFieldConfig ) {

        next SCREEN if !IsHashRefWithData( $ScreenDynamicFieldConfig{$Screen} );

        # get existing config for each screen
        my $Config = $Self->{ConfigObject}->Get("Ticket::Frontend::$Screen");

        # get existing dynamic field config
        my %ExistingSetting = %{ $Config->{DynamicField} || {} };

        my %NewSetting;
        SETTING:
        for my $ExistingSettingKey ( sort keys %ExistingSetting ) {

            next SETTING if $ScreenDynamicFieldConfig{$Screen}->{$ExistingSettingKey};

            $NewSetting{$ExistingSettingKey} = $ExistingSetting{$ExistingSettingKey};
        }

        # update the sysconfig
        my $Success = $Self->{SysConfigObject}->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Frontend::' . $Screen . '###DynamicField',
            Value => \%NewSetting,
        );
    }
    return 1;
}

=item _DynamicFieldsDelete()

This function delete the defined dynamic fields

my $Result = $CodeObject->_DynamicFieldsDelete('Field1', 'Field2');

=cut

sub _DynamicFieldsDelete {
    my ( $Self, @Definition ) = @_;

    # get all current dynamic fields
    my $DynamicFieldList = $Self->{DynamicFieldObject}->DynamicFieldListGet(
        Valid => 0,
    );

    # get the definition for all dynamic fields
    my @DynamicFields = @Definition;

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELDLOOKUP:
    for my $DynamicField ( @{$DynamicFieldList} ) {
        next DYNAMICFIELDLOOKUP if ref $DynamicField ne 'HASH';
        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # disable the dynamic fields
    DYNAMICFIELD:
    for my $DynamicField (@DynamicFields) {
        next if !$DynamicFieldLookup{ $DynamicField };
        my $Success = $Self->{DynamicFieldObject}->DynamicFieldDelete(
            %{ $DynamicFieldLookup{ $DynamicField } },
            Reorder    => 0,
            UserID     => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsDisable()

This function disables the defined dynamic fields

my $Result = $CodeObject->_DynamicFieldsDisable('Field1', 'Field2');

=cut

sub _DynamicFieldsDisable {
    my ( $Self, @Definition ) = @_;

    my $ValidID = $Self->{ValidObject}->ValidLookup(
        Valid => 'invalid',
    );

    # get all current dynamic fields
    my $DynamicFieldList = $Self->{DynamicFieldObject}->DynamicFieldListGet(
        Valid => 0,
    );

    # get the definition for all dynamic fields
    my @DynamicFields = @Definition;

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELDLOOKUP:
    for my $DynamicField ( @{$DynamicFieldList} ) {
        next DYNAMICFIELDLOOKUP if ref $DynamicField ne 'HASH';
        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # disable the dynamic fields
    DYNAMICFIELD:
    for my $DynamicField (@DynamicFields) {
        next if !$DynamicFieldLookup{ $DynamicField };
        my $Success = $Self->{DynamicFieldObject}->DynamicFieldUpdate(
            %{ $DynamicFieldLookup{ $DynamicField } },
            ValidID    => $ValidID,
            Reorder    => 0,
            UserID     => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsCreateIfNotExists()

creates all dynamic fields that are necessary

    my $Result = $CodeObject->_DynamicFieldsCreateIfNotExists( $Definition );

=cut

sub _DynamicFieldsCreateIfNotExists {
    my ( $Self, @Definition ) = @_;

    # get all current dynamic fields
    my $DynamicFieldList = $Self->{DynamicFieldObject}->DynamicFieldListGet(
        Valid => 0,
    );
    my @DynamicFieldExistsNot;
    for my $NewDynamicfield (@Definition) {
        my $Exists = 0;
        for my $OldDynamicfield ( @{$DynamicFieldList} ) {
            if ( $NewDynamicfield->{Name} eq $OldDynamicfield->{Name} ) {
                $Exists = 1;
            }
        }
        if (!$Exists) {
            push @DynamicFieldExistsNot, $NewDynamicfield;
        }
    }
    if (@DynamicFieldExistsNot) {
        $Self->_DynamicFieldsCreate(@DynamicFieldExistsNot);
    }

    return 1;
}

=item _DynamicFieldsCreate()

creates all dynamic fields that are necessary

    my $Result = $CodeObject->_DynamicFieldsCreate( $Definition );

=cut

sub _DynamicFieldsCreate {
    my ( $Self, @Definition ) = @_;

    my $ValidID = $Self->{ValidObject}->ValidLookup(
        Valid => 'valid',
    );

    # get all current dynamic fields
    my $DynamicFieldList = $Self->{DynamicFieldObject}->DynamicFieldListGet(
        Valid => 0,
    );

    # get the list of order numbers (is already sorted).
    my @DynamicfieldOrderList;
    for my $Dynamicfield ( @{$DynamicFieldList} ) {
        push @DynamicfieldOrderList, $Dynamicfield->{FieldOrder};
    }

    # get the last element from the order list and add 1
    my $NextOrderNumber = 1;
    if (@DynamicfieldOrderList) {
        $NextOrderNumber = $DynamicfieldOrderList[-1] + 1;
    }

    # get the definition for all dynamic fields
    my @DynamicFields = @Definition;

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELDLOOKUP:
    for my $DynamicField ( @{$DynamicFieldList} ) {
        next DYNAMICFIELDLOOKUP if ref $DynamicField ne 'HASH';
        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # create or update dynamic fields
    DYNAMICFIELD:
    for my $DynamicField (@DynamicFields) {
        my $CreateDynamicField;

        # check if the dynamic field already exists
        if ( ref $DynamicFieldLookup{ $DynamicField->{Name} } ne 'HASH' ) {
            $CreateDynamicField = 1;
        }

        # if the field exists check if the type match with the needed type
        elsif (
            $DynamicFieldLookup{ $DynamicField->{Name} }->{FieldType}
            ne $DynamicField->{FieldType}
            )
        {

            # rename the field and create a new one
            my $Success = $Self->{DynamicFieldObject}->DynamicFieldUpdate(
                %{ $DynamicFieldLookup{ $DynamicField->{Name} } },
                Name   => $DynamicFieldLookup{ $DynamicField->{Name} }->{Name} . 'Old',
                UserID => 1,
            );

            $CreateDynamicField = 1;
        }

        # otherwise if the field exists and the type matches, update it as defined
        else {
            my $Success = $Self->{DynamicFieldObject}->DynamicFieldUpdate(
                %{$DynamicField},
                ID         => $DynamicFieldLookup{ $DynamicField->{Name} }->{ID},
                FieldOrder => $DynamicFieldLookup{ $DynamicField->{Name} }->{FieldOrder},
                ValidID    => $ValidID,
                Reorder    => 0,
                UserID     => 1,
            );
        }

        # check if new field has to be created
        if ($CreateDynamicField) {

            # create a new field
            my $FieldID = $Self->{DynamicFieldObject}->DynamicFieldAdd(
                Name       => $DynamicField->{Name},
                Label      => $DynamicField->{Label},
                FieldOrder => $NextOrderNumber,
                FieldType  => $DynamicField->{FieldType},
                ObjectType => $DynamicField->{ObjectType},
                Config     => $DynamicField->{Config},
                ValidID    => $ValidID,
                UserID     => 1,
            );
            next DYNAMICFIELD if !$FieldID;

            # increase the order number
            $NextOrderNumber++;
        }
    }

    return 1;
}

=item _GroupCreateIfNotExists()

creates group if not texts

    my $Result = $CodeObject->_GroupCreateIfNotExists( Name => 'Some Group Name' );

=cut

sub _GroupCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    my %Groups = $Self->{GroupObject}->GroupList( Valid => 0 );
    for my $GroupID ( keys %Groups ) {
        return if $Param{Name} eq $Groups{ $GroupID };
    }
    return $Self->{GroupObject}->GroupAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

1;
