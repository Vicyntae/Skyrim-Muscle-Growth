# Skyrim-Muscle-Growth

Mod allowing one to track stats on the player and edit the player visually in response. Supports body morphs (needs to be built in bodyslide), bone morphs, height morphs (buggy, don't recommend), and weight (player only)

Skyrim Special Edition only for now.

## Requirements
- [SKSE64](https://skse.silverlock.org)
- [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604)
- [Racemenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080)
- [PapyrusUtil](https://www.nexusmods.com/skyrimspecialedition/mods/13048)

## Morphs
1. Go to Actions Page
2. Select Add Male Morph or Add Female Morph
3. Input name of the bone or morph
  - Available special morphs are "height" and "weight"
4. Go to Morph Settings Page
5. On the new morph you created,  adjust morph type
  - Does the morph use Body morphs from bodyslide, bone scales, or other changes?
 
## Skills
Select how much weight is given to each skill. Ceiling values in Actions Page determine maximum morph value
 
## Profiles
You can save morph profiles for males and females.
Select "Save Male/Female Morph Profile" to write to file.
Profiles are stored in SKSE\Plugins\StorageUtilData\SMG\Profiles
Restore profiles to a layer using "Restore Male/Female Profile".
WARNING this will overwrite settings for the current layer

## Layers
You can have different skill sets affecting different morphs using layers. Layers can be chosen in the Actions page.
Each layer has its own Morphs Settings and Skill Weights.
Loading a profile will overwrite thses settings, so write to a new profile beforehand.
You can rename layers for readability.

Additional documentation coming later.
