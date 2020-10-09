extensions [vid]
breed [as a]
breed [bs b]
undirected-link-breed [temps temp]
undirected-link-breed [perms perm]

;;

globals[
  a-count b-count
  num-ids viable-patches output_folder filecounter original-spheroid-radius final-spheroid-radius spheroid-radius-inc
  a-count-final b-count-final c-color-count d-color-count c-express-count d-express-count
  total-boundary red-boundary
  cell-move-count-GFP
  cell-move-count-mCherry
  date
  outputFilename
]
as-own[
  d-status
  r-color
  d-express-time
  id
  cluster-pause
  boundary
]
bs-own[
  c-status
  g-color
  c-express-time
  id
  cluster-pause
  boundary
]
to setup
  clear-all
  vid:reset-recorder

;store starting radius of spheroid
  set original-spheroid-radius spheroid-radius

  ask patch 0 0[
;designate area for spheroid/calculate max num of cells that can occupy this space
    set viable-patches patches in-radius spheroid-radius
    let num-cells count patches in-radius spheroid-radius
;scale down max number of cells by the percent saturation of the spheroid
    set a-count ((num-cells / (a-ratio + b-ratio)) * a-ratio) * percent-saturation
    set b-count ((num-cells / (a-ratio + b-ratio)) * b-ratio) * percent-saturation

;determine what radius of spheroid would be at 100% saturation
    let final-spheroid-area a-count + b-count
    set final-spheroid-radius sqrt (final-spheroid-area / pi)
    let spheroid-radius-difference spheroid-radius - final-spheroid-radius
    set spheroid-radius-inc spheroid-radius-difference / 4
;  ]
;    let x-in 0 let y-in 0 let h-in 0
;    let file1 "initial_xyh_a.txt"
;    file-open file1
;    while [not file-at-end?]
;    [
;      set x-in file-read
;      set y-in file-read
;      set h-in file-read
;      create-as 1[
;        set shape "circle"
;        set color blue
;        set size 1
;        set xcor x-in
;        set ycor y-in
;        set heading h-in
;
;        set d-status false
;        set r-color false
;        set d-express-time 0
;        set id num-ids
;        set num-ids num-ids + 1
;        set cluster-pause 0
;      ]
;    ]
;    file-close-all
;    let file2 "initial_xyh_b.txt"
;    file-open file2
;    while [not file-at-end?]
;    [
;      set x-in file-read
;      set y-in file-read
;      set h-in file-read
;      create-bs 1[
;        set shape "circle"
;        set color gray
;        set size 1
;        set xcor x-in
;        set ycor y-in
;        set heading h-in
;
;        set c-status false
;        set g-color false
;        set c-express-time 0
;        set id num-ids
;        set num-ids num-ids + 1
;        set cluster-pause 0
;      ]
;    ]

;initialize A-type and B-type cells in random locations of the spheroid
    let spheroid-area-a  a-count
    let spheroid-radius-a sqrt (spheroid-area-a / pi)

    let spheroid-area-b  b-count
    let spheroid-radius-b sqrt (spheroid-area-b / pi)
    print(spheroid-radius-b)
        ask n-of (a-count) patches in-radius spheroid-radius with [count turtles-here = 0][
      sprout-as 1[
        set shape "circle"
        set color blue
        set size 1

        set d-status false
        set r-color false
        set d-express-time 0
        set id num-ids
        set num-ids num-ids + 1
        set cluster-pause 0
        set boundary 0
      ]
    ]

    ask n-of (b-count) patches in-radius (spheroid-radius) with [count turtles-here = 0][
      sprout-bs 1[
        set shape "circle"
        set color gray
        set size 1

        set c-status false
        set g-color false
        set c-express-time 0
        set id num-ids
        set num-ids num-ids + 1
        set cluster-pause 0
        set boundary 0
      ]
    ]
  ]
  set cell-move-count-GFP 0
  set cell-move-count-mCherry 0
  setOutputFile
  reset-ticks
end

to go
;  ask patch 0 0 [set viable-patches patches in-radius spheroid-radius]
;update location space of spheroid
 if ticks < 100 and ticks mod 25 = 0 [set spheroid-radius spheroid-radius - spheroid-radius-inc ask patch 0 0 [set viable-patches patches in-radius spheroid-radius]]
;break links based on chance + whether cells are still within contact of each other
  ask turtles [update-links]
