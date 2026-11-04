echo '<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8"/>
	<style>
		.table-container {
			max-height: 500px;
			overflow-y: auto;
			border: 1px solid #ccc;
			width: 100%;
		}
		table {
			width: 100%;
			border-collapse: collapse;
		}
		thead th {
			position: sticky;
			top: 0;
			background-color: #f1f1f1;
			z-index: 1;
			border: 2px solid #f04040;
		}
		th, td {
			padding: 10px;
			text-align: left;
			border: 1px solid #888;
		}
		.odd{background:#e8edff;}
	</style>
</head>
<body>
	<p>Запрос формирования таблицы</p>
	<p><code>' >> "$2";
echo "$1" >> "$2";
echo '	</code></p>
<div class="table-container">' >> "$2";
./pghtml "$1" >> "$2";
echo '</div>
</body></html>' >> "$2";
