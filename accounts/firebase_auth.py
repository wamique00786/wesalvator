'''import firebase_admin
from firebase_admin import auth

def verify_firebase_token(id_token):
    """
    Verify Firebase ID token and return user info.
    """
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        return None'''
