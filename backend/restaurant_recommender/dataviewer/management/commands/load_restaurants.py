import pandas as pd
import numpy as np
from django.core.management.base import BaseCommand
from dataviewer.models import Restaurant

class Command(BaseCommand):
    help = 'Lädt Restaurantdaten aus der CSV-Datei in die Datenbank'

    def handle(self, *args, **options):
        file_path = r'C:\Users\uhumb\Desktop\MM0\data\kaggle_data.csv'
        try:
            df = pd.read_csv(file_path)

            df.replace([np.inf, -np.inf], np.nan, inplace=True)
            #df.fillna('', inplace=True) # Entfernt, da wir None verwenden
            #df = df.astype(str) # Entfernt

            for _, row in df.iterrows():
                try:
                    num_reviews_str = row['Number of Reviews']
                    num_reviews = None

                    if pd.notna(num_reviews_str) and num_reviews_str != '': # Korrekte NaN-Prüfung
                        try:
                            num_reviews = int(float(num_reviews_str))
                        except ValueError:
                            self.stdout.write(self.style.ERROR(f'Ungültiger Wert für Number of Reviews: {num_reviews_str} für Restaurant {row["Name"]}'))
                            continue # Überspringe dieses Restaurant

                    rating_str = row['Rating']
                    rating = None
                    if pd.notna(rating_str) and rating_str != '':
                        try:
                            rating = float(rating_str)
                        except ValueError:
                            self.stdout.write(self.style.ERROR(f'Ungültiger Wert für Rating: {rating_str} für Restaurant {row["Name"]}'))
                            continue

                    Restaurant.objects.create(
                        name=row['Name'],
                        city=row['City'],
                        cuisine_style=row['Cuisine Style'],
                        rating=rating,
                        price_range=row['Price Range'],
                        number_of_reviews=num_reviews,
                        reviews=row['Reviews'],
                        url_ta=row['URL_TA'],
                        id_ta=row['ID_TA'],
                    )
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'Fehler beim Importieren von Restaurant {row["Name"]}: {e}'))

            self.stdout.write(self.style.SUCCESS('Restaurantdaten erfolgreich geladen.'))

        except FileNotFoundError:
            self.stdout.write(self.style.ERROR(f'Datei nicht gefunden: {file_path}'))
        except pd.errors.ParserError as e:
            self.stdout.write(self.style.ERROR(f'Fehler beim Parsen der CSV-Datei: {e}'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Unerwarteter Fehler: {e}'))