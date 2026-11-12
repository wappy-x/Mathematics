-- Richardson extrapolation: four times the central difference at bump h, minus the one at bump 2h, over 3, has error -h^4/30 times the fifth derivative plus at most h^5 M₆/60, and the same weighting removes a known leading error power from any method.
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Order.Filter.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Asymptotics.Lemmas
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-! `P` is the price as a function of the yield `x` (any real function will do), `x₀` the point
where the slope is wanted, and `h > 0` the bump each way. "Six continuous derivatives between
`x₀ - 2h` and `x₀ + 2h`" is Mathlib's `ContDiffOn ℝ 6 P (Icc (x₀ - 2h) (x₀ + 2h))`, and every
derivative, `P'`, `P^(5)` and `P^(6)`, is taken within that interval with `iteratedDerivWithin`.
`M` is the card's `M₆`, a ceiling on `|P^(6)|` across the interval. -/

open Set Filter Asymptotics Topology

theorem rx_iDW_eq (P : ℝ → ℝ) (S : Set ℝ) (a y z : ℝ) (k : ℕ) (hk : k ≤ 6)
    (hS : UniqueDiffOn ℝ S) (hsub : uIcc a y ⊆ S) (hay : a ≠ y)
    (hP : ContDiffOn ℝ 6 P S) (hz : z ∈ uIcc a y) :
    iteratedDerivWithin k P (uIcc a y) z = iteratedDerivWithin k P S z := by
  rw [iteratedDerivWithin_eq_iteratedFDerivWithin, iteratedDerivWithin_eq_iteratedFDerivWithin,
    iteratedFDerivWithin_subset hsub (uniqueDiffOn_uIcc hay) hS (hP.of_le (by exact_mod_cast hk)) hz]

#print axioms rx_iDW_eq

