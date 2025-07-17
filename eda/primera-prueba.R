library(tidyverse)
library(ggdist)
library(ggrepel)

DATA_PATH <- "../data/primera-prueba/"

# ==============================================================================
# Carga de datos
# ==============================================================================
df <- list.files(path = DATA_PATH, pattern = "\\.csv$", full.names = T) |>
  set_names() |>
  map(\(path) read_csv(
    path,
    col_types = cols(
      `PARTE A` = col_character(),
      `PARTE B` = col_character(),
      Prueba = col_character(),
    )
  )) |>
  bind_rows(.id = "id") |>
  transmute(
    np = if_any(
      # Técnico y Artístico son de la especialidad de Dibujo
      # Supuesto práctico y Práctico son de la especialidad de Peluquería
      c(`PARTE A`, `PARTE B`, `TÉCNICO`, `ARTÍSTICO`, `SUPUESTO PRÁCTICO`, `PRÁCTICO`),
      ~ !is.na(.) & . == "No presentado"
    ),
    exc = if_any(
      # Técnico y Artístico son de la especialidad de Dibujo
      # Supuesto práctico y Práctico son de la especialidad de Peluquería
      c(`PARTE A`, `PARTE B`, `TÉCNICO`, `ARTÍSTICO`, `SUPUESTO PRÁCTICO`, `PRÁCTICO`),
      ~ !is.na(.) & . == "Excluido"
    ),
    across(c(`PARTE A`, `PARTE B`, Prueba), ~ if_else(. %in% c("-", "No presentado", "Excluido"), NA, .)),
    across(c(`PARTE A`, `PARTE B`, Prueba), as.double),
    `PARTE A` = case_when(
      Especialidad %in% c("Peluquería", "Dibujo") ~ round((Prueba - 0.4 * `PARTE B`) / 0.6, 4),
      TRUE ~ `PARTE A`
    ),
    ...12 = case_when(
      Especialidad %in% c("Peluquería", "Dibujo") ~ ...13,
      TRUE ~ ...12
    ),
    id = id,
    proceso = as_factor(Proceso),
    cuerpo = as_factor(Cuerpo),
    especialidad = as_factor(Especialidad),
    tribunal = Tribunal,
    fecha_pub = dmy_hms(`Fecha de publicación`),
    dni = DNI,
    nombre = `Apellidos y Nombre`,
    nota_a = `PARTE A`,
    nota_b = `PARTE B`,
    nota = Prueba,
    resultado = as_factor(`...12`),
    especialidad_c = as_factor(case_when(
      cuerpo == "Cuerpo de Maestros" ~ paste(especialidad, "(P)"),
      TRUE ~ paste(especialidad, "(S)")
    ))
  ) |>
  select(-c(`PARTE A`, `PARTE B`, Prueba, ...12)) |>
  relocate(c(np, exc), .after = nota) |>
  relocate(especialidad_c, .after = especialidad)

# ==============================================================================
# Nota media de la primera prueba por especialidad
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
      title = "Nota media de la primera prueba por especialidad",
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
# Porcentaje aptos de la primera prueba por especialidad
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
      title = "Porcentaje aptos de la primera prueba por especialidad",
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
# Distribución de notas (densidad) de la primera prueba por especialidad
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
      title = "Distribución de notas (densidad) de la primera prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
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
# Tiempo en publicar notas de la primera prueba por especialidad
# ==============================================================================
df |>
  filter(!np & !exc) |>
  mutate(
    delta_pub = as.numeric(fecha_pub - dmy_hm("21-06-2025 00:00"), units = "days")
  ) |>
  relocate(delta_pub, .after = fecha_pub) |>
  group_by(especialidad_c) |>
  summarize(
    ratio_asp = n() / n_distinct(tribunal),
    tiempo_pub = mean(delta_pub),
  ) |>
  ggplot(aes(x = ratio_asp, y = tiempo_pub)) +
    geom_point() +
    geom_text_repel(aes(label = especialidad_c), size = 3) +
    scale_y_continuous(labels = \(x) paste0(x, " días")) +
    labs(
      title = "Tiempo en publicar notas de la primera prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
        "* El tiempo se calcula desde la fecha de realización de la prueba mediante una media de todos los tribunales de cada especialidad",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = "Ratio de aspirantes por tribunal",
      y = "Tiempo en publicar notas"
    ) +
    theme_minimal(base_family = "Roboto") +
    theme(
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40"),
      axis.title.x = element_text(margin = margin(t = 20)),
      axis.title.y = element_text(margin = margin(r = 20)),
    )

# ==============================================================================
# Nota máxima de la primera prueba por especialidad
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
      title = "Nota máxima de la primera prueba por especialidad",
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
# Nota media de cada parte de la primera prueba por especialidad (APTOS)
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min)
  ) |>
  filter(nota >= 5) |>
  group_by(especialidad_c) |>
  summarize(
    nota_a = -mean(nota_a),
    nota_b = mean(nota_b)
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
        label = c("Parte A", "Parte B"),
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
        hjust = if_else(parte == "A", -0.3, 1.2),
      ),
      size = 3,
      family = "Roboto",
      alpha = 0.7
    ) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Nota media de cada parte de la primera prueba por especialidad (APTOS)",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* Sólo se están teniendo en cuenta aspirantes APTOS en la prueba",
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
# Distribución de notas de cada parte de la primera prueba
# ==============================================================================
df |>
  ggplot(aes(x = nota_a, y = nota_b, color = resultado)) +
    geom_point(alpha = 0.6) +
    labs(
      title = "Distribución de notas de cada parte de la primera prueba",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = "Nota de la parte A",
      y = "Nota de la parte B"
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
# Porcentaje no presentados de la primera prueba por especialidad
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
      title = "Porcentaje no presentados de la primera prueba por especialidad",
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
# Nota media de la primera prueba por isla de tribunal y especialidad
# ==============================================================================
df |>
  filter(!np & !exc) |>
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
    nota = mean(nota)
  ) |>
  ggplot(aes(x = isla_tribunal, y = especialidad_c, fill = nota)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%0.2f", nota), color = nota < mean(df$nota, na.rm = T)), size = 3) +
  scale_fill_viridis_c(option = "D", guide = "none") +
  scale_color_manual(values = c("black", "white"), guide = "none") +
  labs(
    title = "Nota media de la primera prueba por isla de tribunal y especialidad",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* No se están teniendo en cuenta tribunales con sistema acceso",
      "* No se están teniendo en cuenta aspirantes no presentados o excluidos",
      "* Las especialidades están ordenadas alfabéticamente",
      "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      sep = "\n"
    ),
    x = NULL,
    y = NULL
  ) +
  theme_minimal(base_family = "Roboto") +
  theme(
    plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
    plot.title = element_text(size = 16, face = "bold", color = "gray20"),
    plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
    plot.caption = element_text(margin = margin(t = 30), color = "gray40"),
    panel.grid = element_blank()
  )
