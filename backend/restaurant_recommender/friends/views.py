import csv
import json
import os
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

# Pfade – hier liegt die friends.csv im gleichen Ordner wie diese Datei
FRIENDS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'friends.csv')
USERS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'accounts', 'users.csv')

def initialize_friends_csv():
    """Erstellt die friends.csv inklusive Header, falls sie noch nicht existiert."""
    if not os.path.exists(FRIENDS_CSV_PATH):
        with open(FRIENDS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['username', 'friends'])

initialize_friends_csv()

@csrf_exempt
def get_friends(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username')
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    if not username:
        return JsonResponse({'success': False, 'message': 'username ist erforderlich'}, status=400)

    try:
        with open(FRIENDS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    friend_list = row['friends'].strip() != "" and [f.strip() for f in row['friends'].split(',')] or []
                    response = JsonResponse({'success': True, 'friends': friend_list})
                    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
                    return response
        response = JsonResponse({'success': True, 'friends': []})
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return response
    except FileNotFoundError:
        response = JsonResponse({'success': True, 'friends': []})
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return response
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Abrufen: ' + str(e)}, status=500)


@csrf_exempt
def add_friend(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username')  # Username extrahieren
        friend = data.get('friend')      # Friend extrahieren
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    if not username or not friend:
        return JsonResponse({'success': False, 'message': 'username und friend sind erforderlich'}, status=400)

    try:
        rows = []
        found = False
        with open(FRIENDS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                rows.append(row)
        for row in rows:
            if row['username'] == username:
                found = True
                friend_list = row['friends'].strip() != "" and [f.strip() for f in row['friends'].split(',')] or []
                if friend.lower() not in [f.lower() for f in friend_list]:
                    friend_list.append(friend)
                    row['friends'] = ",".join(friend_list)
                break
        if not found:
            rows.append({'username': username, 'friends': friend})
        with open(FRIENDS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['username', 'friends']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for row in rows:
                writer.writerow(row)

        updated_friend_list = []
        with open(FRIENDS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    updated_friend_list = [f.strip() for f in row['friends'].split(',') if f.strip()]
                    break
        response = JsonResponse({'success': True, 'message': 'Freund hinzugefügt', 'updated_friends': updated_friend_list})
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return response
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Hinzufügen: ' + str(e)}, status=500)


@csrf_exempt
def remove_friend(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username')  # Username extrahieren
        friend = data.get('friend')      # Friend extrahieren
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    if not username or not friend:
        return JsonResponse({'success': False, 'message': 'username und friend sind erforderlich'}, status=400)

    try:
        rows = []
        removed = False
        with open(FRIENDS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                rows.append(row)
        for row in rows:
            if row['username'] == username:
                friend_list = []
                if row['friends'].strip() != "":
                    friend_list = [f.strip() for f in row['friends'].split(',')]
                if friend.lower() in [f.lower() for f in friend_list]:
                    friend_list = [f for f in friend_list if f.lower() != friend.lower()]
                    row['friends'] = ",".join(friend_list)
                    removed = True
                break
        if not removed:
            return JsonResponse({'success': False, 'message': 'Freund nicht gefunden'}, status=404)
        with open(FRIENDS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['username', 'friends']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for row in rows:
                writer.writerow(row)

        updated_friend_list = []
        with open(FRIENDS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['username'] == username:
                    if row['friends'].strip() != "":
                        updated_friend_list = [f.strip() for f in row['friends'].split(',') if f.strip()]
                    break
        response = JsonResponse({'success': True, 'message': 'Freund entfernt', 'updated_friends': updated_friend_list})
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return response
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Entfernen: ' + str(e)}, status=500)
    

@csrf_exempt
def get_all_users(request):
    """
    Liefert alle Usernamen aus der User-CSV.
    Erwartet einen GET-Request.
    """
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'Nur GET-Requests erlaubt'}, status=405)
    try:
        users = []
        with open(USERS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if 'username' in row:
                    users.append(row['username'])
        response = JsonResponse({'success': True, 'users': users})
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return response
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Laden der User: ' + str(e)}, status=500)
