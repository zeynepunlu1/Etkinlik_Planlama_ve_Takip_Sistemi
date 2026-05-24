const express = require('express');
const mysql = require('mysql2');
const path = require('path');
const app = express();
const port = 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/public', express.static(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'views')));

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'z0908.', 
    database: 'EtkinlikTakipDB'
});

db.connect((err) => {
    if (err) {
        console.error('Veritabanı bağlantı hatası: ' + err.stack);
        return;
    }
    console.log('SYNAPZ Veritabanı Sistemleri Aktif! ');
});


// GÜVENLİ ROL TABANLI GİRİŞ SİSTEMİ

app.post('/api/giris', (req, res) => {
    const { eposta, sifre } = req.body;
    const sql = `SELECT Kullanici_ID, Ad_Soyad, Hesap_Durumu FROM KULLANICI WHERE Eposta = ? AND Sifre = ?`;
    
    db.query(sql, [eposta, sifre], (err, sonuclar) => {
        if (err) return res.status(500).json({ hata: err.message });
        
        if (sonuclar.length > 0) {
            const user = sonuclar[0];
            res.send(`
                <script>
                    localStorage.setItem('synapz_user_id', '${user.Kullanici_ID}');
                    localStorage.setItem('synapz_user_name', '${user.Ad_Soyad}');
                    window.location.href = '/profil.html?id=${user.Kullanici_ID}';
                </script>
            `);
        } else {
            res.send("<script>alert('E-posta veya şifre hatalı!'); window.location.href='/giris_kayit.html';</script>");
        }
    });
});


//  AKILLI İLİŞKİSEL KAYIT MOTORU 

