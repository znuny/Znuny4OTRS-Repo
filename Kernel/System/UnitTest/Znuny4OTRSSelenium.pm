# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/1f709d129aec08cad724b485839acf1d61ec1a1a/Kernel/System/UnitTest/Selenium.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Znuny4OTRSSelenium;

use strict;
use warnings;

use utf8;

use URI::Escape;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::JSON',
    'Kernel::System::UnitTest::Znuny4OTRSHelper',
);

use base qw( Kernel::System::UnitTest::Selenium );

use Kernel::System::VariableCheck qw(:all);

=item InputGet()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Get' function.

    my $Result = $Znuny4OTRSSelenium->InputGet(
        Attribute => 'QueueID',
        Options   => {                          # optinal
            KeyOrValue => 'Value',              # default is 'Key'
        }
    );

    $Result = 'Postmaster';
=cut

sub InputGet {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $OptionsParameter = '';
    if ( IsHashRefWithData( $Param{Options} ) ) {

        my $OptionsJSON = $JSONObject->Encode(
            Data => $Param{Options},
        );
        $OptionsParameter = ", $OptionsJSON";
    }

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Get('$Param{Attribute}' $OptionsParameter);");
}

=item InputSet()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Set' function.

    my $Result = $Znuny4OTRSSelenium->InputSet(
        Attribute   => 'QueueID',
        WaitForAJAX => 0,                       # optional, default 1
        Content     => 'Misc',                  # optional, none removes content
        Options     => {                        # optinal
            KeyOrValue    => 'Value',           # default is 'Key'
            TriggerChange => 0,                 # default is 1
        }
    );

    $Result = 1;
=cut

sub InputSet {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $Content;
    if ( !defined $Param{Content} ) {
        $Content = 'undefined';
    }
    elsif ( IsStringWithData($Param{Content}) ) {

        if (
            $Param{Content} eq 'true'
            || $Param{Content} eq 'false'
        ) {
            $Content = $Param{Content};
        }
        else {
            # quoting
            $Param{Content} =~ s{'}{\\'}xmsg;
            $Param{Content} =~ s{\n}{\\n\\\n}xmsg;

            $Content = "'$Param{Content}'";
        }
    }
    else {
        my $ContentJSON = $JSONObject->Encode(
            Data => $Param{Content},
        );
        $Content = $ContentJSON;
    }

    my $OptionsParameter = '';
    if ( IsHashRefWithData( $Param{Options} ) ) {

        my $OptionsJSON = $JSONObject->Encode(
            Data => $Param{Options},
        );
        $OptionsParameter = ", $OptionsJSON";
    }

    my $Result = $Self->execute_script("return Core.Form.Znuny4OTRSInput.Set('$Param{Attribute}', $Content $OptionsParameter);");

    if (
        !defined $Param{WaitForAJAX}
        || $Param{WaitForAJAX}
    ) {
        $Self->AJAXCompleted();
    }
    # No GuardClause :)

    return $Result;
}

=item InputMandatory()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Mandatory' function.
Sets OR returns the Mandatory state of an input field.

    # Set mandatory state:

    my $Result = $Znuny4OTRSSelenium->InputMandatory(
        Attribute => 'QueueID',
        Mandatory => 1,         # 1 or 0
    );

    $Result = 1;

    # OR return mandatory state:

    my $Result = $Znuny4OTRSSelenium->InputMandatory(
        Attribute => 'QueueID',
    );

    $Result = 0;
=cut

sub InputMandatory {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $Mandatory;
    if ( defined $Param{Mandatory} ) {
        $Mandatory = $Param{Mandatory} ? 'true' : 'false';
    }

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Mandatory('$Param{Attribute}' $Mandatory);");
}

=item InputFieldID()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'FieldID' function.

    my $Result = $Znuny4OTRSSelenium->InputFieldID(
        Attribute => 'QueueID',
    );

    $Result = 'Dest';
=cut

sub InputFieldID {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.FieldID('$Param{Attribute}');");
}

=item InputType()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Type' function.
Attention: Requires the FieldID - not the Attribute! (See InputFieldID)

    my $Result = $Znuny4OTRSSelenium->InputType(
        FieldID => 'Dest',
    );

    $Result = 'select';
=cut

sub InputType {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Type('$Param{FieldID}');");
}

