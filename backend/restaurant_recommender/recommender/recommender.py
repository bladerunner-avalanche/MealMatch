import csv
import json
import os
import numpy as np
import pandas as pd
from math import log2
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, ndcg_score
from sklearn.preprocessing import label_binarize
from sklearn.metrics import ndcg_score

# Pfad zur Gruppen-CSV (innerhalb des recommender-Ordners)
GROUPS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'groups.csv')
# Pfad zur User-CSV (angenommen, sie liegt in ../accounts/users.csv)
ACCOUNTS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'accounts', 'users.csv')


# Mögliche Küchen (alle in Kleinbuchstaben)
CUISINES = ["italian", "chinese", "mexican", "indian", "japanese", "french", "mediterranean", "thai"]
NUM_CUISINES = len(CUISINES)

# Wir definieren einen maximalen Sequenz-Länge (Anzahl Positionen, die ein Nutzer angeben kann)
MAX_SEQ_LENGTH = 5
# Default-Wert, wenn eine Küche von keinem Nutzer genannt wurde
DEFAULT_RANK = MAX_SEQ_LENGTH + 1  # z.B. 6
p = 2  # Exponent für Frequency-Gewichtung




def initialize_groups_csv():
    """Erstellt die Gruppen-CSV inklusive Header, falls sie noch nicht existiert."""
    if not os.path.exists(GROUPS_CSV_PATH):
        with open(GROUPS_CSV_PATH, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['group_id', 'group_name', 'created_by', 'members'])

initialize_groups_csv()

