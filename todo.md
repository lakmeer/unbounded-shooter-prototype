
# UNBOUNDED SHOOTER

## NOTES

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

- Real game units
- Player physics
- Basic world layout
  - Algorithm that creates sector angles from player max X speed?
- World binning
- Sector binning
  - Turn whole world 45° to make binning easier?
- Basic collision algorithm
- Spawn some enemies in each sector
- Sector debug overview
- World debug overview

- Finish latching flipflipper using better state structure
- OR finish it with computer-controlled releases
- Create real diamond normaliser for gamepad input
- Fine tune firing rules
  - Restrict blended fire to a max fire rate

