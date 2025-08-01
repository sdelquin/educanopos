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
    plazas = `Plazas de ingreso`,
    fecha_pub = dmy_hms(`Fecha de publicación`),
    dni = DNI,
    nombre = `Apellidos y Nombre`,
    nota = Prueba,
    np = `PARTE AB` == "No presentado",
    exc = `PARTE AB` == "Excluido",
    resultado = as_factor(`...13`),
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

# ==============================================================================
# Nota media de la segunda prueba por isla de tribunal y especialidad
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
  coord_fixed(ratio = 0.2) +
  geom_text(aes(label = sprintf("%0.2f", nota), color = nota < mean(df$nota, na.rm = T)), size = 3) +
  scale_fill_viridis_c(option = "D", guide = "none") +
  scale_color_manual(values = c("black", "white"), guide = "none") +
  labs(
    title = "Nota media de la segunda prueba por isla de tribunal y especialidad",
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
    plot.margin = margin(t = 40, r = 20, b = 40, l = -150),
    plot.title = element_text(size = 16, face = "bold", color = "gray20"),
    plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
    plot.caption = element_text(margin = margin(t = 30, r = -150), color = "gray40"),
    panel.grid = element_blank()
  )

# ==============================================================================
# Número de aptos sobre el número de plazas de la segunda prueba por especialidad
# ==============================================================================
df |>
  filter(!np & !exc) |>
  group_by(especialidad_c) |>
  summarize(
    plazas = first(plazas),
    aptos = sum(resultado == "APTO"),
  ) |>
  pivot_longer(cols = c(aptos, plazas)) |>
  mutate(
    opacidad = if_else(name == "plazas", 0.65, 1),
    name = factor(name, levels = c("plazas", "aptos")),
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min, .desc = TRUE)
  ) |>
  ggplot(aes(x = especialidad_c, y = value, fill = name, alpha = opacidad)) +
    geom_col(position = position_identity()) +
    coord_flip() +
    scale_alpha_identity() +
    scale_fill_manual(
      values = c("plazas" = "orchid4", "aptos" = "aquamarine3"),
      labels = c("plazas" = "Plazas", "aptos" = "Aptos"),
      name = NULL
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Número de aptos sobre el número de plazas de la segunda prueba por especialidad",
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
    theme_minimal(base_family = "Roboto") +
    theme(
      # panel.grid = element_blank(),
      plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
      # axis.text.x = element_blank(),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40")
    )

# ==============================================================================
# Fechas de publicación de resultados de la segunda prueba por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    fecha_pub = as.Date(mean(fecha_pub)),
    cuerpo = first(cuerpo),
    n_tribunales = n_distinct(tribunal)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, fecha_pub), y = fecha_pub, color = cuerpo, size = n_tribunales)) +
    geom_point() +
    scale_y_date(breaks = "1 day", date_labels = "%d/%m/%y") +
    coord_flip() +
    labs(
      title = "Fechas de publicación de resultados de la segunda prueba por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* Se ha hecho un promedio de las fechas de publicación de los tribunales de cada especialidad",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL,
      y = NULL,
      color = "Cuerpo",
      size = "Número de tribunales"
    ) +
    theme_minimal(base_family = "Roboto") +
    theme(
      plot.margin = margin(t = 40, r = 40, b = 40, l = 20),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30), color = "gray40"),
      axis.title.x = element_text(margin = margin(t = 20)),
      axis.title.y = element_text(margin = margin(r = 20)),
      panel.grid.minor.x = element_blank(),
      axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 8, color = "gray50")
    )
