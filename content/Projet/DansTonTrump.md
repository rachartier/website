---
title: "DansTonTrump"
date: 2020-07-07T01:00:00+02:00
draft: true
comments: false
images:
---

## Lien
[Github](https://github.com/rachartier/DansTonTrump)

# DansTonTrump

## Description du sujet

Projet de Licence Informatique sur Sailfish reprennant DansTonChat mais avec les quotes de Trump (C++/QML)

Ce projet permet de visualiser les meilleurs citations de Donald Trump et de pouvoir en personnaliser avec le nom de votre choix ! 

Il se décompose en 4 pages:

- Page d'accueil:
- Personalized Quotes: Citation personnalisé avec en entrée un champ de texte.
- Random Quotes: Une citation au hasard
- Last Quotes: Les toutes dernières citations de DT ! Petit veinard.

## Points techniques abordés

### Un master dynamique

- Un pullDownMenu qui permet d'accéder aux différentes vue disponibles de l'application

### Des requêtes à l'API Web WhatDoesTrumpThink

- Requêtes à l'API et parse du JSON renvoyé.
- Visible dans la classe *RestAPI* pour l'appel reseau, et *QuoteManager* pour
le lien à l'API. 
- Parse du JSON visible dans la classe *QuoteBuilder*

## Fonctionnalités à ne pas râter lors des tests

- La fonctionnalité *Personalized Quote* qui permet de compléter une fameuse citation de Donald Trump avec le nom de votre choix!


