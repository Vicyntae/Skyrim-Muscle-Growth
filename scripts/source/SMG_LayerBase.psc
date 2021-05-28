ScriptName SMG_LayerBase Extends ReferenceAlias
String Property LayerName Auto
SMG_MCM Property MCM Auto
String[] Property STRUCT_MorphInfo Auto
;/Format:
0: Morph string
1: Enable Morph
2: Morph Sex
  "$SMGMale"
  "$SMGFemale"
  "$SMGOther" Unused
3: Morph Type
  "$SMGBodyMorphs"
  "$SMGBoneScaleMorphs"
  "$SMGSpecialMorphs"
4: Min Value
5: Max Value
6: Interpolation Method
/;

String[] Property STRUCT_SkillInfo Auto
;/Format:
0: ActorValueString
1: Skill Weight
2: Display Name
/;
Float Property SkillCeiling = 100.0 Auto
Float Property BaseStatCeiling = 500.0 Auto
Int Property LevelCeiling = 75 Auto

Float Property PlayerLastValue = 0.0 Auto
Float AlphaRatePerMinute = 0.05
Float PreviousAlpha = 0.0

;/ Event OnInit()
  STRUCT_SkillInfo = New String[22]

  SetSkillVars(0, "OneHanded", 0.0, "$SMGSkillOneHanded")
  SetSkillVars(1, "TwoHanded", 0.0, "$SMGSkillTwoHanded")
  SetSkillVars(2, "Marksman", 0.0, "$SMGSkillMarksman")
  SetSkillVars(3, "Block", 0.0, "$SMGSkillBlock")
  SetSkillVars(4, "Smithing", 0.0, "$SMGSkillSmithing")
  SetSkillVars(5, "HeavyArmor", 0.0, "$SMGSkillHeavyArmor")
  SetSkillVars(6, "LightArmor", 0.0, "$SMGSkillLightArmor")
  SetSkillVars(7, "Pickpocket", 0.0, "$SMGSkillPickpocket")
  SetSkillVars(8, "Lockpicking", 0.0, "$SMGSkillLockpicking")
  SetSkillVars(9, "Sneak", 0.0, "$SMGSkillSneak")
  SetSkillVars(10, "Alchemy", 0.0, "$SMGSkillAlchemy")
  SetSkillVars(11, "Speechcraft", 0.0, "$SMGSkillSpeechcraft")
  SetSkillVars(12, "Alteration", 0.0, "$SMGSkillAlteration")
  SetSkillVars(13, "Conjuration", 0.0, "$SMGSkillConjuration")
  SetSkillVars(14, "Destruction", 0.0, "$SMGSkillDestruction")
  SetSkillVars(15, "Illusion", 0.0, "$SMGSkillIllusion")
  SetSkillVars(16, "Restoration", 0.0, "$SMGSkillRestoration")
  SetSkillVars(17, "Enchanting", 0.0, "$SMGSkillEnchanting")
  SetSkillVars(18, "Health", 0.0, "$SMGSkillHealth")
  SetSkillVars(19, "Stamina", 0.0, "$SMGSkillStamina")
  SetSkillVars(20, "Magicka", 0.0, "$SMGSkillMagicka")
  SetSkillVars(21, "Level", 0.0, "$SMGSkillLevel")
EndEvent /;

;Debug.Notification("Updating player morphs.")
Int Sex
String SexString
String[] BodyMorphStringCache
Float[] BodyMorphValueCache
Float[] BodyMorphStartingCache

String[] BoneMorphStringCache
Float[] BoneMorphValueCache
Float[] BoneMorphStartingCache

String[] SpecialMorphStringCache
Float[] SpecialMorphValueCache
Float[] SpecialMorphStartingCache

;*******************************************************************************
;Functions
;*******************************************************************************
Actor Property MorphActor Auto

Function StartMorph(Actor TargetActor)
  MorphActor = TargetActor
  Sex = TargetActor.GetLeveledActorBase().GetSex()
  If Sex == 0
    SexString = "$SMGMale"
  ElseIf Sex == 1
    SexString = "$SMGFemale"
  EndIf
  
  CheckSkills()
  ;Debug.Notification("Starting Morph for " + MorphActor.GetLeveledActorBase().GetName() + " Body morphs = " + BodyMorphStringCache)
  RegisterForSingleUpdateGameTime(1.0/60.0)
