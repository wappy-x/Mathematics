-- The Gibbs overshoot and the cure: the Fejér mean of a signal, the average of its first N Fourier partial sums, never leaves the signal's range, because the Fejér kernel is a square that totals 1.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real Complex Finset

/-- The card's coefficient `f̂(n) = (1/2π) ∫_{−π}^{π} f(x) e^{−inx} dx`, Mathlib's `fourierCoeffOn`
on `[−π, π]`, for a real signal viewed as complex-valued. -/
noncomputable def coeff (f : ℝ → ℝ) (n : ℤ) : ℂ :=
  fourierCoeffOn (neg_lt_self Real.pi_pos) (fun t => (f t : ℂ)) n

/-- The partial sum of degree `k`: `S_k(x) = ∑_{|n| ≤ k} f̂(n) e^{inx}`. -/
noncomputable def partialSum (f : ℝ → ℝ) (k : ℕ) (x : ℝ) : ℂ :=
  ∑ n ∈ Icc (-(k : ℤ)) k, coeff f n * exp (n * x * I)

/-- The Fejér mean: `σ_N(x) = (1/N) ∑_{k=0}^{N−1} S_k(x)`, the plain average of the first N
partial sums. -/
noncomputable def fejerMean (f : ℝ → ℝ) (N : ℕ) (x : ℝ) : ℂ :=
  (1 / N) * ∑ k ∈ range N, partialSum f k x

/-- The Fejér kernel as the tapered tone sum `F_N(y) = ∑_{|n| < N} (1 − |n|/N) e^{iny}`. -/
noncomputable def fejerKernel (N : ℕ) (y : ℝ) : ℂ :=
  ∑ n ∈ Icc (-((N : ℤ) - 1)) ((N : ℤ) - 1), (1 - ((|n| : ℤ) : ℂ) / N) * exp (n * y * I)

lemma gs_sum_Icc_succ {β : Type*} [AddCommMonoid β] (g : ℤ → β) (k : ℕ) :
    ∑ n ∈ Icc (-((k : ℤ) + 1)) ((k : ℤ) + 1), g n
      = g (-((k : ℤ) + 1)) + g ((k : ℤ) + 1) + ∑ n ∈ Icc (-(k : ℤ)) k, g n := by
  have h : Icc (-((k : ℤ) + 1)) ((k : ℤ) + 1)
      = insert (-((k : ℤ) + 1)) (insert ((k : ℤ) + 1) (Icc (-(k : ℤ)) k)) := by
    ext n; simp only [mem_Icc, mem_insert]; omega
  rw [h, sum_insert, sum_insert, add_assoc]
  · simp only [mem_Icc]; omega
  · simp only [mem_insert, mem_Icc]; omega

#print axioms gs_sum_Icc_succ

lemma gs_sum_Icc_pair {β : Type*} [AddCommMonoid β] (g : ℤ → β) (k : ℕ) :
    ∑ n ∈ Icc (-(k : ℤ)) k, g n = g 0 + ∑ j ∈ range k, (g ((j : ℤ) + 1) + g (-((j : ℤ) + 1))) := by
  induction k with
  | zero => simp
  | succ k ih =>
    push_cast
    rw [gs_sum_Icc_succ, ih, sum_range_succ]
    abel

#print axioms gs_sum_Icc_pair

