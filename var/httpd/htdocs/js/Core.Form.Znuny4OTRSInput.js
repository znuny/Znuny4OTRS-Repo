// --
// Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --
// nofilter(TidyAll::Plugin::OTRS::JavaScript::ESLint)

"use strict";

var Core = Core || {};

/**
 * @namespace
 * @exports TargetNS as Core.Form.Znuny4OTRSInput
 * @description
 *      This namespace contains the special module functions for Znuny4OTRSInput.
 */
Core.Form.Znuny4OTRSInput = (function (TargetNS) {

    var AttributFieldIDMapping = {
        AgentTicketActionCommon: {
            OwnerID:       'NewOwnerID',
            PriorityID:    'NewPriorityID',
            QueueID:       'NewQueueID',
            ResponsibleID: 'NewResponsibleID',
            Body:          'RichText',
            StateID:       'NewStateID',
        },

        AgentTicketBounce: {
            Body: 'RichText',
        },

        AgentTicketBulk: {
            RichText: 'Body',
            StateID:  'EmailStateID',
        },

        AgentTicketCompose: {
            Body:           'RichText',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer'
        },

        AgentTicketCustomer: {
            Customer:       'CustomerAutoComplete',
            CustomerUserID: 'CustomerAutoComplete',
        },

        AgentTicketEmail: {
            OwnerID:        'NewUserID',
            QueueID:        'Dest',
            ResponsibleID:  'NewResponsibleID',
            Body:           'RichText',
            StateID:        'NextStateID',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer',
        },

        AgentTicketEmailOutbound: {
            Body:           'RichText',
            StateID:        'ComposeStateID',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer'
        },

        AgentTicketForward: {
            Body:           'RichText',
            StateID:        'ComposeStateID',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer'
        },

        AgentTicketMerge: {
            Body: 'RichText',
        },

        AgentTicketMove: {
            QueueID:    'DestQueueID',
            PriorityID: 'NewPriorityID',
            StateID:    'NewStateID',
            Body:       'RichText',
        },

        AgentTicketOverviewMedium: {
            QueueID: 'DestQueueID'
        },

        AgentTicketOverviewPreview: {
            QueueID: 'DestQueueID'
        },

        AgentTicketOverviewSmall: {
            QueueID: 'DestQueueID'
        },

        AgentTicketPhone: {
            CustomerUserID: 'FromCustomer',
            Customer:       'FromCustomer',
            OwnerID:        'NewUserID',
            QueueID:        'Dest',
            ResponsibleID:  'NewResponsibleID',
            Body:           'RichText',
            StateID:        'NextStateID',
        },

        AgentTicketPhoneCommon: {
            Body:    'RichText',
            StateID: 'NextStateID',
        },

        AgentTicketZoom: {
            QueueID: 'DestQueueID'
        },

        CustomerTicketMessage: {
            QueueID: 'Dest',
            Body:    'RichText',
        },

        CustomerTicketZoom: {
            Body: 'RichText',
        },

        AgentTicketProcess: {
            Body:           'RichText',
            Customer:       'CustomerAutoComplete',
            CustomerUserID: 'CustomerAutoComplete',
        },

        CustomerTicketProcess: {
            Body:           'RichText',
            Customer:       'CustomerAutoComplete',
            CustomerUserID: 'CustomerAutoComplete',
        }
    };

    var ActionModuleMapping = {
        AgentTicketClose:         'AgentTicketActionCommon',
        AgentTicketFreeText:      'AgentTicketActionCommon',
        AgentTicketNote:          'AgentTicketActionCommon',
        AgentTicketOwner:         'AgentTicketActionCommon',
        AgentTicketPending:       'AgentTicketActionCommon',
        AgentTicketPriority:      'AgentTicketActionCommon',
        AgentTicketResponsible:   'AgentTicketActionCommon',
        AgentTicketPhoneInbound:  'AgentTicketPhoneCommon',
        AgentTicketPhoneOutbound: 'AgentTicketPhoneCommon',

        // Znuny4OTRS-SecondTicketCreateScreen
        AgentTicketEmailSecond: 'AgentTicketEmail',
        AgentTicketPhoneSecond: 'AgentTicketPhone',

        // Znuny4OTRS-AdditionalCommon
        AgentTicketAdditionalCommon1: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon2: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon3: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon4: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon5: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon6: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon7: 'AgentTicketActionCommon',
        AgentTicketAdditionalCommon8: 'AgentTicketActionCommon',
    }

    TargetNS.FieldID = function (Attribute) {
        var Module;

        if (!Attribute) return false;

        Module = TargetNS.Module();

        if (Attribute.indexOf('DynamicField_') === 0) {

            // check if we have a Date or DateTime DynamicField
            var DynamicFieldDateCheckboxID = Attribute + 'Used';
            if (
                $('#' + DynamicFieldDateCheckboxID)
                && $('#' + DynamicFieldDateCheckboxID).length == 1
                && $('#'+ Attribute + 'Year').length == 1
            ) {
                return DynamicFieldDateCheckboxID;
            }

            return Attribute;
        }

        if (
            !AttributFieldIDMapping[ Module ]
            || !AttributFieldIDMapping[ Module ][ Attribute ]
        ) {
            if ($('#'+ Attribute).length > 0) {
                return Attribute;
            }
            else {
                return false;
            }
        }

        return AttributFieldIDMapping[Module][Attribute];
    }

    /*

    Adds a field mapping to an Action.

        var Result = Core.Form.Znuny4OTRSInput.FieldIDMapping('AdminQueue',
            {
                EscalationStep1Color: 'EscalationStep1Color' # FirstParam = AccessKey
                                                             # SecondParam = ID of the HTML element on page
            }
        );

    Returns:

        Result = {
            EscalationStep1Color: 'EscalationStep1Color'
        };

    */
    TargetNS.FieldIDMapping = function (Action, AttributeFieldIDs) {

        var Module = TargetNS.Module(Action);

        if (typeof AttributeFieldIDs === 'object') {
            AttributFieldIDMapping[Module] = AttributeFieldIDs;
        }

        return AttributFieldIDMapping[Module];
    }

    TargetNS.Module = function (Action) {

        Action = Action || Core.Config.Get('Action');

        if (ActionModuleMapping[Action]) {
            return ActionModuleMapping[Action];
        }

        return Action;
    }

    TargetNS.Get = function (Attribute, Options) {

        var FieldID;
        var KeyOrValue;
        var LookupClass;
        var PossibleValues; // Affects currently only select fields (no dynamic field support)
        var Prefix;
        var Result;
        var SelectedAffix;
        var Type;
        var Value;
        var $Element;

        Options = Options || {};

        if (typeof Options !== 'object') return;

        KeyOrValue     = Options.KeyOrValue || 'Key';
        PossibleValues = Options.PossibleValues; // Affects currently only select fields (no dynamic field support)
        FieldID        = TargetNS.FieldID(Attribute);

        if (!FieldID) return;

        Type = TargetNS.Type(FieldID);

        if (FieldID === 'RichText') {
            if (
                typeof CKEDITOR !== 'undefined'
                && CKEDITOR.instances[FieldID]
            ) {
                return CKEDITOR.instances[FieldID].getData();
            }
            else {
                return $('#'+ FieldID).val();
            }
        }
        else if (
            Type == 'text'
            || Type == 'hidden'
            || Type == 'textarea'
        ) {
            if (
                Type == 'text'
                && $('#'+ FieldID).hasClass('CustomerAutoComplete')
            ) {
                Prefix = FieldID;
                Prefix = Prefix.replace(/^ToCustomer$/, 'Customer');
                Prefix = Prefix.replace(/^FromCustomer$/, 'Customer');

                if (KeyOrValue == 'Key') {
                    LookupClass = 'CustomerKey';
                }
                else {
                    LookupClass = 'CustomerTicketText';
                }

                Result = [];
                $('.'+LookupClass).each(function(Index, Element) {

                    if ($(Element).attr('id').indexOf(Prefix) != 0) return true;

                    Value = $.trim($(Element).val());

                    if (Value.length === 0) return true;

                    // only get selected customers if option is set
                    if (Options.Selected && !$(Element).siblings('.CustomerTicketRadio').prop('checked')) return true;

                    Result.push(Value);
                });

                return Result;
            }
            // AgentTicketCustomer
            else if (
                Type == 'text'
                && FieldID === 'CustomerAutoComplete'
            ) {
                if (KeyOrValue == 'Key') {
                    return $('#SelectedCustomerUser').val();
                }
                else {
                    return $('#CustomerAutoComplete').val();
                }
            }
            // DynamicField CustomerUserID
            else if (
                Type == 'hidden'
                && FieldID.indexOf('DynamicField_') == 0
                && $('#'+ FieldID +'Autocomplete').length > 0
            ) {
                if (KeyOrValue == 'Key') {
                    return $('#'+ FieldID).val();
                }
                else {
                    return $('#'+ FieldID +'Autocomplete').val();
                }
            }
            // regular fields
            else {
                return $('#'+ FieldID).val();
            }
        }
        else if (Type == 'checkbox') {

            // it is not possible to set arrays via ids like $('#StateList[]')
            // because ids always relating to one element
            if ($('input[name=\'' + FieldID + '\']').length > 1) {

                // check checked status
                var ReturnValues = [];
                $('input[name=\'' + FieldID + '\']').each(function(){
                    if (!$(this).prop('checked') && !PossibleValues) return true;

                    ReturnValues.push($(this).val());
                });

                return ReturnValues;
            }

            return $('#'+ FieldID).prop('checked');
        }
        else if (Type == 'select') {

            if ($('#'+ FieldID).prop('multiple') || PossibleValues) {

                Result = [];
                SelectedAffix = '';
                if (!Options.PossibleValues) {
                    SelectedAffix = ':selected';
                }

                $('#' + FieldID + ' option' + SelectedAffix).each(function(Index, Element) {

                    var Text = RebuildLevelText($(Element));

                    if (KeyOrValue == 'Key') {
                        Value = QueueIDExtract($(Element).val(), Text);
                        Result.push(Value);
                    }
                    else {
                        Result.push($.trim(Text));
                    }
                });

                return Result;
            }
            else {
                $Element = $('#'+ FieldID +' option:selected');

                if (!$Element.length) return;

                var Text = RebuildLevelText($Element);

                if (KeyOrValue == 'Key') {
                    return QueueIDExtract($Element.val(), Text);
                }
                else {
                    return $.trim(Text);
                }
            }
        }
        // DynamicField Date or DateTime
        else if (
            Type == 'DynamicField_Date'
            || Type == 'DynamicField_DateTime'
        ) {
            // ATTENTION - SPECIAL CASE: For DynamicFields Date or DateTime the Attribute is used as FieldID
            // to handle input actions since FieldID maps to the Checkbox element

            var DateStructure = {};
            $.each(['Year', 'Month', 'Day', 'Hour', 'Minute'], function (Index, Suffix) {

                if (
                    $('#'+ Attribute + Suffix)
                    && $('#'+ Attribute + Suffix).length == 1
                ) {
                    DateStructure[ Suffix ] = parseInt($('#'+ Attribute + Suffix).val(), 10);
                }
                // exit loop
                else {
                    return false;
                }
            });

            // add checkbox state
            DateStructure.Used = $('#'+ FieldID).prop('checked');

            // new Date(DateStructure.Year, DateStructure.Month, DateStructure.Day, DateStructure.Hour, DateStructure.Minute, DateStructure.Second);
            return DateStructure;
        }
        // TODO: Other Date / DateTime elements (Pending etc.)?
        // TODO: Attachments?

        return;
    }

    TargetNS.Type = function (FieldID) {

        if ($('#'+ FieldID).length == 0) return;

        if ($('#'+ FieldID)[0].tagName != 'INPUT') {
            return $('#'+ FieldID)[0].tagName.toLowerCase();
        }
        var Type = $('#'+ FieldID)[0].type.toLowerCase();

        // special DynamicField Date and DateTime handling
        if (Type != 'checkbox') return Type;

        if (FieldID.indexOf('DynamicField_') != 0) return Type;

        var Attribute = FieldID.replace(/Used$/, '');
        if (FieldID == Attribute) return Type;

        if ($('#'+ Attribute + 'Year').length == 0) return Type;

        if ($('#'+ Attribute + 'Minute').length == 0) return 'DynamicField_Date';

        return 'DynamicField_DateTime';
    }

    TargetNS.Exists = function (Attribute) {
        var FieldID = TargetNS.FieldID(Attribute);

        return $('#' + FieldID).length ? true : false;
    }

    TargetNS.Set = function (Attribute, Content, Options) {

        var Checked;
        var CompareKeyOrValue;
        var CustomerKey;
        var CustomerValue;
        var Exists;
        var FieldID;
        var KeyOrValue;
        var Prefix;
        var Selected;
        var SetSelected;
        var TriggerChange;
        var Type;
        var SetAsTicketCustomer;

        Options = Options || {};

        if (typeof Options !== 'object') return;

        TriggerChange = true;
        if (typeof Options.TriggerChange === 'boolean') {
            TriggerChange = Options.TriggerChange;
        }

        KeyOrValue = Options.KeyOrValue || 'Key';
        FieldID    = TargetNS.FieldID(Attribute);

        if (!FieldID) {
            return false;
        }

        Type = TargetNS.Type(FieldID);

        if (FieldID === 'RichText') {
            if (
                typeof CKEDITOR !== 'undefined'
                && CKEDITOR.instances[FieldID]
            ) {
                // Attention: No 'change' event will get triggered
                // and the content will get re-rendered, so all events are lost :)
                // See: https://dev.ckeditor.com/ticket/6633
                CKEDITOR.instances[FieldID].setData(Content || '');
                Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
            }
            else {
                $('#'+ FieldID).val(Content || '');
                if (TriggerChange) {
                    $('#'+ FieldID).trigger('change');
                }
                Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
            }
        }
        else if (
            Type == 'text'
            || Type == 'hidden'
            || Type == 'textarea'
        ) {
            if (
                Type == 'text'
                && $('#'+ FieldID).hasClass('CustomerAutoComplete')
            ) {
                // register event listener to fetch and set result
                $('#'+ FieldID).one('autocompleteresponse', function(Event, Result) {

                    $('#'+ FieldID).autocomplete('close');

                    Prefix = FieldID;
                    Prefix = Prefix.replace(/^ToCustomer$/, 'Customer');
                    Prefix = Prefix.replace(/^FromCustomer$/, 'Customer');

                    SetAsTicketCustomer = $('#'+ Prefix +'TicketText').hasClass('Radio');
                    $.each(Result.content, function (Index, CustomerUser) {

                        CustomerKey   = CustomerUser.key,
                        CustomerValue = CustomerUser.value;

                        Exists = false;
                        $('input.CustomerTicketText').each(function (Index, Element) {

                            if ($(Element).val() != CustomerValue) return true;

                            if (SetAsTicketCustomer) {
                                Index = $(Element).attr('id');
                                Index = Index.replace('CustomerTicketText_', '');

                                if (TriggerChange) {
                                    $('#CustomerSelected_'+Index).trigger('click');
                                }

                                SetAsTicketCustomer = false;
                            }

                            Exists = true;
                        });

                        if (Exists) return true;

                        Core.Agent.CustomerSearch.AddTicketCustomer($(Event.target).attr('id'), CustomerValue, CustomerKey, SetAsTicketCustomer);

                        Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);

                        SetAsTicketCustomer = false;
                    });
                });

                // start search
                $('#'+FieldID).autocomplete('search', Content);
            }
            // AgentTicketCustomer
            else if (
                Type == 'text'
                && FieldID === 'CustomerAutoComplete'
            ) {
                // register event listener to fetch and set result
                $('#'+ FieldID).one('autocompleteresponse', function(Event, Result) {

                    if (Result.content.length === 1) {

                        CustomerKey   = Result.content[0].key,
                        CustomerValue = Result.content[0].value;

                        $('#'+ FieldID).autocomplete('close');
                        $('#'+ FieldID).val(CustomerValue);

                        if (TriggerChange) {
                            $('#'+ FieldID).trigger('change');
                        }

                        Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);

                        Core.Agent.CustomerSearch.ReloadCustomerInfo(CustomerKey);
                    }
                    else if(KeyOrValue == 'Key' && Result.content.length > 1) {

                        $.each(Result.content, function(Index,Element){

                            if(Element.key != Content) return true;

                            CustomerKey   = Element.key,
                            CustomerValue = Element.value;

                            $('#'+ FieldID).autocomplete('close');
                            $('#'+ FieldID).val(CustomerValue);

                            if (TriggerChange) {
                                $('#'+ FieldID).trigger('change');
                            }

                            Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);

                            Core.Agent.CustomerSearch.ReloadCustomerInfo(CustomerKey);

                            return false;
                        });
                    }
                });

                // start search
                $('#'+ FieldID).autocomplete('search', Content);
            }
            // DynamicField CustomerUserID
            else if (
                Type == 'hidden'
                && FieldID.indexOf('DynamicField_') == 0
                && $('#'+ FieldID +'Autocomplete').length > 0
            ) {
                // register event listener to fetch and set result
                $('#'+ FieldID +'Autocomplete').one('autocompleteresponse', function(Event, Result) {

                    if (Result.content.length === 1) {

                        CustomerKey   = Result.content[0].key,
                        CustomerValue = Result.content[0].value;

                        $('#'+ FieldID +'Autocomplete').autocomplete('close');
                        $('#'+ FieldID +'Autocomplete').val(CustomerValue);
                        $('#'+ FieldID).val(CustomerKey);

                        if (TriggerChange) {
                            $('#'+ FieldID).trigger('change');
                        }

                        Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
                    }
                    else if(KeyOrValue == 'Key' && Result.content.length > 1) {

                        $.each(Result.content, function(Index,Element){

                            if(Element.key != Content) return true;

                            CustomerKey   = Element.key,
                            CustomerValue = Element.value;

                            $('#'+ FieldID +'Autocomplete').autocomplete('close');
                            $('#'+ FieldID +'Autocomplete').val(CustomerValue);
                            $('#'+ FieldID).val(CustomerKey);

                            if (TriggerChange) {
                                $('#'+ FieldID).trigger('change');
                            }

                            Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);

                            return false;
                        });
                    }
                });

                // start search
                $('#'+ FieldID +'Autocomplete').autocomplete('search', Content);
            }
            // regular fields
            else {
                $('#'+ FieldID).val(Content || '');

                if (TriggerChange) {
                    $('#'+ FieldID).trigger('change');
                }

                Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
            }
        }
        else if (Type == 'checkbox') {

            if ($.isArray(Content)) {

                // loop values of checkbox array
                // it is not possible to set arrays via ids like $('#StateList[]')
                // because ids always relating to one element
                $('input[name=\'' + FieldID + '\']').each(function() {

                    // get value of checkbox element
                    var CheckboxValue = $(this).val();

                    // check checked status
                    Checked = false
                    $.each(Content, function(Index, Value) {
                        if (CheckboxValue != Value) return true;

                        Checked = true;

                        return false;
                    });

                    var $Element = $(this);
                    $Element.prop('checked', Checked);
                    if (TriggerChange) {
                        $Element.trigger('change');
                    }

                    Core.App.Publish('Znuny4OTRSInput.Change.' + Attribute + '.' + CheckboxValue);
                });
            }
            else {

                Checked = false;
                if (Content) {
                    Checked = true;
                }

                var $Element = $('#' + FieldID);
                $Element.prop('checked', Checked);
                if (TriggerChange) {
                    $Element.trigger('change');
                }
            }

            Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
        }
        else if (Type == 'select') {

            // reset selection
            $('#'+ FieldID +' option').prop('selected', false);

            // get selected values as an array
            SetSelected = [];
            if (Content) {
                if (
                    $('#'+ FieldID).prop('multiple')
                    && $.isArray(Content)
                ) {
                    SetSelected = Content;
                }
                else {
                    SetSelected = [Content];
                }
            }

            // cast to strings
            SetSelected = jQuery.map(SetSelected, function(Element) {
              return Element.toString();
            });

            $('#'+ FieldID +' option').filter(function() {

                var Text = RebuildLevelText($(this));

                if (KeyOrValue == 'Key') {
                    CompareKeyOrValue = QueueIDExtract($(this).val(), Text);
                }
                else {
                    CompareKeyOrValue = Text;
                }

                Selected = false;
                // may want to use $.trim in here?
                if (SetSelected.indexOf($.trim(CompareKeyOrValue)) != -1) {
                    Selected = true;
                }

                return Selected;
            }).prop('selected', true);

            if (TriggerChange) {
                $('#'+ FieldID).trigger('change');
            }

            Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
        }
        // DynamicField Date or DateTime
        else if (
            Type == 'DynamicField_Date'
            || Type == 'DynamicField_DateTime'
        ) {
            // if no content is given we will disable the Checkbox
            if (!Content) {
                $('#'+ FieldID).prop('checked', false);
                return true;
            }

            // ATTENTION - SPECIAL CASE: For DynamicFields Date or DateTime the Attribute is used as FieldID
            // to handle input actions since FieldID maps to the Checkbox element

            $.each(['Year', 'Month', 'Day', 'Hour', 'Minute'], function (Index, Suffix) {

                // skip if no value is given
                if (typeof Content[ Suffix ] === 'undefined') return true;

                if (
                    $('#'+ Attribute + Suffix)
                    && $('#'+ Attribute + Suffix).length == 1
                ) {
                    $('#'+ Attribute + Suffix).val(Content[ Suffix ]);
                }
                // exit loop
                else {
                    return false;
                }
            });

            if (typeof Content.Used === 'undefined') return true;

            // set checkbox state
            $('#'+ FieldID).prop('checked', Content.Used);

            return true;
        }
        // TODO: Date / DateTime ?
        // TODO: Attachments?

        // trigger redraw on modernized fields
        if ($('#'+ FieldID).hasClass('Modernize')) {
            $('#'+ FieldID).trigger('redraw.InputField');
        }

        return true;
    };

    TargetNS.Hide = function (Attribute) {

        var FieldID = TargetNS.FieldID(Attribute);

        if (!FieldID) {
            return false;
        }

        $('#'+ FieldID).parent().parent('div.Row').hide();
        $('#'+ FieldID).parent().hide();
        $("label[for='" + FieldID + "']").hide();

        return true;
    }

    TargetNS.Show = function (Attribute) {

        var FieldID = TargetNS.FieldID(Attribute);

        if (!FieldID) {
            return false;
        }

        $('#'+ FieldID).parent().parent('div.Row').show();
        $('#'+ FieldID).parent().show();
        $("label[for='" + FieldID + "']").show();

        // Trigger custom redraw event for InputFields
        // since hidden elements are not calculated correclty
        // see https://github.com/OTRS/otrs/pull/1002
        if ($('#'+ FieldID).hasClass('Modernize')) {
            $('#'+ FieldID).trigger('redraw.InputField');
        }

        return true;
    }

    /*

    Manipulates the field to mandatory or optional field.

    var Result = Core.Form.Znuny4OTRSInput.Mandatory('DynamicField_Example', true);
    var Result = Core.Form.Znuny4OTRSInput.Mandatory('DynamicField_Example', false);

    Returns:

        Result = true

    Or:

    var CurrentState = Core.Form.Znuny4OTRSInput.Mandatory('DynamicField_Example');

    Returns:

        CurrentState = true|false

    */
    TargetNS.Mandatory = function (Attribute, Mandatory) {

        var IsMandatory;
        var $LabelObject;
        var FieldID = TargetNS.FieldID(Attribute);

        if (!FieldID) {
            return false;
        }

        $LabelObject = $('[for="'+FieldID+'"]');

        IsMandatory = $LabelObject.hasClass('Mandatory');

        if (typeof Mandatory === 'undefined') {
            return IsMandatory;
        }

        if (Mandatory === IsMandatory) {
            return true;
        }

        if (IsMandatory) {
            $LabelObject.removeClass('Mandatory');
            $LabelObject.find('.Marker').remove();
            $('#'+FieldID).removeClass('Validate_Required');
        }
        else {
            $LabelObject.addClass('Mandatory');
            $LabelObject.prepend('<span class="Marker">*</span>');
            $('#'+FieldID).addClass('Validate_Required');
        }

        return true;
    }

    /*

    Manipulates the error state of a given attribute.

    var Result = Core.Form.Znuny4OTRSInput.Error('DynamicField_Example', 'Error');
    var Result = Core.Form.Znuny4OTRSInput.Error('DynamicField_Example', 'ServerError');

    Returns:

        Result = true

    */
    TargetNS.Error = function (Attribute, ErrorType) {

        var FieldID = TargetNS.FieldID(Attribute);

        if (!FieldID) {
            return false;
        }

        Core.Form.Validate.HighlightError($('#'+ FieldID)[0], ErrorType);
    }

    /*
    Manipulates the configuration of RichText input fields. It takes a config structure where the key is the Editor FieldID and the value is another structure with the config items it should set. It's possible to use the meta key 'Global' to set the config of all RichText instances on the current site. Notice that old configurations will be kept and extended instead of removed. For a complete list of possible config attributes visit the CKEdior documentation: http://docs.ckeditor.com/#!/api/CKEDITOR.config

    var Result = Core.Form.Znuny4OTRSInput.RichTextConfig({
      'RichText': {
        toolbarCanCollapse:     true,
        toolbarStartupExpanded: false,
      }
    });

    Returns:

      Result = true
    */
    TargetNS.RichTextConfig = function (NewConfig) {
        if (typeof CKEDITOR === 'undefined') {
            return;
        }

        // remove all rte's
        $('textarea.RichText').each(function () {
            var EditorID = $(this).attr('id');
            var Editor   = CKEDITOR.instances[EditorID];

            if (!Editor) return true;

            $(this).removeClass('HasCKEInstance');
            Editor.destroy(true);
        });

        // add hack to overwrite config at its lowest place
        CKEDITOR.replaceZnuny4OTRSInput = CKEDITOR.replace;
        CKEDITOR.replace = function(EditorID, EditorConfig) {
            var ExtendedConfig = NewConfig[ EditorID ] || NewConfig['Global'];
            $.each(ExtendedConfig, function(Attribute, Value) {
              EditorConfig[ Attribute ] = Value;
            });

            return CKEDITOR.replaceZnuny4OTRSInput(EditorID, EditorConfig);
        };

        // reinitialize all rte's
        Core.UI.RichTextEditor.InitAllEditors();

        // remove hack
        CKEDITOR.replace = CKEDITOR.replaceZnuny4OTRSInput;
        delete CKEDITOR.replaceZnuny4OTRSInput;

        return true;
    }

    function RebuildLevelText($Element) {

        var Levels = [];

        var CurrentText = $Element.text();
        var Level       = CurrentText.search(/\S/);

        Levels.unshift($.trim(CurrentText));

        var LevelSearch = false;
        if (Level > 0) {
            LevelSearch = true;
        }

        var $TempElement = $Element;
        while (LevelSearch) {

            $TempElement = $TempElement.prev();
            CurrentText  = $TempElement.text();

            // special handling for broken element values
            // that start with a leading whitespace
            // see issue #17
            if (!CurrentText) {
                LevelSearch = false;
                continue;
            }

            var CompareLevel = CurrentText.search(/\S/);

            if (CompareLevel >= Level) {
                continue;
            }

            Level = CompareLevel;

            Levels.unshift($.trim(CurrentText));

            if (Level == 0) {
                LevelSearch = false;
            }
        }

        return Levels.join('::');
    }

    // special queue handling
    function QueueIDExtract (Key, Value) {
        var QueueName   = $.trim(Value);
        QueueName       = escapeRegExp(QueueName);
        var QueueExp    = '^(\\d*)\\|\\|.*'+ QueueName +'$';
        var QueueRegExp = new RegExp(QueueExp);

        return Key.replace(QueueRegExp, "$1");
    }

    function escapeRegExp(str) {
      return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    }
    return TargetNS;
}(Core.Form.Znuny4OTRSInput || {}));
