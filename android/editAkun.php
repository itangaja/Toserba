<?php
include '../koneksi.php';

// Enable error reporting untuk debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

// Tangkap data POST
$oldUsername = isset($_POST['old_username']) ? $_POST['old_username'] : '';
$newUsername = isset($_POST['new_username']) ? $_POST['new_username'] : '';
$email = isset($_POST['email']) ? $_POST['email'] : '';
$password = isset($_POST['password']) ? $_POST['password'] : '';

// Log data yang diterima
error_log("Data diterima - Old: $oldUsername, New: $newUsername, Email: $email");

// Validasi data
if (empty($oldUsername) || empty($newUsername) || empty($email)) {
    echo json_encode([
        "status" => "failed",
        "message" => "Data tidak lengkap"
    ]);
    exit;
}

try {
    // Cek koneksi database
    if ($conn->connect_error) {
        throw new Exception("Koneksi database gagal: " . $conn->connect_error);
    }

    // Mulai transaksi
    $conn->begin_transaction();

    // 1. Pertama, buat temporary table untuk menyimpan data alat
    $conn->query("CREATE TEMPORARY TABLE temp_alat SELECT * FROM alat WHERE username_member = '$oldUsername'");

    // 2. Hapus data dari tabel alat
    $deleteAlat = $conn->prepare("DELETE FROM alat WHERE username_member = ?");
    $deleteAlat->bind_param("s", $oldUsername);
    $deleteAlat->execute();

    // 3. Update tabel members
    $updateQuery = "UPDATE members SET email = ?";
    $params = [$email];
    $types = "s";

    if (!empty($password)) {
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        $updateQuery .= ", password = ?";
        $params[] = $hashedPassword;
        $types .= "s";
    }

    if ($oldUsername !== $newUsername) {
        $updateQuery .= ", username = ?";
        $params[] = $newUsername;
        $types .= "s";
    }

    $updateQuery .= " WHERE username = ?";
    $params[] = $oldUsername;
    $types .= "s";

    $stmt = $conn->prepare($updateQuery);
    if (!$stmt) {
        throw new Exception("Prepare statement error: " . $conn->error);
    }

    $stmt->bind_param($types, ...$params);
    $executeResult = $stmt->execute();

    if (!$executeResult) {
        throw new Exception("Execute error: " . $stmt->error);
    }

    // 4. Kembalikan data alat dengan username yang baru
    if ($oldUsername !== $newUsername) {
        $conn->query("INSERT INTO alat (kode_alat, username_member) 
                     SELECT kode_alat, '$newUsername' 
                     FROM temp_alat");
    } else {
        $conn->query("INSERT INTO alat SELECT * FROM temp_alat");
    }

    // 5. Hapus temporary table
    $conn->query("DROP TEMPORARY TABLE IF EXISTS temp_alat");

    // Commit transaksi
    $conn->commit();

    echo json_encode([
        "status" => "success",
        "message" => "Profil berhasil diperbarui",
        "user" => [
            "username" => $newUsername,
            "email" => $email
        ]
    ]);

} catch (Exception $e) {
    error_log("Error in editAkun.php: " . $e->getMessage());
    
    if (isset($conn)) {
        $conn->rollback();
    }

    echo json_encode([
        "status" => "failed",
        "message" => "Gagal memperbarui profil: " . $e->getMessage()
    ]);
} finally {
    if (isset($stmt)) $stmt->close();
    if (isset($deleteAlat)) $deleteAlat->close();
    if (isset($conn)) $conn->close();
}
?>
