# Restaurant & Group Recommendation App

Dieses Projekt ist eine plattformübergreifende App, die mit **Flutter** entwickelt und durch ein **Django-Backend** unterstützt wird. Ziel ist es, Nutzern personalisierte Restaurantempfehlungen basierend auf individuellen Vorlieben und gruppenspezifischen Präferenzen bereitzustellen. Zur Generierung der Empfehlungen kommt ein Random-Forest-Modell zum Einsatz, das auf synthetischen Daten trainiert wurde, um mit einem kleinen Datensatz hohe Genauigkeitswerte (ca. 90 %) zu erzielen.

---

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Funktionen](#funktionen)
- [Architektur](#architektur)
- [Verwendete Technologien](#verwendete-technologien)
- [Modell-Training und Bewertung](#modell-training-und-bewertung)
- [Setup & Installation](#setup--installation)
- [API-Endpunkte](#api-endpunkte)
- [Quellen](#quellen)
- [Lizenz](#lizenz)

---

## Überblick

Die App bietet eine komplette Lösung zur Verwaltung von Nutzerkonten, Gruppen und Restaurantdaten sowie zur Generierung personalisierter Empfehlungen. Nutzer können:
- Sich registrieren und anmelden.
- Gruppen erstellen, betreten, verlassen und löschen.
- Restaurantdaten in einem Dashboard filtern und anzeigen.
- Basierend auf den Vorlieben der Gruppenmitglieder (inkl. sonstiger Präferenzen) Restaurantempfehlungen abrufen.

---

## Funktionen

- **Nutzer-Authentifizierung:**  
  Registrierung und Login, mit Passwort-Hashing für erhöhte Sicherheit.
  
- **Gruppenverwaltung:**  
  Erstellung, Verwaltung und Löschen von Gruppen. Company-Konten haben keinen Zugriff auf Gruppenfunktionen.

- **Restaurant-Dashboard:**  
  Anzeigen von Restaurants aus einer CSV-Datei mit Filtermöglichkeiten (z. B. nach Standort).

- **Empfehlungssystem:**  
  - Generierung von Gruppenempfehlungen mithilfe eines Random-Forest-Modells, das auf synthetischen Gruppendaten trainiert wurde.
  - Berücksichtigung der aggregierten sonstige Präferenzen der Gruppenmitglieder.
  - Anzeige von bis zu 5 passenden Restaurants, die nach Empfehlung, sonstige Präferenzen und Standort gefiltert werden.

- **Datenverwaltung:**  
  Alle Daten (Nutzer, Gruppen, Restaurants, etc.) werden lokal in CSV-Dateien gespeichert, was den Entwicklungsaufwand gering hält und die direkte Bearbeitung ermöglicht.

---

## Architektur

- **Monolithisches Backend:**  
  Das gesamte Backend ist als eine einzige Django-Anwendung implementiert. Die verschiedenen Funktionsbereiche (Authentifizierung, Gruppenmanagement, Empfehlungssystem etc.) sind in separate Module (Apps) unterteilt, werden aber gemeinsam deployed.

- **Client-Server-Modell:**  
  Das Flutter-Frontend kommuniziert über REST-APIs mit dem Django-Backend. Die Trennung ermöglicht eine klare Aufgabenteilung zwischen Präsentation und Geschäftslogik.

- **Modularisierung:**  
  Obwohl das System monolithisch ist, sind die Funktionen in eigenständige Komponenten (z. B. Authentifizierung, Gruppen, Restaurants) unterteilt, was die Wartung und Weiterentwicklung vereinfacht.

- **Skalierung & Optimierung:**  
  - **Caching und Lastverteilung:** Mittels externen Caching-Lösungen (z. B. Redis) und Load Balancing lässt sich das System bei Bedarf horizontal skalieren.
  - **Optimierung der Datenzugriffe:** Durch gezielten Einsatz von CSV-Dateien für kleinere Datenmengen und spätere Migration in relationale Datenbanken oder NoSQL-Systeme.

---

## Verwendete Technologien

### Flutter
- **Plattformübergreifend:** Ein Codebase für iOS, Android, Web und Desktop.
- **Hohe Performance:** Dank eigener Rendering-Engine (Skia) und Hot Reload.
- **Reaktive UI:** Deklaratives Widget-Modell, das schnelle UI-Updates ermöglicht.

### Django
- **Batteries-Included:** Umfassende integrierte Funktionen für Authentifizierung, ORM, Admin-Interface etc.
- **Sicher und skalierbar:** Gut geeignet für monolithische Anwendungen, die sich später in Microservices aufteilen lassen.
- **Schnelle Entwicklung:** Schneller Prototypenbau und einfache Wartung dank klarer App-Struktur.

### Random Forest & Empfehlungssystem
- **Random Forest:** Ein robustes Ensemble-Lernverfahren, das auf synthetischen Daten trainiert wird, um Empfehlungen zu generieren.
- **Synthetische Daten:** Aufgrund des kleinen Datensatzes werden synthetische Trainingsdaten genutzt, was zu hohen Metriken (ca. 90 % Genauigkeit) führt.
- **Evaluationsmetriken:** Präzision, Recall, F1-Score, Accuracy und NDCG werden zur Bewertung des Modells herangezogen.

### Datenverarbeitung & Speicherung
- **CSV-Dateien:** Einfache, textbasierte Speicherung für schnelle Entwicklungszyklen und Prototyping.
- **Optionale Datenbankintegration:** Bei steigendem Datenvolumen können relationale Datenbanken eingesetzt werden, um bessere Performance und Skalierbarkeit zu erreichen.

---

## Modell-Training und Bewertung

Das Random-Forest-Modell wird mit synthetischen Daten trainiert, da der vorhandene Datensatz zu klein ist. Dadurch lassen sich verschiedene Szenarien simulieren, und das Modell erzielt bei diesem Datensatz eine Genauigkeit von ca. 90 %. Das Modell wird anhand folgender Metriken evaluiert:
- **Präzision:** Anteil der korrekten Empfehlungen.
- **Recall:** Fähigkeit, relevante Restaurants korrekt vorzuschlagen.
- **F1-Score:** Harmonic Mean von Präzision und Recall.
- **Accuracy:** Anteil der korrekten Vorhersagen.
- **NDCG:** Bewertet die Rankingqualität der Empfehlungen.

Das trainierte Modell wird im Backend integriert und über einen API-Endpunkt bereitgestellt.

---

## Setup & Installation

### Voraussetzungen
- **Python 3.x** und **Django**
- **Flutter SDK**
- Weitere Abhängigkeiten wie scikit-learn (für das Random-Forest-Modell) und CSV-Verarbeitungsbibliotheken

### Schritte

1. **Backend:**
   - Klone das Repository.
   - Erstelle ein virtuelles Python-Umfeld und installiere die Abhängigkeiten (z. B. `pip install -r requirements.txt`).
   - Starte den Django-Server mit `python manage.py runserver`.

2. **Frontend:**
   - Navigiere in den Flutter-Projektordner.
   - Führe `flutter pub get` aus, um alle Pakete zu installieren.
   - Starte die App mit `flutter run`.

---

## API-Endpunkte

Beispiele für wichtige Endpunkte:

- **`/api/register/`** – Registrierung eines neuen Nutzers  
- **`/api/login/`** – Login und Authentifizierung  
- **`/api/update_profile/`** – Aktualisierung des Nutzerprofils (aktualisiert users.csv, posts.csv, friends.csv, groups.csv)  
- **`/api/update_favorites/`** – Aktualisierung der Lieblingsküchen  
- **`/api/update_dietary_preferences/`** – Aktualisierung der sonstige Präferenzen  
- **`/api/get_group_dietary_preferences/`** – Aggregiert sonstige Präferenzen aller Gruppenmitglieder  
- **`/api/recommender/recommend/`** – Berechnet eine Empfehlung für eine Gruppe mittels Random Forest  
- **Weitere Endpunkte:** Für Gruppenverwaltung, Filterung etc.

---

## Quellen

- **Django Documentation:** [https://docs.djangoproject.com/](https://docs.djangoproject.com/)  
- **Flutter Documentation:** [https://flutter.dev/docs](https://flutter.dev/docs)  
- **Random Forest – Breiman, L. (2001):** *Random Forests*, Machine Learning, 45(1), 5–32. [Link](https://link.springer.com/article/10.1023/A:1010933404324)  
- **Empfehlungssysteme – Aggarwal, C. C. (2016):** *Recommender Systems: The Textbook*, Springer.  
- **Microservices vs. Monolithic Architecture – Martin Fowler:** [https://martinfowler.com/articles/microservices.html](https://martinfowler.com/articles/microservices.html)

---

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe die [LICENSE](LICENSE) Datei für weitere Details.
