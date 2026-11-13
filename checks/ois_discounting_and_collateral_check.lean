-- Collateral discounting: in the one-period state-price model a claim fully covered by cash collateral is worth its pricing average divided by the collateral growth factor, so the funding rate drops out; partial cover blends the two factors, and over many periods each payment is discounted by the product of the collateral factors.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Finset

/-! The one-period model of the card. There are finitely many year-end states `Ω`. The pricing
probabilities `Q ω` are positive and add to one, and the bank borrows and lends at one funding
growth factor `g_f > 0`, so a year-end payoff `Y` costs `(∑ ω, Q ω * Y ω) / g_f` today
(Step 1). The collateral is cash `C`, handed back at year-end as `g_c * C` with a collateral
growth factor `g_c > 0` known today. Buying the claim (worth `V`) and receiving the collateral
is a position costing `V - C` today that pays `X ω - g_c * C` at year-end (Step 2), so no
arbitrage gives `V - C = (∑ ω, Q ω * (X ω - g_c * C)) / g_f`. -/

/-- Collateral discounting. If a claim paying `X` at year-end is fully covered by cash
collateral, `C = V`, returned with interest at the collateral growth factor `g_c`, then the
claim is worth its pricing average divided by `g_c`: `V = E_Q[X] / g_c`. The funding growth
factor `g_f` does not appear in the answer. -/
theorem fully_collateralised_claim_discounts_at_collateral_rate
    {Ω : Type*} [Fintype Ω] (Q : Ω → ℝ) (hQpos : ∀ ω, 0 < Q ω) (hQsum : ∑ ω, Q ω = 1)
    (X : Ω → ℝ) (g_f g_c V C : ℝ) (hgf : 0 < g_f) (hgc : 0 < g_c)
    (hprice : V - C = (∑ ω, Q ω * (X ω - g_c * C)) / g_f)
    (hfull : C = V) :
    V = (∑ ω, Q ω * X ω) / g_c := by
  subst hfull
  have hsum : ∑ ω, Q ω * (X ω - g_c * C) = ∑ ω, Q ω * X ω - g_c * C := by
    simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hQsum, one_mul]
  rw [hsum, sub_self, eq_comm, div_eq_zero_iff] at hprice
  rcases hprice with h | h
  · field_simp
    linarith
  · exact absurd h hgf.ne'

/-- Partial collateral. If only a fraction `θ` of the value is covered, `C = θ * V` with
`0 ≤ θ ≤ 1`, then the claim is discounted at a blend of the two growth factors weighted by how
much is covered: `V = E_Q[X] / ((1 - θ) * g_f + θ * g_c)`. -/
theorem partially_collateralised_claim_blends_growth_factors
    {Ω : Type*} [Fintype Ω] (Q : Ω → ℝ) (hQpos : ∀ ω, 0 < Q ω) (hQsum : ∑ ω, Q ω = 1)
    (X : Ω → ℝ) (g_f g_c V C θ : ℝ) (hgf : 0 < g_f) (hgc : 0 < g_c)
    (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1)
    (hprice : V - C = (∑ ω, Q ω * (X ω - g_c * C)) / g_f)
    (hC : C = θ * V) :
    V = (∑ ω, Q ω * X ω) / ((1 - θ) * g_f + θ * g_c) := by
  subst hC
  have hsum : ∑ ω, Q ω * (X ω - g_c * (θ * V)) = ∑ ω, Q ω * X ω - g_c * (θ * V) := by
    simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hQsum, one_mul]
  rw [hsum] at hprice
  have hden : 0 < (1 - θ) * g_f + θ * g_c := by
    rcases eq_or_lt_of_le hθ1 with h | h
    · subst h; simpa using hgc
    · have : 0 < 1 - θ := by linarith
      positivity
  rw [eq_div_iff hden.ne']
  rw [eq_div_iff hgf.ne'] at hprice
  linarith

lemma rollback_aux
    (n : ℕ) (g x V : ℕ → ℝ) (hg : ∀ j, 0 < g j)
    (hend : V n = 0)
    (hstep : ∀ i < n, V i = (x (i + 1) + V (i + 1)) / g (i + 1)) :
    ∀ d i, i + d = n →
      V i / ∏ k ∈ Icc 1 i, g k = ∑ j ∈ Ioc i n, x j / ∏ k ∈ Icc 1 j, g k := by
  intro d
  induction d with
  | zero =>
    intro i hi
    simp at hi
    subst hi
    simp [hend]
  | succ d ih =>
    intro i hi
    have hlt : i < n := by omega
    have IH := ih (i + 1) (by omega)
    have hP : 0 < ∏ k ∈ Icc 1 i, g k := Finset.prod_pos (fun k _ => hg k)
    have hg1 := hg (i + 1)
    rw [← Finset.insert_Ioc_add_one_left_eq_Ioc hlt, Finset.sum_insert (by simp), ← IH,
      Finset.prod_Icc_succ_top (by omega), hstep i hlt]
    field_simp

#print axioms rollback_aux

/-- Many periods (Step 4). Over `n` years with collateral growth factors `g j > 0` known today,
let `x j` be the pricing average of year `j`'s payment and `V i` the value just after year
`i`'s payment. Full collateral rolls back one year at a time, `V i = (x (i + 1) + V (i + 1)) /
g (i + 1)`, from `V n = 0`. Then today's value is every payment discounted on the collateral
(overnight) curve, `D j = 1 / (g 1 * ⋯ * g j)`: `V 0 = ∑ j = 1..n, x j / (g 1 * ⋯ * g j)`. -/
theorem collateral_rollback_discounts_on_overnight_curve
    (n : ℕ) (g x V : ℕ → ℝ) (hg : ∀ j, 0 < g j)
    (hend : V n = 0)
    (hstep : ∀ i < n, V i = (x (i + 1) + V (i + 1)) / g (i + 1)) :
    V 0 = ∑ j ∈ Icc 1 n, x j / ∏ k ∈ Icc 1 j, g k := by
  have h := rollback_aux n g x V hg hend hstep n 0 (by simp)
  have hI : Ioc 0 n = Icc 1 n := by ext j; simp; omega
  simpa [hI] using h

/-! The card's exact worked numbers. -/

-- The first coupon: 10,000,000 times (4.20 percent minus 1.00 percent) is 320,000 dollars.
example : (10000000 : ℚ) * (42 / 1000 - 1 / 100) = 320000 := by norm_num

-- Par minus fixed: 4.65 percent minus 1.00 percent is 3.65 percent.
example : (465 / 10000 : ℚ) - 1 / 100 = 365 / 10000 := by norm_num

#print axioms fully_collateralised_claim_discounts_at_collateral_rate
#print axioms partially_collateralised_claim_blends_growth_factors
#print axioms collateral_rollback_discounts_on_overnight_curve
