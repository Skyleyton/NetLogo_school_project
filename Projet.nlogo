globals [
  number-max-civilian
  number-max-policeman
  number-max-thief
  number-max-money
  number-min-money ; Il faut descendre en dessous de ce seuil pour devenir voleur.
  money-timer ; compteur pour gérer la fréquence de perte d'argent
  nbrC
  detection-radius ;
  stunt-timer
]

; Il y a 3 types d'agents.
breed [ civilians civilian ]
breed [ policemen policeman ]
breed [ thieves thief ]

; On part du principe que tous les agents ont de l'argent.
turtles-own [ money ]

; Il n'y a que les policiers et les voleurs qui ont un certain niveau de force et un certain niveau de vitesse.
thieves-own [ strength speed captured? is-escorted? in-prison? ]

; l'attribut in-prison-zone? va permettre de savoir si les policiers sont arrivés dans la prison pendant l'escorte d'un voleur.
policemen-own [ strength speed escorting? has-captured? release-timer in-prison-zone? ]

patches-own [ is-prison? ]

to setup
  clear-all
  set number-max-money 250 ; Les civils ne peuvent avoir que 250 pièces au maximum.
  set number-min-money 25 ; Si ce seuil est dépassé, le civil devient un voleur.
  set money-timer 0 ; initialisation du timer
  set nbrC 25
  setup-civilians
  setup-environment
  reset-ticks
  set detection-radius 5 ;
  set stunt-timer timer  ; initialise le temps de début
end

to move-turtles
  move-civilians
  move-policemen
  move-thieves
end

; Les civils bougent toujours.
to move-civilians
  ask civilians [
    right random 30
    left random 30
    forward 0.5
  ]
end

; Les policiers bougent uniquement s'ils n'ont pas capturé un voleur ou s'ils ne sont pas en train d'escorter un voleur.
to move-policemen
  let prison-patch patch 1 1

  ask policemen with [has-captured? = false] [
    right random 30
    left random 30
    forward 0.5
  ]

  ; Faire en sorte que les policiers qui sont en escorte se dirige vers la prison avec le voleur.
  ask policemen with [escorting?] [
    face prison-patch
    forward 0.1
  ]
end

; Les voleurs bougent uniquement s'ils ne sont pas capturés.
to move-thieves
  let prison-patch patch 1 1

  ask thieves with [captured? = false] [
    ifelse distance prison-patch < 8 [
      ; Si trop proche de la prison, ils rebroussent chemin
      right 160
      forward 0.5
    ] [
      ; Sinon, mouvement normal
      right random 30
      left random 30
      forward 0.5
    ]
  ]
  
  
  

  ask thieves with [is-escorted?] [
    set color orange
    face prison-patch
    forward 0.1
  ]
end

; L'initialisation des civils.
to setup-civilians
  create-civilians nbrC [ ; nombre choisi au hasard.
    set color white
    set shape "person"
    set size 2 ;
    set money number-max-money
    setxy random-xcor random-ycor ; placeholder pour l'instant.
    set label-color black
    set label money ; Affiche l'argent initial sur chaque civil
  ]
end

; L'initialisation de l'environnement.
to setup-environment
  ask patches [
    set pcolor grey
  ]
  ; On initialise la prison dans l'initialisation de l'environnement.
  setup-prison
end

to setup-prison
  ; Crée un espace vert (désignant la prison) entre ces coordonnées.
  ask patches with [ (pxcor >= -4 and pxcor <= 6) and (pycor >= -5 and pycor <= 7) ] [
    set pcolor green
    set is-prison? true
  ]
end

to go
  move-turtles
  set money-timer money-timer + 1
  let priority 0

  if money-timer mod 3 = 0 [
    lose-money
  ]

  check-civilians
  pursue-thieves
  escort-thief
  free-thief

  ask policemen [
    stunt-policemen self ; Vérifier le délai pour chaque policier
  ]

  tick
end


to lose-money
  ; Vérifie s'il reste au moins 5 tortues civiles
  if count civilians >= 5 [
    ; Sélectionne aléatoirement 5 tortues civiles
    let turtles-to-lose-money n-of 5 civilians

    ask turtles-to-lose-money [
      let amount-to-lose random 10 + 1 ; un montant entre 1 et 10
      set money money - amount-to-lose ; décrémenter la variable money
      if money < 0 [ set money 0 ] ; s'assurer que l'argent ne devient pas négatif
      set label-color black
      set label money ; Met à jour le label pour afficher la nouvelle valeur d'argent
    ]
  ]
end

to check-civilians
  ask civilians [
    if money = 0 [
      convert-civilian self
    ]
  ]
end

to convert-civilian [civilian-turtle]
  let num-policemen count policemen
  let num-thieves count thieves

  ; Vérifie si le nombre de policiers est inférieur au nombre de voleurs, sinon donne une chance aléatoire
  ifelse (num-policemen < num-thieves) or (num-policemen = num-thieves and random 2 = 0) [
    convert-civilian-to-policeman civilian-turtle
  ] [
    convert-civilian-to-thief civilian-turtle
  ]
end

; Fonction pour que les turtles rouges se dirigent vers turtles blancs
to move-red-toward-nearest-white
  ask turtles with [color = red] [ ; uniquement les tortues rouges (donc les voleurs).
    let target white-nearest-turtle ; trouve la tortue blanche la plus proche
    if target != nobody [
      face target ; oriente la tortue vers la cible
      forward 0.2 ; avance de 2 unités vers la cible
    ]
  ]
