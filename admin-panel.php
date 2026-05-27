<?php
session_start();
require_once __DIR__ . "/bl/CicekBL.php";
require_once __DIR__ . "/bl/SiparisBL.php";
require_once __DIR__ . "/bl/AdminBL.php";

if (!isset($_SESSION["kullanici_id"])) {
    header("Location: giris.php");
    exit();
}

if (($_SESSION["rol"] ?? "") !== "yonetici") {
    header("Location: index.php");
    exit();
}

$cicekBL = new CicekBL();
$siparisBL = new SiparisBL();
$adminBL = new AdminBL();
$mesaj = "";
$hata = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $islem = $_POST["islem"] ?? "";

    if ($islem === "cicek_ekle") {
        $sonuc = $cicekBL->ekle($_POST["cicek_adi"] ?? "", $_POST["birim_fiyat"] ?? 0, $_POST["stok_miktari"] ?? 0, $_POST["gorsel"] ?? "");
    } elseif ($islem === "cicek_guncelle") {
        $sonuc = $cicekBL->guncelle((int)($_POST["cicek_id"] ?? 0), $_POST["cicek_adi"] ?? "", $_POST["birim_fiyat"] ?? 0, $_POST["stok_miktari"] ?? 0, $_POST["gorsel"] ?? "");
    } elseif ($islem === "cicek_sil") {
        $sonuc = $cicekBL->sil((int)($_POST["cicek_id"] ?? 0));
    } elseif ($islem === "siparis_guncelle") {
        $sonuc = $siparisBL->durumGuncelle((int)($_POST["siparis_id"] ?? 0), $_POST["siparis_durumu"] ?? "");
    } else {
        $sonuc = ["success" => false, "message" => "İşlem bulunamadı."];
    }

    if ($sonuc["success"]) {
        $mesaj = $sonuc["message"];
    } else {
        $hata = $sonuc["message"];
    }
}

$cicekler = $cicekBL->listele();
$siparisler = $siparisBL->adminSiparisListele();
$istatistik = $adminBL->istatistikListele();

function adminDurumYazi(string $durum): string
{
    return match ($durum) {
        "hazirlaniyor" => "Hazırlanıyor",
        "yolda" => "Yolda",
        "teslim_edildi" => "Teslim Edildi",
        "iptal_edildi" => "İptal Edildi",
        default => $durum
    };
}

$pageTitle = "Admin Panel | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-gear"></i> Yönetici Paneli</p>
  <h1>Admin Panel</h1>
  <p>Çiçekleri, stok bilgilerini ve kullanıcıların oluşturduğu siparişleri bu panel üzerinden yönetebilirsin.</p>
</section>

<?php if ($mesaj !== ""): ?><div class="message success"><?php echo htmlspecialchars($mesaj); ?></div><?php endif; ?>
<?php if ($hata !== ""): ?><div class="message error"><?php echo htmlspecialchars($hata); ?></div><?php endif; ?>

