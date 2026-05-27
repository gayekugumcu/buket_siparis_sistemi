<?php

require_once __DIR__ . "/../dal/BuketDAL.php";

class BuketBL
{
    private BuketDAL $buketDAL;

    public function __construct()
    {
        $this->buketDAL = new BuketDAL();
    }

    public function cicekEkle(int $kullaniciId, int $cicekId, int $adet = 1): array
    {
        if ($kullaniciId <= 0 || $cicekId <= 0 || $adet <= 0) {
            return ["success" => false, "message" => "Çiçek bukete eklenemedi."];
        }

        try {
            $this->buketDAL->buketeCicekEkle($kullaniciId, $cicekId, $adet);
            return ["success" => true, "message" => "Çiçek bukete eklendi."];
        } catch (PDOException $e) {
            return ["success" => false, "message" => $e->getMessage()];
        }
    }

    public function aktifBuketGetir(int $kullaniciId): ?array
    {
        return $this->buketDAL->aktifBuketGetir($kullaniciId);
    }

    public function aktifBuketDetaylari(int $kullaniciId): array
    {
        return $this->buketDAL->aktifBuketDetaylari($kullaniciId);
    }

    public function bukettenCicekSil(int $kullaniciId, int $buketDetayId): array
    {
        if ($buketDetayId <= 0) {
            return ["success" => false, "message" => "Silinecek çiçek bulunamadı."];
        }

        $this->buketDAL->bukettenCicekSil($kullaniciId, $buketDetayId);
        return ["success" => true, "message" => "Çiçek buketten kaldırıldı."];
    }

    public function toplamHesapla(array $detaylar): float
    {
        $toplam = 0;
        foreach ($detaylar as $detay) {
            $toplam += (float)$detay["satir_toplam"];
        }
        return $toplam;
    }

    public function adetHesapla(array $detaylar): int
    {
        $adet = 0;
        foreach ($detaylar as $detay) {
            $adet += (int)$detay["adet"];
        }
        return $adet;
    }
}