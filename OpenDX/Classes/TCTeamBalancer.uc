class TCTeamBalancer extends Actor config(OpenDX);

var() config bool          bEnabled;
var() config bool          bSwapNewPlayersFirst;
var() config float         CheckTime;
var() config int           MaxDifference;
var() config float         MessageTime;

var bool bDoBalance;
var bool bInit;


function PostBeginPlay()
{
	if (bInit) return;
	bInit = true;
    bDoBalance = false;
    if (MaxDifference < 0)
        MaxDifference = 1;
    if (CheckTime < 0)
        CheckTime = 15.0;
    SaveConfig();
    SetTimer(CheckTime, True);
}


function Timer()
{
    local int Diff;
    local string Text;

    if (DeathMatchGame(Level.Game) != None)
        return;

    if (bEnabled == false) return;

    // check balance
    Diff = CheckBalance();
    if (Diff == 0)
    {
        bDoBalance = false;
        return;
    }

    // if bDoBalance is true
    if (bDoBalance == true)
    {
        // do balancing
        BalanceTeams(Diff);

        // change bDoBalance to false so next time we only check teams
        bDoBalance = false;
    }
    else
    {
        Text = "Teams will be balanced in "$int(CheckTime)$" seconds.";
        PrintToAll(Text, false);
        // just change bDoBalance to true, so we balance teams next time
        bDoBalance = true;
    }
}


function int CheckBalance()
{
    local int NSF, UNATCO, i;
    local Pawn P;

    NSF = 0;
    UNATCO = 0;

    // count number of UNATCO and number of NSF players
    P = Level.PawnList;
 	while (i < Level.Game.NumPlayers)
	{
		if (P.IsA('PlayerPawn'))
		{
		    if (!P.PlayerReplicationInfo.bIsSpectator || !P.isInState('Spectating'))
		    {
                if (P.PlayerReplicationInfo.Team == 0) UNATCO++;
                else if (P.PlayerReplicationInfo.Team == 1) NSF++;
            }
			i++;
		}
		P = P.nextPawn;
	}

    if (UNATCO == NSF || (UNATCO + NSF) == 1)
        return 0;

    if (MaxDifference > 0 && ((NSF + MaxDifference) < UNATCO ||
        (UNATCO + MaxDifference) < NSF))
        return ((UNATCO - NSF) / 2);

    // other unknown combination???
    else
        return 0;
}


function int CheckTotalScore(int N)
{
    local int NSFScore, UNATCOScore, i;
    local Pawn P;

    NSFScore = 0;
    UNATCOScore = 0;

    // count NSF and UNATCO total scores
    P = Level.PawnList;
 	while (i < Level.Game.NumPlayers)
	{
		if (P.IsA('PlayerPawn'))
		{
            if (P.PlayerReplicationInfo.Team == 0)
                UNATCOScore += int(P.PlayerReplicationInfo.Score);
            else if (P.PlayerReplicationInfo.Team == 1)
                NSFScore += int(P.PlayerReplicationInfo.Score);

			i++;
		}
		P = P.nextPawn;
	}

    // equal scores, no balancing needed
    if (UNATCOScore == NSFScore)
        return 0;

    // if unatco has higher score and more players
    else if (UNATCOScore > NSFScore && N > 0)
        return 1;

    // if nsf has higher score and more players
    else if (NSFScore > UNATCOScore && N < 0)
        return -1;

    // other combination, dont do balancing!
    else
        return 0;
}


