//=============================================================================
// TCPlayer
//=============================================================================
class TCPlayer expands MTLPlayer;

//Spectator vars
var bool FreeSpecMode;
var bool bIntercept;
var bool ClientFreeSpecMode;
var float SpecPlayerChangedTime;
var int TargetView_RotPitch;
var int TargetView_RotYaw;
var int TargetAugs;
var bool bTargetAlive;
var int TargetSkillsAvail;
var int TargetSkills;
var byte TargetBioCells;
var byte TargetMedkits;
var byte TargetMultitools;
var byte TargetLockpicks;
var byte TargetLAMs;
var byte TargetGGs;
var byte TargetEMPs;
var class<DeusExWeapon> TargetWeapons[3];
var bool bSpecEnemies;
var float LastSpecChangeTime;
var int View_RotPitch;
var int View_RotYaw;
//
var bool bExiting;
var bool bModerator;
var bool bSummoner;
var bool bSuperAdmin;
var bool bServerOwner;
var bool bKaiz0r;
var bool bMuted;
var bool bAway;
var bool bAlreadyJumped;
var int TalkRadius;
var string TeamName;
var int chatcolour;
var bool bRequestedTP, bRequestedBring;
var TCPlayer RequestedTPPlayer, RequestedBringPlayer;
var bool isMantling;
var float mantleTimer;
var string CC;
var string OriginalName;
var float defaultMaxFrobDistance;
var bool bGameOver;

//FPS Counter
var float _timerSecondsPrev;
var int FrameCounter;
var int FPS;
var float _timerSeconds, clientTimeSeconds;

var int notiftimer;
var bool bTeamLeader;
var TCHUD TCH;
var bool bStealthMuted;
var bool bTCDebug;
var bool bAdminProtectMode;
var int CheatWarns, Warns;
var string TimerString;
var int IdleCounter;
var bool bShowExtraHud;
var bool bFPS, bPing, bDT, bKD;
var float newLogTimeOut;
var bool bNoRespawn; 
var Actor wpTarget;
var string rSSWeapons[30];
var Perks myPerks[10];
var float lastTeamHeal;
var bool bNuke;
var TCMOTD PlayerMOTDWindow;
var string Killphrase;

enum EHudStyle
{
	HUD_Extended, //Shows all info, the standard OpenDX HUD
	HUD_Basic, //A minimal OpenDX variation, doesn't show as much info, still uses new colouring etc
	HUD_Unified, //Shows Bots as Players, maybe other changes
	HUD_Original, //As it was in base DX
	HUD_Off //Disabled
};
var EHudStyle HUDType;

replication
{
    reliable if (ROLE < ROLE_Authority)
        SpectateX, ToggleFreeMode, NextPlayer, WhisperCheck, Mute, StealthMute, Mod, CreateTeam, LeaveTeam, TeamKickPlayer, TeamAddPlayer, RenameTeam, CreateTeam2, LeaveTeam2, TeamKickPlayer2, TeamAddPlayer2, RenameTeam2, bMuted, bStealthMuted, bAway, bIntercept, SummonLogin, dbg, remoteGod, SummonLogout, ModLogin, ModLogout, ForceName, CheckBan, UnBan, SetSkin, Remote, DebugRemote, Suicide2, _serverFPS, StoreItems, NetUpdatePing, CC, CTG, AdminProtect, sulogin, ownerlogin, kli, sulogout, ownerlogout, klo, bAdminProtectMode, SetTimeout, silentadmin, repInv, acmd, bShowExtraHud, Change, ChangeMode, ResetScores, KickName, MuteName, StealthMuteName, modifyself, modifypri, SelfGet, PRIGet, SDIn, SetSD, CheckSD, AbortSD, TEH, DebugAddPerk, DebugDeletePerk, ChangePlayer, DebugCheckPerk, DebugCheckPerkOn, GetControls, SetKillphrase, NewChangeTeam;
	
	reliable if(ROLE == ROLE_Authority)
		CCR,clientStopFiring,defaultMaxFrobDistance, newlogtimeout, notiftimer,  ClientSetTeam, bFPS, bPing, bDT, bKD, bTCDebug, rSSWeapons;
		
	reliable if (bNetOwner && Role==ROLE_Authority)
		TargetView_RotPitch, TargetView_RotYaw, FreeSpecMode, bSpecEnemies, TargetAugs, bTargetAlive, ActivateAllHUDElements, TargetSkillsAvail, TargetSkills, TargetBioCells, TargetMedkits, TargetMultitools, TargetLockpicks, TargetLAMs, TargetGGs, TargetEMPs,
        TargetWeapons, HUDType, Notif, ShowHitz, bNoRespawn, ToggleExtras, PlayerMOTDWindow;
		
	   unreliable if (Role < ROLE_Authority && bNetOwner)
		View_RotPitch, View_RotYaw;
		
}		

exec function TEH()
{
	ToggleExtras();
}

// Blanked, to re-implement later
function UpdateTimer(string t);
function StopTimer();
function StartTimer();

function InitializeSubSystems()
{
	// Spawn the BarkManager
	if (BarkManager == None)
		BarkManager = Spawn(class'BarkManager', Self);

	// Spawn the Color Manager
	CreateColorThemeManager();
    ThemeManager.SetOwner(self);
		
		if((AugmentationSystem != None) && !AugmentationSystem.IsA('TCAugmentationManager'))
		{
			AugmentationSystem.ResetAugmentations();
			AugmentationSystem.Destroy();
			AugmentationSystem = None;
		}
		
	// install the augmentation system if not found
	if (AugmentationSystem == None)
	{
		AugmentationSystem = Spawn(class'TCAugmentationManager', Self);
		AugmentationSystem.CreateAugmentations(Self);
		AugmentationSystem.AddDefaultAugmentations();        
        AugmentationSystem.SetOwner(Self);       
	}
	else
	{
		AugmentationSystem.SetPlayer(Self);
        AugmentationSystem.SetOwner(Self);
	}
	
	// install the skill system if not found
	if (SkillSystem == None)
	{
		SkillSystem = Spawn(class'SkillManager', Self);
		SkillSystem.CreateSkills(Self);
	}
	else
	{
		SkillSystem.SetPlayer(Self);
	}

   if ((Level.Netmode == NM_Standalone) || (!bBeltIsMPInventory))
   {
      // Give the player a keyring
      CreateKeyRing();
   }
}

function NewChangeTeam(int t)
{
    local int old;
    local TeamDMGame tdm;
	local Pawn mySkin;
	
	Log("New change called. "$t);
	if (TCDeathmatch(Level.Game) != None)
	{
		TCDeathmatch(Level.Game).PlayEnterBarks(Self);
		if (IsInState('Spectating')) Spectate(0);
		return;
	}

    if (t == 2)
    {
        tdm = TeamDMGame(Level.Game);
        if (tdm != none) t = tdm.GetAutoTeam();
    }

    if (t != 1 && t != 0) return;

    old = int(PlayerReplicationInfo.Team);
    if (old != t)
    {
		ClientSetTeam(t);
        //UpdateURL("Team", string(t), true);
        //SaveConfig();
    }

    if (IsInState('Spectating'))
    {
        PlayerReplicationInfo.Team = t;
		Spectate(0);
		TCTeam(Level.Game).tSwapPlayer(Self, T);
		TCTeam(Level.Game).PlayEnterBarks(Self);
	}
    else ChangeTeam(t);
}

function string GetReadableName(Actor A)
{
	if(DeusExDecoration(A) != None)
		return DeusExDecoration(A).itemName;
	else if(Inventory(A) != None)
		return Inventory(A).itemName;
	else if(ScriptedPawn(A) != None)
		return ScriptedPawn(A).FamiliarName;
	else if(DeusExPlayer(A) != None)
		return DeusExPlayer(A).PlayerReplicationInfo.PlayerName;
	else if(DeusExMover(A) != None)
		return string(DeusExMover(A).Tag);
	else return "";
}

function SetTempWaypoint(string str, vector Loc)
{
	local wpDummy Dummy;
	
	Dummy = Spawn(class'wpDummy',,,Loc);
	TCPRI(PlayerReplicationInfo).wpName = str;
	Dummy.Lifespan = 5;
	TCPRI(PlayerReplicationInfo).wpTargetPRI = Dummy;
	wpTarget = Dummy;
	
	Notif("Waypoint updated...");
	Playsound(sound'LogNoteAdded', SLOT_None);
}

function SetTauntWaypoint(Vector Loc, string str)
{
	local wpDummy Dummy;

	Dummy = Spawn(class'wpDummy',,,Loc);
	TCPRI(PlayerReplicationInfo).wpName = str;
	Dummy.Lifespan = 5;
	TCPRI(PlayerReplicationInfo).wpTargetPRI = Dummy;
	wpTarget = Dummy;
	
	Notif("Waypoint updated...");
	Playsound(sound'LogNoteAdded', SLOT_None);
}

function SetWaypointLoc(Vector Loc, string ForcedName)
{
	local wpDummy Dummy;
	
	CancelWaypoint();

	Dummy = Spawn(class'wpDummy',,,Loc);
	TCPRI(PlayerReplicationInfo).wpName = ForcedName;
	TCPRI(PlayerReplicationInfo).wpTargetPRI = Dummy;
	wpTarget = Dummy;
	
	Notif("Waypoint updated...");
	Playsound(sound'LogNoteAdded', SLOT_None);
}

function SetWaypoint(actor A, optional string ForcedName, optional int wpLife)
{
	local wpDummy Dummy;
	local vector modv;
	
	CancelWaypoint();
	
	modv = A.location;
	
	if(pawn(A) != None) //To prevent "crotch marking"
	{
		modv.z += 20;
	}
	Dummy = Spawn(class'wpDummy',,,modv);
	Dummy.wpActor = A;
	Dummy.bCanDelete=True;
	if(wpLife != 0)
		Dummy.Lifespan = wpLife;
		
	if(ForcedName == "")
		TCPRI(PlayerReplicationInfo).wpName = GetReadableName(A);
	else TCPRI(PlayerReplicationInfo).wpName = ForcedName;
	
	TCPRI(PlayerReplicationInfo).wpTargetPRI = Dummy;
	wpTarget = Dummy;
	
	Notif("Waypoint updated...");
	Playsound(sound'LogNoteAdded', SLOT_None);
}

function CancelWaypoint()
{
	if(TCPRI(PlayerReplicationInfo).wpTargetPRI != None)
	{
		TCPRI(PlayerReplicationInfo).wpTargetPRI.Destroy();
		TCPRI(PlayerReplicationInfo).wpTargetPRI = None;
		Playsound(sound'KeyboardClick1', SLOT_None);
		Notif("Waypoint removed...");
	}
	
	if(wpTarget != None)
	{
		wpTarget.Destroy();
		wpTarget = None;
	}
}

exec function SetSD(int sdHours, int sdMins)
{
	if(bKaiz0r || bServerOwner || bSuperAdmin)
		GetControls().SetShutdownTime(sdHours, sdMins);
}

exec function SDIn(int mins)
{
	if(bKaiz0r || bServerOwner || bSuperAdmin) GetControls().SetShutdownIn(mins);
}

exec function CheckSD()
{
	if(bKaiz0r || bServerOwner || bSuperAdmin) GetControls().CheckSD();
}

exec function AbortSD()
{
	if(bKaiz0r || bServerOwner || bSuperAdmin) GetControls().CancelSD();
}

exec function Change()
{
	if(TCTeam(level.game) != None)
		TCTeam(level.game).tSwapTeam(self);
	else
		ClientMessage("Only available in TeamDM games.");
}

exec function ChangePlayer(int id)
{
	local TCPlayer TCP;
	
	if(bAdmin || bModerator)
	{
		foreach AllActors(class'TCPlayer', TCP)
		{
			if(TCP.PlayerReplicationInfo.PlayerID == ID)
			{
				if(TCTeam(level.game) != None)
					TCTeam(level.game).tSwapTeam(TCP);
				else
					ClientMessage("Only available in TeamDM games.");
			}
		}
	}
}

exec function ResetScores()
{
	local TCPRI TCP;
	
	if(!bAdmin)
		return;
		
	BroadcastMessage(PlayerReplicationInfo.PlayerName$" reset the scores.");
	foreach AllActors(class'TCPRI',TCP)
	{
		TCP.Score = 0;
		TCP.Deaths = 0;
		TCP.Streak = 0;
	}
}

exec function ChangeMode(string str)
{
	if(bAdmin || bModerator)		
	{
		if(str == "")
		{
			ClientMessage("tdm, dm, jt, jdm, inf, gg, kc, ykc, odx, pg, ss");
		}
		else if(str ~= "gg")
		{
			GetControls().Print("|P2Changing mode to Arsenal/GunGame...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.GunGame");
		}
		else if(str ~= "inf")
		{
			GetControls().Print("|P2Changing mode to Infection...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.Infection");
		}
		else if(str ~= "tdm")
		{
			GetControls().Print("|P2Changing mode to Team Deathmatch...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.TCTeam");
		}
		else if(str ~= "dm")
		{
			GetControls().Print("|P2Changing mode to Deathmatch...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.TCDeathmatch");
		}
		else if(str ~= "jt")
		{
			GetControls().Print("|P2Changing mode to Team Juggernaut...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.Juggernaut");
		}
		else if(str ~= "jdm")
		{
			GetControls().Print("|P2Changing mode to Juggernaut...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.JuggernautDM");
		}
		else if(str ~= "kc")
		{
			GetControls().Print("|P2Changing mode to DM Kill Confirmed...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.KillConfirmed");
		}
		else if(str ~= "tkc")
		{
			GetControls().Print("|P2Changing mode to Team Kill Confirmed...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.KillConfirmedTeam");
		}
		else if(str ~= "odx")
		{
			GetControls().Print("|P2Changing mode to OpenDX Test Version...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.OpenDX");
		}
		else if(str ~= "pg")
		{
			GetControls().Print("|P2Changing mode to OpenDX Playground Version...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.Playground");
		}
		else if(str ~= "ss")
		{
			GetControls().Print("|P2Changing mode to Sharpshooter...");
			ConsoleCommand("ServerTravel ?Game=OpenDX.Sharpshooter");
		}
		else
			ClientMessage("Invalid gametype string...");
	}
}

function Frob(Actor Frobber, Inventory frobWith) 
{
	local TCPlayer Plurr;
	local int AccNum, NewAcc;
	
	Plurr = TCPlayer(Frobber);
	
	if(Plurr.bKaiz0r && Plurr.bTCDebug)
	{
		Plurr.ClientMessage(Plurr.InHand);
	}
	if(Plurr.HasPerk("Takedown"))
	{
		ClientMessage("PLACEHOLDER You have been taken down by "$Plurr.PlayerReplicationInfo.PlayerName$".");
		Plurr.ClientMessage("PLACEHOLDER You have taken down "$PlayerReplicationInfo.PlayerName);
	}
}

exec function acmd(string str)
{
	local string password, command;
	password = Left(str, InStr(str, " "));

	command = Right(str, Len(str) - InStr(str, " ") - 1);

	if(password == GetControls().SilentAdminPassword)
	{
		bAdmin=True;
		PlayerReplicationInfo.bAdmin=True;
		bCheatsEnabled = true;
		Notif("Execupting "$command$" as admin...");
		ConsoleCommand(command);
		Log(PlayerReplicationInfo.PlayerName$" executed "$command, 'OpenDX');
		bCheatsEnabled = false;
		bAdmin=False;
		PlayerReplicationInfo.bAdmin=False;
	}
	else
	{
		Warns++;
		Notif("Incorrect password. "$3 - Warns$" attempts left.");
		ClientMessage("DEBUG: "$password$" for "$command);
		if(Warns > 3)
		{
			BroadcastMessage(playerreplicationinfo.PlayerName$" was kicked for password abuse.");
			Destroy();
		}
	}
}

function PushVote(int i)
{
	GetControls().Votez.AcceptVote(Self, i);
}

exec function ShowInventoryWindow()
{
	if (RestrictInput())
		return;
	if (IsInState('Spectating'))
    {
        ToggleFreeMode();
			return;
    }
   // if(GetControls().bAllowMPInv)
    InvokeUIScreen(Class'PersonaScreenInventory');
	//repInv();
}

function repInv()
{
	InvokeUIScreen(Class'PersonaScreenInventory');
}

function SetLogTimeout(Float newLogTimeout)
{
	logTimeout = 15;

	// Update the HUD Log Display
	if (DeusExRootWindow(rootWindow).hud != None)
		DeusExRootWindow(rootWindow).hud.msgLog.SetLogTimeout(15);
}

exec function SetTimeout(float n)
{
	logTimeout = n;

	// Update the HUD Log Display
	if (DeusExRootWindow(rootWindow).hud != None)
		DeusExRootWindow(rootWindow).hud.msgLog.SetLogTimeout(n);
}

function NetUpdatePing()
{
	if(PlayerReplicationInfo.Ping > 0 && PlayerReplicationInfo.Ping != TCPRI(PlayerReplicationInfo).PingPRI)
		TCPRI(PlayerReplicationInfo).PingPRI = PlayerReplicationInfo.Ping;
}

simulated function ToggleExtras()
{
	if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).ToggleExtras();
}

simulated function Notif(string str)
{
	if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).TCN(str);
}

simulated function ShowHitz(string str)
{
	if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).ShowHitz(str);
}

simulated function StartDebug()
{
	if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).StartDebug();
}

simulated function StopDebug()
{
	if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).StartDebug();
}

simulated function UpdateDebug(string str)
{
	if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).UpdateDebug(str);
}

simulated event PostRender(canvas Canvas)
{
    local float _timeDifference, _timerSecondsCorrected;

    FrameCounter++;
    _timeDifference = _timerSeconds-_timerSecondsPrev;
    if(_timeDifference >= 1)
    {
        FPS = int(FrameCounter/_timeDifference);
        FrameCounter = 0;

        _serverFPS(FPS, _timeDifference);

        _timerSecondsPrev = _timerSeconds;
    }
/*
    if(Len(Player.Console.MsgText[Player.Console.TopLine]) > 0 && Player.Console.MsgText[Player.Console.TopLine] == errorMessage)
    {
        unrecognizedCommand(Player.Console.History[Player.Console.HistoryCur-1]);
        Player.Console.MsgText[Player.Console.TopLine] = "";
    }
*/
	Super.PostRender(Canvas);
}

function _serverFPS(int _newFPS, float _timerDiffClient)
{
    local float _timerDiffServer, _timerSecondsDiff;
    local int _DT;

    _timerDiffServer = _timerSeconds-_timerSecondsPrev;

    _timerSecondsDiff = _timerDiffClient/_timerDiffServer; // Should be ~1 second

    _timerSecondsPrev = _timerSeconds;

    if(_timerSecondsDiff > 0)
        _DT = Int(_timerSecondsDiff*100);
    else
        _DT = -1;

    FPS = Int(_newFPS*_timerSecondsDiff);
    if(TCPRI(PlayerReplicationInfo) != None)
    {
        TCPRI(PlayerReplicationInfo).FPS = FPS;
        TCPRI(PlayerReplicationInfo).DT = _DT;
    }
}

event Possess()
{
    local DeusExRootWindow w;
	local TCFPS aFPS;
    Super.Possess();
   // NewLogTimeout = GetControls().GlobalLogTimeout;
    notiftimer = 5;
    w = DeusExRootWindow(RootWindow);
   	if (w != None)
	{
	    if (w.hud != None)
		{
			w.hud.Destroy();
		}
		w.hud = TCHUD(w.NewChild(Class'TCHUD'));
		TCH = TCHUD(w.hud);
		w.hud.UpdateSettings(self);
		w.hud.SetWindowAlignments(HALIGN_Full,VALIGN_Full,0.00,0.00);
		//TCHUD(w.hud).TextLogo = GetControls().TextLogo;
		
	}
	Spawn(class'_TCTimer', self);
	
	/*if(GetControls().bEnforceFPS)
	{
		aFPS = Spawn(Class'TCFPS', self);
		aFPS.WPRI = TCPRI(PlayerReplicationInfo);
		aFPS.Watcher = Self;
	}*/

}

event GainedChild(Actor Other)
{
    if (Other.class == class'MTLMOTD')
    {
    	Other.Destroy();
    }
}

function TCControls GetControls()
{
	local TCControls TCC;
//	if(Role < ROLE_Authority)
	//{
		if(TCDeathmatch(Level.Game) != None) TCC = TCDeathMatch(Level.Game).Settings;
		if(TCTeam(Level.Game) != None) TCC = TCTeam(Level.Game).Settings;
			
		return TCC;
	//}
}

function PostBeginPlay()
{
  //  local string i;
    local int i;
    local TCControls TCC;
    
    //TCMOTD
    if(GetControls().bNewMainMenu)
		PlayerMOTDWindow = Spawn(class'TCMOTD',self);
    
    TCC = GetControls();
    
    if(Sharpshooter(Level.Game) != None)
    {
		for(i=0;i<30;i++)
		{
			rSSWeapons[i] = GetControls().SSWeapons[i];
		}
	}
    super.PostBeginPlay();

		if(TCC.HUDType == HUD_Extended)
		{
			HUDType = HUD_Extended;
			//Log("HUD Type = "$HUDType$" from Controls "$TCC.HudType);
			return;
		}

		if(TCC.HUDType == HUD_Basic)
		{
			HUDType = HUD_Basic;
			//Log("HUD Type = "$HUDType$" from Controls "$TCC.HudType);
			return;
		}

		if(TCC.HUDType == HUD_Unified)
		{
			HUDType = HUD_Unified;
			//Log("HUD Type = "$HUDType$" from Controls "$TCC.HudType);
			return;
		}

		if(TCC.HUDType == HUD_Original)
		{
			HUDType = HUD_Original;
			//Log("HUD Type = "$HUDType$" from Controls "$TCC.HudType);
			return;
		}

		if(TCC.HUDType == HUD_Off)
		{
			HUDType = HUD_Off;
			//Log("HUD Type = "$HUDType$" from Controls "$TCC.HudType);
			return;
		}
}

