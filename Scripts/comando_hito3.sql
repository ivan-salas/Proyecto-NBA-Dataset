/*1.- CREACION DE LA TABLA DE PLAYER CRUDA*/
CREATE TABLE player_raw (
    PLAYER_NAME VARCHAR(255),
    PLAYER_ID BIGINT,
    SEASON INT
);

COPY player_raw FROM '/home/cc3201/player_recortado.csv' DELIMITER ';' CSV HEADER;

/*CREACION DE TABLA PLAYER PARA GUARDAR LOS DATOS FILTRADOS*/
CREATE TABLE player (
    PLAYER_NAME VARCHAR(255),
    PLAYER_ID BIGINT,
    SEASON INT,
    PRIMARY KEY (PLAYER_ID)
);

-- INSERT INTO player (player_name, player_id, season)
-- SELECT DISTINCT player_name, player_id, season
-- FROM player_raw
-- ;

INSERT INTO player (player_name, player_id, season)
SELECT DISTINCT ON (player_id)
  player_name, player_id, season
FROM player_raw
ORDER BY player_id, season DESC;

/*2.- CREACION DE LA TABLA TEAM */
CREATE TABLE team (
    LEAGUE_ID INTEGER,
    TEAM_ID BIGINT UNIQUE,
    NICKNAME VARCHAR(255),
    CITY VARCHAR(255),
    ARENA VARCHAR(255),
    PRIMARY KEY (TEAM_ID)
);

COPY team FROM '/home/cc3201/team_recortado.csv' DELIMITER ';' CSV HEADER;

/*CREACION DE LA TABLA GAME CRUDA */
/*game_raw tiene 26.651 tuplas*/
CREATE TABLE game_raw (
    GAME_DATE_EST VARCHAR(255),
    GAME_ID BIGINT,
    HOME_TEAM_ID BIGINT,
    VISITOR_TEAM_ID BIGINT,
    SEASON INT,
    POINTS_HOME INT,
    POINTS_AWAY INT,
    HOME_TEAM_WINS INT
);

COPY game_raw FROM '/home/cc3201/game_recortado.csv' DELIMITER ';' CSV HEADER;

/*3.- CREACION DE LA TABLA GAME PARA GUARDAR LOS DATOS FILTRADOS */
CREATE TABLE game (
    GAME_DATE_EST DATE,
    GAME_ID BIGINT,
    HOME_TEAM_ID BIGINT,
    VISITOR_TEAM_ID BIGINT,
    SEASON VARCHAR(255),
    POINTS_HOME INT,
    POINTS_AWAY INT,
    HOME_TEAM_WINS INT,
    PRIMARY KEY (GAME_ID)
);
/*game tiene 26.622*/

INSERT INTO game (GAME_DATE_EST, GAME_ID, HOME_TEAM_ID, VISITOR_TEAM_ID, SEASON, POINTS_HOME, POINTS_AWAY, HOME_TEAM_WINS)
SELECT DISTINCT TO_DATE(GAME_DATE_EST, 'DD-MM-YYYY'), GAME_ID, HOME_TEAM_ID, VISITOR_TEAM_ID, SEASON, POINTS_HOME, POINTS_AWAY, HOME_TEAM_WINS
FROM game_raw
;

/*4.- CREACION DE LA TABLA PLAYS CRUDA */
CREATE TABLE plays_raw (
    GAME_ID BIGINT ,
    TEAM_ID BIGINT,
    GAME_CITY VARCHAR(255),
    PLAYER_ID BIGINT,
    FREE_THROWS_SUCCESSFUL INT,
    FREE_THROWS_ATTEMPTED INT,
    PLAYER_POINTS INT
);

COPY plays_raw FROM '/home/cc3201/plays_recortado.csv' DELIMITER ';' CSV HEADER;

-- plays_raw tiene 668.628 tuplas

/*CREACION DE LA TABLA PLAYS PARA GUARDAR LOS DATOS FILTRADOS */

