# --
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 80c9a107bc2a5e197466b5efdbdfdeacc3484922 - Kernel/System/UnitTest/Selenium.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Selenium;

use strict;
use warnings;

use MIME::Base64();
use File::Path();
use File::Temp();
use Time::HiRes();

use Kernel::Config;
use Kernel::System::User;
use Kernel::System::UnitTest::Helper;
# ---
# Znuny4OTRS-Repo
# ---
use utf8;
use URI::Escape;
use Kernel::System::VariableCheck qw(:all);
# ---

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AuthSession',
    'Kernel::System::Log',
    'Kernel::System::Main',
# ---
# Znuny4OTRS-Repo
# ---
#     'Kernel::System::DateTime',
#     'Kernel::System::UnitTest::Driver',
    'Kernel::System::JSON',
# ---
    'Kernel::System::UnitTest::Helper',
);

=head1 NAME

Kernel::System::UnitTest::Selenium - run front end tests

This class inherits from Selenium::Remote::Driver. You can use
its full API (see
L<http://search.cpan.org/~aivaturi/Selenium-Remote-Driver-0.15/lib/Selenium/Remote/Driver.pm>).

Every successful Selenium command will be logged as a successful unit test.
In case of an error, an exception will be thrown that you can catch in your
unit test file and handle with C<HandleError()> in this class. It will output
a failing test result and generate a screen shot for analysis.

=head2 new()

create a selenium object to run front end tests.

To do this, you need a running C<selenium> or C<phantomjs> server.

Specify the connection details in C<Config.pm>, like this:

    # For testing with Firefox until v. 47 (testing with recent FF and marionette is currently not supported):
    $Self->{'SeleniumTestsConfig'} = {
        remote_server_addr  => 'localhost',
        port                => '4444',
        platform            => 'ANY',
        browser_name        => 'firefox',
        extra_capabilities => {
            marionette     => \0,   # Required to run FF 47 or older on Selenium 3+.
        },
    };

    # For testing with Chrome/Chromium (requires installed geckodriver):
    $Self->{'SeleniumTestsConfig'} = {
        remote_server_addr  => 'localhost',
        port                => '4444',
        platform            => 'ANY',
        browser_name        => 'chrome',
        extra_capabilities => {
            chromeOptions => {
                # disable-infobars makes sure window size calculations are ok
                args => [ "disable-infobars" ],
            },
        },
    };

Then you can use the full API of L<Selenium::Remote::Driver> on this object.

=cut

sub new {
    my ( $Class, %Param ) = @_;

# ---
# Znuny4OTRS-Repo
# ---
#     $Param{UnitTestDriverObject} ||= $Kernel::OM->Get('Kernel::System::UnitTest::Driver');
    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    $Param{UnitTestDriverObject} ||= $HelperObject->UnitTestObjectGet();
# ---

    $Param{UnitTestDriverObject}->True( 1, "Starting up Selenium scenario..." );

    my %SeleniumTestsConfig = %{ $Kernel::OM->Get('Kernel::Config')->Get('SeleniumTestsConfig') // {} };

    if ( !%SeleniumTestsConfig ) {
        my $Self = bless {}, $Class;
        $Self->{UnitTestDriverObject} = $Param{UnitTestDriverObject};
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
    $Self->{UnitTestDriverObject} = $Param{UnitTestDriverObject};
    $Self->{SeleniumTestsActive}  = 1;

    #$Self->debug_on();

    # set screen size from config or use defauls
    my $Height = $SeleniumTestsConfig{window_height} || 1200;
    my $Width  = $SeleniumTestsConfig{window_width}  || 1400;

    $Self->set_window_size( $Height, $Width );

    $Self->{BaseURL} = $Kernel::OM->Get('Kernel::Config')->Get('HttpType') . '://';
    $Self->{BaseURL} .= Kernel::System::UnitTest::Helper->GetTestHTTPHostname();

    # Remember the start system time for the selenium test run.
    $Self->{TestStartSystemTime} = time;    ## no critic

    return $Self;
}

=head2 RunTest()

runs a selenium test if Selenium testing is configured and performs proper
error handling (calls C<HandleError()> if needed).

    $SeleniumObject->RunTest( sub { ... } );

=cut

sub RunTest {
    my ( $Self, $Test ) = @_;

    if ( !$Self->{SeleniumTestsActive} ) {
        $Self->{UnitTestDriverObject}->True( 1, 'Selenium testing is not active, skipping tests.' );
        return 1;
    }

    eval {
        $Test->();
    };
    $Self->HandleError($@) if $@;

    return 1;
}

=begin Internal:

=head2 _execute_command()

Override internal command of base class.

We use it to output successful command runs to the UnitTest object.
Errors will cause an exeption and be caught elsewhere.

=end Internal:

=cut

sub _execute_command {    ## no critic
    my ( $Self, $Res, $Params ) = @_;

    my $Result = $Self->SUPER::_execute_command( $Res, $Params );

    my $TestName = 'Selenium command success: ';
    $TestName .= $Kernel::OM->Get('Kernel::System::Main')->Dump(
        {
            %{ $Res    || {} },    ## no critic
            %{ $Params || {} },    ## no critic
        }
    );

    if ( $Self->{SuppressCommandRecording} ) {
        print $TestName;
    }
    else {
        $Self->{UnitTestDriverObject}->True( 1, $TestName );
    }

    return $Result;
}

=head2 get()

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

=head2 get_alert_text()

Override get_alert_text() method of base class to return alert text as string.

    my $AlertText = $SeleniumObject->get_alert_text();

returns

    my $AlertText = 'Some alert text!'

=cut

sub get_alert_text {    ## no critic
    my ($Self) = @_;

    my $AlertText = $Self->SUPER::get_alert_text();

    die "Alert dialog is not present" if ref $AlertText eq 'HASH';    # Chrome returns HASH when there is no alert text.

    return $AlertText;
}

=head2 VerifiedGet()

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
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
    ) || die "OTRS API verification failed after page load.";

    return;
}

=head2 VerifiedRefresh()

perform a refresh() call, but wait for the page to be fully loaded (works only within OTRS).
Will die() if the verification fails.

    $SeleniumObject->VerifiedRefresh();

=cut

sub VerifiedRefresh {
    my ( $Self, $URL ) = @_;

    $Self->refresh();

    $Self->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
    ) || die "OTRS API verification failed after page load.";

    return;
}