app.post('/api/kayit', (req, res) => {
    const { ad, soyad, eposta, role, telefon, sehir, sifre } = req.body;
    const tamAd = `${ad} ${soyad}`;

    // Önce e-posta adresi sistemde zaten var mı diye kontrol ediyoruz
    db.query(`SELECT Kullanici_ID FROM KULLANICI WHERE Eposta = ?`, [eposta], (err, checkRes) => {
        if (err) return res.send(`<script>alert('${err.message}'); window.location.href='/giris_kayit.html';</script>`);
        if (checkRes.length > 0) {
            return res.send("<script>alert('Bu e-posta adresi zaten sisteme kayıtlı!'); window.location.href='/giris_kayit.html';</script>");
        }

        // 1. Ana tablo olan KULLANICI tablosuna veriyi işliyoruz (Hesap yeni açıldığı için Aktif başlar)
        const sqlKullanici = `INSERT INTO KULLANICI (Ad_Soyad, Eposta, Telefon, Sifre, Hesap_Durumu) VALUES (?, ?, ?, ?, 'Aktif')`;
        
        db.query(sqlKullanici, [tamAd, eposta, telefon, sifre], (err, result) => {
            if (err) return res.send(`<script>alert('Kullanıcı eklenirken hata: ${err.message}'); window.location.href='/giris_kayit.html';</script>`);
            
            const yeniKullaniciID = result.insertId;

            // 2. Seçilen Hesap Türüne (Role) göre alt/çocuk ilişkisel tablolara kayıt atıyoruz
            if (role === 'Katılımcı') {
                // Katılımcılara şartname gereği ilk kayıt hediyesi olarak 1000 TL bakiye ve hoş geldin kuponu tanımlıyoruz
                db.query(`INSERT INTO KATILIMCI (Katilimci_ID, Sehir, Bakiye, Indirim_Kodu) VALUES (?, ?, 1000.00, 'ILK20')`, [yeniKullaniciID, sehir || 'Belirtilmedi'], (err) => {
                    if (err) return res.send(`<script>alert('Katılımcı detayı eklenemedi.'); window.location.href='/giris_kayit.html';</script>`);
                    res.send("<script>alert('🎉 Katılımcı kaydınız başarıyla oluşturuldu! Hoş geldin hediyesi 1000 TL cüzdanınıza yüklendi. Şimdi giriş yapabilirsiniz.'); window.location.href='/giris_kayit.html';</script>");
                });
            } 
            else if (role === 'Organizatör') {
                // Organizatörler için sahte/örnek fatura ve IBAN bloku oluşturuyoruz
                db.query(`INSERT INTO ORGANIZATOR (Organizator_ID, Firma_Adi, Vergi_No, IBAN_No) VALUES (?, ?, 'VKN-999000', 'TR990001112223334445556667')`, [yeniKullaniciID, tamAd + " Ltd. Şti."], (err) => {
                    if (err) return res.send(`<script>alert('Organizatör detayı eklenemedi.'); window.location.href='/giris_kayit.html';</script>`);
                    res.send("<script>alert(' Organizatör kurumsal kaydınız alındı! Şimdi giriş yapıp yeni etkinlik talepleri oluşturabilirsiniz.'); window.location.href='/giris_kayit.html';</script>");
                });
            } 
            else if (role === 'Mekan Sahibi') {
                // Mekan sahipleri için işletme türü ruhsat mühürlemesi
                db.query(`INSERT INTO MEKAN_SAHIBI (Mekan_Sahibi_ID, Isletme_Turu, Sertifika_No) VALUES (?, 'Özel Ticari İşletme', 'SRT-77722')`, [yeniKullaniciID], (err) => {
                    if (err) return res.send(`<script>alert('Mekan Sahibi detayı eklenemedi.'); window.location.href='/giris_kayit.html';</script>`);
                    res.send("<script>alert('🏛️ Mekan Sahibi kaydınız başarıyla mühürlendi! Şimdi giriş yapıp organizatör kiralama taleplerini yönetebilirsiniz.'); window.location.href='/giris_kayit.html';</script>");
                });
            } 
            else if (role === 'Admin') {
                // Yönetici rolü için ADMIN yetki seviyesi ataması
                db.query(`INSERT INTO ADMIN (Admin_ID, Yetki_Seviyesi) VALUES (?, 5)`, [yeniKullaniciID], (err) => {
                    if (err) return res.send(`<script>alert('Yönetici detayı eklenemedi.'); window.location.href='/giris_kayit.html';</script>`);
                    res.send("<script>alert('🛡️ Üst Düzey Yönetici (Admin) hesabı oluşturuldu! Sisteme tam moderasyon yetkisiyle erişebilirsiniz.'); window.location.href='/giris_kayit.html';</script>");
                });
            } else {
                res.send("<script>alert('Geçersiz rol seçimi yapıldı.'); window.location.href='/giris_kayit.html';</script>");
            }
        });
    });
});


// ETKİNLİK LİSTELEME VE AKILLI ŞEHİR SIRALAMA MOTORU

