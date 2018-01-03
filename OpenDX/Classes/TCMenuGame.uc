//=============================================================================
// MenuMain
//=============================================================================

class TCMenuGame expands MenuUIMenuWindow;

// ----------------------------------------------------------------------
// InitWindow()
//
// Initialize the Window
// ----------------------------------------------------------------------

event InitWindow()
{
	Super.InitWindow();
	ShowVersionInfo();
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

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

defaultproperties
{
     Title="Config"
	ButtonNames(0)="Keyboard"
    ButtonNames(1)="Controls"
	ButtonNames(2)="Game"
	ButtonNames(3)="Display"
	ButtonNames(4)="Colours"
    ButtonNames(5)="Sound"
	ButtonNames(6)="Player Settings"
	ButtonNames(7)="Augmentations"
	ButtonNames(8)="Cancel"
    buttonXPos=7
    buttonWidth=245
    buttonDefaults(0)=(Y=13,Invoke=Class'CBPMenuScreenCustomizeKeys',Key="")
    buttonDefaults(1)=(Y=49,Invoke=Class'MenuScreenControls',Key="")
    buttonDefaults(2)=(Y=85,Invoke=Class'MenuScreenOptions',Key="")
    buttonDefaults(3)=(Y=121,Invoke=Class'MenuScreenDisplay',Key="")
    buttonDefaults(4)=(Y=157,Invoke=Class'MenuScreenAdjustColors',Key="")
    buttonDefaults(5)=(Y=193,Invoke=Class'MenuScreenSound',Key="")
	buttonDefaults(6)=(Y=229,Invoke=Class'MTLmenuscreenplayersetup')
    buttonDefaults(7)=(Y=265,Invoke=class'CBPmenuscreenaugsetup')
	buttonDefaults(8)=(Y=301,Action=MA_PREVIOUS)
    ClientWidth=258
    ClientHeight=345
	    verticalOffset=2
    clientTextures(0)=Texture'DeusExUI.UserInterface.MenuMainBackground_1'
    clientTextures(1)=Texture'DeusExUI.UserInterface.MenuMainBackground_2'
    clientTextures(2)=Texture'DeusExUI.UserInterface.MenuMainBackground_3'
    textureCols=2
}
