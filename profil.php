<?php
session_start();
require_once __DIR__ . "/bl/KullaniciBL.php";
require_once __DIR__ . "/bl/SiparisBL.php";

if (!isset($_SESSION["kullanici_id"])) {
    header("Location: giris.php");
    exit();
}

if (($_SESSION["rol"] ?? "") === "yonetici") {
    header("Location: admin-panel.php");
    exit();
}

$kullaniciBL = new KullaniciBL();
$siparisBL = new SiparisBL();
$profil = $kullaniciBL->profilGetir((int)$_SESSION["kullanici_id"]);
$sonSiparis = $siparisBL->sonSiparisGetir((int)$_SESSION["kullanici_id"]);

$adSoyad = trim(($profil["ad"] ?? $_SESSION["ad"] ?? "") . " " . ($profil["soyad"] ?? $_SESSION["soyad"] ?? ""));
$mail = $profil["mail"] ?? ($_SESSION["mail"] ?? "");
$telefon = $profil["telefon"] ?? ($_SESSION["telefon"] ?? "");

function profilDurumYazi(string $durum): string
{
    return match ($durum) {
        "hazirlaniyor" => "Hazırlanıyor",
        "yolda" => "Yolda",
        "teslim_edildi" => "Teslim Edildi",
        "iptal_edildi" => "İptal Edildi",
        default => $durum
    };
}

$pageTitle = "Profilim | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-person-heart"></i> Kullanıcı Paneli</p>
  <h1>Profilim</h1>
  <p>Hesap bilgilerini, oluşturduğun buketleri ve sipariş geçmişini bu sayfadan görüntüleyebilirsin.</p>
</section>

<main class="profile-section">
  <aside class="profile-card">
    <div class="profile-icon"><i class="bi bi-person"></i></div>
    <h2><?php echo htmlspecialchars($adSoyad); ?></h2>
    <p>Müşteri hesabı</p>

    <div class="user-info">
      <div class="info-line"><span>Mail</span><strong><?php echo htmlspecialchars($mail); ?></strong></div>
      <div class="info-line"><span>Telefon</span><strong><?php echo htmlspecialchars($telefon); ?></strong></div>
    </div>
  </aside>

  <section class="profile-panel">
    <h2>Hızlı İşlemler</h2>

    <div class="panel-grid">
      <a href="buketim.php" class="panel-card">
        <i class="bi bi-bag-heart"></i>
        <h3>Buketim</h3>
        <p>Seçtiğin çiçekleri ve oluşturduğun buketin toplamını görüntüle.</p>
      </a>

      <a href="siparislerim.php" class="panel-card">
        <i class="bi bi-box-seam"></i>
        <h3>Siparişlerim</h3>
        <p>Verdiğin siparişleri ve teslimat durumlarını takip et.</p>
      </a>
    </div>

    <div class="last-order">
      <div class="last-order-top">
        <h3>Son Sipariş</h3>
        <?php if ($sonSiparis): ?>
          <span class="status"><?php echo profilDurumYazi($sonSiparis["siparis_durumu"]); ?></span>
        <?php endif; ?>
      </div>

      <?php if ($sonSiparis): ?>
        <p>Sipariş #<?php echo (int)$sonSiparis["siparis_id"]; ?> için teslimat tarihi <?php echo htmlspecialchars(date("d.m.Y", strtotime($sonSiparis["teslimat_tarihi"]))); ?> olarak belirlenmiştir.</p>
        <a href="siparislerim.php">Sipariş detaylarını görüntüle</a>
      <?php else: ?>
        <p>Henüz oluşturulmuş siparişin bulunmuyor.</p>
        <a href="cicekler.php">İlk buketini oluştur</a>
      <?php endif; ?>
    </div>
  </section>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>