=head2 Login()

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

    $Self->{UnitTestDriverObject}->True( 1, 'Initiating login...' );

    # we will try several times to log in
    my $MaxTries = 5;

    TRY:
    for my $Try ( 1 .. $MaxTries ) {

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

            $Self->{UnitTestDriverObject}->True( 1, 'Login sequence ended...' );
        };

        # an error happend
        if ($@) {

            $Self->{UnitTestDriverObject}->True( 1, "Login attempt $Try of $MaxTries not successful." );

            # try again
            next TRY if $Try < $MaxTries;

            # log error
            $Self->HandleError($@);
            die "Login failed!";
        }

        # login was sucessful
        else {
            last TRY;
        }
    }

    return 1;
}

=head2 WaitFor()

wait with increasing sleep intervals until the given condition is true or the wait time is over.
Exactly one condition (JavaScript or WindowCount) must be specified.

    my $Success = $SeleniumObject->WaitFor(
        JavaScript   => 'return $(".someclass").length',   # Javascript code that checks condition
        AlertPresent => 1,                                 # Wait until an alert, confirm or prompt dialog is present
        WindowCount  => 2,                                 # Wait until this many windows are open
        Callback     => sub { ... }                        # Wait until function returns true
        Time         => 20,                                # optional, wait time in seconds (default 20)
    );

=cut

sub WaitFor {
    my ( $Self, %Param ) = @_;

    if ( !$Param{JavaScript} && !$Param{WindowCount} && !$Param{AlertPresent} && !$Param{Callback} ) {
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
        elsif ( $Param{Callback} ) {
            return 1 if $Param{Callback}->();
        }
        Time::HiRes::sleep($Interval);
        $WaitedSeconds += $Interval;
        $Interval += 0.1;
    }

    my $Argument = '';
    for my $Key (qw(JavaScript WindowCount AlertPresent)) {
        $Argument = "$Key => $Param{$Key}" if $Param{$Key};
    }
    $Argument = "Callback" if $Param{Callback};

    die "WaitFor($Argument) failed.";
}

