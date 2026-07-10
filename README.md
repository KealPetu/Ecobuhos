# 🦉 EcoBúhos: Guardián del Campus

**Motor de Juego:** Godot 4.7  
**Materia:** Desarrollo de Juegos Interactivos (ISWD823) - Escuela Politécnica Nacional (EPN)  

---

## 👥 Integrantes del Equipo
* Jimmy Damian Arias Morales
* Sebastian Mateo Correa Defaz
* Brandon Ricardo Jaya Tutasi
* Henry Francisco Ludeña Chicaiza
* Daniel Alejandro Oña Rosado
* Kevin Alexander Peñafiel Tuz
* Marlon Andres Vinueza Ramos

**Profesora:** Dra. Mayra Carrión

---

## 📖 Historia del Juego
La Escuela Politécnica Nacional (EPN) enfrenta una crisis sin precedentes: el descuido en la gestión de residuos amenaza con paralizar la vida académica. Como Estudiante EPN, has sido testigo de cómo la basura se acumula, bloqueando los laboratorios y pasillos. 

Sin embargo, no todo está perdido. **MAX**, la mascota de la universidad, te ha elegido como el **"Guardián del Campus"**. Tu misión es recorrer las distintas zonas (como la Facultad de Sistemas, Facultad de Química y el Comedor), dominar el arte de la segregación en cada isla ecológica y purificar el entorno antes de que el terrible **"Desordenador"** logre sepultar la universidad bajo desechos mal gestionados. Cada residuo que depositas correctamente restaura la energía vital de la EPN.

---

## 🎯 Objetivo del Juego
**EcoBúhos** es un Juego Serio diseñado con un objetivo pedagógico primordial: **desarrollar y fomentar una cultura de reciclaje sólida en el jugador**. El juego busca que los jugadores interioricen la correcta separación de residuos (orgánico, plástico, vidrio, metal, electrónicos y papel) mientras experimentan una jugabilidad ágil, divertida y bajo presión, inspirada en mecánicas estilo *Overcooked*.

---

## 🎮 Ludificación y Mecánicas
Para asegurar el aprendizaje continuo y el compromiso del jugador, el proyecto aplica la **metodología iPlus** y el **Framework DPE**, enlazando la teoría del reciclaje con el "Hacer" lúdico mediante:

1. **Retos de Gamificación (Time Attack):** Misiones contra reloj que imponen presión. *Ejemplo: Reciclar 10 residuos orgánicos en menos de 30 segundos.*
2. **Gestión e Interacción (Move & Manage):** La bolsa del jugador tiene límite de capacidad. El jugador debe planificar rutas eficientes para recolectar residuos en "lotes" y equilibrar el tiempo de traslado hacia los contenedores correctos.
3. **Refuerzo Operante (Condicionamiento Positivo y Negativo):**
   * *Positivo:* Multiplicadores de Combo por encadenar aciertos consecutivos. Además, los residuos correctos otorgan puntos de experiencia (XP) para motivar al jugador y evitar el abandono incluso si pierde el nivel.
   * *Negativo:* Penalizaciones por "Contaminación Cruzada" (equivocarse de tacho), bloqueos temporales, y la aparición del *Desordenador* en pantalla tras cometer errores.
4. **Tableros de Puntuación (Leaderboards) e Insignias:** Sistemas de ranking (Ej: *1. CARLOS: 9800 pts*) e insignias para fomentar la rejugabilidad y el perfeccionamiento.
5. **Narrativa Cíclica:** Una estructura por turnos donde avalanchas de basura obligan al jugador a adaptarse a retos cada vez más complejos.

---

## 📁 Estructura de Carpetas (Godot 4.7)
El proyecto ha sido estructurado de manera modular para garantizar escalabilidad, orden y un flujo de trabajo óptimo en Godot:

```txt
EcoBuhos_Project/
│
├── 📁 Assets/                # Archivos multimedia (arte y sonido)
│   ├── 📁 Audio/             # Efectos de sonido (SFX) y pistas musicales (BGM)
│   ├── 📁 Models/            # Modelos 3D de personajes (Avatar, MAX, Desordenador), Tachos y Residuos
│   ├── 📁 Textures/          # Texturas, materiales y sprites 2D
│   └── 📁 UI/                # Fuentes tipográficas, iconos de insignias y elementos de interfaz
│
├── 📁 Scenes/                # Escenas del motor Godot (.tscn)
│   ├── 📁 Levels/            # Escenarios principales (Z1_Sistemas, Z3_Quimica, Z5_Comedor)
│   ├── 📁 Menus/             # Interfaces (MainMenu, PauseScreen, Leaderboard, GameOver)
│   └── 📁 Prefabs/           # Nodos y objetos instanciables (Player, Contenedores_Color, Residuos)
│
├── 📁 Scripts/               # Código fuente en GDScript
│   ├── 📁 Core/              # GameManagers, Controladores de Misiones, TimeAttack y Puntaje
│   ├── 📁 Entities/          # Comportamientos del Player, MAX y el Desordenador
│   └── 📁 Mechanics/         # Lógica de interacciones, combos, inventario y validación de reciclaje
│
├── 📁 Resources/             # Archivos personalizados (.tres) como estadísticas o configuraciones de niveles
│
├── 📁 Docs/                  # Documentación (GDD, Diseño Consensuado FASE GAMESCRIPT)
│
├── README.md                 # Este archivo descriptivo
└── project.godot             # Archivo de configuración central de Godot 4.7

```
