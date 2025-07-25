# educanopos

Notificación de las puntuaciones de oposición de la Consejería de Educación del Gobierno de Canarias

## Observaciones

### Tribunales

- Existen dos tipos de tribunales: de **ingreso** y de **acceso**.
- Los tribunales de acceso no tienen la misma estructura de pruebas en la fase de oposición: Sólo disponen de una prueba única. Mientras que los tribunales de ingreso tienen primera prueba y segunda prueba para la fase de oposición.
- Publicaciones (típicas) de un **tribunal de acceso**:
  - Prueba única
  - Prueba única - APTOS
  - Prueba única (Definitiva)
  - Prueba única - APTOS (Definitiva)
  - Fase oposición
  - Fase concurso (Provisional)
  - Fase de concurso (Provisional) - Detalle de baremo
  - Fase concurso (Definitiva)
  - Fase de concurso (Definitiva) - Detalle de baremo
  - Fase Asignación de plazas
- Publicaciones (típicas) de un **tribunal de ingreso**:
  - Primera prueba
  - Primera prueba - APTOS
  - Citaciones - PARTE AB
  - Segunda prueba
  - Segunda prueba - APTOS
  - Fase oposición
  - Fase concurso (Provisional)
  - Fase de concurso (Provisional) - Detalle de baremo
  - Fase concurso (Definitiva)
  - Fase de concurso (Definitiva) - Detalle de baremo
  - Fase Asignación de plazas
- La única publicación con la misma estructura en ambos tribunales es "Asignación de plazas".

### Plazas

- Inicialmente (en las correspondientes convocatorias) se publica el número de plazas por especialidad y por tipo (ingreso y acceso). Igualmente se publica el cupo de reserva para personas con discapacidad.
- Desglose de plazas:
  - Turno Libre → Tribunales de ingreso.
  - Acceso al Subgrupo A1 → Tribunales de acceso.
  - Reserva Discapacidad → Tribunales de ingreso o tribunales de acceso.
- Si en una especialidad no hay aspirantes para acceso, dichas plazas se suman a las de turno libre desde el comienzo del procedimiento.
- Si en el sistema acceso sobran plazas una vez asignadas, dichas plazas se suman a las de turno libre desde que se realice la asignación del turno de acceso.

## Puesta en marcha

Supongamos la carga de datos para procedimientos selectivos en el año 2026:

1. Crea un fichero `data/opos26.yaml` (según el año que corresponda) con los datos de los respectivos procedimientos selectivos (ejemplo en `data/opos25.yaml`).
2. Lanza `just reset-db data/opos26.yaml` lo que recreará la base de datos y cargará los datos indicados en el fichero de entrada.

> [!CAUTION]
> La base de datos y todos sus datos existentes serán borrados.

## Modo de uso

### Exportar tribunales

- `uv run python main.py -v export-boards` → Exporta a `data/boards.csv` los datos de tribunales (con número de plazas y demás información inicial).
- `uv run python main.py -v export-boards -i "SISTEMA ACCESO"` → Exporta a `data/boards.csv` los datos de tribunales (con número de plazas y demás información inicial) ignorando aquellos tribunales que contengan el texto `SISTEMA ACCESO`.

> [!TIP]
> Estos datos se pueden utilizar para [`eda/previa.R`](eda/previa.R)

### Rastrear publicaciones

- `uv run python main.py -v check-pub` → Rastrea las nuevas publicaciones de los tribunales.
- `uv run python main.py -v check-pub --notify` → Rastrea **y notifica** las nuevas publicaciones de los tribunales.
- `uv run python main.py -v check-pub --save` → Rastrea **y guarda** las nuevas publicaciones de los tribunales.
- `uv run python main.py -v checkpub --notify --save` → Rastrea **notifica y guarda** las nuevas publicaciones de los tribunales.

### Exportar publicaciones

Se aconseja lanzar primero el rastreo de publicaciones.

- `uv run python main.py -v export-pub "Primera prueba"` → Exporta a `data/primera-prueba/` los resultados de publicaciones existentes de "Primera prueba".
- `uv run python main.py -v export-pub "Primera prueba" -i "SISTEMA ACCESO"` → Exporta a `data/primera-prueba/` los resultados de publicaciones existentes de "Primera prueba" ignorando aquellos tribunales que contengan el texto `SISTEMA ACCESO`.

> [!TIP]
> Estos datos se pueden utilizar para el resto del [EDA](#análisis-exploratorio).

## Base de datos

### Activación

Por defecto los procedimientos selectivos cargados en la base de datos están activos para su procesamiento, pero si queremos podemos modificar este comportamiento:

Tabla `process` → Atributo `active`

### Publicaciones

Cada vez que el programa detecta una nueva publicación de tribunal (si así se ha indicado) se notifica vía Telegram y se almacena en la base de datos tabla `publication`.

Por lo tanto se entiende que aquellas publicaciones ya almacenadas en `publication` se dan por gestionadas y ya no se vuelven a procesar.

## Análisis exploratorio

En la carpeta [`eda/`](./eda/) se encuentran los scripts de `R` para generar los gráficos de cada una de las fases del procedimiento selectivo.

Es habitual guardar los gráficos en la carpeta `eda/plots/`
