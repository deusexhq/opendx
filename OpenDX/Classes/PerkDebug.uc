class PerkDebug extends Perks;
var int db;

function PerkOn()
{
	PerkOwner.ClientMessage("Debug perk activated.");
}

function PerkOff()
{
	PerkOwner.ClientMessage("Debug perk de-activated.");
}

function PerkTick()
{
	db += 1;
	
	if(db % 10 == 0)
	PerkOwner.ClientMessage("The perk is debugging.");
}

defaultproperties
{
	PerkName="Debugger"
}
