# IntroCSFinal
Intro to Computer Science Final 2022 

By Khin Aung and Haokun (Daniel) Xu

## TODO:

### BOLDED indicates high priority

### Game Mechanics
- [ ] drop and place cards
    - [x] drag with mouse
    - [ ] **spawn troop on drop (state machine type beat)**
    - [could use this model](http://www.netlogoweb.org/launch#http://ccl.northwestern.edu/netlogo/models/models/Code%20Examples/Mouse%20Drag%20Multiple%20Example.nlogo)
- [ ] card attacks
- [ ] **tower pathing**
    - Use SlimeMold like pheromone pathing
- [x] structure hp
- [ ] match progression (based on time)
    - [x] 2x elixir under 1 min
    - [ ] overtime
- [ ] **elixir (subtract when place cards)**

### Game UI / Map
- [x] Elixir bar
- [x] Elixir counter
- [x] Time left
- [x] Crown count
- [x] Tower / Enemy HP
- [ ] Range display
- [ ] **Deck display w/ cooldown**
    - Make decks a rectangle with a netlogo vector shape (importing actual card images is very janky and does not work as a turtle)
    - Assign each card in the deck an appropriate vector shape that makes some degree of sense. (Person is giant) (person on wolf is HOG RIDEEEER)
