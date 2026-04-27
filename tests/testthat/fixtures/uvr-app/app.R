library(shiny)
ui <- fluidPage(
  titlePanel("uvr POC"),
  textOutput("msg")
)
server <- function(input, output, session) {
  output$msg <- renderText("Hello from a uvr-built shiny container.")
}
shinyApp(ui, server)
