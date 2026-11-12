-- Bisection: halving a bracket where a continuous function changes sign keeps a root inside every bracket, puts the k-th midpoint within (b₀ - a₀)/2^(k+1) of it, and passes the mixed stopping test after a number of halvings known in advance.
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic

open Set

namespace Bisection

/-- One halving of the bracket `[a, b]`: test the midpoint `m = (a + b)/2` and keep `[a, m]`
when `f a` and `f m` differ in sign, otherwise `[m, b]`. A midpoint where `f` is exactly zero
counts as a sign change (it is a root), so it is kept as the right end. -/
noncomputable def halve (f : ℝ → ℝ) (p : ℝ × ℝ) : ℝ × ℝ :=
  if f p.1 * f ((p.1 + p.2) / 2) ≤ 0 then (p.1, (p.1 + p.2) / 2) else ((p.1 + p.2) / 2, p.2)

/-- The bracket `[a_k, b_k]` after `k` halvings, starting from `[a₀, b₀]`. -/
noncomputable def bracket (f : ℝ → ℝ) (a₀ b₀ : ℝ) (k : ℕ) : ℝ × ℝ :=
  (halve f)^[k] (a₀, b₀)

/-- The midpoint `m_k` of the bracket after `k` halvings: the answer returned. -/
noncomputable def mid (f : ℝ → ℝ) (a₀ b₀ : ℝ) (k : ℕ) : ℝ :=
  ((bracket f a₀ b₀ k).1 + (bracket f a₀ b₀ k).2) / 2

