scriptName SMG_MCM Extends ski_configbase

;*******************************************************************************
;Properties
;*******************************************************************************
String SMG_Folder_M = "/SMG/Profiles/Male/"
String SMG_Folder_F = "/SMG/Profiles/Female/"
String SMG_Folder_Skills = "/SMG/Profiles/Skills/"

String DefaultMorphProfileName_M
String DefaultMorphProfileName_F
String DefaultSkillProfileName

Actor Property PlayerRef Auto
SMG_LayerBase[] Property Layers Auto
Int Property CurrentLayerIndex Auto

;When layers are updated every day
Float Property DailyUpdateTime = 0.0 Auto

;The current morph page that is selected.
Int Property CurrentMorphPage Auto

Int Property NumMorphsPerPage = 15 Auto

;The number of morph pages that will be displayed
;calculated every time the MCM morph page is loaded
;20 morphs per page
Int Property NumMorphPages Auto

;Mod installation variables
Bool Property NiOverride_Installed = false Auto
Bool Property PapyrusUtil_Installed = false Auto

;/
0 = OneHanded
1 = TwoHanded
2 = Marksman
3 = Block
4 = Smithing
5 = HeavyArmor
6 = LightArmor
7 = Pickpocket
8 = Lockpicking
9 = Sneak
10 = Alchemy
11 = Speechcraft
12 = Alteration
13 = Conjuration
14 = Destruction
15 = Illusion
16 = Restoration
17 = Enchanting
18 = Health
19 = Stamina
20 = Magicka
21 = Level
/;
;Holds an ordered list of index pointers to morph structs on the current layer
Int[] CachedMorphList
;Struct Array, contains the ID of a morph and where it's located in the MCM
string[] MorphOptionIDArray
int[] MorphOptionIndexArray

;Switches display from body morphs to bone morphs
Bool Property DisplayFemaleMorphs Auto
String Property DisplayMorphType Auto

;Options to display when editing morph options.
String[] MorphActionsList
;/
0 = Delete Morph
1 = Cancel
/;
;Enum, sets interpolation setting when morphing
string[] InterpOptions
;/
0 = "Linear"
1 = "Ease In Cubic"
2 = "Ease Out Cubic"
3 = "Ease In/Out Cubic"
/;

Float DEBUG_PlayerStrengthSet = 0.0

String MorphTypeFilter = ""
String[] FilterOptionsType
String MorphSexFilter = ""
String[] FilterOptionsSex
;*******************************************************************************
;Functions
;*******************************************************************************
Bool Function SaveSkillProfile(String ProfileName, Int LayerIndex)
  JsonUtil.ClearAll(SMG_Folder_Skills + ProfileName)
  JsonUtil.StringListCopy(SMG_Folder_Skills + ProfileName, "STRUCT_SkillInfo", Layers[LayerIndex].STRUCT_SkillInfo)
  Return JsonUtil.Save(SMG_Folder_Skills + ProfileName)
EndFunction


Function LoadSkillProfile(String ProfileName, Int LayerIndex)
  If !JsonUtil.Load(SMG_Folder_Skills + ProfileName)
    ShowMessage("Error, Profile could not be found.", false, "OK", "")
    Return
  EndIf
  If !JsonUtil.IsGood(SMG_Folder_Skills + ProfileName)
    ShowMessage("Error, profile has parser errors.", false, "OK", "")
    Return
  EndIf
  Layers[LayerIndex].STRUCT_SkillInfo = JsonUtil.StringListToArray(SMG_Folder_Skills + ProfileName, "STRUCT_SkillInfo")
  JsonUtil.Unload(SMG_Folder_Skills + ProfileName, false, false)
EndFunction

bool Function SaveMorphProfile(String ProfileName, Int LayerIndex, bool IsFemale)
  SMG_LayerBase TargetLayer = Layers[LayerIndex]
  String Sex
  If IsFemale
    Sex = "$SMGFemale"
  Else
    Sex = "$SMGMale"
  EndIf
  Int[] MorphList = TargetLayer.FilterMorphs(False, "", True, Sex)
  Int numMorphs = MorphList.Length
  String[] SaveStructArray = Utility.CreateStringArray(numMorphs, "")
  Int i = 0
  While i < numMorphs
    SaveStructArray[i] = TargetLayer.STRUCT_MorphInfo[MorphList[i]]
    i += 1
  EndWhile
  string filepath
  If isFemale
    filepath = SMG_Folder_F + ProfileName
  Else
    filepath = SMG_Folder_M + ProfileName
  EndIf
  JsonUtil.ClearAll(filepath)
  JsonUtil.StringListCopy(filepath, "STRUCT_MorphInfo", SaveStructArray)
  Return JsonUtil.Save(filepath)
EndFunction

Function LoadMorphProfile(String ProfilePath, Int LayerIndex, Bool IsFemale)
  SMG_LayerBase TargetLayer = Layers[LayerIndex]
  string filepath
  String sex
  If IsFemale
    filepath = SMG_Folder_F + ProfilePath
    sex = "$SMGFemale"
  Else
    filepath = SMG_Folder_M + ProfilePath
    sex = "$SMGMale"
  EndIf

  If !JsonUtil.Load(filepath)
    ShowMessage("Error, Profile could not be found.", false, "OK", "")
    Return
  EndIf
  If !JsonUtil.IsGood(filepath)
    ShowMessage("Error, profile has parser errors.", false, "OK", "")
    Return
  EndIf

  Int[] FilteredMorphs = TargetLayer.FilterMorphs(False, "", True, sex)
  Int i = 0
  Int numMorphs = FilteredMorphs.Length
  While i < numMorphs
    TargetLayer.STRUCT_MorphInfo = RemoveFromStringArray(TargetLayer.STRUCT_MorphInfo, FilteredMorphs[i])
    i += 1
  EndWhile
  String[] NewProfileArray = JsonUtil.StringListToArray(filepath, "STRUCT_MorphInfo")
  TargetLayer.STRUCT_MorphInfo = PapyrusUtil.MergeStringArray(TargetLayer.STRUCT_MorphInfo, NewProfileArray, False)
  JsonUtil.Unload(filepath, false, false)
EndFunction

Function CreateDefaultProfile_F(Int LayerIndex)
  ;Overrides storage arrays with a "default" profile
  ;so that they don't have to start from scratch if they mess something up.

  LoadMorphProfile(DefaultMorphProfileName_F, LayerIndex, True)
EndFunction

Function CreateDefaultProfile_M(Int LayerIndex)
  ;Overrides storage arrays with a "default" profile
  ;so that they don't have to start from scratch if they mess something up.

  LoadMorphProfile(DefaultMorphProfileName_M, LayerIndex, False)

EndFunction