app.get('/api/etkinlikler', (req, res) => {
    const katilimciId = req.query.katilimciId;

    const sqlOnayli = `
        SELECT E.Etkinlik_ID, E.Etkinlik_Adi, E.Etkinlik_Kategori, E.Aciklama, E.Baslangic_Zamani, M.Mekan_ID, M.Mekan_Adi, M.Sehir, M.Kapasite,
        MAX(B.Fiyat) as fiyat, 
        (SELECT COUNT(*) FROM BILET WHERE Etkinlik_ID = E.Etkinlik_ID AND Durum = 'Geçerli') as SatilanBilet
        FROM ETKINLIK E 
        JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID
        LEFT JOIN BILET B ON E.Etkinlik_ID = B.Etkinlik_ID
        WHERE E.Onay_Durumu = 'Onaylandı' OR E.Onay_Durumu = 'Beklemede'
        GROUP BY E.Etkinlik_ID
        ORDER BY E.Baslangic_Zamani ASC`;

    if (katilimciId && katilimciId !== 'null' && katilimciId !== 'undefined') {
        db.query(`SELECT Sehir FROM KATILIMCI WHERE Katilimci_ID = ?`, [katilimciId], (err, katRes) => {
            const katSehir = (katRes && katRes.length > 0) ? katRes[0].Sehir : '';
            
            const sqlSehirli = `
                SELECT E.Etkinlik_ID, E.Etkinlik_Adi, E.Etkinlik_Kategori, E.Aciklama, E.Baslangic_Zamani, M.Mekan_ID, M.Mekan_Adi, M.Sehir, M.Kapasite,
                MAX(B.Fiyat) as fiyat,
                (SELECT COUNT(*) FROM BILET WHERE Etkinlik_ID = E.Etkinlik_ID AND Durum = 'Geçerli') as SatilanBilet
                FROM ETKINLIK E 
                JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID
                LEFT JOIN BILET B ON E.Etkinlik_ID = B.Etkinlik_ID
                WHERE E.Onay_Durumu = 'Onaylandı' OR E.Onay_Durumu = 'Beklemede'
                GROUP BY E.Etkinlik_ID
                ORDER BY CASE WHEN M.Sehir = ? THEN 0 ELSE 1 END ASC, E.Baslangic_Zamani ASC`;
                
            db.query(sqlSehirli, [katSehir], (err, sonuclar) => {
                if (err) return res.status(500).json({ hata: err.message });
                res.json(sonuclar);
            });
        });
    } else {
        db.query(sqlOnayli, (err, sonuclar) => {
            if (err) return res.status(500).json({ hata: err.message });
            res.json(sonuclar);
        });
    }
});


//  ORGANİZATÖR YETKİSİ - ETKİNLİK SİLME MOTORU

app.post('/api/etkinlik-sil', (req, res) => {
    const { etkinlikID } = req.body;
    if (!etkinlikID) return res.json({ basarili: false, mesaj: "Etkinlik ID eksik!" });

    db.query(`DELETE FROM BILET WHERE Etkinlik_ID = ?`, [etkinlikID], (err) => {
        if (err) return res.json({ basarili: false, mesaj: err.message });

        db.query(`DELETE FROM ETKINLIK WHERE Etkinlik_ID = ?`, [etkinlikID], (err, sonuc) => {
            if (err) return res.json({ basarili: false, mesaj: "Etkinlik silinirken hata oluştu: " + err.message });
            res.json({ basarili: true, mesaj: "Etkinlik veritabanından başarıyla temizlendi!" });
        });
    });
});


//  ORGANİZATÖR - YENİ ETKİNLİK TALEBİ

app.post('/api/etkinlik-ekle', (req, res) => {
    const { ad, kategori, aciklama, zaman, mekanID, organizatorID, biletFiyati, fiyat } = req.body;
    const asilFiyat = biletFiyati || fiyat || 400;

    db.query(`SELECT Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID = ?`, [organizatorID], (err, userRes) => {
        if (err || userRes.length === 0) return res.json({ basarili: false, mesaj: "Kullanıcı doğrulanamadı!" });
        if (userRes[0].Hesap_Durumu === 'Askıda') {
            return res.json({ basarili: false, mesaj: "❌ Yetki Reddedildi: Hesabınız askıda!" });
        }

        const secilenZaman = new Date(zaman);
        const simdi = new Date();
        if (secilenZaman < simdi) {
            return res.json({ basarili: false, mesaj: "❌ Kural İhlali: Geçmiş bir zaman dilimine yeni etkinlik tanımlanamaz!" });
        }

        const dinamikAciklama = `${aciklama} |||FIYAT:${asilFiyat}|||`;
        const sql = `INSERT INTO ETKINLIK (Etkinlik_Adi, Etkinlik_Kategori, Aciklama, Baslangic_Zamani, Bitis_Zamani, Mekan_ID, Organizator_ID, Onay_Durumu) VALUES (?, ?, ?, ?, DATE_ADD(?, INTERVAL 3 HOUR), ?, ?, 'Beklemede')`;
        
        db.query(sql, [ad, kategori, dinamikAciklama, zaman, zaman, mekanID, organizatorID], (err) => {
            if (err) return res.json({ basarili: false, mesaj: err.message });
            res.json({ basarili: true, mesaj: "⏳ Rezervasyon Talebi Alındı: Etkinlik onay bekliyor durumunda mekan sahibine iletildi!" });
        });
    });
});


