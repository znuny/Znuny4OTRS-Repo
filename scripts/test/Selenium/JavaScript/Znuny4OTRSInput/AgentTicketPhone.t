# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

# get needed objects
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreSystemConfiguration => 1,
    },
);

# get the Znuny4OTRS Selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Znuny4OTRSSelenium');

# store test function in variable so the Selenium object can handle errors/exceptions/dies etc.
my $SeleniumTest = sub {

    # initialize Znuny4OTRS Helpers and other needed objects
    my $Znuny4OTRSHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Znuny4OTRSHelper');
    my $ZnunyHelperObject      = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $RandomID = $Znuny4OTRSHelperObject->GetRandomID();

    # setup a full featured test environment
    my $TestEnvironmentData = $Znuny4OTRSHelperObject->SetupTestEnvironment();

    my %LoaderConfig = (
        AgentTicketPhone => [
            'Core.Form.Znuny4OTRSInput.js',
        ],
    );

    my $LoaderAddSuccess = $ZnunyHelperObject->_LoaderAdd(%LoaderConfig);

    $Self->True(
        $LoaderAddSuccess,
        "Add Core.Form.Znuny4OTRSInput to AgentTicketPhone JS Loader",
    );

    # create test user and login
    my %TestUser = $Selenium->AgentLogin(
        Groups => [ 'admin', 'users' ],
    );

    $Selenium->AgentInterface(
        Action      => 'AgentTicketPhone',
        WaitForAJAX => 0,
    );

    my $CustomerUser = $TestEnvironmentData->{CustomerUser}->[0];

    my $SetCustomerUserID = $Selenium->InputSet(
        Attribute => 'CustomerUserID',
        Content   => $CustomerUser->{UserID},
    );

    $Self->True(
        $SetCustomerUserID,
        "Setting CustomerUserID '$CustomerUser->{UserID}'",
    );

    my $GetCustomerUserID = $Selenium->InputGet(
        Attribute => 'CustomerUserID',
    );

    $Self->Is(
        $GetCustomerUserID->[0],
        $CustomerUser->{UserID},
        "Get CustomerUserID is '$CustomerUser->{UserID}'",
    );

    my $DynamicFieldText    = "DynamicFieldText äöüß%\$'\")(}{? - $RandomID";
    my $SetDynamicFieldText = $Selenium->InputSet(
        Attribute   => 'DynamicField_UnitTestText',
        Content     => $DynamicFieldText,
        WaitForAJAX => 0,
    );

    $Self->True(
        $SetDynamicFieldText,
        "Setting DynamicFieldText '$DynamicFieldText'",
    );

    my $GetDynamicFieldText = $Selenium->InputGet(
        Attribute => 'DynamicField_UnitTestText',
    );

    $Self->Is(
        $GetDynamicFieldText,
        $DynamicFieldText,
        "Get DynamicFieldText is '$DynamicFieldText'",
    );

    my $DynamicFieldCheckbox        = 'true';
    my $SetDynamicFieldCheckboxTrue = $Selenium->InputSet(
        Attribute   => 'DynamicField_UnitTestCheckbox',
        Content     => $DynamicFieldCheckbox,
        WaitForAJAX => 0,
    );

    $Self->True(
        $SetDynamicFieldCheckboxTrue,
        "Setting DynamicFieldCheckbox '$DynamicFieldCheckbox'",
    );

    my $GetDynamicFieldCheckboxTrue = $Selenium->InputGet(
        Attribute => 'DynamicField_UnitTestCheckbox',
    );

    $Self->True(
        $GetDynamicFieldCheckboxTrue,
        "Get DynamicFieldCheckbox is '$DynamicFieldCheckbox'",
    );

    $DynamicFieldCheckbox = 'false';
    my $SetDynamicFieldCheckboxFalse = $Selenium->InputSet(
        Attribute   => 'DynamicField_UnitTestCheckbox',
        Content     => $DynamicFieldCheckbox,
        WaitForAJAX => 0,
    );

    $Self->True(
        $SetDynamicFieldCheckboxFalse,
        "Setting DynamicFieldCheckbox '$DynamicFieldCheckbox'",
    );

    my $GetDynamicFieldCheckboxFalse = $Selenium->InputGet(
        Attribute => 'DynamicField_UnitTestCheckbox',
    );

    $Self->False(
        $GetDynamicFieldCheckboxFalse,
        "Get DynamicFieldCheckbox is '$DynamicFieldCheckbox'",
    );

    my %DynamicFieldDropdownTestData = (
        Key   => 'Key3',
        Value => 'Value3',
    );

    for my $SetType ( sort keys %DynamicFieldDropdownTestData ) {

        my $SetDynamicFieldDropdown = $Selenium->InputSet(
            Attribute => 'DynamicField_UnitTestDropdown',
            Content   => $DynamicFieldDropdownTestData{$SetType},
            Options   => {
                KeyOrValue => $SetType,
                }
        );

        $Self->True(
            $SetDynamicFieldDropdown,
            "Setting DynamicFieldDropdown '$DynamicFieldDropdownTestData{ $SetType }'",
        );

        for my $GetType ( sort keys %DynamicFieldDropdownTestData ) {

            my $GetDynamicFieldDropdown = $Selenium->InputGet(
                Attribute => 'DynamicField_UnitTestDropdown',
                Options   => {
                    KeyOrValue => $GetType,
                    }
            );

            $Self->Is(
                $GetDynamicFieldDropdown,
                $DynamicFieldDropdownTestData{$GetType},
                "Get DynamicFieldDropdown is '$DynamicFieldDropdownTestData{ $GetType }'",
            );
        }
    }

    my $DynamicFieldTextArea    = "DynamicFieldTextArea \n\n\n äöüß%\$'\")(}{? \n\n\n - $RandomID";
    my $SetDynamicFieldTextArea = $Selenium->InputSet(
        Attribute   => 'DynamicField_UnitTestTextArea',
        Content     => $DynamicFieldTextArea,
        WaitForAJAX => 0,
    );

    $Self->True(
        $SetDynamicFieldTextArea,
        "Setting DynamicFieldTextArea '$DynamicFieldTextArea'",
    );

    my $GetDynamicFieldTextArea = $Selenium->InputGet(
        Attribute => 'DynamicField_UnitTestTextArea',
    );

    $Self->Is(
        $GetDynamicFieldTextArea,
        $DynamicFieldTextArea,
        "Get DynamicFieldTextArea is '$DynamicFieldTextArea'",
    );

    my %DynamicFieldMultiSelectTestData = (
        Key   => [ 'Key1',   'Key2' ],
        Value => [ 'Value1', 'Value2' ],
    );

    for my $SetType ( sort keys %DynamicFieldMultiSelectTestData ) {

        my $SetDynamicFieldMultiSelect = $Selenium->InputSet(
            Attribute => 'DynamicField_UnitTestMultiSelect',
            Content   => $DynamicFieldMultiSelectTestData{$SetType},
            Options   => {
                KeyOrValue => $SetType,
                }
        );

        $Self->True(
            $SetDynamicFieldMultiSelect,
            "Setting DynamicFieldMultiSelect '$DynamicFieldMultiSelectTestData{ $SetType }'",
        );

        for my $GetType ( sort keys %DynamicFieldMultiSelectTestData ) {

            my $GetDynamicFieldMultiSelect = $Selenium->InputGet(
                Attribute => 'DynamicField_UnitTestMultiSelect',
                Options   => {
                    KeyOrValue => $GetType,
                    }
            );

            $Self->IsDeeply(
                $GetDynamicFieldMultiSelect,
                $DynamicFieldMultiSelectTestData{$GetType},
                "Get DynamicFieldMultiSelect is '$DynamicFieldMultiSelectTestData{ $GetType }'",
            );
        }
    }

    my $Subject    = "Subject äöüß%\$'\")(}{? - $RandomID";
    my $SetSubject = $Selenium->InputSet(
        Attribute   => 'Subject',
        Content     => $Subject,
        WaitForAJAX => 0,
    );

    $Self->True(
        $SetSubject,
        "Setting Subject '$Subject'",
    );

    my $GetSubject = $Selenium->InputGet(
        Attribute => 'Subject',
    );

    $Self->Is(
        $GetSubject,
        $Subject,
        "Get Subject is '$Subject'",
    );

    my $RichText    = "RichText<br />\n<br />\n<br />\näöüß%\$'\")(}{?<br />\n<br />\n- $RandomID";
    my $SetRichText = $Selenium->InputSet(
        Attribute   => 'RichText',
        Content     => $RichText,
        WaitForAJAX => 0,
    );

    $Self->True(
        $SetRichText,
        "Setting RichText '$RichText'",
    );

    my $GetRichText = $Selenium->InputGet(
        Attribute => 'RichText',
    );

    $Self->Is(
        $GetRichText,
        $RichText,
        "Get RichText is '$RichText'",
    );

    ATTRIBUTE:
    for my $Attribute (qw(Service SLA Type Queue)) {

        next ATTRIBUTE if !IsHashRefWithData( $TestEnvironmentData->{$Attribute} );

        my $JSAttribute = "${Attribute}ID";

        my $FieldID = $Selenium->InputFieldID(
            Attribute => $JSAttribute,
        );
        my $ModernizedFieldID = "${FieldID}_Search";

        $Self->True(
            $FieldID,
            "Found FieldID for $Attribute",
        );

        my $IsDisplayed = $Selenium->find_element( "#$ModernizedFieldID", 'css' )->is_displayed();

        $Self->True(
            $IsDisplayed,
            "$FieldID ($Attribute) is displayed",
        );

        my $HiddenResult = $Selenium->InputHide(
            Attribute => $JSAttribute,
        );

        $Self->True(
            $HiddenResult,
            "$FieldID ($Attribute) is set to hidden",
        );

        $IsDisplayed = $Selenium->find_element( "#$ModernizedFieldID", 'css' )->is_displayed();

        $Self->False(
            $IsDisplayed,
            "$FieldID ($Attribute) InputHide success",
        );

        my $ShowResult = $Selenium->InputShow(
            Attribute => $JSAttribute,
        );

        $Self->True(
            $ShowResult,
            "$FieldID ($Attribute) is set to shown",
        );

        $IsDisplayed = $Selenium->find_element( "#$ModernizedFieldID", 'css' )->is_displayed();

        $Self->True(
            $IsDisplayed,
            "$FieldID ($Attribute) InputShow success",
        );

        for my $AttributeValue ( sort keys %{ $TestEnvironmentData->{$Attribute} } ) {

            my $AttributeKey = $TestEnvironmentData->{$Attribute}->{$AttributeValue};

            my %SetContentMapping = (
                Key   => $AttributeKey,
                Value => $AttributeValue,
            );

            for my $SetType (qw(Key Value)) {

                my $SetValueResult = $Selenium->InputSet(
                    Attribute => $JSAttribute,
                    Content   => $SetContentMapping{$SetType},
                    Options   => {
                        KeyOrValue => $SetType,
                        }
                );

                $Self->True(
                    $SetValueResult,
                    "Set $SetType '$SetContentMapping{$SetType}' for $FieldID ($Attribute)",
                );

                my $GetKeyResult = $Selenium->InputGet(
                    Attribute => $JSAttribute,
                );

                $Self->Is(
                    $GetKeyResult,
                    $AttributeKey,
                    "Get key '$AttributeKey' for $FieldID ($Attribute)",
                );

                my $GetValueResult = $Selenium->InputGet(
                    Attribute => $JSAttribute,
                    Options   => {
                        KeyOrValue => 'Value',
                        }
                );

                $Self->Is(
                    $GetValueResult,
                    $AttributeValue,
                    "Get value '$AttributeValue' for $FieldID ($Attribute)",
                );
            }
        }
    }
};

# finally run the test(s) in the browser
$Selenium->RunTest($SeleniumTest);

1;
