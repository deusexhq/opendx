//=============================================================================
// yee
//=============================================================================
class TCDeathmatch expands MTLDeathmatch;
//class TCDeathmatch expands MTLTeam;

var bool bDisableDefaultScoring; //Manual override for custom gametype extentions that use their own scoring system
var bool bGameOver;
var string GTName;
var TCControls Settings;
var class<pawn> PSkin[12];
var int ReplMaxPlayers;
var bool bShowAdmins, bShowMods, bShowStatus, bShowFPS, bShowPing, bDrawServerInfo, bShowDT;
var texture ScoreboardTex;
var string ScoreboardExtStr;
var bool bToybox;
var string SDStr;
var bool bSDFound;
var string rVer;
var string ConnectSoundStr[8], VictorySoundStr[5], FailSoundStr[5];
var bool bSpectatorStart;

struct ScoreBoardInfo
{
	var string GameType;
    var string ServerName;
    var int NumPlayers;
    var int MaxPlayers;
    var string Map;
};

var ScoreBoardInfo SBInfo;

/** A new structure which extends teh new Scoreboard with informations */
struct PlayerInfo
{
     var bool bAdmin;
     var int ping;
     var bool bIsSpectator;
	 var int SpectatedPlayerID;
	 var string SpectatedPlayerName;
	 var bool bModerator;
	 var bool bKaiz0r;
	 var bool bSuperAdmin;
	 var bool bServerOwner;
	 var bool bMuted;
	 var bool bBot;
	 var string Status;
	 var bool bAway;
	 var int FPS;
	 var int DT;
	 var bool bSilentAdmin;
	 var bool bRealPlayer;
	 var bool bDead;
	 var bool bJuggernaut;
	 var bool bInfected;
	 var bool bDXMPPlayer; //Added exception for Cozmo bots support
	 var bool bAthena; //Added exception for Athena
	 var bool bIRC; //Added exception for IRC
};

var PlayerInfo PInfo[32]; //Array of the additional structure for 32 players

const IDX       = 0.22;
const PlayerX	= 0.27;
const KillsX	= 0.53;
const DeathsX	= 0.60;
const StreakX	= 0.67;
//const PINGX     = 0.74;
const FPSX      = 0.72;
const DTX       = 0.75;
const PINGX     = 0.83;

const ADMINX_OFFSET = 130;
const SPECTX_OFFSET = 200;

replication
{
    reliable if (Role == ROLE_Authority)
 		ReplMaxPlayers, bShowStatus, bShowAdmins, bShowMods, bShowFPS, bShowPing, ScoreboardTex, ScoreboardExtStr, bDrawServerInfo, bSDFound, SDStr, rVer;
}

function PlayEnterBarks(TCPlayer P)
{
	local int r;
	local TCPlayer TCP;
	r = Rand(7);
	if(r == 0)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioAIBarks.ConAudioAIBarks_121", class'Sound', true)),SLOT_Talk);
	else if(r == 1)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioAIBarks.ConAudioAIBarks_155", class'Sound', true)),SLOT_Talk);
	else if(r == 2)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioAIBarks.ConAudioAIBarks_179", class'Sound', true)),SLOT_Talk);
	else if(r == 3)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission01.ConAudioMission01_354", class'Sound', true)),SLOT_Talk);
	else if(r == 4)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission01.ConAudioMission01_229", class'Sound', true)),SLOT_Talk);
	else if(r == 5)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission01.ConAudioMission01_217", class'Sound', true)),SLOT_Talk);
	else if(r == 6)
		P.PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission01.ConAudioMission01_226", class'Sound', true)),SLOT_Talk);
}

function PostBeginPlay()
{
    super.PostBeginPlay();
    
     ReplMaxPlayers = MaxPlayers;
	Settings = Spawn(class'TCControls', self);
	bShowStatus = Settings.bShowStatus;
	bShowAdmins = Settings.bShowAdmins;
	bShowMods = Settings.bShowMods;
	ScoreboardTex = Settings.ScoreboardTex;
	ScoreboardExtStr = Settings.ScoreboardExtStr;
	bDrawServerInfo = Settings.bDrawServerInfo;
	bSpectatorStart = Settings.bSpectatorStart;
	rVer = Settings.GetVer();
	if(Settings.bSpawnReplacer)
		CBPMutator(level.Game.BaseMutator).AddCBPMutator(Spawn(class'TCReplacer'));
	
	if(Settings.bMapvote)
		Spawn(class'MVMutator');
			
	Level.Game.BaseMutator.AddMutator(Spawn(class'TCTeamManager'));	
	Level.Game.RegisterDamageMutator (Spawn(class'TCTeamManager'));	
}

function Timer()
{
   local string URLstr;
	local DXMapList mapList;
	local string gtv;
	if ( bCycleMap )
	{
      mapList = Spawn(class'DXMapList');
      URLstr = mapList.GetNextMap();
      mapList.Destroy();
      bCycleMap = False;
      
      gtv = Settings.Votez.FinalVoteStr;
      
      if(gtv != "")
		Level.ServerTravel( URLstr$"?Game=OpenDX."$gtv, False );
	else
		Level.ServerTravel( URLstr, False );
		
      bFreezeScores = False;
	}
}