//  MEKAN SAHİBI - TALEP ONAY / RED MODERASYON MOTORU

app.post('/api/mekan-talep-moderasyon', (req, res) => {
    const { etkinlikID, aksiyon } = req.body;

    if (!etkinlikID || !aksiyon) {
        return res.json({ basarili: false, mesaj: "Gerekli moderasyon parametreleri eksik!" });
    }

    const sql = `UPDATE ETKINLIK SET Onay_Durumu = ? WHERE Etkinlik_ID = ?`;
    db.query(sql, [aksiyon, etkinlikID], (err, sonuc) => {
        if (err) return res.json({ basarili: false, mesaj: err.message });
        res.json({ basarili: true, mesaj: `Etkinlik kiralama talebi veritabanında '${aksiyon}' statüsüne getirildi.` });
    });
});


//  KATILIMCI - GERÇEK ZAMANLI BİLET SATIN ALMA MOTORU

app.post('/api/bilet-al', (req, res) => {
    const { katilimciID, etkinlikID, fiyat, kategori, koltukNo } = req.body; 
    let sayisalFiyat = parseFloat(fiyat);

    const nihaiKategori = kategori || 'Standart';
    const nihaiKoltukNo = koltukNo || 'Ayakta / Numarasız';

    db.query(`SELECT Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID = ?`, [katilimciID], (err, userRes) => {
        if (err || userRes.length === 0) return res.json({ basarili: false, mesaj: "Katılımcı bulunamadı!" });
        if (userRes[0].Hesap_Durumu === 'Askıda') {
            return res.json({ basarili: false, mesaj: "❌ İşlem Engellendi: Hesabınız askıya alınmıştır!" });
        }

        db.query(`SELECT COUNT(*) as KatilimciMi FROM KATILIMCI WHERE Katilimci_ID = ?`, [katilimciID], (err, rolCheck) => {
            const kapasiteSql = `
                SELECT M.Kapasite, 
                (SELECT COUNT(*) FROM BILET WHERE Etkinlik_ID = ? AND Durum = 'Geçerli') as Satilan 
                FROM ETKINLIK E 
                JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID 
                WHERE E.Etkinlik_ID = ?`;
            
            db.query(kapasiteSql, [etkinlikID, etkinlikID], (err, kapRes) => {
                if (err || !kapRes || kapRes.length === 0) return res.json({ basarili: false, mesaj: "Etkinlik/Mekan kapasite detayına ulaşılamadı." });
                if (kapRes[0].Satilan >= kapRes[0].Kapasite) return res.json({ basarili: false, mesaj: "❌ Satış Reddedildi: Kontenjan doludur!" });

                db.query(`SELECT Bakiye, Indirim_Kodu FROM KATILIMCI WHERE Katilimci_ID = ?`, [katilimciID], (err, katRes) => {
                    if (err || !katRes || katRes.length === 0) return res.json({ basarili: false, mesaj: "Katılımcı cüzdan bilgisi okunamadı." });
                    
                    if (katRes[0].Indirim_Kodu === 'ILK20') sayisalFiyat = sayisalFiyat * 0.80;

                    const mevcutBakiye = parseFloat(katRes[0].Bakiye);
                    if (mevcutBakiye < sayisalFiyat) return res.json({ basarili: false, mesaj: `❌ Yetersiz Bakiye! Gereken: ${sayisalFiyat.toFixed(2)} TL.` });

                    db.query(`UPDATE KATILIMCI SET Bakiye = Bakiye - ? WHERE Katilimci_ID = ?`, [sayisalFiyat, katilimciID], (err) => {
                        if (err) return res.json({ basarili: false, mesaj: "Finansal güncelleme hatası." });

                        const biletSql = `INSERT INTO BILET (Fiyat, Bilet_Kategori, Koltuk_No, Durum, Etkinlik_ID, Katilimci_ID) VALUES (?, ?, ?, 'Geçerli', ?, ?)`;
                        db.query(biletSql, [sayisalFiyat, nihaiKategori, nihaiKoltukNo, etkinlikID, katilimciID], (err) => {
                            if (err) return res.json({ basarili: false, mesaj: "Bilet tablosuna kayıt yazılamadı: " + err.message });
                            res.json({ basarili: true, mesaj: `🎉 Bilet başarıyla alındı! Kategori: ${nihaiKategori}, Alan: ${nihaiKoltukNo}` });
                        });
                    });
                });
            });
        });
    });
});

