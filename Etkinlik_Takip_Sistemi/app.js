const express = require('express');
const mysql = require('mysql2');
const path = require('path');
const app = express();
const port = 3000;

// VERİTABANI BAĞLANTISI 
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'z0908.',
  database: 'EtkinlikTakipDB'
});

// Veritabanı bağlantı kontrolü
db.connect((err) => {
    if (err) {
        console.error('Veritabanına bağlanırken hata oluştu: ' + err.stack);
        return;
    }
    console.log('Node.js, MySQL veritabanına başarıyla bağlandı!');
});


// KLASÖR TANIMLAMA 
// HTML ve CSS dosyalarının "views" klasöründe olduğunu Express'e söylüyoruz
// KLASÖR TANIMLAMA (CSS, Görseller ve HTML yollarını ayırıyoruz)
app.use('/public', express.static(path.join(__dirname, 'public'))); // public klasörünü /public ön ekiyle açar
app.use(express.static(path.join(__dirname, 'views')));             // HTML sayfalarını doğrudan açar

// VERİ API'LERİ (Web sitesi veri istediğinde MySQL'den çekilen yerler)
app.get('/api/etkinlikler', (req, res) => {
    db.query('SELECT * FROM ETKINLIK', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
});

app.get('/api/yorumlar', (req, res) => {
    db.query('SELECT * FROM VW_ONAYLANMIS_YORUMLAR', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
});


// SUNUCUYU ATEŞLEME
app.listen(port, () => {
    console.log(`Siteniz yayında! Tarayıcıdan şu adrese girin -> http://localhost:${port}`);
});