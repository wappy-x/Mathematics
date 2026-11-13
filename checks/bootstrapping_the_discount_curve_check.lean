-- Bootstrapping: par swap quotes taken shortest first fix exactly one discount curve, each rung solved by one division, and a rung's price is positive exactly when its quote is in range.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Tactic.NormNum
import Mathlib

open Finset

/-- The bootstrapped discount factors, defined on all of `ℕ` by strong recursion. -/
noncomputable def bootD (α S : ℕ → ℝ) : ℕ → ℝ
  | n => (1 - S n * ∑ j : Fin n, α j * bootD α S j) / (1 + α n * S n)
decreasing_by exact j.isLt

theorem bootD_eq (α S : ℕ → ℝ) (n : ℕ) :
    bootD α S n = (1 - S n * ∑ j ∈ range n, α j * bootD α S j) / (1 + α n * S n) := by
  rw [bootD, Fin.sum_univ_eq_sum_range (fun j => α j * bootD α S j) n]

theorem fin_sum_Iio_eq_range {N : ℕ} (f : ℕ → ℝ) (n : Fin N) :
    ∑ j ∈ Iio n, f j = ∑ j ∈ range n, f j := by
  rw [← Nat.Iio_eq_range, ← Fin.map_valEmbedding_Iio, sum_map]
  rfl

theorem fin_sum_Iic_eq {N : ℕ} (f : Fin N → ℝ) (n : Fin N) :
    ∑ j ∈ Iic n, f j = ∑ j ∈ Iio n, f j + f n := by
  rw [← Iio_insert, sum_insert (by simp), add_comm]

theorem rung_denom_pos (α S : ℝ) (hα : 0 < α) (hlow : -1 / α < S) : 0 < 1 + α * S := by
  rw [div_lt_iff₀ hα] at hlow
  linarith