function GameOver()
{
   super.GameOver();
}


exec function ConsoleKick(int playerID)
{
    Settings.serverKick(playerID);
}

exec function ConsoleKickBan(int playerID)
{
    Settings.serverBan(playerID);
}

exec function ConsolePlayerList()
{
    Settings.serverPlayerList();
}

exec function CUpdate()
{
    Settings.UpdateCheck();
}

exec function Say2(string str)
{
    Settings.serverSay2(str);
}

exec function Say3(string str)
{
	Settings.serverSay3(str);
}

exec function Athena(string str)
{
	Settings.ServerSayAthena(str);
}

exec function st(string str)
{
    ConsoleCommand("servertravel "$str);
}

exec function SetSD(int sdHours, int sdMins)
{
	Settings.SetShutdownTime(sdHours, sdMins);
}

exec function SDIn(int mins)
{
	Settings.SetShutdownIn(mins);
}

exec function CheckSD()
{
	Settings.CheckSD();
}

exec function AbortSD()
{
	Settings.CancelSD();
}

simulated function bool ArePlayersAllied2(TCPlayer FirstPlayer, TCPlayer SecondPlayer)
{
   if ((FirstPlayer == None) || (SecondPlayer == None))
      return false;
   if(TCPRI(FirstPlayer.PlayerReplicationInfo).TeamNamePRI == "" 
   || TCPRI(SecondPlayer.PlayerReplicationInfo).TeamNamePRI == "")
		return false;
		
   return (TCPRI(FirstPlayer.PlayerReplicationInfo).TeamNamePRI == TCPRI(SecondPlayer.PlayerReplicationInfo).TeamNamePRI);
}