=head2 DragAndDrop()

Drag and drop an element.

    $SeleniumObject->DragAndDrop(
        Element         => '.Element', # (required) css selector of element which should be dragged
        Target          => '.Target',  # (required) css selector of element on which the dragged element should be dropped
        TargetOffset    => {           # (optional) Offset for target. If not specified, the mouse will move to the middle of the element.
            X   => 150,
            Y   => 100,
        }
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

    my %TargetOffset;
    if ( $Param{TargetOffset} ) {
        %TargetOffset = (
            xoffset => $Param{TargetOffset}->{X} || 0,
            yoffset => $Param{TargetOffset}->{Y} || 0,
        );
    }

    # Make sure Element is visible
    $Self->WaitFor(
        JavaScript => 'return typeof($) === "function" && $(\'' . $Param{Element} . ':visible\').length;',
    );
    my $Element = $Self->find_element( $Param{Element}, 'css' );

    # Move mouse to from element, drag and drop
    $Self->mouse_move_to_location( element => $Element );

    # Holds the mouse button on the element
    $Self->button_down();

    # Make sure Target is visible
    $Self->WaitFor(
        JavaScript => 'return typeof($) === "function" && $(\'' . $Param{Target} . ':visible\').length;',
    );
    my $Target = $Self->find_element( $Param{Target}, 'css' );

    # Move mouse to the destination
    $Self->mouse_move_to_location(
        element => $Target,
        %TargetOffset,
    );

    # Release
    $Self->button_up();

    return;
}

=head2 HandleError()

use this method to handle any Selenium exceptions.

    $SeleniumObject->HandleError($@);

It will create a failing test result and store a screen shot of the page
for analysis (in folder /var/otrs-unittest if it exists, in $Home/var/httpd/htdocs otherwise).

=cut

sub HandleError {
    my ( $Self, $Error ) = @_;

    $Self->{UnitTestDriverObject}->False( 1, "Exception in Selenium': $Error" );

    #eval {
    my $Data = $Self->screenshot();
    return if !$Data;
    $Data = MIME::Base64::decode_base64($Data);

    #
    # Store screenshots in a local folder from where they can be opened directly in the browser.
    #
    my $LocalScreenshotDir = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/httpd/htdocs/SeleniumScreenshots';
    mkdir $LocalScreenshotDir || return $Self->False( 1, "Could not create $LocalScreenshotDir." );

    my $DateTimeObj = $Kernel::OM->Create('Kernel::System::DateTime');
    my $Filename    = $DateTimeObj->ToString();
    $Filename .= '-' . ( int rand 100_000_000 ) . '.png';
    $Filename =~ s{[ :]}{-}smxg;

    my $HttpType = $Kernel::OM->Get('Kernel::Config')->Get('HttpType');
    my $Hostname = $Kernel::OM->Get('Kernel::System::UnitTest::Helper')->GetTestHTTPHostname();
    my $URL      = "$HttpType://$Hostname/"
        . $Kernel::OM->Get('Kernel::Config')->Get('Frontend::WebPath')
        . "SeleniumScreenshots/$Filename";

    $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
        Directory => $LocalScreenshotDir,
        Filename  => $Filename,
        Content   => \$Data,
    ) || return $Self->False( 1, "Could not write file $LocalScreenshotDir/$Filename" );

    #
    # If a shared screenshot folder is present, then we also store the screenshot there for external use.
    #
    if ( -d '/var/otrs-unittest/' ) {

        my $SharedScreenshotDir = '/var/otrs-unittest/SeleniumScreenshots';
        mkdir $SharedScreenshotDir || return $Self->False( 1, "Could not create $SharedScreenshotDir." );

        $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
            Directory => $SharedScreenshotDir,
            Filename  => $Filename,
            Content   => \$Data,
            )
            || return $Self->{UnitTestDriverObject}->False( 1, "Could not write file $SharedScreenshotDir/$Filename" );
    }

    $Self->{UnitTestDriverObject}->False( 1, "Saved screenshot in $URL" );
    $Self->{UnitTestDriverObject}->AttachSeleniumScreenshot(
        Filename => $Filename,
        Content  => $Data
    );

    return;
}

