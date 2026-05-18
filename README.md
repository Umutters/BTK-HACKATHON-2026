# ⏳ FortuneFlow AI - Finansal Oyunlaştırma & Zaman Makinesi Simülasyonu



FortuneFlow AI, geleneksel bütçe takip uygulamalarının ötesine geçerek davranışsal finansı oyunlaştırma prensipleri ve Açıklanabilir Yapay Zeka (XAI) ile birleştiren fütüristik bir finansal yönetim ve simülasyon platformudur. 

Uygulama, kullanıcılara sadece "geçmişte ne harcadıklarını" söylemez; anlık kararlarının, birikim alışkanlıklarının ve beklenmedik krizlerin **20 yıl sonraki (2046 yılındaki)** finansal durumlarını nasıl şekillendireceğini canlı olarak deneyimletir.

---

## 🎯 Vizyon ve Öne Çıkan Özellikler

### 1. ⏳ Zaman Makinesi Projeksiyonu (The Core Engine)
Kullanıcının `savings_pool` (Tasarruf Havuzu) verisini ve günlük harcama alışkanlıklarını baz alarak gelecekteki potansiyel varlığını hesaplayan interaktif bir simülasyon motorudur. `fl_chart` kütüphanesi ile iki rotayı canlı olarak karşılaştırır:
* **Mevcut Rota (Current Path):** Geçmiş harcama alışkanlıkları aynen devam ederse varılacak nokta.
* **Optimize Rota (Optimized Path):** İnteraktif slider'lar vasıtasıyla eklenen günlük tasarruflar ve Oracle önerileriyle ulaşılabilecek finansal zirve.

### 🤖 2. AI Oracle Chat & XAI Katmanı
Gemini Flash API (`google_generative_ai`) ile entegre çalışan, `systemInstruction` mimarisiyle güçlendirilmiş finansal kahin. Sadece ham verileri değil, finansal kararların arkasındaki psikolojik ve mantıksal nedenleri Açıklanabilir AI (XAI) prensipleriyle analiz eder, fütüristik metaforlarla kullanıcıya sunar.

### 🚨 3. Kullanıcı Girdili Kriz Olayları (Financial Shock Mechanism)
Gerçek hayatın dinamizmini simüle eden oyunlaştırma tabanlı kriz yönetim mekanizması:
* Kullanıcı anlık bir kriz girdiğinde (Örn: Araç arızası - 3000 TL), bakiye **anında düşer** ve sisteme bir finansal şok yansıtılır.
* Oracle otomatik olarak tetiklenerek chat ekranında bu krizin 2046 hedeflerine olan faturasını hesaplar (Typewriter etkisiyle).
* Kullanıcıya krizi çözmesi için dinamik aksiyon butonları sunulur: **[Tasarruf Havuzundan Karşıla]** veya **[Kemerleri Sık (Bütçeden Kes - Yüksek Gelişim Ödülü)]**.

### 🏦 4. Otomatik Tasarruf & Oyunlaştırma (Gamification)
* **Leftover-to-Savings:** Günlük harcama limitinin altında kalan her kuruş, gün sonunda otomatik olarak `savings_pool` hesabına aktarılır.
* **XP & Seviye Sistemi:** Finansal disiplin ve kriz anlarında gösterilen kararlılık, kullanıcıya XP (Deneyim Puanı) kazandırır ve `users` tablosundaki finansal olgunluk seviyesini artırır.

---

## 🛠️ Teknolojik Yığın (Tech Stack)

* **Frontend:** Flutter & Dart (Clean Architecture / MVVM pattern via `ChangeNotifier`)
* **Backend & Database:** Supabase (PostgreSQL, Realtime, Row Level Security)
* **AI Katmanı:** Gemini Flash API (`google_generative_ai`)
* **Grafik Motoru:** `fl_chart`
* **UI & Metin Zenginleştirme:** `flutter_markdown`

---


## 🗄️ Veri Tabanı Şeması (Supabase Mimarisi)

FortuneFlow AI, ilişkisel veri gücünü optimize etmek adına şu tablolar üzerinde yükselir:

| Tablo Adı | Birincil Görevi | Kritik Kolonlar |
| :--- | :--- | :--- |
| `users` | Kullanıcı profili, anlık bakiye ve oyunlaştırma verileri | `current_balance`, `savings_pool`, `level`, `xp` |
| `daily_logs` | Günlük harcama geçmişi ve otomatik tasarruf kilidi | `spent_amount`, `transferred_to_savings` |
| `recurring_transactions` | Aylık sabit gelir ve giderlerin projeksiyonu | `amount`, `category`, `is_income`, `is_expense` |
| `decisions_log` | Alınan Oracle tavsiyeleri ve kriz çözümlerinin günlüğü | `action_taken`, `xp_gained` |

---

## 🚀 Kurulum ve Başlangıç

### 1. Gereksinimler
* Flutter SDK (Son kararlı sürüm)
* Dart SDK
* Supabase Projesi ve Gemini API Key

### 2. Ortam Değişkenleri (`.env`)
Projenin çalışabilmesi için `lib/core/constants/app_env.dart` veya kök dizindeki `.env` dosyasında şu tanımlamaların yapılması gerekir:
```env
SUPABASE_URL=https://proje_id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