lemma bracket_succ (f : ℝ → ℝ) (a₀ b₀ : ℝ) (k : ℕ) :
    bracket f a₀ b₀ (k + 1) = halve f (bracket f a₀ b₀ k) := by
  unfold bracket; rw [Function.iterate_succ_apply']

lemma bracket_width (f : ℝ → ℝ) (a₀ b₀ : ℝ) (k : ℕ) :
    (bracket f a₀ b₀ k).2 - (bracket f a₀ b₀ k).1 = (b₀ - a₀) / 2 ^ k := by
  induction k with
  | zero => simp [bracket]
  | succ k ih =>
    rw [bracket_succ, pow_succ, ← div_div, ← ih]
    generalize bracket f a₀ b₀ k = p
    unfold halve
    split_ifs <;> simp only [] <;> ring

lemma bracket_le (f : ℝ → ℝ) (a₀ b₀ : ℝ) (hab : a₀ ≤ b₀) (k : ℕ) :
    (bracket f a₀ b₀ k).1 ≤ (bracket f a₀ b₀ k).2 := by
  have h := bracket_width f a₀ b₀ k
  have : 0 ≤ (b₀ - a₀) / 2 ^ k := by
    have : 0 ≤ b₀ - a₀ := by linarith
    positivity
  linarith

lemma bracket_fst_mono (f : ℝ → ℝ) (a₀ b₀ : ℝ) (hab : a₀ ≤ b₀) :
    Monotone (fun k => (bracket f a₀ b₀ k).1) := by
  refine monotone_nat_of_le_succ fun k => ?_
  have h := bracket_le f a₀ b₀ hab k
  rw [bracket_succ]
  generalize bracket f a₀ b₀ k = p at h ⊢
  unfold halve
  split_ifs <;> simp only [] <;> linarith

lemma bracket_snd_anti (f : ℝ → ℝ) (a₀ b₀ : ℝ) (hab : a₀ ≤ b₀) :
    Antitone (fun k => (bracket f a₀ b₀ k).2) := by
  refine antitone_nat_of_succ_le fun k => ?_
  have h := bracket_le f a₀ b₀ hab k
  rw [bracket_succ]
  generalize bracket f a₀ b₀ k = p at h ⊢
  unfold halve
  split_ifs <;> simp only [] <;> linarith

lemma bracket_sign (f : ℝ → ℝ) (a₀ b₀ : ℝ) (hs : f a₀ * f b₀ ≤ 0) (k : ℕ) :
    f (bracket f a₀ b₀ k).1 * f (bracket f a₀ b₀ k).2 ≤ 0 := by
  induction k with
  | zero => simpa [bracket] using hs
  | succ k ih =>
    rw [bracket_succ]
    generalize bracket f a₀ b₀ k = p at ih ⊢
    unfold halve
    split_ifs with h
    · simpa using h
    · push Not at h
      simp only []
      by_contra hc
      push Not at hc
      nlinarith [mul_pos h hc, mul_nonpos_of_nonpos_of_nonneg ih (sq_nonneg (f ((p.1 + p.2) / 2)))]

lemma half_width_le (D T : ℝ) (hD : 0 ≤ D) (hT : 0 < T) (k : ℕ)
    (hk : ⌈Real.logb 2 (D / (2 * T))⌉ ≤ (k : ℤ)) : D / 2 ^ (k + 1) ≤ T := by
  have h1 : Real.logb 2 (D / (2 * T)) ≤ k := by
    have h0 := Int.le_ceil (Real.logb 2 (D / (2 * T)))
    have h3 : ((⌈Real.logb 2 (D / (2 * T))⌉ : ℤ) : ℝ) ≤ ((k : ℤ) : ℝ) := by exact_mod_cast hk
    simp only [Int.cast_natCast] at h3
    linarith
  rcases hD.eq_or_lt with h | h
  · rw [← h]; simp; exact hT.le
  · have hX : 0 < D / (2 * T) := by positivity
    rw [Real.logb_le_iff_le_rpow (by norm_num) hX, Real.rpow_natCast] at h1
    rw [div_le_iff₀ (by positivity)] at h1
    rw [div_le_iff₀ (by positivity), pow_succ]
    nlinarith

lemma mid_mem (f : ℝ → ℝ) (a₀ b₀ : ℝ) (hab : a₀ ≤ b₀) (k : ℕ) :
    a₀ ≤ mid f a₀ b₀ k ∧ mid f a₀ b₀ k ≤ b₀ := by
  have h1 : a₀ ≤ (bracket f a₀ b₀ k).1 := bracket_fst_mono f a₀ b₀ hab (Nat.zero_le k)
  have h2 : (bracket f a₀ b₀ k).2 ≤ b₀ := bracket_snd_anti f a₀ b₀ hab (Nat.zero_le k)
  have h3 := bracket_le f a₀ b₀ hab k
  unfold mid
  constructor <;> linarith

#print axioms bracket_succ
#print axioms bracket_width
#print axioms bracket_le
#print axioms bracket_fst_mono
#print axioms bracket_snd_anti
#print axioms bracket_sign
#print axioms half_width_le
#print axioms mid_mem

/-- Bisection's guarantee. Let `f` be continuous on the bracket `[a₀, b₀]` with `f a₀` and
`f b₀` of opposite sign. Then one root `r*` of `f` lies in every bracket `[a_k, b_k]`,
each bracket is exactly `(b₀ - a₀)/2^k` wide, and the midpoint after `k` halvings is within
`(b₀ - a₀)/2^(k+1)` of that root, whatever the function looks like. -/
theorem bisection_midpoint_within_half_width_of_root (f : ℝ → ℝ) (a₀ b₀ : ℝ)
    (hab : a₀ ≤ b₀) (hf : ContinuousOn f (Icc a₀ b₀)) (hsign : f a₀ * f b₀ < 0) :
    ∃ r ∈ Icc a₀ b₀, f r = 0 ∧ ∀ k : ℕ,
      r ∈ Icc (bracket f a₀ b₀ k).1 (bracket f a₀ b₀ k).2 ∧
      (bracket f a₀ b₀ k).2 - (bracket f a₀ b₀ k).1 = (b₀ - a₀) / 2 ^ k ∧
      |mid f a₀ b₀ k - r| ≤ (b₀ - a₀) / 2 ^ (k + 1) := by
  have hmono := bracket_fst_mono f a₀ b₀ hab
  have hanti := bracket_snd_anti f a₀ b₀ hab
  have hle := bracket_le f a₀ b₀ hab
  have hbdd : BddAbove (Set.range fun k => (bracket f a₀ b₀ k).1) :=
    ⟨b₀, by
      rintro _ ⟨k, rfl⟩
      exact (hle k).trans (hanti (Nat.zero_le k))⟩
  set r := ⨆ k, (bracket f a₀ b₀ k).1 with hr
  have hA : ∀ k, (bracket f a₀ b₀ k).1 ≤ r := fun k => le_ciSup hbdd k
  have hB : ∀ k, r ≤ (bracket f a₀ b₀ k).2 := fun k =>
    ciSup_le fun j => (hmono (le_max_left j k)).trans
      ((hle (max j k)).trans (hanti (le_max_right j k)))
  have hrI : r ∈ Icc a₀ b₀ := ⟨hA 0, hB 0⟩
  have hAt : Filter.Tendsto (fun k => (bracket f a₀ b₀ k).1) Filter.atTop (nhds r) :=
    tendsto_atTop_ciSup hmono hbdd
  have hgeo : Filter.Tendsto (fun k : ℕ => (b₀ - a₀) * (1 / 2) ^ k) Filter.atTop
      (nhds ((b₀ - a₀) * 0)) :=
    (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num)).const_mul _
  have hBt : Filter.Tendsto (fun k => (bracket f a₀ b₀ k).2) Filter.atTop (nhds r) := by
    have := hAt.add hgeo
    rw [mul_zero, add_zero] at this
    refine this.congr fun k => ?_
    have := bracket_width f a₀ b₀ k
    rw [one_div, inv_pow, ← div_eq_mul_inv]
    linarith
  have hmemA : ∀ k, (bracket f a₀ b₀ k).1 ∈ Icc a₀ b₀ := fun k =>
    ⟨hmono (Nat.zero_le k), (hle k).trans (hanti (Nat.zero_le k))⟩
  have hmemB : ∀ k, (bracket f a₀ b₀ k).2 ∈ Icc a₀ b₀ := fun k =>
    ⟨(hmono (Nat.zero_le k)).trans (hle k), hanti (Nat.zero_le k)⟩
  have hfA : Filter.Tendsto (fun k => f (bracket f a₀ b₀ k).1) Filter.atTop (nhds (f r)) :=
    (hf r hrI).tendsto.comp
      (tendsto_nhdsWithin_iff.2 ⟨hAt, Filter.Eventually.of_forall hmemA⟩)
  have hfB : Filter.Tendsto (fun k => f (bracket f a₀ b₀ k).2) Filter.atTop (nhds (f r)) :=
    (hf r hrI).tendsto.comp
      (tendsto_nhdsWithin_iff.2 ⟨hBt, Filter.Eventually.of_forall hmemB⟩)
  have hprod : f r * f r ≤ 0 :=
    le_of_tendsto' (hfA.mul hfB) fun k => bracket_sign f a₀ b₀ hsign.le k
  have hfr : f r = 0 := mul_self_eq_zero.mp (le_antisymm hprod (mul_self_nonneg _))
  refine ⟨r, hrI, hfr, fun k => ⟨⟨hA k, hB k⟩, bracket_width f a₀ b₀ k, ?_⟩⟩
  have hw := bracket_width f a₀ b₀ k
  have h2 : (b₀ - a₀) / 2 ^ (k + 1) = (b₀ - a₀) / 2 ^ k / 2 := by rw [pow_succ, div_div]
  rw [h2, abs_le]
  have := hA k
  have := hB k
  unfold mid
  constructor <;> linarith

