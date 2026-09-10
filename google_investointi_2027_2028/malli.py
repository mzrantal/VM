"""Yksinkertainen panos-tuotos (Leontief) -laskentamoottori.

Kayttotarkoitus: kun toimialoittainen tekninen kerroinmatriisi A (vain
kotimaiset, tuonnista puhdistetut valituotepanokset) ja toimialoittaiset
arvonlisayskertoimet on saatu Tilastokeskuksen tarjonta- ja kayttotaulukoista
(ks. hae_tilastokeskus.py), tama moduuli ratkaisee kokonaistuotannon ja siita
lasketun BKT (arvonlisays) -vaikutuksen annetulle kysyntashokkivektorille.

Ei riipu numpysta / pandasista - toimii pelkalla Python-standardikirjastolla,
koska matriisi on kooltaan pieni (muutamia-kymmenia toimialoja).
"""
from __future__ import annotations


def solve_linear_system(matrix: list[list[float]], vector: list[float]) -> list[float]:
    """Ratkaisee Mx = v Gaussin eliminaatiolla osittaisella pivotoinnilla."""
    n = len(vector)
    aug = [row[:] + [vector[i]] for i, row in enumerate(matrix)]

    for col in range(n):
        pivot_row = max(range(col, n), key=lambda r: abs(aug[r][col]))
        if abs(aug[pivot_row][col]) < 1e-12:
            raise ValueError("Matriisi on singulaarinen - malli ei ratkea.")
        aug[col], aug[pivot_row] = aug[pivot_row], aug[col]

        pivot = aug[col][col]
        aug[col] = [value / pivot for value in aug[col]]

        for r in range(n):
            if r != col:
                factor = aug[r][col]
                aug[r] = [aug[r][k] - factor * aug[col][k] for k in range(n + 1)]

    return [aug[i][n] for i in range(n)]


def leontief_output(A: list[list[float]], final_demand: list[float]) -> list[float]:
    """Kokonaistuotanto x = (I - A)^-1 * d."""
    n = len(final_demand)
    identity_minus_A = [
        [(1.0 if i == j else 0.0) - A[i][j] for j in range(n)] for i in range(n)
    ]
    return solve_linear_system(identity_minus_A, final_demand)


def value_added_impact(
    A: list[list[float]],
    value_added_coeff: list[float],
    final_demand: list[float],
) -> tuple[float, list[float]]:
    """Laskee BKT (arvonlisays) -vaikutuksen = arvonlisayskertoimet . x.

    Palauttaa (bkt_vaikutus_yhteensa, toimialoittainen_kokonaistuotanto).
    """
    x = leontief_output(A, final_demand)
    bkt = sum(value_added_coeff[i] * x[i] for i in range(len(x)))
    return bkt, x
