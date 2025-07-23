library(tidyverse)
library(ggdist)
library(ggrepel)

DATA_PATH <- "../data/fase-concurso-provisional/"

# ==============================================================================
# Carga de datos
# ==============================================================================
df <- list.files(path = DATA_PATH, pattern = "\\.csv$", full.names = T) |>
  set_names() |>
  map(\(path) read_csv(path)) |>
  bind_rows(.id = "id") |>
  transmute(
    id = id,
    proceso = as_factor(Proceso),
    cuerpo = as_factor(Cuerpo),
    especialidad = as_factor(Especialidad),
    especialidad_c = as_factor(case_when(
      cuerpo == "Cuerpo de Maestros" ~ paste(especialidad, "(P)"),
      TRUE ~ paste(especialidad, "(S)")
    )),
    tribunal = Tribunal,
    fecha_pub = dmy_hms(`Fecha de publicación`),
    dni = DNI,
    nombre = `Apellidos y Nombre`,
    nota_oposicion = as.numeric(gsub(",", ".", `Total Oposición`)),
    nota_concurso = as.numeric(gsub(",", ".", `Total Concurso`)),
    nota = as.numeric(gsub(",", ".", `Total`)),
  )
  
# ==============================================================================
# Nota media de la fase de concurso por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    nota = mean(nota_concurso)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, nota), y = nota, fill = nota)) +
  geom_col() +
  coord_flip() +
  geom_label(aes(label = sprintf("%.02f", nota)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
  scale_fill_viridis_c() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Nota media de la fase de concurso por especialidad",
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

# ==============================================================================
# Distribución de notas (densidad) de la fase de concurso por especialidad
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min)
  ) |>
  ggplot(aes(x = nota_concurso)) +
  geom_density(fill = "skyblue", color = "steelblue4") +
  facet_wrap(~especialidad_c) +
  labs(
    title = "Distribución de notas (densidad) de la fase de concurso por especialidad",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* No se están teniendo en cuenta tribunales con sistema acceso",
      "* Las especialidades están ordenadas alfabéticamente",
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
# Nota máxima de la fase de concurso por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    max_nota = max(nota_concurso)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, max_nota), y = max_nota, fill = max_nota)) +
  geom_col() +
  coord_flip() +
  geom_label(aes(label = sprintf("%.02f", max_nota)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
  scale_fill_viridis_c() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Nota máxima de la fase de concurso por especialidad",
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

# ==============================================================================
# Nota media de cada fase del procedimiento
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min)
  ) |>
  group_by(especialidad_c) |>
  summarize(
    nota_oposicion = -mean(nota_oposicion),
    nota_concurso = mean(nota_concurso)
  ) |>
  pivot_longer(
    cols = starts_with("nota"),
    names_to = "parte",
    names_pattern = "nota_(.*)",
    values_to = "nota",
    names_transform = toupper
  ) |>
  ggplot(aes(x = fct_rev(especialidad_c), y = nota, fill = parte)) +
  geom_col() +
  geom_text(
    data = \(.) . |> filter(especialidad_c == levels(.$especialidad_c)[1]),
    aes(
      label = c("Oposición", "Concurso"),
      color = parte
    ),
    y = c(-3, 3),
    nudge_x = 3,
    vjust = 2,
    size = 5,
    fontface = "bold"
  ) +
  geom_text(
    aes(
      label = sprintf("%.02f", abs(nota)),
      hjust = if_else(parte == "OPOSICION", -0.3, 1.2),
    ),
    size = 3,
    family = "Roboto",
    alpha = 0.7
  ) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Nota media de cada fase del procedimiento",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* No se están teniendo en cuenta tribunales con sistema acceso",
      "* Las especialidades están ordenadas alfabéticamente",
      "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      sep = "\n"
    ),
    x = NULL, y = NULL
  ) +
  guides(fill = "none", color = "none") +
  theme_minimal(base_family = "Roboto") +
  theme(
    panel.grid = element_blank(),
    plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
    axis.text.x = element_blank(),
    axis.text.y = element_text(margin = margin(r = 10)),
    plot.title = element_text(size = 16, face = "bold", color = "gray20"),
    plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
    plot.caption = element_text(margin = margin(t = 30), color = "gray40")
  )

# ==============================================================================
# Distribución de notas de cada fase del procedimiento
# ==============================================================================
df |>
  mutate(
    across(c(nota_oposicion, nota_concurso), ~ signif(., 2))
  ) |>
  ggplot(aes(x = nota_oposicion, y = nota_concurso)) +
    geom_point(alpha = 0.6) +
    labs(
      title = "Distribución de notas de cada fase del procedimiento",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = "Nota de oposición",
      y = "Nota de concurso"
    ) +
    theme_minimal(base_family = "Roboto") +
    theme(
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40"),
      axis.title.x = element_text(margin = margin(t = 20)),
      axis.title.y = element_text(margin = margin(r = 20)),
      legend.title = element_blank()
    )

# ==============================================================================
# Nota media de la fase de concurso por isla de tribunal y especialidad
# ==============================================================================
df |>
  mutate(
    isla_tribunal = factor(case_when(
      str_detect(tribunal, "TF") ~ "Tenerife",
      str_detect(tribunal, "GC") ~ "Gran Canaria",
      str_detect(tribunal, "LZ") ~ "Lanzarote",
      str_detect(tribunal, "FU") ~ "Fuerteventura",
      str_detect(tribunal, "LP") ~ "La Palma",
      str_detect(tribunal, "GO") ~ "La Gomera",
      str_detect(tribunal, "HI") ~ "El Hierro",
      TRUE ~ "Desconocida"
    ), levels = c(
      "Tenerife", "Gran Canaria", "Lanzarote", "Fuerteventura",
      "La Palma", "La Gomera", "El Hierro", "Desconocida"
    )),
    .after = "tribunal"
  ) |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min, .desc = TRUE)
  ) |>
  group_by(isla_tribunal, especialidad_c) |>
  summarize(
    nota_concurso = mean(nota_concurso)
  ) |>
  ggplot(aes(x = isla_tribunal, y = especialidad_c, fill = nota_concurso)) +
  geom_tile() +
  coord_fixed(ratio = 0.2) +
  geom_text(aes(label = sprintf("%0.2f", nota_concurso), color = nota_concurso < mean(df$nota_concurso)), size = 3) +
  scale_fill_viridis_c(option = "D", guide = "none") +
  scale_color_manual(values = c("black", "white"), guide = "none") +
  labs(
    title = "Nota media de la fase de concurso por isla de tribunal y especialidad",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* No se están teniendo en cuenta tribunales con sistema acceso",
      "* Las especialidades están ordenadas alfabéticamente",
      "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      sep = "\n"
    ),
    x = NULL,
    y = NULL
  ) +
  theme_minimal(base_family = "Roboto") +
  theme(
    plot.margin = margin(t = 40, r = 20, b = 40, l = -300),
    plot.title = element_text(size = 16, face = "bold", color = "gray20"),
    plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
    plot.caption = element_text(margin = margin(t = 30, r = -250), color = "gray40"),
    panel.grid = element_blank()
  )