theorem rx_taylor_six (P : ℝ → ℝ) (S : Set ℝ) (a y : ℝ)
    (hS : UniqueDiffOn ℝ S) (hsub : uIcc a y ⊆ S) (hay : a ≠ y)
    (hP : ContDiffOn ℝ 6 P S) :
    ∃ ξ ∈ S, P y = P a + iteratedDerivWithin 1 P S a * (y - a)
      + iteratedDerivWithin 2 P S a * (y - a) ^ 2 / 2
      + iteratedDerivWithin 3 P S a * (y - a) ^ 3 / 6
      + iteratedDerivWithin 4 P S a * (y - a) ^ 4 / 24
      + iteratedDerivWithin 5 P S a * (y - a) ^ 5 / 120
      + iteratedDerivWithin 6 P S ξ * (y - a) ^ 6 / 720 := by
  have hu : UniqueDiffOn ℝ (uIcc a y) := uniqueDiffOn_uIcc hay
  have hP' : ContDiffOn ℝ 6 P (uIcc a y) := hP.mono hsub
  have hd : DifferentiableOn ℝ (iteratedDerivWithin 5 P (uIcc a y)) (uIcc a y) :=
    hP'.differentiableOn_iteratedDerivWithin (by norm_num) hu
  obtain ⟨ξ, hξ, h⟩ := taylor_mean_remainder_lagrange (n := 5) hay (hP'.of_le (by norm_num))
    (hd.mono uIoo_subset_uIcc_self)
  have hξ' : ξ ∈ uIcc a y := uIoo_subset_uIcc_self hξ
  have ha : a ∈ uIcc a y := left_mem_uIcc
  refine ⟨ξ, hsub hξ', ?_⟩
  rw [taylor_within_apply] at h
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, smul_eq_mul] at h
  rw [rx_iDW_eq P S a y ξ 6 le_rfl hS hsub hay hP hξ'] at h
  rw [rx_iDW_eq P S a y a 1 (by norm_num) hS hsub hay hP ha,
    rx_iDW_eq P S a y a 2 (by norm_num) hS hsub hay hP ha,
    rx_iDW_eq P S a y a 3 (by norm_num) hS hsub hay hP ha,
    rx_iDW_eq P S a y a 4 (by norm_num) hS hsub hay hP ha,
    rx_iDW_eq P S a y a 5 (by norm_num) hS hsub hay hP ha,
    iteratedDerivWithin_zero] at h
  simp only [Nat.factorial] at h
  push_cast at h
  linear_combination h

#print axioms rx_taylor_six

/-- The central difference `D(h) = (P(x₀ + h) - P(x₀ - h)) / (2h)`. -/
noncomputable def centralDiff (P : ℝ → ℝ) (x₀ h : ℝ) : ℝ :=
  (P (x₀ + h) - P (x₀ - h)) / (2 * h)

/-- Richardson's combination of the bumps `h` and `2h`: `R(h) = (4 D(h) - D(2h)) / 3`. -/
noncomputable def richardson (P : ℝ → ℝ) (x₀ h : ℝ) : ℝ :=
  (4 * centralDiff P x₀ h - centralDiff P x₀ (2 * h)) / 3

/-- Richardson's error, with its remainder: if `P` has six continuous derivatives on
`[x₀ - 2h, x₀ + 2h]` and `|P^(6)| ≤ M` there, then `R(h) = (4 D(h) - D(2h)) / 3` equals
`P'(x₀) - h^4/30 · P^(5)(x₀)` up to an error of at most `h^5 M / 60`. The step-squared
term of the central difference has cancelled. -/
theorem richardson_error_bound (P : ℝ → ℝ) (x₀ h M : ℝ) (hh : 0 < h)
    (hP : ContDiffOn ℝ 6 P (Icc (x₀ - 2 * h) (x₀ + 2 * h)))
    (hM : ∀ x ∈ Icc (x₀ - 2 * h) (x₀ + 2 * h),
      |iteratedDerivWithin 6 P (Icc (x₀ - 2 * h) (x₀ + 2 * h)) x| ≤ M) :
    |richardson P x₀ h - iteratedDerivWithin 1 P (Icc (x₀ - 2 * h) (x₀ + 2 * h)) x₀
        + h ^ 4 / 30 * iteratedDerivWithin 5 P (Icc (x₀ - 2 * h) (x₀ + 2 * h)) x₀|
      ≤ h ^ 5 * M / 60 := by
  set S := Icc (x₀ - 2 * h) (x₀ + 2 * h) with hSdef
  have hS : UniqueDiffOn ℝ S := uniqueDiffOn_Icc (by linarith)
  have mem : ∀ t, |t| ≤ 2 * h → x₀ + t ∈ S := by
    intro t ht
    rw [abs_le] at ht
    constructor <;> linarith
  have sub : ∀ t, |t| ≤ 2 * h → uIcc x₀ (x₀ + t) ⊆ S := by
    intro t ht
    have h0 := mem 0 (by simp; linarith)
    simp only [add_zero] at h0
    exact uIcc_subset_Icc h0 (mem t ht)
  have ne : ∀ t, t ≠ 0 → x₀ ≠ x₀ + t := fun t ht h => ht (by linarith)
  obtain ⟨ξ1, hξ1, e1⟩ := rx_taylor_six P S x₀ (x₀ + h) hS
    (sub h (by rw [abs_of_pos hh]; linarith)) (ne h hh.ne') hP
  obtain ⟨ξ2, hξ2, e2⟩ := rx_taylor_six P S x₀ (x₀ + -h) hS
    (sub (-h) (by rw [abs_neg, abs_of_pos hh]; linarith)) (ne (-h) (by linarith)) hP
  obtain ⟨ξ3, hξ3, e3⟩ := rx_taylor_six P S x₀ (x₀ + 2 * h) hS
    (sub (2 * h) (by rw [abs_of_pos (by linarith)])) (ne (2 * h) (by linarith)) hP
  obtain ⟨ξ4, hξ4, e4⟩ := rx_taylor_six P S x₀ (x₀ + -(2 * h)) hS
    (sub (-(2 * h)) (by rw [abs_neg, abs_of_pos (by linarith)])) (ne (-(2 * h)) (by linarith)) hP
  rw [← sub_eq_add_neg] at e2 e4
  have key : richardson P x₀ h - iteratedDerivWithin 1 P S x₀
        + h ^ 4 / 30 * iteratedDerivWithin 5 P S x₀
      = h ^ 5 * (4 * (iteratedDerivWithin 6 P S ξ1 - iteratedDerivWithin 6 P S ξ2)
        - 32 * (iteratedDerivWithin 6 P S ξ3 - iteratedDerivWithin 6 P S ξ4)) / 4320 := by
    unfold richardson centralDiff
    rw [e1, e2, e3, e4]
    field_simp
    ring
  rw [key]
  have b1 := hM ξ1 hξ1
  have b2 := hM ξ2 hξ2
  have b3 := hM ξ3 hξ3
  have b4 := hM ξ4 hξ4
  have hX : |4 * (iteratedDerivWithin 6 P S ξ1 - iteratedDerivWithin 6 P S ξ2)
        - 32 * (iteratedDerivWithin 6 P S ξ3 - iteratedDerivWithin 6 P S ξ4)| ≤ 72 * M := by
    rw [abs_le] at b1 b2 b3 b4 ⊢
    constructor <;> linarith [b1.1, b1.2, b2.1, b2.2, b3.1, b3.2, b4.1, b4.2]
  have h5 : 0 < h ^ 5 := by positivity
  rw [abs_div, abs_mul, abs_of_pos h5, abs_of_pos (by norm_num : (0:ℝ) < 4320)]
  have := mul_le_mul_of_nonneg_left hX h5.le
  rw [div_le_iff₀ (by norm_num)]
  nlinarith

/-- The general rule: if a method's answer `A(s)` is the true value `L` plus `c s^p` plus an
error of size `s^q` (the higher powers) as the step `s → 0`, and the step ratio `r` has
`r^p ≠ 1`, then the combination `(r^p A(h) - A(r h)) / (r^p - 1)` differs from `L` by an error
of size `h^q` as `h → 0`: the `c h^p` term is gone, whatever `c` is. -/
theorem richardson_general_rule (A : ℝ → ℝ) (L c r : ℝ) (p q : ℕ) (hr : r ^ p ≠ 1)
    (hA : (fun s => A s - L - c * s ^ p) =O[𝓝 0] (fun s => s ^ q)) :
    (fun h => (r ^ p * A h - A (r * h)) / (r ^ p - 1) - L) =O[𝓝 0] (fun h => h ^ q) := by
  have hr' : r ^ p - 1 ≠ 0 := sub_ne_zero.mpr hr
  have ht : Tendsto (fun h : ℝ => r * h) (𝓝 0) (𝓝 0) := by
    have := ((continuous_const_mul r).tendsto 0)
    simpa using this
  have h1 : (fun h => A (r * h) - L - c * (r * h) ^ p) =O[𝓝 0] (fun h : ℝ => (r * h) ^ q) :=
    hA.comp_tendsto ht
  have h2 : (fun h : ℝ => (r * h) ^ q) =O[𝓝 0] (fun h : ℝ => h ^ q) := by
    simp_rw [mul_pow]
    exact (isBigO_refl _ _).const_mul_left _
  have h3 := ((hA.const_mul_left (r ^ p)).sub (h1.trans h2)).const_mul_left ((r ^ p - 1)⁻¹)
  refine h3.congr_left fun h => ?_
  field_simp
  ring

/-- Spread over the four prices, `R(h)` is the five-point stencil: weights `1, -8, 8, -1`
over `12h` on `P(x₀ - 2h), P(x₀ - h), P(x₀ + h), P(x₀ + 2h)`. -/
theorem richardson_eq_five_point_stencil (P : ℝ → ℝ) (x₀ h : ℝ) (hh : h ≠ 0) :
    richardson P x₀ h =
      (P (x₀ - 2 * h) - 8 * P (x₀ - h) + 8 * P (x₀ + h) - P (x₀ + 2 * h)) / (12 * h) := by
  unfold richardson centralDiff
  field_simp
  ring

/-! The card's whole-number arithmetic. -/

-- Step 2: D(h) carries h^4/120 · P^(5) and D(2h) sixteen times that, so R(h) keeps
-- (4 - 16)/3 · 1/120 = -1/30 of h^4 P^(5).
example : ((4 : ℚ) - 16) / 3 * (1 / 120) = -1 / 30 := by norm_num
-- The proof's remainders total (4 h^5 + 32 h^5)/720 · M₆; divided by 3 that is h^5 M₆/60.
example : ((4 : ℚ) + 32) / 720 / 3 = 1 / 60 := by norm_num
-- The general rule with step ratio r = 2 and error power p = 2 gives the weights 4 and 3.
example : (2 : ℚ) ^ 2 = 4 ∧ (2 : ℚ) ^ 2 - 1 = 3 := by norm_num
-- Bumps of 1 and 3 bp need r^p = 3^2 = 9, and divide by 8.
example : (3 : ℚ) ^ 2 = 9 ∧ (3 : ℚ) ^ 2 - 1 = 8 := by norm_num
-- Step 4: weights 4/3 · 1/(2h) and 1/3 · 1/(4h), each used twice, give rounding 3/2 · η/h.
example : 2 * ((4 : ℚ) / 3 * (1 / 2) + 1 / 3 * (1 / 4)) = 3 / 2 := by norm_num
-- Setting the slope of h^4 |P^(5)|/30 + 3/2 · η/h to zero: h^5 = (3/2 · 30 / 4) η/|P^(5)| = 45/4 · η/|P^(5)|.
example : (3 : ℚ) / 2 * 30 / 4 = 45 / 4 := by norm_num

#print axioms richardson_error_bound
#print axioms richardson_general_rule
#print axioms richardson_eq_five_point_stencil
