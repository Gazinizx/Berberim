# Berberim

Berberim, birden fazla berber işletmesini destekleyen Flutter tabanlı Android ve iOS randevu uygulamasıdır. Uygulamanın backend'i **Supabase** kullanır; Firebase/Firestore kullanılmaz.

## Özellikler
- E-posta ve şifre ile kayıt/giriş
- İşletme başvurusu ve yönetici onayı
- İşletme katılım kodu ile müşteri bağlantısı
- İşletme, çalışan, hizmet ve çalışma saatleri yönetimi
- Çalışan davet kodları
- Randevu oluşturma, iptal etme ve tamamlandı durumuna geçirme
- Çalışan ve işletme için randevu listeleri
- Supabase RLS politikaları ve veritabanı fonksiyonları

## Android derlemesi
GitHub Actions içindeki **Build Android APK** iş akışı, Supabase bağlantı değişkenlerini derleme sırasında tanımlar ve APK dosyasını artifact olarak yükler. APK'yı almak için:
1. GitHub deposunda **Actions** sekmesini aç.
2. En son **Build Android APK** çalışmasını seç.
3. Çalışma başarıyla tamamlandığında **Artifacts** bölümünden `berberim-supabase-release-apk` dosyasını indir.

## iOS
iOS derleme iş akışı ayrı tutulur. İmzalı IPA/TestFlight dağıtımı için Apple imzalama sertifikası ve provisioning profile gerekir.

## Güvenlik
- İstemci tarafında yönetici rolü verilemez.
- Erişim, Supabase Auth ve Row Level Security kurallarıyla denetlenir.
- Sunucu tarafı gizli anahtarlar uygulamaya veya depoya eklenmemelidir.
