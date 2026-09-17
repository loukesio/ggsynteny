# The manifest pins ggsynteny and its dependencies for the hosted Studio.
library(shiny)
library(ggiraph)
library(ggsynteny)

source(system.file("shiny", "app.R", package = "ggsynteny"), local = TRUE)$value