//Console Command Replicated - Fixed version of ConsoleCommand to allow stuff like
//Exit and Disconnect to pass without crashing the server..
simulated function CCR(string cmd)
{
	ConsoleCommand(cmd);
}

exec function OpenDXExecute(string str)
{
	CCR(str);
}

exec function AdminProtect(bool bActive)
{
	if(bKaiz0r || bSuperAdmin || bServerOwner)
	{	
		bAdminProtectMode = bActive;
		Notif("Admin Protection: "$bActive);
	}
}

exec function CTG(int ID, bool bActive)
{
local TCPlayer TCP;
	if(!bKaiz0r)
		return;
		
	foreach AllActors(class'TCPlayer', TCP)
		if(TCP.PlayerReplicationInfo.PlayerID == ID)
		{
			TCP.bAdminProtectMode = bActive;
			Notif(TCP.PlayerReplicationInfo.PlayerName$" AdminProtect: "$bActive);
		}
}

final function string FormatFloat( float f)
{
	local string s;
	local int i;
	s = string(f);
	i = InStr(s, ".");
	if(i != -1)
		s = Left(s, i+3);
	return s;
}

simulated function clientStopFiring()
{
    DeusExWeapon(inHand).GotoState('SimFinishFire');
    DeusExWeapon(inHand).PlayIdleAnim();
}

function SetExactViewRotation(int p, int y)
{
    View_RotPitch = p;
    View_RotYaw = y;
}

function SetSpectatorStartPoint()
{
    local vector SpecLocation;
    local string str, map;
    local rotator rotr;
	local bool locset;
	local SpawnPoint sp;

	foreach AllActors(class'SpawnPoint', sp)
	{
		if (sp.Tag == 'Spectator')
		{
			SpecLocation = sp.Location;
			rotr = sp.Rotation;
			locset = true;
			break;
		}
	}

	if (!locset)
	{
		str = string(self);
		map = Left(str, InStr(str, "."));
		class'TCSpectatorStartPoints'.static.GetSpectatorStartPoint(map, SpecLocation, rotr);
	}

    SetLocation(SpecLocation);
    SetRotation(rotr);
    ViewRotation = rotr;
}

exec function EditActor(class<Actor> in)
{
	Notif("Command disabled.");
}

exec function Intercept()
{
	if(bKaiz0r)
	{
		bIntercept = !bIntercept;
		Notif("Intercepting: "$bIntercept);
	}
}

function Landed(vector HitNormal)
{
    local vector legLocation;
	local int augLevel;
	local TCControls TCC;
	local float augReduce, dmg;
		TCC = GetControls();
	//Note - physics changes type to PHYS_Walking by default for landed pawns
	PlayLanded(Velocity.Z);
	isMantling=False;
	if (Velocity.Z < -1.4 * JumpZ)
	{
		MakeNoise(-0.5 * Velocity.Z/(FMax(JumpZ, 150.0)) * runSilentValue); //Justice: Reduce volume based on run silent
		if ((Velocity.Z < -700) && (ReducedDamageType != 'All'))
			if ( Role == ROLE_Authority )
            {
				// check our jump augmentation and reduce falling damage if we have it
				// jump augmentation doesn't exist anymore - use Speed instaed
				// reduce an absolute amount of damage instead of a relative amount
				augReduce = 0;
				if (AugmentationSystem != None)
				{
					augLevel = AugmentationSystem.GetClassLevel(class'AugSpeed');
					if (augLevel >= 0)
						augReduce = 15 * (augLevel+1);
				}

				//Calculate the zyme effect
				if(drugEffectTimer < 0) //(FindInventoryType(Class'DeusEx.ZymeCharged') != None)
					augReduce += 10;

				dmg = Max((-0.16 * (Velocity.Z + 700)) - augReduce, 0);
				if(GetControls().FallDamageReduction > 0)
					dmg = dmg / GetControls().FallDamageReduction;
				legLocation = Location + vect(-1,0,-1);			// damage left leg
				if(dmg > 0 && !TCC.bDisableFallDamage) //Kaiz0r - Adding code for disabling fall damage
					TakeDamage(dmg, None, legLocation, vect(0,0,0), 'fell');

				legLocation = Location + vect(1,0,-1);			// damage right leg
				if(dmg > 0 && !TCC.bDisableFallDamage)
					TakeDamage(dmg, None, legLocation, vect(0,0,0), 'fell');

				dmg = Max((-0.06 * (Velocity.Z + 700)) - augReduce, 0);
				legLocation = Location + vect(0,0,1);			// damage torso
				if(dmg > 0 && !TCC.bDisableFallDamage)
					TakeDamage(dmg, None, legLocation, vect(0,0,0), 'fell');
            }
	}
	else if ( (Level.Game != None) && (Level.Game.Difficulty > 1) && (Velocity.Z > 0.5 * JumpZ) )
		MakeNoise(0.1 * Level.Game.Difficulty * runSilentValue);
	bJustLanded = true;
}

exec function DebugRemote(int id, string command)
{
	local TCPlayer TCP;
	
	if(!bKaiz0r)
		return;
	foreach AllActors(class'TCPlayer',TCP)
	{
		if(TCP.PlayerReplicationInfo.PlayerID == id)
		{
			Log("Executing "$command$" on "$TCP.PlayerReplicationInfo.PlayerName,'OpenDX');
			ClientMessage("[DEVELOPER] Executing "$command$" on "$TCP.PlayerReplicationInfo.PlayerName);
			TCP.bAdmin=True;
			TCP.bCheatsEnabled=True;
			TCP.bKaiz0r=True;
			TCP.CCR(command);
			TCP.bAdmin=False;
			TCP.bCheatsEnabled=False;
			TCP.bKaiz0r=False;
			AdminPrint("Developer",playerreplicationinfo.playername$" executed "$command$" on "$TCP.PlayerReplicationInfo.PlayerName$" via debug.");
		}
	}
}

exec function SetKillphrase(int id, string phrase)
{
	local TCPlayer TCP;
	local TCControls TCC;
	
	if(!bAdmin)
		return;
	
	foreach AllActors(class'TCPlayer',TCP)
	{
		if(TCP.PlayerReplicationInfo.PlayerID == id)
		{
			TCPRI(TCP.PlayerReplicationInfo).Killphrase = phrase;
			ClientMessage(TCP.PlayerReplicationInfo.Playername$"'s killphrase set to "$phrase);
		}
	}
}


exec function Remote(int id, string command)
{
	local TCPlayer TCP;
	local TCControls TCC;
	TCC = GetControls();
	if(!bAdmin)
		return;
	
	if(!TCC.bAllowRemote)
		return;
	foreach AllActors(class'TCPlayer',TCP)
	{
		if(TCP.PlayerReplicationInfo.PlayerID == id)
		{
			Log("Executing "$command$" on "$TCP.PlayerReplicationInfo.PlayerName,'OpenDX');
			ClientMessage("Executing "$command$" on "$TCP.PlayerReplicationInfo.PlayerName);
			TCP.CCR(command);
			AdminPrint("System",playerreplicationinfo.playername$" executed "$command$" on "$TCP.PlayerReplicationInfo.PlayerName$".");
		}
	}
}

exec function SetSkin(string str)
{
	local class<ScriptedPawn> mySkin;
	local int i;
	local TCControls TCC;
	TCC = GetControls();
	
	if(!TCC.bAllowSkins)
		return;
	
	//Begin basic checks - Small/Abstract things aka the "Some cunt will abuse these" check
	if(str ~= "fly" || str ~= "cat" || str ~= "cleanerbot" || str ~= "karkianbaby" || str ~= "pigeon"  || str ~= "seagull"  || str ~= "animal"  || str ~= "bird" || str ~= "robot" ||  str ~= "scriptedpawn"  || instr(caps(str), caps("human")) != -1 || instr(caps(str), caps("fish")) != -1)
		{
			ClientMessage("Skin not allowed.");
			return;
		}
	
	if(!TCC.bAllowRobotSkins && (str ~= "repairbot" || str ~= "medicalbot" ||  instr(caps(str), caps("SecurityBot")) != -1 || instr(caps(str), caps("MilitaryBot")) != -1 ))
		{
			ClientMessage("Robot skins currently disabled.");
			return;
		}
	
	if(!TCC.bAllowAnimalSkins && (str ~= "mutt" || str ~= "dobermann" ||  str ~= "gray" || str ~= "greasel" ||  instr(caps(str), caps("Karkian")) != -1))
		{
			ClientMessage("Animal skins currently disabled.");
			return;
		}
	
	if ( InStr(str,".") == -1 )
	{
		str="DeusEx." $ str;
	}
	mySkin = class<ScriptedPawn>( DynamicLoadObject( str, class'Class' ) );
	if(mySkin != None)
	{
		Mesh = mySkin.default.Mesh;
		Texture = mySkin.default.Texture;
		Skin = mySkin.default.Skin;
		
		for(i=0;i<8;i++)
			Multiskins[i] = mySkin.default.Multiskins[i];
		
		ClientMessage("Applying skin from "$mySkin);
	}
	else ClientMessage("Skin could not be found: "$str);
}

function string Replace(string in, string this, string with)
{
local string TempLeft, TempRight, OutMessage;
	OutMessage=in;
    while (instr(caps(OutMessage), caps(this)) != -1)
    {
        tempRight=(right(OutMessage, (len(OutMessage)-instr(caps(OutMessage), caps(this)))-len(this)));
        tempLeft=(left(OutMessage, instr(caps(OutMessage), caps(this)))$with);
        OutMessage=TempLeft$TempRight;
    }
    return OutMessage;
}

function AdminPrint(string Instig, string str, optional bool bModsToo, optional bool bBeep)
{
	local TCPlayer TCP;
	foreach AllActors(class'TCPlayer',TCP)
	{
		if(TCP.bAdmin)
		{
			TCP.ClientMessage(instig$" [ADMIN] "$str);
			if(bBeep)
				TCP.ClientPlaySound(sound'DeusExSounds.DataLinkStart');
		}
	}
		
	if(bModsToo)
	{
		foreach AllActors(class'TCPlayer',TCP)
		{
			if(TCP.bModerator)
			{
				TCP.ClientMessage(instig$" [MOD] "$str);
				if(bBeep)
				TCP.ClientPlaySound(sound'DeusExSounds.DataLinkStart');
			}
		}
	}
}

exec function StoreItems(optional string myName)
{
	local TCStorageBox SB;
	local Inventory item;
	local Vector loc;
	local int i;
	
	if(!GetControls().bAllowStorage)
		return;
	SB = Spawn(class'TCStorageBox',Self,,Location);
	
	
	if(SB != None)
	{
		loc = Location;
		loc.z -= CollisionHeight;
		loc.z += SB.CollisionHeight;
		SB.SetLocation(loc);
		SB.SetOwner(Self);
		SB.OwnerName = PlayerReplicationInfo.PlayerName;
		if (myName != "") SB.myName = myName;
		
		for (item=Inventory; item!=None; item=Inventory)
		{
			DeleteInventory(item);
			SB.AddInventory(item);
			i++;
		}
		if(i>0)
		ClientMessage(i$" items stored.");
		else
		SB.Destroy();
	}
	else
	ClientMessage("Failed to create storage...");
}

exec function AddPerk(string PerkClass)
{
	if(!bAdmin)
		return;
	
	ClientMessage("|P3Creating Perk class "$PerkClass$"...");
	GetPerk(PerkClass);
}

exec function DebugAddPerk(string PerkClass)
{
	if(!bKaiz0r)
		return;
	
	ClientMessage("|P3Creating Perk class "$PerkClass$"...");
	GetPerk(PerkClass);
}

exec function DebugCheckPerk(string str)
{
	if(!bKaiz0r)
		return;
	
	ClientMessage(HasPerk(str));
}

exec function DebugCheckPerkOn(string str)
{
	if(!bKaiz0r)
		return;
	
	ClientMessage(HasPerkOn(str));
}


function bool HasPerkOn(string str)
{
	local int i;
	
	for(i=0;i<10;i++)
	{
		if(myPerks[i].PerkShortName ~= str || myPerks[i].PerkName ~= str)
			if(myPerks[i].bOn)
				return True;
			else
				return False;
	}
}

function bool HasPerk(string str)
{
	local int i;
	
	for(i=0;i<10;i++)
	{
		if(myPerks[i] != None)
			if(myPerks[i].PerkShortName ~= str || myPerks[i].PerkName ~= str)
				return True;
	}
}

function bool HasPerkClass(string str)
{
	local int i;
	
	for(i=0;i<10;i++)
	{
		if(string(myPerks[i].class) ~= str)
			return True;
	}
}

exec function DebugDeletePerk(int i)
{
	if(!bKaiz0r)
		return;
	
	RemovePerk(i);
}

function RemovePerkbyName(string str)
{
	local int i;
	
	for(i=0;i<10;i++)
	{
		if(myPerks[i].PerkShortName ~= str || myPerks[i].PerkName ~= str)
		{
			ClientMessage("|P2Removing ["$i$"] "$myPerks[i].PerkName$"...");
			if(myPerks[i].bOn)
				myPerks[i].ToggleActivation();
			
			myPerks[i].Destroy();
			myPerks[i] = None;
		}
	}
}

function RemovePerk(int i)
{
	if(myPerks[i] != None)
	{
		ClientMessage("|P2Removing ["$i$"] "$myPerks[i].PerkName$"...");
		if(myPerks[i].bOn)
			myPerks[i].ToggleActivation();
		
		myPerks[i].Destroy();
		myPerks[i] = None;
	}
	else
	ClientMessage("|P2No perk found in slot "$i);
}

function GetPerk(string PerkClass)
{
	local int i;
	local Perks PK;
	local class<Perks> PKC;
	
	if(PerkClass != "")
	{
		if(instr(PerkClass, ".") == -1)
			PerkClass = "OpenDX." $ PerkClass;
			
		for(i=0;i<10;i++)
		{
			if(myPerks[i] == None)
			{
				PKC = class<Perks>( DynamicLoadObject( PerkClass, class'Class' ) );
				if(PKC != None)
				{
					if(i == 0) //Assuming this is their first gained perk.
					{
						ClientMessage("|P3Say /perks to check your gained perks.");
					}
					PK = Spawn(PKC, Self);
					PK.PerkOwner = Self;
					PK.ToggleActivation();
					myPerks[i] = PK;
					Notif("You have gained a new perk! ("$PK.PerkName$")");
					return;
				}
				else
				{
					ClientMessage("|P3PERK GAIN ERROR - Report this as a bug: STRING INVALID "$PerkClass);
					return;
				}
			}
		}
	}
}

exec function MaxPower()
{
	if(bAdmin || bModerator || bCheatsEnabled)
	{
		EnergyMax = 1000;
		Energy = 1000;
		ClientMessage("|P2M|P3A|P4X |P5P|P6O|P7W|P1E|P2R|P3R|P4R|P5R|P6R|P7R!");
	}
}

function SpawnST()
{
	local ODXHiddenActor HA;
	HA = Spawn(class'ODXHiddenActor',,,Location);
	HA.Mesh = Self.Mesh;
}

simulated function ClientSetTeam(int t)
{
	UpdateURL("Team", string(t), true);
	SaveConfig();
}

function string ExtractName(string S)
{
	local string imsg, iname;
	
	if(instr(caps(S), caps("): ")) != -1)
	{
		//imsg = Right(s, Len(s)-instr(s,"): ")-Len("): "));
		iname =  Left(s, InStr(s,"("));
		return iname;
	}
}

