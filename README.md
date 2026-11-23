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

## Datos que permanecen locales

El carrito sigue persistiendo en el dispositivo. Las imágenes y audios cargados desde archivos se guardan en Hive local; sus referencias en Firestore no sincronizan los bytes entre dispositivos. Para compartir esos archivos hace falta habilitar Firebase Storage y migrar esos medios al bucket.
