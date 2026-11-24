-- Particle filters: the effective sample size of N weights that add to 1 lies between 1 and N, and systematic resampling gives each particle within 1 of its fair share N times its weight.
import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.Chebyshev
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Finset

/-- Helper: the natural-number ceiling of a number above -1 is less than one above it. -/
theorem natCeil_sub_lt_one_of_gt_neg_one (z : ℝ) (hz : -1 < z) : ((⌈z⌉₊ : ℕ) : ℝ) - z < 1 := by
  rcases le_or_gt z 0 with h | h
  · rw [Nat.ceil_eq_zero.mpr h]; simp; linarith
  · have := Nat.ceil_lt_add_one (R := ℝ) h.le; linarith

#print axioms natCeil_sub_lt_one_of_gt_neg_one

/-- The effective sample size never leaves its range: if N weights are nonnegative and add to 1,
then one over the sum of their squares is at least 1 and at most N. -/
theorem ess_between_one_and_card {N : ℕ} (W : Fin N → ℝ) (hW : ∀ i, 0 ≤ W i)
    (hsum : ∑ i, W i = 1) :
    1 ≤ 1 / ∑ i, W i ^ 2 ∧ 1 / ∑ i, W i ^ 2 ≤ N := by
  have hpos : 0 < ∑ i, W i ^ 2 := by
    by_contra h
    push Not at h
    have h0 : ∀ i ∈ (univ : Finset (Fin N)), W i ^ 2 = 0 :=
      (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => sq_nonneg (W i))).mp
        (le_antisymm h (Finset.sum_nonneg (fun i _ => sq_nonneg (W i))))
    have : ∑ i, W i = 0 := Finset.sum_eq_zero (fun i hi => pow_eq_zero_iff (n := 2) (by norm_num) |>.mp (h0 i hi))
    linarith
  have hle1 : ∀ i, W i ≤ 1 := by
    intro i
    rw [← hsum]
    exact Finset.single_le_sum (fun k _ => hW k) (Finset.mem_univ i)
  have hsq : ∑ i, W i ^ 2 ≤ 1 := by
    rw [← hsum]
    refine Finset.sum_le_sum (fun i _ => ?_)
    nlinarith [hW i, hle1 i]
  have hcs := sq_sum_le_card_mul_sum_sq (s := (univ : Finset (Fin N))) (f := W)
  rw [hsum, Finset.card_univ, Fintype.card_fin] at hcs
  constructor
  · rw [le_div_iff₀ hpos]; linarith
  · rw [div_le_iff₀ hpos]; linarith