Function CreateDefaultSkillProfile(Int LayerIndex)
  LoadSkillProfile(DefaultSkillProfileName, LayerIndex)

  ;/Layers[LayerIndex].STRUCT_SkillInfo = New String[22]

  Layers[LayerIndex].SetSkillVars("OneHanded", 2.0)
  Layers[LayerIndex].SetSkillVars("TwoHanded", 2)
  Layers[LayerIndex].SetSkillVars("Marksman", 1.0)
  Layers[LayerIndex].SetSkillVars("Block", 1.0)
  Layers[LayerIndex].SetSkillVars("Smithing", 1.0)
  Layers[LayerIndex].SetSkillVars("HeavyArmor", 2.0)
  Layers[LayerIndex].SetSkillVars("LightArmor", 1.0)
  Layers[LayerIndex].SetSkillVars("Pickpocket", 0.0)
  Layers[LayerIndex].SetSkillVars("Lockpicking", 0.0)
  Layers[LayerIndex].SetSkillVars("Sneak", 0.0)
  Layers[LayerIndex].SetSkillVars("Alchemy", 0.0)
  Layers[LayerIndex].SetSkillVars("Speechcraft", 0.0)
  Layers[LayerIndex].SetSkillVars("Alteration", 0.0)
  Layers[LayerIndex].SetSkillVars("Conjuration", 0.0)
  Layers[LayerIndex].SetSkillVars("Destruction", 0.0)
  Layers[LayerIndex].SetSkillVars("Illusion", 0.0)
  Layers[LayerIndex].SetSkillVars("Restoration", 0.0)
  Layers[LayerIndex].SetSkillVars("Enchanting", 0.0)
  Layers[LayerIndex].SetSkillVars("Health", 1.0)
  Layers[LayerIndex].SetSkillVars("Stamina", 0.0)
  Layers[LayerIndex].SetSkillVars("Magicka", 0.0)
  Layers[LayerIndex].SetSkillVars("Level", 0.0)/;
EndFunction

string Function ModE(bool is_enabled)
  If is_enabled
    return "$SMGModEnabledText"
  EndIf
  return "$SMGModDisabledText"
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

Float[] Function RemoveFromFloatArray(Float[] TargetArray, Int Index)
  Int TargetLength = TargetArray.Length
  If TargetLength <= Index
    Return TargetArray
  EndIf
  Float[] ReturnArray = Utility.CreateFloatArray(TargetLength - 1, 0.0)
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

Int[] Function RemoveFromIntArray(Int[] TargetArray, Int Index)
  Int TargetLength = TargetArray.Length
  If TargetLength <= Index
    Return TargetArray
  EndIf
  Int[] ReturnArray = Utility.CreateIntArray(TargetLength - 1, 0)
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

String[] Function GetMorphOptionListing(Int Option)
  int optionIndexIndex = MorphOptionIndexArray.find(Option)
  If optionIndexIndex < 0
    ShowMessage("Index Index Not found, option idx = " + Option, false, "OK", "")
    return New String[1]
  EndIf

  string optionID = MorphOptionIDArray[optionIndexIndex]
  If !optionID
    ShowMessage("Option not found, option idx = " + optionIndexIndex, false, "OK", "")
    return New String[1]
  EndIf
  Return StringUtil.Split(optionID, "_")
EndFunction




Function UpdateAllLayerMorphs(Actor TargetActor)
  Debug.Notification("Updating player morphs.")
  Int IsFemale = TargetActor.GetActorBase().GetSex()
    String Sex
  If IsFemale == 0
    Sex = "$SMGMale"
  ElseIf IsFemale == 1
    Sex = "$SMGFemale"
  EndIf
  String[] BodyMorphStringCache = New String[1]
  Float[] BodyMorphValueCache = New Float[1]

  String[] BoneMorphStringCache = New String[1]
  Float[] BoneMorphValueCache = New Float[1]

  String[] SpecialMorphStringCache = New String[1]
  Float[] SpecialMorphValueCache = New Float[1]
  Int i = 0
  Int NumLayers = Layers.Length
  While i < NumLayers
    SMG_LayerBase Layer = Layers[i]
    Float LayerValue = Layer.CalculateStat(TargetActor)

    Int[] FilteredMorphs = Layer.FilterMorphs(False, "", True, Sex)
    Int j = 0
    Int numMorphs = FilteredMorphs.Length
    While j < numMorphs
      String[] MorphStruct = Layer.DecodeStruct(Layer.STRUCT_MorphInfo[FilteredMorphs[j]])
      If (MorphStruct[1] as Int) as Bool
        String MorphType = MorphStruct[3]
        Float InterpValue = Layer.InterpolateValue(LayerValue, MorphStruct[4] as Float, MorphStruct[5] as Float, MorphStruct[6] as Int)
        Debug.Notification("Applying Morph " + MorphStruct[0] + ", Value == " + InterpValue)
        If MorphType == "$SMGBodyMorphs"
          Int FoundIndex = BodyMorphStringCache.Find(MorphStruct[0])
          If FoundIndex >= 0
            BodyMorphValueCache[FoundIndex] = BodyMorphValueCache[FoundIndex] + InterpValue
          Else
            BodyMorphStringCache = PapyrusUtil.PushString(BodyMorphStringCache, MorphStruct[0])
            BodyMorphValueCache = PapyrusUtil.PushFloat(BodyMorphValueCache, InterpValue)
          EndIf
        ElseIf MorphType =="$SMGBoneScaleMorphs"
          Int FoundIndex = BoneMorphStringCache.Find(MorphStruct[0])
          If FoundIndex >= 0
            BoneMorphValueCache[FoundIndex] = BoneMorphValueCache[FoundIndex] + InterpValue
          Else
            BoneMorphStringCache = PapyrusUtil.PushString(BoneMorphStringCache, MorphStruct[0])
            BoneMorphValueCache = PapyrusUtil.PushFloat(BoneMorphValueCache, InterpValue)
          EndIf
        ElseIf MorphType == "$SMGSpecialMorphs"
          Int FoundIndex = SpecialMorphStringCache.Find(MorphStruct[0])
          If FoundIndex >= 0
            SpecialMorphValueCache[FoundIndex] = SpecialMorphValueCache[FoundIndex] + InterpValue
          Else
            SpecialMorphStringCache = PapyrusUtil.PushString(SpecialMorphStringCache, MorphStruct[0])
            SpecialMorphValueCache = PapyrusUtil.PushFloat(SpecialMorphValueCache, InterpValue)
          EndIf
        EndIf
      EndIf
      j += 1
    EndWhile
    i += 1
  EndWhile
  ApplyBodyMorphs(TargetActor, BodyMorphStringCache, BodyMorphValueCache)
  ApplyBoneMorphs(TargetActor, BoneMorphStringCache, BoneMorphValueCache)
  ApplySpecialMorphs(TargetActor, SpecialMorphStringCache, SpecialMorphValueCache)

