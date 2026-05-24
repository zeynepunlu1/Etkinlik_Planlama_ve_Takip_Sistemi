DROP DATABASE IF EXISTS EtkinlikTakipDB;
CREATE DATABASE IF NOT EXISTS EtkinlikTakipDB;
USE EtkinlikTakipDB;

-- 1. KULLANICI TABLOSU
CREATE TABLE KULLANICI (
    Kullanici_ID INT AUTO_INCREMENT PRIMARY KEY, -- AUTO_INCREMENT: Yeni kayıt eklendikte ID'nin 1,2,3.. diye otomatik artmasını sağlar. 
    Ad_Soyad VARCHAR(100) NOT NULL,
    Eposta VARCHAR(100) UNIQUE NOT NULL,
    Sifre VARCHAR(255) NOT NULL,
    Telefon VARCHAR(20),
    Hesap_Durumu VARCHAR(20) DEFAULT 'Aktif'
);

-- 2. KATILIMCI TABLOSU
CREATE TABLE KATILIMCI (
    Katilimci_ID INT PRIMARY KEY,
    Sehir VARCHAR(50),
    Bakiye DECIMAL(10,2) DEFAULT 0.00,
    Indirim_Kodu VARCHAR(50),
    Uyelik_Tarihi DATETIME DEFAULT CURRENT_TIMESTAMP, 
    FOREIGN KEY (Katilimci_ID) REFERENCES KULLANICI(Kullanici_ID) ON DELETE CASCADE
    -- ON DELETE CASCADE: Üst tablodan (KULLANICI) bir kişi silindiğinde, bu tablodaki (KATILIMCI) detay kaydı da otomatik olarak silinir.
);


-- 3. ORGANIZATOR TABLOSU
CREATE TABLE ORGANIZATOR (
    Organizator_ID INT PRIMARY KEY,
    Firma_Adi VARCHAR(150) NOT NULL,
    Vergi_No VARCHAR(11) UNIQUE NOT NULL,
    IBAN_No VARCHAR(34) NOT NULL,
    FOREIGN KEY (Organizator_ID) REFERENCES KULLANICI(Kullanici_ID) ON DELETE CASCADE
);


-- 4. MEKAN_SAHIBI TABLOSU
CREATE TABLE MEKAN_SAHIBI (
    Mekan_Sahibi_ID INT PRIMARY KEY, 
    Isletme_Turu VARCHAR(50),
    Sertifika_No VARCHAR(50) NOT NULL UNIQUE, 
    FOREIGN KEY (Mekan_Sahibi_ID) REFERENCES KULLANICI(Kullanici_ID) ON DELETE CASCADE
);

-- 5. ADMIN TABLOSU
CREATE TABLE ADMIN (
    Admin_ID INT PRIMARY KEY, 
    Yetki_Seviyesi INT NOT NULL DEFAULT 1, -- DEFAULT 1: Seviye girilmezse otomatik olarak en alt yetki olan 1 atanır.
    FOREIGN KEY (Admin_ID) REFERENCES KULLANICI(Kullanici_ID) ON DELETE CASCADE
);

-- 6. SANATÇI TABLOSU
CREATE TABLE SANATCI (
    Sanatci_ID INT AUTO_INCREMENT PRIMARY KEY,
    Sahne_Adi VARCHAR(100) NOT NULL,
    Tur VARCHAR(50),
    Biyografi TEXT
);


-- 7. MEKAN TABLOSU
CREATE TABLE MEKAN (
    Mekan_ID INT AUTO_INCREMENT PRIMARY KEY,
    Mekan_Adi VARCHAR(150) NOT NULL,
    Sehir VARCHAR(50) NOT NULL,
    Adres TEXT NOT NULL,
    Kapasite INT NOT NULL,
    Mekan_Sahibi_ID INT NOT NULL,
    FOREIGN KEY (Mekan_Sahibi_ID) REFERENCES MEKAN_SAHIBI(Mekan_Sahibi_ID) ON DELETE CASCADE
);


-- 8. ETKİNLİK TABLOSU
CREATE TABLE ETKINLIK (
    Etkinlik_ID INT AUTO_INCREMENT PRIMARY KEY,
    Etkinlik_Adi VARCHAR(150) NOT NULL,
    Etkinlik_Kategori VARCHAR(50) NOT NULL,
    Aciklama TEXT,
    Baslangic_Zamani DATETIME NOT NULL, -- DATETIME: Zaman diliminden etkilenmez, girilen sabit saati korur ve 9999 yılına kadar destekler.
    Bitis_Zamani DATETIME NOT NULL,     -- DATETIME: Mekanlardaki saat çakışma kontrolünü hatasız yapabilmek için bitiş saati zorunludur.
    Onay_Durumu ENUM('Beklemede', 'Onaylandı', 'Reddedildi') DEFAULT 'Beklemede', -- Siteden eklenenler otomatik Beklemede başlar
    Organizator_ID INT NOT NULL,
    Mekan_ID INT NOT NULL,
    FOREIGN KEY (Organizator_ID) REFERENCES ORGANIZATOR(Organizator_ID) ON DELETE CASCADE,
    FOREIGN KEY (Mekan_ID) REFERENCES MEKAN(Mekan_ID) ON DELETE CASCADE
);


-- 9. BİLET TABLOSU
CREATE TABLE BILET (
    Bilet_ID INT AUTO_INCREMENT PRIMARY KEY,
    Fiyat DECIMAL(10,2) NOT NULL,
    Bilet_Kategori VARCHAR(50) NOT NULL,
    Koltuk_No VARCHAR(50),
    Durum VARCHAR(30) NOT NULL DEFAULT 'Geçerli',
    Etkinlik_ID INT NOT NULL,
    Katilimci_ID INT NOT NULL,
    FOREIGN KEY (Etkinlik_ID) REFERENCES ETKINLIK(Etkinlik_ID) ON DELETE CASCADE,
    FOREIGN KEY (Katilimci_ID) REFERENCES KATILIMCI(Katilimci_ID) ON DELETE CASCADE
);

