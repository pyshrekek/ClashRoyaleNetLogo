globals [elixir time-elapsed time-left bottom-crowns top-crowns deck-rotation]

breed [towers tower]
breed [tests test]
breed [cards card]

tests-own [hp]
cards-own [drag-state pos troop]
towers-own [hp pos side]

to setup
  ca
  set deck-rotation ["Goblin" "Knight" "Archer" "Minions" "Arrows" "Giant" "GoblinBarrel" "MiniPekka"]
  set time-elapsed 0
  resize-world 0 20 0 40
  set-patch-size 18
  set elixir 4
  board
  towers-make
  card-setup
  set time-left "3:00"
end

to go
  clock
  elixir-update
  test-move
  test-attack
  towers-update
  crowns-update
  card-drag
end

;; UI/GAME PROGRESSION
to clock ;counts time elapsed and time left (assuming game time of 3 minutes)
  every 1 [set time-elapsed time-elapsed + 1]
  set time-left (word (floor ((180 - time-elapsed) / 60)) ":" (remainder (180 - time-elapsed) 60))
end

to elixir-update ;updates and counts elixir for player 1
  ifelse (elixir <= 10)
  [
    ifelse (time-elapsed >= 120)
    [every .5 [set elixir elixir + 1]]
    [every 1 [set elixir elixir + 1]]
  ]
  [set elixir 10]

  ;; draw elixir count on screen
  ask patches with [pxcor <= (elixir * 2) and pxcor != 0 and pxcor != 20 and odd? pxcor and pycor = 0] [set pcolor magenta]
  ask patches with [pxcor > (elixir * 2) and pxcor != 0 and pxcor != 20 and odd? pxcor and pycor = 0] [set pcolor brown]
end

to crowns-update ;updates and counts crowns for both players
  set top-crowns 3 - (count towers with [side = "bottom"])
  set bottom-crowns 3 - (count towers with [side = "top"])
end



;; SETUP COMMANDS
to board ;sets up the game field and UI
  ;; playing field
  ask patches [set pcolor 65]
  ask patches with [(even? pxcor and even? pycor) or (odd? pxcor and odd? pycor)] [set pcolor 67]
  ask patches with [pycor = 20] [set pcolor blue]
  ;; deck
  ask patches with [pycor <= 3 or pycor >= 37] [set pcolor brown]
    ask patches with [even? pxcor and pycor = 0] [set pcolor black]
  ;; paths
  ask patches with
  [
    ((pxcor = 4 or pxcor = 16) and (pycor >= 6 and pycor <= 34)) or
    ((pxcor >= 4 and pxcor <= 16) and (pycor = 6 or pycor = 34))
  ]
  [set pcolor 27]
end

to towers-make ;spawns in towers
  ;; at (4,10) (16,10) (10,6) (4,30) (16,30) (10,34)
  create-towers 1 [set pos "bottom-left" set side "bottom"]
  create-towers 1 [set pos "bottom-right" set side "bottom"]
  create-towers 1 [set pos "bottom-king" set side "bottom"]
  create-towers 1 [set pos "top-left" set side "top"]
  create-towers 1 [set pos "top-right" set side "top"]
  create-towers 1 [set pos "top-king" set side "top"]
  ask towers
  [
    set shape "box"
    set color gray
    set size 3
    (ifelse
      (pos = "bottom-left") [set xcor 4 set ycor 10 face patch 4 20 set hp 5000]
      (pos = "bottom-right") [set xcor 16 set ycor 10 face patch 16 20 set hp 5000]
      (pos = "bottom-king") [set xcor 10 set ycor 6 face patch 10 20 set hp 7500]
      (pos = "top-left") [set xcor 4 set ycor 30 face patch 4 20 set hp 5000]
      (pos = "top-right") [set xcor 16 set ycor 30 face patch 16 20 set hp 5000]
      (pos = "top-king") [set xcor 10 set ycor 34 face patch 10 20 set hp 7500]
    )
  ]
end



;; CARDS
to test-spawn
  hatch-tests 1
  [
    setxy mouse-xcor mouse-ycor
    set shape "bug"
    set heading 0
  ]
end

to test-move
  every .3
  [
    ask tests [fd 1]
  ]
end

to test-attack
  ask tests
  [
    ask towers-here with [side = "top"] [set hp 0]
  ]
end



to card-setup ;creates cards
  card-spawn 1
  card-spawn 2
  card-spawn 3
  card-spawn 4
  ask cards
  [
    set shape "square"
    set size 4
    set color gray
    set drag-state "waiting"
  ]
end

