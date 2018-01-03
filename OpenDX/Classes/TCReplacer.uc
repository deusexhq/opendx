class TCReplacer extends CBPMutator config(OpenDX);

var config class<Actor> toReplace[32];
var config class<Actor> replaceTo[32];

function AddMutator(Mutator M)
{
    if(M.Class != class)
      super.AddMutator(M);
}

function PostBeginPlay()
{
	local Actor act;

	super.PostBeginPlay();
	
	foreach AllActors(class'Actor', act)
	{
		ReplaceMapItem(act, act.class);
	}
	/*DelTG();
	ReplaceTurrets();
	ReplaceComs();*/
}

function ReplaceMapItem(out Actor in, Class<Actor> inClass)
{
    local Actor act;
    local Inventory inv;
    local int i;
    local bool bFound;

    for (i = 0; i < ArrayCount(toReplace); i++)
    {
        if (inClass == toReplace[i])
        {
            bFound = true;
            break;
        }
    }
    if (bFound)
    {
		if (replaceTo[i] != none)
		{
			act = Spawn(replaceTO[i],in.owner,in.tag,in.location,in.Rotation);
			if (act != none)
			{
				//log("replacing"@in@"with"@act);
				act.SetPhysics(in.Physics);
				inv = Inventory(act);
				if (inv != none) 
				{
            		inv.RespawnTime = Inventory(in).RespawnTime;
					if (Weapon(inv) != none && Weapon(in) != none)
						Weapon(inv).SetCollisionSize(in.CollisionRadius, in.CollisionHeight);
				}
				if (AutoTurret(act) != none)
					AutoTurret(act).titleString = AutoTurret(in).titleString;
				in.Destroy();
				in=act;
			}
		}
		else
		{
			in.Destroy();
			in = none;
			return;
		}
    }
}

function SpawnNotification(out Actor in, Class<Actor> inClass)
{
	ReplaceMapItem(in, inClass);
	super.ReplaceMapItem(in, inClass);
    super.SpawnNotification(in, inClass);
}

function ImportSecParams(TCComputerSecurity NewSec, ComputerSecurity OldSec)
{
	local int cameraIndex;

	for (cameraIndex=0; cameraIndex<ArrayCount(OldSec.Views); cameraIndex++)
	{
		NewSec.Views[cameraIndex].cameraTag = oldSec.Views[cameraIndex].cameraTag;
		NewSec.Views[cameraIndex].turretTag = oldSec.Views[cameraIndex].turretTag;
		NewSec.Views[cameraIndex].doorTag = oldSec.Views[cameraIndex].doorTag;
	}
}

function DelTG()
{
    local Actor act, oldact;
	
	foreach AllActors(class'Actor', act)
	{
		//if(act.class == class'AutoTurretGun')
		//	act.Destroy();
		if(act.class == class'AutoTurretGun')
		{
			act.Destroy();			
		}
		
	}
}

function ReplaceTurrets()
{
    local Actor act, oldact;
    local Inventory inv;
    local int i;
    local bool bFound;
	local TCAutoTurret MMAT;

	
	foreach AllActors(class'Actor', act)
	{
		if(act.class == class'AutoTurret')
		{
			MMAT = Spawn(class'TCAutoTurret',act.owner,act.tag,act.location,act.Rotation);
			MMAT.Tag = act.Tag;
			MMAT.DrawScale = act.DrawScale;
			MMAT.TitleString = TCAutoTurret(act).TitleString;
			MMAT.SetPhysics(act.Physics);
			act.Destroy();			
		}
		
	}
}

function ReplaceComs()
{
    local Actor act;
    local Inventory inv;
    local int i;
    local bool bFound;
	local TCComputerSecurity TCCS;
	local ComputerSecurity CS;
	
	foreach AllActors(class'Actor', act)
	{
		if(act.class == class'ComputerSecurity')
		{
			TCCS = Spawn(class'TCComputerSecurity',act.owner,act.tag,act.location,act.Rotation);
			TCCS.DrawScale = act.DrawScale;
			TCCS.SetPhysics(PHYS_None);
			
			for (i=0; i<3; i++)
			{
				TCCS.Views[i].titleString = ComputerSecurity(act).Views[i].titleString;
				TCCS.Views[i].cameraTag = ComputerSecurity(act).Views[i].cameraTag;
				TCCS.Views[i].turretTag = ComputerSecurity(act).Views[i].turretTag;
				TCCS.Views[i].doorTag = ComputerSecurity(act).Views[i].doorTag;
			}
			act.Destroy();
		}
	}
}

defaultproperties
{
toReplace(0)=Class'DeusEx.WeaponAssaultShotgun'
toReplace(1)=Class'DXMTL152b1.CBPWeaponPistol'
toReplace(2)=Class'DeusEx.WeaponStealthPistol'
toReplace(3)=Class'DeusEx.WeaponAssaultGun'
toReplace(4)=Class'DeusEx.WeaponPlasmaRifle'
toReplace(5)=Class'DeusEx.WeaponNanoSword'
toReplace(6)=Class'DXMTL152b1.CBPWeaponShuriken'
toReplace(7)=Class'DeusEx.WeaponCombatKnife'
toReplace(8)=Class'DeusEx.WeaponMiniCrossbow'
toReplace(9)=Class'DeusEx.WeaponSawedOffShotgun'
toReplace(10)=Class'DXMTL152b1.CBPWeaponGEPGun'
toReplace(11)=Class'DeusEx.WeaponLAW'
toReplace(12)=Class'DXMTL152b1.CBPWeaponRifle'
toReplace(13)=Class'DeusEx.WeaponLAM'
toReplace(14)=Class'DeusEx.WeaponGasGrenade'
toReplace(15)=Class'DeusEx.WeaponEMPGrenade'
toReplace(16)=Class'DeusEx.WeaponFlamethrower'
replaceTo(0)=Class'OpenDX.TCWeaponAssaultShotgun'
replaceTo(1)=Class'OpenDX.TCWeaponPistol'
replaceTo(2)=Class'OpenDX.TCWeaponStealthPistol'
replaceTo(3)=Class'OpenDX.TCWeaponAssaultGun'
replaceTo(4)=Class'OpenDX.TCWeaponPlasmaRifle'
replaceTo(5)=Class'OpenDX.TCWeaponNanoSword'
replaceTo(6)=Class'OpenDX.TCWeaponShuriken'
replaceTo(7)=Class'OpenDX.TCWeaponCombatKnife'
replaceTo(8)=Class'OpenDX.TCWeaponMiniCrossbow'
replaceTo(9)=Class'OpenDX.TCWeaponSawedOffShotgun'
replaceTo(10)=Class'OpenDX.TCWeaponGEPGun'
replaceTo(11)=Class'OpenDX.TCWeaponLAW'
replaceTo(12)=Class'OpenDX.TCWeaponRifle'
replaceTo(13)=Class'OpenDX.TCWeaponLAM'
replaceTo(14)=Class'OpenDX.TCWeaponGasGrenade'
replaceTo(15)=Class'OpenDX.TCWeaponEMPGrenade'
replaceTo(16)=Class'OpenDX.TCWeaponFlamethrower'
}