//  DETAY GETİRME KAPISI (LEFT JOIN KORUMALI)

app.get('/api/etkinlik-detay/:id', (req, res) => {
    const etkinlikID = req.params.id;
    
    const anaSql = `
        SELECT E.*, M.Mekan_ID, M.Mekan_Adi, M.Sehir, M.Mekan_Sahibi_ID, S.Sanatci_ID, S.Sahne_Adi, S.Biyografi 
        FROM ETKINLIK E 
        JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID
        LEFT JOIN ETKINLIK_SANATCI ES ON E.Etkinlik_ID = ES.Etkinlik_ID
        LEFT JOIN SANATCI S ON ES.Sanatci_ID = S.Sanatci_ID
        WHERE E.Etkinlik_ID = ?`;
    
    db.query(anaSql, [etkinlikID], (err, detaylar) => {
        if (err || !detaylar || detaylar.length === 0) {
            return res.status(200).json({ etkinlik: { Etkinlik_Adi: "Boş Etkinlik Yuvası", Taban_Fiyat: 400 }, yorumlar: [] });
        }
        
        db.query(`SELECT * FROM VW_ONAYLANMIS_YORUMLAR WHERE Etkinlik_ID = ?`, [etkinlikID], (err, yorumlar) => {
            res.json({ etkinlik: detaylar[0], yorumlar: yorumlar || [] });
        });
    });
});


//  BİLET İPTAL ETME (Askı Korumalı)

app.post('/api/bilet-iptal', (req, res) => {
    const biletID = req.body.biletID;
    db.query(`SELECT Fiyat, Katilimci_ID FROM BILET WHERE Bilet_ID = ?`, [biletID], (err, biletSonuc) => {
        if (err || biletSonuc.length === 0) return res.json({ basarili: false, mesaj: "Bilet kaydı bulunamadı." });
        const biletFiyati = parseFloat(biletSonuc[0].Fiyat);
        const katilimciID = biletSonuc[0].Katilimci_ID;
        db.query(`SELECT Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID = ?`, [katilimciID], (err, userRes) => {
            if (userRes[0].Hesap_Durumu === 'Askıda') return res.json({ basarili: false, mesaj: "❌ İşlem Engellendi: Hesabınız askıda!" });
            db.query(`DELETE FROM BILET WHERE Bilet_ID = ?`, [biletID], (err) => {
                db.query(`UPDATE KATILIMCI SET Bakiye = Bakiye + ? WHERE Katilimci_ID = ?`, [biletFiyati, katilimciID], (err) => {
                    res.json({ basarili: true, mesaj: `Bilet iptal edildi! ${biletFiyati} TL cüzdanınıza geri aktarıldı.` });
                });
            });
        });
    });
});


// KATILIMCI - BAKİYE TRANSFER SİSTEMİ (Askı Korumalı)

