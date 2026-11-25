# Friday Night Funkin' - Psych Engine
Engine originally used on [Mind Games Mod](https://gamebanana.com/mods/301107), intended to be a fix for the vanilla version's many issues while keeping the casual play aspect of it. Also aiming to be an easier alternative to newbie coders.

## Installation:

Refer to [the Build Instructions](./BUILDING.md)

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Credits:
* Shadow Mario - Programmer
* Riveren - Artist

### Special Thanks
* bbpanzu - Ex-Programmer
* Yoshubs - Ex-Programmer
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - some Lua reworks
* superpowers04 - LUA JIT Fork
_____________________________________

# Features

## Loading transitions

The custom fade transition keeps its loading bar below full while switching states.
It fills the bar and shows "Finished! :]" only after the destination state finishes
initializing, then briefly holds the result before revealing the screen. The bar
is a transition indicator, not a percentage of assets loaded.

## Scenery stage

Set a chart's stage to `scenerystage` to use the built-in
[SceneryStage](./source/states/stages/SceneryStage.hx). It replaces the stage's Lua
script and still uses `images/sceneryassets/stage.png` from the active mod.
Its default character positions and camera settings are included in
[scenerystage.json](./assets/shared/stages/scenerystage.json).

The scenery song's mechanics keep opponent receptors in their static animation,
at half size above and behind the opponent with slight scatter and shaking.
Opponent notes follow them at the same scale and always use upscroll; the player's
scroll direction is unchanged. Opponent notes and receptors render behind the
opponent, while player notes remain on the HUD. The song sets absolute scroll speeds at steps
704 (2.6), 720 (2.7), 736 (2.8), 752 (2.9), 832 (3), 1216 (2.9), 1232 (2.8),
1248 (2.7), 1264 (2.65), 1280 (2.6), and 1344 (2.5).

## Chromtest character strumlines

The exported mod's Chromtest script hides HuddieNotes, normal opponent notes,
and the original opponent receptors without disabling their character animations.
Only Daren has an extra lane: it starts offscreen, then slides into the opponent
HUD columns over two seconds starting with his character entrance at step 384.
At the same time, both Daren's and the player's receptors slide down to the normal
bottom receptor height and use downscroll. The player's lane uses the selected
scroll setting before this entrance; saved preferences are unchanged. Active and
upcoming player sustains switch orientation with the lane. Frame updates track
only Daren's notes and reuse sustain clipping rectangles. The entrance script
directly tweens the engine's player receptors and Daren's four separately created
receptors; the original opponent receptors remain hidden. Only DarenNotes follow
and trigger Daren's receptors, and lane movement uses native Lua tween callbacks.
All Chromtest note mechanics live in its `mechanics.lua`: Daren's rendering and
automatic hits share one per-frame pass over his active notes. Huddie's opponent
assignment is applied during initialization and spawning, so the global Huddie
script skips Chromtest instead of scanning its notes every frame.

## Attractive animated dialogue boxes:

![](https://user-images.githubusercontent.com/44785097/127706669-71cd5cdb-5c2a-4ecc-871b-98a276ae8070.gif)


## Mod Support
* Probably one of the main points of this engine, you can code in .lua files outside of the source code, making your own weeks without even messing with the source!
* Comes with a Mod Organizing/Disabling Menu.


## Atleast one change to every week:
### Week 1:
  * New Dad Left sing sprite
  * Unused stage lights are now used
  * Dad Battle has a spotlight effect for the breakdown
### Week 2:
  * Both BF and Skid & Pump does "Hey!" animations
  * Thunders does a quick light flash and zooms the camera in slightly
  * Added a quick transition/cutscene to Monster
### Week 3:
  * BF does "Hey!" during Philly Nice
  * Blammed has a cool new colors flash during that sick part of the song
### Week 4:
  * Better hair physics for Mom/Boyfriend (Maybe even slightly better than Week 7's :eyes:)
  * Henchmen die during all songs. Yeah :(
### Week 5:
  * Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog
  * On Winter Horrorland, GF bops her head slower in some parts of the song.
### Week 6:
  * On Thorns, the HUD is hidden during the cutscene
  * Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental

## Cool new Chart Editor changes and countless bug fixes
![](https://github.com/ShadowMario/FNF-PsychEngine/blob/main/docs/img/chart.png?raw=true)
* You can now chart "Event" notes, which are bookmarks that trigger specific actions that usually were hardcoded on the vanilla version of the game.
* Your song's BPM can now have decimal values
* You can manually adjust a Note's strum time if you're really going for milisecond precision
* You can change a note's type on the Editor, it comes with five example types:
  * Alt Animation: Forces an alt animation to play, useful for songs like Ugh/Stress
  * Hey: Forces a "Hey" animation instead of the base Sing animation, if Boyfriend hits this note, Girlfriend will do a "Hey!" too.
  * Hurt Notes: If Boyfriend hits this note, he plays a miss animation and loses some health.
  * GF Sing: Rather than the character hitting the note and singing, Girlfriend sings instead.
  * No Animation: Character just hits the note, no animation plays.

## Multiple editors to assist you in making your own Mod
![Screenshot_3](https://user-images.githubusercontent.com/44785097/144629914-1fe55999-2f18-4cc1-bc70-afe616d74ae5.png)
* Working both for Source code modding and Downloaded builds!

## Story mode menu rework:
![](https://i.imgur.com/UB2EKpV.png)
* Added a different BG to every song (less Tutorial)
* All menu characters are now in individual spritesheets, makes modding it easier.

## Credits menu
![Screenshot_1](https://user-images.githubusercontent.com/44785097/144632635-f263fb22-b879-4d6b-96d6-865e9562b907.png)
* You can add a head icon, name, description and a Redirect link for when the player presses Enter while the item is currently selected.

## Awards/Achievements
* The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx)

## Options menu:
* You can change Note colors, Delay and Combo Offset, Controls and Preferences there.
 * On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc.

## Other gameplay features:
* When the enemy hits a note, their strum note also glows.
* Lag doesn't impact the camera movement and player icon scaling anymore.
* Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes)
* You can reset your Score on Freeplay/Story Mode by pressing Reset button.
* You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space.
* You can enable "Combo Stacking" in Gameplay Options. This causes the combo sprites to just be one sprite with an animation rather than sprites spawning each note hit.