=head2 DEMOLISH()

override DEMOLISH from L<Selenium::Remote::Driver> (required because this class is managed by L<Moo>).
Adds a unit test result to indicate the shutdown, and performs some clean-ups.

=cut

sub DEMOLISH {
    my $Self = shift;

    # Could be missing on early die.
    if ( $Self->{UnitTestDriverObject} ) {
        $Self->{UnitTestDriverObject}->True( 1, "Shutting down Selenium scenario." );
    }

    if ( $Self->{SeleniumTestsActive} ) {
        $Self->SUPER::DEMOLISH(@_);

        # Cleanup possibly leftover zombie firefox profiles.
        my @LeftoverFirefoxProfiles = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
            Directory => '/tmp/',
            Filter    => 'anonymous*webdriver-profile',
        );

        for my $LeftoverFirefoxProfile (@LeftoverFirefoxProfiles) {
            if ( -d $LeftoverFirefoxProfile ) {
                File::Path::remove_tree($LeftoverFirefoxProfile);
            }
        }

        # Cleanup all sessions, which was created after the selenium test start time.
        my $AuthSessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

        my @Sessions = $AuthSessionObject->GetAllSessionIDs();

        SESSION:
        for my $SessionID (@Sessions) {

            my %SessionData = $AuthSessionObject->GetSessionIDData( SessionID => $SessionID );

            next SESSION if !%SessionData;
            next SESSION
                if $SessionData{UserSessionStart} && $SessionData{UserSessionStart} < $Self->{TestStartSystemTime};

            $AuthSessionObject->RemoveSessionID( SessionID => $SessionID );
        }
    }

    return;
}

# ---
# Znuny4OTRS-Repo
# ---

=head2 InputGet()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Get' function.

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

=head2 InputSet()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Set' function.

    my $Result = $SeleniumObject->InputSet(
        Attribute   => 'QueueID',
        WaitForAJAX => 0,                       # optional, default 1
        Content     => 'Misc',                  # optional, none removes content
        Options     => {                        # optional
            KeyOrValue    => 'Value',           # default is 'Key'
            TriggerChange => 0,                 # default is 1
        }
    );

!!!! ATTENTION !!!!
For setting DynamicField Date or DateTime Fields the call should look like:

    my $Result = $SeleniumObject->InputSet(
        Attribute => 'DynamicField_NameOfYourDateOrDateTimeField',
        Content   => {
            Year   => '2016',
            Month  => '08',
            Day    => '30',
            Hour   => '00',
            Minute => '00',
            Second => '00',
            Used   => 1, # THIS ONE IS IMPORTANT -
                       # if not set to 1 field will not get activated and though not transmitted
        },
        WaitForAJAX => 1,
        Options     => {
            TriggerChange => 1,
        }
    );

For Checkboxes the call has to be done with undef,
everything else like '0', 0,... will fail. Example:

    my $Result = $SeleniumObject->InputSet(
        Attribute   => 'DynamicField_ExampleCheckbox',
        WaitForAJAX => 0,                       # optional, default 1
        Content     => undef,                   # optional, none removes content
        Options     => {                        # optional
            TriggerChange => 1,                 # default is 1
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

=head2 InputMandatory()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Mandatory' function.
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

=head2 InputFieldID()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'FieldID' function.

    my $Result = $SeleniumObject->InputFieldID(
        Attribute => 'QueueID',
    );

    $Result = 'Dest';

=cut

sub InputFieldID {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.FieldID('$Param{Attribute}');");
}

=head2 InputType()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Type' function.
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

=head2 InputHide()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Hide' function.

    my $Result = $SeleniumObject->InputHide(
        Attribute => 'QueueID',
    );

    $Result = 1;

=cut

sub InputHide {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Hide('$Param{Attribute}');");
}

=head2 InputExists()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Exists' function.

    my $Result = $SeleniumObject->InputExists(
        Attribute => 'QueueID',
    );

    $Result = 1;

=cut

sub InputExists {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Exists('$Param{Attribute}');");
}

=head2 InputShow()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Show' function.

    my $Result = $SeleniumObject->InputShow(
        Attribute => 'QueueID',
    );

    $Result = 1;

=cut

sub InputShow {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Show('$Param{Attribute}');");
}

=head2 InputModule()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'Module' function.

    my $Result = $SeleniumObject->InputModule(
        Action => 'QueueID',
    );

    $Result = 1;

=cut

sub InputModule {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Module('$Param{Action}');");
}

=head2 InputFieldIDMapping()

Wrapper for the Core.Form.Znuny4OTRSInput JavaScript namespace 'FieldIDMapping' function.
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

=head2 AgentLogin()

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
    };

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

=head2 CustomerUserLogin()

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
    };

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


