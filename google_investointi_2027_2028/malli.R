# Yksinkertainen panos-tuotos (Leontief) -laskentamoottori.
#
# Kayttotarkoitus: kun toimialoittainen tekninen kerroinmatriisi A (vain
# kotimaiset, tuonnista puhdistetut valituotepanokset) ja toimialoittaiset
# arvonlisayskertoimet on saatu Tilastokeskuksen tarjonta- ja
# kayttotaulukoista (ks. hae_tilastokeskus.R), tama moduuli ratkaisee
# kokonaistuotannon ja siita lasketun BKT (arvonlisays) -vaikutuksen
# annetulle kysyntashokkivektorille.
#
# Kayttaa base R:n solve()-funktiota lineaariyhtaloryhman ratkaisuun -
# ei tarvitse ulkoisia paketteja.

#' Kokonaistuotanto x = (I - A)^-1 %*% d
#'
#' @param A Toimialoittainen tekninen kerroinmatriisi (n x n)
#' @param kysynta Kysyntashokkivektori (pituus n)
#' @return Kokonaistuotantovektori (pituus n)
leontief_tuotanto <- function(A, kysynta) {
  n <- length(kysynta)
  if (!all(dim(A) == c(n, n))) {
    stop("A:n tulee olla n x n -matriisi, jossa n = kysynta-vektorin pituus.")
  }
  I <- diag(n)
  as.numeric(solve(I - A, kysynta))
}

#' BKT (arvonlisays) -vaikutus = arvonlisayskertoimet . x
#'
#' @param A Toimialoittainen tekninen kerroinmatriisi (n x n)
#' @param arvonlisays_kertoimet Arvonlisayskertoimet toimialoittain (pituus n)
#' @param kysynta Kysyntashokkivektori (pituus n)
#' @return list(bkt = kokonais-BKT-vaikutus, tuotanto = toimialoittainen
#'   kokonaistuotanto)
arvonlisays_vaikutus <- function(A, arvonlisays_kertoimet, kysynta) {
  x <- leontief_tuotanto(A, kysynta)
  bkt <- sum(arvonlisays_kertoimet * x)
  list(bkt = bkt, tuotanto = x)
}

#' BKT-vaikutus valmiiksi lasketulla Leontiefin kaanteismatriisilla.
#'
#' Kayta tata (etka arvonlisays_vaikutus()-funktiota), kun Tilastokeskuksesta
#' on haettu valmis kaanteismatriisi (I-A)^-1 (esim. taulukko 14yq,
#' "Leontiefin kaanteismatriisi", joka on Tilastokeskuksen mukaan laskettu
#' KOTIMAISESTA kayttotaulukosta) - talloin matriisia ei tarvitse (eika pida)
#' invertoida uudelleen, vaan riittaa suora matriisikertolasku.
#'
#' @param kaanteismatriisi Valmis (I-A)^-1 -matriisi (n x n), esim. 14yq
#' @param arvonlisays_kertoimet Arvonlisayskertoimet (arvonlisays/tuotos)
#'   samassa toimialajarjestyksessa kuin kaanteismatriisin rivit/sarakkeet
#'   (esim. taulukosta 14yn)
#' @param kysynta Kysyntashokkivektori (pituus n), samassa
#'   toimialaluokituksessa kuin kaanteismatriisi
#' @return list(bkt = kokonais-BKT-vaikutus, tuotanto = toimialoittainen
#'   kokonaistuotanto)
arvonlisays_vaikutus_kaanteismatriisilla <- function(
  kaanteismatriisi, arvonlisays_kertoimet, kysynta
) {
  n <- length(kysynta)
  if (!all(dim(kaanteismatriisi) == c(n, n))) {
    stop("Kaanteismatriisin tulee olla n x n, jossa n = kysynta-vektorin pituus.")
  }
  x <- as.numeric(kaanteismatriisi %*% kysynta)
  bkt <- sum(arvonlisays_kertoimet * x)
  list(bkt = bkt, tuotanto = x)
}