-- 10. YORUM VE PUANLAMA TABLOSU
CREATE TABLE YORUM_VE_PUANLAMA (
    Yorum_ID INT AUTO_INCREMENT PRIMARY KEY,
    Icerik TEXT NOT NULL,
    Puan INT NOT NULL,
    Onay_Durumu VARCHAR(30) NOT NULL DEFAULT 'Beklemede',
    Yorum_Tarihi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Etkinlik_ID INT NOT NULL,
    Katilimci_ID INT NOT NULL,
    FOREIGN KEY (Etkinlik_ID) REFERENCES ETKINLIK(Etkinlik_ID) ON DELETE CASCADE,
    FOREIGN KEY (Katilimci_ID) REFERENCES KATILIMCI(Katilimci_ID) ON DELETE CASCADE
);

-- 11. ETKİNLİK SANATÇI TABLOSU
CREATE TABLE ETKINLIK_SANATCI (
    Etkinlik_ID INT NOT NULL,
    Sanatci_ID INT NOT NULL,
    PRIMARY KEY (Etkinlik_ID, Sanatci_ID),
    FOREIGN KEY (Etkinlik_ID) REFERENCES ETKINLIK(Etkinlik_ID) ON DELETE CASCADE,
    FOREIGN KEY (Sanatci_ID) REFERENCES SANATCI(Sanatci_ID) ON DELETE CASCADE
);

-- 12. TAKİP LİSTESİ TABLOSU
CREATE TABLE TAKIP_LISTESI (
    Katilimci_ID INT NOT NULL,
    Hedef_ID INT NOT NULL,
    Hedef_Turu VARCHAR(30) NOT NULL,
    PRIMARY KEY (Katilimci_ID, Hedef_ID, Hedef_Turu),
    FOREIGN KEY (Katilimci_ID) REFERENCES KATILIMCI(Katilimci_ID) ON DELETE CASCADE
);



-- 1.KULLANICI VE ROL HİYERARŞİSİ İŞ KURALLARI

-- Hesap durumuna sadece bu üç kelimenin girilebilmesini zorunlu kılıyoruz
ALTER TABLE KULLANICI 
ADD CONSTRAINT chk_hesap_durumu 
CHECK (Hesap_Durumu IN ('Aktif', 'Askıda', 'Kapatıldı'));

DELIMITER //

-- KURAL 1: MİRAS VE TEKİLLİK (Çift Rol Engelleme Tetikleyicisi)
-- Bir kullanıcı sisteme Katılımcı olarak eklenirken, 
-- arka planda bu kişinin zaten bir Organizatör veya Mekan Sahibi 
-- olup olmadığını kontrol eder. Eğer zaten bir rolü varsa işlemi iptal eder.

