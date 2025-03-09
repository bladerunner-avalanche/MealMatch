# ML Modell testen mit python evaluate_recommendations.py

import csv
import json
import os
import numpy as np
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, ndcg_score
from sklearn.preprocessing import label_binarize

# Pfade (an deine Projektstruktur anpassen)
GROUPS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'groups.csv')
ACCOUNTS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'accounts', 'users.csv')

# Einstellungen
CUISINES = ["italian", "chinese", "mexican", "indian", "japanese", "french", "mediterranean", "thai"]
NUM_CUISINES = len(CUISINES)
MAX_SEQ_LENGTH = 5
DEFAULT_RANK = MAX_SEQ_LENGTH + 1  # z.B. 6

def get_group_feature_and_truth(group):
    """
    Für eine gegebene Gruppe (aus der Gruppen-CSV):
      - Lese die Favoritenlisten der Mitglieder aus der Accounts-CSV.
      - Für jede Küche: Berechne den durchschnittlichen Rang (1-basiert) aus den Favoritenlisten.
        Wird eine Küche nicht genannt, setze DEFAULT_RANK.
      - Als Ground Truth definieren wir den Küchen-Typ mit dem niedrigsten (besten) Durchschnittsrang.
    Liefert:
      - feature_vector: Liste mit 8 Werten (float) für die 8 Küchen.
      - true_label: Der 0-basierte Index der Ground Truth Küche.
    """
    members = group['members'].split(",") if group['members'] else []
    cuisine_ranks = {cuisine: [] for cuisine in CUISINES}
    with open(ACCOUNTS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            username = row.get('username', '')
            if username in members:
                favs = row.get('favorite_cuisines', '')
                if favs:
                    fav_list = [x.strip().lower() for x in favs.split(',') if x.strip()]
                    for pos, cuisine in enumerate(fav_list, start=1):
                        if cuisine in CUISINES:
                            cuisine_ranks[cuisine].append(pos)
    feature_vector = []
    for cuisine in CUISINES:
        if cuisine_ranks[cuisine]:
            avg_rank = np.mean(cuisine_ranks[cuisine])
        else:
            avg_rank = DEFAULT_RANK
        feature_vector.append(avg_rank)
    # Ground truth: Küche mit minimalem Durchschnittsrang
    true_cuisine = CUISINES[np.argmin(feature_vector)]
    true_label = CUISINES.index(true_cuisine)  # 0-basierter Index
    return feature_vector, true_label

def load_all_groups():
    groups = []
    with open(GROUPS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            groups.append(row)
    return groups

def evaluate_model():
    groups = load_all_groups()
    y_true = []
    y_pred = []
    # Für NDCG: Wir sammeln pro Gruppe den Score-Vektor (als Liste) für alle 8 Küchen.
    ndcg_list = []
    
    # Hyperparameter für Aggregation im Empfehlungssystem:
    p = 2  # Exponent für Frequency-Gewichtung

    for group in groups:
        members = group['members'].split(",") if group['members'] else []
        if not members:
            continue  # Überspringe Gruppen ohne Mitglieder
        # Berechne feature_vector wie im Recommendation-Endpoint, aber ohne Bonus
        cuisine_ranks = {cuisine: [] for cuisine in CUISINES}
        with open(ACCOUNTS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                username = row.get('username', '')
                if username in members:
                    favs = row.get('favorite_cuisines', '')
                    if favs:
                        fav_list = [x.strip().lower() for x in favs.split(',') if x.strip()]
                        for pos, cuisine in enumerate(fav_list, start=1):
                            if cuisine in CUISINES:
                                cuisine_ranks[cuisine].append(pos)
        total_users = len(members)
        aggregated_scores = {}
        for cuisine in CUISINES:
            if cuisine_ranks[cuisine]:
                avg_rank = np.mean(cuisine_ranks[cuisine])
                freq = len(cuisine_ranks[cuisine])
                score = avg_rank * ((total_users / freq) ** p)
            else:
                score = DEFAULT_RANK
            aggregated_scores[cuisine] = score
        
        # Vorhersage des Modells: Wähle die Küche mit minimalem Score
        predicted_cuisine = min(aggregated_scores, key=aggregated_scores.get)
        pred_label = CUISINES.index(predicted_cuisine)
        # Ground truth: Die Küche mit minimalem Durchschnittsrang (ohne Frequency-Gewichtung)
        feature_vector, true_label = get_group_feature_and_truth(group)
        
        y_true.append(true_label)
        y_pred.append(pred_label)
        
        # Für NDCG: Erstelle einen Relevanz-Vektor für Ground Truth (One-Hot) und eine Score-Vektor (als Ranking)
        # Da Ground Truth ist ein einzelnes Label, erstellen wir einen One-Hot-Vektor der Länge NUM_CUISINES
        true_relevance = np.zeros((1, NUM_CUISINES))
        true_relevance[0, true_label] = 1
        # Für die Score-Vektor, invertiere die aggregierten Scores (niedriger = besser). Wir nehmen den Negativwert.
        score_vector = np.array([-aggregated_scores[cuisine] for cuisine in CUISINES]).reshape(1, -1)
        ndcg = ndcg_score(true_relevance, score_vector)
        ndcg_list.append(ndcg)
    
    # Berechne Klassifikationsmetriken
    from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
    accuracy = accuracy_score(y_true, y_pred)
    precision = precision_score(y_true, y_pred, average='macro')
    recall = recall_score(y_true, y_pred, average='macro')
    f1 = f1_score(y_true, y_pred, average='macro')
    avg_ndcg = np.mean(ndcg_list) if ndcg_list else 0

    print("Evaluation Metrics for Random Forest Recommendation Model on Groups CSV:")
    print("Accuracy: {:.4f}".format(accuracy))
    print("Precision: {:.4f}".format(precision))
    print("Recall: {:.4f}".format(recall))
    print("F1 Score: {:.4f}".format(f1))
    print("NDCG: {:.4f}".format(avg_ndcg))

if __name__ == "__main__":
    evaluate_model()
