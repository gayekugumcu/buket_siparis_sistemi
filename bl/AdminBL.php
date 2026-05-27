<?php

require_once __DIR__ . "/../dal/AdminDAL.php";

class AdminBL
{
    private AdminDAL $adminDAL;

    public function __construct()
    {
        $this->adminDAL = new AdminDAL();
    }

    public function istatistikListele(): array
    {
        return $this->adminDAL->istatistikListele() ?? [
            "toplam_cicek" => 0,
            "toplam_buket" => 0,
            "toplam_siparis" => 0,
            "toplam_odeme" => 0
        ];
    }
}