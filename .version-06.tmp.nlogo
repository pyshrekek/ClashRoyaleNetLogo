globals [elixir time-elapsed time-left bottom-crowns top-crowns deck-rotation top-deck-rotation]

breed [towers tower]
breed [cards card]
breed [units unit]

cards-own [drag-state pos troop cost global? current-pos]
towers-own [hp pos side]
units-own [hp dmg speed atk-speed troop side fly? target-range atk-range targeted-troop]

to setup
  ca
  set deck-rotation ["SkeletonArmy" "HogRider" "Archers" "Minions" "Arrows" "Giant" "GoblinBarrel" "MiniPekka"]
  set top-deck-rotation ["SkeletonArmy" "HogRider" "Archers" "Minions" "Arrows" "Giant" "GoblinBarrel" "MiniPekka"]
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
  get-card-pos
  towers-update
  crowns-update
  card-drag
  target
  units-move
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
  create-towers 1 [set pos "bottom-left" set side "bottom" set shape "tower"]
  create-towers 1 [set pos "bottom-right" set side "bottom" set shape "tower"]
  create-towers 1 [set pos "bottom-king" set side "bottom" set shape "king"]
  create-towers 1 [set pos "top-left" set side "top" set shape "tower"]
  create-towers 1 [set pos "top-right" set side "top" set shape "tower"]
  create-towers 1 [set pos "top-king" set side "top" set shape "king"]
  ask towers
  [
    ifelse (side = "top")
    [set color red]
    [set color blue]
    ifelse (pos = "top-king" or pos = "bottom-king")
    [set size 4]
    [set size 3]
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

to card-setup ;creates cards
  card-spawn 1
  card-spawn 2
  card-spawn 3
  card-spawn 4
  ask cards
  [
    set shape troop
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
    set shape troop
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
; STATE MACHINE KINDA THING IDK LOL

to card-drag ;allows for player interaction with cards
             ;; POSSIBLE STATES: WAITING, DRAGGING
  ask cards
  [
    (
      ifelse
      (troop = "Archers") [set cost 3 set global? false]
      (troop = "Arrows") [set cost 3 set global? true]
      (troop = "Giant") [set cost 5 set global? false]
      (troop = "GoblinBarrel") [set cost 3 set global? true]
      (troop = "HogRider") [set cost 4 set global? false]
      (troop = "Minions") [set cost 3 set global? false]
      (troop = "MiniPekka") [set cost 4 set global? false]
      (troop = "SkeletonArmy") [set cost 3 set global? false]
    )
    (
      ifelse
      (mouse-down? and (distancexy mouse-xcor mouse-ycor <= 2) and drag-state = "waiting" and (count cards with [drag-state != "waiting"]) = 0)
      [select]

      (not mouse-down? and drag-state = "dragging")
      [
        (
          ifelse
          (current-pos = "on-map" and elixir >= cost)
          [release-valid]
          (current-pos = "invalid" or current-pos = "deck" or elixir < cost)
          [release-invalid]
        )
      ]

      (mouse-down? and drag-state = "dragging")
      [drag]
    )
  ]
end

;;Whenever the card is released and within the placeable area of the player, spawn troop, un-highlight patch, and create new card in the deck
to release-valid
  units-spawn troop
  reset-perspective
  set drag-state "waiting"
  ; insert current troop into last position of deck, then set troop of next card as top card in deck
  set deck-rotation insert-item ((position (last deck-rotation) deck-rotation) + 1) deck-rotation [troop] of self
  set elixir elixir - cost
  hatch-cards 1
  [
    set pos [pos] of self
    set troop first deck-rotation
    set shape troop
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
  set shape troop
  set color gray
  set size 4
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
  (
    ifelse
    (current-pos = "deck") [set shape troop set color gray set size 4 set heading 0 reset-perspective ]
    (current-pos = "invalid" or elixir < cost) [set shape "x" set color red set size 2 set heading 0 reset-perspective]
    (current-pos = "on-map" and elixir >= cost) [set shape "bug" set color gray set size 4 set heading 0 ask patch-here [watch-me]]
  )
  setxy mouse-xcor mouse-ycor
end

to select
  set drag-state "dragging"
end

to get-card-pos
  ask cards
  [
    (
      ifelse
      ; on deck
      (ycor < 4 or ycor > 36) [set current-pos "deck"]
      ; on water
      (ycor = 20 and (xcor <= 3 or (xcor >= 5 and xcor <= 15) or xcor >= 17)) [set current-pos "invalid"]
      ; global allows for worldwide placement
      (global?) [set current-pos "on-map"]
      ; otherwise you only get your side
      (ycor >= 20) [set current-pos "invalid"]
      [set current-pos "on-map"]
    )
  ]
end

;================================================================================

to units-spawn [t]
  ; variables: hp dmg speed atk-speed troop side fly? atk-range targeted-troop
  ; atk-speed is seconds per attack
  (
    ifelse
    (t = "Archers")
    [
      hatch-units 3
      [
        set hp 403
        set dmg 142
        set speed 60
        set atk-speed 1.1
        set fly? false
        set atk-range 5
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "Arrows")
    [
      hatch-units 1
      [
        set hp 1
        set dmg 162
        set speed 200
        set atk-range 4
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "Giant")
    [
      hatch-units 1
      [
        set hp 5423
        set dmg 337
        set speed 45
        set atk-speed 1.5
        set fly? false
        set atk-range 1
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "GoblinBarrel")
    [
      hatch-units 3
      [
        set hp 267
        set dmg 159
        set speed 120
        set atk-speed 1.1
        set fly? false
        set atk-range .5
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "HogRider")
    [
      hatch-units 1
      [
        set hp 2248
      set dmg 135
        set speed 120
        set atk-speed 1.6
        set fly? false
        set atk-range .8
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "Minions")
    [
      hatch-units 3
      [
        set hp 305
        set dmg 135
        set speed 90
        set atk-speed 1
        set fly? true
        set atk-range 1.6
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "MiniPekka")
    [
      hatch-units 1
      [
        set hp 1804
        set dmg 955
        set speed 90
        set atk-speed 1.6
        set fly? false
        set atk-range .5
        set shape (word t "-unit")
        set troop t
      ]
    ]
    (t = "SkeletonArmy")
    [
      hatch-units 15
      [
        set hp 108
        set dmg 108
        set speed 90
        set atk-speed 1
        set fly? false
        set atk-range .5
        set shape (word t "-unit")
        set troop t
      ]
    ]
  )
end

to units-move
  ask units
  [
    fd .000007 * speed
  ]
end

to towers-update ;tower attacking and death
  ask towers
  [
    if (hp <= 0) [die]
  ]
end

to target
  ask units
  [
    ifelse (targeted-troop = 0 or targeted-troop = nobody)
    [
      set targeted-troop (min-one-of units with [(side != [side] of self) and (distance self <= target-range)] [distance self])
    ]
    [
      face targeted-troop
    ]
  ]

end


;; UI/GAME PROGRESSION
to clock ;counts time elapsed and time left (assuming game time of 3 minutes)
  every 1 [set time-elapsed time-elapsed + 1]
  set time-left (word (floor ((180 - time-elapsed) / 60)) ":" (remainder (180 - time-elapsed) 60))
end

to elixir-update ;updates and counts elixir for player 1
  ifelse (elixir <= 10 and not god-mode)
  [
    ifelse (time-elapsed >= 120)
    [every 1.4 [set elixir elixir + 1]]
    [every 2.8 [set elixir elixir + 1]]
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

MONITOR
107
610
185
655
NEXT CARD
first deck-rotation
17
1
11

SWITCH
32
442
143
475
god-mode
god-mode
0
1
-1000

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

archers
false
0
Rectangle -11221820 true false 0 0 300 300
Rectangle -10899396 true false 0 210 300 300
Polygon -13791810 true false 80 186 56 238 75 300 195 300 195 209 158 173
Polygon -1184463 true false 55 99 55 217 133 239 192 174 157 72
Polygon -5825686 true false 60 105 156 80 187 185 203 180 175 38 111 40 35 65 37 219 65 216
Polygon -1 true false 68 127 92 119 112 132 88 140
Polygon -1 true false 159 118 135 110 115 123 139 131
Circle -11221820 true false 86 123 14
Circle -11221820 true false 132 113 15
Polygon -16777216 true false 119 147 110 175 132 175 118 165
Polygon -2064490 true false 104 196 123 199 145 190 138 204 110 210
Polygon -1184463 true false 217 31 269 138 251 260 253 147
Line -1 false 221 42 252 251
Line -6459832 false 154 166 268 145
Polygon -2674135 true false 260 130 289 143 263 157
Polygon -6459832 true false 75 279 21 251 86 158 169 167 93 178 59 250 79 270
Polygon -6459832 true false 186 242 260 169 260 191 184 256
Rectangle -16777216 false false 0 0 300 300
Circle -5825686 true false 75 15 0
Circle -5825686 true false 30 270 60
Circle -5825686 true false 120 270 60
Circle -5825686 true false 210 270 60

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

arrows
false
0
Rectangle -13791810 true false 0 0 300 300
Polygon -6459832 true false 165 165 195 75 210 90 165 165
Polygon -1 true false 180 150 165 135 150 180 150 195 165 195 180 150
Polygon -6459832 true false 90 210 120 120 135 135 90 210
Polygon -6459832 true false 60 165 90 75 105 90 60 165
Polygon -1 true false 60 180 120 105
Polygon -1 true false 60 180 90 75
Polygon -1 true false 75 150 60 135 45 180 45 195 60 195 75 150
Polygon -1 true false 105 195 90 180 75 225 75 240 90 240 105 195
Polygon -6459832 true false 90 105 75 105
Polygon -6459832 true false 75 75
Polygon -6459832 true false 180 240 210 150 225 165 180 240
Polygon -6459832 true false 225 225 255 135 270 150 225 225
Polygon -1 true false 240 210 225 195 210 240 210 255 225 255 240 210
Polygon -1 true false 195 225 180 210 165 255 165 270 180 270 195 225
Polygon -2674135 true false 90 75 75 60 90 105 120 90 105 90
Polygon -2674135 true false 120 120 105 105 120 150 150 135 135 135
Polygon -2674135 true false 195 75 180 60 195 105 225 90 210 90
Polygon -2674135 true false 210 150 195 135 210 180 240 165 225 165
Polygon -2674135 true false 255 135 240 120 255 165 285 150 270 150
Rectangle -16777216 false false 0 0 300 300
Circle -5825686 true false 30 270 58
Circle -5825686 true false 210 270 58
Circle -5825686 true false 120 270 58

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

giant
false
0
Rectangle -11221820 true false 0 0 300 300
Polygon -6459832 true false 74 200 -2 237 -6 311 312 312 225 200
Polygon -1184463 true false 73 31 41 170 111 251 165 260 242 205 257 65 160 21
Circle -1 true false 96 68 42
Circle -1 true false 168 80 42
Circle -13345367 true false 110 78 21
Circle -13345367 true false 180 91 21
Polygon -955883 true false 222 85 225 58 171 57 168 73 210 75
Polygon -955883 true false 88 74 85 47 139 46 142 62 100 64
Polygon -955883 true false 70 50 41 70 56 94 71 62
Polygon -955883 true false 245 151 165 260 206 244 255 198
Polygon -955883 true false 50 116 114 253 65 224 31 154
Polygon -16777216 true false 112 171 143 189 183 173 151 206
Polygon -16777216 true false 150 124 138 149 156 149 147 145
Rectangle -16777216 false false 0 0 300 300
Circle -5825686 true false 9 279 42
Circle -5825686 true false 249 279 42
Circle -5825686 true false 189 279 42
Circle -5825686 true false 129 279 42
Circle -5825686 true false 69 279 42

giant-unit
true
0
Rectangle -1184463 true false 103 226 117 267
Rectangle -1184463 true false 167 224 177 270
Polygon -1184463 true false 211 172 243 170 240 119 263 119 266 195 202 190
Polygon -1184463 true false 71 172 41 176 42 133 20 138 24 197 77 192
Polygon -6459832 true false 56 166 114 134 187 133 232 158 217 241 74 240
Circle -1184463 true false 109 77 75
Polygon -955883 true false 119 113 121 139 152 146 176 126 182 138 162 162 113 151 101 117
Polygon -13791810 true false 94 165 78 190 96 198 117 176
Circle -1 true false 122 76 13
Circle -1 true false 159 78 13
Circle -16777216 true false 125 79 8
Circle -16777216 true false 163 80 8

goblinbarrel
false
0
Rectangle -11221820 true false 0 0 300 300
Polygon -16777216 false false 112 95 67 121 37 191 107 250 219 225 233 165 213 121
Polygon -6459832 true false 59 147 0 285 0 300 135 300 228 194
Polygon -6459832 true false 64 133 49 178 73 236 147 259 218 224 232 168 213 122 174 107 104 105
Polygon -13840069 true false 104 175 93 118 145 26 241 77 187 155 136 190
Polygon -13840069 true false 205 109 241 111 266 143 248 93 199 92
Polygon -13840069 true false 156 63 110 21 79 25 107 38 124 88
Polygon -16777216 true false 125 115 128 145 149 155 175 135
Polygon -2674135 true false 137 134 111 141 125 157
Circle -1184463 true false 147 61 20
Circle -1184463 true false 184 77 20
Circle -10899396 true false 150 66 14
Circle -10899396 true false 188 82 14
Polygon -13840069 true false 105 163 63 213 121 248 153 169
Polygon -13840069 true false 98 189 50 104 36 118 100 195
Polygon -13840069 true false 61 134 74 66
Polygon -13840069 true false 130 199 230 171 232 193
Polygon -16777216 true false 35 190 64 241 107 266 183 258 163 279 102 280 54 257 32 210
Rectangle -16777216 false false 0 0 300 300
Polygon -1184463 true false 165 90 150 105 165 120
Circle -5825686 true false 26 266 67
Circle -5825686 true false 206 266 67
Circle -5825686 true false 116 266 67

hogrider
false
0
Rectangle -11221820 true false 0 0 300 300
Rectangle -10899396 true false 0 150 300 300
Polygon -6459832 true false 0 180 81 162 101 111 82 83 105 70 121 29 178 14 233 42 230 108 212 179 300 240 300 300 0 300
Polygon -16777216 true false 113 75 88 169 131 201 154 201 206 179 220 116 204 121 186 163 165 172 124 162 113 141 122 79
Polygon -16777216 true false 149 190
Polygon -16777216 true false 111 120 162 112 205 130 200 141 157 126 112 132
Polygon -1 true false 126 137 128 150 175 156 181 145 148 145 126 140
Circle -1 true false 139 60 23
Circle -1 true false 184 57 23
Polygon -16777216 true false 130 57 153 43 171 55 148 54
Polygon -16777216 true false 174 54 197 40 217 56 192 51
Circle -11221820 true false 145 65 12
Circle -11221820 true false 191 62 14
Polygon -16777216 true false 168 94 155 105 182 108 170 101
Polygon -16777216 true false 173 31 118 33 117 30 145 10 206 7
Polygon -6459832 true false 25 93 0 135 0 165 37 97
Polygon -1184463 true false 61 77 0 60 0 90 0 105 25 127 78 118
Rectangle -16777216 false false 0 0 300 300
Circle -5825686 true false 39 279 42
Circle -5825686 true false 219 279 42
Circle -5825686 true false 159 279 42
Circle -5825686 true false 99 279 42

hogrider-unit
true
0
Polygon -6459832 true false 217 120 215 161 227 162 228 120
Polygon -2064490 true false 90 270 73 208 131 177 201 209 183 267
Polygon -6459832 true false 108 194 97 122 134 102 184 123 162 206
Polygon -6459832 true false 111 180 54 205 67 263 73 212 115 193
Polygon -6459832 true false 158 199 205 222 195 267 221 263 223 203 155 179
Circle -6459832 true false 93 28 93
Polygon -16777216 true false 127 94 124 26 145 22 147 97
Polygon -1184463 true false 226 87 195 95 195 122 221 130 254 117 250 101
Rectangle -955883 true false 170 152 170 151
Polygon -955883 true false 167 150 223 151 222 162 164 160
Polygon -2064490 true false 111 263 109 292 122 291 125 256
Polygon -2064490 true false 148 257 150 292 165 288 163 255

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

king
false
1
Polygon -7500403 true false 0 15 45 15 45 75 120 75 120 75 180 75 180 75 255 75 255 15 300 15 300 300 0 300
Rectangle -2674135 true true 0 120 300 180
Rectangle -1184463 true false 75 180 75 195
Polygon -16777216 false false 0 15 45 15 45 75 120 75 120 75 180 75 180 75 255 75 255 15 300 15 300 300 0 300 0 15
Polygon -1184463 true false 75 -30 105 45 195 45 225 -30 180 0 150 -45 120 0
Circle -955883 true false 86 26 127
Circle -1 true false 112 55 30
Circle -1 true false 157 55 30
Polygon -16777216 true false 123 116 148 128 177 111 146 104
Circle -13791810 true false 118 62 18
Circle -13791810 true false 164 63 18

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

minions
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -16777216 false false 0 0 300 300
Polygon -13345367 true false 105 198 91 275 115 262 132 199
Polygon -13345367 true false 179 189 193 266 169 253 152 190
Polygon -13791810 true false 248 191 257 128 198 71 173 75 224 136 232 197
Polygon -13791810 true false 77 114 27 37
Polygon -13791810 true false 51 187 42 124 101 67 126 71 75 132 67 193
Polygon -13791810 true false 124 15 90 38 89 82 97 125 141 155 194 113 192 78 193 23
Polygon -13791810 true false 113 130 91 197 135 221 196 192 164 133
Circle -13345367 true false 33 171 47
Circle -13345367 true false 209 174 47
Circle -1 true false 116 58 18
Circle -1 true false 158 58 18
Line -16777216 false 186 41 154 54
Line -16777216 false 106 44 138 57
Polygon -16777216 true false 118 114 144 98 165 117 142 110
Circle -5825686 true false 30 270 60
Circle -5825686 true false 210 270 60
Circle -5825686 true false 120 270 60

minipekka
false
0
Rectangle -13345367 true false 0 0 300 300
Polygon -11221820 true false 202 82 248 78 252 40 265 95 210 111
Polygon -11221820 true false 77 65 39 60 24 25 18 89 75 99
Polygon -7500403 true true 160 49 85 48 53 101 52 179 30 300 285 300 232 219 260 168 232 143 216 56
Polygon -13791810 true false 140 145 109 107 178 108
Polygon -13791810 true false 128 179
Polygon -7500403 true true 217 188 268 123 286 118 276 158 222 210
Polygon -6459832 true false 273 122 273 87 282 89 283 132
Polygon -16777216 true false 275 89 252 33 266 7 289 22 279 97
Rectangle -16777216 false false 0 0 300 300
Line -16777216 false 45 180 240 225
Circle -5825686 true false 39 279 42
Circle -5825686 true false 219 279 42
Circle -5825686 true false 159 279 42
Circle -5825686 true false 99 279 42

minipekka-unit
true
0
Rectangle -16777216 true false 182 233 199 283
Rectangle -16777216 true false 104 236 121 280
Polygon -7500403 true true 156 73 86 104 85 140 219 138 220 116
Polygon -7500403 true true 95 122 61 196 72 254 239 249 250 180 203 112
Rectangle -16777216 true false 239 144 239 142
Polygon -6459832 true false 239 127 237 152 251 154 252 132
Polygon -7500403 true true 244 137 227 130 232 88 251 65 264 89 259 143
Polygon -16777216 true false 217 172 240 144 248 150 221 178
Polygon -11221820 true false 96 112 70 106 58 76 51 115 96 132
Polygon -11221820 true false 208 121 236 106 226 66 252 100 208 133
Line -16777216 false 87 145 220 139

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

skeletonarmy
false
0
Rectangle -8630108 true false 0 0 300 300
Rectangle -1 true false 180 165 270 285
Rectangle -16777216 false false 180 165 270 285
Rectangle -1 true false 90 15 165 150
Rectangle -16777216 false false 90 15 165 150
Rectangle -1 true false 15 105 105 240
Rectangle -16777216 false false 15 105 105 240
Rectangle -16777216 true false 30 135 45 150
Rectangle -16777216 true false 60 135 75 150
Rectangle -7500403 true true 30 195 75 210
Rectangle -16777216 true false 105 45 120 60
Rectangle -16777216 true false 135 45 150 60
Rectangle -7500403 true true 105 120 135 135
Rectangle -7500403 true true 195 240 255 255
Rectangle -16777216 true false 210 195 225 210
Rectangle -16777216 true false 240 195 255 210
Rectangle -16777216 false false 195 45 285 150
Rectangle -1 true false 195 45 285 150
Rectangle -16777216 true false 225 75 240 75
Rectangle -16777216 true false 210 60 225 75
Rectangle -16777216 true false 240 60 255 75
Rectangle -7500403 true true 225 105 270 120
Rectangle -16777216 false false 195 45 285 150
Rectangle -16777216 false false 0 0 300 300
Circle -5825686 true false 26 266 67
Circle -5825686 true false 206 266 67
Circle -5825686 true false 116 266 67

skeletonarmy-unit
true
0
Polygon -7500403 true true 150 250 118 274 123 281 152 257 171 282 179 275 159 254
Polygon -1 true false 109 53 74 110 111 164 187 163 221 124 185 51
Polygon -1 true false 148 156 144 260 162 261 163 149
Polygon -1 true false 152 199 130 192 129 171 119 178 124 194 151 206 184 196 180 172 170 176 172 191 156 196
Circle -16777216 true false 106 71 34
Circle -16777216 true false 149 70 34

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

tower
false
1
Rectangle -7500403 true false 0 105 300 300
Rectangle -7500403 true false 0 45 45 120
Rectangle -7500403 true false 120 45 180 105
Rectangle -7500403 true false 255 45 300 120
Rectangle -2674135 true true 0 120 300 150
Rectangle -1184463 true false 75 180 75 195
Polygon -1184463 true false 89 189 99 231 199 233 208 174 177 200 151 169 127 194 88 174
Polygon -16777216 false false 0 45 45 45 45 105 120 105 120 45 180 45 180 105 255 105 255 45 300 45 300 300 0 300 0 45

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
