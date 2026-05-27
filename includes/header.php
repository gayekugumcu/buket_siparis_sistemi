<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$pageTitle = $pageTitle ?? "Buket Sipariş Sistemi";
?>
<!doctype html>
<html lang="tr">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title><?php echo htmlspecialchars($pageTitle); ?></title>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;500;600;700&family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet" />
    <link rel="stylesheet" href="assets/style.css" />
  </head>

  <body>
    <header class="navbar">
      <a href="index.php" class="logo-area">
        <img src="assets/img/logo.png" alt="Buket Logo" />
        <span>floria.</span>
      </a>

      <nav class="nav-links">
        <a href="index.php">Ana Sayfa</a>
        <a href="cicekler.php">Çiçekler</a>

        <?php if (isset($_SESSION["kullanici_id"])): ?>
          <?php if (($_SESSION["rol"] ?? "") === "yonetici"): ?>
            <a href="admin-panel.php">Admin Panel</a>
          <?php else: ?>
            <a href="buketim.php">Buketim</a>
            <a href="profil.php">Profilim</a>
          <?php endif; ?>
          <a href="cikis.php" class="kayit-giris">Çıkış</a>
        <?php else: ?>
          <a href="giris.php" class="kayit-giris">Giriş Yap</a>
        <?php endif; ?>
      </nav>
    </header>