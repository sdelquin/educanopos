library(tidyverse)

DATA_PATH <- "../data/primera-prueba/"

df <- list.files(path = DATA_PATH, pattern = "\\.csv$", full.names = T) |>
  set_names() |>
  map(\(path) read_csv(
    path,
    na = c("-", "No presentado", "Excluido")
  )) |>
  bind_rows(.id = "id") |>
  transmute(
    proceso = as_factor(Proceso),
    cuerpo = as_factor(Cuerpo),
    especialidad = as_factor(Especialidad),
    tribunal = Tribunal,
    prueba = Publicación,
    fecha_pub = dmy_hms(`Fecha de publicación`),
    dni = DNI,
    nombre = `Apellidos y Nombre`,
    nota_a = `PARTE A`,
    nota_b = `PARTE B`,
    nota = Prueba,
    resultado = as_factor(`...12`)
  ) |>
  # Dibujo y Peluquería presentan una estructura de columnas distintas
  filter(!especialidad %in% c("Dibujo", "Peluquería"))

df_dibpel <- df |>
  filter(Especialidad %in% c("Dibujo", "Peluquería"))

df |>
  filter(nota == 10) |>
  t() |>
  View()

df |>
  group_by(especialidad) |>
  summarize(
    nota = mean(nota, na.rm = T)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad, desc(nota)), y = nota, fill = nota)) +
    geom_col() +
    geom_text(aes(label = round(nota, 2)), vjust = -0.3, size = 3) +
    scale_fill_viridis_c() +
    theme_light() +
    labs(
      title = "Nota media de la primera prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = "Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      x = NULL, y = NULL
    ) +
    expand_limits(y = max(df$nota) * 1.5) +
    guides(fill = "none") +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)
    )
