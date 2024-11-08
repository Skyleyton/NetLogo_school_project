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


@#$#@#$#@
GRAPHICS-WINDOW
441
4
967
531
-1
-1
15.7
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
23
33
86
66
setup
setup
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
138
35
201
68
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?
Ce modèle simule un environnement dynamique où trois types d’agents interagissent : des civils, des voleurs et des gendarmes. Les civils possèdent de l’argent, mais en perdent au fil du temps. Lorsqu’ils n’ont plus d’argent, ils deviennent des voleurs, qui cherchent à voler l’argent des civils. Les gendarmes, quant à eux, tentent de capturer les voleurs et de maintenir l’ordre. La simulation explore les interactions complexes entre ces groupes et les conditions dans lesquelles la sécurité publique peut être maintenue.

## HOW IT WORKS
Le modèle démarre avec un nombre de civils, de voleurs, et de gendarmes prédéfinis :
- **Civils** : Ils commencent avec une certaine somme d’argent. Leur argent diminue progressivement, et lorsqu’il atteint zéro, le civil se transforme en voleur.
- **Voleurs** : Ils volent les civils en les touchant, transférant ainsi une partie de leur argent. Ils peuvent être capturés par les gendarmes, mais peuvent également être libérés par d'autres voleurs.
- **Gendarmes** : Ils patrouillent pour capturer les voleurs. Lorsqu’ils touchent un voleur, ils immobilisent celui-ci. Si un autre gendarme touche un voleur capturé, ce dernier est envoyé en prison, à moins qu’un autre voleur n’intervienne pour le libérer.
- **Prison** : Les voleurs capturés peuvent être emprisonnés, mais ils ont une chance de s'évader (5 % par "tick").

La simulation se termine une fois que tous les voleurs sont en prison.

## HOW TO USE IT
1. **Configuration** : Appuyez sur le bouton “setup” pour initialiser les civils, voleurs et gendarmes, avec leurs positions et caractéristiques de départ.
2. **Démarrage de la simulation** : Appuyez sur “go” pour lancer la simulation en continu.
3. **Suivi des agents** : Observez les civils perdant progressivement de l’argent, les voleurs volant les civils, et les gendarmes capturant les voleurs.
4. **Éléments d'interface** : 
   - **Sliders** pour ajuster le nombre de civils, voleurs et gendarmes au début de la simulation.
   - **Moniteurs** pour afficher le nombre d’agents en chaque état (ex. civils restants, voleurs en fuite, voleurs en prison).

## THINGS TO NOTICE
- **Transformation des civils en voleurs** : Au fil du temps, le nombre de civils diminue en raison de la perte d’argent, et plus de voleurs apparaissent.
- **Mécanisme de capture** : Les gendarmes arrêtent les voleurs, mais un voleur peut être libéré si un autre voleur le touche avant qu'un autre gendarme n’intervienne.
- **Equilibre dans la simulation** : La capacité des gendarmes à capturer et emprisonner les voleurs influence la stabilité de l'environnement. Observez si la situation peut rester sous contrôle ou si les voleurs deviennent trop nombreux.

## THINGS TO TRY
- **Modifier le nombre initial de chaque type d’agent** : Essayez de démarrer avec plus de voleurs ou de gendarmes, et observez comment cela affecte la dynamique de la simulation.
- **Ajuster la fréquence de perte d’argent** : En rendant les civils plus vulnérables, ils deviennent voleurs plus rapidement, ce qui pourrait déséquilibrer la simulation.
- **Augmenter la probabilité d’évasion de la prison** : Voyez comment une augmentation de la probabilité de fuite des voleurs affecte la capacité des gendarmes à maintenir l’ordre.

## EXTENDING THE MODEL
- **Ajouter des niveaux de ressources pour les gendarmes** : Par exemple, un temps de réaction ou un budget pour capturer les voleurs, limitant ainsi leur efficacité à maintenir l’ordre.
- **Créer des civils "riches" et "pauvres"** : Cela permettrait de diversifier les interactions, avec des voleurs potentiellement plus attirés par les civils riches.
- **Complexifier la prison** : Ajouter des conditions pour augmenter ou diminuer la probabilité de fuite selon le nombre de gendarmes.

## NETLOGO FEATURES
Ce modèle utilise des fonctions NetLogo pour gérer les interactions de capture et de libération entre agents, ainsi que pour organiser la zone de prison en tant qu’espace réservé sur la carte. La capacité de conditionner l’état des agents en fonction de leur argent ou de leur proximité avec d'autres agents est un aspect essentiel du modèle. Les événements aléatoires (perte d'argent, évasion) sont également gérés avec des fonctions aléatoires.

## RELATED MODELS
- **Police et Voleurs** : Modèle NetLogo traitant des interactions entre forces de l’ordre et criminels.
- **Propagation de la rumeur** : Montre des dynamiques similaires d’interaction et d’influence entre agents.
  
## CREDITS AND REFERENCES
Modèle développé sous NetLogo pour illustrer la dynamique entre civils, voleurs, et gendarmes dans un contexte de gestion de sécurité publique. Ce modèle est inspiré de simulations de type "jeu de société". Pour en savoir plus sur NetLogo, consultez [NetLogo](https://ccl.northwestern.edu/netlogo/).
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
NetLogo 6.4.0
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