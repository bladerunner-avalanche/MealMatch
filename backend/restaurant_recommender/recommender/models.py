from django.db import models

class RestaurantData(models.Model):
    user_id = models.IntegerField()
    group_id = models.IntegerField()
    cuisine = models.CharField(max_length=50)
    rating = models.IntegerField()
    visit_count = models.IntegerField()
    allergy = models.CharField(max_length=50, null=True, blank=True)
    timestamp = models.DateTimeField()

    def __str__(self):
        return f"User {self.user_id} - {self.cuisine}"