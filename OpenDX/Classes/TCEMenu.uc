class TCEMenu extends MenuUIScreenWindow;

struct S_MenuButton
{
	var int y;
	var int x;
	var EMenuActions action;
	var class invoke;
	var string key;
};

var MenuUIMenuButtonWindow winButtons[4];

var string ButtonNames[4];

var int buttonWidth;
var S_MenuButton buttonDefaults[4];

var bool isspec;
var bool bSpect;

var bool IsExiting;

event InitWindow()
{
	local Window W;

	Super.InitWindow();

	if (Player.GameReplicationInfo != none && !Player.GameReplicationInfo.bTeamGame)
	{
		ButtonNames[0] = "Play";
		ButtonNames[1] = "";
		ButtonNames[2] = "";
	}

	IsExiting = true;

	//CreateMenuButtons();

    //if (Player.PlayerReplicationInfo != none && Player.PlayerReplicationInfo.bIsSpectator) isspec = true;
   // else isspec = false;
    
    winClient.SetBackground(Texture'DeusExUI.MaskTexture');
   winClient.SetBackgroundStyle(DSTY_Modulated);

   W = winClient.NewChild(Class'Window');
   W.SetSize(ClientWidth, ClientHeight);
   W.SetBackground(Texture'DeusExUI.MaskTexture');
   W.SetBackgroundStyle(DSTY_Modulated);
   W.Lower();
}

function SetMOTDText(string MOTDText[8])
{
	local int i;

	for (i = 0; i < 8; i++) CreateLabel(20, 20 + (i * 15), MOTDText[i]);
}

final function MenuUISmallLabelWindow CreateLabel(int X, int Y, string S)
{
	local MenuUISmallLabelWindow W;

	W = MenuUISmallLabelWindow(winClient.NewChild(Class'MenuUISmallLabelWindow'));
	W.SetPos(X, Y);
	W.SetText(S);
	W.SetWordWrap(false);

	return W;
}


function CreateMenuButtons()
{
	local int buttonIndex;

	for (buttonIndex = 0; buttonIndex < arrayCount(buttonDefaults); buttonIndex++)
	{
		if (ButtonNames[buttonIndex] != "")
		{
			winButtons[buttonIndex] = MenuUIMenuButtonWindow(winClient.NewChild(Class'MenuUIMenuButtonWindow'));

			winButtons[buttonIndex].SetButtonText(ButtonNames[buttonIndex]);
			winButtons[buttonIndex].SetPos(buttonDefaults[buttonIndex].x, buttonDefaults[buttonIndex].y);
			winButtons[buttonIndex].SetWidth(buttonWidth);
		}
	}
	if(bSpect)
	{
		winButtons[0].SetSensitivity(True);
		winButtons[1].SetSensitivity(True);
		winButtons[2].SetSensitivity(True);
		winButtons[3].SetSensitivity(False);
	}
	else
	{
		winButtons[0].SetSensitivity(False);
		winButtons[1].SetSensitivity(False);
		winButtons[2].SetSensitivity(False);
		winButtons[3].SetSensitivity(True);
	}
}


function bool ButtonActivated(Window buttonPressed)
{
	local bool bHandled;
	local int  buttonIndex;

	bHandled = False;

	if (Super.ButtonActivated(buttonPressed)) return true;

	// Figure out which button was pressed
	for (buttonIndex = 0; buttonIndex < arrayCount(winButtons); buttonIndex++)
	{
		if (buttonPressed == winButtons[buttonIndex])
		{
			// Check to see if there's somewhere to go
			ProcessMenuAction(buttonDefaults[buttonIndex].action, buttonDefaults[buttonIndex].invoke, buttonDefaults[buttonIndex].key);

			bHandled = True;
			break;
		}
	}

	return bHandled;
}


function ProcessCustomMenuButton(string key)
{
    isspec = false;

	switch(key)
	{
		case "SPECTATE":
			/*if (!mmp.IsInState('Spectating'))*/ TCPlayer(Player).Spectate(1);
			isspec = true;
			break;
		case "JOIN_UNATCO":
			TCPlayer(Player).NewChangeTeam(0);
			break;
		case "JOIN_NSF":
			TCPlayer(Player).NewChangeTeam(1);
			break;
		case "JOIN_AUTO":
			TCPlayer(Player).NewChangeTeam(2);
			break;
	}

	CancelScreen();
}


function ProcessAction(String S)
{
    switch (S)
    {
        case "AUGS":
            root.InvokeMenuScreen(class'MenuScreenAugSetup');
            break;
        case "DISC":
            Player.DisconnectPlayer();
            break;
         case "SET":
            root.InvokeMenuScreen(class'TCMenuGame');
            break;
         case "DXSL":
            root.InvokeMenuScreen(class'mtlmenuscreenjoininternet');
            break;  
         case "CANCEL":
			//if (isspec && mmp != none) mmp.ActivateAllHUDElements(false);
			CancelScreen();
        	//root.PopWindow();
            break;
    }
}


function CancelScreen()
{
	local TCHUD mmdxhud;
	if (isspec) 
	{
		mmdxhud = TCHUD(root.hud);
		if (mmdxhud.HUD_mode == 2) 
		{
			mmdxhud.HUD_mode = 0;
			mmdxhud.UpdateSettings(Player);
		}
	}

	// Play Cancel Sound
	PlaySound(Sound'Menu_Cancel', 0.25); 

	root.PopWindow();
}

defaultproperties
{
    ButtonNames(0)="Join UNATCO"
    ButtonNames(1)="Join NSF"
    ButtonNames(2)="Auto-assign"
    ButtonNames(3)="Spectate"
    buttonWidth=200
    buttonDefaults(0)=(Y=160,X=10,Action=MA_Custom,Key="JOIN_UNATCO"),
    buttonDefaults(1)=(Y=200,X=10,Action=MA_Custom,Key="JOIN_NSF"),
    buttonDefaults(2)=(Y=160,X=230,Action=MA_Custom,Key="JOIN_AUTO"),
    buttonDefaults(3)=(Y=200,X=230,Action=MA_Custom,Key="SPECTATE"),
    actionButtons(0)=(Action=AB_Other,text="Disconnect",Key="DISC",Align=HALIGN_RIGHT)
    actionButtons(1)=(Action=AB_Other,text="Close",Key="CANCEL") 
    actionButtons(2)=(Action=AB_Other,text="Settings",Key="SET")
    actionButtons(3)=(Action=AB_Other,text="Augs",Key="AUGS")
    actionButtons(4)=(Action=AB_Other,text="Servers",Key="DXSL")
    Title="Welcome to DXMP"
    ClientWidth=440
    ClientHeight=240
    bUsesHelpWindow=False
    bEscapeSavesSettings=False
    
   // ScreenType=0
}
