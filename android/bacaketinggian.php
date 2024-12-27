<?php
include "../koneksi.php";

$kode_alat = filter_input(INPUT_GET, 'kode_alat', FILTER_SANITIZE_STRING);

if (!$kode_alat) {
    echo json_encode(['success' => false, 'message' => 'Kode alat diperlukan']);
    exit;
}

$stmt = $conn->prepare("SELECT nilai_tinggi FROM alat WHERE kode_alat = ?");
$stmt->bind_param("s", $kode_alat);
$stmt->execute();
$result = $stmt->get_result();

if ($data = $result->fetch_assoc()) {
    echo json_encode(['success' => true, 'data' => ['ketinggian' => $data['nilai_tinggi']]]);
} else {
    echo json_encode(['success' => false, 'message' => 'Data tidak ditemukan']);
}

$stmt->close();
mysqli_close($conn);
?>