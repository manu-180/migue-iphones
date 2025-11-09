# taller_ceramica

A new Flutter project.

## Getting Started

Para cambiar el nombre de la app :
""
dart run change_app_package_name:main com.manuelnavarro.tallerdeceramica
""
seleccionar el icono :
""
dart run flutter_launcher_icons 
""

andriod AAB :
""
flutter build appbundle
""

user:
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

despliegue en web:
Remove-Item -Recurse -Force docs
flutter build web
mkdir docs    
cp -r build/web/* docs/
copy vercel.json docs/
git add .
git commit -m "actualizando pagina para vercel"
git push



# Desde la raíz del proyecto
flutter build web
# Copia el vercel.json a la carpeta de salida
copy vercel.json build\web\
# Ponete en esa carpeta
cd build\web
# Y deploy principal
vercel --prod


