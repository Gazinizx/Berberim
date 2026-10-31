# Berberim

Berber ve müşterileri için tek Flutter uygulaması.

- Android APK: GitHub Actions ile otomatik derlenir.
- iOS: Flutter ortak kod tabanı hazırdır; iOS hazırlık workflow'u yalnızca manuel tetiklemeyle çalışır. Otomatik iOS derlemesi veya yüklemesi yapılmaz.
- Backend: Appwrite.

## Appwrite
- Endpoint: https://fra.cloud.appwrite.io/v1
- Project ID: 6ae66d0f00204ccbc2e8
- Database: berberim_db
- Collections: barbers, customers, services, appointments

## APK indirme
GitHub > Actions > Android APK > başarılı çalışma > Artifacts > Berberim-Android-APK.

## İlk sürüm kapsamı
Berber işletmesi oluşturma, davet koduyla müşteriyi işletmeye bağlama, hizmet tanımlama/listeleme ve randevu talebi akışının ilk iskeleti eklendi.

Çalışma saatleri, haftalık izinler, özel kapanışlar, gerçek uygun saat takvimi, çakışma kontrolü ve kalıcı kullanıcı hesapları sonraki geliştirme adımlarıdır. Bu nedenle mevcut APK bir ilk test sürümüdür; tam kullanıma hazır rezervasyon sistemi olarak değerlendirilmemelidir.