app.post('/api/bakiye-transfer', (req, res) => {
    const { gonderenID, aliciEposta, miktar } = req.body;
    const sayisalMiktar = parseFloat(miktar);
    db.query(`SELECT Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID = ?`, [gonderenID], (err, userRes) => {
        if (userRes[0].Hesap_Durumu === 'Askıda') return res.json({ basarili: false, mesaj: "❌ Transfer Engellendi!" });
        db.query(`SELECT Bakiye FROM KATILIMCI WHERE Katilimci_ID = ?`, [gonderenID], (err, gonderenRes) => {
            if (parseFloat(gonderenRes[0].Bakiye) < sayisalMiktar) return res.json({ basarili: false, mesaj: "❌ Yetersiz Bakiye!" });
            db.query(`SELECT Kullanici_ID FROM KULLANICI WHERE Eposta = ?`, [aliciEposta], (err, aliciRes) => {
                if (err || aliciRes.length === 0) return res.json({ basarili: false, mesaj: "❌ Alıcı Bulunamadı!" });
                const aliciID = aliciRes[0].Kullanici_ID;
                db.query(`UPDATE KATILIMCI SET Bakiye = Bakiye - ? WHERE Katilimci_ID = ?`, [sayisalMiktar, gonderenID], (err) => {
                    db.query(`UPDATE KATILIMCI SET Bakiye = Bakiye + ? WHERE Katilimci_ID = ?`, [sayisalMiktar, aliciID], (err) => {
                        res.json({ basarili: true, mesaj: `🎁 Bakiye başarıyla transfer edildi.` });
                    });
                });
            });
        });
    });
});


//  KATILIMCI YORUM YAPMA KATMANI

app.post('/api/yorum-yap', (req, res) => {
    const { icerik, puan, etkinlikID, katilimciID } = req.body;
    db.query(`SELECT Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID = ?`, [katilimciID], (err, userRes) => {
        if (userRes[0].Hesap_Durumu === 'Askıda') return res.json({ basarili: false, mesaj: "❌ Yetki Reddedildi!" });
        const sql = `INSERT INTO YORUM_VE_PUANLAMA (Icerik, Puan, Onay_Durumu, Etkinlik_ID, Katilimci_ID) VALUES (?, ?, 'Beklemede', ?, ?)`;
        db.query(sql, [icerik, puan, etkinlikID, katilimciID], (err) => {
            res.json({ basarili: true, mesaj: "⏳ Yorumunuz moderasyon sırasına iletildi!" });
        });
    });
});

app.get('/api/takip-kontrol', (req, res) => {
    const { katilimciID, hedefID, hedefTuru } = req.query;
    db.query(`SELECT COUNT(*) as TakipVarMi FROM TAKIP_LISTESI WHERE Katilimci_ID = ? AND Hedef_ID = ? AND Hedef_Turu = ?`, [katilimciID, hedefID, hedefTuru], (err, result) => {
        res.json({ takipte: result && result[0].TakipVarMi > 0 });
    });
});

app.post('/api/takip-et', (req, res) => {
    const { katilimciID, hedefID, hedefTuru } = req.body;
    db.query(`SELECT Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID = ?`, [katilimciID], (err, userRes) => {
        if (userRes[0].Hesap_Durumu === 'Askıda') return res.json({ basarili: false, mesaj: "❌ Hesabınız askıda!" });
        db.query(`INSERT INTO TAKIP_LISTESI (Katilimci_ID, Hedef_ID, Hedef_Turu) VALUES (?, ?, ?)`, [katilimciID, hedefID, hedefTuru], (err) => {
            res.json({ basarili: true, mesaj: " Takip listenize eklendi!" });
        });
    });
});

app.post('/api/takip-birak', (req, res) => {
    const { katilimciID, hedefID, presidential, hedefTuru } = req.body;
    db.query(`DELETE FROM TAKIP_LISTESI WHERE Katilimci_ID = ? AND Hedef_ID = ? AND Hedef_Turu = ?`, [katilimciID, hedefID, hedefTuru], (err) => {
        res.json({ basarili: true, mesaj: "❌ Takip listenizden kaldırıldı!" });
    });
});

