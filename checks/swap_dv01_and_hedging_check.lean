-- Swap DV01: on a curve bootstrapped from par quotes, a payer swap struck at its quoted par rate has a slope per unit parallel move in the quotes of exactly the notional times the annuity, so its DV01 equals its PV01, and off par the slope gains the extra piece notional times rate gap times the annuity's slope.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Tactic.NormNum

open Finset

/-! Conventions, as on the card: annual payments on both legs, each accrual exactly 1, one curve
for forecasting and discounting. Quotes are numbered `q 0, q 1, …` for years `1, 2, …`. -/

/-- `annuityBefore q k` is `B` on the card: the bootstrapped prices of years `1` to `k` added up,
built one rung at a time, `B 0 = 0` and `B (k+1) = B k + D`, where the rung for year `k+1` is
`D = (1 - q k * B k) / (1 + q k)`. So `annuityBefore q n` is the annuity `A_n`. -/
noncomputable def annuityBefore (q : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | k + 1 => annuityBefore q k + (1 - q k * annuityBefore q k) / (1 + q k)

/-- `discount q k` is the bootstrapped price today of one dollar paid at the end of year `k+1`:
the rung `D = (1 - S B) / (1 + S)` with `S = q k` and `B = annuityBefore q k`. -/
noncomputable def discount (q : ℕ → ℝ) (k : ℕ) : ℝ :=
  (1 - q k * annuityBefore q k) / (1 + q k)

/-- Value to the payer of an `n`-year swap with notional `N` and fixed rate `K`, on the curve
bootstrapped from the quotes `q`: floating leg `N (1 - D(n))` less fixed leg `N K A_n`. -/
noncomputable def payerValue (N K : ℝ) (q : ℕ → ℝ) (n : ℕ) : ℝ :=
  N * (1 - discount q (n - 1)) - N * K * annuityBefore q n

lemma annuityBefore_succ_eq (q : ℕ → ℝ) (k : ℕ) (h : 1 + q k ≠ 0) :
    annuityBefore q (k + 1) = (annuityBefore q k + 1) / (1 + q k) := by
  simp only [annuityBefore]
  field_simp
  ring

lemma payerValue_eq_gap (N K : ℝ) (q : ℕ → ℝ) (m : ℕ) (h : 1 + q m ≠ 0) :
    payerValue N K q (m + 1) = N * (q m - K) * annuityBefore q (m + 1) := by
  simp only [payerValue, discount, Nat.add_sub_cancel]
  rw [annuityBefore_succ_eq q m h]
  field_simp
  ring

lemma annuityBefore_shift_differentiableAt (q : ℕ → ℝ) (k : ℕ) (hq : ∀ j < k, 1 + q j ≠ 0) :
    DifferentiableAt ℝ (fun x : ℝ => annuityBefore (fun j => q j + x) k) 0 := by
  induction k with
  | zero => simp [annuityBefore]
  | succ k ih =>
    have ih' := ih (fun j hj => hq j (Nat.lt_succ_of_lt hj))
    have hk : 1 + (q k + 0) ≠ 0 := by simpa using hq k (Nat.lt_succ_self k)
    simp only [annuityBefore]
    have hlin : DifferentiableAt ℝ (fun x : ℝ => q k + x) 0 :=
      (differentiableAt_id).const_add _
    exact ih'.add (((differentiableAt_const _).sub (hlin.mul ih')).div
      ((differentiableAt_const _).add hlin) hk)

lemma payer_slope_general (N K : ℝ) (q : ℕ → ℝ) (n : ℕ) (hn : 0 < n)
    (hq : ∀ k < n, 1 + q k ≠ 0) :
    HasDerivAt (fun x : ℝ => payerValue N K (fun k => q k + x) n)
      (N * annuityBefore q n
        + N * (q (n - 1) - K) * deriv (fun x : ℝ => annuityBefore (fun k => q k + x) n) 0) 0 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hm : 1 + q m ≠ 0 := hq m (Nat.lt_succ_self m)
  have hA := (annuityBefore_shift_differentiableAt q (m + 1) hq).hasDerivAt
  have hlin : HasDerivAt (fun x : ℝ => q m + x - K) 1 0 :=
    ((hasDerivAt_id (0 : ℝ)).const_add (q m)).sub_const K
  have hprod := (hlin.const_mul N).mul hA
  have hev : (fun x : ℝ => payerValue N K (fun k => q k + x) (m + 1)) =ᶠ[nhds 0]
      (fun x : ℝ => N * (q m + x - K) * annuityBefore (fun k => q k + x) (m + 1)) := by
    have hc : ContinuousAt (fun x : ℝ => 1 + (q m + x)) 0 :=
      (continuous_const.add (continuous_const.add continuous_id)).continuousAt
    filter_upwards [hc.eventually_ne (by simpa using hm)] with x hx
    rw [payerValue_eq_gap N K (fun k => q k + x) m hx]
  have hfin := hprod.congr_of_eventuallyEq hev
  convert hfin using 1
  simp only [Nat.add_sub_cancel, add_zero, mul_one]

#print axioms annuityBefore_succ_eq
#print axioms payerValue_eq_gap
#print axioms annuityBefore_shift_differentiableAt
#print axioms payer_slope_general

