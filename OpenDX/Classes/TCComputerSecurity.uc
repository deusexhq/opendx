//=============================================================================
// ComputerSecurity.
//=============================================================================
class TCComputerSecurity extends Computersecurity;

struct sViewInfo
{
	var() localized string	titleString;
	var() name				cameraTag;
	var() name				turretTag;
	var() name				doorTag;
};

var() localized sViewInfo Views[3];
var int team;
var string TeamName;

// ----------------------------------------------------------------------------
// network replication
// ----------------------------------------------------------------------------
replication
{
   //server to client
   reliable if (Role == ROLE_Authority)
      Views, team, TeamName;
}

// -----------------------------------------------------------------------
// SetControlledObjectOwners
// Used to enhance network replication.
// -----------------------------------------------------------------------

function SetControlledObjectOwners(DeusExPlayer PlayerWhoOwns)
{
	local int cameraIndex;
	local name tag;
	local SecurityCamera camera;
   local TCAutoTurret turret;
   local DeusExMover door;

	for (cameraIndex=0; cameraIndex<ArrayCount(Views); cameraIndex++)
	{
		tag = Views[cameraIndex].cameraTag;
		if (tag != '')
			foreach AllActors(class'SecurityCamera', camera, tag)
				camera.SetOwner(PlayerWhoOwns);

		tag = Views[cameraIndex].turretTag;
		if (tag != '')
			foreach AllActors(class'TCAutoTurret', turret, tag)
            {
				if(TCDeathmatch(level.game) != None)
					turret.teamstring = TCPRI(PlayerWhoOwns.PlayerReplicationInfo).TeamNamePRI;
				turret.SetOwner(PlayerWhoOwns);
			}
				
		tag = Views[cameraIndex].doorTag;
		if (tag != '')
			foreach AllActors(class'DeusExMover', door, tag)
				door.SetOwner(PlayerWhoOwns);

	}

}

// ----------------------------------------------------------------------
// AdditionalActivation()
// Called for subclasses to do any additional activation steps.
// ----------------------------------------------------------------------

function AdditionalActivation(DeusExPlayer ActivatingPlayer)
{
   if (Level.NetMode != NM_Standalone)
      SetControlledObjectOwners(ActivatingPlayer);
   
   Super.AdditionalDeactivation(ActivatingPlayer);
}

// ----------------------------------------------------------------------
// AdditionalDeactivation()
// ----------------------------------------------------------------------

function AdditionalDeactivation(DeusExPlayer DeactivatingPlayer)
{
   if (Level.NetMode != NM_Standalone)
      SetControlledObjectOwners(None);
   
   Super.AdditionalDeactivation(DeactivatingPlayer);
}



defaultproperties
{
    TeamName=""
	Team=-1
	Physics=PHYS_None
    terminalType=Class'NetworkTerminalSecurity'
    lockoutDelay=120.00
    UserList=(accountNumber="SECURITY",PIN="SECURITY",balance=1918989824),
    ItemName="Security Computer Terminal"
    Physics=0
    Mesh=LodMesh'DeusExDeco.ComputerSecurity'
    SoundRadius=8
    SoundVolume=255
    SoundPitch=96
    AmbientSound=Sound'DeusExSounds.Generic.SecurityL'
    CollisionRadius=11.59
    CollisionHeight=10.10
    bCollideWorld=False
    BindName="ComputerSecurity"
}