app.get('/api/profil/:id', (req, res) => {
    const kullaniciID = req.params.id;
    const anaSorgu = `SELECT K.Ad_Soyad, K.Eposta, K.Telefon, K.Hesap_Durumu, (SELECT COUNT(*) FROM KATILIMCI WHERE Katilimci_ID = K.Kullanici_ID) as KatilimciMi, (SELECT COUNT(*) FROM ORGANIZATOR WHERE Organizator_ID = K.Kullanici_ID) as OrganizatorMi, (SELECT COUNT(*) FROM MEKAN_SAHIBI WHERE Mekan_Sahibi_ID = K.Kullanici_ID) as MekanSahibiMi, (SELECT COUNT(*) FROM ADMIN WHERE Admin_ID = K.Kullanici_ID) as AdminMi FROM KULLANICI K WHERE K.Kullanici_ID = ?`;
    db.query(anaSorgu, [kullaniciID], (err, sonuclar) => {
        const user = sonuclar[0];
        if (user.KatilimciMi > 0) {
            db.query(`SELECT Sehir, Bakiye, Indirim_Kodu FROM KATILIMCI WHERE Katilimci_ID = ?`, [kullaniciID], (err, katDetay) => {
                const biletSql = `SELECT B.Bilet_ID, B.Fiyat, B.Koltuk_No, B.Durum, E.Etkinlik_Adi, M.Mekan_Adi, E.Baslangic_Zamani FROM BILET B JOIN ETKINLIK E ON B.Etkinlik_ID = E.Etkinlik_ID JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID WHERE B.Katilimci_ID = ?`;
                db.query(biletSql, [kullaniciID], (err, biletler) => {
                    const takipSql = `SELECT T.Hedef_ID, T.Hedef_Turu, CASE WHEN T.Hedef_Turu = 'Sanatçı' THEN S.Sahne_Adi ELSE M.Mekan_Adi END as Isim, CASE WHEN T.Hedef_Turu = 'Sanatçı' THEN S.Tur ELSE M.Sehir END as Detay FROM TAKIP_LISTESI T LEFT JOIN SANATCI S ON T.Hedef_ID = S.Sanatci_ID AND T.Hedef_Turu = 'Sanatçı' LEFT JOIN MEKAN M ON T.Hedef_ID = M.Mekan_ID AND T.Hedef_Turu = 'Mekan' WHERE T.Katilimci_ID = ?`;
                    db.query(takipSql, [kullaniciID], (err, takipleri) => {
                        res.json({ rol: 'Katılımcı', bilgiler: { ...user, ...katDetay[0] }, liste: biletler, takipleri: takipleri });
                    });
                });
            });
        } else if (user.OrganizatorMi > 0) {
            db.query(`SELECT Firma_Adi, Vergi_No, IBAN_No FROM ORGANIZATOR WHERE Organizator_ID = ?`, [kullaniciID], (err, orgDetay) => {
                const orgEtkinliklerSql = `SELECT E.Etkinlik_ID, E.Etkinlik_Adi, E.Etkinlik_Kategori, E.Onay_Durumu, M.Mekan_Adi, COUNT(B.Bilet_ID) as SatilanBilet, M.Kapasite FROM ETKINLIK E JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID LEFT JOIN BILET B ON E.Etkinlik_ID = B.Etkinlik_ID WHERE E.Organizator_ID = ? GROUP BY E.Etkinlik_ID`;
                db.query(orgEtkinliklerSql, [kullaniciID], (err, etkinlikler) => {
                    const finSql = `SELECT IFNULL(SUM(B.Fiyat), 0) as CanliCiro FROM BILET B JOIN ETKINLIK E ON B.Etkinlik_ID = E.Etkinlik_ID WHERE E.Organizator_ID = ? AND E.Onay_Durumu = 'Onaylandı'`;
                    db.query(finSql, [kullaniciID], (err, finRes) => {
                        res.json({ rol: 'Organizatör', bilgiler: { ...user, ...orgDetay[0], CanliBakiye: finRes[0].CanliCiro }, liste: etkinlikler });
                    });
                });
            });
        } else if (user.MekanSahibiMi > 0) {
            db.query(`SELECT Isletme_Turu, Sertifika_No FROM MEKAN_SAHIBI WHERE Mekan_Sahibi_ID = ?`, [kullaniciID], (err, mekanSahibiDetay) => {
                const mekanlarSql = `SELECT E.Etkinlik_ID, E.Etkinlik_Adi, E.Etkinlik_Kategori, E.Onay_Durumu, DATE_FORMAT(E.Baslangic_Zamani, '%Y-%m-%d %H:%i') as Baslangic_Zamani, M.Mekan_Adi, M.Kapasite, M.Sehir FROM ETKINLIK E JOIN MEKAN M ON E.Mekan_ID = M.Mekan_ID WHERE M.Mekan_Sahibi_ID = ? ORDER BY E.Baslangic_Zamani ASC`;
                db.query(mekanlarSql, [kullaniciID], (err, mekanlar) => {
                    res.json({ rol: 'Mekan Sahibi', bilgiler: { ...user, ...mekanSahibiDetay[0] }, liste: mekanlar });
                });
            });
        } else if (user.AdminMi > 0) {
            db.query(`SELECT Kullanici_ID, Ad_Soyad, Hesap_Durumu FROM KULLANICI WHERE Kullanici_ID != ?`, [kullaniciID], (err, tumKullanicilar) => {
                const bekleyenYorumlarSql = `SELECT Y.Yorum_ID, Y.Icerik, Y.Puan, Y.Onay_Durumu, E.Etkinlik_Adi, K.Ad_Soyad as KatilimciAdi FROM YORUM_VE_PUANLAMA Y JOIN ETKINLIK E ON Y.Etkinlik_ID = E.Etkinlik_ID JOIN KULLANICI K ON Y.Katilimci_ID = K.Kullanici_ID ORDER BY Y.Yorum_ID DESC`;
                db.query(bekleyenYorumlarSql, (err, yorumlar) => {
                    res.json({ rol: 'Admin', bilgiler: { ...user, Yetki_Seviyesi: 5 }, liste: yorumlar, kullanicilar: tumKullanicilar });
                });
            });
        }
    });
});