lemma gs_fejer_count (g : ℤ → ℂ) (M : ℕ) :
    ∑ k ∈ range (M + 1), ∑ n ∈ Icc (-(k : ℤ)) k, g n
      = ∑ n ∈ Icc (-(M : ℤ)) M, ((M : ℂ) + 1 - ((|n| : ℤ) : ℂ)) * g n := by
  induction M with
  | zero => simp
  | succ M ih =>
    rw [sum_range_succ, ih]
    push_cast
    rw [gs_sum_Icc_succ, gs_sum_Icc_succ]
    have h1 : |(-((M : ℤ) + 1))| = (M : ℤ) + 1 := by
      rw [abs_neg]; exact abs_of_nonneg (by positivity)
    have h2 : |((M : ℤ) + 1)| = (M : ℤ) + 1 := abs_of_nonneg (by positivity)
    rw [h1, h2]
    have h3 : ∑ n ∈ Icc (-(M : ℤ)) M, ((M : ℂ) + 1 + 1 - ((|n| : ℤ) : ℂ)) * g n
        = ∑ n ∈ Icc (-(M : ℤ)) M, ((M : ℂ) + 1 - ((|n| : ℤ) : ℂ)) * g n
          + ∑ n ∈ Icc (-(M : ℤ)) M, g n := by
      rw [← sum_add_distrib]; refine sum_congr rfl fun n _ => by ring
    rw [h3]; push_cast; ring

#print axioms gs_fejer_count

lemma gs_square (y : ℝ) (N : ℕ) :
    (∑ j ∈ range N, exp (j * y * I)) * (∑ j ∈ range N, exp (-(j * y * I)))
      = ∑ k ∈ range N, ∑ n ∈ Icc (-(k : ℤ)) k, exp (n * y * I) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [sum_range_succ', sum_range_succ' (fun j : ℕ => exp (-(j * y * I))), sum_range_succ, ← ih,
      gs_sum_Icc_pair]
    have ha : ∀ j : ℕ, exp (((j + 1 : ℕ) : ℂ) * y * I) = exp (y * I) * exp (j * y * I) := by
      intro j; rw [← Complex.exp_add]; push_cast; ring_nf
    have hb : ∀ j : ℕ, exp (-(((j + 1 : ℕ) : ℂ) * y * I)) = exp (-(y * I)) * exp (-(j * y * I)) := by
      intro j; rw [← Complex.exp_add]; push_cast; ring_nf
    simp_rw [ha, hb, ← mul_sum]
    have hab : exp (y * I) * exp (-(y * I)) = 1 := by rw [← Complex.exp_add]; simp
    have hc : ∑ j ∈ range N, (exp ((((j : ℤ) + 1 : ℤ) : ℂ) * y * I)
        + exp ((((-((j : ℤ) + 1)) : ℤ) : ℂ) * y * I))
        = exp (y * I) * ∑ j ∈ range N, exp (j * y * I)
          + exp (-(y * I)) * ∑ j ∈ range N, exp (-(j * y * I)) := by
      rw [mul_sum, mul_sum, ← sum_add_distrib]
      refine sum_congr rfl fun j _ => ?_
      rw [← Complex.exp_add, ← Complex.exp_add]; push_cast; ring_nf
    rw [hc]; simp only [Nat.cast_zero, zero_mul, neg_zero, Complex.exp_zero, Int.cast_zero]
    linear_combination (∑ j ∈ range N, exp (↑j * ↑y * I)) * (∑ j ∈ range N, exp (-(↑j * ↑y * I))) * hab

#print axioms gs_square

lemma gs_kernel_avg (M : ℕ) (y : ℝ) :
    fejerKernel (M + 1) y
      = 1 / ((M : ℂ) + 1) * ∑ k ∈ range (M + 1), ∑ n ∈ Icc (-(k : ℤ)) k, exp (n * y * I) := by
  rw [gs_fejer_count, fejerKernel, mul_sum]
  have hb : (((M + 1 : ℕ) : ℤ) - 1) = (M : ℤ) := by push_cast; ring
  rw [hb]
  refine sum_congr rfl fun n _ => ?_
  have : (M : ℂ) + 1 ≠ 0 := by norm_cast
  push_cast
  field_simp

#print axioms gs_kernel_avg

