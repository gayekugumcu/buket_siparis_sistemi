<?php

require_once __DIR__ . "/../dal/CicekDAL.php";

class CicekBL
{
    private CicekDAL $cicekDAL;

    public function __construct()
    {
        $this->cicekDAL = new CicekDAL();
    }

    public function listele(): array
    {
        return $this->cicekDAL->listele();
    }

    public function ekle(string $ad, $fiyat, $stok, string $gorsel): array
    {
        $ad = trim($ad);
        $gorsel = trim($gorsel);
        $fiyat = (float)$fiyat;
        $stok = (int)$stok;

        if ($ad === "" || $fiyat < 0 || $stok < 0) {
            return ["success" => false, "message" => "Çiçek adı, fiyat ve stok bilgilerini kontrol et."];
        }

        if ($gorsel === "") {
            $gorsel = "assets/img/hero-flower.png";
        }

        $this->cicekDAL->ekle($ad, $fiyat, $stok, $gorsel);
        return ["success" => true, "message" => "Çiçek başarıyla eklendi."];
    }

    public function guncelle(int $id, string $ad, $fiyat, $stok, string $gorsel): array
    {
        $ad = trim($ad);
        $gorsel = trim($gorsel);
        $fiyat = (float)$fiyat;
        $stok = (int)$stok;

        if ($id <= 0 || $ad === "" || $fiyat < 0 || $stok < 0) {
            return ["success" => false, "message" => "Güncellenecek çiçek bilgilerini kontrol et."];
        }

        if ($gorsel === "") {
            $gorsel = "assets/img/hero-flower.png";
        }

        $this->cicekDAL->guncelle($id, $ad, $fiyat, $stok, $gorsel);
        return ["success" => true, "message" => "Çiçek başarıyla güncellendi."];
    }

    public function sil(int $id): array
    {
        if ($id <= 0) {
            return ["success" => false, "message" => "Silinecek çiçek bulunamadı."];
        }

        $this->cicekDAL->sil($id);
        return ["success" => true, "message" => "Çiçek silindi."];
    }
}