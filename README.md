# bhop-get-stats

### Big fat warning: If you choose to use these plugins, please be aware they are pretty much in beta and I'm not 100% they are all working great, but I would still really appreciate it if you tried them out and messaged me with any issues (discord enimmy)

Central plugin for calling bhop statistic forwards and base plugins for displaying that information.

All of these plugins were created to be used in tandem with my sync style, [sync style](https://github.com/Nimmy2222/shavit-syncstyle). This style breaks probably every other SSJ/Jhud/Trainer, so you will need these. I also just wanted to make it easier for other people to make changes to these types of plugins in the future. Now devs will not have to worry about making mistakes with calculations, and can easily make changes they like.

MasterHud - Drop in replacement for Jhud, Trainer, and Offsets

SSJ - Drop in replacement for SSJ

Get Stats - Supports both of the above plugins, reducing redundant calculations

# Usage:

  MasterHud (Open Menu):
  ```
    - /bhud /offsets /offset (in order to not override old commands if you want them)
    - /jhud /trainer /strafetrainer (when overrides enabled by server admin)
  ```
  SSJ:
  ```
    - /ssj
  ```

# Cvars:
* MasterHud: 
   * bstat-master-override-jhud Default: 1 Override /jhud command? 0 (false) or 1 (true)
   * bstat-master-override-trainer Default: 1 Override /strafetrainer commands? 0 (false) or 1 (true)

# Dependencies:
* (All Plugins -> bhop-get-stats.smx) (in this repo) the central plugin. You cannot just install master-hud/ssj by itself, you MUST HAVE bhop-get-stats.smx
* (MasterHud -> [Dynamic Channels](https://github.com/Vauff/DynamicChannels))

# Changelog:
	* SSJ:
	* removed some characters/decimal points to add more options (approaching the character limit)
	* added colors onto the gain field (optional)
	* fixed many bugs from base version

* JHUD:
	* removed all constant speed settings, seriously doubt anyone cares and I'd rather just create a better speedometer plugin
	* added sync into the logs
	* added color options
	* Uses a more accurate JSS calculation (old 103% is 100%, basically going over 100% now will lose you speed)
	* added white color for 90 gains after first 6/16 (extra speed) jumps

* TRAINER:
	* Mostly the same, just using the more accurate JSS calculation
	* changed some of the color logic (the plugin REALLY DISLIKES you going over 100%, if its too much lmk please)
	* The update rate on the actual bar slider is now divorced from the number, they are both still accurate, but players who like using the bar now get updates more often while number users can still use their number without it being too fast
	* Plugin should display the specced players' trainer stats to the spectator if enabled

* OFFSETS:
	* No real changes, just merged in now.