lemma gs_kernel_sq (N : ℕ) (hN : 0 < N) (y : ℝ) :
    fejerKernel N y = (((1 / N : ℝ) * ‖∑ j ∈ range N, exp (j * y * I)‖ ^ 2 : ℝ) : ℂ) := by
  obtain ⟨M, rfl⟩ : ∃ M, N = M + 1 := ⟨N - 1, by omega⟩
  rw [gs_kernel_avg, ← gs_square]
  have hc : (∑ j ∈ range (M + 1), exp (-(j * y * I)))
      = (starRingEnd ℂ) (∑ j ∈ range (M + 1), exp (j * y * I)) := by
    rw [map_sum]; refine sum_congr rfl fun j _ => ?_
    rw [← Complex.exp_conj]; congr 1; simp [conj_ofReal]
  rw [hc, Complex.mul_conj, Complex.normSq_eq_norm_sq]
  push_cast; ring

#print axioms gs_kernel_sq

lemma gs_int_exp (n : ℤ) :
    ∫ t in (-π)..π, exp (n * t * I) = if n = 0 then (2 * π : ℂ) else 0 := by
  split_ifs with h
  · subst h; simp; ring
  · have hc : (n : ℂ) * I ≠ 0 := mul_ne_zero (by exact_mod_cast h) I_ne_zero
    have e : ∀ t : ℝ, exp (n * t * I) = exp ((n * I) * t) := fun t => by ring_nf
    simp_rw [e]
    rw [integral_exp_mul_complex hc]
    have hp : exp (n * I * (π : ℂ)) = exp (n * I * ((-π : ℝ) : ℂ)) := by
      rw [show (n : ℂ) * I * (π : ℂ) = n * I * ((-π : ℝ) : ℂ) + n * (2 * π * I) by push_cast; ring,
        Complex.exp_add, exp_int_mul_two_pi_mul_I, mul_one]
    rw [hp, sub_self, zero_div]

#print axioms gs_int_exp

lemma gs_int_exp_shift (x : ℝ) (n : ℤ) :
    ∫ t in (-π)..π, exp (n * (x - t) * I) = if n = 0 then (2 * π : ℂ) else 0 := by
  have e : ∀ t : ℝ, exp (n * ((x : ℂ) - t) * I) = exp (n * x * I) * exp (((-n : ℤ) : ℂ) * t * I) := by
    intro t; rw [← Complex.exp_add]; congr 1; push_cast; ring
  simp_rw [e]
  rw [intervalIntegral.integral_const_mul, gs_int_exp]
  by_cases h : n = 0
  · subst h; simp
  · simp [h]

#print axioms gs_int_exp_shift

lemma gs_kernel_cont (N : ℕ) : Continuous (fun y : ℝ => fejerKernel N y) := by
  unfold fejerKernel; fun_prop

#print axioms gs_kernel_cont

