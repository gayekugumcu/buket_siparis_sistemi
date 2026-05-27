<?php
session_start();
require_once __DIR__ . "/bl/SiparisBL.php";

if (!isset($_SESSION["kullanici_id"])) {
    header("Location: giris.php");
    exit();
}

if (($_SESSION["rol"] ?? "") === "yonetici") {
    header("Location: admin-panel.php");
    exit();
}

function durumClass(string $durum): string
{
    return match ($durum) {
        "hazirlaniyor" => "preparing",
        "yolda" => "on-road",
        "teslim_edildi" => "delivered",
        "iptal_edildi" => "cancelled",
        default => "preparing"
    };
}

function durumYazi(string $durum): string
{
    return match ($durum) {
        "hazirlaniyor" => "Hazırlanıyor",
        "yolda" => "Yolda",
        "teslim_edildi" => "Teslim Edildi",
        "iptal_edildi" => "İptal Edildi",
        default => $durum
    };
}

$siparisBL = new SiparisBL();
$siparisler = $siparisBL->kullaniciSiparisleriListele((int)$_SESSION["kullanici_id"]);

$pageTitle = "Siparişlerim | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-box-seam"></i> Sipariş Geçmişi</p>
  <h1>Siparişlerim</h1>
  <p>Daha önce oluşturduğun buket siparişlerini ve teslimat durumlarını bu sayfadan takip edebilirsin.</p>
</section>

<main class="orders-section">
  <div class="orders-list">
    <?php if (count($siparisler) === 0): ?>
      <div class="empty-box">Henüz siparişin yok. <a href="cicekler.php">İlk buketini oluştur</a>.</div>
    <?php endif; ?>

    <?php foreach ($siparisler as $siparis): ?>
      <article class="order-history-card">
        <div class="order-history-top">
          <div>
            <h2>Sipariş #<?php echo (int)$siparis["siparis_id"]; ?></h2>
            <p class="order-date">Sipariş Tarihi: <?php echo htmlspecialchars(date("d.m.Y H:i", strtotime($siparis["siparis_tarihi"]))); ?></p>
          </div>
          <span class="order-status <?php echo durumClass($siparis["siparis_durumu"]); ?>"><?php echo durumYazi($siparis["siparis_durumu"]); ?></span>
        </div>

        <div class="order-info-grid">
          <div class="order-info-box"><span>Alıcı</span><strong><?php echo htmlspecialchars($siparis["alici_ad_soyad"]); ?></strong></div>
          <div class="order-info-box"><span>Teslimat Tarihi</span><strong><?php echo htmlspecialchars(date("d.m.Y", strtotime($siparis["teslimat_tarihi"]))); ?></strong></div>
          <div class="order-info-box"><span>Ödeme</span><strong>Kredi Kartı</strong></div>
          <div class="order-info-box"><span>Toplam Tutar</span><strong>₺<?php echo number_format((float)$siparis["toplam_fiyat"], 2, ",", "."); ?></strong></div>
        </div>

        <div class="order-products">
          <h3>Buket İçeriği</h3>
          <p><?php echo htmlspecialchars($siparis["buket_icerigi"] ?? ""); ?></p>
        </div>
      </article>
    <?php endforeach; ?>
  </div>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>