EndFunction

Function ApplyBodyMorphs(Actor TargetActor, String[] MorphStrings, Float[] MorphValues)
  Int i = 0
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  While i < MorphStrings.Length
    String MorphString = MorphStrings[i]
    If MorphString
      Float MorphValue = MorphValues[i]
      NiOverride.SetBodyMorph(TargetActor, MorphString, "SkyrimMuscleGrowth.esp", MorphValue)
    EndIf
    i += 1
  EndWhile
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction

Function ApplyBoneMorphs(Actor TargetActor, String[] MorphStrings, Float[] MorphValues)
  Int i = 0
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  While i < MorphStrings.Length
    String MorphString = MorphStrings[i]
    If MorphString
      Float MorphValue = MorphValues[i]
      NiOverride.AddNodeTransformScale(TargetActor, False, IsFemale, MorphString, "SkyrimMuscleGrowth.esp", MorphValue)
      NiOverride.AddNodeTransformScale(TargetActor, True, IsFemale, MorphString, "SkyrimMuscleGrowth.esp", MorphValue)
      NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, MorphString)
      NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, MorphString)
    EndIf
    i += 1
  EndWhile
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction

Function ApplySpecialMorphs(Actor TargetActor, String[] MorphStrings, Float[] MorphValues)
  Debug.Notification("Applying Body Morphs. Length == " + MorphStrings.Length)
  Int i = 0
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  While i < MorphStrings.Length
    String MorphString = MorphStrings[i]
    If MorphString
      Float MorphValue = MorphValues[i]
      If MorphString == "Weight"
        If TargetActor == Game.GetPlayer()
          MorphValue = PapyrusUtil.ClampFloat(MorphValue, 0, 1)
          MorphValue *= 100
          TargetActor.GetActorBase().SetWeight(MorphValue)
          TargetActor.UpdateWeight(0.0)
        EndIf
      ElseIf MorphString == "Height"
        If MorphValue <= 0
          MorphValue = 0.01
        EndIf
        Debug.Notification("Height == " + MorphValue)
        ;Debug.Notification("Updating Height, value = " + InterpValue)
        NiOverride.AddNodeTransformScale(TargetActor, false, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp", MorphValue)
        NiOverride.AddNodeTransformScale(TargetActor, True, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp", MorphValue)
        NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, "NPC Root [Root]")
        NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, "NPC Root [Root]")
      EndIf
    EndIf
    i += 1
  EndWhile
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction


