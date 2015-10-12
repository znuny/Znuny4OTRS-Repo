// --
// Core.Form.Znuny4OTRSInput.js - normalizes the input experience
// Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
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
            ArticleTypeID: 'ArticleTypeID',
            NewOwnerID:    'NewOwnerID',
            OldOwnerID:    'OldOwnerID',
            NewPriorityID: 'NewPriorityID',
            PriorityID:    'NewPriorityID',
            NewQueueID:    'NewQueueID',
            QueueID:       'NewQueueID',
            ResponsibleID: 'NewResponsibleID',
            RichText:      'RichText',
            ServiceID:     'ServiceID',
            SLAID:         'SLAID',
            NewStateID:    'NewStateID',
            StateID:       'NewStateID',
            Subject:       'Subject',
            Title:         'Title',
            TypeID:        'TypeID',
        },

        AgentTicketBounce: {
            BounceStateID: 'BounceStateID',
            BounceTo:      'BounceTo',
            CustomerID:    'CustomerID',
            RichText:      'RichText',
            Subject:       'Subject',
            To:            'To',
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
            TypeID:        'TypeID',
        },

        AgentTicketCompose: {
            ArticleTypeID: 'ArticleTypeID',
            BccCustomer:   'BccCustomer',
            CcCustomer:    'CcCustomer',
            RichText:      'RichText',
            StateID:       'StateID',
            Subject:       'Subject',
            ToCustomer:    'ToCustomer',
            Customer:      'ToCustomer',
        },

        AgentTicketCustomer: {
            CustomerAutoComplete: 'CustomerAutoComplete',
            Customer:             'CustomerAutoComplete',
            CustomerID:           'CustomerID',
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
            TypeID:           'TypeID',
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
        },

        AgentTicketMerge: {
            From:     'From',
            RichText: 'RichText',
            Subject:  'Subject',
            To:       'To',
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
            Subject:       'Subject',
        },

        AgentTicketOverviewMedium: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID',
        },

        AgentTicketOverviewPreview: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID',
        },

        AgentTicketOverviewSmall: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID',
        },

        AgentTicketPhone: {
            CustomerID:       'CustomerID',
            FromCustomer:     'FromCustomer',
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
            TypeID:           'TypeID',
        },

        AgentTicketPhoneCommon: {
            RichText:    'RichText',
            NextStateID: 'NextStateID',
            StateID:     'NextStateID',
            Subject:     'Subject',
        },

        AgentTicketZoom: {
            DestQueueID: 'DestQueueID',
            QueueID:     'DestQueueID',
        },
    };

    var ActionModuleMapping = {
        AgentTicketClose:       'AgentTicketActionCommon',
        AgentTicketFreeText:    'AgentTicketActionCommon',
        AgentTicketNote:        'AgentTicketActionCommon',
        AgentTicketOwner:       'AgentTicketActionCommon',
        AgentTicketPending:     'AgentTicketActionCommon',
        AgentTicketPriority:    'AgentTicketActionCommon',
        AgentTicketResponsible: 'AgentTicketActionCommon',
    }

    TargetNS.FieldID = function ( Attribute ) {

        var Module = TargetNS.Module();

        if ( Attribute.indexOf('DynamicField_') === 0 ) {
            return Attribute;
        }

        if (
            !AttributFieldIDMapping[ Module ]
            || !AttributFieldIDMapping[ Module ][ Attribute ]
        ) {
            return false;
        }

        return AttributFieldIDMapping[ Module ][ Attribute ];
    }

    TargetNS.SetFieldIDMapping = function ( Action, AttributeFieldIDs ) {

        var Module = TargetNS.Module( Action );

        AttributFieldIDMapping[ Module ] = AttributeFieldIDs;

        return true;
    }

    TargetNS.Module = function ( Action ) {

        Action = Action || Core.Config.Get('Action');

        if ( ActionModuleMapping[ Action ] ) {
            return ActionModuleMapping[ Action ];
        }

        return Action;
    }

    // TODO: Get -> Read out Attribute value(s)
    TargetNS.Get = function ( Attribute, KeyOrValue ) {

        KeyOrValue  = KeyOrValue || 'Key';
        var FieldID = TargetNS.FieldID( Attribute );

        KeyOrValue  = KeyOrValue || 'Key';
        var FieldID = TargetNS.FieldID( Attribute );

        if ( !FieldID ) {
            return false;
        }

        var Type = TargetNS.Type( FieldID );

        if (
            Type == 'text'
            || Type == 'hidden'
            || Type == 'textarea'
        ) {
            if (
                Type == 'text'
                && $('#'+ FieldID).hasClass('CustomerAutoComplete')
            ) {
                var Prefix = FieldID;
                Prefix     = Prefix.replace(/^ToCustomer$/, 'Customer');
                Prefix     = Prefix.replace(/^FromCustomer$/, 'Customer');

                var LookupClass;
                if ( KeyOrValue == 'Key' ) {
                    LookupClass = 'CustomerKey';
                }
                else {
                    LookupClass = 'CustomerTicketText';
                }

                // TODO: CustomerSelected
                var Result = [];
                $('.'+ LookupClass).each( function (Index, Element) {

                    if ( $(Element).attr('id').indexOf( Prefix ) != 0 ) return true;

                    var Value = $.trim( $(Element).val() );

                    if ( Value.length === 0 ) return true;

                    Result.push( Value );
                });

                return Result;
            }
            // AgentTicketCustomer
            else if (
                Type == 'text'
                && FieldID === 'CustomerAutoComplete'
            ) {
                if ( KeyOrValue == 'Key' ) {
                    return $('#SelectedCustomerUser').val();
                }
                else {
                    return $('#CustomerAutoComplete').val();
                }
            }
            // regular fields
            else {
                return $('#'+ FieldID).val();
            }
        }
        else if ( Type == 'checkbox' ) {
            return $('#'+ FieldID).prop('checked');
        }
        else if ( Type == 'select' ) {

            if ( $('#'+ FieldID).prop('multiple') ) {

                var Result = [];
                $('#'+ FieldID +' option:selected').each(function(Index, Element) {

                    if ( KeyOrValue == 'Key' ) {
                        var Value = QueueIDExtract( $(Element).val(), $(Element).text() );
                        Result.push( Value );
                    }
                    else {
                        Result.push( $.trim( $(Element).text() ) );
                    }
                });
                return Result;
            }
            else {
                var $Element = $('#'+ FieldID +' option:selected');
                if ( KeyOrValue == 'Key' ) {
                    return QueueIDExtract( $Element.val(), $Element.text() );
                }
                else {
                    return $.trim( $Element.text() );
                }
            }
        }
        // TODO: Date / DateTime?
        // TODO: Attachments?

        return true;
    }

    TargetNS.Type = function ( FieldID ) {

        if ( $('#'+ FieldID)[0].tagName == 'INPUT' ) {
            return $('#'+ FieldID)[0].type.toLowerCase();
        }
        return $('#'+ FieldID)[0].tagName.toLowerCase();
    }

    TargetNS.Set = function ( Attribute, Content, KeyOrValue ) {

        KeyOrValue  = KeyOrValue || 'Key';
        var FieldID = TargetNS.FieldID( Attribute );

        if ( !FieldID ) {
            return false;
        }

        var Type = TargetNS.Type( FieldID );

        if (
            Type == 'text'
            || Type == 'hidden'
            || Type == 'textarea'
        ) {
            if (
                Type == 'text'
                && $('#'+ FieldID).hasClass('CustomerAutoComplete')
            ) {
                // register event listener to fetch and set result
                $('#'+ FieldID).one('autocompleteresponse', function( Event, Result ) {

                    $('#'+ FieldID).autocomplete('close');

                    var Prefix = FieldID;
                    Prefix     = Prefix.replace(/^ToCustomer$/, 'Customer');
                    Prefix     = Prefix.replace(/^FromCustomer$/, 'Customer');

                    var SetAsTicketCustomer = $('#'+ Prefix +'TicketText').hasClass('Radio');
                    $.each(Result.content, function (Index, CustomerUser) {

                        var CustomerKey   = CustomerUser.key,
                            CustomerValue = CustomerUser.value;

                        var Exists = false;
                        $('input.CustomerTicketText').each( function (Index, Element) {

                            if ( $(Element).val() != CustomerValue ) return true;

                            if ( SetAsTicketCustomer ) {
                                var Index = $(Element).attr('id');
                                Index     = Index.replace('CustomerTicketText_', '');

                                $('#CustomerSelected_'+ Index ).trigger('click');

                                SetAsTicketCustomer = false;
                            }

                            Exists = true;
                        });

                        if ( Exists ) return true;

                        Core.Agent.CustomerSearch.AddTicketCustomer($(Event.target).attr('id'), CustomerValue, CustomerKey, SetAsTicketCustomer);

                        SetAsTicketCustomer = false;
                    });
                } );

                // start search
                $('#'+ FieldID).autocomplete('search', Content);
            }
            // AgentTicketCustomer
            else if (
                Type == 'text'
                && FieldID === 'CustomerAutoComplete'
            ) {
                // register event listener to fetch and set result
                $('#'+ FieldID).one('autocompleteresponse', function( Event, Result ) {

                    if ( Result.content.length === 1 ) {

                        var CustomerKey   = Result.content[0].key,
                            CustomerValue = Result.content[0].value;

                        $('#'+ FieldID).autocomplete('close');
                        $('#'+ FieldID).val(CustomerValue);

                        Core.Agent.CustomerSearch.ReloadCustomerInfo(CustomerKey);
                    }
                } );

                // start search
                $('#'+ FieldID).autocomplete('search', Content);
            }
            // regular fields
            else {
                $('#'+ FieldID).val( Content || '' ).trigger('change');
            }

        }
        else if ( Type == 'checkbox' ) {

            var Checked = false;
            if ( Content ) {
                Checked = true;
            }
            $('#'+ FieldID).prop('checked', Checked);
            $('#'+ FieldID).trigger('change');
        }
        else if ( Type == 'select' ) {

            // reset selection
            $('#'+ FieldID +' option').prop('selected', false);

            // get selected values as an array
            var SetSelected = [];
            if ( Content ) {
                if (
                    $('#'+ FieldID).prop('multiple')
                    && $.isArray(Content)
                ) {
                    SetSelected = Content;
                }
                else {
                    SetSelected = [ Content ];
                }
            }

            // cast to strings
            SetSelected = jQuery.map( SetSelected, function( Element ) {
              return Element.toString();
            });

            $('#'+ FieldID +' option').filter(function() {

                var CompareKeyOrValue;
                if ( KeyOrValue == 'Key' ) {
                    CompareKeyOrValue = QueueIDExtract( $(this).val(), $(this).text() );
                }
                else {
                    CompareKeyOrValue = $(this).text();
                }

                var Selected = false;
                // may want to use $.trim in here?
                if ( SetSelected.indexOf( $.trim( CompareKeyOrValue ) ) != -1 ) {
                    Selected = true;
                }

                return Selected;
            }).prop('selected', true);

            $('#'+ FieldID).trigger('change');
        }
        // TODO: Date / DateTime ?
        // TODO: Attachments?

        return true;
    };

    // special queue handling
    function QueueIDExtract (Key, Value) {
        var QueueName   = $.trim( Value );
        var QueueExp    = '^(\\d*)\\|\\|'+ QueueName +'$';
        var QueueRegExp = new RegExp(QueueExp);

        return Key.replace(QueueRegExp, "$1");
    }

    return TargetNS;
}(Core.Form.Znuny4OTRSInput || {}));
