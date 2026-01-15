# 1. Instalacja pakietów 
# install.packages(c("shiny", "tidyverse", "DT", "bslib", "bsicons", "stringr"))

library(shiny)
library(tidyverse)
library(DT)       # Do tabel
library(bslib)    # Do ładnego wyglądu (dashboard)
library(bsicons)  # Do ikonek w kafelkach
library(stringr)  # Do obsługi tekstów

# 2. Wczytanie danych
# Upewnij się, że plik instagram_pjm_data.csv jest w tym samym folderze!
df <- read.csv("instagram_pjm_data.csv", stringsAsFactors = FALSE)
df$date <- as.Date(df$date) # Konwersja daty

# 3. Interfejs Użytkownika (UI)
ui <- page_sidebar(
  title = "Narzędzie do analizy sieci PJM na Instagramie",
  theme = bs_theme(bootswatch = "lux", primary = "#C13584"), # Kolory w stylu Instagrama
  
  # Panel boczny (Filtry)
  sidebar = sidebar(
    h5("Panel sterowania"),
    selectInput("user_select", "Wybierz konto:", 
                choices = c("Wszyscy", unique(df$username))),
    
    dateRangeInput("date_range", "Zakres dat:",
                   start = min(df$date), 
                   end = max(df$date),
                   language = "pl"), # Polski kalendarz
    
    hr(),
    helpText("Analiza sieci influencerskich w Polskim Języku Migowym."),
    markdown("
    **Metryki:**
    * **ER (Engagement Rate):** Zaangażowanie odbiorców.
    * **Hashtagi:** Tematyka dyskusji.
    ")
  ),
  
  # Główna część (Dashboard)
  layout_columns(
    # Kafelki z liczbami (Value Boxes)
    value_box(
      title = "Średnia liczba lajków",
      value = textOutput("avg_likes"),
      showcase = bs_icon("heart-fill"),
      theme = "danger" # Czerwony
    ),
    value_box(
      title = "Średni Engagement Rate",
      value = textOutput("avg_er"),
      showcase = bs_icon("graph-up"),
      theme = "purple" # Fioletowy
    ),
    value_box(
      title = "Analizowane posty",
      value = textOutput("total_posts"),
      showcase = bs_icon("camera-fill"),
      theme = "info" # Niebieski
    )
  ),
  
  # Zakładki z analizami
  navset_card_underline(
    title = "Szczegóły analizy",
    
    # Zakładka 1: Wykresy czasowe i relacji
    nav_panel("Zaangażowanie (Engagement)", 
              layout_columns(
                card(
                  card_header("Popularność w czasie (Lajki)"),
                  plotOutput("time_plot")
                ),
                card(
                  card_header("Relacja: Lajki vs Komentarze"),
                  plotOutput("scatter_plot")
                )
              )
    ),
    
    # Zakładka 2: Hashtagi
    nav_panel("Analiza Tematyki (Hashtagi)",
              card(
                card_header("Najczęściej poruszane tematy"),
                plotOutput("hashtag_plot"),
                card_footer("Wykres pokazuje top 15 hashtagów w wybranym okresie.")
              )
    ),
    
    # Zakładka 3: Tabela danych
    nav_panel("Baza Postów (Dane)", 
              DTOutput("raw_table")
    )
  )
)

# 4. Serwer 
server <- function(input, output, session) {
  
  # Reaktywne filtrowanie danych (działa na wszystko poniżej)
  filtered_data <- reactive({
    req(input$date_range)
    
    data <- df %>%
      filter(date >= input$date_range[1] & date <= input$date_range[2])
    
    if (input$user_select != "Wszyscy") {
      data <- data %>% filter(username == input$user_select)
    }
    data
  })
  
  # Obliczenia do kafelków (Value Boxes)
  output$avg_likes <- renderText({
    d <- filtered_data()
    if(nrow(d) == 0) return("0")
    round(mean(d$likes_count), 0)
  })
  
  output$avg_er <- renderText({
    d <- filtered_data()
    if(nrow(d) == 0) return("0%")
    paste0(round(mean(d$engagement_rate), 2), "%")
  })
  
  output$total_posts <- renderText({
    nrow(filtered_data())
  })
  
  # Wykres 1: Czasowy
  output$time_plot <- renderPlot({
    d <- filtered_data()
    validate(need(nrow(d) > 0, "Brak danych dla wybranych filtrów."))
    
    ggplot(d, aes(x = date, y = likes_count, color = username)) +
      geom_line(size = 1, alpha = 0.7) +
      geom_point(size = 2) +
      theme_minimal() +
      labs(x = "Data", y = "Liczba polubień") +
      theme(legend.position = "bottom") +
      scale_color_viridis_d() # Ładna paleta barw
  })
  
  # Wykres 2: Scatter (Punktowy)
  output$scatter_plot <- renderPlot({
    d <- filtered_data()
    validate(need(nrow(d) > 0, "Brak danych."))
    
    ggplot(d, aes(x = likes_count, y = comments_count)) +
      geom_point(aes(color = username), size = 3, alpha = 0.7) +
      geom_smooth(method = "lm", se = FALSE, color = "black", linetype="dashed") +
      theme_minimal() +
      labs(x = "Lajki", y = "Komentarze", 
           title = "Korelacja aktywności")
  })
  
  # Wykres 3: Hashtagi 
  output$hashtag_plot <- renderPlot({
    d <- filtered_data()
    validate(need(nrow(d) > 0, "Brak danych."))
    
    # Rozdzielamy ciągi tekstowe (np. "#PJM #Kultura") na pojedyncze słowa po spacji
    all_tags <- unlist(str_split(d$hashtags, "\\s+"))
    
    # Tworzymy tabelę liczebności
    tags_df <- data.frame(tag = all_tags) %>%
      filter(str_starts(tag, "#")) %>% # Upewniamy się, że to hashtag
      count(tag, sort = TRUE) %>%
      head(15) # Bierzemy tylko Top 15
    
    validate(need(nrow(tags_df) > 0, "Brak hashtagów w tym zakresie."))
    
    # Rysujemy
    ggplot(tags_df, aes(x = reorder(tag, n), y = n)) +
      geom_col(fill = "#833AB4") + # Kolor Instagrama
      coord_flip() + # Obracamy, żeby napisy były czytelne
      theme_minimal() +
      labs(x = "", y = "Liczba wystąpień") +
      theme(axis.text.y = element_text(size = 12, face = "bold"))
  })
  
  # Tabela danych
  output$raw_table <- renderDT({
    filtered_data() %>%
      select(Data=date, Konto=username, Treść=caption, Hashtagi=hashtags, Lajki=likes_count, ER=engagement_rate)
  }, options = list(pageLength = 10, scrollX = TRUE))
}

# 5. Uruchomienie aplikacji
shinyApp(ui, server)