<main class="admin-section">
  <section class="stats-grid">
    <div class="stat-card"><i class="bi bi-flower3"></i><span>Toplam Çiçek</span><strong><?php echo (int)$istatistik["toplam_cicek"]; ?></strong></div>
    <div class="stat-card"><i class="bi bi-bag-heart"></i><span>Oluşturulan Buket</span><strong><?php echo (int)$istatistik["toplam_buket"]; ?></strong></div>
    <div class="stat-card"><i class="bi bi-box-seam"></i><span>Toplam Sipariş</span><strong><?php echo (int)$istatistik["toplam_siparis"]; ?></strong></div>
    <div class="stat-card"><i class="bi bi-credit-card"></i><span>Ödeme Kaydı</span><strong><?php echo (int)$istatistik["toplam_odeme"]; ?></strong></div>
  </section>

  <section class="admin-grid">
    <div class="admin-card">
      <h2>Çiçek Ekle</h2>
      <form method="post" action="admin-panel.php">
        <input type="hidden" name="islem" value="cicek_ekle" />
        <div class="form-group"><label for="cicek-adi">Çiçek Adı</label><input type="text" id="cicek-adi" name="cicek_adi" placeholder="Örn: Beyaz Zambak" required /></div>
        <div class="form-group"><label for="fiyat">Birim Fiyat</label><input type="number" step="0.01" id="fiyat" name="birim_fiyat" placeholder="Örn: 85" required /></div>
        <div class="form-group"><label for="stok">Stok Miktarı</label><input type="number" id="stok" name="stok_miktari" placeholder="Örn: 24" required /></div>
        <div class="form-group"><label for="gorsel">Görsel Yolu</label><input type="text" id="gorsel" name="gorsel" placeholder="assets/img/hero-flower.png" /></div>
        <button type="submit" class="admin-btn">Çiçek Ekle</button>
      </form>
    </div>

    <div class="admin-card">
      <h2>Çiçek Yönetimi</h2>
      <div class="table-wrapper">
        <table>
          <thead><tr><th>Çiçek</th><th>Fiyat</th><th>Stok</th><th>Görsel</th><th>Durum</th><th>İşlem</th></tr></thead>
          <tbody>
            <?php foreach ($cicekler as $cicek): ?>
              <tr>
                <form method="post" action="admin-panel.php">
                  <input type="hidden" name="islem" value="cicek_guncelle" />
                  <input type="hidden" name="cicek_id" value="<?php echo (int)$cicek["cicek_id"]; ?>" />
                  <td><input class="inline-input" type="text" name="cicek_adi" value="<?php echo htmlspecialchars($cicek["cicek_adi"]); ?>" /></td>
                  <td><input class="inline-input" type="number" step="0.01" name="birim_fiyat" value="<?php echo htmlspecialchars($cicek["birim_fiyat"]); ?>" /></td>
                  <td><input class="inline-input" type="number" name="stok_miktari" value="<?php echo htmlspecialchars($cicek["stok_miktari"]); ?>" /></td>
                  <td><input class="inline-input" type="text" name="gorsel" value="<?php echo htmlspecialchars($cicek["gorsel"] ?? ""); ?>" /></td>
                  <td>
                    <?php if ((int)$cicek["stok_miktari"] === 0): ?>
                      <span class="stock out">Tükendi</span>
                    <?php elseif ((int)$cicek["stok_miktari"] <= 5): ?>
                      <span class="stock low">Az Stok</span>
                    <?php else: ?>
                      <span class="stock good">Stokta</span>
                    <?php endif; ?>
                  </td>
                  <td>
                    <div class="table-actions">
                      <button type="submit" class="soft-btn">Güncelle</button>
                </form>
                      <form method="post" action="admin-panel.php" onsubmit="return confirm('Bu çiçeği silmek istediğine emin misin?');">
                        <input type="hidden" name="islem" value="cicek_sil" />
                        <input type="hidden" name="cicek_id" value="<?php echo (int)$cicek["cicek_id"]; ?>" />
                        <button type="submit" class="admin-delete-btn">Sil</button>
                      </form>
                    </div>
                  </td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="admin-card full-card">
    <h2>Sipariş Yönetimi</h2>
    <div class="table-wrapper">
      <table>
        <thead><tr><th>Sipariş</th><th>Müşteri</th><th>Alıcı</th><th>Teslimat</th><th>Tutar</th><th>Durum</th><th>İşlem</th></tr></thead>
        <tbody>
          <?php if (count($siparisler) === 0): ?>
            <tr><td colspan="7">Henüz sipariş bulunmuyor.</td></tr>
          <?php endif; ?>

          <?php foreach ($siparisler as $siparis): ?>
            <tr>
              <form method="post" action="admin-panel.php">
                <input type="hidden" name="islem" value="siparis_guncelle" />
                <input type="hidden" name="siparis_id" value="<?php echo (int)$siparis["siparis_id"]; ?>" />
                <td>#<?php echo (int)$siparis["siparis_id"]; ?></td>
                <td><?php echo htmlspecialchars($siparis["musteri_ad_soyad"]); ?></td>
                <td><?php echo htmlspecialchars($siparis["alici_ad_soyad"]); ?></td>
                <td><?php echo htmlspecialchars(date("d.m.Y", strtotime($siparis["teslimat_tarihi"]))); ?></td>
                <td>₺<?php echo number_format((float)$siparis["toplam_fiyat"], 2, ",", "."); ?></td>
                <td>
                  <select class="status-select" name="siparis_durumu">
                    <?php foreach (["hazirlaniyor", "yolda", "teslim_edildi", "iptal_edildi"] as $durum): ?>
                      <option value="<?php echo $durum; ?>" <?php echo $siparis["siparis_durumu"] === $durum ? "selected" : ""; ?>><?php echo adminDurumYazi($durum); ?></option>
                    <?php endforeach; ?>
                  </select>
                </td>
                <td><button type="submit" class="soft-btn">Güncelle</button></td>
              </form>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </section>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>