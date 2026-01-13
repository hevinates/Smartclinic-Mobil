<div align="center">

# 🏥 SmartClinic - Akıllı Sağlık Yönetim Sistemi

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge)

**Hastalar ve doktorlar için geliştirilmiş, yapay zeka destekli modern sağlık yönetim uygulaması.**

[Özellikler](#-özellikler) • [Kurulum](#-kurulum) • [Ekran Görüntüleri](#-ekran-görüntüleri) • [Teknolojiler](#-kullanılan-teknolojiler) • [API](#-backend-api) • [Katkıda Bulunma](#-katkıda-bulunma)

</div>

---

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Özellikler](#-özellikler)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Proje Yapısı](#-proje-yapısı)
- [Kullanılan Teknolojiler](#-kullanılan-teknolojiler)
- [Backend API](#-backend-api)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)
- [İletişim](#-iletişim)

---

## 🎯 Proje Hakkında

**SmartClinic**, sağlık sektöründe hasta-doktor iletişimini kolaylaştırmak, tahlil sonuçlarını yönetmek ve yapay zeka destekli sağlık danışmanlığı sunmak amacıyla geliştirilmiş kapsamlı bir mobil/web uygulamasıdır.

### 🎓 Proje Amacı
Bu proje, modern sağlık hizmetlerinin dijitalleşmesi vizyonuyla geliştirilmiştir. Hastalar tahlil sonuçlarını kolayca takip edebilir, doktorlarıyla güvenli bir şekilde iletişim kurabilir ve AI destekli sağlık asistanından anlık destek alabilir.

---

## ✨ Özellikler

### 👨‍⚕️ Doktor Paneli
| Özellik | Açıklama |
|---------|----------|
| 📊 **Dashboard** | Hasta istatistikleri, günlük randevular ve hızlı erişim |
| 👥 **Hasta Yönetimi** | Kayıtlı hastaları görüntüleme ve yönetme |
| 🔬 **Tahlil Takibi** | Hasta tahlil sonuçlarını inceleme ve değerlendirme |
| 📅 **Randevu Yönetimi** | Randevu onaylama, reddetme ve takvim görünümü |
| 💬 **Mesajlaşma** | Hastalarla güvenli mesajlaşma |
| 📈 **Analitik** | Detaylı istatistikler ve grafikler |
| 👤 **Profil Yönetimi** | Kişisel bilgiler ve hastane bilgisi |

### 🏃 Hasta Paneli
| Özellik | Açıklama |
|---------|----------|
| 📊 **Dashboard** | Kişisel sağlık özeti ve hızlı erişim |
| 🔬 **Tahlillerim** | Tahlil sonuçlarını görüntüleme ve yükleme |
| 📋 **Raporlarım** | Sağlık raporlarını PDF olarak görüntüleme |
| 📅 **Randevu Alma** | Online randevu oluşturma ve takip |
| 💬 **Mesajlaşma** | Doktorla güvenli iletişim |
| 🤖 **AI Asistan** | Gemini AI destekli sağlık danışmanlığı |
| 👤 **Profil** | Kişisel ve sağlık bilgileri yönetimi |

### 🤖 AI Sağlık Asistanı (Gemini 2.5 Flash)
- 💬 Doğal dil ile sağlık sorularına yanıt
- 🔬 Tahlil sonuçlarını analiz etme ve yorumlama
- 💡 Kişiselleştirilmiş sağlık önerileri
- ⚠️ Acil durumlarda doktora yönlendirme
- 🇹🇷 Tamamen Türkçe dil desteği

---

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK `>= 3.9.2`
- Dart SDK `>= 3.9.2`
- Android Studio / VS Code
- Xcode (iOS için)
- Git

### Adım Adım Kurulum

#### 1️⃣ Projeyi Klonlayın
```bash
git clone https://github.com/hevinates/Smartclinic-Mobil.git
cd Smartclinic-Mobil
```

#### 2️⃣ Bağımlılıkları Yükleyin
```bash
flutter pub get
```

#### 3️⃣ API Anahtarını Ayarlayın
`lib/patient_chatbot_page.dart` dosyasında Gemini API anahtarınızı güncelleyin:
```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY';
```

#### 4️⃣ Backend URL'ini Ayarlayın
API endpoint'lerini kendi backend adresinize göre güncelleyin:
```dart
// Örnek: http://localhost:5080/api/
```

#### 5️⃣ Uygulamayı Çalıştırın

**iOS:**
```bash
flutter run -d ios
```

**Android:**
```bash
flutter run -d android
```

**Web:**
```bash
flutter run -d chrome
```

**macOS:**
```bash
flutter run -d macos
```

---

## 📱 Kullanım

### Hasta Girişi
1. Uygulamayı açın
2. "Hasta" rolünü seçin
3. E-posta ve şifre ile giriş yapın
4. Dashboard'dan tüm özelliklere erişin

### Doktor Girişi
1. Uygulamayı açın
2. "Doktor" rolünü seçin
3. E-posta ve şifre ile giriş yapın
4. Hasta listesi ve randevuları yönetin

### AI Asistan Kullanımı
1. Hasta panelinden "AI Asistan" sekmesine gidin
2. Sağlık sorunuzu yazın veya hızlı eylem butonlarını kullanın
3. Tahlillerinizi analiz ettirin
4. Kişiselleştirilmiş öneriler alın

---

## 📁 Proje Yapısı

```
smartclinic/
├── 📂 lib/
│   ├── 📄 main.dart                    # Uygulama giriş noktası
│   ├── 📄 login_page.dart              # Giriş sayfası
│   ├── 📄 register_page.dart           # Kayıt sayfası
│   ├── 📄 role_select_page.dart        # Rol seçim sayfası
│   │
│   ├── 🏥 HASTA MODÜLÜ
│   ├── 📄 dashboard_patient.dart       # Hasta ana paneli
│   ├── 📄 patient_profile_page.dart    # Hasta profil sayfası
│   ├── 📄 patient_tests_page.dart      # Tahlil sonuçları
│   ├── 📄 patient_reports_page.dart    # Raporlar
│   ├── 📄 patient_appointment_page.dart# Randevu alma
│   ├── 📄 patient_messages_page.dart   # Mesajlaşma
│   ├── 📄 patient_chatbot_page.dart    # AI Sağlık Asistanı
│   │
│   ├── 👨‍⚕️ DOKTOR MODÜLÜ
│   ├── 📄 dashboard_doctor.dart        # Doktor ana paneli
│   ├── 📄 doctor_profile_page.dart     # Doktor profil sayfası
│   ├── 📄 doctor_patients_page.dart    # Hasta listesi
│   ├── 📄 doctor_patient_tests_page.dart# Hasta tahlilleri
│   ├── 📄 doctor_appointments_page.dart# Randevu yönetimi
│   ├── 📄 doctor_messages_page.dart    # Mesajlaşma
│   ├── 📄 doctor_analytics_page.dart   # İstatistikler
│   │
│   ├── 🔬 TAHLİL MODÜLÜ
│   ├── 📄 test_list_page.dart          # Tahlil listesi
│   ├── 📄 test_detail_page.dart        # Tahlil detayı
│   ├── 📄 upload_result_page.dart      # Tahlil yükleme
│   │
│   └── 📂 services/                    # API servisleri
│
├── 📂 assets/
│   └── 📂 images/                      # Görseller
│
├── 📂 android/                         # Android yapılandırması
├── 📂 ios/                             # iOS yapılandırması
├── 📂 web/                             # Web yapılandırması
├── 📂 macos/                           # macOS yapılandırması
├── 📂 linux/                           # Linux yapılandırması
├── 📂 windows/                         # Windows yapılandırması
│
├── 📄 pubspec.yaml                     # Proje bağımlılıkları
├── 📄 analysis_options.yaml            # Lint kuralları
└── 📄 README.md                        # Bu dosya
```

---

## 🛠 Kullanılan Teknolojiler

### Frontend
| Teknoloji | Versiyon | Açıklama |
|-----------|----------|----------|
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) | 3.9.2 | UI Framework |
| ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) | 3.9.2 | Programlama Dili |
| ![Material](https://img.shields.io/badge/Material_Design-757575?style=flat&logo=material-design&logoColor=white) | 3.0 | Tasarım Sistemi |

### Paketler
| Paket | Açıklama |
|-------|----------|
| `google_generative_ai` | Gemini AI entegrasyonu |
| `http` | HTTP istekleri |
| `dio` | Gelişmiş HTTP client |
| `file_picker` | Dosya seçme |
| `flutter_secure_storage` | Güvenli veri saklama |
| `animated_text_kit` | Animasyonlu yazılar |
| `cupertino_icons` | iOS tarzı ikonlar |

### Backend (Ayrı Repo)
| Teknoloji | Açıklama |
|-----------|----------|
| ASP.NET Core 8.0 | Web API |
| Entity Framework Core | ORM |
| SQLite | Veritabanı |
| JWT | Kimlik doğrulama |

---

## 🔌 Backend API

Uygulama aşağıdaki API endpoint'lerini kullanır:

### Kimlik Doğrulama
```
POST   /api/auth/login          # Giriş
POST   /api/auth/register       # Kayıt
GET    /api/auth/user/{email}   # Kullanıcı bilgisi
```

### Hasta İşlemleri
```
GET    /api/PatientProfile/{id}         # Profil getir
POST   /api/PatientProfile              # Profil kaydet
GET    /api/PatientProfile/doctors      # Doktor listesi
GET    /api/PatientProfile/{id}/tests   # Tahlil sonuçları
```

### Randevu İşlemleri
```
GET    /api/Appointment/patient/{id}    # Hasta randevuları
GET    /api/Appointment/doctor/{id}     # Doktor randevuları
POST   /api/Appointment                 # Randevu oluştur
PUT    /api/Appointment/{id}/status     # Durum güncelle
```

### Mesajlaşma
```
GET    /api/Message/conversation/{id1}/{id2}  # Mesajları getir
POST   /api/Message                           # Mesaj gönder
```

### Tahlil Sonuçları
```
GET    /api/TestResult/patient/{id}     # Hasta tahlilleri
POST   /api/TestResult                  # Tahlil ekle
```

---

## 🤝 Katkıda Bulunma

Katkılarınızı memnuniyetle karşılıyoruz! 


---

## 📞 İletişim

<div align="center">

**Geliştirici:** Hevin Ateş

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/hevinates)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/hevinates)

</div>

---

<div align="center">

### ⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

**Made with ❤️ and Flutter**

</div>
