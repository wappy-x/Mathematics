-- Fourier series: for a signal that repeats every 2π and has a finite average of |f|^2, the sums of the arrows c_n e^(inx), with each c_n the average of f(x) e^(−inx) over one cycle, close in on the signal on average and Parseval holds; a convergent sum of arrows gives back its own amounts as these averages; and the square wave's amounts are 2/(iπn) for odd n and 0 for even n.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Tactic.NormNum
import Mathlib.Order.Filter.AtTopBot.Interval
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Complex MeasureTheory Filter Topology
open Real

lemma fs_fourier_coe (n : ℤ) (x : ℝ) :
    haveI : Fact (0 < 2 * π) := ⟨by positivity⟩
    fourier n (x : AddCircle (2 * π)) = Complex.exp (n * x * I) := by
  rw [fourier_coe_apply]
  congr 1
  have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  field_simp
  push_cast; ring

#print axioms fs_fourier_coe

lemma fs_haar_integral (g : ℝ → ℝ) :
    haveI : Fact (0 < 2 * π) := ⟨by positivity⟩
    ∫ t : AddCircle (2 * π), AddCircle.liftIoc (2 * π) (-π) g t ∂AddCircle.haarAddCircle
      = (1 / (2 * π)) * ∫ x in (-π)..π, g x := by
  haveI : Fact (0 < 2 * π) := ⟨by positivity⟩
  rw [AddCircle.integral_haarAddCircle, AddCircle.integral_liftIoc_eq_intervalIntegral,
    show -π + 2 * π = π by ring, smul_eq_mul, one_div]

#print axioms fs_haar_integral

lemma fs_L2_norm_sq {α : Type*} [MeasurableSpace α] {μ : Measure α} (G : Lp ℂ 2 μ) :
    ‖G‖ ^ 2 = ∫ t, ‖G t‖ ^ 2 ∂μ := by
  have h := L2.inner_def (𝕜 := ℂ) G G
  rw [inner_self_eq_norm_sq_to_K] at h
  simp_rw [inner_self_eq_norm_sq_to_K] at h
  apply Complex.ofReal_injective
  rw [integral_complex_ofReal.symm]
  push_cast
  exact h

#print axioms fs_L2_norm_sq

lemma fs_exp_odd (n : ℤ) (hn : Odd n) : Complex.exp (n * π * I) = -1 := by
  obtain ⟨k, rfl⟩ := hn
  have : ((2 * k + 1 : ℤ) : ℂ) * π * I = k * (2 * π * I) + π * I := by push_cast; ring
  rw [this, Complex.exp_add, exp_int_mul_two_pi_mul_I, exp_pi_mul_I, one_mul]

#print axioms fs_exp_odd

lemma fs_exp_even (n : ℤ) (hn : Even n) : Complex.exp (n * π * I) = 1 := by
  obtain ⟨k, rfl⟩ := hn
  have : ((k + k : ℤ) : ℂ) * π * I = k * (2 * π * I) := by push_cast; ring
  rw [this, exp_int_mul_two_pi_mul_I]

#print axioms fs_exp_even

lemma fs_exp_neg (k : ℤ) : Complex.exp (-(k * π * I)) = Complex.exp (k * π * I) := by
  rw [← mul_one (Complex.exp (-(k * π * I))), ← exp_int_mul_two_pi_mul_I k, ← Complex.exp_add]
  congr 1; ring

#print axioms fs_exp_neg

lemma fs_int_exp (n : ℤ) (hn : n ≠ 0) (a b : ℝ) :
    ∫ x in a..b, Complex.exp (-(n * x * I)) =
      (Complex.exp (-(n * b * I)) - Complex.exp (-(n * a * I))) / (-(n * I)) := by
  have hc : (-(n * I) : ℂ) ≠ 0 := by simp [hn]
  simp_rw [show ∀ x : ℝ, -((n : ℂ) * x * I) = (-(n * I)) * x by intro; ring]
  exact integral_exp_mul_complex hc

#print axioms fs_int_exp

lemma fs_int_exp_cycle (n : ℤ) (hn : n ≠ 0) :
    ∫ x in (-π)..π, Complex.exp (-(n * x * I)) = 0 := by
  rw [fs_int_exp n hn, fs_exp_neg]
  push_cast
  rw [show -((n : ℂ) * -π * I) = n * π * I by ring, sub_self, zero_div]

#print axioms fs_int_exp_cycle

