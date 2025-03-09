from rest_framework import generics, filters
from rest_framework.pagination import PageNumberPagination
from .models import Restaurant
from .serializers import RestaurantSerializer


class RestaurantPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


class RestaurantList(generics.ListAPIView):
    queryset = Restaurant.objects.order_by('id')
    serializer_class = RestaurantSerializer
    pagination_class = RestaurantPagination
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'city', 'cuisine_style']  # Suchbare Felder


class RestaurantDetail(generics.RetrieveAPIView):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer
    lookup_field = 'pk'  # Primärschlüsselfeld



import spacy
nlp = spacy.load("en_core_web_sm")

def clean_cuisine_string_spacy(raw_string):
    # Erstelle ein spaCy-Dokument
    doc = nlp(raw_string)
    # Filtere Tokens: Behalte nur solche, die alphabetisch sind (ohne Klammern, Kommata etc.)
    tokens = [token.text for token in doc if token.is_alpha]
    # Verbinde die Tokens mit Komma und Leerzeichen
    return ", ".join(tokens)

# Beispiel:
raw = "['Durch','European','Asian']"
print(clean_cuisine_string_spacy(raw))
# Mögliche Ausgabe: Durch, European, Asian
