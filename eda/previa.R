library(tidyverse)

DATA_PATH <- "../data/boards.csv"

# ==============================================================================
# Carga de datos
# ==============================================================================
df <- read_csv(DATA_PATH) |>
  transmute(
    proceso = as_factor(Proceso),
    cuerpo = as_factor(Cuerpo),
    especialidad = as_factor(Especialidad),
    especialidad_c = as_factor(case_when(
      cuerpo == "Cuerpo de Maestros" ~ paste(especialidad, "(P)"),
      TRUE ~ paste(especialidad, "(S)")
    )),
    tribunal = Tribunal,
    plazas = `Plazas de ingreso`
  )
  
# ==============================================================================
# Número de tribunales por especialidad e isla
# ==============================================================================
df |>
  mutate(
    isla_tribunal = factor(case_when(
      str_detect(tribunal, "TF") ~ "Tenerife",
      str_detect(tribunal, "GC") ~ "Gran Canaria",
      str_detect(tribunal, "LZ") ~ "Lanzarote",
      str_detect(tribunal, "LP") ~ "La Palma",
      str_detect(tribunal, "FU") ~ "Fuerteventura",
      str_detect(tribunal, "GO") ~ "La Gomera",
      str_detect(tribunal, "HI") ~ "El Hierro",
      TRUE ~ "Desconocida"
    ), levels = c(
      "Tenerife", "Gran Canaria", "Lanzarote", "Fuerteventura",
      "La Palma", "La Gomera", "El Hierro", "Desconocida"
    )),
    .after = "tribunal"
  ) |>
  group_by(especialidad_c, isla_tribunal) |>
  summarize(
    num_tribunales = n_distinct(tribunal)
  ) |>
  group_by(especialidad_c) |>
  mutate(
    total_tribunales = sum(num_tribunales)
  ) |>
  ungroup() |>
  arrange(total_tribunales, desc(as.character(especialidad_c))) |>
  mutate(
    fila = row_number(),
  ) |>
  ggplot(
    aes(
      x =  fct_reorder(especialidad_c, fila),
      y = num_tribunales,
      fill = isla_tribunal)
  ) +
  geom_col(position = position_stack(reverse = T)) +
  coord_flip() +
  geom_text(
    aes(label = num_tribunales),
    size = 2.5,
    position = position_stack(vjust = 0.5, reverse = T)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_ramp_discrete() +
  labs(
    title = "Número de tribunales por especialidad e isla",
    subtitle = "Oposiciones del profesorado 2025",
    caption = paste(
      "* (P) = Primaria; (S) = Secundaria",
      "* No se están teniendo en cuenta tribunales con sistema acceso",
      "© Sergio Delgado Quintero | Datos publicados por la Consejería de Educación del Gobierno de Canarias",
      sep = "\n"
    ),
    fill = NULL, x = NULL, y = NULL
  ) +
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
# Número de plazas por especialidad
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    plazas = first(plazas)
  ) |>
  ungroup() |>
  arrange(plazas, desc(as.character(especialidad_c))) |>
  mutate(
    fila = row_number(),
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, fila), y = plazas, fill = plazas)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = plazas), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Número de plazas por especialidad",
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
# Número medio de plazas por tribunal
# ==============================================================================
df |>
  group_by(especialidad_c) |>
  summarize(
    media_plazas = round(first(plazas) / n_distinct(tribunal))
  ) |>
  ungroup() |>
  arrange(media_plazas, desc(as.character(especialidad_c))) |>
  mutate(
    fila = row_number(),
  ) |>
  ggplot(aes(x = fct_reorder(especialidad_c, fila), y = media_plazas, fill = media_plazas)) +
    geom_col() +
    coord_flip() +
    geom_label(aes(label = media_plazas), size = 2.5, hjust = 1.2, fill = "white", alpha = 0.6) +
    scale_fill_viridis_c() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = "Número medio de plazas por tribunal",
      subtitle = "Oposiciones del profesorado 2025",
      caption = paste(
        "* (P) = Primaria; (S) = Secundaria",
        "* No se están teniendo en cuenta tribunales con sistema acceso",
        "* Se está aplicando un redondeo a la cifra decimal de plazas",
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