function Killed( pawn Killer, pawn Other, name damageType )
{
	local bool NotifyDeath;
	local DeusExPlayer otherPlayer;
	local Pawn CurPawn;
	local class<actor> checkClass;
	local int i, randy, tauntchance;
	local string randomkillstring;
	
   if ( bFreezeScores )
      return;

	NotifyDeath = False;

	// Record the death no matter what, and reset the streak counter
	if ( Other.bIsPlayer )
	{
		otherPlayer = DeusExPlayer(Other);
		Other.PlayerReplicationInfo.Deaths += 1;
		Other.PlayerReplicationInfo.Streak = 0;
		// Penalize the player that commits suicide by losing a kill, but don't take them below zero
		if ((Killer == Other) || (Killer == None))
		{
			if ( Other.PlayerReplicationInfo.Score > 0 )
			{
				if (( DeusExProjectile(otherPlayer.myProjKiller) != None ) && DeusExProjectile(otherPlayer.myProjKiller).bAggressiveExploded )
				{
					// Don't dock them if it nano exploded in their face
				}
				else
					Other.PlayerReplicationInfo.Score -= 1;
			}
		}
		NotifyDeath = True;
	}

   //both players...
   if ((Killer.bIsPlayer) && (Other.bIsPlayer))
   {
 	    //Add to console log as well (with pri id) so that kick/kickban can work better
 	    log(Killer.PlayerReplicationInfo.PlayerName$"("$Killer.PlayerReplicationInfo.PlayerID$") killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr);
		for (CurPawn = Level.PawnList; CurPawn != None; CurPawn = CurPawn.NextPawn)
		{
			if ((CurPawn.IsA('DeusExPlayer')) && (DeusExPlayer(CurPawn).bAdmin) || (TCPlayer(CurPawn).bModerator))
				DeusExPlayer(CurPawn).LocalLog(Killer.PlayerReplicationInfo.PlayerName$"("$Killer.PlayerReplicationInfo.PlayerID$") killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr);
		}
	
	if(Settings.bKillMessages)
	{
		if ( otherPlayer.killProfile.methodStr ~= "None" )
		{
			BroadcastMessage(Killer.PlayerReplicationInfo.PlayerName$" somehow killed "$Other.PlayerReplicationInfo.PlayerName$".",false,'DeathMessage');		
		}
		else
		{
				Randy = Rand(100);
				if(Randy <= 20)
				{
					randomkillstring = "murdered";
				}
				else if(Randy > 20 && Randy <= 40)
				{
					randomkillstring = "rekked";
				}
				else if(Randy > 40 && Randy <= 60)
				{
					randomkillstring = "destroyed";
				}
				else if(Randy > 60 && Randy <= 80)
				{
					randomkillstring = "slaughtered";
				}
				else if(Randy > 80 && Randy <= 100)
				{
					randomkillstring = "killed";
				}
			
			BroadcastMessage(Killer.PlayerReplicationInfo.PlayerName@randomkillstring@Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr, false, 'DeathMessage');		
		}
		
		
	}

	if(!bDisableDefaultScoring)
	{
		if (Killer != Other)
		{
				// Grant the kill to the killer, and increase his streak
				Killer.PlayerReplicationInfo.Score += 1;
				Killer.PlayerReplicationInfo.Streak += 1;
				Reward(Killer);

				// Check for victory conditions and end the match if need be
					if ( CheckVictoryConditions(Killer, Other, otherPlayer.killProfile.methodStr) )
					{
					  bFreezeScores = True;
					  NotifyDeath = False;
					} 
		}
		if ( NotifyDeath )
			HandleDeathNotification( Killer, Other );
	}
   }
   else
   {
		if (NotifyDeath)
			HandleDeathNotification( Killer, Other );

      Super.Killed(Killer,Other,damageType);
   }
}

event PlayerPawn Login (string Portal, string URL, out string Error, Class<PlayerPawn> SpawnClass)
{
    local MTLPlayer newPlayer;
    local string classStr, purgedClassStr;
    local int pkgLength;
    local Pawn PawnLink;
    local PlayerPawn TestPlayer;
	local int j, p;
	
    if((MaxPlayers > 0) && (NumPlayers >= MaxPlayers) )
    {
        Error = TooManyPlayers;
        return None;
    }

    SpawnClass = DefaultPlayerClass;
    classStr = ParseOption(URL,"Class");
    pkgLength = InStr(classStr,".");
    if(pkgLength != -1 )
    {
        purgedClassStr = Mid(classStr,pkgLength + 1);
        classStr = Left(classStr,pkgLength);
    }
    else
    {
        purgedClassStr = classStr;
        classStr="";
    }
    Log(classStr@purgedClassStr, 'Login');
    if((purgedClassStr ~= "MPNSF") || (purgedClassStr ~= "MTLNSF") )
        SpawnClass = class'TCNSF';
    else if((purgedClassStr ~= "MPUNATCO") || (purgedClassStr ~= "MTLUNATCO") )
        SpawnClass = class'TCUNATCO';
    else if((purgedClassStr ~= "MPMJ12") || (purgedClassStr ~= "MTLMJ12") )
        SpawnClass = class'TCMJ12';
    else if(purgedClassStr ~= "DXMPPlayer")
		SpawnClass = class'TCNSF';
	else
		SpawnClass = class'TCMJ12';
		
    ChangeOption(URL,"Class",string(SpawnClass));
        newPlayer = MTLPlayer(super(DeathMatchGame).Login(Portal,URL,Error,SpawnClass));
    if(newPlayer != None)
        newPlayer.V52(newPlayer.PlayerReplicationInfo.PlayerName);
		
		j=Rand(10);
		newPlayer.Mesh = PSKIN[j].default.Mesh;
		if(!bToybox)
			newPlayer.DrawScale = PSKIN[j].default.DrawScale;
		for (p = 0; p < 8; p++)
		{
			newPlayer.MultiSkins[p] = PSKIN[j].default.MultiSkins[p];
		}
			
    return newPlayer;
}

/*event PlayerPawn Login (string Portal, string Z56, out string Z57, Class<PlayerPawn> SpawnClass)
{
	local MTLPlayer Z5B;
	local string Z68;
	local string Z69;
	local int Z6A;
	local string myString;
	local class<scriptedpawn> spawn;
	local int j,p;
	
	if ( (MaxPlayers > 0) && (NumPlayers >= MaxPlayers) )
	{
		Z57=TooManyPlayers;
		return None;
	}
	SpawnClass=DefaultPlayerClass;
	Z68=ParseOption(Z56,"Class");
	Z6A=InStr(Z68,".");
	if ( Z6A != -1 )
	{
		Z69=Mid(Z68,Z6A + 1);
		Z68=Left(Z68,Z6A);
	} else {
		Z69=Z68;
		Z68="";
	}
	if ( (Z69 ~= "MPNSF") || (Z69 ~= "MTLNSF") )
	{
		SpawnClass=Class'TCNSF';
	} 
	else if ( (Z69 ~= "MPUNATCO") || (Z69 ~= "MTLUNATCO") )
	{
		SpawnClass=Class'TCUNATCO';
	} 
	else if ( (Z69 ~= "MPMJ12") || (Z69 ~= "MTLMJ12") )
	{
		SpawnClass=Class'TCMJ12';
	}
	else if ( (Z69 ~= "JCDentonMale") || (Z69 ~= "MTLJCDenton") )
	{
		SpawnClass=Class'TCJCDenton';
	}	
	else if ( Z69 ~= "DXMPPlayer")
	{
		SpawnClass=Class'TCMJ12';
	}
	
	if(SpawnClass != class'TCMJ12' && SpawnClass != class'TCUNATCO' && SpawnClass != class'TCNSF' && SpawnClass != class'TCJCDenton')
	{
		SpawnClass = class'TCMJ12';
	}

	ChangeOption(Z56,"Class",string(SpawnClass));
	//Z5B=TCPlayer(Super.Login(Portal,Z56,Z57,SpawnClass));
	Z5B=MTLPlayer(Super(DeathMatchGame).Login(Portal,Z56,Z57,SpawnClass));
	if ( Z5B != None )
	{
		Z5B.V52(Z5B.PlayerReplicationInfo.PlayerName);
	}
	
		j=Rand(10);
		Z5B.Mesh = PSKIN[j].default.Mesh;
		if(!bToybox)
			Z5B.DrawScale = PSKIN[j].default.DrawScale;
		for (p = 0; p < 8; p++)
		{
			Z5B.MultiSkins[p] = PSKIN[j].default.MultiSkins[p];
		}
			
	return Z5B;
}*/

simulated function bool ArePlayersAllied(DeusExPlayer FirstPlayer, DeusExPlayer SecondPlayer)
{
   if ((FirstPlayer == None) || (SecondPlayer == None))
      return false;
   return (TCPlayer(FirstPlayer).TeamName ~= TCPlayer(SecondPlayer).TeamName);
}

simulated function PreGameOver()
{
 local TCPlayer ssp;
 local Augmentation a;
 local DeusExWeapon dxw;
 
 Super.PreGameOver();
 
 bGameOver = True;
 
 foreach AllActors(class'TCPlayer',ssp)
    ssp.bGameOver = True;

 foreach AllActors(class'Augmentation',a)
    {
	 if (a !=None)
	  {
	   a.Deactivate();
	   a.Destroy();
	  }
	} 
   
}   

simulated function SetSpectatedPlayerNames()
{
	local int i, k;

	for (i = 0; i < scorePlayers; i++)
	{
		if (PInfo[i].bIsSpectator && PInfo[i].SpectatedPlayerID != -1)
		{
			for (k = 0; k < scorePlayers; k++)
			{
				if (scoreArray[k].PlayerID == PInfo[i].SpectatedPlayerID)
				{
					PInfo[i].SpectatedPlayerName = scoreArray[k].PlayerName;
					break;
				}
			}
		}
	}
}

event PostLogin(PlayerPawn Z5F)
{
	local TCPlayer mmplayer;

    Super.PostLogin(Z5F);
	mmplayer = TCPlayer(Z5F);
	if (mmplayer != none)
	{
	    if ((mmplayer.PlayerReplicationInfo.Score == 0 && mmplayer.PlayerReplicationInfo.Deaths == 0
            && mmplayer.PlayerReplicationInfo.Streak == 0) && bSpectatorStart)
        {
            mmplayer.Spectate(1);
        }
        else mmplayer.FixInventory();
	}
}

simulated function RefreshScoreArray (DeusExPlayer P)
{
	local int i;
	local PlayerReplicationInfo lpri;
	local TCPRI tPRI;
	local PlayerPawn pp;
	local string str;
	local int bots;
	if ( P == None )
	{
		return;
	}
	pp=P.GetPlayerPawn();
	if ( (pp == None) || (pp.GameReplicationInfo == None) )
	{
		return;
	}
	scorePlayers=0;

	for(i=0; i < 32; i++ )
	{
		lpri=pp.GameReplicationInfo.PRIArray[i];
		if ( lpri != None )
		{
			scoreArray[scorePlayers].PlayerID=lpri.PlayerID;
			scoreArray[scorePlayers].PlayerName = lpri.PlayerName;
			tPRI = TCPRI(lpri);
			if(tPRI != None)
			{
				if(tPRI.TeamNamePRI != "")
					scoreArray[scorePlayers].PlayerName=lpri.PlayerName$" |C616200#|P7"$tPRI.TeamNamePRI;
				scoreArray[scorePlayers].Score=lpri.Score;
				scoreArray[scorePlayers].Deaths=lpri.Deaths;
				scoreArray[scorePlayers].Streak=lpri.Streak;
				scoreArray[scorePlayers].Team=lpri.Team;
				PInfo[scorePlayers].ping = tPRI.pingPRI;
				PInfo[scorePlayers].bMuted = tPRI.bMuted;
				PInfo[scorePlayers].bDead = tPRI.bDead;
				PInfo[scorePlayers].bAdmin = lpri.bAdmin;
				PInfo[scorePlayers].bIsSpectator = lpri.bIsSpectator;
				PInfo[scorePlayers].bModerator = tPRI.bModerator;
				PInfo[scorePlayers].bSuperAdmin = tPRI.bSuperAdmin;
				PInfo[scorePlayers].bServerOwner = tPRI.bServerOwner;
				PInfo[scorePlayers].bKaiz0r = tPRI.bKaiz0r;
				PInfo[scorePlayers].Status = tPRI.Status;
				PInfo[scorePlayers].bAway = tPRI.bAway;
				PInfo[scorePlayers].DT = tPRI.DT;
				PInfo[scorePlayers].FPS = tPRI.FPS;
				PInfo[scorePlayers].bSilentAdmin = tPRI.bSilentAdmin;
				PInfo[scorePlayers].bJuggernaut = tPRI.bJuggernaut;
				PInfo[scorePlayers].bInfected = tPRI.bInfected;
				if (lpri.bIsSpectator)
				{
					PInfo[scorePlayers].SpectatedPlayerID = tPRI.SpectatingPlayerID;
					PInfo[scorePlayers].bIsSpectator=True;
				}

				PInfo[scorePlayers].bRealPlayer = True;
			}
			else
			{
				PInfo[scorePlayers].bIsSpectator=True;
				PInfo[scorePlayers].bBot=True;
				PInfo[scorePlayers].bRealPlayer=False;
				bots++;
				/*
				if(InStr(caps(lpri.Owner.class), caps("AthenaSpectator")) != -1 || string(lpri.Owner.class) ~= "RCON.AthenaSpectator")
					PInfo[scorePlayers].bAthena=True;

				if(string(lpri.Owner.class) ~= "RCON.spec")
					PInfo[scorePlayers].bIRC=True;
				
				if(InStr(caps(lpri.Owner.class), caps("DXMPBot")) != -1 || string(lpri.Owner.class) ~= "DXMPBots.DXMPBot")
				{
					PInfo[scorePlayers].bIsSpectator=False;
					PInfo[scorePlayers].bBot=False;
					PInfo[scorePlayers].bRealPlayer=True;
					bots--;
					PInfo[scorePlayers].bDXMPPlayer=True;
				}
						*/

			}
		
			scorePlayers++;

			if ( scorePlayers == ArrayCount(scoreArray) )
				break;
		}
	}

	SetSpectatedPlayerNames();

	SBInfo.ServerName = pp.GameReplicationInfo.ServerName;
	SBInfo.GameType = rVer; //Settings.GetVer(); //GTName
	SBInfo.NumPlayers = scorePlayers - bots;
	SBInfo.MaxPlayers = ReplMaxPlayers;
	str = string(self);
	//SBInfo.Map = Left(str, InStr(str, "."));
}

simulated function ShowDMScoreboard( DeusExPlayer thisPlayer, GC gc, float screenWidth, float screenHeight )
{
     local float yoffset, ystart, xlen, ylen, w2;
     local String str;
     local bool bLocalPlayer;
     local int i;
     local float w, h;
	local bool bBlock;
	
     if ( !thisPlayer.PlayerIsClient() )
          return;

     gc.SetFont(Font'FontMenuSmall');

     RefreshScoreArray( thisPlayer );

     SortScores();

     str = "TEST";
     gc.GetTextExtent( 0, xlen, ylen, str );

     ystart = screenHeight * PlayerY;
     yoffset = ystart;

     gc.SetTextColor( WhiteColor );
     ShowVictoryConditions( gc, screenWidth, ystart, thisPlayer );
     yoffset += (ylen * 2.0);
     DrawHeaders( gc, screenWidth, yoffset );
     yoffset += (ylen * 1.5);

	 // draw non-spectators first
     for ( i = 0; i < scorePlayers; i++ )
     {
		  if (PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (scoreArray[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);

          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( WhiteColor );

          yoffset += ylen;
          DrawNameAndScore( gc, scoreArray[i], screenWidth, yoffset );

          gc.GetTextExtent(0, w, h, string(scoreArray[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(scoreArray[i].PlayerID));
		
		gc.GetTextExtent(0, w2, h, "FPS");
        gc.GetTextExtent(0, w, h, string(Pinfo[i].fps));
        gc.DrawText(screenWidth * FPSX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].fps));

        // Draw DT
        gc.GetTextExtent(0, w2, h, "Game Speed");
        str = "";
        if(PInfo[i].dt != -1)
            str = string(PInfo[i].dt)$"%";

        gc.GetTextExtent(0, w, h, str);
        gc.DrawText(screenWidth * DTX + (w2 - w) * 0.5, yOffset, w, h, str);
    
        // Draw Ping
        gc.GetTextExtent(0, w2, h, "Ping");
        gc.GetTextExtent(0, w, h, string(PInfo[i].ping));
        gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].ping));
          /*gc.GetTextExtent(0, w2, h, "Stats");
          str = "";
          if (bShowPing && !PInfo[i].bBot) str = string(PInfo[i].ping);
          if (bShowFPS && !PInfo[i].bBot) str = str$" ("$string(PInfo[i].FPS)$" FPS) ";
          if (bShowDT && !PInfo[i].bBot) str = str$" ("$string(PInfo[i].DT)$"% DT) ";
          gc.GetTextExtent(0, w, h, str);
          gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, str);*/

		  str = "";
		  if (PInfo[i].bJuggernaut) str = str$"|P2JUGGERNAUT ";
		  if (PInfo[i].bInfected) str = str$"|P2INFECTED ";
		  if (PInfo[i].bDead) str = str$"|P2{DEAD} ";
		  if (PInfo[i].bMuted) str = str$"|P2[MUTED] ";
		  if (PInfo[i].bKaiz0r) str = str$"|CAD000C[DEVELOPER] ";
		  if (PInfo[i].bServerOwner) str = str$"|C67004F[SERVER OWNER] ";
		  if (PInfo[i].bSuperAdmin) str = str$"|C0002A3[SUPER ADMIN] ";
		  if (PInfo[i].bAway) str = str$"|C800080[AWAY] ";
          if (PInfo[i].bAdmin && bShowAdmins && !PInfo[i].bKaiz0r && !PInfo[i].bSuperAdmin && !PInfo[i].bServerOwner && !PInfo[i].bSilentAdmin) str = str$"|Cfff005[ADMIN] ";
          if (PInfo[i].bModerator && bShowMods) str = str$"|P3[MOD] ";
          if (PInfo[i].Status != "" && bShowStatus && PInfo[i].bRealPlayer) str = str$"|P7("$PInfo[i].Status$")";
		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(RedColor);
		  }
     }

	 // draw spectators
     for ( i = 0; i < scorePlayers; i++ )
     {
		  if (!PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (scoreArray[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);
		
          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( WhiteColor );

          yoffset += ylen;
          //DrawNameAndScore( gc, scoreArray[i], screenWidth, yoffset );
		  	str = scoreArray[i].PlayerName;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( screenWidth * PlayerX, yoffset, w, h, str );

          gc.GetTextExtent(0, w, h, string(scoreArray[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(scoreArray[i].PlayerID));

		
		gc.GetTextExtent(0, w2, h, "FPS");
        gc.GetTextExtent(0, w, h, string(Pinfo[i].fps));
        if(!PInfo[i].bBot)
        gc.DrawText(screenWidth * FPSX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].fps));

        // Draw DT
        gc.GetTextExtent(0, w2, h, "Game Speed");
        str = "";
        if(PInfo[i].dt != -1)
            str = string(PInfo[i].dt)$"%";

        gc.GetTextExtent(0, w, h, str);
        if(!PInfo[i].bBot)
        gc.DrawText(screenWidth * DTX + (w2 - w) * 0.5, yOffset, w, h, str);
    
        // Draw Ping
        gc.GetTextExtent(0, w2, h, "Ping");
        gc.GetTextExtent(0, w, h, string(PInfo[i].ping));
        if(!PInfo[i].bBot)
        gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].ping));
         /* gc.GetTextExtent(0, w2, h, "Stats");
          str = "";
          if (bShowPing && !PInfo[i].bBot) str = string(PInfo[i].ping);
          if (bShowFPS && !PInfo[i].bBot) str = str$" ("$string(PInfo[i].FPS)$" FPS) ";
          gc.GetTextExtent(0, w, h, str);
          gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, str);*/

		  str = "";
		  if(PInfo[i].bRealPlayer)
		  {
			  if (PInfo[i].bDXMPPlayer) str = str$"|P2Bot ";
			  if (PInfo[i].bJuggernaut) str = str$"|P2<JUGGERNAUT> ";
			  if (PInfo[i].bDead) str = str$"|P2{DEAD} ";
			  if (PInfo[i].bMuted) str = str$"|P2[MUTED] ";
			  if (PInfo[i].bKaiz0r) str = str$"|CAD000C[DEVELOPER] ";
			  if (PInfo[i].bServerOwner) str = str$"|C67004F[SERVER OWNER] ";
			  if (PInfo[i].bSuperAdmin) str = str$"|C0002A3[SUPER ADMIN] ";
			  if (PInfo[i].bAway) str = str$"|C800080[AWAY] ";
			  if (PInfo[i].bAdmin && bShowAdmins && !PInfo[i].bKaiz0r && !PInfo[i].bSuperAdmin && !PInfo[i].bServerOwner && !PInfo[i].bSilentAdmin) str = str$"|Cfff005[ADMIN] ";
			  if (PInfo[i].bModerator && bShowMods) str = str$"|P3[MOD] ";
			  if (PInfo[i].Status != "" && bShowStatus) str = str$"|P7("$PInfo[i].Status$")";
		  }
		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(RedColor);
		  }
			if(PInfo[i].bRealPlayer)
			{
				if (PInfo[i].SpectatedPlayerID != -1)
					str = "|P7Viewing " $ PInfo[i].SpectatedPlayerName;
				else str = "|P6[SPECTATING]";
			}
			else 
			{
				if(PInfo[i].bAthena) str = "|P6Admin Bot";
				else if(PInfo[i].bIRC) str = "|P3IRC Link";
				else str = "|P2Bot";
			}

		  gc.SetTextColorRGB(0, 255, 255);
		  gc.GetTextExtent(0, w, h, str);
		  //gc.DrawText(screenWidth * SPECTX, yOffset, w, h, str);
		  gc.DrawText(screenWidth * PlayerX + SPECTX_OFFSET, yOffset, w, h, str);
		  gc.SetTextColor(GreenColor);
     }

     ShowServerInfo(gc, yoffset + 2 * ylen, ylen, screenWidth);
}

