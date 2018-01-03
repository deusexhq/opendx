class TCTimerActor extends Actor;

var bool bRunning;
var int min, sec;

function ToggleTimer()
{
	if(bRunning)
		StopTimer();
	else
		StartTimer();
}

function StartTimer()
{
	local TCPlayer TCP;
	
	min = 0;
	sec = 0;
	
	foreach AllActors(class'TCPlayer', TCP)
		TCP.StartTimer();
	
	Log("Timer started.",'OpenDX');
	bRunning=True;
	SetTimer(1,True);
}

function StopTimer()
{
	local TCPlayer TCP;
	
	foreach AllActors(class'TCPlayer', TCP)
		TCP.StopTimer();
	
	Log("Timer stopped.",'OpenDX');
	bRunning=false;
}

function UpdateTimer(string str)
{
	local TCPlayer TCP;
	
	foreach AllActors(class'TCPlayer', TCP)
	{
		TCP.UpdateTimer(str);
		TCP.TimerString=str;
	}

	if(!bRunning)
	SetTimer(1,False);
}

function Timer()
{
	local string finaltime, localsec;
	
	sec++;
	
	if(sec < 10)
		localsec = "0"$sec;
		
	if(sec > 60)
	{
		sec = 1;
		localsec = "01";
		min++;
	}
	
	if(localsec == "")
		localsec = string(sec);
	finaltime = min$":"$localsec;
	
	UpdateTimer(finaltime);
}

defaultproperties
{
	bHidden=True;
}
