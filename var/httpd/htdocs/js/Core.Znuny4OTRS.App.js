// --
// Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core        = Core || {};
Core.Znuny4OTRS = Core.Znuny4OTRS || {};

/**
 * @namespace
 * @exports TargetNS as Core.Znuny4OTRS.App
 * @description
 *      This namespace contains the special module functions Znuny4OTRS.App.
 */

Core.Znuny4OTRS.App = (function (TargetNS) {

    /*

    This function checks if all needed params are defined.

    var ParamCheckSuccess = Core.Znuny4OTRS.App.ParamCheck(Param, ['ID', 'Action', 'TicketID', 'Text', 'Title']);

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


    /*

    This function creates URL.

    var URL = Core.Znuny4OTRS.App.URL({
        Action:    Param['Action'],
        TicketID:  Param['TicketID'],
        ArticleID: ArticleID
    });

    */

    TargetNS.URL = function (Param) {

        var URL;
        URL = Core.Config.Get('Baselink') + TargetNS.SerializeData(Param);
        URL += TargetNS.SerializeData(Core.App.GetSessionInformation());

        return URL;
    };


    /*

    This function creates URL.

    The encodeURIComponent() function encodes a URI component.

    var EncodedURI = Core.Znuny4OTRS.App.SerializeData(Data);

    */

    TargetNS.SerializeData = function (Data) {

        var QueryString = '';

        $.each(Data, function (Key, Value) {
            QueryString += encodeURIComponent(Key) + '=' + encodeURIComponent(Value) + ';';
        });

        return QueryString;
    }

    return TargetNS;

}(Core.Znuny4OTRS.App || {}));
