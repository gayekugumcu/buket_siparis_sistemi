<?php

require_once __DIR__ . "/BaseDAL.php";

class AdminDAL extends BaseDAL
{
    public function istatistikListele(): ?array
    {
        return $this->fetchOneProcedure("CALL AdminIstatistikListele()");
    }
}