Function RemoveMorph(Actor TargetActor, String MorphString, String MorphType)
  Int IsFemale = TargetActor.GetActorBase().GetSex()
  If MorphType == "$SMGBodyMorphs"
    NiOverride.ClearBodyMorph(TargetActor, MorphString, "SkyrimMuscleGrowth.esp")
  ElseIf MorphType == "$SMGBoneScaleMorphs"
    NiOverride.RemoveNodeTransformScale(TargetActor, False, IsFemale, MorphString, "SkyrimMuscleGrowth.esp")
    NiOverride.RemoveNodeTransformScale(TargetActor, True, IsFemale, MorphString, "SkyrimMuscleGrowth.esp")
    NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, MorphString)
    NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, MorphString)
  ElseIf MorphType == "$SMGSpecialMorphs"
    If MorphString == "Weight"
      If TargetActor == Game.GetPlayer()
        TargetActor.GetActorBase().SetWeight(0)
        TargetActor.UpdateWeight(0.0)
      EndIf
    ElseIf MorphString == "Height"
      NiOverride.RemoveNodeTransformScale(TargetActor, False, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp")
      NiOverride.RemoveNodeTransformScale(TargetActor, True, IsFemale, "NPC Root [Root]", "SkyrimMuscleGrowth.esp")
      NiOverride.UpdateNodeTransform(TargetActor, False, IsFemale, "NPC Root [Root]")
      NiOverride.UpdateNodeTransform(TargetActor, True, IsFemale, "NPC Root [Root]")
    EndIf
  EndIf
  TargetActor.QueueNiNodeUpdate()
  NiOverride.UpdateModelWeight(TargetActor)
EndFunction


Function AddToCache(String[] StringCache, Float[] FloatCache, String MorphString, Float MorphValue)
  Int FoundIndex = StringCache.Find(MorphString)
  If FoundIndex >= 0
    FloatCache[FoundIndex] = FloatCache[FoundIndex] + MorphValue
  Else
    StringCache = PapyrusUtil.PushString(StringCache, MorphString)
    FloatCache = PapyrusUtil.PushFloat(FloatCache, MorphValue)
  EndIf
EndFunction

Function RegisterSpecificTimeUpdate(Float TimeOfDayEvent)
  ; Taken from https://forums.nexusmods.com/index.php?/topic/2602204-script-to-run-daily-in-game-time/
  float currentTime = Utility.GetCurrentGameTime()
  currentTime = 24.0 * (currentTime - (CurrentTime as Int))
  If currentTime < TimeOfDayEvent
    ;Debug.Notification("Next update in " + (TimeOfDayEvent - currentTime) + " hours.")
    RegisterForSingleUpdateGameTime(TimeOfDayEvent - currentTime)
  Else
    ;Debug.Notification("Next update in " + (TimeOfDayEvent - currentTime + 24) + " hours.")
    RegisterForSingleUpdateGameTime(TimeOfDayEvent - currentTime + 24)
  EndIf
EndFunction
;*******************************************************************************
;Events
;*******************************************************************************
Event OnConfigInit()
  ;Initialize Pages
  RegisterForSingleUpdateGameTime(0.01)
  RegisterForSleep()
  RegisterForMenu("Sleep/Wait Menu")

  Pages = new String[4]
  Pages[0] = "$SMGInformation"
  Pages[1] = "$SMGLayerActions"
  Pages[2] = "$SMGMorphSettings"
  Pages[3] = "$SMGSkillWeights"

  ;Setup Interpolation enum
  InterpOptions = new String[4]
  InterpOptions[0] = "$SMGInterpolationLinear"
  InterpOptions[1] = "$SMGInterpolationEaseInCubic"
  InterpOptions[2] = "$SMGInterpolationEaseOutCubic"
  InterpOptions[3] = "$SMGInterpolationEaseInOutCubic"

  MorphActionsList = new String[3]
  MorphActionsList[0] = "$SMGMorphActionEnableDisableMorph"
  MorphActionsList[1] = "$SMGMorphActionDeleteMorph"
  MorphActionsList[2] = "$SMGGenericCancel02"

  FilterOptionsType = New String[4]
  FilterOptionsType[0] = "$SMGBodyMorphs"
  FilterOptionsType[1] = "$SMGBoneScaleMorphs"
  FilterOptionsType[2] = "$SMGSpecialMorphs"
  FilterOptionsType[3] = "$SMGGenericCancel02"

  FilterOptionsSex = New String[3]
  FilterOptionsSex[0] = "$SMGMale"
  FilterOptionsSex[1] = "$SMGFemale"
  FilterOptionsSex[2] = "$SMGGenericCancel02"
  ;Hard-coded default profile
  ;CreateDefaultSkillProfile(CurrentLayerIndex)
  ;CreateDefaultProfile_F()
  ;Debug.Notification("SAM quest valid = " + SAM_Quest as Bool)

EndEvent


Event OnGameReload()
  parent.OnGameReload()

  ;Check what mods are installed
  ;NiOverride
  int NiOverrideVer = NiOverride.GetScriptVersion()
  If NiOverrideVer != 0
    NiOverride_Installed = true
  EndIf

  ;PapyrusUtil
  int PapyrusUtilVer = PapyrusUtil.GetVersion()
  If PapyrusUtilVer != 0
    PapyrusUtil_Installed = true
  EndIf

EndEvent

Event OnMenuOpen(String MenuName)
  If MenuName == "Sleep/Wait Menu"
    UpdateAllLayerMorphs(PlayerRef)
    RegisterSpecificTimeUpdate(DailyUpdateTime)
  EndIf
EndEvent

Event OnSleepStop(bool abInterrupted)
  UpdateAllLayerMorphs(PlayerRef)
  RegisterSpecificTimeUpdate(DailyUpdateTime)
EndEvent

Event OnUpdateGameTime()
  ;Debug.Notification("Updating player strength. New strength = " + UpdateStrength())
  UpdateAllLayerMorphs(PlayerRef)
  RegisterSpecificTimeUpdate(DailyUpdateTime)
EndEvent

event OnPageReset(string page)
  ;CurrentPage = page
  If page == ""
    ;LoadCustomContent("")
    return
  Else
    UnloadCustomContent()
  EndIf

  If page == "$SMGInformation"
    SetCursorFillMode(LEFT_TO_RIGHT)
    AddTextOptionST("NIOVERRIDE_INSTALLED", "$SMGIsNiOverrideInstalled", ModE(NiOverride_Installed))
    AddTextOptionST("PAPYRUSUTIL_INSTALLED", "$SMGIsPapyrusUtilInstalled", ModE(PapyrusUtil_Installed))
    AddEmptyOption()
    AddEmptyOption()
    AddEmptyOption()
    AddSliderOptionST("SET_UPDATE_TIME", "$SMGSetUpdateTime", DailyUpdateTime, "{0}")
    ;AddSliderOptionST("DEBUG_SET_STRENGTH", "Set Player Strength", PlayerLastStrength, "{1}")
  ElseIf page == "$SMGLayerActions"
    SetCursorFillMode(LEFT_TO_RIGHT)

    AddMenuOptionST("SELECT_LAYER", "$SMGSelectLayer", Layers[CurrentLayerIndex].LayerName)
    AddInputOptionST("RENAME_LAYER", "$SMGRenameLayer", "")
    AddTextOptionST("LAST_LAYER_VALUE", "$SMGLastLayerValue", Layers[CurrentLayerIndex].PlayerLastValue)
    AddEmptyOption()
    AddEmptyOption()
    AddEmptyOption()
    AddSliderOptionST("LAYER_SKILL_CEILING", "$SMGLayerSkillCeiling", Layers[CurrentLayerIndex].SkillCeiling, "{0}")
    AddSliderOptionST("LAYER_BASE_STAT_CEILING", "$SMGLayerBaseStatCeiling", Layers[CurrentLayerIndex].BaseStatCeiling, "{0}")
    AddSliderOptionST("LAYER_LEVEL_CEILING", "$SMGLayerLevelCeiling", Layers[CurrentLayerIndex].LevelCeiling, "{0}")
    AddEmptyOption()
    AddEmptyOption()
    AddEmptyOption()
    AddTextOptionST("RESTORE_DEFAULT_PROFILE_M", "$SMGRestoreDefaultProfileM", "")
    AddInputOptionST("ADD_MORPH_M", "$SMGAddMorphM", Layers[CurrentLayerIndex].STRUCT_MorphInfo.Length)
    AddMenuOptionST("SELECT_LOADED_PROFILE_M", "$SMGSelectProfileM", "")
    AddInputOptionST("SAVE_LOADED_PROFILE_M", "$SMGSaveMorphProfileM", "")
    AddEmptyOption()
    AddEmptyOption()
    AddTextOptionST("RESTORE_DEFAULT_PROFILE_F", "$SMGRestoreDefaultProfileF", "")
    AddInputOptionST("ADD_MORPH_F", "$SMGAddMorphF", Layers[CurrentLayerIndex].STRUCT_MorphInfo.Length)
    AddMenuOptionST("SELECT_LOADED_PROFILE_F", "$SMGSelectProfileF", "")
    AddInputOptionST("SAVE_LOADED_PROFILE_F", "$SMGSaveMorphProfileF", "")
    AddEmptyOption()
    AddEmptyOption()
    AddTextOptionST("RESTORE_DEFAULT_PROFILE_SKILL", "$SMGRestoreDefaultSkillProfile", "")
    AddEmptyOption()
    AddMenuOptionST("SELECT_LOADED_PROFILE_SKILL", "$SMGSelectProfileSkill", "")
    AddInputOptionST("SAVE_LOADED_PROFILE_SKILL", "$SMGSaveMorphProfileSkill", "")


  ElseIf page == "$SMGMorphSettings"
    ;Disable profile options if PapyrusUtil is unavailable
    int flag = OPTION_FLAG_NONE
    If !PapyrusUtil_Installed
      flag = OPTION_FLAG_DISABLED
    EndIf

    ;Calculate number of entries needed
    SMG_LayerBase Layer = Layers[CurrentLayerIndex]
    Bool FilterTypes = (MorphTypeFilter as Bool)
    Bool FilterSex = (MorphSexFilter as Bool)
    Int i = 0
    CachedMorphList = Layer.FilterMorphs(FilterTypes, MorphTypeFilter, FilterSex, MorphSexFilter)
    ;ShowMessage("Num cached options = " + CachedMorphList.Length, False, "OK", "")
    Int numEntries = CachedMorphList.Length
    NumMorphPages = Math.Ceiling(numEntries / NumMorphsPerPage)

    SetCursorFillMode(LEFT_TO_RIGHT)
    ;Setup Page Buttons
    AddTextOptionST("MORPH_OPTION_FILTER_RESET", "$SMGMorphOptionFilterReset", "")
    AddMenuOptionST("MORPH_OPTION_FILTER_TYPE", "$SMGMorphOptionFilterType", MorphTypeFilter)
    AddMenuOptionST("MORPH_OPTION_FILTER_SEX", "$SMGMorphOptionFilterSex", MorphSexFilter)
    If NumMorphPages <= 1
      ;Disable page buttons if only one page
      AddTextOptionST("GO_TO_NEXT_PAGE", "$SMGNextMorphPage", 1, OPTION_FLAG_DISABLED)
      AddTextOptionST("GO_TO_PREVIOUS_PAGE", "$SMGPreviousMorphPage", 1, OPTION_FLAG_DISABLED)
      AddSliderOptionST("JUMP_TO_MORPH_PAGE", "$SMGJumpToMorphPage", CurrentMorphPage, OPTION_FLAG_DISABLED)
    Else
      Int nextPage = CurrentMorphPage + 1
      If nextPage > NumMorphPages - 1
        nextPage = 0
      EndIf
      nextPage += 1
      AddTextOptionST("GO_TO_NEXT_PAGE", "$SMGNextMorphPage", nextPage)
      Int prevPage = CurrentMorphPage - 1
      If prevPage < 0
        prevPage = NumMorphPages - 1
      EndIf
      prevPage += 1
      AddTextOptionST("GO_TO_PREVIOUS_PAGE", "$SMGPreviousMorphPage", prevPage)
      AddSliderOptionST("JUMP_TO_MORPH_PAGE", "$SMGJumpToMorphPage", CurrentMorphPage + 1)
    EndIf

    ;Cancel adding options if NiOverride is unavailable
    If !NiOverride_Installed
      Return
    EndIf

    Int selectedMorphPage = PapyrusUtil.ClampInt(CurrentMorphPage, 0, NumMorphPages)

    AddEmptyOption()
    AddEmptyOption()

    If numEntries == 0
      Return
    EndIf

    Int idx = NumMorphsPerPage * selectedMorphPage  ;Set index at start of page

    Int end_idx = NumMorphsPerPage * (selectedMorphPage + 1) ;Set limit at start of next page, clamped to actual num of entries
    end_idx = PapyrusUtil.ClampInt(end_idx, idx, numEntries)

    ;Reinitialize Index and ID arrays
    MorphOptionIDArray = new String[128]  ;The Pointer Index and Option Type
    MorphOptionIndexArray = new Int[128]
    Int absIndex = 0  ;Stores struct location in the above when iterating

    While idx < end_idx

      String[] MorphStruct = Layer.GetMorphStructidx(CachedMorphList[idx])

      MorphOptionIndexArray[absIndex] = AddMenuOption(MorphStruct[0], "$SMGMorphEnable")
      MorphOptionIDArray[absIndex] = (idx as String) + "_name"
      absIndex += 1

      Int OptionFlag = OPTION_FLAG_NONE
      If !(MorphStruct[1] as Int) as Bool
        OptionFlag = OPTION_FLAG_DISABLED
      EndIf

      MorphOptionIndexArray[absIndex] = AddMenuOption("$SMGMorphSex", MorphStruct[2], OptionFlag)
      MorphOptionIDArray[absIndex] = (idx as String) + "_sex"
      absIndex += 1

      MorphOptionIndexArray[absIndex] = AddMenuOption("$SMGMorphType", MorphStruct[3], OptionFlag)
      MorphOptionIDArray[absIndex] = (idx as String) + "_type"
      absIndex += 1

      MorphOptionIndexArray[absIndex] = AddMenuOption("$SMGMorphInterpOption", InterpOptions[MorphStruct[6] as Int], OptionFlag)
      MorphOptionIDArray[absIndex] = (idx as String) + "_interp"
      absIndex += 1

      MorphOptionIndexArray[absIndex] = AddSliderOption("$SMGMorphMinValueOption", MorphStruct[4] as Float, "{1}", OptionFlag)
      MorphOptionIDArray[absIndex] = (idx as String)  + "_min"
      absIndex += 1

      MorphOptionIndexArray[absIndex] = AddSliderOption("$SMGMorphMaxValueOption", MorphStruct[5] as Float, "{1}", OptionFlag)
      MorphOptionIDArray[absIndex] = (idx as String)  + "_max"
      absIndex += 1

      AddEmptyOption()
      AddEmptyOption()

      idx += 1
    EndWhile
  ElseIf page == "$SMGSkillWeights"
    SetCursorFillMode(LEFT_TO_RIGHT)
    SMG_LayerBase Layer = Layers[CurrentLayerIndex]
    MorphOptionIDArray = new String[128]  ;The Pointer Index and Option Type
    MorphOptionIndexArray = new Int[128]
    Int i = 0
    Int numSkills = Layer.STRUCT_SkillInfo.Length
    CachedMorphList = Utility.CreateIntArray(numSkills, -1)
    While i < numSkills
      CachedMorphList[i] = i
      i += 1
    EndWhile
    Int absIndex = 0
    i = 0
    While i < numSkills
      String[] SkillStruct = Layer.DecodeStruct(Layer.STRUCT_SkillInfo[CachedMorphList[i]])

      MorphOptionIndexArray[absIndex] = AddSliderOption(SkillStruct[2], SkillStruct[1] as Float, "{1}")
      MorphOptionIDArray[absIndex] = (i as String)  + "_weight"
      absIndex += 1

      i += 1
    EndWhile
  EndIf
EndEvent

Event OnOptionSliderOpen(int a_option)
  If CurrentPage == "$SMGMorphSettings"
    String[] OptionListing = GetMorphOptionListing(a_option)
    If OptionListing.Length < 2
      Return
    EndIf
    Int pointer = OptionListing[0] as Int
    string option_type = OptionListing[1]

    String[] MorphStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_MorphInfo[CachedMorphList[pointer]])
    If MorphStruct.Length < 7
      ShowMessage("Morph index not found morph_name = " + pointer, false, "OK", "")
      ShowMessage("Morph index not found, option name = " + option_type, false, "OK", "")
      return
    EndIf

    Float optionvalue = 0
    If option_type == "min"
      optionvalue = MorphStruct[4] as Float
    Elseif option_type == "max"
      optionvalue = MorphStruct[5] as Float
    EndIf
    Float RangeMin = -5.0
    If MorphStruct[0] == "Weight" && MorphStruct[3] == "$SMGSpecialMorphs"
      RangeMin = 0
    ElseIf MorphStruct[0] == "Height" && MorphStruct[3] == "$SMGSpecialMorphs"
      RangeMin = 0
    EndIf
    Float RangeMax = 5.0
    If MorphStruct[0] == "Weight" && MorphStruct[3] == "$SMGSpecialMorphs"
      RangeMax = 1
    ElseIf MorphStruct[0] == "Height" && MorphStruct[3] == "$SMGSpecialMorphs"
      RangeMax = 2
    EndIf
    Float Interval = 0.1
    If MorphStruct[0] == "Weight" && MorphStruct[3] == "$SMGSpecialMorphs"
      Interval = 0.01
    ElseIf MorphStruct[0] == "Height" && MorphStruct[3] == "$SMGSpecialMorphs"
      Interval = 0.01
    EndIf
    SetSliderDialogStartValue(optionvalue)
    SetSliderDialogDefaultValue(0)
    SetSliderDialogRange(RangeMin, RangeMax)
    SetSliderDialogInterval(Interval)
  ElseIf CurrentPage == "$SMGSkillWeights"
    String[] OptionListing = GetMorphOptionListing(a_option)
    If OptionListing.Length < 2
      Return
    EndIf

    Int pointer = OptionListing[0] as Int
    string option_type = OptionListing[1]

    String[] SkillStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_SkillInfo[CachedMorphList[pointer]])
    If SkillStruct.Length < 3
      ShowMessage("Morph index not found morph_name = " + pointer, false, "OK", "")
      ShowMessage("Morph index not found, option name = " + option_type, false, "OK", "")
      return
    EndIf
    Float optionvalue = 0
    If option_type == "Weight"
      optionvalue = SkillStruct[1] as Float
    EndIf
    SetSliderDialogStartValue(optionvalue)
    SetSliderDialogDefaultValue(0)
    SetSliderDialogRange(-5, 5)
    SetSliderDialogInterval(0.1)
  EndIf
