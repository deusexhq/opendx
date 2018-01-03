class PerkBoost extends Perks;

var int Count;

function PerkOn()
{
	SetTimer(1, True);

	PerkOwner.GroundSpeed *= 1.8;
	PerkOwner.mpGroundSpeed *= 1.8;
	PerkOwner.JumpZ *= 1.8;
	PerkOwner.UpdateAnimRate(1.8);		
}

function PerkOff()
{
	PerkOwner.GroundSpeed = PerkOwner.Default.mpGroundSpeed;
	PerkOwner.mpGroundSpeed = PerkOwner.Default.mpGroundSpeed;
	PerkOwner.JumpZ = PerkOwner.Default.JumpZ;
	PerkOwner.UpdateAnimRate( -1.0 );
}

function Timer()
{
	Count--;
	
	if(Count <= 5)
		PerkOwner.Notif("(Boost) "$Count$" seconds remaining.");
		
	if(Count <= 0)
		PerkOwner.RemovePerkbyName("Speed Boost");
}

defaultproperties
{
	Count=30
	PerkName="Speed Boost"
	PerkShortName="boost"
	bLock=True
}
