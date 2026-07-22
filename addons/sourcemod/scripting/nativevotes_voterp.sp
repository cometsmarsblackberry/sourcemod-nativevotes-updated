#include <sourcemod>
#include <multicolors>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <nativevotes>
#define REQUIRE_PLUGIN

#define PLUGIN_PREFIX "[\x04NativeVotes\x01]"

public Plugin myinfo =
{
	name = "NativeVotes | Medieval Auto-RP",
	author = "Heapons",
	description = "Provides Medieval Auto-RP voting.",
	version = "26w15a",
	url = "https://github.com/Heapons/sourcemod-nativevotes-updated/"
};

enum
{
    tf_medieval,
    tf_medieval_autorp,
    sv_vote_timer_duration,

    MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];

bool g_NativeVotes;

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("nativevotes.phrases.txt");

    g_ConVars[tf_medieval] = FindConVar("tf_medieval");
    g_ConVars[tf_medieval_autorp] = FindConVar("tf_medieval_autorp");
    if (FindSendPropInfo("CTFGameRulesProxy", "m_bPlayingMedieval") <= 0)
    {
        SetFailState("This game doesn't support Medieval Mode.");
    }

    g_ConVars[sv_vote_timer_duration] = FindConVar("sv_vote_timer_duration");

    RegConsoleCmd("sm_voterp", Command_VoteRP, "Vote to toggle 'tf_medieval_autorp'.");
}

public void OnAllPluginsLoaded()
{
    g_NativeVotes = LibraryExists("nativevotes");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "nativevotes", false))
    {
        g_NativeVotes = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "nativevotes", false))
    {
        g_NativeVotes = false;
    }
}

int MenuHandler_VoteRP(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_VoteEnd:
        {
            int item = param1;
            char info[8];
            menu.GetItem(item, info, sizeof(info));
            int value = StringToInt(info);
            g_ConVars[tf_medieval_autorp].SetInt(value);
            CPrintToChatAll(PLUGIN_PREFIX ... " %t", value ? "NativeVotes Medieval RP Enabled" : "NativeVotes Medieval RP Disabled");
        }
        case MenuAction_End:
        {
            delete menu;
        }
        case MenuAction_Display:
        {
            char phrase[64], title[128];
            menu.GetTitle(phrase, sizeof(phrase));
            Format(title, sizeof(title), "%T", phrase, param1);

            Panel panel = view_as<Panel>(param2);
            panel.SetTitle(title);
        }
        case MenuAction_DisplayItem:
        {
            char info[8], phrase[64], display[64];
            menu.GetItem(param2, info, sizeof(info), _, phrase, sizeof(phrase));
            Format(display, sizeof(display), "%T", phrase, param1);
            return RedrawMenuItem(display);
        }
    }
    return 0;
}

Action Command_VoteRP(int client, int args)
{
    if (!client || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if ((g_NativeVotes && NativeVotes_IsVoteInProgress()) || (!g_NativeVotes && IsVoteInProgress()))
    {
        CPrintToChat(client, PLUGIN_PREFIX ... " %t", "Vote in Progress");
        return Plugin_Handled;
    }

    bool isMedieval = g_ConVars[tf_medieval].BoolValue || GameRules_GetProp("m_bPlayingMedieval") || FindEntityByClassname(-1, "tf_logic_medieval") != -1;
    if (!isMedieval)
    {
        CPrintToChat(client, PLUGIN_PREFIX ... " %t", "NativeVotes Medieval RP Only");
        return Plugin_Handled;
    }

    bool enabled = g_ConVars[tf_medieval_autorp].BoolValue;

    if (g_NativeVotes)
    {
        NativeVote vote = NativeVotes_Create(VoteHandler, NativeVotesType_Custom_YesNo, MENU_ACTIONS_ALL);
        NativeVotes_SetTitle(vote, enabled ? "NativeVotes Medieval RP Disable Title" : "NativeVotes Medieval RP Enable Title");
        NativeVotes_SetInitiator(vote, client);
        NativeVotes_AddItem(vote, enabled ? "0" : "1", enabled ? "NativeVotes Medieval RP Disable" : "NativeVotes Medieval RP Enable");
        NativeVotes_AddItem(vote, enabled ? "1" : "0", enabled ? "NativeVotes Medieval RP Enable" : "NativeVotes Medieval RP Disable");
        NativeVotes_DisplayToAll(vote, g_ConVars[sv_vote_timer_duration].IntValue);
    }
    else
    {
        Menu menu = new Menu(MenuHandler_VoteRP, MENU_ACTIONS_ALL);
        menu.SetTitle(enabled ? "NativeVotes Medieval RP Disable Title" : "NativeVotes Medieval RP Enable Title");
        menu.AddItem(enabled ? "0" : "1", enabled ? "NativeVotes Medieval RP Disable" : "NativeVotes Medieval RP Enable");
        menu.AddItem(enabled ? "1" : "0", enabled ? "NativeVotes Medieval RP Enable" : "NativeVotes Medieval RP Disable");
        menu.ExitButton = false;
        menu.DisplayVoteToAll(g_ConVars[sv_vote_timer_duration].IntValue);
    }

    return Plugin_Handled;
}

int VoteHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_VoteEnd:
        {
            int item = param1;
            char info[8];
            NativeVotes_GetItem(vote, item, info, sizeof(info));
            int value = StringToInt(info);
            g_ConVars[tf_medieval_autorp].SetInt(value);
            NativeVotes_DisplayPassCustom(vote, "%t", value ? "NativeVotes Medieval RP Enabled" : "NativeVotes Medieval RP Disabled");
        }
        case MenuAction_End:
        {
            NativeVotes_Close(vote);
        }
        case MenuAction_Display:
        {
            char phrase[64], title[128];
            NativeVotes_GetTitle(vote, phrase, sizeof(phrase));
            Format(title, sizeof(title), "%T", phrase, param1);
            return view_as<int>(NativeVotes_RedrawVoteTitle(title));
        }
        case MenuAction_DisplayItem:
        {
            char info[8], phrase[64], display[64];
            NativeVotes_GetItem(vote, param2, info, sizeof(info), phrase, sizeof(phrase));
            Format(display, sizeof(display), "%T", phrase, param1);
            return view_as<int>(NativeVotes_RedrawVoteItem(display));
        }
    }
    return Plugin_Continue;
}
