# ClashRoyaleNetLogo
Final Assingment for Intro to Computer Science Spring 2022

By Khin Aung and Haokun (Daniel) Xu


![](https://github-readme-stats.vercel.app/api/pin/?username=pyshrekek&repo=ClashRoyaleNetLogo&cache_seconds=86400&theme=tokyonight)

## TODO:

### GAME IS IN PLAYABLE STATE!!!

### Game Mechanics
- [x] drop and place cards
    - [x] drag with mouse
    - [x] spawn troop on drop (state machine type beat)
    - [x] deck rotation
    - [could use this model](http://www.netlogoweb.org/launch#http://ccl.northwestern.edu/netlogo/models/models/Code%20Examples/Mouse%20Drag%20Multiple%20Example.nlogo)
- [x] card attacks
- [x] tower pathing
    - Use SlimeMold like pheromone pathing
- [x] structure hp
- [ ] match progression (based on time)
    - [x] 2x elixir under 1 min
    - [ ] overtime
- [x] elixir (subtract when place cards)
- [x] troop targetting
    - Both enemy troops and your troops follow the same procedure: 
        - When an opposing troop is within (troop range) then it will lock on and start executing the
        attack procedure (melee towers will move towards the target before attacking), loop attack until opposing troop dies (or you die but that doesn't need to be coded). Once opposing troop dies then repeat targetting procedure. 
        - While there no opposing troop in range execute the structure targetting procedure.
- [ ] **valid troop placement** (extended placement values when tower is broken) ***might not do***

### Game UI / Map
- [x] Elixir bar
- [x] Elixir counter
- [x] Time left
- [x] Crown count
- [x] Tower / Enemy HP
- [ ] ~~Range display~~
- [x] Deck display w/ cooldown/cost
    - Make decks a rectangle with a netlogo vector shape (importing actual card images is very janky and does not work as a turtle)
    - Assign each card in the deck an appropriate vector shape that makes some degree of sense. (Person is giant) (person on wolf is HOG RIDEEEER)
- [x] Add elixir costs to card sprite


# Troop Stats
- **VALUES ARE SUBJECT TO CHANGE**

| Troop        | size | hp   | unit-dmg | building-dmg | speed | sec/atk | fly? | atk-range           | attack-type | sight-range | notes               |
|--------------|------|------|----------|--------------|-------|---------|------|---------------------|-------------|-------------|---------------------|
| Archers      | 2.5  | 403  | 142      | 142          | 60    | 1.1     | no   | 5                   | ranged      | 5.5         | spawns 2            |
| Arrows       | 8    | n/a  | 162 x 3  | 49 x 3       | n/a   | n/a     | n/a  | 5 (radius of spell) | spell       | n/a         |                     |
| Giant        | 5    | 5423 | 337      | 337          | 45    | 1.5     | no   | medium (1?)         | melee       | 7.5         |                     |
| GoblinBarrel | 2.5  | 267  | 159      | 159          | 120   | 1.1     | no   | short (.5)          | melee       | 5.5         | spawns 3            |
| HogRider     | 3.5  | 2248 | 421      | 421          | 120   | 1.6     | no   | short (.8)          | melee       | 9.5         | can hop river       |
| Minions      | 2.5  | 305  | 135      | 135          | 90    | 1       | yes  | 1.6                 | ranged      | 5.5         | spawns 3            |
| MiniPekka    | 3    | 1804 | 955      | 955          | 90    | 1.6     | no   | short               | melee       | 5           |                     |
| SkeletonArmy | 1    | 108  | 108      | 108          | 90    | 1       | no   | short (.5)          | melee       | 5.5         | spawns 15 skeletons |
