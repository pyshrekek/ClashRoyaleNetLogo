extensions [sound]

globals
[
  elixir top-elixir
  time-elapsed time-left
  bottom-crowns top-crowns
  deck-rotation top-deck-rotation
  speed-constant
]

breed [towers tower]
breed [cards card]
breed [units unit]
breed [top-cards top-card]
breed [spells spell]
breed [projectiles projectile]
breed [hehehehaws hehehehaw]

patches-own [bottom-priority top-priority]
cards-own [drag-state pos troop cost global? current-pos]
top-cards-own [pos troop cost global?]
towers-own [hp pos side troop dmg atk-range sight-range targeted-troop]
units-own [hp dmg speed atk-speed troop side fly? atk-range sight-range targeted-troop atk-type dps]
spells-own [speed troop side landing-patch]
projectiles-own [speed targeted-troop dmg]

to setup
  ; reset
  ca

  ; set global variables
  set speed-constant .000007
  set deck-rotation ["Archers" "Arrows" "Giant" "GoblinBarrel" "HogRider" "Minions" "MiniPekka" "SkeletonArmy"]
  set top-deck-rotation ["Archers" "Arrows" "Giant" "GoblinBarrel" "HogRider" "Minions" "MiniPekka" "SkeletonArmy"]
  set top-deck-rotation shuffle top-deck-rotation
  set time-elapsed 0
  set elixir 4
  set top-elixir 4
  set time-left "3:00"

  ; setup world
  resize-world 0 20 0 40
  set-patch-size 18
  board
  towers-spawn

  ; setup cards
  card-setup
  top-card-setup
end

to go
  ; overall stuff
  labelhp
  clock
  winloss
  elixir-update
  crowns-update

  ; ai send
  top-send-troop

  ; card dragging
  get-card-pos
  card-drag

  ; unit targeting
  target
  towers-target

  ; move stuff
  projectiles-move
  units-move
  spells-move

  ; unit procedures
  units-attack
  units-die

  ; tower procedures
  towers-attack
  towers-die
end

; HEHEHEHAW
to emote
  sound:play-sound "hehehehaw.wav"
  create-hehehehaws 1
  [
    set shape "hehehehaw"
    set size 8
    setxy 10 10
  ]
  wait 1.5
  ask hehehehaws [die]
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

to top-card-spawn [p]
  create-top-cards 1
  [
    set pos p
    set troop first top-deck-rotation
    set top-deck-rotation remove [troop] of self top-deck-rotation
    hide-turtle
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
  ]
end

to top-card-setup
  top-card-spawn 1
  top-card-spawn 2
  top-card-spawn 3
  top-card-spawn 4
end

to top-send-troop
  let pos-send 1 + random 3
  ifelse (top-elixir >= (first [cost] of top-cards with [pos = pos-send]))
  [
    ask one-of towers with [pos = "top-left" or pos = "top-right"]
    [
      units-spawn (first [troop] of top-cards with [pos = pos-send]) "top"
      set top-elixir top-elixir - (first [cost] of top-cards with [pos = pos-send])
      set top-deck-rotation insert-item ((position (last top-deck-rotation) top-deck-rotation) + 1) top-deck-rotation (first [troop] of top-cards with [pos = pos-send])
    ]
    ask top-cards with [pos = pos-send]
    [
      die
    ]
    top-card-spawn pos-send
  ]
  []
end

;; p is the position of the card (1, 2, 3, or 4)
to card-spawn [p]
  create-cards 1
  [
    set pos p
    set troop (one-of deck-rotation)
    set shape troop
    set deck-rotation remove [troop] of self deck-rotation
    set drag-state "waiting"
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
  units-spawn troop "bottom"
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
    (current-pos = "on-map" and elixir >= cost) [set shape (word troop "-unit") set color gray set size 4 set heading 0 ask patch-here [watch-me]]
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
      (ycor > 19 and ycor < 21 and (xcor <= 3 or (xcor >= 5 and xcor <= 15) or xcor >= 17)) [set current-pos "invalid"]
      ; global allows for worldwide placement
      (global?) [set current-pos "on-map"]
      ; otherwise you only get your side
      (ycor >= 20) [set current-pos "invalid"]
      [set current-pos "on-map"]
    )
  ]
end

;================================================================================

