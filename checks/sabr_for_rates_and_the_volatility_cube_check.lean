-- SABR for rates: the near-money slope and curvature of the smile give back rho and nu exactly, the reading is the y-squared product of Hagan's pieces, and a butterfly never pays less than zero.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Algebra.Polynomial.Roots

open Polynomial

/-- Running the reading backwards. Take a positive shifted forward `f` (the shift is larger than any
rate the node sees), a positive level `α`, a positive vol of vol `ν`, a fixed beta `β` and any
correlation `ρ`, and put `λ = ν f^(1-β) / α`. If the smile's slope and curvature against log-strike are
`s = -(1/2)(1 - β - ρλ)` and `c = (1/12)[(1-β)^2 + (2 - 3ρ^2)λ^2]`, then `ρλ = 2s + (1-β)`,
`λ^2 = (1/2)[12c - (1-β)^2 + 3(ρλ)^2]`, and dividing gives back rho and nu exactly:
`ρ = (2s + (1-β)) / λ` and `ν = λ α / f^(1-β)` with `λ` the square root above. -/
theorem sabr_reading_recovers_rho_and_nu (f α β ρ ν lam s c : ℝ)
    (hf : 0 < f) (hα : 0 < α) (hν : 0 < ν)
    (hlam : lam = ν * f ^ (1 - β) / α)
    (hs : s = -(1 / 2) * (1 - β - ρ * lam))
    (hc : c = (1 / 12) * ((1 - β) ^ 2 + (2 - 3 * ρ ^ 2) * lam ^ 2)) :
    ρ * lam = 2 * s + (1 - β) ∧
    lam ^ 2 = (1 / 2) * (12 * c - (1 - β) ^ 2 + 3 * (ρ * lam) ^ 2) ∧
    ρ = (2 * s + (1 - β)) / Real.sqrt ((1 / 2) * (12 * c - (1 - β) ^ 2 + 3 * (2 * s + (1 - β)) ^ 2)) ∧
    ν = Real.sqrt ((1 / 2) * (12 * c - (1 - β) ^ 2 + 3 * (2 * s + (1 - β)) ^ 2)) * α / f ^ (1 - β) := by
  have hfp : 0 < f ^ (1 - β) := Real.rpow_pos_of_pos hf _
  have hlpos : 0 < lam := by rw [hlam]; positivity
  have h1 : ρ * lam = 2 * s + (1 - β) := by rw [hs]; ring
  have h2 : lam ^ 2 = (1 / 2) * (12 * c - (1 - β) ^ 2 + 3 * (ρ * lam) ^ 2) := by rw [hc]; ring
  have hsq : Real.sqrt ((1 / 2) * (12 * c - (1 - β) ^ 2 + 3 * (2 * s + (1 - β)) ^ 2)) = lam := by
    rw [← h1, ← h2]; exact Real.sqrt_sq hlpos.le
  refine ⟨h1, h2, ?_, ?_⟩
  · rw [hsq, ← h1]; field_simp
  · rw [hsq, hlam]; field_simp

/-- The reading, "Multiply" step of the detailed proof. With `e = 1 - β`, the level seen from the strike
`1 - (e/2) y + (e^2/8) y^2`, the divisor's share `1 - (e^2/24) y^2`, and the bend
`1 + (ρλ/2) y (1 + (e/2) y) + ((2 - 3ρ^2)λ^2/12) y^2` multiply to
`1 - (1/2)(e - ρλ) y + (1/12)[e^2 + (2 - 3ρ^2)λ^2] y^2` up to terms in `y^3` and higher:
the difference is a polynomial in `y` divisible by `y^3`. -/
theorem sabr_reading_product_to_second_order (β ρ lam : ℝ) :
    (X : ℝ[X]) ^ 3 ∣
      (1 - C ((1 - β) / 2) * X + C ((1 - β) ^ 2 / 8) * X ^ 2) *
        (1 - C ((1 - β) ^ 2 / 24) * X ^ 2) *
        (1 + C (ρ * lam / 2) * X * (1 + C ((1 - β) / 2) * X) + C ((2 - 3 * ρ ^ 2) * lam ^ 2 / 12) * X ^ 2)
      - (1 + C (-(1 / 2) * ((1 - β) - ρ * lam)) * X
           + C ((1 / 12) * ((1 - β) ^ 2 + (2 - 3 * ρ ^ 2) * lam ^ 2)) * X ^ 2) := by
  refine ⟨C ((1 - β) ^ 3 / 48 + (1 - β) ^ 2 / 12 * (ρ * lam / 2)
        + (-((1 - β) / 2)) * (ρ * lam * (1 - β) / 4 + (2 - 3 * ρ ^ 2) * lam ^ 2 / 12))
      + C (-((1 - β) ^ 4 / 192) + (1 - β) ^ 3 / 48 * (ρ * lam / 2)
        + (1 - β) ^ 2 / 12 * (ρ * lam * (1 - β) / 4 + (2 - 3 * ρ ^ 2) * lam ^ 2 / 12)) * X
      + C (-((1 - β) ^ 4 / 192) * (ρ * lam / 2)
        + (1 - β) ^ 3 / 48 * (ρ * lam * (1 - β) / 4 + (2 - 3 * ρ ^ 2) * lam ^ 2 / 12)) * X ^ 2
      + C (-((1 - β) ^ 4 / 192) * (ρ * lam * (1 - β) / 4 + (2 - 3 * ρ ^ 2) * lam ^ 2 / 12)) * X ^ 3, ?_⟩
  apply Polynomial.funext
  intro y
  simp only [eval_sub, eval_add, eval_mul, eval_one, eval_C, eval_X, eval_pow]
  ring

/-- A butterfly (long one call at the low strike `K - h` and one at the high strike `K + h`, short two at
the middle strike `K`) never pays less than zero, whatever the rate `x` at expiry. -/
theorem butterfly_payoff_nonneg (K h x : ℝ) :
    0 ≤ max (x - (K - h)) 0 - 2 * max (x - K) 0 + max (x - (K + h)) 0 := by
  simp only [max_def]
  split_ifs <;> linarith

-- Quotes in thousandths of a volatility point: 22.625, 22 and 22.375 percent. A vol bp is 10 of them.
-- Risk reversal: high wing minus low wing is -25 vol bp.
example : ((22375 : ℚ) - 22625) / 10 = -25 := by norm_num
-- Butterfly: mean of the wings minus the middle is +50 vol bp.
example : (((22625 : ℚ) + 22375) / 2 - 22000) / 10 = 50 := by norm_num
-- Rates in bp, shift 200 bp: the shifted forward is 450 and the shifted low strike 400.
example : (250 : ℤ) + 200 = 450 ∧ (200 : ℤ) + 200 = 400 := by norm_num
-- Shifting does not change the payoff: f - k = F - K at the low strike.
example : ((250 : ℤ) + 200) - (200 + 200) = 250 - 200 := by norm_num
-- The 2y-into-2y node: a forward of -50 bp shifts to 150 bp, which is positive.
example : (-50 : ℤ) + 200 = 150 ∧ (0 : ℤ) < -50 + 200 := by norm_num

#print axioms sabr_reading_recovers_rho_and_nu
#print axioms sabr_reading_product_to_second_order
#print axioms butterfly_payoff_nonneg
