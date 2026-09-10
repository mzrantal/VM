# Lataa oikeat panos-tuotos-tiedot Tilastokeskuksen PxWeb-CSV-vienneista.
#
# Kaksi tiedostoa data/-kansiosta:
#
#   data/panoskertoimet_14yq.csv
#     Taulukko 14yq "Tuotoksen panoskertoimet" - toimialoittainen (63
#     toimialaa) tekninen kerroinmatriisi A: A[i,j] = kuinka monta euroa
#     toimialan i tuotantoa tarvitaan yhta euroa kohti toimialan j
#     tuotosta (KOTIMAINEN, kayttajan vahvistama). Sisaltaa myos
#     lisarivin "B1GPH Bruttoarvonlisays perushintaan", joka antaa VALMIIN
#     arvonlisays/tuotos-kertoimen suoraan (ei tarvitse laskea itse).
#
#   data/kayttotaulukko_14yn.csv
#     Taulukko 14yn "Panos-tuotostaulukko perushintaan" - kaytetaan tasta
#     vain kahta riv­ia: "P1R Tuotos perushintaan" (toimialan tuotos,
#     milj. e) ja "E1 Tyolliset, kotimaa (1000 henkea)" (tyollisyys),
#     joista lasketaan tyollisyyskerroin (tyollisia / milj. e tuotosta).
#
# Molemmat tiedostot ovat PxWeb:n vakiomuotoista CSV-vientia: rivi 1 =
# taulukon otsikko, rivi 2 tyhja, rivi 3 = otsikkorivi, rivi 4+ = data.
# Erotin ";", desimaalipiste ".", puuttuva arvo ".".

vuoden_data_oletus <- "2023"

#' Lukee yhden PxWeb-CSV-vienti-tiedoston data.frameksi (ohittaa taulukon
#' otsikon ja tyhjan rivin, ja siivoaa mahdollisen UTF-8 BOM-merkin, jonka
#' PxWeb:n vienti lisaa tiedoston alkuun ja joka muuten rikkoo ensimmaisen
#' sarakkeen (Vuosi) nimen luvun).
lue_pxweb_csv <- function(polku) {
  rivit <- readLines(polku, encoding = "UTF-8", warn = FALSE)
  rivit[1] <- gsub("^\xef\xbb\xbf", "", rivit[1], useBytes = TRUE)
  read.csv(
    text = rivit[-(1:2)], sep = ";", header = TRUE, check.names = FALSE,
    na.strings = ".", stringsAsFactors = FALSE
  )
}

