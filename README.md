# 🗄️ Modélisation Relationnelle & Base de Données d'Assurance (Merise & SQL)

Projet de conception de base de données relationnelle appliqué à un cabinet de courtage en assurance (**Assur+**), réalisé dans le cadre du Master 1 MAS (parcours IMSA) à Aix-Marseille Université.

---

## 🎯 Contexte & Objectifs Métier
Modélisation complète du système d'information d'un courtier multi-risques (Automobile, Habitation, Santé) permettant de :
* Gérer les portefeuilles clients, les courtiers référents et les compagnies partenaires (Axa, Allianz, MAIF, etc.).
* Administrer les contrats, les primes annuelles et les commissions des courtiers.
* Suivre le cycle de vie complet des sinistres (déclaration, missionnement d'experts, chiffrage des dommages, refus ou indemnisation).
* Mesurer le pilotage commercial (objectifs annuels de vente par risque et par courtier) et l'accidentologie pour le recalibrage tarifaire.

---

## 📐 Démarche de Conception (Méthode Merise)
1. **Dictionnaire des données épuré :** Élimination systématique des données calculables redondantes (commissions en euros, cumuls d'indemnisation).
2. **Schéma Conceptuel des Données (MCD) :**
   * Modélisation des cardinalités `(1,1)`, `(0,n)` et d'une association ternaire `FixerObjectif` (Courtier × Risque × Année).
3. **Passage au Modèle Relationnel & Normalisation (3NF) :**
   * Structuration en 9 tables relationnelles garantissant l'intégrité référentielle.
   * Respect strict de la **3NF** pour éliminer les anomalies d'insertion, de mise à jour et de suppression.

---

## ⚙️ Implémentation SQL & Sécurisation des Données (SQLite)
Le script SQL intègre des mécanismes de contrôle rigoureux au niveau du SGBD :
* **Vérification d'intégrité référentielle :** Clés primaires et étrangères strictement typées (`PRAGMA foreign_keys = ON`).
* **Contrôles de cohérence temporelle :** Vérification de l'enchaînement chronologique des événements :
  $$\text{Souscription} < \text{Survenue} \le \text{Déclaration} (\le 30\text{j}) \le \text{Mission} \le \text{Rapport} \le \text{Indemnisation}$$
* **Machines à états pour les sinistres :** Contrainte `CHECK` interdisant la présence d'informations d'expertise sur un sinistre simplement « déclaré » ou une indemnisation sur un sinistre « refusé ».
* **Formats & Masques :** Validation stricte des numéros de téléphone via regex/GLOB (`+33...`), formats d'emails et bornes de commission ($0 \le \tau \le 1$).

---

## 📊 Requêtes Analytiques & Décisionnelles
Le script inclut des requêtes d'extraction et de pilotage :
* **Consultation portefeuille :** État des contrats souscrits et primes associées par client.
* **Indemnisation cumulée :** Calcul agrégé du montant total versé par client via jointures externes et `COALESCE`.
* **Fréquence de sinistralité :** Comptage annuel des sinistres par type de risque pour le reporting actuariel.
* **Suivi de la performance commerciale :** Comparaison entre contrats visés et contrats réellement souscrits par courtier.

---

## 📁 Contenu du dépôt
* `Projet_SQL_ANTOURI_Mohamed.sql` : Script DDL complet (création des tables, contraintes `CHECK`, jeu d'essai `INSERT`, requêtes métier et tests de contraintes).
* `Projet_SQL_ANTOURI_Mohamed.pdf` : Rapport technique détaillé (dictionnaire des données, hypothèses de gestion, schéma MCD et schéma relationnel normalisé).
