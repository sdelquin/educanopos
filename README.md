# educanopos

Notificación de las puntuaciones de oposición de la Consejería de Educación del Gobierno de Canarias

## Puesta en marcha

Supongamos la carga de datos para procedimientos selectivos en el año 2026:

1. Crea un fichero `data/opos26.yaml` (según corresponda) con los datos de los respectivos procedimientos selectivos (ejemplo en `data/opos25.yaml`).
2. Lanza `just reset-db data/opos26.yaml` lo que recreará la base de datos y cargará los datos indicados en el fichero de entrada.

> [!CAUTION]
> La base de datos y todos sus datos existentes serán borrados.

## Modo de uso

- `uv run python main.py` → Rastrea las nuevas publicaciones de los tribunales.
- `uv run python main.py --notify` → Rastrea **y notifica** las nuevas publicaciones de los tribunales.
- `uv run python main.py --save` → Rastrea **y guarda** las nuevas publicaciones de los tribunales.
- `uv run python main.py --notify --save` → Rastrea **notifica y guarda** las nuevas publicaciones de los tribunales.

## Base de datos

### Activación

Por defecto los procedimientos selectivos cargados en la base de datos están activos para su procesamiento, pero si queremos podemos modificar este comportamiento:

Tabla `process` → Atributo `active`

### Publicaciones

Cada vez que el programa detecta una nueva publicación de tribunal (si así se ha indicado) se notifica vía Telegram y se almacena en la base de datos tabla `publication`.

Por lo tanto se entiende que aquellas publicaciones ya almacenadas en `publication` se dan por gestionadas y ya no se vuelven a procesar.
