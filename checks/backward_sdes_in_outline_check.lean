-- Backward SDEs in outline: one backward step on a tree replicates both children, equals a discounted reweighted average, and picks the larger of the two one-rate values, while the two-rate driver is the larger of two linear drivers and is Lipschitz with constants R and θ + (R − r)/σ.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Order.Group.PosPart
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

namespace BackwardSDEOutline

open Real Finset

/-- The dealer's two-rate driver `f(y, z) = -r y - θ z + (R - r)(y - z/σ)⁻`: cash lent earns
`r`, cash borrowed costs `R`, `θ` is the market price of risk and `σ` the volatility. Here `y`
is the value held, `z` the hedge in noise units, and `y - z/σ` the cash. -/
noncomputable def twoRateDriver (r R θ σ y z : ℝ) : ℝ :=
  -r * y - θ * z + (R - r) * (y - z / σ)⁻

/-- **One backward step on a tree is the discrete backward SDE** (the card's Step 6).
A node has share price `S ≠ 0` and two children `S_up = S g_u` and `S_down = S g_d` with
down factor `g_d` below up factor `g_u`; the values `Y_up` and `Y_down` there are known.
Hold `Δ = (Y_up - Y_down)/(S_up - S_down)` shares and `cash = Y_up - Δ S_up` (cash at the
next date). Discount the cash at `ρ = r` if it is lent (`cash ≥ 0`) and at `ρ = R` if it is
borrowed, over a step `h ≥ 0`, with lending rate `r` at most borrowing rate `R`, and set
`Y = Δ S + cash e^{-ρh}`. Then the account matches both children, `Y` is the discounted
average `e^{-ρh}(q Y_up + (1 - q) Y_down)` with weight `q = (e^{ρh} - g_d)/(g_u - g_d)`
(a change of measure, one step at a time), and the rate rule makes `Y` the larger of the
value at `r` alone and the value at `R` alone. -/
theorem tree_step_is_discrete_backward_sde
    (S g_u g_d Y_up Y_down r R h : ℝ) (hS : S ≠ 0) (hg : g_d < g_u) (hrR : r ≤ R)
    (hh : 0 ≤ h) :
    let S_up := S * g_u
    let S_down := S * g_d
    let Δ := (Y_up - Y_down) / (S_up - S_down)
    let cash := Y_up - Δ * S_up
    let ρ := if 0 ≤ cash then r else R
    let Y := Δ * S + cash * exp (-(ρ * h))
    let q := (exp (ρ * h) - g_d) / (g_u - g_d)
    Δ * S_up + cash = Y_up ∧ Δ * S_down + cash = Y_down ∧
      Y = exp (-(ρ * h)) * (q * Y_up + (1 - q) * Y_down) ∧
      Y = max (Δ * S + cash * exp (-(r * h))) (Δ * S + cash * exp (-(R * h))) := by
  intro S_up S_down Δ cash ρ Y q
  have hSup : S_up = S * g_u := rfl
  have hSdn : S_down = S * g_d := rfl
  have hcash : cash = Y_up - Δ * S_up := rfl
  have hρ : ρ = if 0 ≤ cash then r else R := rfl
  have hY : Y = Δ * S + cash * exp (-(ρ * h)) := rfl
  have hq : q = (exp (ρ * h) - g_d) / (g_u - g_d) := rfl
  have hgd : g_u - g_d ≠ 0 := sub_ne_zero.mpr (ne_of_gt hg)
  have hSd0 : S_up - S_down ≠ 0 := by
    rw [hSup, hSdn, ← mul_sub]; exact mul_ne_zero hS hgd
  have hΔ : Δ * (S_up - S_down) = Y_up - Y_down := div_mul_cancel₀ _ hSd0
  clear_value q Y ρ cash Δ S_up S_down
  subst hSup hSdn
  have hΔS : Δ * S * (g_u - g_d) = Y_up - Y_down := by rw [← hΔ]; ring
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hcash]; ring
  · rw [hcash]; linear_combination (-1 : ℝ) * hΔ
  · have he : exp (-(ρ * h)) * exp (ρ * h) = 1 := by
      rw [← Real.exp_add]; simp
    have hqD : q * (Y_up - Y_down) = (exp (ρ * h) - g_d) * (Δ * S) := by
      rw [← hΔS, hq]; field_simp
    rw [hY, hcash]
    linear_combination (-exp (-(ρ * h))) * hqD - (Δ * S) * he - exp (-(ρ * h)) * hΔS
  · have hmono : exp (-(R * h)) ≤ exp (-(r * h)) := by
      apply Real.exp_le_exp.mpr
      nlinarith
    by_cases hc : 0 ≤ cash
    · have hρr : ρ = r := by rw [hρ, ite_eq_left_iff.mpr (fun h => absurd hc h)]
      rw [hY, hρr, max_eq_left]
      nlinarith [mul_le_mul_of_nonneg_left hmono hc]
    · have hρR : ρ = R := by rw [hρ, ite_eq_right_iff.mpr (fun h => absurd h hc)]
      rw [hY, hρR, max_eq_right]
      have hc' : cash ≤ 0 := le_of_lt (lt_of_not_ge hc)
      nlinarith [mul_le_mul_of_nonpos_left hmono hc']

/-- **The two-rate driver is the larger of two linear drivers** (the card's Step 4). When the
borrowing rate `R` is at least the lending rate `r`, the driver
`-r y - θ z + (R - r)(y - z/σ)⁻` equals the larger of the one-rate driver
`f_r(y, z) = -r y - θ z` and the borrowing driver `f_R(y, z) = -R y - θ z + (R - r) z/σ`.
By the comparison theorem, the dealer's price is therefore at least each linear price. -/
theorem two_rate_driver_eq_max_of_linear_drivers (r R θ σ y z : ℝ) (hrR : r ≤ R) :
    twoRateDriver r R θ σ y z = max (-r * y - θ * z) (-R * y - θ * z + (R - r) * z / σ) := by
  unfold twoRateDriver
  rw [negPart_def, mul_div_assoc]
  have hk : 0 ≤ R - r := sub_nonneg.mpr hrR
  rcases le_total (-(y - z / σ)) 0 with hc | hc
  · rw [max_eq_right hc, max_eq_left]
    · ring
    · nlinarith [mul_nonneg hk (neg_nonneg.mpr hc)]
  · rw [max_eq_left hc, max_eq_right]
    · ring
    · nlinarith [mul_nonneg hk hc]

/-- **The two-rate driver is Lipschitz** (the card's "When it holds"). With lending rate
`r ≥ 0`, borrowing rate `R ≥ r`, market price of risk `θ ≥ 0` and volatility `σ > 0`, the
driver changes at most in proportion to changes in `y` and `z`, with constants `R` and
`θ + (R - r)/σ`. So the existence and uniqueness theorem applies to the dealer's equation. -/
theorem two_rate_driver_lipschitz (r R θ σ : ℝ) (hr : 0 ≤ r) (hrR : r ≤ R) (hθ : 0 ≤ θ)
    (hσ : 0 < σ) (y z y' z' : ℝ) :
    |twoRateDriver r R θ σ y z - twoRateDriver r R θ σ y' z'|
      ≤ R * |y - y'| + (θ + (R - r) / σ) * |z - z'| := by
  unfold twoRateDriver
  have hk : 0 ≤ R - r := sub_nonneg.mpr hrR
  have hneg : |(y - z / σ)⁻ - (y' - z' / σ)⁻| ≤ |y - y'| + |z - z'| / σ := by
    rw [negPart_def, negPart_def]
    calc |max (-(y - z / σ)) 0 - max (-(y' - z' / σ)) 0|
        ≤ |-(y - z / σ) - -(y' - z' / σ)| := abs_max_sub_max_le_abs _ _ _
      _ = |(y - y') - (z - z') / σ| := by rw [← abs_neg]; congr 1; ring
      _ ≤ |y - y'| + |(z - z') / σ| := abs_sub _ _
      _ = |y - y'| + |z - z'| / σ := by rw [abs_div, abs_of_pos hσ]
  have h1 : |-r * y - θ * z + (R - r) * (y - z / σ)⁻ - (-r * y' - θ * z' + (R - r) * (y' - z' / σ)⁻)|
      ≤ r * |y - y'| + θ * |z - z'| + (R - r) * |(y - z / σ)⁻ - (y' - z' / σ)⁻| := by
    have e : -r * y - θ * z + (R - r) * (y - z / σ)⁻ - (-r * y' - θ * z' + (R - r) * (y' - z' / σ)⁻)
        = (-r) * (y - y') + (-θ) * (z - z') + (R - r) * ((y - z / σ)⁻ - (y' - z' / σ)⁻) := by ring
    rw [e]
    calc _ ≤ |(-r) * (y - y') + (-θ) * (z - z')| + |(R - r) * ((y - z / σ)⁻ - (y' - z' / σ)⁻)| :=
          abs_add_le _ _
      _ ≤ |(-r) * (y - y')| + |(-θ) * (z - z')| + |(R - r) * ((y - z / σ)⁻ - (y' - z' / σ)⁻)| := by
          gcongr; exact abs_add_le _ _
      _ = _ := by
          rw [abs_mul, abs_mul, abs_mul, abs_neg, abs_neg, abs_of_nonneg hr, abs_of_nonneg hθ,
            abs_of_nonneg hk]
  have h2 := mul_le_mul_of_nonneg_left hneg hk
  have e2 : (θ + (R - r) / σ) * |z - z'| = θ * |z - z'| + (R - r) * (|z - z'| / σ) := by ring
  rw [e2]
  nlinarith [h1, h2]

/-! The card's exact worked numbers. -/

-- The hand node: the down child is 100, the strike, so its payoff is 0 and the up payoff is
-- S_up − 100. Then Δ = 1 share and the cash at the end is −100 (a debt), whatever S_up is.
example (S_up : ℝ) (h : S_up ≠ 100) :
    ((S_up - 100) - 0) / (S_up - 100) = 1 ∧ (S_up - 100) - 1 * S_up = -100 := by
  constructor
  · rw [sub_zero, div_self (sub_ne_zero.mpr h)]
  · ring

-- The example's market price of risk θ = (μ − r)/σ = (0.08 − 0.02)/0.20 = 0.3.
example : ((8 / 100 : ℚ) - 2 / 100) / (20 / 100) = 3 / 10 := by norm_num

-- The Lipschitz constant for z: θ + (R − r)/σ = 0.3 + (0.06 − 0.02)/0.20 = 0.5.
example : (3 / 10 : ℚ) + (6 / 100 - 2 / 100) / (20 / 100) = 1 / 2 := by norm_num

-- The 50-step tree has 1 + 2 + … + 50 = 1275 nodes before the end; the seller's hedge
-- borrows at 950, lends at none, and holds no cash at the other 325.
example : ∑ m ∈ range 50, (m + 1) = 1275 ∧ 950 + 0 + 325 = 1275 := by decide

#print axioms tree_step_is_discrete_backward_sde
#print axioms two_rate_driver_eq_max_of_linear_drivers
#print axioms two_rate_driver_lipschitz

end BackwardSDEOutline