to units-spawn [t s]
  ; variables: hp dmg speed atk-speed troop side fly? atk-range targeted-troop
  ; atk-speed is seconds per attack
  (
    ifelse
    (t = "Archers")
    [
      hatch-units 1
      [
        set size 2.5
        set hp 403
        set dmg 142
        set speed 60
        set atk-speed 1.1
        set fly? false
        set atk-range 5
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "ranged"
        set side s
        set xcor xcor + 1
      ]
      hatch-units 1
      [
        set size 2.5
        set hp 403
        set dmg 142
        set speed 60
        set atk-speed 1.1
        set fly? false
        set atk-range 5
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "ranged"
        set side s
        set xcor xcor - 1
      ]
    ]
    (t = "Arrows")
    [
      ask towers with [side = s and pos = (word s "-king")]
      [
        hatch-spells 1
        [
          set size 8
          set speed 1500
          set troop t
          set side s
          ifelse
          (s = "bottom")
          [set landing-patch patch mouse-xcor mouse-ycor]
          [set landing-patch one-of (patch-set patch 4 11 patch 16 11)]
          set shape (word t "-unit")
        ]
      ]
    ]
    (t = "Giant")
    [
      hatch-units 1
      [
        set size 5
        set hp 5423
        set dmg 337
        set speed 45
        set atk-speed 1.5
        set fly? false
        set atk-range 1
        set sight-range 7.5
        set shape (word t "-unit")
        set troop t
        set atk-type "melee"
        set side s
      ]
    ]
    (t = "GoblinBarrelGround")
    [
      hatch-units 1
      [
        set size 2
        set hp 267
        set dmg 159
        set speed 120
        set atk-speed 1.1
        set fly? false
        set atk-range .5
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "melee"
        set side s
        set xcor xcor + 1
      ]
      hatch-units 1
      [
        set size 2
        set hp 267
        set dmg 159
        set speed 120
        set atk-speed 1.1
        set fly? false
        set atk-range .5
        set sight-range 5.5
        set shape (word t "-unit")
        set troop troop
        set atk-type "melee"
        set side s
        set xcor xcor - 1
      ]
      hatch-units 1
      [
        set size 2
        set hp 267
        set dmg 159
        set speed 120
        set atk-speed 1.1
        set fly? false
        set atk-range .5
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "melee"
        set side s
        set ycor ycor - 1
      ]
    ]
    (t = "HogRider")
    [
      hatch-units 1
      [
        set size 3.5
        set hp 2248
        set dmg 135
        set speed 120
        set atk-speed 1.6
        set fly? false
        set atk-range .8
        set sight-range 9.5
        set shape (word t "-unit")
        set troop troop
        set atk-type "melee"
        set side s
      ]
    ]
    (t = "Minions")
    [
      hatch-units 1
      [
        set size 2.5
        set hp 305
        set dmg 135
        set speed 90
        set atk-speed 1
        set fly? true
        set atk-range 1.6
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "ranged"
        set side s
        set xcor xcor + 1
      ]
      hatch-units 1
      [
        set size 2.5
        set hp 305
        set dmg 135
        set speed 90
        set atk-speed 1
        set fly? true
        set atk-range 1.6
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "ranged"
        set side s
        set xcor xcor - 1
      ]
      hatch-units 1
      [
        set size 2.5
        set hp 305
        set dmg 135
        set speed 90
        set atk-speed 1
        set fly? true
        set atk-range 1.6
        set sight-range 5.5
        set shape (word t "-unit")
        set troop t
        set atk-type "ranged"
        set side s
        set ycor ycor - 1
      ]
    ]
    (t = "MiniPekka")
    [
      hatch-units 1
      [
        set size 2.5
        set hp 1804
        set dmg 955
        set speed 90
        set atk-speed 1.6
        set fly? false
        set atk-range .5
        set sight-range 5
        set shape (word t "-unit")
        set troop troop
        set atk-type "melee"
        set side s
      ]
    ]
    (t = "SkeletonArmy")
    [
      ask n-of 15 patches in-radius 3 with [count turtles-here = 0]
      [
        sprout-units 1
        [
          set size 1
          set hp 108
          set dmg 108
          set speed 90
          set atk-speed 1
          set fly? false
          set atk-range .5
          set sight-range 5.5
          set shape (word t "-unit")
          set troop t
          set atk-type "melee"
          set side s
          set heading 0
        ]
      ]
    ]
    (t = "GoblinBarrel")
    [
      ask towers with [side = s and pos = (word s "-king")]
        [
          hatch-spells 1
          [
            set size 3
            set speed 1000
            set troop t
            set side s
            ifelse
            (s = "bottom")
            [set landing-patch patch mouse-xcor mouse-ycor]
            [set landing-patch one-of (patch-set patch 4 11 patch 16 11)]
            set shape (word t "-unit")
          ]
      ]
    ]
  )
  ask units
  [
    set color gray
    set dps round (dmg / atk-speed)
  ]