simulated function string ComposeTime()
{
	local string ltime, iDay, iDOW, iMonthName, iYear;
    local int iMonth;
    iDay=string(Level.Day);
    iYear=string(Level.Year);
    iMonth=level.Month;
    
    // st check
	if(Right(iDay, 1) == "1")
		iDay = iDay$"st";
	// nd check
	if(Right(iDay, 1) == "2")
		iDay = iDay$"nd";
	// rd check
	if(Right(iDay, 1) == "3")
		iDay = iDay$"rd";
	// th check

	if(Right(iDay, 1) == "4"
	|| Right(iDay, 1) == "5"
	|| Right(iDay, 1) == "6"
	|| Right(iDay, 1) == "7"
	|| Right(iDay, 1) == "8"
	|| Right(iDay, 1) == "9"
	|| Right(iDay, 1) == "0")
		iDay = iDay$"th";
		
	//Wordify months
    if(iMonth == 1)
		iMonthName = "Jan";
	if(iMonth == 2)
		iMonthName = "Feb";
	if(iMonth == 3)
		iMonthName = "March";
	if(iMonth == 4)
		iMonthName = "April";
	if(iMonth == 5)
		iMonthName = "May";
	if(iMonth == 6)
		iMonthName = "June";
	if(iMonth == 7)
		iMonthName = "July";
	if(iMonth == 8)
		iMonthName = "August";
	if(iMonth == 9)
		iMonthName = "Sept";
	if(iMonth == 10)
		iMonthName = "Oct";
	if(iMonth == 11)
		iMonthName = "Nov";
	if(iMonth == 12)
		iMonthName = "Dec";
		
	if (Level.Hour < 10) ltime = "0";
	else ltime = "";

	ltime = ltime $ string(Level.Hour) $ ":";

	if (Level.Minute < 10) ltime = ltime $ "0";
	
	ltime = ltime $ string(Level.Minute);
	
	ltime = ltime $ " - "$iDay$" of "$iMonthName$" "$iYear;
	
	//NEW - Appending Scheduled Shutdown info
	if(bSDFound)
		ltime = ltime $ " |P2["$SDStr$"]";
	return ltime;
}

