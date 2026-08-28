# Producción de Videojuegos - Sistemas Interactivos 2026

**Universidad Antonio Nariño (UAN)**
**Facultad de Ingeniería de Sistemas y Computación**

## 📝 Descripción del Proyecto

Este repositorio contiene el desarrollo del **Laboratorio 1: Configuración del Entorno, Arquitectura Base e Interacción Local**, correspondiente al curso de **Producción de Videojuegos - Sistemas Interactivos** de la Universidad Antonio Nariño.

El laboratorio tiene como propósito establecer la línea base del proyecto interactivo mediante la configuración del entorno de desarrollo en **Godot Engine 4.x**, la organización estructurada de los archivos del proyecto y la implementación de los primeros componentes visuales y lógicos utilizando **GDScript 2.0**.

Durante el desarrollo se implementa una arquitectura organizada dentro de la carpeta `src/`, separando los recursos multimedia, componentes, escenas y scripts de acuerdo con su responsabilidad dentro del proyecto. Esta organización busca mantener una estructura limpia, facilitar el mantenimiento del código y permitir la evolución del sistema durante las siguientes etapas del proyecto integrador.

El proyecto cuenta con dos escenas principales de interacción:

* **`main.tscn`**: corresponde al menú principal del sistema. Esta escena permite iniciar la simulación mediante el botón **Simular** o finalizar la ejecución mediante el botón **Salir**. Al seleccionar la opción de simulación, el sistema actualiza el estado visual de la interfaz y realiza la navegación hacia `main_level_1.tscn`.

* **`main_level_1.tscn`**: corresponde a la pantalla de selección de la simulación. Esta escena presenta diferentes opciones mediante un `GridContainer`, permitiendo seleccionar una base de simulación y visualizar de forma inmediata el nombre de la opción seleccionada junto con su costo asociado.

La lógica de interacción se implementa mediante señales conectadas directamente desde código. Las referencias a los nodos de la interfaz se almacenan mediante `@onready` y el operador de ruta `$`, evitando búsquedas repetitivas dentro del árbol de nodos. Asimismo, se utiliza tipado estático en las variables, parámetros y funciones principales para mejorar la claridad y seguridad del código.

En `main.gd`, las señales de los botones se registran mediante una función de configuración independiente. El botón **Simular** utiliza `get_tree().change_scene_to_file()` para realizar la transición hacia la escena de selección, mientras que el botón **Salir** ejecuta `get_tree().quit()` para finalizar la aplicación de manera controlada.

En `main_level_1.gd`, los botones de selección utilizan el método `.bind()` para enviar dinámicamente el nombre y el costo de cada opción hacia una única función controladora. De esta manera, diferentes botones pueden utilizar la misma función de procesamiento sin duplicar la lógica de interacción.

## 📂 Estructura de Directorios del Repositorio

El desarrollo sigue una arquitectura estructurada de carpetas dentro del directorio `src/`, manteniendo separados los diferentes elementos que conforman el proyecto:

* `src/scenes/`: Contenedor de las escenas principales del proyecto. En esta carpeta se encuentran las interfaces y flujos visuales utilizados para la interacción del sistema, incluyendo `main.tscn` y `main_level_1.tscn`.

* `src/scripts/`: Contiene los archivos desarrollados en GDScript encargados de controlar el comportamiento y la interacción de las diferentes escenas. Los scripts principales corresponden a `main.gd` y `main_level_1.gd`.

* `src/assets/`: Contenedor destinado a los recursos multimedia utilizados por el proyecto. Su contenido se organiza de acuerdo con el tipo de recurso utilizado por la aplicación.

* `src/assets/audio/`: Recursos relacionados con efectos de sonido, música u otros elementos de audio que puedan incorporarse al proyecto.

* `src/assets/textures/`: Contiene las imágenes, texturas y recursos gráficos utilizados dentro de las escenas.

* `src/assets/ui/`: Contiene los recursos visuales asociados a la interfaz de usuario, como iconos y elementos gráficos utilizados por el proyecto.

* `src/components/`: Contenedor destinado a componentes y elementos reutilizables que puedan ser incorporados en diferentes escenas del sistema.

La estructura busca mantener una separación clara entre la presentación visual, los recursos y la lógica de programación, siguiendo la organización establecida para el laboratorio.

## ⚙️ Tecnologías Utilizadas

* **Engine:** Godot Engine 4.x, utilizando la versión Standard de 64 bits y el renderizador *Compatibility*, seleccionado para favorecer la portabilidad del proyecto y su compatibilidad con plataformas de ejecución web.

* **Lenguaje:** GDScript 2.0, utilizado para implementar la lógica de control de las escenas y las interacciones locales. Los métodos, variables, parámetros y referencias principales utilizan tipado estático para mejorar la claridad y seguridad del código.

* **Interfaz de Usuario:** Nodos de tipo `Control` y contenedores adaptativos de Godot para construir interfaces que puedan ajustarse a diferentes tamaños de pantalla. La pantalla principal utiliza un `VBoxContainer` para organizar los botones de control, mientras que la pantalla de selección utiliza un `GridContainer` para distribuir las opciones de simulación.

* **Sistema de Señales:** Las interacciones de los botones se gestionan mediante conexiones realizadas desde código utilizando `pressed.connect()`. Las conexiones se organizan mediante funciones específicas para mantener separada la configuración de eventos de la lógica que ejecuta cada acción.

* **Paso de Parámetros:** La pantalla de selección utiliza `.bind()` para asociar dinámicamente el nombre y el costo correspondiente a cada botón. Los parámetros son recibidos posteriormente por una única función controladora, evitando la duplicación de código.

* **Navegación entre Escenas:** La transición desde el menú principal hacia la pantalla de selección se realiza mediante `get_tree().change_scene_to_file()`, permitiendo establecer un flujo secuencial entre las escenas principales del laboratorio.

* **Control de Versionamiento:** Git y GitHub utilizados para administrar el historial del proyecto, mantener el control de cambios y establecer una versión de entrega mediante el tag correspondiente al laboratorio.

## Personalización del Proyecto

El nombre, la descripción y el ícono del proyecto se configuraron desde el panel interno de Godot Engine, siguiendo la ruta:

**Project > Project Settings > Application > Config**

Dentro de esa sección se editaron los siguientes campos:

* **Name:** Nombre visible utilizado para identificar el proyecto dentro del entorno de Godot.

* **Description:** Descripción del proyecto correspondiente al Laboratorio 1 de Producción de Videojuegos - Sistemas Interactivos, relacionado con la configuración del entorno, la arquitectura base y la implementación de interacción local.

* **Icon:** Imagen personalizada utilizada como ícono representativo del proyecto. El recurso gráfico se encuentra organizado dentro de la carpeta `src/assets/ui/`, manteniendo la estructura de directorios definida para el laboratorio.

Adicionalmente, el proyecto se configuró utilizando el renderizador **Compatibility**, requisito establecido para favorecer la portabilidad y permitir que el proyecto pueda orientarse posteriormente hacia plataformas compatibles con WebGL.

La configuración general del proyecto y sus recursos se mantiene organizada de acuerdo con la estructura definida para la actividad, evitando incorporar archivos de desarrollo local que no sean necesarios para el control de versiones.

## Autor

* **Nombre:** July Tatiana Ariza Peña
* **Código Estudiantil:** 12242612877
* **Programa:** Ingeniería de Sistemas y Computación
* **Universidad:** Universidad Antonio Nariño
* **Facultad:** Facultad de Ingeniería de Sistemas
* **Ciudad:** Bogotá, Colombia
* **Año:** 2026