end

to units-move
  ask units
  [
    (
      ifelse
      (targeted-troop = 0 or targeted-troop = nobody)
      [fd speed-constant * speed]
      [
        ifelse
        (distance targeted-troop <= atk-range)
        []
        [fd speed-constant * speed]
      ]
    )
  ]
end

to spells-move
  ask spells
  [
    ifelse
    (distance landing-patch <= .2)
    [spells-attack side]
    [
      face landing-patch
      fd speed-constant * speed
    ]
  ]
end

to units-attack
  every 1
  [
    ask units
    [
      let s side
      let d dps
      (
        ifelse
        (targeted-troop = 0 or targeted-troop = nobody)
        []
        (distance targeted-troop <= atk-range)
        [
          (
            ifelse
            (atk-type = "ranged")
            [
              projectiles-spawn targeted-troop troop d
            ]
            (atk-type = "melee")
            [
              ask targeted-troop
              [
                set hp hp - d
              ]
            ]
          )
        ]
      )
    ]
  ]
end

to projectiles-spawn [ptarget ptype d]
  hatch-projectiles 1
  [
    set targeted-troop ptarget
    set dmg d
    face targeted-troop
    set shape (word ptype "-projectile")
    set speed 1000
  ]
end

to projectiles-move
  ask projectiles
  [
    let d dmg
    (
      ifelse
      (targeted-troop = nobody)
      [die]
      (distance targeted-troop <= .2)
      [
        ask targeted-troop
        [
          set hp hp - d
        ]
        die
      ]
      [
        face targeted-troop
        fd speed-constant * speed
      ]
    )
  ]
end

to spells-attack [s]
  ask spells
  [
    let me self
    (
      ifelse
      (troop = "Arrows")
      [
        ask units with
        [distance me <= 5 and side != s]
        [
          set hp hp - 162
          set hp hp - 162
          set hp hp - 162
        ]
        ask towers with
        [distance me <= 5 and side != s]
        [
          set hp hp - 49
          set hp hp - 49
          set hp hp - 49
        ]
        die
      ]
      (troop = "GoblinBarrel")
      [
        units-spawn "GoblinBarrelGround" side
        die
      ]
    )
  ]
end

to units-die
  ask units
  [
    if (hp <= 0)
    [die]
  ]
end

to towers-attack
  every 1
  [
    ask towers with [pos = "bottom-king" or pos = "top-king"]
    [
      ifelse
      (targeted-troop = 0 or targeted-troop = nobody)
      []
      [projectiles-spawn targeted-troop "tower" dmg]
    ]
  ]
  every .8
  [
    ask towers with [pos = "bottom-left" or pos = "bottom-right" or pos = "top-left" or pos = "top-right"]
    [
      ifelse
      (targeted-troop = 0 or targeted-troop = nobody)
      []
      [projectiles-spawn targeted-troop "tower" dmg]
    ]
  ]
end

to towers-die ;tower attacking and death
  ask towers
  [
    if (hp <= 0) [die]
  ]
end