#' Lataa toimialoittaisen teknisen kerroinmatriisin A (63x63) ja siihen
#' liittyvan arvonlisayskertoimen (B1GPH-rivi) taulukosta 14yq.
#'
#' @return list(A = kerroinmatriisi, va_kertoimet = arvonlisayskertoimet,
#'   toimialat = toimialakoodien/-nimien vektori samassa jarjestyksessa
#'   kuin A:n rivit/sarakkeet)
lataa_panoskertoimet <- function(polku, vuosi = vuoden_data_oletus) {
  df <- lue_pxweb_csv(polku)
  toimiala_sarake <- names(df)[2]
  df <- df[df$Vuosi == vuosi, ]

  # Toimialasarakkeet = kaikki sarakkeet paitsi Vuosi/Toimiala/Tiedot/Yhteensä.
  # "Yhteensä" tunnistetaan ASCII-alkuosalla ("Yhteens"), ei koko nimella -
  # ks. huomautus C-lokaalin merkkijonovertailun rajoituksesta alempana.
  kaikki_sarakkeet <- names(df)
  ei_toimiala <- (kaikki_sarakkeet %in% c("Vuosi", toimiala_sarake, "Tiedot")) |
    grepl("^Yhteens", kaikki_sarakkeet, useBytes = TRUE)
  toimialat <- kaikki_sarakkeet[!ei_toimiala]

  # HUOM enkoodauksesta: taman istunnon R-ajoymparisto on C-lokaalissa,
  # jossa merkkijonojen ==-vertailu skandimerkkien (ä/ö) kanssa ei toimi
  # luotettavasti kasin kirjoitetun (tuntematon enkoodaus) ja CSV:sta
  # luetun (UTF-8-merkitty) merkkijonon valilla, vaikka tavut olisivat
  # identtiset. Siksi rivihaku tehdaan grepl(..., fixed=TRUE, useBytes=TRUE)
  # -tavuvertailulla pelkan ASCII-alkuosan (esim. "B1GPH") perusteella -
  # tama toimii aina, riippumatta lokaalista.
  hae_rivi <- function(ascii_alkuosa) {
    osuma <- grepl(ascii_alkuosa, df[[toimiala_sarake]], fixed = TRUE, useBytes = TRUE)
    if (sum(osuma) != 1) {
      stop(sprintf(
        "panoskertoimet_14yq.csv: riviä, joka alkaa '%s', ei löytynyt (tai löytyi useita) vuodelle %s.",
        ascii_alkuosa, vuosi
      ))
    }
    arvot <- as.numeric(df[osuma, toimialat])
    arvot[is.na(arvot)] <- 0
    setNames(arvot, toimialat)
  }

  va_kertoimet <- hae_rivi("B1GPH")

  # A[i, j] = toimialan i (rivi) tuotoksen tarve toimialan j (sarake) yhta
  # tuotosyksikkoa kohti - CSV:ssa rivi "i" antaa taman koko sarakevektorin
  # (arvot j:n mukaan), joten se asetetaan A:n RIVILLE i, ei sarakkeelle.
  # Rivin tunnistus toimialan NIMELLA (ei ASCII-alkuosalla) toimii tassa
  # ongelmitta, koska seka rivinimi etta "toimiala"-silmukan arvo tulevat
  # samasta CSV-lukupolusta (molemmat UTF-8-merkittyja) - ks. testi, joka
  # vahvisti taman tassa istunnossa.
  A <- matrix(0, nrow = length(toimialat), ncol = length(toimialat), dimnames = list(toimialat, toimialat))
  for (toimiala in toimialat) {
    rivi <- df[df[[toimiala_sarake]] == toimiala, ]
    if (nrow(rivi) != 1) {
      stop(sprintf("panoskertoimet_14yq.csv: toimialan '%s' riviä ei löytynyt yksiselitteisesti.", toimiala))
    }
    arvot <- as.numeric(rivi[1, toimialat])
    arvot[is.na(arvot)] <- 0
    A[toimiala, ] <- arvot
  }

  list(A = A, va_kertoimet = va_kertoimet, toimialat = toimialat)
}

#' Lataa toimialoittaisen tuotoksen (P1R) ja tyollisyyden (E1) taulukosta
#' 14yn, samassa toimialajarjestyksessa kuin annettu `toimialat`-vektori,
#' ja laskee niista tyollisyyskertoimen (tyollisia / milj. e tuotosta).
lataa_tyollisyyskertoimet <- function(polku, toimialat, vuosi = vuoden_data_oletus) {
  df <- lue_pxweb_csv(polku)
  toimiala_sarake <- names(df)[2]
  df <- df[df$Vuosi == vuosi, ]

  # Ks. lataa_panoskertoimet():n huomautus C-lokaalin merkkijonovertailun
  # rajoituksesta - siksi haku ASCII-alkuosalla (fixed/useBytes-tavuhaku).
  hae_rivi_arvot <- function(ascii_alkuosa) {
    osuma <- grepl(ascii_alkuosa, df[[toimiala_sarake]], fixed = TRUE, useBytes = TRUE)
    if (sum(osuma) != 1) {
      stop(sprintf(
        "kayttotaulukko_14yn.csv: riviä, joka alkaa '%s', ei löytynyt (tai löytyi useita) vuodelle %s.",
        ascii_alkuosa, vuosi
      ))
    }
    rivi <- df[osuma, ]
    puuttuu <- setdiff(toimialat, names(rivi))
    if (length(puuttuu) > 0) {
      stop(sprintf(
        "kayttotaulukko_14yn.csv: toimialasarakkeita ei löydy: %s",
        paste(puuttuu, collapse = ", ")
      ))
    }
    arvot <- as.numeric(rivi[1, toimialat])
    setNames(arvot, toimialat)
  }

  tuotos_milj_e <- hae_rivi_arvot("P1R")
  tyolliset_1000hlo <- hae_rivi_arvot("E1 ")

  # Tuotos ("Tiedot" = "Käypiin hintoihin, miljoonaa euroa") on miljoonina
  # euroina, tyolliset tuhansina henkilina - muunnetaan molemmat perus-
  # yksikoihin (henkiloa / euro), jotta kerroin toimii yhteen A-matriisin
  # (ja sita kayttavan kysyntashokkivektorin, joka on RAAOISSA euroissa)
  # kanssa samassa mittakaavassa.
  kerroin <- (tyolliset_1000hlo * 1000) / (tuotos_milj_e * 1e6)
  # Osalla toimialoista (esim. asuntojen imputoitu vuokra-arvo) ei ole
  # todellista tyollisyytta - Tilastokeskus merkitsee taman puuttuvaksi
  # (.), ei nollaksi. Tulkitaan puuttuva = 0 tyollisyyskerroin.
  kerroin[is.na(kerroin)] <- 0
  kerroin
}

