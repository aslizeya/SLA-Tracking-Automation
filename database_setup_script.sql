-- ==============================================================================
-- 1. DATABASE CREATION
-- ==============================================================================
-- CREATE DATABASE SLA_Takip_Sistemi;
-- GO
USE SLA_Takip_Sistemi;
GO

-- ==============================================================================
-- 2. TABLE CREATION
-- ==============================================================================
CREATE TABLE Tedarikciler (
    TedarikciID INT PRIMARY KEY IDENTITY(1,1),
    FirmaAdi NVARCHAR(100) NOT NULL,
    IletisimKisi NVARCHAR(50),
    Email NVARCHAR(100)
);
GO

CREATE TABLE SLA_Kriterleri (
    KriterID INT PRIMARY KEY IDENTITY(1,1),
    TedarikciID INT FOREIGN KEY REFERENCES Tedarikciler(TedarikciID),
    ToleransSaati INT NOT NULL,
    SaatlikCezaTutari DECIMAL(18,2) NOT NULL
);
GO

CREATE TABLE Siparisler (
    SiparisID INT PRIMARY KEY IDENTITY(1,1),
    TedarikciID INT FOREIGN KEY REFERENCES Tedarikciler(TedarikciID),
    SiparisTarihi DATETIME NOT NULL,
    BeklenenTeslim DATETIME NOT NULL,
    GerceklesenTeslim DATETIME NULL,
    ToplamUrun INT NOT NULL,
    KusurluUrun INT DEFAULT 0,
    SiparisDurumu NVARCHAR(50) DEFAULT 'Bekliyor',
    SLA_HesaplandiMi BIT DEFAULT 0
);
GO

CREATE TABLE SLA_Ihlalleri (
    IhlalID INT PRIMARY KEY IDENTITY(1,1),
    SiparisID INT FOREIGN KEY REFERENCES Siparisler(SiparisID),
    IhlalTipi NVARCHAR(50) NOT NULL,
    GecikmeSuresi INT NOT NULL,
    KesilenCeza DECIMAL(18,2) NOT NULL,
    TespitTarihi DATETIME DEFAULT GETDATE()
);
GO

-- ==============================================================================
-- 3. DUMMY DATA INSERTION
-- ==============================================================================
INSERT INTO Tedarikciler (FirmaAdi, IletisimKisi, Email) VALUES 
('Mavi Kutu Lojistik', 'Ahmet Yilmaz', 'ahmet@mavikutu.com'),
('Hizli Kargo A.S.', 'Ayse Demir', 'ayse@hizlikargo.com');
GO

INSERT INTO SLA_Kriterleri (TedarikciID, ToleransSaati, SaatlikCezaTutari) VALUES 
(1, 24, 50.00), -- Mavi Kutu: 24 saat tolerans, saatlik ceza 50 TL
(2, 12, 100.00); -- Hizli Kargo: 12 saat tolerans, saatlik ceza 100 TL
GO

INSERT INTO Siparisler (TedarikciID, SiparisTarihi, BeklenenTeslim, GerceklesenTeslim, ToplamUrun, SiparisDurumu, SLA_HesaplandiMi)
VALUES 
-- Tedarikci 1
(1, '2026-07-10', '2026-07-15 17:00:00', '2026-07-14 10:00:00', 150, 'Teslim Edildi', 0), 
(1, '2026-07-12', '2026-07-16 12:00:00', '2026-07-18 15:00:00', 200, 'Teslim Edildi', 0), 
(1, '2026-07-15', '2026-07-18 09:00:00', '2026-07-18 09:30:00', 50,  'Teslim Edildi', 0), 
(1, '2026-07-18', '2026-07-22 17:00:00', '2026-07-22 16:45:00', 400, 'Teslim Edildi', 0), 
(1, '2026-07-20', '2026-07-25 10:00:00', '2026-07-28 10:00:00', 100, 'Teslim Edildi', 0), 
(1, '2026-07-25', '2026-07-30 17:00:00', '2026-07-29 11:00:00', 80,  'Teslim Edildi', 0), 
(1, '2026-07-28', '2026-08-01 12:00:00', '2026-08-03 14:00:00', 600, 'Teslim Edildi', 0), 
(1, '2026-08-01', '2026-08-05 17:00:00', '2026-08-05 16:50:00', 120, 'Teslim Edildi', 0), 
-- Tedarikci 2
(2, '2026-07-11', '2026-07-14 17:00:00', '2026-07-17 09:00:00', 300, 'Teslim Edildi', 0), 
(2, '2026-07-14', '2026-07-19 12:00:00', '2026-07-21 14:00:00', 150, 'Teslim Edildi', 0), 
(2, '2026-07-19', '2026-07-23 17:00:00', '2026-07-23 18:00:00', 250, 'Teslim Edildi', 0), 
(2, '2026-07-22', '2026-07-27 12:00:00', '2026-07-30 10:00:00', 450, 'Teslim Edildi', 0), 
(2, '2026-07-26', '2026-07-29 17:00:00', '2026-07-29 15:00:00', 90,  'Teslim Edildi', 0), 
(2, '2026-07-29', '2026-08-02 12:00:00', '2026-08-06 09:00:00', 700, 'Teslim Edildi', 0), 
(2, '2026-08-03', '2026-08-06 17:00:00', '2026-08-06 16:00:00', 110, 'Teslim Edildi', 0); 
GO

-- ==============================================================================
-- 4. VIEW CREATION FOR POWER BI
-- ==============================================================================
IF OBJECT_ID('vw_SLA_YoneticiRaporu', 'V') IS NOT NULL
    DROP VIEW vw_SLA_YoneticiRaporu;
GO

CREATE VIEW vw_SLA_YoneticiRaporu AS
SELECT 
    s.SiparisID,
    t.FirmaAdi AS TedarikciFirma,
    s.SiparisTarihi,
    s.BeklenenTeslim,
    s.GerceklesenTeslim,
    s.ToplamUrun,
    s.SiparisDurumu,
    ISNULL(DATEDIFF(HOUR, s.BeklenenTeslim, s.GerceklesenTeslim), 0) AS ToplamGecikmeSaati,
    ISNULL(i.KesilenCeza, 0) AS ToplamCezaTutari,
    CASE 
        WHEN s.GerceklesenTeslim IS NULL THEN 'Henüz Teslim Edilmedi'
        WHEN s.GerceklesenTeslim <= s.BeklenenTeslim THEN 'Zamanında / Erken'
        ELSE 'Gecikti'
    END AS TeslimatPerformansi
FROM Siparisler s
LEFT JOIN Tedarikciler t ON s.TedarikciID = t.TedarikciID
LEFT JOIN SLA_Ihlalleri i ON s.SiparisID = i.SiparisID;
GO