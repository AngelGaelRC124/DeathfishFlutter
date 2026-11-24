# DEATHFISH: Terminal & Hub Móvil

Aplicación Flutter de DEATHFISH con Firebase Authentication y Cloud Firestore.

## Preparar Firebase

1. Configura las aplicaciones del proyecto con `flutterfire configure` y verifica `lib/firebase_options.dart`.
2. En Firebase Authentication, habilita los proveedores **Correo electrónico/contraseña** y **Anónimo**.
3. Crea la base de datos de Cloud Firestore y publica las reglas de `firestore.rules`:

   ```sh
   firebase deploy --only firestore:rules
   ```

4. Registra una cuenta desde la app. En Firestore, cambia `users/{uid}.rol` de `fan` a `admin` para la cuenta administradora.
5. Inicia sesión con esa cuenta. La app carga `assets/data.json` en `feed`, `tracks` y `merch` si cada colección está vacía.

La inicialización de contenido requiere una sesión admin para que los clientes invitados no puedan escribir. Los invitados tienen acceso de solo lectura; el formulario de contacto requiere una cuenta registrada. Las modificaciones de `feed`, canciones, merch y favoritos se sincronizan con Firestore, que mantiene persistencia offline habilitada.

## Archivos compartidos

La app carga audios MP3/WAV, videos MP4 e imágenes seleccionados por el administrador al bucket público `media` de Supabase Storage. Las URLs resultantes se guardan en los documentos de Firestore y se usan en los reproductores y en el catálogo de merch. Los dispositivos reciben las referencias mediante los streams de Firestore.

Crea el bucket público `media` en Supabase y configura las políticas de Storage para permitir las operaciones necesarias. La clave `publishable` incluida en el cliente no otorga permisos administrativos. Firebase Auth no se convierte automáticamente en una identidad de Supabase: una política de escritura abierta para `anon` permitiría que cualquier persona con la app suba archivos. Para garantizar la autorización admin en el servidor, protege la subida con una Edge Function/API que valide el token de Firebase y el rol en Firestore; no publiques una `service_role` key en la app.

## Datos locales

El carrito sigue persistiendo en el dispositivo. Los medios existentes con identificadores locales de Hive continúan disponibles en el dispositivo donde se guardaron; los nuevos archivos se almacenan en Supabase para compartirlos entre dispositivos.

## EmailJS

El formulario guarda primero el mensaje en Firestore y después lo envía a EmailJS. Configura `emailjs.recipient_email` en `assets/data.json` con la dirección oficial de DEATHFISH; mientras esté vacío, la app informa que el mensaje quedó respaldado en Firestore y no envía una petición incompleta a EmailJS.
