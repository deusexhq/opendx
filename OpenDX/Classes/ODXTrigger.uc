//=============================================================================
//ODX - parent class.
//======================================

class ODXTrigger extends Trigger abstract;

var(Events) class<Actor> LimitingClass;

function Trigger(Actor other,Pawn instigator)
{
	BeenTriggeredODX(TCPlayer(instigator));
	if(bTriggerOnceOnly)
		Destroy();
}

function Touch(Actor other)
{
	if(IsRelevant(other))
	{
		BeenTriggeredODX(TCPlayer(other));
		if(bTriggerOnceOnly)
			Destroy();
	}
}

function BeenTriggeredODX(TCPlayer instigator)
{} //set by subclasses

defaultproperties
{
     LimitingClass=Class'Engine.Actor'
    // Texture=Texture'MoreTriggersIcon'
}