theorem rung_formula_aux (α S B D : ℝ) (hα : 0 < α) (hlow : -1 / α < S) :
    S * (B + α * D) = 1 - D ↔ D = (1 - S * B) / (1 + α * S) := by
  have h := rung_denom_pos α S hα hlow
  rw [eq_div_iff h.ne']
  constructor <;> intro e <;> linarith

#print axioms bootD
#print axioms bootD_eq
#print axioms fin_sum_Iio_eq_range
#print axioms fin_sum_Iic_eq
#print axioms rung_denom_pos
#print axioms rung_formula_aux

/-- The ladder has exactly one solution. Number the pillars `0, 1, …, N-1` shortest first.
Quote `n` is a par rate `S n` whose schedule pays on every pillar up to and including `n`,
with accrual fractions `α j > 0`, so it reads `S n * (α 0 D 0 + ⋯ + α n D n) = 1 - D n`
(a deposit is the first rung, where this reads `(1 + α 0 S 0) D 0 = 1`).
If every quote sits above the bottom edge `-1 / α n`, there is exactly one list of discount
factors that fits every quote. -/
theorem bootstrap_unique_curve (N : ℕ) (α S : ℕ → ℝ) (hα : ∀ j, 0 < α j)
    (hlow : ∀ n < N, -1 / α n < S n) :
    ∃! D : Fin N → ℝ, ∀ n : Fin N, S n * ∑ j ∈ Iic n, α j * D j = 1 - D n := by
  refine ⟨fun n => bootD α S n, ?_, ?_⟩
  · intro n
    simp only
    rw [fin_sum_Iic_eq (fun j => α j * bootD α S j),
      fin_sum_Iio_eq_range (fun j => α j * bootD α S j) n,
      rung_formula_aux _ _ _ _ (hα n) (hlow n n.isLt)]
    exact bootD_eq α S n
  · intro D hD
    funext n
    induction n using WellFoundedLT.induction with
    | _ n ih =>
      have e := hD n
      rw [fin_sum_Iic_eq (fun j => α j * D j),
        rung_formula_aux _ _ _ _ (hα n) (hlow n n.isLt)] at e
      rw [e, bootD_eq, ← fin_sum_Iio_eq_range (fun j => α j * bootD α S j) n]
      congr 3
      refine sum_congr rfl fun j hj => ?_
      rw [ih j (mem_Iio.mp hj)]

/-- One rung, one unknown: with the earlier coupons already costing `B`, the par swap equation
`S (B + α D) = 1 - D` holds exactly when `D = (1 - S B) / (1 + α S)`, provided `α > 0` and the
quote is above the bottom edge `-1 / α`. -/
theorem bootstrap_rung_formula (α S B D : ℝ) (hα : 0 < α) (hlow : -1 / α < S) :
    S * (B + α * D) = 1 - D ↔ D = (1 - S * B) / (1 + α * S) := by
  have h := rung_denom_pos α S hα hlow
  rw [eq_div_iff h.ne']
  constructor <;> intro e <;> linarith

/-- On the curve that fits every quote, each pillar's price is positive exactly when its quote
is below the top edge: `S n * B n < 1`, where `B n` is the annuity of the pillars already solved
(that is, `S n < 1 / B n` when `B n > 0`, and automatic at the first rung). -/
theorem bootstrap_price_pos_iff (N : ℕ) (α S : ℕ → ℝ) (hα : ∀ j, 0 < α j)
    (hlow : ∀ n < N, -1 / α n < S n) (D : Fin N → ℝ)
    (hD : ∀ n : Fin N, S n * ∑ j ∈ Iic n, α j * D j = 1 - D n) (n : Fin N) :
    0 < D n ↔ S n * ∑ j ∈ Iio n, α j * D j < 1 := by
  have e := hD n
  rw [fin_sum_Iic_eq (fun j => α j * D j),
    rung_formula_aux _ _ _ _ (hα n) (hlow n n.isLt)] at e
  rw [e, div_pos_iff_of_pos_right (rung_denom_pos _ _ (hα n) (hlow n n.isLt)), sub_pos]

/-! The card's worked numbers, as exact fractions (rates 4.0000 % = 4/100 and so on). -/

-- six-month deposit at 4.0000 %, accrual 1/2: D(0.5) = 50/51 = 0.98039216…
example : (1 + (1 / 2 : ℚ) * (4 / 100)) * (50 / 51) = 1 := by norm_num
-- one-year deposit at 4.2000 %, accrual 1: D(1) = 500/521 = 0.95969290…
example : (1 + (1 : ℚ) * (42 / 1000)) * (500 / 521) = 1 := by norm_num
-- two-year par swap at 4.4000 %: D(2) = 124750/135981 = 0.91740758…
example : (44 / 1000 : ℚ) * (500 / 521 + 124750 / 135981) = 1 - 124750 / 135981 := by norm_num
-- three-year par swap at 4.5500 %: D(3) = 248734250/284336271 = 0.87478903…
example : (455 / 10000 : ℚ) * (500 / 521 + 124750 / 135981 + 248734250 / 284336271)
    = 1 - 248734250 / 284336271 := by norm_num
-- four-year par swap at 4.6200 %: D(4) = 413644211000/495787677867 = 0.83431725…
example : (462 / 10000 : ℚ) * (500 / 521 + 124750 / 135981 + 248734250 / 284336271
    + 413644211000 / 495787677867) = 1 - 413644211000 / 495787677867 := by norm_num
-- five-year par swap at 4.6500 %: D(5) = 826221623729000/1037683609775631
example : (465 / 10000 : ℚ) * (500 / 521 + 124750 / 135981 + 248734250 / 284336271
    + 413644211000 / 495787677867 + 826221623729000 / 1037683609775631)
    = 1 - 826221623729000 / 1037683609775631 := by norm_num
-- the card prints D(5) as 0.79621728: the exact value lies between 0.79621728 and 0.79621729
example : (79621728 / 10 ^ 8 : ℚ) < 826221623729000 / 1037683609775631 ∧
    (826221623729000 / 1037683609775631 : ℚ) < 79621729 / 10 ^ 8 := by norm_num

#print axioms bootstrap_unique_curve
#print axioms bootstrap_rung_formula
#print axioms bootstrap_price_pos_iff
