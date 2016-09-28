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
 * @exports TargetNS as Core.Znuny4OTRSApp
 * @description
 *      This namespace contains the special module functions Znuny4OTRSApp.
 */

Core.Znuny4OTRSApp = (function (TargetNS) {

    /*

    This function checks if all needed params are defined.

    var ParamCheckSuccess = Core.Znuny4OTRSApp.ParamCheck(Param, ['ID', 'Action', 'TicketID', 'Text', 'Title']);

    */

    TargetNS.ParamCheck = function (Param, Content) {

        var ParamCheckSuccess = true;
        $.each(Content, function (Index, ParameterName) {

            // skip valid parameters
            if (typeof Param[ ParameterName ] != 'undefined') return true;

            // cancel loop and keep missing parameter in mind
            ParamCheckSuccess = false;
            return false;
        });

        return ParamCheckSuccess;
    };

    return TargetNS;

}(Core.Znuny4OTRSApp || {}));