EndEvent

Event OnOptionSliderAccept(int a_option, float a_value)
  If CurrentPage == "$SMGMorphSettings"

    String[] OptionListing = GetMorphOptionListing(a_option)
    If OptionListing.Length < 2
      Return
    EndIf
    Int pointer = OptionListing[0] as Int
    string option_type = OptionListing[1]

    Int morph_idx = CachedMorphList[pointer]
    if morph_idx < 0
      ShowMessage("Morph index not found, pointer = " + pointer, false, "OK", "")
      ShowMessage("Morph index not found, option name = " + option_type, false, "OK", "")
      return
    EndIf

    If option_type == "min"
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 4, a_value)
    ElseIf option_type == "max"
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 5, a_value)
    EndIf
    SetSliderOptionValue(a_option, a_value, "{1}")
  ElseIf CurrentPage == "$SMGSkillWeights"

    String[] OptionListing = GetMorphOptionListing(a_option)
    If OptionListing.Length < 2
      Return
    EndIf
    Int pointer = OptionListing[0] as Int
    string option_type = OptionListing[1]

    Int morph_idx = CachedMorphList[pointer]
    if morph_idx < 0
      ShowMessage("Morph index not found, pointer = " + pointer, false, "OK", "")
      ShowMessage("Morph index not found, option name = " + option_type, false, "OK", "")
      return
    EndIf

    If option_type == "weight"
      Layers[CurrentLayerIndex].SetSkillVar(morph_idx, 1, a_value)
    EndIf
    SetSliderOptionValue(a_option, a_value, "{1}")
  EndIf
  RegisterForSingleUpdateGameTime(0.001)
