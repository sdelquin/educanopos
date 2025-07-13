library(tidyverse)
library(ggdist)
library(ggrepel)

DATA_PATH <- "../data/segunda-prueba/"

# ==============================================================================
# Carga de datos
# ==============================================================================
df <- list.files(path = DATA_PATH, pattern = "\\.csv$", full.names = T) |>
  set_names() |>
  map(\(path) read_csv(path, na = c("-"))) |>
  bind_rows(.id = "id") |>
  transmute(
    id = id,
    proceso = as_factor(Proceso),
    cuerpo = as_factor(Cuerpo),
    especialidad = as_factor(Especialidad),
    tribunal = Tribunal,
    fecha_pub = dmy_hms(`Fecha de publicación`),
    dni = DNI,
    nombre = `Apellidos y Nombre`,
    nota = Prueba,
    np = `PARTE AB` == "No presentado",
    exc = `PARTE AB` == "Excluido",
    resultado = as_factor(`...11`),
    especialidad_c = as_factor(case_when(
      cuerpo == "Cuerpo de Maestros" ~ paste(especialidad, "(P)"),
      TRUE ~ paste(especialidad, "(S)")
    ))
  )
  
# ==============================================================================
# Nota media de la segunda prueba por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  filter(!np & !exc) |>
  summarize(
    nota = mean(nota)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, nota), y = nota, fill = nota)) +
  geom_col() +
  coord_flip() +
  geom_label(aes(label = sprintf("%.02f", nota)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
  scale_fill_viridis_c() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Nota media de la segunda prueba por especialidad",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* No se están teniendo en cuenta tribunales con sistema acceso",
      "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
      "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      sep = "\n"
    ),
    x = NULL, y = NULL
  ) +
  guides(fill = "none") +
  theme_minimal(base_family = "Roboto") +
  theme(
    panel.grid = element_blank(),
    plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
    axis.text.x = element_blank(),
    plot.title = element_text(size = 16, face = "bold", color = "gray20"),
    plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
    plot.caption = element_text(margin = margin(t = 30), color = "gray40")
  )

# ==============================================================================
# Porcentaje aptos de la segunda prueba por especialidad
# ==============================================================================
df |>
  filter(!np & !exc) |>
  group_by(especialidad_c) |>
  count(resultado) |>
  mutate(
    p = n / sum(n) * 100,
  ) |>
  filter(resultado == "APTO") |>
  ggplot(aes(x = fct_reorder(especialidad_c, p), y = p, fill = p)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = sprintf("%.01f%%", p)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Porcentaje aptos de la segunda prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL, y = NULL
    ) +
    guides(fill = "none") +
    theme_minimal(base_family = "Roboto") +
    theme(
      panel.grid = element_blank(),
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      axis.text.x = element_blank(),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40")
    )

# ==============================================================================
# Distribución de notas (densidad) de la segunda prueba por especialidad
# ==============================================================================
df |>
  filter(!np & !exc) |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min)
  ) |>
  ggplot(aes(x = nota)) +
    geom_density(fill = "skyblue", color = "steelblue4") +
    facet_wrap(~especialidad_c) +
    labs(
      title = "Distribución de notas (densidad) de la segunda prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
        "* Las especialidades están ordenadas por orden alfabético",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL, y = NULL
    ) +
    theme_ggdist(base_family = "Roboto") +
    theme(
      panel.grid = element_blank(),
      strip.background = element_rect(fill = "skyblue4"),
      strip.text = element_text(color = "white", face = "bold"),
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40")
    )

# ==============================================================================
# Nota máxima de la segunda prueba por especialidad
# ==============================================================================
df |>
  filter(!np & !exc) |>
  group_by(especialidad_c) |>
  summarize(
    max_nota = max(nota)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, max_nota), y = max_nota, fill = max_nota)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = sprintf("%.02f", max_nota)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Nota máxima de la segunda prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL, y = NULL
    ) +
    guides(fill = "none") +
    theme_minimal(base_family = "Roboto") +
    theme(
      panel.grid = element_blank(),
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      axis.text.x = element_blank(),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40")
    )

# ==============================================================================
# Porcentaje no presentados de la segunda prueba por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    ratio_np = sum(np) / n() * 100,
  ) |>
  arrange(desc(ratio_np)) |>
  ggplot(aes(x = fct_reorder(especialidad_c, ratio_np), y = ratio_np, fill = ratio_np)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = sprintf("%.01f%%", ratio_np)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Porcentaje no presentados de la segunda prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL, y = NULL
    ) +
    guides(fill = "none") +
    theme_minimal(base_family = "Roboto") +
    theme(
      panel.grid = element_blank(),
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      axis.text.x = element_blank(),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40")
    )
