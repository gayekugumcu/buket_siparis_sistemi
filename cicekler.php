<?php
session_start();
require_once __DIR__ . "/bl/CicekBL.php";
require_once __DIR__ . "/bl/BuketBL.php";

$cicekBL = new CicekBL();
$buketBL = new BuketBL();
$mesaj = "";
$hata = "";

if ($_SERVER["REQUEST_METHOD"] === "POST" && ($_POST["islem"] ?? "") === "bukete_ekle") {
    if (!isset($_SESSION["kullanici_id"])) {
        header("Location: giris.php");
        exit();
    }

    if (($_SESSION["rol"] ?? "") === "yonetici") {
        $hata = "Admin hesabı ile buket oluşturulamaz.";
    } else {
        $sonuc = $buketBL->cicekEkle((int)$_SESSION["kullanici_id"], (int)($_POST["cicek_id"] ?? 0), 1);
        if ($sonuc["success"]) {
            $mesaj = $sonuc["message"];
        } else {
            $hata = $sonuc["message"];
        }
    }
}

$cicekler = $cicekBL->listele();
$pageTitle = "Çiçekler | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-flower3"></i> Çiçek Koleksiyonu</p>
  <h1>Çiçekler</h1>
  <p>Buketinde kullanmak istediğin çiçekleri incele. Farklı türleri bir araya getirerek özel bir buket oluştur.</p>
</section>

<?php if ($mesaj !== ""): ?><div class="message success"><?php echo htmlspecialchars($mesaj); ?> <a href="buketim.php">Buketimi gör</a></div><?php endif; ?>
<?php if ($hata !== ""): ?><div class="message error"><?php echo htmlspecialchars($hata); ?></div><?php endif; ?>

<main class="flowers-section">
  <div class="flowers-grid">
    <?php foreach ($cicekler as $index => $cicek): ?>
      <div class="flower-card">
        <div class="flower-image">
          <?php if (!empty($cicek["gorsel"])): ?>
            <img src="<?php echo htmlspecialchars($cicek["gorsel"]); ?>" alt="<?php echo htmlspecialchars($cicek["cicek_adi"]); ?>" />
          <?php else: ?>
            <i class="bi bi-flower<?php echo ($index % 3) + 1; ?>"></i>
          <?php endif; ?>
        </div>

        <div class="flower-info">
          <h3><?php echo htmlspecialchars($cicek["cicek_adi"]); ?></h3>

          <?php if ((int)$cicek["stok_miktari"] > 0): ?>
            <p class="stock available">Stokta var</p>
          <?php else: ?>
            <p class="stock out">Tükendi</p>
          <?php endif; ?>

          <div class="flower-bottom">
            <span class="price">₺<?php echo number_format((float)$cicek["birim_fiyat"], 2, ",", "."); ?></span>

            <?php if ((int)$cicek["stok_miktari"] > 0): ?>
              <form method="post" action="cicekler.php">
                <input type="hidden" name="islem" value="bukete_ekle" />
                <input type="hidden" name="cicek_id" value="<?php echo (int)$cicek["cicek_id"]; ?>" />
                <button type="submit" class="add-btn">Bukete Ekle</button>
              </form>
            <?php else: ?>
              <button class="add-btn disabled" disabled>Bukete Eklenemez</button>
            <?php endif; ?>
          </div>
        </div>
      </div>
    <?php endforeach; ?>
  </div>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>