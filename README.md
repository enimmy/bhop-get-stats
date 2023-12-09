# bhop-get-stats
get the stats

all of these plugins were created in preparation for the release of my autostrafer (its actually an auto syncer). It will allow you to get -1 offset (perfect sync) on every strafe, but the way it does it broke other plugins.

In response, I've fixed the main plugins it broke, I can fix others if found as well. Since all of these plugins essentially do very similar things, I created a small "core" plugin to act as a dependency to the main ones. For devs, this means you can easily create/edit these plugins without worrying about calculations related to bhop. I guesss it also saves a bit of CPU if you use all of them maybe?

Dependencies:
All plugins depend on bhop-get-stats

Trainer/Jhud dynamic channels

https://github.com/Vauff/DynamicChannels

Changelog:

SSJ:
- removed some characters/decimal points to add more options (approaching character limit)
- added colors onto the gain field (optional)
- fixed a bunch of shit from the base version

JHUD:
- removed all constant speed settings, seriously doubt anyone cares and id rather just create a better speedometer plugin
- added sync into the logs
- added color options
- rewrote the menu logic (can maybe make it better upon request)
- Uses a more accurate JSS calculation (old 103% is 100%, basically going over 100% now will lose you speed)
- The HUD is displayed in a new way in order to support dynamic channels
- I rewrote this entire plugin almost, wouldn't be surprised if its the most buggy of the bunch

TRAINER:
- Mostly the same, just using the more accurate JSS calculation
- changed some of the color logic (the plugin REALLY DISLIKES you going over 100%, if its too much lmk please)
- The HUD is displayed in a new way which should look a bit smoother (and not break as many other huds)
- The update rate on the actual bar slider is now divorced from the number, they are both still accurate, but players who like using the bar now get updates more often while number users can still use their number without it being too fastj
- Plugin should display the specced players trainer stats to the spectator, if enabled


Big fat warning: If you choose to use these plugins, please be aware they are pretty much in beta and I'm not 100% they are all working great, but I would still really appreciate if you tried them out and messaged me with any issues (discord enimmy)
