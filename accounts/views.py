from django.contrib.auth.models import User
from django.contrib.auth.tokens import default_token_generator
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.core.mail import send_mail
from django.conf import settings
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.template.loader import render_to_string
from django.shortcuts import render, redirect
from django.views.decorators.csrf import csrf_exempt
from .models import UserProfile
from .forms import SignUpForm, PasswordResetForm
import random
from django.http import JsonResponse
#from .firebase_auth import verify_firebase_token

def get_admins(request):
    if request.method == 'GET':
        admins = User.objects.filter(userprofile__user_type='ADMIN').values('id', 'username')
        return JsonResponse({'admins': list(admins)})

def signup(request):
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            # Create user but don't save to database yet
            user = form.save()
            user.save()  # Now save the user

            # Update the UserProfile that was automatically created by the signal
            user_type = form.cleaned_data.get('user_type')
            try:
                user_profile = UserProfile.objects.get(user=user)
                user_profile.user_type = user_type
                user_profile.save()
            except UserProfile.DoesNotExist:
                UserProfile.objects.create(user=user, user_type=user_type)

            messages.success(request, 'Account created successfully. Please login.')
            return redirect('login')
    else:
        form = SignUpForm()
    return render(request, 'registration/signup.html', {'form': form})

'''@csrf_exempt
def verify_firebase_token_view(request):
    if request.method == 'POST':
        id_token = request.POST.get('id_token')
        decoded_token = verify_firebase_token(id_token)
        if decoded_token:
            # Get user info from decoded_token
            uid = decoded_token['uid']
            # Link the verified phone number to the user account
            # You can create or update the user profile here
            return JsonResponse({'status': 'success', 'uid': uid})
        else:
            return JsonResponse({'status': 'error', 'message': 'Invalid token'}, status=400)'''

def custom_login(request):
    if request.user.is_authenticated:
        profile = UserProfile.objects.get(user=request.user)
        print(profile.user_type)
        if profile.user_type == 'VOLUNTEER':
            return redirect('volunteer_dashboard')
        elif profile.user_type == 'ORGANIZATION':
            return redirect('organization_dashboard')
        return redirect('user_dashboard')

    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user_type = request.POST['user_type']
        
        print(f"Login attempt - Username: {username}, User Type: {user_type}")  # Debug print
        
        user = authenticate(request, username=username, password=password)
        
        if user is not None:
            try:
                profile = UserProfile.objects.get(user=user)
                print(f"Found profile type: {profile.user_type}")  # Debug print
                
                if profile.user_type == user_type:
                    login(request, user)
                    print(f"Login successful, redirecting to {user_type} dashboard")  # Debug print
                    
                    if user_type == 'VOLUNTEER':
                        print("Redirecting to volunteer dashboard")  # Debug print
                        return redirect('volunteer_dashboard')
                    elif user_type == 'ORGANIZATION':
                        return redirect('organization_dashboard')
                    else:
                        return redirect('user_dashboard')
                else:
                    messages.error(request, f'This account is not registered as {user_type}')
            except UserProfile.DoesNotExist:
                messages.error(request, 'User profile not found')
        else:
            messages.error(request, 'Invalid username or password')
    
    return render(request, 'registration/login.html')

@csrf_exempt
def password_reset_request(request):
    if request.method == "POST":
        form = PasswordResetForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            associated_users = User.objects.filter(email=email)
            if associated_users.exists():
                for user in associated_users:
                    subject = "Password Reset Requested"
                    email_template_name = "registration/password_reset_email.html"
                    context = {
                        "email": user.email,
                        "domain": request.get_host(),
                        "site_name": "Wesalvator",
                        "uid": urlsafe_base64_encode(force_bytes(user.pk)),
                        "token": default_token_generator.make_token(user),
                        "protocol": "http",
                    }
                    email = render_to_string(email_template_name, context)
                    send_mail(subject, email, settings.DEFAULT_FROM_EMAIL, [user.email], fail_silently=False)
                messages.success(request, "A password reset link has been sent to your email.")
                return redirect("login")
            else:
                messages.error(request, "No user is associated with this email address.")
    else:
        form = PasswordResetForm()
    return render(request, "registration/password_reset.html", {"form": form})