#' TRUE jos molemmat tarvittavat CSV-tiedostot löytyvät data_kansio:sta.
oikea_data_saatavilla <- function(data_kansio) {
  file.exists(file.path(data_kansio, "panoskertoimet_14yq.csv")) &&
    file.exists(file.path(data_kansio, "kayttotaulukko_14yn.csv"))
}

#' Lataa koko oikean mallin (A-matriisi, arvonlisays- ja
#' tyollisyyskertoimet) molemmista tiedostoista.
lataa_oikea_malli <- function(data_kansio, vuosi = vuoden_data_oletus) {
  pk <- lataa_panoskertoimet(file.path(data_kansio, "panoskertoimet_14yq.csv"), vuosi)
  tyollisyys_kertoimet <- lataa_tyollisyyskertoimet(
    file.path(data_kansio, "kayttotaulukko_14yn.csv"), pk$toimialat, vuosi
  )
  list(
    A = pk$A,
    toimialat = pk$toimialat,
    va_kertoimet = pk$va_kertoimet,
    tyollisyys_kertoimet = tyollisyys_kertoimet
  )
}

#' Rakentaa kysyntashokkivektorin 14yq/14yn:n toimialaluokituksessa
#' (pituus = length(kaikki_toimialat)) omien toimialaryhmiemme (esim.
#' TOIMIALAOSUUDET * investointi_vuonna) pohjalta, TOIMIALA_KOODIT_14Y
#' -vastaavuuden avulla (oletukset.R). Useampi oma toimialaryhma voi
#' osua samaan taulukon toimialaan (esim. kaikki kolme rakennusryhmaamme
#' -> "F Rakentaminen (41-43)") - niiden shokit summautuvat.
rakenna_kysyntavektori <- function(kaikki_toimialat, oma_shokki) {
  d <- setNames(numeric(length(kaikki_toimialat)), kaikki_toimialat)
  for (oma_toimiala in names(oma_shokki)) {
    koodi <- TOIMIALA_KOODIT_14Y[[oma_toimiala]]
    # Haku ASCII-koodin (esim. "F", "26") alkuosalla valilyonnilla - ks.
    # lataa_panoskertoimet():n huomautus C-lokaalin merkkijonovertailusta.
    osuma <- grepl(paste0("^", koodi, " "), kaikki_toimialat, useBytes = TRUE)
    if (is.null(koodi) || sum(osuma) != 1) {
      stop(sprintf(
        "Toimialaa '%s' vastaavaa taulukon toimialaa (koodi '%s') ei löydy yksiselitteisesti - tarkista TOIMIALA_KOODIT_14Y oletukset.R:ssa.",
        oma_toimiala, koodi
      ))
    }
    kohde <- kaikki_toimialat[osuma]
    d[[kohde]] <- d[[kohde]] + oma_shokki[[oma_toimiala]]
  }
  d
}
