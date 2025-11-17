# Projet BAN - Base Adresse Nationale

## 📋 Description

Ce projet Docker permet d'importer et de normaliser un fichier CSV de la Base Adresse Nationale (BAN) dans une base de données PostgreSQL. Le système crée automatiquement une structure de base de données normalisée avec des tables pour les communes, voies, adresses, etc.

## 🚀 Démarrage rapide

### Prérequis

- Docker et Docker Compose installés sur votre machine
- Port 5432 disponible (ou modifier le port dans `docker-compose.yml`)

### Installation et initialisation

1. **Cloner ou télécharger le projet**

```bash
cd dockerBanSimplon
```

2. **Démarrer le conteneur PostgreSQL**

```bash
docker-compose up
```

Le conteneur va :

- Créer la base de données `ban_schooldocker`
- Exécuter automatiquement le script `init.sql`
- Importer les données depuis `adresses-92.csv`
- Créer toutes les tables normalisées

**⏱️ Temps d'attente** : L'import peut prendre quelques minutes selon la taille du fichier CSV.

3. **Vérifier que tout fonctionne**

Attendez de voir dans les logs :

```
postgres_db  | CREATE TABLE
postgres_db  | COPY [nombre de lignes]
```

Si vous voyez des erreurs, consultez la section [Dépannage](#-dépannage).

## Réinitialiser la base de données

Si vous modifiez le script `init.sql` ou si vous voulez réimporter les données :

```bash
docker-compose down -v
docker-compose up
```

⚠️ **Attention** : `-v` supprime le volume et toutes les données. La base sera recréée à zéro.

## 🔌 Connexion à la base de données

### Paramètres de connexion

| Paramètre    | Valeur             |
| ------------ | ------------------ |
| **Host**     | `localhost`        |
| **Port**     | `5432`             |
| **Database** | `ban_schooldocker` |
| **User**     | `postgres`         |
| **Password** | `postgres`         |

### Connexion avec psql (ligne de commande)

```bash
psql -h localhost -p 5432 -U postgres -d ban_schooldocker
```

### Connexion avec un client graphique

Utilisez un outil comme **pgAdmin**, **DBeaver** ou **TablePlus** avec les paramètres ci-dessus.

## 🧪 Tester le projet

### 1. Vérifier que les données sont importées

```sql
-- Compter le nombre d'adresses dans la table de staging
SELECT COUNT(*) FROM newtable;

-- Compter les communes
SELECT COUNT(*) FROM commune;

-- Compter les voies
SELECT COUNT(*) FROM voie;

-- Compter les adresses normalisées
SELECT COUNT(*) FROM adresse;
```

````sql
-- Lister les 10 premières communes
SELECT code_insee, nom_commune, code_poqtal
FROM commune
LIMIT 10;

-- Trouver toutes les adresses d'une commune (ex: Bagneux)
SELECT a.numero, a.rep, v.nom_voie, c.nom_commune, c.code_postal
FROM adresse a
JOIN voie v ON a.id_voie = v.id
JOIN commune c ON v.id_commune = c.id
WHERE c.nom_commune = 'Bagneux'
LIMIT 20;

-- Compter les adresses par commune
SELECT c.nom_commune, COUNT(a.id_adresse) as nb_adresses
FROM commune c
LEFT JOIN voie v ON c.id = v.id_commune
LEFT JOIN adresse a ON v.id = a.id_voie
GROUP BY c.nom_commune
ORDER BY nb_adresses DESC
LIMIT 10;

-- Rechercher une voie spécifique
SELECT v.nom_voie, c.nom_commune, COUNT(a.id_adresse) as nb_adresses
FROM voie v
JOIN commune c ON v.id_commune = c.id
LEFT JOIN adresse a ON v.id = a.id_voie
WHERE v.nom_voie ILIKE '%rue%'
GROUP BY v.nom_voie, c.nom_commune
ORDER BY nb_adresses DESC
LIMIT 10;
``` -->

### 2. Requêtes de test

```sql

-- 1 Lister toutes les adresses d’une commune donnée (triées par numéro)

SELECT
    adresse.id_adresse,
    voie.nom_voie,
    adresse.numero,
    adresse.rep,
    adresse.lat,
    adresse.lon
FROM adresse
JOIN voie ON adresse.id_voie = voie.id
JOIN commune ON voie.id_commune = commune.id
WHERE commune.nom_commune = 'Nanterre'
ORDER BY voie.nom_voie, adresse.numero;

-- 2 Compter le nombre d’adresses par commune et type de voie
SELECT
    commune.nom_commune,
    COUNT(adresse.id_adresse) AS nombre_adresses
FROM adresse
JOIN voie ON adresse.id_voie = voie.id
JOIN commune ON voie.id_commune = commune.id
GROUP BY commune.nom_commune
ORDER BY nombre_adresses DESC;


-- 3 Lister les communes distinctes
SELECT DISTINCT nom_commune
FROM commune
ORDER BY nom_commune;

-- 4 Rechercher toutes les adresses contenant un mot-clé particulier dans le nom de voie
SELECT
    adresse.id_adresse,
    voie.nom_voie,
    adresse.numero
FROM adresse
JOIN voie ON adresse.id_voie = voie.id
WHERE voie.nom_voie ILIKE '%motclé%';
````

### 3. Vérifier l'intégrité des données

```sql
-- Vérifier qu'il n'y a pas de doublons dans les communes
SELECT code_insee, COUNT(*)
FROM commune
GROUP BY code_insee
HAVING COUNT(*) > 1;

-- Vérifier les relations entre tables
SELECT
    (SELECT COUNT(*) FROM commune) as nb_communes,
    (SELECT COUNT(*) FROM voie) as nb_voies,
    (SELECT COUNT(*) FROM adresse) as nb_adresses,
    (SELECT COUNT(*) FROM newtable) as nb_lignes_csv;
```

## 📁 Structure du projet

```
dockerBanSimplon/
├── docker-compose.yml          # Configuration Docker
├── README                       # Ce fichier
└── init/
    ├── init.sql                # Script d'initialisation SQL
    ├── adresses-92.csv         # Fichier CSV à importer
    └── data.csv                # Fichier CSV optionnel
```

## 🗄️ Schéma de la base de données

### Table de staging

- **`newtable`** : Table temporaire contenant les données brutes importées depuis le CSV

### Tables normalisées

- **`commune`** : Communes (code INSEE, code postal, nom)
- **`commune_ancienne`** : Anciennes communes fusionnées
- **`voie`** : Voies et rues (nom, code FANTOIR, etc.)
- **`lieu_dit`** : Lieux-dits
- **`cad_parcelle`** : Parcelles cadastrales
- **`adresse`** : Adresses complètes avec coordonnées GPS et relations

### Relations

```
commune (1) ──< (N) commune_ancienne
commune (1) ──< (N) voie
voie (1) ──< (N) adresse
lieu_dit (1) ──< (N) adresse
cad_parcelle (1) ──< (N) adresse
```

## 🛠️ Commandes utiles

### Arrêter le conteneur

```bash
docker-compose stop
```

### Redémarrer le conteneur

```bash
docker-compose restart
```

### Voir les logs

```bash
docker-compose logs -f postgres
```

### Accéder au conteneur

```bash
docker exec -it postgres_db psql -U postgres -d ban_schooldocker
```

## 🐛 Dépannage

### Erreur : "port already in use"

Le port 5432 est déjà utilisé. Modifiez le port dans `docker-compose.yml` :

```yaml
ports:
  - "5433:5432" # Utilisez 5433 au lieu de 5432
```

### Erreur lors de l'import CSV

Si vous voyez des erreurs comme `invalid input syntax for type integer`, vérifiez que :

- L'ordre des colonnes dans `init.sql` correspond à l'ordre dans le CSV
- Le délimiteur est bien `;` (point-virgule)
- Le fichier CSV a bien un en-tête (header)

### Réinitialiser complètement

```bash
docker-compose down -v
docker volume prune -f  # Optionnel : supprime tous les volumes inutilisés
docker-compose up
```

## 📝 Notes importantes

- Le script `init.sql` n'est exécuté qu'une seule fois lors de la création initiale de la base
- Pour réexécuter le script, il faut supprimer le volume avec `docker-compose down -v`
- Le fichier CSV doit avoir un en-tête (header) avec les noms des colonnes
- Le délimiteur utilisé est le point-virgule (`;`)
- Les données sont importées dans `newtable` puis normalisées dans les autres tables

## 📚 Ressources

- [Documentation PostgreSQL](https://www.postgresql.org/docs/)
- [Base Adresse Nationale](https://adresse.data.gouv.fr/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