CREATE TABLE plays (
    GAME_ID BIGINT ,
    TEAM_ID BIGINT,
    GAME_CITY VARCHAR(255),
    PLAYER_ID BIGINT,
    FREE_THROWS_SUCCESSFUL INT,
    FREE_THROWS_ATTEMPTED INT,
    PLAYER_POINTS INT,
    FOREIGN KEY (GAME_ID) REFERENCES game(GAME_ID),
    FOREIGN KEY (TEAM_ID) REFERENCES team(TEAM_ID),
    FOREIGN KEY (PLAYER_ID) REFERENCES player(PLAYER_ID),
    PRIMARY KEY (GAME_ID, TEAM_ID, PLAYER_ID)  
);

INSERT INTO plays (GAME_ID, TEAM_ID, GAME_CITY, PLAYER_ID, FREE_THROWS_SUCCESSFUL, FREE_THROWS_ATTEMPTED, PLAYER_POINTS)
SELECT DISTINCT pr.GAME_ID, pr.TEAM_ID, pr.GAME_CITY, pr.PLAYER_ID, pr.FREE_THROWS_SUCCESSFUL, pr.FREE_THROWS_ATTEMPTED, pr.PLAYER_POINTS
FROM plays_raw pr
LEFT JOIN player p ON pr.PLAYER_ID = p.PLAYER_ID
WHERE p.PLAYER_ID IS NOT NULL;


---------------------------------------------
/*SECCION DE CONSULTAS A LA BASE DE DATOS*/
---------------------------------------------

-- PRIMERA CONSULTA
/*
En que ciudades [GAME_CITY] ha marcado un equipo [NICKNAME] y cuántos puntos ha marcado en cada ciudad (hay que ver [PTS_home] o [PTS_away] dependiendo si era local o visita ) ? 
Donde [NICKNAME] es un input del usuario, el parametro [NICKNAME] se encuentra registrado en la tabla "team"
Donde [GAME_CITY] corresponde a las ciudades de los juegos, [GAME_CITY] se encuentra registrado en la tabla "plays"
Donde [PTS_home] y [PTS_away] corresponden a los puntos del local y del visitante, se encuentran en la tabla "game"

Cabe destacar solo el [NICKNAME] será el input del usuario.
Deberiamos buscar todos los juegos en las distintas ciudades donde ha jugado el equipo con ese nickname
Luego ver si fue local o visitante para finalmente contabilizar dichos puntos. 
*/
SELECT t.NICKNAME, p.GAME_CITY, SUM(g.POINTS_HOME) AS PUNTOS
FROM team t
LEFT JOIN game g ON t.TEAM_ID = g.HOME_TEAM_ID
LEFT JOIN plays p ON g.GAME_ID = p.GAME_ID
WHERE t.NICKNAME = 'Bulls'
GROUP BY t.NICKNAME, p.GAME_CITY
ORDER BY PUNTOS DESC;

/*
Analisis de tiempo de ejecucion de la primera consulta:
    Se utiliza EXPLAIN ANALYZE para ver el tiempo de ejecucion de la consulta
    Se usa NICKNAME igual a 'Bulls' solo como ejemplo para ver el tiempo de ejecucion
    Planning Time: 1.987 ms
    Execution Time: 122.906 ms
*/

-- SEGUNDA CONSULTA
/*
¿Qué jugadores participaron en más de un equipo para las temporadas: [temporada1] y [temporada2]? 
Donde [temporada1] y [temporada2] son los parámetros dados
Las temporadas estan guardadas como SEASON en la tabla "game" 
*/
SELECT p.PLAYER_NAME, COUNT(DISTINCT t.NICKNAME) AS EQUIPOS, ARRAY_AGG(DISTINCT g.SEASON) AS TEMPORADAS
FROM player p
LEFT JOIN plays pl ON p.PLAYER_ID = pl.PLAYER_ID
LEFT JOIN team t ON pl.TEAM_ID = t.TEAM_ID
LEFT JOIN game g ON pl.GAME_ID = g.GAME_ID
WHERE g.SEASON IN ('2019', '2018')
GROUP BY p.PLAYER_NAME
HAVING COUNT(DISTINCT t.NICKNAME) > 1
ORDER BY EQUIPOS DESC;

