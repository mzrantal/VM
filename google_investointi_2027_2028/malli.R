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