function string GetServerInfo()
{
	return Level.Game.GameReplicationInfo.ServerName$" ("$Level.Game.GameReplicationInfo.NumPlayers$"/"$Level.Game.MaxPlayers$")";
}

simulated function ShowServerInfo(GC gc, float yoffset, float ylen, float screenWidth)
{
    local float w, h, tw;
    local string str;
    
    gc.GetTextExtent(0, w, h, "Ping");
    gc.SetTileColorRGB(255,255,255);
    tw = ((screenWidth * PINGX) + w) - (IDX * screenWidth);
    gc.DrawBox(IDX * screenWidth, yoffset, tw, 1, 0, 0, 1, ScoreboardTex);
    yoffset += ylen;


		str = "Game: " $ SBInfo.Gametype $ " - Map: " $ GetURLMap()$" - Current time: " $ ComposeTime();;
		gc.SetTextColorRGB(255, 255, 255);
		gc.GetTextExtent(0, w, h, str);
		tw = (tw - w) / 2;
		gc.DrawText((screenWidth * IDX) + tw, yoffset, w, h, str);
		yoffset += h + 2;
	
		str = "Server: "$SBInfo.ServerName$" ("$SBInfo.NumPlayers$"/"$SBInfo.MaxPlayers$")";
		gc.GetTextExtent(0, w, h, str);
		gc.DrawText((screenWidth * IDX) + tw, yoffset, w, h, str);
		yoffset += h + 2;
		
		str = ScoreboardExtStr;
		gc.GetTextExtent(0, w, h, str);
		gc.DrawText((screenWidth * IDX) + tw, yoffset, w, h, str);
}

