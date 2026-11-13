-- Multi-curve: with a flat-spread forecast curve a floating leg is the overnight floater plus a spread annuity, with one curve the legs telescope so any two tenors are worth the same and the basis is zero, and one quote fixes exactly one spread.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Finset

/-- The index forecast for the period from `a` to `b` read off a forecast curve `H`:
`F = (1 / (b − a)) · (H a / H b − 1)`. -/
noncomputable def fwdRate (H : ℝ → ℝ) (a b : ℝ) : ℝ :=
  (1 / (b - a)) * (H a / H b - 1)

/-- A floating leg per dollar of notional with payment dates `t 1, …, t n` (`t 0` is today):
each coupon is the accrual `α = t (i+1) − t i` times the forecast off the index's curve `H`,
discounted off the shared discount curve `D` at its payment date, `C = ∑ α F_i D(t_i)`. -/
noncomputable def floatingLeg (D H : ℝ → ℝ) (t : ℕ → ℝ) (n : ℕ) : ℝ :=
  ∑ i ∈ range n, (t (i + 1) - t i) * fwdRate H (t i) (t (i + 1)) * D (t (i + 1))

/-- The annuity of a schedule: discount factors weighted by accrual, `A = ∑ α D(t_i)`. -/
noncomputable def annuity (D : ℝ → ℝ) (t : ℕ → ℝ) (n : ℕ) : ℝ :=
  ∑ i ∈ range n, (t (i + 1) - t i) * D (t (i + 1))

/-- Helper: one flat-spread coupon over a period of length `α` starting at `x`. -/
theorem flat_term_aux (D : ℝ → ℝ) (hD : ∀ t, 0 < D t) (α b x : ℝ) (hα : 0 < α) :
    ((x + α) - x) * fwdRate (fun s => D s * Real.exp (-b * s)) x (x + α) * D (x + α) =
      Real.exp (b * α) * D x - D (x + α) := by
  unfold fwdRate
  have h1 : Real.exp (-b * x) = Real.exp (b * α) * Real.exp (-b * (x + α)) := by
    rw [← Real.exp_add]; congr 1; ring
  have hDx := hD (x + α)
  have he := Real.exp_pos (-b * (x + α))
  simp only
  rw [show x + α - x = α by ring, h1]
  field_simp

/-- Helper: the flat-spread leg in summed form. -/
theorem flat_leg_aux (D : ℝ → ℝ) (hD0 : D 0 = 1) (hD : ∀ t, 0 < D t) (α b : ℝ) (hα : 0 < α)
    (n : ℕ) :
    floatingLeg D (fun s => D s * Real.exp (-b * s)) (fun i : ℕ => (i : ℝ) * α) n =
      (1 - D (n * α)) + (Real.exp (b * α) - 1) * ∑ i ∈ range n, D (i * α) := by
  unfold floatingLeg
  rw [Finset.sum_congr rfl (g := fun i : ℕ => Real.exp (b * α) * D (i * α) - D (((i + 1 : ℕ) : ℝ) * α))]
  · rw [Finset.sum_sub_distrib, ← Finset.mul_sum]
    have tel := Finset.sum_range_sub (fun i : ℕ => D ((i : ℝ) * α)) n
    simp only [Nat.cast_zero, zero_mul, hD0] at tel
    rw [Finset.sum_sub_distrib] at tel
    linarith
  · intro i _
    have := flat_term_aux D hD α b ((i : ℝ) * α) hα
    simp only
    rw [show (((i + 1 : ℕ) : ℝ)) * α = (i : ℝ) * α + α by push_cast; ring]
    exact this