/*
Analisis de tiempo de ejecucion de la segunda consulta:
    Se utiliza EXPLAIN ANALYZE para ver el tiempo de ejecucion de la consulta
    Se usa temporadas igual a '2019' y '2018' solo como ejemplo para ver el tiempo de ejecucion
    Planning Time: 0.773 ms
    Execution Time: 1538.832 ms
*/

-- TERCERA CONSULTA
/*
¿Qué jugadores intentaron tiros libres [FREE_THROWS_ATTEMPTED] y el porcentaje de tiros libres correctamente hechos  para [temporada]? 
Donde [temporada] es el parámetro dado por el usuario
[FREE_THROWS_ATTEMPTED] se encuentran en la tabla "plays"
El porcentaje de tiros libres correctamente hechos habria que calcularlo como 100*( [FREE_THROWS_SUCCESSFUL]/[FREE_THROWS_ATTEMPTED] )
*/
SELECT p.PLAYER_NAME,
       SUM(pl.FREE_THROWS_ATTEMPTED) AS TIROS_LIBRES_ATTEMPTED,
       SUM(pl.FREE_THROWS_SUCCESSFUL) AS TIROS_LIBRES_SUCCESSFUL,
       CASE
           WHEN SUM(pl.FREE_THROWS_ATTEMPTED) = 0 THEN NULL
           ELSE 100 * (CAST(SUM(pl.FREE_THROWS_SUCCESSFUL) AS FLOAT) / NULLIF(SUM(pl.FREE_THROWS_ATTEMPTED), 0))
       END AS PORCENTAJE,
       ARRAY_AGG(DISTINCT g.SEASON) AS TEMPORADA
FROM player p
LEFT JOIN plays pl ON p.PLAYER_ID = pl.PLAYER_ID
LEFT JOIN game g ON pl.GAME_ID = g.GAME_ID
WHERE g.SEASON = '2019'
GROUP BY p.PLAYER_NAME
HAVING SUM(pl.FREE_THROWS_ATTEMPTED) > 0
ORDER BY TIROS_LIBRES_ATTEMPTED DESC;

/*
Analisis de tiempo de ejecucion de la tercera consulta:
    Se utiliza EXPLAIN ANALYZE para ver el tiempo de ejecucion de la consulta
    Se usa temporada igual a '2019' solo como ejemplo para ver el tiempo de ejecucion
    Planning Time: 0.869 ms
    Execution Time: 1159.023 ms
*/


---------------------------------------------
/*SECCION DE OPTIMIZACION DE CONSULTAS A LA BASE DE DATOS*/
---------------------------------------------
-- CREAMOS VISTAS MATERIALIZADA PARA TODAS LAS TABLAS Y ASÍ OPTIMIZAR LAS CONSULTAS
--1. VISTA MATERIALIZADA DE LA TABLA TEAM
CREATE MATERIALIZED VIEW nbainfo.team_materialized
AS
SELECT *
FROM team;

--Le añadimos un indice a la vista materializada al atributo que era llave primaria en la tabla original
CREATE UNIQUE INDEX team_materialized_pkey ON nbainfo.team_materialized (TEAM_ID);

--2. VISTA MATERIALIZADA DE LA TABLA PLAYER
CREATE MATERIALIZED VIEW nbainfo.player_materialized
AS
SELECT *
FROM player;

--Le añadimos un indice a la vista materializada al atributo que era llave primaria en la tabla original
CREATE UNIQUE INDEX player_materialized_pkey ON nbainfo.player_materialized (PLAYER_ID);

