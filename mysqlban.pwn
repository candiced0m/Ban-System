#define FILTERSCRIPT

#include <a_samp>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>
#include <easyDialog>

#if defined FILTERSCRIPT

new MySQL: Database;

public OnFilterScriptInit()
{
    /*new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	Database = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE, option_id);
	if(Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0)
	{
		print("The server couldn't connect to the MySQL Database");
		SendRconCommand("exit");
		return 1;
	}
	else
		print("Connection to MySQL database was successful.");*/
		
 	print("\n--------------------------------------");
	print("Ban / Unban system by willbedie (MySQL)");
	print("--------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	new query[100];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `bans` WHERE (`User`='%e');", GetName(playerid));
	mysql_tquery(Database, query, "CheckPlayer", "d", playerid); // Check if the player is banned
	return 1;
}

forward CheckPlayer(playerid); // We are going to check the player who is logging in
public CheckPlayer(playerid)
{
	if(cache_num_rows() != 0) // If the player is currently banned.
	{
	    new Username[24], BannedBy[24], BanReason[70];
	    cache_get_value_name(0, "Username", Username); // Retreive the username from the mysql database
	    cache_get_value_name(0, "BannedBy", BannedBy); // Retreive the admin's name from the mysql database
	    cache_get_value_name(0, "BanReason", BanReason); // Retreive the ban reason from the mysql database

	    SendClientMessage(playerid, -1, "{D93D3D}You are banned from this server."); // Send a message to the player to tell him he's banned
	    new string[500];
	    format(string, sizeof(string), "{FFFFFF}You are banned from this server\n{D93D3D}Username: {FFFFFF}%s\n{D93D3D}Banned by: {FFFFFF}%s\n{D93D3D}Ban Reason: {FFFFFF}%s", Username, BannedBy, BanReason);
	    Dialog_Show(playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "Ban Info", string, "Close", "");  // Show this dialog to the player.
	    SetTimerEx("SendToKick", 400, false, "i", playerid); // Kick the player in 400 miliseconds.
	}
	else
	{
		//Log the player in here
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}


forward SendToKick(playerid);
public SendToKick(playerid)
{
	Kick(playerid);
	return 1;
}

GetName(playerid)
{
	new Name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, Name, sizeof(Name));
	return Name;
}

CMD:ban(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "SERVER: You are not authorized to use that command."); // If the player is not logged into rcon
    
	new PlayerIP[17];
	new giveplayerid, reason[70], string[150], query[150];
	GetPlayerIp(giveplayerid, PlayerIP, sizeof(PlayerIP)); // We are going to get the target's IP with this.
	
	if(sscanf(params, "us[70]", giveplayerid, reason)) return SendClientMessage(playerid, -1, "USAGE: /ban [playerid] [reason]"); // This will show the usage of the command after the player types /ban
	if(!IsPlayerConnected(giveplayerid)) return SendClientMessage(playerid, -1, "That player is not connected"); // If the target is not connected.
	
	mysql_format(Database, query, sizeof(query), "INSERT INTO `bans` (`Username`, `BannedBy`, `BanReason`, `IpAddress`) VALUES ('%e', '%e', '%e', '%e')", GetName(giveplayerid), GetName(playerid), reason, PlayerIP);
	mysql_tquery(Database, query, "", ""); // This will insert the information into the bans table.

	format(string, sizeof(string), "SERVER: %s[%d] was banned by %s, Reason: %s", GetName(giveplayerid), giveplayerid, GetName(playerid), reason); // This message will be sent to every player online.
	SendClientMessageToAll(-1, string);
	SetTimerEx("SendToKick", 500, false, "d", giveplayerid); // Kicks the player in 500 miliseconds.
	return 1;
}

CMD:unban(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "SERVER: You are not authorized to use that command.");
	
	new name[MAX_PLAYER_NAME], query[150], string[150], rows;
	if(sscanf(params, "s[70]", name)) return SendClientMessage(playerid, -1, "USAGE: /unban [name]"); // This will show the usage of the command if the player types only /unban.
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `bans` WHERE `Username` = '%e' LIMIT 0, 1", name);
	new Cache:result = mysql_query(Database, query);
	cache_get_row_count(rows);
	
	if(!rows)
	{
	    SendClientMessage(playerid, -1, "SERVER: That name does not exist or there is no ban under that name.");
	}
	
 	for (new i = 0; i < rows; i ++)
	{
	    mysql_format(Database, query, sizeof(query), "DELETE FROM `bans` WHERE User = '%e'", name);
	    mysql_tquery(Database, query);
     	for(new x; x < MAX_PLAYERS; x++)
     	{
	        if(IsPlayerAdmin(x))
	        {
				format(string, sizeof(string), "AdminWarn: %s(%d) has unbanned %s", GetName(playerid), name);
				SendClientMessage(x, -1, string);
	        }
	    }
	}
	cache_delete(result);
	return 1;
}
#endif