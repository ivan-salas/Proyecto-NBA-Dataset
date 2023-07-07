<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Consulta de Puntos por Equipo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1 {
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #57c757;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Consulta de Puntos por Equipo</h1>

    <?php
    echo "<table>";
    echo "<tr>
            <th>Nickname Equipo</th>
            <th>Ciudad</th>
            <th>Numero de Puntos</th>
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
        $variable1 = $_GET['equipo'];
        $stmt = $pdo->prepare(
            'SELECT t.NICKNAME, p.GAME_CITY, SUM(g.POINTS_HOME) AS PUNTOS
            FROM nbainfo.team_materialized t
            LEFT JOIN nbainfo.game_materialized g ON t.TEAM_ID = g.HOME_TEAM_ID
            LEFT JOIN nbainfo.plays_materialized p ON g.GAME_ID = p.GAME_ID
            WHERE t.NICKNAME = :equipo
            GROUP BY t.NICKNAME, p.GAME_CITY
            ORDER BY PUNTOS DESC'
        );
        $stmt->execute(['equipo' => $variable1]);
        $result = $stmt->setFetchMode(PDO::FETCH_ASSOC);

        foreach (new TableRows(new RecursiveArrayIterator($stmt->fetchAll())) as $k => $v) {
            echo $v;
        }
    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
    echo "</table>";
    ?>
</body>
</html>
