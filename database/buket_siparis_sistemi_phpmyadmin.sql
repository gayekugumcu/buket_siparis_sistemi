-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1:3307
-- Üretim Zamanı: 31 May 2026, 19:07:13
-- Sunucu sürümü: 10.4.32-MariaDB
-- PHP Sürümü: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Veritabanı: `buket_siparis_sistemi`
--

DELIMITER $$
--
-- Yordamlar
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AdminIstatistikListele` ()   BEGIN
    SELECT
        (SELECT COUNT(*) FROM cicekler) AS toplam_cicek,
        (SELECT COUNT(*) FROM buketler) AS toplam_buket,
        (SELECT COUNT(*) FROM siparisler) AS toplam_siparis,
        (SELECT COUNT(*) FROM odemeler) AS toplam_odeme;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AdminSiparisListele` ()   BEGIN
    SELECT 
        s.siparis_id,
        s.buket_id,
        CONCAT(k.ad, ' ', k.soyad) AS musteri_ad_soyad,
        s.siparis_tarihi,
        s.siparis_durumu,
        s.teslimat_adresi,
        s.teslimat_tarihi,
        s.alici_ad_soyad,
        s.alici_telefon,
        s.kart_mesaji,
        b.toplam_fiyat,
        GROUP_CONCAT(CONCAT(c.cicek_adi, ' x ', bd.adet) SEPARATOR ', ') AS buket_icerigi
    FROM siparisler s
    INNER JOIN buketler b ON s.buket_id = b.buket_id
    INNER JOIN kullanicilar k ON b.kullanici_id = k.kullanici_id
    INNER JOIN buket_detaylari bd ON b.buket_id = bd.buket_id
    INNER JOIN cicekler c ON bd.cicek_id = c.cicek_id
    GROUP BY
        s.siparis_id,
        s.buket_id,
        musteri_ad_soyad,
        s.siparis_tarihi,
        s.siparis_durumu,
        s.teslimat_adresi,
        s.teslimat_tarihi,
        s.alici_ad_soyad,
        s.alici_telefon,
        s.kart_mesaji,
        b.toplam_fiyat
    ORDER BY s.siparis_tarihi DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AktifBuketGetir` (`p_kullanici_id` INT)   BEGIN
    SELECT b.buket_id, b.kullanici_id, b.olusturma_tarihi, b.toplam_fiyat
    FROM buketler b
    LEFT JOIN siparisler s ON b.buket_id = s.buket_id
    WHERE b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL
    ORDER BY b.olusturma_tarihi DESC
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketDetayEkle` (`p_buket_id` INT, `p_cicek_id` INT, `p_adet` INT)   BEGIN
    IF CicekStokKontrol(p_cicek_id, p_adet) = 'Stok Yetersiz' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'İstenen adet stok miktarını aştığı için çiçek bukete eklenemedi.';
    ELSE
        INSERT INTO buket_detaylari(buket_id, cicek_id, adet)
        VALUES(p_buket_id, p_cicek_id, p_adet);

        UPDATE buketler
        SET toplam_fiyat = BuketToplamFiyat(p_buket_id)
        WHERE buket_id = p_buket_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketDetayGuncelle` (`p_buket_detay_id` INT, `p_adet` INT)   BEGIN
    DECLARE v_buket_id INT;
    DECLARE v_cicek_id INT;

    SELECT buket_id, cicek_id
    INTO v_buket_id, v_cicek_id
    FROM buket_detaylari
    WHERE buket_detay_id = p_buket_detay_id;

    IF CicekStokKontrol(v_cicek_id, p_adet) = 'Stok Yetersiz' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'İstenen adet stok miktarını aştığı için buket güncellenemedi.';
    ELSE
        UPDATE buket_detaylari
        SET adet = p_adet
        WHERE buket_detay_id = p_buket_detay_id;

        UPDATE buketler
        SET toplam_fiyat = BuketToplamFiyat(v_buket_id)
        WHERE buket_id = v_buket_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketDetayListele` ()   BEGIN
    SELECT buket_detaylari.buket_detay_id,
           buket_detaylari.buket_id,
           buket_detaylari.cicek_id,
           cicekler.cicek_adi,
           buket_detaylari.adet,
           cicekler.birim_fiyat,
           (buket_detaylari.adet * cicekler.birim_fiyat) AS ara_toplam
    FROM buket_detaylari, cicekler
    WHERE buket_detaylari.cicek_id = cicekler.cicek_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketDetaySil` (`p_buket_detay_id` INT)   BEGIN
    DECLARE v_buket_id INT;

    SELECT buket_id
    INTO v_buket_id
    FROM buket_detaylari
    WHERE buket_detay_id = p_buket_detay_id;

    DELETE FROM buket_detaylari
    WHERE buket_detay_id = p_buket_detay_id;

    UPDATE buketler
    SET toplam_fiyat = BuketToplamFiyat(v_buket_id)
    WHERE buket_id = v_buket_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketeCicekEkle` (`p_kullanici_id` INT, `p_cicek_id` INT, `p_adet` INT)   BEGIN
    DECLARE v_buket_id INT DEFAULT 0;
    DECLARE v_detay_id INT DEFAULT 0;
    DECLARE v_mevcut_adet INT DEFAULT 0;
    DECLARE v_yeni_adet INT DEFAULT 0;

    SELECT COALESCE((
        SELECT b.buket_id
        FROM buketler b
        LEFT JOIN siparisler s ON b.buket_id = s.buket_id
        WHERE b.kullanici_id = p_kullanici_id
          AND s.siparis_id IS NULL
        ORDER BY b.olusturma_tarihi DESC
        LIMIT 1
    ), 0)
    INTO v_buket_id;

    IF v_buket_id = 0 THEN
        INSERT INTO buketler(kullanici_id, toplam_fiyat)
        VALUES(p_kullanici_id, 0);

        SET v_buket_id = LAST_INSERT_ID();
    END IF;

    SELECT COALESCE(MAX(buket_detay_id), 0), COALESCE(MAX(adet), 0)
    INTO v_detay_id, v_mevcut_adet
    FROM buket_detaylari
    WHERE buket_id = v_buket_id
      AND cicek_id = p_cicek_id;

    SET v_yeni_adet = v_mevcut_adet + p_adet;

    IF CicekStokKontrol(p_cicek_id, v_yeni_adet) = 'Stok Yetersiz' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'İstenen adet stok miktarını aştığı için çiçek bukete eklenemedi.';
    ELSE
        IF v_detay_id = 0 THEN
            INSERT INTO buket_detaylari(buket_id, cicek_id, adet)
            VALUES(v_buket_id, p_cicek_id, p_adet);
        ELSE
            UPDATE buket_detaylari
            SET adet = v_yeni_adet
            WHERE buket_detay_id = v_detay_id;
        END IF;

        UPDATE buketler
        SET toplam_fiyat = BuketToplamFiyat(v_buket_id)
        WHERE buket_id = v_buket_id;
    END IF;

    SELECT v_buket_id AS buket_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketEkle` (`p_kullanici_id` INT)   BEGIN
    INSERT INTO buketler(kullanici_id, toplam_fiyat)
    VALUES(p_kullanici_id, 0);

    SELECT LAST_INSERT_ID() AS yeni_buket_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketGuncelle` (`p_buket_id` INT, `p_kullanici_id` INT)   BEGIN
    UPDATE buketler
    SET kullanici_id = p_kullanici_id,
        toplam_fiyat = BuketToplamFiyat(p_buket_id)
    WHERE buket_id = p_buket_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketListele` ()   BEGIN
    SELECT buketler.buket_id,
           buketler.kullanici_id,
           kullanicilar.ad,
           kullanicilar.soyad,
           buketler.olusturma_tarihi,
           buketler.toplam_fiyat
    FROM buketler, kullanicilar
    WHERE buketler.kullanici_id = kullanicilar.kullanici_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuketSil` (`p_buket_id` INT)   BEGIN
    DELETE FROM buketler
    WHERE buket_id = p_buket_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CicekEkle` (`p_cicek_adi` VARCHAR(100), `p_birim_fiyat` DECIMAL(10,2), `p_stok_miktari` INT, `p_gorsel` VARCHAR(255))   BEGIN
    INSERT INTO cicekler(cicek_adi, birim_fiyat, stok_miktari, gorsel)
    VALUES(p_cicek_adi, p_birim_fiyat, p_stok_miktari, p_gorsel);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CicekGuncelle` (`p_cicek_id` INT, `p_cicek_adi` VARCHAR(100), `p_birim_fiyat` DECIMAL(10,2), `p_stok_miktari` INT, `p_gorsel` VARCHAR(255))   BEGIN
    UPDATE cicekler
    SET cicek_adi = p_cicek_adi,
        birim_fiyat = p_birim_fiyat,
        stok_miktari = p_stok_miktari,
        gorsel = p_gorsel
    WHERE cicek_id = p_cicek_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CicekListele` ()   BEGIN
    SELECT cicek_id, cicek_adi, birim_fiyat, stok_miktari, gorsel
    FROM cicekler;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CicekSil` (`p_cicek_id` INT)   BEGIN
    DELETE FROM cicekler
    WHERE cicek_id = p_cicek_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciAktifBuketDetaylari` (`p_kullanici_id` INT)   BEGIN
    SELECT 
        bd.buket_detay_id,
        bd.buket_id,
        bd.cicek_id,
        c.cicek_adi,
        bd.adet,
        c.birim_fiyat,
        (bd.adet * c.birim_fiyat) AS satir_toplam
    FROM buket_detaylari bd
    INNER JOIN cicekler c ON bd.cicek_id = c.cicek_id
    INNER JOIN buketler b ON bd.buket_id = b.buket_id
    LEFT JOIN siparisler s ON b.buket_id = s.buket_id
    WHERE b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL
    ORDER BY bd.buket_detay_id DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciBuketDetaySil` (`p_kullanici_id` INT, `p_buket_detay_id` INT)   BEGIN
    DECLARE v_buket_id INT DEFAULT 0;

    SELECT COALESCE(MAX(b.buket_id), 0)
    INTO v_buket_id
    FROM buket_detaylari bd
    INNER JOIN buketler b ON bd.buket_id = b.buket_id
    LEFT JOIN siparisler s ON b.buket_id = s.buket_id
    WHERE bd.buket_detay_id = p_buket_detay_id
      AND b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL;

    DELETE bd
    FROM buket_detaylari bd
    INNER JOIN buketler b ON bd.buket_id = b.buket_id
    LEFT JOIN siparisler s ON b.buket_id = s.buket_id
    WHERE bd.buket_detay_id = p_buket_detay_id
      AND b.kullanici_id = p_kullanici_id
      AND s.siparis_id IS NULL;

    IF v_buket_id > 0 THEN
        UPDATE buketler
        SET toplam_fiyat = BuketToplamFiyat(v_buket_id)
        WHERE buket_id = v_buket_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciEkle` (`p_ad` VARCHAR(100), `p_soyad` VARCHAR(100), `p_mail` VARCHAR(150), `p_sifre` VARCHAR(255), `p_telefon` VARCHAR(20), `p_rol` VARCHAR(20))   BEGIN
    INSERT INTO kullanicilar(ad, soyad, mail, sifre, telefon, rol)
    VALUES (p_ad, p_soyad, p_mail, p_sifre, p_telefon, p_rol);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciGetir` (`p_kullanici_id` INT)   BEGIN
    SELECT kullanici_id, ad, soyad, mail, telefon, rol
    FROM kullanicilar
    WHERE kullanici_id = p_kullanici_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciGuncelle` (`p_kullanici_id` INT, `p_ad` VARCHAR(100), `p_soyad` VARCHAR(100), `p_mail` VARCHAR(150), `p_sifre` VARCHAR(255), `p_telefon` VARCHAR(20), `p_rol` VARCHAR(20))   BEGIN
    UPDATE kullanicilar
    SET ad = p_ad,
        soyad = p_soyad,
        mail = p_mail,
        sifre = p_sifre,
        telefon = p_telefon,
        rol = p_rol
    WHERE kullanici_id = p_kullanici_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciListele` ()   BEGIN
    SELECT kullanici_id, ad, soyad, mail, sifre, telefon, rol
    FROM kullanicilar;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciMailIleGetir` (`p_mail` VARCHAR(150))   BEGIN
    SELECT kullanici_id, ad, soyad, mail, sifre, telefon, rol
    FROM kullanicilar
    WHERE mail = p_mail
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciSil` (`p_kullanici_id` INT)   BEGIN
    DELETE FROM kullanicilar
    WHERE kullanici_id = p_kullanici_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciSiparisleriListele` (`p_kullanici_id` INT)   BEGIN
    SELECT 
        s.siparis_id,
        s.buket_id,
        s.siparis_tarihi,
        s.siparis_durumu,
        s.teslimat_adresi,
        s.teslimat_tarihi,
        s.alici_ad_soyad,
        s.alici_telefon,
        s.kart_mesaji,
        b.toplam_fiyat,
        GROUP_CONCAT(CONCAT(c.cicek_adi, ' x ', bd.adet) SEPARATOR ', ') AS buket_icerigi
    FROM siparisler s
    INNER JOIN buketler b ON s.buket_id = b.buket_id
    INNER JOIN buket_detaylari bd ON b.buket_id = bd.buket_id
    INNER JOIN cicekler c ON bd.cicek_id = c.cicek_id
    WHERE b.kullanici_id = p_kullanici_id
    GROUP BY
        s.siparis_id,
        s.buket_id,
        s.siparis_tarihi,
        s.siparis_durumu,
        s.teslimat_adresi,
        s.teslimat_tarihi,
        s.alici_ad_soyad,
        s.alici_telefon,
        s.kart_mesaji,
        b.toplam_fiyat
    ORDER BY s.siparis_tarihi DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KullaniciSonSiparisGetir` (`p_kullanici_id` INT)   BEGIN
    SELECT 
        s.siparis_id,
        s.siparis_tarihi,
        s.siparis_durumu,
        s.teslimat_tarihi,
        s.alici_ad_soyad,
        b.toplam_fiyat
    FROM siparisler s
    INNER JOIN buketler b ON s.buket_id = b.buket_id
    WHERE b.kullanici_id = p_kullanici_id
    ORDER BY s.siparis_tarihi DESC
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `OdemeEkle` (IN `p_siparis_id` INT, IN `p_odeme_tutari` DECIMAL(10,2), IN `p_odeme_turu` VARCHAR(30), IN `p_odeme_durumu` VARCHAR(30))   BEGIN
    INSERT INTO odemeler(siparis_id, odeme_tutari, odeme_turu, odeme_durumu)
    VALUES(p_siparis_id, p_odeme_tutari, p_odeme_turu, p_odeme_durumu);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `OdemeGuncelle` (`p_odeme_id` INT, `p_odeme_durumu` VARCHAR(20))   BEGIN
    UPDATE odemeler
    SET odeme_durumu = p_odeme_durumu
    WHERE odeme_id = p_odeme_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `OdemeListele` ()   BEGIN
    SELECT odemeler.odeme_id,
           odemeler.siparis_id,
           odemeler.odeme_tarihi,
           odemeler.odeme_tutari,
           odemeler.odeme_turu,
           odemeler.odeme_durumu,
           siparisler.siparis_durumu
    FROM odemeler, siparisler
    WHERE odemeler.siparis_id = siparisler.siparis_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `OdemeSil` (`p_odeme_id` INT)   BEGIN
    DELETE FROM odemeler
    WHERE odeme_id = p_odeme_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SiparisDurumGuncelle` (`p_siparis_id` INT, `p_siparis_durumu` VARCHAR(20))   BEGIN
    UPDATE siparisler
    SET siparis_durumu = p_siparis_durumu
    WHERE siparis_id = p_siparis_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SiparisEkle` (`p_buket_id` INT, `p_teslimat_adresi` VARCHAR(300), `p_teslimat_tarihi` DATE, `p_alici_ad_soyad` VARCHAR(150), `p_alici_telefon` VARCHAR(20), `p_kart_mesaji` VARCHAR(250))   BEGIN 
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SiparisEkleVeGetir` (`p_buket_id` INT, `p_teslimat_adresi` VARCHAR(300), `p_teslimat_tarihi` DATE, `p_alici_ad_soyad` VARCHAR(150), `p_alici_telefon` VARCHAR(20), `p_kart_mesaji` VARCHAR(250))   BEGIN
    DECLARE v_detay_sayisi INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_detay_sayisi
    FROM buket_detaylari
    WHERE buket_id = p_buket_id;

    IF v_detay_sayisi = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Boş buket için sipariş oluşturulamaz.';
    ELSE
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
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SiparisGuncelle` (`p_siparis_id` INT, `p_siparis_durumu` VARCHAR(20), `p_teslimat_adresi` VARCHAR(300), `p_teslimat_tarihi` DATE, `p_alici_ad_soyad` VARCHAR(150), `p_alici_telefon` VARCHAR(20), `p_kart_mesaji` VARCHAR(250))   BEGIN
    UPDATE siparisler
    SET siparis_durumu = p_siparis_durumu,
        teslimat_adresi = p_teslimat_adresi,
        teslimat_tarihi = p_teslimat_tarihi,
        alici_ad_soyad = p_alici_ad_soyad,
        alici_telefon = p_alici_telefon,
        kart_mesaji = p_kart_mesaji
    WHERE siparis_id = p_siparis_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SiparisListele` ()   BEGIN
    SELECT siparisler.siparis_id,
           siparisler.buket_id,
           kullanicilar.ad,
           kullanicilar.soyad,
           siparisler.siparis_tarihi,
           siparisler.siparis_durumu,
           siparisler.teslimat_adresi,
           siparisler.teslimat_tarihi,
           siparisler.alici_ad_soyad,
           siparisler.alici_telefon,
           siparisler.kart_mesaji,
           buketler.toplam_fiyat
    FROM siparisler, buketler, kullanicilar
    WHERE siparisler.buket_id = buketler.buket_id
      AND buketler.kullanici_id = kullanicilar.kullanici_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SiparisSil` (`p_siparis_id` INT)   BEGIN
    DELETE FROM siparisler
    WHERE siparis_id = p_siparis_id;
