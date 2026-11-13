-- Discount factors: quotes for once-a-year, m-times-a-year and continuous interest that grow one unit to the same place in a year give the same price today for one unit paid T years later, a logarithm converts between them, a positive factor names exactly one continuous rate, a certain promise must trade at that factor when no free trade exists, and the card's 5 percent bill and bond land on the cents it prints.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-- The formula and the conversion pair. Interest is added `m` times a year (`m` at least 1) at
the yearly quote `rₘ`, so one unit grows by the positive factor `1 + rₘ / m` each period. Two
quotes describe the same money when they grow one unit to the same place in one year: here the
`m`-times-a-year quote `rₘ`, the once-a-year quote `r₁` and the continuous quote `r_c` all grow
one unit to `1 + r₁` in a year. Then, for every waiting time `T` in years, the three ways of
writing the discount factor give the same number,
`1 / (1 + r₁)^T = (1 + rₘ/m)^(-m T) = e^(-r_c T)`,
and the labels convert by a logarithm and back:
`r_c = m ln(1 + rₘ/m)` and `rₘ = m (e^(r_c/m) - 1)`. -/
theorem every_compounding_convention_labels_the_same_discount_factor
    (m : ℕ) (hm : 0 < m) (r₁ rₘ r_c : ℝ)
    (hgrow : 0 < 1 + rₘ / m)
    (same_m : (1 + rₘ / m) ^ m = 1 + r₁)
    (same_c : Real.exp r_c = 1 + r₁) (T : ℝ) :
    1 / (1 + r₁) ^ T = (1 + rₘ / m) ^ (-(m * T)) ∧
    (1 + rₘ / m) ^ (-(m * T)) = Real.exp (-r_c * T) ∧
    r_c = m * Real.log (1 + rₘ / m) ∧
    rₘ = m * (Real.exp (r_c / m) - 1) := by
  set a : ℝ := 1 + rₘ / m with ha_def
  have hmR : (0 : ℝ) < m := by exact_mod_cast hm
  have hmne : (m : ℝ) ≠ 0 := ne_of_gt hmR
  have hlog : (m : ℝ) * Real.log a = r_c := by
    have h1 : Real.log (a ^ m) = (m : ℝ) * Real.log a := Real.log_pow a m
    rw [← h1, same_m, ← same_c, Real.log_exp]
  have hpow : (1 + r₁) = a ^ ((m : ℝ)) := by
    rw [Real.rpow_natCast, same_m]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hpow, ← Real.rpow_mul (le_of_lt hgrow), Real.rpow_neg (le_of_lt hgrow), one_div]
  · rw [Real.rpow_def_of_pos hgrow]
    congr 1
    rw [← hlog]
    ring
  · exact hlog.symm
  · have hexp : Real.exp (r_c / m) = a := by
      rw [← hlog, mul_div_cancel_left₀ _ hmne, Real.exp_log hgrow]
    rw [hexp, ha_def]
    field_simp
    ring

/-- Reading the rate back out of a factor. Over a wait `T` longer than zero, the factor
`e^(-r T)` falls strictly as the continuous rate `r` rises. A positive factor `D` names one
continuous rate and no other, namely `r = -ln(D) / T`. A factor of zero or less names no rate
at all. A factor of exactly 1 means a rate of 0, and a factor above 1 means a rate below 0. -/
theorem a_positive_factor_names_exactly_one_continuous_rate (T : ℝ) (hT : 0 < T) :
    StrictAnti (fun r : ℝ => Real.exp (-r * T)) ∧
    (∀ D : ℝ, 0 < D → ∀ r : ℝ, Real.exp (-r * T) = D ↔ r = -Real.log D / T) ∧
    (∀ D : ℝ, D ≤ 0 → ∀ r : ℝ, Real.exp (-r * T) ≠ D) ∧
    (∀ r : ℝ, Real.exp (-r * T) = 1 ↔ r = 0) ∧
    (∀ r : ℝ, 1 < Real.exp (-r * T) ↔ r < 0) := by
  have hTne : T ≠ 0 := ne_of_gt hT
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro r₁ r₂ h
    simp only
    apply Real.exp_lt_exp.mpr
    nlinarith
  · intro D hD r
    constructor
    · intro h
      have h2 : -r * T = Real.log D := by rw [← h, Real.log_exp]
      field_simp
      linarith
    · intro h
      have h2 : -r * T = Real.log D := by
        rw [h]
        field_simp
      rw [h2, Real.exp_log hD]
  · intro D hD r h
    have := Real.exp_pos (-r * T)
    linarith
  · intro r
    rw [Real.exp_eq_one_iff]
    constructor
    · intro h
      rcases mul_eq_zero.mp h with h1 | h1
      · linarith
      · exact absurd h1 hTne
    · intro h
      rw [h]
      ring
  · intro r
    rw [Real.one_lt_exp_iff]
    constructor
    · intro h
      by_contra hc
      push Not at hc
      nlinarith
    · intro h
      nlinarith

