# DEVLOG — Bitácora de Desarrollo

## [2026-08-23] - Configuración inicial e interacción local

**Autor:** July Tatiana Ariza Peña

### Resumen

Se configuró el entorno de desarrollo utilizando **Godot Engine 4.7.1** con el renderizador **Compatibility** y se estableció la estructura inicial del proyecto bajo la convención `snake_case`, organizando los archivos fuente dentro de la carpeta `src/`.

Durante esta etapa se implementaron las dos escenas principales del laboratorio y sus respectivos scripts de control, estableciendo la base para la interacción local y la navegación entre pantallas.

### Cambios realizados

* Creación de `main.tscn` como menú principal del proyecto, utilizando un `VBoxContainer` para organizar los botones `BtnSimular` y `BtnSalir`.

* Creación de `main_level_1.tscn` como pantalla de selección de la simulación, utilizando un `GridContainer` para organizar las diferentes opciones de ingredientes.

* Implementación de `main.gd` como controlador de la escena principal, utilizando tipado estático, referencias mediante `@onready` y conexión de señales desde código mediante `pressed.connect()`.

* Organización de las conexiones de los botones de `main.gd` mediante una función independiente encargada de registrar los eventos de interacción.

* Implementación de la navegación desde `main.tscn` hacia `main_level_1.tscn` mediante `get_tree().change_scene_to_file()` al seleccionar la opción de inicio de simulación.

* Implementación de `main_level_1.gd` utilizando referencias `@onready` para acceder a los botones y a la etiqueta de estado de la interfaz.

* Implementación de una única función controladora para procesar las selecciones de ingredientes, utilizando `.bind()` para enviar dinámicamente el nombre y el costo correspondiente a cada opción.

* Configuración del botón de salida mediante `get_tree().quit()`, permitiendo finalizar la ejecución de la aplicación desde el menú principal.

* Personalización del nombre, descripción e ícono del proyecto desde la configuración de aplicación de Godot Engine.

### Problemas encontrados y solución

* Durante la implementación inicial, el script `main_level_1.gd` no quedó asociado correctamente al nodo raíz de la escena, por lo que las interacciones de los botones de selección no se ejecutaban. El problema se solucionó asociando correctamente el script existente al nodo correspondiente.

* Se identificaron conexiones de señales redundantes durante la configuración de la navegación entre escenas. Estas conexiones podían provocar referencias inválidas al cambiar de escena, por lo que se reorganizó la lógica para evitar duplicidad en el manejo de eventos.

* La navegación entre las escenas fue ajustada para que el cambio desde el menú principal hacia la pantalla de selección se realice directamente desde `main.gd` mediante `get_tree().change_scene_to_file()`.

### Próximos pasos

* Verificar el funcionamiento completo de las dos escenas y la correcta respuesta de todos los botones.

* Comprobar que las rutas de los nodos utilizadas mediante `$` coincidan con la jerarquía definida en cada escena.

* Revisar la estructura final del repositorio y preparar la grabación del video de sustentación.