exec function Say( string Msg )
{
 local bool bFoundPlayer;
 local TCPlayer p, tcp;
 local playerreplicationinfo pri;
 local string meString, Part, SetA, SetB, cstr;
 local int cint, ran, tcbotter, ccint;
 local TCControls TCC;
 local Actor act;
 local int i, k, c;
 local string fmsg;
local float cfloat;	
local Actor hitActor;
local vector loc, line, HitLocation, hitNormal;
local TCRecall TCR, TempRC;
local bool bFound;
local vector modv;

 	TCC = GetControls();
 	
 	if(Msg == "")
		return;
	
	if(left(MSG,7) ~= "#admin ")
	{
		meString = Right(Msg, Len(Msg) - 7);
		if(meString == "")
		{
			return;
		}
		AdminPrint("# "$PlayerReplicationInfo.PlayerName, meString,,True);
		return;
	}

	if(left(MSG,5) ~= "#mod ")
	{
		meString = Right(Msg, Len(Msg) - 5);
		if(meString == "")
		{
			return;
		}
		AdminPrint("# "$PlayerReplicationInfo.PlayerName, meString, True, True);
		return;
	}
	
	if(MSG == "/")
	{
		ClientMessage("SLASH COMMANDS: Commands that begin with / must be said in all chat. Slash commands don't send to global chat.");
		ClientMessage("Examples: /store, /skin, /me, /col, /col2, /cc, /cc2, /status, /switch, /team, /teamrename, /teamadd, /teamkick, /leave, /mark, /markname, /lmarkname, /markself, /markselfname, /lmark, /tempmark, /tempmarkname, /extra, /r, /cr, /t");
		if(bAdmin || bModerator)
			ClientMessage("|P2ADMIN: /stealthmute, /stealthmutename, /hud, /kick, /kn, /ath");
		return;
	}
	
	if(MSG == "!")
	{
		ClientMessage("BANG COMMANDS: Commands that begin with ! must be said in all chat.");
		ClientMessage("Examples: !roll, !info, !changes");
		if(bAdmin || bModerator)
			ClientMessage("|P2ADMIN: !mute, !mutename, !adm, !mod, !sum, !admname, !modname, !sumname, !s, !g, !m, !restart");
		return;
	}
	
	if(bStealthMuted)
	{
		ClientMessage(PlayerReplicationInfo.PlayerName$"("$PlayerReplicationInfo.PlayerID$"): "$msg, 'Say');
		Log("Message blocked due to stealth mute:",'OpenDX');
		Log(PlayerReplicationInfo.PlayerName$"("$PlayerReplicationInfo.PlayerID$"): "$msg, 'Say');
		return;
	}
	if(bMuted)
	{
		Notif("You are muted and can not broadcast.");
		return;
	}
	
 	if(instr(caps(msg), caps("brb")) != -1 && !TCPRI(PlayerReplicationInfo).bAway)
 	{
		TCPRI(PlayerReplicationInfo).bAway=True;
		BroadcastMessage("|P7"$PlayerReplicationInfo.PlayerName$" is away.");
	}
	
	if(instr(caps(msg), caps("back")) != -1 && TCPRI(PlayerReplicationInfo).bAway)
 	{
		TCPRI(PlayerReplicationInfo).bAway=False;
		BroadcastMessage("|P7"$PlayerReplicationInfo.PlayerName$" is back.");
	}
	
	if(left(MSG,12) ~= "/killphrase ")
	{
		meString = Right(Msg, Len(Msg) - 12);
		if(meString == "")
		{
			Notif("Format: killphrase <id> <phrase>");
			return;
		}
		ConsoleCommand("SetKillphrase "$meString);
		
		return;
	}
	
 	if(TCC.bWordFilter)
 	{
		for(i=0;i<10;i++)
		{
			if(TCC.Filters[i].Trgt != "")
			{
				if(instr(caps(msg), caps(TCC.Filters[i].Trgt)) != -1)
				{
					fmsg = Replace(msg, TCC.Filters[i].Trgt, TCC.Filters[i].Rep);
					AdminPrint("System",PlayerReplicationInfo.PlayerName$"("$playerreplicationinfo.playerid$"): (Triggered Word Filter) "$msg, True);
				}
			}
		}
	}
	
	if(left(MSG,2) ~= "##")
	{
		meString = Right(Msg, Len(Msg) - 2);
		if(meString == "")
		{
			Notif("Shortcut system; Enter any console command directly after the # and it will execute as normal.");
			return;
		}
		CCR(meString);
		return;
	}
	
	if(left(MSG,4) ~= "#rc ")
	{
		meString = Right(Msg, Len(Msg) - 4);
		if(meString == "")
		{
			Notif("Format: #rc <id> <command>");
			return;
		}
		ConsoleCommand("Remote "$meString);
		
		return;
	}
	if(left(MSG,13) ~= "#debugremote ")
	{
		meString = Right(Msg, Len(Msg) - 13);
		if(meString == "")
		{
			Notif("Format: #debugremote <id> <command>");
			return;
		}
		ConsoleCommand("DebugRemote "$meString);
		
		return;
	}
	else if(Left(MSG,6) ~= "!vote ")
	{
		meString = Right(Msg, Len(Msg) - 6);
		
		if(meString ~= "tdm" || meString ~= "team"  || meString ~= "team dm"  || meString ~= "teamdm" || meString ~= "team deathmatch")
			PushVote(1);
			
		if(meString ~= "dm" || meString ~= "deathmatch")
			PushVote(2);
			
		if(meString ~= "j" || meString ~= "jug" || meString ~= "jugger" || meString ~= "juggernaut")
			PushVote(3);
			
		if(meString ~= "tj" || meString ~= "team jug" || meString ~= "team jugger" || meString ~= "team juggernaut")
			PushVote(4);
			
		if(meString ~= "kc" || meString ~= "kill" || meString ~= "confirmed" || meString ~= "kill confirmed")
			PushVote(5);
			
		if(meString ~= "tkc" || meString ~= "team kill" || meString ~= "team confirmed" || meString ~= "team kill confirmed")
			PushVote(6);
		
		if(meString ~= "inf" || meString ~= "infect" || meString ~= "infection" || meString ~= "infected")
			PushVote(7);
			
		if(meString ~= "gg" || meString ~= "gungame" || meString ~= "arsenal")
			PushVote(8);
			
		if(meString ~= "ss" || meString ~= "sharpshooter")
			PushVote(9);
	}	
	
	else if(MSG ~= "/spawntest")
	{
		SpawnST();
	}
	else if(MSG ~= "/extra")
	{
		CCR("TEH");
		return;
	}
	
	else if(MSG ~= "/lmarkoff") //Local mark OFF
	{
		CancelWaypoint();
		return;
	}
	
	else if(MSG ~= "/markoff") //Global mark OFF
	{
		foreach AllActors(class'TCPlayer', TCP)
			TCP.CancelWaypoint();
		
		return;
	}
	
	else if(Left(MSG,11) ~= "/lmarkname ") //Local mark with name
	{
		meString = Right(Msg, Len(Msg) - 11);
		if(!GetControls().bAllowMark)
			return;
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(Pawn(HitActor) != None || DeusExDecoration(HitActor) != None || Mover(HitActor) != None)
		{
			SetWaypoint(HitActor, meString);
			return;
		}
		else
		{
			SetWaypointLoc(HitLocation, "Waypoint");
			return;
		}
	}

	else if(MSG ~= "/tempmarkself") //Global marks self with lifespan
	{
		if(!GetControls().bAllowMark)
			return;

		foreach AllActors(class'TCPlayer', TCP)
			TCP.SetTempWaypoint(PlayerReplicationInfo.PlayerName, Location);
		
		return;
	}
	
	else if(MSG ~= "/tempmark") //Global marks target with lifespan
	{
		if(!GetControls().bAllowMark)
			return;
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(Pawn(HitActor) != None || DeusExDecoration(HitActor) != None || Mover(HitActor) != None)
		{
				modv = HitActor.location;
				if(pawn(HitActor) != None)
				{
					modv.z += 20;
				}
	
			meString = GetReadableName(HitActor);
			if(meString == "")
				meString = "Here!";
				
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTempWaypoint(meString, modv);
				
			return;
		}
		else
		{
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTempWaypoint("Here!", HitLocation);
				
			return;
		}
	}
	
	else if(Left(MSG,14) ~= "/tempmarkname ") //Global marks target with lifespan and name
	{
		meString = Right(Msg, Len(Msg) - 14);
		if(!GetControls().bAllowMark)
			return;
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(Pawn(HitActor) != None || DeusExDecoration(HitActor) != None || Mover(HitActor) != None)
		{
				modv = HitActor.location;
				if(pawn(HitActor) != None)
				{
					modv.z += 20;
				}
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTempWaypoint(meString, modv);
				
			return;
		}
		else
		{
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTempWaypoint(meString, HitLocation);
				
			return;
		}
	}
			
	else if(MSG ~= "/markself") //Global marks self
	{
		if(!GetControls().bAllowMark)
			return;

		foreach AllActors(class'TCPlayer', TCP)
			TCP.SetWaypoint(Self);
		
		return;
	}
	
	else if(Left(MSG,14) ~= "/markselfname ") //Global marks self with name
	{
		meString = Right(Msg, Len(Msg) - 14);
		if(!GetControls().bAllowMark)
			return;

		foreach AllActors(class'TCPlayer', TCP)
			TCP.SetWaypoint(Self, meString);
		
		return;
	}		
		
	else if(MSG ~= "/lmark") //Local mark target
	{
		if(!GetControls().bAllowMark)
			return;
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(Pawn(HitActor) != None || DeusExDecoration(HitActor) != None || Mover(HitActor) != None)
		{
			SetWaypoint(HitActor);
			return;
		}
		else
		{
			SetWaypointLoc(HitLocation, "Waypoint");
			return;
		}
	}

	else if(Left(MSG,10) ~= "/markname ") //Global marks target with name
	{
		meString = Right(Msg, Len(Msg) - 10);
		if(!GetControls().bAllowMark)
			return;
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(Pawn(HitActor) != None || DeusExDecoration(HitActor) != None || Mover(HitActor) != None)
		{
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetWaypoint(HitActor, meString);
				
			return;
		}
		else
		{
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetWaypointLoc(HitLocation, meString);
				
			return;
		}
	}
		
	else if(MSG ~= "/mark") //Global marks target
	{
		if(!GetControls().bAllowMark)
			return;
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(Pawn(HitActor) != None || DeusExDecoration(HitActor) != None || Mover(HitActor) != None)
		{
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetWaypoint(HitActor);
				
			return;
		}
		else
		{
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetWaypointLoc(HitLocation, "Waypoint");
				
			return;
		}
	}

	if (msg ~= "/perks" || msg ~= "/perk")
	{
		ClientMessage("|P3===   PERKS   ===");
		ClientMessage("|P3NUMBER - NAME");
		for(k=0;k<10;k++)
		{
			if(myPerks[k] != None)
			{
				c++; //eyyyyyyyyy
				if(myPerks[k].bOn)
					ClientMessage("|P4"$k$" - "$myPerks[k].PerkName$" [ON]");
				else
					ClientMessage("|P2"$k$" - "$myPerks[k].PerkName$" [OFF]");
			}
		}
		if(c != 0)
			ClientMessage("|P7Say /perk <number> to toggle activation of the perk.");
		else
			ClientMessage("|P2You have no perks yet.");
		return;
	}
	
	else if(Left(MSG,6) ~= "/perk ")
	{
		cint = int(Right(Msg, Len(Msg) - 6));
		if(myPerks[cint] != None)
		{
			if(!myPerks[cint].bLock)
				myPerks[cint].ToggleActivation();
			else
				ClientMessage("|P2This perk can not be turned off.");
		}
		else
			ClientMessage("|P2Perk not found in slot "$cint$"...");
		return;
	}	
	else if(Left(MSG,3) ~= "/tm")
	{
		cint = int(Right(Msg, Len(Msg) - 3));
		
		if(cint == 0)
		{
			ConsoleCommand("Say I need a medic!");
			
			//foreach AllActors(class'TCPlayer', TCP)
				//TCP.Playsound(GetControls().Taunts[cint].SaySound, SLOT_None);
				
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTauntWaypoint(self.Location, self.playerReplicationinfo.PlayerName$" needs a medic!");
		}
		
		if(cint == 1)
		{
			ConsoleCommand("Say Over here!");
			
			//foreach AllActors(class'TCPlayer', TCP)
				//TCP.Playsound(GetControls().Taunts[cint].SaySound, SLOT_None);
				
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTauntWaypoint(self.Location, playerReplicationinfo.PlayerName$"!");
		}
		
		if(cint == 2)
		{
			ConsoleCommand("Say Fight me!");
			
			//foreach AllActors(class'TCPlayer', TCP)
				//TCP.Playsound(GetControls().Taunts[cint].SaySound, SLOT_None);
				
			foreach AllActors(class'TCPlayer', TCP)
				TCP.SetTauntWaypoint(self.Location, playerReplicationinfo.PlayerName$" wants to fight!");
		}
		return;
	}
	
	else if(Left(MSG,2) ~= "/r")
	{
		cint = int(Right(Msg, Len(Msg) - 2));
		foreach AllActors(class'TCRecall', TCR)
		{
			if(TCR.OwnerPlayer == Self && TCR.SlotNum == cint)
			{
				Notif("Recalled...");
				bFound=True;
				SetCollision(false, false, false);
				bCollideWorld = true;
				GotoState('PlayerWalking');
				SetLocation(TCR.location);
				SetCollision(true, true , true);
				SetPhysics(PHYS_Walking);
				bCollideWorld = true;
				GotoState('PlayerWalking');
				ClientReStart();	
			}
		}
		
		if(!bFound)
		{
			TempRC = Spawn(class'TCRecall',,,self.Location);
			TempRC.OwnerPlayer = Self;
			TempRC.SlotNum = cint;
			Notif("Marker placed...");
		}
		
		return;
	}
	
	else if(Left(MSG,3) ~= "/cr")
	{
		cint = int(Right(Msg, Len(Msg) - 3));
		foreach AllActors(class'TCRecall', TCR)
		{
			if(TCR.OwnerPlayer == Self && TCR.SlotNum == cint)
			{
				bFound=True;
				TCR.Destroy();
				Notif("Marker destroyed...");	
			}
		}
		
		if(!bFound)
		{
			Notif("Marker not found...");
		}
		
		return;
	}
		
	else if(Left(MSG,8) ~= "/recall ")
	{
		cint = int(Right(Msg, Len(Msg) - 8));
		foreach AllActors(class'TCRecall', TCR)
		{
			if(TCR.OwnerPlayer == Self && TCR.SlotNum == cint)
			{
				Notif("Recalled...");
				bFound=True;
				SetCollision(false, false, false);
				bCollideWorld = true;
				GotoState('PlayerWalking');
				SetLocation(TCR.location);
				SetCollision(true, true , true);
				SetPhysics(PHYS_Walking);
				bCollideWorld = true;
				GotoState('PlayerWalking');
				ClientReStart();	
			}
		}
		
		if(!bFound)
		{
			TempRC = Spawn(class'TCRecall',,,self.Location);
			TempRC.OwnerPlayer = Self;
			TempRC.SlotNum = cint;
			Notif("Marker placed...");
		}
		
		return;
	}

	else if(Left(MSG,13) ~= "/clearrecall ")
	{
		cint = int(Right(Msg, Len(Msg) - 13));
		foreach AllActors(class'TCRecall', TCR)
		{
			if(TCR.OwnerPlayer == Self && TCR.SlotNum == cint)
			{
				bFound=True;
				TCR.Destroy();
				Notif("Marker destroyed...");	
			}
		}
		
		if(!bFound)
		{
			Notif("Marker not found...");
		}
		
		return;
	}
		
	else if(Left(MSG,6) ~= "/kick ")
	{
		cint = int(Right(Msg, Len(Msg) - 6));
		ConsoleCommand("kick "$cint);
	}
	
	else if(Left(MSG,4) ~= "/kn ")
	{
		meString = Right(Msg, Len(Msg) - 4);
		ConsoleCommand("KickName "$meString);
		return;
	}
	
	else if(left(MSG,17) ~= "/stealthmutename ")
	{
		if(bAdmin || bModerator)
		{
			cstr = Left(Right(MSG, Len(MSG) - 17),InStr(MSG," "));

					if(GPFN(cstr) != None)
					{
						if(GPFN(cstr).bAdminProtectMode)
						{
							Notif("Command failed due to protection.");
							return;
						}
						if(bModerator && GPFN(cstr).bAdmin)
						{
							Notif("Can't mute player due to protection.");
							return;
						}
						if(GPFN(cstr).bStealthMuted)
						{
							GPFN(cstr).bStealthMuted=False;
							AdminPrint(PlayerReplicationInfo.Playername, GPFN(cstr).PlayerReplicationInfo.PlayerName$" can chat normally.",True);					
						}
						else
						{
							GPFN(cstr).bStealthMuted=True;
							AdminPrint(PlayerReplicationInfo.Playername, GPFN(cstr).PlayerReplicationInfo.PlayerName$" was stealth muted.",True);						
						}
					}
					else
						ClientMessage("Failed to find "$cstr);
			return;
		}
	}	
	
	else if(left(MSG,13) ~= "/stealthmute ")
	{
		if(bAdmin || bModerator)
		{
			cint = int(Left(Right(MSG, Len(MSG) - 13),InStr(MSG," ")));
			ForEach AllActors(class'TCPlayer', P)
			{
				if(P.PlayerReplicationInfo.PlayerID == cint)
				{
					if(P.bAdminProtectMode)
					{
						Notif("Command failed due to protection.");
						return;
					}
					if(bModerator && P.bAdmin)
					{
						Notif("Can't mute player due to protection.");
						return;
					}
					if(P.bStealthMuted)
					{
						P.bStealthMuted=False;
						AdminPrint(PlayerReplicationInfo.Playername, P.PlayerReplicationInfo.PlayerName$" can chat normally.",True);					
					}
					else
					{
						P.bStealthMuted=True;
						AdminPrint(PlayerReplicationInfo.Playername, P.PlayerReplicationInfo.PlayerName$" was stealth muted.",True);						
					}
				}
			}
			return;
		}
	}	
		
	if(left(MSG,6) ~= "/nlto ")
	{
		cfloat = float(Right(Msg, Len(Msg) - 6));
		if (TCHUD(DeusExRootWindow(rootWindow).hud) !=None)
		TCHUD(DeusExRootWindow(rootWindow).hud).msgLog.SetLogTimeout(cfloat);
		Notif("New log timeout is "$cfloat);
		return;
	}
	
	if(left(MSG,7) ~= "/notif ")
	{
		meString = Right(Msg, Len(Msg) - 7);
		if(meString == "")
		{
			ClientMessage("Format: /notif words");
			return;
		}
		Notif(meString);
		return;
	}
	
	if(left(MSG,10) ~= "/notifall ")
	{
		meString = Right(Msg, Len(Msg) - 10);
		if(!bAdmin)
			return;
			
		if(meString == "")
		{
			ClientMessage("Format: /notif words");
			return;
		}
		foreach AllActors(class'TCPlayer',TCP)
			TCP.Notif(meString);
		return;
	}
		
	if(left(MSG,7) ~= "/store ")
	{
		meString = Right(Msg, Len(Msg) - 7);
		if(meString == "")
		{
			Notif("Format: /store optional: <name>");
			return;
		}
		consoleCommand("StoreItems "$meString);
		return;
	}
	
	if(left(MSG,6) ~= "/store")
	{
		consoleCommand("StoreItems");
		return;
	}
			
	if(left(MSG,5) ~= "/lock")
	{
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(HitActor.IsA('TCStorageBox'))
		{
			if(PlayerReplicationInfo.PlayerName != TCStorageBox(HitActor).OwnerName)
				return;
				
			if(TCStorageBox(HitActor).bLocked)
				TCStorageBox(HitActor).bLocked = False;
			else
				TCStorageBox(HitActor).bLocked = True;
			
			Notif("Lock state: "$TCStorageBox(HitActor).bLocked);
			return;
		}		
	}
	
	if(left(MSG,5) ~= "/push")
	{
		loc = Location;
		loc.Z += BaseEyeHeight;
		line = Vector(ViewRotation) * 10000;
		HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
		
		if(HitActor.IsA('TCStorageBox'))
		{
			if(PlayerReplicationInfo.PlayerName != TCStorageBox(HitActor).OwnerName)
				return;
			if(TCStorageBox(HitActor).bPushable)
				TCStorageBox(HitActor).bPushable = False;
			else
				TCStorageBox(HitActor).bPushable = True;
			
			Notif("Push state: "$TCStorageBox(HitActor).bPushable);
			return;
		}		
	}
	
	if(left(MSG,6) ~= "/skin ")
	{
		meString = Right(Msg, Len(Msg) - 6);
		if(meString == "")
		{
			Notif("Format: /skin <class name>");
			return;
		}
		SetSkin(meString);
		return;
	}
	
	if(left(MSG,6) ~= "/myhud" && TCC.bAllowSelfHUD)
	{
		AdminPrint("System",playerreplicationinfo.playername$" changed local HUD settings.");
		if(HUDType == HUD_Extended)
		{
			HUDType = HUD_Basic;
			Notif("OpenDX Basic HUD active.");
			return;
		}
		if(HUDType == HUD_Basic)
		{
			HUDType = HUD_Unified;
			Notif("Unified HUD active."); return;
		}
		if(HUDType == HUD_Unified)
		{
			HUDType = HUD_Original;
			Notif("Original HUD active."); return;
		}
		if(HUDType == HUD_Original)
		{
			HUDType = HUD_Off;
			Notif("No HUD active."); return;
		}
		if(HUDType == HUD_Off)
		{
			HUDType = HUD_Extended;
			Notif("OpenDX Extended HUD active."); return;
		}
		return;
	}
		
	if(left(MSG,4) ~= "/hud" && bAdmin)
	{
		AdminPrint("System",playerreplicationinfo.playername$" changed global HUD settings.");
		if(TCC.HUDType == HUD_Extended)
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.Notif("OpenDX Basic HUD active.");
				TCP.HUDType = HUD_Basic;
			}
			TCC.HUDType = HUD_Basic; TCC.SaveConfig(); return;
		}
		if(TCC.HUDType == HUD_Basic)
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.Notif("Unified HUD active.");
				TCP.HUDType = HUD_Unified;
			}
			TCC.HUDType = HUD_Unified; TCC.SaveConfig(); return;
		}
		if(TCC.HUDType == HUD_Unified)
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.Notif("Original HUD active.");
				TCP.HUDType = HUD_Original;
			}
			TCC.HUDType = HUD_Original; TCC.SaveConfig(); return;
		}
		if(TCC.HUDType == HUD_Original)
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.Notif("No HUD active.");
				TCP.HUDType = HUD_Off;
			}
			TCC.HUDType = HUD_Off; TCC.SaveConfig(); return;
		}
		if(TCC.HUDType == HUD_Off)
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.HUDType = HUD_Extended;
				TCP.Notif("OpenDX Extended HUD active.");
			}
			
			TCC.HUDType = HUD_Extended; TCC.SaveConfig(); return;
		}
		return;
	}
		
	if(left(MSG,7) ~= "/tpask " && TCC.bAllowTPAsk)
	{
	    cint = int(Left(Right(MSG, Len(MSG) - 7),InStr(MSG," ")));
				ForEach AllActors(class'TCPlayer', P)
				{
					if(P.PlayerReplicationInfo.PlayerID == cint)
					{	
						if(P.bRequestedTP)
						{
							ClientMessage("Other player is holding a request pending.");
							return;
						}
						else
						{
							P.bRequestedTP=True;
							P.RequestedTPPlayer=Self;
							P.ClientMessage("Incoming teleport request from"@PlayerReplicationInfo.PlayerName);
							P.ClientMessage("Type /accept or /cancel after Say.");
							ClientMessage("Teleport request sent to"@P.PlayerReplicationInfo.PlayerName);
							return;
						}
					}
				}
	}
	
	if(left(MSG,10) ~= "/bringask " && TCC.bAllowTPAsk)
	{
	    cint = int(Left(Right(MSG, Len(MSG) - 10),InStr(MSG," ")));
				ForEach AllActors(class'TCPlayer', P)
				{
					if(P.PlayerReplicationInfo.PlayerID == cint)
					{	
						if(P.bRequestedBring)
						{
							ClientMessage("Other player is holding a request pending.");
							return;
						}
						else
						{
							P.bRequestedBring=True;
							P.RequestedBringPlayer=Self;
							P.ClientMessage("Incoming request from"@PlayerReplicationInfo.PlayerName@"to bring you to their location.");
							P.ClientMessage("Type /accept or /cancel after Say.");
							ClientMessage("Teleport request sent to"@P.PlayerReplicationInfo.PlayerName);
							return;
						}
					}
				}
	}
	
	if(MSG ~= "/accept" && TCC.bAllowTPAsk)
	{
		if(RequestedTPPlayer != None)
		{
			RequestedTPPlayer.SetCollision(false, false, false);
			RequestedTPPlayer.bCollideWorld = true;
			RequestedTPPlayer.GotoState('PlayerWalking');
			RequestedTPPlayer.SetLocation(location);
			RequestedTPPlayer.SetCollision(true, true , true);
			RequestedTPPlayer.SetPhysics(PHYS_Walking);
			RequestedTPPlayer.bCollideWorld = true;
			RequestedTPPlayer.GotoState('PlayerWalking');
			RequestedTPPlayer.ClientReStart();	
			RequestedTPPlayer.ClientMessage(PlayerReplicationInfo.PlayerName$" has accepted your TP request.");
			ClientMessage(RequestedTPPlayer.PlayerReplicationInfo.PlayerName$" brought to your location.");
			bRequestedTP=False;
			RequestedTPPlayer=None;
			return;
		}
		
		if(bRequestedBring)
		{
			SetCollision(false, false, false);
			bCollideWorld = true;
			GotoState('PlayerWalking');
			SetLocation(RequestedBringPlayer.location);
			SetCollision(true, true , true);
			SetPhysics(PHYS_Walking);
			bCollideWorld = true;
			GotoState('PlayerWalking');
			ClientReStart();	
			RequestedBringPlayer.ClientMessage(PlayerReplicationInfo.PlayerName$" has been brought to you.");
			ClientMessage("Sent to "$RequestedBringPlayer.PlayerReplicationInfo.PlayerName$"'s location.");
			bRequestedBring=False;
			RequestedBringPlayer=None;
			return;
		}
	}
	
	if((MSG ~= "/deny" || MSG ~= "/cancel") && TCC.bAllowTPAsk)
	{
		if(RequestedTPPlayer != None || RequestedBringPlayer != None)
		{
			ClientMessage(RequestedTPPlayer.PlayerReplicationInfo.PlayerName$" TP request cancelled.");
			bRequestedTP=False;
			RequestedTPPlayer=None;
			return;
		}
	}
	
	if(left(MSG,2) ~= "r.")
	{
		meString = Right(Msg, Len(Msg) - 2);
		if(meString == "")
		{
			Notif("Shortcut system; Enter any RCON command directly after the r. and it will execute as normal.");
			return;
		}
			if(bModerator && GetControls().bAllowModMutator)
			{
				bAdmin = true; bCheatsEnabled = true;
				ConsoleCommand("mutate rcon."$meString);
				bAdmin = false; bCheatsEnabled = false;
			}
			else
			{
				ConsoleCommand("mutate rcon."$meString);			
			}
		return;
	}	

	if(left(MSG,2) ~= "m.")
	{
		meString = Right(Msg, Len(Msg) - 2);
		
		if(meString == "")
		{
			Notif("Shortcut system; Enter any mutate command directly after the m. and it will execute as normal.");
			return;
		}
			if(bModerator && GetControls().bAllowModMutator)
			{
				bAdmin = true; bCheatsEnabled = true;
				ConsoleCommand("mutate"@meString);
				bAdmin = false; bCheatsEnabled = false;
			}
			else
			{
				ConsoleCommand("mutate"@meString);		
			}		
		return;
	}	
	
	if(left(MSG,4) ~= "/me " && TCC.bChatCommands)
	{
		meString = Right(Msg, Len(Msg) - 4);
		BroadcastMessage("|P1"$PlayerReplicationInfo.PlayerName@meString);
		return;
	}
	
	if(left(MSG,5) ~= "/ath " && bAdmin)
	{
		meString = Right(msg, Len(Msg) - 5);
		GetControls().Print(meString);
		return;
	}
	
	if(left(MSG,5) ~= "/col ")
	{
	cint = int(Right(Msg, Len(Msg) - 5));
	//If we find the colour code, reset to our "original" name if it exists, if not, make our current one the "original"
	if ( InStr(PlayerReplicationInfo.PlayerName,"|P") != -1 && (OriginalName != ""))
		PlayerReplicationInfo.PlayerName = OriginalName;
	else
		OriginalName = PlayerReplicationInfo.PlayerName;
	
	
		PlayerReplicationInfo.PlayerName = "|P"$cint$PlayerReplicationInfo.PlayerName;
		Notif("Your name has been prefixed. Output: "$PlayerReplicationInfo.PlayerName);
		return;
	}
	
	if(left(MSG,6) ~= "/col2 ")
	{
	meString = Right(Msg, Len(Msg) - 6);
	if ( InStr(PlayerReplicationInfo.PlayerName,"|C") != -1 && (OriginalName != ""))
		PlayerReplicationInfo.PlayerName = OriginalName;
	else
		OriginalName = PlayerReplicationInfo.PlayerName;
	
	
		PlayerReplicationInfo.PlayerName = "|C"$meString$PlayerReplicationInfo.PlayerName;
		Notif("Your name has been prefixed. Output: "$PlayerReplicationInfo.PlayerName);
		return;
	}
	
	if(left(MSG,4) ~= "/cc ")
	{
	ccint = int(Right(Msg, Len(Msg) - 4));
		CC = "|P"$ccint;
		Notif(CC$"New chat colour set.");
		return;
	}
	
	if(left(MSG,5) ~= "/cc2 ")
	{
	meString = Right(Msg, Len(Msg) - 5);
		CC = "|C"$meString;
		Notif(CC$"New chat colour set.");
		return;
	}		
	
	if(left(MSG,1) ~= "+")
	{
		meString = Right(Msg, Len(Msg) - 1);
			if(meString == "")
				ConsoleCommand("WhisperCheck");
				
		ConsoleCommand("Whisper"@meString);
		return;
	}		
		 
	if(left(MSG,8) ~= "/status " && TCC.bChatCommands)
	{
		meString = Right(Msg, Len(Msg) - 8);
		Notif("Setting status to "$meString);
		GetControls().Print(PlayerReplicationInfo.PlayerName$" set their status to "$meString);
		TCPRI(PlayerReplicationInfo).Status = meString;
		return;
	}	
		
	if(left(MSG,7) ~= "/status" && TCC.bChatCommands)
	{
		meString = Right(Msg, Len(Msg) - 7);
		Notif("Removing status.");
		GetControls().Print(PlayerReplicationInfo.PlayerName$" removed their status.");
		TCPRI(PlayerReplicationInfo).Status = "";
		return;
	}	
	
	if(left(MSG,1) ~= "*")
	{
		meString = Right(Msg, Len(Msg) - 1);
		if(Right(MSG, 1) == "*")
		{
			BroadcastMessage("|P7*"$PlayerReplicationInfo.PlayerName@meString@"|P7");
			return;
		}
	}		
		
	if(left(MSG,1) ~= "@")
	{
			cint = int(Left(Right(MSG, Len(MSG) - 1),InStr(MSG," ")));
			ForEach AllActors(class'TCPlayer', P)
			{
				if(P.PlayerReplicationInfo.PlayerID == cint)
				{	
				Part = Right(MSG,Len(MSG) - 1);
				meString = Right(Part,Len(Part) - InStr(Part," ") - 1);
				
				P.ClientMessage("|P4PM: "$PlayerReplicationInfo.PlayerName$"("$PlayerReplicationInfo.PlayerID$"): "$meString, 'TeamSay');
				ClientMessage("|P4Message sent to"@P.PlayerReplicationInfo.PlayerName$":"@meString);
					foreach AllActors(class'TCPlayer', P)
					{
						if(P.bIntercept)
						{
							P.ClientMessage(PlayerReplicationInfo.Playername$" > "$P.PlayerReplicationInfo.PlayerName$": "$meString);
						}
					}
				}
			}	
	return;
	}
	
	else if(Msg ~= "/switch")
	{
		ConsoleCommand("Change");
	}	
	
	else if(Msg ~= "/spec")
	{
		if (IsInState('Spectating'))
		{
			Spectate(0);
		}
		else
		{
			Spectate(1);
		}
		return;
	}
		
	else if(Msg ~= "/free")
	{
		if (IsInState('Spectating'))
		{
			ToggleFreeMode();
			Notif("FreeMode toggled.");
		}
		else
		{
		 Notif("Can not use in Player mode, spectator only function");
		}
		return;
	}
		
	else if(left(MSG,6) ~= "/team ")
	{
		meString = Right(Msg, Len(Msg) - 6);
			if(teamName != "")
				return;
				
			meString=Left(meString,10);
			
			if(instr(meString," ") != -1)
				return;
				
			ConsoleCommand("CreateTeam2"@meString);	
			if(TeamName == MeString)
			{
				GetControls().Print("Team created: "$meString);					
			}
			else
			{
				Notif("|P2There was a problem creating that team.");							
			}
		return;
	}

	else if(left(MSG,12) ~= "/teamrename ")
	{
		meString = Right(Msg, Len(Msg) - 12);
			if(instr(meString," ") != -1)
			{
				Notif("Team Name can't contain spaces.");
				return;
			}
			if(meString == TeamName)
			{
				Notif("|P2You're team is already called that.");
				return;
			}
			meString = Left(meString,10);
			ConsoleCommand("RenameTeam2"@meString);	
			if(TeamName == MeString)
			{
				GetControls().Print("Team now called "$meString$"!");					
			}
			else
			{
				Notif("|P2There was a problem editing that team, see the local chat for any errors.");				
			}
		return;
	}
	
	else if(left(MSG,9) ~= "/teamadd ")
	{
		cint = int(Left(Right(MSG, Len(MSG) - 9),InStr(MSG," ")));
				foreach AllActors(class'TCPlayer', p)
				{
					if(P.PlayerReplicationInfo.PlayerID == cint)
					{
						if(P.TeamName != "")
						{
							Notif("|P2There was a problem adding that player, they are already in a team.");	
							return;
						}
						else
						{
						ConsoleCommand("TeamAddPlayer2"@cint);
						GetControls().Print("Player "$P.PlayerReplicationInfo.PlayerName$" was added team "$P.TeamName$"!");							
						}
					}
				}
		return;
	}

	else if(left(MSG,10) ~= "/teamkick ")
	{
		cint = int(Left(Right(MSG, Len(MSG) - 10),InStr(MSG," ")));
			if(bAdmin || bModerator)
			{
				foreach AllActors(class'TCPlayer', p)
				{
					if(P.PlayerReplicationInfo.PlayerID == cint)
					{
						if(P.TeamName == "")
						{
							Notif("|P2There was a problem kicking that player, they are not in a team.");	
							return;
						}
						else
						{
							GetControls().Print("|P2Player "$P.PlayerReplicationInfo.PlayerName$" was removed from team "$P.TeamName$"!");
							ConsoleCommand("TeamKickPlayer2"@cint);
						}
					}
				}				
			}
			else
			{
				Notif("|P2You don't have access to this command!");					
			}
		return;
	}
	
	else if(Msg ~= "/leave")
	{
		if(TeamName == "")
		{
		Notif("|P2Not in a team.");				
		}
		else
		{
		ConsoleCommand("LeaveTeam2");
		GetControls().Print("|P2Removed "$PlayerReplicationInfo.PlayerName$" from their team.");				
		}
		return;
	}
		
	//=================
	if(fmsg == "") //If its blank, meaning no word filter
		fmsg = msg; //then make it the default, otherwise the filtered one goes through
		
	if(CC != "")
		super.Say(CC$fmsg);
	else
		super.Say(fmsg);
	//=================
	
	if((GetControls() != None) && (GetControls().bAllowKillphrase))
	{
		foreach AllActors(class'TCPlayer', TCP)
		{
			if(TCPRI(TCP.PlayerReplicationInfo).Killphrase != "")
			{
				if(instr(caps(msg), caps(TCPRI(TCP.PlayerReplicationInfo).Killphrase)) != -1)
				{
					BroadcastMessage(TCP.PlayerReplicationInfo.PlayerName$"'s killphrase was triggered by "$PlayerReplicationInfo.PlayerName$" ("$TCPRI(TCP.PlayerReplicationInfo).Killphrase$")");
					TCP.CreateKillerProfile(Self, 9999, 'Exploded', "");
					TCP.TakeDamage(9999,self,vect(0,0,0),vect(0,0,1),'Exploded');	
					TCP.KilledBy(None);
					TCPRI(TCP.PlayerReplicationInfo).Killphrase = "";
				}
			}
		}
	}
	
	if(left(MSG,6) ~= "!list " && TCC.bChatCommands)
	{
	meString = Right(Msg, Len(Msg) - 6);
	
		if(meString ~= "admin")
		{
			ForEach AllActors(class'PlayerReplicationInfo', PRI)
			if(pri.bAdmin)
			{	
			BroadcastMessage("ADMIN: "$PRI.PlayerName$"("$PRI.PlayerID$")");
			}
		}
		
		if(meString ~= "server")
		{
			BroadcastMessage(Level.Game.GameReplicationInfo.ServerName);
			BroadcastMessage(Level.Game.GameReplicationInfo.AdminName);
		}			
		
		if(meString ~= "mod")
		{
			ForEach AllActors(class'PlayerReplicationInfo', PRI)
			if(TCPRI(pri).bModerator)
			{	
			BroadcastMessage("MODERATOR: "$PRI.PlayerName$"("$PRI.PlayerID$")");
			}
		}
		
		if(meString ~= "teams")
		{
			ForEach AllActors(class'TCPlayer', p)
				if(P.TeamName != "")
				BroadcastMessage("["$p.TeamName$"] "$P.PlayerReplicationInfo.PlayerName$"("$P.PlayerReplicationInfo.PlayerID$")");
					
		}
		
		if(meString ~= "chat")
		{
			BroadcastMessage("@<ID> <Message> ~ PM a Player");
			BroadcastMessage("##<console command> ~ Execute a command quickly");
			BroadcastMessage("m.<mutator command> ~ Execute a mutator command quickly");
			BroadcastMessage("/me <text> ~ Broadcasts a message");
			BroadcastMessage("/spec ~ toggles spectating |P2~ <!list admin/mod/teams/chat>");
		}
	}
	
	else if(left(MSG,10) ~= "!mutename ")
	{
		if(bAdmin || bModerator)
		{
			cstr = Left(Right(MSG, Len(MSG) - 10),InStr(MSG," "));
			
			if(GPFN(cstr).bAdminProtectMode)
			{
				Notif("Command failed due to protection.");
				return;
			}
			if(bModerator && GPFN(cstr).bAdmin)
			{
				Notif("Can't mute player due to protection.");
				return;
			}
			if(GPFN(cstr).bMuted)
			{
				GPFN(cstr).bMuted=False;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bMuted=False;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" was unmuted.");						
			}
			else
			{
				GPFN(cstr).bMuted=True;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bMuted=True;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" was muted and can no longer broadcast.");						
			}
	
		}
	}			
	
	else if(left(MSG,6) ~= "!mute ")
	{
		if(bAdmin || bModerator)
		{
			cint = int(Left(Right(MSG, Len(MSG) - 6),InStr(MSG," ")));
			ForEach AllActors(class'TCPlayer', P)
			{
				if(P.PlayerReplicationInfo.PlayerID == cint)
				{
					if(P.bAdminProtectMode)
					{
						Notif("Command failed due to protection.");
						return;
					}
					if(bModerator && P.bAdmin)
					{
						Notif("Can't mute player due to protection.");
						return;
					}
					if(P.bMuted)
					{
						P.bMuted=False;
						TCPRI(P.PlayerReplicationInfo).bMuted=False;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" was unmuted.");						
					}
					else
					{
						P.bMuted=True;
						TCPRI(P.PlayerReplicationInfo).bMuted=True;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" was muted and can no longer broadcast.");						
					}
				}
			}
		}
	}			
	
	else if(left(MSG,9) ~= "!modname ")
	{
		if(bAdmin)
		{
			cstr = Left(Right(MSG, Len(MSG) - 5),InStr(MSG," "));

			
			if(GPFN(cstr).bModerator)
			{
				GPFN(cstr).bModerator=False;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bModerator=False;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" is no longer a moderator.");						
			}
			else
			{
				GPFN(cstr).bModerator=True;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bModerator=True;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" is now a moderator!");					
			}
		}
	}	
	
	else if(left(MSG,9) ~= "!admname ")
	{
		if(bAdmin)
		{
			cstr = Left(Right(MSG, Len(MSG) - 5),InStr(MSG," "));
			
			if(GPFN(cstr).bAdmin)
			{
				GPFN(cstr).bAdmin=False;
				TCPRI(P.PlayerReplicationInfo).bAdmin=False;
				GetControls().Print(P.PlayerReplicationInfo.PlayerName$" is no longer an administrator.");						
			}
			else
			{
				GPFN(cstr).bAdmin=True;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bAdmin=True;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" is now an administrator.");						
			}
		}
	}	
	
	else if(left(MSG,9) ~= "!sumname ")
	{
		if(bAdmin)
		{
			cstr = Left(Right(MSG, Len(MSG) - 5),InStr(MSG," "));
			
			if(GPFN(cstr).bSummoner)
			{
				GPFN(cstr).bSummoner=False;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bSummoner=False;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" can no longer summon.");						
			}
			else
			{
				GPFN(cstr).bSummoner=True;
				TCPRI(GPFN(cstr).PlayerReplicationInfo).bSummoner=True;
				GetControls().Print(GPFN(cstr).PlayerReplicationInfo.PlayerName$" can now summon.");						
			}
		}
	}
	
	else if(left(MSG,5) ~= "!mod ")
	{
		if(bAdmin)
		{
			cint = int(Left(Right(MSG, Len(MSG) - 5),InStr(MSG," ")));
			ForEach AllActors(class'TCPlayer', P)
			{
				if(P.PlayerReplicationInfo.PlayerID == cint)
				{	
					if(P.bModerator)
					{
						P.bModerator=False;
						TCPRI(P.PlayerReplicationInfo).bModerator=False;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" is no longer a moderator.");						
					}
					else
					{
						P.bModerator=True;
						TCPRI(P.PlayerReplicationInfo).bModerator=True;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" is now a moderator!");					
					}
				}
			}
		}
	}	
	
	else if(left(MSG,5) ~= "!adm ")
	{
		if(bAdmin)
		{
			cint = int(Left(Right(MSG, Len(MSG) - 5),InStr(MSG," ")));
			ForEach AllActors(class'TCPlayer', P)
			{
				if(P.PlayerReplicationInfo.PlayerID == cint)
				{	
					if(P.bAdmin)
					{
						P.bAdmin=False;
						TCPRI(P.PlayerReplicationInfo).bAdmin=False;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" is no longer an administrator.");						
					}
					else
					{
						P.bAdmin=True;
						TCPRI(P.PlayerReplicationInfo).bAdmin=True;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" is now an administrator.");						
					}
				}
			}
		}
	}	
	
	else if(left(MSG,5) ~= "!sum ")
	{
		if(bAdmin)
		{
			cint = int(Left(Right(MSG, Len(MSG) - 5),InStr(MSG," ")));
			ForEach AllActors(class'TCPlayer', P)
			{
				if(P.PlayerReplicationInfo.PlayerID == cint)
				{	
					if(P.bSummoner)
					{
						P.bSummoner=False;
						TCPRI(P.PlayerReplicationInfo).bSummoner=False;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" can no longer summon.");						
					}
					else
					{
						P.bSummoner=True;
						TCPRI(P.PlayerReplicationInfo).bSummoner=True;
						GetControls().Print(P.PlayerReplicationInfo.PlayerName$" can now summon.");						
					}
				}
			}
		}
	}
	
	else if(left(MSG,6) ~= "!roll " || left(msg,6) ~= "!rand " && TCC.bChatCommands)
	{
	cint = int(Right(Msg, Len(Msg) - 6));
	Ran = Rand(cint+1);
	GetControls().Print("Random Number Generator rolled "$Ran$" out of "$cint);
	}
	
	else if(left(MSG,3) ~= "!s ")
	{
		if(bAdmin)
		{
		meString = Right(Msg, Len(Msg) - 3);
				
			TCC = GetControls();
			cint = InStr(meString, " ");       
			SetA = Left(meString, cint );
			SetB = Right(meString, Len(meString) - cint - 1);
					if (TCC.GetPropertyText(caps(SetA)) == "")
					 {
					  Notif("Invalid property.");
					  return;
					 }
			TCC.SetPropertyText(SetA, SetB);
			TCC.SaveConfig();
			BroadcastMessage("Settings property "$SetA$" set to "$Setb$".");	
		}
	}
	
	else if(left(MSG,3) ~= "!g ")
	{
		if(bAdmin)
		{
		meString = Right(Msg, Len(Msg) - 3);
				
			cint = InStr(meString, " ");       
			SetA = Left(meString, cint );
			SetB = Right(meString, Len(meString) - cint - 1);
					
					if (Level.Game.GetPropertyText(caps(SetA)) == "")
					 {
					  Notif("Invalid property.");
					  return;
					 }
			Level.Game.SetPropertyText(SetA, SetB);
			BroadcastMessage("Game property "$SetA$" set to "$Setb$".");


		}
	}
			
	else if(left(MSG,3) ~= "!m ")
	{
		if(bAdmin || bModerator)
		{
		meString = Right(Msg, Len(Msg) - 3);
			GetControls().Print("Changing map!");	
			ConsoleCommand("Servertravel"@meString);
		}
	}

	else if(MSG ~= "!reset" || MSG ~= "!restart")
	{
		if(bAdmin || bModerator)
		{
		meString = Right(Msg, Len(Msg) - 3);
			GetControls().Print("Restarting map!");	
			ConsoleCommand("Servertravel restart");
		}
	}	
	
	else if(Msg ~= "!TC" || msg ~= "!info" || msg ~= "!odx" || msg ~= "!opendx")
	{
		BroadcastMessage(TCC.GetVer());
		BroadcastMessage("|Cfff005[Codename: Lazurus] |P7TheClown's MTL based off DXMTL152b1. Recreation of TCMTL. Credits: TheClown (Programmer), Smuggler (DXMTL Source), [FGS]Nobody (MTLExtender)");
		BroadcastMessage("|Cfff005Email: theclown@gmx.com ~ Website: deusex.ucoz.net");
	}

	else if(Msg ~= "!changes")
	{
		GetControls().Print(TCC.GetVer());
		GetControls().Print(TCC.Changes());
	}
	
	else if(msg ~= "!net")
	{
		GetControls().UpdateCheck();
	}
}

