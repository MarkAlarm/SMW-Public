____________________________________________________________________________________________________

 Cluster Bullet Sprite Shooter
 Made by MarkAlarm
 Credit if used, do not claim as your own
____________________________________________________________________________________________________

 1. Credits
 2. What's Included
 3. Information
 4. Contact
 5. Update Log
 6. Future Plans
 7. Known Bugs
____________________________________________________________________________________________________

 1. Credits
____________________________________________________________________________________________________

 Sprite shooter created by MarkAlarm
 Cluster bullet created by MarkAlarm
 Graphics used from the JUMP resource pack
 MathGetCoordSpd routine created by worldpeace, SA-1 hybridized by MarkAlarm

 Special thanks goes out to the following people:
 worldpeace:
  For creating one of my favorite levels of all time (Cool or Cruel: Tubular)
  For inspiring me to create this in the first place
  For being a tremendous help when I first started trying to make cluster sprites, in a sense being a mentor
  And for providing me the MathGetCoordSpd routine, for which this sprite would not be the same otherwise

 dtothefourth:
  For being one of my primary ASM mentors, especially over the past several months to a year
  For helping me figure out the SA-1 conversion for the math routine
  And just being there for me any time I have questions for why stuff breaks

 Atari2.0:
  For also working with me on the SA-1 conversion
  And for continuing the maintenance of Pixi, working on new updates and features
____________________________________________________________________________________________________

 2. What's Included
____________________________________________________________________________________________________

 readme.txt:
  What you're reading right now :)

 extra byte info.txt
  Documentation on how all of the extra bytes (and extra bit) work

 list.txt:
  Not really necessary, but it's there so you can have a quick way of just getting this inserted onto your ROM
  Also included so the showcase level is configured properly

 Showcase Level - 136:
  Modifies Level 136 (as the name implies)
  After inserting the sprites successfully, I'd recommend inserting this level into your ROM
  It shows off how a bunch of different shooters work, how their extra bytes are used to do different things, etc

 ExGFX8AA.bin:
  A graphic file that you can use for exanimation
  For this sprite, the exanimation replaces the smiley coin with a ball of plasma

 cluster-shooter.json:
  This sprite should be inserted as a regular sprite, not as a shooter (contrary to what the name would imply)

 cluster-shooter.asm:
  This is what will spawn the cluster bullets, and has a ton of different customization features tied to the 12 extra bytes
  I highly recommend you read through the extra byte document to get an idea of how they work before trying to throw in random values
  You also have to change !readme to 1 in order for it to be inserted

 bullet.asm
  The cluster sprite itself
  This is what actually gets shot out, a 16x16 ball of plasma (assuming you use the exanimation graphic provided)
  It will hurt the player upon impact, but there is future room for expansion to have it do other things

 MathGetCoordSpd.asm
  A required routine used to calculate X and Y speeds based on a given input speed and angle
____________________________________________________________________________________________________

 3. Information
____________________________________________________________________________________________________

 Set !readme to 1 in the cluster-shooter.asm file
 You must be on the most recent version of Pixi (as of writing this, 1.32 or higher)

 This is a sprite that will shoot out cluster sprites in various different ways
 You can customize basically every attribute of it via the 12 extra bytes it supports, using only one list.txt slot in the process
 Things such as the rate of fire, speed of bullets, the angle they're shot out, additional parameters, and more are all included
 Each of the extra bytes are documented in the extra byte info file, so it would be best that you reference that for detailed explanations of everything

 There are some things that I pre-reserved for the future, such as future parameters and shooter types
 I also left some room in the ASM file to add in some of your own features (assuming you know how, I'm not gonna help you on that), such as new parameters
 This shooter sprite is very customizable and I intend to make it even more custom as time goes on, so if you have suggestions on what you think would be fitting for a future update, contact me!
____________________________________________________________________________________________________

 4. Contact
____________________________________________________________________________________________________

 There shouldn't be too many reasons to message me regarding this sprite. However, any of the following would give you good reason to:
  The shooter results in unintended behavior (IE you didn't mean for it to attach to that spring over there)
  A game crash occurs and you can determine with certainty it was a result of my sprite
  You have an idea for a feature that you think could be widely applicable and/or useful, and it isn't in the future updates segment of this readme
  You're the one that has to moderate this sprite, then in which case I'm deeply sorry

 Assuming one of those reasons has been met, then you may contact me (MarkAlarm) from either of these methods:
  DM me on SMWCentral (MarkAlarm, ID 32173)
  DM me on Discord (MarkAlarm#5071)
  If you somehow contact me through another platform, there's a low to 0 chance I will respond

 If you try inserting this before reading the readme, don't ask me about an insertion error
____________________________________________________________________________________________________

 5. Update Log
____________________________________________________________________________________________________

 June 10th, 2021: v1.1
  Added shooter types with customizable parameters, including:
   Circular shooter
   Back and forth shooter
   Speed-up and slow-down shooters
   Sine and cosine wave shooters
   Re-aiming bullet shooter
  Added a new parameter type via dragon coins, with the following options:
   Collected count = 0
   Collected count > 0
   Collected count < 5
   Collected count = 5
  Added a separate document to explain all of the extra bytes
   Done to avoid having a massive comment block in the ASM file
  Added the ability to attach to custom sprites
  Added a !readme define to make people read the documentation I included
  Included a bank wrapper for the MathGetCoordSpd.asm
   Fixes a bug with angles shooting at incorrect speeds due to bank crossing
  Recoded the shooter to store the extra bytes into RAM, making it possible to modify values in-game
  Recoded the bullets to allow modifying their properties even after they've been shot
  Changed the bullet to use defines in the ASM file to customize tile and palette
   This makes setting values in the extra property bytes obsolete
  Changed the .json to use the default graphic and palette, rather than a red X
  Removed the simple versions of the shooters
   If you leave extra bytes 1 and 5-12 as $00, then it acts exactly the same as the simple version
   Done to avoid needless updating of multiple sprites

 September 19th, 2020: v1.0
  Initial Submission to SMWCentral
  Wow look at how small this update log is, hopefully it doesn't get too big
____________________________________________________________________________________________________

 6. Future Plans
____________________________________________________________________________________________________

 Include an 8x8 (or just a customizeable size) version of the bullet sprite
 Give bullets object interaction so they can bounce off walls
 Add an option to spin jump off bullets
 Rewrite the math routine to allow for more precise angle shots
____________________________________________________________________________________________________

 7. Known Bugs
____________________________________________________________________________________________________

 Placing more than 16 shooters on SA-1 causes them to load invalid values
 Attaching shooters to some sprites that change either state or number can be wonky
  For example, attaching to baby yoshi as it grows into adult yoshi
 Back and forth shooters don't shoot at super precise angles, due to how the math routine is made
____________________________________________________________________________________________________

 And if you read this whole thing, thanks! I hope you found it useful and informative :D