to target
  ;path
  ask units
  [
    ifelse
    (side = "bottom")
    [
      ifelse
      (ycor <= 19)
      [face max-one-of (patches in-radius 6 with [pycor <= 19]) [bottom-priority]]
      [
        face max-one-of (patches in-radius 6) [bottom-priority]
      ]
    ]
    [
      ifelse
      (ycor >= 21)
      [face max-one-of (patches in-radius 6 with [pycor >= 21]) [top-priority]]
      [
        face max-one-of (patches in-radius 6) [top-priority]
      ]
    ]
  ]


  ;target
  ask units
  [
    ifelse
    (targeted-troop = 0 or targeted-troop = nobody)
    [
      (
        ifelse
        (side = "bottom")
        [
          ifelse
          (atk-type = "melee")
          [
            set targeted-troop min-one-of
            (
              turtle-set
              min-one-of units in-radius sight-range with [side = "top" and fly? = false] [distance self]
              min-one-of towers in-radius sight-range with [side = "top"] [distance self]
            )
            [distance self]
          ]
          [
            set targeted-troop min-one-of
            (
              turtle-set
              min-one-of units in-radius sight-range with [side = "top"] [distance self]
              min-one-of towers in-radius sight-range with [side = "top"] [distance self]
            )
            [distance self]
          ]
        ]

        (side = "top")
        [
          ifelse
          (atk-type = "melee")

          [
            set targeted-troop min-one-of
            (
              turtle-set
              min-one-of units in-radius sight-range with [side = "bottom" and fly? = false] [distance self]
              min-one-of towers in-radius sight-range with [side = "bottom"] [distance self]
            )
            [distance self]
          ]

          [
            set targeted-troop min-one-of
            (
              turtle-set
              min-one-of units in-radius sight-range with [side = "bottom"] [distance self]
              min-one-of towers in-radius sight-range with [side = "bottom"] [distance self]
            )
            [distance self]
          ]
        ]
      )
    ]
    [face targeted-troop]
  ]
end

to towers-target
  ask towers
  [
    if
    (targeted-troop = 0 or targeted-troop = nobody)
    [
      ifelse
      (side = "bottom")
      [set targeted-troop min-one-of units in-radius sight-range with [side = "top"] [distance self]]
      [set targeted-troop min-one-of units in-radius sight-range with [side = "bottom"] [distance self]]
    ]
  ]
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
  ;; paths around towers
  ask patches with [
    ((((pxcor >= 2 and pxcor <= 6) or (pxcor >= 14 and pxcor <= 18)) and
      ((pycor >= 9 and pycor <= 12) or (pycor >= 28 and pycor <= 31))) or
      ((pxcor >= 8 and pxcor <= 12) and ((pycor >= 4 and pycor <= 8) or (pycor >= 32 and pycor <= 36))))
  ]
  [set pcolor 27]

  ;; pathing bottom-priority
  ask patches with [(pxcor = 4 or pxcor = 16) and (pycor >= 13 and pycor <= 27)]
  [set bottom-priority [pycor] of self - 12]
  ask (patch-set patch 4 30 patch 16 30 patch 10 34) [set bottom-priority 17]
  ask patches with [(pxcor = 2 or pxcor = 6 or pxcor = 14 or pxcor = 18) and (pycor >= 9 and pycor <= 12)]
  [set bottom-priority .5]
  ask (patch-set patch 6 34 patch 14 32)
  [set bottom-priority 30]

  ;; pathing top-priority
  ask patches with [(pxcor = 4 or pxcor = 16) and (pycor >= 13 and pycor <= 27)]
  [set top-priority 28 - [pycor] of self]
  ask (patch-set patch 4 11 patch 16 11 patch 16 11)
  [set top-priority 17]
  ask patches with [(pxcor = 2 or pxcor = 6 or pxcor = 14 or pxcor = 18) and (pycor >= 28 and pycor <= 31)]
  [set top-priority .5]
  ask (patch-set patch 6 8 patch 14 8)
  [set top-priority 30]
end

to towers-spawn ;spawns in towers
                ;; at (4,10) (16,10) (10,6) (4,30) (16,30) (10,34)
  create-towers 1 [set pos "bottom-left" set side "bottom" set shape "tower"]
  create-towers 1 [set pos "bottom-right" set side "bottom" set shape "tower"]
  create-towers 1 [set pos "bottom-king" set side "bottom" set shape "king"]
  create-towers 1 [set pos "top-left" set side "top" set shape "tower"]
  create-towers 1 [set pos "top-right" set side "top" set shape "tower"]
  create-towers 1 [set pos "top-king" set side "top" set shape "king"]
  ask towers
  [
    set dmg 144
    set sight-range 7

    ifelse (side = "top")
    [set color red]
    [set color blue]
    ifelse (pos = "top-king" or pos = "bottom-king")
    [set size 4]
    [set size 3]
    (ifelse
      (pos = "bottom-left") [set xcor 4 set ycor 11 face patch 4 20 set hp 5000]
      (pos = "bottom-right") [set xcor 16 set ycor 11 face patch 16 20 set hp 5000]
      (pos = "bottom-king") [set xcor 10 set ycor 6 face patch 10 20 set hp 7500]
      (pos = "top-left") [set xcor 4 set ycor 30 face patch 4 20 set hp 5000]
      (pos = "top-right") [set xcor 16 set ycor 30 face patch 16 20 set hp 5000]
      (pos = "top-king") [set xcor 10 set ycor 34 face patch 10 20 set hp 7500]
    )
  ]
