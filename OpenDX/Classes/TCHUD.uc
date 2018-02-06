//=============================================================================
// DeusExHUD.
//=============================================================================
class TCHUD expands DeusExHUD;

var TextWindow winNotif, winTimerDisplay, winHitz, winDebug, winFPS;
//var TCHUDWaypoint winWaypoint;
var float wintimer, wintimerhitz;
var int newLTO;
var bool bshowing, bshowinghitz;
var string CurHitz;
var TCPlayer Hostz;
var int HUD_Mode;
var Texture TextLogo;
//To do, a party display, on center right
event InitWindow()
{
	local DeusExRootWindow root;
	local DeusExPlayer player;

	Super.InitWindow();

	// Get a pointer to the root window
	root = DeusExRootWindow(GetRootWindow());

	// Get a pointer to the player
	player = DeusExPlayer(root.parentPawn);
	
	Hostz = TCPlayer(root.parentPawn);
	
	SetFont(Font'TechMedium');
	SetSensitivity(false);

	/*ammo			= HUDAmmoDisplay(NewChild(Class'HUDAmmoDisplay'));
	hit				= HUDHitDisplay(NewChild(Class'HUDHitDisplay'));
	cross			= Crosshair(NewChild(Class'Crosshair'));
	belt			= HUDObjectBelt(NewChild(Class'HUDObjectBelt'));
	activeItems		= HUDActiveItemsDisplay(NewChild(Class'HUDActiveItemsDisplay'));
	damageDisplay	= DamageHUDDisplay(NewChild(Class'DamageHUDDisplay'));
	compass     	= HUDCompassDisplay(NewChild(Class'HUDCompassDisplay'));
	hms				= HUDMultiSkills(NewChild(Class'HUDMultiSkills'));*/
	
	//Debug
	//winDebug = TextWindow(NewChild(Class'TextWindow'));
	//winDebug.SetWindowAlignments(HALIGN_Left,VALIGN_Top,,128);
	//winDebug.SetFont(Font'TechMedium');
	
	//winWaypoint = TCHUDWaypoint(NewChild(Class'TCHUDWaypoint'));
	//winWaypoint.SetWindowAlignments(HALIGN_Full, VALIGN_Full);

	//Notifications
	winNotif = TextWindow(NewChild(Class'TextWindow'));
	winNotif.SetWindowAlignments(HALIGN_Center,VALIGN_Top,,128);
	winNotif.SetFont(Font'TechMedium');
	
	//Timer
	winTimerDisplay = TextWindow(NewChild(Class'TextWindow'));
	winTimerDisplay.SetWindowAlignments(HALIGN_Right,VALIGN_Center,,128);
	winTimerDisplay.SetFont(Font'TechMedium');
	
	winFPS = TextWindow(NewChild(Class'TextWindow'));
	winFPS.SetWindowAlignments(HALIGN_Right,VALIGN_Center,,128);
	winFPS.SetFont(Font'TechMedium');
	winFPS.Show(True);
	
	winHitz = TextWindow(NewChild(Class'TextWindow'));
	winHitz.SetWindowAlignments(HALIGN_Left,VALIGN_Center,,128);
	winHitz.SetFont(Font'TechMedium');

	if(msgLog != None) msgLog.Destroy();
	msgLog 			= HUDLogDisplay(NewChild(Class'TCHUDLogDisplay'));
	msgLog.SetLogTimeout(15);
	//TCHUDLogDisplay(msgLog).TextLogo=TextLogo;

	if (hit != none) hit.Destroy();
	hit				= HUDHitDisplay(NewChild(Class'TCHUDHitDisplay'));
	if (augDisplay != None)	augDisplay.Destroy();
	augDisplay		= AugmentationDisplayWindow(NewChild(Class'TCAugmentationDisplayWindow'));
	augDisplay.SetWindowAlignments(HALIGN_Full, VALIGN_Full);

	bTickEnabled = True;
}

/*event wpActive(bool bOn)
{
	if(winWaypoint != None)
	{
		winWaypoint.bActive = bOn;
	}
}
*/

event DescendantRemoved(Window descendant)
{
	if (descendant == winTimerDisplay)
		winTimerDisplay = None;
	else if (descendant == winHitz)
		winHitz = None;
	else if (descendant == winFPS)
		winFPS = None;
	else if (descendant == winNotif)
		winNotif = None;
	else
		Super.DescendantRemoved(descendant);
}

event StartDebug()
{
	winDebug.Show(True);
}

event StopDebug()
{
	winDebug.Hide();
}

