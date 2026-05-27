<?php

require_once __DIR__ . "/../dal/KullaniciDAL.php";

class KullaniciBL
{
    private KullaniciDAL $kullaniciDAL;

    public function __construct()
    {
        $this->kullaniciDAL = new KullaniciDAL();
    }

    public function girisYap(string $mail, string $sifre): array
    {
        $mail = trim($mail);

        if ($mail === "" || $sifre === "") {
            return ["success" => false, "message" => "Mail ve şifre boş bırakılamaz."];
        }

        $kullanici = $this->kullaniciDAL->mailIleGetir($mail);

        if (!$kullanici) {
            return ["success" => false, "message" => "Bu mail adresiyle kayıtlı kullanıcı bulunamadı."];
        }

        if (!password_verify($sifre, $kullanici["sifre"])) {
            return ["success" => false, "message" => "Şifre hatalı."];
        }

        return ["success" => true, "message" => "Giriş başarılı.", "kullanici" => $kullanici];
    }

    public function kayitOl(string $ad, string $soyad, string $mail, string $telefon, string $sifre): array
    {
        $ad = trim($ad);
        $soyad = trim($soyad);
        $mail = trim($mail);
        $telefon = trim($telefon);

        if ($ad === "" || $soyad === "" || $mail === "" || $telefon === "" || $sifre === "") {
            return ["success" => false, "message" => "Tüm alanları doldurmalısın."];
        }

        if (!filter_var($mail, FILTER_VALIDATE_EMAIL)) {
            return ["success" => false, "message" => "Geçerli bir mail adresi gir."];
        }

        if (strlen($sifre) < 6) {
            return ["success" => false, "message" => "Şifre en az 6 karakter olmalı."];
        }

        if ($this->kullaniciDAL->mailIleGetir($mail)) {
            return ["success" => false, "message" => "Bu mail adresiyle zaten kayıt olunmuş."];
        }

        $hashliSifre = password_hash($sifre, PASSWORD_DEFAULT);
        $eklendiMi = $this->kullaniciDAL->kullaniciEkle($ad, $soyad, $mail, $hashliSifre, $telefon, "musteri");

        if (!$eklendiMi) {
            return ["success" => false, "message" => "Kayıt sırasında bir hata oluştu."];
        }

        return ["success" => true, "message" => "Kayıt başarılı. Şimdi giriş yapabilirsin."];
    }

    public function profilGetir(int $kullaniciId): ?array
    {
        return $this->kullaniciDAL->kullaniciGetir($kullaniciId);
    }
}