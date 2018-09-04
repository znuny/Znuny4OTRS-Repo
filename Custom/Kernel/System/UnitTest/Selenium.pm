# --
# Copyright (C) 2001-2018 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - cab4d630be0ff58f47cf2dfa2281020ad23cd0db - Kernel/System/UnitTest/Selenium.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
# ---
# Znuny4OTRS-Repo
# ---
# nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::STDERRCheck)
# ---

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
    'Kernel::System::Time',
# ---
# Znuny4OTRS-Repo
# ---
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

=over 4

=cut

=item new()

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
    $Self->{TestStartSystemTime} = $Kernel::OM->Get('Kernel::System::Time')->SystemTime();

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
        $Self->{UnitTestDriverObject}->True( 1, 'Selenium testing is not active, skipping tests.' );
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
        $Self->{UnitTestDriverObject}->True( 1, $TestName );
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

=item get_alert_text()

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
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
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
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
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

=item WaitFor()

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
    return;
}

=item DragAndDrop()

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

=item HandleError()

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

    my $Filename = $Kernel::OM->Get('Kernel::System::Time')->CurrentTimestamp();
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
}

# ---
# Znuny4OTRS-Repo
# ---
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

=item InputExists()

Wrapper for the Core.Form.Znuny4OTRSInput JS namespace 'Exists' function.

    my $Result = $SeleniumObject->InputExists(
        Attribute => 'QueueID',
    );

    $Result = 1;
=cut

sub InputExists {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Core.Form.Znuny4OTRSInput.Exists('$Param{Attribute}');");
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

    $Self->{UnitTestDriverObject}->True(
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

    $Self->{UnitTestDriverObject}->False(
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
# ---
# Znuny4OTRS-Repo
# ---
    # The idea of this improvement is the following problem case:
    # A InputSet of the Znuny4OTRSInput in a selenium test does trigger an ajax request
    # which is completed too fast for the "WaitFor" check above. So the "WaitFor" check jQuery.active
    # is not set to true and will crash the test completly. In these cases we want to disable
    # the die and the following checks and hope that the ajax request is done successfully.
    if (!$AJAXStartedLoading) {
        print STDERR "NOTICE: SeleniumHelper->AJAXCompleted -> jQuery.active check is disabled and failed\n";
        return 1;
    }
# ---

    $Self->{UnitTestDriverObject}->True(
        $AJAXStartedLoading,
        'AJAX requests started loading.'
    );

    my $AJAXCompletedLoading = $Self->WaitFor( JavaScript => 'return jQuery.active == 0' );
    $Self->{UnitTestDriverObject}->True(
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

    my $Result = $SeleniumObject->_Hash2GETParamString(
        Action   => 'AgentTicketZoom',
        TicketID => \@TicketIDs,
    );

    $Result = 'Action=AgentTicketZoom;TicketID=1'
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

=item FindElementSave()

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

=item ElementExists()

This function checks if a given element exisits.

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

=item ElementExistsNot()

This function checks if a given element doesn't exisit.

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
    $Param{Message} ||= "Element '$Param{Selector}' doesn't exist.";

    my $Element = $Self->FindElementSave( %Param );

    return $Self->{UnitTestDriverObject}->False(
        $Element,
        $Param{Message},
    );
}

=item SysConfig()

DEPRECATED!!!! So yound and already dead :(

Please use Kernel::System::UnitTest::Helper->ConfigSettingChange instead!

=cut

sub SysConfig {
    my ( $Self, %Param ) = @_;
    die "DEPRECATED! Please use Kernel::System::UnitTest::Helper->ConfigSettingChange instead!\n";
}

# ---

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
