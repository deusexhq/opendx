class PerkNuke extends Perks;

function PerkOn()
{
	PerkOwner.bNuke=True;
}

function PerkOff()
{
	PerkOwner.bNuke=False;
}

defaultproperties
{
	PerkName="Death Nuke"
	PerkShortName="Nuke"
}