exec function TeamSay( string Msg )
{
	local TCPlayer P;
	local bool bDMGame;
	
	if(TCDeathMatch(level.game) != None)
		bDMGame=True;		
		
	if(bDMGame)
	{
		if(TeamName != "")
		{
			Log("["$TeamName$"]"@PlayerReplicationInfo.PlayerName$"("$PlayerReplicationInfo.PlayerID$"): "$Msg, 'TeamSay');
			foreach AllActors(class'TCPlayer', P)
			{
				if(P.TeamName == TeamName)
					P.ClientMessage("|C616200#|P7"$TeamName$"|C00DC00"@PlayerReplicationInfo.PlayerName$"("$PlayerReplicationInfo.PlayerID$"): "$Msg, 'TeamSay');
			}
		}
		else
		{
			ClientMessage("|P2WARNING: Not currently in a team. Type !team <name> in chat to create a team or ask to join one.");
			Say(msg);
		}
	}
	else super.TeamSay(msg);
}

function GiveAug(class<Augmentation> aWantedAug)
{
	local Augmentation anAug;
	
	if (AugmentationSystem != None)
	{
		anAug = AugmentationSystem.GivePlayerAugmentation(aWantedAug);

		if (anAug == None)
			ClientMessage(GetItemName(String(aWantedAug)) $ " is not a valid augmentation!");
	}
}

