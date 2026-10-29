#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#include <shop>

#define TOP10_CACHE_TIME 60

Database dp;
char dp_prefix[16];

// Cached result of the last top10 query, shared by every player
char g_sTopName[10][MAX_NAME_LENGTH + 1];
int g_iTopMoney[10];
int g_iTopCount;
int g_iTopCacheTime;

bool g_bLate = false;

public Plugin myinfo = 
{
	name = "[Shop] Top10 Function",
	author = "FrozDark",
	description = "Adds top10 function to the shop",
	version = "2.0.4",
	url = "http://www.hlmod.ru/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (g_bLate && Shop_IsStarted())
	{
		Shop_Started();
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	delete dp;
	dp = Shop_GetDatabase();
	g_iTopCacheTime = 0;
	Shop_GetDatabasePrefix(dp_prefix, sizeof(dp_prefix));
	
	Shop_AddToFunctionsMenu(FunctionDisplay, FunctionSelect);
}

public void FunctionDisplay(int client, char[] buffer, int maxlength)
{
	strcopy(buffer, maxlength, "Top 10 richest players");
}

public bool FunctionSelect(int client)
{
	if (g_iTopCacheTime && GetTime() - g_iTopCacheTime < TOP10_CACHE_TIME)
	{
		ShowTop10(client);
		return true;
	}
	
	if (dp == null)
	{
		return false;
	}
	
	char query[256];
	FormatEx(query, sizeof(query), "SELECT `name`, `money` FROM `%splayers` ORDER BY `money` DESC LIMIT 10", dp_prefix);
	dp.Query(GetTop10, query, GetClientSerial(client));
	
	return true;
}

public void GetTop10(Database owner, DBResultSet hndl, const char[] error, any serial) 
{ 
	if (hndl == null || error[0]) 
	{ 
		LogError("GetTop10: %s", error);
		
		return;
	}
	
	g_iTopCount = 0;
	while (g_iTopCount < sizeof(g_iTopMoney) && hndl.FetchRow())
	{
		hndl.FetchString(0, g_sTopName[g_iTopCount], sizeof(g_sTopName[]));
		g_iTopMoney[g_iTopCount] = hndl.FetchInt(1);
		g_iTopCount++;
	}
	g_iTopCacheTime = GetTime();
	
	int client = GetClientFromSerial(serial);
	if (!client)
	{
		return;
	}
	
	ShowTop10(client);
}

void ShowTop10(int client)
{
	if (!g_iTopCount)
	{
		Shop_ShowFunctionsMenu(client);
		return;
	}
		
	Panel panel = new Panel();
	panel.SetTitle("Top 10 richest players");
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	panel.DrawText("-----------------------------");
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	char display[128];
	for (int i = 0; i < g_iTopCount; i++)
	{
		FormatEx(display, sizeof(display), "%i. %s [%d]", i + 1, g_sTopName[i], g_iTopMoney[i]);
		
		panel.DrawText(display);
	}
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	panel.DrawText("-----------------------------");
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	panel.CurrentKey = 8;
	panel.DrawItem("Back");
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	panel.CurrentKey = 10;
	panel.DrawItem("Exit");
	
	panel.Send(client, PanelHandler, 30);
	delete panel;
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (param2)
	{
		case 8 :
		{
			Shop_ShowFunctionsMenu(param1);
		}
	}
	return 0;
}
