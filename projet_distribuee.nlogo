globals [
  number-max-civilian
  number-max-policeman
  number-max-thief
  number-max-money
  number-min-money ; Il faut descendre en dessous de ce seuil pour devenir voleur.
  money-timer ; compteur pour gérer la fréquence de perte d'argent
  nbrC
  detection-radius ;

]

; Il y a 3 types d'agents.
breed [ civilians civilian ]
breed [ policemen policeman ]
breed [ thieves thief ]

; On part du principe que tous les agents ont de l'argent.
turtles-own [ money ]

; Il n'y a que les policiers et les voleurs qui ont un certain niveau de force et un certain niveau de vitesse.
thieves-own [ strength speed captured? escort? ]
policemen-own [ strength speed helping? has-captured?]


patches-own [ is-prison? ]



to setup
  clear-all
  set number-max-money 250 ; Les civils ne peuvent avoir que 250 pièces au maximum.
  set number-min-money 25 ; Si ce seuil est dépassé, le civil devient un voleur.
  set money-timer 0 ; initialisation du timer
  set nbrC 25
  setup-civilians
  setup-environment
  setup-prison
  reset-ticks
  set detection-radius 5 ;
end

to move-turtles
  ; Les civils et policiers bougent toujours
  ask civilians [
    right random 30
    left random 30
    forward 0.5
  ]
  
  ask policemen with [not has-captured?][
    right random 30
    left random 30
    forward 0.5
  ]

  ; Les voleurs bougent uniquement s'ils ne sont pas capturés
  ask thieves with [not captured?] [
    right random 30
    left random 30
    forward 0.5
  ]
end

to setup-civilians
  create-civilians nbrC [ ; nombre choisi au hasard.
    set color white
    set shape "person"
    set size 2 ;
    set money number-max-money
    setxy random-xcor random-ycor ; placeholder pour l'instant.
    set label money ; Affiche l'argent initial sur chaque civil
  ]
end

; L'environnement sera de couleur bleu.
to setup-environment
  ask patches [
    set pcolor grey
  ]
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
  set money-timer money-timer + 1 ; incrémentation du timer

  ; Exécute lose-money toutes les 3 secondes (ticks).
  if money-timer mod 3 = 0 [
    lose-money
  ]
 
    check-civilians
		pursue-thieves

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

;Fonction pour que les turtles rouges se dirigent vers turtles blancs
to move-red-toward-nearest-white
  ask turtles with [color = red] [ ; uniquement les tortues rouges
    let target white-nearest-turtle ; trouve la tortue blanche la plus proche
    if target != nobody [
      face target ; oriente la tortue vers la cible
      forward 0.2 ; avance de 1 unité vers la cible
    ]
  ]
end

to-report white-nearest-turtle
  ; renvoie la tortue blanche la plus proche ou personne si aucune n'existe
  report min-one-of turtles with [color = white] [distance myself]
end


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

      ]
      die
    ]
  ]
end



;Cette fonction va créé un turtle de type thief à la place d'un turtle de type civilians
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
        set escort? false ; Initialisation booléenne
      ]
      die
    ]
  ]
end


to pursue-thieves
  ask policemen with [has-captured? = false ] [
    let nearest-thief min-one-of (thieves in-radius detection-radius) with [captured? = false] [distance myself]
    if nearest-thief != nobody [
      face nearest-thief
      forward 0.1
      if distance nearest-thief < 1 [
        capture-thief self nearest-thief ; Passe le policier et le voleur capturé
      ]
    ]
  ]
end


to capture-thief [policeman-turtle thief-turtle]
  ask thief-turtle [
    set captured? true
    set color yellow ; Change la couleur pour indiquer la capture
  ]
  ask policeman-turtle [
    set has-captured? true ; Marque le policier comme ayant capturé un voleur
    set helping? true
  ]
  
  ; Cherche un deuxième policier dans le rayon de détection qui n'a pas capturé
  let second-policeman min-one-of (policemen in-radius detection-radius) with [has-captured? = false and helping? = false] [distance policeman-turtle]
  
  if second-policeman != nobody [
    ask second-policeman [
      set helping? true ; marque le policier comme aidant
      escort-thief policeman-turtle thief-turtle second-policeman ; Lance l'escorte
    ]
  ]
end



to escort-thief [first-policeman thief-turtle second-policeman]
  ; Demande aux policiers et au voleur de se déplacer ensemble vers la prison
  ask first-policeman [
    face patch 1 1 ; point d'entrée de la prison
    forward 0.1
  ]
  ask second-policeman [
    face patch 1 1
    forward 0.1
  ]
  ask thief-turtle [
    face patch 1 1
    forward 0.1
  ]
  
  ; Vérifie si tous les trois sont dans la prison
  if [is-prison?] of patch-here [
    ; Libère le voleur et remet les policiers à leur état initial
    ask thief-turtle [
      die ;(à changer plus tard)
    ]
    ask first-policeman [
      set has-captured? false
      set helping? false
    ]
    ask second-policeman [
      set helping? false
    ]
  ]
end


