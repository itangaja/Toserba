<?php
include '../koneksi.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Debug log
error_log("Received POST data: " . print_r($_POST, true));

$nama = isset($_POST['nama']) ? $_POST['nama'] : '';
$kode_alat = isset($_POST['alat']) ? $_POST['alat'] : '';

if (empty($nama) || empty($kode_alat)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Parameter nama dan kode alat harus diisi'
    ]);
    exit;
}

try {
    // Cek apakah kode alat ada di tabel alat dan sesuai dengan username
    $stmt = $conn->prepare("SELECT * FROM alat WHERE username_member = ? AND kode_alat = ?");
    $stmt->bind_param("ss", $nama, $kode_alat);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Jika data ditemukan, berarti verifikasi berhasil
        echo json_encode([
            'status' => 'success',
            'message' => 'Device berhasil diverifikasi'
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Kode alat tidak sesuai dengan akun Anda'
        ]);
    }
    $stmt->close();

} catch (Exception $e) {
    error_log("Database error: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Terjadi kesalahan pada server: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
