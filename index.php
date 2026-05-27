<?php
session_start();
$pageTitle = "Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<main class="hero">
  <div class="hero-text">
    <p class="small-title">
      <i class="bi bi-flower3 flower-icon"></i>
      Kişiselleştirilebilir buket sipariş sistemi
    </p>

    <h1>Kendi Buketini Oluştur</h1>

    <p>
      Farklı çiçekleri bir araya getir, kendin ya da sevdiklerin için özel
      bir buket hazırla.
    </p>
  </div>

  <div class="hero-image">
    <img src="assets/img/hero-flower.png" alt="Çiçek Görseli" />
  </div>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>