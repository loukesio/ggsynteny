##############################
#create data 
###############################


# Generate non-overlapping gene rectangles
rectangles <- data.frame(
  species = rep(species_list, gene_counts),
  id = paste0("gene", seq(sum(gene_counts))),
  y = rep(species_y_positions, gene_counts)
) %>%
  group_by(species) %>%
  mutate(
    gene_index = row_number(),  # Assign each gene an index within the species
    xmin = (gene_index - 1) * 7 + 2,  # Distribute genes evenly along x-axis
    xmax = xmin + 5  # Keep all genes the same width
  ) %>%
  ungroup()

rectangles

generate_connections <- function(rectangles) {
  connections <- data.frame(
    source_id = c("gene1", "gene2", "gene4", "gene7", "gene6", "gene11", "gene12", "gene15", "gene17"),  # Source genes
    target_id = c("gene5", "gene9", "gene13", "gene8", "gene10", "gene14", "gene16", "gene2", "gene3")   # Target genes
  )
  
  # Merge x-coordinates and y-coordinates dynamically
  connections <- connections %>%
    left_join(rectangles %>% select(id, y, xmin, xmax, species), by = c("source_id" = "id")) %>%
    rename(source_y = y, source_xstart = xmin, source_xend = xmax, source_species = species) %>%
    left_join(rectangles %>% select(id, y, xmin, xmax, species), by = c("target_id" = "id")) %>%
    rename(target_y = y, target_xstart = xmin, target_xend = xmax, target_species = species)
  
  return(connections)
}

connections <- 
  generate_connections(rectangles) %>% 
  dplyr::relocate(source_species, target_species) %>% 
  add_row(source_species="Human", target_species="Pigs", source_id="gene1", target_id="gene4", 
          source_y=0, source_xstart=3, source_xend=3,target_y=60,target_xstart=17,target_xend=17) %>% 
  add_row(source_species="Human", target_species="Plants", source_id="gene1", target_id="gene4", 
          source_y=0, source_xstart=2, source_xend=4,target_y=60,target_xstart=10,target_xend=12)



connections


##########################################
#
# Function
#
############################################

bezier_curve <- function(x0, y0, x1, y1, curvature = 0.65, n = 100) {
  # Control points for cubic Bezier curve
  yi <- seq(y0, y1, length.out = n)
  y2 <- y0 + curvature * (y1 - y0)
  y3 <- y1 - curvature * (y1 - y0)
  
  # Generate curve points
  t <- seq(0, 1, length.out = n)
  bx <- (1 - t)^3 * x0 + 3 * (1 - t)^2 * t * x0 + 3 * (1 - t) * t^2 * x1 + t^3 * x1
  by <- (1 - t)^3 * y0 + 3 * (1 - t)^2 * t * y2 + 3 * (1 - t) * t^2 * y3 + t^3 * y1
  
  data.frame(x = bx, y = by)
}

polygon_connection <- function(source_xstart, source_xend, source_y, 
                               target_xstart, target_xend, target_y, curvature = 0.65, n = 100) {
  # Top curve (source to target)
  top_curve <- bezier_curve(source_xstart, source_y, target_xstart, target_y, curvature, n)
  
  # Bottom curve (source to target)
  bottom_curve <- bezier_curve(source_xend, source_y, target_xend, target_y, curvature, n)
  
  # Combine top and bottom curves into a polygon
  data.frame(
    x = c(top_curve$x, rev(bottom_curve$x)),
    y = c(top_curve$y, rev(bottom_curve$y))
  )
}


# Define y-axis labels mapping
species_labels <- c("Human", "Mouse", "Plants", "Pigs")  # Labels
names(species_labels) <- c(0, 20, 40, 60)  # Corresponding y-values
species_labels
species_labels






plot_synteny <- function(rectangles, connections, curvature = 0.65, n = 100) {
  library(ggplot2)
  
  # Process connections
  connection_areas <- data.frame()
  connection_lines <- data.frame()
  
  for (i in seq_len(nrow(connections))) {
    conn <- connections[i, ]
    
    if (conn$source_xstart == conn$source_xend && conn$target_xstart == conn$target_xend) {
      # Single-point connection (curved line)
      curve <- bezier_curve(conn$source_xstart, conn$source_y, conn$target_xstart, conn$target_y, curvature, n)
      curve$target_species <- conn$target_species
      connection_lines <- rbind(connection_lines, curve)
    } else {
      # Area connection (polygon)
      poly <- polygon_connection(conn$source_xstart, conn$source_xend, conn$source_y, 
                                 conn$target_xstart, conn$target_xend, conn$target_y, curvature, n)
      poly$target_species <- conn$target_species
      connection_areas <- rbind(connection_areas, poly)
    }
  }
  
  # Create base plot
  p <- ggplot()
  
  # Add connections (lines and areas) first
  if (nrow(connection_areas) > 0) {
    p <- p + geom_polygon(data = connection_areas, aes(x = x, y = y, fill = target_species), alpha = 0.3)
  }
  
  if (nrow(connection_lines) > 0) {
    p <- p + geom_path(data = connection_lines, aes(x = x, y = y, color = target_species), linewidth = 0.5)
  }
  
  # Add rectangles (genes) on top
  p <- p + geom_rect(data = rectangles,
                     aes(xmin = xmin, xmax = xmax, ymin = y - 1, ymax = y + 1, fill = species),
                     color = NA, alpha = 1) +
    scale_y_continuous(breaks = as.numeric(names(species_labels)), labels = species_labels) +
    scale_fill_manual(values = c("Human" = "#1a5b5b", "Mouse" = "#acc8be", "Plants" = "#f4ab5c", "Pigs" = "#d1422f")) +
    scale_color_manual(values = c("Human" = "#1a5b5b", "Mouse" = "#acc8be", "Plants" = "#f4ab5c", "Pigs" = "#d1422f")) +
    coord_cartesian(ylim = c(-10, max(rectangles$y) + 10), xlim = c(0, max(rectangles$xmax) + 10)) +
    theme_minimal() +
    theme(text=element_text(family = "Avenir")
          ,panel.grid = element_blank()) +
    labs(y = "Species", x = "Genomic Position", fill = "Species Type") +
    theme(legend.position = "none") +
    labs(title = "Synteny Plot",
         subtitle = "Connections by target species",
         fill = "Species",
         color = "Target Species")
  
  return(p)

}

connections <- 
connections %>% 
  slice_tail(n=5)

p <- plot_synteny(rectangles, connections, curvature = 0.65, n = 300) +
  theme(
    panel.background = element_rect(fill = "black", color = NA),  # Set panel background to black
    plot.background = element_rect(fill = "black", color = NA),  # Set entire plot background to black
    panel.grid = element_blank(),  # Remove all grid lines
    axis.text = element_text(color = "white"),  # White axis text for contrast
    axis.title = element_text(color = "white"),  # White axis titles
    axis.ticks = element_blank()  # White axis ticks
  ) +
  labs(y=NULL)

print(p)
