import csv
import json
import os
import sys
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.hashers import make_password, check_password

# Erhöhe das Limit für CSV-Felder
try:
    max_int = sys.maxsize
    csv.field_size_limit(max_int)
except OverflowError:
    max_int = 2147483647
    csv.field_size_limit(max_int)

# Pfade definieren
CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'users.csv')
POSTS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'posts', 'posts.csv')
# Verwende für Friends den gleichen Pfad, wie in friends/views.py (z. B. "friends.csv")
FRIENDS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'friends', 'friends.csv')
# groups.csv liegt im recommender-Ordner
GROUPS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'recommender', 'groups.csv')

def initialize_csv():
    """Erstellt die users.csv inklusive Header, falls sie noch nicht existiert."""
    if not os.path.exists(CSV_PATH):
        with open(CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['username', 'password_hash', 'account_type', 'profile_picture', 'favorite_cuisines', 'dietary_preferences'])

initialize_csv()

@csrf_exempt
def register(request):
    """
    Registrierung: Erwartet einen POST-Request mit JSON-Daten:
    {
      "username": "<dein username>",
      "password": "<dein password>",
      "account_type": "user" oder "company"
    }
    """
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            username = data.get('username')
            password = data.get('password')
            account_type = data.get('account_type')
        except (json.JSONDecodeError, KeyError):
            return JsonResponse({'success': False, 'message': 'Ungültige Daten'}, status=400)

        if not username or not password or not account_type:
            return JsonResponse({'success': False, 'message': 'Es fehlen erforderliche Felder'}, status=400)

        # Prüfe, ob der Username bereits existiert
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    return JsonResponse({'success': False, 'message': 'Username existiert bereits'}, status=400)

        password_hash = make_password(password)
        with open(CSV_PATH, 'a', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([username, password_hash, account_type, "", "", ""]) # Hier wurde "" hinzugefügt
        return JsonResponse({'success': True, 'message': 'Registrierung erfolgreich'})
    return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)


@csrf_exempt
def login_view(request):
    """
    Login: Erwartet einen POST-Request mit JSON-Daten:
    {
      "username": "<dein username>",
      "password": "<dein password>"
    }
    """
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            username = data.get('username')
            password = data.get('password')
        except (json.JSONDecodeError, KeyError):
            return JsonResponse({'success': False, 'message': 'Ungültige Daten'}, status=400)

        if not username or not password:
            return JsonResponse({'success': False, 'message': 'Username und Passwort sind erforderlich'}, status=400)

        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    if check_password(password, row['password_hash']):
                        response = JsonResponse({
                            'success': True,
                            'message': 'Login erfolgreich',
                            'account_type': row['account_type'],
                            'profile_picture': row.get('profile_picture', ""),
                            'favorite_cuisines': row.get('favorite_cuisines', ""),
                            'dietary_preferences': row.get('dietary_preferences', "")
                        })
                        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
                        return response
                    else:
                        return JsonResponse({'success': False, 'message': 'Username oder Passwort falsch'}, status=400)
        return JsonResponse({'success': False, 'message': 'Username oder Passwort falsch'}, status=400)
    return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)


