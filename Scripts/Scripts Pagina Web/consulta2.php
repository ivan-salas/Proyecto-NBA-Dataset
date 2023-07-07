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
                <th> Num Equipos </th>
                <th> Temporadas </th>
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
            $variable1=$_GET['temporada1'];
            $variable2=$_GET['temporada2'];
            $stmt = $pdo->prepare(
                'SELECT p.PLAYER_NAME, COUNT(DISTINCT t.NICKNAME) AS EQUIPOS, ARRAY_AGG(DISTINCT g.SEASON) AS TEMPORADAS
                FROM nbainfo.player_materialized p
                LEFT JOIN nbainfo.plays_materialized pl ON p.PLAYER_ID = pl.PLAYER_ID
                LEFT JOIN nbainfo.team_materialized t ON pl.TEAM_ID = t.TEAM_ID
                LEFT JOIN nbainfo.game_materialized g ON pl.GAME_ID = g.GAME_ID
                WHERE g.SEASON IN (:temporada1, :temporada2)
                GROUP BY p.PLAYER_NAME
                HAVING COUNT(DISTINCT t.NICKNAME) > 1
                ORDER BY EQUIPOS DESC'
            );
            $stmt->execute(['temporada1' => $variable1, 'temporada2' => $variable2]);
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
