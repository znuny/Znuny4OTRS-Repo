# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/c5b77b7918dd1ccaf1ae1c20f997ed5c019d3f86/Kernel/System/UnitTest/Selenium.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Selenium;
## nofilter(TidyAll::Plugin::OTRS::Perl::Goto)
use Kernel::System::UnitTest::Helper;

use strict;
use warnings;

use MIME::Base64();
use File::Temp();

use Kernel::Config;
use Kernel::System::User;
# ---
# Znuny4OTRS-Repo
# ---
use utf8;
use URI::Escape;
use Kernel::System::VariableCheck qw(:all);
# ---

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Time',
    'Kernel::System::UnitTest',
# ---
# Znuny4OTRS-Repo
# ---
    'Kernel::System::JSON',
    'Kernel::System::UnitTest::Helper',
# ---
);

=head1 NAME

Kernel::System::UnitTest::Selenium - run frontend tests

This class inherits from Selenium::Remote::Driver. You can use
its full API (see
L<http://search.cpan.org/~aivaturi/Selenium-Remote-Driver-0.15/lib/Selenium/Remote/Driver.pm>).

Every successful Selenium command will be logged as a successful unit test.
In case of an error, an exception will be thrown that you can catch in your
unit test file and handle with C<HandleError()> in this class. It will output
a failing test result and generate a screenshot for analysis.

=over 4

=cut

=item new()

create a selenium object to run fontend tests.

To do this, you need a running selenium or phantomjs server.

Specify the connection details in Config.pm, like this:

    $Self->{'SeleniumTestsConfig'} = {
        remote_server_addr  => 'localhost',
        port                => '4444',
        browser_name        => 'phantomjs',
        platform            => 'ANY',
        window_height       => 1200,    # optional, default 1000
        window_width        => 1600,    # optional, default 1200
    };

Then you can use the full API of Selenium::Remote::Driver on this object.

=cut

sub new {
    my ( $Class, %Param ) = @_;

    $Param{UnitTestObject} ||= $Kernel::OM->Get('Kernel::System::UnitTest');

    $Param{UnitTestObject}->True( 1, "Starting up Selenium scenario..." );

    my %SeleniumTestsConfig = %{ $Kernel::OM->Get('Kernel::Config')->Get('SeleniumTestsConfig') // {} };

    if ( !%SeleniumTestsConfig ) {
        my $Self = bless {}, $Class;
        $Self->{UnitTestObject} = $Param{UnitTestObject};
        return $Self;
    }

    for my $Needed (qw(remote_server_addr port browser_name platform)) {
        if ( !$SeleniumTestsConfig{$Needed} ) {
            die "SeleniumTestsConfig must provide $Needed!";
        }
    }

    $Kernel::OM->Get('Kernel::System::Main')->RequireBaseClass('Selenium::Remote::Driver')
        || die "Could not load Selenium::Remote::Driver";

    $Kernel::OM->Get('Kernel::System::Main')->Require('Kernel::System::UnitTest::Selenium::WebElement')
        || die "Could not load Kernel::System::UnitTest::Selenium::WebElement";

    my $Self = $Class->SUPER::new(
        webelement_class => 'Kernel::System::UnitTest::Selenium::WebElement',
        %SeleniumTestsConfig
    );
    $Self->{UnitTestObject}      = $Param{UnitTestObject};
    $Self->{SeleniumTestsActive} = 1;

    #$Self->debug_on();

    # set screen size from config or use defauls
    my $Height = $SeleniumTestsConfig{window_height} || 1200;
    my $Width  = $SeleniumTestsConfig{window_width}  || 1400;

    $Self->set_window_size( $Height, $Width );

    $Self->{BaseURL} = $Kernel::OM->Get('Kernel::Config')->Get('HttpType') . '://';
    $Self->{BaseURL} .= Kernel::System::UnitTest::Helper->GetTestHTTPHostname();

    return $Self;
}

=item RunTest()

runs a selenium test if Selenium testing is configured and performs proper
error handling (calls C<HandleError()> if needed).

    $SeleniumObject->RunTest( sub { ... } );

=cut

sub RunTest {
    my ( $Self, $Test ) = @_;

    if ( !$Self->{SeleniumTestsActive} ) {
        $Self->{UnitTestObject}->True( 1, 'Selenium testing is not active, skipping tests.' );
        return 1;
    }

    eval {
        $Test->();
    };
    $Self->HandleError($@) if $@;

    return 1;
}

=item _execute_command()

Override internal command of base class.

We use it to output successful command runs to the UnitTest object.
Errors will cause an exeption and be caught elsewhere.

=cut

sub _execute_command {    ## no critic
    my ( $Self, $Res, $Params ) = @_;

    my $Result = $Self->SUPER::_execute_command( $Res, $Params );

    my $TestName = 'Selenium command success: ';
    $TestName .= $Kernel::OM->Get('Kernel::System::Main')->Dump(
        {
            %{ $Res    || {} },
            %{ $Params || {} },
        }
    );

    if ( $Self->{SuppressCommandRecording} ) {
        print $TestName;
    }
    else {
        $Self->{UnitTestObject}->True( 1, $TestName );
    }

    return $Result;
}

=item get()

Override get method of base class to prepend the correct base URL.

    $SeleniumObject->get(
        $URL,
    );

=cut

sub get {    ## no critic
    my ( $Self, $URL ) = @_;

    if ( $URL !~ m{http[s]?://}smx ) {
        $URL = "$Self->{BaseURL}/$URL";
    }

    $Self->SUPER::get($URL);

    return;
}

=item VerifiedGet()

perform a get() call, but wait for the page to be fully loaded (works only within OTRS).
Will die() if the verification fails.

    $SeleniumObject->VerifiedGet(
        $URL,
    );

=cut

sub VerifiedGet {
    my ( $Self, $URL ) = @_;

    $Self->get($URL);

    $Self->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.Config) == "object" && Core.Config.Get("Baselink")'
    ) || die "OTRS API verification failed after page load.";

    return;
}

=item VerifiedRefresh()

perform a refresh() call, but wait for the page to be fully loaded (works only within OTRS).
Will die() if the verification fails.

    $SeleniumObject->VerifiedRefresh();

=cut

sub VerifiedRefresh {
    my ( $Self, $URL ) = @_;

    $Self->refresh();

    $Self->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.Config) == "object" && Core.Config.Get("Baselink")'
    ) || die "OTRS API verification failed after page load.";

    return;
}