lemma fs_square_split (f : ℝ → ℂ) (hpos : ∀ x ∈ Set.Ioo 0 π, f x = 1)
    (hneg : ∀ x ∈ Set.Ioo (-π) 0, f x = -1) (n : ℤ) :
    ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) =
      -(∫ x in (-π)..0, Complex.exp (-(n * x * I))) + ∫ x in (0 : ℝ)..π, Complex.exp (-(n * x * I)) := by
  have hp := pi_pos
  have i1 : IntervalIntegrable (fun x : ℝ => f x * Complex.exp (-(n * x * I))) volume (-π) 0 := by
    have : IntervalIntegrable (fun x : ℝ => -Complex.exp (-(n * x * I))) volume (-π) 0 :=
      (by fun_prop : Continuous fun x : ℝ => -Complex.exp (-(n * x * I))).intervalIntegrable _ _
    refine this.congr_uIoo fun x hx => ?_
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp [hneg x hx]
  have i2 : IntervalIntegrable (fun x : ℝ => f x * Complex.exp (-(n * x * I))) volume 0 π := by
    have : IntervalIntegrable (fun x : ℝ => Complex.exp (-(n * x * I))) volume 0 π :=
      (by fun_prop : Continuous fun x : ℝ => Complex.exp (-(n * x * I))).intervalIntegrable _ _
    refine this.congr_uIoo fun x hx => ?_
    rw [Set.uIoo_of_le (by linarith)] at hx
    simp [hpos x hx]
  rw [← intervalIntegral.integral_add_adjacent_intervals i1 i2, ← intervalIntegral.integral_neg]
  congr 1
  · refine intervalIntegral.integral_congr_Ioo_of_le (by linarith) fun x hx => ?_
    simp [hneg x hx]
  · refine intervalIntegral.integral_congr_Ioo_of_le (by linarith) fun x hx => ?_
    simp [hpos x hx]

#print axioms fs_square_split