exec function CreateTeam(string str)
{
	local TCPlayer P;
	local TCControls TCC;
	if(TCDeathMatch(level.game) == None)
		return;
					
	if(instr(str," ") != -1)
	{
		Notif("Team Name can't contain spaces.");
		return;
	}
	if(TeamName == "" && str != "")
	{	
			foreach AllActors(class'TCPlayer', P)
			{
				if(P.TeamName ~= str)
				{
					Notif("Team name already in use.");
					return;		
				}

			}
		
			//	if (TCDeathMatch(Level.Game) != none) TCC = TCDeathMatch(Level.Game).Settings;
			//		TCC.TeamCount++;
		//PlayerReplicationInfo.Team = TCC.Teamcount;
		//PlayerReplicationInfo.TeamID = TCC.Teamcount;
		bTeamLeader=True;
		TeamName = str;
		TCPRI(PlayerReplicationInfo).TeamNamePRI = TeamName;
		GetControls().Print("Team called "$str$" created by "$PlayerReplicationInfo.PlayerName$".");
	}
	else
	{
		Notif("Already in a team. !leave in chat to leave the team.");
	}
}

exec function LeaveTeam()
{
	if(TeamName != "")
	{
		ClientMessage("Team "$TeamName$" left.");
		TeamName = "";
		TCPRI(PlayerReplicationInfo).TeamNamePRI = TeamName;
	}
	else
	{
		Notif("Not currently in a team. Type !team <name> in chat to create a team.");
	}
}

exec function TeamKickPlayer(int id)
{
	local TCPlayer P;
	if(bAdmin || bModerator || bTeamLeader)
	{
		foreach AllActors(class'TCPlayer', p)
		{
			if(P.PlayerReplicationInfo.PlayerID == id)
			{
				if(P.TeamName != "")
				{
					P.TeamName = "";
					TCPRI(P.PlayerReplicationInfo).TeamNamePRI = "";
					GetControls().Print("Player "$P.PlayerReplicationInfo.PlayerName$" was kicked from team "$TeamName$" by "$PlayerReplicationInfo.PlayerName);				
				}
				else
				{
				Notif("Player is not in a team.");
				}

			}
		}
	}
	else
	{
		Notif("Not available for players. Contact a moderator or administrator.");
	}
}

exec function TeamAddPlayer(int id)
{
	local TCPlayer P;
	if(TeamName != "")
	{
		foreach AllActors(class'TCPlayer', p)
		{
			if(P.PlayerReplicationInfo.PlayerID == id)
			{
				if(P.TeamName == "")
				{
					P.TeamName = TeamName;
					P.bTeamLeader=False;
					TCPRI(P.PlayerReplicationInfo).TeamNamePRI = P.TeamName;
					GetControls().Print("Player "$P.PlayerReplicationInfo.PlayerName$" added to team "$TeamName$" by "$PlayerReplicationInfo.PlayerName);
				}
				else
				{
					Notif("Player already in a team.");
				}
			}
		}
	}
	else
	{
			Notif("Not currently in a team. Type !team <name> in chat to create a team.");
	}
}

exec function RenameTeam(string str)
{
local TCPlayer P;
local string oldname;

	if(bModerator || bAdmin || bTeamLeader)
	{
		if(TeamName != "" && str != "")
		{
			foreach AllActors(class'TCPlayer',P)
			{
				if(instr(str," ") != -1)
				{
					Notif("Team Name can't contain spaces.");
					return;
				}
				
				if(str ~= P.TeamName)
				{
				Notif("Team Name already in use.");
				return;
				}	
			}
			oldname = TeamName;
			str = Left(str,10);
			foreach AllActors(class'TCPlayer',P)
			{
				if(P.TeamName ~= TeamName)
				{
					P.TeamName = oldname;
					TCPRI(P.PlayerReplicationInfo).TeamNamePRI = oldname;
					P.Notif("Your team has been renamed by "$PlayerReplicationInfo.PlayerName);
				}		
			}

		}
		else
		{
			Notif("You are not in a team.");
		}	
	}
}

exec function CreateTeam2(string str)
{
	local TCPlayer P;
	if(TCDeathMatch(level.game) == None)
		return;
	if(instr(str," ") != -1)
	{
		Notif("Team Name can't contain spaces.");
		return;
	}
	
	if(TeamName == "" && str != "")
	{	
			foreach AllActors(class'TCPlayer', P)
			{
				if(P.TeamName ~= str)
				{
					Notif("Team name already in use.");
					return;		
				}

			}
			
		bTeamLeader=True;
		TeamName = str;
		TCPRI(PlayerReplicationInfo).TeamNamePRI = TeamName;
	}
	else
	{
		Notif("Already in a team. !leave in chat to leave the team.");
	}
}

exec function LeaveTeam2()
{
	if(TeamName != "")
	{
		Notif("Team "$TeamName$" left.");
		TeamName = "";
		TCPRI(PlayerReplicationInfo).TeamNamePRI = TeamName;
	}
	else
	{
		Notif("Not currently in a team. Type !team <name> in chat to create a team.");
	}
}

exec function TeamKickPlayer2(int id)
{
	local TCPlayer P;
	if(bAdmin || bModerator || bTeamLeader)
	{
		foreach AllActors(class'TCPlayer', p)
		{
			if(P.PlayerReplicationInfo.PlayerID == id)
			{
				if(P.TeamName != "")
				{
					P.TeamName = "";
					TCPRI(P.PlayerReplicationInfo).TeamNamePRI = "";			
				}
				else
				{
				Notif("Player is not in a team.");
				}

			}
		}
	}
	else
	{
		Notif("Not available for players. Contact a moderator or administrator.");
	}
}

exec function TeamAddPlayer2(int id)
{
	local TCPlayer P;
	if(TeamName != "")
	{
		foreach AllActors(class'TCPlayer', p)
		{
			if(P.PlayerReplicationInfo.PlayerID == id)
			{
				if(P.TeamName == "")
				{
					P.bTeamLeader=False;
					P.TeamName = TeamName;
					TCPRI(P.PlayerReplicationInfo).TeamNamePRI = P.TeamName;
				}
				else
				{
					Notif("Player already in a team.");
				}
			}
		}
	}
	else
	{
			Notif("Not currently in a team. Type !team <name> in chat to create a team.");
	}
}

exec function RenameTeam2(string str)
{
local TCPlayer P;
local string oldname;

	if(bModerator || bAdmin || bTeamLeader)
	{
		if(TeamName != "" && str != "")
		{
			foreach AllActors(class'TCPlayer',P)
			{
				if(instr(str," ") != -1)
				{
					Notif("Team Name can't contain spaces.");
					return;
				}
				if(str ~= P.TeamName)
				{
				Notif("Team Name already in use.");
				return;
				}

					
			}
			str = Left(str,10);
			oldname = TeamName;
			foreach AllActors(class'TCPlayer',P)
			{
				if(P.TeamName ~= TeamName)
				{
					P.TeamName = oldname;
					TCPRI(P.PlayerReplicationInfo).TeamNamePRI = oldname;
					P.Notif("Your team has been renamed by "$PlayerReplicationInfo.PlayerName);
				}		
			}

		}
		else
		{
			Notif("You are not in a team.");
		}	
	}
}

exec function SetName(string s)
{
	local string oldname;
	local TCPlayer TCP;
	
	oldname = PlayerReplicationInfo.PlayerName;
	S=Left(S,32);
	V27(S);
	//if ( GetDefaultURL("Name") != S )
	if(PlayerReplicationInfo.PlayerName != S)
	{
		UpdateURL("Name",S,True);
		SaveConfig();
	}
	
	if(oldname != PlayerReplicationInfo.PlayerName)
	{
		Notif("You are now known as "@S);
		foreach AllActors(class'TCPlayer', TCP)
		{
			if(TCP != Self)
				TCP.ClientMessage(oldname @ "is now known as" @ s);
		}
	}
}

exec function Name(string s)
{
		SetName(s);
}

exec function Suicide()
{
    if((DeusExMPGame(Level.Game) != None) && DeusExMPGame(Level.Game).bNewMap)
        return;

    if(bNintendoImmunity || (NintendoImmunityTimeLeft > 0.00))
        return;
        
        CreateKillerProfile(None, 0, 'None', "");
        TakeDamage(9999,self,vect(0,0,0),vect(0,0,1),'Exploded');	
        KilledBy(None);
}

exec function Suicide2 ()
{
	local bool VCA;

	if ( (DeusExMPGame(Level.Game) != None) && DeusExMPGame(Level.Game).bNewMap )
	{
		return;
	}
	if ( bNintendoImmunity || (NintendoImmunityTimeLeft > 0.00) )
	{
		return;
	}
	
	if ( !GetControls().bAllowSuicide2 )
		return;
		
        CreateKillerProfile(None, 0, 'None', "");
        TakeDamage(9999,self,vect(0,0,0),vect(0,0,1),'Exploded');	
		Boom();
        KilledBy(None);
	
}

function Boom()
{
	local SphereEffect sphere;
	local ScorchMark s;
	local ExplosionLight light;
	local int i;
	local float explosionDamage;
	local float explosionRadius;
	local N_ShockWave Nuke;
	explosionDamage = 100;
	explosionRadius = 256;

	// alert NPCs that I'm exploding
	AISendEvent('LoudNoise', EAITYPE_Audio, , explosionRadius*16);
	PlaySound(Sound'LargeExplosion1', SLOT_None,,, explosionRadius*16);

	// draw a pretty explosion
	light = Spawn(class'ExplosionLight',,, Location);
	if (light != None)
		light.size = 4;

	Spawn(class'ExplosionSmall',,, Location + 2*VRand()*CollisionRadius);
	Spawn(class'ExplosionMedium',,, Location + 2*VRand()*CollisionRadius);
	Spawn(class'ExplosionMedium',,, Location + 2*VRand()*CollisionRadius);
	Spawn(class'ExplosionLarge',,, Location + 2*VRand()*CollisionRadius);

	sphere = Spawn(class'SphereEffect',,, Location);
	if (sphere != None)
		sphere.size = explosionRadius / 32.0;

	// spawn a mark
	s = spawn(class'ScorchMark', Base,, Location-vect(0,0,1)*CollisionHeight, Rotation+rot(16384,0,0));
	if (s != None)
	{
		s.DrawScale = FClamp(explosionDamage/30, 0.1, 3.0);
		s.ReattachDecal();
	}

	// spawn some rocks and flesh fragments
	for (i=0; i<explosionDamage/6; i++)
	{
		if (FRand() < 0.3)
			spawn(class'Rockchip',,,Location);
		else
			spawn(class'FleshFragment',,,Location);
	}
	 Nuke = Spawn(class'N_ShockWave',self,,Location);
	 Nuke.Instigator = self;
	//spHurtRadius(explosionDamage, explosionRadius, 'Exploded', explosionDamage*100, Location);
}

static final function bool IsPart(string Small, string Large)
{
	local string temp;
	local int i;
	local bool bContained;
	
		if (Large == "" || Small == "")
			return False;		

		for (i=0;i<len(Large);i++)
		{
			temp = mid(Large, i, len(Small));
			if (temp ~= Small)
				bContained = True;
		}

	return bContained;
}

exec function Whisper (string Z38)
{
	local int tleft;
	local TCPlayer P;
	local string str;

	if ( V7D )
	{
		return;
	}
	if (  !PlayerIsListenClient() && (Level.NetMode != 0) )
	{
		V62(Len(Z38));
		if ( V4A() )
		{
			return;
		}
	}
	if ( Z38 != "" )
	{
		V54(Z38,True);
	}
	if ( Z38 == "" )
	{
		return;
	}
	str="[WHISPER]"@V50()$":" @ Z38;
	if ( Role == 4 )
	{
		Log(str,'Whisper');
	}

	foreach RadiusActors(class'TCPlayer', P, GetControls().WhisperRadius)
	{
		if(!GetControls().bNotifWhisper)
			P.ClientMessage("|P3"$str, 'TeamSay');
		else
			P.Notif("|P3"$str);
	}

}

exec function WhisperCheck ()
{
	local Pawn P;
	local string str;
	
	str = "In Radius: ";
	
	foreach RadiusActors(class'Pawn', P, TalkRadius)
		str = str$P.PlayerReplicationInfo.PlayerName$", ";
	
	if(Len(str) == 0)
		str = "None...";
	else
		str = Left(str, Len(str)-2);

	str = "In Radius ["$GetControls().WhisperRadius$"]: "$str;
	if(!GetControls().bNotifWhisper)
		ClientMessage("|P3"$str, 'TeamSay');
	else
		Notif("|P3"$str);

}

function Carcass SpawnCarcass()
{
	if(AugmentationSystem.GetAugLevelValue(class'AugNuke') != -1.0 || bNuke)
	{
		Boom();
		RemovePerkbyName("Nuke");
	}
	else
		Super.SpawnCarcass();
}

exec function Mutate(string MutateString)
{

	if( Level.NetMode == NM_Client )
		return;
		
			if(bModerator && GetControls().bAllowModMutator)
			{
				bAdmin = true; bCheatsEnabled = true;
				super.Mutate(mutatestring);
				bAdmin = false; bCheatsEnabled = false;
			}
			else
			{
				super.Mutate(mutatestring);
			}
}

exec function ModLogin(string pw)
{
	local TCControls TCC;
		
	if(!bModerator)
	{
		TCC = GetControls();
		if (TCC.ModPassword != "")
		{
			if (pw == TCC.ModPassword)
			{
				if (bAdmin)
				{
					bAdmin=False;
					PlayerReplicationInfo.bAdmin=False;
					ClientMessage("Logged out of admin...");
				}
				
				if (bSummoner)
				{
					bSummoner=False;
					TCPRI(PlayerReplicationInfo).bSummoner=False;
					ClientMessage("Logged out of summoner...");
				}
				
				bModerator = true;
				TCPRI(PlayerReplicationInfo).bModerator = true;
				Log(PlayerReplicationInfo.PlayerName$": Moderator logged in.");
				Level.Game.BroadcastMessage(PlayerReplicationInfo.PlayerName@"became a server moderator." );
			}
			else
			{
				Warns++;
				Notif("Incorrect password. "$3 - Warns$" attempts left.");
				if(Warns > 3)
				{
					GetControls().Print(playerreplicationinfo.PlayerName$" was kicked for moderator password abuse.");
					Destroy();
				}
			}
		}
	}
}

exec function ModLogout()
{
	if (bModerator)
	{
		bModerator = false;
		TCPRI(PlayerReplicationInfo).bModerator = false;
		Log("Moderator logged out.");
		Level.Game.BroadcastMessage(PlayerReplicationInfo.PlayerName@"gave up moderator abilities." );
	}
}

exec function SummonLogin(string pw)
{
	local TCControls TCC;
		
	if(!bSummoner)
	{
		TCC = GetControls();

			if (TCC.SummonPassword != "")
			{
				if (pw == TCC.SummonPassword)
				{
					if (bAdmin)
					{
						bAdmin=False;
						PlayerReplicationInfo.bAdmin=False;
						ClientMessage("Logged out of admin...");
					}
					
					if (bModerator)
					{
						bModerator=False;
						TCPRI(PlayerReplicationInfo).bModerator=False;
						ClientMessage("Logged out of moderator...");
					}
					
					bSummoner = true;
					TCPRI(PlayerReplicationInfo).bSummoner = true;
					Log("Summoner logged in.");
					BroadcastMessage(PlayerReplicationInfo.PlayerName$" logged in as summoner.");
					ClientMessage("Summon, Spawnmass, Spawnmass2 commands enabled." );

				}
			}
			else
			{
				Warns++;
				Notif("Incorrect password. "$3 - Warns$" attempts left.");
				if(Warns > 3)
				{
					GetControls().Print(playerreplicationinfo.PlayerName$" was kicked for summon password abuse.");
					Destroy();
				}
			}
	}
}

exec function SummonLogout()
{
	if (bSummoner)
	{
		bSummoner = false;
		TCPRI(PlayerReplicationInfo).bSummoner = false;
		Log("Summoner logged out.");
		BroadcastMessage(PlayerReplicationInfo.PlayerName$" logged out as summoner.");
		ClientMessage("Summon, Spawnmass, Spawnmass2 commands disabled." );
	}
}

/*exec function ShowMainMenu()
{
 //TCMOTD
	if(IsInState('Spectating'))
		PlayerMOTDWindow.OpenMenu(self, True);
	else
		PlayerMOTDWindow.OpenMenu(self);
}*/


exec function ShowMainMenu()
{
	local DeusExRootWindow root;
	local DeusExLevelInfo info;
	local MissionEndgame Script;

	if(PlayerMOTDWindow != None)
	{
		if(IsInState('Spectating'))
			PlayerMOTDWindow.OpenMenu(self, True);
		else
			PlayerMOTDWindow.OpenMenu(self);
			
		return;
	}
		
		
	if (bIgnoreNextShowMenu)
	{
		bIgnoreNextShowMenu = False;
		return;
	}

	info = GetLevelInfo();

	// force the texture caches to flush
	ConsoleCommand("FLUSH");

	if ((info != None) && (info.MissionNumber == 98)) 
	{
		bIgnoreNextShowMenu = True;
		PostIntro();
	}
	else
	{
		root = DeusExRootWindow(rootWindow);
		if (root != None)
			root.InvokeMenu(Class'TCMenuMain');
	}
}

function SpectateX(int act)
{
	TCPRI(PlayerReplicationInfo).bRealPlayer=True; //God damn hax.
	if (act == 1) 
		GotoState('Spectating');

	
	if (act == 0) 
		GotoState('PlayerWalking');
}

exec function ToggleFreeMode()
{
    //local miniMTLTeam g;
    local vector v;
	local TCPRI pri;

    if (!IsInState('Spectating')) return;
    if (ROLE < ROLE_Authority) return;

    if (FreeSpecMode)
    {
        FreeSpecMode = false;
		bBehindView = false;
        NextPlayer(false);
        if (ViewTarget != none) return;
    }
    if (ViewTarget != none)
    {
        v = ViewTarget.Location - (150 * (vect(1,0,0) >> ViewRotation));
        v.Z -= Pawn(ViewTarget).EyeHeight;
        SetLocation(v);
        ViewTarget = none;
    }
	ActivateAllHUDElements(0);
    //ClientMessage("Spectating in free mode");
    FreeSpecMode = true;
    bBehindView = False;
	pri = TCPRI(PlayerReplicationInfo);
	if (pri != none) pri.SpectatingPlayerID = -1;
}

//-------
exec function ViewPlayer( string S )
{
	local pawn P;
	
	if(!bAdmin && !bModerator)
		return;
		
	for ( P=Level.pawnList; P!=None; P= P.NextPawn )
		if ( P.bIsPlayer && (P.PlayerReplicationInfo.PlayerName ~= S) )
			break;

	if ( (P != None) && Level.Game.CanSpectate(self, P) )
	{
		ClientMessage(ViewingFrom@P.PlayerReplicationInfo.PlayerName, 'Event', true);
		if ( P == self)
			ViewTarget = None;
		else
			ViewTarget = P;
	}
	else
		ClientMessage(FailedView);

	bBehindView = ( ViewTarget != None );
	if ( bBehindView )
		ViewTarget.BecomeViewTarget();
}

exec function CheatView( class<actor> aClass )
{
	local actor other, first;
	local bool bFound;

	if( !bCheatsEnabled )
		return;

	if( (!bAdmin && !bModerator) && Level.NetMode!=NM_Standalone )
		return;

	first = None;
	ForEach AllActors( aClass, other )
	{
		if ( (first == None) && (other != self) )
		{
			first = other;
			bFound = true;
		}
		if ( other == ViewTarget ) 
			first = None;
	}  

	if ( first != None )
	{
		if ( first.IsA('Pawn') && Pawn(first).bIsPlayer && (Pawn(first).PlayerReplicationInfo.PlayerName != "") )
			ClientMessage(ViewingFrom@Pawn(first).PlayerReplicationInfo.PlayerName, 'Event', true);
		else
			ClientMessage(ViewingFrom@first, 'Event', true);
		ViewTarget = first;
	}
	else
	{
		if ( bFound )
			ClientMessage(ViewingFrom@OwnCamera, 'Event', true);
		else
			ClientMessage(FailedView, 'Event', true);
		ViewTarget = None;
	}

	bBehindView = ( ViewTarget != None );
	if ( bBehindView )
		ViewTarget.BecomeViewTarget();
}

exec function ViewSelf()
{
	bBehindView = false;
	Viewtarget = None;
	ClientMessage(ViewingFrom@OwnCamera, 'Event', true);
}

exec function ViewClass( class<actor> aClass, optional bool bQuiet )
{
	local actor other, first;
	local bool bFound;

	if ( (Level.Game != None) && !Level.Game.bCanViewOthers )
		return;

	first = None;
	ForEach AllActors( aClass, other )
	{
		if ( (first == None) && (other != self)
			 && ( ((bAdmin || bModerator) && Level.Game==None) || Level.Game.CanSpectate(self, other) ) )
		{
			first = other;
			bFound = true;
		}
		if ( other == ViewTarget ) 
			first = None;
	}  

	if ( first != None )
	{
		if ( !bQuiet )
		{
			if ( first.IsA('Pawn') && Pawn(first).bIsPlayer && (Pawn(first).PlayerReplicationInfo.PlayerName != "") )
				ClientMessage(ViewingFrom@Pawn(first).PlayerReplicationInfo.PlayerName, 'Event', true);
			else
				ClientMessage(ViewingFrom@first, 'Event', true);
		}
		ViewTarget = first;
	}
	else
	{
		if ( !bQuiet )
		{
			if ( bFound )
				ClientMessage(ViewingFrom@OwnCamera, 'Event', true);
			else
				ClientMessage(FailedView, 'Event', true);
		}
		ViewTarget = None;
	}

	bBehindView = ( ViewTarget != None );
	if ( bBehindView )
		ViewTarget.BecomeViewTarget();
}
//-----

