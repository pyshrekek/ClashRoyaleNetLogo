# ClashRoyaleNetLogo
Final Assingment for Intro to Computer Science Spring 2022

By Khin Aung and Haokun (Daniel) Xu

## TODO:

### BOLDED indicates high priority

### Game Mechanics
- [x] drop and place cards
    - [x] drag with mouse
    - [x] spawn troop on drop (state machine type beat)
    - [x] deck rotation
    - [could use this model](http://www.netlogoweb.org/launch#http://ccl.northwestern.edu/netlogo/models/models/Code%20Examples/Mouse%20Drag%20Multiple%20Example.nlogo)
- [ ] card attacks
- [ ] **tower pathing**
    - Use SlimeMold like pheromone pathing
- [x] structure hp
- [ ] match progression (based on time)
    - [x] 2x elixir under 1 min
    - [ ] overtime
- [x] elixir (subtract when place cards)
- [ ] **troop targetting**
    - Both enemy troops and your troops follow the same procedure: 
        - When an opposing troop is within (troop range) then it will lock on and start executing the
        attack procedure (melee towers will move towards the target before attacking), loop attack until opposing troop dies (or you die but that doesn't need to be coded). Once opposing troop dies then repeat targetting procedure. 
        - While there no opposing troop in range execute the structure targetting procedure.
- [ ] **valid troop placement** (extended placement values when tower is broken)

### Game UI / Map
- [x] Elixir bar
- [x] Elixir counter
- [x] Time left
- [x] Crown count
- [x] Tower / Enemy HP
- [ ] Range display
- [x] Deck display w/ cooldown/cost
    - Make decks a rectangle with a netlogo vector shape (importing actual card images is very janky and does not work as a turtle)
    - Assign each card in the deck an appropriate vector shape that makes some degree of sense. (Person is giant) (person on wolf is HOG RIDEEEER)
- [x] Add elixir costs to card sprite


# Troop Stats
- **VALUES ARE SUBJECT TO CHANGE**

| Troop        | size | hp  | unit-dmg | building-dmg | speed | fly? | unit-range | attack-type                                                                                                          |
|--------------|------|-----|----------|--------------|-------|------|------------|----------------------------------------------------------------------------------------------------------------------|
| Archers      |      |     |          |              |       |      |            | ranged                                                                                                               |
| Arrows       |      |     |          |              |       |      |            | spell                                                                                                                |
| Giant        | 5    | 350 | 20       | 35           | 0.6   | no   |            | melee                                                                                                                |
| GoblinBarrel |      |     |          |              |       |      |            | melee (not a spell bc we will just make it spawn a sprite of the thing getting thrown but in the end it spawns gobs) |
| HogRider     |      |     |          |              |       |      |            |                                                                                                                      |
| Minions      |      |     |          |              |       |      |            |                                                                                                                      |
| MiniPekka    | 3    | 100 | 40       | 40           | 1     | no   |            | melee                                                                                                                |
| SkeletonArmy |      |     |          |              |       |      |            |                                                                                                                      |
