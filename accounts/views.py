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
from django_otp.plugins.otp_email.models import EmailDevice
from .send_email import send_sms_to_user
from django.http import JsonResponse
import json

def get_admins(request):
    if request.method == 'GET':
        admins = User.objects.filter(userprofile__user_type='ADMIN').values('id', 'username')
        return JsonResponse({'admins': list(admins)})

def signup(request):
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            # Generate OTPs
            email_otp = str(random.randint(100000, 999999))
            mobile_otp = str(random.randint(100000, 999999))

            # Store data in session
            request.session['signup_data'] = {
                'name': form.cleaned_data['name'],
                'username': form.cleaned_data['username'],
                'email': form.cleaned_data['email'],
                'password1': form.cleaned_data['password1'],
                'user_type': form.cleaned_data['user_type'],
                'mobile_number': form.cleaned_data['mobile_number'],
                'location': form.cleaned_data['location'],
            }
            request.session['email_otp'] = email_otp
            request.session['mobile_otp'] = mobile_otp
            request.session.set_expiry(300)  # 5 minutes expiration

            # Send email OTP using django-otp
            user = User(username=form.cleaned_data['username'], email=form.cleaned_data['email'])
            device = EmailDevice.objects.create(user=user, name='email_otp_device')
            device.generate_challenge()  # This sends the OTP via email

            send_sms_to_user(form.cleaned_data['mobile_number'], mobile_otp)

            return redirect('verify_otp')
    else:
        form = SignUpForm()
    return render(request, 'registration/signup.html', {'form': form})

def verify_otp(request):
    if request.method == 'POST':
        entered_email_otp = request.POST.get('email_otp')
        entered_mobile_otp = request.POST.get('mobile_otp')
        
        # Retrieve session data
        signup_data = request.session.get('signup_data')
        stored_email_otp = request.session.get('email_otp')
        stored_mobile_otp = request.session.get('mobile_otp')
        
        if not (signup_data and stored_email_otp and stored_mobile_otp):
            messages.error(request, 'Session expired. Please register again.')
            return redirect('signup')
        
        if entered_email_otp == stored_email_otp and entered_mobile_otp == stored_mobile_otp:
            # Create user
            user = User.objects.create_user(
                username=signup_data['username'],
                email=signup_data['email'],
                password=signup_data['password1']
            )
            # Create UserProfile
            UserProfile.objects.create(
                user=user,
                user_type=signup_data['user_type'],
                mobile_number=signup_data['mobile_number']
            )
            # Clear session
            del request.session['signup_data']
            del request.session['email_otp']
            del request.session['mobile_otp']
            messages.success(request, 'Account verified! Please login.')
            return redirect('login')
        else:
            messages.error(request, 'Invalid OTP. Please try again.')
            return redirect('verify_otp')
        
    return render(request, 'registration/verify_otp.html')

@csrf_exempt
def get_email_otp(request):
    if request.method == 'POST':
        email = json.loads(request.body).get('email')
        otp = str(random.randint(100000, 999999))
        
        # Store in session
        request.session['email_otp'] = otp
        request.session['email'] = email
        request.session.set_expiry(300)  # 5 minutes
        
        # Send email (use your email sending logic)
        send_mail(
            'Your Email OTP',
            f'Your verification code is: {otp}',
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False
        )
        return JsonResponse({'status': 'success'})
    return JsonResponse({'status': 'error'}, status=400)

@csrf_exempt
def get_sms_otp(request):
    if request.method == 'POST':
        mobile = json.loads(request.body).get('mobile')
        otp = str(random.randint(100000, 999999))
        
        # Store in session
        request.session['sms_otp'] = otp
        request.session['mobile'] = mobile
        request.session.set_expiry(300)  # 5 minutes
        
        # Send SMS (use your SMS sending logic)
        send_sms_to_user(mobile, otp)
        return JsonResponse({'status': 'success'})
    return JsonResponse({'status': 'error'}, status=400)

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
                        "site_name": "Wesalvatore",
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
