ScriptName SMG_Tracker extends ActiveMagicEffect

SMG_MCM Property SMG Auto

Actor Target

Event OnEffectStart(Actor akTarget, Actor akCaster)
    ;Debug.Notification("Effect Start: " + akTarget.GetActorBase().GetName())
    Target = akTarget
    PO3_Events_AME.RegisterForSkillIncrease(self)
    PO3_Events_AME.RegisterForLevelIncrease(self)
    RegisterForModEvent("SMG_AllActorsUpdated", "OnAllActorsUpdated")
    RegisterForModEvent("SMG_MorphRemoved", "OnMorphRemoved")
    SMG.AddTrackedActor(Target)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    SMG.RemoveTrackedActor(Target)
EndEvent

Event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
    SMG.UpdateAllLayerMorphs(Target)
EndEvent

Event OnSkillIncrease(String asSkill)
    SMG.UpdateAllLayerMorphs(Target)
EndEvent

Event OnAllActorsUpdated()
    ;Debug.Notification("Updating Actor: " + Target.GetActorBase().GetName())
    SMG.UpdateAllLayerMorphs(Target)
EndEvent

Event OnLevelIncrease(int aiLevel)
    SMG.UpdateAllLayerMorphs(Target)
EndEvent

Function OnMorphRemoved(String MorphString, String MorphType)
    SMG.RemoveMorph(Target, MorphString, MorphType)
  EndFunction