EndFunction

Event OnUpdateGameTime()
  If Sex != MorphActor.GetLeveledActorBase().GetSex()
    nioverride.ClearBodyMorphKeys(MorphActor, "SkyrimMuscleGrowth.esp")
    CheckSkills()
  EndIf
  PreviousAlpha += AlphaRatePerMinute
  ;Debug.Notification("Updating morphs for " + MorphActor.GetLeveledActorBase().GetName() + ", Alpha = " + PreviousAlpha)

  Bool stop = false

  If PreviousAlpha > 1
    PreviousAlpha = 1
    stop = true
  Else
    RegisterForSingleUpdateGameTime(1.0/60.0)
  EndIf

  ApplyBodyMorphs(MorphActor, BodyMorphStringCache, BodyMorphValueCache, PreviousAlpha, BodyMorphStartingCache)
  ApplyBoneMorphs(MorphActor, BoneMorphStringCache, BoneMorphValueCache, PreviousAlpha, BoneMorphStartingCache)
  ApplySpecialMorphs(MorphActor, SpecialMorphStringCache, SpecialMorphValueCache, PreviousAlpha, SpecialMorphStartingCache)

  If stop
    ;Debug.Notification("Morphing finished")
    MorphActor = None
  EndIf


;/   If PlayerLastValue > PreviousAlpha
    PreviousAlpha += AlphaRatePerMinute
    If PreviousAlpha > PlayerLastValue
      PreviousAlpha = PlayerLastValue
    EndIf
    UpdateActorMorphs(CurrentTarget, PreviousAlpha)
    RegisterForSingleUpdateGameTime(1.0/60.0)
  ElseIf PlayerLastValue < PreviousAlpha
    PreviousAlpha -= AlphaRatePerMinute
    If PreviousAlpha < PlayerLastValue
      PreviousAlpha = PlayerLastValue
    EndIf
    UpdateActorMorphs(CurrentTarget, PreviousAlpha)
    RegisterForSingleUpdateGameTime(1.0/60.0)
  EndIf /;
EndEvent

Function ApplyBodyMorphs(Actor TargetActor, String[] MorphStrings, Float[] MorphValues, Float AlphaValue, Float[] StartValues)
  ;Debug.Notification("Morphing " + TargetActor.GetLeveledActorBase().GetName())
  Int i = 0
  Int IsFemale = TargetActor.GetLeveledActorBase().GetSex()
  While i < MorphStrings.Length
    String MorphString = MorphStrings[i]
    If MorphString
      ;Debug.Notification("Morph = " + MorphString + ", Final value = " + MorphValues[i] + ", Alpha = " + AlphaValue + "Start = " + StartValues[i])
      Float Interp = InterpolateValue(AlphaValue, StartValues[i], MorphValues[i], 0)
      NiOverride.SetBodyMorph(TargetActor, MorphString, "SkyrimMuscleGrowth.esp", Interp)
    EndIf
    i += 1
  EndWhile
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction

Function ApplyBoneMorphs(Actor TargetActor, String[] MorphStrings, Float[] MorphValues, Float AlphaValue, Float[] StartValues)
  Int i = 0
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  While i < MorphStrings.Length
    String MorphString = MorphStrings[i]
    If MorphString
      Float Interp = InterpolateValue(AlphaValue, StartValues[i], MorphValues[i], 0)
      NiOverride.AddNodeTransformScale(TargetActor, False, IsFemale, MorphString, "SkyrimMuscleGrowth.esp", Interp)
      NiOverride.AddNodeTransformScale(TargetActor, True, IsFemale, MorphString, "SkyrimMuscleGrowth.esp", Interp)
      NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, MorphString)
      NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, MorphString)
    EndIf
    i += 1
  EndWhile
  
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction

Function ApplySpecialMorphs(Actor TargetActor, String[] MorphStrings, Float[] MorphValues, Float AlphaValue, Float[] StartValues)
  ;Debug.Notification("Applying Body Morphs. Length == " + MorphStrings.Length)
  Int i = 0
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  While i < MorphStrings.Length
    String MorphString = MorphStrings[i]
    If MorphString
      Float Interp = InterpolateValue(AlphaValue, StartValues[i], MorphValues[i], 0)
      If MorphString == "Weight"
        If TargetActor == Game.GetPlayer()
          Interp = PapyrusUtil.ClampFloat(Interp, 0, 1)
          Interp *= 100
          TargetActor.GetActorBase().SetWeight(Interp)
          TargetActor.UpdateWeight(0.0)
        EndIf
      ElseIf MorphString == "Height"
        If Interp <= 0
          Interp = 0.01
        EndIf
        ;Debug.Notification("Height == " + MorphValue)
        ;Debug.Notification("Updating Height, value = " + InterpValue)
        NiOverride.AddNodeTransformScale(TargetActor, false, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp", Interp)
        NiOverride.AddNodeTransformScale(TargetActor, True, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp", Interp)
        NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, "NPC Root [Root]")
        NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, "NPC Root [Root]")
      EndIf
    EndIf
    i += 1
  EndWhile
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction

String[] Function MergeMorphLayers(Actor TargetActor)
  String[] a = PapyrusUtil.MergeStringArray(MCM.GetMorphLayers(None), MCM.GetMorphLayers(TargetActor.GetLeveledActorBase()))
  Debug.Notification("Merge Morphs: " + a)
  Int[] s = FilterMorphs(a, False, "", True, SexString)
  Int i = 0
  String[] b = Utility.CreateStringArray(s.Length)
  While i < s.Length
    b[i] = a[s[i]]
    ;a = RemoveFromStringArray(a, s[i])
    i += 1
  EndWhile
  Debug.Notification("b = " + b.Length)
  Return b
EndFunction

String[] Function MergeSkillLayers(Actor TargetActor)
  String[] a = PapyrusUtil.MergeStringArray(MCM.GetSkillLayers(None), MCM.GetSkillLayers(TargetActor.GetLeveledActorBase()))
  Return a
EndFunction

Function CheckSkills()
  BodyMorphStringCache = Utility.CreateStringArray(0)
  BodyMorphValueCache = Utility.CreateFloatArray(0)
  BodyMorphStartingCache = Utility.CreateFloatArray(0)

  BoneMorphStringCache = Utility.CreateStringArray(0)
  BoneMorphValueCache = Utility.CreateFloatArray(0)
  BoneMorphStartingCache = Utility.CreateFloatArray(0)

  SpecialMorphStringCache = Utility.CreateStringArray(0)
  SpecialMorphValueCache = Utility.CreateFloatArray(0)
  SpecialMorphStartingCache = Utility.CreateFloatArray(0)

;/   BodyMorphStringCache = New String[1]
  BodyMorphValueCache = New Float[1]
  BodyMorphStartingCache = New Float[1]

  BoneMorphStringCache = New String[1]
  BoneMorphValueCache = New Float[1]
  BoneMorphStartingCache = New Float[1]

  SpecialMorphStringCache = New String[1]
  SpecialMorphValueCache = New Float[1]
  SpecialMorphStartingCache = New Float[1] /;

  ;String[] morph_layers = MergeMorphLayers(MorphActor)
  ;String[] FullMorphLayerList = MergeMorphLayers(MorphActor)
  ;Debug.Notification("Full Layer Morph List: " + morph_layers.Length)
  ;String[] FullSkillLayerList = MergeSkillLayers(MorphActor)
  
  ApplyLayers(MCM.GetMorphLayers(None), MCM.GetSkillLayers(None))
  ApplyLayers(MCM.GetMorphLayers(MorphActor.GetLeveledActorBase()), MCM.GetSkillLayers(MorphActor.GetLeveledActorBase()))
  
  PreviousAlpha = 0.0

EndFunction