end

;; UI/GAME PROGRESSION
to clock ;counts time elapsed and time left (assuming game time of 3 minutes)
  every 1 [set time-elapsed time-elapsed + 1]
  set time-left (word (floor ((180 - time-elapsed) / 60)) ":" (remainder (180 - time-elapsed) 60))
end

to elixir-update ;updates and counts elixir
  ifelse (elixir <= 10 and not god-mode)
  [
    ifelse (time-elapsed >= 120)
    [every 1.4 [set elixir elixir + 1]]
    [every 2.8 [set elixir elixir + 1]]
  ]
  [set elixir 10]

  ifelse (time-elapsed >= 120)
  [every 1.4 [set top-elixir top-elixir + 1]]
  [every 2.8 [set top-elixir top-elixir + 1]]

  ;; draw elixir count on screen
  ask patches with [pxcor <= (elixir * 2) and pxcor != 0 and pxcor != 20 and odd? pxcor and pycor = 0] [set pcolor magenta]
  ask patches with [pxcor > (elixir * 2) and pxcor != 0 and pxcor != 20 and odd? pxcor and pycor = 0] [set pcolor brown]
end

to crowns-update ;updates and counts crowns for both players
  set top-crowns 3 - (count towers with [side = "bottom"])
  set bottom-crowns 3 - (count towers with [side = "top"])
end

to winloss
  if (time-elapsed >= 180)
  [
    if (bottom-crowns = top-crowns)
    [
      user-message "It was a draw!"
    ]
    if (bottom-crowns > top-crowns)
    [
      user-message (word "You won with " bottom-crowns " crowns, while the enemy had only " top-crowns " crowns!")
    ]
    if (top-crowns > bottom-crowns)
    [
      user-message (word "You lost since you only had " bottom-crowns " crowns, while the enemy had " top-crowns " crowns!")
    ]
  ]
end

to labelhp
  ask towers [set label hp]
  ask units [set label ""]
  ask projectiles [set label ""]
  ask spells [set label ""]
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
1
1
-1000

BUTTON
65
255
131
288
NIL
emote
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?
This NetLogo model is a recreation of the critically acclaimed game, Clash Royale, which has reached worldwide success. In this model we hoped to recreate the idea of taking cards from a deck and using them to place troops on the battlefield, defending against enemy troops and advancing forward in order to destroy enemy structures.

## HOW IT WORKS
Throughout this model we divert our attention to a few vital game mechanics, elixir, card placement and rotation, troop spawning, pathing, and attacking, and game progression. I will now begin to outline what each procedure does.

to setup - This procedure returns the board to its base state and all variables that fluctuate throughout the match (elixir, deck rotation, tower hp, time left) back to its starting value.  
Authors:  Daniel   
Agentsets: Patches, Observer

to go - This procedure continuously calls the main procedures we used to recreate the mechanics outlined before. 
Authors: Daniel, Khin   
Agentsets: Observer, Turtles

to emote - This is a miscellaneous function we coded in for fun. Emotes in the actual game are used to express emotion in an otherwise silent exchange between two players.
This iconic emote is used to taunt your opponent by laughing. 
Authors: Daniel
Agentsets: Observer

to card-setup - This procedure places the cards into the deck located on the bottom row of the screen. 
Authors: Daniel
Agentsets: Turtles

to top-card-spawn [p] - This procedure spawns and gives the first four cards of the enemy deck a position [p] and elixir cost corresponding to the unit of the card. 
Authors: Daniel
Agentsets: Turtles

to top-card-setup - This procedure runs through top-card-spawn for all available positions [1] [2] [3] [4]. 
Authors: Daniel
Agentsets: Turtles

to top-send-troop - This procedure sends an enemy troop given that the drawn card's elixir cost does not exceed how much elixir the enemy currently has.
Authors: Daniel
Agentsets: Turtles

to card-spawn [p] - This procedure behaves in a very similar way to top-card-spawn, except this time it creates a visible turtle in the shape of a card with the corresponding unit. These cards are spawned at the bottom of your screen within one of the 4 positions [p] within the row, representing your deck.
Authors: Khin Daniel
Agentsets: Turtles

