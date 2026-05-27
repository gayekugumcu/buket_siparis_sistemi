<?php

class Database
{
    private string $host     = "127.0.0.1";
    private string $port     = "3307";
    private string $dbName   = "buket_siparis_sistemi";
    private string $username = "root";
    private string $password = "13072006";

    public function connect(): PDO
    {
        $dsn = "mysql:host={$this->host};port={$this->port};dbname={$this->dbName};charset=utf8mb4";

        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_turkish_ci",
        ];

        try {
            return new PDO($dsn, $this->username, $this->password, $options);
        } catch (PDOException $e) {
            // Üretim ortamında hata detayını gizle
            error_log("Veritabanı bağlantı hatası: " . $e->getMessage());
            throw new RuntimeException("Veritabanına bağlanılamadı. Lütfen daha sonra tekrar deneyin.");
        }
    }
}