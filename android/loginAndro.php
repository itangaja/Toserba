<?php
include '../koneksi.php';

// Validasi input
$username = filter_input(INPUT_POST, 'nama', FILTER_SANITIZE_STRING);
$password = filter_input(INPUT_POST, 'password', FILTER_SANITIZE_STRING);
$kodeAlat = filter_input(INPUT_POST, 'alat', FILTER_SANITIZE_STRING);

error_log("Login attempt - Username: $username, Kode Alat: $kodeAlat");

if (!$username || !$password || !$kodeAlat) {
    echo json_encode([
        "status" => "failed",
        "message" => "Semua field harus diisi"
    ]);
    exit;
}

// Update query untuk mengecek relasi user dengan alat
$stmt = $conn->prepare("SELECT m.username, m.password, m.email, a.kode_alat, a.nilai_keruh, a.nilai_tinggi 
                       FROM members m
                       LEFT JOIN alat a ON m.username = a.username_member 
                       WHERE m.username = ? AND a.kode_alat = ?");
$stmt->bind_param("ss", $username, $kodeAlat);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $data = $result->fetch_assoc();
    error_log("Data found: " . json_encode($data));
    
    if (password_verify($password, $data['password'])) {
        // Update username_member di tabel alat
        $update_stmt = $conn->prepare("UPDATE alat SET username_member = ? WHERE kode_alat = ?");
        $update_stmt->bind_param("ss", $username, $kodeAlat);
        $update_stmt->execute();
        $update_stmt->close();
        
        echo json_encode([
            "status" => "success",
            "message" => "Login berhasil",
            "user" => [
                "username" => $data['username'],
                "email" => $data['email'],
                "kode_alat" => $kodeAlat,
                "nilai_keruh" => $data['nilai_keruh'],
                "nilai_tinggi" => $data['nilai_tinggi']
            ]
        ]);
    } else {
        echo json_encode([
            "status" => "failed",
            "message" => "Password yang Anda masukkan salah"
        ]);
    }
} else {
    echo json_encode([
        "status" => "failed",
        "message" => "Username atau kode alat tidak valid"
    ]);
}

$stmt->close();
mysqli_close($conn);
?>