/-- Why a certain payment must trade at this price. A promise to pay one unit on the date can
be bought or sold in any amount at the price `z`, and the bank lends and borrows on the same
schedule, growing one unit by the positive factor `A` over the wait, so the discount factor is
`1 / A`. A position holds `x` promises (negative means sold) and `y` in the bank (negative
means borrowed): it costs `x z + y` today and pays `x + y A` on the date. No position that
costs nothing today pays a positive amount on the date exactly when `z = 1 / A`. -/
theorem certain_promise_trades_at_the_discount_factor (A z : ℝ) (hA : 0 < A) :
    (∀ x y : ℝ, x * z + y = 0 → ¬ (0 < x + y * A)) ↔ z = 1 / A := by
  have hAne : A ≠ 0 := ne_of_gt hA
  constructor
  · intro h
    by_contra hz
    have hne : 1 - z * A ≠ 0 := by
      intro h0
      apply hz
      field_simp
      linarith
    apply h (1 - z * A) (-(1 - z * A) * z) (by ring)
    have hsq : 0 < (1 - z * A) ^ 2 := by positivity
    nlinarith
  · intro hz x y hxy hpos
    have hy : y = -(x * z) := by linarith
    rw [hy, hz] at hpos
    field_simp at hpos
    linarith

-- The card's numbers, in exact fractions. 5 percent is 105/100, and dividing by 1.05 is
-- multiplying by 20/21. Money is counted in cents.
-- One year's factor and the five-year factor as whole-number fractions: 20^5 / 21^5.
example : (1 : ℚ) / (105 / 100) = 20 / 21 := by norm_num
example : (1 : ℚ) / (105 / 100) ^ 5 = 20 ^ 5 / 21 ^ 5 := by norm_num
example : ((20 : ℚ) / 21) ^ 5 = 3200000 / 4084101 := by norm_num
-- The five-year factor rounds to 0.7835261665 at ten places.
example : (78352616645 / 10 ^ 11 : ℚ) ≤ (20 / 21) ^ 5 ∧
    ((20 : ℚ) / 21) ^ 5 < 78352616655 / 10 ^ 11 := by norm_num
-- The council's deposit for the 1,000 dollar bill: within half a cent of 783.53.
example : (156705 / 2 : ℚ) ≤ 100000 * (20 / 21) ^ 5 ∧
    (100000 : ℚ) * (20 / 21) ^ 5 < 156707 / 2 := by norm_num
-- 783.53 grown five years at 5 percent lands on 1000.00, to the cent.
example : (199999 / 2 : ℚ) ≤ 78353 * (105 / 100) ^ 5 ∧
    (78353 : ℚ) * (105 / 100) ^ 5 < 200001 / 2 := by norm_num
-- The deposit by how far off the bill is: 952.38, 907.03, 613.91 and 231.38.
example : (190475 / 2 : ℚ) ≤ 100000 * (20 / 21) ∧ (100000 : ℚ) * (20 / 21) < 190477 / 2 := by
  norm_num
example : (181405 / 2 : ℚ) ≤ 100000 * (20 / 21) ^ 2 ∧
    (100000 : ℚ) * (20 / 21) ^ 2 < 181407 / 2 := by norm_num
example : (122781 / 2 : ℚ) ≤ 100000 * (20 / 21) ^ 10 ∧
    (100000 : ℚ) * (20 / 21) ^ 10 < 122783 / 2 := by norm_num
example : (46275 / 2 : ℚ) ≤ 100000 * (20 / 21) ^ 30 ∧
    (100000 : ℚ) * (20 / 21) ^ 30 < 46277 / 2 := by norm_num
-- The deposit by the rate, five years out: 1000.00 at 0 percent, then 905.73 at 2 percent,
-- 680.58 at 8 percent and 567.43 at 12 percent.
example : (100000 : ℚ) / (1 + 0) ^ 5 = 100000 := by norm_num
example : (181145 / 2 : ℚ) ≤ 100000 / (102 / 100) ^ 5 ∧
    (100000 : ℚ) / (102 / 100) ^ 5 < 181147 / 2 := by norm_num
example : (136115 / 2 : ℚ) ≤ 100000 / (108 / 100) ^ 5 ∧
    (100000 : ℚ) / (108 / 100) ^ 5 < 136117 / 2 := by norm_num
