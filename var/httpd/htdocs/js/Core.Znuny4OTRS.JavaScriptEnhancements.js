// --
// Core.Znuny4OTRS.JavaScriptEnhancements.js - provides additional functions for the OTRS JavaScript namespace
// Copyright (C) 2014 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

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