--3. VISTA MATERIALIZADA DE LA TABLA GAME
CREATE MATERIALIZED VIEW nbainfo.game_materialized
AS
SELECT *
FROM game;

--Le añadimos un indice a la vista materializada al atributo que era llave primaria en la tabla original
CREATE UNIQUE INDEX game_materialized_pkey ON nbainfo.game_materialized (GAME_ID);

--4. VISTA MATERIALIZADA DE LA TABLA PLAYS
CREATE MATERIALIZED VIEW nbainfo.plays_materialized
AS
SELECT *
FROM plays;

--Le añadimos un indice a la vista materializada al atributo que era llave primaria en la tabla original
CREATE UNIQUE INDEX plays_materialized_pkey ON nbainfo.plays_materialized (GAME_ID, TEAM_ID, PLAYER_ID);

-------------------------------------------
/*ANALISIS TIEMPO DE VISTAS MATERIALIZADAS
    Ahora vamos a ejecutar las mismas tres consultas anteriores pero sobre las vistas materializadas de las tablas
    Y veremos con EXPLAIN ANALYZE si mejoraron los tiempos de ejecucion y/o planificacion
*/
-------------------------------------------

-- PRIMERA CONSULTA CON VISTAS MATERIALIZADAS
EXPLAIN ANALYZE
SELECT t.NICKNAME, p.GAME_CITY, SUM(g.POINTS_HOME) AS PUNTOS
FROM team_materialized t
LEFT JOIN game_materialized g ON t.TEAM_ID = g.HOME_TEAM_ID
LEFT JOIN plays_materialized p ON g.GAME_ID = p.GAME_ID
WHERE t.NICKNAME = 'Bulls'
GROUP BY t.NICKNAME, p.GAME_CITY
ORDER BY PUNTOS DESC;

/*
Analisis de tiempo de ejecucion de la primera consulta:
    Se utiliza EXPLAIN ANALYZE para ver el tiempo de ejecucion de la consulta
    Se usa NICKNAME igual a 'Bulls' solo como ejemplo para ver el tiempo de ejecucion

    TIEMPOS ORIGINALES:
        Planning Time: 1.987 ms
        Execution Time: 122.906 ms

    TIEMPOS CON VISTAS MATERIALIZADAS:
        Planning Time: 0.481 ms
        Execution Time: 121.695 ms
*/

-- SEGUNDA CONSULTA CON VISTAS MATERIALIZADAS
EXPLAIN ANALYZE
SELECT p.PLAYER_NAME, COUNT(DISTINCT t.NICKNAME) AS EQUIPOS, ARRAY_AGG(DISTINCT g.SEASON) AS TEMPORADAS
FROM player_materialized p
LEFT JOIN plays_materialized pl ON p.PLAYER_ID = pl.PLAYER_ID
LEFT JOIN team_materialized t ON pl.TEAM_ID = t.TEAM_ID
LEFT JOIN game_materialized g ON pl.GAME_ID = g.GAME_ID
WHERE g.SEASON IN ('2019', '2018')
GROUP BY p.PLAYER_NAME
HAVING COUNT(DISTINCT t.NICKNAME) > 1
ORDER BY EQUIPOS DESC;

/*
Analisis de tiempo de ejecucion de la segunda consulta:
    Se utiliza EXPLAIN ANALYZE para ver el tiempo de ejecucion de la consulta
    Se usa temporadas igual a '2019' y '2018' solo como ejemplo para ver el tiempo de ejecucion

    TIEMPOS ORIGINALES:
        Planning Time: 0.773 ms
        Execution Time: 1538.832 ms

    TIEMPOS CON VISTAS MATERIALIZADAS:
        Planning Time: 1.077 ms
        Execution Time: 1540.666 ms
        
*/

