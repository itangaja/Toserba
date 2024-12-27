<?php
include "../koneksi.php";

$kode_alat = filter_input(INPUT_GET, 'kode_alat', FILTER_SANITIZE_STRING);

error_log("Request untuk kode alat: " . $kode_alat); // Debug log

if (!$kode_alat) {
    echo json_encode(['success' => false, 'message' => 'Kode alat diperlukan']);
    exit;
}

$stmt = $conn->prepare("SELECT nilai_keruh FROM alat WHERE kode_alat = ?");
$stmt->bind_param("s", $kode_alat);
$stmt->execute();
$result = $stmt->get_result();
$data = $result->fetch_assoc();

error_log("Data dari database: " . json_encode($data)); // Debug log

if ($data) {
    echo json_encode([
        'success' => true, 
        'data' => [
            'kekeruhan' => floatval($data['nilai_keruh'])
        ]
    ]);
} else {
    echo json_encode([
        'success' => false, 
        'message' => 'Data tidak ditemukan untuk kode alat: ' . $kode_alat
    ]);
}

$stmt->close();
mysqli_close($conn);
?>