to card-drag - This procedure allows for player interaction with the spawned cards. While the card is in the “waiting” state and no other cards are in the “dragging” state the card will move into the “dragging” state upon mouse-down?. While in the dragging state and your mouse is still held down the card will initiate the drag procedure. If the mouse has been released while the card is in the dragging state the release-valid procedure will initiate if the card is in a valid position, while release-invalid will initiate if the card is in an invalid position.
Authors: Khin Daniel
Agentsets: Turtles

to release-valid - This procedure is triggered upon a valid release of a card from the deck. It will spawn the corresponding unit for the card, subtract its respective elixir cost, and insert the card into the last position of the deck, setting the troop of the next card as top card in deck.
Authors: Khin Daniel
Agentsets: Turtles

to release-invalid - This procedure is triggered upon an invalid release of a card from the deck. The card will return back to its original position in the deck.
Authors: Daniel
Agentsets: Turtles

to drag - This procedure occurs while the card is in the “dragging” state. The card will set its coordinates to the mouse-xcor and mouse-ycor, effectively following it. If the card is still within the deck then it will show the card, if it is in an invalid position on the map or the elixir cost has not been met it will show an “x” symbol, if it is in a valid position on the map and that elixir cost has been met then it will show the unit that will be spawned and be watched (highlighted).
Authors: Khin
Agentsets: Turtles

to select - This procedure simply sets the card’s drag-state to “dragging” in order to initiate the drag procedure.
Authors: Khin
Agentsets: Turtles

to get-card-pos - This procedure assigns the current-pos variable of the card with the card’s general position on the map. If it is on the deck then it will be set to “deck”, if it is on the bottom side of the map then it will be set to “on-map”, if it is on the top side of the map, the bridge, or water then it will be set to “invalid”.
Authors: Daniel
Agentsets: Turtles

to units-spawn [t s]  - This procedure will hatch (spawn) a unit corresponding to the [t] value given and assign it a side [s]. For each unit there are different values that affect its behavior: size, hp, speed, atk-speed, fly?, atk-range, sight-range, atk-type. These different variables allow for the variety in troops that contribute to the strategy required in this game.
Authors: Daniel
Agentsets: Turtles

to units-move - This procedure asks units to keep moving forward relative to their respective speed, they will move towards enemies instead if the enemies are within their attack range.
Authors: Daniel Khin
Agentsets: Turtles

to spells-move - This procedure asks spells to move towards their landing-patch then initiate the spell-attack procedure to deal damage.
Authors: Daniel Khin
Agentsets: Turtles

to units-attack - This procedure asks units to attack the targeted-troop as long as it is within the atk-range of the unit. If the unit is a ranged troop then it will spawn projectiles at its enemy using the projectile-spawn function. If the unit is a melee troop then it will subtract the hp of its enemy based on the dps assigned to the unit.
Authors: Daniel Khin
Agentsets: Turtles

to projectiles-spawn [ ptarget ptype d ] - This procedure hatches projectiles and sets their targeted-troop [ptarget], their damage [d], and projectile type for the corresponding unit [ptype]. The projectile will face the targeted troop and have a speed of 1000.
Authors: Daniel Khin
Agentsets: Turtles

to projectiles-move - This procedure asks projectiles to face and move towards their targeted troop at the assigned speed, subtracted the projectile’s damage from the troop’s hp, then die (disappear).
Authors: Khin
Agentsets: Turtles


to spells-attack - This procedure allows spells to deal damage. If the spell is “Arrows” then it will ask troops within 5 patches and of the opposite side (team) to subtract 162 hp, it will also ask towers within 5 patches and of the opposite side to subtract 49 hp. After doing so the spell will die. If the spell is “GoblinBarrel” it will trigger unit spawn to spawn goblin units that will aid you in battle (same team / side as you).
Authors: Daniel
Agentsets: Turtles

to units-die - This procedure asks units with hp at or below zero to die.
Authors: Daniel
Agentsets: Turtles

to towers-attack - This procedure asks king towers to send projectiles toward targeted enemies every second, and asks the side towers to send projectiles toward targeted enemies every 0.8 second.
Authors: Daniel Khin
Agentsets: Turtles

to towers-die - This procedure asks towers with hp at or below zero to die.
Authors: Daniel
Agentsets: Turtles

