# Analiza sieci influencerskich PJM na Instagramie (Projekt R Shiny)

### 🎯 Cel projektu
Celem projektu było stworzenie interaktywnego narzędzia do analizy tematyki i zaangażowania (Engagement Rate) na profilach związanych z Polskim Językiem Migowym (PJM). Projekt jest prototypem narzędzia do pracy magisterskiej.

### 📊 O danych
Ze względu na ograniczenia API Instagrama (brak dostępu publicznego), w projekcie wykorzystano **zbiór danych syntetycznych (symulowanych)**. 
- Struktura danych odwzorowuje prawdziwe profile (np. Migam, Iwona Cichosz, PZG).
- Dane zawierają: daty postów (2020-2026), treść, hashtagi oraz statystyki lajków i komentarzy.
- Algorytm generatora uwzględnia specyfikę kont (np. treści o COVID w latach 2020-2021).

### 🛠️ Technologie
- **Język:** R
- **Biblioteki:** Shiny, Tidyverse, DT, Bslib.
- **Wizualizacja:** ggplot2 (wykresy czasowe, korelacje, analiza hashtagów).

### 🚀 Jak uruchomić aplikację?
1. Pobierz pliki z tego repozytorium.
2. Otwórz plik `app.R` w RStudio.
3. Upewnij się, że plik `instagram_pjm_data.csv` jest w tym samym folderze.
4. Kliknij przycisk "Run App".
