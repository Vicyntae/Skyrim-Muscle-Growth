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
Actor CurrentTarget
Float AlphaRatePerMinute = 0.05
Float PreviousAlpha = 0.0

Event OnInit()
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
EndEvent
;*******************************************************************************
;Functions
;*******************************************************************************
Float Function SumStructValues(String[] StructArray, Int Index)
  ;Sums all values in a struct array at a give Struct Index
  Int i = 0
  Int numStructs = StructArray.Length
  Float Sum = 0
  While i < numStructs
    String[] Struct = DecodeStruct(StructArray[i])
    Sum += Struct[1] as Float
    i += 1
  EndWhile
  Return Sum
EndFunction

Float Function CalculateStat(Actor TargetActor)
  ;(Weight / SumOfWeights) * (Value / MaxValue)
  Int numStats = STRUCT_SkillInfo.Length
  Float FinalStat = 0
  Float SkillSum = SumStructValues(STRUCT_SkillInfo, 1)
  Int i = 0
  While i < numStats
    String[] SkillStruct = DecodeStruct(STRUCT_SkillInfo[i])
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
  PlayerLastValue = FinalStat
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

String Function EncodeArray(String[] StructArray, String Delimiter = "_")
  Return PapyrusUtil.StringJoin(StructArray, Delimiter)
EndFunction

Bool Function AddMorph(String MorphString, Bool Enabled, String MorphSex, String MorphType, Float MorphMin = 0.0, Float MorphMax = 1.0, Int MorphInterp = 0)
  If STRUCT_MorphInfo.Length > 128
    Return False
  EndIf
  String[] StructArray = New String[7]
  StructArray[0] = MorphString
  StructArray[1] = (Enabled as Int) as String
  StructArray[2] = MorphSex
  StructArray[3] = MorphType
  StructArray[4] = MorphMin as String
  StructArray[5] = MorphMax as String
  StructArray[6] = MorphInterp as String
  STRUCT_MorphInfo = PapyrusUtil.PushString(STRUCT_MorphInfo, EncodeArray(StructArray))
  Return True
EndFunction

String[] Function DecodeStruct(String Struct)
  Return StringUtil.Split(Struct, "_")
EndFunction

String[] Function GetMorphStructIdx(Int index)
  String EncodedStruct = STRUCT_MorphInfo[index]
  Return DecodeStruct(EncodedStruct)
EndFunction

Int[] Function FilterMorphs(Bool FilterMorphType, String MorphType, Bool FilterSex, String MorphSex)
  Int i = 0
  Int numMorphs = STRUCT_MorphInfo.length
  Int j = 0
  Int[] ReturnArray = Utility.CreateIntArray(128, -1)
  While i < numMorphs
    String[] MorphStruct = DecodeStruct(STRUCT_MorphInfo[i])
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

Int Function GetMorphIndex(String MorphString, String MorphType, String MorphSex)
  Int i = 0
  Int numMorphs = STRUCT_MorphInfo.length
  While i < numMorphs
    String[] MorphStruct = DecodeStruct(STRUCT_MorphInfo[i])
    If MorphStruct[3] == MorphType
      If MorphStruct[2] == MorphSex
        If MorphStruct[0] == MorphString
          Return i
        EndIf
      EndIf
    EndIf
    i += 1
  EndWhile
  Return -1
EndFunction

String[] Function GetMorphStructString(String MorphString, String MorphType, String MorphSex)
  Int Index = GetMorphIndex(MorphString, MorphType, MorphSex)
  If Index < 0
    Return New String[1]
  EndIf
  Return GetMorphStructIdx(Index)
EndFunction