/-- Helper: with one curve every schedule telescopes. -/
theorem single_curve_aux (D : ℝ → ℝ) (hD0 : D 0 = 1) (hD : ∀ t, 0 < D t)
    (t : ℕ → ℝ) (ht0 : t 0 = 0) (ht : StrictMono t) (n : ℕ) :
    floatingLeg D D t n = 1 - D (t n) := by
  unfold floatingLeg
  rw [Finset.sum_congr rfl (g := fun i : ℕ => D (t i) - D (t (i + 1)))]
  · rw [Finset.sum_range_sub', ht0, hD0]
  · intro i _
    have hne : t (i + 1) - t i ≠ 0 := sub_ne_zero.mpr (ht (Nat.lt_succ_self i)).ne'
    have hDp := hD (t (i + 1))
    unfold fwdRate
    field_simp

/-- Step 3, the closed form. Take any discount curve `D` with `D 0 = 1` and every discount
factor positive, an accrual fraction `α > 0`, `n` periods paying at `α, 2α, …, nα`, and the
flat-spread forecast curve `H(t) = D(t) e^{−bt}` for any spread `b`. Then the floating leg is
the overnight floater plus an extra coupon of `e^{bα} − 1` each period discounted from the
period's start: `C = (1 − D(T)) + (e^{bα} − 1) ∑ D(t_{i−1})`, with `T = nα`. -/
theorem flat_spread_leg_eq_floater_add_spread_annuity
    (D : ℝ → ℝ) (hD0 : D 0 = 1) (hD : ∀ t, 0 < D t) (α b : ℝ) (hα : 0 < α) (n : ℕ) :
    floatingLeg D (fun s => D s * Real.exp (-b * s)) (fun i : ℕ => (i : ℝ) * α) n =
      (1 - D (n * α)) + (Real.exp (b * α) - 1) * ∑ i ∈ range n, D (i * α) := by
  exact flat_leg_aux D hD0 hD α b hα n

/-- Step 1, one curve forces the basis to zero. If the index is forecast off the discount
curve itself (`H = D`), with `D 0 = 1` and every discount factor positive, then on any
schedule of payment dates `0 = t 0 < t 1 < … < t n` the coupons telescope and the leg is worth
`1 − D(t n)`, whatever the period lengths. So a second schedule `u` with `m` periods ending on
the same date gives the same leg, and the fair spread `(C_u − C_t) / A_t` on the first leg is
zero. -/
theorem single_curve_leg_telescopes_and_basis_eq_zero
    (D : ℝ → ℝ) (hD0 : D 0 = 1) (hD : ∀ t, 0 < D t)
    (t u : ℕ → ℝ) (ht0 : t 0 = 0) (hu0 : u 0 = 0) (ht : StrictMono t) (hu : StrictMono u)
    (n m : ℕ) (hT : u m = t n) :
    floatingLeg D D t n = 1 - D (t n) ∧
      (floatingLeg D D u m - floatingLeg D D t n) / annuity D t n = 0 := by
  have h1 := single_curve_aux D hD0 hD t ht0 ht n
  have h2 := single_curve_aux D hD0 hD u hu0 hu m
  refine ⟨h1, ?_⟩
  rw [h1, h2, hT, sub_self, zero_div]

/-- One quote, one spread. With `D 0 = 1`, every discount factor positive, `α > 0`, `n ≥ 1`
periods and the flat-spread forecast curve `H(t) = D(t) e^{−bt}`, let `C` be a quoted leg value
with `(C − 1 + D(T)) / ∑ D(t_{i−1}) > −1`. Then the leg equals `C` for exactly one spread:
`b = (1/α) ln(1 + (C − 1 + D(T)) / ∑ D(t_{i−1}))`. -/
theorem one_quote_one_spread
    (D : ℝ → ℝ) (hD0 : D 0 = 1) (hD : ∀ t, 0 < D t) (α : ℝ) (hα : 0 < α) (n : ℕ) (hn : 1 ≤ n)
    (C : ℝ) (hC : -1 < (C - 1 + D (n * α)) / ∑ i ∈ range n, D (i * α)) (b : ℝ) :
    floatingLeg D (fun s => D s * Real.exp (-b * s)) (fun i : ℕ => (i : ℝ) * α) n = C ↔
      b = (1 / α) * Real.log (1 + (C - 1 + D (n * α)) / ∑ i ∈ range n, D (i * α)) := by
  rw [flat_leg_aux D hD0 hD α b hα n]
  have hS : 0 < ∑ i ∈ range n, D (i * α) :=
    Finset.sum_pos (fun i _ => hD _) (Finset.nonempty_range_iff.mpr (by omega))
  set S := ∑ i ∈ range n, D (i * α) with hSdef
  set q := (C - 1 + D (n * α)) / S with hq
  have hq1 : 0 < 1 + q := by linarith
  have key : (1 - D (n * α)) + (Real.exp (b * α) - 1) * S = C ↔ Real.exp (b * α) = 1 + q := by
    rw [hq]
    constructor
    · intro h
      have h' : Real.exp (b * α) - 1 = (C - 1 + D (n * α)) / S := by
        rw [eq_div_iff hS.ne']; linarith
      linarith
    · intro h
      rw [h, add_sub_cancel_left, div_mul_cancel₀ _ hS.ne']
      ring
  rw [key]
  constructor
  · intro h
    have := congrArg Real.log h
    rw [Real.log_exp] at this
    rw [← this]; field_simp
  · intro h
    rw [h, show 1 / α * Real.log (1 + q) * α = Real.log (1 + q) by field_simp]
    exact Real.exp_log hq1

-- Five years hold twenty quarterly coupons and ten half-yearly ones.
example : (5 : ℚ) / (1 / 4) = 20 ∧ (5 : ℚ) / (1 / 2) = 10 := by norm_num

-- The fixed payer pays 4.5% for a leg quoted at 4.75%: 25 bp a year on 10,000,000 dollars
-- is 25,000 dollars a year.
example : ((475 : ℚ) / 10000 - 45 / 1000) * 10000000 = 25000 := by norm_num

-- The wrong 6-month par rate: 4.75% plus 8 bp read as a par-rate gap is 4.83%.
example : (475 : ℚ) / 10000 + 8 / 10000 = 483 / 10000 := by norm_num

-- A basis swap struck at 10 bp when the fair basis is 8 bp pays 2 bp a year over fair:
-- on 10,000,000 dollars that is 2,000 dollars a year before discounting.
example : ((10 : ℚ) - 8) / 10000 * 10000000 = 2000 := by norm_num

#print axioms flat_term_aux
#print axioms flat_leg_aux
#print axioms single_curve_aux
#print axioms flat_spread_leg_eq_floater_add_spread_annuity
#print axioms single_curve_leg_telescopes_and_basis_eq_zero
#print axioms one_quote_one_spread