function BalanceTeams(int D)
{
    local int RemainingToSwap, i, MaxFrags, sw;
    local Pawn P;

    // D can be negative, but we need positive RemainingToSwap
    if (D > 0)
        RemainingToSwap = D;
    else if (D < 0)
        RemainingToSwap = (D)*(-1);
    else
        // should never happen
        return;

    if (bSwapNewPlayersFirst)
    {
        // check for new players and swap them
		sw = SwapPlayers(D, 0);
        RemainingToSwap -= sw;
		if (D > 0) D -= sw;
		else if (D < 0) D += sw;
    }

    if (RemainingToSwap == 0)
        return;

    // find top player, so we dont swap him
    P = Level.PawnList;
    MaxFrags = 0;
    i = 0;
    while (i < Level.Game.NumPlayers)
    {
        if (P.IsA('PlayerPawn'))
        {
            if (!P.PlayerReplicationInfo.bIsSpectator)
            {
	            if (D > 0 && P.PlayerReplicationInfo.Team == 0)
	            {
	                // assign new MaxFrags if we find player with higher score
                    if (P.PlayerReplicationInfo.Score > MaxFrags)
                        MaxFrags = int(P.PlayerReplicationInfo.Score);
                }
	            else if (D < 0 && P.PlayerReplicationInfo.Team == 1)
	            {
                    // assign new MaxFrags if we find player with higher score
                    if (P.PlayerReplicationInfo.Score > MaxFrags)
                        MaxFrags = int(P.PlayerReplicationInfo.Score);
                }
            }
            i++;
        }
        P = P.nextPawn;
    }

    // security check (in case of map begins and all players have score 0
    // set MaxFrags to 1 and just swap first appropriate player(s)
    if (MaxFrags == 0)
        MaxFrags = 1;

    // swap other players
    RemainingToSwap -= SwapPlayers(D, MaxFrags);

    // ooops, not all players could be swapped
    if (RemainingToSwap > 0)
        log("Failed to balance teams...", 'OpenDX');
}


function int SwapPlayers(int N, int Frags)
{
    local int i, Swapped;
    local Pawn P;
	local TCPRI mmp;

    Swapped = 0;
    i = 0;
    P = Level.PawnList;
    while (i < Level.Game.NumPlayers && N != 0)
    {
        if (P.IsA('PlayerPawn'))
        {
			mmp = TCPRI(P.PlayerReplicationInfo);
            if (mmp != none && !mmp.bIsSpectator && !P.isinState('Spectating'))
            {
                if (Frags > 0 || (P.PlayerReplicationInfo.Score == 0 &&
		            P.PlayerReplicationInfo.Deaths == 0))
                {
                    // if N > 0: swap to NSF
                    // if N < 0: swap to UNATCO
		            if (N > 0 && P.PlayerReplicationInfo.Team == 0 &&
                        (P.PlayerReplicationInfo.Score < Frags || Frags == 0))
                    {
                        SwapPlayer(P, 1);
                        Swapped++;
                        N--;
                    }
		            else if (N < 0 && P.PlayerReplicationInfo.Team == 1 &&
                        P.PlayerReplicationInfo.Score < Frags || Frags == 0)
                    {
                        SwapPlayer(P, 0);
                        Swapped++;
                        N++;
                    }
                }
            }
            i++;
		}
        P = P.nextPawn;
    }

    return Swapped;
}


function SwapPlayer(Pawn P, int T)
{
	local NavigationPoint startSpot;
	local bool foundStart;
	local TCPlayer DxP;
	local string Text, TP;

	DxP = TCPlayer(P);

    Text = "Switching player player "
        $DxP.PlayerReplicationInfo.PlayerName$
        " ("$DxP.PlayerReplicationInfo.PlayerID$") to ";
    TP = "You have been switched to ";

    if (T == 0)
    {
        Text = Text$"team UNATCO.";
        TP = TP$"team UNATCO.";
    }
    else
    {
        Text = Text$"team NSF.";
        TP = TP$"team NSF.";
    }

    PrintToAll(Text, true);

    DxP.PlayerReplicationInfo.Team = T;
    UpdateSkin(DxP, T);
	DxP.ClientSetTeam(T);
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
     PrintToPlayer(DxP, TP);
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


function PrintToAll(string TextToSay, bool uplink)
{
    local int i;
    local Pawn P;
    local TCPlayer mmp;
    local color rgb;

    rgb.G = 255;
    // print text to all clients
    P = Level.PawnList;
 	while (i < Level.Game.NumPlayers)
	{
		if (P.IsA('PlayerPawn'))
		{
	        if (uplink) P.ClientMessage(TextToSay, , true);
	        else
	        {
		        mmp = TCPlayer(P);
                if (mmp != none) mmp.ClientMessage(TextToSay);
            }
			i++;
		}
		P = P.nextPawn;
	}
}


function PrintToPlayer(DeusExPlayer dxp, string Message)
{
    local TCPlayer mmp;
    local color rgb;

    rgb.G = 255;
    mmp = TCPlayer(dxp);
    if (mmp != none) mmp.ClientMessage(Message);
}

defaultproperties
{
    bEnabled=True
    bSwapNewPlayersFirst=True
    checkTime=15.00
    MaxDifference=1
    MessageTime=5.00
    bHidden=True
    NetUpdateFrequency=1.00
}
