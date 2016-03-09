// --
// Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

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
            ArticleTypeID:    'ArticleTypeID',
            NewOwnerID:       'NewOwnerID',
            OldOwnerID:       'OldOwnerID',
            OwnerID:          'NewOwnerID',
            NewPriorityID:    'NewPriorityID',
            PriorityID:       'NewPriorityID',
            NewQueueID:       'NewQueueID',
            QueueID:          'NewQueueID',
            NewResponsibleID: 'NewResponsibleID',
            ResponsibleID:    'NewResponsibleID',
            RichText:         'RichText',
            ServiceID:        'ServiceID',
            SLAID:            'SLAID',
            NewStateID:       'NewStateID',
            StateID:          'NewStateID',
            Subject:          'Subject',
            Title:            'Title',
            TypeID:           'TypeID'
        },

        AgentTicketBounce: {
            BounceStateID: 'BounceStateID',
            BounceTo:      'BounceTo',
            CustomerID:    'CustomerID',
            RichText:      'RichText',
            Subject:       'Subject',
            To:            'To'
        },

        AgentTicketBulk: {
            ArticleTypeID: 'ArticleTypeID',
            Body:          'Body',
            EmailBody:     'EmailBody',
            OwnerID:       'OwnerID',
            PriorityID:    'PriorityID',
            QueueID:       'QueueID',
            ResponsibleID: 'ResponsibleID',
            EmailStateID:  'EmailStateID',
            StateID:       'EmailStateID',
            EmailSubject:  'EmailSubject', // TODO: Which one?
            Subject:       'Subject',
            TypeID:        'TypeID'
        },

        AgentTicketCompose: {
            ArticleTypeID:  'ArticleTypeID',
            BccCustomer:    'BccCustomer',
            CcCustomer:     'CcCustomer',
            RichText:       'RichText',
            StateID:        'StateID',
            Subject:        'Subject',
            ToCustomer:     'ToCustomer',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer'
        },

        AgentTicketCustomer: {
            CustomerAutoComplete: 'CustomerAutoComplete',
            Customer:             'CustomerAutoComplete',
            CustomerUserID:       'CustomerAutoComplete',
            CustomerID:           'CustomerID'
        },

        AgentTicketEmail: {
            BccCustomer:      'BccCustomer',
            CcCustomer:       'CcCustomer',
            CustomerID:       'CustomerID',
            NewUserID:        'NewUserID',
            OwnerID:          'NewUserID',
            PriorityID:       'PriorityID',
            Dest:             'Dest',
            QueueID:          'Dest',
            NewResponsibleID: 'NewResponsibleID',
            ResponsibleID:    'NewResponsibleID',
            RichText:         'RichText',
            ServiceID:        'ServiceID',
            SLAID:            'SLAID',
            NextStateID:      'NextStateID',
            StateID:          'NextStateID',
            Subject:          'Subject',
            ToCustomer:       'ToCustomer',
            Customer:         'ToCustomer',
            CustomerUserID:   'ToCustomer',
            TypeID:           'TypeID'
        },

        AgentTicketEmailOutbound: {
            ArticleTypeID:  'ArticleTypeID',
            BccCustomer:    'BccCustomer',
            CcCustomer:     'CcCustomer',
            RichText:       'RichText',
            ComposeStateID: 'ComposeStateID',
            StateID:        'ComposeStateID',
            Subject:        'Subject',
            ToCustomer:     'ToCustomer',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer'
        },

        AgentTicketForward: {
            ArticleTypeID:  'ArticleTypeID',
            BccCustomer:    'BccCustomer',
            CcCustomer:     'CcCustomer',
            RichText:       'RichText',
            ComposeStateID: 'ComposeStateID',
            StateID:        'ComposeStateID',
            Subject:        'Subject',
            ToCustomer:     'ToCustomer',
            Customer:       'ToCustomer',
            CustomerUserID: 'ToCustomer'
        },

        AgentTicketMerge: {
            From:     'From',
            RichText: 'RichText',
            Subject:  'Subject',
            To:       'To'
        },

        AgentTicketMove: {
            DestQueueID:   'DestQueueID',
            QueueID:       'DestQueueID',
            NewPriorityID: 'NewPriorityID',
            PriorityID:    'NewPriorityID',
            NewStateID:    'NewStateID',
            StateID:       'NewStateID',
            NewUserID:     'NewUserID',
            OldUserID:     'OldUserID',
            RichText:      'RichText',
            Subject:       'Subject'
        },

        AgentTicketOverviewMedium: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID'
        },

        AgentTicketOverviewPreview: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID'
        },

        AgentTicketOverviewSmall: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID'
        },

        AgentTicketPhone: {
            CustomerID:       'CustomerID',
            FromCustomer:     'FromCustomer',
            CustomerUserID:   'FromCustomer',
            Customer:         'FromCustomer',
            NewUserID:        'NewUserID',
            OwnerID:          'NewUserID',
            PriorityID:       'PriorityID',
            Dest:             'Dest',
            QueueID:          'Dest',
            NewResponsibleID: 'NewResponsibleID',
            ResponsibleID:    'NewResponsibleID',
            RichText:         'RichText',
            ServiceID:        'ServiceID',
            SLAID:            'SLAID',
            NextStateID:      'NextStateID',
            StateID:          'NextStateID',
            Subject:          'Subject',
            TypeID:           'TypeID'
        },

        AgentTicketPhoneCommon: {
            RichText:    'RichText',
            NextStateID: 'NextStateID',
            StateID:     'NextStateID',
            Subject:     'Subject'
        },

        AgentTicketZoom: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID'
        },

        CustomerTicketMessage: {
            Dest:       'Dest',
            QueueID:    'Dest',
            PriorityID: 'PriorityID',
            RichText:   'RichText',
            ServiceID:  'ServiceID',
            SLAID:      'SLAID',
            Subject:    'Subject',
            TypeID:     'TypeID'
        },

        CustomerTicketZoom: {
            PriorityID: 'PriorityID',
            RichText:   'RichText',
            StateID:    'StateID',
            Subject:    'Subject'
        },

        AgentTicketProcess: {
            Subject:        'Subject',
            RichText:       'RichText',
            Customer:       'CustomerAutoComplete',
            CustomerUserID: 'CustomerAutoComplete',
            CustomerID:     'CustomerID',
            Title:          'Title',
            ResponsibleID:  'ResponsibleID',
            OwnerID:        'OwnerID',
            SLAID:          'SLAID',
            ServiceID:      'ServiceID',
            LockID:         'LockID',
            PriorityID:     'PriorityID',
            QueueID:        'QueueID',
            StateID:        'StateID',
            TypeID:         'TypeID'
        },

        CustomerTicketProcess: {
            Subject:        'Subject',
            RichText:       'RichText',
            Customer:       'CustomerAutoComplete',
            CustomerUserID: 'CustomerAutoComplete',
            CustomerID:     'CustomerID',
            Title:          'Title',
            ResponsibleID:  'ResponsibleID',
            OwnerID:        'OwnerID',
            SLAID:          'SLAID',
            ServiceID:      'ServiceID',
            LockID:         'LockID',
            PriorityID:     'PriorityID',
            QueueID:        'QueueID',
            StateID:        'StateID',
            TypeID:         'TypeID'
        }
    };

    var ActionModuleMapping = {
        AgentTicketClose:       'AgentTicketActionCommon',
        AgentTicketFreeText:    'AgentTicketActionCommon',
        AgentTicketNote:        'AgentTicketActionCommon',
        AgentTicketOwner:       'AgentTicketActionCommon',
        AgentTicketPending:     'AgentTicketActionCommon',
        AgentTicketPriority:    'AgentTicketActionCommon',
        AgentTicketResponsible: 'AgentTicketActionCommon'
    }

    TargetNS.FieldID = function (Attribute) {
        var Module;

        if (!Attribute) return false;

        Module = TargetNS.Module();

        if (Attribute.indexOf('DynamicField_') === 0) {
            return Attribute;
        }

        if (
            !AttributFieldIDMapping[ Module ]
            || !AttributFieldIDMapping[ Module ][ Attribute ]
        ) {
            return false;
        }

        return AttributFieldIDMapping[Module][Attribute];
    }

    TargetNS.SetFieldIDMapping = function (Action, AttributeFieldIDs) {

        var Module = TargetNS.Module(Action);

        AttributFieldIDMapping[Module] = AttributeFieldIDs;

        return true;
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

        if (
            Type == 'text'
            || Type == 'hidden'
            || Type == 'textarea'
        ) {
            if (
                Type == 'text'
                && $('#'+ FieldID).hasClass('CustomerAutoComplete')
            ) {
                Prefix = FieldID;
                Prefix     = Prefix.replace(/^ToCustomer$/, 'Customer');
                Prefix     = Prefix.replace(/^FromCustomer$/, 'Customer');

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

                    if (KeyOrValue == 'Key') {
                        Value = QueueIDExtract($(Element).val(), $(Element).text());
                        Result.push(Value);
                    }
                    else {
                        Result.push($.trim($(Element).text()));
                    }
                });

                return Result;
            }
            else {
                $Element = $('#'+ FieldID +' option:selected');

                if (!$Element.length) return;

                if (KeyOrValue == 'Key') {
                    return QueueIDExtract($Element.val(), $Element.text());
                }
                else {
                    return $.trim($Element.text());
                }
            }
        }
        // TODO: Date / DateTime?
        // TODO: Attachments?

        return;
    }

    TargetNS.Type = function (FieldID) {

        if ($('#'+ FieldID).length == 0) return;

        if ($('#'+ FieldID)[0].tagName == 'INPUT') {
            return $('#'+ FieldID)[0].type.toLowerCase();
        }
        return $('#'+ FieldID)[0].tagName.toLowerCase();
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
        var SelectValue;
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

                    Prefix     = FieldID;
                    Prefix     = Prefix.replace(/^ToCustomer$/, 'Customer');
                    Prefix     = Prefix.replace(/^FromCustomer$/, 'Customer');

                    SetAsTicketCustomer = $('#'+ Prefix +'TicketText').hasClass('Radio');
                    $.each(Result.content, function (Index, CustomerUser) {

                        CustomerKey   = CustomerUser.key,
                        CustomerValue = CustomerUser.value;

                        Exists = false;
                        $('input.CustomerTicketText').each(function (Index, Element) {

                            if ($(Element).val() != CustomerValue) return true;

                            if (SetAsTicketCustomer) {
                                Index = $(Element).attr('id');
                                Index     = Index.replace('CustomerTicketText_', '');

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

            Checked = false;
            if (Content) {
                Checked = true;
            }
            $('#'+ FieldID).prop('checked', Checked);
            if (TriggerChange) {
                $('#'+ FieldID).trigger('change');
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

                if (KeyOrValue == 'Key') {
                    CompareKeyOrValue = QueueIDExtract($(this).val(), $(this).text());
                }
                else {
                    CompareKeyOrValue = $(this).text();
                }

                Selected = false;
                // may want to use $.trim in here?
                if (SetSelected.indexOf($.trim(CompareKeyOrValue)) != -1) {
                    Selected = true;
                    SelectValue = $(this).val();
                }

                return Selected;
            }).prop('selected', true);

            $('#' + FieldID).val(SelectValue);

            if (TriggerChange) {
                $('#'+ FieldID).trigger('change');
            }

            Core.App.Publish('Znuny4OTRSInput.Change.'+ Attribute);
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

        $('#'+ FieldID).parent().hide();
        $("label[for='" + FieldID + "']").hide();

        return true;
    }

    TargetNS.Show = function (Attribute) {

        var FieldID = TargetNS.FieldID(Attribute);

        if (!FieldID) {
            return false;
        }

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
    Manipulates the configuration of RichText input fields. It takes a config structure where the key is the Editor FieldID and the value is another structure with the config items it should set. It's possible to use the meta key 'Global' to set the config of all RichText instances on the current site. Notice that old configurations will be kept and extended instead of removed. For a complete list of possible config attributes visit the CKEdior documentation: http://docs.ckeditor.com/#!/api/CKEDITOR.config

    var Result = Core.Form.Znuny4OTRSInput.RichTextConfig({
      'RichText': {
        toolbarCanCollapse:     true,
        toolbarStartupExpanded: false,
      }
    })

    Returns:

      Result = true
    */
    TargetNS.RichTextConfig = function (NewConfig) {

        Core.UI.RichTextEditor.InitAll = function () {

            $('textarea.RichText').each(function () {
                var EditorID;
                var Editor;
                var EditorConfig;
                var ExtendedConfig;

                Core.UI.RichTextEditor.Init($(this));

                EditorID = $(this).attr('id');

                if (typeof NewConfig != 'object') return true;

                ExtendedConfig = NewConfig[ EditorID ] || NewConfig['Global'];
                if (typeof ExtendedConfig != 'object') return true;

                Editor = CKEDITOR.instances[EditorID];

                if (!Editor) return true;

                EditorConfig = Editor.config;

                $.each(ExtendedConfig, function(Attribute, Value) {
                  EditorConfig[ Attribute ] = Value;
                });

                Editor.destroy(true);
                CKEDITOR.replace(EditorID, EditorConfig);
            });
        };

        Core.UI.RichTextEditor.InitAll();
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
