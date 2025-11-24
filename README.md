# SmartClinic Mobil Uygulaması

Bu proje, **SmartClinic** ekosisteminin Flutter ile geliştirilmiş **mobil uygulama** kısmını içermektedir. Uygulama hem **hasta** hem de **doktor** kullanıcıları için tasarlanmış olup, modern bir sağlık yönetim sistemi sunar.

---

## 📱 Proje Özeti

SmartClinic Mobil uygulaması, kullanıcıların laboratuvar tahlillerini yükleyip sonuçlarını görüntüleyebileceği, doktorların ise hasta tahlil verilerini takip edebileceği bir dijital sağlık platformudur. Uygulama **Flutter (Dart)** ile geliştirilmiş olup, **ASP.NET Core API** ile haberleşir.

---

## 🏗️ Proje Yapısı

```
smartclinic/               # Flutter projesi ana klasörü
├── lib/                   # Sayfalar, servisler ve modeller
│   ├── dashboard_doctor.dart
│   ├── dashboard_patient.dart
│   ├── register_page.dart
│   ├── login_page.dart
│   ├── services/          # API bağlantı servisleri
│   │   ├── test_service.dart
│   │   └── pdf_upload_service.dart
│   └── widgets/           # UI bileşenleri
├── assets/                # Görseller ve PDF test dosyaları
└── pubspec.yaml           # Bağımlılıklar
```

---

## ⚙️ Özellikler

### 👩‍⚕️ Doktor Paneli

* Tüm hastaların tahlil verilerine erişim.
* Her bir testin referans aralıklarının takibi.
* Anlık test sonuçlarını görüntüleme.

### 🧑‍⚕️ Hasta Paneli

* PDF formatında tahlil sonucu yükleme.
* Test sonuçlarını tarih bazında listeleme.
* Referans dışı sonuçları kırmızı renkte gösterme.
* Önceki test geçmişine erişim.

### 🔐 Kimlik Doğrulama

* Kullanıcı kayıt ve giriş işlemleri **SmartClinic API** üzerinden yapılır.
* Roller: `doctor` ve `patient` olarak ikiye ayrılır.
* Başarılı giriş sonrasında ilgili panele yönlendirme yapılır.

---

## 🧠 Veri Akışı

1. Kullanıcı (hasta) PDF test dosyasını yükler.
2. Uygulama, PDF içeriğini analiz ederek test adlarını, sonuçlarını ve referans aralıklarını çıkarır.
3. Elde edilen veriler **API’ye JSON formatında** gönderilir.
4. Sunucu, verileri PostgreSQL veritabanına kaydeder.
5. Kullanıcı, daha sonra geçmiş testleri tarih sırasına göre listeleyebilir.

---

## 🔌 API Bağlantısı

Flutter uygulaması aşağıdaki API uç noktalarına bağlanır:

| Endpoint              | Açıklama                                        |
| --------------------- | ----------------------------------------------- |
| `/api/auth/register`  | Yeni kullanıcı kaydı (hasta/doktor)             |
| `/api/auth/login`     | Kullanıcı girişi                                |
| `/api/test/add`       | Yeni test verisi ekleme                         |
| `/api/test/user/{id}` | Belirli bir kullanıcının test geçmişini getirme |

---

## 🧩 Kullanılan Teknolojiler

| Katman         | Teknoloji                      |
| -------------- | ------------------------------ |
| Mobil Uygulama | Flutter (Dart)                 |
| UI             | Material Design Widgets        |
| HTTP İletişimi | http package                   |
| Dosya Yükleme  | file_picker package            |
| API            | ASP.NET Core (SmartClinic API) |

---

## 🚀 Kurulum

### 1. Gerekli paketleri yükle

```bash
flutter pub get
```

### 2. API bağlantısını düzenle

`lib/services/test_service.dart` ve `pdf_upload_service.dart` dosyalarındaki IP adresini kendi API sunucuna göre değiştir:

```dart
static const String baseUrl = 'http://192.168.x.x:5080/api/test';
```

### 3. Uygulamayı çalıştır

```bash
flutter run
```

---

## 🧾 Örnek Veri (API’ye gönderilen JSON)

```json
{
  "userId": "5",
  "testName": "Hemoglobin (HGB)",
  "result": "10.4",
  "referenceRange": "11.5-15.5",
  "isOutOfRange": true,
  "date": "2025-11-24T22:32:45.174895Z"
}
```

---



## 👩‍💻 Geliştirici

**Hevin Ateş**

Flutter & .NET Entegrasyon Geliştiricisi

---

## 🏥 SmartClinic Mobil

Modern, güvenli ve kullanıcı dostu bir dijital sağlık yönetim platformu.
