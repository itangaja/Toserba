<?php

$usernameHost = "root";
$passwordHost = "";
$database = "monitoringairkeruh";

$conn = mysqli_connect("localhost", $usernameHost, $passwordHost, $database);

if (!$conn) {
    die("Koneksi gagal: " . mysqli_connect_error());
}
?>