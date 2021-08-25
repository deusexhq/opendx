//=============================================================================
// SecurityBot2.
//=============================================================================
class MountMech extends Mountable;

enum ESkinColor
{
	SC_UNATCO,
	SC_Chinese
};

var() ESkinColor SkinColor;

function BeginPlay()
{
	Super.BeginPlay();

	switch (SkinColor)
	{
		case SC_UNATCO:		Skin = Texture'MilitaryBotTex1'; break;
		case SC_Chinese:	Skin = Texture'MilitaryBotTex2'; break;
	}
}

defaultproperties
{
     EMPHitPoints=100
     explosionSound=Sound'DeusExSounds.Robot.SecurityBot2Explode'
     WalkingSpeed=1.000000
     WalkSound=Sound'DeusExSounds.Robot.SecurityBot2Walk'
     GroundSpeed=9500.000000
     WaterSpeed=50.000000
     AirSpeed=144.000000
     AccelRate=500.000000
     Health=250
     UnderWaterTime=20.000000
     DrawType=DT_Mesh
     Mesh=LodMesh'DeusExCharacters.MilitaryBot'
     CollisionRadius=80.000000
     CollisionHeight=79.000000
     Mass=800.000000
     Buoyancy=100.000000
     ItemName="Mech"
}