function UpdateDebug(string str)
{
	winDebug.SetText(str);
}

event StartTimer()
{
	//winTimerDisplay.Show(True);
}

event StopTimer()
{
	//winTimerDisplay.Hide();
}

function UpdateTimer(string str)
{
	//local DeusExRootWindow root;
	//root = DeusExRootWindow(GetRootWindow());
	//winTimerDisplay.SetText(TCPlayer(root.parentPawn).CC$str);
}

event TCN(string str)
{
	winNotif.SetText(str);
	winNotif.Show(True);
    bShowing = True;
	wintimer = 5; 
}

final function string FormatFloat( float f)
{
	return Left(f, Len(f)-7);
}

//If the basics of this works
//Try changing how the script works
//Instead of creating one window at initiation
//Each call of showhitz crates one window
//Then somehow make that one window gradually move up for a timer?
//Maybe new class extending text window using the tick to track a lifespan while moving up
event ShowHitz(string Dmg) 
{
	CurHitz = CurHitz@dmg;
	winHitz.SetText(Left(CurHitz,128));
	winHitz.Show(True);
    bShowingHitz = True;
	wintimerHitz = 2; 
}

event ToggleExtras()
{
	if(winFPS == None)
	{
		winFPS = TextWindow(NewChild(Class'TextWindow'));
		winFPS.SetWindowAlignments(HALIGN_Right,VALIGN_Center,,128);
		winFPS.SetFont(Font'TechMedium');
		winFPS.Show(True);
		return;
	}
	else
		winFPS.Destroy();
}

function tick(float deltaTime)
{
	local DeusExRootWindow root;
	local TCPlayer tcp;
	local string str;
	local TCPRI hostPRI;
	
	root = DeusExRootWindow(GetRootWindow());
	if(hostz != None && TCPRI(hostz.PlayerReplicationInfo) != None)
		hostPRI = TCPRI(hostz.PlayerReplicationInfo);

	if(winFPS != None && hostz != None)
	{
		//if(hostz.bFPS)
			str = "FPS="$hostPRI.FPS;
		//if(hostz.bDT)
			str = str@"SPEED="$hostPRI.DT;
		//if(hostz.bPing)
			str = str@"PING="$hostPRI.PingPRI;
		//if(hostz.bKD)
			str = str@"K/D="$FormatFloat(hostPRI.Score)$"/"$FormatFloat(hostPRI.Deaths);
		winFPS.SetText(str);
	}
		
	if (bShowing)
	{
		wintimer -= deltaTime;

		winNotif.Show(True);

		if (wintimer <= 0)
		{
			TCNHide();
			bShowing = False;
		}
	}	
	
	if (bShowinghitz)
	{
		wintimerhitz -= deltaTime;

		winhitz.Show(True);
	  
		if (wintimerhitz <= 0)
		{
			hitzhide();
			curhitz="";
			bShowinghitz = False;
		}
	}	   
}

event hitzhide()
{
	curhitz="";
	bShowinghitz = False;
	winhitz.Hide();
}

event TCNHide()
{
	bShowing = False;
	winNotif.Hide();
}

function UpdateSettings( DeusExPlayer player )
{
	if (HUD_mode > 0)
	{
		// spectating another player
		hit.SetVisibility(player.bHitDisplayVisible);
		activeItems.SetVisibility(player.bAugDisplayVisible);
		damageDisplay.SetVisibility(player.bHitDisplayVisible);
		cross.SetCrosshair(player.bCrosshairVisible);
		if (HUD_mode > 1)
		{
			// playing
			compass.SetVisibility(player.bCompassVisible);
			ammo.SetVisibility(player.bAmmoDisplayVisible);
			belt.SetVisibility(player.bObjectBeltVisible);
		}
		else
		{
			// spectating another player, hide these
			//compass.SetVisibility(false);
			ammo.SetVisibility(false);
			belt.SetVisibility(false);
			ResetCrosshair();
		}
	}
	else
	{
		// spectating in free mode, hide all
		hit.SetVisibility(false);
		activeItems.SetVisibility(false);
		damageDisplay.SetVisibility(false);
		cross.SetCrosshair(false);
		compass.SetVisibility(false);
		ammo.SetVisibility(false);
		belt.SetVisibility(false);
		ResetCrosshair();
	}
}
function ResetCrosshair()
{
	local color col;
    col.R = 255;
    col.G = 255;
    col.B = 255;
    cross.SetCrosshairColor(col);
}
defaultproperties
{
	HUD_Mode=2
}
