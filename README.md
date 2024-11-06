# Simulation NetLogo : Gendarmes, Voleurs et Civils

## Description du projet

Ce projet NetLogo simule un environnement dans lequel coexistent trois types d'agents :

- **Civils** : Les civils commencent avec une certaine quantité d'argent. Au fil du temps, ils perdent de l'argent de manière aléatoire. Lorsqu'ils n'ont plus d'argent, ils se transforment en voleurs.
  
- **Voleurs** : Les voleurs ont pour objectif de voler de l'argent aux civils. Lorsqu'un voleur touche un civil, il vole de l'argent à ce dernier. Les voleurs peuvent être capturés par les gendarmes et mis en prison.

- **Gendarmes** : Les gendarmes sont chargés d'arrêter les voleurs. Lorsqu'un gendarme touche un voleur, les deux agents sont immobilisés. Cependant, un voleur ne sera mis en prison que si un autre gendarme le touche avant qu'un autre voleur ne vienne le libérer.

Les voleurs en prison ont 5 % de chances de s'évader. Une fois en prison, ils peuvent être capturés à nouveau par les gendarmes.

La simulation se termine lorsque tous les voleurs sont en prison.

## Fonctionnalités

- **Perte d'argent des civils** : Les civils perdent de l'argent au fil du temps, et lorsqu'ils n'ont plus d'argent, ils deviennent des voleurs.
- **Vol d'argent** : Les voleurs volent de l'argent aux civils lorsqu'ils les touchent.
- **Capture des voleurs** : Les gendarmes arrêtent les voleurs lorsqu'ils les touchent, mais un voleur ne sera mis en prison que si un autre gendarme le touche avant qu'un autre voleur ne le libère.
- **Évasion de la prison** : Les voleurs en prison ont 5 % de chances de s'évader.
- **Fin de la simulation** : La simulation se termine lorsque tous les voleurs sont en prison.

## Objectifs de la simulation

1. **Représentation d'un environnement dynamique** avec des agents qui interagissent entre eux : civils, voleurs et gendarmes.
2. **Gestion d'événements aléatoires**, tels que la perte d'argent des civils et les tentatives d'évasion des voleurs.
3. **Mécanismes de capture et de libération** : Les voleurs peuvent être capturés par les gendarmes, mais peuvent également être libérés par d'autres voleurs.
4. **Simulation de la gestion de la sécurité publique** dans un environnement de type "jeu de société".

## Comment exécuter la simulation

1. Téléchargez et installez [NetLogo](https://ccl.northwestern.edu/netlogo/).
2. Ouvrez le fichier de simulation `simulation.nlogo` dans NetLogo.
3. Cliquez sur le bouton "setup" pour initialiser les agents.
4. Cliquez sur le bouton "go" pour démarrer la simulation.
5. Observez l'interaction entre les civils, les voleurs et les gendarmes.

## Architecture du code

- **Civils** : Les civils sont représentés par des agents avec une variable `money` qui diminue au fil du temps.
- **Voleurs** : Lorsqu'un civil n'a plus d'argent, il devient un voleur. Les voleurs interagissent avec les civils pour leur voler de l'argent.
- **Gendarmes** : Les gendarmes interagissent avec les voleurs pour les capturer et les emprisonner.
- **Prison** : La prison est représentée par un rectangle sur la carte. Les voleurs capturés sont placés dans cette zone.