lemma gs_int_kernel_shift (N : ℕ) (hN : 0 < N) (x : ℝ) :
    ∫ t in (-π)..π, fejerKernel N (x - t) = 2 * π := by
  unfold fejerKernel
  rw [intervalIntegral.integral_finsetSum]
  · simp_rw [Complex.ofReal_sub, intervalIntegral.integral_const_mul, gs_int_exp_shift, mul_ite, mul_zero]
    rw [sum_ite_eq']
    · simp; omega
  · intro n _
    exact (by fun_prop : Continuous fun t : ℝ => (1 - ((|n| : ℤ) : ℂ) / N) * exp (n * ((x - t : ℝ) : ℂ) * I)).intervalIntegrable _ _

#print axioms gs_int_kernel_shift

lemma gs_coeff (f : ℝ → ℝ) (n : ℤ) :
    coeff f n = 1 / (2 * π : ℂ) * ∫ t in (-π)..π, (f t : ℂ) * exp (-(n * t * I)) := by
  unfold coeff
  rw [fourierCoeffOn_eq_integral]
  simp only [fourier_coe_apply, Complex.real_smul, smul_eq_mul]
  have hp : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  congr 1
  · push_cast; ring
  · refine intervalIntegral.integral_congr fun t _ => ?_
    rw [mul_comm]; congr 2; push_cast; field_simp; ring

#print axioms gs_coeff

lemma gs_term (f : ℝ → ℝ) (n : ℤ) (x : ℝ) :
    coeff f n * exp (n * x * I)
      = 1 / (2 * π : ℂ) * ∫ t in (-π)..π, (f t : ℂ) * exp (n * ((x - t : ℝ) : ℂ) * I) := by
  rw [gs_coeff, mul_assoc, ← intervalIntegral.integral_mul_const]
  congr 2; ext t
  rw [mul_assoc, ← Complex.exp_add]; congr 2; push_cast; ring

#print axioms gs_term

lemma gs_ofReal_ii (f : ℝ → ℝ) (a b : ℝ) (hf : IntervalIntegrable f MeasureTheory.volume a b) :
    IntervalIntegrable (fun t => (f t : ℂ)) MeasureTheory.volume a b :=
  ⟨hf.1.ofReal, hf.2.ofReal⟩

#print axioms gs_ofReal_ii

lemma gs_mean_rep (f : ℝ → ℝ) (hf : IntervalIntegrable f MeasureTheory.volume (-π) π)
    (M : ℕ) (x : ℝ) :
    fejerMean f (M + 1) x
      = 1 / (2 * π : ℂ) * ∫ t in (-π)..π, (f t : ℂ) * fejerKernel (M + 1) (x - t) := by
  have hfC := gs_ofReal_ii f _ _ hf
  set c : ℂ := 1 / ((M : ℂ) + 1) with hc
  have hint : ∀ n : ℤ, IntervalIntegrable
      (fun t : ℝ => c * ((f t : ℂ) * exp (n * ((x - t : ℝ) : ℂ) * I))) MeasureTheory.volume (-π) π :=
    fun n => (hfC.mul_continuousOn
      (by fun_prop : Continuous fun t : ℝ => exp (n * ((x - t : ℝ) : ℂ) * I)).continuousOn).const_mul c
  have hpt : ∀ t : ℝ, (f t : ℂ) * fejerKernel (M + 1) (x - t)
      = ∑ k ∈ range (M + 1), ∑ n ∈ Icc (-(k : ℤ)) k,
          c * ((f t : ℂ) * exp (n * ((x - t : ℝ) : ℂ) * I)) := by
    intro t; rw [gs_kernel_avg, ← hc]; simp only [mul_sum]
    exact sum_congr rfl fun k _ => sum_congr rfl fun n _ => by ring
  simp_rw [hpt]
  rw [intervalIntegral.integral_finsetSum]
  · unfold fejerMean partialSum
    simp_rw [gs_term]
    rw [mul_sum, mul_sum]
    refine sum_congr rfl fun k _ => ?_
    rw [intervalIntegral.integral_finsetSum (fun n _ => hint n), mul_sum, mul_sum]
    refine sum_congr rfl fun n _ => ?_
    rw [intervalIntegral.integral_const_mul, hc]; push_cast; ring
  · intro k _
    have := IntervalIntegrable.sum (Icc (-(k : ℤ)) k) (fun n _ => hint n)
    convert this using 1; ext t; simp [Finset.sum_apply]

#print axioms gs_mean_rep

lemma gs_exp_pi_sym (n : ℤ) : exp (-(n * I * π)) = exp (n * I * π) := by
  rw [show -((n : ℂ) * I * π) = n * I * π + ((-n : ℤ) : ℂ) * (2 * π * I) by push_cast; ring,
    Complex.exp_add, exp_int_mul_two_pi_mul_I, mul_one]

#print axioms gs_exp_pi_sym

lemma gs_exp_pi (n : ℤ) : exp (n * I * π) = (-1) ^ n.natAbs := by
  have hm : ∀ m : ℕ, exp ((m : ℂ) * I * π) = (-1) ^ m := fun m => by
    rw [show (m : ℂ) * I * π = m * (π * I) by ring, Complex.exp_nat_mul, exp_pi_mul_I]
  obtain ⟨m, rfl | rfl⟩ := Int.eq_nat_or_neg n
  · rw [Int.natAbs_natCast]; push_cast; exact hm _
  · rw [Int.natAbs_neg, Int.natAbs_natCast]
    rw [show (((-(m : ℤ)) : ℤ) : ℂ) * I * π = -(((m : ℤ) : ℂ) * I * π) by push_cast; ring, gs_exp_pi_sym]
    push_cast; exact hm _

#print axioms gs_exp_pi

lemma gs_sq_ii_real (a b : ℝ) :
    IntervalIntegrable (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) MeasureTheory.volume a b := by
  apply Monotone.intervalIntegrable
  intro s t hst
  dsimp only
  split_ifs with h1 h2 <;> (try simp only [not_le] at *) <;> linarith

#print axioms gs_sq_ii_real

lemma gs_sq_ii (a b : ℝ) :
    IntervalIntegrable (fun t : ℝ => (((if t ≤ 0 then (-1 : ℝ) else 1) : ℝ) : ℂ))
      MeasureTheory.volume a b :=
  gs_ofReal_ii (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) a b (gs_sq_ii_real a b)

#print axioms gs_sq_ii

lemma gs_sq_split (h : ℝ → ℂ) (hc : Continuous h) :
    ∫ t in (-π)..π, (((if t ≤ 0 then (-1 : ℝ) else 1) : ℝ) : ℂ) * h t
      = -(∫ t in (-π)..0, h t) + ∫ t in (0 : ℝ)..π, h t := by
  have hi : ∀ a b : ℝ, IntervalIntegrable
      (fun t : ℝ => (((if t ≤ 0 then (-1 : ℝ) else 1) : ℝ) : ℂ) * h t) MeasureTheory.volume a b :=
    fun a b => (gs_sq_ii a b).mul_continuousOn hc.continuousOn
  rw [← intervalIntegral.integral_add_adjacent_intervals (hi (-π) 0) (hi 0 π),
    ← intervalIntegral.integral_neg]
  congr 1
  · refine intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall fun t ht => ?_)
    rw [Set.uIoc_of_le (by linarith [pi_pos])] at ht
    simp [ht.2]
  · refine intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall fun t ht => ?_)
    rw [Set.uIoc_of_le pi_pos.le] at ht
    simp [not_le.mpr ht.1]

