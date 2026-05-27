<?php
session_start();
require_once __DIR__ . "/bl/BuketBL.php";
require_once __DIR__ . "/bl/SiparisBL.php";

if (!isset($_SESSION["kullanici_id"])) {
    header("Location: giris.php");
    exit();
}

if (($_SESSION["rol"] ?? "") === "yonetici") {
    header("Location: admin-panel.php");
    exit();
}

$buketBL = new BuketBL();
$siparisBL = new SiparisBL();
$hata = "";

$detaylar = $buketBL->aktifBuketDetaylari((int)$_SESSION["kullanici_id"]);
$toplam = $buketBL->toplamHesapla($detaylar);

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $sonuc = $siparisBL->siparisOlustur(
        (int)$_SESSION["kullanici_id"],
        $_POST["alici_ad_soyad"] ?? "",
        $_POST["alici_telefon"] ?? "",
        $_POST["teslimat_adresi"] ?? "",
        $_POST["teslimat_tarihi"] ?? "",
        $_POST["kart_mesaji"] ?? ""
    );

    if ($sonuc["success"]) {
        header("Location: siparislerim.php");
        exit();
    }

    $hata = $sonuc["message"];
}

$pageTitle = "Sipariş Oluştur | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-truck"></i> Sipariş Oluştur</p>
  <h1>Teslimat Bilgileri</h1>
  <p>Buketinin ulaşacağı kişiye ait bilgileri girerek siparişini kolayca tamamlayabilirsin.</p>
</section>

<?php if ($hata !== ""): ?><div class="message error"><?php echo htmlspecialchars($hata); ?></div><?php endif; ?>

<main class="order-section">
  <section class="order-card">
    <h2>Alıcı ve Teslimat</h2>

    <?php if (count($detaylar) === 0): ?>
      <div class="empty-box">Sipariş verebilmek için önce <a href="cicekler.php">buketine çiçek eklemelisin</a>.</div>
    <?php else: ?>
      <form method="post" action="siparis.php">
        <div class="form-row">
          <div class="form-group">
            <label for="alici">Alıcı Ad Soyad</label>
            <input type="text" id="alici" name="alici_ad_soyad" placeholder="Örn: Ayşe Yılmaz" required />
          </div>

          <div class="form-group">
            <label for="telefon">Alıcı Telefon</label>
            <input type="tel" id="telefon" name="alici_telefon" placeholder="05xx xxx xx xx" required />
          </div>
        </div>

        <div class="form-group">
          <label for="adres">Teslimat Adresi</label>
          <textarea id="adres" name="teslimat_adresi" placeholder="Teslimat adresini yaz..." required></textarea>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="tarih">Teslimat Tarihi</label>
            <input type="date" id="tarih" name="teslimat_tarihi" required />
          </div>

          <div class="form-group">
            <label>Ödeme Yöntemi</label>
            <div class="payment-box"><i class="bi bi-credit-card"></i><span>Kredi kartı ile ödeme</span></div>
          </div>
        </div>

        <div class="form-group">
          <label for="kart-mesaji">Kart Mesajı</label>
          <textarea id="kart-mesaji" name="kart_mesaji" placeholder="Buketle birlikte gönderilecek kısa mesaj..."></textarea>
        </div>

        <button type="submit" class="order-btn">Siparişi Tamamla</button>
      </form>
    <?php endif; ?>
  </section>

  <aside class="summary-card">
    <h2>Sipariş Özeti</h2>

    <?php foreach ($detaylar as $detay): ?>
      <div class="summary-item">
        <span><?php echo htmlspecialchars($detay["cicek_adi"]); ?> x <?php echo (int)$detay["adet"]; ?></span>
        <strong>₺<?php echo number_format((float)$detay["satir_toplam"], 2, ",", "."); ?></strong>
      </div>
    <?php endforeach; ?>

    <div class="summary-total"><span>Toplam</span><span>₺<?php echo number_format($toplam, 2, ",", "."); ?></span></div>
    <a href="buketim.php" class="back-link">Buketimi düzenle</a>
  </aside>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>