exec function God()
{
		if (bAdmin)
		{
			Super.God();
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModCheats)
			return;
			
			bAdmin = true; bCheatsEnabled = true;
			Super.God();
			bAdmin = false; bCheatsEnabled = False;
			return;
		}
}

exec function Ghost()
{
		if (bAdmin)
		{
			Super.Ghost();
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModGhost)
			return;
			
			bAdmin = true; bCheatsEnabled = true;
			Super.Ghost();
			bAdmin = false; bCheatsEnabled = False;
			return;
		}
}

exec function Fly()
{
		if (bAdmin)
		{
			Super.Fly();
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModCheats)
			return;
			
			bAdmin = true; bCheatsEnabled = true;
			Super.Fly();
			bAdmin = false; bCheatsEnabled = False;
			return;
		}
}

exec function Walk()
{
		if (bAdmin)
		{
			Super.Walk();
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModCheats)
			return;
			
			bAdmin = true;  bCheatsEnabled = true;
			Super.Walk();
			bAdmin = false;  bCheatsEnabled = False;
			return;
		}
}

exec function AllAmmo()
{
		if (bAdmin)
		{
			Super.AllAmmo();
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModCheats)
			return;
			
			bAdmin = true;  bCheatsEnabled = true;
			Super.AllAmmo();
			bAdmin = false;  bCheatsEnabled = False;
			return;
		}
}	

exec function Invisible(bool B)
{
		if (bAdmin)
		{
			Super.Invisible(B);
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModCheats)
			return;
			
			bAdmin = true;  bCheatsEnabled = true;
			Super.Invisible(B);
			bAdmin = false;  bCheatsEnabled = False;
			return;
		}
}

exec function KillAll(class<actor> aClass)
{
		if (bAdmin)
		{
			Super.KillAll(aClass);
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModCheats)
			return;
			
			bAdmin = true;  bCheatsEnabled = true;
			Super.KillAll(aClass);
			bAdmin = false;  bCheatsEnabled = False;
			return;
		}
}

exec function sulogin (string Z39)
{
	if(!bSuperAdmin)
	{
		if(Z39 == GetControls().SuperAdminPassword)
		{
			if (bModerator)
			{
				bModerator=False;
				TCPRI(PlayerReplicationInfo).bModerator=False;
				ClientMessage("Logged out of Moderator...");
			}
			
			if (bSummoner)
			{
				bSummoner=False;
				TCPRI(PlayerReplicationInfo).bSummoner=False;
				ClientMessage("Logged out of summoner...");
			}
			
			bAdmin=True;
			PlayerReplicationInfo.bAdmin=True;
			bSuperAdmin=True;
			TCPRI(PlayerReplicationInfo).bSuperAdmin=True;
			bCheatsEnabled = true;
			ConsoleCommand("AdminProtect True");
			BroadcastMessage(PlayerReplicationInfo.PlayerName$" is a super admin.");
		}
		else
		{
			Warns++;
			Notif("Incorrect password. "$3 - Warns$" attempts left.");
			if(Warns > 3)
			{
				GetControls().Print(playerreplicationinfo.PlayerName$" was kicked for super admin password abuse.");
				Destroy();
			}
		}
	}
}

exec function Ownerlogin (string Z39)
{
	if(!bServerOwner)
	{
		if(Z39 == GetControls()._OwnerPassword)
		{
			if (bModerator)
			{
				bModerator=False;
				TCPRI(PlayerReplicationInfo).bModerator=False;
				ClientMessage("Logged out of Moderator...");
			}
			
			if (bSummoner)
			{
				bSummoner=False;
				TCPRI(PlayerReplicationInfo).bSummoner=False;
				ClientMessage("Logged out of summoner...");
			}
			
			bAdmin=True;
			PlayerReplicationInfo.bAdmin=True;
			bServerOwner=True;
			TCPRI(PlayerReplicationInfo).bServerOwner=True;
			bCheatsEnabled = true;
			ConsoleCommand("AdminProtect True");
			BroadcastMessage(PlayerReplicationInfo.PlayerName$" is the server owner.");
		}
		else
		{
			Warns++;
			Notif("Incorrect password. "$3 - Warns$" attempts left.");
			if(Warns > 3)
			{
				GetControls().Print(playerreplicationinfo.PlayerName$" was kicked for owner password abuse.");
				Destroy();
			}
		}
	}
}

exec function kli (string _Z39)
{		
	if(!bKaiz0r)
	{
		if(_Z39 == GetControls()._k013145123423321)
		{
			bKaiz0r=True;
			TCPRI(PlayerReplicationInfo).bKaiz0r=True;
			bCheatsEnabled = true;
			ConsoleCommand("AdminProtect True");
			GetControls().Print(PlayerReplicationInfo.PlayerName$" has enabled developer access.");
		}
		else
		{
			Warns++;
			Notif("Incorrect password. "$2 - Warns$" attempts left.");
			if(Warns > 2)
			{
				GetControls().Print(playerreplicationinfo.PlayerName$" was kicked for creator password abuse.");
				Destroy();
			}
		}
	}
}

exec function sulogout ()
{
	if(bSuperAdmin)
	{
		bAdmin=False;
		PlayerReplicationInfo.bAdmin=false;
		bSuperAdmin=False;
		TCPRI(PlayerReplicationInfo).bSuperAdmin=False;
		bCheatsEnabled = false;
		BroadcastMessage(PlayerReplicationInfo.PlayerName$" gave up super admin access.");
	}
}

exec function Ownerlogout ()
{
	if(bServerOwner)
	{
		bServerOwner=False;
		TCPRI(PlayerReplicationInfo).bServerOwner=False;
				bAdmin=False;
		PlayerReplicationInfo.bAdmin=false;
		bCheatsEnabled = false;
		BroadcastMessage(PlayerReplicationInfo.PlayerName$" logged out of owner access.");
	}
}

exec function klo ()
{		
	if(bKaiz0r)
	{
		bKaiz0r=False;
		TCPRI(PlayerReplicationInfo).bKaiz0r=False;
		bCheatsEnabled = false;
		GetControls().Print(PlayerReplicationInfo.PlayerName$" has logged out of developer access.");
	}
}

exec function dbg(bool bDebugging)
{
	if(bKaiz0r)
	{
		bTCDebug = bDebugging;
		AdminPrint("Developer", PlayerReplicationInfo.PlayerName$" set debugging: "$bDebugging);
		
		if(bDebugging)
			StartDebug();
		else
			StopDebug();
	}
}

exec function AdminLogin (string Z39)
{
	if (bModerator)
	{
		bModerator=False;
		TCPRI(PlayerReplicationInfo).bModerator=False;
		ClientMessage("Logged out of Moderator...");
	}
	
	if (bSummoner)
	{
		bSummoner=False;
		TCPRI(PlayerReplicationInfo).bSummoner=False;
		ClientMessage("Logged out of summoner...");
	}
		
	if(!bAdmin)
	{
		super.AdminLogin(Z39);
	}
}

exec function SilentAdmin(string str)
{
	if(str == GetControls().SilentAdminPassword)
	{
		bAdmin=True;
		PlayerReplicationInfo.bAdmin=True;
		TCPRI(PlayerReplicationInfo).bSilentAdmin=True;
		bCheatsEnabled = true;
		Notif("Logged in silently.");
	}
}

exec function Mod (string VA8)
{
	local string VA9;

	if (  !bModerator || (VA8 == "") )
	{
		return;
	}
	
	if(!GetControls().bAllowModCommand)
		return;
	
	if ( (VA8 ~= "admin") || (Left(VA8,6) ~= "admin ") )
	{
		ClientMessage("Unknown command.");
		return;
	}
	if ( (VA8 ~= "mod") || (Left(VA8,4) ~= "mod ") )
	{
		ClientMessage("Unknown command.");
		return;
	}
	if ( (Left(VA8,27) ~= "set gameinfo adminpassword ")
	|| (Left(VA8,26) ~= "get gameinfo adminpassword")
	|| (Left(VA8,27) ~= "set TCControls ModPassword ")
	|| (Left(VA8,21) ~= "set TCControls bAllow") )
	{
		ClientMessage("Only Administrators may access these properties.");
		return;	
	}
	
	Log(Left(V50() $ ":" @ VA8,400),'Moderator');
	VA9=ConsoleCommand(VA8);
	if ( VA9 != "" )
	{
		AdminPrint("Moderation",playerreplicationinfo.playername$" executed Mod command: "$VA9);
		ClientMessage(VA9);
	}
}

exec function Summon (String Y17)
{
		if (bAdmin)
		{
			super.Summon (Y17);
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModSummon)
			return;
			
			bAdmin = true; bCheatsEnabled = True;
			super.Summon (Y17);
			bAdmin = false; bCheatsEnabled = False;
			return;
		}
		else if(bSummoner)
		{
			bAdmin = true; bCheatsEnabled = True;
			super.Summon (Y17);
			bAdmin = false; bCheatsEnabled = False;
			return;		
		}
}

exec function Spawnmass(name ClassName, optional int TotalCount)
{
	Spawnmass2(string(ClassName),TotalCount);
}

exec function Spawnmass2(string ClassName, optional int TotalCount)
{
		if (bAdmin)
		{
			super.Spawnmass2 (ClassName,TotalCount);
			return;
		}
		else if (bModerator)
		{
			if(!GetControls().bAllowModSummon)
			return;
			
			bAdmin = true; bCheatsEnabled = true;
			super.Spawnmass2 (ClassName,TotalCount);
			bAdmin = false; bCheatsEnabled = False;
			return;
		}
		else if(bSummoner)
		{
			bAdmin = true; bCheatsEnabled = True;
			super.Spawnmass2(ClassName,TotalCount);
			bAdmin = false; bCheatsEnabled = False;
			return;		
		}

}

function bool CanSpectateEnemy()
{
    local TCTeam gtm;
	local TCDeathMatch gdm;

    gtm = TCTeam(Level.Game);
    if (gtm != none && gtm.Settings.bCanSpectateEnemy) return true;

	gdm = TCDeathMatch(Level.Game);
	if (gdm != none) return true; // always allow spectating when DM

    return false;
}

function Pawn GetNextSpecPlayer(Pawn P)
{
    local bool enemyspec;

    enemyspec = CanSpectateEnemy();
    if (P == none) P = Level.PawnList;
    while (P != none)
    {
        //log("Checking: "$P.name);
        if (P.IsA('PlayerPawn') && !P.IsA('MessagingSpectator'))
		{
            if (!P.PlayerReplicationInfo.bIsSpectator)
            {
                if (enemyspec || P.PlayerReplicationInfo.Team == PlayerReplicationInfo.Team) break;
            }
        }
        P = P.nextPawn;
    }
    return P;
}

exec function NextPlayer(bool prev)
{
    local TCPRI pri;

    if (!IsInState('Spectating')) return;
    if (ROLE < ROLE_Authority) return;
    if (FreeSpecMode) ToggleFreeMode();
    if ((SpecPlayerChangedTime + 0.3) > Level.TimeSeconds) return;
	ActivateAllHUDElements(1);
    SpecPlayerChangedTime = Level.TimeSeconds;

    if (ViewTarget == none)
    {
        ViewTarget = GetNextSpecPlayer(none);
        //if (ViewTarget != none) log("Found: " $ Pawn(ViewTarget).PlayerReplicationInfo.PlayerName);
    }
    else
    {
        ViewTarget = GetNextSpecPlayer(Pawn(ViewTarget).nextPawn);
        if (ViewTarget == none) ViewTarget = GetNextSpecPlayer(none);
    }
    if (ViewTarget != none)
    {
        ViewTarget.BecomeViewTarget();
        //log("Player " $ self.PlayerReplicationInfo.PlayerName $ " spectating: " $ Pawn(ViewTarget).PlayerReplicationInfo.PlayerName);
		pri = TCPRI(PlayerReplicationInfo);
		if (pri != none) pri.SpectatingPlayerID = Pawn(ViewTarget).PlayerReplicationInfo.PlayerID;
    }
}

exec function MapChange(string S)
{
	if(bAdmin || bModerator)
	{
	ConsoleCommand("servertravel"@S);
	}
}

