<?php

require_once __DIR__ . "/../dal/SiparisDAL.php";
require_once __DIR__ . "/../dal/BuketDAL.php";

class SiparisBL
{
    private SiparisDAL $siparisDAL;
    private BuketDAL   $buketDAL;

    public function __construct()
    {
        $this->siparisDAL = new SiparisDAL();
        $this->buketDAL   = new BuketDAL();
    }

    public function siparisOlustur(int $kullaniciId, string $alici, string $telefon, string $adres, string $tarih, string $kartMesaji): array
    {
        $alici      = trim($alici);
        $telefon    = trim($telefon);
        $adres      = trim($adres);
        $tarih      = trim($tarih);
        $kartMesaji = trim($kartMesaji);

        if ($alici === "" || $telefon === "" || $adres === "" || $tarih === "") {
            return ["success" => false, "message" => "Alıcı ve teslimat bilgilerini doldurmalısın."];
        }

        $buket    = $this->buketDAL->aktifBuketGetir($kullaniciId);
        $detaylar = $this->buketDAL->aktifBuketDetaylari($kullaniciId);

        if (!$buket || count($detaylar) === 0) {
            return ["success" => false, "message" => "Sipariş verebilmek için önce buketine çiçek eklemelisin."];
        }

        try {
            $siparis   = $this->siparisDAL->siparisEkle(
                (int)$buket["buket_id"], $adres, $tarih, $alici, $telefon, $kartMesaji
            );
            $siparisId = (int)($siparis["siparis_id"] ?? 0);

            // Hata ayıklama: siparis_id 0 geliyorsa log'a yaz
            if ($siparisId <= 0) {
                error_log("[SiparisBL] siparisEkle sonucu: " . print_r($siparis, true));
                error_log("[SiparisBL] buket_id: " . $buket["buket_id"]);
                return ["success" => false, "message" => "Sipariş oluşturulamadı. (siparis_id alınamadı)"];
            }

            $this->siparisDAL->odemeEkle($siparisId, (float)$buket["toplam_fiyat"]);
            return ["success" => true, "message" => "Sipariş başarıyla oluşturuldu."];

        } catch (PDOException $e) {
            error_log("[SiparisBL] PDOException: " . $e->getMessage());
            return ["success" => false, "message" => $e->getMessage()];
        }
    }

    public function kullaniciSiparisleriListele(int $kullaniciId): array
    {
        return $this->siparisDAL->kullaniciSiparisleriListele($kullaniciId);
    }

    public function sonSiparisGetir(int $kullaniciId): ?array
    {
        $siparisler = $this->kullaniciSiparisleriListele($kullaniciId);
        return $siparisler[0] ?? null;
    }

    public function adminSiparisListele(): array
    {
        return $this->siparisDAL->adminSiparisListele();
    }

    public function durumGuncelle(int $siparisId, string $durum): array
    {
        $gecerliDurumlar = ["hazirlaniyor", "yolda", "teslim_edildi", "iptal_edildi"];

        if ($siparisId <= 0 || !in_array($durum, $gecerliDurumlar, true)) {
            return ["success" => false, "message" => "Sipariş durumu güncellenemedi."];
        }

        $this->siparisDAL->durumGuncelle($siparisId, $durum);
        return ["success" => true, "message" => "Sipariş durumu güncellendi."];
    }
}