-- TERCERA CONSULTA CON VISTAS MATERIALIZADAS
EXPLAIN ANALYZE
SELECT p.PLAYER_NAME,
       SUM(pl.FREE_THROWS_ATTEMPTED) AS TIROS_LIBRES_ATTEMPTED,
       SUM(pl.FREE_THROWS_SUCCESSFUL) AS TIROS_LIBRES_SUCCESSFUL,
       CASE
           WHEN SUM(pl.FREE_THROWS_ATTEMPTED) = 0 THEN NULL
           ELSE 100 * (CAST(SUM(pl.FREE_THROWS_SUCCESSFUL) AS FLOAT) / NULLIF(SUM(pl.FREE_THROWS_ATTEMPTED), 0))
       END AS PORCENTAJE,
       ARRAY_AGG(DISTINCT g.SEASON) AS TEMPORADA
FROM player_materialized p
LEFT JOIN plays_materialized pl ON p.PLAYER_ID = pl.PLAYER_ID
LEFT JOIN game_materialized g ON pl.GAME_ID = g.GAME_ID
WHERE g.SEASON = '2019'
GROUP BY p.PLAYER_NAME
HAVING SUM(pl.FREE_THROWS_ATTEMPTED) > 0
ORDER BY TIROS_LIBRES_ATTEMPTED DESC;

/*
Analisis de tiempo de ejecucion de la tercera consulta:
    Se utiliza EXPLAIN ANALYZE para ver el tiempo de ejecucion de la consulta
    Se usa temporada igual a '2019' solo como ejemplo para ver el tiempo de ejecucion

    TIEMPOS ORIGINALES:
        Planning Time: 0.869 ms
        Execution Time: 1159.023 ms

    TIEMPOS CON VISTAS MATERIALIZADAS:
        Planning Time: 0.910 ms
        Execution Time: 1156.471 ms      
*/

-- Como SEASON es un atributo que se consulta harto, le vamos a añadir un indice a la vista materializada
CREATE INDEX game_materialized_season_idx ON nbainfo.game_materialized (SEASON);

/* RESULTADOS TIEMPOS DE CONSULTAS:
    TIEMPOS ORIGINALES:
        PRIMERA CONSULTA:
            Planning Time: 1.987 ms
            Execution Time: 122.906 ms
        SEGUNDA CONSULTA:
            Planning Time: 0.773 ms
            Execution Time: 1538.832 ms
        TERCERA CONSULTA:
            Planning Time: 0.869 ms
            Execution Time: 1159.023 ms

    TIEMPOS CON VISTAS MATERIALIZADAS CON INDICES EN LLAVES PRIMARIAS SIN INDICE A SEASON:
        PRIMERA CONSULTA:
            Planning Time: 0.481 ms
            Execution Time: 121.695 ms
        SEGUNDA CONSULTA:
            Planning Time: 1.077 ms
            Execution Time: 1540.666 ms
        TERCERA CONSULTA:
            Planning Time: 0.910 ms
            Execution Time: 1156.471 ms

    TIEMPOS CON VISTAS MATERIALIZADAS CON INDICES EN LLAVES PRIMARIAS Y AÑADIR INDICE A SEASON:
        PRIMERA CONSULTA:
            Planning Time: 1.798 ms
            Execution Time: 123.038 ms
        SEGUNDA CONSULTA:
            Planning Time: 1.109 ms
            Execution Time: 1535.320 ms
        TERCERA CONSULTA:
            Planning Time: 1.130 ms
            Execution Time: 1167.330 ms
    
    TIEMPOS CON VISTAS MATERIALIZADAS E INDICES DROPEADOS:
        PRIMERA CONSULTA:
            Planning Time: 0.474 ms
            Execution Time: 936.747 ms
        SEGUNDA CONSULTA:
            Planning Time: 0.517 ms
            Execution Time: 1552.715 ms
        TERCERA CONSULTA:
            Planning Time: 0.426 ms
            Execution Time: 1170.624 ms
*/

