/-- The step count in advance, for a bracket that does not contain zero. With tolerances
`t_abs, t_rel ≥ 0` and `T = t_abs + t_rel · min(|a₀|, |b₀|) > 0`, every
`k ≥ K = ⌈log₂((b₀ - a₀)/(2T))⌉` passes the mixed stopping test
`(b_k - a_k)/2 ≤ t_abs + t_rel · |m_k|`. -/
theorem halvings_promised_pass_mixed_test (f : ℝ → ℝ) (a₀ b₀ t_abs t_rel : ℝ)
    (hab : a₀ ≤ b₀) (hzero : (0 : ℝ) ∉ Icc a₀ b₀) (habs : 0 ≤ t_abs) (hrel : 0 ≤ t_rel)
    (hT : 0 < t_abs + t_rel * min |a₀| |b₀|) (k : ℕ)
    (hk : ⌈Real.logb 2 ((b₀ - a₀) / (2 * (t_abs + t_rel * min |a₀| |b₀|)))⌉ ≤ (k : ℤ)) :
    ((bracket f a₀ b₀ k).2 - (bracket f a₀ b₀ k).1) / 2
      ≤ t_abs + t_rel * |mid f a₀ b₀ k| := by
  have hm := mid_mem f a₀ b₀ hab k
  have hmin : min |a₀| |b₀| ≤ |mid f a₀ b₀ k| := by
    simp only [mem_Icc, not_and, not_le] at hzero
    by_cases ha : 0 < a₀
    · rw [abs_of_pos ha, abs_of_pos (show 0 < mid f a₀ b₀ k by linarith)]
      exact (min_le_left _ _).trans hm.1
    · have hb := hzero (by linarith)
      rw [abs_of_neg hb, abs_of_neg (show mid f a₀ b₀ k < 0 by linarith)]
      exact (min_le_right _ _).trans (by linarith)
  have hw := bracket_width f a₀ b₀ k
  have h := half_width_le (b₀ - a₀) _ (by linarith) hT k hk
  have h2 : (b₀ - a₀) / 2 ^ (k + 1) = (b₀ - a₀) / 2 ^ k / 2 := by rw [pow_succ, div_div]
  rw [hw, ← h2]
  have := mul_le_mul_of_nonneg_left hmin hrel
  linarith

