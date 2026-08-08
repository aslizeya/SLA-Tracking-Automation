using System;
using Microsoft.Data.SqlClient;

namespace SLABot_Otomasyon
{
    class Program
    {
        static void Main(string[] args)
        { 
            string baglantiAdresi = "Server=localhost\\SQLEXPRESS;Database=SLA_Takip_Sistemi;Integrated Security=True;TrustServerCertificate=True;";

            Console.WriteLine("==================================================");
            Console.WriteLine("   TOPLU SLA HESAPLAMA SÜRECİ BAŞLATILDI...       ");
            Console.WriteLine("==================================================\n");

            
            using (SqlConnection baglanti = new SqlConnection(baglantiAdresi))
            {
                baglanti.Open();

              
                string sorgu = @"
                    SELECT 
                        s.SiparisID, 
                        s.BeklenenTeslim, 
                        s.GerceklesenTeslim, 
                        k.ToleransSaati, 
                        k.SaatlikCezaTutari 
                    FROM Siparisler s
                    INNER JOIN SLA_Kriterleri k ON s.TedarikciID = k.TedarikciID
                    WHERE s.SiparisDurumu = 'Teslim Edildi' AND s.SLA_HesaplandiMi = 0";

                SqlCommand komut = new SqlCommand(sorgu, baglanti);
                SqlDataReader okuyucu = komut.ExecuteReader();

                int islenenSiparisSayisi = 0;
                int kesilenCezaSayisi = 0;

                while (okuyucu.Read())
                {
                    islenenSiparisSayisi++;
                    int siparisId = Convert.ToInt32(okuyucu["SiparisID"]);
                    DateTime beklenenTarih = Convert.ToDateTime(okuyucu["BeklenenTeslim"]);

                    if (okuyucu["GerceklesenTeslim"] == DBNull.Value) continue;

                    DateTime gerceklesenTarih = Convert.ToDateTime(okuyucu["GerceklesenTeslim"]);
                    int tolerans = Convert.ToInt32(okuyucu["ToleransSaati"]);
                    decimal saatlikCeza = Convert.ToDecimal(okuyucu["SaatlikCezaTutari"]);

                    Console.WriteLine($"[İŞLENİYOR] Sipariş No: {siparisId}");

              
                    if (gerceklesenTarih > beklenenTarih)
                    {
                        TimeSpan fark = gerceklesenTarih - beklenenTarih;
                        int gecikenSaat = (int)fark.TotalHours;

                        if (gecikenSaat > tolerans)
                        {
                            decimal kesilecekCeza = (gecikenSaat - tolerans) * saatlikCeza;

                            Console.WriteLine($"  -> İHLAL TESPİT EDİLDİ! Gecikme: {gecikenSaat} saat. Ceza: {kesilecekCeza} TL");

                            
                            IhlaliYaz(baglantiAdresi, siparisId, gecikenSaat, kesilecekCeza);
                            kesilenCezaSayisi++;
                        }
                        else
                        {
                            Console.WriteLine($"  -> Gecikmiş ({gecikenSaat} saat) ama tolerans ({tolerans} saat) dahilinde. Ceza Yok.");
                        }
                    }
                    else
                    {
                        Console.WriteLine("  -> Sipariş zamanında veya erken teslim edilmiş. Sorun Yok.");
                    }

               
                    SiparisiKapat(baglantiAdresi, siparisId);
                }

                okuyucu.Close();

                Console.WriteLine("\n==================================================");
                Console.WriteLine($"ÖZET: Toplam {islenenSiparisSayisi} sipariş incelendi, {kesilenCezaSayisi} adet ceza kesildi.");
                Console.WriteLine("==================================================");
            }

            Console.WriteLine("Çıkmak için bir tuşa basın...");
            Console.ReadLine();
        }

        static void IhlaliYaz(string adres, int siparisId, int gecikmeSaat, decimal ceza)
        {
            using (SqlConnection baglanti = new SqlConnection(adres))
            {
                baglanti.Open();
                string sorgu = $"INSERT INTO SLA_Ihlalleri (SiparisID, IhlalTipi, GecikmeSuresi, KesilenCeza) VALUES ({siparisId}, 'Zaman', {gecikmeSaat}, {ceza.ToString().Replace(",", ".")})";
                SqlCommand komut = new SqlCommand(sorgu, baglanti);
                komut.ExecuteNonQuery();
            }
        }

        static void SiparisiKapat(string adres, int siparisId)
        {
            using (SqlConnection baglanti = new SqlConnection(adres))
            {
                baglanti.Open();
                string sorgu = $"UPDATE Siparisler SET SLA_HesaplandiMi = 1 WHERE SiparisID = {siparisId}";
                SqlCommand komut = new SqlCommand(sorgu, baglanti);
                komut.ExecuteNonQuery();
            }
        }
    }
}