EndEvent


Event OnOptionMenuOpen(int a_option)
  If CurrentPage == "$SMGMorphSettings"

    String[] OptionListing = GetMorphOptionListing(a_option)
    If OptionListing.Length < 2
      Return
    EndIf
    Int pointer = OptionListing[0] as Int
    string option_type = OptionListing[1]
    String[] MorphStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_MorphInfo[CachedMorphList[pointer]])

    int optionvalue = 0
    If option_type == "name"
      optionvalue = 0
      SetMenuDialogOptions(MorphActionsList)
      SetMenuDialogDefaultIndex(0)
      SetMenuDialogStartIndex(optionvalue)
    ElseIf option_type == "sex"
      String[] menuOptions = New String[2]
      menuOptions[0] = "$SMGMale"
      menuOptions[1] = "$SMGFemale"
      SetMenuDialogOptions(menuOptions)
      SetMenuDialogDefaultIndex(0)
      SetMenuDialogStartIndex(0)
    ElseIf option_type == "type"
      String[] menuOptions = New String[3]
      menuOptions[0] = "$SMGBodyMorphs"
      menuOptions[1] = "$SMGBoneScaleMorphs"
      menuOptions[2] = "$SMGSpecialMorphs"
      SetMenuDialogOptions(menuOptions)
      SetMenuDialogDefaultIndex(0)
      SetMenuDialogStartIndex(0)
    ElseIf option_type == "interp"
      If MorphStruct.Length < 7
        optionvalue = 0
      Else
        optionvalue = MorphStruct[3] as Int
      EndIf
      SetMenuDialogOptions(InterpOptions)
      SetMenuDialogDefaultIndex(0)
      SetMenuDialogStartIndex(optionvalue)
    EndIf

  ;ElseIf CurrentPage == "$SMGSkillWeights"
  EndIf
EndEvent

Event OnOptionMenuAccept(int a_option, int a_index)
  String[] OptionListing = GetMorphOptionListing(a_option)
  If OptionListing.Length < 2
    Return
  EndIf
  Int pointer = OptionListing[0] as Int
  string option_type = OptionListing[1]

  Int morph_idx = CachedMorphList[pointer]
  if morph_idx < 0
    ShowMessage("Morph index not found, pointer = " + pointer, false, "OK", "")
    ShowMessage("Morph index not found, option name = " + option_type, false, "OK", "")
    return
  EndIf
  If option_type == "name"
    If a_index == 0 ;Enable/Disable Morph
      String[] MorphStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_MorphInfo[morph_idx])
      Bool is_enabled = (MorphStruct[1] as Int) as Bool
      If !is_enabled
        RemoveMorph(PlayerRef, MorphStruct[0], MorphStruct[3])
      EndIf
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 1, ((!is_enabled) as Int) as String)
      ForcePageReset()
    ElseIf a_index == 1 ;Delete Morph
      String[] MorphStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_MorphInfo[morph_idx])
      RemoveMorph(PlayerRef, MorphStruct[0], MorphStruct[3])
      Layers[CurrentLayerIndex].DeleteMorph(morph_idx)
      ForcePageReset()
    EndIf
  ElseIf option_type == "sex"
    String[] MorphStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_MorphInfo[morph_idx])
     RemoveMorph(PlayerRef, MorphStruct[0], MorphStruct[3])
    If a_index == 0
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 2, "$SMGMale")
    ElseIf a_index == 1
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 2, "$SMGFemale")
    EndIf
    ForcePageReset()
  ElseIf option_type == "type"
    String[] MorphStruct = Layers[CurrentLayerIndex].DecodeStruct(Layers[CurrentLayerIndex].STRUCT_MorphInfo[morph_idx])
    RemoveMorph(PlayerRef, MorphStruct[0], MorphStruct[3])
    If a_index == 0
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 3, "$SMGBodyMorphs")
      SetMenuOptionValue(a_option, "$SMGBodyMorphs")
    ElseIf a_index == 1
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 3, "$SMGBoneScaleMorphs")
      SetMenuOptionValue(a_option, "$SMGBoneScaleMorphs")
    ElseIf a_index == 2
      Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 3, "$SMGSpecialMorphs")
      SetMenuOptionValue(a_option, "$SMGSpecialMorphs")
    EndIf
  ElseIf option_type == "interp"
    Layers[CurrentLayerIndex].SetMorphVar(morph_idx, 6, a_Index as String)
    SetMenuOptionValue(a_option, InterpOptions[a_index])
  EndIf
  RegisterForSingleUpdateGameTime(0.001)
