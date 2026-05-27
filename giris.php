<?php
session_start();
require_once __DIR__ . "/bl/KullaniciBL.php";

$kullaniciBL = new KullaniciBL();
$mesaj = "";
$hata  = "";

if (isset($_SESSION["kullanici_id"])) {
    if (($_SESSION["rol"] ?? "") === "yonetici") {
        header("Location: admin-panel.php");
        exit();
    }
    header("Location: profil.php");
    exit();
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $formTipi = $_POST["form_tipi"] ?? "";

    try {
        if ($formTipi === "giris") {
            $sonuc = $kullaniciBL->girisYap($_POST["giris_mail"] ?? "", $_POST["giris_sifre"] ?? "");

            if ($sonuc["success"]) {
                $kullanici = $sonuc["kullanici"];
                $_SESSION["kullanici_id"] = $kullanici["kullanici_id"];
                $_SESSION["ad"]           = $kullanici["ad"];
                $_SESSION["soyad"]        = $kullanici["soyad"];
                $_SESSION["ad_soyad"]     = $kullanici["ad"] . " " . $kullanici["soyad"];
                $_SESSION["mail"]         = $kullanici["mail"];
                $_SESSION["telefon"]      = $kullanici["telefon"];
                $_SESSION["rol"]          = $kullanici["rol"];

                if ($kullanici["rol"] === "yonetici") {
                    header("Location: admin-panel.php");
                    exit();
                }

                header("Location: profil.php");
                exit();
            }

            $hata = $sonuc["message"];
        }

        if ($formTipi === "kayit") {
            $sonuc = $kullaniciBL->kayitOl(
                $_POST["ad"]         ?? "",
                $_POST["soyad"]      ?? "",
                $_POST["kayit_mail"] ?? "",
                $_POST["telefon"]    ?? "",
                $_POST["kayit_sifre"] ?? ""
            );

            if ($sonuc["success"]) {
                $mesaj = $sonuc["message"];
            } else {
                $hata = $sonuc["message"];
            }
        }
    } catch (RuntimeException $e) {
        $hata = $e->getMessage();
    }
}

$pageTitle = "Giriş Yap | Buket Sipariş Sistemi";
require_once __DIR__ . "/includes/header.php";
?>

<section class="page-header">
  <p class="small-title"><i class="bi bi-person-heart"></i> Üyelik İşlemleri</p>
  <h1>Giriş Yap veya Kayıt Ol</h1>
  <p>Buket oluşturmak ve sipariş verebilmek için hesabına giriş yapabilir ya da yeni bir üyelik oluşturabilirsin.</p>
</section>

<?php if ($mesaj !== ""): ?>
  <div class="message success"><?php echo htmlspecialchars($mesaj); ?></div>
<?php endif; ?>

<?php if ($hata !== ""): ?>
  <div class="message error"><?php echo htmlspecialchars($hata); ?></div>
<?php endif; ?>

<main class="auth-section">
  <section class="auth-card">
    <h2>Giriş Yap</h2>
    <p class="card-text">Hesabınla giriş yaparak buketlerini ve siparişlerini görüntüleyebilirsin.</p>

    <form method="post" action="giris.php">
      <input type="hidden" name="form_tipi" value="giris" />

      <div class="form-group">
        <label for="giris-mail">Mail</label>
        <div class="input-box">
          <i class="bi bi-envelope"></i>
          <input type="email" id="giris-mail" name="giris_mail" placeholder="Mail adresini gir" required />
        </div>
      </div>

      <div class="form-group">
        <label for="giris-sifre">Şifre</label>
        <div class="input-box">
          <i class="bi bi-lock"></i>
          <input type="password" id="giris-sifre" name="giris_sifre" placeholder="Şifreni gir" required />
        </div>
      </div>

      <button type="submit" class="auth-btn">Giriş Yap</button>
    </form>

    <div class="soft-note">
      <i class="bi bi-flower3"></i>
      Admin hesabı kayıt olmaz, sadece giriş yapar. Müşteri hesabı kayıt formu ile oluşturulur.
    </div>
  </section>

  <section class="auth-card">
    <h2>Kayıt Ol</h2>
    <p class="card-text">Yeni bir hesap oluşturarak seçtiğin çiçeklerden özel buketler hazırlayabilirsin.</p>

    <form method="post" action="giris.php">
      <input type="hidden" name="form_tipi" value="kayit" />

      <div class="form-group">
        <label for="ad">Ad</label>
        <div class="input-box"><i class="bi bi-person"></i><input type="text" id="ad" name="ad" placeholder="Adını gir" required /></div>
      </div>

      <div class="form-group">
        <label for="soyad">Soyad</label>
        <div class="input-box"><i class="bi bi-person"></i><input type="text" id="soyad" name="soyad" placeholder="Soyadını gir" required /></div>
      </div>

      <div class="form-group">
        <label for="kayit-mail">Mail</label>
        <div class="input-box"><i class="bi bi-envelope"></i><input type="email" id="kayit-mail" name="kayit_mail" placeholder="Mail adresini gir" required /></div>
      </div>

      <div class="form-group">
        <label for="telefon">Telefon</label>
        <div class="input-box"><i class="bi bi-phone"></i><input type="tel" id="telefon" name="telefon" placeholder="05xx xxx xx xx" required /></div>
      </div>

      <div class="form-group">
        <label for="kayit-sifre">Şifre</label>
        <div class="input-box"><i class="bi bi-lock"></i><input type="password" id="kayit-sifre" name="kayit_sifre" placeholder="Şifre oluştur" required /></div>
      </div>

      <button type="submit" class="auth-btn">Kayıt Ol</button>
    </form>
  </section>
</main>

<?php require_once __DIR__ . "/includes/footer.php"; ?>