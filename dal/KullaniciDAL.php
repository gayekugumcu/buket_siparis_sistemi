<?php

require_once __DIR__ . "/BaseDAL.php";

class KullaniciDAL extends BaseDAL
{
    public function mailIleGetir(string $mail): ?array
    {
        return $this->fetchOneProcedure(
            "CALL KullaniciMailIleGetir(:mail)",
            [":mail" => $mail]
        );
    }

    public function kullaniciGetir(int $kullaniciId): ?array
    {
        return $this->fetchOneProcedure(
            "CALL KullaniciGetir(:kullanici_id)",
            [":kullanici_id" => $kullaniciId]
        );
    }

    public function kullaniciEkle(string $ad, string $soyad, string $mail, string $sifre, string $telefon, string $rol): bool
    {
        return $this->executeProcedure(
            "CALL KullaniciEkle(:ad, :soyad, :mail, :sifre, :telefon, :rol)",
            [
                ":ad" => $ad,
                ":soyad" => $soyad,
                ":mail" => $mail,
                ":sifre" => $sifre,
                ":telefon" => $telefon,
                ":rol" => $rol
            ]
        );
    }
}