EndEvent

Event OnOptionHighlight(int a_option)
  String[] OptionListing = GetMorphOptionListing(a_option)
  If OptionListing.Length < 2
    Return
  EndIf
  Int pointer = OptionListing[0] as Int
  string option_type = OptionListing[1]
  If option_type == "name"
    SetInfoText("$SMGMorphActionsInfo")
  ElseIf option_type == "min"
    SetInfoText("$SMGMorphSetSexInfo")
  ElseIf option_type == "min"
    SetInfoText("$SMGMorphSetTypeInfo")
  ElseIf option_type == "min"
    SetInfoText("$SMGMorphMinValueInfo")
  ElseIf option_type == "max"
    SetInfoText("$SMGMorphMaxValueInfo")
  ElseIf option_type == "interp"
    SetInfoText("$SMGMorphInterpInfo")
  ElseIf option_type == "weight"
    SetInfoText("$SMGSkillWeightInfo")
  EndIf
EndEvent

;*******************************************************************************
;Option States
;*******************************************************************************
State SELECT_LAYER
  Event OnMenuOpenST()
    Int numLayers = Layers.Length
    String[] LayerNames = Utility.CreateStringArray(numLayers, "")
    Int i = 0
    While i < numLayers
      LayerNames[i] = Layers[i].LayerName
      i += 1
    EndWhile
    SetMenuDialogStartIndex(CurrentLayerIndex)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(LayerNames)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    CurrentLayerIndex = a_index
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGSelectLayerInfo")
  EndEvent
EndState

State RENAME_LAYER
  Event OnInputOpenST()
     SetInputDialogStartText(Layers[CurrentLayerIndex].LayerName)
  EndEvent

  Event OnInputAcceptST(string a_input)
    If !a_input
      ShowMessage("$SMGInvalidLayerName", False, "$SMGGenericConfirm02", "")
      Return
    EndIf
    Layers[CurrentLayerIndex].LayerName = a_input
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGRenameLayerInfo")
  EndEvent
EndState

State LAST_LAYER_VALUE
  Event OnHighlightST()
    SetInfoText("$SMGLastLayerValueInfo")
  EndEvent
EndState

State ADD_MORPH_M
  Event OnInputAcceptST(string a_input)
    If !a_input
      ShowMessage("$SMGInvalidMorphName", False, "$SMGGenericConfirm02", "")
      Return
    EndIf
    If !Layers[CurrentLayerIndex].AddMorph(a_input, true, "$SMGMale", "$SMGBodyMorphs", 0.0, 1.0, 0)
      ShowMessage("$SMGExceedMorphNumberMessage", False, "$SMGGenericConfirm02", "")
    EndIf
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGAddBodyMorphInfo")
  EndEvent
EndState

State ADD_MORPH_F
  Event OnInputAcceptST(string a_input)
    If !a_input
      ShowMessage("$SMGInvalidMorphName", False, "$SMGGenericConfirm02", "")
      Return
    EndIf
    If !Layers[CurrentLayerIndex].AddMorph(a_input, true, "$SMGFemale", "$SMGBodyMorphs", 0.0, 1.0, 0)
      ShowMessage("$SMGExceedMorphNumberMessage", False, "$SMGGenericConfirm02", "")
    EndIf
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGAddBodyMorphInfo")
  EndEvent
EndState

State NIOVERRIDE_INSTALLED
  Event OnHighlightST()
    If NiOverride_Installed
      SetInfoText("$SMGNiOverrideEnabledInfo")
    Else
      SetInfoText("$SMGNiOverrideDisabledInfo")
    EndIf
  EndEvent
EndState

State PAPYRUSUTIL_INSTALLED
  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGPapyrusUtilEnabledInfo")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

State GO_TO_NEXT_PAGE
  Event OnSelectST()
    CurrentMorphPage = (CurrentMorphPage + 1) % NumMorphPages
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGNextMorphPageInfo")
  EndEvent
EndState
State GO_TO_PREVIOUS_PAGE
  Event OnSelectST()
    Int prevPage = CurrentMorphPage - 1
    If prevPage < 0
      prevPage = NumMorphPages - 1
    EndIf
    CurrentMorphPage = prevPage
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGPreviousMorphPageInfo")
  EndEvent
EndState

State JUMP_TO_MORPH_PAGE
  Event OnSliderOpenST()
    Int StartPage = CurrentMorphPage
    StartPage += 1
    SetSliderDialogStartValue(StartPage)
    SetSliderDialogDefaultValue(1)
    SetSliderDialogRange(1, NumMorphPages)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    a_value -= 1
    CurrentMorphPage = a_value as int
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGJumpToMorphPageInfo")
  EndEvent
EndState

string[] profileIDs
State SELECT_LOADED_PROFILE_M
  Event OnMenuOpenST()
    profileIDs = JsonUtil.JsonInFolder(SMG_Folder_M)
    SetMenuDialogStartIndex(0)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(profileIDs)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    string new_profile = profileIDs[a_index]
    LoadMorphProfile(new_profile, CurrentLayerIndex, false)
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGSelectProfileInfoM")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

State SELECT_LOADED_PROFILE_F
  Event OnMenuOpenST()
    profileIDs = JsonUtil.JsonInFolder(SMG_Folder_F)
    SetMenuDialogStartIndex(0)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(profileIDs)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    string new_profile = profileIDs[a_index]
    LoadMorphProfile(new_profile, CurrentLayerIndex, True)
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGSelectProfileInfoF")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

