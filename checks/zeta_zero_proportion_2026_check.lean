-- The August 2026 zeta-zeros claim: the counting step "simple points on the line number at least twice the total minus the pair energy" holds for every finite set of points, and the flat and cosine windows give Q = 1/(2w) + 2w/3 and Q = 1/2 + cot(1/√2)/√2, so the bounds 2/3 and 0.6725007 are exact arithmetic.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Finset

/-- The window constant of the card: for a window `g` that lives on `[-w, w]`,
`Q(g) = (∫ g² + ∬ g(x) g(y) |x - y|) / (∫ g)²`. -/
noncomputable def windowQ (w : ℝ) (g : ℝ → ℝ) : ℝ :=
  ((∫ x in (-w)..w, g x ^ 2) +
      ∫ x in (-w)..w, ∫ y in (-w)..w, g x * g y * |x - y|) /
    (∫ x in (-w)..w, g x) ^ 2

lemma abs_split_integral (g : ℝ → ℝ) (hg : Continuous g) {w x : ℝ} (h1 : -w ≤ x) (h2 : x ≤ w) :
    ∫ y in (-w)..w, g y * |x - y| =
      (∫ y in (-w)..x, g y * (x - y)) + ∫ y in x..w, g y * (y - x) := by
  have hc : Continuous fun y => g y * |x - y| := by fun_prop
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := x)
    (hc.intervalIntegrable _ _) (hc.intervalIntegrable _ _)]
  congr 1
  · apply intervalIntegral.integral_congr
    intro y hy
    rw [Set.uIcc_of_le h1] at hy
    simp only
    rw [abs_of_nonneg (by linarith [hy.2])]
  · apply intervalIntegral.integral_congr
    intro y hy
    rw [Set.uIcc_of_le h2] at hy
    simp only
    rw [abs_of_nonpos (by linarith [hy.1])]
    ring