;; p is the position of the card (1, 2, 3, or 4) - caller is the caller of the function (observer, turtle)
to card-spawn [p]
  create-cards 1
  [
    set pos p
    set troop (one-of deck-rotation)
    set deck-rotation remove [troop] of self deck-rotation
    (
      ifelse
      (pos = 1) [setxy 2.5 3]
      (pos = 2) [setxy 7.5 3]
      (pos = 3) [setxy 12.5 3]
      (pos = 4) [setxy 17.5 3]
    )
  ]
end

;================================================================================
;STATE MACHINE KINDA THING IDK LOL

to card-drag ;allows for player interaction with cards
  ;; POSSIBLE STATES: WAITING, DRAGGING, RELEASING
  ask cards
  [
    (
      ifelse
      (drag-state = "releasing")
      [release-valid]

      (mouse-down? and (distancexy mouse-xcor mouse-ycor <= 2) and drag-state = "waiting" and (count cards with [drag-state != "waiting"]) = 0)
      [select]

      (not mouse-down? and drag-state = "dragging")
      [
        (
          ifelse
          (mouse-ycor <= 3 or mouse-ycor >= 20)
          [release-invalid]
          (mouse-ycor > 3 and mouse-ycor < 20)
          [release-valid]
        )
      ]

      (mouse-down? and drag-state = "dragging")
      [drag]
    )
  ]
end

;;Whenever the card is released and within the placeable area of the player, spawn troop, un-highlight patch, and create new card in the deck
to release-valid
  test-spawn
  reset-perspective
  set drag-state "waiting"
  ; insert current troop into last position of deck, then set troop of next card as top card in deck
  set deck-rotation insert-item ((position (last deck-rotation) deck-rotation) + 1) deck-rotation [troop] of self
  hatch-cards 1
  [
    set pos [pos] of self
    set troop first deck-rotation
    set deck-rotation but-first deck-rotation
    (
      ifelse
      (pos = 1) [setxy 2.5 3]
      (pos = 2) [setxy 7.5 3]
      (pos = 3) [setxy 12.5 3]
      (pos = 4) [setxy 17.5 3]
    )
  ]
  die
end

;;Whenever the card is released and not within the placeable area of the player
to release-invalid
  reset-perspective
  set drag-state "waiting"
  (
    ifelse
    (pos = 1) [setxy 2.5 3]
    (pos = 2) [setxy 7.5 3]
    (pos = 3) [setxy 12.5 3]
    (pos = 4) [setxy 17.5 3]
  )
end

;;Move the card
to drag
  ifelse (ycor > 3) [set shape "bug" set heading 0] [set shape "square" set heading 0]
  setxy mouse-xcor mouse-ycor
  ask patch-here [watch-me]
end

to select
  set drag-state "dragging"
end

;================================================================================

to towers-update ;tower attacking and death
  ask towers
  [
    if (hp <= 0) [die]
  ]
end



;; AUXILIARY FUNCTIONS
to-report even? [n]
  report n mod 2 = 0
end

to-report odd? [n]
  report not even? n
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
596
757
-1
-1
18.0
1
10
1
1
1
0
0
0
1
0
20
0
40
0
0
1
ticks
30.0

MONITOR
0
0
0
0
NIL
NIL
17
1
11

BUTTON
8
30
92
108
NIL
setup
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

MONITOR
119
712
202
757
NIL
elixir
17
1
11

BUTTON
93
30
175
109
NIL
go
T
1
T
OBSERVER
NIL
E
NIL
NIL
1

MONITOR
689
10
783
55
NIL
time-elapsed
17
1
11

MONITOR
603
11
669
56
NIL
time-left
17
1
11

MONITOR
610
538
681
583
bot-left hp
first [hp] of towers with [pos = \"bottom-left\"]
0
1
11

MONITOR
701
537
780
582
bot-right hp
first [hp] of towers with [pos = \"bottom-right\"]
17
1
11

MONITOR
657
590
732
635
bot-king hp
first [hp] of towers with [pos = \"bottom-king\"]
17
1
11

MONITOR
603
174
675
219
top-left hp
first [hp] of towers with [pos = \"top-left\"]
17
1
11

MONITOR
690
174
769
219
top-right hp
first [hp] of towers with [pos = \"top-right\"]
17
1
11

MONITOR
644
115
719
160
top-king hp
first [hp] of towers with [pos = \"top-king\"]
17
1
11

MONITOR
604
64
679
109
NIL
top-crowns
17
1
11

MONITOR
608
647
704
692
NIL
bottom-crowns
17
1
11

MONITOR
611
282
828
327
NIL
[troop] of cards with [pos = 1]
17
1
11

MONITOR
616
341
827
386
NIL
[troop] of cards with [pos = 2]
17
1
11

MONITOR
620
394
831
439
NIL
[troop] of cards with [pos = 3]
17
1
11

MONITOR
621
457
832
502
NIL
[troop] of cards with [pos = 4]
17
1
11

MONITOR
172
763
714
808
NIL
deck-rotation
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
