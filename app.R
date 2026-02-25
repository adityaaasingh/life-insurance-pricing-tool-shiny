library(shiny)
library(ggplot2)
library(dplyr)

# Source all R files automatically
lapply(list.files("R", full.names = TRUE), source)

# Load mortality dataset
mort <- readRDS("data_processed/mortality_ultimate.rds")

ui <- fluidPage(
  titlePanel("Life Insurance Pricing Tool (AGA Life Tables)"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("sex", "Sex", c("Male", "Female")),
      
      selectInput("product", "Policy Type",
                  c("Pure Endowment",
                    "Term Assurance",
                    "Endowment Assurance",
                    "Whole Life Assurance")),
      
      numericInput("age", "Age (20–80)", value = 30, min = 20, max = 80),
      
      uiOutput("term_ui"),
      
      numericInput("B", "Sum Assured", value = 100000),
      sliderInput("i", "Interest Rate", 0, 0.10, 0.05, step = 0.005),
      
      radioButtons("premium_type", "Premium Type",
                   c("Single", "Level")),
      
      conditionalPanel(
        condition = "input.premium_type == 'Level'",
        radioButtons("prem_freq", "Premium Frequency",
                     c("Annual", "Monthly"))
      ),
      
      radioButtons("timing", "Death Benefit Timing",
                   c("EOY", "Immediate")),
      
      selectInput("mort_type", "Mortality Type",
                  c("Ultimate", "Select")),
      
      conditionalPanel(
        condition = "input.mort_type == 'Select'",
        sliderInput("select_years", "Select Period",
                    min = 1, max = 10, value = 2),
        sliderInput("select_factor", "Selection Factor",
                    min = 0.5, max = 1, value = 0.85)
      ),
      
      checkboxInput("use_exp", "Include Expenses", FALSE),
      
      conditionalPanel(
        condition = "input.use_exp == true",
        sliderInput("initial_exp", "Initial Expense",
                    0, 0.5, 0.05),
        sliderInput("renewal_exp", "Renewal Expense",
                    0, 0.5, 0.02),
        sliderInput("claim_exp", "Claim Expense",
                    0, 0.5, 0.01)
      ),
      
      checkboxInput("use_inc", "Include Bonus & Inflation", FALSE),
      
      conditionalPanel(
        condition = "input.use_inc == true",
        sliderInput("bonus", "Bonus Rate",
                    0, 0.5, 0.02),
        sliderInput("inflation", "Inflation Rate",
                    0, 0.10, 0.03)
      )
    ),
    
    mainPanel(
      h3("Premium"),
      verbatimTextOutput("premium_out"),
      
      h3("Reserve Plot"),
      plotOutput("reserve_plot"),
      
      h3("Reserve Table"),
      tableOutput("reserve_table")
    )
  )
)

server <- function(input, output) {
  
  term_val <- reactive({
    if (input$product == "Whole Life Assurance") {
      100 - input$age
    } else {
      input$term
    }
  })
  
  output$term_ui <- renderUI({
    if (input$product == "Whole Life Assurance") {
      helpText("Whole Life: Term automatically set to 100 - age")
    } else {
      numericInput("term", "Term", value = 10, min = 5)
    }
  })
  
  premium_calc <- reactive({
    
    term <- term_val()
    
    initial_exp <- if (input$use_exp) input$initial_exp else 0
    renewal_exp <- if (input$use_exp) input$renewal_exp else 0
    claim_exp   <- if (input$use_exp) input$claim_exp else 0
    
    bonus <- if (input$use_inc) input$bonus else 0
    inflation <- if (input$use_inc) input$inflation else 0
    
    prem_freq <- if (input$premium_type == "Level") input$prem_freq else "Annual"
    
    calc_premium(
      mort = mort,
      product = input$product,
      premium_type = input$premium_type,
      prem_freq = prem_freq,
      x = input$age,
      sex = input$sex,
      term = term,
      i = input$i,
      B = input$B,
      timing = input$timing,
      mort_type = input$mort_type,
      select_years = input$select_years,
      select_factor = input$select_factor,
      initial_exp = initial_exp,
      renewal_exp = renewal_exp,
      claim_exp = claim_exp,
      bonus = bonus,
      inflation = inflation
    )
  })
  
  output$premium_out <- renderText({
    p <- premium_calc()
    
    if (input$premium_type == "Single") {
      paste("Net:", round(p$net,2),
            "\nGross:", round(p$gross,2))
    } else {
      paste("Net:", round(p$net,2),
            "\nGross:", round(p$gross,2))
    }
  })
  
  reserves_calc <- reactive({
    
    term <- term_val()
    
    initial_exp <- if (input$use_exp) input$initial_exp else 0
    renewal_exp <- if (input$use_exp) input$renewal_exp else 0
    claim_exp   <- if (input$use_exp) input$claim_exp else 0
    
    bonus <- if (input$use_inc) input$bonus else 0
    inflation <- if (input$use_inc) input$inflation else 0
    
    prem_freq <- if (input$premium_type == "Level") input$prem_freq else "Annual"
    
    calc_reserves(
      mort = mort,
      product = input$product,
      premium_type = input$premium_type,
      prem_freq = prem_freq,
      x = input$age,
      sex = input$sex,
      term = term,
      i = input$i,
      B = input$B,
      timing = input$timing,
      mort_type = input$mort_type,
      select_years = input$select_years,
      select_factor = input$select_factor,
      initial_exp = initial_exp,
      renewal_exp = renewal_exp,
      claim_exp = claim_exp,
      bonus = bonus,
      inflation = inflation
    )
  })
  
  output$reserve_plot <- renderPlot({
    df <- reserves_calc()
    ggplot(df, aes(x = t, y = V)) +
      geom_line(linewidth = 1) +
      theme_minimal()
  })
  
  output$reserve_table <- renderTable({
    df <- reserves_calc()
    T <- max(df$t)
    df %>% filter(t %in% c(0,1,2,3,T-1,T))
  })
}

shinyApp(ui, server)