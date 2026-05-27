<?php

require_once __DIR__ . "/BaseDAL.php";

class SiparisDAL extends BaseDAL
{
    public function siparisEkle(int $buketId, string $adres, string $tarih, string $alici, string $telefon, string $kartMesaji): ?array
    {
        $stmt = $this->db->prepare(
            "CALL SiparisEkle(:buket_id, :teslimat_adresi, :teslimat_tarihi, :alici_ad_soyad, :alici_telefon, :kart_mesaji)"
        );
        $stmt->execute([
            ":buket_id"        => $buketId,
            ":teslimat_adresi" => $adres,
            ":teslimat_tarihi" => $tarih,
            ":alici_ad_soyad"  => $alici,
            ":alici_telefon"   => $telefon,
            ":kart_mesaji"     => $kartMesaji,
        ]);

        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        try {
            while ($stmt->nextRowset()) { $stmt->fetchAll(); }
        } catch (PDOException $e) { /* sürücü farklılıkları */ }

        $siparisId = (int)($row["siparis_id"] ?? $this->db->lastInsertId());

        error_log("[SiparisDAL] row=" . print_r($row, true) . " lastInsertId=" . $this->db->lastInsertId() . " siparisId=$siparisId");

        return $siparisId > 0 ? ["siparis_id" => $siparisId] : null;
    }

    public function odemeEkle(int $siparisId, float $tutar): bool
    {
        return $this->executeProcedure(
            "CALL OdemeEkle(:siparis_id, :odeme_tutari, :odeme_turu, :odeme_durumu)",
            [
                ":siparis_id"   => $siparisId,
                ":odeme_tutari" => $tutar,
                ":odeme_turu"   => "kredi_karti",
                ":odeme_durumu" => "odendi",
            ]
        );
    }

    public function kullaniciSiparisleriListele(int $kullaniciId): array
    {
        return $this->fetchAllProcedure(
            "CALL KullaniciSiparisleriListele(:kullanici_id)",
            [":kullanici_id" => $kullaniciId]
        );
    }

    public function adminSiparisListele(): array
    {
        return $this->fetchAllProcedure("CALL AdminSiparisListele()");
    }

    public function durumGuncelle(int $siparisId, string $durum): bool
    {
        return $this->executeProcedure(
            "CALL SiparisDurumGuncelle(:siparis_id, :siparis_durumu)",
            [
                ":siparis_id"     => $siparisId,
                ":siparis_durumu" => $durum,
            ]
        );
    }
}