#print axioms gs_sq_split

lemma gs_sq_coeff (n : ℤ) (hn : n ≠ 0) :
    coeff (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) n
      = (((-1) ^ n.natAbs - 1) * I) / (π * n) := by
  rw [gs_coeff, gs_sq_split _ (by fun_prop)]
  set c : ℂ := -(n * I) with hc
  have hc0 : c ≠ 0 := by rw [hc]; exact neg_ne_zero.mpr (mul_ne_zero (by exact_mod_cast hn) I_ne_zero)
  have e : ∀ t : ℝ, exp (-(n * t * I)) = exp (c * t) := fun t => by rw [hc]; ring_nf
  simp_rw [e]
  rw [integral_exp_mul_complex hc0, integral_exp_mul_complex hc0]
  have h1 : exp (c * ((-π : ℝ) : ℂ)) = (-1) ^ n.natAbs := by
    rw [← gs_exp_pi]; congr 1; rw [hc]; push_cast; ring
  have h2 : exp (c * (π : ℂ)) = (-1) ^ n.natAbs := by
    rw [← gs_exp_pi, ← gs_exp_pi_sym]; congr 1; rw [hc]; ring
  rw [h1, h2]
  simp only [Complex.ofReal_zero, mul_zero, Complex.exp_zero]
  have hp : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  have hn' : (n : ℂ) ≠ 0 := by exact_mod_cast hn
  rw [hc]
  field_simp
  linear_combination (-2 * ((-1) ^ n.natAbs - 1) : ℂ) * I_sq

#print axioms gs_sq_coeff

lemma gs_sq_coeff_zero :
    coeff (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) 0 = 0 := by
  rw [gs_coeff, gs_sq_split _ (by fun_prop)]
  simp

#print axioms gs_sq_coeff_zero

