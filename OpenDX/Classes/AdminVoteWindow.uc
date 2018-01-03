class AdminVoteWindow expands MenuUIWindow;

enum EMessageBoxModes
{
	MB_YesNo,
	MB_OK,
};

enum EMessageBoxResults
{
	MR_Yes,
	MR_No,
	MR_OK
};

var Color colTextMessage;
var bool bForced;
var DXL Caller;
var MenuUIActionButtonWindow btnYes;
var MenuUIActionButtonWindow btnNo;
var MenuUIHeaderWindow winText;
var int  mbMode;
var bool bDeferredKeyPress;
var bool bKeyPressed;
var Window winNotify;
var int textBorderX;
var int textBorderY;
var int numButtons;
var localized string btnLabelYes;
var localized string btnLabelNo;

event InitWindow()
{
	Super.InitWindow();
	// Don't show if match has ended
	if (( DeusExMPGame(Player.DXGame) != None ) && DeusExMPGame(Player.DXGame).bClientNewMap )
		return;
	// Force the title bar to be a certain width;
	winTitle.minTitleWidth = 250;

	CreateTextWindow();
	SetTitle("MapVote");
	SetMode(0);
	SetNotifyWindow(Self);
}

function CreateTextWindow()
{
	winText = CreateMenuHeader(21, 13, "", winClient);
	winText.SetTextAlignments(HALIGN_Center, VALIGN_Center);
	winText.SetFont(Font'FontMenuHeaders_DS');
	winText.SetWindowAlignments(HALIGN_Full, VALIGN_Full, textBorderX, textBorderY);
}

function SetMessageText( String msgText )
{
	winText.SetText(msgText);

	AskParentForReconfigure();
}

function SetDeferredKeyPress(bool bNewDeferredKeyPress)
{
	bDeferredKeyPress = bNewDeferredKeyPress;
}

function SetMode( int newMode )
{
	mbMode = newMode;

	switch( mbMode )
	{
		case 0:			// MB_YesNo:
			btnNo  = winButtonBar.AddButton(btnLabelNo, HALIGN_Right);
			btnYes = winButtonBar.AddButton(btnLabelYes, HALIGN_Right);
			numButtons = 2;
			SetFocusWindow(btnYes);
			break;
	}

	if (winShadow != None)
		MenuUIMessageBoxShadowWindow(winShadow).SetButtonCount(numButtons);
}

function int GetNumButtons()
{
	return numButtons;
}

function SetNotifyWindow( Window newWinNotify )
{
	winNotify = newWinNotify;
}

function bool ButtonActivated( Window buttonPressed )
{
	local bool bHandled;

	bHandled = True;

	Super.ButtonActivated(buttonPressed);

	switch( buttonPressed )
	{
		case btnYes:
			if ((bDeferredKeyPress) && (IsKeyDown(IK_Enter) || IsKeyDown(IK_Space) || IsKeyDown(IK_Y)))
				bKeyPressed = True;
			else
				PostResult(1);  // MR_Yes;

			bHandled = True;
			break;

		case btnNo:
			PostResult(0);
			break;

		default:
			bHandled = False;
			break;
	}

	return bHandled;
}

event bool MouseButtonReleased(float pointX, float pointY, EInputKey button, int numClicks)
{
	return True;
}

event bool VirtualKeyPressed(EInputKey key, bool bRepeat)
{
	local bool bHandled;

	switch( key )
	{

        case IK_Escape:
			if ( mbMode == 0  /*MB_YesNo*/ )
			{
				PostResult(0);
				bHandled = True;
			}
			break;

		case IK_Enter:
			if ( mbMode == 0  /*MB_YesNo*/ )
			{
				PostResult(1);
				bHandled = True;
			}
			break;

		case IK_Y:
			if ( mbMode == 0  /*MB_YesNo*/ )
			{
				PostResult(1);
				bHandled = True;
			}
			break;

		case IK_N:
			if ( mbMode == 0  /*MB_YesNo*/ )
			{
				PostResult(0);
				bHandled = True;
			}
			break;
	}

	return bHandled;
}

event bool RawKeyPressed(EInputKey key, EInputState iState, bool bRepeat)
{
	if (((key == IK_Enter) || (key == IK_Space) || (key == IK_Y)) &&
	   ((iState == IST_Release) && (bKeyPressed)))
	{
		PostResult(0);
		return True;
	}
	else
	{
		return false;
	}
}

function PostResult( int buttonNumber )
{
	if(ButtonNumber==0)
	{
        Caller.ClientAdminVote(False);
    }
    else if(ButtonNumber==1)
	{
        Caller.ClientAdminVote(True);
    }
    root.PopWindow();
	root.ClearWindowStack();
}

defaultproperties
{
    textBorderX=20
    textBorderY=14
    btnLabelYes="|&Yes"
    btnLabelNo="|&No"
    ClientWidth=280
    ClientHeight=85
    clientTextures(0)=Texture'DeusExUI.UserInterface.MenuMessageBoxBackground_1'
    clientTextures(1)=Texture'DeusExUI.UserInterface.MenuMessageBoxBackground_2'
    textureRows=1
    textureCols=2
    bActionButtonBarActive=True
    bUsesHelpWindow=False
    winShadowClass=Class'DeusEx.MenuUIMessageBoxShadowWindow'
}
