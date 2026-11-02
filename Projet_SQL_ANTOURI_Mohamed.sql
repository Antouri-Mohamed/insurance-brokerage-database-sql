-- PROJET : modélisation Merise d’un cabinet de courtage
--  ANTOURI Mohamed

-- Active la verification des cles etrangeres dans SQLite
PRAGMA foreign_keys = ON;

-- Drop existing tables if any (order respects FKs)
DROP TABLE IF EXISTS Objectif;
DROP TABLE IF EXISTS Sinistre;
DROP TABLE IF EXISTS Contrat;
DROP TABLE IF EXISTS Client;
DROP TABLE IF EXISTS Annee;
DROP TABLE IF EXISTS Expert;
DROP TABLE IF EXISTS Risque;
DROP TABLE IF EXISTS Compagnie;
DROP TABLE IF EXISTS Courtier;

-- =========================
-- Schema
-- =========================

CREATE TABLE Courtier(
  NumCourtier     INTEGER(5) CONSTRAINT Pk_Courtier PRIMARY KEY CHECK (NumCourtier > 0 AND NumCourtier <= 99999),
  NomCourtier     CHAR VARYING(30) NOT NULL CHECK (LENGTH(NomCourtier) > 1),
  PrenomCourtier  CHAR VARYING(30) NOT NULL CHECK (LENGTH(PrenomCourtier) > 1)
);

CREATE TABLE Compagnie(
  NumCompagnie  INTEGER(5) CONSTRAINT Pk_Compagnie PRIMARY KEY CHECK (NumCompagnie > 0 AND NumCompagnie <= 99999),
  NomCompagnie  CHAR VARYING(30) NOT NULL CHECK (LENGTH(NomCompagnie) > 1)
);

CREATE TABLE Risque(
  CodeRisque     TEXT CONSTRAINT Pk_Risque PRIMARY KEY CHECK (CodeRisque IN ('AUTO', 'HAB', 'SAN')),
  LibelleRisque  TEXT NOT NULL CHECK (LibelleRisque IN ('automobile', 'habitation', 'santé'))
);

CREATE TABLE Expert(
  NumExpert  INTEGER(5) CONSTRAINT Pk_Expert PRIMARY KEY CHECK (NumExpert > 0 AND NumExpert <= 99999),
  NomExpert  CHAR VARYING(30) NOT NULL CHECK (LENGTH(NomExpert) > 1)
);

CREATE TABLE Annee(
  AnneeObjectif  INTEGER(4) CONSTRAINT Pk_Annee PRIMARY KEY CHECK (AnneeObjectif >= 2026 AND AnneeObjectif <= 9999)
);