State SELECT_LOADED_PROFILE_SKILL
  Event OnMenuOpenST()
    profileIDs = JsonUtil.JsonInFolder(SMG_Folder_Skills)
    SetMenuDialogStartIndex(0)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(profileIDs)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    string new_profile = profileIDs[a_index]
    LoadSkillProfile(new_profile, CurrentLayerIndex)
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGSelectProfileInfoSkill")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

State RESTORE_DEFAULT_PROFILE_F
  Event OnSelectST()
    If !ShowMessage("$SMGRestoreDefaultProfileConfirmF", true, "$SMGGenericConfirm02", "$SMGGenericCancel02")
      Return
    EndIf
    CreateDefaultProfile_F(CurrentLayerIndex)
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGRestoreDefaultProfileInfoF")
  EndEvent
EndState

State RESTORE_DEFAULT_PROFILE_M
  Event OnSelectST()
    If !ShowMessage("$SMGRestoreDefaultProfileConfirmM", true, "$SMGGenericConfirm02", "SMGGenericCancel02")
      Return
    EndIf
    CreateDefaultProfile_M(CurrentLayerIndex)
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGRestoreDefaultProfileInfoM")
  EndEvent
EndState

State RESTORE_DEFAULT_PROFILE_SKILL
  Event OnSelectST()
    If !ShowMessage("$SMGRestoreDefaultProfileConfirmSkill", true, "$SMGGenericConfirm02", "SMGGenericCancel02")
      Return
    EndIf
    CreateDefaultSkillProfile(CurrentLayerIndex)
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGRestoreDefaultProfileInfoSkill")
  EndEvent
EndState

STATE SAVE_LOADED_PROFILE_M
  Event OnInputAcceptST(string a_input)
    if !a_input
      ShowMessage("$SMGInvalidFileNameWarning", false, "$SMGGenericConfirm02", "")
    EndIf
    SaveMorphProfile(a_input, CurrentLayerIndex, false)
    ShowMessage("$SMGNewProfileCreatedMessage" + a_input, false, "$SMGGenericConfirm02" , "")
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGSaveProfileInfo")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

STATE SAVE_LOADED_PROFILE_F
  Event OnInputAcceptST(string a_input)
    if !a_input
      ShowMessage("$SMGInvalidFileNameWarning", false, "$SMGGenericConfirm02", "")
    EndIf
    SaveMorphProfile(a_input, CurrentLayerIndex, true)
    ShowMessage("$SMGNewProfileCreatedMessage" + a_input, false, "$SMGGenericConfirm02" , "")
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGSaveProfileInfo")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

STATE SAVE_LOADED_PROFILE_SKILL
  Event OnInputAcceptST(string a_input)
    if !a_input
      ShowMessage("$SMGInvalidFileNameWarning", false, "$SMGGenericConfirm02", "")
    EndIf
    SaveSkillProfile(a_input, CurrentLayerIndex)
    ShowMessage("$SMGNewProfileCreatedMessage" + a_input, false, "$SMGGenericConfirm02" , "")
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If PapyrusUtil_Installed
      SetInfoText("$SMGSaveProfileInfo")
    Else
      SetInfoText("$SMGPapyrusUtilDisabledInfo")
    EndIf
  EndEvent
EndState

State MORPH_OPTION_FILTER_RESET
  Event OnSelectST()
    MorphTypeFilter = ""
    MorphSexFilter = ""
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGResetMorphFilter")
  EndEvent
EndState

State MORPH_OPTION_FILTER_TYPE
  Event OnMenuOpenST()
    SetMenuDialogStartIndex(0)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(FilterOptionsType)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    MorphTypeFilter = FilterOptionsType[a_index]
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGMorphOptionFilterTypeInfo")
  EndEvent
EndState

State MORPH_OPTION_FILTER_SEX
  Event OnMenuOpenST()
    SetMenuDialogStartIndex(0)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(FilterOptionsSex)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    If a_index == 2
      Return
    EndIf
    MorphSexFilter = FilterOptionsSex[a_index]
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGMorphOptionFilterSexInfo")
  EndEvent
EndState

State SET_UPDATE_TIME
  Event OnSliderOpenST()
    SetSliderDialogStartValue(DailyUpdateTime)
    SetSliderDialogDefaultValue(0)
    SetSliderDialogRange(0, 24)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    DailyUpdateTime = a_value
    SetSliderOptionValueST(DailyUpdateTime, "{0}")
    RegisterSpecificTimeUpdate(DailyUpdateTime)
  EndEvent

  Event OnOptionDefault(int a_option)
    DailyUpdateTime = 0.0
    SetSliderOptionValueST(DailyUpdateTime, "{0}")
    RegisterSpecificTimeUpdate(DailyUpdateTime)
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGSetUpdateTimeInfo")
  EndEvent
EndState

State LAYER_SKILL_CEILING
  Event OnSliderOpenST()
    SetSliderDialogStartValue(Layers[CurrentLayerIndex].SkillCeiling)
    SetSliderDialogDefaultValue(100)
    SetSliderDialogRange(0, 500)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    Layers[CurrentLayerIndex].SkillCeiling = a_value
    SetSliderOptionValueST(a_value, "{0}")
  EndEvent

  Event OnOptionDefault(int a_option)
    Layers[CurrentLayerIndex].SkillCeiling = 100
    SetSliderOptionValueST(100, "{0}")
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGLayerSkillCeilingInfo")
  EndEvent
EndState

State LAYER_BASE_STAT_CEILING
  Event OnSliderOpenST()
    SetSliderDialogStartValue(Layers[CurrentLayerIndex].BaseStatCeiling)
    SetSliderDialogDefaultValue(500)
    SetSliderDialogRange(0, 2000)
    SetSliderDialogInterval(10)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    Layers[CurrentLayerIndex].BaseStatCeiling = a_value
    SetSliderOptionValueST(a_value, "{0}")
  EndEvent

  Event OnOptionDefault(int a_option)
    Layers[CurrentLayerIndex].BaseStatCeiling = 500
    SetSliderOptionValueST(500, "{0}")
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGLayerBaseStatCeilingInfo")
  EndEvent
EndState

State LAYER_LEVEL_CEILING
  Event OnSliderOpenST()
    SetSliderDialogStartValue(Layers[CurrentLayerIndex].LevelCeiling)
    SetSliderDialogDefaultValue(75)
    SetSliderDialogRange(0, 300)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    Layers[CurrentLayerIndex].LevelCeiling = a_value as Int
    SetSliderOptionValueST(a_value, "{0}")
  EndEvent

  Event OnOptionDefault(int a_option)
    Layers[CurrentLayerIndex].LevelCeiling = 75
    SetSliderOptionValueST(75, "{0}")
  EndEvent

  Event OnHighlightST()
    SetInfoText("$SMGLayerLevelCeilingInfo")
  EndEvent
EndState