lemma gs_sq_pair (x : ℝ) (j : ℕ) :
    coeff (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) ((j : ℤ) + 1)
        * exp ((((j : ℤ) + 1 : ℤ) : ℂ) * x * I)
      + coeff (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) (-((j : ℤ) + 1))
        * exp (((-((j : ℤ) + 1) : ℤ) : ℂ) * x * I)
      = ((4 / π * (if Odd (j + 1) then Real.sin ((j + 1 : ℕ) * x) / (j + 1 : ℕ) else 0) : ℝ) : ℂ) := by
  rw [gs_sq_coeff _ (by omega), gs_sq_coeff _ (by omega)]
  have hA : ((j : ℤ) + 1).natAbs = j + 1 := by omega
  have hB : (-((j : ℤ) + 1)).natAbs = j + 1 := by omega
  rw [hA, hB]
  have e1 : exp ((((j : ℤ) + 1 : ℤ) : ℂ) * x * I)
      = Complex.cos (((j + 1 : ℕ) : ℂ) * x) + Complex.sin (((j + 1 : ℕ) : ℂ) * x) * I := by
    rw [← Complex.exp_mul_I]; push_cast; ring_nf
  have e2 : exp (((-((j : ℤ) + 1) : ℤ) : ℂ) * x * I)
      = Complex.cos (((j + 1 : ℕ) : ℂ) * x) - Complex.sin (((j + 1 : ℕ) : ℂ) * x) * I := by
    rw [show (((-((j : ℤ) + 1) : ℤ) : ℂ) * x * I) = (-(((j + 1 : ℕ) : ℂ) * x)) * I by push_cast; ring,
      Complex.exp_mul_I, Complex.cos_neg, Complex.sin_neg]; ring
  rw [e1, e2]
  have hp : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  have hj : ((j : ℂ) + 1) ≠ 0 := by norm_cast
  rcases Nat.even_or_odd (j + 1) with h | h
  · rw [h.neg_one_pow, ite_eq_right (Nat.not_odd_iff_even.mpr h)]
    push_cast; ring
  · rw [h.neg_one_pow, ite_eq_left h]
    push_cast
    field_simp
    linear_combination (-4 * Complex.sin (((j : ℂ) + 1) * x) : ℂ) * I_sq

#print axioms gs_sq_pair

