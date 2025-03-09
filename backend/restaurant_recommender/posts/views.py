from django.shortcuts import render

# Create your views here.
import csv
import os
import base64
import datetime
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

# Definiere den Pfad zur posts.csv – diese Datei wird im gleichen Ordner wie diese views.py abgelegt.
POSTS_CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'posts.csv')

def initialize_posts_csv():
    """Erstellt die posts.csv inklusive Header, falls sie noch nicht existiert."""
    if not os.path.exists(POSTS_CSV_PATH):
        with open(POSTS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            # Felder: post_id, username, image_data, post_text, timestamp
            writer.writerow(['post_id', 'username', 'image_data', 'post_text', 'timestamp'])

initialize_posts_csv()

@csrf_exempt
def create_post(request):
    """
    Erlaubt es einem Nutzer/einem Unternehmen, einen Post zu erstellen.
    Erwartet einen POST-Request mit JSON:
    {
       "username": "<username>",
       "post_text": "<Text zum Post>",
       "image_data": "<Base64-kodierter Bildstring>"  // optional, kann leer sein
    }
    Der Post wird in der posts.csv gespeichert.
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username', '')
        post_text = data.get('post_text', '')
        image_data = data.get('image_data', '')  # Base64-kodierter String (falls vorhanden)
        timestamp = datetime.datetime.now().isoformat()
        
        # Erzeuge eine post_id: Lese die letzte post_id aus der CSV und erhöhe sie um 1
        post_id = 1
        try:
            with open(POSTS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                post_ids = [int(row['post_id']) for row in reader if row['post_id'].isdigit()]
                if post_ids:
                    post_id = max(post_ids) + 1
        except Exception:
            post_id = 1
        
        with open(POSTS_CSV_PATH, 'a', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([post_id, username, image_data, post_text, timestamp])
        
        return JsonResponse({'success': True, 'message': 'Post erstellt', 'post_id': post_id})
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Erstellen des Posts: ' + str(e)}, status=500)

def list_posts(request):
    """
    Gibt alle Posts zurück, sortiert nach Timestamp (neueste zuerst).
    Diese Funktion wird per GET-Request aufgerufen.
    """
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'Nur GET-Requests erlaubt'}, status=405)
    posts = []
    try:
        with open(POSTS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                posts.append(row)
        # Sortiere Posts nach Timestamp absteigend
        posts.sort(key=lambda x: x['timestamp'], reverse=True)
        return JsonResponse({'success': True, 'posts': posts})
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Laden der Posts: ' + str(e)}, status=500)
    


@csrf_exempt
def delete_post(request):
    """
    Löscht einen Post.
    Erwartet einen POST-Request mit JSON:
    {
        "post_id": <post_id>,
        "username": "<username>"
    }
    Es wird überprüft, ob der angefragte Benutzer (username) der Ersteller des Posts ist.
    """
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Nur POST-Requests erlaubt'}, status=405)
    try:
        data = json.loads(request.body)
        post_id = data.get('post_id')
        username = data.get('username')
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Ungültige Daten: ' + str(e)}, status=400)
    
    if not post_id or not username:
        return JsonResponse({'success': False, 'message': 'post_id und username sind erforderlich'}, status=400)
    
    posts = []
    post_found = False
    try:
        with open(POSTS_CSV_PATH, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                posts.append(row)
        new_posts = []
        for row in posts:
            if row['post_id'] == str(post_id):
                post_found = True
                # Überprüfe, ob der Post von diesem Benutzer erstellt wurde.
                if row.get('username') != username:
                    return JsonResponse({'success': False, 'message': 'Nur der Ersteller kann den Post löschen.'}, status=400)
                # Post wird hier nicht hinzugefügt (gelöscht)
                continue
            else:
                new_posts.append(row)
        if not post_found:
            return JsonResponse({'success': False, 'message': 'Post nicht gefunden.'}, status=404)
        # Schreibe die aktualisierte Posts-Liste in die CSV
        with open(POSTS_CSV_PATH, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['post_id', 'username', 'image_data', 'post_text', 'timestamp']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for row in new_posts:
                writer.writerow(row)
        return JsonResponse({'success': True, 'message': 'Post erfolgreich gelöscht'})
    except Exception as e:
        return JsonResponse({'success': False, 'message': 'Fehler beim Löschen des Posts: ' + str(e)}, status=500)
