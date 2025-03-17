from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import AdoptableAnimal
from .forms import AdoptableAnimalForm

def adopt_view(request):
    animals = AdoptableAnimal.objects.filter(is_adoptable=True)
    return render(request, 'adoption/adopt.html', {'animals': animals})

def adopt_animal(request):
    # Fetch all adoptable animals
    adoptable_animals = AdoptableAnimal.objects.filter(is_adoptable=True)

    context = {
        'adoptable_animals': adoptable_animals,
    }

    return render(request, 'adoption/adopt_animal.html', context)

@login_required
def add_adoptable_animal(request):
    if request.user.userprofile.user_type != 'ORGANIZATION':
        return render(request, 'adoption/not_authorized.html')

    if request.method == 'POST':
        form = AdoptableAnimalForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect('adoptable_animals_list')
    else:
        form = AdoptableAnimalForm()
    return render(request, 'adoption/add_adoptable_animal.html', {'form': form})

def adoptable_animals_list(request):
    adoptable_animals = AdoptableAnimal.objects.all()  # Fetch all adoptable animals
    return render(request, 'adoption/adopt_animal.html', {'adoptable_animals': adoptable_animals})  # Render the template with the animals

@login_required
def adoptable_animal_detail(request, pk):
    adoptable_animal = get_object_or_404(AdoptableAnimal, pk=pk)
    return render(request, 'adoption/adoptable_animal_detail.html', {'adoptable_animal': adoptable_animal})

@login_required
def edit_adoptable_animal(request, pk):
    adoptable_animal = get_object_or_404(AdoptableAnimal, pk=pk)
    
    if request.user.userprofile.user_type != 'ORGANIZATION':
        return render(request, 'adoption/not_authorized.html')

    if request.method == 'POST':
        form = AdoptableAnimalForm(request.POST, request.FILES, instance=adoptable_animal)
        if form.is_valid():
            form.save()
            return redirect('adoptable_animal_detail', pk=adoptable_animal.pk)
    else:
        form = AdoptableAnimalForm(instance=adoptable_animal)

    return render(request, 'adoption/add_adoptable_animal.html', {'form': form})

def not_authorized(request):
    return render(request, 'adoption/not_authorized.html')



