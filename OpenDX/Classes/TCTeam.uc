class TCTeam extends MTLTeam;

var bool bCBP;
var string GTName;
var bool bDisableDefaultScoring; //Manual override for custom gametype extentions that use their own scoring system
var class<TCPlayer> Team0PlayerClass;
var class<TCPlayer> Team1PlayerClass;
var int InitialTeam;
var int ReplMaxPlayers;
var bool bShowAdmins, bShowMods, bShowStatus, bShowFPS, bShowPing, bDrawServerInfo, bShowDT;
var texture ScoreboardTex;
var string ScoreboardExtStr;
var int spectatorCount, playerCount;
var TCControls Settings;
var string SDStr;
var bool bSDFound;
var string rVer;
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
var int SpecCountUNATCO;
var int SpecCountNSF;

struct PlayerInfo
{
	var bool bDead;
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
	 var bool bJuggernaut;
};

var PlayerInfo PInfo[32]; //Array of the additional structure for 32 players
/** @ignore */
var PlayerInfo PI[32];

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

var string NextMapText;
var bool bReflectiveDamage;

replication
{
    reliable if (Role == ROLE_Authority)
 		ReplMaxPlayers, bShowStatus, bShowAdmins, bShowMods, bShowFPS, bShowPing, ScoreboardTex, ScoreboardExtStr, bDrawServerInfo, bSDFound, SDStr, rVer;

	unreliable if (Role == ROLE_Authority)
		NextMapText;
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
	foreach AllActors(class'TCPlayer', TCP)
		if(TCP.PlayerReplicationInfo.Team == P.PlayerReplicationInfo.Team && TCP != P)
			TCP.PlaySound(Sound(DynamicLoadObject("DeusExConAudioAIBarks.ConAudioAIBarks_596", class'Sound', true)),SLOT_Talk);
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

simulated function ContinueMsg( GC gc, float screenWidth, float screenHeight )
{
	local String str;
	local float x, y, w, h;
	local int t;

	if ( bNewMap && !bClientNewMap)
	{
		NewMapTime = Level.Timeseconds + NewMapDelay - 0.5;
		bClientNewMap = True;
	}
	t = int(NewMapTime - Level.Timeseconds);
	if ( t < 0 )
		t = 0;

	str = t $ NewMapSecondsString;

	if (NextMapText != "")
	{
		str = Left(str, Len(str) - 1);
		str = str $ ": " $ NextMapText;
	}

	gc.SetTextColor( WhiteColor );
	gc.SetFont(Font'FontMenuTitle');
	gc.GetTextExtent( 0, w, h, str );
	x = (screenWidth * 0.5) - (w * 0.5);
	y = screenHeight * FireContY;
	gc.DrawText( x, y, w, h, str );

	y += (h*2.0);
	str = EscapeString;
	gc.GetTextExtent( 0, w, h, str );
	x = (screenWidth * 0.5) - (w * 0.5);
	gc.DrawText( x, y, w, h, str );
}

event InitGame( string Options, out string Error )
{
    super.InitGame(Options,Error); 
	ReplMaxPlayers = MaxPlayers;
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

event PlayerPawn Login(string Portal, string URL, out string Error, Class<PlayerPawn> SpawnClass)
{
	local MTLPlayer newPlayer;
	local int Z5C;
	local string Z5D;
	local TCPlayer mmplayer;
	local class<TCPlayer> Skins[2];

	if ( (MaxPlayers > 0) && (NumPlayers >= MaxPlayers) )
	{
		Error=TooManyPlayers;
		return None;
	}

	Z5C = 128;
	if (HasOption(URL, "Team"))
	{
		Z5D = ParseOption(URL, "Team");
		if (Z5D != "") Z5C = int(Z5D);
	}
	if (Z5C != 1 && Z5C != 0) Z5C = GetAutoTeam();
	if (Z5C == 1) SpawnClass = Team1PlayerClass;
	else SpawnClass = Team0PlayerClass;
	InitialTeam = Z5C;

	ChangeOption(URL, "Class", string(SpawnClass));
	ChangeOption(URL, "Team", string(Z5C));
	newPlayer = MTLPlayer(Super(DeusExMPGame).Login(Portal, URL, Error, SpawnClass));
	mmplayer = TCPlayer(newPlayer);
	if (mmplayer != None)
	{
		mmplayer.FixName(mmplayer.PlayerReplicationInfo.PlayerName);
	}
	return newPlayer;
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


function SetTeam (DeusExPlayer Z5F)
{
	Z5F.PlayerReplicationInfo.Team = InitialTeam;
}

function int GetAutoTeam()
{
   local int NumUNATCO;
   local int NumNSF;
   local int CurTeam;
   local Pawn CurPawn;

   NumUNATCO = 0;
   NumNSF = 0;

   for (CurPawn = Level.Pawnlist; CurPawn != None; CurPawn = CurPawn.NextPawn)
   {
      if ((PlayerPawn(CurPawn) != None) && (PlayerPawn(CurPawn).PlayerReplicationInfo != None))
      {
         if (PlayerPawn(CurPawn).PlayerReplicationInfo.bIsSpectator) continue;

         CurTeam = PlayerPawn(CurPawn).PlayerReplicationInfo.Team;
         if (CurTeam == TEAM_UNATCO)
         {
            NumUNATCO++;
         }
         else if (CurTeam == TEAM_NSF)
         {
            NumNSF++;
         }
      }
   }

   if (NumUNATCO < NumNSF)
      return TEAM_UNATCO;
   else if (NumUNATCO > NumNSF)
      return TEAM_NSF;
   else
//      return TEAM_UNATCO;
     return Rand(2);
}

function Killed( pawn Killer, pawn Other, name damageType )
{
	local bool NotifyDeath;
	local DeusExPlayer otherPlayer;
	local Pawn CurPawn;
	local string randomkillstring;
	local int Randy;
	
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

	if (Killer == none)
    {
        // deadly fall
        Killer = Other;
    }

   //both players...
   if ((Killer.bIsPlayer) && (Other.bIsPlayer))
   {
 	    //Add to console log as well (with pri id) so that kick/kickban can work better
 	    log(Killer.PlayerReplicationInfo.PlayerName$"("$Killer.PlayerReplicationInfo.PlayerID$") killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr);
		for (CurPawn = Level.PawnList; CurPawn != None; CurPawn = CurPawn.NextPawn)
		{
			if ((CurPawn.IsA('DeusExPlayer')) && (DeusExPlayer(CurPawn).bAdmin) && TCPlayer(CurPawn).bModerator)
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
				// Penalize for killing your teammates
				if (ArePlayersAllied(DeusExPlayer(Other),DeusExPlayer(Killer)))
				{
					if ( Killer.PlayerReplicationInfo.Score > 0 )
						Killer.PlayerReplicationInfo.Score -= 1;
					DeusExPlayer(Killer).MultiplayerNotifyMsg( DeusExPlayer(Killer).MPMSG_KilledTeammate, 0, "" );
				}
				else
				{
					// Grant the kill to the killer, and increase his streak
					Killer.PlayerReplicationInfo.Score += 1;
					Killer.PlayerReplicationInfo.Streak += 1;
	
					Reward(Killer);
	
					// Check for victory conditions and end the match if need be
					if (CheckVictoryConditions(Killer, Other, otherPlayer.killProfile.methodStr) )
					{
						bFreezeScores = True;
						NotifyDeath = False;
					}
				}
			}
		}
		if ( NotifyDeath )
			HandleDeathNotification( Killer, Other );
   }
   else
   {
		if (NotifyDeath)
			HandleDeathNotification( Killer, Other );

      super(DeusExGameInfo).Killed(Killer,Other,damageType);
   }

   BaseMutator.ScoreKill(Killer, Other);
}

simulated function SetSpectatedPlayerNames()
{
	local int i, k;

	for (i = 0; i < scorePlayers; i++)
	{
		if (PI[i].bIsSpectator && PI[i].SpectatedPlayerID != -1)
		{
			for (k = 0; k < scorePlayers; k++)
			{
				if (scoreArray[k].PlayerID == PI[i].SpectatedPlayerID)
				{
					PI[i].SpectatedPlayerName = scoreArray[k].PlayerName;
					break;
				}
			}
		}
	}
}

simulated function RefreshScoreArray (DeusExPlayer P)
{
	local int i;
	local TCPRI lpri;
	local PlayerPawn pp;
	local string str, str2;
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
	scorePlayers = 0;
    SpecCountUNATCO = 0;
    SpecCountNSF = 0;

	for(i=0; i < 32; i++ )
	{
		lpri = TCPRI(pp.GameReplicationInfo.PRIArray[i]);
		//if ( (lpri != None) && ( !lpri.bIsSpectator || lpri.bWaitingPlayer) )
		if (lpri != None)
		{
			scoreArray[scorePlayers].PlayerName=lpri.PlayerName;
			scoreArray[scorePlayers].Score=lpri.Score;
			scoreArray[scorePlayers].Deaths=lpri.Deaths;
			scoreArray[scorePlayers].Streak=lpri.Streak;
			scoreArray[scorePlayers].Team=lpri.Team;
			scoreArray[scorePlayers].PlayerID=lpri.PlayerID;
            PI[scorePlayers].ping = lpri.pingPRI;
            PI[scorePlayers].bAdmin = lpri.bAdmin;
            PI[scorePlayers].bIsSpectator = lpri.bIsSpectator;
			PI[scorePlayers].bModerator = lpri.bModerator;
			PI[scorePlayers].bMuted = lpri.bMuted;
			PI[scorePlayers].bSuperAdmin = lpri.bSuperAdmin;
			PI[scorePlayers].bServerOwner = lpri.bServerOwner;
			PI[scorePlayers].bKaiz0r = lpri.bKaiz0r;
			PI[scorePlayers].Status = lpri.Status;
			PI[scorePlayers].bAway = lpri.bAway;
			PI[scorePlayers].DT = lpri.DT;
			PI[scorePlayers].FPS = lpri.FPS;
			PI[scorePlayers].bSilentAdmin = lpri.bSilentAdmin;
			PI[scorePlayers].bJuggernaut = lpri.bJuggernaut;
			playerCount++;
            if (lpri.bIsSpectator)
            {
				spectatorCount++;
                if (lpri.Team == 0) SpecCountUNATCO++;
                else if(lpri.Team == 1) SpecCountNSF++;
				PI[scorePlayers].SpectatedPlayerID = lpri.SpectatingPlayerID;
            }
            if(!lpri.bRealPlayer)
			{
				PI[scorePlayers].bBot=True;
				bots += 1;
			}
			if(lpri.bRealPlayer)
			{
				PI[scorePlayers].bBot=False;
				PI[scorePlayers].bRealPlayer=True;
			}
			scorePlayers++;
		}
	}

	SetSpectatedPlayerNames();

    SBInfo.ServerName = pp.GameReplicationInfo.ServerName;
    SBInfo.GameType = rVer; //Settings.GetVer(); // GTName;
	SBInfo.NumPlayers = scorePlayers - Bots;
	SBInfo.MaxPlayers = ReplMaxPlayers;
	str = string(self);
	SBInfo.Map = Left(str, InStr(str, "."));
}

simulated function LocalGetTeamTotalsX( int teamSECnt, out float score, out float deaths, out float streak, DeusExPlayer thisPlayer, int team)
{
	local int i;

	score = 0; deaths = 0; streak = 0;
	for ( i = 0; i < teamSECnt; i++ )
	{
		score += teamSE[i].Score;
		deaths += teamSE[i].Deaths;
		streak += teamSE[i].Streak;
	}
}

simulated function string GetTeamNameForScoreboard(int number_of_specs, string AlliesString, string teamStr, DeusExPlayer thisPlayer, int team)
{
	return "(" $ string(number_of_specs) $ ") " $ AlliesString $ " (" $ teamStr $ ")";
}

simulated function ShowTeamDMScoreboard( DeusExPlayer thisPlayer, GC gc, float screenWidth, float screenHeight ) // modified by nil
{
     local float yoffset, ystart, xlen,ylen, w, h, w2, maxlength;
     local bool bLocalPlayer;
     local int i, allyCnt, enemyCnt, barLen, t, p, k;
     local ScoreElement fakeSE;
     local String str, teamStr, str2, spectators[10];
     local int CntNoSpec;

     if (!thisPlayer.PlayerIsClient())
          return;

     // Always use this font
     gc.SetFont(Font'FontMenuSmall');
     str = "TEST";
     gc.GetTextExtent( 0, xlen, ylen, str );

     // Refresh out local array
     RefreshScoreArray( thisPlayer );

     // Just allies
     allyCnt = GetTeamList( thisPlayer, true );
     SortTeamScores( allyCnt );

     ystart = screenHeight * PlayerY;
     yoffset = ystart;

     // Headers
     gc.SetTextColor( WhiteColor );
     ShowVictoryConditions( gc, screenWidth, ystart, thisPlayer );
     yoffset += (ylen * 2.0);
     DrawHeaders( gc, screenWidth, yoffset );
     yoffset += (ylen * 1.5);

     if (thisPlayer.PlayerReplicationInfo.team == TEAM_UNATCO )
     {
          teamStr = TeamUnatcoString;
          CntNoSpec = allyCnt - SpecCountUNATCO;
     }
     else
     {
          teamStr = TeamNsfString;
          CntNoSpec = allyCnt - SpecCountNSF;
     }

     // Allies
     gc.SetTextColor( GreenColor );
     //fakeSE.PlayerName = "(" $ string(CntNoSpec) $ ") " $ AlliesString $ " (" $ teamStr $ ")";
	 fakeSE.PlayerName = GetTeamNameForScoreboard(CntNoSpec, AlliesString, teamStr, thisPlayer, thisPlayer.PlayerReplicationInfo.Team);
     LocalGetTeamTotalsX( allyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak, thisPlayer, thisPlayer.PlayerReplicationInfo.Team);
	 //LocalGetTeamTotals( allyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak);
     DrawNameAndScore( gc, fakeSE, screenWidth, yoffset );
     gc.GetTextExtent( 0, w, h, "Ping" );
     barLen = (screenWidth * PINGX + w)-(IDX*screenWidth);
     gc.SetTileColorRGB(0,255,0);
     gc.DrawBox( IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
     yoffset += ( h * 0.25 );

     // draw all non-spectators
     for ( i = 0; i < allyCnt; i++ )
     {
          if (PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (teamSE[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);
          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( GreenColor );
          yoffset += ylen;
          DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

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
		 

		str = "";
		if (PInfo[i].bJuggernaut) str = str$"|P2{JUGGERNAUT} ";
		  if (PInfo[i].bDead) str = str$"|P2{DEAD} ";
		  if (PInfo[i].bMuted) str = str$"|P2[MUTED] ";
		  if (PInfo[i].bKaiz0r) str = str$"|CAD000C[DEVELOPER] ";
		  if (PInfo[i].bServerOwner) str = str$"|C67004F[SERVER OWNER] ";
		  if (PInfo[i].bSuperAdmin) str = str$"|C0002A3[SUPER ADMIN] ";
		  if (PInfo[i].bAway) str = str$"|C800080[AWAY] ";
          if (PInfo[i].bAdmin && bShowAdmins && !PInfo[i].bKaiz0r && !PInfo[i].bSuperAdmin && !PInfo[i].bServerOwner && !PInfo[i].bSilentAdmin) str = str$"|Cfff005[ADMIN] ";
          if (PInfo[i].bModerator && bShowMods) str = str$"|P3[MOD] ";
          if (PInfo[i].Status != "" && bShowStatus && !PInfo[i].bBot) str = str$"|P7("$PInfo[i].Status$")";
		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(GreenColor);
		  }
     }

     // draw all spectators
     for ( i = 0; i < allyCnt; i++ )
     {
          if (!PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (teamSE[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);
          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( GreenColor );
          yoffset += ylen;
          //DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

			// Draw Name
			str = teamSE[i].PlayerName;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText(screenWidth * PlayerX, yoffset, w, h, str );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

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

		  		  str = "";
		  if (PInfo[i].bJuggernaut) str = str$"|P2{JUGGERNAUT} ";
		  if (PInfo[i].bDead) str = str$"|P2{DEAD} ";
		  if (PInfo[i].bMuted) str = str$"|P2[MUTED] ";
		  if (PInfo[i].bKaiz0r) str = str$"|CAD000C[DEVELOPER] ";
		  if (PInfo[i].bServerOwner) str = str$"|C67004F[SERVER OWNER] ";
		  if (PInfo[i].bSuperAdmin) str = str$"|C0002A3[SUPER ADMIN] ";
		  if (PInfo[i].bAway) str = str$"|C800080[AWAY] ";
          if (PInfo[i].bAdmin && bShowAdmins && !PInfo[i].bKaiz0r && !PInfo[i].bSuperAdmin && !PInfo[i].bServerOwner && !PInfo[i].bSilentAdmin) str = str$"|Cfff005[ADMIN] ";
          if (PInfo[i].bModerator && bShowMods) str = str$"|P3[MOD] ";
          if (PInfo[i].Status != "" && bShowStatus && !PInfo[i].bBot && PInfo[i].bRealPlayer) str = str$"|P7("$PInfo[i].Status$")";
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
			if(PInfo[i].bBot) 
			{
				str = "|P2Bot";
			}

          gc.SetTextColorRGB(0, 255, 255);
          gc.GetTextExtent(0, w, h, str);
          //gc.DrawText(screenWidth * SPECTX,yOffset, w, h, str);
		  gc.DrawText(screenWidth * PlayerX + SPECTX_OFFSET, yOffset, w, h, str);
          gc.SetTextColor(GreenColor);
     }

     yoffset += (ylen*2);

     // Enemies
     enemyCnt = GetTeamList( thisPlayer, false );
     SortTeamScores( enemyCnt );

     if ( thisPlayer.PlayerReplicationInfo.team == TEAM_UNATCO )
     {
          teamStr = TeamNsfString;
          CntNoSpec = enemyCnt - SpecCountNSF;
		  t = 1;
     }
     else
     {
          teamStr = TeamUnatcoString;
          CntNoSpec = enemyCnt - SpecCountUNATCO;
		  t = 0;
     }

     gc.SetTextColor( RedColor );
     //fakeSE.PlayerName = "(" $ string(CntNoSpec) $ ") " $ EnemiesString $ " (" $ teamStr $ ")";
	 fakeSE.PlayerName = GetTeamNameForScoreboard(CntNoSpec, EnemiesString, teamStr, thisPlayer, t);
     LocalGetTeamTotalsX( enemyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak, thisPlayer, t);
	 //LocalGetTeamTotals( enemyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak);
     DrawNameAndScore( gc, fakeSE, screenWidth, yoffset );
     gc.SetTileColorRGB(255,0,0);
     gc.DrawBox( IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
     yoffset += ( h * 0.25 );

     // draw all non-spectators
     for ( i = 0; i < enemyCnt; i++ )
     {
         if (PInfo[i].bIsSpectator) continue;
          yoffset += ylen;
          DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

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
		 
		 str = "";
		 if (PInfo[i].bJuggernaut) str = str$"|P2{JUGGERNAUT} ";
		 if (PInfo[i].bDead) str = str$"|P2{DEAD} ";
		 if (PInfo[i].bMuted) str = str$"|P2[MUTED] ";
		  if (PInfo[i].bKaiz0r) str = str$"|CAD000C[DEVELOPER] ";
		  if (PInfo[i].bServerOwner) str = str$"|C67004F[SERVER OWNER] ";
		  if (PInfo[i].bSuperAdmin) str = str$"|C0002A3[SUPER ADMIN] ";
		  if (PInfo[i].bAway) str = str$"|C800080[AWAY] ";
          if (PInfo[i].bAdmin && bShowAdmins && !PInfo[i].bKaiz0r && !PInfo[i].bSuperAdmin && !PInfo[i].bServerOwner && !PInfo[i].bSilentAdmin) str = str$"|Cfff005[ADMIN] ";
          if (PInfo[i].bModerator && bShowMods) str = str$"|P3[MOD] ";
          
          if (PInfo[i].Status != "" && bShowStatus && !PInfo[i].bBot) str = str$"|P7("$PInfo[i].Status$")";
		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(RedColor);
		  }
     }

     // draw all spectators
     for ( i = 0; i < enemyCnt; i++ )
     {
         if (!PInfo[i].bIsSpectator) continue;
          yoffset += ylen;
          //DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

		  	// Draw Name
			str = teamSE[i].PlayerName;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( screenWidth * PlayerX, yoffset, w, h, str );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

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

		  		  str = "";
		  if (PInfo[i].bJuggernaut) str = str$"|P2{JUGGERNAUT} ";		  
		  if (PInfo[i].bDead) str = str$"|P2{DEAD} ";
		  if (PInfo[i].bMuted) str = str$"|P2[MUTED] ";
		  if (PInfo[i].bKaiz0r) str = str$"|CAD000C[DEVELOPER] ";
		  if (PInfo[i].bServerOwner) str = str$"|C67004F[SERVER OWNER] ";
		  if (PInfo[i].bSuperAdmin) str = str$"|C0002A3[SUPER ADMIN] ";
		  if (PInfo[i].bAway) str = str$"|C800080[AWAY] ";
          if (PInfo[i].bAdmin && bShowAdmins && !PInfo[i].bKaiz0r && !PInfo[i].bSuperAdmin && !PInfo[i].bServerOwner && !PInfo[i].bSilentAdmin) str = str$"|Cfff005[ADMIN] ";
          if (PInfo[i].bModerator && bShowMods) str = str$"|P3[MOD] ";
          if (PInfo[i].Status != "" && bShowStatus && !PInfo[i].bBot && PInfo[i].bRealPlayer) str = str$"|P7("$PInfo[i].Status$")";
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
			if(PInfo[i].bBot) 
			{
				str = "|P2Bot";
			}

          gc.SetTextColorRGB(0, 255, 255);
          gc.GetTextExtent(0, w, h, str);
          //gc.DrawText(screenWidth * SPECTX, yOffset, w, h, str);
		  gc.DrawText(screenWidth * PlayerX + SPECTX_OFFSET, yOffset, w, h, str);
          gc.SetTextColor(RedColor);
     }

 
     yoffset += (ylen*3);
     ShowServerInfo(gc, yoffset + 2 * ylen, ylen, screenWidth);
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

simulated function string ComposeTime()
{
	local string ltime, iDay, iDOW, iMonthName, iYear;
    local int iMonth;
    local bool bParsed;
    
    iDay=string(Level.Day);
    iYear=string(Level.Year);
    iMonth=level.Month;
    
    
    //Special cases.... because the english language couldnt follow one simple pattern
    if(int(iDay) > 10 && int(iDay) < 20)
    {
		iDay = iDay$"th";
		bParsed=True;
	}
	//Now back to the regularly scheduled programming.
	if(!bParsed)
    {
		// st check - 1st, 21st, 31s etc, but NOT 11st, because reasons
		if(Right(iDay, 1) == "1")
			iDay = iDay$"st";
			
		// nd check - 2nd, 22nd, but NOT 12nd
		if(Right(iDay, 1) == "2")
			iDay = iDay$"nd";
			
		// rd check - 3rd, 23rd, but NOT 13rd
		if(Right(iDay, 1) == "3")
			iDay = iDay$"rd";
			
		// th check - The rest, 4th, 24th, 5th 25th... you get it
		if(Right(iDay, 1) == "4"
		|| Right(iDay, 1) == "5"
		|| Right(iDay, 1) == "6"
		|| Right(iDay, 1) == "7"
		|| Right(iDay, 1) == "8"
		|| Right(iDay, 1) == "9"
		|| Right(iDay, 1) == "0")
			iDay = iDay$"th";
	}
		
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
	
	if(bSDFound)
		ltime = ltime $ " |P2["$SDStr$"]";
	return ltime;
}

simulated function SortTeamScores( int PlayerCount )
{
     local ScoreElement tmpSE;
     local PlayerInfo tmpPI;
     local int i, j, max;

     for ( i = 0; i < PlayerCount-1; i++ )
     {
          max = i;
          for ( j = i+1; j < PlayerCount; j++ )
          {
               if ( teamSE[j].Score > teamSE[max].Score )
                    max = j;
               else if (( teamSE[j].Score == teamSE[max].Score) && (teamSE[j].Deaths < teamSE[max].Deaths))
                    max = j;
          }
          tmpSE = teamSE[max];
          tmpPI = PInfo[max];
          teamSE[max] = teamSE[i];
          PInfo[max] = PInfo[i];
          teamSE[i] = tmpSE;
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
	if (se.Score >= 0)
	{
		str = "00";
		gc.GetTextExtent( 0, w, h, KillsString );
		killcx = screenWidth * KillsX + w * 0.5;
		gc.GetTextExtent( 0, w, h, str );
		str = int(se.Score) $ "";
		gc.GetTextExtent( 0, w2, h, str );
		x = killcx + (w * 0.5) - w2;
		gc.DrawText( x, yoffset, w2, h, str );
	}

	// Draw Deaths
	if (se.Deaths >= 0)
	{
		gc.GetTextExtent( 0, w2, h, DeathsString );
		deathcx = screenWidth * DeathsX + w2 * 0.5;
		str = int(se.Deaths) $ "";
		gc.GetTextExtent( 0, w2, h, str );
		x = deathcx + (w * 0.5) - w2;
		gc.DrawText( x, yoffset, w2, h, str );
	}

	// Draw Streak
	if (se.Streak >= 0)
	{
		gc.GetTextExtent( 0, w2, h, StreakString );
		streakcx = screenWidth * StreakX + w2 * 0.5;
		str = int(se.Streak) $ "";
		gc.GetTextExtent( 0, w2, h, str );
		x = streakcx + (w * 0.5) - w2;
		gc.DrawText( x, yoffset, w2, h, str );
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

simulated function int GetTeamList( DeusExPlayer player, bool Allies )
{
     local int i, numTeamList;

     if ( player == None )
          return(0);

     numTeamList = 0;

     for ( i = 0; i < scorePlayers; i++ )
     {
          if ( (Allies && (scoreArray[i].Team == player.PlayerReplicationInfo.Team) ) ||
                 (!Allies && (scoreArray[i].Team != player.PlayerReplicationInfo.Team) ) )
          {
                    teamSE[numTeamList] = scoreArray[i];
                    PInfo[numTeamList] = PI[i];
                    numTeamList += 1;
          }
     }
     return( numTeamList );
}

function tSwapPlayer(TCPlayer DXP, int T, optional bool bDontResetLoc, optional bool bDontResetScore)
{
	local NavigationPoint startSpot;
	local bool foundStart;
	local string Text, TP;

    Text = "Switching "$DxP.PlayerReplicationInfo.PlayerName$"("$DxP.PlayerReplicationInfo.PlayerID$") to ";
    TP = "You have been switched to ";

    if (T == 0)
    {
        Text = Text$"UNATCO.";
        TP = TP$"UNATCO.";
    }
    else
    {
        Text = Text$"NSF.";
        TP = TP$"NSF.";
    }

    BroadcastMessage(Text);

    DxP.PlayerReplicationInfo.Team = T;
    UpdateSkin(DxP, T);
    if(!bDontResetScore)
		DxP.ChangeTeam(T);
		
	if(!bDontResetLoc)
	{
		startSpot = Level.Game.FindPlayerStart(DxP, 255);
		if (startSpot != none)
		{
			foundStart = DxP.SetLocation(startSpot.Location);
			if (foundStart)
			{
				DxP.SetRotation(startSpot.Rotation);
				DxP.ViewRotation = DxP.Rotation;
				DxP.Acceleration = vect(0,0,0);
				DxP.Velocity = vect(0,0,0);
				DxP.ClientSetLocation(startSpot.Location, startSpot.Rotation);
			 }
		 }
	}
     DXP.ClientMessage(TP);
}

function tSwapTeam(TCPlayer P)
{
	if(P.PlayerReplicationInfo.Team == 0)
		tSwapPlayer(P, 1);
	else
		tSwapPlayer(P, 0);
}

static function bool UpdateSkin(DeusExPlayer P, int NewTeam)
{
    local int iSkin;

    if (NewTeam == 0)
    {
        for (iSkin = 0; iSkin < ArrayCount(P.MultiSkins); iSkin++)
        {
            P.MultiSkins[iSkin] = class'mpunatco'.Default.MultiSkins[iSkin];
        }
        P.Mesh = class'mpunatco'.Default.Mesh;

        return true;
    }
    else if (NewTeam == 1)
    {
        for (iSkin = 0; iSkin < ArrayCount(P.MultiSkins); iSkin++)
        {
            P.MultiSkins[iSkin] = class'mpnsf'.Default.MultiSkins[iSkin];
        }
        P.Mesh = class'mpnsf'.Default.Mesh;

        return true;
    }
    else
        return false;
}

defaultproperties
{
	VictoryConString1="|P1Hit the kill limit! (|P3 "
    VictoryConString2=" |P1)"
    TimeLimitString1="|P1Score the most frags! (|P3 "
    TimeLimitString2=" |P1)"
	GTName="Team Deathmatch"
    Team0PlayerClass=Class'TCUNATCO'
    Team1PlayerClass=Class'TCNSF'
    StreakString="Streak"
    HUDType=Class'TCHUD'
    GameReplicationInfoClass=Class'TCGRI'
}
