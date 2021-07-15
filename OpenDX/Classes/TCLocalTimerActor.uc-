class TCLocalTimerActor extends Actor;

var bool bRunning;
var int min, sec;
var TCPlayer TimerPlayer;

function StartTimer()
{
	min = 0;
	sec = 0;
	
	TimerPlayer.StartTimer();

	bRunning=True;
	SetTimer(1,True);
}

function StopTimer()
{
	TimerPlayer.StopTimer();
	bRunning=false;
	Destroy();
}

function UpdateTimer(string str)
{
	
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
	
	TimerPlayer.UpdateTimer(finaltime);
	TimerPlayer.TimerString=finaltime;
	//UpdateTimer(finaltime);
}

defaultproperties
{
	bHidden=True;
}
