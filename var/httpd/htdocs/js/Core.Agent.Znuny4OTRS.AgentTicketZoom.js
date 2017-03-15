// --
// Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core              = Core || {};
Core.Agent            = Core.Agent || {};
Core.Agent.Znuny4OTRS = Core.Agent.Znuny4OTRS || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.Znuny4OTRS.AgentTicketZoom
 * @description
 *      This namespace contains the special module functions for AgentTicketZoom.
 */

Core.Agent.Znuny4OTRS.AgentTicketZoom = (function (TargetNS) {

    /*

    This function adds a Function / Button to ArticleMenu.

    Core.Agent.Znuny4OTRS.AgentTicketZoom.AddArticleMenu({
        ID:       'NewFunction',
        Action:   'AgentTicketNote',
        TicketID: 237,
        Title:    'TranslateTitle',
        Text:     'This function is epic',
        Position: 'append'                   # optional -  'append' | 'prepend' | 5 | 3
    });

    */

    TargetNS.AddArticleMenu = function (Param) {

        var ParamCheckSuccess = Core.Znuny4OTRS.App.ParamCheck(Param, ['ID', 'Action', 'TicketID', 'Text', 'Title']);
        if (!ParamCheckSuccess) return;

        // check if at least one article exists
        if ($('#ArticleItems div a').length == 0) return;

        // update call when another item is selected
        Core.App.Subscribe('Event.AJAX.ContentUpdate.Callback', function() {
            TargetNS.AddArticleMenu(Param);
        });

        // return if new article menu item always exists
        if ($('#' + Param['ID']).length != 0){
            return;
        }

        var ArticleID = $('#ArticleItems div a').attr('name').replace('Article', '');

        var URL = Core.Znuny4OTRS.App.URL({
            Action:    Param['Action'],
            TicketID:  Param['TicketID'],
            ArticleID: ArticleID
        });

        var Link = $('<a/>', {
            text:  Param['Text'],
            id:    Param['ID'],
            href:  URL,
            class: 'AsPopup PopupType_TicketAction',
            title: Param['Title']
        });

        var ListItem = $('<li/>').append(Link);

        // possibly needed in the future
        // var numberRegex = /^(\d+)?$/;
        // if(Param['Position'] && numberRegex.test(Param['Position'])) {
        //     $('#ArticleItems > div:nth-child(1) > div > div.LightRow.Bottom > ul > li:nth-child(' + Param['Position'] + ')').prepend(ListItem);
        // }

        if (Param['Position'] && Param['Position'] == 'prepend'){
            $('#ArticleItems div div ul.Actions').prepend(ListItem);
        }
        else{
            $('#ArticleItems div div ul.Actions').append(ListItem);
        }

        return ListItem;
    };

    return TargetNS;

}(Core.Agent.Znuny4OTRS.AgentTicketZoom || {}));