@csrf_exempt
def update_profile(request):
    """
    Aktualisiert das Benutzerprofil und passt den Benutzernamen in users.csv, posts.csv,
    friends.csv und groups.csv an, falls er geändert wird.
    Erwartet einen POST-Request mit JSON-Daten:
    {
        "username": "<alter Benutzername>",
        "new_username": "<neuer Benutzername>" oder null,
        "new_password": "<neues Passwort>" oder null,
        "profile_picture": "<Base64 Bildstring>" oder leer,
        "favorite_cuisines": "<Kommaseparierte Liste der Lieblingsküchen>"
    }
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        old_username = data.get("username")
        new_username = data.get("new_username")
        new_password = data.get("new_password")
        profile_picture = data.get("profile_picture", "")
        favorite_cuisines = data.get("favorite_cuisines", "")
        dietary_preferences = data.get("dietary_preferences", "") # dietary_preferences hinzugefügt
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    
    if not old_username:
        return JsonResponse({'success': False, 'message': 'Alter Benutzername erforderlich'}, status=400)
    
    # Aktualisiere users.csv
    user_updated = False
    updated_users = []
    try:
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == old_username:
                    if new_username and new_username != old_username:
                        row['username'] = new_username
                    if new_password:
                        row['password_hash'] = make_password(new_password)
                    row['profile_picture'] = profile_picture
                    row['favorite_cuisines'] = favorite_cuisines
                    row['dietary_preferences'] = dietary_preferences # dietary_preferences hinzugefügt
                    user_updated = True
                updated_users.append(row)
        if not user_updated:
            return JsonResponse({'success': False, 'message': 'User not found in users.csv'}, status=404)
        with open(CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['username', 'password_hash', 'account_type', 'profile_picture', 'favorite_cuisines', 'dietary_preferences'] # dietary_preferences hinzugefügt
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for row in updated_users:
                writer.writerow(row)
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Aktualisieren der users.csv: ' + str(e)}, status=500)
    
    # Falls der Benutzername geändert wurde, aktualisiere auch posts.csv, friends.csv und groups.csv
    if new_username and new_username != old_username:
        # Update posts.csv
        try:
            posts = []
            with open(POSTS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    if row.get("username") == old_username:
                        row["username"] = new_username
                    posts.append(row)
            with open(POSTS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
                fieldnames = ['post_id', 'username', 'image_data', 'post_text', 'timestamp']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for row in posts:
                    writer.writerow(row)
        except Exception as e:
            return JsonResponse({'success': False, 'message': 'Fehler beim Aktualisieren der posts.csv: ' + str(e)}, status=500)
        
        # Update friends.csv
        try:
            friends = []
            with open(FRIENDS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    # Aktualisiere falls der alte Username als "username" oder in "friends" vorkommt
                    if row.get("username") == old_username:
                        row["username"] = new_username
                    if row.get("friends"):
                        friend_list = [f.strip() for f in row["friends"].split(",")]
                        friend_list = [new_username if f == old_username else f for f in friend_list]
                        row["friends"] = ",".join(friend_list)
                    friends.append(row)
            with open(FRIENDS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
                if friends:
                    fieldnames = friends[0].keys()
                else:
                    fieldnames = ['username', 'friends']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for row in friends:
                    writer.writerow(row)
        except Exception as e:
            return JsonResponse({'success': False, 'message': 'Fehler beim Aktualisieren der friends.csv: ' + str(e)}, status=500)
        
        # Update groups.csv – hier müssen wir "created_by" und "members" anpassen
        try:
            groups = []
            with open(GROUPS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    # Ersetze im Feld "created_by" den alten Username
                    if row.get("created_by") == old_username:
                        row["created_by"] = new_username
                    # Ersetze in "members" (kommagetrennte Liste) alle Vorkommen des alten Benutzernamens
                    if "members" in row and row["members"]:
                        members_list = [m.strip() for m in row["members"].split(",")]
                        updated_members = [new_username if m == old_username else m for m in members_list]
                        row["members"] = ",".join(updated_members)
                    groups.append(row)
            with open(GROUPS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
                fieldnames = ['group_id', 'group_name', 'created_by', 'members']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for row in groups:
                    writer.writerow(row)
        except Exception as e:
            return JsonResponse({'success': False, 'message': 'Fehler beim Aktualisieren der groups.csv: ' + str(e)}, status=500)
    
    response = JsonResponse({'success': True})
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    return response


@csrf_exempt
def update_favorites(request):
    """
    Aktualisiert die Lieblingsküchen.
    Erwartet einen POST-Request mit JSON:
    {
      "username": "bestehender Username",
      "favorite_cuisines": "Italienisch,Chinesisch,..."
    }
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
    except Exception:
        return JsonResponse({'success': False, 'message': 'Ungültige JSON-Daten'}, status=400)
    username = data.get('username')
    favorite_cuisines = data.get('favorite_cuisines', "")
    if not username:
        return JsonResponse({'success': False, 'message': 'Username erforderlich'}, status=400)
    
    updated = False
    rows = []
    try:
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    row['favorite_cuisines'] = favorite_cuisines
                    updated = True
                rows.append(row)
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Lesen der CSV: {str(e)}'}, status=500)
    if not updated:
        return JsonResponse({'success': False, 'message': 'User not found'}, status=404)
    headers = ['username', 'password_hash', 'account_type', 'profile_picture', 'favorite_cuisines']
    try:
        with open(CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            writer.writeheader()
            for row in rows:
                writer.writerow(row)
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Schreiben der CSV: {str(e)}'}, status=500)
    response = JsonResponse({'success': True, 'message': 'Favorite cuisines updated'})
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    return response



@csrf_exempt
def update_dietary_preferences(request):
    """
    Aktualisiert die diätetischen Präferenzen.
    Erwartet einen POST-Request mit JSON-Daten:
    {
        "username": "bestehender Username",
        "dietary_preferences": "Vegetarisch,Glutenfrei,..." 
    }
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
    except Exception:
        return JsonResponse({'success': False, 'message': 'Ungültige JSON-Daten'}, status=400)
    
    username = data.get('username')
    dietary_preferences = data.get('dietary_preferences', "")
    if not username:
        return JsonResponse({'success': False, 'message': 'Username erforderlich'}, status=400)
    
    updated = False
    rows = []
    try:
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    row['dietary_preferences'] = dietary_preferences
                    updated = True
                rows.append(row)
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Lesen der CSV: ' + str(e)}, status=500)
    
    if not updated:
        return JsonResponse({'success': False, 'message': 'User not found'}, status=404)
    
    headers = ['username', 'password_hash', 'account_type', 'profile_picture', 'favorite_cuisines', 'dietary_preferences']
    try:
        with open(CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            writer.writeheader()
            for row in rows:
                writer.writerow(row)
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Schreiben der CSV: ' + str(e)}, status=500)
    
    response = JsonResponse({
        'success': True,
        'message': 'Dietary preferences updated',
        'dietary_preferences': dietary_preferences
    })
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    return response



@csrf_exempt
def get_users(request):
    """
    Liefert alle User-Namen (account_type == 'user').
    """
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'Nur GET-Requests erlaubt'}, status=405)
    users = []
    try:
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row.get('account_type') == 'user':
                    users.append(row.get('username'))
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Lesen der CSV: {str(e)}'}, status=500)
    response = JsonResponse({'success': True, 'users': users})
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    return response





@csrf_exempt
def filter_by_dietary_preferences(request):
    """
    Filtert Benutzer nach diätetischen Präferenzen.
    Erwartet einen GET-Request mit Query-Parameter:
    /filter_by_dietary_preferences?preferences=vegetarian,vegan
    """
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'Nur GET-Requests erlaubt'}, status=405)
    
    preferences = request.GET.get('preferences', '').split(',')
    preferences = [p.strip().lower() for p in preferences if p.strip()]
    
    if not preferences:
        return JsonResponse({'success': False, 'message': 'Keine gültigen Präferenzen angegeben'}, status=400)

    matching_users = []
    
    try:
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                user_preferences = row.get('dietary_preferences', '').lower().split(',')
                user_preferences = [p.strip() for p in user_preferences if p.strip()]
                
                # Überprüfen, ob eine der angegebenen Präferenzen übereinstimmt
                if any(pref in user_preferences for pref in preferences):
                    matching_users.append({
                        'username': row['username'],
                        'profile_picture': row.get('profile_picture', ""),
                        'favorite_cuisines': row.get('favorite_cuisines', ""),
                        'dietary_preferences': row.get('dietary_preferences', "")
                    })
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Fehler beim Lesen der CSV: {str(e)}'}, status=500)
    
    return JsonResponse({'success': True, 'filtered_users': matching_users})



@csrf_exempt
def get_group_dietary_preferences(request):
    """
    Aggregiert die diätetischen Präferenzen aller übergebenen Mitglieder.
    Erwartet einen POST-Request mit JSON:
    {
        "members": ["user1", "user2", ...]
    }
    Liefert:
    {
        "success": true,
        "dietary_preferences": ["Vegetarian Friendly", "Gluten Free Options", ...]
    }
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        members = data.get('members', [])
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    
    if not members:
        return JsonResponse({'success': True, 'dietary_preferences': []})
    
    aggregated = set()
    try:
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                username = row.get('username', '')
                if username in members:
                    prefs = row.get('dietary_preferences', '')
                    if prefs:
                        for p in prefs.split(','):
                            aggregated.add(p.strip())
        aggregated_list = list(aggregated)
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Aggregieren: ' + str(e)}, status=500)
    
    return JsonResponse({'success': True, 'dietary_preferences': aggregated_list})