lemma gs_sq_partial (x : ℝ) (k : ℕ) :
    partialSum (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) k x
      = ((4 / π * ∑ m ∈ range (k + 1),
          (if Odd m then Real.sin (m * x) / m else 0) : ℝ) : ℂ) := by
  unfold partialSum
  rw [gs_sum_Icc_pair, gs_sq_coeff_zero, zero_mul, zero_add]
  simp_rw [gs_sq_pair]
  rw [sum_range_succ', ite_eq_right (by decide)]
  push_cast
  rw [add_zero, mul_sum]

#print axioms gs_sq_partial

lemma gs_count (b : ℕ → ℝ) (N : ℕ) :
    ∑ k ∈ range N, ∑ m ∈ range (k + 1), b m = ∑ m ∈ range N, ((N : ℝ) - m) * b m := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [sum_range_succ, ih]
    simp only [sum_range_succ]
    have : ∑ m ∈ range N, (((N + 1 : ℕ) : ℝ) - m) * b m
        = ∑ m ∈ range N, ((N : ℝ) - m) * b m + ∑ m ∈ range N, b m := by
      rw [← sum_add_distrib]; refine sum_congr rfl fun m _ => ?_; push_cast; ring
    rw [this]; push_cast; ring

#print axioms gs_count

lemma gs_sq_mean (N : ℕ) (hN : 0 < N) (x : ℝ) :
    fejerMean (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) N x
      = ((4 / π * ∑ n ∈ (range N).filter Odd, (1 - (n : ℝ) / N) * Real.sin (n * x) / n : ℝ) : ℂ) := by
  unfold fejerMean
  simp_rw [gs_sq_partial]
  rw [← Complex.ofReal_sum, ← mul_sum, gs_count, sum_filter, mul_sum, mul_sum]
  have hN' : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
  push_cast
  rw [mul_sum]
  refine sum_congr rfl fun n _ => ?_
  split_ifs with hn
  · have hNc : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
    have hnc : (n : ℂ) ≠ 0 := by
      norm_cast; rintro rfl; exact absurd hn (by decide)
    push_cast; field_simp
  · simp

#print axioms gs_sq_mean

/-- Fejér's no-overshoot theorem: if a signal lies between `m` and `M` on a cycle `[−π, π]`
(and can be integrated there), then for every `N ≥ 1` and every `x` its Fejér mean `σ_N(x)`,
the average of its first `N` Fourier partial sums, is a real number between `m` and `M`.
Averaging never climbs past the signal's top or below its bottom, even beside a jump. -/
theorem fejer_mean_stays_in_range (f : ℝ → ℝ) (m M : ℝ)
    (hf : IntervalIntegrable f MeasureTheory.volume (-π) π)
    (hbound : ∀ t ∈ Set.Icc (-π) π, m ≤ f t ∧ f t ≤ M)
    (N : ℕ) (hN : 0 < N) (x : ℝ) :
    ∃ r : ℝ, fejerMean f N x = r ∧ m ≤ r ∧ r ≤ M := by
  obtain ⟨L, rfl⟩ : ∃ L, N = L + 1 := ⟨N - 1, by omega⟩
  set k : ℝ → ℝ := fun t =>
    (1 / ((L + 1 : ℕ) : ℝ)) * ‖∑ j ∈ range (L + 1), exp (j * ((x - t : ℝ) : ℂ) * I)‖ ^ 2 with hk
  have hkK : ∀ t, fejerKernel (L + 1) (x - t) = (k t : ℂ) := fun t => gs_kernel_sq _ (by omega) _
  have hkc : Continuous k := by rw [hk]; fun_prop
  have hk0 : ∀ t, 0 ≤ k t := fun t => by rw [hk]; positivity
  have hkI : ∫ t in (-π)..π, k t = 2 * π := by
    have h := gs_int_kernel_shift (L + 1) (by omega) x
    simp_rw [hkK] at h
    rw [intervalIntegral.integral_ofReal] at h
    exact_mod_cast h
  have hfk : IntervalIntegrable (fun t => f t * k t) MeasureTheory.volume (-π) π :=
    hf.mul_continuousOn hkc.continuousOn
  refine ⟨(∫ t in (-π)..π, f t * k t) / (2 * π), ?_, ?_, ?_⟩
  · rw [gs_mean_rep f hf]
    simp_rw [hkK]
    have h : ∫ t in (-π)..π, (f t : ℂ) * (k t : ℂ) = ((∫ t in (-π)..π, f t * k t : ℝ) : ℂ) := by
      rw [← intervalIntegral.integral_ofReal]; simp_rw [Complex.ofReal_mul]
    rw [h]; push_cast; ring
  · have hlo : ∫ t in (-π)..π, m * k t ≤ ∫ t in (-π)..π, f t * k t :=
      intervalIntegral.integral_mono_on (by linarith [pi_pos])
        ((hkc.intervalIntegrable _ _).const_mul m) hfk
        (fun t ht => mul_le_mul_of_nonneg_right (hbound t ht).1 (hk0 t))
    rw [intervalIntegral.integral_const_mul, hkI] at hlo
    rw [le_div_iff₀ (by positivity)]; linarith
  · have hhi : ∫ t in (-π)..π, f t * k t ≤ ∫ t in (-π)..π, M * k t :=
      intervalIntegral.integral_mono_on (by linarith [pi_pos]) hfk
        ((hkc.intervalIntegrable _ _).const_mul M)
        (fun t ht => mul_le_mul_of_nonneg_right (hbound t ht).2 (hk0 t))
    rw [intervalIntegral.integral_const_mul, hkI] at hhi
    rw [div_le_iff₀ (by positivity)]; linarith

/-- The Fejér kernel is a square divided by `N`, so never negative, and its average over a
cycle is 1: `F_N(y) = (1/N) |1 + e^{iy} + ⋯ + e^{i(N−1)y}|²` and `(1/2π) ∫_{−π}^{π} F_N = 1`. -/
theorem fejer_kernel_square_and_total_one (N : ℕ) (hN : 0 < N) :
    (∀ y : ℝ, fejerKernel N y =
        (((1 / N : ℝ) * ‖∑ j ∈ range N, exp (j * y * I)‖ ^ 2 : ℝ) : ℂ)) ∧
    (1 / (2 * π) : ℂ) * ∫ y in (-π)..π, fejerKernel N y = 1 := by
  refine ⟨fun y => gs_kernel_sq N hN y, ?_⟩
  have h := gs_int_kernel_shift N hN 0
  simp only [zero_sub] at h
  rw [intervalIntegral.integral_comp_neg (fun t => fejerKernel N t), neg_neg] at h
  rw [h]
  have hp : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  field_simp

/-- The siren never overshoots once averaged: the Fejér mean of the ±1 V square wave,
`σ_N(x) = (4/π) ∑_{n < N, n odd} (1 − n/N) sin(nx)/n`, stays between −1 V and +1 V
for every `N ≥ 1` and every `x`. -/
theorem square_wave_fejer_mean_no_overshoot (N : ℕ) (hN : 0 < N) (x : ℝ) :
    |4 / π * ∑ n ∈ (range N).filter Odd, (1 - (n : ℝ) / N) * Real.sin (n * x) / n| ≤ 1 := by
  obtain ⟨r, hr, h1, h2⟩ := fejer_mean_stays_in_range
    (fun t : ℝ => if t ≤ 0 then (-1 : ℝ) else 1) (-1) 1 (gs_sq_ii_real _ _)
    (fun t _ => by split_ifs <;> norm_num) N hN x
  rw [gs_sq_mean N hN x] at hr
  rw [Complex.ofReal_injective hr]
  exact abs_le.mpr ⟨h1, h2⟩

-- CD rate 44,100 per second keeps tones below 22,050 Hz: the 100th harmonic of 220 Hz fits,
-- the 101st does not, and the last odd one, the 99th, sits at 21,780 Hz.
example : 44100 / 2 = 22050 ∧ 100 * 220 < 22050 ∧ 22050 < 101 * 220 ∧ 99 * 220 = 21780 := by
  decide

-- Step 1, N = 4: harmonic 1 enters 3 of S_0..S_3 and harmonic 3 enters 1, so the average
-- keeps 3/4 of the first and 1/4 of the third.
example : ((range 4).filter (fun k => 1 ≤ k)).card = 3 ∧
    ((range 4).filter (fun k => 3 ≤ k)).card = 1 := by
  decide

example : (1 : ℚ) - 1 / 4 = 3 / 4 ∧ (1 : ℚ) - 3 / 4 = 1 / 4 := by
  norm_num

-- Step 2, N = 4: the pairs (j, k) with j − k = n number N − |n|.
example : ((range 4 ×ˢ range 4).filter (fun p : ℕ × ℕ => (p.1 : ℤ) - p.2 = 1)).card = 3 ∧
    ((range 4 ×ˢ range 4).filter (fun p : ℕ × ℕ => (p.1 : ℤ) - p.2 = -3)).card = 1 := by
  decide

-- At mid-top, sin(π/2) = 1 and sin(3π/2) = −1, so S_3 and σ_4 both give (4/π) × 2/3:
-- 1 − 1/3 = 2/3 and (3/4)·1 + (1/4)·(−1/3) = 2/3.
example : (1 : ℚ) - 1 / 3 = 2 / 3 ∧ (3 / 4 : ℚ) * 1 + (1 / 4) * (-1 / 3) = 2 / 3 := by
  norm_num

#print axioms fejer_mean_stays_in_range
#print axioms fejer_kernel_square_and_total_one
#print axioms square_wave_fejer_mean_no_overshoot
