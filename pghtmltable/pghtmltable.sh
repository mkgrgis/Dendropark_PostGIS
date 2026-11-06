echo '<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8"/>
	<style>
		.table-container {
			max-height: 700px;
			overflow-y: auto;
			border: 1px solid #ccc;
			width: 100%;
		}
		.objmap {
			height: 250px;
			border: 1px solid #ccc;
			width: 250px;
		}
		table {
			width: 100%;
			border-collapse: collapse;
		}
		thead th {
			position: sticky;
			top: 0;
			background-color: #f1f1f1;
			z-index: 3;
			border: 2px solid #f04040;
		}
		th, td {
			padding: 10px;
			text-align: left;
			border: 1px solid #888;
		}
		th:first-child {
			position: sticky;
			left: 0;
			top: 0;
			background-color: #fff1f1;
			z-index: 4;
		}
		td:first-child {
			position: sticky;
			left: 0;
			top: 0;
			background-color: #f1f1f1;
			z-index: 3;
		}
		.odd{background:#e8edff;}
		.leaflet-container {
			z-index: 0
		}
	</style>
	<link rel="stylesheet" href="leaflet.css" />
</head>
<body>
	<script src="leaflet.js"></script>
	<script src="hexewkb2geojson.js"></script>
	<script>
		const objstyle = { fillOpacity: 0.55, color: "#008800", fillColor: "#000000", weight: 2 };
	</script>
	<p>Запрос формирования таблицы</p>
	<p><code>' >> "$2";
echo "$1" >> "$2";
echo '	</code></p>
<div class="table-container">' >> "$2";
"$(dirname "$0")/pghtmltable" "$1" >> "$2";
echo '</div>
 	<p>Акутально на ' >> "$2";
date +'%Y-%m-%d %H:%M:%S %:z' >> "$2";
echo '</p>
</body></html>' >> "$2";