=item Login()

login to agent or customer interface

    $SeleniumObject->Login(
        Type     => 'Agent', # Agent|Customer
        User     => 'someuser',
        Password => 'somepassword',
    );

=cut

sub Login {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Type User Password)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    $Self->{UnitTestObject}->True( 1, 'Initiating login...' );

    eval {
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        if ( $Param{Type} eq 'Agent' ) {
            $ScriptAlias .= 'index.pl';
        }
        else {
            $ScriptAlias .= 'customer.pl';
        }

        $Self->get("${ScriptAlias}");
        $Self->delete_all_cookies();
        $Self->VerifiedGet("${ScriptAlias}?Action=Login;User=$Param{User};Password=$Param{Password}");

        # login successful?
        $Self->find_element( 'a#LogoutButton', 'css' );    # dies if not found

        $Self->{UnitTestObject}->True( 1, 'Login sequence ended...' );
    };
    if ($@) {
        $Self->HandleError($@);
        die "Login failed!";
    }

    return 1;
}

=item WaitFor()

wait with increasing sleep intervals until the given condition is true or the wait time is over.
Exactly one condition (JavaScript or WindowCount) must be specified.

    my $Success = $SeleniumObject->WaitFor(
        JavaScript   => 'return $(".someclass").length',   # Javascript code that checks condition
        AlertPresent => 1,                                 # Wait until an alert, confirm or prompt dialog is present
        WindowCount  => 2,                                 # Wait until this many windows are open
        Time         => 20,                                # optional, wait time in seconds (default 20)
    );

=cut

