#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#include <shop>

Database dp;
char dp_prefix[16];

bool g_bLate = false;

public Plugin myinfo = 
{
	name = "[Shop] Top10 Function",
	author = "FrozDark",
	description = "Adds top10 function to the shop",
	version = "2.0.3",
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
	dp = Shop_GetDatabase();
	Shop_GetDatabasePrefix(dp_prefix, sizeof(dp_prefix));
	
	Shop_AddToFunctionsMenu(FunctionDisplay, FunctionSelect);
}

public void FunctionDisplay(int client, char[] buffer, int maxlength)
{
	strcopy(buffer, maxlength, "Top 10 richest players");
}

public bool FunctionSelect(int client)
{
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
	
	int client = GetClientFromSerial(serial);
	if (!client)
	{
		return;
	}
	
	int count = hndl.RowCount;
	if (count > 10)
	{
		count = 10;
	}
	else if (!count)
	{
		Shop_ShowFunctionsMenu(client);
		return;
	}
		
	Panel panel = new Panel();
	panel.SetTitle("Top 10 richest players");
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	panel.DrawText("-----------------------------");
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	char display[128], name[MAX_NAME_LENGTH + 1], money;
	for (int i = 1; i <= count; i++)
	{
		hndl.FetchRow();
		
		hndl.FetchString(0, name, sizeof(name));
		money = hndl.FetchInt(1);
		
		FormatEx(display, sizeof(display), "%i. %s [%d]", i, name, money);
		
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
