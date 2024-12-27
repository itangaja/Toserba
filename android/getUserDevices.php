<?php
include '../koneksi.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$username = filter_input(INPUT_GET, 'username', FILTER_SANITIZE_STRING);

$stmt = $conn->prepare("SELECT kode_alat, nilai_keruh, nilai_tinggi FROM alat WHERE username_member = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

$devices = [];
while ($row = $result->fetch_assoc()) {
    $devices[] = $row;
}

echo json_encode([
    'status' => 'success',
    'devices' => $devices
]);

$stmt->close();
mysqli_close($conn);
?> 