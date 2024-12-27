<?php
include '../koneksi.php';

$kode = filter_input(INPUT_GET, 'kode', FILTER_SANITIZE_STRING);

$stmt = $conn->prepare("SELECT kode_alat FROM alat WHERE kode_alat = ?");
$stmt->bind_param("s", $kode);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode(["verified" => true]);
} else {
    echo json_encode(["verified" => false]);
}

$stmt->close();
mysqli_close($conn);
?>