;  let move-chance random 100

;find number of clusters in spheroid and iteratively move each cluster
  ask bs [cluster-c] ask as [cluster-d]
  ;ask turtles [set label id]
  let cluster-list (range 0 (num-ids + 1))
  ;foreach cluster-list [ask bs [cluster-c] ask as [cluster-d]]
  foreach cluster-list move-cluster

  ask turtles [set id num-ids set num-ids num-ids + 1]

  ask bs with [count in-link-neighbors = 0][
;    if move-chance < 70[
      move-cen
;      ifelse c-status = true [move-cen][move]
;      move
      if ticks > c-express-delay [if g-color = false [express-c]]
      if g-color[set c-express-time c-express-time + 1]
      if c-express-time > c-express-thresh [set c-status true]
      ;if id = -1 [id-self]
;      cluster-c
;    ]
  ]
  ask as with [count in-link-neighbors = 0 ][
;    if move-chance < 70[
      move-cen
      if ticks > (d-express-delay) [if r-color = false [express-d]]
      if r-color[set d-express-time d-express-time + 1]
      if d-express-time > d-express-thresh [set d-status true]
      ;if id = -1 [id-self]
;      cluster-d
;    ]
  ]

  ask bs with [c-status = true and count in-link-neighbors > 0] [if random 100 <  homotypic-prob-c [probe-surroundings]]
  ask as with [d-status = true and count in-link-neighbors > 0] [if random 100 <  homotypic-prob-d [probe-surroundings]]
  ask as with [d-status = true] [if random 100 < heterotypic-prob [probe-surroundings-hetero]]
;  if ticks > 80 [ask bs with [c-status = true] [if random 100 < homotypic-prob-c [probe-surroundings]]]
;  if ticks > 80 [ask as with [d-status = true] [if random 100 < homotypic-prob-d [probe-surroundings]]]
  normalize-ids
;  ask turtles [set label id]

  ask turtles [if ticks mod cluster-pause-delay = 0 [set cluster-pause 0]]
  set num-ids 0
  ;ask turtles with [count my-links > 0] [set color pink]
;  outputCellMovement
  set cell-move-count-GFP 0
  set cell-move-count-mCherry 0
  tick
end

to move
  let empty-spots neighbors with [count turtles-here = 0]
  let viable-empty-spots viable-patches with [member? self empty-spots]
  if any? viable-empty-spots [
    move-to one-of viable-empty-spots
    if breed = as [ if r-color = true [set cell-move-count-mCherry cell-move-count-mCherry + 1]]
    if breed = bs [ if g-color = true [set cell-move-count-GFP cell-move-count-GFP + 1]]
  ]
;   if id = -1 [id-self]
end

to move-cen
  let empty-spots neighbors with [count turtles-here = 0]
  let viable-empty-spots viable-patches with [member? self empty-spots]
  if any? viable-empty-spots [
    let target min-one-of viable-empty-spots [distancexy 0 0]
    move-to target
    if breed = as [ if r-color = true [set cell-move-count-mCherry cell-move-count-mCherry + 1]]
    if breed = bs [ if g-color = true [set cell-move-count-GFP cell-move-count-GFP + 1]]
  ]
;  if id = -1 [id-self]
end

to move-cluster [x]
  let cluster turtles with [id = x]
  let cluster-patches patch-set [patch-here] of cluster
  ;print cluster-patches
  ;ask cluster [set color orange]
  if count cluster < cluster-move-size and count cluster > 1[
    ;ask cluster [set color orange]
    let actor min-one-of cluster [distancexy 0 0]
    ask actor [
      ;move-cen
      ;set color pink
      ifelse distancexy 0 0 <= spheroid-radius / 3 [fd 0][move-cen]
      if breed = as [ if r-color = true [set cell-move-count-mCherry cell-move-count-mCherry + 1]]
      if breed = bs [ if g-color = true [set cell-move-count-GFP cell-move-count-GFP + 1]]
    ]
   ask cluster[
   let others other turtles-here
   if any? others[
    ask links[untie]
    ask others[
      let empty-spots cluster-patches with [count turtles-here = 0]
      if any? empty-spots [
        let target min-one-of empty-spots [distance self]
        move-to target
      ]
    ]
    ask links[tie]
    ]
  ]
  ]
end

