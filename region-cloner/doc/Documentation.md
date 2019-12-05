# Region Cloner

Region Cloner is a mod that enhances the cloning functionality built into Factorio. The primary intent is to facilitate quick benchmark setups.

## Main Use Cases

Region Cloner excels in the following areas:
* Cloning a large number of entities.
* Cloning trains to get the proper manual_mode
* Cloning the signals on the wire of circuit networks.
* Quickly cloning an entire design N many times in N/S/E/W direction.
* Cloning inserters and preserving their pickup/drop targets.

## Supported versions
Region Cloner versions are noted as follows:
```
1.2.0
{major_version}.{feature_version}.{patch_version}
```
For major_version, this corresponds to the most recent Factorio stable version following this rule:
```
0.16: major_version 0
0.17: major_version 1
...
```
Feature versions denote that a major feature was added, removed, or changed significantly.

## Features
Region cloner comes with several features that allow for quick and correct cloning.
#### Autoclone
Region cloner comes with a command entitled autoclone which allows for rapid cloning. Autoclone performs automatic cloning of all entites of the surface of the player who ran the command.
When choosing the area to clone, only entities of the "player" force are considered. But when actually performing cloning, all entities within the selection are cloned. (Ex: won't clone ore patches unless they're built on).
Autoclone can be invoked with the following:
```
/autoclone [#] [N/s/e/w] [c]
```
* [\#]: A positive number that denotes the number of times to paste. Optional. Default = 1
* [N/s/e/w]: A single character that denotes which direction the paste should be executed towards. Optional. Default = North
* [c]: A single character 'c' which if present changes the cloning selection area to be chunk aligned. Optional. Default = Off

All arguments are case insensitive. Any additional arguments are ignored.

Usage:
```
/autoclone 9 e c
# Automatically clones 9 pastes towards the east, chunk aligned

/autoclone c
# Automatically clones 1 time towards the north, chunk aligned.

/autoclone 2 N
# Automatically clones 2 times towards the north, not chunk aligned
```

#### GUI
Region Cloner adds a GUI in the top left corner of the game. This GUI allows for fine tuned control of various cloning parameters.

###### Standard
The standard window contains fields left_top and right_bottom. These fields control the source area that you want to find potential entites to clone. The left_top field is the left top corner of the selection, and so forth for the right_bottom corner as well. The mod will automatically resolve the left/top most coordinates to the left_top fields, and vice versa for the bottom_right.

The direction to copy parameter decides which direction you wish to copy. This parameter is ignored if the advanced tile paste override checkbox is selected. This direction is based off of the selection in the prior parameter.

Number of copies allows you to specify how many pastes you want. ex: I want 10 total copies of a design, I put 9 here. Must be a whole positive number.

The shrink selection area reduces the selected area to only the area required. This can expand the area as well, if an entity is partially cut off by the selection area, but its collision box lies partially outside. If your selection box is currently all 0's, then it will select the box around all player entites.

Get selection tool gives you a tool that allows you to rapidly select new areas and populate them into the left_top and right_bottom fields.

The Start button begins a paste with the parameters provided.

###### Advanced
There are a number of advanced parameters in the advanced tab of the GUI

The tile paste override feature can be used to specify a custom tile paste offset. This overrides the direction to copy value in the standard window. An offset smaller than the selection area creates pastes that shingle together. Only the originally found entites will be cloned, so there won't be a multiplying effect for multiple pastes. Either or both X/Y offsets can be used, use negative values to paste west/north. Allows decimal or probably invalid offsets, use with care.

The clear paste area flags allow for selectively destroying entites where we are about to paste. No matter what, entites on the enemy force are destroyed. The first paste of a source area will always ignore the entities in the source area as possibly entities to destroy. Due to performance considerations checking more than the first paste is not viable, so if you are shingling multiple pastes together you may want to turn off the 'Normal entites' flag.

## Considerations
Region Cloner officially supports multiplayer, however it's strongly recommended to use GUI parameters instead of autoclone. This configuration is lightly tested so please report any issues you may encounter.

Since version 1.2.0, Region Cloner doesn't have any runtime cost, all cost is localized to performing a paste.

When using autoclone, it's often a good idea to use chunk alignment. This reduces the likelihood of pastes having performance or behavior differences between each other.

## Known issues
1.2.1 - Cloning rolling stock with speed changes their position relative to the source. [Bug](https://forums.factorio.com/viewtopic.php?f=48&t=68329#p464461)

1.2.1 - Cloning a train waiting at a station with waitcondition of time passed or inactivity resets their timer to 0. [InterfaceRequest](https://forums.factorio.com/viewtopic.php?f=28&t=77537)

~~1.2.1 - You cannot copy circuit network signals across surfaces.~~ Actually you can. But not yet resolved (1.2.2).