=item InputHide()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Hide' function.

    my $Result = $Znuny4OTRSSelenium->InputHide(
        Attribute => 'QueueID',
    );

    $Result = 1;
=cut

sub InputHide {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Hide('$Param{Attribute}');");
}

=item InputShow()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Show' function.

    my $Result = $Znuny4OTRSSelenium->InputShow(
        Attribute => 'QueueID',
    );

    $Result = 1;
=cut

sub InputShow {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Show('$Param{Attribute}');");
}

=item InputModule()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Module' function.

    my $Result = $Znuny4OTRSSelenium->InputModule(
        Action => 'QueueID',
    );

    $Result = 1;
=cut

sub InputModule {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Module('$Param{Action}');");
}

=item InputFieldIDMapping()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'FieldIDMapping' function.
Sets OR returns the mapping structure of the given Action.

    my $Result = $Znuny4OTRSSelenium->InputFieldIDMapping(
        Action  => 'AgentTicketZoom',
        Mapping => {
            ...
            QueueID => 'DestQueueID',
            ...
        },
    );

    $Result = 1;

    # OR

    my $Result = $Znuny4OTRSSelenium->InputFieldIDMapping(
        Action  => 'AgentTicketZoom',
    );

    $Result = {
        DestQueueID => 'DestQueueID',
        QueueID =>     'DestQueueID'
    };
=cut

sub InputFieldIDMapping {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $MappingParameter = '';
    if ( IsHashRefWithData( $Param{Mapping} ) ) {

        my $MappingJSON = $JSONObject->Encode(
            Data => $Param{Mapping},
        );
        $MappingParameter = ", $MappingJSON";
    }

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.FieldIDMapping('$Param{Action}' $MappingParameter);");
}

=item AgentLogin()