/-- **A repeating signal is the sum of its arrows, and Parseval holds.** Let f be a signal that
repeats every 2π and whose square |f|^2 has a finite average over one cycle (f is measurable
and the integral of |f(x)|^2 from −π to π is finite). Let c_n be the average over one cycle of
f(x) e^(−inx), that is c_n = (1/2π) ∫_{−π}^{π} f(x) e^(−inx) dx. Let S_N be the sum of the
arrows c_n e^(inx) for n from −N to N. Then the average of |f − S_N|^2 over a cycle tends to 0
as N grows, and the sum over all whole numbers n of |c_n|^2 equals the average of |f|^2. -/
theorem fourier_series_converges_in_mean_and_parseval
    (f : ℝ → ℂ) (hper : Function.Periodic f (2 * π))
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π)))
    (c : ℤ → ℂ)
    (hc : ∀ n : ℤ, c n = (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I))) :
    Tendsto (fun N : ℕ => (1 / (2 * π)) * ∫ x in (-π)..π,
        ‖f x - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, c n * Complex.exp (n * x * I)‖ ^ 2) atTop (𝓝 0) ∧
      HasSum (fun n : ℤ => ‖c n‖ ^ 2) ((1 / (2 * π)) * ∫ x in (-π)..π, ‖f x‖ ^ 2) := by
  haveI hT : Fact (0 < 2 * π) := ⟨by positivity⟩
  have hab : -π + 2 * π = π := by ring
  have hf' : MemLp f 2 (volume.restrict (Set.Ioc (-π) (-π + 2 * π))) := by rw [hab]; exact hf
  have hL := (hf'.memLp_liftIoc (T := 2 * π)).haarAddCircle
  set F := hL.toLp with hFdef
  have hcoef : ∀ n : ℤ, fourierCoeff (F : AddCircle (2 * π) → ℂ) n = c n := by
    intro n
    rw [fourierCoeff_congr_ae hL.coeFn_toLp, fourierCoeff_eq_intervalIntegral _ n (-π), hab, hc n,
      Complex.real_smul]
    congr 1
    · push_cast; ring
    · apply intervalIntegral.integral_congr_ae
      refine ae_of_all _ fun x hx => ?_
      rw [Set.uIoc_of_le (by linarith [Real.pi_pos])] at hx
      rw [AddCircle.liftIoc_coe_apply (by rwa [hab]), fs_fourier_coe, smul_eq_mul, mul_comm]
      congr 2
      push_cast; ring
  constructor
  · have hS := hasSum_fourier_series_L2 F
    simp_rw [hcoef] at hS
    have h1 := (hS.comp (Finset.tendsto_Icc_neg (R := ℤ)))
    have h2 := (tendsto_iff_norm_sub_tendsto_zero.mp h1).pow 2
    rw [zero_pow two_ne_zero] at h2
    refine h2.congr fun N => ?_
    simp only [Function.comp_apply]
    rw [norm_sub_rev, fs_L2_norm_sq,
      ← fs_haar_integral (fun x => ‖f x - ∑ n ∈ Finset.Icc (-(N : ℤ)) N,
        c n * Complex.exp (n * x * I)‖ ^ 2)]
    have hsum : (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourierLp (T := 2 * π) 2 i) =
        ContinuousMap.toLp 2 AddCircle.haarAddCircle ℂ
          (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourier i) := by
      rw [map_sum]; simp [map_smul]
    rw [hsum]
    apply integral_congr_ae
    filter_upwards [Lp.coeFn_sub F (ContinuousMap.toLp 2 AddCircle.haarAddCircle ℂ
          (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourier i)), hL.coeFn_toLp,
        ContinuousMap.coeFn_toLp (p := 2) (𝕜 := ℂ) (μ := AddCircle.haarAddCircle)
          (∑ i ∈ Finset.Icc (-(N : ℤ)) N, c i • fourier i)] with t h1 h2 h3
    rw [h1, Pi.sub_apply, h2, h3]
    simp only [AddCircle.liftIoc, Function.comp_apply, Set.domRestrict_apply,
      AddCircle.coe_equivIoc, ContinuousMap.coe_sum, ContinuousMap.coe_smul, Finset.sum_apply,
      Pi.smul_apply, smul_eq_mul]
    congr 3
    refine Finset.sum_congr rfl fun n _ => ?_
    rw [← fs_fourier_coe, AddCircle.coe_equivIoc]
  · have hP := hasSum_sq_fourierCoeff F
    simp_rw [hcoef] at hP
    convert hP using 1
    rw [← fs_haar_integral]
    apply integral_congr_ae
    filter_upwards [hL.coeFn_toLp] with t ht
    rw [ht]
    rfl

/-- **Each coefficient is an average.** If a signal f is a sum of arrows c_m e^(imx) over all
whole numbers m, and the sum converges well enough (the lengths |c_m| have a finite sum), then
for every whole number n the amount c_n is the average over one cycle of f(x) e^(−inx):
c_n = (1/2π) ∫_{−π}^{π} f(x) e^(−inx) dx. -/
theorem fourier_coefficient_eq_average
    (c : ℤ → ℂ) (hc : Summable fun m : ℤ => ‖c m‖)
    (f : ℝ → ℂ) (hf : ∀ x : ℝ, f x = ∑' m : ℤ, c m * Complex.exp (m * x * I)) (n : ℤ) :
    c n = (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) := by
  have hπ : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  let g : ℤ → C(ℝ, ℂ) := fun m =>
    ⟨fun x => c m * Complex.exp (m * x * I) * Complex.exp (-(n * x * I)), by fun_prop⟩
  have hsum : Summable fun m => ‖(g m).restrict
      (⟨Set.uIcc (-π) π, isCompact_uIcc⟩ : TopologicalSpace.Compacts ℝ)‖ := by
    refine Summable.of_nonneg_of_le (fun _ => norm_nonneg _) (fun m => ?_) hc
    refine (ContinuousMap.norm_le _ (norm_nonneg _)).mpr fun x => ?_
    simp only [ContinuousMap.restrict_apply, ContinuousMap.coe_mk, g, norm_mul]
    rw [show (m : ℂ) * (x : ℝ) * I = ((m * x : ℝ) : ℂ) * I by push_cast; ring,
      show -((n : ℂ) * (x : ℝ) * I) = ((-(n * x) : ℝ) : ℂ) * I by push_cast; ring,
      Complex.norm_exp_ofReal_mul_I, Complex.norm_exp_ofReal_mul_I]
    simp
  have key := intervalIntegral.tsum_intervalIntegral_eq_of_summable_norm hsum
  have hint : ∀ m, ∫ x in (-π)..π, g m x = if m = n then 2 * π * c n else 0 := by
    intro m
    simp only [ContinuousMap.coe_mk, g]
    split_ifs with hmn
    · subst hmn
      simp_rw [mul_assoc, ← Complex.exp_add, add_neg_cancel, Complex.exp_zero, mul_one]
      simp
      ring
    · have : (fun x : ℝ => c m * Complex.exp (m * x * I) * Complex.exp (-(n * x * I))) =
          fun x : ℝ => c m * Complex.exp (-(((n - m : ℤ) : ℂ) * x * I)) := by
        funext x
        rw [mul_assoc, ← Complex.exp_add]
        congr 2
        push_cast; ring
      rw [this, intervalIntegral.integral_const_mul,
        fs_int_exp_cycle _ (sub_ne_zero.mpr (Ne.symm hmn)), mul_zero]
  have hfx : (fun x : ℝ => f x * Complex.exp (-(n * x * I))) = fun x => ∑' m, g m x := by
    funext x
    rw [hf, ← tsum_mul_right]
    rfl
  rw [hfx, ← key]
  simp_rw [hint]
  rw [tsum_ite_eq]
  field_simp

/-- **The square wave has only odd tones.** Let f be +1 on (0, π) and −1 on (−π, 0). Then the
average over one cycle of f(x) e^(−inx) is 2/(iπn) for every odd n and 0 for every even n. -/
theorem square_wave_fourier_coefficients
    (f : ℝ → ℂ) (hpos : ∀ x ∈ Set.Ioo 0 π, f x = 1) (hneg : ∀ x ∈ Set.Ioo (-π) 0, f x = -1) :
    (∀ n : ℤ, Odd n →
        (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) = 2 / (I * π * n)) ∧
      (∀ n : ℤ, Even n →
        (1 / (2 * π : ℂ)) * ∫ x in (-π)..π, f x * Complex.exp (-(n * x * I)) = 0) := by
  have hπ : (π : ℂ) ≠ 0 := ofReal_ne_zero.mpr pi_ne_zero
  constructor
  · intro n hn
    have hn0 : n ≠ 0 := by rintro rfl; simp at hn
    have hn0' : (n : ℂ) ≠ 0 := by exact_mod_cast hn0
    rw [fs_square_split f hpos hneg, fs_int_exp n hn0, fs_int_exp n hn0]
    have e1 : Complex.exp (-(n * ((π : ℝ) : ℂ) * I)) = -1 := by
      rw [fs_exp_neg, fs_exp_odd n hn]
    have e2 : Complex.exp (-(n * ((-π : ℝ) : ℂ) * I)) = -1 := by
      rw [show -((n : ℂ) * ((-π : ℝ) : ℂ) * I) = n * π * I by push_cast; ring, fs_exp_odd n hn]
    rw [e1, e2]
    simp only [ofReal_zero, mul_zero, zero_mul, neg_zero, Complex.exp_zero]
    field_simp
    ring_nf
  · intro n hn
    rcases eq_or_ne n 0 with rfl | hn0
    · rw [fs_square_split f hpos hneg]
      simp
    · rw [fs_square_split f hpos hneg, fs_int_exp n hn0, fs_int_exp n hn0]
      have e1 : Complex.exp (-(n * ((π : ℝ) : ℂ) * I)) = 1 := by
        rw [fs_exp_neg, fs_exp_even n hn]
      have e2 : Complex.exp (-(n * ((-π : ℝ) : ℂ) * I)) = 1 := by
        rw [show -((n : ℂ) * ((-π : ℝ) : ℂ) * I) = n * π * I by push_cast; ring, fs_exp_even n hn]
      rw [e1, e2]
      simp

-- The tones of a 220 Hz square wave: odd multiples 1, 3 and 5 of 220 give 220, 660 and 1100 Hz.
example : 1 * 220 = 220 ∧ 3 * 220 = 660 ∧ 5 * 220 = 1100 := by norm_num
-- The high half: 1 − (−1)^n is 2 for odd n and 0 for even n (here n = 3 and n = 4).
example : (1 : ℤ) - (-1) ^ 3 = 2 ∧ (1 : ℤ) - (-1) ^ 4 = 0 := by norm_num
-- Three tones at x = π/2: the bracket in (4/π)(1 − 1/3 + 1/5) is 13/15.
example : (1 : ℚ) - 1 / 3 + 1 / 5 = 13 / 15 := by norm_num
-- Parseval for the square wave, first three terms: 1 + 1/9 + 1/25 = 259/225.
example : (1 : ℚ) + 1 / 9 + 1 / 25 = 259 / 225 := by norm_num

#print axioms fourier_series_converges_in_mean_and_parseval
#print axioms fourier_coefficient_eq_average
#print axioms square_wave_fourier_coefficients