end

; Renvoie la tortue blanche la plus proche ou personne si aucune n'existe
to-report white-nearest-turtle
  report min-one-of turtles with [color = white] [distance myself]
end

; Convertit un civil en policier.
to convert-civilian-to-policeman [civilian-turtle]
  if [breed] of civilian-turtle = civilians [
    let civ-money [money] of civilian-turtle
    let civ-xcor [xcor] of civilian-turtle
    let civ-ycor [ycor] of civilian-turtle

    ask civilian-turtle [
      hatch-policemen 1 [
        set money civ-money
        set color blue
        set shape "person"
        set size 2
        setxy civ-xcor civ-ycor
        set strength random 10 + 1
        set speed random 3 + 1
				set has-captured? false ; Initialisation booléenne
        set escorting? false
        set in-prison-zone? false
      ]
      die
    ]
  ]
end


; Cette fonction va créé un turtle de type thief à la place d'un turtle de type civilians
to convert-civilian-to-thief [civilian-turtle]
  if [breed] of civilian-turtle = civilians [
    let civ-money [money] of civilian-turtle
    let civ-xcor [xcor] of civilian-turtle
    let civ-ycor [ycor] of civilian-turtle

    ask civilian-turtle [
      hatch-thieves 1 [
        set money civ-money
        set color red
        set shape "person"
        set size 2
        setxy civ-xcor civ-ycor
        set strength random 10 + 1
        set speed random 3 + 1
        set captured? false ; Initialisation booléenne
        set is-escorted? false ; Initialisation booléenne
      ]
      die
    ]
  ]
end

; Pour que les policiers pourchassent les voleurs.
to pursue-thieves
  ; On choisit uniquement les policiers qui ne bloque personne et qui n'aide personne.
  ask policemen with [has-captured? = false and escorting? = false] [
    let nearest-thief min-one-of (thieves in-radius detection-radius) with [captured? = false and is-escorted? = false] [distance myself]
    if nearest-thief != nobody [
      face nearest-thief
      forward 0.1
      if distance nearest-thief < 1 [
        capture-thief self nearest-thief ; Passe le policier et le voleur capturé
      ]
    ]
  ]
end

; Pour que les voleurs viennent en aide aux autres voleurs.
to free-thief
  ask turtles with [color = red] [
    ; On cherche un autre voleur qui est capturé, mais pas en train d'être escorté.
    let nearest-thief min-one-of (thieves in-radius detection-radius) with [captured? = true and is-escorted? = false] [distance myself]
    if nearest-thief != nobody [
      face nearest-thief
      forward 0.1
      ; Le voleur s'est fait libérer alors il n'est plus captif.
      if distance nearest-thief < 1 [
        ask nearest-thief [
          set captured? false
          ; set is-escorted? false ; Il n'était déjà pas en train d'être escorté.
          set color red
        ]
      ]
    ]

    let nearest-policeman min-one-of (policemen in-radius detection-radius) with [has-captured? = true] [distance self]
    if nearest-policeman != nobody [
      stunt-policemen nearest-policeman
      ask nearest-policeman [ set release-timer 1 ] ; Démarrer le délai
    ]
  ]
end

; Pour indiquer que le policier a capturé un voleur.
to capture-thief [policeman-turtle thief-turtle]
  ask thief-turtle [
    set captured? true
    set color yellow ; Change la couleur pour indiquer la capture
  ]
  ask policeman-turtle [
    set has-captured? true ; Marque le policier comme ayant capturé un voleur
    ; set escorting? true
    set color black ; Indique que le policier a attrapé un voleur.
    set release-timer 0 ; Initialiser le compteur
  ]
end

; Pour faire en sorte qu'un policier lâche le voleur qu'il tenait et soit étourdi.
to stunt-policemen [stunt-policeman]
  ask stunt-policeman [
    if release-timer > 0 [
      set release-timer release-timer + 1
      if release-timer >= 5 [
        set has-captured? false
        set escorting? false
        set color blue ; On le repasse en bleu
        set release-timer 0 ; Réinitialiser le compteur
      ]
    ]
  ]
end

; Permets à deux policiers d'escorter un voleur.
to escort-thief
  let prison-patch patch 1 1

  ; Policier principal qui effectue l'escorte
  ask policemen with [has-captured? = true and escorting? = false] [
    let nearest-thief min-one-of (thieves in-radius detection-radius) with [captured? = true and is-escorted? = false] [distance myself]
    let second-policeman min-one-of (policemen in-radius detection-radius) with [has-captured? = false and escorting? = false] [distance myself]

    if nearest-thief != nobody and second-policeman != nobody [
      ; Lancer l'escorte
      set escorting? true

      ask second-policeman [
        set escorting? true
      ]

      ask nearest-thief [
        set is-escorted? true
        face prison-patch
        forward 0.1
      ]
    ]
  ]

  ask policemen with [escorting? = true] [
    face prison-patch
    forward 0.1
    if distance prison-patch < 1 [
      set escorting? false
      set has-captured? false
      set color blue
    ]
  ]

  ask thieves with [is-escorted? = true] [
    face prison-patch
    forward 0.1
    if distance prison-patch < 1 [
      set is-escorted? false
      set in-prison? true
      set color grey ; Changement de couleur pour indiquer l'emprisonnement
    ]
  ]
end