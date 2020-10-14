// --
// Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

// taken from: http://stackoverflow.com/a/2641047
// [name] is the name of the event "click", "mouseover", ..
// same as you'd pass it to on()
// [fn] is the handler function
$.fn.unshiftOn = function(name, fn) {
    // on as you normally would
    // don't want to miss out on any jQuery magic
    this.on(name, fn);

    // Thanks to a comment by @Martin, adding support for
    // namespaced events too.
    this.each(function() {
        var handlers = $._data(this, 'events')[name.split('.')[0]];

        // take out the handler we just inserted from the end
        var handler = handlers.pop();
        // move it at the beginning
        handlers.splice(0, 0, handler);
    });
};

Core.AJAX.FunctionCallSynchronous = function (URL, Data, Callback, DataType) {

    // store the original state
    // this is basically an example how to access
    // the current state of the $.ajaxSetup values
    var OriginalAsyncState = $.ajaxSetup()['async'];

    // make a custom callback that gets passed to the standard Core.AJAX.FunctionCall
    // that resets back to asynchronous AJAX calls as before and executes the regualar
    // given Callback function as usual
    var ResetCallback = function (Response) {

        // set requests back to asynchronous
        $.ajaxSetup({
            async: OriginalAsyncState
        });

        // call given callback function as usual
        Callback(Response);
    };

    // set this request as synchronous
    $.ajaxSetup({
        async: false
    });

    // start the wanted request by the framework functionality with our
    // manipulated callback function and disabled async flag
    Core.AJAX.FunctionCall(URL, Data, ResetCallback, DataType);
};

/**
 * @private
 * @name ToggleAJAXLoader
 * @memberof Core.Znuny4OTRS.App
 * @function
 * @param {String} FieldID - Id of the field which is updated via ajax
 * @param {Boolean} Show - Show or hide the AJAX loader image
 * @description
 *      Shows and hides an ajax loader for every element which is updates via ajax.
 */

Core.AJAX.ToggleAJAXLoader = function (FieldID, Show) {
    var AJAXLoaderPrefix = 'AJAXLoader',
        $Element = $('#' + FieldID),
        $Loader = $('#' + AJAXLoaderPrefix + FieldID),
        LoaderHTML = '<span id="' + AJAXLoaderPrefix + FieldID + '" class="AJAXLoader"></span>';

    // Ignore hidden fields
    if ($Element.is('[type=hidden]')) {
        return;
    }
    // Element not present, reset counter and ignore
    if (!$Element.length) {
            ActiveAJAXCalls[FieldID] = 0;
            return;
    }

    // Init counter value, if needed.
    // This counter stores the number of running AJAX requests for each field.
    // The loader image will be shown if it is > 0.
    if (typeof ActiveAJAXCalls[FieldID] === 'undefined') {
        ActiveAJAXCalls[FieldID] = 0;
    }

    // Calculate counter
    if (Show) {
        ActiveAJAXCalls[FieldID]++;
    }
    else {
        ActiveAJAXCalls[FieldID]--;
        if (ActiveAJAXCalls[FieldID] <= 0) {
            ActiveAJAXCalls[FieldID] = 0;
        }
    }

    // Show or hide the loader
    if (ActiveAJAXCalls[FieldID] > 0) {
        if (!$Loader.length) {
            $Element.after(LoaderHTML);
        }
        else {
            $Loader.show();
        }
    }
    else {
        $Loader.hide();
    }
};
