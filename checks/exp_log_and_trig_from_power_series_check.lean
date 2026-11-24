-- Exp, log, sine, cosine and pi from series alone: exp, cos and sin defined as power series satisfy exp(x + y) = exp x exp y, have log as an inverse, and give pi as twice the first positive zero of cos with period 2 pi.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Series
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Algebra.BigOperators.Field

open Nat

/-- The exp series: the sum of x ^ n / n! over n = 0, 1, 2, ... -/
noncomputable def seriesExp (x : ℝ) : ℝ := ∑' n : ℕ, x ^ n / (n ! : ℝ)

/-- The cosine series: the even powers, with alternating signs. -/
noncomputable def seriesCos (x : ℝ) : ℝ := ∑' n : ℕ, (-1) ^ n * x ^ (2 * n) / ((2 * n)! : ℝ)

/-- The sine series: the odd powers, with alternating signs. -/
noncomputable def seriesSin (x : ℝ) : ℝ :=
  ∑' n : ℕ, (-1) ^ n * x ^ (2 * n + 1) / ((2 * n + 1)! : ℝ)

theorem seriesCos_eq_cos (x : ℝ) : seriesCos x = Real.cos x :=
  (Real.hasSum_cos x).tsum_eq

theorem seriesSin_eq_sin (x : ℝ) : seriesSin x = Real.sin x :=
  (Real.hasSum_sin x).tsum_eq

theorem seriesExp_eq_exp (x : ℝ) : seriesExp x = Real.exp x := by
  rw [Real.exp_eq_exp_ℝ]
  exact (NormedSpace.expSeries_div_hasSum_exp x).tsum_eq

#print axioms seriesCos_eq_cos
#print axioms seriesSin_eq_sin
#print axioms seriesExp_eq_exp

/-- Pi from the cosine series alone. The cosine series has a first positive zero p: it is 0 at p
and positive on [0, p). That zero lies between 1.5 and 1.6, and pi = 2p (the same number as
Mathlib's `Real.pi`). The cosine and sine series repeat after a shift of 2 pi, and no smaller
positive shift works, because the cosine series equals 1 nowhere in (0, 2 pi). -/
theorem cos_series_first_zero_gives_pi_and_period :
    ∃ p : ℝ, 0 < p ∧ seriesCos p = 0 ∧ (∀ x, 0 ≤ x → x < p → 0 < seriesCos x) ∧
      3 / 2 < p ∧ p < 8 / 5 ∧ 2 * p = Real.pi ∧
      (∀ x : ℝ, seriesCos (x + 2 * (2 * p)) = seriesCos x ∧
        seriesSin (x + 2 * (2 * p)) = seriesSin x) ∧
      (∀ T : ℝ, 0 < T → T < 2 * (2 * p) → seriesCos T ≠ 1) := by
  refine ⟨Real.pi / 2, by positivity, ?_, ?_, ?_, ?_, by ring, ?_, ?_⟩
  · rw [seriesCos_eq_cos, Real.cos_pi_div_two]
  · intro x hx0 hxp
    rw [seriesCos_eq_cos]
    apply Real.cos_pos_of_mem_Ioo
    constructor <;> linarith [Real.pi_pos]
  · linarith [Real.pi_gt_three]
  · have := Real.pi_lt_d2
    norm_num at this ⊢
    linarith
  · intro x
    have h : x + 2 * (2 * (Real.pi / 2)) = x + 2 * Real.pi := by ring
    rw [h, seriesCos_eq_cos, seriesCos_eq_cos, seriesSin_eq_sin, seriesSin_eq_sin,
      Real.cos_add_two_pi, Real.sin_add_two_pi]
    exact ⟨rfl, rfl⟩
  · intro T hT0 hT
    rw [seriesCos_eq_cos]
    intro h1
    have hlt : T < 2 * Real.pi := by linarith
    have := (Real.cos_eq_one_iff_of_lt_of_lt (by linarith [Real.pi_pos]) hlt).mp h1
    linarith

/-- Exponents add, by the Cauchy product. The n-th Cauchy term of the exp series at x times the
exp series at y is (x + y) ^ n / n! (the binomial theorem), so the exp series at x + y equals the
exp series at x times the exp series at y. -/
theorem exp_series_add (x y : ℝ) :
    (∀ n : ℕ, ∑ k ∈ Finset.range (n + 1), x ^ k / (k ! : ℝ) * (y ^ (n - k) / ((n - k)! : ℝ)) =
      (x + y) ^ n / (n ! : ℝ)) ∧
    seriesExp (x + y) = seriesExp x * seriesExp y := by
  refine ⟨?_, ?_⟩
  · intro n
    rw [add_pow, Finset.sum_div]
    apply Finset.sum_congr rfl
    intro k hk
    have hk' : k ≤ n := Nat.lt_succ_iff.mp (Finset.mem_range.mp hk)
    rw [Nat.cast_choose ℝ hk']
    have h1 : (k ! : ℝ) ≠ 0 := by positivity
    have h2 : ((n - k)! : ℝ) ≠ 0 := by positivity
    have h3 : (n ! : ℝ) ≠ 0 := by positivity
    field_simp
  · rw [seriesExp_eq_exp, seriesExp_eq_exp, seriesExp_eq_exp, Real.exp_add]

/-- Log is the inverse of exp. For v above 0 there is exactly one t with exp t = v (and Mathlib's
`Real.log v` is that t). The log rule: for u and v above 0, the number whose exp is u v is the
sum of the numbers whose exps are u and v. -/
theorem log_is_inverse_of_exp_series (u v : ℝ) (hu : 0 < u) (hv : 0 < v) :
    (∃! t : ℝ, seriesExp t = v) ∧ seriesExp (Real.log v) = v ∧
    ∀ s t r : ℝ, seriesExp s = u → seriesExp t = v → seriesExp r = u * v → r = s + t := by
  simp only [seriesExp_eq_exp]
  refine ⟨⟨Real.log v, Real.exp_log hv, fun t ht => ?_⟩, Real.exp_log hv, ?_⟩
  · rw [← ht, Real.log_exp]
  · intro s t r hs ht hr
    apply Real.exp_injective
    rw [hr, Real.exp_add, hs, ht]

-- The card's Cauchy terms of exp 1 times exp 1, n = 0 to 5: 1, 2, 2, 4/3, 2/3, 4/15, each 2 ^ n / n!.
example : (∑ k ∈ Finset.range 1, (1 : ℚ) / ((k ! : ℚ) * ((0 - k)! : ℚ))) = 1 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]
example : (∑ k ∈ Finset.range 2, (1 : ℚ) / ((k ! : ℚ) * ((1 - k)! : ℚ))) = 2 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]
example : (∑ k ∈ Finset.range 3, (1 : ℚ) / ((k ! : ℚ) * ((2 - k)! : ℚ))) = 2 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]
example : (∑ k ∈ Finset.range 4, (1 : ℚ) / ((k ! : ℚ) * ((3 - k)! : ℚ))) = 4 / 3 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]
example : (∑ k ∈ Finset.range 5, (1 : ℚ) / ((k ! : ℚ) * ((4 - k)! : ℚ))) = 2 / 3 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]
example : (∑ k ∈ Finset.range 6, (1 : ℚ) / ((k ! : ℚ) * ((5 - k)! : ℚ))) = 4 / 15 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]

#print axioms cos_series_first_zero_gives_pi_and_period
#print axioms exp_series_add
#print axioms log_is_inverse_of_exp_series
