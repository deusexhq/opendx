//=============================================================================
// MenuMain
//=============================================================================

class TCMenuMain expands MenuUIMenuWindow;

// ----------------------------------------------------------------------
// InitWindow()
//
// Initialize the Window
// ----------------------------------------------------------------------

event InitWindow()
{
	Super.InitWindow();

	UpdateButtonStatus();
	ShowVersionInfo();
}

// ----------------------------------------------------------------------
// UpdateButtonStatus()
// ----------------------------------------------------------------------
function UpdateButtonStatus()
{
//Do nothing
}

// ----------------------------------------------------------------------
// ShowVersionInfo()
// ----------------------------------------------------------------------

function ShowVersionInfo()
{
	local TextWindow version;

	version = TextWindow(NewChild(Class'TextWindow'));
	version.SetTextMargins(0, 0);
	version.SetWindowAlignments(HALIGN_Right, VALIGN_Bottom);
	version.SetTextColorRGB(255, 255, 255);
	version.SetTextAlignments(HALIGN_Right, VALIGN_Bottom);
	version.SetText("[DEVELOPMENT]");
}

function ProcessCustomMenuButton(string key)
{
	switch(key)
	{
		case "TOGGLESPECTATE":
			TCPlayer(Player).ToggleSpectate();
			CancelScreen();
			break;
			
		case "DISCONNECT":
			Player.DisconnectPlayer();
			break;
		case "RECONNECT":
			TCPlayer(Player).ConsoleCommand("Reconnect");
			break;

	}
}
// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

defaultproperties
{
     Title="TheClown's MTL : Main Menu"
    ButtonNames(0)="Settings"
    ButtonNames(1)="Toggle Spectate"
    ButtonNames(2)="MTL Server List"
	ButtonNames(3)="Close Menu"
	ButtonNames(4)="Disconnect"
	ButtonNames(5)="Reconnect"
	ButtonNames(6)="Quit Deus Ex"
    buttonXPos=7
    buttonWidth=245
    buttonDefaults(0)=(Y=13,Invoke=Class'TCMenuGame')
    buttonDefaults(1)=(Y=49,Action=MA_Custom,Key="TOGGLESPECTATE")
	buttonDefaults(2)=(Y=85,Invoke=Class'mtlmenuscreenjoininternet',)
    buttonDefaults(3)=(Y=121,Action=MA_PREVIOUS)
    buttonDefaults(4)=(Y=157,Action=MA_Custom,Key="Disconnect")
	buttonDefaults(5)=(Y=193,Action=MA_Custom,Key="Reconnect")
    buttonDefaults(6)=(Y=229,Action=MA_Quit)
    ClientWidth=258
    ClientHeight=270
	    verticalOffset=2
    clientTextures(0)=Texture'DeusExUI.UserInterface.MenuMainBackground_1'
    clientTextures(1)=Texture'DeusExUI.UserInterface.MenuMainBackground_2'
    clientTextures(2)=Texture'DeusExUI.UserInterface.MenuMainBackground_3'
    textureCols=2
}
