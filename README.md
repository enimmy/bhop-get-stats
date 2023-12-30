# bhop-get-stats

### [my discord](https://discord.gg/j9nfnjcUVd)

Central plugin for calling bhop statistic forwards and base plugins for displaying that information.

These plugins were created to be used in tandem with my sync style, [sync style](https://github.com/Nimmy2222/shavit-syncstyle). This style breaks probably every other SSJ/Jhud/Trainer, so you will need these. I also just wanted to make it easier for other people to make changes to these types of plugins in the future. Now devs will not have to worry about making mistakes with calculations, and can easily make changes they like.

Jumpstats - Drop-in replacement for Jhud, Trainer, Offsets, Speedometer, SSJ and FJT. Most (if not all) of these HUDs are more full-featured and accurate on my versions.

Get Stats - Supports jump stats (and hopefully other devs plugins in the future), by reducing redundant calculations.

# Usage/Directions:

Press the green "Code" button at the top, and download zip. Extract zip, then drag the plugins folder into ```cstrike/addons/sourcemod.```

  JumpStats (Open Menu):
  ```
    - /js
    - /jhud /trainer /strafetrainer /offsets /offset /ssj /speedometer /fjt 
	- (Enabled by default in CVARS, but disablable commands)
  ```

# Cvars:
* JumpStats:
   * All enabled (1) default, 0 to disable
   * js-override-jhud Override /jhud command
   * js-override-trainer Override /strafetrainer /trainer
   * js-override-offset Override /offset /offsets
   * js-override-speed Override /speedometer /speed
   * js-override-ssj Override /ssj
   * js-override-fjt override /fjt

# Dependencies:
* (All Plugins -> bhop-get-stats.smx) (in this repo) the central plugin. You cannot just install jumpstats by itself, you MUST HAVE bhop-get-stats.smx
* (JumpStats) -> [Dynamic Channels](https://github.com/Vauff/DynamicChannels)
* (JumpStats) -> (OPTIONAL) [Shavit](https://github.com/shavitush/bhoptimer) For FJT Hud/Time SSJ/Time Delta SJJ options

# Changelog:
* JumpStats Overall
	* All HUD elements (jhud, trainer, offsets, speedometer) can be adjusted to be positioned pretty much anywhere on the screen
	* Menus for all of these HUDs have been merged
   	* All HUDs should be properly displayed to spectators
 
* JumpStats Colors
	* All HUD element colors are changeable but have inherent links (except FJT)
   	* You can adjust colors by "action", so you can change the color of any "bad action"/"good action", and all HUDs will reflect that color
   	* The reasoning behind this, is doing it differently drastically ups code complexity/memory and I just don't see a need, this feature is already overkill
   	* Defaults:
   		* 90+ Gain / High Speed SSJ / -1 Offset / 90-100 JSS: White
   	 	* 80+ Gain / Decent Speed SSJ / 0 Offset / 80-90 JSS: Cyan
   	  	* 70+ Gain / Meh Speed SSJ / -2 Offset / 70-89 JSS: Green
   	  	* 60+ Gain / Bad Speed SSJ / -3 Offset / 60-70 JSS: Orange
   	  	* Any gain lower than 60 / Terrible Speed SSJ / Any positive offset, or below -4 / Any JSS Above 100 or below 60: Red

* SSJ:
	* removed some characters/decimal points to add more options (approaching the character limit)
	* added optional colors onto the gain numbers
	* fixed many bugs from the base version

* JHUD:
	* removed all constant speed settings (moved to speedometer)
	* added sync into the logs
	* Uses a more accurate JSS calculation (old 103% is 100%, basically going over 100% now will lose you speed)

* TRAINER:
	* Updated JSS calculation
	* changed some of the color logic
	* The update rate on the actual bar slider is now divorced from the number, they are both still accurate, but players who like using the bar now get updates more often while number users can still use their number without it being too fast

* OFFSETS:
	* Should properly detect every type of strafe (normal, sideways, reverse, halfsideways, etc)
   	* moved "really good" action onto -1 offset instead of 0
   	* altered no press detection to detect whether you're normal or sideways

 * SPEEDOMETER
   	* Added option to have colors based on current gain, instead of just gaining/maintaining/losing speed

* FJT
	* Nothing really changed, just merged into the plugin