to target - This procedure handles the path towers will take, whether that be towards enemy towers or units. Targeting of towers takes precedence over targeting of enemies, but it all depends on what the unit sees first. For targeting of enemies, melee units will target a random unit (min-one-of) within its sight range, on the opposite side (team), and not flying. Flying melee and ranged units will do the same, except they are able to target flying units. All unit types will target the closest tower within its sight range that's on the opposite side. 
Authors: Khin
Agentsets: Turtles

to towers-target - This procedure handles what enemies the tower will target, the tower functions similarly to the regular target procedure, in that it will target a random unit within range of the tower and on the opposite side / team.
Authors: Khin
Agentsets: Turtles

to board - This procedure creates the appearance of the playing field and assigns patches on the top and bottom half the board a priority. Elaborate on priority
Authors: Daniel
Agentsets: Turtles

to towers-spawn - This procedure spawns the towers, assigning them their corresponding side and position, as well as giving them a sight-range, hp, and damage.
Authors: Daniel
Agentsets: Turtles

to clock - This procedure keeps track of the time left in the match, which outputs in a “min : seconds” format.
Authors: Daniel
Agentsets: Turtles

to elixir-update - This procedure updates the elixir count for the player. As long as the elixir is not already at max (10) and god-mode (infinite elixir) is not turned on, then the player will gain one elixir every 2.8 seconds. Once the time goes past 2 minutes the elixir rate will double and the player will gain one elixir every 1.4 seconds. The same thing applies to the enemy’s elixir, with the exception that the enemy does not have a god-mode (this would break the game!). The procedure also draws purple squares at the bottom of the screen, with each square representing one elixir.
Authors: Daniel
Agentsets: Turtles

to crowns-update - This procedure keeps track of how many crowns are left on both sides, based on how many towers still exist for that side.
Authors: Daniel
Agentsets: Turtles

to winloss - This procedure stops the game and sends a pop-up message once the time elapsed in the match has exceeded 3 minutes. The pop-up message corresponds with whether or not the user has lost, won, or reached a draw. Ex: Loss -> "You won with " bottom-crowns " crowns, while the enemy had only " top-crowns " crowns!".
Authors: Daniel
Agentsets: Turtles

to labelhp - This procedure displays the hp of the towers on the world itself (alleviating the need to look at a monitor), by setting the label of the towers as their hp variable.
Authors: Daniel Khin
Agentsets: Turtles

to report even? [n] - This procedure returns whether or not the input number is even.
Authors: Khin
Agentsets: Turtles

to report odd? [n] - This procedure returns whether or not the input number is odd.
Authors: Khin
Agentsets: Turtles



## HOW TO USE IT

Press the setup button to set up the game board.
The go button will start the game, allowing you to drag cards and play the game.
The various monitors around the screen display information about the game, such as your next card, elixir, crowns, and time left.
Press the emote button, or J on your keyboard to emote and humiliate the enemy.
Turning on the god-mode switch gives you infinite elixir to play with.

## THINGS TO NOTICE

The elixir bar in the bottom of the screen is dynamic and updates with the current elixir count for you. Notice how the troops path towards the bridge first, and then towards the enemy tower.

## THINGS TO TRY

If you can’t win, try turning on the god-mode switch to give you unlimited elixir, which makes the game much easier.

## EXTENDING THE MODEL

Try to add a proper win loss screen (not a popup message) with a visual display of how many crowns were obtained by each side, and showing who won!

## NETLOGO FEATURES

In the absence of a proper Finite State Machine in NetLogo, we leveraged the power of a global variable and a per-tick check to see which state cards were in. Although we only used 2 main states, it is easily expandable and flexible.

## RELATED MODELS

The Slime Mold model we completed in class was the inspiration for the pathing system, using a “pheromone”-like, invisible substance on the board to lure the units in a certain direction.

## CREDITS AND REFERENCES

The model can be found at https://github.com/pyshrekek/ClashRoyaleNetLogo, along with a README containing more information about the model and units.

By Khin Aung and Haokun (Daniel) Xu, Period 7
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

archers-projectile
true
0
Polygon -2674135 true false 165 210 135 210 135 255 150 240 165 255 165 225
Rectangle -6459832 true false 142 105 157 210
Polygon -1 true false 150 114 126 115 151 82 173 116

archers-unit
true
0
Rectangle -13791810 true false 105 225 195 300
Circle -1184463 true false 75 90 150
Polygon -5825686 true false 75 120 90 90 195 90 210 90 225 135 225 195 210 150 150 150 135 150 90 150 90 195 75 195 75 135
Polygon -6459832 true false 146 74 131 104 131 149 176 254 206 299 161 284 146 239 131 194 116 119 146 74
Line -1 false 132 91 191 286

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

