
# UNBOUNDED SHOOTER

## NOTES

### Movement mechanics

- Barrel-roll-dodge
  - Moves rapidly on the diagonal
  - Can be bailed out of?? Committal means tradeoff in strategy
  - Deflects enemy fire while moving
  - Fires a single, more powerful shot when it lands?
    - Maybe when it begins, too
  - Bound linearly to trigger input

- Travelling backwards
  - Expendable resource? Seems lame
  - For-cost special move, with a flashbulb feel like World of Goo's undo?
  - Does it reset the enemy state as well?
    - If it doesn't, makes a powerful special move
    - If it does, allows retrying or escaping tight scenarios

- Somersault
  - With strict time-binding, allows rewinding
  - Could be an interesting part of violating the event horizon

- Colour mixing
  - Instead of colour being part of the ship's state via rotation, have
    one button for each color and just allow all of them all the time
  - Easier to combine colours, but almost to the point of making combining
    of colours trivial; no longer exciting option
  - Maybe firing two colours at once cost most energy than a single colour
  - Firing all three colors is annoying with the thumb

- Super weapon button with Silvergun-style weapons
  - Hold down the super button to charge
  - When charge is reached, press a colour to fire the super in that color
  - Maybe we can't mix colors by pressing colors simultaneously like we do with
    normal shooting
  - This allows the layering mechanic to exist and retains some discoverability
    about blended supers
  - It should still be hard to pull off

- Directional super?
  - Presuming the super lives on one of the shoulder buttons, maybe there could
    be two diretion or two 'ways' of doing the super.
  - A left-ish facing one and a right-ish facing one?

- Magnet special
  - If there isn't directionality to the super such that it requires two shoulder
    buttons, the other shoulder could be a magnet ability that draws powerups
  - Either hold-to-use which draws things in slowly or with speed ~= 1/d^2
  - Or press once and it zaps up any visible powerups regardless of distance
  - There's no particular need to use up ALL the controller buttons and it's
    harder to play with a keyboard, so be careful

- Strict time binding
  - Whole world stops when the player's worldline isn't progressing
    - Maintains good thematic consistency about swapping constant time for contant space
  - Makes some agility-based play trivially easy, like layering supers
  - Maybe a penalty for hogging the time axis?
    - Maybe a combo-cooldown mechanic that runs down more quickly when time is
      slowed, to make it easier to drop chains
    - It doesn't even have to run more quickly during slowdown as the player will
      be inherently less likely to combo kills in the required amount of time
    - However this means the combo timer will need to be immune to slowdown

- Y Button
  - If the AXY buttons are use for colors due to their obvious correlation and
    thumb proximity, what should the Y button do?
  - Bomb? Reliable standard-issue shmup standby
  - Controller input completionism?

- Firing directionality with second joystick?
  - It's not a GW clone but that might be interesting

### Enemies must be killed by same or different light?

- Different
 - Makes sense cos things of a given color reflect those photons
 - However that's harder to think about than just matching colors
 - Consequences for white light are different
  - If colours must be absorbed to damage, white light is in fact useless
    and not interesting to use, will be reflected by everyone
   - We can go Ikaruga style and say matching still does damage, just less
   - Then white light is still useful cos it damages everything, but not much
 - Black light?
  - No physical basis, but if white light is universally reflected, it makes
    videogame-sense that black is universally absorbed
  - Not sure how to make it. Subtractive gun mode?

- Same
 - Is easier to think about but more restricting to play - each color is
   adept at only one type of enemy instead of two
 - White light makes sense as a powerful weapon, and occurs to the player
   intuitively once they discover they can mix colours
 - Black light then useless, which makes sense since it doesn't exist.
  - Could work as a super-secret hack weapon for experts


### Super weapon

- Uses a full bar of charge, is a static laser beam
- Beam is prepared by spinning 360 without firing
- Charge up noise starts when player flips but stops if flips dont chain
- Can be mistaken as just the sound that flipping makes
- Fires a static beam, makes a low musical, rending, metallic clang
- Time slows when the beam is fired giving the player time to stack them
- Crawls back to normal speed over about 1 second
- If player fires another beam on top in that time, it stacks
 - Stacked beams create a beam of the blended colour
 - When stack beam is produced, it sounds a broader, louder sound one 5th above the
  the original clang
- Time slow counter resets, waiting for third stack
- If third stack happens, white beam is produces and the broadest, loudest
 clang happens, at the octave above the original
- As time crawls back to normal, the beam destroys everything of matching
 colour


## TODO

- Engine
  - Real consistent game units
  - World binning
  - Sector binning
    - Turn whole world 45° to make binning easier?
  - Basic collision algorithm
- World
  - Basic world layout
  - Algorithm that creates sector angles from player max X speed?
- Vis
  - Seperate canvas for each vis, saves arranging them on the canvas
  - Sector debug overview
  - World debug overview
- Mechanics
  - Flipflop mode: Restrict blended fire to a max fire rate
  - Enemy firing
  - Player physics?? shmup guidelines say no but could feel good


### TODO: Experimental features

- Rolldodge
- Coloured fire-buttons
- Super laser
- Bomb
- Big-fire for dodgeroll combos
- Strict time
- Somersault
- Backwards zap
- Directional fire with second input

- Switches
  - Triggers flipflop / triggers rolldodge
  - Color by rotation / Color by input button
  - Shoulder super-laser
  - Strict-time on/off
  - Backwards zap rewinds time / just moves player


