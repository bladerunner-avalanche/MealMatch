from django.db import models

# Create your models here.
class Restaurant(models.Model):
    name = models.CharField(max_length=255)
    city = models.CharField(max_length=255)
    cuisine_style = models.TextField()  # Kann eine Liste von Stilen enthalten
    rating = models.FloatField(null=True, blank=True)
    price_range = models.CharField(max_length=20, blank=True)
    number_of_reviews = models.IntegerField(null=True, blank=True)
    reviews = models.TextField(blank=True) # Speichere die Reviews als JSON-String
    url_ta = models.URLField(blank=True)
    id_ta = models.CharField(max_length=50, blank=True)
    # ... weitere Felder

    def __str__(self):
        return self.name