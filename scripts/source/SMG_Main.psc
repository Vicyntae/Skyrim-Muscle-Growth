ScriptName SMG_Main Extends Quest

float Property StrengthStatOverride Auto
actor Property PlayerRef Auto
SMG_MCM Property MCM Auto
Event OnInit()
  RegisterForSingleUpdateGameTime(0.01)
  RegisterForSleep()
EndEvent

Event OnSleepStop(bool abInterrupted)
  UpdateStrength()
  RegisterForSingleUpdateGameTime(MCM.DailyUpdateTime)
EndEvent

Float Function UpdateStrength()
  MCM.UpdateAllLayerMorphs(PlayerRef)
EndFunction

Event OnUpdateGameTime()
  ;Debug.Notification("Updating player strength. New strength = " + UpdateStrength())
  UpdateStrength()
  RegisterSpecificTimeUpdate(MCM.DailyUpdateTime)
EndEvent

Function RegisterSpecificTimeUpdate(Float TimeOfDayEvent)
  ; Taken from https://forums.nexusmods.com/index.php?/topic/2602204-script-to-run-daily-in-game-time/
  float currentTime = Utility.GetCurrentGameTime()
  currentTime = 24.0 * (currentTime - (CurrentTime as Int))
  If currentTime < TimeOfDayEvent
    RegisterForSingleUpdateGameTime(TimeOfDayEvent - currentTime)
  Else
    RegisterForSingleUpdateGameTime(TimeOfDayEvent - currentTime + 24)
  EndIf
EndFunction

Float Function MapRange(Float n, Float From1, Float To1, Float From2, Float To2)
  return (n - from1) / (To1 - from1) * (To2 - From2) + From2
EndFunction