Function SetMorphVar(Int ArrayIndex, Int StructIndex, String Value)
  If ArrayIndex > STRUCT_MorphInfo.Length - 1
    STRUCT_MorphInfo = PapyrusUtil.ResizeStringArray(STRUCT_MorphInfo, ArrayIndex + 1, "")
  EndIf
  String[] MorphStruct = DecodeStruct(STRUCT_MorphInfo[ArrayIndex])
  If MorphStruct.Length != 7
    MorphStruct = New String[7]
    MorphStruct[0] = "NONE"
    MorphStruct[1] = 0
    MorphStruct[2] = "$SMGMale"
    MorphStruct[3] = "$SMGSpecialMorphs"
    MorphStruct[4] = 0.0
    MorphStruct[5] = 1.0
    MorphStruct[6] = 0
  EndIf
  MorphStruct[StructIndex] = Value
  STRUCT_MorphInfo[ArrayIndex] = EncodeArray(MorphStruct)
EndFunction

Function SetMorphVars(Int ArrayIndex, String MorphString, Bool MorphEnabled, String MorphSex, String MorphType, Float MorphMin, Float MorphMax, Int MorphInterp)
  If ArrayIndex > STRUCT_MorphInfo.Length - 1
    STRUCT_MorphInfo = PapyrusUtil.ResizeStringArray(STRUCT_MorphInfo, ArrayIndex + 1, "")
  EndIf
  String[] MorphStruct = New String[7]
  MorphStruct[0] = MorphString
  MorphStruct[1] = (MorphEnabled as Int) as String
  MorphStruct[2] = MorphSex
  MorphStruct[3] = MorphType
  MorphStruct[4] = MorphMin
  MorphStruct[5] = MorphMax
  MorphStruct[6] = MorphInterp
  STRUCT_MorphInfo[ArrayIndex] = EncodeArray(MorphStruct)
EndFunction

Function SetSkillVar(Int ArrayIndex, Int StructIndex, String Value)
  If ArrayIndex > STRUCT_SkillInfo.Length - 1
    STRUCT_SkillInfo = PapyrusUtil.ResizeStringArray(STRUCT_SkillInfo, ArrayIndex + 1, "")
  EndIf
  String[] SkillStruct = DecodeStruct(STRUCT_SkillInfo[ArrayIndex])
  If SkillStruct.Length != 3
    SkillStruct = New String[3]
    SkillStruct[0] = "NONE"
    SkillStruct[1] = 0.0
    SkillStruct[2] = "NONE"
  EndIf
  SkillStruct[StructIndex] = Value
  STRUCT_SkillInfo[ArrayIndex] = EncodeArray(SkillStruct)
EndFunction

Function SetSkillVars(Int ArrayIndex, String SkillString, Float SkillWeight, String SkillDisplayName)
  If ArrayIndex > STRUCT_SkillInfo.Length - 1
    STRUCT_SkillInfo = PapyrusUtil.ResizeStringArray(STRUCT_SkillInfo, ArrayIndex + 1, "")
  EndIf
  String[] SkillStruct = New String[3]
  SkillStruct[0] = SkillString
  SkillStruct[1] = SkillWeight
  SkillStruct[2] = SkillDisplayName
  STRUCT_SkillInfo[ArrayIndex] = EncodeArray(SkillStruct)
EndFunction

Function DeleteMorph(Int Index)
	String[] MorphStruct = DecodeStruct(STRUCT_MorphInfo[Index])
	String MorphType = MorphStruct[3]
	Actor Player = MCM.PlayerRef
	Int IsFemale = Player.GetActorBase().GetSex()
	If MorphType == "$SMGSpecialMorphs"
		If MorphStruct[0] == "Weight"
	        Player.GetActorBase().SetWeight(0)
	        Player.UpdateWeight(0.0)
        ElseIf MorphStruct[0] == "Height"
          NiOverride.RemoveNodeTransformScale(Player, false, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp")
          NiOverride.RemoveNodeTransformScale(Player, True, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp")
          NiOverride.UpdateNodeTransform(Player, False, IsFemale, "NPC Root [Root]")
          NiOverride.UpdateNodeTransform(Player, True, IsFemale, "NPC Root [Root]")
		EndIf
	EndIf
	STRUCT_MorphInfo = RemoveFromStringArray(STRUCT_MorphInfo, Index)
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
