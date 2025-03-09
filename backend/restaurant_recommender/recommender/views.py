from django.shortcuts import render
import pandas as pd
from rest_framework.decorators import api_view
from rest_framework.response import Response
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics.pairwise import cosine_similarity

@api_view(['GET'])
def recommend_restaurant(request, group_id):
    # Passe den Pfad zur restaurant_data.csv an deine Umgebung an
    df = pd.read_csv('~/Desktop/MM/data/restaurant_data.csv')
    df = df[df['group_id'] == group_id]

    # Datenvorverarbeitung
    le_cuisine = LabelEncoder()
    df['cuisine_encoded'] = le_cuisine.fit_transform(df['cuisine'])
    user_profiles = df.groupby('user_id').agg({'cuisine_encoded': list, 'rating': 'mean'}).reset_index()

    # Ähnlichkeit berechnen
    def calculate_similarity(profile):
        cuisine_vector = [0] * len(le_cuisine.classes_)
        for cuisine in profile['cuisine_encoded']:
            cuisine_vector[cuisine] = 1
        return cuisine_vector

    user_profiles['cuisine_vector'] = user_profiles.apply(calculate_similarity, axis=1)
    user_vectors = list(user_profiles['cuisine_vector'])
    similarity_matrix = cosine_similarity(user_vectors)

    # Beste Wahl für die Gruppe ermitteln (ein einfaches Beispiel)
    avg_cuisine_vector = [sum(x) / len(x) for x in zip(*user_vectors)]
    best_cuisine_index = avg_cuisine_vector.index(max(avg_cuisine_vector))
    best_cuisine = le_cuisine.inverse_transform([best_cuisine_index])[0]

    return Response({'recommended_cuisine': best_cuisine})
