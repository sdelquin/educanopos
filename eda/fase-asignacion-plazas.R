library(tidyverse)
library(ggdist)
library(ggrepel)

DATA_PATH <- "../data/fase-asignacion-de-plazas/"

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
    plazas = `Plazas de ingreso` + `Plazas de acceso`,
    fecha_pub = dmy_hms(`Fecha de publicación`),
    dni = DNI,
    nombre = `Apellidos y Nombre`,
    nota_ponderada = `Total Ponderada`,
    seleccionado = case_when(
      ...14 == "SELECCIONADO" ~ TRUE,
      TRUE ~ FALSE
    )
  )

# ==============================================================================
# Nota (total ponderada final) media del procedimiento selectivo por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    nota = mean(nota_ponderada)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, nota), y = nota, fill = nota)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = sprintf("%.02f", nota)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Nota (total ponderada final) media del procedimiento selectivo por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
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
# Distribución de notas (densidad) total ponderada final del procedimiento selectivo
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min)
  ) |>
  ggplot(aes(x = nota_ponderada)) +
    geom_density(fill = "skyblue", color = "steelblue4") +
    facet_wrap(~especialidad_c) +
    labs(
      title = "Distribución de notas (densidad) total ponderada final del procedimiento selectivo por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
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
# Nota (total ponderada final) máxima del procedimiento selectivo por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    max_nota = max(nota_ponderada)
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, max_nota), y = max_nota, fill = max_nota)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = sprintf("%.02f", max_nota)), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Nota (total ponderada final) máxima del procedimiento selectivo por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
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
# Número de aspirantes seleccionados y no seleccionados por especialidad
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min)
  ) |>
  group_by(especialidad_c) |>
  summarize(
    no_seleccionados = -sum(!seleccionado),
    seleccionados = sum(seleccionado)
  ) -> aux

aux |>
  summarize(
    no_seleccionados = min(no_seleccionados) / 2,
    seleccionados = max(seleccionados) / 2,
  ) -> title

aux |>
  pivot_longer(
    cols = c(no_seleccionados, seleccionados),
    names_to = "seleccion",
    values_to = "n"
  ) |>
  ggplot(aes(x = fct_rev(especialidad_c), y = n, fill = seleccion)) +
    geom_col() +
    geom_text(
      data = \(.) . |> filter(especialidad_c == levels(.$especialidad_c)[1]),
      aes(
        color = seleccion,
        label = c("No seleccionados", "Seleccionados")
      ),
      y = title |> unlist() |> as.vector(),
      nudge_x = 3,
      vjust = 2,
      size = 5,
      fontface = "bold"
    ) +
    geom_text(
      data = \(.) . |> filter(n != 0),
      aes(
        label = abs(n),
        hjust = if_else(seleccion == "no_seleccionados", 1.2, -0.2),
      ),
      size = 2.5,
      family = "Roboto",
      alpha = 0.7,
    ) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0.03, 0.1))) +
    labs(
      title = "Número de aspirantes seleccionados y no seleccionados por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
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
# Nota (total ponderada final) media del procedimiento selectivo por isla de tribunal y especialidad
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min, .desc = TRUE)
  ) |>
  group_by(isla_tribunal, especialidad_c) |>
  summarize(
    nota = mean(nota_ponderada)
  ) |>
  ggplot(aes(x = isla_tribunal, y = especialidad_c, fill = nota)) +
    geom_tile() +
    coord_fixed(ratio = 0.2) +
    geom_text(aes(label = sprintf("%0.2f", nota), color = nota < mean(df$nota_ponderada)), size = 3) +
    scale_fill_viridis_c(option = "D", guide = "none") +
    scale_color_manual(values = c("black", "white"), guide = "none") +
    labs(
      title = "Nota (total ponderada final) media del procedimiento por isla de tribunal y especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
        "* Las especialidades están ordenadas alfabéticamente",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_family = "Roboto") +
    theme(
      plot.margin = margin(t = 40, r = 20, b = 40, l = -250),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30, r = -250), color = "gray40"),
      panel.grid = element_blank()
    )

# ==============================================================================
# Número de aspirantes seleccionados por isla de tribunal y especialidad
# ==============================================================================
df |>
  mutate(
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min, .desc = TRUE)
  ) |>
  group_by(isla_tribunal, especialidad_c) |>
  summarize(
    seleccionados = sum(seleccionado)
  ) |>
  ungroup() |>
  mutate(
    media_seleccionados = mean(seleccionados)
  ) |>
  ggplot(aes(x = isla_tribunal, y = especialidad_c, fill = seleccionados)) +
    geom_tile() +
    coord_fixed(ratio = 0.2) +
    geom_text(aes(label = seleccionados, color = seleccionados < media_seleccionados), size = 3) +
    scale_fill_viridis_c(option = "D", guide = "none") +
    scale_color_manual(values = c("black", "white"), guide = "none") +
    labs(
      title = "Número de aspirantes seleccionados por isla de tribunal y especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
        "* Las especialidades están ordenadas alfabéticamente",
        "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
        sep = "\n"
      ),
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_family = "Roboto") +
    theme(
      plot.margin = margin(t = 40, r = 20, b = 40, l = -200),
      plot.title = element_text(size = 16, face = "bold", color = "gray20"),
      plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
      plot.caption = element_text(margin = margin(t = 30, r = -200), color = "gray40"),
      panel.grid = element_blank()
    )

# ==============================================================================
# Número de plazas asignadas sobre el número de plazas ofertadas por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    plazas_ofertadas = first(plazas),
    plazas_asignadas = sum(seleccionado),
    porcentaje_asignadas = plazas_asignadas / plazas_ofertadas * 100
  ) |>
  pivot_longer(cols = c(plazas_asignadas, plazas_ofertadas)) |>
  mutate(
    name = factor(name, levels = c("plazas_ofertadas", "plazas_asignadas")),
    especialidad_c = fct_reorder(especialidad_c, as.character(especialidad_c), .fun = min, .desc = TRUE)
  ) |>
  arrange(name) |>
  ggplot(aes(x = especialidad_c, y = value, fill = name)) +
  geom_col(position = position_identity()) +
  geom_text(
    data = \(.) . |> filter(name == "plazas_ofertadas"),
    aes(label = sprintf("%0.2f%%", porcentaje_asignadas)),
    size = 2.5,
    family = "Roboto",
    hjust = -0.2,
    alpha = 0.7
  ) +
  coord_flip() +
  scale_fill_manual(
    values = c("plazas_ofertadas" = "orchid4", "plazas_asignadas" = "aquamarine3"),
    labels = c("plazas_ofertadas" = "Plazas ofertadas", "plazas_asignadas" = "Plazas asignadas"),
    name = NULL
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Número de plazas asignadas sobre el número de plazas ofertadas por especialidad",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
      "* Las especialidades están ordenadas alfabéticamente",
      "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      sep = "\n"
    ),
    x = NULL, y = NULL
  ) +
  theme_minimal(base_family = "Roboto") +
  theme(
    plot.margin = margin(t = 40, r = 20, b = 40, l = 20),
    plot.title = element_text(size = 16, face = "bold", color = "gray20"),
    plot.subtitle = element_text(size = 14, color = "gray30", margin = margin(b = 20)),
    plot.caption = element_text(margin = margin(t = 30), color = "gray40"),
    panel.grid.major.y = element_blank(),
  )
  
# ==============================================================================
# Fechas de publicación de la asignación de plazas por especialidad
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
      title = "Fechas de publicación de la asignación de plazas por especialidad",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* Se están teniendo en cuenta tribunales tanto con sistema ingreso como con sistema acceso",
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
