# bhop-get-stats

## [my discord](https://discord.gg/j9nfnjcUVd)

### credits - me, Alkatraz, Nairda, Oblivious, Xutax, xWidovV, Tekno/f0e, Kaldun, Lilac, Shavit Timer contributors

Jumpstats - Drop-in replacement for Jhud, Trainer, Offsets, Speedometer, SSJ, FJT, and Showkeys. Most (if not all) of these HUDs are more full-featured or accurate on my versions.

Get Stats - Supports jump stats (and hopefully other devs plugins in the future), by reducing redundant calculations.

This implementation of these plugins, as of now, are the only versions that still work when [sync style](https://github.com/Nimmy2222/shavit-syncstyle) is used.

# Usage/Directions:

Press the green "Code" button at the top, and download the zip. Extract the zip, then drag the plugins folder into ```cstrike/addons/sourcemod.```

Make sure you have Dynamic Channels installed as well, check the dependencies section below.

  JumpStats (Open Menu):
  ```
    - /js
    - /jhud /trainer /strafetrainer /offsets /offset /ssj /speedometer /speed /fjt 
	- (Enabled by default in CVARS, but disablable commands)
  ```

# Cvars:
* Most cvars in jumpstats enable/disable the different modules (jhud, trainer, etc), everything is enabled by default
* js-allow-trainer-fast: Allows the trainer to update very quickly, only enable for smaller servers with strafe tryhards. off by default
* js-allow-trainer-medium: Allows the trainer to update semi-quickly, it should be fine to enable for medium servers. off by default

# Dependencies:
* bhop-get-stats.smx (in this repo) the central plugin. You cannot just install jumpstats by itself, you MUST HAVE bhop-get-stats.smx
* (JumpStats) -> [Dynamic Channels](https://github.com/Vauff/DynamicChannels)
* (JumpStats) -> (OPTIONAL) [Shavit](https://github.com/shavitush/bhoptimer) For FJT Hud/Time SSJ/Time Delta SJJ options

# Changelog:
* JumpStats Overall
	* All HUD elements can be adjusted to be positioned pretty much anywhere on the screen
	* Menus for all of these HUDs have been merged
   	* All HUDs should be properly displayed to spectators
 
* JumpStats Colors
	* All (color-relevant) HUD element colors are changeable but have inherent links
   	* You can adjust colors by "action", so you can change the color of any "bad action"/"good action", and all HUDs will reflect that color
   	* The reasoning behind this, is doing it differently drastically ups code complexity/memory and I just don't see a need, this feature is already overkill
   	* Defaults:
   		* 90+ Gain / High Speed SSJ / -1 Offset / 90-100 JSS: White
   	 	* 80+ Gain / Decent Speed SSJ / 0 Offset / 80-90 JSS: Cyan
   	  	* 70+ Gain / Meh Speed SSJ / -2 Offset / 70-89 JSS: Green
   	  	* 60+ Gain / Bad Speed SSJ / -3 Offset / 60-70 JSS: Orange
   	  	* Any gain lower than 60 / Terrible Speed SSJ / Any positive offset, or below -4 / Any JSS Above 100 or below 60: Red

* I had a changelog here for each plugin, but I cannot keep up with it. Just know I've added a shit ton of features and improvements to almost every single plugin I've merged into this one. There are also better changelogs in my discord.