@csrf_exempt
def create_group(request):
    """
    Erstellt eine neue Gruppe. Der Ersteller (created_by) wird automatisch als Mitglied hinzugefügt.
    Der eigene Name soll dabei nicht auswählbar sein.
    Erwartet einen POST-Request mit JSON:
    {
        "group_name": "Gruppenname",
        "created_by": "username",
        "members": ["user1", "user2", ...]  // Der eigene Name (created_by) darf hier nicht enthalten sein.
    }
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        group_name = data.get('group_name')
        created_by = data.get('created_by')
        members = data.get('members', [])
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    
    if not group_name or not created_by:
        return JsonResponse({'success': False, 'message': 'Gruppenname und Ersteller sind erforderlich.'}, status=400)
    
    # Entferne den eigenen Namen, falls er versehentlich in der Mitgliederliste enthalten ist,
    # da er automatisch hinzugefügt wird.
    members = [member for member in members if member != created_by]
    
    # Füge den Ersteller automatisch hinzu
    members.append(created_by)
    
    # Entferne Duplikate (beibehaltung der Reihenfolge)
    members = list(dict.fromkeys(members))
    
    # Erzeuge eine neue group_id (einfacher Auto-Inkrement-Ansatz)
    try:
        new_group_id = 1
        if os.path.exists(GROUPS_CSV_PATH):
            with open(GROUPS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                group_ids = [int(row['group_id']) for row in reader if row['group_id'].isdigit()]
                if group_ids:
                    new_group_id = max(group_ids) + 1
        else:
            # Falls die Datei nicht existiert, wird sie neu erstellt.
            with open(GROUPS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(['group_id', 'group_name', 'created_by', 'members'])
        
        with open(GROUPS_CSV_PATH, 'a', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            # Speichere die Mitglieder als kommagetrennte Zeichenkette
            writer.writerow([new_group_id, group_name, created_by, ",".join(members)])
        
        return JsonResponse({'success': True, 'message': 'Gruppe erstellt', 'group_id': new_group_id})
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Erstellen der Gruppe: ' + str(e)}, status=500)
    



@csrf_exempt
def list_groups(request):
    """
    Gibt alle Gruppen zurück, in denen ein gegebener Nutzer Mitglied ist.
    Erwartet einen POST-Request mit JSON:
    {
      "username": "username"
    }
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username')
    except Exception:
        return JsonResponse({'success': False, 'message': 'Ungültige JSON-Daten'}, status=400)
    if not username:
        return JsonResponse({'success': False, 'message': 'Username erforderlich'}, status=400)
    
    groups = []
    try:
        with open(GROUPS_CSV_PATH, 'r', newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                members = row['members'].split(",") if row['members'] else []
                if username in members:
                    groups.append(row)
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Lesen der Gruppen: {str(e)}'}, status=500)
    
    return JsonResponse({'success': True, 'groups': groups})


@csrf_exempt
def leave_group(request):
    """
    Ermöglicht es einem Nutzer, eine Gruppe zu verlassen.
    Erwartet einen POST-Request mit JSON:
    {
       "group_id": <group_id>,
       "username": "<username>"  // Der Nutzer, der die Gruppe verlassen möchte.
    }
    Hinweis: Der Ersteller (created_by) kann über diesen Endpoint die Gruppe verlassen, 
    was sie – wenn er der letzte ist – automatisch löscht.
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        group_id = data.get('group_id')
        username = data.get('username')
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    
    if not group_id or not username:
        return JsonResponse({'success': False, 'message': 'group_id und username sind erforderlich'}, status=400)
    
    groups = []
    group_found = False
    try:
        with open(GROUPS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                groups.append(row)
        # Suche nach der Gruppe und entferne den Nutzer aus der Mitgliederliste.
        for row in groups:
            if row['group_id'] == str(group_id):
                group_found = True
                members_list = [m.strip() for m in row['members'].split(',') if m.strip()]
                if username not in members_list:
                    return JsonResponse({'success': False, 'message': 'Nutzer nicht in der Gruppe gefunden'}, status=400)
                # Entferne den Nutzer (egal ob Ersteller oder nicht)
                members_list.remove(username)
                row['members'] = ",".join(members_list)
                break
        if not group_found:
            return JsonResponse({'success': False, 'message': 'Gruppe nicht gefunden'}, status=404)
        
        # Automatisches Löschen: Wenn nach dem Entfernen kein Mitglied mehr in der Gruppe ist, lösche die Gruppe.
        new_groups = []
        group_deleted = False
        for row in groups:
            if row['group_id'] == str(group_id):
                if not row['members'].strip():
                    group_deleted = True
                    continue  # Gruppe nicht hinzufügen, da sie gelöscht wird.
                else:
                    new_groups.append(row)
            else:
                new_groups.append(row)
        
        with open(GROUPS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['group_id', 'group_name', 'created_by', 'members']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for row in new_groups:
                writer.writerow(row)
        
        if group_deleted:
            return JsonResponse({'success': True, 'message': 'Gruppe wurde gelöscht, da kein Mitglied mehr vorhanden ist'})
        else:
            return JsonResponse({'success': True, 'message': 'Gruppe erfolgreich verlassen'})
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Aktualisieren der Gruppe: ' + str(e)}, status=500)

@csrf_exempt
def delete_group(request):
    """
    Ermöglicht es einem Nutzer, eine Gruppe zu löschen.
    Erwartet einen POST-Request mit JSON:
    {
       "group_id": <group_id>,
       "username": "<username>"  // Der Ersteller muss diesen Wert haben.
    }
    Nur der Ersteller kann die Gruppe löschen.
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        group_id = data.get('group_id')
        username = data.get('username')
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    
    if not group_id or not username:
        return JsonResponse({'success': False, 'message': 'group_id und username sind erforderlich'}, status=400)
    
    groups = []
    group_found = False
    try:
        with open(GROUPS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                groups.append(row)
        new_groups = []
        for row in groups:
            if row['group_id'] == str(group_id):
                group_found = True
                if row['created_by'] != username:
                    return JsonResponse({'success': False, 'message': 'Nur der Ersteller kann die Gruppe löschen.'}, status=400)
                # Diese Gruppe wird gelöscht (nicht in new_groups aufgenommen)
                continue
            else:
                new_groups.append(row)
        if not group_found:
            return JsonResponse({'success': False, 'message': 'Gruppe nicht gefunden'}, status=404)
        
        with open(GROUPS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['group_id', 'group_name', 'created_by', 'members']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for row in new_groups:
                writer.writerow(row)
        return JsonResponse({'success': True, 'message': 'Gruppe erfolgreich gelöscht'})
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Löschen der Gruppe: ' + str(e)}, status=500)

###################################################################################  ML Modell  ############################################################################################################

##############################################
# Synthetische Gruppendaten generieren und RF Modell trainieren
##############################################

def generate_synthetic_group_data_weighted(num_groups=1000, random_state=42, p=2):
    """
    Generiere synthetische Gruppendaten, die denselben Feature-Transformationsprozess verwenden wie im Endpunkt.
    Für jede Gruppe:
      - Simuliere 2 bis 5 Nutzer, denen zufällig eine geordnete Favoritenliste von Küchen zugewiesen wird.
      - Für jede Küche wird der Durchschnitt der Rangpositionen berechnet (1-basierend); falls nicht genannt, DEFAULT_RANK.
      - Der gewichtete Score für eine Küche wird berechnet als:
            score = avg_rank * ((total_users / frequency) ** p)
        (Falls frequency=0, wird DEFAULT_RANK genutzt.)
      - Das Label ist der Index (0-basiert) der Küche mit dem minimalen Score.
    """
    np.random.seed(random_state)
    X = []  # Feature-Vektoren (8-dimensional)
    y = []  # Labels (0 bis NUM_CUISINES-1)
    for _ in range(num_groups):
        num_users = np.random.randint(2, 6)
        group_favorites = []
        for _ in range(num_users):
            seq_len = np.random.randint(1, MAX_SEQ_LENGTH + 1)
            favorites = np.random.choice(CUISINES, size=seq_len, replace=False).tolist()
            group_favorites.append(favorites)
        # Aggregiere Favoriten: Für jede Küche sammle alle Rangpositionen (1-basierend)
        cuisine_ranks = {cuisine: [] for cuisine in CUISINES}
        for fav_list in group_favorites:
            for pos, cuisine in enumerate(fav_list, start=1):
                cuisine_ranks[cuisine].append(pos)
        feature_vector = []
        for cuisine in CUISINES:
            if cuisine_ranks[cuisine]:
                avg_rank = np.mean(cuisine_ranks[cuisine])
                freq = len(cuisine_ranks[cuisine])
                score = avg_rank * ((num_users / freq) ** p)
            else:
                score = DEFAULT_RANK
            feature_vector.append(score)
        X.append(feature_vector)
        best_cuisine = CUISINES[np.argmin(feature_vector)]
        label = CUISINES.index(best_cuisine)
        y.append(label)
    return np.array(X), np.array(y)

# Generiere synthetische Trainingsdaten
X_synth, y_synth = generate_synthetic_group_data_weighted(num_groups=1000, p=p)

# Aufteilen in Training und Test (optional)
from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X_synth, y_synth, test_size=0.2, random_state=42)

# Trainiere den Random Forest
rf_model = RandomForestClassifier(n_estimators=100, random_state=42)
rf_model.fit(X_train, y_train)

# Optionale Evaluation auf dem Testset
y_pred = rf_model.predict(X_test)
acc = accuracy_score(y_test, y_pred)
prec = precision_score(y_test, y_pred, average='macro')
rec = recall_score(y_test, y_pred, average='macro')
f1 = f1_score(y_test, y_pred, average='macro')
# Für NDCG: Binarisiere Labels
from sklearn.preprocessing import label_binarize
y_test_bin = label_binarize(y_test, classes=range(NUM_CUISINES))
ndcg = ndcg_score(y_test_bin, rf_model.predict_proba(X_test))
print("Trained Random Forest Model on Synthetic Group Data")
print("Accuracy: {:.4f}".format(acc))
print("Precision: {:.4f}".format(prec))
print("Recall: {:.4f}".format(rec))
print("F1 Score: {:.4f}".format(f1))
print("NDCG: {:.4f}".format(ndcg))

##############################################
# Recommendation Endpoint mit Random Forest
##############################################

@csrf_exempt
def recommend_for_group(request):
    """
    Empfehlung für eine Gruppe mithilfe eines Random Forest basierten Recommendation-ML-Modells.
    
    Vorgehen:
      1. Lade die Gruppe anhand der group_id aus der Gruppen-CSV.
      2. Für jedes Gruppenmitglied: Lese die Favoritenliste (als kommaseparierte Liste) aus der Accounts-CSV.
      3. Für jede Küche in CUISINES: Berechne den durchschnittlichen Rang (1-basierend) aus den Favoritenlisten der Gruppenmitglieder.
         Falls eine Küche nicht genannt wurde, verwende DEFAULT_RANK.
         Wende dieselbe Frequency-Gewichtung an wie im Training:
             score = (avg_rank) * ((total_users / frequency) ** p)
         Falls frequency = 0, setze score = DEFAULT_RANK.
      4. Der resultierende 8-dimensionale Feature-Vektor wird an das Random Forest Modell übergeben,
         das ein Label (0-basiert) vorhersagt.
      5. Dieses Label wird in den entsprechenden Küchen-Namen umgewandelt und als Empfehlung zurückgegeben.
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        group_id = data.get('group_id')
    except Exception:
        return JsonResponse({'success': False, 'message': 'Ungültige JSON-Daten'}, status=400)
    if not group_id:
        return JsonResponse({'success': False, 'message': 'group_id erforderlich'}, status=400)
    
    # Gruppe laden
    group = None
    try:
        with open(GROUPS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['group_id'] == str(group_id):
                    group = row
                    break
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Lesen der Gruppen: {str(e)}'}, status=500)
    if group is None:
        return JsonResponse({'success': False, 'message': 'Gruppe nicht gefunden'}, status=404)
    
    members = group['members'].split(",") if group['members'] else []
    if not members:
        return JsonResponse({'success': False, 'message': 'Keine Mitglieder in der Gruppe'}, status=400)
    
    # Aggregiere Favoriten-Ränge aus den Accounts der Gruppenmitglieder
    cuisine_ranks = {cuisine: [] for cuisine in CUISINES}
    try:
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
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Lesen der Nutzerdaten: {str(e)}'}, status=500)
    
    total_users = len(members)  # Wird hier nicht mehr genutzt
    feature_vector = []
    for cuisine in CUISINES:
        if cuisine_ranks[cuisine]:
            avg_rank = np.mean(cuisine_ranks[cuisine])
            freq = len(cuisine_ranks[cuisine])
            # Neuer Score: Je höher die Frequency, desto niedriger der Score.
            score = avg_rank / (freq ** p)
        else:
            score = DEFAULT_RANK
        feature_vector.append(score)
    feature_vector = np.array(feature_vector).reshape(1, -1)
    
    # Vorhersage mit dem trainierten Random Forest Modell
    predicted_label = int(rf_model.predict(feature_vector)[0])
    recommended_cuisine = CUISINES[predicted_label]
    
    # Debug-Ausgabe im Terminal
    print("Empfehlung für Group ID {}:".format(group_id))
    print("Aggregierte Favoriten-Ränge pro Küche:")
    for cuisine in CUISINES:
        avg = np.mean(cuisine_ranks[cuisine]) if cuisine_ranks[cuisine] else DEFAULT_RANK
        freq = len(cuisine_ranks[cuisine])
        print("  {}: avg rank {:.1f} (frequency: {})".format(cuisine, avg, freq))
    print("Feature Vector:", feature_vector)
    print("Empfohlene Küche:", recommended_cuisine)


    #############################################
    # Vorhersagen auf den Testdaten
    y_pred = rf_model.predict(X_test)

    # Berechnung der Metriken
    acc = accuracy_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred, average='weighted', zero_division=0)
    rec = recall_score(y_test, y_pred, average='weighted', zero_division=0)
    f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)

    # NDCG berechnen (Label-Binarisierung für Ranking erforderlich)
    y_test_bin = label_binarize(y_test, classes=range(len(CUISINES)))
    y_pred_bin = label_binarize(y_pred, classes=range(len(CUISINES)))
    ndcg = ndcg_score(y_test_bin, y_pred_bin)

    # Ausgabe der Metriken
    print("Tested Random Forest Model on Synthetic Group Data")
    print("Accuracy: {:.4f}".format(acc))
    print("Precision: {:.4f}".format(prec))
    print("Recall: {:.4f}".format(rec))
    print("F1 Score: {:.4f}".format(f1))
    print("NDCG: {:.4f}".format(ndcg))
#####################################################
    
    return JsonResponse({'success': True, 'recommended_cuisine': recommended_cuisine})