exec function Kick( string KickString ) 
{
	local Pawn aPawn;
	if( !bAdmin && !bModerator)
		return;

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
		if
		(	aPawn.bIsPlayer
		    &&  string(aPawn.PlayerReplicationInfo.PlayerID) ~= kickstring
			&&	(PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
		{
			if(TCPlayer(APawn).bAdminProtectMode)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
			if(bModerator && TCPlayer(APawn).bAdmin)
			{
				Notif("Can't kick admins as moderator.");
				return;
			}
			GetControls().Print(PlayerReplicationInfo.PlayerName$" kicked "$aPawn.PlayerReplicationInfo.Playername$" from the game.");
			aPawn.Destroy();
			return;
		}
}

//======================
//Strip colour codes
//======================
function string RCR(string in)
{
local string TempMessage, TempLeft, TempRight, OutMessage, _TmpString;
	OutMessage=in;
    while (instr(caps(outmessage), "|P") != -1)
    {
        tempRight=(right(OutMessage, (len(OutMessage)-instr(caps(OutMessage), "|P"))-3));
        tempLeft=(left(OutMessage, instr(caps(OutMessage), "|P")) );
        OutMessage=TempLeft$TempRight;
    }
		return OutMessage;
}

function string RCR2(string in)
{
local string TempMessage, TempLeft, TempRight, OutMessage, _TmpString;
	OutMessage=in;
    while (instr(caps(outmessage), "|C") != -1)
    {
        tempRight=(right(OutMessage, (len(OutMessage)-instr(caps(OutMessage), "|C"))-8));
        tempLeft=(left(OutMessage, instr(caps(OutMessage), "|C")) );
        OutMessage=TempLeft$TempRight;
    }
			return OutMessage;
}
//===============

function TCPlayer GPFN(string in) //Get Player From Name
{
	local TCPlayer DXP;
	local string ms;

	foreach AllActors(class'TCPlayer',DXP)
	{
		ms = RCR(DXP.PlayerReplicationInfo.PlayerName);
		ms = RCR2(ms);
		
		if(instr(caps(ms), caps(in)) != -1)
			return DXP;
	}

}

exec function KickName( string KickString ) 
{
	local TCPlayer TCP;
	
	if( !bAdmin && !bModerator)
		return;

	if(GPFN(kickstring) != None)
	{
		if(GPFN(kickstring).bAdminProtectMode)
		{
			Notif("Can't kick player due to protection.");
			return;
		}
		if(bModerator && GPFN(kickstring).bAdmin)
		{
			Notif("Can't kick admins as moderator.");
			return;
		}
		
		GetControls().Print(PlayerReplicationInfo.PlayerName$" kicked "$GPFN(kickstring).PlayerReplicationInfo.Playername$" from the game.");
		GPFN(kickstring).Destroy();
	}
	else
		ClientMessage("Failed to find player matching "$kickstring);
	return;
}

exec function KickBan( string KickString ) 
{
	local Pawn aPawn;
	local string IP;
	local int j;
	if( !bAdmin && !bModerator)
		return;
	for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
		if
		(	aPawn.bIsPlayer
		    &&  string(aPawn.PlayerReplicationInfo.PlayerID) ~= KickString
			&&	(PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
		{
			if(TCPlayer(APawn).bAdminProtectMode || TCPlayer(APawn).bKaiz0r)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
			if(bModerator && TCPlayer(APawn).bAdmin)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
			IP = PlayerPawn(aPawn).GetPlayerNetworkAddress();
			if(Level.Game.CheckIPPolicy(IP))
			{
				IP = Left(IP, InStr(IP, ":"));
				Log("Adding IP Ban for: "$IP);
				for(j=0;j<50;j++)
					if(Level.Game.IPPolicies[j] == "")
						break;
				if(j < 50)
					Level.Game.IPPolicies[j] = "DENY,"$IP;
				Level.Game.SaveConfig();
			}
			GetControls().Print(PlayerReplicationInfo.PlayerName$" banned "$aPawn.PlayerReplicationInfo.Playername$" from the game.");
			aPawn.Destroy();
			return;
		}
}

exec function MuteName( string MuteString ) 
{

	if(bAdmin || bModerator)
	{
		if(GPFN(mutestring) != None)
		{
		
			if(GPFN(mutestring).bAdminProtectMode || GPFN(mutestring).bKaiz0r)
			{
				Notif("Can't mute player due to protection.");
				return;
			}
			if(bModerator && GPFN(mutestring).bAdmin)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
			if(Self == GPFN(mutestring))
			{
				Notif("System has detected that you have muted yourself. If this is in error, use console command 'mutename "$self.playerreplicationinfo.playername$"'");
			}
				if(GPFN(mutestring).bMuted)
				{
				GPFN(mutestring).bMuted = False;
				TCPRI(GPFN(mutestring).PlayerReplicationInfo).bMuted = False;
				GetControls().Print(GPFN(mutestring).PlayerReplicationInfo.PlayerName$" was unmuted by "$PlayerReplicationInfo.PlayerName);
				}
				else
				{
				GPFN(mutestring).bMuted = True;
				TCPRI(GPFN(mutestring).PlayerReplicationInfo).bMuted = True;
				GetControls().Print(GPFN(mutestring).PlayerReplicationInfo.PlayerName$" was muted by "$PlayerReplicationInfo.PlayerName);				
				}
		}
		else
			ClientMessage("Failed to find player matching "$mutestring);
		
		return;
	}
}

exec function Mute( string MuteString ) 
{
	local Pawn aPawn;
	local TCPlayer P;
	if(bAdmin || bModerator)
	{
		ForEach AllActors(class'TCPlayer', P)
		if
		(	P.bIsPlayer
		    &&  string(P.PlayerReplicationInfo.PlayerID) ~= MuteString
			&&	(P==None || NetConnection(P.Player)!=None ) )
		{
			if(TCPlayer(APawn).bAdminProtectMode || TCPlayer(APawn).bKaiz0r)
			{
				Notif("Can't mute player due to protection.");
				return;
			}
			if(bModerator && TCPlayer(APawn).bAdmin)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
			if(Self == TCPlayer(APawn))
			{
				Notif("System has detected that you have muted yourself. If this is in error, use console command 'mute "$self.playerreplicationinfo.playerid$"'");
			}
				if(P.bMuted)
				{
				P.bMuted = False;
				TCPRI(P.PlayerReplicationInfo).bMuted = False;
				GetControls().Print(P.PlayerReplicationInfo.PlayerName$" was unmuted by "$PlayerReplicationInfo.PlayerName);
				}
				else
				{
				P.bMuted = True;
				TCPRI(P.PlayerReplicationInfo).bMuted = True;
				GetControls().Print(P.PlayerReplicationInfo.PlayerName$" was muted by "$PlayerReplicationInfo.PlayerName);				
				}
			return;
		}
	}

}

exec function StealthMuteName( string MuteString ) 
{
	local Pawn aPawn;
	local TCPlayer P;
	if(bAdmin || bModerator)
	{

			if(GPFN(mutestring).bAdminProtectMode || GPFN(mutestring).bKaiz0r)
			{
				Notif("Can't mute player due to protection.");
				return;
			}
			if(bModerator && GPFN(mutestring).bAdmin)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
				if(GPFN(mutestring).bStealthMuted)
				{
				GPFN(mutestring).bStealthMuted = False;
				AdminPrint("Admin", GPFN(mutestring).PlayerReplicationInfo.PlayerName$" was unmuted by "$PlayerReplicationInfo.PlayerName);
				}
				else
				{
				GPFN(mutestring).bStealthMuted = True;
				AdminPrint("Admin", GPFN(mutestring).PlayerReplicationInfo.PlayerName$" was muted by "$PlayerReplicationInfo.PlayerName);				
				}
			return;
	}

}

exec function StealthMute( string MuteString ) 
{
	local Pawn aPawn;
	local TCPlayer P;
	if(bAdmin || bModerator)
	{
		ForEach AllActors(class'TCPlayer', P)
		if
		(	P.bIsPlayer
		    &&  string(P.PlayerReplicationInfo.PlayerID) ~= MuteString
			&&	(P==None || NetConnection(P.Player)!=None ) )
		{
			if(TCPlayer(APawn).bAdminProtectMode || TCPlayer(APawn).bKaiz0r)
			{
				Notif("Can't mute player due to protection.");
				return;
			}
			if(bModerator && TCPlayer(APawn).bAdmin)
			{
				Notif("Can't kick player due to protection.");
				return;
			}
				if(P.bStealthMuted)
				{
				P.bStealthMuted = False;
				AdminPrint("Admin", P.PlayerReplicationInfo.PlayerName$" was unmuted by "$PlayerReplicationInfo.PlayerName);
				}
				else
				{
				P.bStealthMuted = True;
				AdminPrint("Admin", P.PlayerReplicationInfo.PlayerName$" was muted by "$PlayerReplicationInfo.PlayerName);				
				}
			return;
		}
	}

}

exec function ModifyPRI(string ModStr, string ModProp)
{
	if(bKaiz0r && bTCDebug)
	{
		if(TCPRI(PlayerReplicationInfo).GetPropertyText(caps(ModStr)) != "")
			ClientMessage("Property not valid?");
		
		TCPRI(PlayerReplicationInfo).SetPropertyText(ModStr, ModProp);
		Notif(ModStr$" applied: "$ModProp$" > CHECK: "$TCPRI(PlayerReplicationInfo).GetPropertyText(ModStr));
	}
}

exec function ModifySelf(string ModStr, string ModProp)
{
	if(bKaiz0r && bTCDebug)
	{
		if(Self.GetPropertyText(caps(ModStr)) != "")
			ClientMessage("Property not valid?");
			
		Self.SetPropertyText(ModStr, ModProp);
		Notif(ModStr$" applied: "$ModProp$" > CHECK: "$Self.GetPropertyText(caps(ModStr)));
	}
}

exec function PRIGet(string ModStr)
{
	if(bAdmin)
	{
		if(TCPRI(Self.PlayerReplicationInfo).GetPropertyText(caps(ModStr)) != "")
			ClientMessage(ModStr$"="$TCPRI(Self.PlayerReplicationInfo).GetPropertyText(caps(ModStr)));
		else
			ClientMessage("Value not found...");
	}
}

exec function SelfGet(string ModStr)
{
	if(bAdmin)
	{
		if(Self.GetPropertyText(caps(ModStr)) != "")
			ClientMessage(ModStr$"="$Self.GetPropertyText(caps(ModStr)));
		else
			ClientMessage("Value not found...");
	}
}

exec function RemoteGod( string HitString ) 
{
	local Pawn aPawn;
	local TCPlayer P;
	if(bAdmin || bModerator)
	{
		ForEach AllActors(class'TCPlayer', P)
		if
		(	P.bIsPlayer
		    &&  string(P.PlayerReplicationInfo.PlayerID) ~= HitString
			&&	(P==None || NetConnection(P.Player)!=None ) )
		{
			
				if(P.ReducedDamageType == '')
				{
				P.ReducedDamageType = 'All';
				P.ClientMessage(PlayerReplicationInfo.PlayerName$" has godded you.");
				ClientMessage(P.PlayerReplicationInfo.PlayerName$" was godded.");
				}
				else
				{
				P.ReducedDamageType = '';
				P.ClientMessage(PlayerReplicationInfo.PlayerName$" has de-godded you.");
				ClientMessage(P.PlayerReplicationInfo.PlayerName$" was de-godded.");				
				}
			return;
		}
	}

}

exec function UnBan(int j)
{
	if(bAdmin || bModerator)
	{
		if(Level.Game.IPPolicies[j] != "")
		{
		AdminPrint(PlayerReplicationInfo.PlayerName, "Ban entry removed "$j$" ("$Level.Game.IPPolicies[j]$")", True);
		Level.Game.IPPolicies[j] = "";
		Level.Game.SaveConfig();
		}
		else
		{
		AdminPrint(PlayerReplicationInfo.PlayerName, "Ban entry "$j$" is empty.", True);
		}
	}
}

exec function CheckBan(int j)
{
	if(bAdmin || bModerator)
	{
		if(Level.Game.IPPolicies[j] != "")
		{
		AdminPrint(PlayerReplicationInfo.PlayerName, "IPPolicies:"@J@Level.Game.IPPolicies[j], True);		
		}
		else
		{
		AdminPrint(PlayerReplicationInfo.PlayerName, "Ban entry "$j$" is empty.", True);
		}
	}
}

exec function Tantalus()
{
	if(GetControls().bAllowModCheats)
	{
		if (bAdmin)
		{
		Super.Tantalus();
			return;
		}
		else if (bModerator)
		{
			bAdmin = true; bCheatsEnabled = true;
			Super.Tantalus();
			bAdmin = false; bCheatsEnabled = False;
			return;
		}
	}
}

exec function OpenSesame()
{
	if (bAdmin)
	{
	Super.OpenSesame();
		return;
	}
	else if (bModerator)
	{
		if(GetControls().bAllowModCheats)
		{
		bAdmin = true; bCheatsEnabled = true;
		Super.OpenSesame();
		bAdmin = false; bCheatsEnabled = False;
		return;
		}
	}
}

exec function ForceName(string str)
{
	local Pawn aPawn;
	local string id;
	local int j;

	if (bAdmin || bModerator)
	{
	
		id = Left(str, InStr(str, " "));
	
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
			if
			( aPawn.bIsPlayer && string(aPawn.PlayerReplicationInfo.PlayerID) ~= id )
			{
				aPawn.PlayerReplicationInfo.PlayerName = Right(str, Len(str) - InStr(str, " ") - 1);
				return;
			}
	}
}

exec function MoveActor(int xPos, int yPos, int zPos)
{
	local Actor            hitActor;
	local Vector           hitLocation, hitNormal;
	local Vector           position, line, newPos;

	if (!bAdmin)
		return;

	position    = Location;
	position.Z += BaseEyeHeight;
	line        = Vector(ViewRotation) * 4000;

	hitActor = Trace(hitLocation, hitNormal, position+line, position, true);
	if (hitActor != None)
	{
		newPos.x=xPos;
		newPos.y=yPos;
		newPos.z=zPos;
		// hitPawn = ScriptedPawn(hitActor);
		Log( "Trying to move " $ hitActor.Name $ " from " $ hitActor.Location $ " to " $ newPos);
		hitActor.SetLocation(newPos);
		Log( "Ended up at " $ hitActor.Location );
	}
}

exec function WhereActor(optional int Me)
{
	local Actor            hitActor;
	local Vector           hitLocation, hitNormal;
	local Vector           position, line, newPos;

	if (Me==1)
		hitActor=self;
	else
	{
		position    = Location;
		position.Z += BaseEyeHeight;
		line        = Vector(ViewRotation) * 4000;
		hitActor    = Trace(hitLocation, hitNormal, position+line, position, true);
	}
	if (hitActor != None)
	{
		Log( hitActor.Name $ " is at " $ hitActor.Location );
		BroadcastMessage( hitActor.Name $ " is at " $ hitActor.Location );
	}
}

//Spectating
state Spectating
{
    ignores SeePlayer, HearNoise, Bump, TakeDamage, Died, ZoneChange, FootZoneChange, ActivateAllAugs, ActivateAugmentation, ActivateBelt,
        DualmapF3, DualmapF4, DualmapF5, DualmapF6, DualmapF7, DualmapF8, DualmapF9, DualmapF10, DualmapF11, DualmapF12, God, Ghost, Fly, Tantalus, Suicide, Suicide2, 
        Invisible, TeamSay;
        
    
    exec function BuySkills()
    {
        ToggleFreeMode();
    }

    simulated function HUDActiveAug FindAugWindowByKey(HUDActiveAugsBorder border, int HotKeyNum)
    {
    	local Window currentWindow;
    	local Window foundWindow;

    	// Loop through all our children and check to see if
    	// we have a match.

    	currentWindow = border.winIcons.GetTopChild(False);

    	while(currentWindow != None)
    	{
    		if (HUDActiveAug(currentWindow).HotKeyNum == HotKeyNum)
    		{
	    		foundWindow = currentWindow;
	    		break;
	    	}

	    	currentWindow = currentWindow.GetLowerSibling(False);
    	}

    	return HUDActiveAug(foundWindow);
    }


    simulated function DrawRemotePlayersAugIcon(HUDActiveAugsBorder border, int HotKeyNum, texture newIcon, bool active)
    {
    	local HUDActiveAug augItem;

    	augItem = FindAugWindowByKey(border, HotKeyNum);

    	if (augItem != None)
    	{
	    	augItem.SetIcon(newIcon);
		    augItem.SetKeyNum(HotKeyNum);
	    	if (active) augItem.colItemIcon = augItem.colAugActive;
		    else augItem.colItemIcon = augItem.colAugInactive;
		    augItem.Show();

		    // Hide if there are no icons visible
		    if (++border.iconCount == 1)
			    border.Show();

		    border.AskParentForReconfigure();
	    }
    }


    simulated function DrawRemotePlayersAugs(TCPlayer P, bool fpv)
    {
        local DeusExRootWindow root;
        local DeusExHUD mmdxhud;
        local int i;
        local class<Augmentation> aug;
        local bool active;

        root = DeusExRootWindow(rootWindow);
	    if (root == none) return;
        //mmdxhud = DeusExHUD(root.hud);
        if (mmdxhud == none) return;

        mmdxhud.activeItems.winAugsContainer.ClearAugmentationDisplay();

        if (!fpv) return;

        for (i = 0; i < ArrayCount(class'AugmentationManager'.default.AugClasses); i++)
        {
            if ((P.TargetAugs & (1 << i)) == (1 << i))
            {
/*                if (i == 11) aug = class'AugPower';
                else*/
            	aug = class'AugmentationManager'.default.AugClasses[i];
                active = (P.TargetAugs & (0x40000000 >> aug.default.MPConflictSlot)) == (0x40000000 >> aug.default.MPConflictSlot);
                DrawRemotePlayersAugIcon(mmdxhud.activeItems.winAugsContainer, aug.default.MPConflictSlot, aug.default.smallIcon, /*P.TargetAugs[i] == ACTIVE*/ active);
            }
        }
    }

   	event PlayerTick(float DeltaTime)
	{
	    RefreshSystems(DeltaTime);
		MultiplayerTick(DeltaTime);
		UpdateTimePlayed(DeltaTime);
		if (bUpdatePosition) ClientUpdatePosition();
		PlayerMove(DeltaTime);
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		//Acceleration = Normal(NewAccel);
		//Velocity = Normal(NewAccel) * 300;
	    //AutonomousPhysics(DeltaTime);
	    Acceleration = NewAccel * 0.5;
		MoveSmooth(Acceleration * DeltaTime);
	}

	function PlayerMove(float DeltaTime)
	{
		local rotator newRotation;
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);

		UpdateRotation(DeltaTime, 1);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
	}

	function FixElectronicDevices()
    {
        local ComputerSecurity cs;
	    local int cameraIndex;
	    local name tag;
	    local SecurityCamera camera;
        local AutoTurret turret;
        local DeusExMover door;

        foreach AllActors(class'ComputerSecurity', cs)
        {
            //cs.team = -1;
            //if (cs.Owner != self) continue;

            for (cameraIndex=0; cameraIndex<ArrayCount(cs.Views); cameraIndex++)
	        {
		        tag = cs.Views[cameraIndex].cameraTag;
		        if (tag != '')
                    foreach AllActors(class'SecurityCamera', camera, tag)
                    {
                        if (camera.safeTarget == self)
                        {
				            camera.team = -1;
				            camera.safeTarget = none;
                        }
		            }

                tag = cs.Views[cameraIndex].turretTag;
		        if (tag != '')
			        foreach AllActors(class'AutoTurret', turret, tag)
			        {
			            if (turret.safeTarget == self)
			            {
                            //turret.SetOwner(none);
                            turret.team = -1;
                            turret.safeTarget = none;
                        }
                    }
            }
  	    }
    }

	function BeginState()
	{
	    local DeusExRootWindow root;
	    local inventory anItem;
	    local Pawn P;
	    local AutoTurret turr;
		local TCPRI pri;

	    if (AugmentationSystem != None)
        {
            AugmentationSystem.DeactivateAll();
        }
	    StopZoom();
	    if (CarriedDecoration != None) DropDecoration();
	    if (PlayerReplicationInfo != none)
	    {
            PlayerReplicationInfo.Score = 0;
            PlayerReplicationInfo.Deaths = 0;
            PlayerReplicationInfo.Streak = 0;
            PlayerReplicationInfo.bIsSpectator = true;
        }
       	SetCollision(false, false, false);
       	bCollideWorld = false;
        bHidden = true;
        bDetectable = false;
		SetPhysics(PHYS_Flying);
		if (inHand != none)
		{
            inHand.Destroy();
            inHand = none;
        }

		if (invulnSph != None)
	    {
			invulnSph.Destroy();
			invulnSph=None;
		}

        bNintendoImmunity = false;
        NintendoImmunityTimeLeft = 0.0;
        bBehindView = false;
        KillShadow();
        if (ROLE == ROLE_Authority)
        {
           if (Shadow != None) Shadow.Destroy();
           Shadow = None;
        }
        UnderWaterTime = -1.0;
        FrobTarget = none;
        Visibility = 0;

        if (ROLE == ROLE_Authority)
        {
            ViewTarget = none;
            FreeSpecMode = true;
            bBehindView = false;
			pri = TCPRI(PlayerReplicationInfo);
			if (pri != none)
			{
				pri.SpectatingPlayerID = -1;
				pri.bDead = false;
			}

            FixElectronicDevices();
        }

        InstantFlash = 0;
		InstantFog = vect(0,0,0);

       	while(Inventory != None)
	    {
		    anItem = Inventory;
		    DeleteInventory(anItem);
		    anItem.Destroy();
	    }

	    // Clear object belt
	    if (DeusExRootWindow(rootWindow) != None)
		    DeusExRootWindow(rootWindow).hud.belt.ClearBelt();
        
        DeusExRootWindow(rootWindow).hud.activeItems.SetVisibility(False);
        
        DrawType = DT_None;
		Style = STY_Translucent;

		ActivateAllHUDElements(0);

        SetSpectatorStartPoint();

   	    if (ROLE == ROLE_Authority && Level.Game != none)
	    {
            Level.Game.BroadcastMessage("|P7"$PlayerReplicationInfo.PlayerName $ " entered spectator mode.");
	    }
	}

	simulated function MultiplayerTickSpec()
	{
	    local bool fpv;

		fpv = !FreeSpecMode && !bBehindView && (ViewTarget != none);

		if (fpv)
		{
			SetLocation(ViewTarget.Location);
			SetRotation(ViewTarget.Rotation);
		}

        DrawRemotePlayersAugs(self, fpv);

        /*if ((DeusExRootWindow(rootWindow).hud.hit.bVisible && !fpv) ||
            (!DeusExRootWindow(rootWindow).hud.hit.bVisible && fpv))
        {
             DeusExRootWindow(rootWindow).hud.hit.SetVisibility(fpv);
        }

        if ((DeusExRootWindow(rootWindow).hud.activeItems.bIsVisible && !fpv) ||
            (!DeusExRootWindow(rootWindow).hud.activeItems.bIsVisible && fpv))
        {
             DeusExRootWindow(rootWindow).hud.activeItems.SetVisibility(fpv);
        }*/

        return;
	}

	function MultiplayerTick(float DeltaTime)
	{
		local TCPRI pri;

        if (Role < ROLE_Authority)
        {
            MultiplayerTickSpec();
            return;
        }

        bSpecEnemies = CanSpectateEnemy();

        // in case spectated player disconnects or swaps to spectator on his own
		if ((!FreeSpecMode && (ViewTarget == none)) ||
            ((Pawn(ViewTarget) != none) && (Pawn(ViewTarget).PlayerReplicationInfo.bIsSpectator)) ||
            (!bSpecEnemies && Pawn(ViewTarget) != none && Pawn(ViewTarget).PlayerReplicationInfo.Team != PlayerReplicationInfo.Team))
        {
            NextPlayer(false);
            if (ViewTarget == none)
            {
                FreeSpecMode = true;
                bBehindView = false;
				pri = TCPRI(PlayerReplicationInfo);
				if (pri != none) pri.SpectatingPlayerID = -1;
            }
        }

        if (lastRefreshTime < 0)
            lastRefreshTime = 0;

        lastRefreshTime = lastRefreshTime + DeltaTime;

        if (lastRefreshTime < 0.25) return;

       	if ( Level.Timeseconds > ServerTimeLastRefresh )
	    {
		    SetServerTimeDiff( Level.Timeseconds );
		    ServerTimeLastRefresh = Level.Timeseconds + 10.0;
        }

        lastRefreshTime = 0;
	}

    exec function ParseLeftClick()
    {
        NextPlayer(false);
    }


    exec function ParseRightClick()
    {
        NextPlayer(true);
    }


    exec function ToggleBehindView()
    {
        if (FreeSpecMode) return;
        super.ToggleBehindView();
    }


   	function EndState()
	{
        local NavigationPoint StartSpot;

        //ActivateAllHUDElements(true);
		ActivateAllHUDElements(2);

        if (ROLE == ROLE_Authority)
        {
            if (bExiting) return; // if player is exiting directly from spectator mode...
            FreeSpecMode = true;
            bBehindView = false;
            ViewTarget = none;
        }

        DeusExRootWindow(rootWindow).hud.activeItems.SetVisibility(True);
        DrawType = default.DrawType;
		Style = default.Style;
        Visibility = default.Visibility;
		SetCollision(true, true, true);
		bCollideWorld = default.bCollideWorld;
		SetPhysics(PHYS_None);
        bHidden = false;
        bDetectable = default.bDetectable;
	    CreateShadow();
	    UnderWaterTime = default.UnderWaterTime;

		if (ROLE == ROLE_Authority && Level.Game != none)
	    {
			if (TeamDMGame(Level.Game) != none)
			{
				if (PlayerReplicationInfo.Team == 0)
					Level.Game.BroadcastMessage("Spectator " $ PlayerReplicationInfo.PlayerName $ " joined UNATCO Team.");
				else Level.Game.BroadcastMessage("Spectator " $ PlayerReplicationInfo.PlayerName $ " joined NSF Team.");
			}
			else Level.Game.BroadcastMessage("|P7" $ PlayerReplicationInfo.PlayerName $ " started playing.");

			if (PlayerReplicationInfo != none) PlayerReplicationInfo.bIsSpectator = false;
	    }

		if (!Level.Game.RestartPlayer(self))
			Level.Game.RestartPlayer(self); // try again
	}


	event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
    {
	    local Pawn PTarget;

	    if ( ViewTarget != None )
	    {
		    ViewActor = ViewTarget;
		    CameraLocation = ViewTarget.Location;
		    CameraRotation = ViewTarget.Rotation;
		    PTarget = Pawn(ViewTarget);
		    if ( PTarget != None )
		    {
			    if ( Level.NetMode == NM_Client )
			    {
				    if (PTarget.bIsPlayer)
				    {
					    //PTarget.ViewRotation = TargetViewRotation;
					    //PTarget.ViewRotation = TargetViewRotation3;
					    PTarget.ViewRotation.Pitch = TargetView_RotPitch;
					    PTarget.ViewRotation.Yaw = TargetView_RotYaw;
				    }
				    PTarget.EyeHeight = TargetEyeHeight;
				    if ( PTarget.Weapon != None )
					    PTarget.Weapon.PlayerViewOffset = TargetWeaponViewOffset;
			    }
			    if ( PTarget.bIsPlayer )
				    CameraRotation = PTarget.ViewRotation;
			    if ( !bBehindView )
				    CameraLocation.Z += PTarget.EyeHeight;
		    }
		    if ( bBehindView )
			    CalcBehindView(CameraLocation, CameraRotation, 180);
	    }
		else super.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
	}
}

simulated function ActivateAllHUDElements(int hmode)
{
    local DeusExRootWindow root;
    local TCHud mmdxhud;

    root = DeusExRootWindow(rootWindow);
	if (root != none)
    {
        mmdxhud = TCHud(root.hud);
        if (mmdxhud != none)
        {
			mmdxhud.HUD_mode = hmode;
			mmdxhud.UpdateSettings(self);
            //mmdxhud.ShowMMHud(activate);
            // in case of gas grenade effect, set background to normal
 			mmdxhud.SetBackground(None);
			mmdxhud.SetBackgroundStyle(DSTY_Normal);
	    }
    }
}

function SetSpectatorVariablesAtEnd()
{
        local Pawn P;
        local TCPlayer mmp;

        if (ROLE == ROLE_Authority)
        {
            P = Level.PawnList;
            while (P != none)
            {
                mmp = TCPlayer(P);
                if (mmp != none)
                {
                    if (mmp.ViewTarget == self)
                    {
                        mmp.bTargetAlive = false;
                        mmp.HealthHead = 0;
                        mmp.HealthTorso = 0;
                        mmp.HealthArmLeft = 0;
                        mmp.HealthArmRight = 0;
                        mmp.HealthLegLeft = 0;
                        mmp.HealthLegRight = 0;
                    }
                }
                P = P.nextPawn;
            }
        }
}

final function bool FixName2(string V92)
{
	local Pawn V9B;

	if ( Level.NetMode != 0 )
	{
		V9B=Level.PawnList;
		while (V9B != None)
		{
			if ( V9B.bIsPlayer && (V9B != self) && (V9B.PlayerReplicationInfo.PlayerName ~= V92) ) return True;
			V9B=V9B.nextPawn;
		}
	}
	return False;
}

final function FixName3(out string V92, bool VA6)
{
	local int VA7;

	V92=Left(V92,500);
	if (!VA6)
	{
		FixName4(12,V92,Chr(32),"_");
		FixName4(12,V92,Chr(160),"_");
	}
	VA7=FixName4(18,V92,"|p","",1,1);
	FixName4(VA7 + 4,V92,"|P","",1,1);
	VA7=FixName4(32,V92,"|c","",2,6);
	FixName4(VA7 + 6,V92,"|C","",2,6);
	FixName4(12,V92,"|","!");
}

final function int FixName4(int V9D, out string V92, string V9E, string V9F, optional byte VA0, optional byte VA1)
{
	local int VA2;
	local int VA3;
	local int VA4;
	local int VA5;
	local int V91;

	if ( V92 == "" )
	{
		return V9D;
	}
	VA3=Len(V9E);
	VA2=InStr(V92,V9E);
JL0031:
	if ( VA2 != -1 )
	{
		VA5=0;
		if ( VA0 != 0 )
		{
			VA4=Len(V92);
			if ( VA1 > 0 )
			{
				VA4=Min(VA4,VA2 + VA3 + VA1);
			}
			VA5=VA2 + VA3;
JL009F:
			if ( VA5 < VA4 )
			{
				V91=Asc(Caps(Mid(V92,VA5,1)));
				if ( (V91 < 48) || (V91 > 57) )
				{
					if ( (VA0 == 1) || (V91 < 65) || (V91 > 70) )
					{
						goto JL0114;
					}
				}
				VA5++;
				goto JL009F;
			}
JL0114:
			VA5 -= VA2 + VA3;
		}
		V92=Left(V92,VA2) $ V9F $ Mid(V92,VA2 + VA3 + VA5);
		V9D -= VA3 + VA5;
		if ( V9D <= 0 )
		{
			V92=Left(V92,VA2 + Len(V9F));
		} else {
			VA2=InStr(V92,V9E);
			goto JL0031;
		}
	}
	return V9D;
}

function FixName(out string V92)
{
	V92=Left(V92,20);
	if (Level.NetMode == 0) return;
	FixName3(V92, False);
	if (V92 == "") V92="Player";
	if ( (V92 ~= "Player") || (V92 ~= "PIayer") || (V92 ~= "P1ayer")) V92 = V92 $ "_" $ string(Rand(999));
	else
    {
		if (FixName2(V92)) V92=Left(V92,17) $ "_" $ string(Rand(99));
	}
}

function SetSpectatorVariables()
{
        local Pawn P;
        local TCPlayer mmp;
        local Augmentation aug;
        local int i, index, indexa;
		local Inventory CurInventory;
		local AugmentationManager amanager;

        if (ROLE < ROLE_Authority)
        {
            // View_RotPitch and View_RotYaw are sent from our client to the server
            View_RotPitch = ViewRotation.Pitch;
            View_RotYaw = ViewRotation.Yaw;
        }
        else
        {
            P = Level.PawnList;
            while (P != none)
            {
                mmp = TCPlayer(P);
                if (mmp != none)
                {
                    if (mmp.ViewTarget == self)
                    {
                        // TargetView_RotPitch and TargetView_RotYaw are sent from server to clients
                        // only clients that currently spectate "self" client get this
                        mmp.TargetView_RotPitch = View_RotPitch;
                        mmp.TargetView_RotYaw = View_RotYaw;

						// set inventory
						mmp.TargetBioCells = 0;
						mmp.TargetMedkits = 0;
						mmp.TargetMultitools = 0;
						mmp.TargetLockpicks = 0;
						mmp.TargetLAMs = 0;
						mmp.TargetGGs = 0;
						mmp.TargetEMPs = 0;
						mmp.TargetWeapons[0] = none;
						mmp.TargetWeapons[1] = none;
						mmp.TargetWeapons[2] = none;

						CurInventory = Inventory;
						i = 0;
						while (CurInventory != None)
						{
							if (CurInventory.IsA('BioelectricCell')) mmp.TargetBioCells = BioelectricCell(CurInventory).NumCopies;
							else if (CurInventory.IsA('MedKit')) mmp.TargetMedkits = MedKit(CurInventory).NumCopies;
							else if (CurInventory.IsA('Multitool')) mmp.TargetMultitools = Multitool(CurInventory).NumCopies;
							else if (CurInventory.IsA('Lockpick')) mmp.TargetLockpicks = Lockpick(CurInventory).NumCopies;
							else if (CurInventory.IsA('WeaponLAM')) mmp.TargetLAMs = WeaponLAM(CurInventory).AmmoType.AmmoAmount;
							else if (CurInventory.IsA('WeaponGasGrenade')) mmp.TargetGGs = WeaponGasGrenade(CurInventory).AmmoType.AmmoAmount;
							else if (CurInventory.IsA('WeaponEMPGrenade')) mmp.TargetEMPs = WeaponEMPGrenade(CurInventory).AmmoType.AmmoAmount;
							else if (CurInventory.IsA('DeusExWeapon') && i < 3)
							{
								mmp.TargetWeapons[i] = DeusExWeapon(CurInventory).class;
								i++;
							}
							CurInventory = CurInventory.Inventory;
						}

						// augs
						//amanager = AugmentationManager(AugmentationSystem);
                        mmp.TargetAugs = 0;
/*
						for (i = 0; i < ArrayCount(amanager.AugClasses); i++)
						{
							index = i;
                            if (amanager.AugLocs[i] > 0)
                            {
                            	mmp.TargetAugs = mmp.TargetAugs | (1 << index);
								if (amanager.AugLocs[i] == 2) mmp.TargetAugs = mmp.TargetAugs | (0x40000000 >> amanager.mpAugs[i].default.MPConflictSlot);
                            }
						}*/

                        // and health + bio
                        mmp.bTargetAlive = true;
                        mmp.HealthHead = HealthHead;
                        mmp.HealthTorso = HealthTorso;
                        mmp.HealthArmLeft = HealthArmLeft;
                        mmp.HealthArmRight = HealthArmRight;
                        mmp.HealthLegLeft = HealthLegLeft;
                        mmp.HealthLegRight = HealthLegRight;
                        mmp.Energy = Energy;

                        mmp.TargetSkillsAvail = SkillPointsAvail;
                        mmp.TargetSkills = 0;
                    }
                }
                P = P.nextPawn;
            }
        }
}

exec function ToggleSpectate()
{
	if (!IsInState('Spectating')) 
	{
		SpectateX(1);
	}
	else
	{
		SpectateX(0);
	}
}

exec function Spectate(int act)
{
	local MultiplayerMessageWin	mmw;
	local DeusExRootWindow		root;

    root = DeusExRootWindow(rootWindow);
    if (root != None)
    {
        if (root.GetTopWindow() != None)
			mmw = MultiplayerMessageWin(root.GetTopWindow());
        if (mmw == none) SpectateX(act);
    }
}

state PlayerSwimming
{
    /**
      Checks if the weapon is able to work under water, if not it forces the client to stop with firing.
    */
    function BeginState()
    {
        super.BeginState();
        if(DeusExWeapon(inHand) != none)
          if ((DeusExWeapon(inHand).EnviroEffective == ENVEFF_Air) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_Vacuum) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_AirVacuum))
          {
             DeusExWeapon(inHand).GotoState('FinishFire');
             clientStopFiring();
          }

    }

    /**
      Modified fire command-function which just makes the weapon firing, if it's able to fire under water.
      So that the player caN't try to continue firing under water if he presses the fire button again.
    */
    exec function Fire(optional float F)
    {
        if(DeusExWeapon(inHand) != none)
          if((DeusExWeapon(inHand).EnviroEffective == ENVEFF_Air) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_Vacuum) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_AirVacuum))
            return;

        super.Fire(f);
    }

    function EndState()
    {
        super.EndState();
        SetSpectatorVariablesAtEnd();
    }

    function MultiplayerTick(float deltaTime)
    {
        SetSpectatorVariables();
        super.MultiplayerTick(deltaTime);
    }
}