/-- The two ends of the range: equal weights 1/N give an effective sample size of N,
and all the weight on one particle gives 1. -/
theorem ess_equal_weights_and_one_particle {N : ℕ} (W : Fin N → ℝ) :
    ((0 < N ∧ ∀ i, W i = 1 / N) → 1 / ∑ i, W i ^ 2 = N) ∧
    (∀ j, W = Pi.single j 1 → 1 / ∑ i, W i ^ 2 = 1) := by
  constructor
  · rintro ⟨hN, hW⟩
    have hNr : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
    simp only [hW, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    field_simp
  · rintro j rfl
    have : ∑ i, (Pi.single j (1 : ℝ) : Fin N → ℝ) i ^ 2 = 1 := by
      rw [Finset.sum_eq_single j]
      · simp
      · intro b _ hb; simp [hb]
      · intro h; exact absurd (Finset.mem_univ j) h
    rw [this]; norm_num

/-- Systematic resampling: with weights that are nonnegative and add to 1, one draw u with
0 ≤ u < 1/N, and N pointers u + i/N for i = 0, ..., N - 1, the number of pointers that land in
particle j's slice of the running total is within 1 of its fair share N times its weight. -/
theorem systematic_resampling_copies_within_one {N : ℕ} (W : Fin N → ℝ) (hW : ∀ i, 0 ≤ W i)
    (hsum : ∑ i, W i = 1) (u : ℝ) (hu0 : 0 ≤ u) (hu1 : u < 1 / N) (j : Fin N) :
    |(((range N).filter (fun i : ℕ =>
        ∑ k ∈ Iio j, W k ≤ u + i / N ∧ u + i / N < ∑ k ∈ Iic j, W k)).card : ℝ)
      - N * W j| < 1 := by
  have hN : 0 < N := Fin.pos j
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  have hb : ∑ k ∈ Iic j, W k = ∑ k ∈ Iio j, W k + W j := by
    rw [← Finset.Iio_insert, Finset.sum_insert Finset.notMem_Iio_self, add_comm]
  have ha0 : 0 ≤ ∑ k ∈ Iio j, W k := Finset.sum_nonneg (fun i _ => hW i)
  have hb1 : ∑ k ∈ Iic j, W k ≤ 1 := by
    rw [← hsum]
    exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _) (fun i _ _ => hW i)
  rw [hb] at hb1 ⊢
  set a := ∑ k ∈ Iio j, W k with ha
  have hNu : N * u < 1 := by
    rw [lt_div_iff₀ hNr] at hu1; linarith
  set x : ℝ := N * a - N * u with hx
  set y : ℝ := N * (a + W j) - N * u with hy
  have hxy : x ≤ y := by
    have := mul_nonneg hNr.le (hW j); simp only [hx, hy]; nlinarith
  have hyN : y ≤ N := by
    have := mul_nonneg hNr.le hu0
    have := mul_le_mul_of_nonneg_left hb1 hNr.le
    simp only [hy]; nlinarith
  have hfilter : (range N).filter (fun i : ℕ => a ≤ u + i / N ∧ u + i / N < a + W j)
      = Finset.Ico ⌈x⌉₊ ⌈y⌉₊ := by
    ext i
    simp only [Finset.mem_filter, Finset.mem_range, Finset.mem_Ico]
    have key : u + (i : ℝ) / N = (N * u + i) / N := by field_simp
    rw [key, le_div_iff₀ hNr, div_lt_iff₀ hNr, Nat.ceil_le, Nat.lt_ceil]
    constructor
    · rintro ⟨_, h1, h2⟩
      constructor
      · simp only [hx]; linarith
      · simp only [hy]; linarith
    · rintro ⟨h1, h2⟩
      refine ⟨?_, ?_, ?_⟩
      · have : (i : ℝ) < N := lt_of_lt_of_le h2 hyN
        exact_mod_cast this
      · simp only [hx] at h1; linarith
      · simp only [hy] at h2; linarith
  rw [hfilter, Nat.card_Ico, Nat.cast_sub (Nat.ceil_mono hxy)]
  have hx1 : -1 < x := by
    have := mul_nonneg hNr.le ha0; simp only [hx]; linarith
  have hy1 : -1 < y := lt_of_lt_of_le hx1 hxy
  have c1 := natCeil_sub_lt_one_of_gt_neg_one x hx1
  have c2 := natCeil_sub_lt_one_of_gt_neg_one y hy1
  have c3 : x ≤ (⌈x⌉₊ : ℝ) := Nat.le_ceil x
  have c4 : y ≤ (⌈y⌉₊ : ℝ) := Nat.le_ceil y
  have hWj : (N : ℝ) * W j = y - x := by simp only [hx, hy]; ring
  rw [hWj, abs_sub_lt_iff]
  constructor <;> linarith

/- The card's five-particle table, in hundredths: weights 10, 40, 5, 30, 15 (running totals
10, 50, 55, 85, 100) and pointers 7, 27, 47, 67, 87 give copy counts 1, 2, 0, 1, 1. -/
example : ((range 5).filter (fun i => 0 ≤ 7 + 20 * i ∧ 7 + 20 * i < 10)).card = 1 := by decide
example : ((range 5).filter (fun i => 10 ≤ 7 + 20 * i ∧ 7 + 20 * i < 50)).card = 2 := by decide
example : ((range 5).filter (fun i => 50 ≤ 7 + 20 * i ∧ 7 + 20 * i < 55)).card = 0 := by decide
example : ((range 5).filter (fun i => 55 ≤ 7 + 20 * i ∧ 7 + 20 * i < 85)).card = 1 := by decide
example : ((range 5).filter (fun i => 85 ≤ 7 + 20 * i ∧ 7 + 20 * i < 100)).card = 1 := by decide

/- The resampling threshold is half the particle count, and the first resampling keeps all
1,000 particles: 487 on the negative hump and 513 on the positive. -/
example : 1000 / 2 = 500 ∧ 487 + 513 = 1000 := by decide

#print axioms ess_between_one_and_card
#print axioms ess_equal_weights_and_one_particle
#print axioms systematic_resampling_copies_within_one
