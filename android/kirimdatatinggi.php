<?php
include "../koneksi.php";

error_reporting(E_ALL);
ini_set('display_errors', 1);

$nilai_tinggi = filter_input(INPUT_GET, 'nilaiTinggi', FILTER_VALIDATE_FLOAT);
$kode_alat = filter_input(INPUT_GET, 'kode_alat', FILTER_SANITIZE_STRING);

error_log("Updating ketinggian - Kode Alat: $kode_alat, Nilai: $nilai_tinggi");

if ($nilai_tinggi === false || !$kode_alat) {
    echo json_encode(['success' => false, 'message' => 'Parameter tidak valid']);
    exit;
}

$stmt = $conn->prepare("UPDATE alat SET nilai_tinggi = ? WHERE kode_alat = ?");
$stmt->bind_param("ds", $nilai_tinggi, $kode_alat);

if ($stmt->execute()) {
    error_log("Berhasil update nilai ketinggian untuk alat: $kode_alat");
    echo json_encode(['success' => true]);
} else {
    error_log("Gagal update nilai ketinggian: " . $conn->error);
    echo json_encode(['success' => false, 'message' => 'Gagal update data']);
}

$stmt->close();
mysqli_close($conn);
?>