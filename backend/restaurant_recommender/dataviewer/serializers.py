from rest_framework import serializers
from .models import Restaurant
import spacy
import ast

# Lade das spaCy-Modell (dies sollte einmalig erfolgen)
nlp = spacy.load("en_core_web_sm")

def clean_cuisine_string(raw_string):
    """
    Versucht, einen String wie "['Dutch', 'European', 'Vegetarian Friendly', 'Gluten Free Options']"
    als Liste zu interpretieren. Falls das gelingt, werden die Elemente per Komma getrennt zusammengefügt.
    Falls nicht, wird der String mit spaCy tokenisiert – wobei in diesem Fall mehr Token (und somit
    eine Aufspaltung) resultieren kann.
    """
    try:
        parsed = ast.literal_eval(raw_string)
        if isinstance(parsed, list):
            # Entferne eventuelle Leerzeichen und schließe leere Einträge aus
            cleaned = [str(item).strip() for item in parsed if str(item).strip()]
            return ", ".join(cleaned)
    except Exception:
        pass
    # Fallback: spaCy-Variante (kann Phrasen auftrennen)
    doc = nlp(raw_string)
    tokens = [token.text for token in doc if token.is_alpha]
    return ", ".join(tokens)

class RestaurantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Restaurant
        fields = '__all__'
    
    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if 'cuisine_style' in rep and rep['cuisine_style']:
            rep['cuisine_style'] = clean_cuisine_string(rep['cuisine_style'])
        return rep
