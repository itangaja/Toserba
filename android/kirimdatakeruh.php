<?php
include "../koneksi.php";

error_reporting(E_ALL);
ini_set('display_errors', 1);

$nilai_keruh = filter_input(INPUT_GET, 'nilaiKeruh', FILTER_VALIDATE_FLOAT);
$kode_alat = filter_input(INPUT_GET, 'kode_alat', FILTER_SANITIZE_STRING);

error_log("Updating kekeruhan - Kode Alat: $kode_alat, Nilai: $nilai_keruh");

if ($nilai_keruh === false || !$kode_alat) {
    echo json_encode(['success' => false, 'message' => 'Parameter tidak valid']);
    exit;
}

$stmt = $conn->prepare("UPDATE alat SET nilai_keruh = ? WHERE kode_alat = ?");
$stmt->bind_param("ds", $nilai_keruh, $kode_alat);

if ($stmt->execute()) {
    error_log("Berhasil update nilai kekeruhan untuk alat: $kode_alat");
    echo json_encode(['success' => true]);
} else {
    error_log("Gagal update nilai kekeruhan: " . $conn->error);
    echo json_encode(['success' => false, 'message' => 'Gagal update data']);
}

$stmt->close();
mysqli_close($conn);
?>