END$$

--
-- İşlevler
--
CREATE DEFINER=`root`@`localhost` FUNCTION `BuketToplamFiyat` (`p_buket_id` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
	DECLARE toplam DECIMAL(10,2);
	SELECT IFNULL(SUM(buket_detaylari.adet*cicekler.birim_fiyat),0)
    INTO toplam
    FROM buket_detaylari, cicekler
    WHERE buket_detaylari.cicek_id = cicekler.cicek_id
    AND buket_detaylari.buket_id = p_buket_id;
    RETURN toplam;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `CicekStokKontrol` (`p_cicek_id` INT, `p_istenen_adet` INT) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
	DECLARE mevcut_stok INT;
    SELECT IFNULL(MAX(stok_miktari ),0)
    INTO mevcut_stok 
    FROM cicekler 
    WHERE cicek_id = p_cicek_id;
    
    IF mevcut_stok >= p_istenen_adet THEN
		RETURN 'Stok Yeterli';
	ELSE 
		RETURN 'Stok Yetersiz';
	END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `buketler`
--

CREATE TABLE `buketler` (
  `buket_id` int(11) NOT NULL,
  `kullanici_id` int(11) NOT NULL,
  `olusturma_tarihi` datetime NOT NULL DEFAULT current_timestamp(),
  `toplam_fiyat` decimal(10,2) NOT NULL DEFAULT 0.00 CHECK (`toplam_fiyat` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `buketler`
--

INSERT INTO `buketler` (`buket_id`, `kullanici_id`, `olusturma_tarihi`, `toplam_fiyat`) VALUES
(6, 4, '2026-05-27 10:48:28', 75.00),
(7, 4, '2026-05-27 10:50:38', 330.00),
(8, 4, '2026-05-27 10:53:03', 125.00),
(10, 4, '2026-05-31 13:29:51', 175.00),
(12, 4, '2026-05-31 13:43:41', 170.00),
(14, 4, '2026-05-31 13:56:31', 105.00),
(15, 4, '2026-05-31 14:25:21', 80.00);

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `buket_detaylari`
--

CREATE TABLE `buket_detaylari` (
  `buket_detay_id` int(11) NOT NULL,
  `buket_id` int(11) NOT NULL,
  `cicek_id` int(11) NOT NULL,
  `adet` int(11) NOT NULL CHECK (`adet` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `buket_detaylari`
--

INSERT INTO `buket_detaylari` (`buket_detay_id`, `buket_id`, `cicek_id`, `adet`) VALUES
(21, 6, 8, 1),
(22, 6, 7, 1),
(23, 7, 3, 2),
(24, 7, 6, 3),
(25, 7, 1, 2),
(26, 8, 4, 3),
(27, 8, 11, 1),
(29, 10, 2, 1),
(30, 10, 3, 1),
(33, 12, 6, 1),
(34, 12, 5, 1),
(37, 14, 7, 1),
(38, 14, 6, 1),
(39, 15, 11, 1),
(40, 15, 8, 1);

--
-- Tetikleyiciler `buket_detaylari`
--
DELIMITER $$
CREATE TRIGGER `StokKontrol` BEFORE INSERT ON `buket_detaylari` FOR EACH ROW BEGIN
    IF CicekStokKontrol(NEW.cicek_id, NEW.adet) = 'Stok Yetersiz' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'İstenen adet stok miktarını aştığı için çiçek bukete eklenemedi.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `cicekler`
--

CREATE TABLE `cicekler` (
  `cicek_id` int(11) NOT NULL,
  `cicek_adi` varchar(100) NOT NULL,
  `birim_fiyat` decimal(10,2) NOT NULL CHECK (`birim_fiyat` > 0),
  `stok_miktari` int(11) NOT NULL DEFAULT 0 CHECK (`stok_miktari` >= 0),
  `gorsel` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `cicekler`
--

INSERT INTO `cicekler` (`cicek_id`, `cicek_adi`, `birim_fiyat`, `stok_miktari`, `gorsel`) VALUES
(1, 'Baby\'s Breath', 20.00, 9, 'assets/img/cicekler/cipso.jpg'),
(2, 'Orkide', 120.00, 8, 'assets/img/cicekler/orkide.jpg'),
(3, 'Raninkül', 55.00, 5, 'assets/img/cicekler/raninkul.jpg'),
(4, 'Papatya', 25.00, 23, 'assets/img/cicekler/papatya.jpg'),
(5, 'Şakayık', 110.00, 10, 'assets/img/cicekler/sakayik.jpg'),
(6, 'Lisianthus', 60.00, 7, 'assets/img/cicekler/lisianthus.jpg'),
(7, 'Lale', 45.00, 16, 'assets/img/cicekler/lale.jpg'),
(8, 'Karanfil', 30.00, 7, 'assets/img/cicekler/karanfil.jpg'),
(9, 'Gerbera', 35.00, 0, 'assets/img/cicekler/gerbera.jpg'),
(10, 'Sardunya', 40.00, 20, 'assets/img/cicekler/sardunya.jpg'),
(11, 'Leylak', 50.00, 17, 'assets/img/cicekler/leylak.jpg'),
(12, 'Anthurium', 85.00, 18, 'assets/img/cicekler/anthurium.jpg');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `kullanicilar`
--

CREATE TABLE `kullanicilar` (
  `kullanici_id` int(11) NOT NULL,
  `ad` varchar(100) NOT NULL,
  `soyad` varchar(100) NOT NULL,
  `mail` varchar(150) NOT NULL CHECK (`mail` like '%@%.%'),
  `sifre` varchar(255) NOT NULL,
  `telefon` varchar(20) NOT NULL,
  `rol` varchar(20) NOT NULL DEFAULT 'musteri' CHECK (`rol` in ('musteri','yonetici'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `kullanicilar`
--

INSERT INTO `kullanicilar` (`kullanici_id`, `ad`, `soyad`, `mail`, `sifre`, `telefon`, `rol`) VALUES
(1, 'Floria', 'Admin', 'admin@gmail.com', '$2y$10$S68Oyo0sSMPh4.v6h/ItJe2OJalLmpp/rz5p.WSeHOnJSnOx/x1/2', '05433253628', 'yonetici'),
(4, 'Gaye', 'Kuğumcu', 'gayem@gmail.com', '$2y$10$BuIYWL42No.nzIjnsyty9OkcAgXLUOvV3m0sxnQdqkWa27HsbPROC', '05433243628', 'musteri');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `odemeler`
--

CREATE TABLE `odemeler` (
  `odeme_id` int(11) NOT NULL,
  `siparis_id` int(11) NOT NULL,
  `odeme_tarihi` datetime NOT NULL DEFAULT current_timestamp(),
  `odeme_tutari` decimal(10,2) NOT NULL CHECK (`odeme_tutari` > 0),
  `odeme_turu` varchar(20) NOT NULL DEFAULT 'kredi_karti' CHECK (`odeme_turu` = 'kredi_karti'),
  `odeme_durumu` varchar(20) NOT NULL DEFAULT 'odendi' CHECK (`odeme_durumu` in ('odendi','basarisiz'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `odemeler`
--

INSERT INTO `odemeler` (`odeme_id`, `siparis_id`, `odeme_tarihi`, `odeme_tutari`, `odeme_turu`, `odeme_durumu`) VALUES
(2, 9, '2026-05-27 10:49:01', 75.00, 'kredi_karti', 'odendi'),
(3, 10, '2026-05-27 10:52:55', 330.00, 'kredi_karti', 'odendi'),
(4, 11, '2026-05-27 10:53:43', 125.00, 'kredi_karti', 'odendi'),
(5, 12, '2026-05-31 13:32:18', 175.00, 'kredi_karti', 'odendi'),
(6, 13, '2026-05-31 13:45:18', 170.00, 'kredi_karti', 'odendi'),
(7, 14, '2026-05-31 13:58:30', 105.00, 'kredi_karti', 'odendi'),
(8, 15, '2026-05-31 14:26:16', 80.00, 'kredi_karti', 'odendi');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `siparisler`
--

CREATE TABLE `siparisler` (
  `siparis_id` int(11) NOT NULL,
  `buket_id` int(11) NOT NULL,
  `siparis_tarihi` datetime NOT NULL DEFAULT current_timestamp(),
  `siparis_durumu` varchar(20) NOT NULL DEFAULT 'hazirlaniyor' CHECK (`siparis_durumu` in ('hazirlaniyor','yolda','teslim_edildi','iptal edildi')),
  `teslimat_adresi` varchar(300) NOT NULL,
  `teslimat_tarihi` date NOT NULL,
  `alici_ad_soyad` varchar(150) NOT NULL,
  `alici_telefon` varchar(20) DEFAULT NULL,
  `kart_mesaji` varchar(250) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `siparisler`
--

INSERT INTO `siparisler` (`siparis_id`, `buket_id`, `siparis_tarihi`, `siparis_durumu`, `teslimat_adresi`, `teslimat_tarihi`, `alici_ad_soyad`, `alici_telefon`, `kart_mesaji`) VALUES
(9, 6, '2026-05-27 10:49:01', 'teslim_edildi', 'Zonguldak', '2026-05-30', 'Gaye Kuğumcu', '05433243628', ''),
(10, 7, '2026-05-27 10:52:55', 'yolda', 'Zonguldak', '2026-06-09', 'Yadigar Kuğumcu', '05433253628', 'Doğum günün kutlu olsun.'),
(11, 8, '2026-05-27 10:53:43', 'hazirlaniyor', 'Zonguldak', '2026-07-13', 'Gaye Kuğumcu', '05433243628', ''),
(12, 10, '2026-05-31 13:32:18', 'hazirlaniyor', 'Bartın', '2026-06-26', 'Gaye Kuğumcu', '05433243628', ''),
(13, 12, '2026-05-31 13:45:18', 'hazirlaniyor', 'Bartın', '2026-06-26', 'Gaye Kuğumcu', '05433243628', ''),
(14, 14, '2026-05-31 13:58:30', 'hazirlaniyor', 'Bartın', '2026-06-25', 'Gaye Kuğumcu', '05433243628', ''),
(15, 15, '2026-05-31 14:26:16', 'hazirlaniyor', 'Bartın', '2026-06-26', 'Gaye Kuğumcu', '05433243628', '');

--
-- Tetikleyiciler `siparisler`
--
DELIMITER $$
CREATE TRIGGER `StokAzalt` AFTER INSERT ON `siparisler` FOR EACH ROW BEGIN
    UPDATE cicekler, buket_detaylari
    SET cicekler.stok_miktari = cicekler.stok_miktari - buket_detaylari.adet
    WHERE cicekler.cicek_id = buket_detaylari.cicek_id
      AND buket_detaylari.buket_id = NEW.buket_id;
END
$$
DELIMITER ;

--
-- Dökümü yapılmış tablolar için indeksler
--

--
-- Tablo için indeksler `buketler`
--
ALTER TABLE `buketler`
  ADD PRIMARY KEY (`buket_id`),
  ADD KEY `kullanici_id` (`kullanici_id`);

--
-- Tablo için indeksler `buket_detaylari`
--
ALTER TABLE `buket_detaylari`
  ADD PRIMARY KEY (`buket_detay_id`),
  ADD UNIQUE KEY `buket_id` (`buket_id`,`cicek_id`),
  ADD KEY `cicek_id` (`cicek_id`);

--
-- Tablo için indeksler `cicekler`
--
ALTER TABLE `cicekler`
  ADD PRIMARY KEY (`cicek_id`);

--
-- Tablo için indeksler `kullanicilar`
--
ALTER TABLE `kullanicilar`
  ADD PRIMARY KEY (`kullanici_id`),
  ADD UNIQUE KEY `mail` (`mail`);

--
-- Tablo için indeksler `odemeler`
--
ALTER TABLE `odemeler`
  ADD PRIMARY KEY (`odeme_id`),
  ADD UNIQUE KEY `siparis_id` (`siparis_id`);

--
-- Tablo için indeksler `siparisler`
--
ALTER TABLE `siparisler`
  ADD PRIMARY KEY (`siparis_id`),
  ADD UNIQUE KEY `buket_id` (`buket_id`);

--
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `buketler`
--
ALTER TABLE `buketler`
  MODIFY `buket_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Tablo için AUTO_INCREMENT değeri `buket_detaylari`
--
ALTER TABLE `buket_detaylari`
  MODIFY `buket_detay_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- Tablo için AUTO_INCREMENT değeri `cicekler`
--
ALTER TABLE `cicekler`
  MODIFY `cicek_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- Tablo için AUTO_INCREMENT değeri `kullanicilar`
--
ALTER TABLE `kullanicilar`
  MODIFY `kullanici_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Tablo için AUTO_INCREMENT değeri `odemeler`
--
ALTER TABLE `odemeler`
  MODIFY `odeme_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Tablo için AUTO_INCREMENT değeri `siparisler`
--
ALTER TABLE `siparisler`
  MODIFY `siparis_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Dökümü yapılmış tablolar için kısıtlamalar
--

--
-- Tablo kısıtlamaları `buketler`
--
ALTER TABLE `buketler`
  ADD CONSTRAINT `buketler_ibfk_1` FOREIGN KEY (`kullanici_id`) REFERENCES `kullanicilar` (`kullanici_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `buket_detaylari`
--
ALTER TABLE `buket_detaylari`
  ADD CONSTRAINT `buket_detaylari_ibfk_1` FOREIGN KEY (`buket_id`) REFERENCES `buketler` (`buket_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `buket_detaylari_ibfk_2` FOREIGN KEY (`cicek_id`) REFERENCES `cicekler` (`cicek_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `odemeler`
--
ALTER TABLE `odemeler`
  ADD CONSTRAINT `odemeler_ibfk_1` FOREIGN KEY (`siparis_id`) REFERENCES `siparisler` (`siparis_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `siparisler`
--
ALTER TABLE `siparisler`
  ADD CONSTRAINT `siparisler_ibfk_1` FOREIGN KEY (`buket_id`) REFERENCES `buketler` (`buket_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