lemma flat_inner {w x : ℝ} (h1 : -w ≤ x) (h2 : x ≤ w) :
    ∫ y in (-w)..w, (1 : ℝ) * |x - y| = x ^ 2 + w ^ 2 := by
  rw [abs_split_integral (fun _ => (1 : ℝ)) continuous_const h1 h2]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun y => -(x - y) ^ 2 / 2)
    (fun y _ => ((((hasDerivAt_id' y).const_sub x).fun_pow 2).fun_neg.div_const 2).congr_deriv
      (by norm_num))
    ((by fun_prop : Continuous fun y : ℝ => (1:ℝ) * (x - y)).intervalIntegrable _ _)]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun y => (y - x) ^ 2 / 2)
    (fun y _ => ((((hasDerivAt_id' y).sub_const x).fun_pow 2).div_const 2).congr_deriv
      (by norm_num))
    ((by fun_prop : Continuous fun y : ℝ => (1:ℝ) * (y - x)).intervalIntegrable _ _)]
  ring

lemma hasDerivAt_sin_mul_div (a y : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun y => Real.sin (a * y) / a) (Real.cos (a * y)) y :=
  (((hasDerivAt_id' y).const_mul a).sin.div_const a).congr_deriv (by field_simp)

lemma hasDerivAt_cos_mul_div (a y : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun y => Real.cos (a * y) / a ^ 2) (-(Real.sin (a * y) / a)) y :=
  (((hasDerivAt_id' y).const_mul a).cos.div_const (a ^ 2)).congr_deriv (by field_simp)

lemma integral_cos_mul (a w : ℝ) (ha : a ≠ 0) :
    ∫ x in (-w)..w, Real.cos (a * x) = 2 * Real.sin (a * w) / a := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hasDerivAt_sin_mul_div a y ha)
    ((by fun_prop : Continuous fun y : ℝ => Real.cos (a * y)).intervalIntegrable _ _)]
  rw [mul_neg, Real.sin_neg]
  ring

lemma integral_cos_mul_sq (a w : ℝ) (ha : a ≠ 0) :
    ∫ x in (-w)..w, Real.cos (a * x) ^ 2 = w + Real.sin (2 * a * w) / (2 * a) := by
  have hd : ∀ y : ℝ, HasDerivAt (fun y => y / 2 + Real.sin (2 * a * y) / (4 * a))
      (Real.cos (a * y) ^ 2) y := by
    intro y
    refine (((hasDerivAt_id' y).div_const 2).fun_add
      (((hasDerivAt_id' y).const_mul (2 * a)).sin.div_const (4 * a))).congr_deriv ?_
    rw [Real.cos_sq (a * y)]
    field_simp
    ring_nf
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hd y)
    ((by fun_prop : Continuous fun y : ℝ => Real.cos (a * y) ^ 2).intervalIntegrable _ _)]
  rw [mul_neg, Real.sin_neg]
  field_simp
  ring

lemma cos_inner {a w x : ℝ} (ha : a ≠ 0) (h1 : -w ≤ x) (h2 : x ≤ w) :
    ∫ y in (-w)..w, Real.cos (a * y) * |x - y| =
      2 * w * Real.sin (a * w) / a + 2 * Real.cos (a * w) / a ^ 2 -
        2 * Real.cos (a * x) / a ^ 2 := by
  rw [abs_split_integral (fun y => Real.cos (a * y)) (by fun_prop) h1 h2]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun y => (x - y) * (Real.sin (a * y) / a) - Real.cos (a * y) / a ^ 2)
    (fun y _ => (((hasDerivAt_id' y).const_sub x).fun_mul (hasDerivAt_sin_mul_div a y ha)).fun_sub
      (hasDerivAt_cos_mul_div a y ha) |>.congr_deriv (by ring))
    ((by fun_prop : Continuous fun y : ℝ => Real.cos (a * y) * (x - y)).intervalIntegrable _ _)]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun y => (y - x) * (Real.sin (a * y) / a) + Real.cos (a * y) / a ^ 2)
    (fun y _ => (((hasDerivAt_id' y).sub_const x).fun_mul (hasDerivAt_sin_mul_div a y ha)).fun_add
      (hasDerivAt_cos_mul_div a y ha) |>.congr_deriv (by ring))
    ((by fun_prop : Continuous fun y : ℝ => Real.cos (a * y) * (y - x)).intervalIntegrable _ _)]
  simp only [mul_neg, Real.sin_neg, Real.cos_neg]
  field_simp
  ring

lemma cos_double {a w : ℝ} (ha : a ≠ 0) (hw : 0 ≤ w) :
    (∫ x in (-w)..w, ∫ y in (-w)..w, Real.cos (a * x) * Real.cos (a * y) * |x - y|) =
      (2 * w * Real.sin (a * w) / a + 2 * Real.cos (a * w) / a ^ 2) * (2 * Real.sin (a * w) / a) -
        2 / a ^ 2 * (w + Real.sin (2 * a * w) / (2 * a)) := by
  have hin : (∫ x in (-w)..w, ∫ y in (-w)..w, Real.cos (a * x) * Real.cos (a * y) * |x - y|) =
      ∫ x in (-w)..w, ((2 * w * Real.sin (a * w) / a + 2 * Real.cos (a * w) / a ^ 2) *
        Real.cos (a * x) - 2 / a ^ 2 * Real.cos (a * x) ^ 2) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by linarith)] at hx
    simp only [mul_assoc]
    rw [intervalIntegral.integral_const_mul, cos_inner ha hx.1 hx.2]
    ring
  rw [hin, intervalIntegral.integral_sub
    ((by fun_prop : Continuous fun x : ℝ => (2 * w * Real.sin (a * w) / a +
      2 * Real.cos (a * w) / a ^ 2) * Real.cos (a * x)).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun x : ℝ => 2 / a ^ 2 * Real.cos (a * x) ^ 2).intervalIntegrable _ _),
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_cos_mul a w ha, integral_cos_mul_sq a w ha]

#print axioms abs_split_integral
#print axioms flat_inner
#print axioms hasDerivAt_sin_mul_div
#print axioms hasDerivAt_cos_mul_div
#print axioms integral_cos_mul
#print axioms integral_cos_mul_sq
#print axioms cos_inner
#print axioms cos_double

/-- The counting lemma on the line (Step 0 and Step 1 of the card). Take finitely many
distinct points `z` on the real line, the point `z` repeated `m z` times, and any real
score `K` with `K 0 = 1`. Let `N` be the total count with repeats and
`E = Σ_z Σ_s m(z) m(s) K(z - s)²` the pair energy, self-pairs included. Then the number
of simple points (those with `m z = 1`) is at least `2N - E`. -/
theorem simple_count_ge_two_mul_total_sub_energy (s : Finset ℝ) (m : ℝ → ℕ) (K : ℝ → ℝ)
    (hK : K 0 = 1) :
    2 * (∑ z ∈ s, (m z : ℝ)) -
        ∑ z ∈ s, ∑ t ∈ s, (m z : ℝ) * (m t : ℝ) * K (z - t) ^ 2 ≤
      ((s.filter (fun z => m z = 1)).card : ℝ) := by
  have hE : ∑ z ∈ s, (m z : ℝ) ^ 2 ≤
      ∑ z ∈ s, ∑ t ∈ s, (m z : ℝ) * (m t : ℝ) * K (z - t) ^ 2 := by
    apply Finset.sum_le_sum
    intro z hz
    have h := Finset.single_le_sum (f := fun t => (m z : ℝ) * (m t : ℝ) * K (z - t) ^ 2)
      (fun t _ => by positivity) hz
    simpa [hK, sq] using h
  have hC : ((s.filter (fun z => m z = 1)).card : ℝ) =
      ∑ z ∈ s, (if m z = 1 then (1 : ℝ) else 0) := by
    rw [Finset.card_filter]; push_cast; rfl
  have hP : ∀ z ∈ s, 2 * (m z : ℝ) - (m z : ℝ) ^ 2 ≤ (if m z = 1 then (1 : ℝ) else 0) := by
    intro z _
    rcases Nat.lt_or_ge (m z) 2 with h | h
    · interval_cases hm : m z <;> norm_num
    · have h1 : m z ≠ 1 := by omega
      have h2 : (2 : ℝ) ≤ m z := by exact_mod_cast h
      simp only [h1, ↓reduceIte]; nlinarith
  rw [hC]
  calc 2 * (∑ z ∈ s, (m z : ℝ)) - ∑ z ∈ s, ∑ t ∈ s, (m z : ℝ) * (m t : ℝ) * K (z - t) ^ 2
      ≤ 2 * (∑ z ∈ s, (m z : ℝ)) - ∑ z ∈ s, (m z : ℝ) ^ 2 := by linarith
    _ = ∑ z ∈ s, (2 * (m z : ℝ) - (m z : ℝ) ^ 2) := by
        rw [Finset.sum_sub_distrib, Finset.mul_sum]
    _ ≤ _ := Finset.sum_le_sum hP

/-- The flat window `g = 1` on `[-w, w]` has `Q = 1/(2w) + 2w/3`. At the allowed width
`w = 1/2` this is `4/3`, Montgomery's bound `2 - 4/3 = 2/3`; at `w = 1`, which uses the
unproved range of pair correlation, it is `7/6`, the bound `5/6 ≈ 0.8333` that proves
nothing. -/
theorem flat_window_Q (w : ℝ) (hw : 0 < w) :
    windowQ w (fun _ => 1) = 1 / (2 * w) + 2 * w / 3 := by
  unfold windowQ
  have hin : (∫ x in (-w)..w, ∫ y in (-w)..w, (fun _ => (1 : ℝ)) x * (fun _ => (1 : ℝ)) y * |x - y|)
      = ∫ x in (-w)..w, (x ^ 2 + w ^ 2) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by linarith)] at hx
    simp only [one_mul]
    rw [← flat_inner hx.1 hx.2]
    simp
  rw [hin]
  simp only [one_pow, intervalIntegral.integral_const, smul_eq_mul, mul_one]
  rw [intervalIntegral.integral_add ((by fun_prop : Continuous fun x : ℝ => x ^ 2).intervalIntegrable _ _)
    intervalIntegrable_const]
  rw [integral_pow, intervalIntegral.integral_const, smul_eq_mul]
  field_simp
  ring

/-- The Montgomery–Taylor window `g(x) = cos(√2 x)` on `[-1/2, 1/2]` has the closed form
`Q = 1/2 + cot(1/√2)/√2 ≈ 1.3274993`, so the bound `2 - Q` is `0.6725007`. -/
theorem cos_sqrt_two_window_Q :
    windowQ (1 / 2) (fun x => Real.cos (Real.sqrt 2 * x)) =
      1 / 2 + Real.cot (1 / Real.sqrt 2) / Real.sqrt 2 := by
  have hs0 : 0 < Real.sqrt 2 := by positivity
  have hs : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  unfold windowQ
  simp only
  rw [cos_double hs0.ne' (by norm_num), integral_cos_mul_sq _ _ hs0.ne',
    integral_cos_mul _ _ hs0.ne']
  set s := Real.sqrt 2 with hsdef
  have hc : s * (1 / 2) = 1 / s := by field_simp; nlinarith
  have hc2 : 2 * s * (1 / 2) = 2 * (1 / s) := by rw [← hc]; ring
  rw [hc, hc2, Real.sin_two_mul, Real.cot_eq_cos_div_sin]
  have hS : 0 < Real.sin (1 / s) := by
    apply Real.sin_pos_of_pos_of_lt_pi (by positivity)
    have : 1 < s := by nlinarith
    have : 1 / s < 1 := by rw [div_lt_one hs0]; exact this
    linarith [Real.two_le_pi]
  set S := Real.sin (1 / s)
  set C := Real.cos (1 / s)
  field_simp
  linear_combination (s + 2 * S * C) * hs

/-! ### The card's exact worked numbers -/

-- Flat window: Q = 1 + 1/3 = 4/3 and the bound 2 - 4/3 = 2/3.
example : (1 : ℚ) + 1 / 3 = 4 / 3 ∧ (2 : ℚ) - 4 / 3 = 2 / 3 := by norm_num

-- What breaks: window on [-1, 1] gives Q = 7/6 and bound 5/6; dropping the |α| term
-- leaves Q = 1 and the bound 1, "every zero simple".
example : (1 : ℚ) / (2 * 1) + 2 * 1 / 3 = 7 / 6 ∧ (2 : ℚ) - 7 / 6 = 5 / 6 := by norm_num
example : (1 : ℚ) / (2 * (1 / 2)) = 1 ∧ (2 : ℚ) - 1 = 1 := by norm_num

-- One point of multiplicity m: m(2 - m) minus [m = 1] is at most 0, for m ≤ 49.
example : ∀ m ∈ Finset.range 50, (m : ℤ) * (2 - m) - (if m = 1 then 1 else 0) ≤ 0 := by
  decide

-- The toy set of 6 zeros, coordinates scaled by 10: 0, 1.5, 3 ± 0.3i, and 5 twice.
-- Simple points on the line: 2. Naive count of lone points: 4.
example :
    let toy : List (ℤ × ℤ) := [(0, 0), (15, 0), (30, 3), (30, -3), (50, 0), (50, 0)]
    (toy.filter (fun z => z.2 = 0 ∧ toy.count z = 1)).length = 2 ∧
      (toy.filter (fun z => toy.count z = 1)).length = 4 := by
  decide

#print axioms simple_count_ge_two_mul_total_sub_energy
#print axioms flat_window_Q
#print axioms cos_sqrt_two_window_Q