app.get('/api/mekanlar', (req, res) => {
    db.query(`SELECT Mekan_ID, Mekan_Adi FROM MEKAN`, (err, data) => { res.json(data); });
});


//  YORUM MODERASYON KAPISI

app.post('/api/yorum-moderasyon', (req, res) => {
    const { yorumID, aksiyon } = req.body;
    let sql = aksiyon === 'onayla' ? `UPDATE YORUM_VE_PUANLAMA SET Onay_Durumu = 'Onaylandı' WHERE Yorum_ID = ?` : `UPDATE YORUM_VE_PUANLAMA SET Onay_Durumu = 'Reddedildi' WHERE Yorum_ID = ?`;

    db.query(sql, [yorumID], (err) => {
        if (err) return res.json({ basarili: false, mesaj: err.message });
        res.json({ basarili: true, mesaj: aksiyon === 'onayla' ? "Yorum veritabanında onaylandı!" : "Yorum reddedildi!" });
    });
});

app.listen(port, () => {
    console.log(`SYNAPZ Sistemi Sorunsuz Ayakta! Port: ${port} 2026 `);
});

// HESAP DURUMU GÜNCELLEME 

app.post('/api/hesap-durumu-guncelle', (req, res) => {
    const { hedefKullaniciID, yeniDurum } = req.body;
    
    // Değerlerin 'Askıda' veya 'Aktif' olduğundan emin oluyoruz (Boşlukları temizle)
    const durum = yeniDurum.trim();

    const sql = `UPDATE KULLANICI SET Hesap_Durumu = ? WHERE Kullanici_ID = ?`;
    db.query(sql, [durum, hedefKullaniciID], (err, result) => {
        if (err) {
            console.error("Güncelleme hatası:", err);
            return res.json({ basarili: false, mesaj: "Veritabanı hatası: " + err.message });
        }
        
        if (result.affectedRows === 0) {
            return res.json({ basarili: false, mesaj: "Kullanıcı bulunamadı veya güncelleme yapılamadı." });
        }
        
        res.json({ basarili: true, mesaj: `Kullanıcı hesabı başarıyla '${durum}' durumuna getirildi.` });
    });
});