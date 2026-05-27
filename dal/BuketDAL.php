<?php

require_once __DIR__ . "/BaseDAL.php";

class BuketDAL extends BaseDAL
{
    public function aktifBuketGetir(int $kullaniciId): ?array
    {
        return $this->fetchOneProcedure(
            "CALL AktifBuketGetir(:kullanici_id)",
            [":kullanici_id" => $kullaniciId]
        );
    }

    public function buketEkle(int $kullaniciId): ?array
    {
        $stmt = $this->db->prepare("CALL BuketEkle(:kullanici_id)");
        $stmt->execute([":kullanici_id" => $kullaniciId]);

        do { $stmt->fetchAll(); } while ($stmt->nextRowset());

        $id = (int) $this->db->lastInsertId();

        return $id > 0 ? ["buket_id" => $id] : null;
    }

    public function buketeCicekEkle(int $kullaniciId, int $cicekId, int $adet): ?array
    {
        return $this->fetchOneProcedure(
            "CALL BuketeCicekEkle(:kullanici_id, :cicek_id, :adet)",
            [
                ":kullanici_id" => $kullaniciId,
                ":cicek_id"     => $cicekId,
                ":adet"         => $adet,
            ]
        );
    }

    public function aktifBuketDetaylari(int $kullaniciId): array
    {
        return $this->fetchAllProcedure(
            "CALL KullaniciAktifBuketDetaylari(:kullanici_id)",
            [":kullanici_id" => $kullaniciId]
        );
    }

    public function bukettenCicekSil(int $kullaniciId, int $buketDetayId): bool
    {
        return $this->executeProcedure(
            "CALL KullaniciBuketDetaySil(:kullanici_id, :buket_detay_id)",
            [
                ":kullanici_id"    => $kullaniciId,
                ":buket_detay_id"  => $buketDetayId,
            ]
        );
    }
}