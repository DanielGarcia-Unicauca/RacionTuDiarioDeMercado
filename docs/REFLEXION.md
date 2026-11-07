# Reflexión: de Compose/XML a SwiftUI

Migrar Ración de Android a iOS no fue traducir líneas, sino traducir un modelo mental. En Android convivían dos formas de describir la interfaz: el XML inflado con View Binding y, en las pantallas nuevas, Jetpack Compose. Incluso dentro de Compose la experiencia se sentía fragmentada, porque el estado viajaba por `ViewModel`, `StateFlow` y `collectAsStateWithLifecycle`.

SwiftUI reduce esa distancia. Su sintaxis declarativa se parece a Compose —`VStack`, modificadores encadenados, composición— pero el resultado es más uniforme: una vista es una función del estado y no hay dos sistemas de vistas que aprender. En experiencia de desarrollo, la previsualización inmediata y los modificadores hacen que ajustar el diseño sea más rápido; en Android, validar un cambio dependía de emuladores y builds de Gradle más lentos.

El cambio más profundo está en el estado. Compose obliga a pensar en recomposición y en `remember`; SwiftUI obliga a pensar en propiedad. Pasar de `@State` a `@Binding` y de `@StateObject` a `@ObservedObject` deja explícito quién posee cada dato. Esa disciplina es más simple de explicar y de auditar, aunque también más fácil de romper: un `@StateObject` creado dentro de `body` se recrea sin avisar.

En arquitectura, MVVM sobrevivió intacto: Models, ViewModels y Views siguen separados y la regla de dependencias no cambió. Lo que cambió fue la infraestructura: Retrofit se convirtió en `URLSession` + `Codable`, Firestore en archivos JSON y `NavHost` en `NavigationStack` con rutas tipadas. Si volviera a empezar, elegiría SwiftUI para una app pequeña y muy visual como esta; para un equipo grande con Android ya maduro, mantener Compose y compartir solo el dominio seguiría siendo lo más rentable.