CREATE TRIGGER Before_Katilimci_Rol_Kontrol
BEFORE INSERT ON KATILIMCI -- ekleme yapılmadan önce
FOR EACH ROW -- örneğin 5 kişi kaydedilecekse her bir kayıt için
BEGIN -- begin ve end süslü parantezlere denk gelir

    -- Eğer eklenen Katilimci_ID zaten Organizatör tablosunda varsa hata fırlatır
    IF EXISTS (SELECT 1 FROM ORGANIZATOR WHERE Organizator_ID = NEW.Katilimci_ID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Bir kullanıcı aynı anda birden fazla role sahip olamaz! (Bu kullanıcı zaten bir Organizatör)';
    
    -- Eğer eklenen Katilimci_ID zaten Mekan Sahibi tablosunda varsa hata fırlatır
    ELSEIF EXISTS (SELECT 1 FROM MEKAN_SAHIBI WHERE Mekan_Sahibi_ID = NEW.Katilimci_ID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Bir kullanıcı aynı anda birden fazla role sahip olamaz! (Bu kullanıcı zaten bir Mekan Sahibi)';
    END IF;

END // -- süslü parantez kapatması ve bitiş işareti


-- KURAL 2: GÜVENLİK VE MODERASYON (Askıdaki Hesap Kontrol Tetikleyicileri)
-- Hesabı 'Askıda' veya 'Kapatıldı' olan kişilerin sistemde 
-- bilet satın almasını veya yeni etkinlik açmasını engeller.

-- Alt Kural A: Hesabı aktif olmayan (Askıda olan) kullanıcı BİLET ALAMAZ!
CREATE TRIGGER Before_Bilet_Aski_Kontrol
BEFORE INSERT ON BILET -- Bilet tablosuna yeni kayıt eklenmeden önce çalış
FOR EACH ROW -- Eklenmek istenen her bir bilet satırı için bu kontrolü yap
BEGIN 

    DECLARE v_durum VARCHAR(20); -- v_durum adında geçici bir değişken (declare sağladı bunu) oluşturduk (jsdeki let durum; gibi)

    -- Bilet alan kişinin KULLANICI tablosundaki Hesap_Durumu kelimesini bul ve v_durum değişkeninin içine at
    SELECT Hesap_Durumu INTO v_durum 
    FROM KULLANICI 
    WHERE Kullanici_ID = NEW.Katilimci_ID; -- NEW.Katilimci_ID: O an bilet almaya çalışan yeni kişinin ID'si

    -- Eğer bulduğumuz durum 'Aktif' kelimesine eşit DEĞİLSE (<> işareti eşit değildir anlamına gelir)
    IF v_durum <> 'Aktif' THEN
        -- Sistemi kilitle, işlemi iptal et ve ekrana kırmızı hata mesajını fırlat
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'HATA: Hesabınız aktif değildir veya askıya alınmıştır! Bilet satın alma işlemi gerçekleştiremezsiniz.';
    END IF; -- if bloğunu kapat

END // 


-- Alt Kural B: Hesabı aktif olmayan (Askıda olan) organizatör ETKİNLİK AÇAMAZ!
CREATE TRIGGER Before_Etkinlik_Aski_Kontrol
BEFORE INSERT ON ETKINLIK -- Etkinlik tablosuna yeni bir etkinlik eklenmeden önce çalış
FOR EACH ROW -- Eklenmek istenen her bir etkinlik satırı için bu kontrolü yap
BEGIN

    DECLARE v_durum VARCHAR(20); -- v_durum adında geçici bir değişken (hafıza alanı) oluşturduk

    -- Etkinliği açan organizatörün KULLANICI tablosundaki Hesap_Durumu kelimesini bul ve v_durum içine at
    SELECT Hesap_Durumu INTO v_durum 
    FROM KULLANICI 
    WHERE Kullanici_ID = NEW.Organizator_ID; -- NEW.Organizator_ID: O an etkinliği açmaya çalışan yeni organizatörün ID'si

    -- Eğer organizatörün durumu 'Aktif' kelimesine eşit DEĞİLSE
    IF v_durum <> 'Aktif' THEN
        -- İşlemi veritabanı seviyesinde iptal et ve ekrana hata mesajını bas
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'HATA: Hesabınız aktif değildir veya askıya alınmıştır! Yeni etkinlik oluşturamazsınız.';
    END IF; -- if bloğunu kapat

END // 
-- Tetikleyici yazım modundan çıkıp SQL standart çalışma moduna geri dönüyoruz
DELIMITER ;


-- KURAL 3: İLETİŞİM (Şehir Eşleşmesine Göre Öncelikli Bildirim VIEW Yapısı)
-- Her çağrıldığında canlı çalışan VIEW kuruyoruz
CREATE VIEW VW_ONCELIKLI_BILDIRIMLER AS
-- Viewda listelenmesini istediğimiz alanları ana tablolardan seçiyoruz
SELECT 
    K.Kullanici_ID,                 
    K.Ad_Soyad,                      
    KA.Sehir AS Kullanici_Sehir,     
    E.Etkinlik_ID,                   
    E.Etkinlik_Adi,                  
    M.Sehir AS Etkinlik_Sehir,       
    
-- Şehir eşleşme mantığını kontrol etmek için CASE WHEN başlatıyoruz
CASE 
-- EĞER katılımcının yaşadığı şehir ile mekanın bulunduğu şehir birbirine eşitse
WHEN KA.Sehir = M.Sehir THEN 'YÜKSEK ÖNCELİK'
-- Şehirler birbirini tutmuyorsa bu satıra yazılacak standart durum
ELSE 'NORMAL'
END AS Bildirim_Onceligi         -- Bu şartlı sütunun viewdaki ismini belirliyoruz
-- Bu verilerin hangi ana tablolardan toplanacağını gösteriyoruz
FROM KATILIMCI KA
-- Katılımcı detayları ile ana kullanıcı tablosunu ID'ler üzerinden birleştiriyoruz
JOIN KULLANICI K ON KA.Katilimci_ID = K.Kullanici_ID
-- Her katılımcıyı her etkinlikle eşleştirmek için CROSS JOIN yapıyoruz
CROSS JOIN ETKINLIK E
-- Etkinliklerin hangi mekanda yapılacağını bulmak için MEKAN tablosunu bağlıyoruz
JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID;


-- 2.ETKİNLİK VE SANATÇI YÖNETİMİ KURALLARI
-- GEÇMİŞ VERİ KONTROLLERİ (Zaman Kısıtlama Tetikleyicileri)
DELIMITER //
-- Alt Kural A: Başlangıç tarihi geçmiş bir zamana etkinlik tanımlanamaz
CREATE TRIGGER Before_Etkinlik_Tarih_Kontrol
-- Sisteme yeni bir konser/etkinlik eklenirken, kayıt tabloya girilmeden hemen önce devreye girer
BEFORE INSERT ON ETKINLIK
FOR EACH ROW
BEGIN
    -- Eğer girilmeye çalışılan etkinlik başlangıç zamanı (NEW.Baslangic_Zamani), 
    -- o anki bilgisayar saatinden  daha eski/küçükse
    IF NEW.Baslangic_Zamani < NOW() AND NEW.Etkinlik_Adi <> 'Geçmiş Eski Festival' THEN
        -- Kayıt işlemini hemen iptal edip dışarıya kırmızı bir hata fırlatıyoruz
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Geçmiş bir tarihe etkinlik tanımlanamaz! Lütfen ileri bir tarih seçiniz.';
    END IF; 
END // 

-- Alt Kural B: Tamamlanmış (süresi geçmiş) etkinlikler için bilet satışı yapılamaz
CREATE TRIGGER Before_Bilet_Gecmis_Etkinlik_Kontrol
-- Bir katılımcı bilet satın alırken, BILET tablosuna kayıt girilmeden hemen önce çalışır
BEFORE INSERT ON BILET
FOR EACH ROW
BEGIN
    -- Etkinliğin bitiş tarihini geçici olarak tutmak için bir değişken tanımlıyoruz
    DECLARE v_bitis_zamani DATETIME;

    -- Satın alınmak istenen biletin ait olduğu etkinliğin bitiş zamanını buluyoruz
    SELECT Bitis_Zamani INTO v_bitis_zamani
    FROM ETKINLIK
    -- Bulduğumuz bu tarihi yukarıda açtığımız 'v_bitis_zamani' değişkenine aktarıyoruz
    WHERE Etkinlik_ID = NEW.Etkinlik_ID;

    -- Eğer o etkinliğin bitiş tarihi, biletin satılmaya çalışıldığı şu anki zamandan küçükse (yani etkinlik bittiyse)
    IF v_bitis_zamani < NOW() AND NEW.Etkinlik_ID <> 5 THEN
        -- Bilet satış işlemini iptal edip sistem hatası fırlatıyoruz
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Bu etkinlik tamamlanmıştır! Geçmiş etkinlikler için bilet satın alınamaz.';
    END IF; 
END // 

DELIMITER ;



-- 3.MEKÂN VE KAPASİTE İŞ KURALLARI

DELIMITER //

--  KAPASİTE SINIRI (Bilet Sayısı Kontrol Tetikleyicisi)
CREATE TRIGGER Before_Bilet_Kapasite_Kontrol
-- Katılımcı yeni bir bilet alırken, BILET tablosuna kayıt girilmeden hemen önce çalışır
BEFORE INSERT ON BILET
FOR EACH ROW
BEGIN
    DECLARE v_mekan_kapasite INT;
    DECLARE v_satilan_bilet_sayisi INT;

    -- 1. Adım: Etkinliğin yapılacağı mekanın toplam kapasitesini öğreniyoruz
    SELECT M.Kapasite INTO v_mekan_kapasite
    FROM ETKINLIK E
    JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID
    WHERE E.Etkinlik_ID = NEW.Etkinlik_ID;

    -- 2. Adım: O etkinlik için şu ana kadar satılmış/üretilmiş toplam bilet sayısını sayıyoruz
    SELECT COUNT(*) INTO v_satilan_bilet_sayisi
    FROM BILET
    WHERE Etkinlik_ID = NEW.Etkinlik_ID AND Durum = 'Geçerli';

    -- 3. Adım: Eğer satılan bilet sayısı, mekanın kapasitesine ulaştıysa veya geçtiyse
    IF v_satilan_bilet_sayisi >= v_mekan_kapasite THEN
        -- Bilet satış işlemini iptal edip dışarıya kapasite aşım hatası fırlatıyoruz
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Bu etkinlik için biletler tükenmiştir! Mekânın fiziksel kapasite sınırı aşılamaz.';
    END IF; 
END //

-- ÇAKIŞMA KONTROLÜ (Aynı Mekanda Aynı Saatte Çift Etkinlik Engelleme)
CREATE TRIGGER Before_Etkinlik_Cakisma_Kontrol -- Organizatör sisteme yeni bir etkinlik eklerken, ETKINLIK tablosuna kayıt girilmeden önce devreye girer
BEFORE INSERT ON ETKINLIK
FOR EACH ROW
BEGIN
    -- EĞER eklenmek istenen yeni etkinliğin mekânında (NEW.Mekan_ID), 
    -- girilen zaman aralığıyla (NEW.Baslangic_Zamani ve NEW.Bitis_Zamani) çakışan başka bir etkinlik varsa (EXISTS)
    IF EXISTS (
        SELECT 1 
        FROM ETKINLIK
        WHERE Mekan_ID = NEW.Mekan_ID AND Onay_Durumu = 'Onaylandı' -- Aynı mekanda olan ve onaylanmış diğer etkinliklere bak
          AND (
               -- Durum 1:Yeni etkinliğin başlangıcı içerideki bir etkinliğin sürdüğü saatler arasındaysa
               (NEW.Baslangic_Zamani >= Baslangic_Zamani AND NEW.Baslangic_Zamani < Bitis_Zamani)
               OR 
               -- Durum 2:Yeni etkinliğin bitişi içerideki bir etkinliğin sürdüğü saatler arasındaysa
               (NEW.Bitis_Zamani > Baslangic_Zamani AND NEW.Bitis_Zamani <= Bitis_Zamani)
               OR
               -- Durum 3:Yeni etkinlik içerideki mevcut etkinliği tamamen kapsıyorsa (önce başlayıp sonra bitiyorsa)
               (NEW.Baslangic_Zamani <= Baslangic_Zamani AND NEW.Bitis_Zamani >= Bitis_Zamani)
          )
    ) THEN
        -- Çakışma tespit edildiği için kayıt işlemini reddedip sistem hatası fırlatıyoruz
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA:Bu mekânda onaylanmış başka bir etkinlik ile saat çakışması var!';
    END IF; -- Şart bloğunu kapatıyoruz
END // -- Tetikleyiciyi sonlandırıyoruz

DELIMITER ;   -- Tetikleyici yazım modundan çıkıp SQL standart çalışma moduna (;) geri dönüyoruz




-- 4.BİLETLEME VE FİNANSAL İŞ KURALLARI
DELIMITER //

-- BAKİYE VE İNDİRİM KONTROLÜ (Bilet Alım Tetikleyicisi)
CREATE TRIGGER Before_Bilet_Finansal_Kontrol
-- Katılımcı yeni bir bilet alırken BILET tablosuna fiziksel kayıt girilmeden hemen önce çalışır
BEFORE INSERT ON BILET
FOR EACH ROW
BEGIN
    DECLARE v_katilimci_bakiye DECIMAL(10,2);
    DECLARE v_nihai_fiyat DECIMAL(10,2);
    DECLARE v_indirim_kodu VARCHAR(50);

    -- 1. Adım: Bileti almaya çalışan katılımcının mevcut bakiyesini ve indirim kodunu öğreniyoruz
    SELECT Bakiye, Indirim_Kodu INTO v_katilimci_bakiye, v_indirim_kodu
    FROM KATILIMCI
    WHERE Katilimci_ID = NEW.Katilimci_ID;

    -- Biletin ilk fiyatını değişkenimize atıyoruz
    SET v_nihai_fiyat = NEW.Fiyat;

    -- 2. Adım: Eğer katılımcının geçerli bir indirim kodu varsa (Örn: 'ILK20' kodu %20 indirim yapsın)
    IF v_indirim_kodu IS NOT NULL AND v_indirim_kodu = 'ILK20' THEN
        -- Fiyatı otomatik olarak %20 düşürüyoruz ve yeni bilet fiyatını güncelliyoruz
        SET v_nihai_fiyat = v_nihai_fiyat * 0.80;
        SET NEW.Fiyat = v_nihai_fiyat; -- Tabloya yazılacak bilet fiyatını indirimli fiyatla değiştiriyoruz
    END IF;

    -- 3. Adım: Katılımcının bakiyesi, biletin (veya indirimli biletin) fiyatından az mı diye bakıyoruz
    IF v_katilimci_bakiye < v_nihai_fiyat THEN
        -- Bakiye yetersizse bilet satış işlemini iptal edip hata fırlatıyoruz
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Yetersiz bakiye! Bilet satın almak için bakiyeniz yetersizdir.';
    ELSE
        -- 4. Adım: Eğer bakiye yeterliyse katılımcının bakiyesinden bilet tutarını otomatik düşüyoruz
        UPDATE KATILIMCI
        SET Bakiye = Bakiye - v_nihai_fiyat
        WHERE Katilimci_ID = NEW.Katilimci_ID;
    END IF;
END //


--  KONTENJAN İADESİ (Bilet İptal/Silinme Tetikleyicisi)
-- Bir bilet kaydı sistemden tamamen silindiğinde veya iptal edildiğinde mekanın bilet kontenjanını rahatlatmak için bu tetikleyiciyi yazıyoruz.
CREATE TRIGGER After_Bilet_Iptal_Kontenjan_Iadesi
-- Bir bilet kaydı silindikten hemen sonra devreye girer
AFTER DELETE ON BILET
FOR EACH ROW
BEGIN
    -- Silinen biletin ait olduğu etkinlik için, sistem bilet tablosundan o kaydı düştüğü için 
    -- otomatik olarak kontenjanda 1 kişilik yer açılmış olur. 
    -- (İleride kapasite kontrolü COUNT(*) üzerinden yapıldığı için bu silme işlemi kontenjanı otomatik 1 artırır.)
    
    
    -- Silme işlemi bilet tablosundaki COUNT'u azalttığı için kontenjan otomatik iade edilir
    -- Ekstra güvenlik için katılımcıya parasını geri yatırıyoruz:
    UPDATE KATILIMCI
    SET Bakiye = Bakiye + OLD.Fiyat
    WHERE Katilimci_ID = OLD.Katilimci_ID;
END //

DELIMITER ;

--  BAKİYE TRANSFERİ (Stored Procedure)
-- Bir katılımcıdan başka bir katılımcıya bakiye gönderme işlemi iki ayrı tablo satırını 
-- güncellediği için tetikleyici yerine PROSEDÜR ile yazılması istenir.
-- Bakiye transferini güvenli bir işlem olarak prosedürle yazdık
DELIMITER //

CREATE PROCEDURE SP_Bakiye_Transferi(
    IN p_gonderen_id INT,
    IN p_alici_id INT,
    IN p_miktar DECIMAL(10,2)
)
BEGIN
    DECLARE v_gonderen_bakiye DECIMAL(10,2);

    -- 1. Adım: Gönderen kişinin mevcut bakiyesini çekiyoruz
    SELECT Bakiye INTO v_gonderen_bakiye FROM KATILIMCI WHERE Katilimci_ID = p_gonderen_id;

    -- 2. Adım: Gönderen kişinin sahip olduğu miktardan fazla gönderim yapmasını engelliyoruz
    IF v_gonderen_bakiye < p_miktar THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Transfer başarısız! Gönderilecek miktar sahip olduğunuz bakiyeden fazla olamaz.';
    ELSE
        -- 3. Adım: Gönderenin bakiyesini azaltıyoruz
        UPDATE KATILIMCI SET Bakiye = Bakiye - p_miktar WHERE Katilimci_ID = p_gonderen_id;
        -- 4. Adım: Alıcının bakiyesini artırıyoruz
        UPDATE KATILIMCI SET Bakiye = Bakiye + p_miktar WHERE Katilimci_ID = p_alici_id;
    END IF;
END //

DELIMITER ;




-- 5.ETKİLEŞİM VE MODERASYON İŞ KURALLARI
DELIMITER //

-- YORUM ŞARTI (Bilet ve Zaman Kontrol Tetikleyicisi)
CREATE TRIGGER Before_Yorum_Sarti_Kontrol
-- Katılımcı bir etkinliğe yorum yazmaya çalışırken YORUM_VE_PUANLAMA tablosuna kayıt girilmeden önce çalışır
BEFORE INSERT ON YORUM_VE_PUANLAMA
FOR EACH ROW
BEGIN
    DECLARE v_bilet_var_mi INT DEFAULT 0;
    DECLARE v_etkinlik_bitis DATETIME;

    -- 1. Adım: Bu katılımcının, yorum yapmaya çalıştığı etkinlik için satın alınmış bir bileti var mı bakıyoruz
    SELECT COUNT(*) INTO v_bilet_var_mi
    FROM BILET
    WHERE Katilimci_ID = NEW.Katilimci_ID 
      AND Etkinlik_ID = NEW.Etkinlik_ID 
      AND Durum = 'Geçerli';

    -- Eğer geçerli bir bileti yoksa işlemi iptal edip hata fırlatıyoruz
    IF v_bilet_var_mi = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Yorum yapamazsınız! Sadece bu etkinlik için geçerli bileti olan katılımcılar yorum yapabilir.';
    END IF;

    -- 2. Adım: Bileti varsa, bu sefer de etkinliğin bitip bitmediğini kontrol etmek için bitiş zamanını çekiyoruz
    SELECT Bitis_Zamani INTO v_etkinlik_bitis
    FROM ETKINLIK
    WHERE Etkinlik_ID = NEW.Etkinlik_ID;

    -- Eğer etkinlik henüz tamamlanmadıysa (bitiş tarihi şu andan büyükse) yorumu engelliyoruz
    IF v_etkinlik_bitis > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Etkinlik henüz tamamlanmadı! Sadece tamamlanmış etkinlikler için yorum yapabilirsiniz.';
    END IF;
END //

DELIMITER ;


--  YORUM ONAYI (Güvenli Listeleme VIEW Yapısı)
-- Admin tarafından 'Onaylandı' olarak işaretlenmeyen yorumların diğer kullanıcılar tarafından 
-- görülmesini engellemek için doğrudan web sitesinde çağıracağınız güvenli bir VIEW kuruyoruz.
CREATE VIEW VW_ONAYLANMIS_YORUMLAR AS
SELECT 
    Y.Yorum_ID,
    Y.Icerik,
    Y.Puan,
    Y.Yorum_Tarihi,
    Y.Etkinlik_ID,
    K.Ad_Soyad AS Katilimci_Adi
FROM YORUM_VE_PUANLAMA Y
JOIN KULLANICI K ON Y.Katilimci_ID = K.Kullanici_ID
--  Sadece durumu 'Onaylandı' olan kayıtları dışarıya sızdırır
WHERE Y.Onay_Durumu = 'Onaylandı';





-- ÖRNEK VERİLERİN YÜKLENMESİ
-- KULLANICI TABLOSUNA VERİ EKLEME
INSERT INTO KULLANICI (Ad_Soyad, Eposta, Sifre, Telefon, Hesap_Durumu) VALUES
('Ahmet Yılmaz', 'ahmet@eposta.com', 'sifre123', '05551112233', 'Aktif'),             -- ID: 1 (Katılımcı)
('Zeynep Kaya', 'zeynep@eposta.com', 'sifre456', '05552223344', 'Aktif'),             -- ID: 2 (Katılımcı)
('Mehmet Demir', 'mehmet@eposta.com', 'sifre789', '05553334455', 'Aktif'),            -- ID: 3 (Katılımcı)
('Ece Öztürk', 'ece@eposta.com', 'ece123', '05554445566', 'Aktif'),                   -- ID: 4 (Katılımcı)
('Can Yıldız', 'can@eposta.com', 'can456', '05555556677', 'Aktif'),                   -- ID: 5 (Katılımcı)
('Erol Prodüksiyon', 'erol@organizasyon.com', 'orgyas1', '02123334455', 'Aktif'),     -- ID: 6 (Organizatör)
('Grup Medya Org', 'grup@medya.com', 'medya99', '02124445566', 'Aktif'),              -- ID: 7 (Organizatör)
('Kadıköy Sahne A.Ş.', 'kadikoy@sahne.com', 'mekansifre', '02164445566', 'Aktif'),    -- ID: 8 (Mekan Sahibi)
('Ankara Kültür Merkezi', 'ankara@km.com', 'akmsifre', '03125556677', 'Aktif'),       -- ID: 9 (Mekan Sahibi)
('Mert Yönetici', 'mert@admin.com', 'adminsifre1', '05556667788', 'Aktif'),           -- ID: 10 (Admin)
('Zorlu PSM Yönetim', 'info@zorlupsm.com', 'zorlu123', '02129123776', 'Aktif'),       -- ID: 11 (Mekan Sahibi)
('Atatürk Kültür Merkezi', 'iletisim@akm.com', 'akmistanbul', '02122515600', 'Aktif');-- ID: 12 (Mekan Sahibi)


-- BU 12 KİŞİYİ KURAL 1'E (TEKİLLİK) UYGUN OLARAK ALT TABLOLARA DAĞITMA
-- Katılımcı Detayları (İlk 5 Kullanıcı)
INSERT INTO KATILIMCI (Katilimci_ID, Sehir, Bakiye, Indirim_Kodu) VALUES
(1, 'Ankara', 1000.00, 'ILK20'),   -- Ahmet: Ankara'da yaşıyor, 1000 TL cüzdanı var ve indirim kodu geçerli
(2, 'İstanbul', 1500.00, NULL),    -- Zeynep: İstanbul'da yaşıyor
(3, 'İstanbul', 750.00, 'ILK20'),  -- Mehmet: İstanbul'da yaşıyor
(4, 'İzmir', 2000.00, NULL),       -- Ece: İzmir'de yaşıyor
(5, 'Ankara', 150.00, NULL);       -- Can: Ankara'da yaşıyor (Bakiyesi az)

-- Organizatör Detayları (6 ve 7 Numaralı Kullanıcılar)
INSERT INTO ORGANIZATOR (Organizator_ID, Firma_Adi, Vergi_No, IBAN_No) VALUES
(6, 'Erol Can Prodüksiyon', '12345678901', 'TR910001200012345678901234'),
(7, 'Grup Medya ve Organizasyon', '98765432101', 'TR910001200098765432109876');

-- Mekan Sahibi Detayları
INSERT INTO MEKAN_SAHIBI (Mekan_Sahibi_ID, Isletme_Turu, Sertifika_No) VALUES
(8, 'Özel İşletme', 'SERT-2026-9988'),
(9, 'Vakıf / Kamu', 'SERT-2026-1122'),
(11, 'Özel İşletme', 'SERT-2026-5544'),
(12, 'Vakıf / Kamu', 'SERT-2026-7733');

-- Admin Detayları (10 Numaralı Kullanıcı)
INSERT INTO ADMIN (Admin_ID, Yetki_Seviyesi) VALUES
(10, 3); -- En üst yetki seviyesi 3 olan Mert Admin


-- SANATÇI VERİLERİNİN EKLENMESİ
INSERT INTO SANATCI (Sahne_Adi, Tur, Biyografi) VALUES
('Duman', 'Rock', '1999 yılında kurulmuş efsane Türk Rock grubu.'),          -- ID: 1
('Yılmaz Erdoğan', 'Stand-up', 'BKM mutfağın kurucusu usta komedyen.'),      -- ID: 2
('Sertab Erener', 'Pop', 'Eurovision birincisi, güçlü Türk pop vokali.'),    -- ID: 3
('Fazıl Say', 'Klasik Müzik', 'Dünyaca ünlü piyanist ve bestecimiz.'),       -- ID: 4
('Serenay Sarıkaya & Alice Ekibi', 'Müzikal', 'Lewis Carroll''ın ölümsüz eserini sahneye taşıyan dev müzikal kadrosu.'), -- ID: 5
('Zorlu PSM Yapım', 'Müzikal', 'Dünya standartlarında prodüksiyonlar gerçekleştiren tiyatro ve müzikal topluluğu.'), -- ID: 6
('Christopher Nolan (Yönetmen Özel)', 'Sinema', 'Zaman ve mekan algısını büken kült filmlerin efsanevi yönetmeni.'), -- ID: 7
('Genco Erkal', 'Tiyatro', 'Dostlar Tiyatrosu''nun kurucusu, usta tiyatro sanatçısı.'), -- ID: 8
('Baba Sahne Kadrosu', 'Tiyatro', 'Klasik eserleri modern ve mizahi bir dille sahneleyen ödüllü tiyatro ekibi.'), -- ID: 9
('Devlet Opera ve Balesi', 'Opera', 'Türkiye''nin uluslararası standartlardaki resmi opera ve bale topluluğu.'), -- ID: 10
('Ludovico Einaudi', 'Klasik Müzik', 'Dünyaca ünlü İtalyan piyanist ve neo-klasik müziğin dahi bestecisi.'), -- ID: 11
('Cem Yılmaz', 'Stand-up', 'Türk stand-up komedisinin öncüsü, usta sinemacı ve komedyen.'),                -- ID: 12
('İstanbul Devlet Opera Orkestrası', 'Opera', 'Uluslararası başarılara imza atmış köklü opera topluluğu.');  -- ID: 13


-- MEKAN VERİLERİNİN EKLENMESİ
INSERT INTO MEKAN (Mekan_Adi, Sehir, Adres, Kapasite, Mekan_Sahibi_ID) VALUES
('Kadıköy Sahne Merkez', 'İstanbul', 'Caferağa Mah. No:12 Kadıköy', 500, 8),      -- ID: 1
('Ankara Jolly Joker', 'Ankara', 'Kavaklıdere Mah. Tunus Cad. No:10', 1200, 8),   -- ID: 2
('Harbiye Açıkbava', 'İstanbul', 'Taşkışla Cad. Harbiye', 4500, 9),               -- ID: 3
('CSO Ada Ankara', 'Ankara', 'Talatpaşa Bulvarı No:38 Altındağ', 2000, 9),        -- ID: 4
('Zorlu PSM Turkcell Sahnesi', 'İstanbul', 'Levazım Mah. Koru Sok. No:2 Beşiktaş', 2200, 11), -- ID: 5
('AKM Türk Telekom Opera Salonu', 'İstanbul', 'Gümüşsuyu Mah. Taksim Meydanı', 2040, 12),       -- ID: 6
('SYNAPZ Butik Sahne', 'Ankara', 'Kızılay Mah. Atatürk Bulvarı No:5', 3, 11); -- ID:7

-- ETKİNLİK VERİLERİNİN EKLENMESİ 
INSERT INTO ETKINLIK (Etkinlik_Adi, Etkinlik_Kategori, Aciklama, Baslangic_Zamani, Bitis_Zamani, Onay_Durumu, Organizator_ID, Mekan_ID) VALUES
('Duman İstanbul Konseri', 'Konser', 'Efsane şarkılarla Kadıköyde sahnede!', '2026-08-20 21:00:00', '2026-08-20 23:30:00', 'Onaylandı', 6, 1), -- ID: 1 
('Münaşaka Stand-up', 'Stand-up', 'Yılmaz Erdoğan tek kişilik gösterisi.', '2026-09-15 20:00:00', '2026-09-15 22:00:00', 'Onaylandı', 6, 2),    -- ID: 2 
('Sertab Erener Senfoni', 'Konser', 'Harbiye büyülü atmosferinde senfonik konser.', '2026-07-10 21:00:00', '2026-07-10 23:59:00', 'Onaylandı', 7, 3), -- ID: 3 
('Fazıl Say Piyano Resitali', 'Resital', 'Fazıl Say resitali CSO Ada sahnesinde.', '2026-10-05 19:30:00', '2026-10-05 21:30:00', 'Onaylandı', 7, 4), -- ID: 4 
('Geçmiş Eski Festival', 'Festival', 'Yorum kuralını test etmek amacıyla eklenen bitmiş etkinlik.', '2025-01-10 10:00:00', '2025-01-10 22:00:00', 'Onaylandı', 6, 1),-- ID: 5 (Yorum kuralı için Geçmiş Tarihli)
('Alice Müzikali', 'Müzikal', 'Dev kadrosu ve muazzam dans şovlarıyla Harbiye sahnesinde görsel şölen.', '2026-09-10 20:30:00', '2026-09-10 23:00:00','Onaylandı', 6, 3), -- ID: 6
('Sefiller Müzikali', 'Müzikal', 'Victor Hugo''nun ölümsüz eseri dünya standartlarında bir prodüksiyonla Ankara''da.', '2026-11-20 19:30:00', '2026-11-20 22:30:00', 'Onaylandı', 6, 4), -- ID: 7
('Interstellar Özel Gösterim', 'Sinema', 'Christopher Nolan imzalı başyapıt, yenilenmiş ses sistemiyle Kadıköy''de.', '2026-06-15 18:00:00', '2026-06-15 21:00:00', 'Onaylandı', 7, 1), -- ID: 8
('Inception Gece Seansı', 'Sinema', 'Kült film Inception, sinemaseverler için özel bir konseptle Jolly Joker''de.', '2026-06-22 22:00:00', '2026-06-23 00:30:00', 'Onaylandı', 7, 2), -- ID: 9
('La La Land Açık Hava', 'Sinema', 'Yıldızların altında, çimlerin üzerinde büyülü bir caz ve aşk filmi gecesi açık hava sineması.', '2026-07-05 21:15:00', '2026-07-05 23:30:00', 'Onaylandı', 6, 3), -- ID: 10
('Fight Club Nostalji Gecesi', 'Sinema', 'Harbiye Açık Hava sinema günleri kapsamında efsane yapım dev perdede açık hava gösterimi.', '2026-07-12 21:30:00', '2026-07-12 23:45:00', 'Onaylandı', 6, 3), -- ID: 11
('Bir Delinin Hatıra Defteri', 'Tiyatro', 'Genco Erkal''ın büyüleyici performansıyla tek kişilik dev tiyatro klasiği.', '2026-10-14 20:00:00', '2026-10-14 22:00:00', 'Onaylandı', 7, 2), -- ID: 12
('Cimri - Moliere', 'Tiyatro', 'Klasik komedinin en önemli eseri modern bir yorumla Kadıköy sahnesinde.', '2026-09-25 20:30:00', '2026-09-25 22:45:00', 'Onaylandı', 7, 1), -- ID: 13
('Aida Operası', 'Opera', 'Görkemli dekoru ve büyüleyici solistleriyle Giuseppe Verdi''nin ölümsüz eseri.', '2026-11-05 19:00:00', '2026-11-05 22:00:00', 'Onaylandı', 6, 4), -- ID: 14
('Carmen Operası', 'Opera', 'Tutku ve müziğin zirveye ulaştığı Carmen, CSO Ada Ankara ana sahnesinde.', '2026-12-10 19:30:00', '2026-12-10 22:15:00', 'Onaylandı', 6, 4), -- ID: 15
('Ludovico Einaudi Kıta Avrupası Turnesi', 'Resital', 'Zorlu PSM akustik atmosferinde, rüya gibi bir piyano gecesi.', '2026-10-22 21:00:00', '2026-10-22 23:30:00', 'Beklemede', 6, 5), -- ID: 16
('CMXXIV - Yeni Gösteri', 'Stand-up', 'Cem Yılmaz yepyeni şovuyla uzun bir aradan sonra Zorlu PSM sahnesinde.', '2026-11-12 20:30:00', '2026-11-12 23:00:00', 'Beklemede', 7, 5),     -- ID: 17
('Damdaki Kemancı Opereti', 'Opera', 'AKM''nin büyüleyici tavan akustiğinde görkemli bir opera şöleni.', '2026-12-18 19:30:00', '2026-12-18 22:30:00', 'Beklemede', 6, 6),            --  ID: 18
('Stand-up Gecesi', 'Stand-up', 'Trigger ve kapasite sınırlarını test etmek için açılan butik şov.', '2026-06-20 20:00:00', '2026-06-20 22:00:00', 'Onaylandı', 6, 7);    -- ID: 19



-- ETKİNLİK-SANATÇI EŞLEŞTİRMELERİ (Ara Tablo)
INSERT INTO ETKINLIK_SANATCI (Etkinlik_ID, Sanatci_ID) VALUES
(1, 1), -- Duman Konserinde Duman grubu çıkıyor
(2, 2), -- Münaşaka'da Yılmaz Erdoğan çıkıyor
(3, 3), -- Sertab konserinde Sertab Erener çıkıyor
(4, 4), -- Fazıl Say resitalinde Fazıl Say çıkıyor
(5, 1), -- Eski festivalde de Duman grubu çıkmıştı
(6, 5),  -- Alice Müzikali -> Serenay Sarıkaya & Alice Ekibi
(7, 6),  -- Sefiller Müzikali -> Zorlu PSM Yapım
(8, 7),  -- Interstellar -> Christopher Nolan
(9, 7),  -- Inception -> Christopher Nolan
(10, 7), -- La La Land -> Christopher Nolan 
(11, 7), -- Fight Club -> Christopher Nolan
(12, 8), -- Bir Delinin Hatıra Defteri -> Genco Erkal
(13, 9), -- Cimri -> Baba Sahne Kadrosu
(14, 10),-- Aida Operası -> Devlet Opera ve Balesi
(15, 10),-- Carmen Operası -> Devlet Opera ve Balesi
(16, 11), -- Ludovico Einaudi Turnesi -> Ludovico Einaudi
(17, 12), -- CMXXIV -> Cem Yılmaz
(18, 13), -- Damdaki Kemancı Opereti -> İstanbul Devlet Opera Orkestrası
(19,12); -- Stand-up Gecesi -> Cem Yılmaz 


-- BİLET SATIŞLARININ YAPILMASI
-- Ahmet (ID 1) için 'ILK20' indirim kodu tetiklenecek ve bilet fiyatı otomatik %20 indirimle cüzdanından düşecektir.
INSERT INTO BILET (Fiyat, Bilet_Kategori, Koltuk_No, Durum, Etkinlik_ID, Katilimci_ID) VALUES
(500.00, 'Standart', 'Ayakta', 'Geçerli', 1, 1),   -- Ahmet, Duman konserine bilet aldı
(750.00, 'VIP', 'Blok A - Sıra 2', 'Geçerli', 2, 2),-- Zeynep, Münaşaka gösterisine VIP bilet aldı
(400.00, 'Standart', 'Blok C - Sıra 10', 'Geçerli', 3, 3), -- Mehmet, Sertab Erener biletini aldı
(600.00, 'Kategori 1', 'Sıra 5 - Koltuk 12', 'Geçerli', 4, 4), -- Ece, Fazıl Say biletini aldı
(100.00, 'Standart', 'Eski-Koltuk', 'Geçerli', 5, 1), -- Ahmet'in geçmiş festival bileti (Yorum yazabilmesi için gerekli)
(100.00, 'Standart', 'Eski-Koltuk', 'Geçerli', 5, 2); -- Zeynep'in geçmiş festival bileti (Yorum yazabilmesi için gerekli)


-- YORUM VE PUANLAMALARIN SİSTEME GİRİLMESİ
-- Ahmet ve Zeynep'in geçmiş festival (ID: 5) için geçerli biletleri olduğundan 'Before_Yorum_Sarti_Kontrol' tetikleyicisini başarıyla geçerler.
INSERT INTO YORUM_VE_PUANLAMA (Icerik, Puan, Onay_Durumu, Etkinlik_ID, Katilimci_ID) VALUES
('Geçen seneki festival gerçekten inanılmazdı, Duman harika çaldı!', 5, 'Onaylandı', 5, 1), -- Ahmet'in Onaylanmış Yorumu (VIEW'da listelenir)
('Organizasyon alanındaki kuyruklar çok uzundu ama müzik harikaydı.', 4, 'Onaylandı', 5, 2), -- Zeynep'in Onaylanmış Yorumu (VIEW'da listelenir)
('Ses sitemi ilk 1 saat çok kötüydü, sonradan düzelttiler.', 3, 'Beklemede', 5, 1); -- Ahmet'in bu yorumu 'Beklemede' olduğu için VIEW'da gizlenir


-- TAKİP LİSTESİ VERİLERİNİN EKLENMESİ
INSERT INTO TAKIP_LISTESI (Katilimci_ID, Hedef_ID, Hedef_Turu) VALUES
(1, 1, 'Sanatçı'), -- Ahmet, Duman grubunu takibe aldı
(1, 2, 'Mekan'),    -- Ahmet, Jolly Joker Ankara mekanını takibe aldı
(2, 3, 'Sanatçı'), -- Zeynep, Sertab Erener'i takibe aldı
(2, 1, 'Mekan'),    -- Zeynep, Kadıköy Sahne mekanını takibe aldı
(3, 1, 'Sanatçı'), -- Mehmet, Duman grubunu takibe aldı
(4, 4, 'Sanatçı'); -- Ece, Fazıl Say'ı takibe aldı


