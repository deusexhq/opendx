class PerkIcarus extends Perks;

var bool bReverse, bTrig;

function PerkTick()
{	
	if(PerkOwner.Velocity.Z < -600 && !bReverse)
	{
		bTrig=True;
		bReverse=True;
		PerkOwner.ClientMessage("|P3Icarus landing system activated...");
	}
	
	if(bTrig)
	{
		if(bReverse)
			PerkOwner.Velocity.Z += 100;
		
		if(PerkOwner.Velocity.Z > 0)
		{
			bTrig=False;
			bReverse=False;
			PerkOwner.ClientMessage("|P3Icarus landing system de-activated...");
		}
	}
}

defaultproperties
{
	PerkName="Icarus Landing System"
	PerkShortName="Icarus"
}