to express-c
  let n random 100
  let c count as with [r-color = false] in-radius 1
  if n < (1 - exp (-1 * exp-expression-const-c * c / 8)) * 100[
    set color green
    set g-color true
  ]
;  if(c = 1)[
;    if n < express-prob-1[
;      set color green
;      set g-color true
;    ]
;  ]
;  if(c = 2)[
;    if n < express-prob-2[
;      set color green
;      set g-color true
;    ]
;  ]
;  if(c = 3)[
;    if n < express-prob-3[
;      set color green
;      set g-color true
;    ]
;  ]
;  if(c > 3 AND c < 6)[
;    if n < express-prob-3-6[
;      set color green
;      set g-color true
;    ]
;  ]
;  if(c > 6)[
;    if n < express-prob-max[
;      set color green
;      set g-color true
;    ]
;  ]
end

to express-d
  let n random 100
  let c count bs with [g-color = true] in-radius 1
  if n < (1 - exp (-1 * exp-expression-const-d * c / 8)) * 100[
    set color red
    set r-color true
  ]
;  if(c = 1)[
;    if n < express-prob-1[
;      set color red
;      set r-color true
;    ]
;  ]
;  if(c = 2)[
;    if n < express-prob-2[
;      set color red
;      set r-color true
;    ]
;  ]
;  if(c = 3)[
;    if n < express-prob-3[
;      set color red
;      set r-color true
;    ]
;  ]
;  if(c > 3 AND c < 6)[
;    if n < express-prob-3-6[
;      set color red
;      set r-color true
;    ]
;  ]
;  if(c > 6)[
;    if n < express-prob-max[
;      set color red
;      set r-color true
;    ]
;  ]
end

