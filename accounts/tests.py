from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status

class AccountsTest(APITestCase):
    def test_signup(self):
        _data = {
            "username": "test1",
            "email": "test@gmail.com",
            "mobile_number": "+919056342734",
            "password": "name1234",
            "password2": "name1234",  # Add password2 to match serializer
            "user_type": "ADMIN"
        }

        _response = self.client.post("/api/accounts/signup/", _data, format="json")
        print(_response.json())  
        
        self.assertEqual(_response.status_code, status.HTTP_201_CREATED)  # Expect 201 instead of 200
        self.assertTrue(_response.data['message'], "User created successfully.")