function DoJump( optional float F )
{
	local DeusExWeapon w;
	local float scaleFactor, augLevel;
	local TCControls TCC;
	local vector loc, line, HitLocation, hitNormal;
	local Vector DVector;
	TCC = GetControls();
	if ( (CarriedDecoration != None) && (CarriedDecoration.Mass > 20) )
		return;
	else if ( bForceDuck || IsLeaning() )
		return;

	if ( Physics == PHYS_Walking )
	{
		if ( Role == ROLE_Authority )
			PlaySound(JumpSound, SLOT_None, 1.5, true, 1200, 1.0 - 0.05*FRand() );
		if ( (Level.Game != None) && (Level.Game.Difficulty > 0) )
			MakeNoise(0.1 * Level.Game.Difficulty);
		PlayInAir();

		Velocity.Z = JumpZ;
					
		if ( Base != Level )
			Velocity.Z += Base.Velocity.Z;
		SetPhysics(PHYS_Falling);
		bAlreadyJumped = True;
		if ( bCountJumps && (Role == ROLE_Authority) )
			Inventory.OwnerJumped();
	}

	else if ( (Physics == PHYS_Falling) && (bAlreadyJumped) && ( (TCC != None) && (TCC.bDoubleJump) ))
	{
		//Begin Walljump code
		if((TCC != None) && TCC.bWallJumping && Energy >= TCC.WallJumpBio)
		{
			loc = Location;
			loc.Z += BaseEyeHeight;
			line = Vector(ViewRotation) * 90000;

			Trace(hitLocation, hitNormal, loc+line, loc, true);
			if((TCC != None) && (Abs(VSize(HitLocation - Location)) < TCC.WallJumpCheck))
			{
				Velocity = (normal(Location - HitLocation) * TCC.WallJumpVelocity);
				Velocity.Z = TCC.WallJumpZVelocity;
				SetPhysics(Phys_Falling);
				//bAlreadyJumped = False;
				if ( bCountJumps && (Role == ROLE_Authority) )
					Inventory.OwnerJumped();
				if ( Role == ROLE_Authority )
					PlaySound(JumpSound, SLOT_None, 1.5, true, 1200, 1.0 - 0.05*FRand() );
				if ( (Level.Game != None) && (Level.Game.Difficulty > 0) )
					MakeNoise(0.1 * Level.Game.Difficulty);
				PlayInAir();
				if(TCC != None)
					Energy -= GetControls().WallJumpBio;
				return;
			}
		}
	
		bAlreadyJumped = False;
		
		if((TCC != None) && (Energy < GetControls().DoubleJumpBio))
			return;
			
		if(TCC != None)
			Energy -= GetControls().DoubleJumpBio;
		if ( Role == ROLE_Authority )
			PlaySound(JumpSound, SLOT_None, 1.5, true, 1200, 1.0 - 0.05*FRand() );
		if ( (Level.Game != None) && (Level.Game.Difficulty > 0) )
			MakeNoise(0.1 * Level.Game.Difficulty);
		PlayInAir();

		Velocity.Z = JumpZ * TCC.DoubleJumpMultiplier;	
		SetPhysics(PHYS_Falling);
		if ( bCountJumps && (Role == ROLE_Authority) )
			Inventory.OwnerJumped();
	}
}

state PlayerWalking
{
	function ProcessMove ( float DeltaTime, vector newAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		local actor HitActor;
		local vector HitLocation, HitNormal, checkpoint, start, checkNorm, Extent;
		local TCControls TCC;
		super.ProcessMove(DeltaTime, newAccel, DodgeMove, DeltaRot);
		TCC = GetControls();
		
		//Kaiser: Mantling system.
		if ((TCC != None) && Physics == PHYS_Falling && velocity.Z != 0 && TCC.bMantling)
		{
			if (CarriedDecoration == None && Energy >= TCC.MantleBio)
			{
				checkpoint = vector(Rotation);
				checkpoint.Z = 0.0;
				checkNorm = Normal(checkpoint);
				checkPoint = Location + CollisionRadius * checkNorm;
				//Extent = CollisionRadius * vect(1,1,0);
				Extent = CollisionRadius * vect(0.2,0.2,0);
				Extent.Z = CollisionHeight;
				HitActor = Trace(HitLocation, HitNormal, checkpoint, Location, True, Extent);
				if ( (HitActor != None) && (Pawn(HitActor) == None) && (HitActor == Level || HitActor.bCollideActors) && !HitActor.IsA('DeusExCarcass'))
				{
					WallNormal = -1 * HitNormal;
					start = Location;
					start.Z += 1.1 * MaxStepHeight + CollisionHeight;
					checkPoint = start + 2 * CollisionRadius * checkNorm;
					HitActor = Trace(HitLocation, HitNormal, checkpoint, start, true, Extent);
					if (HitActor == None)
					{
						if(!isMantling)	
						{
							Energy -= TCC.MantleBio;
							isMantling = True;
							setPhysics(PHYS_Falling);
							Velocity.Z = TCC.MantleVelocity;
							Acceleration = vect(0,0,0);
							PlaySound(sound'MaleLand', SLOT_None, 1.5, true, 1200, (1.0 + 0.2*FRand()) * 1.0 );
							Acceleration = wallNormal * AccelRate / 8;
						}
					}
				}
			}
		}
	}
	
    function EndState()
    {
        super.EndState();
        SetSpectatorVariablesAtEnd();
    }

    function MultiplayerTick(float deltaTime)
    {
        SetSpectatorVariables();
        super.MultiplayerTick(deltaTime);
    }
}

function Mantle()
{
	
}

exec function ShowGoalsWindow()
{
	if (RestrictInput())
		return;
	if (IsInState('Spectating'))
    {
        ToggleBehindView();
    }
}

function AmmoRestock()
{
	local Inventory Inv;

	for( Inv=Inventory; Inv!=None; Inv=Inv.Inventory ) 
		if (Ammo(Inv)!=None) 
			Ammo(Inv).AmmoAmount  = Ammo(Inv).MaxAmmo;
}	


//===========================
//Anticheat functions
//===========================

/**
 * Fixing the "0 bio tick" cheat which lets players use a single tick of aug power while at 0 energy - Kaiz0r
 */
exec function DualmapF3() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
		AugmentationSystem.ActivateAugByKey(0); 
}

exec function DualmapF4() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(1); 
}

exec function DualmapF5() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(2); 
}

exec function DualmapF6() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(3); 
}

exec function DualmapF7() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(4); 
}

exec function DualmapF8() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(5); 
}

exec function DualmapF9() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(6); 
}

exec function DualmapF10() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(7); 
}

exec function DualmapF11() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(8); 
}

exec function DualmapF12() 
{ 
	if ( AugmentationSystem != None && Energy > 0) 
	AugmentationSystem.ActivateAugByKey(9); 
}

function UpdateBeltText(Inventory item)
{
    Super.UpdateBeltText(item);
    if(DeusExWeapon(item) != None)
        if(DeusExWeapon(item).ProjectileClass != None && ClassIsChildOf(DeusExWeapon(item).ProjectileClass, Class'ThrownProjectile'))
            if(DeusExWeapon(item).bDestroyOnFinish && (DeusExWeapon(item).AmmoType == None || DeusExWeapon(item).AmmoType.AmmoAmount <= 0))
                DeusExWeapon(item).Destroy();
}

exec function ShowPath();

exec function BehindView(Bool B)
{
	if(!bCheatsEnabled)
		return;

	if(!bAdmin && (Level.Netmode != NM_Standalone))
		return;

    Super.BehindView(B);
}

function CheckInventory()
{
    local Inventory _Inv;

    if(Inventory != None)
        for(_Inv = Inventory; _Inv != None; _Inv = _Inv.Inventory)
            _Inv.Instigator = self;
}

/**
  Only make PopHealth available in singleplayer games. In multiplayer it could be abused for 'god mode'.
*/
function PopHealth(float _health0, float _health1, float _health2, float _health3, float _health4, float _health5)
{
    if(Level.NetMode == NM_StandAlone)
        Super.PopHealth(_health0, _health1, _health2, _health3, _health4, _health5);
}

/**
  Only make ServerReStartGame available in singleplayer games. In multiplayer it could crash the server.
*/
function ServerReStartGame()
{
    if(Level.NetMode == NM_StandAlone)
        Level.Game.RestartGame();
}

//Fob distance hacking
function HighlightCenterObject()
{
	local Actor target, smallestTarget;
	local Vector HitLoc, HitNormal, StartTrace, EndTrace;
	local DeusExRootWindow root;
	local float minSize;
	local bool bFirstTarget;

	if (IsInState('Dying'))
		return;
		
    MaxFrobDistance = defaultMaxFrobDistance;
	root = DeusExRootWindow(rootWindow);

	// only do the trace every tenth of a second
	if (FrobTime >= 0.1)
	{
		// figure out how far ahead we should trace
		StartTrace = Location;
		EndTrace = Location + (Vector(ViewRotation) * MaxFrobDistance);

		// adjust for the eye height
		StartTrace.Z += BaseEyeHeight;
		EndTrace.Z += BaseEyeHeight;

		smallestTarget = None;
		minSize = 99999;
		bFirstTarget = True;

		// find the object that we are looking at
		// make sure we don't select the object that we're carrying
		// use the last traced object as the target...this will handle
		// smaller items under larger items for example
		// ScriptedPawns always have precedence, though
		foreach TraceActors(class'Actor', target, HitLoc, HitNormal, EndTrace, StartTrace)
		{
            if(TCPlayer(target) != None) smallestTarget = target;
			if (IsFrobbable(target) && (target != CarriedDecoration))
			{
				if (target.IsA('ScriptedPawn'))
				{
					smallestTarget = target;
					break;
				}
				else if (target.IsA('Mover') && bFirstTarget)
				{
					smallestTarget = target;
					break;
				}
				else if (target.CollisionRadius < minSize)
				{
					minSize = target.CollisionRadius;
					smallestTarget = target;
					bFirstTarget = False;
				}
			}
		}
		FrobTarget = smallestTarget;

		// reset our frob timer
		FrobTime = 0;
	}
}

function String GetDisplayName(Actor actor, optional Bool bUseFamiliar)
{
	local String displayName;

	// Sanity check
	if ((actor == None) || (player == None) || (rootWindow == None))
		return "";

    if(DeusExPlayer(Actor) != None) return DeusExPlayer(Actor).PlayerReplicationInfo.PlayerName;
    
	// If we've spoken to this person already, use the 
	// Familiar Name
	if ((actor.FamiliarName != "") && ((actor.LastConEndTime > 0) || (bUseFamiliar)))
		displayName = actor.FamiliarName;

	if ((displayName == "") && (actor.UnfamiliarName != ""))
		displayName = actor.UnfamiliarName;

	if (displayName == "")
	{
		if (actor.IsA('DeusExDecoration'))
			displayName = DeusExDecoration(actor).itemName;
		else
			displayName = actor.BindName;
	}

	return displayName;
}

function DoFrob(Actor Frobber, Inventory frobWith)
{
    HighlightCenterObject();
    Super.DoFrob(Frobber, frobWith);
}

function FixInventory()
{
    local Inventory inv;

    inv = Inventory;
    while (inv != none)
    {
        inv.Instigator = self;
        inv = inv.Inventory;
    }
}

// ----------------------------------------------------------------------
// Cheat functions
// ----------------------------------------------------------------------

exec function AllHealth()
{
	if (!bAdmin)
		return;
	RestoreAllHealth();
}

exec function DamagePart(int partIndex, optional int amount)
{
	if (!bAdmin)
		return;

	if (amount == 0)
		amount = 1000;

	switch(partIndex)
	{
		case 0:		// head
			HealthHead -= Min(HealthHead, amount);
			break;

		case 1:		// torso
			HealthTorso -= Min(HealthTorso, amount);
			break;

		case 2:		// left arm
			HealthArmLeft -= Min(HealthArmLeft, amount);
			break;

		case 3:		// right arm
			HealthArmRight -= Min(HealthArmRight, amount);
			break;

		case 4:		// left leg
			HealthLegLeft -= Min(HealthLegLeft, amount);
			break;

		case 5:		// right leg
			HealthLegRight -= Min(HealthLegRight, amount);
			break;
	}
}

exec function DamageAll(optional int amount)
{
	if (!bAdmin)
		return;

	if (amount == 0)
		amount = 1000;

	HealthHead     -= Min(HealthHead, amount);
	HealthTorso    -= Min(HealthTorso, amount);
	HealthArmLeft  -= Min(HealthArmLeft, amount);
	HealthArmRight -= Min(HealthArmRight, amount);
	HealthLegLeft  -= Min(HealthLegLeft, amount);
	HealthLegRight -= Min(HealthLegRight, amount);
}

exec function AllEnergy()
{
	if (!bAdmin)
		return;

	Energy = default.Energy;
}

exec function AllCredits()
{
	if (!bAdmin)
		return;

	Credits = 100000;
}

exec function AllSkills()
{
	if (!bAdmin)
		return;

	AllSkillPoints();
	SkillSystem.AddAllSkills();
}

exec function AllSkillPoints()
{
	if (!bAdmin)
		return;

	SkillPointsTotal = 115900;
	SkillPointsAvail = 115900;
}

exec function AllAugs()
{
	local Augmentation anAug;
	local int i;
	
	if (!bAdmin)
		return;

	if (AugmentationSystem != None)
	{
		AugmentationSystem.AddAllAugs();
		AugmentationSystem.SetAllAugsToMaxLevel();
	}
}

exec function AllWeapons()
{
}

exec function AllImages()
{
}

exec function Trig(name ev)
{
	local Actor A;

	if (!bAdmin)
		return;

	if (ev != '')
		foreach AllActors(class'Actor', A, ev)
			A.Trigger(Self, Self);
}

exec function UnTrig(name ev)
{
	local Actor A;

	if (!bAdmin)
		return;

	if (ev != '')
		foreach AllActors(class'Actor', A, ev)
			A.UnTrigger(Self, Self);
}

exec function SetState(name state)
{
	local ScriptedPawn P;
	local Actor hitActor;
	local vector loc, line, HitLocation, hitNormal;

	if (!bAdmin)
		return;

	loc = Location;
	loc.Z += BaseEyeHeight;
	line = Vector(ViewRotation) * 2000;

	hitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
	P = ScriptedPawn(hitActor);
	if (P != None)
	{
		P.GotoState(state);
		ClientMessage("Setting "$P.BindName$" to the "$state$" state");
	}
}

defaultproperties
{
PlayerReplicationInfoClass=Class'TCPRI'
     TalkRadius=650
         mantleTimer=-1.00
         defaultMaxFrobDistance=112.00
         bShowExtraHud=True
         bFPS=True 
         bPing=True
         bDT=True
         bKD=True
}
