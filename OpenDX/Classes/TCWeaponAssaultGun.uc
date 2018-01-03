class TCWeaponAssaultGun extends WeaponAssaultGun;

// fix bug related to firing when having no weapon in hand
simulated function bool ClientFire( float value )
{
	if (DeusExPlayer(Owner) != none && DeusExPlayer(Owner).inHand != self) return false;
	return super.ClientFire(value);
}

defaultproperties
{
    ProjectileNames(1)=Class'TCHECannister20mm'
}