arrows-unit
true
0
Rectangle -6459832 true false 75 120 90 195
Rectangle -6459832 true false 128 91 143 167
Rectangle -6459832 true false 184 76 198 149
Rectangle -6459832 true false 222 125 237 205
Polygon -1 true false 99 185 65 186 85 216
Polygon -1 true false 244 193 210 194 230 224
Polygon -1 true false 205 142 171 143 191 173
Polygon -1 true false 149 156 115 157 135 187
Polygon -2674135 true false 82 140 56 102 81 117 102 95
Polygon -2674135 true false 229 147 203 109 228 124 249 102
Polygon -2674135 true false 191 99 165 61 190 76 211 54
Polygon -2674135 true false 136 117 110 79 135 94 156 72

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

crown
true
0
Polygon -1184463 true false 75 120 90 180 210 180 225 120 195 150 150 105 105 150
Rectangle -7500403 true true 90 180 210 195
Circle -2674135 true false 135 135 30

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

goblinbarrel-unit
true
0
Polygon -6459832 true false 120 31 210 46 240 121 225 226 180 271 90 256 60 181 90 76
Line -16777216 false 92 74 236 115
Line -16777216 false 63 179 225 224
Polygon -10899396 true false 147 122 120 113 110 147 146 187 181 167 195 134
Circle -1184463 true false 124 124 17
Circle -1184463 true false 154 131 17

goblinbarrelground-unit
true
0
Polygon -13840069 true false 106 63 161 58 189 131 163 159 112 159 93 139
Polygon -13840069 true false 107 145 87 202 109 267 196 260 201 193 163 138
Polygon -6459832 true false 119 169 117 246 179 235 169 164
Polygon -10899396 true false 119 262 117 290 133 290 133 258
Polygon -10899396 true false 164 256 166 282 183 282 180 255
Polygon -10899396 true false 188 189 222 176 219 131 240 130 236 190 191 206
Polygon -10899396 true false 103 194 69 181 72 136 51 135 55 195 100 211
Polygon -14835848 true false 168 83 208 66 231 77 212 86 188 85 164 98
Polygon -14835848 true false 109 82 69 65 46 76 65 85 89 84 113 97

hehehehaw
false
0
Polygon -955883 true false 80 66 185 51 237 149 156 243 23 176
Polygon -16777216 true false 149 109 185 94 206 112 179 106
Polygon -16777216 true false 128 114 92 99 71 117 98 111
Polygon -8630108 true false 72 153 201 142 146 214
Polygon -1 true false 91 153 138 170 180 145
Polygon -1 true false 102 183 143 188 174 173 144 211
Line -16777216 false 118 164 116 151
Line -16777216 false 140 167 137 149
Line -16777216 false 157 158 154 148
Line -16777216 false 122 184 122 198
Line -16777216 false 135 185 138 211
Line -16777216 false 154 183 160 192
Polygon -16777216 true false 63 155 141 219 202 145 234 150 152 256 20 185 22 147
Polygon -16777216 true false 35 122 73 134 198 125 234 118 219 145 57 151
Polygon -5825686 true false 137 103 135 124 122 137 153 134 143 121 145 103
Polygon -1184463 true false 125 51 93 50 87 25 101 15 111 37 126 38 131 5 151 7 150 35 166 36 189 22 202 32 169 52

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

minions-projectile
true
0
Circle -7500403 true true 135 135 30
Circle -16777216 true false 137 137 26

minions-unit
true
0
Polygon -13345367 true false 150 240 150 285 180 285 165 240
Polygon -13345367 true false 105 240 90 285 120 285 120 225
Polygon -13345367 true false 154 166 218 118 229 180 208 163 204 196 187 181 178 216 154 182
Polygon -13345367 true false 103 170 39 122 28 184 49 167 53 200 70 185 79 220 103 186
Polygon -13791810 true false 109 127 72 171 84 244 175 257 193 177 151 126
Polygon -13791810 true false 111 140 79 102 123 54 164 58 183 105 147 142

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

tower-projectile
true
0
Rectangle -6459832 true false 147 106 154 212
Polygon -1 true false 150 114 135 124 149 44 165 120
Polygon -2674135 true false 151 207 138 199 133 263 147 232 164 263 163 193

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
