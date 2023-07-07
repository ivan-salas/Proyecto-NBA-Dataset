<!DOCTYPE html>
<html>
    <head>
        <script src=http://html5shiv.googlecode.com/svn/trunk/html5.js ></script>
    </head>
<body>
    <?php
        echo "<table>";
        echo "<tr>
                <th> Nombre Jugador </th>
                <th> Intentos Tiros libres </th>
                <th> Tiros libres Exitosos </th>
		<th> Porcentaje de Acierto </th>
		<th> Temporada </th>
              </tr>";
        
        class TableRows extends RecursiveIteratorIterator {
            function __construct($it) {
                parent::__construct($it, self::LEAVES_ONLY);
            }
            function current() {
                return "<td>" . parent::current(). "</td>";
            }
            function beginChildren() {
                echo "<tr>";
            }
            function endChildren() {
                echo "</tr>" . "\n";
            }    
        }

        try {
            $pdo = new PDO('pgsql:
                            host=localhost;
                            port=5432;
                            dbname=cc3201;
                            user=webuser;
                            password=contrasena');
            $variable1=$_GET['temporada'];
            $stmt = $pdo->prepare(
                'SELECT p.PLAYER_NAME,
                SUM(pl.FREE_THROWS_ATTEMPTED) AS TIROS_LIBRES_ATTEMPTED,
                SUM(pl.FREE_THROWS_SUCCESSFUL) AS TIROS_LIBRES_SUCCESSFUL,
                CASE
                    WHEN SUM(pl.FREE_THROWS_ATTEMPTED) = 0 THEN NULL
                    ELSE 100 * (CAST(SUM(pl.FREE_THROWS_SUCCESSFUL) AS FLOAT) / NULLIF(SUM(pl.FREE_THROWS_ATTEMPTED), 0))
                END AS PORCENTAJE,
                ARRAY_AGG(DISTINCT g.SEASON) AS TEMPORADA
                FROM nbainfo.player_materialized p
                LEFT JOIN nbainfo.plays_materialized pl ON p.PLAYER_ID = pl.PLAYER_ID
                LEFT JOIN nbainfo.game_materialized g ON pl.GAME_ID = g.GAME_ID
                WHERE g.SEASON = :temporada
                GROUP BY p.PLAYER_NAME
                HAVING SUM(pl.FREE_THROWS_ATTEMPTED) > 0
                ORDER BY TIROS_LIBRES_ATTEMPTED DESC'
            );
            $stmt->execute(['temporada' => $variable1]);
            $result = $stmt->setFetchMode(PDO::FETCH_ASSOC);
            
            foreach(new TableRows(new RecursiveArrayIterator($stmt->fetchAll())) as $k=>$v) {
                echo $v;
            }
        }
        catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
        }
        echo "</table>";
    ?>
</body>
</html>
