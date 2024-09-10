from django.shortcuts import render

from visits.models import PageVisit

def home_view(request, *args, **kwargs):
   return about_view(request, *args, **kwargs)

def about_view(request, *args, **kwargs):
   qs = PageVisit.objects.all()
   page_qs = PageVisit.objects.filter(path=request.path)
   my_title = 'My Page'
   my_context = {
      'page_title': my_title,
      'page_visits_count': page_qs.count(),
      'total_visits_count': qs.count()
      }
   html_template = 'home.html'
   PageVisit.objects.create(path=request.path)

   return render(request, html_template, my_context)