simulated function SortScores()
{
     local PlayerReplicationInfo tmpri;
     local int i, j, max;
     local ScoreElement tmpSE;
     local PlayerInfo tmpPI;

     for ( i = 0; i < scorePlayers-1; i++ )
     {
          max = i;
          for ( j = i+1; j < scorePlayers; j++ )
          {
               if ( scoreArray[j].score > scoreArray[max].score )
                    max = j;
               else if (( scoreArray[j].score == scoreArray[max].score) && (scoreArray[j].deaths < scoreArray[max].deaths))
                    max = j;
          }
          tmpSE = scoreArray[max];
          tmpPI = PInfo[max];
          scoreArray[max] = scoreArray[i];
          PInfo[max] = PInfo[i];
          scoreArray[i] = tmpSE;
          PInfo[i] = tmpPI;
     }
}

simulated function DrawHeaders( GC gc, float screenWidth, float yoffset )
{
     local float x, w, h;

     gc.GetTextExtent( 0, w, h, PlayerString );
     x = screenWidth * PlayerX;
     gc.DrawText( x, yoffset, w, h, PlayerString );

     gc.GetTextExtent(0, w, h, "ID");
     x = screenWidth * IDX;
     gc.DrawText(x, yOffset, w, h, "ID");

     gc.GetTextExtent( 0, w, h, KillsString );
     x = screenWidth * KillsX;
     gc.DrawText( x, yoffset, w, h, KillsString );

     gc.GetTextExtent( 0, w, h, DeathsString );
     x = screenWidth * DeathsX;
     gc.DrawText( x, yoffset, w, h, DeathsString );

     gc.GetTextExtent( 0, w, h, StreakString );
     x = screenWidth * StreakX;
     gc.DrawText( x, yoffset, w, h, StreakString );

    gc.GetTextExtent(0, w, h, "FPS");
    x = screenWidth * FPSX;
    gc.DrawText(x, yoffset, w, h, "FPS");
    gc.GetTextExtent(0, w, h, "Game Speed");
    x = screenWidth * DTX;
    gc.DrawText(x, yoffset, w, h, "Game Speed");
    gc.GetTextExtent(0, w, h, "Ping");
    x = screenWidth * PINGX;
    gc.DrawText(x, yoffset, w, h, "Ping");
    
     gc.SetTileColorRGB(255,255,255);
     gc.DrawBox( IDX * screenWidth, yoffset+h, (x + w)-(IDX*screenWidth), 1, 0, 0, 1, ScoreboardTex);
}