example : (113485 / 2 : ℚ) ≤ 100000 / (112 / 100) ^ 5 ∧
    (100000 : ℚ) / (112 / 100) ^ 5 < 113487 / 2 := by norm_num
-- The shelf's bond: 1,000 face, 60.00 coupon a year, five years, at 5 percent. Priced cash
-- amount by cash amount it equals the coupons as one block plus the discounted face, exactly.
example : (6000 : ℚ) * (20 / 21) + 6000 * (20 / 21) ^ 2 + 6000 * (20 / 21) ^ 3 +
      6000 * (20 / 21) ^ 4 + 106000 * (20 / 21) ^ 5 =
    6000 * (1 - (20 / 21) ^ 5) / (5 / 100) + 100000 * (20 / 21) ^ 5 := by norm_num
-- That price is within half a cent of 1043.29.
example : (208657 / 2 : ℚ) ≤ 6000 * (1 - (20 / 21) ^ 5) / (5 / 100) + 100000 * (20 / 21) ^ 5 ∧
    (6000 : ℚ) * (1 - (20 / 21) ^ 5) / (5 / 100) + 100000 * (20 / 21) ^ 5 < 208659 / 2 := by
  norm_num
-- Pull to par at an unchanged 5 percent: 1035.46, 1027.23, 1018.59, 1009.52 with four, three,
-- two and one years left, and 1000.00 with none.
example : (207091 / 2 : ℚ) ≤ 6000 * (1 - (20 / 21) ^ 4) / (5 / 100) + 100000 * (20 / 21) ^ 4 ∧
    (6000 : ℚ) * (1 - (20 / 21) ^ 4) / (5 / 100) + 100000 * (20 / 21) ^ 4 < 207093 / 2 := by
  norm_num
example : (205445 / 2 : ℚ) ≤ 6000 * (1 - (20 / 21) ^ 3) / (5 / 100) + 100000 * (20 / 21) ^ 3 ∧
    (6000 : ℚ) * (1 - (20 / 21) ^ 3) / (5 / 100) + 100000 * (20 / 21) ^ 3 < 205447 / 2 := by
  norm_num
example : (203717 / 2 : ℚ) ≤ 6000 * (1 - (20 / 21) ^ 2) / (5 / 100) + 100000 * (20 / 21) ^ 2 ∧
    (6000 : ℚ) * (1 - (20 / 21) ^ 2) / (5 / 100) + 100000 * (20 / 21) ^ 2 < 203719 / 2 := by
  norm_num
example : (201903 / 2 : ℚ) ≤ 6000 * (1 - 20 / 21) / (5 / 100) + 100000 * (20 / 21) ∧
    (6000 : ℚ) * (1 - 20 / 21) / (5 / 100) + 100000 * (20 / 21) < 201905 / 2 := by norm_num
example : (6000 : ℚ) * (1 - (20 / 21) ^ 0) / (5 / 100) + 100000 * (20 / 21) ^ 0 = 100000 := by
  norm_num
-- What breaks. Halving the 5 percent and applying it twice a year: deposit 781.20, which grows
-- at the true 5 percent to 997.03.
example : (156239 / 2 : ℚ) ≤ 100000 / (1 + 5 / 200) ^ 10 ∧
    (100000 : ℚ) / (1 + 5 / 200) ^ 10 < 156241 / 2 := by norm_num
example : (199405 / 2 : ℚ) ≤ 78120 * (105 / 100) ^ 5 ∧
    (78120 : ℚ) * (105 / 100) ^ 5 < 199407 / 2 := by norm_num
-- Simple interest, dividing by 1 + 0.05 × 5: deposit exactly 800.00, which grows to 1021.03.
example : (100000 : ℚ) / (1 + 5 / 100 * 5) = 80000 := by norm_num
example : (204205 / 2 : ℚ) ≤ 80000 * (105 / 100) ^ 5 ∧
    (80000 : ℚ) * (105 / 100) ^ 5 < 204207 / 2 := by norm_num
-- Time counted in months, 5 percent fed in sixty times: deposit 53.54, which grows to 68.33.
example : (10707 / 2 : ℚ) ≤ 100000 * (20 / 21) ^ 60 ∧
    (100000 : ℚ) * (20 / 21) ^ 60 < 10709 / 2 := by norm_num
example : (13665 / 2 : ℚ) ≤ 5354 * (105 / 100) ^ 5 ∧
    (5354 : ℚ) * (105 / 100) ^ 5 < 13667 / 2 := by norm_num

#print axioms every_compounding_convention_labels_the_same_discount_factor
#print axioms a_positive_factor_names_exactly_one_continuous_rate
#print axioms certain_promise_trades_at_the_discount_factor