/-- DV01 equals PV01 at par. Move every quote by the same amount `x` and rebuild the curve.
For an `n`-year payer swap struck at the market rate (the fixed rate `K` equals the quoted
`n`-year par rate), the value changes at rate exactly `N * A_n` per unit move, so its DV01,
that slope times one basis point `δ`, is `N * A_n * δ`: the notional times the annuity times one
basis point. (`1 + q k ≠ 0` only says each bootstrap rung can be divided out.) -/
theorem par_swap_dv01_eq_pv01 (N : ℝ) (q : ℕ → ℝ) (n : ℕ) (hn : 0 < n)
    (hq : ∀ k < n, 1 + q k ≠ 0) :
    HasDerivAt (fun x : ℝ => payerValue N (q (n - 1)) (fun k => q k + x) n)
      (N * annuityBefore q n) 0 := by
  have h := payer_slope_general N (q (n - 1)) q n hn hq
  simpa using h

/-- Off par, the slope picks up a second piece: the existing profit `N (S - K)` a year, revalued
on the annuity as it moves. With `S` the quoted `n`-year par rate and `A_n'` the slope of the
annuity under a parallel move of the quotes, the payer's value changes at rate
`N * A_n + N * (S - K) * A_n'`. -/
theorem payer_swap_slope_off_par (N K : ℝ) (q : ℕ → ℝ) (n : ℕ) (hn : 0 < n)
    (hq : ∀ k < n, 1 + q k ≠ 0) :
    HasDerivAt (fun x : ℝ => payerValue N K (fun k => q k + x) n)
      (N * annuityBefore q n
        + N * (q (n - 1) - K) * deriv (fun x : ℝ => annuityBefore (fun k => q k + x) n) 0) 0 := by
  exact payer_slope_general N K q n hn hq

/-- Step 1: the floating leg collapses to two numbers, and the swap is worth the rate gap times
the annuity. For any discount curve with `D 0 = 1` and nonzero prices, the floating leg paid as a
strip of forwards, `∑ (D(i-1)/D(i) - 1) D(i)` over years `1` to `n`, is `N (1 - D(n))`, and the
payer's value, floating less fixed `N K A_n`, equals `N (S - K) A_n` with par rate
`S = (1 - D(n)) / A_n`. -/
theorem payer_value_eq_rate_gap_times_annuity (N K : ℝ) (D : ℕ → ℝ) (n : ℕ) (hD0 : D 0 = 1)
    (hD : ∀ i ∈ Icc 1 n, D i ≠ 0) (hA : ∑ i ∈ Icc 1 n, D i ≠ 0) :
    N * ∑ i ∈ Icc 1 n, (D (i - 1) / D i - 1) * D i = N * (1 - D n) ∧
    N * ∑ i ∈ Icc 1 n, (D (i - 1) / D i - 1) * D i - N * K * ∑ i ∈ Icc 1 n, D i
      = N * ((1 - D n) / ∑ i ∈ Icc 1 n, D i - K) * ∑ i ∈ Icc 1 n, D i := by
  have htel : ∀ m ≤ n, ∑ i ∈ Icc 1 m, (D (i - 1) / D i - 1) * D i = 1 - D m := by
    intro m
    induction m with
    | zero => intro _; simp [hD0]
    | succ m ih =>
      intro hm
      rw [sum_Icc_succ_top (by omega), ih (by omega)]
      have : D (m + 1) ≠ 0 := hD (m + 1) (mem_Icc.mpr ⟨by omega, hm⟩)
      simp only [Nat.add_sub_cancel]
      field_simp
      ring
  have h1 := htel n le_rfl
  refine ⟨by rw [h1], ?_⟩
  rw [h1]
  field_simp

/-! The card's worked numbers, as exact fractions: the house curve 4.20, 4.40, 4.55, 4.62 and
4.65 percent, notional 10,000,000, fixed rate 4.5 percent, one basis point 1/10000. -/

/-- The house curve's par quotes for years 1 to 5. -/
noncomputable def houseQuotes (k : ℕ) : ℝ :=
  [42 / 1000, 44 / 1000, 455 / 10000, 462 / 10000, 465 / 10000].getD k 0

-- D(1) = 1 / 1.042 = 500/521 = 0.95969290…
example : discount houseQuotes 0 = 500 / 521 := by
  norm_num [discount, annuityBefore, houseQuotes]

-- D(5) = 0.79621728…, exactly 826221623729000/1037683609775631
example : discount houseQuotes 4 = 826221623729000 / 1037683609775631 := by
  norm_num [discount, annuityBefore, houseQuotes]

-- A_5 = 4.382424…, exactly 13642708777202000/3113050829326893
example : annuityBefore houseQuotes 5 = 13642708777202000 / 3113050829326893 := by
  norm_num [annuityBefore, houseQuotes]

-- value to the payer: 65,736.36 dollars (between 65,736.36 and 65,736.37)
example : 6573636 / 100 < payerValue 10000000 (45 / 1000) houseQuotes 5 ∧
    payerValue 10000000 (45 / 1000) houseQuotes 5 < 6573637 / 100 := by
  norm_num [payerValue, discount, annuityBefore, houseQuotes]

-- PV01 = N × A_5 × δ = 4,382.42 dollars (between 4,382.42 and 4,382.43)
example : 438242 / 100 < 10000000 * annuityBefore houseQuotes 5 * (1 / 10000) ∧
    10000000 * annuityBefore houseQuotes 5 * (1 / 10000) < 438243 / 100 := by
  norm_num [annuityBefore, houseQuotes]

#print axioms par_swap_dv01_eq_pv01
#print axioms payer_swap_slope_off_par
#print axioms payer_value_eq_rate_gap_times_annuity
