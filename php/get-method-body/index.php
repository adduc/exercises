<h1>$_GET</h1>
<?= var_export($_GET, true) ?>

<h1>$_POST</h1>
<?= var_export($_POST, true) ?>

<h1>Raw Input</h1>
<?= var_export(file_get_contents('php://input'), true) ?>
