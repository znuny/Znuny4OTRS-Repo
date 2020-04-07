// --
// Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Znuny4OTRS = Core.Znuny4OTRS || {};
Core.Znuny4OTRS.Form = Core.Znuny4OTRS.Form || {};

/**
 * @namespace Core.Znuny4OTRS.Form.Generic
 * @memberof Core.Znuny4OTRS.Form
 * @author Znuny GmbH
 * @description
 *      This namespace contains the special module functions for the Core.Znuny4OTRS.Form module.
 */
Core.Znuny4OTRS.Form.Generic = (function (TargetNS) {

    var RestoreElements = {};

    /**
     * @name Init
     * @memberof Core.Znuny4OTRS.Form.Generic
     * @function
     * @description
     *       Initialize module functionality
     */
    TargetNS.Init = function () {
        var $Restore = $('[data-formelement-restore]');

        // This binds a click event (Add) to the document and all child elements within it.
        // This means that elements that are not yet present already get the correct bind.
        $(document).on("click", '[data-formelement-add]', function () {
            TargetNS.Add(
                $(this)
            );
            return false;
        });

        // This binds a click event (Remove) to the document and all child elements within it.
        // This means that elements that are not yet present already get the correct bind.
        $(document).on("click", '[data-formelement-remove]', function () {
            TargetNS.Remove(
                $(this)
            );
            return false;
        });

        // This binds a click event (Restore) to the document and all child elements within it.
        // This means that elements that are not yet present already get the correct bind.
        $(document).on("click", '[data-formelement-restore]', function () {
            TargetNS.Restore(
                $(this)
            );
            return false;
        });

        $Restore.each(function(){
            var DestinationName   = $(this).data('formelementRestoreDestinationName'),
                $Destination      = $('[data-formelement-restore-destination="' + DestinationName + '"]'),
                $DestinationClone = $Destination.clone();

            RestoreElements[DestinationName] = $DestinationClone;
        });
    };

    /**
     * @name Add
     * @memberof Core.Znuny4OTRS.Form.Generic
     * @function
     * @returns {Boolean} Returns false
     * @param {Object} AddElement - Object of the clicked add element.
     *
     * data-formelement-add                                              # if empty use following data attributes:
     * data-formelement-add-destination-name="AdditionalDFStorage"       # name of destination element
     * data-formelement-add-source-name="AdditionalDFStorageTemplate"    # name of source element (template)
     * data-formelement-add-counter-name="AdditionalDFStorageCounter"    # name of counter element (maybe input field to count entries)
     * data-formelement-add-method='append'                              # method to add this source element (append|prepend|after|before)

     * @description
     *      This function adds a new value to the possible values list
     */
    TargetNS.Add = function (AddElement) {
        var Param = {},
            Method,
            $Source,
            $Destination,
            $Counter,
            $SourceClone,
            Counter;

        $.each(AddElement.data(), function(Key, Value) {
            Param[Key] = Value || '';
        });

        Method = Param['formelementAddMethod'] || 'append';

        $Source      = $('[data-formelement-add-source="'      + Param['formelementAddSourceName']      + '"]');
        $Destination = $('[data-formelement-add-destination="' + Param['formelementAddDestinationName'] + '"]');
        $Counter     = $('[data-formelement-add-counter="'     + Param['formelementAddCounterName']     + '"]');

        $SourceClone = $Source.clone();
        Counter      = $Counter.val() + 1;

        $SourceClone.addClass('ValueRow');
        $SourceClone.removeClass('Hidden ValueTemplate');
        $SourceClone.removeAttr("data-formelement-add-source");

        // copy values and change IDs and names
        $SourceClone.find(':input, a, button').each(function() {
            var ID        = $(this).attr('id'),
                CounterID = ID + '_' + Counter;

            $(this).attr('id', CounterID);
            $(this).attr('name', CounterID);

            $(this).addClass('Validate_Required');

            // set error controls
            $(this).parent().find('#' + ID + 'Error').attr('id', CounterID + 'Error');
            $(this).parent().find('#' + ID + 'Error').attr('name', CounterID + 'Error');

            $(this).parent().find('#' + ID + 'ServerError').attr('id', CounterID + 'ServerError');
            $(this).parent().find('#' + ID + 'ServerError').attr('name', CounterID + 'ServerError');

            // add event handler to remove button
            if($(this).is('[data-formelement-remove]')) {
                var DestinationName        = $(this).data('formelementRemoveDestinationName'),
                    DestinationNameCounter = DestinationName + '_' + Counter;

                $(this).removeAttr("data-formelement-remove-destination-name");
                $(this).attr( 'data-formelement-remove-destination-name', DestinationNameCounter );
                $(this).data( 'formelementRemoveDestinationName', DestinationNameCounter );

                $SourceClone.removeAttr("data-formelement-remove-destination");
                $SourceClone.attr( 'data-formelement-remove-destination', DestinationNameCounter );
                $SourceClone.data( 'formelementRemoveDestination', DestinationNameCounter );

                // bind click function to remove button
                $(this).on('click', function () {
                    TargetNS.Remove($(this));
                    return false;
                });
            }
        });

        $SourceClone.find('label').each(function(){
            var For = $(this).attr('for');
            $(this).attr('for', For + '_' + Counter);
        });

        // append to container
        $Destination[Method]($SourceClone);

        // set new counter
        $Counter.val(Counter);

        // Modernize
        Core.UI.InputFields.Activate();

        return false;
    };


    /**
     * @name Remove
     * @memberof Core.Znuny4OTRS.Form.Generic
     * @function
     * @returns {Boolean} Returns false
     * @param {Object} RemoveElement - Object of the clicked remove element.
     *
     * data-formelement-remove                                              # if empty use following data attributes:
     * data-formelement-remove-destination-name='AdditionalDFStorage'       # name of destination element
     *
     * data-formelement-remove='.Header'                                    # if string contains class syntax - remove all elements with this class
     * data-formelement-remove='#Header'                                    # if string contains id syntax - remove all elements with this id
     *
     * @description
     *      This function removes a value from possible values list,
     *      removes elements via class or id selector.
     */
    TargetNS.Remove = function (RemoveElement){
        var $Destination,
            Param = {};

        $.each(RemoveElement.data(), function(Key, Value) {
            Param[Key] = Value || '';
        });

        // removes element from data-formelement-remove-destination-name = 'AdditionalDFStorage'
        if (
            Param['formelementRemoveDestinationName'].length
            && $('[data-formelement-remove-destination="' + Param['formelementRemoveDestinationName'] + '"]').length
        ){
            $Destination = $('[data-formelement-remove-destination="' + Param['formelementRemoveDestinationName'] + '"]');
        }

        // removes elements from data-formelement-remove = '.Header'
        else if (Param['formelementRemove'].length &&  Param['formelementRemove'].startsWith(".") || Param['formelementRemove'].startsWith("#")) {
            $Destination = $(Param['formelementRemove']);
        }

        $Destination.remove();

        return false;
    };

    /**
     * @name Restore
     * @memberof Core.Znuny4OTRS.Form.Generic
     * @function
     * @returns {Boolean} Returns false
     * @param {Object} RestoreElement - Object of the clicked restore element
     *
     * data-formelement-restore                                              # if empty use following data attributes:
     * data-formelement-restore-destination-name='AdditionalDFStorage'       # name of restore destination element
     *
     * @description
     *      This function restores the values list
     */
    TargetNS.Restore = function(RestoreElement) {
        var Param = {},
            DestinationName,
            $Destination;

        $.each(RestoreElement.data(), function(Key, Value) {
            Param[Key] = Value || '';
        });

        DestinationName = Param['formelementRestoreDestinationName'];
        $Destination    = $('[data-formelement-restore-destination="' + DestinationName + '"]');

        if (RestoreElements[DestinationName] && $Destination){
            $Destination.html(RestoreElements[DestinationName].html());
        }

        return false;
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Znuny4OTRS.Form.Generic || {}));
