-- Spectral estimation: averaging K segment periodograms with neighbour correlation ρ gives variance (S²/K)(1 + 2ρ(1 − 1/K)), the periodogram is the transform of the sample autocovariance, and a white-noise periodogram value has an exponential tail.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Complex.Circle

open MeasureTheory ProbabilityTheory Finset
open scoped NNReal

/-- The sample autocovariance of a record `x[0], …, x[N-1]` at lag `h`:
`c(h) = (1/N) · Σ_{n=0}^{N-1-h} x[n] · x[n+h]`. -/
noncomputable def sampleAutocov (x : ℕ → ℝ) (N h : ℕ) : ℝ :=
  (1 / (N : ℝ)) * ∑ n ∈ range (N - h), x n * x (n + h)

lemma count_next (K : ℕ) :
    ∑ i ∈ range K, ∑ j ∈ range K, (if i + 1 = j then (1 : ℝ) else 0) = ((K - 1 : ℕ) : ℝ) := by
  simp_rw [Finset.sum_ite_eq]
  rw [Finset.sum_boole]
  congr 1
  have : Finset.filter (fun i => i + 1 ∈ range K) (range K) = range (K - 1) := by
    ext i; simp; omega
  rw [this, card_range]

lemma lag_fiber_sum {R : Type*} [CommRing R] (y : ℕ → R) (N : ℕ) (h : ℤ) :
    ∑ p ∈ (range N ×ˢ range N).filter (fun p : ℕ × ℕ => (p.1 : ℤ) - p.2 = h), y p.1 * y p.2 =
      ∑ k ∈ range (N - h.natAbs), y k * y (k + h.natAbs) := by
  refine Finset.sum_nbij' (fun p => min p.1 p.2)
    (fun k => if 0 ≤ h then (k + h.natAbs, k) else (k, k + h.natAbs)) ?_ ?_ ?_ ?_ ?_
  · intro p hp
    simp only [mem_filter, mem_product, mem_range, ] at hp ⊢
    omega
  · intro k hk
    simp only [mem_range] at hk
    split_ifs <;> simp only [mem_filter, mem_product, mem_range] <;> omega
  · intro p hp
    simp only [mem_filter, mem_product, mem_range, ] at hp
    split_ifs <;> ext <;> simp <;> omega
  · intro k hk
    split_ifs <;> simp
  · intro p hp
    simp only [mem_filter, mem_product, mem_range, ] at hp
    rcases le_total p.1 p.2 with h1 | h1
    · have e1 : min p.1 p.2 = p.1 := min_eq_left h1
      have e2 : p.1 + h.natAbs = p.2 := by omega
      rw [e1, e2]
    · have e1 : min p.1 p.2 = p.2 := min_eq_right h1
      have e2 : p.2 + h.natAbs = p.1 := by omega
      rw [e1, e2, mul_comm]