=head2 SwitchToPopUp()

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
    $Self->WaitFor( JavaScript => 'return typeof($) === "function" && ($(".CancelClosePopup").length || $(".UndoClosePopup").length)' );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
    ) {
        return;
    }

    $Self->AJAXCompleted();
    return;
}

=head2 SwitchToMainWindow()

Switches the Selenium context to the main window

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
    return;
}

=head2 PageContains()

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

    $Self->{UnitTestDriverObject}->True(
        index( $Self->get_page_source(), $Param{String} ) > -1,
        $UnitTestMessage,
    );
    return;
}

=head2 PageContainsNot()

Checks if the currently opened page does not contain the given String

    $SeleniumObject->PageContainsNot(
        String  => 'Ticked locked.',
        Message => "Page does not contain 'Ticket locked.'" # optional - default
    );

=cut

sub PageContainsNot {
    my ( $Self, %Param ) = @_;

    my $UnitTestMessage = $Param{Message};
    $UnitTestMessage  ||= "Page does not contain '$Param{String}'";

    $Self->{UnitTestDriverObject}->False(
        index( $Self->get_page_source(), $Param{String} ) > -1,
        $UnitTestMessage,
    );
    return;
}

=head2 AJAXCompleted()

Waits for AJAX requests to be completed by checking the jQuery 'active' attribute.

    $SeleniumObject->AJAXCompleted();

=cut

sub AJAXCompleted {
    my ( $Self, %Param ) = @_;

    my $AJAXStartedLoading = $Self->WaitFor( JavaScript => 'return jQuery.active' );
    $Self->{UnitTestDriverObject}->True(
        $AJAXStartedLoading,
        'AJAX requests started loading.'
    );

    my $AJAXCompletedLoading = $Self->WaitFor( JavaScript => 'return jQuery.active == 0' );
    $Self->{UnitTestDriverObject}->True(
        $AJAXCompletedLoading,
        'AJAX requests have finished loading.'
    );
    return;
}

=head2 AgentInterface()

Performs a GET request to the AgentInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->AgentInterface(
        Action      => 'AgentTicketZoom',
        WaitForAJAX => 0,                     # optional, default 1
    );

=cut

