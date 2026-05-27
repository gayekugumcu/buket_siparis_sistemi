<?php

require_once __DIR__ . "/BaseDAL.php";

class CicekDAL extends BaseDAL
{
    public function listele(): array
    {
        return $this->fetchAllProcedure("CALL CicekListele()");
    }

    public function ekle(string $cicekAdi, float $birimFiyat, int $stokMiktari, string $gorsel): bool
    {
        return $this->executeProcedure(
            "CALL CicekEkle(:cicek_adi, :birim_fiyat, :stok_miktari, :gorsel)",
            [
                ":cicek_adi" => $cicekAdi,
                ":birim_fiyat" => $birimFiyat,
                ":stok_miktari" => $stokMiktari,
                ":gorsel" => $gorsel
            ]
        );
    }

    public function guncelle(int $cicekId, string $cicekAdi, float $birimFiyat, int $stokMiktari, string $gorsel): bool
    {
        return $this->executeProcedure(
            "CALL CicekGuncelle(:cicek_id, :cicek_adi, :birim_fiyat, :stok_miktari, :gorsel)",
            [
                ":cicek_id" => $cicekId,
                ":cicek_adi" => $cicekAdi,
                ":birim_fiyat" => $birimFiyat,
                ":stok_miktari" => $stokMiktari,
                ":gorsel" => $gorsel
            ]
        );
    }

    public function sil(int $cicekId): bool
    {
        return $this->executeProcedure(
            "CALL CicekSil(:cicek_id)",
            [":cicek_id" => $cicekId]
        );
    }
}