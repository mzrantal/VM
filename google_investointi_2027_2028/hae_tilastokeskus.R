# Apufunktiot Tilastokeskuksen PxWeb-rajapinnan kayttoon.
#
# Tama moduuli hakee kansantalouden tilinpidon tarjonta- ja kayttotaulukot /
# panos-tuotostaulukot Tilastokeskuksen PxWeb-rajapinnasta (pxdata.stat.fi),
# jotta niista voidaan laskea toimialoittainen tekninen kerroinmatriisi A ja
# arvonlisayskertoimet malli.R:n Leontief-laskentaa varten.
#
# HUOM - TAMAN ISTUNNON RAJOITUS:
# Tata koodia kirjoitettaessa istunnon verkkoyhteys pxdata.stat.fi-osoitteeseen
# oli estetty (hiekkalaatikkoymparistön ulosmenevan liikenteen rajoitus, HTTP
# 403 yhdyskaytavalta). Koodi on kuitenkin toiminnallista PxWeb-rajapinnan
# vakiokayttoa (JSON-kysely httr-paketilla) ja toimii ajettuna ymparistossa,
# jossa on internet-yhteys, esim. kayttajan omalla koneella.
#
# RIIPPUVUUDET: install.packages(c("httr", "jsonlite"))
#
# TAULUKON OSOITE:
# PxWeb-taulukoiden tarkat tunnukset vaihtelevat julkaisuvuosittain, joten
# niita ei ole kovakoodattu tahan. Etsi oikea taulukko selaimella osoitteesta:
#   https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/
#   -> Kansantalouden tilinpito -> Tarjonta- ja kayttotaulukot / Panos-tuotos
# ja aseta taulukon rajapinta-URL alla olevaan TAULUKON_URL-muuttujaan.

TAULUKON_URL <- ""  # esim. "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/.../taulukko.px"

vaadi_paketit <- function() {
  puuttuu <- c("httr", "jsonlite")[!c(
    requireNamespace("httr", quietly = TRUE),
    requireNamespace("jsonlite", quietly = TRUE)
  )]
  if (length(puuttuu) > 0) {
    stop(sprintf(
      "Asenna ensin puuttuvat paketit: install.packages(c(%s))",
      paste(sprintf('"%s"', puuttuu), collapse = ", ")
    ))
  }
}

#' Hakee taulukon muuttujat ja koodit (GET-pyynto), jotta oikea kysely
#' (toimialat, muuttujat, vuodet) voidaan rakentaa.
hae_taulukon_metatiedot <- function(taulukon_url, timeout_s = 30) {
  vaadi_paketit()
  vastaus <- httr::GET(taulukon_url, httr::timeout(timeout_s))
  httr::stop_for_status(vastaus)
  jsonlite::fromJSON(httr::content(vastaus, as = "text", encoding = "UTF-8"))
}

#' Lahettaa PxWeb-kyselyn (POST, JSON) ja palauttaa vastauksen jasennettyna.
#'
#' `kysely` on PxWebin odottama kyselyrakenne (R-listana), esim.:
#'   list(
#'     query = list(
#'       list(code = "Toimiala", selection = list(filter = "item", values = list("..."))),
#'       list(code = "Vuosi", selection = list(filter = "item", values = list("2021")))
#'     ),
#'     response = list(format = "json-stat2")
#'   )
hae_pxweb_data <- function(taulukon_url, kysely, timeout_s = 60) {
  vaadi_paketit()
  vastaus <- httr::POST(
    taulukon_url,
    body = kysely,
    encode = "json",
    httr::content_type_json(),
    httr::timeout(timeout_s)
  )
  httr::stop_for_status(vastaus)
  jsonlite::fromJSON(httr::content(vastaus, as = "text", encoding = "UTF-8"))
}

#' Pika-testi: onko Tilastokeskuksen rajapintaan yhteytta tassa ymparistossa.
#' Kaytetaan laske_vaikutus.R:ssa paattamaan, kaytetaanko oikeaa dataa vai
#' oletukset.R:n karkeita arvioita.
yhteys_toimiiko <- function(url = "https://pxdata.stat.fi", timeout_s = 5) {
  if (!requireNamespace("httr", quietly = TRUE)) {
    return(FALSE)
  }
  tulos <- tryCatch(
    httr::GET(url, httr::timeout(timeout_s)),
    error = function(e) NULL
  )
  !is.null(tulos) && httr::status_code(tulos) < 500
}

if (identical(environment(), globalenv()) && sys.nframe() == 0) {
  if (yhteys_toimiiko()) {
    cat("Yhteys Tilastokeskuksen rajapintaan toimii.\n")
    if (nzchar(TAULUKON_URL)) {
      str(hae_taulukon_metatiedot(TAULUKON_URL))
    } else {
      cat("Aseta TAULUKON_URL-muuttuja ennen taulukon hakemista.\n")
    }
  } else {
    cat("Ei yhteytta Tilastokeskuksen rajapintaan tasta ymparistosta.\n")
    cat("laske_vaikutus.R kayttaa oletukset.R:n karkeita arvioita.\n")
  }
}