/-- When the bracket may contain zero, drop the relative part: with `t_abs > 0`, every
`k ≥ ⌈log₂((b₀ - a₀)/(2 t_abs))⌉` passes the mixed stopping test. -/
theorem halvings_promised_pass_test_bracket_with_zero (f : ℝ → ℝ) (a₀ b₀ t_abs t_rel : ℝ)
    (hab : a₀ ≤ b₀) (habs : 0 < t_abs) (hrel : 0 ≤ t_rel) (k : ℕ)
    (hk : ⌈Real.logb 2 ((b₀ - a₀) / (2 * t_abs))⌉ ≤ (k : ℤ)) :
    ((bracket f a₀ b₀ k).2 - (bracket f a₀ b₀ k).1) / 2
      ≤ t_abs + t_rel * |mid f a₀ b₀ k| := by
  have hw := bracket_width f a₀ b₀ k
  have h := half_width_le (b₀ - a₀) _ (by linarith) habs k hk
  have h2 : (b₀ - a₀) / 2 ^ (k + 1) = (b₀ - a₀) / 2 ^ k / 2 := by rw [pow_succ, div_div]
  rw [hw, ← h2]
  have := mul_nonneg hrel (abs_nonneg (mid f a₀ b₀ k))
  linarith

-- The card's worked numbers, with rates in percent and tolerances as exact fractions.

-- The least tolerance: T = 10^-6 + 10^-5 × 1/100 = 11/10^7 (the card's 1.100e-06).
example : (1 : ℚ) / 10 ^ 6 + 1 / 10 ^ 5 * (1 / 100) = 11 / 10 ^ 7 := by norm_num
-- The promise: (b₀ - a₀)/(2T) = (14/100)/(22/10^7) = 700000/11, between 2^15 and 2^16, so K = 16.
example : (14 / 100 : ℚ) / (2 * (11 / 10 ^ 7)) = 700000 / 11 := by norm_num
example : (2 : ℚ) ^ 15 < 700000 / 11 ∧ (700000 / 11 : ℚ) ≤ 2 ^ 16 := by norm_num
-- After 16 halvings the bound (14/100)/2^17 is inside T; after 15 it is not yet.
example : (14 / 100 : ℚ) / 2 ^ 17 ≤ 11 / 10 ^ 7 ∧ ¬ ((14 / 100 : ℚ) / 2 ^ 16 ≤ 11 / 10 ^ 7) := by
  norm_num
-- The first four midpoints from [1%, 15%]: 8%, 4.5%, 6.25%, 5.375%.
example : ((1 : ℚ) + 15) / 2 = 8 ∧ ((1 : ℚ) + 8) / 2 = 9 / 2 ∧ ((9 / 2 : ℚ) + 8) / 2 = 25 / 4 ∧
    ((9 / 2 : ℚ) + 25 / 4) / 2 = 43 / 8 := by norm_num
-- Each kept bracket is half as wide: 14, 7, 7/2, 7/4, 7/8 percentage points.
example : (8 : ℚ) - 1 = 14 / 2 ∧ (8 : ℚ) - 9 / 2 = 14 / 2 ^ 2 ∧ (25 / 4 : ℚ) - 9 / 2 = 14 / 2 ^ 3 ∧
    (43 / 8 : ℚ) - 9 / 2 = 14 / 2 ^ 4 := by norm_num
-- Outward search from [1%, 2%]: step past the upper end by twice the width, to [2%, 4%], then [4%, 8%].
example : (2 : ℤ) + 2 * (2 - 1) = 4 ∧ (4 : ℤ) + 2 * (4 - 2) = 8 := by decide
-- The $900 payment: from [1%, 15%] step below the lower end by twice the width, to [-27%, 1%].
example : (1 : ℤ) - 2 * (15 - 1) = -27 := by decide
-- Cost: 2 end values plus 16 midpoints is 18 evaluations.
example : 2 + 16 = 18 := by decide

#print axioms bisection_midpoint_within_half_width_of_root
#print axioms halvings_promised_pass_mixed_test
#print axioms halvings_promised_pass_test_bracket_with_zero

end Bisection
