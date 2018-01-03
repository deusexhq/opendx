class TCHUDLogDisplay extends HUDLogDisplay;

var texture TextLogo;

function CreateControls()
{
	// Create the icon in the upper left corner
	winIcon = NewChild(Class'Window');
	winIcon.SetSize(16, 16);
	winIcon.SetPos(logMargin * 2, topMargin + 5);
	winIcon.SetBackgroundStyle(DSTY_Masked);
	winIcon.SetBackground(Texture'DeusExSmallIcon');

	// Create the text log
	winLog = TextLogWindow(NewChild(Class'TextLogWindow'));
	winLog.SetTextAlignments(HALIGN_Left, VALIGN_Top);
	winLog.SetTextMargins(0, 0);
	winLog.SetFont(fontLog);
	winLog.SetLines(MinLogLines, MaxLogLines);
}

function AddLog(coerce String newLog, Color linecol)
{
	local DeusExRootWindow root;
	local PersonaScreenBaseWindow winPersona;

	if ( newLog != "" )
	{
		root = DeusExRootWindow(GetRootWindow());

		// If a PersonaBaseWindow is visible, send the log message 
		// that way as well.

		winPersona = PersonaScreenBaseWindow(root.GetTopWindow());
		if (winPersona != None)
			winPersona.AddLog(newLog);

		// If the Hud is not visible, then pause the log
		// until we become visible again
		//
		// Don't show the log if a DataLink is playing

		if (( GetParent().IsVisible() ) && ( root.hud.infolink == None ))
		{
			Show();
		}
		else
		{
			bMessagesWaiting = True;
			winLog.PauseLog( True );
		}

		bTickEnabled = TRUE;
		winLog.AddLog(newLog, linecol);
		lastLogMsg = 0.0;
		AskParentForReconfigure();
	}
}


defaultproperties
{
	minLogLines=2
}
