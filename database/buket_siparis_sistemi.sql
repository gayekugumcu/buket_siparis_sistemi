DROP DATABASE IF EXISTS buket_siparis_sistemi;
CREATE DATABASE buket_siparis_sistemi
CHARACTER SET utf8mb4
COLLATE utf8mb4_turkish_ci;

USE buket_siparis_sistemi;

CREATE TABLE kullanicilar (
    kullanici_id INT AUTO_INCREMENT PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    mail VARCHAR(100) NOT NULL UNIQUE,
    sifre VARCHAR(255) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    rol ENUM('musteri', 'yonetici') NOT NULL DEFAULT 'musteri',
    kayit_tarihi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cicekler (
    cicek_id INT AUTO_INCREMENT PRIMARY KEY,
    cicek_adi VARCHAR(100) NOT NULL,
    birim_fiyat DECIMAL(10,2) NOT NULL,
    stok_miktari INT NOT NULL DEFAULT 0,
    gorsel VARCHAR(255),
    CHECK (birim_fiyat >= 0),
    CHECK (stok_miktari >= 0)
);

CREATE TABLE buketler (
    buket_id INT AUTO_INCREMENT PRIMARY KEY,
    kullanici_id INT NOT NULL,
    olusturma_tarihi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    toplam_fiyat DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE buket_detaylari (
    buket_detay_id INT AUTO_INCREMENT PRIMARY KEY,
    buket_id INT NOT NULL,
    cicek_id INT NOT NULL,
    adet INT NOT NULL,
    UNIQUE (buket_id, cicek_id),
    FOREIGN KEY (buket_id) REFERENCES buketler(buket_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (cicek_id) REFERENCES cicekler(cicek_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK (adet > 0)
);

CREATE TABLE siparisler (
    siparis_id INT AUTO_INCREMENT PRIMARY KEY,
    buket_id INT NOT NULL UNIQUE,
    siparis_tarihi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    siparis_durumu ENUM('hazirlaniyor', 'yolda', 'teslim_edildi', 'iptal_edildi') NOT NULL DEFAULT 'hazirlaniyor',
    teslimat_adresi TEXT NOT NULL,
    teslimat_tarihi DATE NOT NULL,
    alici_ad_soyad VARCHAR(150) NOT NULL,
    alici_telefon VARCHAR(20) NOT NULL,
    kart_mesaji TEXT,
    FOREIGN KEY (buket_id) REFERENCES buketler(buket_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE odemeler (
    odeme_id INT AUTO_INCREMENT PRIMARY KEY,
    siparis_id INT NOT NULL UNIQUE,
    odeme_tarihi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    odeme_tutari DECIMAL(10,2) NOT NULL,
    odeme_turu ENUM('kredi_karti') NOT NULL DEFAULT 'kredi_karti',
    odeme_durumu ENUM('odendi', 'beklemede', 'iptal') NOT NULL DEFAULT 'odendi',
    FOREIGN KEY (siparis_id) REFERENCES siparisler(siparis_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK (odeme_tutari >= 0)
);

DELIMITER //

CREATE FUNCTION BuketToplamFiyat(p_buket_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE toplam DECIMAL(10,2);

    SELECT IFNULL(SUM(bd.adet * c.birim_fiyat), 0)
    INTO toplam
    FROM buket_detaylari bd
    INNER JOIN cicekler c ON bd.cicek_id = c.cicek_id
    WHERE bd.buket_id = p_buket_id;

    RETURN toplam;
END //

CREATE FUNCTION CicekStokKontrol(p_cicek_id INT, p_istenen_adet INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE mevcut_stok INT;

    SELECT IFNULL(stok_miktari, 0)
    INTO mevcut_stok
    FROM cicekler
    WHERE cicek_id = p_cicek_id;

    IF mevcut_stok >= p_istenen_adet THEN
        RETURN 'Stok Yeterli';
    ELSE
        RETURN 'Stok Yetersiz';
    END IF;
END //

CREATE TRIGGER TRG_BuketDetay_Insert_StokKontrol
BEFORE INSERT ON buket_detaylari
FOR EACH ROW
BEGIN
    IF NEW.adet <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Çiçek adedi sıfırdan büyük olmalıdır.';
    END IF;

    IF CicekStokKontrol(NEW.cicek_id, NEW.adet) = 'Stok Yetersiz' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'İstenen adet stok miktarını aştığı için çiçek bukete eklenemedi.';
    END IF;
END //

CREATE TRIGGER TRG_BuketDetay_Update_StokKontrol
BEFORE UPDATE ON buket_detaylari
FOR EACH ROW
BEGIN
    IF NEW.adet <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Çiçek adedi sıfırdan büyük olmalıdır.';
    END IF;

    IF CicekStokKontrol(NEW.cicek_id, NEW.adet) = 'Stok Yetersiz' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Güncellenen adet stok miktarını aşıyor.';
    END IF;
END //

CREATE TRIGGER TRG_BuketDetay_Insert_ToplamGuncelle
AFTER INSERT ON buket_detaylari
FOR EACH ROW
BEGIN
    UPDATE buketler
    SET toplam_fiyat = BuketToplamFiyat(NEW.buket_id)
    WHERE buket_id = NEW.buket_id;
END //

CREATE TRIGGER TRG_BuketDetay_Update_ToplamGuncelle
AFTER UPDATE ON buket_detaylari
FOR EACH ROW
BEGIN
    UPDATE buketler
    SET toplam_fiyat = BuketToplamFiyat(NEW.buket_id)
    WHERE buket_id = NEW.buket_id;
END //

CREATE TRIGGER TRG_BuketDetay_Delete_ToplamGuncelle
AFTER DELETE ON buket_detaylari
FOR EACH ROW
BEGIN
    UPDATE buketler
    SET toplam_fiyat = BuketToplamFiyat(OLD.buket_id)
    WHERE buket_id = OLD.buket_id;
END //

CREATE TRIGGER TRG_Siparis_Insert_StokAzalt
AFTER INSERT ON siparisler
FOR EACH ROW
BEGIN
    UPDATE cicekler c
    INNER JOIN buket_detaylari bd ON c.cicek_id = bd.cicek_id
    SET c.stok_miktari = c.stok_miktari - bd.adet
    WHERE bd.buket_id = NEW.buket_id;
END //

CREATE PROCEDURE KullaniciEkle(
    IN p_ad VARCHAR(100),
    IN p_soyad VARCHAR(100),
    IN p_mail VARCHAR(100),
    IN p_sifre VARCHAR(255),
    IN p_telefon VARCHAR(20),
    IN p_rol VARCHAR(20)
)
BEGIN
    INSERT INTO kullanicilar(ad, soyad, mail, sifre, telefon, rol)
    VALUES(p_ad, p_soyad, p_mail, p_sifre, p_telefon, p_rol);
END //

CREATE PROCEDURE KullaniciGuncelle(
    IN p_kullanici_id INT,
    IN p_ad VARCHAR(100),
    IN p_soyad VARCHAR(100),
    IN p_mail VARCHAR(100),
    IN p_sifre VARCHAR(255),
    IN p_telefon VARCHAR(20),
    IN p_rol VARCHAR(20)
)
BEGIN
    UPDATE kullanicilar
    SET ad = p_ad,
        soyad = p_soyad,
        mail = p_mail,
        sifre = p_sifre,
        telefon = p_telefon,
        rol = p_rol
    WHERE kullanici_id = p_kullanici_id;
END //

CREATE PROCEDURE KullaniciSil(IN p_kullanici_id INT)
BEGIN
    DELETE FROM kullanicilar WHERE kullanici_id = p_kullanici_id;
END //

CREATE PROCEDURE KullaniciListele()
BEGIN
    SELECT kullanici_id, ad, soyad, mail, sifre, telefon, rol, kayit_tarihi
    FROM kullanicilar
    ORDER BY kullanici_id DESC;
END //

CREATE PROCEDURE KullaniciGetir(IN p_kullanici_id INT)
BEGIN
    SELECT kullanici_id, ad, soyad, mail, sifre, telefon, rol, kayit_tarihi
    FROM kullanicilar
    WHERE kullanici_id = p_kullanici_id;
END //

CREATE PROCEDURE KullaniciMailIleGetir(IN p_mail VARCHAR(100))
BEGIN
    SELECT kullanici_id, ad, soyad, mail, sifre, telefon, rol, kayit_tarihi
    FROM kullanicilar
    WHERE mail = p_mail
    LIMIT 1;
END //

CREATE PROCEDURE CicekEkle(
    IN p_cicek_adi VARCHAR(100),
    IN p_birim_fiyat DECIMAL(10,2),
    IN p_stok_miktari INT,
    IN p_gorsel VARCHAR(255)
)
BEGIN
    INSERT INTO cicekler(cicek_adi, birim_fiyat, stok_miktari, gorsel)
    VALUES(p_cicek_adi, p_birim_fiyat, p_stok_miktari, p_gorsel);
END //

CREATE PROCEDURE CicekGuncelle(
    IN p_cicek_id INT,
    IN p_cicek_adi VARCHAR(100),
    IN p_birim_fiyat DECIMAL(10,2),
    IN p_stok_miktari INT,
    IN p_gorsel VARCHAR(255)
)
BEGIN
    UPDATE cicekler
    SET cicek_adi = p_cicek_adi,
        birim_fiyat = p_birim_fiyat,
        stok_miktari = p_stok_miktari,
        gorsel = p_gorsel
    WHERE cicek_id = p_cicek_id;
END //

CREATE PROCEDURE CicekSil(IN p_cicek_id INT)
BEGIN
    DELETE FROM cicekler WHERE cicek_id = p_cicek_id;
END //

CREATE PROCEDURE CicekListele()
BEGIN
    SELECT cicek_id, cicek_adi, birim_fiyat, stok_miktari, gorsel
    FROM cicekler
    ORDER BY cicek_id ASC;
END //

CREATE PROCEDURE CicekGetir(IN p_cicek_id INT)
BEGIN
    SELECT cicek_id, cicek_adi, birim_fiyat, stok_miktari, gorsel
    FROM cicekler
    WHERE cicek_id = p_cicek_id;
END //

CREATE PROCEDURE BuketEkle(
    IN p_kullanici_id INT
)
BEGIN
    INSERT INTO buketler(kullanici_id, toplam_fiyat)
    VALUES(p_kullanici_id, 0);

    SELECT LAST_INSERT_ID() AS buket_id;
END //

CREATE PROCEDURE BuketGuncelle(
    IN p_buket_id INT,
    IN p_kullanici_id INT,
    IN p_toplam_fiyat DECIMAL(10,2)
)
BEGIN
    UPDATE buketler
    SET kullanici_id = p_kullanici_id,
        toplam_fiyat = p_toplam_fiyat
    WHERE buket_id = p_buket_id;
END //

CREATE PROCEDURE BuketSil(IN p_buket_id INT)
BEGIN
    DELETE FROM buketler WHERE buket_id = p_buket_id;
END //

CREATE PROCEDURE BuketListele()
BEGIN
    SELECT buket_id, kullanici_id, olusturma_tarihi, toplam_fiyat
    FROM buketler
    ORDER BY buket_id DESC;
END //

CREATE PROCEDURE BuketGetir(IN p_buket_id INT)
BEGIN
    SELECT buket_id, kullanici_id, olusturma_tarihi, toplam_fiyat
    FROM buketler
    WHERE buket_id = p_buket_id;
END //

CREATE PROCEDURE AktifBuketGetir(IN p_kullanici_id INT)
BEGIN
    SELECT b.buket_id, b.kullanici_id, b.olusturma_tarihi, b.toplam_fiyat
    FROM buketler b
    LEFT JOIN siparisler s ON s.buket_id = b.buket_id
    WHERE b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL
    ORDER BY b.buket_id DESC
    LIMIT 1;
END //

CREATE PROCEDURE BuketDetayEkle(
    IN p_buket_id INT,
    IN p_cicek_id INT,
    IN p_adet INT
)
BEGIN
    INSERT INTO buket_detaylari(buket_id, cicek_id, adet)
    VALUES(p_buket_id, p_cicek_id, p_adet);
END //

CREATE PROCEDURE BuketDetayGuncelle(
    IN p_buket_detay_id INT,
    IN p_buket_id INT,
    IN p_cicek_id INT,
    IN p_adet INT
)
BEGIN
    UPDATE buket_detaylari
    SET buket_id = p_buket_id,
        cicek_id = p_cicek_id,
        adet = p_adet
    WHERE buket_detay_id = p_buket_detay_id;
END //

CREATE PROCEDURE BuketDetaySil(IN p_buket_detay_id INT)
BEGIN
    DELETE FROM buket_detaylari WHERE buket_detay_id = p_buket_detay_id;
END //

CREATE PROCEDURE BuketDetayListele()
BEGIN
    SELECT buket_detay_id, buket_id, cicek_id, adet
    FROM buket_detaylari
    ORDER BY buket_detay_id DESC;
END //

CREATE PROCEDURE BuketDetayGetir(IN p_buket_detay_id INT)
BEGIN
    SELECT buket_detay_id, buket_id, cicek_id, adet
    FROM buket_detaylari
    WHERE buket_detay_id = p_buket_detay_id;
END //

CREATE PROCEDURE BuketeCicekEkle(
    IN p_kullanici_id INT,
    IN p_cicek_id INT,
    IN p_adet INT
)
BEGIN
    DECLARE v_buket_id INT DEFAULT NULL;
    DECLARE v_buket_detay_id INT DEFAULT NULL;
    DECLARE v_mevcut_adet INT DEFAULT 0;

    SELECT b.buket_id
    INTO v_buket_id
    FROM buketler b
    LEFT JOIN siparisler s ON s.buket_id = b.buket_id
    WHERE b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL
    ORDER BY b.buket_id DESC
    LIMIT 1;

    IF v_buket_id IS NULL THEN
        INSERT INTO buketler(kullanici_id, toplam_fiyat)
        VALUES(p_kullanici_id, 0);
        SET v_buket_id = LAST_INSERT_ID();
    END IF;

    SELECT buket_detay_id, adet
    INTO v_buket_detay_id, v_mevcut_adet
    FROM buket_detaylari
    WHERE buket_id = v_buket_id
      AND cicek_id = p_cicek_id
    LIMIT 1;

    IF v_buket_detay_id IS NULL THEN
        INSERT INTO buket_detaylari(buket_id, cicek_id, adet)
        VALUES(v_buket_id, p_cicek_id, p_adet);
    ELSE
        UPDATE buket_detaylari
        SET adet = v_mevcut_adet + p_adet
        WHERE buket_detay_id = v_buket_detay_id;
    END IF;

    SELECT v_buket_id AS buket_id;
END //

CREATE PROCEDURE KullaniciAktifBuketDetaylari(IN p_kullanici_id INT)
BEGIN
    SELECT bd.buket_detay_id,
           bd.buket_id,
           bd.cicek_id,
           c.cicek_adi,
           c.birim_fiyat,
           c.gorsel,
           bd.adet,
           (bd.adet * c.birim_fiyat) AS satir_toplam
    FROM buketler b
    INNER JOIN buket_detaylari bd ON b.buket_id = bd.buket_id
    INNER JOIN cicekler c ON bd.cicek_id = c.cicek_id
    LEFT JOIN siparisler s ON s.buket_id = b.buket_id
    WHERE b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL
    ORDER BY bd.buket_detay_id ASC;
END //

CREATE PROCEDURE KullaniciBuketDetaySil(
    IN p_kullanici_id INT,
    IN p_buket_detay_id INT
)
BEGIN
    DELETE bd
    FROM buket_detaylari bd
    INNER JOIN buketler b ON bd.buket_id = b.buket_id
    LEFT JOIN siparisler s ON s.buket_id = b.buket_id
    WHERE bd.buket_detay_id = p_buket_detay_id
      AND b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL;
END //

CREATE PROCEDURE SiparisEkle(
    IN p_buket_id INT,
    IN p_teslimat_adresi TEXT,
    IN p_teslimat_tarihi DATE,
    IN p_alici_ad_soyad VARCHAR(150),
    IN p_alici_telefon VARCHAR(20),
    IN p_kart_mesaji TEXT
)
BEGIN
    INSERT INTO siparisler(
        buket_id,
        teslimat_adresi,
        teslimat_tarihi,
        alici_ad_soyad,
        alici_telefon,
        kart_mesaji
    )
    VALUES(
        p_buket_id,
        p_teslimat_adresi,
        p_teslimat_tarihi,
        p_alici_ad_soyad,
        p_alici_telefon,
        p_kart_mesaji
    );

    SELECT LAST_INSERT_ID() AS siparis_id;
END //

CREATE PROCEDURE SiparisGuncelle(
    IN p_siparis_id INT,
    IN p_siparis_durumu VARCHAR(30),
    IN p_teslimat_adresi TEXT,
    IN p_teslimat_tarihi DATE,
    IN p_alici_ad_soyad VARCHAR(150),
    IN p_alici_telefon VARCHAR(20),
    IN p_kart_mesaji TEXT
)
BEGIN
    UPDATE siparisler
    SET siparis_durumu = p_siparis_durumu,
        teslimat_adresi = p_teslimat_adresi,
        teslimat_tarihi = p_teslimat_tarihi,
        alici_ad_soyad = p_alici_ad_soyad,
        alici_telefon = p_alici_telefon,
        kart_mesaji = p_kart_mesaji
    WHERE siparis_id = p_siparis_id;
END //

CREATE PROCEDURE SiparisDurumGuncelle(
    IN p_siparis_id INT,
    IN p_siparis_durumu VARCHAR(30)
)
BEGIN
    UPDATE siparisler
    SET siparis_durumu = p_siparis_durumu
    WHERE siparis_id = p_siparis_id;
END //

CREATE PROCEDURE SiparisSil(IN p_siparis_id INT)
BEGIN
    DELETE FROM siparisler WHERE siparis_id = p_siparis_id;
END //

CREATE PROCEDURE SiparisListele()
BEGIN
    SELECT siparis_id, buket_id, siparis_tarihi, siparis_durumu,
           teslimat_adresi, teslimat_tarihi, alici_ad_soyad,
           alici_telefon, kart_mesaji
    FROM siparisler
    ORDER BY siparis_id DESC;
END //

CREATE PROCEDURE SiparisGetir(IN p_siparis_id INT)
BEGIN
    SELECT siparis_id, buket_id, siparis_tarihi, siparis_durumu,
           teslimat_adresi, teslimat_tarihi, alici_ad_soyad,
           alici_telefon, kart_mesaji
    FROM siparisler
    WHERE siparis_id = p_siparis_id;
END //

CREATE PROCEDURE KullaniciSiparisleriListele(IN p_kullanici_id INT)
BEGIN
    SELECT s.siparis_id,
           s.buket_id,
           s.siparis_tarihi,
           s.siparis_durumu,
           s.teslimat_adresi,
           s.teslimat_tarihi,
           s.alici_ad_soyad,
           s.alici_telefon,
           s.kart_mesaji,
           b.toplam_fiyat,
           o.odeme_turu,
           o.odeme_durumu,
           GROUP_CONCAT(CONCAT(c.cicek_adi, ' x ', bd.adet) SEPARATOR ', ') AS buket_icerigi
    FROM siparisler s
    INNER JOIN buketler b ON s.buket_id = b.buket_id
    LEFT JOIN odemeler o ON o.siparis_id = s.siparis_id
    INNER JOIN buket_detaylari bd ON bd.buket_id = b.buket_id
    INNER JOIN cicekler c ON c.cicek_id = bd.cicek_id
    WHERE b.kullanici_id = p_kullanici_id
    GROUP BY s.siparis_id, s.buket_id, s.siparis_tarihi, s.siparis_durumu,
             s.teslimat_adresi, s.teslimat_tarihi, s.alici_ad_soyad,
             s.alici_telefon, s.kart_mesaji, b.toplam_fiyat,
             o.odeme_turu, o.odeme_durumu
    ORDER BY s.siparis_id DESC;
END //

CREATE PROCEDURE AdminSiparisListele()
BEGIN
    SELECT s.siparis_id,
           s.buket_id,
           CONCAT(k.ad, ' ', k.soyad) AS musteri_ad_soyad,
           s.siparis_tarihi,
           s.siparis_durumu,
           s.teslimat_tarihi,
           s.alici_ad_soyad,
           b.toplam_fiyat,
           GROUP_CONCAT(CONCAT(c.cicek_adi, ' x ', bd.adet) SEPARATOR ', ') AS buket_icerigi
    FROM siparisler s
    INNER JOIN buketler b ON s.buket_id = b.buket_id
    INNER JOIN kullanicilar k ON b.kullanici_id = k.kullanici_id
    INNER JOIN buket_detaylari bd ON bd.buket_id = b.buket_id
    INNER JOIN cicekler c ON c.cicek_id = bd.cicek_id
    GROUP BY s.siparis_id, s.buket_id, musteri_ad_soyad, s.siparis_tarihi,
             s.siparis_durumu, s.teslimat_tarihi, s.alici_ad_soyad, b.toplam_fiyat
    ORDER BY s.siparis_id DESC;
END //

CREATE PROCEDURE OdemeEkle(
    IN p_siparis_id INT,
    IN p_odeme_tutari DECIMAL(10,2),
    IN p_odeme_turu VARCHAR(30),
    IN p_odeme_durumu VARCHAR(30)
)
BEGIN
    INSERT INTO odemeler(siparis_id, odeme_tutari, odeme_turu, odeme_durumu)
    VALUES(p_siparis_id, p_odeme_tutari, p_odeme_turu, p_odeme_durumu);
END //

CREATE PROCEDURE OdemeGuncelle(
    IN p_odeme_id INT,
    IN p_siparis_id INT,
    IN p_odeme_tutari DECIMAL(10,2),
    IN p_odeme_turu VARCHAR(30),
    IN p_odeme_durumu VARCHAR(30)
)
BEGIN
    UPDATE odemeler
    SET siparis_id = p_siparis_id,
        odeme_tutari = p_odeme_tutari,
        odeme_turu = p_odeme_turu,
        odeme_durumu = p_odeme_durumu
    WHERE odeme_id = p_odeme_id;
END //

CREATE PROCEDURE OdemeSil(IN p_odeme_id INT)
BEGIN
    DELETE FROM odemeler WHERE odeme_id = p_odeme_id;
END //

CREATE PROCEDURE OdemeListele()
BEGIN
    SELECT odeme_id, siparis_id, odeme_tarihi, odeme_tutari, odeme_turu, odeme_durumu
    FROM odemeler
    ORDER BY odeme_id DESC;
END //

CREATE PROCEDURE OdemeGetir(IN p_odeme_id INT)
BEGIN
    SELECT odeme_id, siparis_id, odeme_tarihi, odeme_tutari, odeme_turu, odeme_durumu
    FROM odemeler
    WHERE odeme_id = p_odeme_id;
END //

CREATE PROCEDURE AdminIstatistikListele()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM cicekler) AS toplam_cicek,
        (SELECT COUNT(*) FROM buketler) AS toplam_buket,
        (SELECT COUNT(*) FROM siparisler) AS toplam_siparis,
        (SELECT COUNT(*) FROM odemeler) AS toplam_odeme;
END //

DELIMITER ;

INSERT INTO kullanicilar(ad, soyad, mail, sifre, telefon, rol) VALUES
('Admin', 'Floria', 'admin@floria.com', '$2y$12$QpG4E/KL4z/yRCouaGDejetsGdg/WF8FdvEyD07v3d15JIKN620X6', '05000000000', 'yonetici'),
('Gaye', 'Kuğumcu', 'musteri@floria.com', '$2y$12$.4LkJfwzEEgdt/XMUo13NOxtvoqHLq3iIq2o2k3/jhoOqqjnq3rg2', '05555555555', 'musteri');

INSERT INTO cicekler(cicek_adi, birim_fiyat, stok_miktari, gorsel) VALUES
('Beyaz Zambak', 85.00, 24, 'assets/img/hero-flower.png'),
('Toz Pembe Gül', 65.00, 18, 'assets/img/hero-flower.png'),
('Lale', 45.00, 30, 'assets/img/hero-flower.png'),
('Lavanta', 40.00, 12, 'assets/img/hero-flower.png'),
('Papatya', 35.00, 28, 'assets/img/hero-flower.png'),
('Orkide', 120.00, 3, 'assets/img/hero-flower.png'),
('Karanfil', 30.00, 40, 'assets/img/hero-flower.png'),
('Şakayık', 95.00, 10, 'assets/img/hero-flower.png');
