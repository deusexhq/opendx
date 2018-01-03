//================================================================================
// Auto-shutdown Actor
//================================================================================
class OSDActor extends Actor;

var bool bSDAt, bSDIn;

var int ShutdownInTime; //Shuts down in X minutes;
var string ShutdownAtTime; //Shutsdown at X time;

var int SDaMins, SDaHours;
var int SDInCur;
var bool bSDReady;
var bool bDebug;
var TCDeathmatch myDMGame;
var TCTeam myTDMGame;

function TCControls GetControls()
{
	local TCControls TCC;
	if(TCDeathmatch(Level.Game) != None) TCC = TCDeathMatch(Level.Game).Settings;
	if(TCTeam(Level.Game) != None) TCC = TCTeam(Level.Game).Settings;
	
	if(TCC == None)
		log("ERROR: SETTINGS NOT FOUND", 'OSDA');
		
	return TCC;
}

function PostBeginPlay()
{
	if(TCDeathMatch(level.game) != None)
	{
		TCDeathMatch(level.game).bSDFound=True;		
		myDMGame = TCDeathmatch(level.game);
		if(bDebug) log("Deathmatch found.",'OSDA');
	}
	
	if(TCTeam(level.game) != None)
	{
		TCTeam(level.game).bSDFound=True;		
		myTDMGame = TCTeam(level.game);
		if(bDebug) log("TeamDeathmatch found.",'OSDA');
	}
	super.PostBeginPlay();
}

function Destroyed() 
{
	if(myDMGame != None)
	{
		myDMGame.bSDFound=False;	
		myDMGame.SDStr = "";
		if(bDebug) log("Deathmatch found on Destroyed().",'OSDA');
	}
	
	if(TCTeam(level.game) != None)
	{
		myTDMGame.bSDFound=False;	
		myTDMGame.SDStr = "";
		if(bDebug) log("TeamDeathmatch found on Destroyed().",'OSDA');
	}
	super.Destroyed();
}

function SetSDStr(string str)
{
	if(myDMGame != None)
	{	
		myDMGame.SDStr = str;
	}
	
	if(TCTeam(level.game) != None)
	{
		myTDMGame.SDStr = str;
	}
}

function Timer()
{
	local string curtime;
	local int curmins, curhours;
	if(bSDReady)
	{
		Log("Server was closed due to OSDA System",'OpenDX');
		ConsoleCommand("exit");
	}
	
	if(bSDAt)
	{
		curtime = Level.hour $ ":" $ Level.minute;
		if(MinsRemain(60))
		{
			GetControls().Print("Sixty minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(50))
		{
			GetControls().Print("Fifty minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(40))
		{
			GetControls().Print("Fourty minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(30))
		{
			GetControls().Print("Thirty minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(20))
		{
			GetControls().Print("Twenty minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(15))
		{
			GetControls().Print("Fifteen minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(10))
		{
			GetControls().Print("Ten minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(5))
		{
			GetControls().Print("Five minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(4))
		{
			GetControls().Print("Four minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(3))
		{
			GetControls().Print("Three minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(2))
		{
			GetControls().Print("Two minutes remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(1))
		{
			GetControls().Print("One minute remains until scheduled shutdown at "$ShutdownAtTime);
		}
		if(MinsRemain(0))
		{
			GetControls().Print("Server will be closing shortly due to scheduled shutdown.");
			bSDReady=True;
		}
	}
	if(bSDIn)
	{
		SDInCur++;
		SetSDStr("Shuts down in "$ShutdownInTime - SDInCur);
		
		if(SDInCur == (ShutdownInTime - 60))
		{
			GetControls().Print("Sixty minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 50))
		{
			GetControls().Print("Fifty minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 40))
		{
			GetControls().Print("Forty minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 30))
		{
			GetControls().Print("Thirty minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 20))
		{
			GetControls().Print("Twenty minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 15))
		{
			GetControls().Print("Fifteen minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 10))
		{
			GetControls().Print("Ten minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 5))
		{
			GetControls().Print("Five minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 3))
		{
			GetControls().Print("Three minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 2))
		{
			GetControls().Print("Two minutes remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime - 1))
		{
			GetControls().Print("One minute remains until shutdown.");
		}
		if(SDInCur == (ShutdownInTime))
		{
			GetControls().Print("Server will be closing shortly....");
			bSDReady=True;
		}
	}
}

/*
 * if sd time is 1:00
 * 5 mins remain at 55
 * or if sd is 1:03
 * 5 mins remain at 58
 * so we need a var; remainder = Level.minutes (example: 5) then - the minsremaining
 * so 5 - 10 = -5
 * if under 0 then + 60 and - 1 hour
*/

//if 17 01
// m = 5
// 01 - 5 = -4
// -4 + 60 = 54 then hour becomes 16
// final result is 16 54
function bool MinsRemain(int m)
{
	local int ch, cm;
	local bool bLastHour;
	local string cmf;
	
	ch = SDAHours;
	cm = SDAMins;
	
	cm -= m;
	if(cm < 0)
	{
		cm += 60;
		ch -= 1;
		if(ch == -1)
			ch = 23;
		bLastHour=True;
	}
	
	if(cm == 60)
	{
		cm = 0;
		ch += 1;
		bLastHour=False;
	}
	
	if(bDebug)
		Log(Level.hour$":"$level.minute$" Checking: ["$bLastHour$"] "$ch$":"$cm$" against "$m$" remaining... "$SDAHours$":"$SDAMins$" ("$ShutdownAtTime$")");
	
	if(cm == Level.minute)
	{
			if(Level.Hour == ch)
			{
				if(bDebug)
					Log("Returning true");
				return true;
			}
	}
}

defaultproperties
{
    bHidden=true
}