CREATE TABLE Client(
  NumClient      INTEGER(10) CONSTRAINT Pk_Client PRIMARY KEY CHECK (NumClient > 0 AND NumClient <= 9999999999),
  NomClient      CHAR VARYING(30) NOT NULL CHECK (LENGTH(NomClient) > 1),
  PrenomClient   CHAR VARYING(30) NOT NULL CHECK (LENGTH(PrenomClient) > 1),
  AdresseClient  TEXT NOT NULL CHECK (LENGTH(AdresseClient) > 5),
  TelClient      TEXT NOT NULL CHECK (TelClient GLOB '+33[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
  MailClient     TEXT NOT NULL CHECK (MailClient LIKE '%@%'),
  NumCourtier    INTEGER(5) NOT NULL CONSTRAINT Fk_Client_Ref_Courtier REFERENCES Courtier(NumCourtier)
);

CREATE TABLE Contrat(
  NumContrat        INTEGER(10) CONSTRAINT Pk_Contrat PRIMARY KEY CHECK (NumContrat > 0 AND NumContrat <= 9999999999),
  DateSouscription  TEXT NOT NULL CHECK (DateSouscription >= '2026-01-01'),
  MontantPrime      REAL NOT NULL CHECK (MontantPrime > 0),
  TauxCommission    DECIMAL(4, 3) NOT NULL CHECK (TauxCommission >= 0 AND TauxCommission <= 1),
  NumClient         INTEGER(10) NOT NULL CONSTRAINT Fk_Contrat_Ref_Client REFERENCES Client(NumClient),
  NumCompagnie      INTEGER(5) NOT NULL CONSTRAINT Fk_Contrat_Ref_Compagnie REFERENCES Compagnie(NumCompagnie),
  CodeRisque        TEXT NOT NULL CONSTRAINT Fk_Contrat_Ref_Risque REFERENCES Risque(CodeRisque)
);

CREATE TABLE Sinistre(
  NumSinistre        INTEGER(10) CONSTRAINT Pk_Sinistre PRIMARY KEY CHECK (NumSinistre > 0 AND NumSinistre <= 9999999999),
  DateSurvenue       TEXT NOT NULL,
  DateDeclaration    TEXT NOT NULL,
  EtatSinistre       TEXT NOT NULL CONSTRAINT Dom_Etat CHECK (EtatSinistre IN ('déclaré', 'en cours d''expertise', 'indemnisé', 'refusé')),
  DateMission        TEXT,
  DateRapport        TEXT,
  MontantDommages    REAL CHECK (MontantDommages >= 0),
  DateIndemnisation  TEXT,
  MontantIndemnise   REAL CHECK (MontantIndemnise >= 0),
  NumContrat         INTEGER(10) NOT NULL CONSTRAINT Fk_Sinistre_Ref_Contrat REFERENCES Contrat(NumContrat),
  NumExpert          INTEGER(5) CONSTRAINT Fk_Sinistre_Ref_Expert REFERENCES Expert(NumExpert),

  -- ordre des dates (si une date est NULL, la condition est acceptee)
  CONSTRAINT Ck_Decl_Survenue CHECK (DateDeclaration >= DateSurvenue),
  CONSTRAINT Ck_Decl_30j CHECK (DateDeclaration <= date(DateSurvenue, '+30 days')),
  CONSTRAINT Ck_Mission CHECK (DateMission >= DateDeclaration),
  CONSTRAINT Ck_Rapport CHECK (DateRapport >= DateMission),
  CONSTRAINT Ck_Indemnisation CHECK (DateIndemnisation >= DateRapport),
  CONSTRAINT Ck_Montants CHECK (MontantIndemnise <= MontantDommages),

  -- coherence entre l'etat et les infos d'expertise (tableau du rapport)
  CONSTRAINT Ck_Etat_Coherent CHECK (
    (EtatSinistre = 'déclaré'
      AND NumExpert IS NULL AND DateMission IS NULL
      AND DateRapport IS NULL AND MontantDommages IS NULL
      AND DateIndemnisation IS NULL AND MontantIndemnise IS NULL)
    OR
    (EtatSinistre = 'en cours d''expertise'
      AND NumExpert IS NOT NULL AND DateMission IS NOT NULL
      AND ((DateRapport IS NULL AND MontantDommages IS NULL)
        OR (DateRapport IS NOT NULL AND MontantDommages IS NOT NULL))
      AND DateIndemnisation IS NULL AND MontantIndemnise IS NULL)
    OR
    (EtatSinistre = 'indemnisé'
      AND NumExpert IS NOT NULL AND DateMission IS NOT NULL
      AND DateRapport IS NOT NULL AND MontantDommages IS NOT NULL
      AND DateIndemnisation IS NOT NULL AND MontantIndemnise IS NOT NULL)
    OR
    (EtatSinistre = 'refusé'
      AND NumExpert IS NOT NULL AND DateMission IS NOT NULL
      AND DateRapport IS NOT NULL AND MontantDommages IS NOT NULL
      AND DateIndemnisation IS NULL AND MontantIndemnise IS NULL)
  )
);

CREATE TABLE Objectif(
  NumCourtier      INTEGER(5) NOT NULL CONSTRAINT Fk_Obj_Ref_Courtier REFERENCES Courtier(NumCourtier) ON DELETE CASCADE,
  CodeRisque       TEXT NOT NULL CONSTRAINT Fk_Obj_Ref_Risque REFERENCES Risque(CodeRisque),
  AnneeObjectif    INTEGER(4) NOT NULL CONSTRAINT Fk_Obj_Ref_Annee REFERENCES Annee(AnneeObjectif),
  NbContratsVises  INTEGER NOT NULL CHECK (NbContratsVises > 0),
  CONSTRAINT Pk_Objectif PRIMARY KEY (NumCourtier, CodeRisque, AnneeObjectif)
);

-- =========================
-- Donnees
-- =========================

INSERT INTO Courtier VALUES
  (20500, 'Martin',  'Alice'),
  (20501, 'Bernard', 'Karim'),
  (20502, 'Petit',   'Sophie');

-- Groupama n'a pas encore de contrat
INSERT INTO Compagnie VALUES
  (50000, 'Axa'),
  (50001, 'Allianz'),
  (50002, 'MAIF'),
  (50003, 'Groupama');

INSERT INTO Risque VALUES
  ('AUTO', 'automobile'),
  ('HAB',  'habitation'),
  ('SAN',  'santé');

INSERT INTO Expert VALUES
  (40200, 'Dubois'),
  (40201, 'Leroy'),
  (40202, 'Moreau');

INSERT INTO Annee VALUES
  (2026),
  (2027);

-- Julie Lambert (10105) n'a pas de contrat
INSERT INTO Client VALUES
  (10100, 'Dupont',  'Camille', '12 rue des Lilas',                    '+33601020304', 'camille@mail.fr', 20500),
  (10101, 'Haddad',  'Yasmine', '8 avenue du Prado, Marseille',         '+33611223344', 'yasmine.haddad@mail.fr', 20500),
  (10102, 'Garcia',  'Lucas',   '25 cours Julien, Marseille',           '+33622334455', 'lucas.garcia@mail.fr',   20501),
  (10103, 'Nguyen',  'Linh',    '3 boulevard Longchamp, Marseille',     '+33633445566', 'linh.nguyen@mail.fr',    20501),
  (10104, 'Rossi',   'Marco',   '17 rue de la Republique, Aix-en-Provence', '+33644556677', 'marco.rossi@mail.fr', 20502),
  (10105, 'Lambert', 'Julie',   '40 rue Paradis, Marseille',            '+33655667788', 'julie.lambert@mail.fr',  20502);

INSERT INTO Contrat VALUES
  (9001004501, '2026-05-14',  450.50, 0.100, 10100, 50000, 'AUTO'),
  (9001004502, '2026-02-03',  780.00, 0.080, 10100, 50001, 'HAB'),
  (9001004503, '2026-03-20', 1200.00, 0.120, 10101, 50002, 'SAN'),
  (9001004504, '2026-06-01',  520.00, 0.100, 10101, 50000, 'AUTO'),
  (9001004505, '2026-01-15',  640.00, 0.090, 10102, 50001, 'AUTO'),
  (9001004506, '2026-04-10',  300.00, 0.150, 10102, 50002, 'HAB'),
  (9001004507, '2026-07-07',  950.00, 0.110, 10103, 50000, 'SAN'),
  (9001004508, '2026-08-22',  410.00, 0.100, 10104, 50001, 'AUTO'),
  (9001004509, '2026-09-05',  700.00, 0.080, 10104, 50002, 'HAB');

-- NumSinistre, DateSurvenue, DateDeclaration, EtatSinistre, DateMission, DateRapport,
-- MontantDommages, DateIndemnisation, MontantIndemnise, NumContrat, NumExpert
INSERT INTO Sinistre VALUES
  (3004500120, '2026-10-08', '2026-10-10', 'indemnisé', '2026-10-12', '2026-10-25', 1250.00, '2026-10-26', 1000.00, 9001004501, 40200),
  (3004500121, '2026-03-15', '2026-03-18', 'indemnisé', '2026-03-20', '2026-04-02', 2300.00, '2026-04-10', 2000.00, 9001004502, 40201),
  (3004500122, '2026-06-12', '2026-06-20', 'refusé',    '2026-06-25', '2026-07-10',  150.00, NULL,         NULL,    9001004503, 40202),
  (3004500123, '2026-05-02', '2026-05-05', 'indemnisé', '2026-05-08', '2026-05-20',  890.00, '2026-05-28',  890.00, 9001004505, 40200),
  (3004500124, '2026-09-18', '2026-09-20', 'en cours d''expertise', '2026-09-25', NULL, NULL, NULL, NULL, 9001004506, 40201),
  (3004500125, '2026-09-30', '2026-10-02', 'déclaré',   NULL,         NULL,         NULL,   NULL,         NULL,    9001004508, NULL),
  (3004500126, '2026-08-14', '2026-08-20', 'en cours d''expertise', '2026-08-25', '2026-09-15', 1800.00, NULL, NULL, 9001004504, 40202),
  (3004500127, '2026-12-30', '2027-01-04', 'déclaré',   NULL,         NULL,         NULL,   NULL,         NULL,    9001004509, NULL),
  (3004500128, '2026-09-01', '2026-09-03', 'indemnisé', '2026-09-05', '2026-09-12',  300.00, '2026-09-20',  250.00, 9001004501, 40200);
-- le sinistre 3004500127 sert de test : survenu en 2026 mais declare en 2027

INSERT INTO Objectif VALUES
  (20500, 'AUTO', 2026, 50), (20500, 'HAB', 2026, 30), (20500, 'SAN', 2026, 20),
  (20501, 'AUTO', 2026, 40), (20501, 'HAB', 2026, 25), (20501, 'SAN', 2026, 15),
  (20502, 'AUTO', 2026, 35), (20502, 'HAB', 2026, 20), (20502, 'SAN', 2026, 10),
  (20500, 'AUTO', 2027, 55), (20500, 'HAB', 2027, 35), (20500, 'SAN', 2027, 25),
  (20501, 'AUTO', 2027, 45), (20501, 'HAB', 2027, 30), (20501, 'SAN', 2027, 20),
  (20502, 'AUTO', 2027, 40), (20502, 'HAB', 2027, 25), (20502, 'SAN', 2027, 15);

-- =========================
-- Les 3 requetes demandees
-- =========================

-- Requête 1 : liste des contrats du client 10100, avec le risque couvert et le montant de la prime
SELECT c.NumContrat, r.LibelleRisque, c.MontantPrime
FROM Contrat c
JOIN Risque r ON r.CodeRisque = c.CodeRisque
WHERE c.NumClient = 10100
ORDER BY c.NumContrat;

-- Résultat requête 1 :
-- NumContrat  LibelleRisque  MontantPrime
-- ----------  -------------  ------------
-- 9001004501  automobile     450.5
-- 9001004502  habitation     780.0

-- Requête 2 : montant total versé au client 10100 pour ses sinistres indemnisés
SELECT cl.NumClient, cl.NomClient, cl.PrenomClient,
       COALESCE(SUM(s.MontantIndemnise), 0) AS TotalVerse
FROM Client cl
LEFT JOIN Contrat c  ON c.NumClient = cl.NumClient
LEFT JOIN Sinistre s ON s.NumContrat = c.NumContrat AND s.EtatSinistre = 'indemnisé'
WHERE cl.NumClient = 10100
GROUP BY cl.NumClient, cl.NomClient, cl.PrenomClient;

-- Résultat requête 2 :
-- NumClient  NomClient  PrenomClient  TotalVerse
-- ---------  ---------  ------------  ----------
-- 10100      Dupont     Camille       3250.0

-- Requête 3 : nombre de sinistres déclarés en 2026 pour chaque type de risque
SELECT r.CodeRisque, r.LibelleRisque, COUNT(s.NumSinistre) AS NbSinistres
FROM Risque r
LEFT JOIN Contrat c  ON c.CodeRisque = r.CodeRisque
LEFT JOIN Sinistre s ON s.NumContrat = c.NumContrat
                    AND s.DateDeclaration >= '2026-01-01'
                    AND s.DateDeclaration <  '2027-01-01'
GROUP BY r.CodeRisque, r.LibelleRisque
ORDER BY r.CodeRisque;

-- Résultat requête 3 :
-- CodeRisque  LibelleRisque  NbSinistres
-- ----------  -------------  -----------
-- AUTO        automobile     5
-- HAB         habitation     2
-- SAN         santé          1

-- =========================
-- Requetes de test
-- =========================

-- Test 1 : montant total versé à chaque client
SELECT cl.NumClient, cl.NomClient, COALESCE(SUM(s.MontantIndemnise), 0) AS TotalVerse
FROM Client cl
LEFT JOIN Contrat c  ON c.NumClient = cl.NumClient
LEFT JOIN Sinistre s ON s.NumContrat = c.NumContrat AND s.EtatSinistre = 'indemnisé'
GROUP BY cl.NumClient, cl.NomClient
ORDER BY cl.NumClient;

-- Résultat test 1 :
-- NumClient  NomClient  TotalVerse
-- ---------  ---------  ----------
-- 10100      Dupont     3250.0
-- 10101      Haddad     0
-- 10102      Garcia     890.0
-- 10103      Nguyen     0
-- 10104      Rossi      0
-- 10105      Lambert    0

-- Test 2 : nombre de sinistres survenus en 2026 pour chaque type de risque (comme la requête 3, mais avec DateSurvenue, voir H8)
SELECT r.CodeRisque, COUNT(s.NumSinistre) AS NbSinistres
FROM Risque r
LEFT JOIN Contrat c  ON c.CodeRisque = r.CodeRisque
LEFT JOIN Sinistre s ON s.NumContrat = c.NumContrat
                    AND s.DateSurvenue >= '2026-01-01'
                    AND s.DateSurvenue <  '2027-01-01'
GROUP BY r.CodeRisque
ORDER BY r.CodeRisque;

-- Résultat test 2 :
-- CodeRisque  NbSinistres
-- ----------  -----------
-- AUTO        5
-- HAB         3
-- SAN         1

-- Test 3 : nombre de sinistres dans chaque état
SELECT EtatSinistre, COUNT(*) AS NbSinistres
FROM Sinistre
GROUP BY EtatSinistre;

-- Résultat test 3 :
-- EtatSinistre          NbSinistres
-- --------------------  -----------
-- déclaré               2
-- en cours d'expertise  2
-- indemnisé             4
-- refusé                1

-- Test 4 : commission en euros de chaque contrat (MontantPrime x TauxCommission)
SELECT co.NomCourtier, ct.NumContrat, ROUND(ct.MontantPrime * ct.TauxCommission, 2) AS CommissionEuros
FROM Contrat ct
JOIN Client cl   ON cl.NumClient = ct.NumClient
JOIN Courtier co ON co.NumCourtier = cl.NumCourtier
ORDER BY co.NumCourtier, ct.NumContrat;

-- Résultat test 4 :
-- NomCourtier  NumContrat  CommissionEuros
-- -----------  ----------  ---------------
-- Martin       9001004501  45.05
-- Martin       9001004502  62.4
-- Martin       9001004503  144.0
-- Martin       9001004504  52.0
-- Bernard      9001004505  57.6
-- Bernard      9001004506  45.0
-- Bernard      9001004507  104.5
-- Petit        9001004508  41.0
-- Petit        9001004509  56.0

-- Test 5 : objectif 2026 de chaque courtier et nombre de contrats signés en 2026
SELECT o.NumCourtier, o.CodeRisque, o.NbContratsVises, COUNT(ct.NumContrat) AS NbSignes
FROM Objectif o
LEFT JOIN Client cl  ON cl.NumCourtier = o.NumCourtier
LEFT JOIN Contrat ct ON ct.NumClient = cl.NumClient
                    AND ct.CodeRisque = o.CodeRisque
                    AND ct.DateSouscription >= '2026-01-01'
                    AND ct.DateSouscription <  '2027-01-01'
WHERE o.AnneeObjectif = 2026
GROUP BY o.NumCourtier, o.CodeRisque, o.NbContratsVises
ORDER BY o.NumCourtier, o.CodeRisque;

-- Résultat test 5 :
-- NumCourtier  CodeRisque  NbContratsVises  NbSignes
-- -----------  ----------  ---------------  --------
-- 20500        AUTO        50               2
-- 20500        HAB         30               1
-- 20500        SAN         20               1
-- 20501        AUTO        40               1
-- 20501        HAB         25               1
-- 20501        SAN         15               1
-- 20502        AUTO        35               1
-- 20502        HAB         20               1
-- 20502        SAN         10               0

-- Test 6 : sinistres survenus avant la souscription de leur contrat
-- (un CHECK ne peut pas vérifier cette règle car elle compare deux tables)
SELECT s.NumSinistre, s.DateSurvenue, c.DateSouscription
FROM Sinistre s
JOIN Contrat c ON c.NumContrat = s.NumContrat
WHERE s.DateSurvenue < c.DateSouscription;

-- Résultat test 6 :
-- (aucune ligne)

-- =========================
-- Tests des contraintes
-- Chaque INSERT est en commentaire : le decommenter pour le tester
-- =========================

-- Test de contrainte 1 : taux de commission supérieur à 1
-- INSERT INTO Contrat VALUES (9001004599, '2026-10-01', 500.00, 1.500, 10100, 50000, 'AUTO');
-- Résultat test de contrainte 1 : Error: CHECK constraint failed: TauxCommission >= 0 AND TauxCommission <= 1

-- Test de contrainte 2 : souscription avant 2026
-- INSERT INTO Contrat VALUES (9001004598, '2025-12-31', 500.00, 0.100, 10100, 50000, 'AUTO');
-- Résultat test de contrainte 2 : Error: CHECK constraint failed: DateSouscription >= '2026-01-01'

-- Test de contrainte 3 : téléphone qui ne respecte pas le format +33 suivi de 9 chiffres
-- INSERT INTO Client VALUES (10199, 'Test', 'Client', '1 rue du Test, Marseille', '0601020304', 'test@mail.fr', 20500);
-- Résultat test de contrainte 3 : Error: CHECK constraint failed: TelClient GLOB '+33[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'

-- Test de contrainte 4 : déclaration avant la survenue
-- INSERT INTO Sinistre VALUES (3004500199, '2026-10-10', '2026-10-05', 'déclaré', NULL, NULL, NULL, NULL, NULL, 9001004501, NULL);
-- Résultat test de contrainte 4 : Error: CHECK constraint failed: Ck_Decl_Survenue

-- Test de contrainte 5 : déclaration plus de 30 jours après la survenue
-- INSERT INTO Sinistre VALUES (3004500198, '2026-08-01', '2026-09-15', 'déclaré', NULL, NULL, NULL, NULL, NULL, 9001004501, NULL);
-- Résultat test de contrainte 5 : Error: CHECK constraint failed: Ck_Decl_30j

-- Test de contrainte 6 : état indemnisé mais pas de montant indemnisé
-- INSERT INTO Sinistre VALUES (3004500197, '2026-10-01', '2026-10-02', 'indemnisé', '2026-10-03', '2026-10-04', 500.00, '2026-10-05', NULL, 9001004501, 40200);
-- Résultat test de contrainte 6 : Error: CHECK constraint failed: Ck_Etat_Coherent

-- Test de contrainte 7 : deux objectifs pour le même courtier, le même risque et la même année
-- INSERT INTO Objectif VALUES (20500, 'AUTO', 2026, 99);
-- Résultat test de contrainte 7 : Error: UNIQUE constraint failed: Objectif.NumCourtier, Objectif.CodeRisque, Objectif.AnneeObjectif

-- Test de contrainte 8 : contrat pour un client qui n'existe pas
-- INSERT INTO Contrat VALUES (9001004597, '2026-10-01', 500.00, 0.100, 99999, 50000, 'AUTO');
-- Résultat test de contrainte 8 : Error: FOREIGN KEY constraint failed
