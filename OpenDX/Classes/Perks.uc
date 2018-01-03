class Perks extends Actor;

var TCPlayer PerkOwner; //The player
var string PerkName; //Its name
var string PerkShortName; //For when the normal name is too long, make detection easier by using a smaller identifier
var bool bLock; //Can the /perk command disable it
var bool bOn; //Master on switch, will function if on unless sleep
var bool bSleep; //Disables the tick while staying on

function PostBeginPlay()
{
	if(PerkShortName == "")
		PerkShortName = PerkName;
}

function PerkSleep(float Delay) //Called when the perk needs to be temporarily disabled
{
	PerkOwner.ClientMessage("|P2"$PerkName$" has been temporarily disabled...");
	bSleep=True;
	SetTimer(Delay, False);
}

function Timer()
{
	if(PerkOwner != None && bSleep)
	{
		PerkOwner.ClientMessage("|P2"$PerkName$" has been recharged...");
		bSleep=False;
	}
}

function ToggleActivation() //Called by the Player activator
{
	if(bOn)
	{
		PerkOwner.ClientMessage("|P4"$PerkName$" de-activated.");
		PerkOff();
		bOn=False;
	}
	else
	{
		PerkOwner.ClientMessage("|P4"$PerkName$" activated.");
		PerkOn();
		bOn=True;
	}
}

function PerkOn() //called when activated
{}

function PerkOff() //called when de-activated
{}

function PerkTick() //called by tick if active
{}

function Tick(float Deltatime) //for passive effects, check if bOn and run code
{
	if( PerkOwner != None && bOn && !bSleep )
		PerkTick();
}

defaultproperties
{
	bHidden=True
}
