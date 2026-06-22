## Navigation menu

### Namespaces

English

### Views

More

### Search

[Visit the main page](https://warcraft.wiki.gg/ "Visit the main page")

### Navigation

### Wiki community

### World of Warcraft

### Franchise

### Useful pages

### Lore

### Tools

# Patch 12.1.0/API changes

From Warcraft Wiki

< [Patch 12.1.0](https://warcraft.wiki.gg/wiki/Patch_12.1.0 "Patch 12.1.0")

[Jump to navigation](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#mw-head) [Jump to search](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#searchInput)

| [Main Menu](https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization "Warcraft Wiki:Interface customization") |
| --- |
| - [WoW API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API "World of Warcraft API")<br>- [Lua API](https://warcraft.wiki.gg/wiki/Lua_functions "Lua functions")<br>- [FrameXML API](https://warcraft.wiki.gg/wiki/FrameXML_functions "FrameXML functions")<br>* * *<br>- [ScriptObject API](https://warcraft.wiki.gg/wiki/Widget_API "Widget API")<br>- [Widget scripts](https://warcraft.wiki.gg/wiki/Widget_script_handlers "Widget script handlers")<br>- [XML schema](https://warcraft.wiki.gg/wiki/XML_schema "XML schema")<br>- [Events](https://warcraft.wiki.gg/wiki/Events "Events")<br>- [CVars](https://warcraft.wiki.gg/wiki/Console_variables "Console variables")<br>* * *<br>- [Macro commands](https://warcraft.wiki.gg/wiki/Macro_commands "Macro commands")<br>- [Combat Log](https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT "COMBAT LOG EVENT")<br>- [Escape sequences](https://warcraft.wiki.gg/wiki/UI_escape_sequences "UI escape sequences")<br>- [Hyperlinks](https://warcraft.wiki.gg/wiki/Hyperlinks "Hyperlinks")<br>- [API changes](https://warcraft.wiki.gg/wiki/API_change_summaries "API change summaries")<br>- [HOWTOs](https://warcraft.wiki.gg/wiki/HOWTOs "HOWTOs")<br>- [![Discord logo.png](https://warcraft.wiki.gg/images/thumb/Discord_logo.png/12px-Discord_logo.png?4d7bc2)](https://discord.gg/txUg39Vhc6)[wowuidev](https://discord.gg/txUg39Vhc6) |

|     |     |
| --- | --- |
| [![Icon-api-48x48.png](https://warcraft.wiki.gg/images/Icon-api-48x48.png?6b6990)](https://warcraft.wiki.gg/wiki/File:Icon-api-48x48.png) | **This article documents [API changes](https://warcraft.wiki.gg/wiki/API_change_summaries "API change summaries") made in [Patch 12.1.0](https://warcraft.wiki.gg/wiki/Patch_12.1.0 "Patch 12.1.0").** <br>- Previous patch: [Patch 12.0.7](https://warcraft.wiki.gg/wiki/Patch_12.0.7/API_changes "Patch 12.0.7/API changes").<br>- Next patch: Patch 12.1.5. |

## Contents

- [1Resources](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Resources)
- [2Undocumented changes](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Undocumented_changes)
- [3Blue posts](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Blue_posts)
  - [3.12026-06-18](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#2026-06-18)
- [4Consolidated changes](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Consolidated_changes)
  - [4.1Global API](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Global_API)
  - [4.2ScriptObjects](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#ScriptObjects)
  - [4.3Widgets](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Widgets)
  - [4.4Events](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Events)
  - [4.5CVars](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#CVars)
  - [4.6Enumerations](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Enumerations)
  - [4.7Structures](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Structures)
- [5Deprecated API](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes#Deprecated_API)

## Resources

- TOC: `120100`
- Official patch notes: [Midnight: Curse of Ula’tek PTR Development Notes](https://us.forums.blizzard.com/en/wow/t/midnight-curse-of-ulatek-ptr-development-notes/2317811#p-29652268-user-interface-and-accessibility-19)
- Diffs: [wow-ui-source](https://github.com/Gethe/wow-ui-source/compare/12.0.7..12.1.0), [BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources/compare/12.0.7..12.1.0)

## Undocumented changes

- The [UIParentLoadAddOn](https://warcraft.wiki.gg/wiki/API_UIParentLoadAddOn "API UIParentLoadAddOn") FrameXML function has been renamed to [LoadAddOnWithErrorHandling](https://www.townlong-yak.com/framexml/ptr/go/LoadAddOnWithErrorHandling).

## Blue posts

**Addons and Auras in Curse of Ula’tek** \| 2026-06-18 17:00 \| [![Blizzard Entertainment](https://warcraft.wiki.gg/images/Blizz.gif?984542)](https://warcraft.wiki.gg/wiki/Blizzard_Entertainment "Blizzard Entertainment")**JHemphill**

Since the launch of Midnight, we’ve continued to iterate on the addon-related changes introduced in the Midnight pre-patch. In the 12.1 Curse of Ula’tek update, we are pleased to be taking the next major step in that work. This work reflects the insights and feedback shared by our community, with a focus on auras, commonly referred to by players as buffs and debuffs.

These changes focus on preventing auras (whether on the player, enemies, or party and raid members) from leaking important combat information that can be used for combat automation. At the same time, we want addons to continue being able to show auras in a variety of custom ways.

To support that goal, Curse of Ula’tek will introduce new APIs that allow addons to display filtered sets of auras in customized ways, without exposing the underlying aura information that could be used for automation. Addons that currently display auras will need to be updated to support these new APIs, and we’ll be working directly with addon authors throughout the Curse of Ula’tek PTR to help them adapt to these changes and gather feedback during testing.

[View original post](https://us.forums.blizzard.com/en/wow/t/addons-and-auras-in-curse-of-ula%E2%80%99tek/2317456)

### 2026-06-18

[_Midnight 12.1.0 PTR Changes 1_](https://discord.com/channels/327414731654692866/1517308873093152768)

> Hello again from the World of Warcraft UI Engineering team! Today we’d like to talk about a significant set of Aura-related changes coming in 12.1. Most of these changes will be available when PTR launches, with the remaining pieces rolling out over the following few weeks.
>
> **Why Auras?**
>
> Since the Addon Disarmament project went live with Midnight, Auras (aka buffs and debuffs) have consistently been one of the weakest areas for addon security, with numerous exploits discovered both before launch and since then. The core issue is that, in many cases, simply knowing that any aura is present on a unit (whether it be the player, an enemy, or a raid/party member) is enough to determine that some important combat event has occurred. Aura filters are vital for many legitimate addon use cases, but they also make this problem harder to contain by allowing even more ways to tell if “special aura X” is on a unit, even if the unit has multiple auras on them.
>
> Up until now, our solution to this has been to lean on Private Auras. Unfortunately, Private Auras come with several downsides: they are invisible to addons, which prevents customization; they are not supported in every context, such as nameplates; and setting them up across every encounter adds significant setup work for our designers. Secret values were created specifically to protect against cases like this, providing passive protection by default.
>
> **What is changing?**
>
> We’ll get to the changes to existing APIs shortly, but first, we’d like to introduce a couple of new constructs we are adding to Lua, along with two new object types (Aura Containers and Aura Buttons).
>
> **New Tech: Private Script Objects & The Forbidden Partition**
>
> Private Script Objects are a new construct that lets us split the Lua representation of a script object across multiple Lua tables, or partitions. One of these partitions we call the Forbidden Partition, because it is inaccessible to addons. The Forbidden Partition can contain any kind of value, from mixins to key/value pairs, functions, script handlers, and child objects. This allows us to effectively hide portions of the object from addon code even when the object itself isn’t in the secure environment.
>
> **New Tech: Forbidden Aspects**
>
> Forbidden Aspects are another new construct that works alongside Private Script Objects. Forbidden Aspects are similar in concept to the Secret Aspects we introduced in Midnight, but instead of causing certain object APIs to return secrets, they prevent addons from using certain functionality entirely. Where Secret Aspects obfuscate data, Forbidden Aspects restrict what addons are allowed to do with an object.
>
> There are several Forbidden Aspects being added (details are in the docs), but let’s use the UntrustedScriptExecution Forbidden Aspect as an example. When a frame has the UntrustedScriptExecution Forbidden Aspect applied to it, any script binding handlers set on it (e.g. OnShow, OnLoad, OnSizeChanged) will not be run unless that handler lives in the object’s Forbidden Partition and execution is untainted. In other words, addons cannot install their own script bindings on the object, but our code can.
>
> **New Object Types: Aura Containers & Aura Buttons**
>
> Aura Containers and Aura Buttons are new Lua object types that allow addons to display auras in custom ways. Here’s a small example showing how they can be used:
>
> ```
> local container = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate");
> container:SetSize(1, 1);
> container:SetPoint("CENTER");
> container:SetUnit("target");
> container:AddAuraFilter("HELPFUL", { maxFrameCount = 5 });
>
> for i = 1, 5 do
> 	local auraButton = CreateFrame("AuraButton", nil, container, "CustomAuraButtonTemplate");
> 	auraButton:SetSize(40, 40);
> 	auraButton:SetPoint("TOPLEFT", container, "TOPLEFT", (i - 1) * 42, 0);
> 	auraButton.Icon = auraButton:CreateTexture(nil, "OVERLAY");
> 	auraButton.Icon:SetAllPoints(auraButton);
> 	auraButton:SetIcon(auraButton.Icon);
> 	auraButton.Text = auraButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
> 	auraButton.Text:SetPoint("TOP", auraButton, "BOTTOM", 0, -5);
> 	auraButton:SetDurationText(auraButton.Text);
> 	container:AddAuraFrame(auraButton);
> end
> ```
>
> Copy
>
> In the example above, we create an Aura Container, specify that it should track the first 5 helpful auras on the player’s target, and then add 5 Aura Buttons to it. For each Aura Button, we create a texture for the icon and a font string for the duration. The APIs shown here on the Aura Button are just a sample of the APIs provided (full details will be in the docs), but this should give you a sense of what is possible. Note that addon code still has a great deal of control over how the auras are presented, but it doesn’t interact with the underlying aura data at all. This separation is important for security, but it should also make custom aura displays easier to build and more performant. Aura Containers handle the tracking, filtering, and updating of aura assignments internally, so addons can focus more on presentation and less on repeatedly querying, diffing, and refreshing aura state themselves.
>
> **Why Are Aura Containers Safer?**
>
> To answer that, let’s go back to Private Script Objects and Forbidden Aspects again. Aura Buttons and Aura Containers both have Forbidden Aspects applied to them on creation. When an Aura Button is added to an Aura Container using the [AddAuraFrame](https://www.townlong-yak.com/framexml/ptr/go/CustomAuraContainerInboundMixin:AddAuraFrame) API, it is added to the Forbidden Partition of that Aura Container. This means addon code cannot install script handlers on Aura Buttons to be notified when they show or hide. It also cannot hook functions called on the Aura Button’s mixins or register events on those buttons. While addons can still hold references to those individual Aura Buttons, calling certain APIs on them will be disallowed, and they cannot run logic based on whether those buttons are shown, because IsShown and similar APIs return secrets.
>
> **Which current APIs are changing?**
>
> The main change to existing APIs is that, when auras are secret (during combat, encounters, M+, and PvP matches), all of the UnitAura APIs will now either return full secrets or nil when called by addons. That means that APIs like [GetUnitAuras](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetUnitAuras "API C UnitAuras.GetUnitAuras") and [GetUnitAuraInstanceIDs](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetUnitAuraInstanceIDs "API C UnitAuras.GetUnitAuraInstanceIDs") will return a secret vector, meaning addon code will not be able to determine how many auras it contains or iterate through it for display. Auras we explicitly flag as non-secret will still be returned as non-secret by UnitAura APIs, however.
>
> **Is all this in place in PTR Week 1?**
>
> No, several pieces of this are not currently implemented in the first PTR build but will be coming over the next few weeks. The biggest pieces not in place yet are the changes to the UnitAura APIs. Some Aura Button protections are also not yet in place: their script handlers are protected, but script handlers on their child frames are not, and event registration is still currently allowed. Those protections, along with additional safeguards, will arrive over the next few weeks. In the meantime, though, feel free to start experimenting!
>
> As always, we are actively seeking your feedback and will be monitoring the ⁠ [author-wishlist](https://discord.com/channels/327414731654692866/1376602198687092857) channel, so please share feedback, bugs, and any potential exploits there. Thanks as always for helping us test and improve this system!
>
> DISCLAIMER: These notes are for addon authors and as such are focused specifically on addon-facing API and security changes only. Changes planned for other parts of the game (UI or otherwise) are not included here.

**Interface Texture Filenames**

Starting in 12.1, new interface texture filenames will no longer be published to the ManifestInterfaceData DB, and as a result will not be available via `exportinterfacefiles art`. **Existing filenames will remain in the DB.** You may notice that a few entries are still added in 12.1 and over the next few patches, but this is due to those assets already having been added prior to this change being made. We are making this change to prevent leaks caused by texture names containing hints about future content. We understand that this is going to be a somewhat disruptive change for some addon developers, so please let us know your largest pain points and we'll try to make accommodations where possible.

**Other changes in 12.1 PTR 1**

- We now support showing SVG textures in our UI. They can be used on regular textures (e.g. `file="Path/To/Texture.svg"`) or with a new [VectorGraphics](https://warcraft.wiki.gg/wiki/UIOBJECT_VectorGraphics "UIOBJECT VectorGraphics") object type, which renders them at higher quality.

  - Note that the VectorGraphics objects don't currently support all of the APIs on regular Textures (rotation, masking, tex coords, etc.)

- Load-on-Demand addons can now specify that specific files in the TOC should load on startup through a new per-file `[Bootstrap]` directive.

  - This still requires that the addon be enabled in order for these files to load.

- [UIParent.lua](https://www.townlong-yak.com/framexml/ptr/go/UIParent.lua) has been heavily refactored, with all of the code that previously handled loading LoD addons moved into the addons themselves, taking advantage of the new `[Bootstrap]` directive.
- Added a new API [Frame:SetOnUpdateMode](https://warcraft.wiki.gg/wiki/API_Frame_SetOnUpdateMode "API Frame SetOnUpdateMode")(mode), which lets you specify when the `OnUpdate` script on a frame should run.
- The options are `Disabled`, `RunWhenVisible` (default), `RunWhenVisibleOnce`, `RunOnce`, and `RunAlways`
- A new system has been added called the Roleset System, which allows you to tag a frame as being part of a "roleset". You can then use the new [C\_Roleset.ApplyRolesetFilters](https://warcraft.wiki.gg/wiki/API_C_Roleset.ApplyRolesetFilters "API C Roleset.ApplyRolesetFilters") to specify which rolesets are currently active.

  - Frames in an inactive roleset will never be shown, regardless of their shown state. See [Blizzard\_UIModeManager.lua](https://www.townlong-yak.com/framexml/ptr/go/Blizzard_UIModeManager.lua) for more details and examples.

- Radial masking support has been added to textures and status bars, allowing them to have a radial mask applied to them without the need for hacky uses of cooldowns. Example usage on a texture:

```
texture:SetRadialProgressBarPercent(0.5);
texture:SetRadialProgressBarStartOffset(0.25);
texture:SetRadialProgressBarEndOffset(0.75);
texture:SetRadialProgressBarReverse(true);
texture:SetRadialProgressBarFeather(0.125);
```

Copy

- KeyValues can now specify that their value should be pulled directly from the private addon table. Example usage: `<KeyValue key="myKey" type="local"/>`
- Mixins can now be added on an object using a new `<Mixins>` element.

  - Using this element allows you to use the `source="local"` specifier to indicate the mixin lives in the private addon table.
  - Mixins added on an object (either through the Mixins element or the regular `mixin="myMixin"` attribute) can also now be nested within tables.

Example usage:

```
local _addonName, addonTbl = ...;

local CustomFrameMixin = {};
addonTbl.CustomFrameMixin = CustomFrameMixin;

local NestedMixin = {};
addonTbl.Mixins = {};
addonTbl.Mixins.NestedMixin = NestedMixin;
```

Copy

```
<Frame name="TestFrame">
    <Mixins>
        <Mixin key="CustomFrameMixin" source="local"/>
        <Mixin key="Mixins.NestedMixin" source="local"/>
    </Mixins>
</Frame>
```

Copy

## Consolidated changes

12.0.7 (68256) → PTR 12.1.0 (68209) Jun 15 2026

### Global API

| Added(89) | Removed(10) |
| --- | --- |
| [C\_BattleNet.AreFriendTagsEnabled](https://warcraft.wiki.gg/wiki/API_C_BattleNet.AreFriendTagsEnabled "API C BattleNet.AreFriendTagsEnabled")[C\_BattleNet.AreTitleFriendsEnabled](https://warcraft.wiki.gg/wiki/API_C_BattleNet.AreTitleFriendsEnabled "API C BattleNet.AreTitleFriendsEnabled")[C\_BattleNet.BNCheckTitleFriendInviteToUnit](https://warcraft.wiki.gg/wiki/API_C_BattleNet.BNCheckTitleFriendInviteToUnit "API C BattleNet.BNCheckTitleFriendInviteToUnit")[C\_BattleNet.GetFriendInviteInfo](https://warcraft.wiki.gg/wiki/API_C_BattleNet.GetFriendInviteInfo "API C BattleNet.GetFriendInviteInfo")[C\_BattleNet.IsBattleNetFriendsListEnabled](https://warcraft.wiki.gg/wiki/API_C_BattleNet.IsBattleNetFriendsListEnabled "API C BattleNet.IsBattleNetFriendsListEnabled")[C\_BattleNet.IsBattleNetFriendsListSupported](https://warcraft.wiki.gg/wiki/API_C_BattleNet.IsBattleNetFriendsListSupported "API C BattleNet.IsBattleNetFriendsListSupported")[C\_BattleNet.SendVerifiedBattleNetFriendInvite](https://warcraft.wiki.gg/wiki/API_C_BattleNet.SendVerifiedBattleNetFriendInvite "API C BattleNet.SendVerifiedBattleNetFriendInvite")[C\_BattleNet.SetFriendTags](https://warcraft.wiki.gg/wiki/API_C_BattleNet.SetFriendTags "API C BattleNet.SetFriendTags")[C\_CVar.AreCVarsLoaded](https://warcraft.wiki.gg/wiki/API_C_CVar.AreCVarsLoaded "API C CVar.AreCVarsLoaded")[C\_CooldownViewer.GetGroupBuffItems](https://warcraft.wiki.gg/wiki/API_C_CooldownViewer.GetGroupBuffItems "API C CooldownViewer.GetGroupBuffItems")[C\_DelvesUI.GetFlavorNodeForCompanion](https://warcraft.wiki.gg/wiki/API_C_DelvesUI.GetFlavorNodeForCompanion "API C DelvesUI.GetFlavorNodeForCompanion")[C\_DelvesUI.GetFlavorNodeNameForCompanion](https://warcraft.wiki.gg/wiki/API_C_DelvesUI.GetFlavorNodeNameForCompanion "API C DelvesUI.GetFlavorNodeNameForCompanion")[C\_Discord.Authorize](https://warcraft.wiki.gg/wiki/API_C_Discord.Authorize "API C Discord.Authorize")[C\_Discord.GetDiscordChannelName](https://warcraft.wiki.gg/wiki/API_C_Discord.GetDiscordChannelName "API C Discord.GetDiscordChannelName")[C\_Discord.GetDiscordUserID](https://warcraft.wiki.gg/wiki/API_C_Discord.GetDiscordUserID "API C Discord.GetDiscordUserID")[C\_Discord.GetDisplayNameType](https://warcraft.wiki.gg/wiki/API_C_Discord.GetDisplayNameType "API C Discord.GetDisplayNameType")[C\_Discord.GetGuildLinkStatus](https://warcraft.wiki.gg/wiki/API_C_Discord.GetGuildLinkStatus "API C Discord.GetGuildLinkStatus")[C\_Discord.GetNumDiscordChannels](https://warcraft.wiki.gg/wiki/API_C_Discord.GetNumDiscordChannels "API C Discord.GetNumDiscordChannels")[C\_Discord.GetNumDiscordServers](https://warcraft.wiki.gg/wiki/API_C_Discord.GetNumDiscordServers "API C Discord.GetNumDiscordServers")[C\_Discord.GetServerLinkableChannels](https://warcraft.wiki.gg/wiki/API_C_Discord.GetServerLinkableChannels "API C Discord.GetServerLinkableChannels")[C\_Discord.GetServerName](https://warcraft.wiki.gg/wiki/API_C_Discord.GetServerName "API C Discord.GetServerName")[C\_Discord.GuildLink](https://warcraft.wiki.gg/wiki/API_C_Discord.GuildLink "API C Discord.GuildLink")[C\_Discord.GuildUnlink](https://warcraft.wiki.gg/wiki/API_C_Discord.GuildUnlink "API C Discord.GuildUnlink")[C\_Discord.IsEnabled](https://warcraft.wiki.gg/wiki/API_C_Discord.IsEnabled "API C Discord.IsEnabled")[C\_Discord.IsGuildChannelLinked](https://warcraft.wiki.gg/wiki/API_C_Discord.IsGuildChannelLinked "API C Discord.IsGuildChannelLinked")[C\_Discord.IsGuildSettingSet](https://warcraft.wiki.gg/wiki/API_C_Discord.IsGuildSettingSet "API C Discord.IsGuildSettingSet")[C\_Discord.IsUserOAuthed](https://warcraft.wiki.gg/wiki/API_C_Discord.IsUserOAuthed "API C Discord.IsUserOAuthed")[C\_Discord.RefreshAuth](https://warcraft.wiki.gg/wiki/API_C_Discord.RefreshAuth "API C Discord.RefreshAuth")[C\_Discord.SetGuildSetting](https://warcraft.wiki.gg/wiki/API_C_Discord.SetGuildSetting "API C Discord.SetGuildSetting")[C\_Discord.UpdateDiscordServers](https://warcraft.wiki.gg/wiki/API_C_Discord.UpdateDiscordServers "API C Discord.UpdateDiscordServers")[C\_Discord.UpdateGuildLobby](https://warcraft.wiki.gg/wiki/API_C_Discord.UpdateGuildLobby "API C Discord.UpdateGuildLobby")[C\_DyeColor.GetDyeColorsForItemLocation](https://warcraft.wiki.gg/wiki/API_C_DyeColor.GetDyeColorsForItemLocation "API C DyeColor.GetDyeColorsForItemLocation")[C\_DyeColor.GetDyeColorsForItem](https://warcraft.wiki.gg/wiki/API_C_DyeColor.GetDyeColorsForItem "API C DyeColor.GetDyeColorsForItem")[C\_GuildInfo.IsDiscordStreamSeparate](https://warcraft.wiki.gg/wiki/API_C_GuildInfo.IsDiscordStreamSeparate "API C GuildInfo.IsDiscordStreamSeparate")[C\_Housing.HouseFinderIgnoreNeighborhood](https://warcraft.wiki.gg/wiki/API_C_Housing.HouseFinderIgnoreNeighborhood "API C Housing.HouseFinderIgnoreNeighborhood")[C\_Housing.IsInsideOwnedHouseOrPlot](https://warcraft.wiki.gg/wiki/API_C_Housing.IsInsideOwnedHouseOrPlot "API C Housing.IsInsideOwnedHouseOrPlot")[C\_Housing.IsInsideOwnedHouse](https://warcraft.wiki.gg/wiki/API_C_Housing.IsInsideOwnedHouse "API C Housing.IsInsideOwnedHouse")[C\_Housing.IsInsideOwnedPlot](https://warcraft.wiki.gg/wiki/API_C_Housing.IsInsideOwnedPlot "API C Housing.IsInsideOwnedPlot")[C\_Housing.ResetHouse](https://warcraft.wiki.gg/wiki/API_C_Housing.ResetHouse "API C Housing.ResetHouse")[C\_HousingBlueprint.CanImportTypeFromCurrentLocation](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.CanImportTypeFromCurrentLocation "API C HousingBlueprint.CanImportTypeFromCurrentLocation")[C\_HousingBlueprint.DeleteBlueprint](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.DeleteBlueprint "API C HousingBlueprint.DeleteBlueprint")[C\_HousingBlueprint.ExportBlueprint](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.ExportBlueprint "API C HousingBlueprint.ExportBlueprint")[C\_HousingBlueprint.ExportRoomBlueprint](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.ExportRoomBlueprint "API C HousingBlueprint.ExportRoomBlueprint")[C\_HousingBlueprint.GetBlueprintHyperlink](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.GetBlueprintHyperlink "API C HousingBlueprint.GetBlueprintHyperlink")[C\_HousingBlueprint.GetBlueprintTypeForCode](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.GetBlueprintTypeForCode "API C HousingBlueprint.GetBlueprintTypeForCode")[C\_HousingBlueprint.ImportBlueprint](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.ImportBlueprint "API C HousingBlueprint.ImportBlueprint")[C\_HousingBlueprint.IsExportAvailable](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.IsExportAvailable "API C HousingBlueprint.IsExportAvailable")[C\_HousingBlueprint.IsImportAvailable](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.IsImportAvailable "API C HousingBlueprint.IsImportAvailable")[C\_HousingBlueprint.IsShareCodeValid](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.IsShareCodeValid "API C HousingBlueprint.IsShareCodeValid")[C\_HousingBlueprint.RenameBlueprint](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.RenameBlueprint "API C HousingBlueprint.RenameBlueprint")[C\_HousingBlueprint.RequestBlueprintCollection](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.RequestBlueprintCollection "API C HousingBlueprint.RequestBlueprintCollection")[C\_HousingBlueprint.RequestBlueprintContentsForContext](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.RequestBlueprintContentsForContext "API C HousingBlueprint.RequestBlueprintContentsForContext")[C\_HousingBlueprint.RequestBlueprintContents](https://warcraft.wiki.gg/wiki/API_C_HousingBlueprint.RequestBlueprintContents "API C HousingBlueprint.RequestBlueprintContents")[C\_HousingCustomizeMode.ApplyPetToSelectedDecor](https://warcraft.wiki.gg/wiki/API_C_HousingCustomizeMode.ApplyPetToSelectedDecor "API C HousingCustomizeMode.ApplyPetToSelectedDecor")[C\_HousingCustomizeMode.GetSelectedDecorPetInfo](https://warcraft.wiki.gg/wiki/API_C_HousingCustomizeMode.GetSelectedDecorPetInfo "API C HousingCustomizeMode.GetSelectedDecorPetInfo")[C\_HousingDecor.AnyDecorPlacedInRoom](https://warcraft.wiki.gg/wiki/API_C_HousingDecor.AnyDecorPlacedInRoom "API C HousingDecor.AnyDecorPlacedInRoom")[C\_HousingDecor.GetBothMaxPlacementBudgets](https://warcraft.wiki.gg/wiki/API_C_HousingDecor.GetBothMaxPlacementBudgets "API C HousingDecor.GetBothMaxPlacementBudgets")[C\_HousingDecor.GetDecorAssignedPetName](https://warcraft.wiki.gg/wiki/API_C_HousingDecor.GetDecorAssignedPetName "API C HousingDecor.GetDecorAssignedPetName")[C\_HousingDecor.GetDecorCanAttachPet](https://warcraft.wiki.gg/wiki/API_C_HousingDecor.GetDecorCanAttachPet "API C HousingDecor.GetDecorCanAttachPet")[C\_HousingDecor.GetMaxPetPlacementBudget](https://warcraft.wiki.gg/wiki/API_C_HousingDecor.GetMaxPetPlacementBudget "API C HousingDecor.GetMaxPetPlacementBudget")[C\_HousingDecor.GetSpentPetPlacementBudget](https://warcraft.wiki.gg/wiki/API_C_HousingDecor.GetSpentPetPlacementBudget "API C HousingDecor.GetSpentPetPlacementBudget")[C\_HousingLayout.GetBaseRoomFloor](https://warcraft.wiki.gg/wiki/API_C_HousingLayout.GetBaseRoomFloor "API C HousingLayout.GetBaseRoomFloor")[C\_HousingLayout.GetRoomPlayerIsIn](https://warcraft.wiki.gg/wiki/API_C_HousingLayout.GetRoomPlayerIsIn "API C HousingLayout.GetRoomPlayerIsIn")[C\_Item.DoesItemMatchSpellItemCondition](https://warcraft.wiki.gg/wiki/API_C_Item.DoesItemMatchSpellItemCondition "API C Item.DoesItemMatchSpellItemCondition")[C\_LFGList.ConfirmCensoredActiveEntry](https://warcraft.wiki.gg/wiki/API_C_LFGList.ConfirmCensoredActiveEntry "API C LFGList.ConfirmCensoredActiveEntry")[C\_LFGList.DoesCensoredTextMatch](https://warcraft.wiki.gg/wiki/API_C_LFGList.DoesCensoredTextMatch "API C LFGList.DoesCensoredTextMatch")[C\_LFGList.IsCensoredActiveEntryUnresolved](https://warcraft.wiki.gg/wiki/API_C_LFGList.IsCensoredActiveEntryUnresolved "API C LFGList.IsCensoredActiveEntryUnresolved")[C\_LFGList.RevealCensoredActiveEntry](https://warcraft.wiki.gg/wiki/API_C_LFGList.RevealCensoredActiveEntry "API C LFGList.RevealCensoredActiveEntry")[C\_LFGList.RevealCensoredSearchResult](https://warcraft.wiki.gg/wiki/API_C_LFGList.RevealCensoredSearchResult "API C LFGList.RevealCensoredSearchResult")[C\_PaperDollInfo.GetInventorySlotInfoForInvSlot](https://warcraft.wiki.gg/wiki/API_C_PaperDollInfo.GetInventorySlotInfoForInvSlot "API C PaperDollInfo.GetInventorySlotInfoForInvSlot")[C\_PaperDollInfo.GetInventorySlotInfo](https://warcraft.wiki.gg/wiki/API_C_PaperDollInfo.GetInventorySlotInfo "API C PaperDollInfo.GetInventorySlotInfo")[C\_PetJournal.GetPetInfoTableBySpeciesID](https://warcraft.wiki.gg/wiki/API_C_PetJournal.GetPetInfoTableBySpeciesID "API C PetJournal.GetPetInfoTableBySpeciesID")[C\_PvP.CanSurrenderArena](https://warcraft.wiki.gg/wiki/API_C_PvP.CanSurrenderArena "API C PvP.CanSurrenderArena")[C\_QuestHub.IsAreaPOICurrentlyRelatedToHub](https://warcraft.wiki.gg/wiki/API_C_QuestHub.IsAreaPOICurrentlyRelatedToHub "API C QuestHub.IsAreaPOICurrentlyRelatedToHub")[C\_RecruitAFriend.IsSystemEnabled](https://warcraft.wiki.gg/wiki/API_C_RecruitAFriend.IsSystemEnabled "API C RecruitAFriend.IsSystemEnabled")[C\_RecruitAFriend.IsSystemSupported](https://warcraft.wiki.gg/wiki/API_C_RecruitAFriend.IsSystemSupported "API C RecruitAFriend.IsSystemSupported")[C\_Roleset.ApplyRolesetFilters](https://warcraft.wiki.gg/wiki/API_C_Roleset.ApplyRolesetFilters "API C Roleset.ApplyRolesetFilters")[C\_SocialQueue.IsSystemEnabled](https://warcraft.wiki.gg/wiki/API_C_SocialQueue.IsSystemEnabled "API C SocialQueue.IsSystemEnabled")[C\_SocialQueue.IsSystemSupported](https://warcraft.wiki.gg/wiki/API_C_SocialQueue.IsSystemSupported "API C SocialQueue.IsSystemSupported")[C\_SocialRestrictions.IsFriendsDisabled](https://warcraft.wiki.gg/wiki/API_C_SocialRestrictions.IsFriendsDisabled "API C SocialRestrictions.IsFriendsDisabled")[C\_SocialUI.IsSystemEnabled](https://warcraft.wiki.gg/wiki/API_C_SocialUI.IsSystemEnabled "API C SocialUI.IsSystemEnabled")[C\_Sound.PlaySoundWithOptions](https://warcraft.wiki.gg/wiki/API_C_Sound.PlaySoundWithOptions "API C Sound.PlaySoundWithOptions")[C\_Spell.TargetSpellChecksItemCondition](https://warcraft.wiki.gg/wiki/API_C_Spell.TargetSpellChecksItemCondition "API C Spell.TargetSpellChecksItemCondition")[C\_UnitAuras.GetGroupBuffVisualAlerts](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetGroupBuffVisualAlerts "API C UnitAuras.GetGroupBuffVisualAlerts")[C\_UnitAuras.GetHiddenGroupBuffs](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetHiddenGroupBuffs "API C UnitAuras.GetHiddenGroupBuffs")[C\_UnitAuras.SetGroupBuffVisualAlerts](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.SetGroupBuffVisualAlerts "API C UnitAuras.SetGroupBuffVisualAlerts")[C\_UnitAuras.SetHiddenGroupBuffs](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.SetHiddenGroupBuffs "API C UnitAuras.SetHiddenGroupBuffs")[GetSpecializationSystem](https://warcraft.wiki.gg/wiki/API_GetSpecializationSystem "API GetSpecializationSystem")[securecopy](https://warcraft.wiki.gg/wiki/API_securecopy "API securecopy") | [BNGetFriendInviteInfo](https://warcraft.wiki.gg/wiki/API_BNGetFriendInviteInfo "API BNGetFriendInviteInfo")[BNSendVerifiedBattleTagInvite](https://warcraft.wiki.gg/wiki/API_BNSendVerifiedBattleTagInvite "API BNSendVerifiedBattleTagInvite")[C\_DyeColor.GetDyeColorForItemLocation](https://warcraft.wiki.gg/wiki/API_C_DyeColor.GetDyeColorForItemLocation "API C DyeColor.GetDyeColorForItemLocation")[C\_DyeColor.GetDyeColorForItem](https://warcraft.wiki.gg/wiki/API_C_DyeColor.GetDyeColorForItem "API C DyeColor.GetDyeColorForItem")[C\_Housing.IsInsideOwnHouse](https://warcraft.wiki.gg/wiki/API_C_Housing.IsInsideOwnHouse "API C Housing.IsInsideOwnHouse")[C\_Ping.GetContextualPingTypeForUnit](https://warcraft.wiki.gg/wiki/API_C_Ping.GetContextualPingTypeForUnit "API C Ping.GetContextualPingTypeForUnit")[C\_RecruitAFriend.IsEnabled](https://warcraft.wiki.gg/wiki/API_C_RecruitAFriend.IsEnabled "API C RecruitAFriend.IsEnabled")[C\_UnitAuras.TriggerPrivateAuraShowDispelType](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.TriggerPrivateAuraShowDispelType "API C UnitAuras.TriggerPrivateAuraShowDispelType")CanSurrenderArena[GetInventorySlotInfo](https://warcraft.wiki.gg/wiki/API_GetInventorySlotInfo "API GetInventorySlotInfo") |

```
C_ActionBar.ForceUpdateAction
  + arg2 = suppressEvents
C_CombatAudioAlert.SpeakText
  + ret1 = utteranceID
  + MayReturnNothing
C_HousingDecor.GetMaxPlacementBudget
  # ret1.Nilable false -> true
C_HousingDecor.GetSpentPlacementBudget
  # ret1.Nilable false -> true
C_HousingLayout.GetRoomPlacementBudget
  # ret1.Nilable false -> true
C_HousingLayout.GetSpentPlacementBudget
  # ret1.Nilable false -> true
C_Ping.SendMacroPing
  # arg1.Name type -> macroInfo
  # arg1.Nilable true -> false
  # arg1.Type PingSubjectType -> PingMacroInfo
  - arg2 = targetToken
C_QuestHub.IsQuestCurrentlyRelatedToHub
  # arg2.Name areaPoiID -> hubAreaPoiID
C_RecruitAFriend.CanSummonFriend
  # ret1.Name result -> canSummon
  + ret2 = reason
  + MayReturnNothing
C_Sound.PlaySound
  + arg6 = volumeOverride
C_Spell.GetSpellTexture
  + ret3 = conditionalIconID
CreateSecureDelegate
  + arg2 = options
```

### ScriptObjects

| Added(8) | Removed(0) |
| --- | --- |
| [RadialProgress:GetFromPercent](https://warcraft.wiki.gg/wiki/API_RadialProgress_GetFromPercent "API RadialProgress GetFromPercent")[RadialProgress:GetToPercent](https://warcraft.wiki.gg/wiki/API_RadialProgress_GetToPercent "API RadialProgress GetToPercent")[RadialProgress:SetFromPercent](https://warcraft.wiki.gg/wiki/API_RadialProgress_SetFromPercent "API RadialProgress SetFromPercent")[RadialProgress:SetToPercent](https://warcraft.wiki.gg/wiki/API_RadialProgress_SetToPercent "API RadialProgress SetToPercent")[DurationTextBinding:ClearTextColorCurve](https://warcraft.wiki.gg/wiki/API_DurationTextBinding_ClearTextColorCurve "API DurationTextBinding ClearTextColorCurve")[DurationTextBinding:GetFormattedTextColor](https://warcraft.wiki.gg/wiki/API_DurationTextBinding_GetFormattedTextColor "API DurationTextBinding GetFormattedTextColor")[DurationTextBinding:GetTextColorCurve](https://warcraft.wiki.gg/wiki/API_DurationTextBinding_GetTextColorCurve "API DurationTextBinding GetTextColorCurve")[DurationTextBinding:SetTextColorCurve](https://warcraft.wiki.gg/wiki/API_DurationTextBinding_SetTextColorCurve "API DurationTextBinding SetTextColorCurve") |  |

### Widgets

| Added(29) | Removed(0) |
| --- | --- |
| [FrameScriptObject:AddForbiddenAspects](https://warcraft.wiki.gg/wiki/API_FrameScriptObject_AddForbiddenAspects "API FrameScriptObject AddForbiddenAspects")[FrameScriptObject:GetObjectTable](https://warcraft.wiki.gg/wiki/API_FrameScriptObject_GetObjectTable "API FrameScriptObject GetObjectTable")[FrameScriptObject:HasAnyForbiddenAspect](https://warcraft.wiki.gg/wiki/API_FrameScriptObject_HasAnyForbiddenAspect "API FrameScriptObject HasAnyForbiddenAspect")[FrameScriptObject:HasAnyForbiddenAspects](https://warcraft.wiki.gg/wiki/API_FrameScriptObject_HasAnyForbiddenAspects "API FrameScriptObject HasAnyForbiddenAspects")[TextureBase:ClearRadialProgressBar](https://warcraft.wiki.gg/wiki/API_TextureBase_ClearRadialProgressBar "API TextureBase ClearRadialProgressBar")[TextureBase:GetRadialProgressBarEndOffset](https://warcraft.wiki.gg/wiki/API_TextureBase_GetRadialProgressBarEndOffset "API TextureBase GetRadialProgressBarEndOffset")[TextureBase:GetRadialProgressBarFeather](https://warcraft.wiki.gg/wiki/API_TextureBase_GetRadialProgressBarFeather "API TextureBase GetRadialProgressBarFeather")[TextureBase:GetRadialProgressBarPercent](https://warcraft.wiki.gg/wiki/API_TextureBase_GetRadialProgressBarPercent "API TextureBase GetRadialProgressBarPercent")[TextureBase:GetRadialProgressBarReverse](https://warcraft.wiki.gg/wiki/API_TextureBase_GetRadialProgressBarReverse "API TextureBase GetRadialProgressBarReverse")[TextureBase:GetRadialProgressBarStartOffset](https://warcraft.wiki.gg/wiki/API_TextureBase_GetRadialProgressBarStartOffset "API TextureBase GetRadialProgressBarStartOffset")[TextureBase:SetRadialProgressBarEndOffset](https://warcraft.wiki.gg/wiki/API_TextureBase_SetRadialProgressBarEndOffset "API TextureBase SetRadialProgressBarEndOffset")[TextureBase:SetRadialProgressBarFeather](https://warcraft.wiki.gg/wiki/API_TextureBase_SetRadialProgressBarFeather "API TextureBase SetRadialProgressBarFeather")[TextureBase:SetRadialProgressBarPercent](https://warcraft.wiki.gg/wiki/API_TextureBase_SetRadialProgressBarPercent "API TextureBase SetRadialProgressBarPercent")[TextureBase:SetRadialProgressBarReverse](https://warcraft.wiki.gg/wiki/API_TextureBase_SetRadialProgressBarReverse "API TextureBase SetRadialProgressBarReverse")[TextureBase:SetRadialProgressBarStartOffset](https://warcraft.wiki.gg/wiki/API_TextureBase_SetRadialProgressBarStartOffset "API TextureBase SetRadialProgressBarStartOffset")[Frame:AddRoleset](https://warcraft.wiki.gg/wiki/API_Frame_AddRoleset "API Frame AddRoleset")[Frame:CreateVectorGraphics](https://warcraft.wiki.gg/wiki/API_Frame_CreateVectorGraphics "API Frame CreateVectorGraphics")[Frame:GetOnUpdateMode](https://warcraft.wiki.gg/wiki/API_Frame_GetOnUpdateMode "API Frame GetOnUpdateMode")[Frame:GetRolesetNames](https://warcraft.wiki.gg/wiki/API_Frame_GetRolesetNames "API Frame GetRolesetNames")[Frame:RemoveRoleset](https://warcraft.wiki.gg/wiki/API_Frame_RemoveRoleset "API Frame RemoveRoleset")[Frame:SetOnUpdateMode](https://warcraft.wiki.gg/wiki/API_Frame_SetOnUpdateMode "API Frame SetOnUpdateMode")[Frame:SetRolesets](https://warcraft.wiki.gg/wiki/API_Frame_SetRolesets "API Frame SetRolesets")[Minimap:SetIconScale](https://warcraft.wiki.gg/wiki/API_Minimap_SetIconScale "API Minimap SetIconScale")[StatusBar:GetRenderMode](https://warcraft.wiki.gg/wiki/API_StatusBar_GetRenderMode "API StatusBar GetRenderMode")[StatusBar:SetRenderMode](https://warcraft.wiki.gg/wiki/API_StatusBar_SetRenderMode "API StatusBar SetRenderMode")[VectorGraphics:ClearSVG](https://warcraft.wiki.gg/wiki/API_VectorGraphics_ClearSVG "API VectorGraphics ClearSVG")[VectorGraphics:GetSVGFileID](https://warcraft.wiki.gg/wiki/API_VectorGraphics_GetSVGFileID "API VectorGraphics GetSVGFileID")[VectorGraphics:HasSVG](https://warcraft.wiki.gg/wiki/API_VectorGraphics_HasSVG "API VectorGraphics HasSVG")[VectorGraphics:SetSVG](https://warcraft.wiki.gg/wiki/API_VectorGraphics_SetSVG "API VectorGraphics SetSVG") |  |

```
Animation:GetScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Nilable true -> false
  # arg2.Type number -> ScriptBindingType
  + arg2.Default = Extrinsic
  # ret1.Type luaFunction -> LuaFunctionReference
  + ChecksForbiddenAspects
  + RequiresSupportedScript
Animation:HookScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Type luaFunction -> LuaFunctionReference
  # arg3.Nilable true -> false
  # arg3.Type number -> ScriptBindingType
  + arg3.Default = Extrinsic
  + ChecksForbiddenAspects
  + ret1 = success
  + RequiresAssignableScript
  # SecretArguments AllowedWhenUntainted -> NotAllowed
Animation:SetScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Type luaFunction -> LuaFunctionReference
  + ChecksForbiddenAspects
  + RequiresAssignableScript
  # SecretArguments AllowedWhenUntainted -> NotAllowed
AnimationGroup:GetScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Nilable true -> false
  # arg2.Type number -> ScriptBindingType
  + arg2.Default = Extrinsic
  # ret1.Type luaFunction -> LuaFunctionReference
  + ChecksForbiddenAspects
  + RequiresSupportedScript
AnimationGroup:HookScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Type luaFunction -> LuaFunctionReference
  # arg3.Nilable true -> false
  # arg3.Type number -> ScriptBindingType
  + arg3.Default = Extrinsic
  + ret1 = success
  + ChecksForbiddenAspects
  + RequiresAssignableScript
  # SecretArguments AllowedWhenUntainted -> NotAllowed
AnimationGroup:SetScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Type luaFunction -> LuaFunctionReference
  + ChecksForbiddenAspects
  + RequiresAssignableScript
  # SecretArguments AllowedWhenUntainted -> NotAllowed
FrameScriptObject:SetToDefaults
  + ChecksForbiddenAspects
ScriptRegion:ClearScripts
  + ChecksForbiddenAspects
ScriptRegion:GetScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Nilable true -> false
  # arg2.Type number -> ScriptBindingType
  + arg2.Default = Extrinsic
  # ret1.Type luaFunction -> LuaFunctionReference
  + ChecksForbiddenAspects
  + RequiresSupportedScript
ScriptRegion:HookScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Type luaFunction -> LuaFunctionReference
  # arg3.Nilable true -> false
  # arg3.Type number -> ScriptBindingType
  + arg3.Default = Extrinsic
  + ret1 = success
  + ChecksForbiddenAspects
  + RequiresAssignableScript
  # SecretArguments AllowedWhenUntainted -> NotAllowed
ScriptRegion:SetScript
  # arg1.Type cstring -> ScriptTypeName
  # arg2.Type luaFunction -> LuaFunctionReference
  + ChecksForbiddenAspects
  + RequiresAssignableScript
  # SecretArguments AllowedWhenUntainted -> NotAllowed
```

### Events

| Added(35) | Removed(1) |
| --- | --- |
| [BATTLE\_NET\_FRIEND\_TAG\_ENABLED\_STATUS\_UPDATED](https://warcraft.wiki.gg/wiki/BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED "BATTLE NET FRIEND TAG ENABLED STATUS UPDATED")[CHAT\_MSG\_GUILD\_DISCORD](https://warcraft.wiki.gg/wiki/CHAT_MSG_GUILD_DISCORD "CHAT MSG GUILD DISCORD")[CONFIRM\_BATTLE\_NET\_FRIEND\_INVITE\_SHOW](https://warcraft.wiki.gg/wiki/CONFIRM_BATTLE_NET_FRIEND_INVITE_SHOW "CONFIRM BATTLE NET FRIEND INVITE SHOW")[DISCORD\_GUILD\_ACHIEVEMENT](https://warcraft.wiki.gg/wiki/DISCORD_GUILD_ACHIEVEMENT "DISCORD GUILD ACHIEVEMENT")[DISCORD\_GUILD\_LOBBY\_UPDATE](https://warcraft.wiki.gg/wiki/DISCORD_GUILD_LOBBY_UPDATE "DISCORD GUILD LOBBY UPDATE")[DISCORD\_GUILD\_SETTINGS\_UPDATE](https://warcraft.wiki.gg/wiki/DISCORD_GUILD_SETTINGS_UPDATE "DISCORD GUILD SETTINGS UPDATE")[DISCORD\_LINK\_UPDATE](https://warcraft.wiki.gg/wiki/DISCORD_LINK_UPDATE "DISCORD LINK UPDATE")[DISCORD\_SERVER\_LIST\_UPDATE](https://warcraft.wiki.gg/wiki/DISCORD_SERVER_LIST_UPDATE "DISCORD SERVER LIST UPDATE")[DISCORD\_STATUS\_UPDATE](https://warcraft.wiki.gg/wiki/DISCORD_STATUS_UPDATE "DISCORD STATUS UPDATE")[GROUP\_BUFF\_VISUAL\_ALERTS\_CHANGED](https://warcraft.wiki.gg/wiki/GROUP_BUFF_VISUAL_ALERTS_CHANGED "GROUP BUFF VISUAL ALERTS CHANGED")[GUILD\_RANKS\_UPDATE\_ACTIVE\_PLAYER](https://warcraft.wiki.gg/wiki/GUILD_RANKS_UPDATE_ACTIVE_PLAYER "GUILD RANKS UPDATE ACTIVE PLAYER")[HIDDEN\_GROUP\_BUFFS\_CHANGED](https://warcraft.wiki.gg/wiki/HIDDEN_GROUP_BUFFS_CHANGED "HIDDEN GROUP BUFFS CHANGED")[HOUSE\_RESET\_COMPLETED](https://warcraft.wiki.gg/wiki/HOUSE_RESET_COMPLETED "HOUSE RESET COMPLETED")[HOUSE\_RESET\_FAILED](https://warcraft.wiki.gg/wiki/HOUSE_RESET_FAILED "HOUSE RESET FAILED")[HOUSING\_BLUEPRINT\_COLLECTION\_FAILURE](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_COLLECTION_FAILURE "HOUSING BLUEPRINT COLLECTION FAILURE")[HOUSING\_BLUEPRINT\_COLLECTION\_RECEIVED](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_COLLECTION_RECEIVED "HOUSING BLUEPRINT COLLECTION RECEIVED")[HOUSING\_BLUEPRINT\_CONTENTS\_FAILURE](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_CONTENTS_FAILURE "HOUSING BLUEPRINT CONTENTS FAILURE")[HOUSING\_BLUEPRINT\_CONTENTS\_RECEIVED](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_CONTENTS_RECEIVED "HOUSING BLUEPRINT CONTENTS RECEIVED")[HOUSING\_BLUEPRINT\_DELETE\_FAILURE](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_DELETE_FAILURE "HOUSING BLUEPRINT DELETE FAILURE")[HOUSING\_BLUEPRINT\_DELETE\_SUCCESS](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_DELETE_SUCCESS "HOUSING BLUEPRINT DELETE SUCCESS")[HOUSING\_BLUEPRINT\_EXPORT\_FAILURE](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_EXPORT_FAILURE "HOUSING BLUEPRINT EXPORT FAILURE")[HOUSING\_BLUEPRINT\_EXPORT\_SUCCESS](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_EXPORT_SUCCESS "HOUSING BLUEPRINT EXPORT SUCCESS")[HOUSING\_BLUEPRINT\_IMPORT\_FAILURE](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_IMPORT_FAILURE "HOUSING BLUEPRINT IMPORT FAILURE")[HOUSING\_BLUEPRINT\_IMPORT\_SUCCESS](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_IMPORT_SUCCESS "HOUSING BLUEPRINT IMPORT SUCCESS")[HOUSING\_BLUEPRINT\_RENAME\_FAILURE](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_RENAME_FAILURE "HOUSING BLUEPRINT RENAME FAILURE")[HOUSING\_BLUEPRINT\_RENAME\_SUCCESS](https://warcraft.wiki.gg/wiki/HOUSING_BLUEPRINT_RENAME_SUCCESS "HOUSING BLUEPRINT RENAME SUCCESS")[HOUSING\_NEW\_DECOR\_PLACE\_COMPLETE](https://warcraft.wiki.gg/wiki/HOUSING_NEW_DECOR_PLACE_COMPLETE "HOUSING NEW DECOR PLACE COMPLETE")[IGNORE\_NEIGHBORHOOD\_RESPONSE](https://warcraft.wiki.gg/wiki/IGNORE_NEIGHBORHOOD_RESPONSE "IGNORE NEIGHBORHOOD RESPONSE")[LFG\_LIST\_CENSORED\_ACTIVE\_ENTRY\_UPDATE](https://warcraft.wiki.gg/wiki/LFG_LIST_CENSORED_ACTIVE_ENTRY_UPDATE "LFG LIST CENSORED ACTIVE ENTRY UPDATE")[LFG\_LIST\_REVEALED\_CENSORED\_ACTIVE\_ENTRY](https://warcraft.wiki.gg/wiki/LFG_LIST_REVEALED_CENSORED_ACTIVE_ENTRY "LFG LIST REVEALED CENSORED ACTIVE ENTRY")[SOCIAL\_UI\_FRIENDS\_LIST\_SYSTEM\_STATUS\_UPDATED](https://warcraft.wiki.gg/wiki/SOCIAL_UI_FRIENDS_LIST_SYSTEM_STATUS_UPDATED "SOCIAL UI FRIENDS LIST SYSTEM STATUS UPDATED")[SOCIAL\_UI\_SOCIAL\_QUEUE\_SYSTEM\_STATUS\_UPDATED](https://warcraft.wiki.gg/wiki/SOCIAL_UI_SOCIAL_QUEUE_SYSTEM_STATUS_UPDATED "SOCIAL UI SOCIAL QUEUE SYSTEM STATUS UPDATED")[SOCIAL\_UI\_SYSTEM\_STATUS\_UPDATED](https://warcraft.wiki.gg/wiki/SOCIAL_UI_SYSTEM_STATUS_UPDATED "SOCIAL UI SYSTEM STATUS UPDATED")UNIT\_PING\_PIN\_ADDEDUNIT\_PING\_PIN\_REMOVED | [BATTLETAG\_INVITE\_SHOW](https://warcraft.wiki.gg/wiki/BATTLETAG_INVITE_SHOW "BATTLETAG INVITE SHOW") |

```
CHAT_MSG_*
  + discordInfo
SPELL_UPDATE_COOLDOWN
  + itemID
```

### CVars

| Added(19) | Removed(2) |
| --- | --- |
| accessibilityScreenNarrationEnabledCVar: accessibilityScreenNarrationEnabled (Game)<br>Default: `1`<br>Enables screen narration for accessibilityaccessibilityScreenNarrationSpeechRateCVar: accessibilityScreenNarrationSpeechRate (Game)<br>Default: `0`<br>Speed at which voice narration speaksaccessibilityScreenNarrationSpeechVolumeCVar: accessibilityScreenNarrationSpeechVolume (Game)<br>Default: `100`<br>Volume at which voice narration speaksaccessibilityScreenNarrationVoiceCVar: accessibilityScreenNarrationVoice (Game)<br>Default: `1`<br>Voice option used with screen narrationdiscordClientEnabledCVar: discordClientEnabled (Debug)<br>Default: `1`<br>Enable the discord client integrationdiscordDisplayNameCVar: discordDisplayName (Game)<br>Default: `0`<br>The name to show for text from you in-game from DiscordnameplateCheckDistanceForTargetCVar: nameplateCheckDistanceForTarget (Game)<br>Default: `0`<br>If false, show our target's nameplate even if they're very far away.nameplateForceShowUnitNameCVar: nameplateForceShowUnitName (Game)<br>Default: `0`<br>If true, nameplates will always show the unit name regardless of other unit name settings.nameplateNotSelectedAlphaCVar: nameplateNotSelectedAlpha (Game)<br>Default: `-1.000000`<br>When you have a target, the alpha of other nameplates (not used if value is negative).nameplatePlayRemovalAnimationCVar: nameplatePlayRemovalAnimation (Game)<br>Default: `1`<br>If true, play a scale/alpha animation when a nameplate is removed. If false, remove the nameplate instantly.nameplateShowAllPersonalAurasCVar: nameplateShowAllPersonalAuras (Game)<br>Default: `0`<br>If true, show all personal auras on nameplates, regardless of whether they are normally flagged to be shown.nameplateShowFriendlyRealmNameCVar: nameplateShowFriendlyRealmName (Game)<br>Default: `1`, Scope: Account<br>Used to show or hide the realm name in friendly player unit nameplate names.nameplateShowFriendsCVar: nameplateShowFriends (Game)pingTargetCVar: pingTarget (Game)<br>Default: `0`<br>Determines how pinging in the world should behave for the ping system.showPingsOnRaidFramesCVar: showPingsOnRaidFrames (Game)<br>Default: `1`<br>Enables ping details being shown on raid frames.showScreenNarrationDialogCVar: showScreenNarrationDialog (Game)<br>Default: `1`<br>Show screen narration dialog on startuptaintLogObjectSecretsCVar: taintLogObjectSecrets (Debug)<br>Default: `0`<br>If enabled, include additional taint log entries when script objects gain secret aspects or values.userFontScaleGlueCVar: userFontScaleGlue (Game)<br>Default: `1.390000`<br>glues: Defines the scale of the font used in places around the UI where readability requires larger defaults which are still customizable by the user.[![Test](https://warcraft.wiki.gg/images/Test-inline.png?3b2330)](https://warcraft.wiki.gg/wiki/Public_Test_Realm "Test") AftermathShaderDebugCVar: AftermathShaderDebug<br>Default: `0`<br>Enables NVIDIA Aftermath shader debugging | lastLockedDelvesCompanionAbilitiesCVar: lastLockedDelvesCompanionAbilities (Game)<br>Stores the nodeIDs of the locked delve companion abilities, to highlight them when unlocked.SlugSupersamplingCVar: SlugSupersampling (Debug)<br>Default: `1`<br>The slug glyph shader performs adaptive supersampling for high-quality rendering at small font sizes |

### Enumerations

```
Enum.ClubStreamType (C_Club.GetStreamInfo, C_Club.GetStreams)
  + Discord
Enum.CompanionConfigSlotTypes (C_DelvesUI.GetUnseenCuriosBySlotType, C_DelvesUI.SaveSeenCuriosBySlotType)
  + Flavor
Enum.CooldownViewerCategory (C_CooldownViewer.GetCooldownViewerCategorySet, C_CooldownViewer.GetCooldownViewerCooldownInfo)
  + GroupBuff
  + SpecAgnosticEssential
  + SpecAgnosticTracked
  + EquipSlotEssential
  + EquipSlotTracked
Enum.EditModeAccountSetting (C_EditMode.SetAccountSetting)
  + ShowRaidWarning
Enum.EditModeMinimapSetting
  + IconScale
Enum.EditModeSystem (C_EditMode.ConvertLayoutInfoToString, C_EditMode.ConvertStringToLayoutInfo, C_EditMode.GetLayouts, C_EditMode.SaveLayouts, EDIT_MODE_LAYOUTS_UPDATED)
  + RaidWarning
Enum.EditModeUnitFrameSetting
  - IconSize
  + BuffIconSize
  + DebuffIconSize
Enum.FragmentID
  + FMapObject
  + FWorldStateListenerData
Enum.FrameTutorialAccount
  + HousingPetBeds
Enum.HouseFinderSuggestionReason (C_HousingNeighborhood.GetCornerstoneNeighborhoodInfo, B_NET_NEIGHBORHOOD_LIST_UPDATED, NEIGHBORHOOD_INFO_UPDATED, NEIGHBORHOOD_LIST_UPDATED, OPEN_NEIGHBORHOOD_CHARTER, OPEN_NEIGHBORHOOD_CHARTER_SIGNATURE_REQUEST, UPDATE_BULLETIN_BOARD_ROSTER)
  + Relinquished
Enum.HousingResult (C_HouseEditor.ActivateHouseEditorMode, C_HouseEditor.EnterHouseEditor, C_HouseEditor.GetHouseEditorAvailability, C_HouseEditor.GetHouseEditorModeAvailability, B_NET_NEIGHBORHOOD_LIST_UPDATED, CREATE_NEIGHBORHOOD_RESULT, HOUSE_EDITOR_MODE_CHANGE_FAILURE, HOUSE_EXTERIOR_POSITION_FAILURE, HOUSE_RESERVATION_RESPONSE_RECIEVED, HOUSE_RESET_FAILED, HOUSING_BLUEPRINT_COLLECTION_FAILURE, HOUSING_BLUEPRINT_CONTENTS_FAILURE, HOUSING_BLUEPRINT_DELETE_FAILURE, HOUSING_BLUEPRINT_EXPORT_FAILURE, HOUSING_BLUEPRINT_IMPORT_FAILURE, HOUSING_BLUEPRINT_RENAME_FAILURE, HOUSING_DECOR_DYE_FAILURE, HOUSING_DECOR_PLACE_FAILURE, HOUSING_DECOR_SELECT_RESPONSE, HOUSING_LAYOUT_ROOM_COMPONENT_THEME_SET_CHANGED, HOUSING_ROOM_COMPONENT_CUSTOMIZATION_CHANGE_FAILED, HOUSING_SET_EXTERIOR_HOUSE_SIZE_RESPONSE, HOUSING_SET_EXTERIOR_HOUSE_TYPE_RESPONSE, HOUSING_SET_FIXTURE_RESPONSE, NEIGHBORHOOD_LIST_UPDATED)
  + BlueprintGenericImportError
  + BlueprintStorageLimit
  + BlueprintTypeInvalid
  + BlueprintNotFound
  + InvalidExteriorDocument
  + BlueprintGenericExportError
  + InvalidInteriorDocument
  + BlueprintRequirementsUnmet
  + RoomPlacementOutOfBounds
  + BlueprintCodeInvalid
  + InsufficientRoomBudget
  + BlueprintLocationInvalid
  + BlueprintNameInvalid
  + BlueprintVersionInvalid
Enum.NamePlateStyle
  + Classic
Enum.PingResult (C_PingSecure.SendHitTestPing, C_PingSecure.SendPlayerItemPing, C_PingSecure.SendPlayerSpellPing, C_PingSecure.SendUnitPing, C_PingSecure.SetHitTestTargetAndSendPing)
  + FailedSilent
Enum.PingSubjectType (C_Ping.GetDefaultPingOptions, C_Ping.GetTextureKitForType, C_Ping.SendMacroPing, C_PingSecure.SendHitTestPing, C_PingSecure.SendPlayerItemPing, C_PingSecure.SendPlayerSpellPing, C_PingSecure.SendUnitPing, C_PingSecure.SetHitTestTargetAndSendPing)
  + ActionReady
  + ActionOnCooldown
  + ActionUnavailable
Enum.SecretAspect (FrameScriptObject:HasSecretAspect)
  + RadialProgress
Enum.TieredEntranceType (C_DelvesUI.GetTieredEntranceType)
  + Lairs
Enum.TooltipDataLineType
  + ItemSpellTriggerOnUse
  + ItemSpellTriggerOnEquip
  + ItemSpellTriggerOnProc
```

### Structures

```
AddPrivateAuraAnchorArgs (C_UnitAuras.AddPrivateAuraAnchor)
  - showCountdownFrame
  + showDispelIcon
  + showCooldownEdge
  + showCooldownFrame
BNetAccountInfo (C_BattleNet.GetAccountInfoByGUID, C_BattleNet.GetAccountInfoByID, C_BattleNet.GetFriendAccountInfo)
  + friendLevel
  + friendTags
BNetGameAccountInfo (C_BattleNet.GetAccountInfoByGUID, C_BattleNet.GetAccountInfoByID, C_BattleNet.GetFriendAccountInfo, C_BattleNet.GetFriendGameAccountInfo, C_BattleNet.GetGameAccountInfoByGUID, C_BattleNet.GetGameAccountInfoByID)
  + classFilename
ChatMessageEventParams
  + discordInfo
ClubMemberInfo (C_Club.GetInfoFromLastCommunityChatLine, C_Club.GetInvitationInfo, C_Club.GetInvitationsForClub, C_Club.GetInvitationsForSelf, C_Club.GetMemberInfo, C_Club.GetMemberInfoForSelf, C_Club.GetMessageInfo, C_Club.GetMessagesBefore, C_Club.GetMessagesInRange, C_Club.GetTickets, CLUB_INVITATION_ADDED_FOR_SELF, CLUB_TICKET_CREATED)
  + discordInfo
CooldownViewerCooldown (C_CooldownViewer.GetCooldownViewerCooldownInfo)
  + spellCategoryID
  + equipSlot
  + isInvisible
HousingDecorInstanceInfo (C_HousingBasicMode.GetHoveredDecorInfo, C_HousingBasicMode.GetSelectedDecorInfo, C_HousingCleanupMode.GetHoveredDecorInfo, C_HousingCustomizeMode.GetHoveredDecorInfo, C_HousingCustomizeMode.GetSelectedDecorInfo, C_HousingDecor.GetDecorInstanceInfoForGUID, C_HousingDecor.GetHoveredDecorInfo, C_HousingDecor.GetSelectedDecorInfo, C_HousingExpertMode.GetHoveredDecorInfo, C_HousingExpertMode.GetSelectedDecorInfo)
  + canAttachPet
LfgEntryData (C_LFGList.GetActiveEntryInfo)
  + censored
LfgSearchResultData (C_LFGList.GetSearchResultInfo)
  + censored
PetJournalPetInfo (C_PetJournal.GetPetInfoTableByPetID, C_PetJournal.GetPetInfoTableBySpeciesID)
  # [3].Nilable false -> true
  # [4].Nilable false -> true
  # [5].Nilable false -> true
  # [6].Nilable false -> true
  # [7].Nilable false -> true
  # [9].Type number -> luaIndex
  # [14].Nilable false -> true
  + canAttachToDecor
  + creatureModelScale
PlaySoundParams (C_Sound.PlaySoundWithOptions)
  + volumeOverride
PlayerChoiceInfo (C_PlayerChoice.GetCurrentPlayerChoiceInfo)
  + hideAnswerArt
TieredEntranceTierInfo (C_DelvesUI.GetActiveDelveTier, C_DelvesUI.GetDelveEntranceTiers)
  + overrideTooltipSpellID
  + isLFG
UnitPrivateAuraAnchorInfo
  - showCountdownFrame
  + showDispelIcon
  + showCooldownEdge
  + showCooldownFrame
```

## Deprecated API

- [Blizzard\_Deprecated/Deprecated\_12\_1\_0.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.0/Interface/AddOns/Blizzard_Deprecated/Deprecated_12_1_0.lua)

```
function getglobal(var)
	return _G[var];
end

local forceinsecure = forceinsecure;
function setglobal(var, val)
	if forceinsecure then
		forceinsecure();
	end

	_G[var] = val;
end
```

Copy

- [Blizzard\_DeprecatedBattleNet/Deprecated\_BattleNet.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.0/Interface/AddOns/Blizzard_DeprecatedBattleNet/Deprecated_BattleNet.lua)

```
BNSendVerifiedBattleTagInvite = function()
	C_BattleNet.SendVerifiedBattleNetFriendInvite();
end

BNGetFriendInviteInfo = function(inviteIndex)
	local inviteInfo = C_BattleNet.GetFriendInviteInfo(inviteIndex);
	if not inviteInfo then
		return;
	end

	local isBattleTag = inviteInfo.friendLevel == Enum.BattleNetFriendLevel.BattleTag;
	return inviteInfo.inviteID, inviteInfo.accountName, isBattleTag, nil, inviteInfo.creationTimestamp;
end
```

Copy

- [Blizzard\_DeprecatedHousing/Deprecated\_Housing.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.0/Interface/AddOns/Blizzard_DeprecatedHousing/Deprecated_Housing.lua)

```
-- Old: Returned an arbitrary default int value when not in an owned house or plot
-- New: Returns nil when not in an owned house or plot
local originalGetSpentPlacementBudget = C_HousingDecor.GetSpentPlacementBudget;
C_HousingDecor.GetSpentPlacementBudget = function()
	return originalGetSpentPlacementBudget() or 0;
end

-- Old: Returned an arbitrary default int value when not in an owned house or plot
-- New: Returns nil when not in an owned house or plot
local originalGetMaxPlacementBudget = C_HousingDecor.GetMaxPlacementBudget;
C_HousingDecor.GetMaxPlacementBudget = function()
	return originalGetMaxPlacementBudget() or 0;
end

-- Old: Returned an arbitrary default int value when not in an owned house
-- New: Returns nil when not in an owned house
local originalGetSpentRoomPlacementBudget = C_HousingLayout.GetSpentPlacementBudget;
C_HousingLayout.GetSpentPlacementBudget = function()
	return originalGetSpentRoomPlacementBudget() or 0;
end

-- Old: Returned an arbitrary default int value when not in an owned house
-- New: Returns nil when not in an owned house or plot
local originalGetRoomPlacementBudget = C_HousingLayout.GetRoomPlacementBudget;
C_HousingLayout.GetRoomPlacementBudget = function()
	return originalGetRoomPlacementBudget() or 0;
end

-- API was updated to be plural, to account for one dye item being usable for multiple Dye Colors
C_DyeColor.GetDyeColorForItem = function(itemLinkOrID)
	local dyeColors = C_DyeColor.GetDyeColorsForItem(itemLinkOrID);
	if dyeColors and #dyeColors > 0 then
		return dyeColors[1];
	end

	return nil;
end

-- API was updated to be plural, to account for one dye item being usable for multiple Dye Colors
C_DyeColor.GetDyeColorForItemLocation = function(itemLocation)
	local dyeColors = C_DyeColor.GetDyeColorsForItemLocation(itemLocation);
	if dyeColors and #dyeColors > 0 then
		return dyeColors[1];
	end

	return nil;
end

-- API was renamed to be consistent with other similar APIs
C_Housing.IsInsideOwnHouse = C_Housing.IsInsideOwnedHouse;
```

Copy

- [Blizzard\_DeprecatedRaidWarning/Deprecated\_RaidWarning.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.0/Interface/AddOns/Blizzard_DeprecatedRaidWarning/Deprecated_RaidWarning.lua)

```
RaidNotice_AddMessage = function(_noticeFrame, textString, colorInfo, displayTime)
	RaidWarningUtil.AddMessage(textString, colorInfo, displayTime);
end;

RaidNotice_Clear = function(noticeFrame)
	noticeFrame:ClearMessages();
end;

RaidNotice_UpdateSlot = function(slotFrame, timings, elapsedTime, hasFading)
	if not slotFrame.textScalingMinHeight then
		local minHeight = timings["RAID_NOTICE_MIN_HEIGHT"] or timings.minHeight;
		local maxHeight = timings["RAID_NOTICE_MAX_HEIGHT"] or timings.maxHeight;
		local scaleUp = timings["RAID_NOTICE_SCALE_UP_TIME"] or timings.scaleUpTime;
		local scaleDown = timings["RAID_NOTICE_SCALE_DOWN_TIME"] or timings.scaleDownTime;
		FadingFrame_SetTextScaling(slotFrame, minHeight, maxHeight, scaleUp, scaleDown);
	end
	FadingFrame_UpdateTextScaling(slotFrame, elapsedTime);
	if hasFading then
		FadingFrame_OnUpdate(slotFrame);
	end
end;

RaidNotice_FadeInit = function(slotFrame)
	FadingFrame_OnLoad(slotFrame);
	FadingFrame_SetFadeInTime(slotFrame, 0.2);
	FadingFrame_SetHoldTime(slotFrame, 0.2);
	FadingFrame_SetFadeOutTime(slotFrame, 3.0);
end;
```

Copy

Retrieved from " [https://warcraft.wiki.gg/wiki/Patch\_12.1.0/API\_changes?oldid=6751582](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes?oldid=6751582)"

[Category](https://warcraft.wiki.gg/wiki/Special:Categories "Special:Categories"):

- [API patch changes](https://warcraft.wiki.gg/wiki/Category:API_patch_changes "Category:API patch changes")

Cookies help us deliver our services. By using our services, you agree to our use of cookies.

[More information](https://www.indie.io/privacy-policy)OK