Creates and logs in an Agent. Calls TestUserDataGet and Login on the Znuny4OTRSHelper object.

    my %UserData = $Znuny4OTRSSelenium->AgentLogin(
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

sub AgentLogin {
    my ( $Self, %Param ) = @_;

    my $Znuny4OTRSHelper = $Kernel::OM->Get('Kernel::System::UnitTest::Znuny4OTRSHelper');

    # create test user and login
    my %TestUser = $Znuny4OTRSHelper->TestUserDataGet(
        %Param
    );

    $Self->Login(
        Type     => 'Agent',
        User     => $TestUser{UserLogin},
        Password => $TestUser{UserLogin},
    );

    return %TestUser;
}

=item CustomerUserLogin()

Creates and logs in an CustomerUser. Calls TestCustomerUserDataGet and Login on the Znuny4OTRSHelper object.

    my %CustomerUserData = $Znuny4OTRSSelenium->CustomerUserLogin(
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

sub CustomerUserLogin {
    my ( $Self, %Param ) = @_;

    my $Znuny4OTRSHelper = $Kernel::OM->Get('Kernel::System::UnitTest::Znuny4OTRSHelper');

    # create test user and login
    my %TestCustomerUser = $Znuny4OTRSHelper->TestCustomerUserDataGet(
        %Param
    );

    $Self->Login(
        Type     => 'Customer',
        User     => $TestCustomerUser{UserLogin},
        Password => $TestCustomerUser{UserLogin},
    );

    return %TestCustomerUser;
}


=item SwitchToPopUp()

Switches the Selenium context to the PopUp

    $Znuny4OTRSSelenium->SwitchToPopUp(
        WaitForAJAX => 0, # optional, default 1
    );
=cut

sub SwitchToPopUp {
    my ( $Self, %Param ) = @_;

    # switch to PopUp window
    $Self->WaitFor( WindowCount => 2 );
    my $Handles = $Self->get_window_handles();
    $Self->switch_to_window( $Handles->[1] );

    # wait until page has loaded, if necessary
    $Self->WaitFor( JavaScript => 'return typeof($) === "function" && $(".CancelClosePopup").length' );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
    ) {
        return;
    }

    $Self->AJAXCompleted();
}

=item PageContains()

Checks if the currelty opened page contains the given String

    $Znuny4OTRSSelenium->PageContains(
        String  => 'Ticked locked.',
        Message => "Page contains 'Ticket locked.'" # optional - default
    );
=cut

sub PageContains {
    my ( $Self, %Param ) = @_;

    my $UnitTestMessage = $Param{Message};
    $UnitTestMessage  ||= "Page contains '$Param{String}'";

    $Self->{UnitTestObject}->True(
        index( $Self->get_page_source(), $Param{String} ) > -1,
        $UnitTestMessage,
    );
}

=item AJAXCompleted()

Waits for AJAX requests to be completed by checking the jQuery 'active' attribute.

    $Znuny4OTRSSelenium->AJAXCompleted();
=cut

sub AJAXCompleted {
    my ( $Self, %Param ) = @_;

    my $AJAXStartedLoading = $Self->WaitFor( JavaScript => 'return jQuery.active' );
    $Self->{UnitTestObject}->True(
        $AJAXStartedLoading,
        'AJAX requests started loading.'
    );

    my $AJAXCompletedLoading = $Self->WaitFor( JavaScript => 'return jQuery.active == 0' );
    $Self->{UnitTestObject}->True(
        $AJAXCompletedLoading,
        'AJAX requests have finished loading.'
    );
}

=item AgentInterface()

Performs a GET request to the AgentInterface with the given parameters. Interally _GETInterface is called.

    $Znuny4OTRSSelenium->AgentInterface(
        Action      => 'AgentTicketZoom',
        WaitForAJAX => 0,                     # optional, default 1
    );
=cut

sub AgentInterface {
    my ( $Self, %Param ) = @_;

    $Self->_GETInterface(
        Interface   => 'Agent',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=item CustomerInterface()

Performs a GET request to the CustomerInterface with the given parameters. Interally _GETInterface is called.

    $Znuny4OTRSSelenium->CustomerInterface(
        Action      => 'CustomerTicketMessage',
        WaitForAJAX => 0,                      # optional, default 1
    );
=cut

sub CustomerInterface {
    my ( $Self, %Param ) = @_;

    $Self->_GETInterface(
        Interface   => 'Customer',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=item PublicInterface()

Performs a GET request to the PublicInterface with the given parameters. Interally _GETInterface is called.

    $Znuny4OTRSSelenium->PublicInterface(
        Action      => 'PublicFAQ',
        WaitForAJAX => 0,             # optional, default 1
    );
=cut

sub PublicInterface {
    my ( $Self, %Param ) = @_;

    $Self->_GETInterface(
        Interface   => 'Customer',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=item _GETInterface()

Performs a GET request to the given Interface with the given parameters. Interally VerifiedGet is called.
Request waits till page has finished loading via checking if the jQuery Object has been initialized and
all AJAX requests are compleded via function AJAXCompleted.

    $Znuny4OTRSSelenium->_GETInterface(
        Interface   => 'Agent',           # or Customer or Public
        WaitForAJAX => 0,                 # optional, default 1
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );
=cut
sub _GETInterface {
    my ( $Self, %Param ) = @_;

    # get script alias
    my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

    my %InterfaceMapping = (
        Agent    => 'index',
        Customer => 'customer',
        Public   => 'public',
    );

    my $RequestURL = $ScriptAlias . $InterfaceMapping{ $Param{Interface} } .'.pl';
    if ( IsHashRefWithData( $Param{Param} ) ) {
        $RequestURL .= '?';
        $RequestURL .= $Self->_Hash2GETParamString( %{ $Param{Param} } );
    }

    $Self->VerifiedGet($RequestURL);

    my $PageFinishedLoading = $Self->WaitFor( JavaScript => 'return typeof($) === "function"' );
    $Self->{UnitTestObject}->True(
        $PageFinishedLoading,
        'Page has finished loading.'
    );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
    ) {
        return;
    }

    $Self->AJAXCompleted();
}

=item _Hash2GETParamString()

Converts a Hash into a GET Parameter String, without the leading ?. Inspired by http://stackoverflow.com/a/449204

    my $Result = $Znuny4OTRSSelenium->_Hash2GETParamString(
        Action   => 'AgentTicketZoom',
        TicketID => 1,
    );

    $Result = 'Action=AgentTicketZoom;TicketID=1'
=cut
sub _Hash2GETParamString {
    my ( $Self, %Param ) = @_;
    my @Pairs;
    for my $Key (sort keys %Param) {
        push @Pairs, join '=', map { uri_escape($_) } $Key, $Param{$Key};
    }
    return join ';', @Pairs;
}

1;