Function ApplyLayers(String[] morph_layers, String[] skill_layers)
  Int i = 0
  
  Int NumLayers = morph_layers.Length
  While i < NumLayers
    String[] SkillLayer = MCM.DecodeLayer(skill_layers[i])
    Float LayerValue = CalculateStat(MorphActor, SkillLayer)

    String[] MorphLayer = MCM.DecodeLayer(morph_layers[i])
    

    Int[] FilteredMorphs = FilterMorphs(MorphLayer, False, "", True, SexString)
    Int j = 0
    Int numMorphs = FilteredMorphs.Length
    While j < numMorphs
      String[] MorphStruct = MCM.DecodeStruct(MorphLayer[FilteredMorphs[j]])
      If (MorphStruct[1] as Int) as Bool
        String MorphType = MorphStruct[3]
        Float InterpValue = InterpolateValue(LayerValue, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
        ;Debug.Notification("Applying Morph " + MorphStruct[0] + ", Value == " + InterpValue)
        If MorphType == "$SMGBodyMorphs"
          Int FoundIndex = BodyMorphStringCache.Find(MorphStruct[0])
          If FoundIndex >= 0
            BodyMorphValueCache[FoundIndex] = BodyMorphValueCache[FoundIndex] + InterpValue
          Else
            BodyMorphStringCache = PapyrusUtil.PushString(BodyMorphStringCache, MorphStruct[0])
            BodyMorphValueCache = PapyrusUtil.PushFloat(BodyMorphValueCache, InterpValue)
            BodyMorphStartingCache = PapyrusUtil.PushFloat(BodyMorphStartingCache, nioverride.GetBodyMorph(MorphActor, MorphStruct[0], "SkyrimMuscleGrowth.esp"))
          EndIf
        ElseIf MorphType =="$SMGBoneScaleMorphs"
          Int FoundIndex = BoneMorphStringCache.Find(MorphStruct[0])
          If FoundIndex >= 0
            BoneMorphValueCache[FoundIndex] = BoneMorphValueCache[FoundIndex] + InterpValue
          Else
            BoneMorphStringCache = PapyrusUtil.PushString(BoneMorphStringCache, MorphStruct[0])
            BoneMorphValueCache = PapyrusUtil.PushFloat(BoneMorphValueCache, InterpValue)
            BoneMorphStartingCache = PapyrusUtil.PushFloat(BoneMorphStartingCache, nioverride.GetNodeTransformScale(MorphActor, false, Sex, MorphStruct[0], "SkyrimMuscleGrowth.esp"))

          EndIf
        ElseIf MorphType == "$SMGSpecialMorphs"
          If MorphStruct[0] != "Weight" || MorphActor == MCM.PlayerRef 
            Int FoundIndex = SpecialMorphStringCache.Find(MorphStruct[0])
            If FoundIndex >= 0
              SpecialMorphValueCache[FoundIndex] = SpecialMorphValueCache[FoundIndex] + InterpValue
            Else
              SpecialMorphStringCache = PapyrusUtil.PushString(SpecialMorphStringCache, MorphStruct[0])
              SpecialMorphValueCache = PapyrusUtil.PushFloat(SpecialMorphValueCache, InterpValue)
              If MorphStruct[0] == "Weight"
                SpecialMorphStartingCache = PapyrusUtil.PushFloat(SpecialMorphStartingCache, MorphActor.GetLeveledActorBase().GetWeight())
              ElseIf MorphStruct[0] == "Height"
                SpecialMorphStartingCache = PapyrusUtil.PushFloat(SpecialMorphStartingCache, nioverride.GetNodeTransformScale(MorphActor, false, Sex, "NPC Root [Root]", "SkyrimMuscleGrowth.esp"))
              EndIf
            EndIf
          EndIf
        EndIf
      EndIf
      j += 1
    EndWhile
    i += 1
  EndWhile
EndFunction

Float Function SumStructValues(String[] StructArray, Int Index)
  ;Sums all values in a struct array at a give Struct Index
  Int i = 0
  Int numStructs = StructArray.Length
  Float Sum = 0
  While i < numStructs
    String[] Struct = MCM.DecodeStruct(StructArray[i])
    Sum += Struct[1] as Float
    i += 1
  EndWhile
  Return Sum
EndFunction

Float Function CalculateStat(Actor TargetActor, String[] SkillLayer)
  ;(Weight / SumOfWeights) * (Value / MaxValue)
  Int numStats = SkillLayer.Length
  Float FinalStat = 0
  Float SkillSum = SumStructValues(SkillLayer, 1)
  Int i = 0
  While i < numStats
    String[] SkillStruct = MCM.DecodeStruct(SkillLayer[i])
    String ActorValueString = SkillStruct[0]
    Float weight = SkillStruct[1] as Float
    If weight != 0
      Float SkillLevel
      If ActorValueString == "Level"
        SkillLevel = TargetActor.GetLevel()
      Else
        SkillLevel = TargetActor.GetActorValue(ActorValueString)
      EndIf
      If ActorValueString == "Health" || ActorValueString == "Stamina" || ActorValueString == "Magicka"
        FinalStat += (weight/SkillSum) * (SkillLevel/BaseStatCeiling)
      ElseIf ActorValueString == "Level"
        FinalStat += (weight/SkillSum) * (SkillLevel/LevelCeiling)
      Else
        FinalStat += (weight/SkillSum) * (SkillLevel/SkillCeiling)
      EndIf
    EndIf
    i += 1
  EndWhile
  If (TargetActor == MCM.PlayerRef)
    PlayerLastValue = FinalStat
  EndIf
  Return FinalStat
EndFunction

;/ Function StartUpdates(Actor TargetActor)
  CurrentTarget = TargetActor
  CalculateStat(TargetActor)
  RegisterForSingleUpdateGameTime(1.0/60.0)
  UpdateActorMorphs(CurrentTarget, PreviousAlpha)
EndFunction
 /;
;/ Event OnUpdateGameTime()
  If PlayerLastValue > PreviousAlpha
    PreviousAlpha += AlphaRatePerMinute
    If PreviousAlpha > PlayerLastValue
      PreviousAlpha = PlayerLastValue
    EndIf
    UpdateActorMorphs(CurrentTarget, PreviousAlpha)
    RegisterForSingleUpdateGameTime(1.0/60.0)
  ElseIf PlayerLastValue < PreviousAlpha
    PreviousAlpha -= AlphaRatePerMinute
    If PreviousAlpha < PlayerLastValue
      PreviousAlpha = PlayerLastValue
    EndIf
    UpdateActorMorphs(CurrentTarget, PreviousAlpha)
    RegisterForSingleUpdateGameTime(1.0/60.0)
  EndIf
EndEvent /;

;/ Function UpdateActorMorphs(Actor TargetActor, Float Alpha)
  ;Alpha should be between 0 and 1, but can be beyond in extreme cases
  ;Debug.Notification("Updating actor " + TargetActor.GetActorBase().GetName() + ", Alpha = " + Alpha)
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  String Sex
  If IsFemale == 0
    Sex = "$SMGMale"
  ElseIf IsFemale == 1
    Sex = "$SMGFemale"
  EndIf
  Int[] FilteredMorphs = FilterMorphs(False, "", True, Sex)
  Int i = 0
  Int numMorphs = FilteredMorphs.Length
  While i < numMorphs
    String[] MorphStruct = DecodeStruct(STRUCT_MorphInfo[FilteredMorphs[i]])
    ;Debug.Notification("Updating morph " + MorphStruct[0])
    If (MorphStruct[1] as Int) as Bool
      String MorphType = MorphStruct[3]
      If MorphType == "$SMGBodyMorphs"
        Float InterpValue = InterpolateValue(Alpha, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
        NiOverride.SetBodyMorph(TargetActor, MorphStruct[0], "SkyrimMuscleGrowth.esp", InterpValue)
      ElseIf MorphType == "$SMGBoneScaleMorphs"
        Float InterpValue = InterpolateValue(Alpha, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
        NiOverride.AddNodeTransformScale(TargetActor, false, IsFemale, MorphStruct[0], "SkyrimMuscleGrowth.esp", InterpValue)
        NiOverride.AddNodeTransformScale(TargetActor, True, IsFemale, MorphStruct[0], "SkyrimMuscleGrowth.esp", InterpValue)
        NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, MorphStruct[0])
        NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, MorphStruct[0])
      ElseIf MorphType == "$SMGSpecialMorphs"
        If MorphStruct[0] == "Weight"
          If TargetActor == Game.GetPlayer()
            Float InterpValue = InterpolateValue(Alpha, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
            InterpValue = PapyrusUtil.ClampFloat(InterpValue, 0, 1)
            InterpValue *= 100
            TargetActor.GetActorBase().SetWeight(InterpValue)
            TargetActor.UpdateWeight(0.0)
          EndIf
        ElseIf MorphStruct[0] == "Height"
          Float InterpValue = InterpolateValue(Alpha, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
          If InterpValue <= 0
            InterpValue = 0.01
          EndIf
          ;Debug.Notification("Updating Height, value = " + InterpValue)
          NiOverride.AddNodeTransformScale(TargetActor, false, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp", InterpValue)
          NiOverride.AddNodeTransformScale(TargetActor, True, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp", InterpValue)
          NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, "NPC Root [Root]")
          NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, "NPC Root [Root]")

          ;TargetActor.GetActorBase().SetHeight(InterpValue)
        EndIf
      EndIf
    Else
      String MorphType = MorphStruct[3]
      If MorphType == "$SMGBodyMorphs"
        NiOverride.ClearBodyMorph(TargetActor, MorphStruct[0], "SkyrimMuscleGrowth.esp")
      ElseIf MorphType == "$SMGBoneScaleMorphs"
        NiOverride.RemoveNodeTransformScale(TargetActor, false, IsFemale, MorphStruct[0], "SkyrimMuscleGrowth.esp")
        NiOverride.RemoveNodeTransformScale(TargetActor, True, IsFemale, MorphStruct[0], "SkyrimMuscleGrowth.esp")
        NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, MorphStruct[0])
        NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, MorphStruct[0])
      ElseIf MorphType == "$SMGSpecialMorphs"
        If MorphStruct[0] == "Weight"
          If TargetActor == Game.GetPlayer()
            TargetActor.GetActorBase().SetWeight(0)
            TargetActor.UpdateWeight(0.0)
          EndIf
        ElseIf MorphStruct[0] == "Height"
          Float InterpValue = InterpolateValue(Alpha, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
          NiOverride.RemoveNodeTransformScale(TargetActor, false, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp")
          NiOverride.RemoveNodeTransformScale(TargetActor, True, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp")
          NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, "NPC Root [Root]")
          NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, "NPC Root [Root]")

          ;TargetActor.GetActorBase().SetHeight(1)
        EndIf
      EndIf
    EndIf
    i += 1
  EndWhile
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction /;

Float Function InterpolateValue(Float Alpha, Float a, Float b, Int Method)
  ;Taken From https://lunarlabs.pt/blog/post/the_art_of_lerp
  ; and https://www.gizma.com/easing
  If Method <= 0  ;Linear Interpolation
    Return a + (b - a) * Alpha
  ElseIf Method == 1  ;Ease in Cubic
    Return a + (b - a) * (Math.pow(Alpha, 3))
  ElseIf Method == 2  ;Ease out cubic
    Return a + (b - a) * (1 - Math.pow(1 - Alpha, 3))
  ElseIf Method == 3  ;Ease in/out cubic
    If Alpha < 0.5
      Return a + (b - a) * (4 * Math.pow(Alpha, 3))
    Else
      Return a + (b - a) * (1- Math.pow(-2 * Alpha + 2, 3) / 2)
    EndIf
  EndIf
EndFunction


Int[] Function FilterMorphs(String[] LayerMorphs, Bool FilterMorphType, String MorphType, Bool FilterSex, String MorphSex)
  Int i = 0
  Int numMorphs = LayerMorphs.Length
  Int j = 0
  Int[] ReturnArray = Utility.CreateIntArray(128, -1)
  While i < numMorphs
    String[] MorphStruct = MCM.DecodeStruct(LayerMorphs[i])
    Bool TypeSuccess = False
    If !FilterMorphType || MorphStruct[3] == MorphType
      TypeSuccess = True
    EndIf
    Bool SexSuccess = False
    If !FilterSex || MorphStruct[2] == MorphSex
      SexSuccess = True
    EndIf
    If TypeSuccess && SexSuccess
      ReturnArray[j] = i
      j += 1
    EndIf
    i += 1
  EndWhile
  ;MCM.ShowMessage("Num Filtered Option = " + ReturnArray.Length, False, "OK", "")
  Return PapyrusUtil.RemoveInt(ReturnArray, -1)
EndFunction

String[] Function RemoveFromStringArray(String[] TargetArray, Int Index)
  Int TargetLength = TargetArray.Length
  If TargetLength <= Index
    Return TargetArray
  EndIf
  String[] ReturnArray = Utility.CreateStringArray(TargetLength - 1, "")
  Int i = 0
  Int j = 0
  While i < TargetLength - 1
    If i == Index
      j += 1
    EndIf
    ReturnArray[i] = TargetArray[j]
    i += 1
    j += 1
  EndWhile
  Return ReturnArray
EndFunction
