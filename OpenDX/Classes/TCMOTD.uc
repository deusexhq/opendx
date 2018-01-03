class TCMOTD extends Info config(OpenDX);

var config string MOTDText[8];

replication
{
	reliable if (ROLE == ROLE_Authority)
 		OpenMenu;
	reliable if ((ROLE == ROLE_Authority) && (bNetOwner))
	    MOTDText;
}

function PostBeginPlay()
{
    SaveConfig();
    SetTimer(1.2, false);
}

function Timer()
{
    local TCPlayer mmp;

    mmp = TCPlayer(Owner);
    if (mmp != none)
    {
        OpenMenu(mmp, mmp.PlayerReplicationInfo.bIsSpectator);
    }
}

simulated function OpenMenu(TCPlayer P, optional bool bSpectator)
{
    local DeusExRootWindow W;
    local TCEMenu nw;

	P.ConsoleCommand("FLUSH");
    W = DeusExRootWindow(P.RootWindow);
    nw = TCEMenu(W.InvokeMenuScreen(Class'TCEMenu', True));
	if (nw != none) 
	{
		nw.bSpect = bSpectator;
		nw.CreateMenuButtons();
		nw.SetMOTDText(MOTDText);
	}
}

defaultproperties
{
    MOTDText(0)="Hello..."
    MOTDText(7)="---"
    RemoteRole=2
    bAlwaysRelevant=True
    NetPriority=1.40
    NetUpdateFrequency=2.00
}
