class PerkSpy extends Perks;

function PerkOn()
{
	TCPRI(PerkOwner.PlayerReplicationInfo).bSpy = True;
}

function PerkOff()
{
	TCPRI(PerkOwner.PlayerReplicationInfo).bSpy = False;
}

defaultproperties
{
	PerkName="Spy"
}