sub AgentInterface {
    my ( $Self, %Param ) = @_;

    return $Self->_GETInterface(
        Interface   => 'Agent',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=head2 AgentRequest()

Performs a GET request to a non-JavaScript controller in the AgentInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->AgentRequest(
        Action      => 'CustomerUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );

=cut

sub AgentRequest {
    my ( $Self, %Param ) = @_;

    return $Self->_GETRequest(
        Interface => 'Agent',
        Param     => \%Param,
    );
}

=head2 CustomerInterface()

Performs a GET request to the CustomerInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->CustomerInterface(
        Action      => 'CustomerTicketMessage',
        WaitForAJAX => 0,                      # optional, default 1
    );

=cut

sub CustomerInterface {
    my ( $Self, %Param ) = @_;

    return $Self->_GETInterface(
        Interface   => 'Customer',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=head2 CustomerRequest()

Performs a GET request to a non-JavaScript controller in the CustomerInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->CustomerRequest(
        Action      => 'CustomerUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );

=cut

sub CustomerRequest {
    my ( $Self, %Param ) = @_;

    return $Self->_GETRequest(
        Interface => 'Customer',
        Param     => \%Param,
    );
}

=head2 PublicInterface()

Performs a GET request to the PublicInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->PublicInterface(
        Action      => 'PublicFAQ',
        WaitForAJAX => 0,             # optional, default 1
    );

=cut

sub PublicInterface {
    my ( $Self, %Param ) = @_;

    return $Self->_GETInterface(
        Interface   => 'Public',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=head2 PublicRequest()

Performs a GET request to a non-JavaScript controller in the PublicInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->PublicRequest(
        Action      => 'PublicUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );

=cut

sub PublicRequest {
    my ( $Self, %Param ) = @_;

    return $Self->_GETRequest(
        Interface => 'Public',
        Param     => \%Param,
    );
}

=head2 _GETInterface()

Performs a GET request to the given Interface with the given parameters. Interally VerifiedGet is called.
Request waits till page has finished loading via checking if the jQuery Object has been initialized and
all AJAX requests are completed via function AJAXCompleted.

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
    $Self->{UnitTestDriverObject}->True(
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
    return;
}

=head2 _GETRequest()

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

    return $Self->get($RequestURL);
}

=head2 RequestURLBuild()

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

=head2 _Hash2GETParamString()

Converts a Hash into a GET Parameter String, without the leading ?. Inspired by http://stackoverflow.com/a/449204

    my $Result = $SeleniumObject->_Hash2GETParamString(
        Action   => 'AgentTicketZoom',
        TicketID => 1,
    );

    my $Result = $SeleniumObject->_Hash2GETParamString(
        Action   => 'AgentTicketZoom',
        TicketID => \@TicketIDs,
    );

    $Result = 'Action=AgentTicketZoom;TicketID=1';

=cut

sub _Hash2GETParamString {
    my ( $Self, %Param ) = @_;
    my @Pairs;

    for my $Key (sort keys %Param) {

        if ( !IsArrayRefWithData( $Param{$Key} ) ) {
            $Param{$Key} = [ $Param{$Key} ];
        }

        for my $Value ( @{$Param{$Key}} ) {
            push @Pairs, join '=', map { uri_escape($_) } $Key, $Value;
        }
    }
    return join ';', @Pairs;
}

=head2 FindElementSave()

This function is a wrapper around the 'find_element' function which can be used to check if elements are even present.

    my $Element = $SeleniumObject->FindElementSave(
        Selector     => '#GroupID',
        SelectorType => 'css',        # optional
    );

    is equivalent to:

    $Element = $Self->find_element('#GroupID', 'css');

=cut

sub FindElementSave {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed ( qw(Selector) ) {

        next NEEDED if defined $Param{ $Needed };

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{SelectorType} ||= 'css';

    my $Element;
    eval {
        $Element = $Self->find_element($Param{Selector}, $Param{SelectorType});
    };

    return $Element;
}

=head2 ElementExists()

This function checks if a given element exists.

    $SeleniumObject->ElementExists(
        Selector     => '#GroupID',
        SelectorType => 'css',        # optional
    );

=cut

sub ElementExists {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed ( qw(Selector) ) {

        next NEEDED if defined $Param{ $Needed };

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{Message} ||= "Element '$Param{Selector}' exists.";

    my $Element = $Self->FindElementSave( %Param );

    return $Self->{UnitTestDriverObject}->True(
        $Element,
        $Param{Message},
    );
}

=head2 ElementExistsNot()

This function checks if a given element does not exist.

    $SeleniumObject->ElementExistsNot(
        Selector     => '#GroupID',
        SelectorType => 'css',        # optional
    );

=cut

sub ElementExistsNot {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed ( qw(Selector) ) {

        next NEEDED if defined $Param{ $Needed };

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{Message} ||= "Element '$Param{Selector}' does not exist.";

    my $Element = $Self->FindElementSave( %Param );

    return $Self->{UnitTestDriverObject}->False(
        $Element,
        $Param{Message},
    );
}

sub _CaptureScreenshot {
    my ($Self, $Hook, $Function) = @_;

    # extract caller information:
    # - Package for checking direct calls and early exit
    # - Line of function call to be used in filename
    my ($CallingPackage, $CallerFilename, $TestLine) = caller(1);
    return if $CallingPackage ne 'Kernel::System::UnitTest';

    # taking a screenshot after the SeleniumObject
    # is destroyed is not possible
    if (
        $Function eq 'DESTROY'
        && $Hook eq 'AFTER'
    ) {
        return;
    }

    # lat object initialization for performance reasons
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');

    # someone might want to enable local screenshots only if needed?
    return if $ConfigObject->Get('SeleniumTestsConfig')->{DisableScreenshots};

    # trying to extract the name of the test file right from the UnitTestObject
    # kind of hacky but there is no other place where to get this information
    my $TestFile = 'UnknownTestFile';
    if ($Self->{UnitTestDriverObject}->{TestFile} =~ m{scripts\/test\/(.+?)\.t$}) {
        $TestFile = $1;
        # make folder path a filename
        $TestFile =~ s{\/}{_}g;
    }

    # build filename to be most reasonable and easy to follow like e.g.:
    # Znuny4OTRSRepo_Selenium_Input-Line 359-InputFieldID-1497085163-BEFORE.png
    my $SystemTime = $DateTimeObject->ToEpoch();
    my $Filename   = "$TestFile-Line $TestLine-$Function-$SystemTime-$Hook.png";
    # use CI project directory so the CI env can collect the artifacts afterwards
    # fallback to the tmp directory in local environments
    my $TargetFolder = $ENV{CI_PROJECT_DIR} || $ConfigObject->Get('Home') . '/var/tmp';
    my $FilePath     = $TargetFolder . '/' . $Filename;

    # finally take the screenshot via the Selenium API
    # and store it in to the build file path
    $Self->capture_screenshot($FilePath);

    return 1;
}

# strongly inspired by: https://stackoverflow.com/a/2663723/7900866
#
if ($ENV{SELENIUM_SCREENSHOTS}) {
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my @FunctionBlacklist = ('_CaptureScreenshot', 'RunTest', 'AJAXCompleted', 'Dumper');

    my @FunctionWhitelist = map { ## no critic
        s/^\s+//;  # strip leading spaces
        s/\s+$//;  # strip trailing spaces
        $_         # return the modified string
    } split(',', $ENV{SELENIUM_SCREENSHOTS_FUNCTIONS} || '');

    # wonder if we can get away without 'no strict'? Hate doing that!
    no strict; ## no critic
    no warnings; ## no critic

    # iterate over symbol table of the package
    FUNCTION:
    for my $FunctionName (sort keys %Kernel::System::UnitTest::Selenium::) {

        # only subroutines needed
        next FUNCTION if !defined *{$Kernel::System::UnitTest::Selenium::{$FunctionName}}{CODE};

        # skip blacklisted functions
        next FUNCTION if grep { $FunctionName eq $_ } @FunctionBlacklist;

        # capture all if the full monty is requested
        if (@FunctionWhitelist) {
            # skip if whitelist is defined but function not whitelisted
            next FUNCTION if !grep {$FunctionName eq $_} @FunctionWhitelist;
        }

        # skip internal and imported functions
        next FUNCTION if $FunctionName =~ /^_/;
        next FUNCTION if $FunctionName !~ /^[[:upper:]]/;
        next FUNCTION if $FunctionName =~ /^Is[[:upper:]]/;

        # build full and backup function name
        my $FullName   = "Kernel::System::UnitTest::Selenium::$FunctionName";
        my $BackupName = "Kernel::System::UnitTest::Selenium::___OLD_$FunctionName";

        # save original sub reference
        *{$BackupName} = \&{$FullName};
        # overwrite original with screenshot hook version
        *{$FullName} = sub {
            # take screenshot before the original function gets executed
            _CaptureScreenshot($_[0], 'BEFORE', $FunctionName);

            # call the original function and store
            # the response in the matching variable type
            my $Result;
            if (wantarray) {
                $Result = [ &{$BackupName}(@_) ];
            } else {
                $Result = &{$BackupName}(@_);
            }
            # take screenshot before the original function gets executed
            _CaptureScreenshot($_[0], 'AFTER', $FunctionName);

            # return whatever was expected to get returned
            return (wantarray && ref $Result eq 'ARRAY')
                ? @$Result : $Result;
        };
    }
    use strict;
    use warnings;
}
# ---


1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