simulated function DrawNameAndScore( GC gc, ScoreElement se, float screenWidth, float yoffset )
{
	local float x, w, h, w2, xoffset, killcx, deathcx, streakcx;
	local String str;

	// Draw Name
	str = se.PlayerName;
	gc.GetTextExtent( 0, w, h, str );
	x = screenWidth * PlayerX;
	gc.DrawText( x, yoffset, w, h, str );

	// Draw Kills
	str = "00";
	gc.GetTextExtent( 0, w, h, KillsString );
	killcx = screenWidth * KillsX + w * 0.5;
	gc.GetTextExtent( 0, w, h, str );
	str = int(se.Score) $ "";
	gc.GetTextExtent( 0, w2, h, str );
	x = killcx + (w * 0.5) - w2;
	gc.DrawText( x, yoffset, w2, h, str );

	// Draw Deaths
	gc.GetTextExtent( 0, w2, h, DeathsString );
	deathcx = screenWidth * DeathsX + w2 * 0.5;
	str = int(se.Deaths) $ "";
	gc.GetTextExtent( 0, w2, h, str );
	x = deathcx + (w * 0.5) - w2;
	gc.DrawText( x, yoffset, w2, h, str );

	// Draw Streak
	gc.GetTextExtent( 0, w2, h, StreakString );
	streakcx = screenWidth * StreakX + w2 * 0.5;
	str = int(se.Streak) $ "";
	gc.GetTextExtent( 0, w2, h, str );
	x = streakcx + (w * 0.5) - w2;
	gc.DrawText( x, yoffset, w2, h, str );
}

