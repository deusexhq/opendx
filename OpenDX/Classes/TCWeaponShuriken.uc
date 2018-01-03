class TCWeaponShuriken extends CBPWeaponShuriken;

// fix bug related to firing when having no weapon in hand
simulated function bool ClientFire( float value )
{
	if (DeusExPlayer(Owner) != none && DeusExPlayer(Owner).inHand != self) return false;
	return super.ClientFire(value);
}

defaultproperties
{
}
