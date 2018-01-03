class PerkQuad extends Perks;

var int Count;

function PerkOn()
{
	SetTimer(1, True);	
}

function PerkOff()
{
}

function Timer()
{
	Count--;
	
	if(Count <= 5)
		PerkOwner.Notif("(Quad) "$Count$" seconds remaining.");
		
	if(Count <= 0)
		PerkOwner.RemovePerkbyName("Quad Damage");
}

defaultproperties
{
	Count=30
	PerkName="Quad Damage"
	PerkShortName="quad"
	bLock=True
}