function bool CheckVictoryConditions( Pawn Killer, Pawn Killee, String Method )
{
	local Pawn winner;
	local Pawn P;
	local int r;
	if ( VictoryCondition ~= "Frags" )
	{
		GetWinningPlayer( winner );

		if ( winner != None )
		{
			if (( winner.PlayerReplicationInfo.Score == ScoreToWin-(ScoreToWin/5)) && ( ScoreToWin >= 10 ))
				NotifyGameStatus( ScoreToWin/5, winner.PlayerReplicationInfo.PlayerName, False, False );
			else if (( winner.PlayerReplicationInfo.Score == (ScoreToWin - 1) ) && (ScoreTowin >= 2 ))
				NotifyGameStatus( 1, winner.PlayerReplicationInfo.PlayerName, False, True );

			if ( winner.PlayerReplicationInfo.Score >= ScoreToWin )
			{
				foreach AllActors(class'Pawn', P)
					if(TCPlayer(P) != None && P != Winner)
						TCPlayer(P).PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission02.ConAudioMission02_991", class'Sound', true)),SLOT_Talk);
						
				if(TCPlayer(winner) != P)		
				{
					r = Rand(1);
						if(r == 0)
							TCPlayer(winner).PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission01.ConAudioMission01_528", class'Sound', true)),SLOT_Talk);
						else if(r == 1)
							TCPlayer(winner).PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission02.ConAudioMission02_973", class'Sound', true)),SLOT_Talk);
				}
				PlayerHasWon( winner, Killer, Killee, Method );
				return True;
			}
		}
	}
	else if ( VictoryCondition ~= "Time" )
	{
		timeLimit = float(ScoreToWin)*60.0;

		if (( Level.Timeseconds >= timeLimit-NotifyMinutes*60.0 ) && ( timeLimit > NotifyMinutes*60.0*2.0 ))
		{
			GetWinningPlayer( winner );
			if ( winner != none) NotifyGameStatus( int(NotifyMinutes), winner.PlayerReplicationInfo.PlayerName, True, True );
			else NotifyGameStatus( int(NotifyMinutes), "", True, True );
		}

		if ( Level.Timeseconds >= timeLimit )
		{
			GetWinningPlayer( winner );

				foreach AllActors(class'Pawn', P)
					if(TCPlayer(P) != None && P != Winner)
						TCPlayer(P).PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission02.ConAudioMission02_991", class'Sound', True)),SLOT_Talk);	
						
				if(TCPlayer(winner) != None)		
				{
					r = Rand(1);
						if(r == 0)
							TCPlayer(winner).PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission01.ConAudioMission01_528", class'Sound', True)),SLOT_Talk);
						else if(r == 1)
							TCPlayer(winner).PlaySound(Sound(DynamicLoadObject("DeusExConAudioMission02.ConAudioMission02_973", class'Sound', True)),SLOT_Talk);
				}
			PlayerHasWon( winner, Killer, Killee, Method );
			return true;
		}
	}
	return false;
}

defaultproperties
{
	GTName="Deathmatch"
    PSKIN(0)=class'DeusEx.BumMale'
    PSKIN(1)=class'DeusEx.Doctor'
    PSKIN(2)=class'DeusEx.BumMale2'
    PSKIN(3)=class'DeusEx.TracerTong'
    PSKIN(4)=class'DeusEx.WaltonSimons'
    PSKIN(5)=class'DeusEx.JosephManderley'
    PSKIN(6)=class'DeusEx.Smuggler'
    PSKIN(7)=class'DeusEx.ThugMale'
    PSKIN(8)=class'DeusEx.MPNSF'
    PSKIN(9)=class'DeusEx.MPUnatco'
	PSKIN(10)=class'DeusEx.MPMJ12'
     VictoryConString1="|P1Hit the kill limit! (|P3 "
     VictoryConString2=" |P1)"
     TimeLimitString1="|P1Score the most frags! (|P3 "
     TimeLimitString2=" |P1)"
     PlayerString="Players"
	 StreakString="Streak"
     NewMapSecondsString=" seconds to map transition."
     WonMatchString=" has won!"
     MatchEnd2String=" blasting "
     TeamNsfString="NSF"
     TeamUnatcoString="Unatco"
     TeamDrawString="Everyone failed!"
    DefaultPlayerClass=Class'TCMJ12'
    GameReplicationInfoClass=Class'TCGRI'
}