sub WaitFor {
    my ( $Self, %Param ) = @_;

    if ( !$Param{JavaScript} && !$Param{WindowCount} && !$Param{AlertPresent} ) {
        die "Need JavaScript, WindowCount or AlertPresent.";
    }

    local $Self->{SuppressCommandRecording} = 1;

    $Param{Time} //= 20;
    my $WaitedSeconds = 0;
    my $Interval      = 0.1;

    while ( $WaitedSeconds <= $Param{Time} ) {
        if ( $Param{JavaScript} ) {
            return 1 if $Self->execute_script( $Param{JavaScript} )
        }
        elsif ( $Param{WindowCount} ) {
            return 1 if scalar( @{ $Self->get_window_handles() } ) == $Param{WindowCount};
        }
        elsif ( $Param{AlertPresent} ) {
            # Eval is needed because the method would throw if no alert is present (yet).
            return 1 if eval { $Self->get_alert_text() };
        }
        sleep $Interval;
        $WaitedSeconds += $Interval;
        $Interval += 0.1;
    }
    return;
}

=item HandleError()

use this method to handle any Selenium exceptions.

    $SeleniumObject->HandleError($@);

It will create a failing test result and store a screenshot of the page
for analysis (in folder /var/otrs-unittest if it exists, in /tmp otherwise).

=cut

sub HandleError {
    my ( $Self, $Error ) = @_;

    $Self->{UnitTestObject}->False( 1, "Exception in Selenium': $Error" );

    #eval {
    my $Data = $Self->screenshot();
    return if !$Data;
    $Data = MIME::Base64::decode_base64($Data);

    my $TmpDir = -d '/var/otrs-unittest/' ? '/var/otrs-unittest/' : '/tmp/';
    $TmpDir .= 'SeleniumScreenshots/';
    mkdir $TmpDir || return $Self->False( 1, "Could not create $TmpDir." );

    my $Product = $Self->{UnitTestObject}->{Product};
    $Product =~ s{[^a-z0-9_.\-]+}{_}smxig;
    $TmpDir .= $Product;
    mkdir $TmpDir || return $Self->False( 1, "Could not create $TmpDir." );

    my $Filename = $Kernel::OM->Get('Kernel::System::Time')->CurrentTimestamp();
    $Filename .= '-' . ( int rand 100_000_000 ) . '.png';
    $Filename =~ s{[ :]}{-}smxg;

    $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
        Directory => $TmpDir,
        Filename  => $Filename,
        Content   => \$Data,
    ) || return $Self->False( 1, "Could not write file $TmpDir/$Filename" );

    $Self->{UnitTestObject}->False(
        1,
        "Saved screenshot in file://$TmpDir/$Filename",
    );
}

=item DESTROY()

cleanup. Adds a unit test result to indicate the shutdown.

=cut

sub DESTROY {
    my $Self = shift;

    # Could be missing on early die.
    if ( $Self->{UnitTestObject} ) {
        $Self->{UnitTestObject}->True( 1, "Shutting down Selenium scenario." );
    }

    if ( $Self->{SeleniumTestsActive} ) {
        $Self->SUPER::DESTROY();
    }
}
# ---
# Znuny4OTRS-Repo
# ---

=item DragAndDrop()

Drag and drop an element

    $SeleniumObject->DragAndDrop(
        Element => '.Element', # css selector of element which should be dragged
        Target  => '.Target',  # css selector of element on which the dragged element should be dropped
    );

=cut

sub DragAndDrop {

    my ( $Self, %Param ) = @_;

    # Value is optional parameter
    for my $Needed (qw(Element Target)) {
        if ( !$Param{$Needed} ) {
            die "Need $Needed";
        }
    }

    my $Element = $Self->find_element( $Param{Element}, 'css' );
    my $Target  = $Self->find_element( $Param{Target},  'css' );

    # Move mouse to from element, drag and drop
    $Self->mouse_move_to_location( element => $Element );

    # Holds the mouse button on the element
    $Self->button_down();

    # Move mouse to the destination
    $Self->mouse_move_to_location(
        element => $Target,
        xoffset => 1,
        yoffset => 1,
    );

    # Release
    $Self->button_up();

    return;
}