lemma lag_double_sum {R : Type*} [CommRing R] (y : ℕ → R) (e : ℤ → R) (N : ℕ) :
    ∑ n ∈ range N, ∑ m ∈ range N, y n * y m * e ((n : ℤ) - m) =
      ∑ h ∈ Ioo (-(N : ℤ)) N, (∑ k ∈ range (N - h.natAbs), y k * y (k + h.natAbs)) * e h := by
  rw [← Finset.sum_product' (f := fun n m => y n * y m * e ((n : ℤ) - m))]
  rw [← Finset.sum_fiberwise_of_maps_to (g := fun p : ℕ × ℕ => (p.1 : ℤ) - p.2)
    (t := Ioo (-(N : ℤ)) N)]
  · refine Finset.sum_congr rfl (fun h _ => ?_)
    rw [← lag_fiber_sum, Finset.sum_mul]
    refine Finset.sum_congr rfl (fun p hp => ?_)
    rw [(mem_filter.mp hp).2]
  · intro p hp
    simp only [mem_product, mem_range] at hp
    simp only [mem_Ioo]
    omega

lemma aemeasurable_of_map_eq_gaussianReal {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {C : Ω → ℝ} {s2 : ℝ≥0} (hs2 : s2 ≠ 0)
    (hC : μ.map C = gaussianReal 0 s2) : AEMeasurable C μ := by
  by_contra h
  have h0 := Measure.map_of_not_aemeasurable_of_ne_zero h (IsProbabilityMeasure.ne_zero μ)
  rw [hC] at h0
  have h1 := congrArg (fun m : Measure ℝ => m {Classical.ofNonempty}) h0
  have := nullSingletonClass_gaussianReal (μ := 0) hs2
  simp only [measure_singleton, Measure.dirac_apply_of_mem (Set.mem_singleton _)] at h1
  exact zero_ne_one h1

/-- The radial tail integral `∫_{√t}^∞ r e^{-r²/(2v)} dr = v e^{-t/(2v)}`. -/
lemma radial_tail_integral (v t : ℝ) (hv : 0 < v) (ht : 0 ≤ t) :
    ∫⁻ r in Set.Ioi (Real.sqrt t), ENNReal.ofReal (r * Real.exp (-r ^ 2 / (2 * v))) =
      ENNReal.ofReal (v * Real.exp (-t / (2 * v))) := by
  set G : ℝ → ℝ := fun r => -v * Real.exp (-r ^ 2 / (2 * v)) with hG
  have hderiv : ∀ x ∈ Set.Ici (Real.sqrt t),
      HasDerivAt G (x * Real.exp (-x ^ 2 / (2 * v))) x := by
    intro x _
    have h1 : HasDerivAt (fun r : ℝ => -r ^ 2 / (2 * v)) (-(2 * x) / (2 * v)) x := by
      have := ((hasDerivAt_pow 2 x).neg).div_const (2 * v)
      convert this using 1
      push_cast; ring
    have h2 := (h1.exp).const_mul (-v)
    convert h2 using 1
    field_simp
  have hpos : ∀ x ∈ Set.Ioi (Real.sqrt t), 0 ≤ x * Real.exp (-x ^ 2 / (2 * v)) := by
    intro x hx
    have : 0 ≤ x := le_trans (Real.sqrt_nonneg t) (le_of_lt hx)
    positivity
  have hlim : Filter.Tendsto G Filter.atTop (nhds 0) := by
    have h1 : Filter.Tendsto (fun r : ℝ => -r ^ 2 / (2 * v)) Filter.atTop Filter.atBot := by
      have := (Filter.tendsto_neg_atTop_atBot.comp (Filter.tendsto_pow_atTop (α := ℝ) two_ne_zero))
      exact this.atBot_div_const (by positivity)
    have h2 := (Real.tendsto_exp_atBot.comp h1).const_mul (-v)
    rw [hG]; simpa using h2
  have hint := integrableOn_Ioi_deriv_of_nonneg' hderiv hpos hlim
  have hval := integral_Ioi_of_hasDerivAt_of_nonneg' hderiv hpos hlim
  rw [← ofReal_integral_eq_lintegral_ofReal hint
    ((ae_restrict_iff' measurableSet_Ioi).mpr (Filter.Eventually.of_forall hpos)), hval]
  congr 1
  simp only [hG, Real.sq_sqrt ht]
  ring

#print axioms count_next
#print axioms lag_fiber_sum
#print axioms lag_double_sum
#print axioms aemeasurable_of_map_eq_gaussianReal
#print axioms radial_tail_integral

/-- Welch's variance formula (Step 3). Average the periodograms `P 0, …, P (K-1)` of `K`
segments at one frequency. If each has variance `S²`, neighbouring segments are correlated
by `ρ` (covariance `ρ S²`), and segments two or more apart are uncorrelated, then the
average has variance `(S²/K) · (1 + 2ρ(1 − 1/K))`: averaging cuts the variance by `K`,
slightly less because half-overlapped neighbours share samples. -/
theorem welch_variance_of_average {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (K : ℕ) (P : ℕ → Ω → ℝ) (S ρ : ℝ)
    (hP : ∀ i < K, MemLp (P i) 2 μ)
    (hvar : ∀ i < K, Var[P i; μ] = S ^ 2)
    (hnext : ∀ i, i + 1 < K → cov[P i, P (i + 1); μ] = ρ * S ^ 2)
    (hfar : ∀ i j, j < K → i + 2 ≤ j → cov[P i, P j; μ] = 0) :
    Var[fun ω ↦ (∑ i ∈ range K, P i ω) / K; μ] = S ^ 2 / K * (1 + 2 * ρ * (1 - 1 / K)) := by
  have h1 : (fun ω ↦ (∑ i ∈ range K, P i ω) / K) = fun ω ↦ (1 / (K : ℝ)) * ∑ i ∈ range K, P i ω := by
    funext ω; ring
  rw [h1, variance_const_mul, variance_fun_sum' (fun i hi => hP i (mem_range.mp hi))]
  have hc : ∀ i ∈ range K, ∀ j ∈ range K, cov[P i, P j; μ] =
      S ^ 2 * (if i = j then 1 else 0) + ρ * S ^ 2 * (if i + 1 = j then 1 else 0)
        + ρ * S ^ 2 * (if j + 1 = i then 1 else 0) := by
    intro i hi j hj
    rw [mem_range] at hi hj
    obtain h | h | h | h | h : i = j ∨ i + 1 = j ∨ j + 1 = i ∨ i + 2 ≤ j ∨ j + 2 ≤ i := by omega
    · subst h
      rw [covariance_self (hP i hi).aemeasurable, hvar i hi]; simp
    · subst h
      rw [hnext i hj]; simp; intro h; omega
    · subst h
      rw [covariance_comm, hnext j hi]; simp; intro h; omega
    · rw [hfar i j hj h]
      simp only [show ¬ i = j by omega, show ¬ i + 1 = j by omega, show ¬ j + 1 = i by omega,
        ite_false]; ring
    · rw [covariance_comm, hfar j i hi h]
      simp only [show ¬ i = j by omega, show ¬ i + 1 = j by omega, show ¬ j + 1 = i by omega,
        ite_false]; ring
  rw [Finset.sum_congr rfl (fun i hi => Finset.sum_congr rfl (fun j hj => hc i hi j hj))]
  simp only [Finset.sum_add_distrib, ← Finset.mul_sum]
  have e1 : ∑ i ∈ range K, ∑ j ∈ range K, (if i = j then (1 : ℝ) else 0) = K := by
    rw [Finset.sum_congr rfl (g := fun _ => (1 : ℝ)) (fun i hi => by simp only [Finset.sum_ite_eq, hi, ite_true])]; simp
  have e2 := count_next K
  have e3 : ∑ i ∈ range K, ∑ j ∈ range K, (if j + 1 = i then (1 : ℝ) else 0) = ((K - 1 : ℕ) : ℝ) := by
    rw [Finset.sum_comm]; exact count_next K
  rw [e1, e2, e3]
  rcases Nat.eq_zero_or_pos K with hK | hK
  · subst hK; simp
  · have hK' : (K : ℝ) ≠ 0 := by positivity
    rw [Nat.cast_sub (by omega)]
    field_simp
    ring

/-- The periodogram is the transform of the sample autocovariance (Step 1). For any record
`x[0], …, x[N-1]` sampled `f_s` times a second and any frequency `f`, the plain periodogram
`(2/(f_s N)) |Σ_n x[n] e^{-j2πfn/f_s}|²` equals `(2/f_s) Σ_{h=-(N-1)}^{N-1} c(h) e^{-j2πfh/f_s}`,
with `c(-h) = c(h)` the sample autocovariance. -/
theorem plain_periodogram_eq_transform_of_sample_autocov (x : ℕ → ℝ) (N : ℕ) (fs f : ℝ) :
    ((2 / (fs * N) *
        ‖∑ n ∈ range N, (x n : ℂ) * Complex.exp (-((2 * Real.pi * f * n / fs : ℝ) : ℂ) * Complex.I)‖ ^ 2
        : ℝ) : ℂ) =
      ((2 / fs : ℝ) : ℂ) * ∑ h ∈ Ioo (-(N : ℤ)) N,
        (sampleAutocov x N h.natAbs : ℂ) *
          Complex.exp (-((2 * Real.pi * f * h / fs : ℝ) : ℂ) * Complex.I) := by
  set z := ∑ n ∈ range N, (x n : ℂ) * Complex.exp (-((2 * Real.pi * f * n / fs : ℝ) : ℂ) * Complex.I)
    with hz
  have hconj : (starRingEnd ℂ) z =
      ∑ m ∈ range N, (x m : ℂ) * Complex.exp (((2 * Real.pi * f * m / fs : ℝ) : ℂ) * Complex.I) := by
    rw [hz, map_sum]
    refine Finset.sum_congr rfl (fun m _ => ?_)
    simp only [map_mul, map_neg, Complex.conj_ofReal, Complex.conj_I, ← Complex.exp_conj]
    ring_nf
  have hsq : ((‖z‖ ^ 2 : ℝ) : ℂ) =
      ∑ n ∈ range N, ∑ m ∈ range N, (x n : ℂ) * (x m : ℂ) *
        Complex.exp (-((2 * Real.pi * f * (((n : ℤ) - m : ℤ) : ℝ) / fs : ℝ) : ℂ) * Complex.I) := by
    rw [Complex.ofReal_pow, ← Complex.mul_conj', hconj, hz, Finset.sum_mul_sum]
    refine Finset.sum_congr rfl (fun n _ => Finset.sum_congr rfl (fun m _ => ?_))
    rw [show ∀ a b c d : ℂ, a * b * (c * d) = a * c * (b * d) by intros; ring,
      ← Complex.exp_add]
    congr 2
    push_cast
    ring
  rw [Complex.ofReal_mul, hsq,
    lag_double_sum (fun n => (x n : ℂ))
      (fun h : ℤ => Complex.exp (-((2 * Real.pi * f * (h : ℝ) / fs : ℝ) : ℂ) * Complex.I)) N]
  unfold sampleAutocov
  rw [Finset.mul_sum, Finset.mul_sum]
  refine Finset.sum_congr rfl (fun h _ => ?_)
  push_cast
  ring

/-- A white-noise periodogram value is an exponential random draw (Step 2). If the real and
imaginary parts `C`, `D` of a DFT value are independent normal variables with mean 0 and the
same variance `s² > 0`, then the chance that `C² + D²` exceeds `t ≥ 0` is `e^{-t/(2s²)}`:
an exponential law with mean `2s²`, so its standard deviation equals its mean. -/
theorem periodogram_value_exponential_tail {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (C D : Ω → ℝ) (s2 : ℝ≥0) (hs2 : s2 ≠ 0)
    (hC : μ.map C = gaussianReal 0 s2) (hD : μ.map D = gaussianReal 0 s2)
    (hCD : IndepFun C D μ) (t : ℝ) (ht : 0 ≤ t) :
    μ {ω | t < C ω ^ 2 + D ω ^ 2} = ENNReal.ofReal (Real.exp (-t / (2 * s2))) := by
  have hCm := aemeasurable_of_map_eq_gaussianReal hs2 hC
  have hDm := aemeasurable_of_map_eq_gaussianReal hs2 hD
  have hmap : μ.map (fun ω => (C ω, D ω)) = (gaussianReal 0 s2).prod (gaussianReal 0 s2) := by
    rw [(indepFun_iff_map_prod_eq_prod_map_map hCm hDm).mp hCD, hC, hD]
  set A : Set (ℝ × ℝ) := {p | t < p.1 ^ 2 + p.2 ^ 2} with hA
  have hAm : MeasurableSet A := measurableSet_lt measurable_const (by fun_prop)
  have h1 : μ {ω | t < C ω ^ 2 + D ω ^ 2} = μ.map (fun ω => (C ω, D ω)) A := by
    rw [Measure.map_apply_of_aemeasurable (hCm.prodMk hDm) hAm]; rfl
  have hv : (0 : ℝ) < s2 := by
    have := pos_iff_ne_zero.mpr hs2
    exact_mod_cast this
  set K : ℝ := (Real.sqrt (2 * Real.pi * s2))⁻¹ ^ 2 with hK
  rw [h1, hmap, gaussianReal_of_var_ne_zero _ hs2,
    prod_withDensity (measurable_gaussianPDF _ _) (measurable_gaussianPDF _ _),
    withDensity_apply _ hAm, ← lintegral_indicator hAm, ← Measure.volume_eq_prod,
    ← lintegral_comp_polarCoord_symm]
  have hpt : ∀ p ∈ polarCoord.target,
      ENNReal.ofReal p.1 • A.indicator
        (fun z : ℝ × ℝ => gaussianPDF 0 s2 z.1 * gaussianPDF 0 s2 z.2) (polarCoord.symm p) =
      (Set.Ioi (Real.sqrt t)).indicator
        (fun r => ENNReal.ofReal K * ENNReal.ofReal (r * Real.exp (-r ^ 2 / (2 * s2)))) p.1 := by
    rintro ⟨r, θ⟩ hp
    simp only [polarCoord_target, Set.mem_prod, Set.mem_Ioi, Set.mem_Ioo] at hp
    have hr := hp.1
    have hsq : (r * Real.cos θ) ^ 2 + (r * Real.sin θ) ^ 2 = r ^ 2 := by
      rw [mul_pow, mul_pow, ← mul_add, Real.cos_sq_add_sin_sq, mul_one]
    have hiff : t < r ^ 2 ↔ Real.sqrt t < r := (Real.sqrt_lt' hr).symm
    simp only [polarCoord_symm_apply, smul_eq_mul]
    by_cases hin : Real.sqrt t < r
    · rw [Set.indicator_of_mem (show (r * Real.cos θ, r * Real.sin θ) ∈ A by
          simp only [hA, Set.mem_ofPred_eq, hsq]; exact hiff.mpr hin),
        Set.indicator_of_mem (show r ∈ Set.Ioi (Real.sqrt t) from hin)]
      simp only [gaussianPDF, gaussianPDFReal]
      rw [← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul hr.le,
        ← ENNReal.ofReal_mul (by positivity)]
      congr 1
      rw [hK]
      have he : Real.exp (-(r * Real.cos θ - 0) ^ 2 / (2 * s2)) *
          Real.exp (-(r * Real.sin θ - 0) ^ 2 / (2 * s2)) = Real.exp (-r ^ 2 / (2 * s2)) := by
        rw [← Real.exp_add, ← hsq]; congr 1; ring
      linear_combination (r * (Real.sqrt (2 * Real.pi * s2))⁻¹ ^ 2) * he
    · rw [Set.indicator_of_notMem (show (r * Real.cos θ, r * Real.sin θ) ∉ A by
          simp only [hA, Set.mem_ofPred_eq, hsq]; exact fun h => hin (hiff.mp h)),
        Set.indicator_of_notMem (show r ∉ Set.Ioi (Real.sqrt t) from hin)]
      simp
  rw [setLIntegral_congr_fun polarCoord.open_target.measurableSet hpt]
  rw [polarCoord_target, Measure.volume_eq_prod, ← Measure.prod_restrict,
    lintegral_prod _ (by
      refine (Measurable.indicator ?_ measurableSet_Ioi).comp measurable_fst |>.aemeasurable
      fun_prop)]
  simp only [lintegral_const, Measure.restrict_apply MeasurableSet.univ, Set.univ_inter,
    Real.volume_Ioo]
  rw [lintegral_mul_const' _ _ ENNReal.ofReal_ne_top, lintegral_indicator measurableSet_Ioi,
    Measure.restrict_restrict measurableSet_Ioi,
    Set.inter_eq_left.mpr (Set.Ioi_subset_Ioi (Real.sqrt_nonneg t)),
    lintegral_const_mul' _ _ ENNReal.ofReal_ne_top, radial_tail_integral s2 t hv ht,
    ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity)]
  congr 1
  rw [hK, inv_pow, Real.sq_sqrt (by positivity)]
  field_simp
  ring

-- 1200 rpm is 20 revolutions a second: the drum line sits at 20 Hz.
example : (1200 : ℕ) / 60 = 20 := by decide

-- Half-overlapped segments of L = 512 in a record of N = 8192: K = (8192 − 512)/(512/2) + 1 = 31.
example : (8192 - 512) / (512 / 2) + 1 = 31 := by decide

-- The grid is 16 times coarser, and half overlap nearly doubles K: 31 = 2 · 16 − 1.
example : 8192 / 512 = 16 ∧ (8192 - 512) / (512 / 2) + 1 = 2 * (8192 / 512) - 1 := by decide

-- The Hann overlap correlation at L = 512: ρ = (32/192)² = 1/36.
example : ((32 : ℚ) / 192) ^ 2 = 1 / 36 := by norm_num

-- Welch's squared scatter at K = 31: (1 + 2 · (1/36) · (1 − 1/31)) / 31 = 98/2883.
example : (1 + 2 * (1 / 36 : ℚ) * (1 - 1 / 31)) / 31 = 98 / 2883 := by norm_num

#print axioms welch_variance_of_average
#print axioms plain_periodogram_eq_transform_of_sample_autocov
#print axioms periodogram_value_exponential_tail
