**♩♫♩ sndr manual ♩♫♩**
-----------------------

Summary
-------

Hey! This is the first library I made,
And also the first audio adventure I've gone on in general.

This library is for use with löve, *(https://love2d.org/)*
And uses the following modules: **love.math**, **love.audio**, And **love.sound**.

And it also uses the same synth and would probably help to also use
Sounder which is what this whole library
is designed and named for. *(https://smellyfishstiks.itch.io/sounder)*

So ya you save your .sndr files using that and then put the data into a string,
(since it uses '\n's use [[]].)
and then the library's API can let you play sound!


Just require the file and it returns the API!
(And also call sndr.update in your update function, Very important!!)

Manual for the API
------------------
(italicized if optional arg.)



list [*index*, *table*] {boolTable}
===================================
returns a table that contains bools if that channel is either filled or empty.
*index* is optional if you want to check a certain channel,
And *table* is what table your checking; "buffer" if the buffer, else if channel.



info [index, *table*] {infoTable}
=================================
returns a table that contains all of the info about the channel/buffer at *index*.
if *index*==**nil** then it returns **nil**.

infoTable's Contents:
- name (name of the sfx.)
- data (the notedata of that sfx. (not the whole sfx!) )
- id (if it's a song or not.)
- state (if it's playing or not.)
- speed (speed of the sfx.)
- prog (prog of the sfx's source.)
- vol (global volume the sfx is under.)
- loop (loopPoint of the sfx.)
- start (startingPoint of the sfx.)
- flags (table that stores the sfx's flags.)
- output (the sound that sfx's source outputed on the frame this runs.)
- age (how old that sfx is. (frames not bufferAdvances.))

These get dumped as custom keys so to get the name of a sfx just do:
```lua
local name = sndr.info(1).name
```



load [data, *index*, *flags*]
=============================
Loads the sfx into a channel and if needed pushes old sfx into buffer,
Also can do some other nice things like overwriting certain
channels or giving special flags.
If not given a *index* it will try to find a empty channel, if not then
it (**jankly...**) tries to find the oldest channel
that's not index 1 (due to that being used to control music.)
and will push that sfx to the buffer and replace it.

*index* can also be "song" to push it to index 1 and play the sfx's channels
as a song.

Flags (As in a table of custom keys.) let you set certain properties of the sfx,
Here's a guide;
```lua
sndr.load( sound, nil, {play=true, quit=false, loop=false, lock=false, layer=0} )
```

---------------------------------------------------
 - play
 Automaticly play the sfx; no need for sndr.play.
 
 - quit
 Quit the sfx if it ends (overrides loop.)
 
 - loop
 if true loops back to sfx's loopPoint.
 
 - lock
 will prevent a automaticly loaded sfx from overwriting it... I hope
 
 - layer
 used for giving a sfx or song a layer to use with volume.
---------------------------------------------------



dump [index]
============
Dumps the given channel's sfx, if it's empty errors.
Will remove a sfx from the channels and the buffer will try to fill that
space with a buffered sfx.



play [index]
============
Will set that sfx's state to true and play it.
if that the sfx at the channel's index is a song will play the song.



pause [index]
=============
The same thing as play but sets the state to false.
just like play if it's a song will pause the whole song.



vol [index,layer]
===========
Sets the global volume that applies to the channels.
*index* can be 0..5 0 being normal and 5 being super quiet.
if index is **nil** will error.
*layer* is used for saying "I want only layer 1 to be quiet and layer 0 to be loud." (0 is sfx by defualt and 1 is songs by defualt.)



getVol [layer] {layerVolume}
=====================
Returns the layer's volume index



prog [index, unit, amount]
=========================
Sets the prog (Progress, I don't know I thought prog was funner to say.) of the sfx(s).
If the channel is empty errors.
*index* is the channel's sfx being progged, (Works for songs like how play and pause do.)

*unit* is either "note" or "sample" if note it will be in units of notes,
If sample then it's per sample.
*amount* is what it sounds like.



getProg [index] {amount}
========================
Gets the progress of the channel at that *index*.
(The amount returned is in samples.)
if channel[index] is **nil** errors.



setSampler [index, table]
==================
Sets the sampler to the table,
The sampler is the table pulled from by instrument 7,
This lets you set it so you can use your own sounds in songs!
The sampler follows the same rules as the sampler in Sounder,
So you give it a *index* for which sound to replace and the *table* to replace it with.



Ending Notes
------------
ya that should be everything! IDK it's probably pretty
flawed and also there's also some bugs in there maybe...
Don't think this will catch on as a audio format but for my little games and
making simple music I think it's nice. any ways if you use this please credit it!

Thanks for checking it out! - Smelly


*updated for v1.1*

