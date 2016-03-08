# --
# Znuny4OTRSRepo.t
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed objects
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

# Tests for _ItemReverseListGet function
my $ResultItemReverseListGet = $ZnunyHelperObject->_ItemReverseListGet(
    'test', ( 'Test' => 1 )
);

$Self->True(
    $ResultItemReverseListGet,
    'Test basic function call of _ItemReverseListGet()',
);

# Tests for _EventAdd function
my $ResultEventAdd = $ZnunyHelperObject->_EventAdd(
    Object => 'Ticket',
    Event  => [
        'Znuny4OTRSRepoEvent1',
        'Znuny4OTRSRepoEvent2',
    ]
);

$Self->True(
    $ResultEventAdd,
    'Test basic function call of _EventAdd()',
);

# Tests for _EventRemove function
my $ResultEventRemove = $ZnunyHelperObject->_EventRemove(
    Object => 'Ticket',
    Event  => [
        'Znuny4OTRSRepoEvent1',
        'Znuny4OTRSRepoEvent2',
    ]
);

$Self->True(
    $ResultEventRemove,
    'Test basic function call of _EventRemove()',
);

# Tests for _LoaderAdd function
my $ResultLoaderAdd = $ZnunyHelperObject->_LoaderAdd(
    'AgentTicketPhone' => [
        'Core.Agent.Test.css',
        'Core.Agent.Test.js'
    ],
);

$Self->True(
    $ResultLoaderAdd,
    'Test basic function call of _LoaderAdd()',
);

# Tests for _LoaderRemove function
my $ResultLoaderRemove = $ZnunyHelperObject->_LoaderRemove(
    'AgentTicketPhone' => [
        'Core.Agent.Test.css',
        'Core.Agent.Test.js'
    ],
);

$Self->True(
    $ResultLoaderRemove,
    'Test basic function call of _LoaderRemove()',
);

# Tests for _DynamicFieldsScreenEnable function
my $ResultDynamicFieldsScreenEnable = $ZnunyHelperObject->_DynamicFieldsScreenEnable(
    'AgentTicketFreeText' => {
        'TestDynamicField1' => 1,
        'TestDynamicField2' => 1,
        }
);

$Self->True(
    $ResultDynamicFieldsScreenEnable,
    'Test basic function call of _DynamicFieldsScreenEnable()',
);

# Tests for _DynamicFieldsScreenDisable function
my $ResultDynamicFieldsScreenDisable = $ZnunyHelperObject->_DynamicFieldsScreenDisable(
    'AgentTicketFreeText' => {
        'TestDynamicField1' => 1,
        'TestDynamicField2' => 1,
        }
);

$Self->True(
    $ResultDynamicFieldsScreenDisable,
    'Test basic function call of _DynamicFieldsScreenDisable()',
);

# Tests for _DynamicFieldsCreateIfNotExists function
my $ResultDynamicFieldsCreateIfNotExists = $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
    {
        Name       => 'TestDynamicField1',
        Label      => "TestDynamicField1",
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
);

$Self->True(
    $ResultDynamicFieldsCreateIfNotExists,
    'Test basic function call of _DynamicFieldsCreateIfNotExists()',
);

# Tests for _DynamicFieldsDisable function
my $ResultDynamicFieldsDisable = $ZnunyHelperObject->_DynamicFieldsDisable(
    'TestDynamicField1',
);

$Self->True(
    $ResultDynamicFieldsDisable,
    'Test basic function call of _DynamicFieldsDisable()',
);

# Tests for _DynamicFieldsDelete function
my $ResultDynamicFieldsDelete = $ZnunyHelperObject->_DynamicFieldsDelete(
    'TestDynamicField1',
);

$Self->True(
    $ResultDynamicFieldsDelete,
    'Test basic function call of _DynamicFieldsDelete()',
);

# Tests for _GroupCreateIfNotExists function
my $ResultGroupCreateIfNotExists = $ZnunyHelperObject->_GroupCreateIfNotExists(
    Name => 'Some Group Name',
);

$Self->True(
    $ResultGroupCreateIfNotExists,
    'Test basic function call of _GroupCreateIfNotExists()',
);

# Tests for _RoleCreateIfNotExists function
my $ResultRoleCreateIfNotExists = $ZnunyHelperObject->_RoleCreateIfNotExists(
    Name => 'Some Role Name',
);

$Self->True(
    $ResultRoleCreateIfNotExists,
    'Test basic function call of _RoleCreateIfNotExists()',
);

# Tests for _TypeCreateIfNotExists function
my $ResultTypeCreateIfNotExists = $ZnunyHelperObject->_TypeCreateIfNotExists(
    Name => 'Some Type Name',
);

$Self->True(
    $ResultTypeCreateIfNotExists,
    'Test basic function call of _TypeCreateIfNotExists()',
);

# Tests for _StateCreateIfNotExists function
my $ResultStateCreateIfNotExists = $ZnunyHelperObject->_StateCreateIfNotExists(
    Name   => 'Some State Name',
    TypeID => 1,
);

$Self->True(
    $ResultStateCreateIfNotExists,
    'Test basic function call of _StateCreateIfNotExists()',
);

# Tests for _StateDisable function
my $ResultStateDisable = $ZnunyHelperObject->_StateDisable(
    'Some State Name',
);

$Self->True(
    $ResultStateDisable,
    'Test basic function call of _StateDisable()',
);

# Tests for _ServiceCreateIfNotExists function
my $ResultServiceCreateIfNotExists = $ZnunyHelperObject->_ServiceCreateIfNotExists(
    Name => 'Some ServiceName',
);

$Self->True(
    $ResultServiceCreateIfNotExists,
    'Test basic function call of _ServiceCreateIfNotExists()',
);

# Tests for _SLACreateIfNotExists function
my $ResultSLACreateIfNotExists = $ZnunyHelperObject->_SLACreateIfNotExists(
    Name => 'Some SLAName',
);

$Self->True(
    $ResultSLACreateIfNotExists,
    'Test basic function call of _SLACreateIfNotExists()',
);

# Tests for _QueueCreateIfNotExists function
my $ResultQueueCreateIfNotExists = $ZnunyHelperObject->_QueueCreateIfNotExists(
    Name    => 'Some Queue Name',
    GroupID => 1,
);

$Self->True(
    $ResultQueueCreateIfNotExists,
    'Test basic function call of _QueueCreateIfNotExists()',
);

# Tests for _WebserviceCreateIfNotExists function
my $ResultWebserviceCreateIfNotExists = $ZnunyHelperObject->_WebserviceCreateIfNotExists(
    SubDir => 'Znuny4OTRSRepo',
);

$Self->True(
    $ResultWebserviceCreateIfNotExists,
    'Test basic function call of _WebserviceCreateIfNotExists()',
);

# Tests for _WebservicesGet function
my $ResultWebservicesGet = $ZnunyHelperObject->_WebservicesGet(
    SubDir => 'Znuny4OTRSRepo',
);

$Self->True(
    $ResultWebservicesGet,
    'Test basic function call of _WebservicesGet()',
);

# Tests for _WebserviceDelete function
my $ResultWebserviceDelete = $ZnunyHelperObject->_WebserviceDelete(
    SubDir => 'Znuny4OTRSRepo',
);

$Self->True(
    $ResultWebserviceDelete,
    'Test basic function call of _WebserviceDelete()',
);

1;
