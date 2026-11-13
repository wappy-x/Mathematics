-- Caplets and floorlets: under the odds set by the payment-date bond the fixed rate averages to the forward rate, so caplet minus floorlet is a forward rate agreement, and a caplet is a put on that bond.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

open Finset

/-! A model with finitely many outcomes at the reset date, numbered by `s : ι`.
`π s > 0` is the state price (today's cost of `$1` at the reset date in outcome `s` only),
`L s` is the rate fixed in outcome `s`, and `τ > 0` is the length of the interest period in years.
`X s = 1 / (1 + τ * L s)` is the reset-date price of `$1` paid at the payment date.
Today's discount factors are `D(T₁) = ∑ π s` and `D(T₂) = ∑ π s * X s`, and the forward rate is
`F = (D(T₁) / D(T₂) - 1) / τ`. The payment-date bond's odds are `q s = π s * X s / D(T₂)`.
The positive part `(x)⁺` is written `max x 0`. -/

/-- The forward measure makes the forward rate a fair bet: in any model with positive state prices
and positive rates, the weights `q s = π s * X s / D(T₂)` set by the payment-date bond are positive
and add to 1, and under them the average of the fixed rate is exactly the forward rate
`F = (D(T₁) / D(T₂) - 1) / τ`. Nothing is assumed about how rates move. -/
theorem forward_rate_is_fair_bet_under_payment_bond_odds {ι : Type*} [Fintype ι] [Nonempty ι]
    (π L : ι → ℝ) (τ : ℝ) (hτ : 0 < τ) (hπ : ∀ s, 0 < π s) (hL : ∀ s, 0 < L s) :
    let X : ι → ℝ := fun s => 1 / (1 + τ * L s)
    let D₁ : ℝ := ∑ s, π s
    let D₂ : ℝ := ∑ s, π s * X s
    let q : ι → ℝ := fun s => π s * X s / D₂
    (∀ s, 0 < q s) ∧ ∑ s, q s = 1 ∧ ∑ s, q s * L s = (D₁ / D₂ - 1) / τ := by
  intro X D₁ D₂ q
  have hX : ∀ s, 0 < X s := fun s => by
    simp only [X]; have := hL s; positivity
  have hXL : ∀ s, π s * X s * L s = (π s - π s * X s) / τ := fun s => by
    simp only [X]
    have h1 : (0:ℝ) < 1 + τ * L s := by have := hL s; positivity
    field_simp
    ring
  have hD₂ : 0 < D₂ := Finset.sum_pos (fun s _ => mul_pos (hπ s) (hX s)) Finset.univ_nonempty
  refine ⟨fun s => div_pos (mul_pos (hπ s) (hX s)) hD₂, ?_, ?_⟩
  · simp only [q, ← Finset.sum_div]
    exact div_self hD₂.ne'
  · have e : ∑ s, q s * L s = (∑ s, π s * X s * L s) / D₂ := by
      simp only [q, Finset.sum_div]
      refine Finset.sum_congr rfl (fun s _ => ?_)
      ring
    rw [e]
    simp only [hXL, ← Finset.sum_div, Finset.sum_sub_distrib]
    show (D₁ - D₂) / τ / D₂ = (D₁ / D₂ - 1) / τ
    field_simp

/-- Caplet minus floorlet is a forward rate agreement: a caplet bought and a floorlet sold, on
notional `M` and strike `K`, each paying at the payment date, are together worth
`M * τ * D(T₂) * (F - K)` today, whatever the volatility or the model. -/
theorem caplet_sub_floorlet_eq_fra {ι : Type*} [Fintype ι] [Nonempty ι]
    (π L : ι → ℝ) (τ M K : ℝ) (hτ : 0 < τ) (hπ : ∀ s, 0 < π s) (hL : ∀ s, 0 < L s)
    (hK : 0 < K) :
    let X : ι → ℝ := fun s => 1 / (1 + τ * L s)
    let D₁ : ℝ := ∑ s, π s
    let D₂ : ℝ := ∑ s, π s * X s
    let F : ℝ := (D₁ / D₂ - 1) / τ
    (∑ s, π s * X s * (M * τ * max (L s - K) 0)) - (∑ s, π s * X s * (M * τ * max (K - L s) 0))
      = M * τ * D₂ * (F - K) := by
  intro X D₁ D₂ F
  have hX : ∀ s, 0 < X s := fun s => by
    simp only [X]; have := hL s; positivity
  have hXL : ∀ s, π s * X s * L s = (π s - π s * X s) / τ := fun s => by
    simp only [X]
    have h1 : (0:ℝ) < 1 + τ * L s := by have := hL s; positivity
    field_simp
    ring
  have hD₂ : 0 < D₂ := Finset.sum_pos (fun s _ => mul_pos (hπ s) (hX s)) Finset.univ_nonempty
  have hm : ∀ a : ℝ, max a 0 - max (-a) 0 = a := fun a => by
    rcases le_total a 0 with h | h
    · rw [max_eq_right h, max_eq_left (by linarith)]; ring
    · rw [max_eq_left h, max_eq_right (by linarith)]; ring
  rw [← Finset.sum_sub_distrib]
  have e : ∀ s, π s * X s * (M * τ * max (L s - K) 0) - π s * X s * (M * τ * max (K - L s) 0)
      = M * τ * (π s * X s * L s) - M * τ * K * (π s * X s) := fun s => by
    have := hm (L s - K)
    rw [show K - L s = -(L s - K) by ring]
    linear_combination (π s * X s * (M * τ)) * this
  simp only [e, hXL, Finset.sum_sub_distrib, ← Finset.mul_sum, ← Finset.sum_div]
  show M * τ * ((D₁ - D₂) / τ) - M * τ * K * D₂ = M * τ * D₂ * ((D₁ / D₂ - 1) / τ - K)
  field_simp

/-- A caplet is a put on the payment-date bond: on the reset date, the caplet's payment
`X * τ * (L - K)⁺` (per dollar of notional, with `X = 1 / (1 + τ * L)`) equals `1 + τ * K` puts on
the bond struck at `1 / (1 + τ * K)`, that is `(1 + τ * K) * (1 / (1 + τ * K) - X)⁺`. -/
theorem caplet_eq_put_on_payment_bond (τ L K : ℝ) (hτ : 0 < τ) (hL : 0 < L) (hK : 0 < K) :
    1 / (1 + τ * L) * τ * max (L - K) 0
      = (1 + τ * K) * max (1 / (1 + τ * K) - 1 / (1 + τ * L)) 0 := by
  have h1 : 0 < 1 + τ * L := by positivity
  have h2 : 0 < 1 + τ * K := by positivity
  have e : 1 / (1 + τ * K) - 1 / (1 + τ * L) = τ * (L - K) / ((1 + τ * K) * (1 + τ * L)) := by
    field_simp; ring
  rw [e]
  rcases le_total L K with h | h
  · rw [max_eq_right (by linarith), max_eq_right]
    · ring
    · apply div_nonpos_of_nonpos_of_nonneg
      · nlinarith
      · positivity
  · rw [max_eq_left (by linarith), max_eq_left]
    · field_simp
    · apply div_nonneg
      · nlinarith
      · positivity

/-! The card's exact worked numbers: notional `$10,000,000`, a quarter (`τ = 1/4`), strike 5%. -/

-- Fixed at 7 percent, the caplet pays $50,000.
example : (10000000 : ℚ) * (1 / 4) * max (7 / 100 - 5 / 100) 0 = 50000 := by norm_num

-- Fixed at 4 percent, it pays nothing.
example : (10000000 : ℚ) * (1 / 4) * max (4 / 100 - 5 / 100) 0 = 0 := by norm_num

-- The chart: $12,500 for every half point above 5 percent (5.5, 6, 6.5 percent).
example : (10000000 : ℚ) * (1 / 4) * max (55 / 1000 - 5 / 100) 0 = 12500 := by norm_num
example : (10000000 : ℚ) * (1 / 4) * max (6 / 100 - 5 / 100) 0 = 25000 := by norm_num
example : (10000000 : ℚ) * (1 / 4) * max (65 / 1000 - 5 / 100) 0 = 37500 := by norm_num

-- The bond strike of the put: 1 / (1 + τ K) = 80/81 = 0.98765432...
example : (1 : ℚ) / (1 + 1 / 4 * (5 / 100)) = 80 / 81 := by norm_num

#print axioms forward_rate_is_fair_bet_under_payment_bond_odds
#print axioms caplet_sub_floorlet_eq_fra
#print axioms caplet_eq_put_on_payment_bond
