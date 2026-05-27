<?php

require_once __DIR__ . "/../config/database.php";

class BaseDAL
{
    protected PDO $db;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->connect();
    }

    protected function fetchAllProcedure(string $sql, array $params = []): array
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        $result = $stmt->fetchAll();

        while ($stmt->nextRowset()) {
        }

        return $result;
    }

    protected function fetchOneProcedure(string $sql, array $params = []): ?array
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        $result = $stmt->fetch();

        while ($stmt->nextRowset()) {
        }

        return $result ?: null;
    }

    protected function executeProcedure(string $sql, array $params = []): bool
    {
        $stmt = $this->db->prepare($sql);
        $success = $stmt->execute($params);

        try {
            while ($stmt->nextRowset()) {
            }
        } catch (PDOException $e) {
        }

        return $success;
    }
}