to cluster-c
  if c-status = true and cluster-pause = 0[
    let x turtles-on neighbors4
    set x x with [breed = bs] with [c-status = true]

    let y turtles-on neighbors4
    set y y with [breed = as] with [d-status = true]
  ifelse any? x[
      if random 100 < homotypic-prob-c [
      create-perms-with x
      id-linkers [id] of self x
      ]
  ]
    [set id -1]
;  if any? y[
;    if count in-link-neighbors = 0 [id-self ]
;    create-temps-with y
;    id-linkers [id] of self y
;  ]
  ;if count in-link-neighbors = 0 [id-self ]
;  if any? linkers[
;    if count in-link-neighbors = 0 [id-self ]
;    create-links-with linkers
;    id-linkers [id] of self linkers
    ;
    ask perms [tie]
    ask temps [tie]
    ;set label id
]
end

to cluster-d
  if d-status = true and cluster-pause = 0[
    let x turtles-on neighbors4
    set x x with [breed = bs] with [c-status = true]

    let y turtles-on neighbors4
    set y y with [breed = as] with [d-status = true]

    ;if count in-link-neighbors = 0 [id-self ]
    ifelse any? y[
      if random 100 < homotypic-prob-d[
        create-perms-with y
        id-linkers [id] of self y
      ]
    ]
    [set id -1]
;
    ifelse any? x[
      if random 100 < heterotypic-prob[
        create-perms-with x
        id-linkers [id] of self x
      ]
    ]
    [set id -1]
;    ifelse any? x[
;      create-temps-with x
;      id-myself [id] of one-of x
;    ]
;    [set id -1]
    ask perms [tie]
    ask temps [tie]
    ;set label id
    ;if not any? x and not any? y [set id -1]
  ]
end

to update-links
  let chance random 100
  ask turtles with [distancexy 0 0 > spheroid-radius * 2 / 3]
  [
    if count my-links > 0[
      let n1 count my-perms
      let n2 count my-temps
      ifelse ticks < 50
      [
        if random 100 < 90 [ask n-of (n1 / 2) my-perms [die] set cluster-pause 1]
      ]
      [
        if random 100 < 70 [ask n-of (n1 / 4) my-perms [die] set cluster-pause 1]
        if random 100 < 70 [ask n-of (n2 / 2) my-temps [die] set cluster-pause 1]
      ]
    ]
  ]
;
  ask turtles with [distancexy 0 0 > spheroid-radius * 1 / 3 and distancexy 0 0 < spheroid-radius * 2 / 3]
  [
    if count my-links > 0[
      let n1 count my-perms
      let n2 count my-temps
      ifelse ticks < 50
      [
        if random 100 < 70 [ask n-of (n1 / 2) my-perms [die] set cluster-pause 1]
      ]
      [
        if random 100 < 50 [ask n-of (n1 / 4) my-perms [die] set cluster-pause 1]
        if random 100 < 50 [ask n-of (n2 / 2) my-temps [die] set cluster-pause 1]
      ]
    ]
  ]
  ask turtles with [distancexy 0 0 < spheroid-radius * 1 / 3 ]
  [
    if count my-links > 0[
      let n1 count my-perms
      let n2 count my-temps
      ifelse ticks < 50
      [
        if random 100 < 30 [ask n-of (n1 / 2) my-perms [die] set cluster-pause 1]
      ]
      [
        if random 100 < 20 [ask n-of (n1 / 4) my-perms [die] set cluster-pause 1]
        if random 100 < 20 [ask n-of (n2 / 4) my-temps [die] set cluster-pause 1]
      ]
    ]
  ]

  if count in-link-neighbors = 0 [set id -1]

;  let n1 count perms
;  let n2 count perms with [link-length = sqrt(2)]
;  print n2
;  ;let n2 count temps
;  if any? perms [ifelse ticks < 40 [if chance < 70 [ask n-of (n1 / 2) perms [untie die]]] [if chance < 50 [ask n-of (n1 / 2) perms [untie die]]]]
;  ;if any? temps [ifelse ticks < 70 [if chance < 90 [ask one-of temps [untie die]]] [if chance < 70 [ask one-of temps [untie die]]]]

  let x in-link-neighbors
  let y turtles-on neighbors4
  let exterminate x with [not member? self y]
  ask exterminate [ask link-with myself [die]]
  if count in-link-neighbors = 0 [set id -1]
end

to probe-surroundings
  if distancexy 0 0 > 10 [stop]
  if xcor = 0 and ycor > 0 [foreach[135 180 225] squeeze-out]
  if xcor = 0 and ycor < 0 [foreach[335 0 45] squeeze-out]

  if ycor = 0 and xcor < 0 [foreach[45 90 135] squeeze-out]
  if ycor = 0 and xcor > 0 [foreach[225 270 335] squeeze-out]

  if xcor < 0 and ycor > 0 [foreach[90 135 180] squeeze-out]
  if xcor < 0 and ycor < 0 [foreach[0 45 90] squeeze-out]
  if xcor > 0 and ycor > 0 [foreach[180 225 270] squeeze-out]
  if xcor > 0 and ycor < 0 [foreach[270 335 360] squeeze-out]
;  foreach [0 45 90 135 180 225 270 335] squeeze-out
end

to squeeze-out [h]
  let x turtles-on patch-at-heading-and-distance h 2
  ;ask x[set color pink]
  let y turtles-on patch-at-heading-and-distance h 1
  ;ask y[set color orange]
  if any? x and any? y [
    set x one-of x
    set y one-of y
    if ([breed] of self = [breed] of x) and ([breed] of x != [breed] of y) [switch-spots self y]
  ]
end

to probe-surroundings-hetero
  if distancexy 0 0 > 10 [stop]
;  foreach [0 45 90 135 180 225 270 335] squeeze-out-hetero
  if xcor = 0 and ycor > 0 [foreach[135 180 225] squeeze-out-hetero]
  if xcor = 0 and ycor < 0 [foreach[335 0 45] squeeze-out-hetero]

  if ycor = 0 and xcor < 0 [foreach[45 90 135] squeeze-out-hetero]
  if ycor = 0 and xcor > 0 [foreach[225 270 335] squeeze-out-hetero]

  if xcor <= 0 and ycor >= 0 [foreach[90 135 180] squeeze-out-hetero]
  if xcor <= 0 and ycor <= 0 [foreach[0 45 90] squeeze-out-hetero]
  if xcor >= 0 and ycor >= 0 [foreach[180 225 270] squeeze-out-hetero]
  if xcor >= 0 and ycor <= 0 [foreach[270 335 360] squeeze-out-hetero]

end

to squeeze-out-hetero [h]
  let x turtles-on patch-at-heading-and-distance h 2
  ;ask x[set color pink]
  let y turtles-on patch-at-heading-and-distance h 1
  ;ask y[set color orange]
  if any? x and any? y [
    set x one-of x
    set y one-of y
    if ([breed] of x = bs) and ([breed] of y = bs) [if [c-status] of x = true and [c-status] of y = false  [switch-spots self y]]
    if ([breed] of x = bs) and ([breed] of y != bs) [if [c-status] of x = true and [d-status] of y = false  [switch-spots self y]]
  ]
end

to outline-boundary
  find-boundary
  let start one-of turtles with [boundary = 1]
  let x [xcor] of start
  let y [ycor] of start
  let pivot 0
  let prev 0
  ask start [set pivot max-one-of bs-on neighbors [distancexy 0 0]]
  set prev start
  while[ [patch-here] of pivot != [patch-here] of start][
    print "im here"
    ask pivot[
      set boundary 1
      set color orange
      let check-area 0
      ask [patch-here] of prev [set check-area other [neighbors4] of pivot]
      ask check-area[set pcolor white]
      let r 0
;      let check-area neighbors4 with [not member? self [patch-here] of prev]
      set r bs-on check-area
      ask r [probe-surroundings-boundary-inner]
      set r one-of r with [boundary = 1 and patch-here != [patch-here] of prev]
;      ;let new one-of r with [boundary = 1 and patch-here != [patch-here] of prev]
      if r != nobody [
        ask r [set color white]
        set prev pivot
        set pivot r
      ]
    ]
  ]
end

;to trace-boundary [pivot]
;  ask pivot[
;      set boundary 1
;      set color orange
;      let check-area 0
;      ask [patch-here] of prev [set check-area other [neighbors4] of pivot]
;      ask check-area[set pcolor white]
;      let r 0
;;      let check-area neighbors4 with [not member? self [patch-here] of prev]
;      set r max-one-of bs-on check-area [distancexy 0 0]
;;      ;if [patch-here] of r != [patch
;;      ;ask r [probe-surroundings-boundary-inner]
;;      ;let new one-of r with [boundary = 1 and patch-here != [patch-here] of prev]
;      if r != nobody [
;        ask r [set color white]
;        set prev pivot
;        set pivot r
;      ]
;    ]
;end

to probe-surroundings-boundary-inner
  foreach [0 90] count-contiguous-inner
end
to probe-surroundings-boundary-outter
  if count (turtles-on neighbors) with [boundary = 1] > 0 [set color pink set red-boundary red-boundary + 1]
  ;foreach [0 45 90 135] count-contiguous-outter
end

to find-boundary
  let start one-of bs with [c-status = true and distancexy 0 0 < 2]
  while [count turtles with [boundary = 1] = 0] [
    ask start [
      ifelse [breed] of max-one-of turtles-on neighbors [distancexy 0 0] != as[
        set color pink
        set start max-one-of turtles-on neighbors [distancexy 0 0]
      ]
      [
        set color orange
        set boundary 1
      ]
    ]
  ]
end

to count-contiguous-inner[h]
  if boundary != 1[
  let x turtles-on patch-at-heading-and-distance h 1
  ;ask x[set color pink]
  let y turtles-on patch-at-heading-and-distance (h + 180) 1
  ;ask y[set color orange]
  if not any? x and any? y [
    let x_1 one-of y
    if ([breed] of self = [breed] of x_1)[
        set total-boundary total-boundary + 1
        set boundary 1
        set color orange
        stop
    ]
  ]
  if any? x and not any? y [
    let x_1 one-of x
    if ([breed] of self = [breed] of x_1)[
        set total-boundary total-boundary + 1
        set boundary 1
        set color orange
        stop
    ]
  ]
  if any? x and any? y [
    set x one-of x
    set y one-of y
    if ([breed] of self = [breed] of x) and ([breed] of self != [breed] of y)
    [
      set color orange
      set total-boundary total-boundary + 1
      set boundary 1
      stop
    ]
    if ([breed] of self != [breed] of x) and ([breed] of self = [breed] of y)
    [
      set color orange
      set total-boundary total-boundary + 1
      set boundary 1
      stop
    ]
  ]
  ]
end

to switch-spots [x y]
  ask links[untie]
  let patch1 [patch-here] of x
  let patch2 [patch-here] of y
  ask x [move-to patch2]
  ask y [move-to patch1]
  ask links[tie]
end

to id-self
  set num-ids num-ids + 1
  set id num-ids
end

to id-myself [x]
  set id x
end

to id-linkers [x linkers]
  ask linkers[
    set id x
    let n in-link-neighbors
    if any? n[set id x]
  ]
end

to normalize-ids
  ask turtles[
    let x [id] of self
    let y in-link-neighbors
    let z 0
    if any? y [
      ask y[
        set id x
        ask in-link-neighbors [set id x]
      ]
    ]
  ]
end

to setOutputFile
  set fileCounter 0
  set date date-and-time
  repeat 16 [set date remove-item 0 date]

  set output_folder (word "Output_3.1/Core_Pole_Ratio_Comparison/"a-ratio"A|"b-ratio"B_SphRad-"original-spheroid-radius"/")

;  set output_folder (word "Output_3.1/DynamicCellSignalingEffect/WithSignaling/")

  while [file-exists? (word output_folder"run_"fileCounter".txt")][set fileCounter fileCounter + 1]
  set outputFilename (word output_folder"run_"fileCounter".txt")
  file-close-all
  file-open outputFilename
end

to outputCellMovement
  file-close-all
  file-open outputFilename
  file-write (word "cell-movement-GFP")
  file-write cell-move-count-GFP
  file-write (word "cell-movement-mCherry")
  file-write cell-move-count-mCherry
  file-print ""
  let num-empty-spots 0
  ask patch 0 0[
    let empty-spots patches in-radius spheroid-radius with [count turtles-here = 0]
    set num-empty-spots count empty-spots
  ]

  file-write (word "num-empty-spots")
  file-write num-empty-spots

  file-write (word "total-GFP")
  file-write count turtles with [color = green]

  file-write (word "total-mCherry")
  file-write count turtles with [color = red]
  file-print ""
end

to makeOutputFile
  let check false
  ask turtles [if distancexy 0 0 > original-spheroid-radius [if check = false [set check true]]]
  ifelse check = false [
;  set fileCounter 0
;  let date date-and-time
;  repeat 16 [set date remove-item 0 date]
;
;  set output_folder (word "output_2.6/RatioFeatureClassification_Final_2/"a-ratio"A|"
;    b-ratio"B_SphRad-"original-spheroid-radius"/")
;
;s

  file-close-all
  file-open outputFilename
  outputXYH
  outputCellMovement
  file-close
  ]
  []
end

to outputImages
  set output_folder (word "output_2.6/RuleKnockdowns/Cluster-Var-BreakLinks/")
  while [file-exists? (word output_folder"/run_"fileCounter".png")][set fileCounter fileCounter + 1]
  let outputImageName (word output_folder"/run_"fileCounter".png")
  export-view outputImageName
end

to outputXYH
;let outputFileXYHA (word "output_2.6/initial_xyh_a.txt")
; file-open outputFileXYHA
  ask as[
    file-write color
    file-write xcor
    file-write ycor
    file-write heading
    file-print ""
  ]

;  let outputFileXYHB (word "output_2.6/initial_xyh_b.txt")
;  file-open outputFileXYHB
  ask bs[
    file-write color
    file-write xcor
    file-write ycor
    file-write heading
    file-print ""
  ]
end

to outputCellCounts
  let x as with [d-status = false]
  let y bs with [c-status = false]
  let g bs with [g-color = true]
  let z bs with [c-status = true]
  let r as with [r-color = true]
  let w as with [d-status = true]

  set a-count-final count x
  set b-count-final count y
  set c-color-count count g
  set d-color-count count r
  set c-express-count count z
  set d-express-count count w

  ;output cell-counts
  file-write (word "a-count")
  file-write a-count-final
  file-print ""

  file-write (word "b-count")
  file-write b-count-final
  file-print ""

  file-write (word "c-color-count")
  file-write c-color-count
  file-print ""

  file-write (word "c-express-count")
  file-write c-express-count
  file-print ""

  file-write (word "d-color-count")
  file-write d-color-count
  file-print ""

  file-write (word "d-express-count")
  file-write d-express-count
  file-print ""


  file-write (word "cell-count")
  file-write count turtles
  file-print ""
end

to outputContigArea
  ask turtles with [color = green] [probe-surroundings-boundary-inner]
  let contig-green-1 count turtles with [color = orange]
;  file-write (word "contig-green")
;  file-write contig-green
;  file-print ""
  ask turtles with [color = red] [let n turtles-on neighbors4 if count n with [color = orange] > 0[set color white]]
  let contig-red-1 count turtles with [color = white]
;  file-write (word "contig-red")
;  file-write contig-red
;  file-print ""
  let contig-ratio contig-red-1 / contig-green-1
  file-write (word "contig-ratio-green-core")
  file-write contig-ratio
  file-print ""

  ask bs with [g-color = true] [set color green]
  ask as with [r-color = true] [set color red]

  ask turtles with [color = red] [probe-surroundings-boundary-inner]
  let contig-red-2 count turtles with [color = orange]
  ask turtles with [color = green] [let n turtles-on neighbors4 if count n with [color = orange] > 0[set color white]]
  let contig-green-2 count turtles with [color = white]

  let contig-ratio-2 contig-green-2 / contig-red-2
  file-write (word "contig-ratio-red-core")
  file-write contig-ratio-2
  file-print ""
end
@#$#@#$#@
GRAPHICS-WINDOW
239
45
644
451
-1
-1
18.905
1
10
1
1
1
0
0
0
1
-10
10
-10
10
0
0
1
ticks
30.0

BUTTON
40
78
106
111
setup
set spheroid-radius 5.3\nsetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
42
131
176
164
repeat 100 [go]
repeat 100 [go]\n;set spheroid-radius 5.3\n\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
43
230
93
290
a-ratio
9.0
1
0
Number

INPUTBOX
99
230
149
290
b-ratio
1.0
1
0
Number

SLIDER
43
183
215
216
spheroid-radius
spheroid-radius
0
20
4.291180130888505
.1
1
NIL
HORIZONTAL

SLIDER
879
75
1067
108
c-express-delay
c-express-delay
0
100
10.0
10
1
ticks
HORIZONTAL

SLIDER
878
119
1074
152
c-express-thresh
c-express-thresh
0
500
10.0
5
1
ticks
HORIZONTAL

SLIDER
878
160
1067
193
d-express-delay
d-express-delay
0
100
20.0
5
1
ticks
HORIZONTAL

SLIDER
878
201
1075
234
d-express-thresh
d-express-thresh
0
100
10.0
5
1
ticks
HORIZONTAL

BUTTON
124
79
187
112
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
878
246
1142
279
NIL
normalize-ids\nask turtles [set label id]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
878
293
1006
326
NIL
makeOutputFile\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
46
380
218
413
percent-saturation
percent-saturation
0
1
0.65
.01
1
NIL
HORIZONTAL

MONITOR
46
303
101
348
NIL
a-count
0
1
11

MONITOR
108
303
172
348
NIL
b-count
0
1
11

BUTTON
1034
294
1132
327
NIL
outputXYH
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
673
55
852
88
cluster-pause-delay
cluster-pause-delay
0
15
3.0
1
1
NIL
HORIZONTAL

SLIDER
673
105
845
138
cluster-move-size
cluster-move-size
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
673
160
859
193
exp-expression-const-c
exp-expression-const-c
0
10
0.2
.05
1
NIL
HORIZONTAL

SLIDER
674
299
846
332
homotypic-prob-c
homotypic-prob-c
0
100
100.0
10
1
NIL
HORIZONTAL

SLIDER
675
392
847
425
heterotypic-prob
heterotypic-prob
0
100
0.0
5
1
NIL
HORIZONTAL

SLIDER
674
344
846
377
homotypic-prob-d
homotypic-prob-d
0
100
100.0
10
1
NIL
HORIZONTAL

SLIDER
673
206
860
239
exp-expression-const-d
exp-expression-const-d
0
10
0.2
.05
1
NIL
HORIZONTAL

SLIDER
673
251
861
284
exp-expression-const
exp-expression-const
0
0.5
0.2
0.05
1
NIL
HORIZONTAL

SLIDER
881
351
1053
384
homotypic-prob
homotypic-prob
0
100
100.0
10
1
NIL
HORIZONTAL

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="1A:1,4,9B_SphRad-4,5.8" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4_percent-saturation" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="1"/>
      <value value="0.9"/>
      <value value="0.85"/>
      <value value="0.8"/>
      <value value="0.75"/>
      <value value="0.7"/>
      <value value="0.5"/>
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4,5.8_percent-saturation" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="1"/>
      <value value="0.9"/>
      <value value="0.85"/>
      <value value="0.8"/>
      <value value="0.75"/>
      <value value="0.7"/>
      <value value="0.5"/>
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4,5.8_200Ticks" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4,5.8_300Ticks" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="300"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4_200Ticks" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4_300Ticks" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="300"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-3.7_PercSat-1.0_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="3.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4.1_PercSat-.78_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4.5_PercSat-.52_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-5.8_PercSat-.25_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-3.7_PercSat-1.0_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="3.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4.1_PercSat-.78_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4.5_PercSat-.52_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-5.8_PercSat-.25_C-express-delay-10,20,30,40,50_D-express-delay_10,20,30" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="22.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>set spheroid-radius 5.8
outputImages</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4.3,6.4" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.3"/>
      <value value="6.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4.3,6.4" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.3"/>
      <value value="6.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B_SphRad-6.4_Probe-Surr-Thresh" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="6.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-4.3,6.4_Probe-Surr-Thresh" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4.3"/>
      <value value="6.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-count">
      <value value="14.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="300runs" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="6.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SpheroidRadius_SensitivityAnalysis" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-4.0" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-2.68" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="2.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-2.68" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="2.68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4,9B_SphRad-5.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4,9A:1B_SphRad-5.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B_SphRad-5.1_ProbeSurrProb" repetitions="70" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probe-chance">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-exp-expression-const [0.1 0.2 0.3]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-c-express-delay [5 10 15]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-d-express-delay [15 20 25]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-c-express-thresh [5 10 15]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-d-express-thresh [5 10 15]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-c-probe-surr-thresh [65 70 75]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-d-probe-surr-thresh [75 80 85]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-cluster-pause-delay [75 80 85]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-1DSA-cluster-move-size [4 5 6]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="probe-chance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3-6">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-max">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="express-prob-3">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1B-HomoHetero-ExpC-ExpD" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.05"/>
      <value value="0.2"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.05"/>
      <value value="0.2"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="25"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="25"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="C+DExpressThresh-ProbeSurr_SensitivityAnalysis" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="c-probe-surr-thresh">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-probe-surr-thresh">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp-Expression-Const-CD" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.3"/>
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.3"/>
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_c-express-delay [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_d-express-delay [18 20 22]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="18"/>
      <value value="20"/>
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_c-express-thresh [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_d-express-thresh [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_exp-expression-const [0.27 0.3 0.33]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.27"/>
      <value value="0.3"/>
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_cluster-move-size [4 5 6]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_cluster-pause-delay [2 3 4]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_2_homotypic-prob [80 90 100]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SymmetricRulesetTrainingData" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="AsymmetricRulesetTrainingData" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="C+DExpressThresh-ProbeSurr_Symm_SensitivityAnalysis" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="300"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp-Expression-Const-CD_Symmetric" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.3"/>
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.3"/>
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4A:1B_Cluster-Asymm-Validation" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:9B_Cluster-Asymm-Validation" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp-Expression-Const/Thresh-CD_Symmetric" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.05"/>
      <value value="0.3"/>
      <value value="0.7"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.05"/>
      <value value="0.3"/>
      <value value="0.7"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SpheroidRadius" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_cluster-pause-delay [2 3 4]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_cluster-move-size [4 5 6]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_c-express-thresh [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_d-express-thresh [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_d-express-delay [18 20 22]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="18"/>
      <value value="20"/>
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_d-express-thresh [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_exp-expression-const [0.18 0.2 0.22]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.18"/>
      <value value="0.2"/>
      <value value="0.22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_heterotypic-prob [0 5 10]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_homotypic-prob [80 90 100]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1DSA_3_c-express-delay [9 10 11]" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1,4,9A:1B-CoreShell" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="300"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.6"/>
      <value value="6.4"/>
      <value value="7.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:4,9B-CoreShell" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.6"/>
      <value value="6.4"/>
      <value value="7.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:1,4B-CoreShell-ExpC_ExpD" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="200"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.2"/>
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.2"/>
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="7.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SignalingRemovedExperiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="WithSignalingExperiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1,4,9A:1B-CorePole" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>makeOutputFile</final>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1A:4,9B-CorePole" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <enumeratedValueSet variable="percent-saturation">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-c">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-expression-const-d">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterotypic-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-move-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-delay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spheroid-radius">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-delay">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b-ratio">
      <value value="4"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-express-thresh">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster-pause-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-c">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homotypic-prob-d">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
