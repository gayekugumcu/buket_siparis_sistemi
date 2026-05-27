<?php
session_start();
require_once __DIR__ . "/bl/BuketBL.php";

if (!isset($_SESSION["kullanici_id"])) {
    header("Location: giris.php");
    exit();
}

if (($_SESSION["rol"] ?? "") === "yonetici") {
    header("Location: admin-panel.php");
    exit();
}

$buketBL = new BuketBL();
$mesaj = "";
$hata = "";

if ($_SERVER["REQUEST_METHOD"] === "POST" && ($_POST["islem"] ?? "") === "sil") {
    $sonuc = $buketBL->bukettenCicekSil((int)$_SESSION["kullanici_id"], (int)($_POST["buket_detay_id"] ?? 0));
    if ($sonuc["success"]) {
        $mesaj = $sonuc["message"];
    } else {
        $hata = $sonuc["message"];
    }
}

$detaylar = $buketBL->aktifBuketDetaylari((int)$_SESSION["kullanici_id"]);
$toplam = $buketBL->toplamHesapla($detaylar);
$adet = $buketBL->adetHesapla($detaylar);

$pageTitle = "Buketim | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-bag-heart"></i> Buket Özeti</p>
  <h1>Buketim</h1>
  <p>Seçtiğin çiçekleri görüntüleyebilir, buketinin toplam tutarını inceleyerek sipariş adımına geçebilirsin.</p>
</section>

<?php if ($mesaj !== ""): ?><div class="message success"><?php echo htmlspecialchars($mesaj); ?></div><?php endif; ?>
<?php if ($hata !== ""): ?><div class="message error"><?php echo htmlspecialchars($hata); ?></div><?php endif; ?>

<main class="bouquet-section">
  <section class="bouquet-card">
    <h2>Seçilen Çiçekler</h2>

    <?php if (count($detaylar) === 0): ?>
      <div class="empty-box">Buketin şu an boş. <a href="cicekler.php">Çiçek eklemeye başla</a>.</div>
    <?php endif; ?>

    <?php foreach ($detaylar as $detay): ?>
      <div class="bouquet-item">
        <div class="item-left">
          <div class="item-icon"><i class="bi bi-flower3"></i></div>
          <div class="item-info">
            <h3><?php echo htmlspecialchars($detay["cicek_adi"]); ?></h3>
            <p>Buket içinde seçilen çiçek</p>
          </div>
        </div>

        <div class="item-right">
          <span class="quantity"><?php echo (int)$detay["adet"]; ?> adet</span>
          <span class="item-price">₺<?php echo number_format((float)$detay["satir_toplam"], 2, ",", "."); ?></span>
          <form method="post" action="buketim.php">
            <input type="hidden" name="islem" value="sil" />
            <input type="hidden" name="buket_detay_id" value="<?php echo (int)$detay["buket_detay_id"]; ?>" />
            <button type="submit" class="delete-btn"><i class="bi bi-trash"></i></button>
          </form>
        </div>
      </div>
    <?php endforeach; ?>
  </section>

  <aside class="summary-card">
    <h2>Buket Toplamı</h2>
    <div class="summary-line"><span>Çiçek sayısı</span><span><?php echo $adet; ?> adet</span></div>
    <div class="summary-line"><span>Buket ara toplamı</span><span>₺<?php echo number_format($toplam, 2, ",", "."); ?></span></div>
    <div class="summary-line total"><span>Toplam</span><span>₺<?php echo number_format($toplam, 2, ",", "."); ?></span></div>

    <?php if (count($detaylar) > 0): ?>
      <a href="siparis.php" class="order-btn">Siparişe Geç</a>
    <?php else: ?>
      <a href="cicekler.php" class="order-btn">Çiçek Seç</a>
    <?php endif; ?>

    <a href="cicekler.php" class="continue-link">Çiçek eklemeye devam et</a>
  </aside>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>