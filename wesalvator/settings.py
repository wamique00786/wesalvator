from pathlib import Path
import os
from dotenv import load_dotenv
'''import firebase_admin
from firebase_admin import credentials

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FIREBASE_CONFIG_PATH = os.path.join(BASE_DIR, "firebase_config.json")

# Initialize Firebase
if os.path.exists(FIREBASE_CONFIG_PATH):
    cred = credentials.Certificate(FIREBASE_CONFIG_PATH)
    firebase_admin.initialize_app(cred)
else:
    raise FileNotFoundError(f"Firebase config file not found: {FIREBASE_CONFIG_PATH}")'''

# Load environment variables from .env file
load_dotenv()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv("SECRET_KEY")

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['wesalvator.com', 'www.wesalvator.com', '127.0.0.1', 'localhost']

# Application definition
INSTALLED_APPS = [
    "channels",
    "daphne",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    'django.contrib.gis',
    'csp',
    'accounts',
    'rescue',
    'donation',
    'adoption',
    'subscription',
    'session_timeout',
    'base',
    'chatbot',
    'rest_framework',
    'rest_framework.authtoken',
    'django_otp',
    'django_otp.plugins.otp_email',
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    'csp.middleware.CSPMiddleware',
    'base.csp_middleware.ContentSecurityPolicyMiddleware',
    'session_timeout.middleware.SessionTimeoutMiddleware',
    'chatbot.middleware.ChatWidgetMiddleware',
    'django_otp.middleware.OTPMiddleware',
]

ROOT_URLCONF = "wesalvator.urls"

# Add these settings
LOGIN_URL = 'login'
LOGIN_REDIRECT_URL = 'dashboard'
LOGOUT_REDIRECT_URL = 'login'

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [os.path.join(BASE_DIR, 'templates')],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                'chatbot.context_processors.chat_widget_context',
                'rescue.context_processors.rescued_animals_count',
            ],
        },
    },
]

# WSGI_APPLICATION = "wesalvator.wsgi.application"
ASGI_APPLICATION = "wesalvator.asgi.application"

# Redis for Channels Layer (ensure Redis is running)
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",  # Fix import
        "CONFIG": {
            "hosts": [("144.24.122.171", 6379)],
        },
    },
}

# Database
DATABASES = {
    'default': {  # PostgreSQL with PostGIS (for GIS data)
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.getenv("DATABASE_NAME"),
        'USER': os.getenv("DATABASE_USER"),
        'PASSWORD': os.getenv("DATABASE_PASSWORD"),
        'HOST': os.getenv("DATABASE_HOST"),
        'PORT': os.getenv("DATABASE_PORT")
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'static'),  # This is where your static files should be located
]
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')  # This is where collectstatic will gather files

# Default primary key field type
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Add media settings
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Firebase configuration
'''FIREBASE_CONFIG = {
    "apiKey": os.getenv("FIREBASE_API_KEY"),
    "authDomain": os.getenv("FIREBASE_AUTH_DOMAIN"),
    "projectId": os.getenv("FIREBASE_PROJECT_ID"),
    "storageBucket": os.getenv("FIREBASE_STORAGE_BUCKET"),
    "messagingSenderId": os.getenv("FIREBASE_MESSAGING_SENDER_ID"),
    "appId": os.getenv("FIREBASE_APP_ID"),
}'''

# Email configuration
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_USE_SSL = False
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")

#GDAL_LIBRARY_PATH = r"C:\OSGeo4W\bin\gdal309.dll"  # Verify this path
#GDAL_LIBRARY_PATH = "/usr/lib/libgdal.so"
GDAL_LIBRARY_PATH = "/usr/lib/aarch64-linux-gnu/libgdal.so"

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

CSRF_COOKIE_SECURE = True  # for HTTPS sites
CSRF_COOKIE_HTTPONLY = False  # Allow JavaScript to access the CSRF token

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
        },
    },
}

CSRF_TRUSTED_ORIGINS = [
       'https://c26f-2409-40e3-305b-b7df-2dfe-4170-2f7d-a4a9.ngrok-free.app',
       'https://wesalvator.com',
       'https://www.wesalvator.com',# Add any other trusted origins here
   ]

SESSION_COOKIE_AGE = 300  # 5 minutes in seconds
SESSION_SAVE_EVERY_REQUEST = True  # Reset the session expiry time on every request