=item InputGet()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Get' function.

    my $Result = $SeleniumObject->InputGet(
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

    my $Result = $Self->execute_script("return Core.Form.Znuny4OTRSInput.Get('$Param{Attribute}' $OptionsParameter);");

    return $Result if !IsHashRefWithData( $Result );

    # should be recursive sometimes
    KEY:
    for my $Key ( sort keys %{ $Result } ) {

        my $Value = $Result->{ $Key };

        next KEY if !defined $Value;
        next KEY if ref $Value ne 'JSON::PP::Boolean';


        $Result->{ $Key } = $Value ? 1 : 0;
    }

    return $Result;
}

=item InputSet()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Set' function.

    my $Result = $SeleniumObject->InputSet(
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

    my $Result = $SeleniumObject->InputMandatory(
        Attribute => 'QueueID',
        Mandatory => 1,         # 1 or 0
    );

    $Result = 1;

    # OR return mandatory state:

    my $Result = $SeleniumObject->InputMandatory(
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

    my $Result = $SeleniumObject->InputFieldID(
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

    my $Result = $SeleniumObject->InputType(
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

    my $Result = $SeleniumObject->InputHide(
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

    my $Result = $SeleniumObject->InputShow(
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

    my $Result = $SeleniumObject->InputModule(
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

    my $Result = $SeleniumObject->InputFieldIDMapping(
        Action  => 'AgentTicketZoom',
        Mapping => {
            ...
            QueueID => 'DestQueueID',
            ...
        },
    );

    $Result = 1;

    # OR

    my $Result = $SeleniumObject->InputFieldIDMapping(
        Action  => 'AgentTicketZoom',
    );

    $Result = {
        DestQueueID => 'DestQueueID',
        QueueID     => 'DestQueueID'
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

    my %UserData = $SeleniumObject->AgentLogin(
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

    my $Znuny4OTRSHelper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

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

    my %CustomerUserData = $SeleniumObject->CustomerUserLogin(
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

    my $Znuny4OTRSHelper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

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

    $SeleniumObject->SwitchToPopUp(
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

=item SwitchToMainWindow()

Switches the Selenium conetext to the main window

    $SeleniumObject->SwitchToMainWindow(
        WaitForAJAX => 0, # optional, default 1
    );

=cut

sub SwitchToMainWindow {
    my ( $Self, %Param ) = @_;

    my $Handles = $Self->get_window_handles();
    $Self->switch_to_window( $Handles->[0] );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
    ) {
        return;
    }

    $Self->AJAXCompleted();
}

=item PageContains()

Checks if the currently opened page contains the given String

    $SeleniumObject->PageContains(
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

=item PageContainsNot()

Checks if the currently opened page doesn't contain the given String

    $SeleniumObject->PageContainsNot(
        String  => 'Ticked locked.',
        Message => "Page doesn't contain 'Ticket locked.'" # optional - default
    );
=cut

sub PageContainsNot {
    my ( $Self, %Param ) = @_;

    my $UnitTestMessage = $Param{Message};
    $UnitTestMessage  ||= "Page doesn't contain '$Param{String}'";

    $Self->{UnitTestObject}->False(
        index( $Self->get_page_source(), $Param{String} ) > -1,
        $UnitTestMessage,
    );
}

=item AJAXCompleted()

Waits for AJAX requests to be completed by checking the jQuery 'active' attribute.

    $SeleniumObject->AJAXCompleted();
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

    $SeleniumObject->AgentInterface(
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

=item AgentRequest()

Performs a GET request to a non-JS controller in the AgentInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->AgentRequest(
        Action      => 'CustomerUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );
=cut

sub AgentRequest {
    my ( $Self, %Param ) = @_;

    $Self->_GETRequest(
        Interface => 'Agent',
        Param     => \%Param,
    );
}

=item CustomerInterface()

Performs a GET request to the CustomerInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->CustomerInterface(
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

=item CustomerRequest()

Performs a GET request to a non-JS controller in the CustomerInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->CustomerRequest(
        Action      => 'CustomerUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );
=cut

sub CustomerRequest {
    my ( $Self, %Param ) = @_;

    $Self->_GETRequest(
        Interface => 'Customer',
        Param     => \%Param,
    );
}

=item PublicInterface()

Performs a GET request to the PublicInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->PublicInterface(
        Action      => 'PublicFAQ',
        WaitForAJAX => 0,             # optional, default 1
    );
=cut

sub PublicInterface {
    my ( $Self, %Param ) = @_;

    $Self->_GETInterface(
        Interface   => 'Public',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=item PublicRequest()

Performs a GET request to a non-JS controller in the PublicInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->PublicRequest(
        Action      => 'PublicUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );
=cut

sub PublicRequest {
    my ( $Self, %Param ) = @_;

    $Self->_GETRequest(
        Interface => 'Public',
        Param     => \%Param,
    );
}

=item _GETInterface()

Performs a GET request to the given Interface with the given parameters. Interally VerifiedGet is called.
Request waits till page has finished loading via checking if the jQuery Object has been initialized and
all AJAX requests are compleded via function AJAXCompleted.

    $SeleniumObject->_GETInterface(
        Interface   => 'Agent',           # or Customer or Public
        WaitForAJAX => 0,                 # optional, default 1
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );
=cut
sub _GETInterface {
    my ( $Self, %Param ) = @_;

    my $RequestURL = $Self->RequestURLBuild( %Param );

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

=item _GETRequest()

Performs a GET request to a Request endpoint in the given Interface with the given parameters. Interally Seleniums get is called.

    $SeleniumObject->_GETRequest(
        Interface   => 'Agent',           # or Customer or Public
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );
=cut
sub _GETRequest {
    my ( $Self, %Param ) = @_;

    my $RequestURL = $Self->RequestURLBuild( %Param );

    $Self->get($RequestURL);
}

=item RequestURLBuild()

This function builds a requestable HTTP GET URL to the given OTRS interface with the given parameters

    my $RequestURL = $SeleniumObject->RequestURLBuild(
        Interface   => 'Agent',           # or Customer or Public
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );

    $RequestURL = 'http://localhost/otrs/index.pl?Action=AgentTicketZoom';

=cut

sub RequestURLBuild {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get script alias
    my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

    my %InterfaceMapping = (
        Agent    => 'index',
        Customer => 'customer',
        Public   => 'public',
    );

    my $RequestURL = $ScriptAlias . $InterfaceMapping{ $Param{Interface} } .'.pl';

    return $RequestURL if !IsHashRefWithData( $Param{Param} );

    $RequestURL .= '?';
    $RequestURL .= $Self->_Hash2GETParamString( %{ $Param{Param} } );

    return $RequestURL;
}

=item _Hash2GETParamString()

Converts a Hash into a GET Parameter String, without the leading ?. Inspired by http://stackoverflow.com/a/449204

    my $Result = $SeleniumObject->_Hash2GETParamString(
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

=item SysConfig()

This function sets a permanent entry in the SysConfig via a Perl structure that is available in the Selenium scope.

    my $ConfigString = <<'CONFIG';

$Self->{'Frontend::Module'}->{'Example'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'Loader' => {
    'JavaScript' => [
      'Core.UI.Table.js'
    ]
  },
  'NavBarModule' => {
    'Block' => 'System',
    'Description' => 'View the example.',
    'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
    'Name' => 'Example',
    'Prio' => '500'
  },
  'NavBarName' => 'Admin',
  'Title' => 'Example'
};

CONFIG

    my $Success = $SeleniumObject->SysConfig(
        String => $ConfigString,
    );

=cut

sub SysConfig {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed ( qw(ConfigString) ) {

        next NEEDED if defined $Param{ $Needed };

        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $RestoreSystemConfigurationCheck = IsStringWithData( $Self->{UnitTestObject}->{SysConfigBackup} );
    $Self->{UnitTestObject}->True(
        $RestoreSystemConfigurationCheck,
        "Kernel::System::UnitTest::Helper was initialized with 'RestoreSystemConfiguration'",
    );
    return if !$RestoreSystemConfigurationCheck;

    my $ChangedSysConfig = $Self->{UnitTestObject}->{SysConfigBackup};

    # append
    $ChangedSysConfig =~ s{(\} \s+ 1;\Z)}{$Param{ConfigString}$1}xms;

    $Self->{UnitTestObject}->{SysConfigObject}->Upload( Content => $ChangedSysConfig );

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
