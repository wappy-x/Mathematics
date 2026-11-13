-- Fourier series: sines and cosines of whole-number frequencies are orthogonal over one cycle, so each amount in a sum of them is one integral of the signal against that wave, and the square wave's amounts are 4/(nπ) for odd n and 0 otherwise.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real Filter Finset

namespace FourierSeries

/-- The sum stopped after harmonic `N`:
`S_N(x) = a_0/2 + ∑_{n=1}^{N} (a_n cos(nx) + b_n sin(nx))`. -/
noncomputable def partialSum (a b : ℕ → ℝ) (N : ℕ) (x : ℝ) : ℝ :=
  a 0 / 2 + ∑ n ∈ Icc 1 N, (a n * cos (n * x) + b n * sin (n * x))

/-- The card's square wave in phase: +1 for the first half of each cycle of length 2π and
−1 for the second half (`x mod 2π < π` gives +1). -/
noncomputable def squareWave (x : ℝ) : ℝ :=
  if Int.fract (x / (2 * π)) < 1 / 2 then 1 else -1

lemma integral_cos_int_mul (k : ℤ) :
    ∫ x in (-π)..π, cos (k * x) = if k = 0 then 2 * π else 0 := by
  split_ifs with hk
  · subst hk; simp; ring
  · have hk' : (k : ℝ) ≠ 0 := by exact_mod_cast hk
    rw [intervalIntegral.integral_comp_mul_left (fun x => cos x) hk', integral_cos]
    simp [mul_neg, sin_neg, sin_int_mul_pi]

#print axioms integral_cos_int_mul

lemma integral_sin_int_mul (k : ℤ) :
    ∫ x in (-π)..π, sin (k * x) = 0 := by
  by_cases hk : k = 0
  · subst hk; simp
  · have hk' : (k : ℝ) ≠ 0 := by exact_mod_cast hk
    rw [intervalIntegral.integral_comp_mul_left (fun x => sin x) hk', integral_sin]
    simp [mul_neg, cos_neg]

#print axioms integral_sin_int_mul

lemma integral_sin_mul_sin (m n : ℕ) :
    ∫ x in (-π)..π, sin (m * x) * sin (n * x) =
      (if (m : ℤ) - n = 0 then π else 0) - (if (m : ℤ) + n = 0 then π else 0) := by
  have key : (fun x : ℝ => sin (m * x) * sin (n * x)) = fun x =>
      (1 / 2) * cos ((((m : ℤ) - n : ℤ) : ℝ) * x) - (1 / 2) * cos ((((m : ℤ) + n : ℤ) : ℝ) * x) := by
    funext x; push_cast; rw [sub_mul, add_mul, cos_sub, cos_add]; ring
  rw [key, intervalIntegral.integral_sub (Continuous.intervalIntegrable (by fun_prop) _ _) (Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_cos_int_mul, integral_cos_int_mul]
  split_ifs <;> ring

#print axioms integral_sin_mul_sin

lemma integral_cos_mul_cos (m n : ℕ) :
    ∫ x in (-π)..π, cos (m * x) * cos (n * x) =
      (if (m : ℤ) - n = 0 then π else 0) + (if (m : ℤ) + n = 0 then π else 0) := by
  have key : (fun x : ℝ => cos (m * x) * cos (n * x)) = fun x =>
      (1 / 2) * cos ((((m : ℤ) - n : ℤ) : ℝ) * x) + (1 / 2) * cos ((((m : ℤ) + n : ℤ) : ℝ) * x) := by
    funext x; push_cast; rw [sub_mul, add_mul, cos_sub, cos_add]; ring
  rw [key, intervalIntegral.integral_add (Continuous.intervalIntegrable (by fun_prop) _ _) (Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_cos_int_mul, integral_cos_int_mul]
  split_ifs <;> ring

#print axioms integral_cos_mul_cos

lemma integral_sin_mul_cos (m n : ℕ) :
    ∫ x in (-π)..π, sin (m * x) * cos (n * x) = 0 := by
  have key : (fun x : ℝ => sin (m * x) * cos (n * x)) = fun x =>
      (1 / 2) * sin ((((m : ℤ) + n : ℤ) : ℝ) * x) + (1 / 2) * sin ((((m : ℤ) - n : ℤ) : ℝ) * x) := by
    funext x; push_cast; rw [sub_mul, add_mul, sin_sub, sin_add]; ring
  rw [key, intervalIntegral.integral_add (Continuous.intervalIntegrable (by fun_prop) _ _) (Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_sin_int_mul, integral_sin_int_mul]
  ring

#print axioms integral_sin_mul_cos

/-- **Orthogonality, the card's main claim.** For whole numbers m and n of at least 1, over one
cycle from −π to π: `∫ sin(mx) sin(nx) dx` is π if m = n and 0 if not; the same holds with
cosines for both; and `∫ sin(mx) cos(nx) dx` is always 0 (for every whole m and n, 0 included).
Two different harmonics multiplied together cancel over a cycle; a harmonic times itself
leaves π. -/
theorem harmonics_are_orthogonal_over_one_cycle :
    (∀ m n : ℕ, 1 ≤ m → 1 ≤ n →
      ∫ x in (-π)..π, sin (m * x) * sin (n * x) = if m = n then π else 0) ∧
    (∀ m n : ℕ, 1 ≤ m → 1 ≤ n →
      ∫ x in (-π)..π, cos (m * x) * cos (n * x) = if m = n then π else 0) ∧
    (∀ m n : ℕ, ∫ x in (-π)..π, sin (m * x) * cos (n * x) = 0) := by
  refine ⟨fun m n hm hn => ?_, fun m n hm hn => ?_, integral_sin_mul_cos⟩
  · rw [integral_sin_mul_sin]
    split_ifs <;> first | (exfalso; omega) | ring1
  · rw [integral_cos_mul_cos]
    split_ifs <;> first | (exfalso; omega) | ring1

lemma partialSum_continuous (a b : ℕ → ℝ) (N : ℕ) : Continuous (partialSum a b N) := by
  unfold partialSum; fun_prop

#print axioms partialSum_continuous

lemma integral_eq_of_uniform_limit (f : ℝ → ℝ) (a b : ℕ → ℝ)
    (hconv : TendstoUniformlyOn (partialSum a b) f atTop (Set.Icc (-π) π))
    (g : ℝ → ℝ) (hg : Continuous g) (hg1 : ∀ x, |g x| ≤ 1) (c : ℝ) (N0 : ℕ)
    (hc : ∀ N, N0 ≤ N → ∫ x in (-π)..π, partialSum a b N x * g x = c) :
    ∫ x in (-π)..π, f x * g x = c := by
  have hf : ContinuousOn f (Set.Icc (-π) π) :=
    hconv.continuousOn (Frequently.of_forall fun N => (partialSum_continuous a b N).continuousOn)
  have hle : -π ≤ π := by linarith [pi_pos]
  have hfg : IntervalIntegrable (fun x => f x * g x) MeasureTheory.volume (-π) π := by
    apply ContinuousOn.intervalIntegrable
    rw [Set.uIcc_of_le hle]
    exact hf.mul hg.continuousOn
  apply eq_of_forall_dist_le
  intro ε hε
  have hδ : 0 < ε / (2 * π) := by positivity
  obtain ⟨N, hN, hNx⟩ :=
    ((eventually_ge_atTop N0).and (Metric.tendstoUniformlyOn_iff.mp hconv _ hδ)).exists
  have hSg : IntervalIntegrable (fun x => partialSum a b N x * g x) MeasureTheory.volume (-π) π := by
    apply Continuous.intervalIntegrable
    exact (partialSum_continuous a b N).mul hg
  rw [← hc N hN, Real.dist_eq, ← intervalIntegral.integral_sub hfg hSg]
  have hb := intervalIntegral.norm_integral_le_of_norm_le_const (a := -π) (b := π)
    (C := ε / (2 * π)) (f := fun x => f x * g x - partialSum a b N x * g x) (by
      intro x hx
      have hx' : x ∈ Set.Icc (-π) π := by
        have := Set.uIoc_subset_uIcc hx
        rwa [Set.uIcc_of_le hle] at this
      have hd := hNx x hx'
      rw [Real.dist_eq] at hd
      rw [Real.norm_eq_abs, ← sub_mul, abs_mul]
      calc |f x - partialSum a b N x| * |g x| ≤ ε / (2 * π) * 1 :=
            mul_le_mul hd.le (hg1 x) (abs_nonneg _) hδ.le
        _ = ε / (2 * π) := mul_one _)
  rw [Real.norm_eq_abs] at hb
  have h2 : |π - -π| = 2 * π := by rw [abs_of_nonneg (by linarith [pi_pos])]; ring
  rw [h2, div_mul_cancel₀ _ (by positivity)] at hb
  exact hb

#print axioms integral_eq_of_uniform_limit

lemma integral_partialSum_mul_cos (a b : ℕ → ℝ) (N n : ℕ) (hN : n ≤ N) :
    ∫ x in (-π)..π, partialSum a b N x * cos (n * x) = π * a n := by
  have h1 : (fun x => partialSum a b N x * cos (n * x)) = fun x =>
      a 0 / 2 * cos ((n : ℝ) * x) + ∑ k ∈ Icc 1 N,
        (a k * (cos (k * x) * cos (n * x)) + b k * (sin (k * x) * cos (n * x))) := by
    funext x
    rw [partialSum, add_mul, Finset.sum_mul]
    congr 1
    exact Finset.sum_congr rfl fun k _ => by ring
  have h2 : ∀ k ∈ Icc 1 N, ∫ x in (-π)..π,
      (a k * (cos (k * x) * cos (n * x)) + b k * (sin (k * x) * cos (n * x))) =
        if n = k then π * a k else 0 := by
    intro k hk
    rw [mem_Icc] at hk
    rw [intervalIntegral.integral_add (Continuous.intervalIntegrable (by fun_prop) _ _)
      (Continuous.intervalIntegrable (by fun_prop) _ _), intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_cos_mul_cos, integral_sin_mul_cos]
    split_ifs <;> first | (exfalso; omega) | ring1
  have hcn := integral_cos_int_mul n
  push_cast at hcn
  rw [h1, intervalIntegral.integral_add (Continuous.intervalIntegrable (by fun_prop) _ _)
    (Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_finsetSum (fun k _ => Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_const_mul, hcn, Finset.sum_congr rfl h2,
    Finset.sum_ite_eq]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp; ring
  · have hn' : (n : ℤ) ≠ 0 := by omega
    have hmem : n ∈ Icc 1 N := mem_Icc.mpr ⟨hn, hN⟩
    simp [hmem, hn.ne']

#print axioms integral_partialSum_mul_cos

lemma integral_partialSum_mul_sin (a b : ℕ → ℝ) (N n : ℕ) (hn : 1 ≤ n) (hN : n ≤ N) :
    ∫ x in (-π)..π, partialSum a b N x * sin (n * x) = π * b n := by
  have h1 : (fun x => partialSum a b N x * sin (n * x)) = fun x =>
      a 0 / 2 * sin ((n : ℝ) * x) + ∑ k ∈ Icc 1 N,
        (a k * (sin (n * x) * cos (k * x)) + b k * (sin (k * x) * sin (n * x))) := by
    funext x
    rw [partialSum, add_mul, Finset.sum_mul]
    congr 1
    exact Finset.sum_congr rfl fun k _ => by ring
  have h2 : ∀ k ∈ Icc 1 N, ∫ x in (-π)..π,
      (a k * (sin (n * x) * cos (k * x)) + b k * (sin (k * x) * sin (n * x))) =
        if n = k then π * b k else 0 := by
    intro k hk
    rw [mem_Icc] at hk
    rw [intervalIntegral.integral_add (Continuous.intervalIntegrable (by fun_prop) _ _)
      (Continuous.intervalIntegrable (by fun_prop) _ _), intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_sin_mul_sin, integral_sin_mul_cos]
    split_ifs <;> first | (exfalso; omega) | ring1
  have hsn := integral_sin_int_mul n
  push_cast at hsn
  rw [h1, intervalIntegral.integral_add (Continuous.intervalIntegrable (by fun_prop) _ _)
    (Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_finsetSum (fun k _ => Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_const_mul, hsn, Finset.sum_congr rfl h2,
    Finset.sum_ite_eq]
  have hmem : n ∈ Icc 1 N := mem_Icc.mpr ⟨hn, hN⟩
  simp [hmem]

#print axioms integral_partialSum_mul_sin

/-- **Orthogonality hands you each amount.** Let a signal f on one cycle −π ≤ x ≤ π be the sum
`a_0/2 + ∑_{n≥1} (a_n cos(nx) + b_n sin(nx))`, in the sense the card's detailed proof asks for
(uniform convergence): the largest gap between f and the sum stopped after harmonic N shrinks
to 0 as N grows. Then each amount is a single integral of the signal against its own wave,
over π: `a_n = (1/π) ∫ f(x) cos(nx) dx` for every whole n, n = 0 included (this is why the
average level is written a_0/2), and `b_n = (1/π) ∫ f(x) sin(nx) dx` for every n ≥ 1.
A finite sum of harmonics is the case where every amount past some N is 0. -/
theorem fourier_coefficient_is_integral_against_its_wave (f : ℝ → ℝ) (a b : ℕ → ℝ)
    (hconv : TendstoUniformlyOn (partialSum a b) f atTop (Set.Icc (-π) π)) :
    (∀ n : ℕ, a n = (1 / π) * ∫ x in (-π)..π, f x * cos (n * x)) ∧
    (∀ n : ℕ, 1 ≤ n → b n = (1 / π) * ∫ x in (-π)..π, f x * sin (n * x)) := by
  have hpi : π ≠ 0 := pi_ne_zero
  refine ⟨fun n => ?_, fun n hn => ?_⟩
  · rw [integral_eq_of_uniform_limit f a b hconv (fun x => cos (n * x)) (by fun_prop)
      (fun x => abs_cos_le_one _) (π * a n) n (fun N hN => integral_partialSum_mul_cos a b N n hN)]
    field_simp
  · rw [integral_eq_of_uniform_limit f a b hconv (fun x => sin (n * x)) (by fun_prop)
      (fun x => abs_sin_le_one _) (π * b n) n
      (fun N hN => integral_partialSum_mul_sin a b N n hn hN)]
    field_simp

lemma squareWave_of_nonneg {x : ℝ} (h0 : 0 ≤ x) (h1 : x < π) : squareWave x = 1 := by
  have hp := pi_pos
  have ha : 0 ≤ x / (2 * π) := by positivity
  have hb : x / (2 * π) < 1 / 2 := by rw [div_lt_iff₀ (by positivity)]; linarith
  rw [squareWave, Int.fract_eq_self.mpr ⟨ha, by linarith⟩]
  simp only [hb, ↓reduceIte]

#print axioms squareWave_of_nonneg

lemma squareWave_of_neg {x : ℝ} (h0 : -π ≤ x) (h1 : x < 0) : squareWave x = -1 := by
  have hp := pi_pos
  have ha : -(1 / 2) ≤ x / (2 * π) := by rw [le_div_iff₀ (by positivity)]; linarith
  have hb : x / (2 * π) < 0 := div_neg_of_neg_of_pos h1 (by positivity)
  have hf : Int.fract (x / (2 * π)) = x / (2 * π) + 1 :=
    Int.fract_eq_iff.mpr ⟨by linarith, by linarith, -1, by push_cast; ring⟩
  rw [squareWave, hf]
  have : ¬ (x / (2 * π) + 1 < 1 / 2) := by linarith
  simp only [this, ↓reduceIte]

#print axioms squareWave_of_neg

lemma integral_squareWave_mul (g : ℝ → ℝ) (hg : Continuous g) :
    ∫ x in (-π)..π, squareWave x * g x = (∫ x in (0 : ℝ)..π, g x) - ∫ x in (-π)..0, g x := by
  have hp := pi_pos
  have hA : Set.EqOn (fun x => squareWave x * g x) (fun x => -g x) (Set.uIoo (-π) 0) := by
    intro x hx
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp [squareWave_of_neg hx.1.le hx.2]
  have hB : Set.EqOn (fun x => squareWave x * g x) (fun x => g x) (Set.uIoo 0 π) := by
    intro x hx
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp [squareWave_of_nonneg hx.1.le hx.2]
  have iA : IntervalIntegrable (fun x => squareWave x * g x) MeasureTheory.volume (-π) 0 :=
    (hg.neg.intervalIntegrable _ _).congr_uIoo hA.symm
  have iB : IntervalIntegrable (fun x => squareWave x * g x) MeasureTheory.volume 0 π :=
    (hg.intervalIntegrable _ _).congr_uIoo hB.symm
  rw [← intervalIntegral.integral_add_adjacent_intervals iA iB,
    intervalIntegral.integral_congr_uIoo hA, intervalIntegral.integral_congr_uIoo hB,
    intervalIntegral.integral_neg]
  ring

#print axioms integral_squareWave_mul

/-- **The square wave's amounts.** For the wave that is +1 for half a cycle and −1 for the other
half, every cosine amount is 0 (`a_n = 0`, the average a_0 included), and the sine amounts are
`b_n = 4/(nπ)` for odd n and 0 for even n: the series is
`(4/π)(sin x + sin 3x / 3 + sin 5x / 5 + ⋯)`. -/
theorem square_wave_coefficients :
    (∀ n : ℕ, (1 / π) * ∫ x in (-π)..π, squareWave x * cos (n * x) = 0) ∧
    (∀ n : ℕ, 1 ≤ n → (1 / π) * ∫ x in (-π)..π, squareWave x * sin (n * x) =
      if Odd n then 4 / (n * π) else 0) := by
  have hpi : π ≠ 0 := pi_ne_zero
  refine ⟨fun n => ?_, fun n hn => ?_⟩
  · have h := integral_squareWave_mul (fun x => cos (n * x)) (by fun_prop)
    rw [h]
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
      rw [intervalIntegral.integral_comp_mul_left (fun x => cos x) hn',
        intervalIntegral.integral_comp_mul_left (fun x => cos x) hn', integral_cos, integral_cos]
      simp [mul_neg, sin_neg, sin_nat_mul_pi]
  · have h := integral_squareWave_mul (fun x => sin (n * x)) (by fun_prop)
    rw [h]
    have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
    rw [intervalIntegral.integral_comp_mul_left (fun x => sin x) hn',
      intervalIntegral.integral_comp_mul_left (fun x => sin x) hn', integral_sin, integral_sin]
    simp only [mul_neg, cos_neg, mul_zero, cos_zero, cos_nat_mul_pi, smul_eq_mul]
    split_ifs with ho
    · rw [ho.neg_one_pow]; field_simp; ring
    · rw [(Nat.not_odd_iff_even.mp ho).neg_one_pow]; ring

-- The tones: odd multiples of 220 Hz give 660 Hz and 1100 Hz.
example : (220 * 3, 220 * 5) = (660, 1100) := by norm_num
-- b_3 / b_1 = (4/(3π)) / (4/π) = 1/3: the 660 Hz tone has a third of the 220 Hz amplitude.
example : ((4 : ℚ) / 3) / (4 / 1) = 1 / 3 := by norm_num
-- Three harmonics at x = π/2: (4/π)(1 − 1/3 + 1/5), and the bracket is 13/15.
example : (1 : ℚ) - 1 / 3 + 1 / 5 = 13 / 15 := by norm_num
-- Frequencies 1 and 1.5: product-to-sum gives sin(π/2)/(1/2) − sin(5π/2)/(5/2) = 2 − 2/5 = 8/5,
-- the card's 1.600000, not 0.
example : (1 : ℚ) / (1 / 2) - 1 / (5 / 2) = 8 / 5 := by norm_num

#print axioms harmonics_are_orthogonal_over_one_cycle
#print axioms fourier_coefficient_is_integral_against_its_wave
#print axioms square_wave_coefficients

end FourierSeries
