-- Completeness of sines and cosines: no finite-energy signal on one cycle (−π, π) is perpendicular to every harmonic e_n(x) = e^(inx)/√(2π) except the zero signal, so every such signal's Fourier partial sums close the energy gap.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Order.Filter.AtTopBot.Interval

open MeasureTheory Complex Filter Topology Real

/-- The harmonic `e_n(x) = e^(inx) / √(2π)`, for every whole number `n`, negative ones included. -/
noncomputable def harmonic (n : ℤ) (x : ℝ) : ℂ :=
  Complex.exp (n * x * Complex.I) / (Real.sqrt (2 * π) : ℂ)

/-- The amount of harmonic `n` in `f`: the inner product `⟨e_n, f⟩ = ∫_{-π}^{π} conj(e_n x) f x dx`,
conjugating the first slot. -/
noncomputable def amount (f : ℝ → ℂ) (n : ℤ) : ℂ :=
  ∫ x in (-π)..π, (starRingEnd ℂ) (harmonic n x) * f x

/-- The partial sum `S_N f = ∑_{n=-N}^{N} ⟨e_n, f⟩ e_n`. -/
noncomputable def partialSum (f : ℝ → ℂ) (N : ℕ) (x : ℝ) : ℂ :=
  ∑ n ∈ Finset.Icc (-(N : ℤ)) N, amount f n * harmonic n x

lemma amount_eq_sqrt_mul_fourierCoeffOn (f : ℝ → ℂ) (n : ℤ) :
    amount f n = (Real.sqrt (2 * π) : ℂ) * fourierCoeffOn (neg_lt_self Real.pi_pos) f n := by
  rw [fourierCoeffOn_eq_integral]
  have hs : (Real.sqrt (2 * π) : ℂ) ≠ 0 := by
    exact_mod_cast (Real.sqrt_pos.2 (by positivity)).ne'
  have hss : (Real.sqrt (2 * π) : ℂ) * (Real.sqrt (2 * π) : ℂ) = 2 * π := by
    rw [← Complex.ofReal_mul, Real.mul_self_sqrt (by positivity)]; push_cast; ring
  have h1 : ∀ x : ℝ, (starRingEnd ℂ) (harmonic n x) * f x
      = (Real.sqrt (2 * π) : ℂ)⁻¹ * (fourier (-n) (x : AddCircle (π - -π)) • f x) := by
    intro x
    rw [fourier_coe_apply, harmonic, map_div₀, ← Complex.exp_conj, Complex.conj_ofReal, smul_eq_mul]
    have : (starRingEnd ℂ) (↑n * ↑x * I) = 2 * ↑π * I * ↑(-n) * ↑x / ↑(π - -π) := by
      simp only [map_mul, map_intCast, Complex.conj_ofReal, Complex.conj_I]
      push_cast
      field_simp
      ring
    rw [this]; ring
  simp_rw [amount, h1]
  rw [intervalIntegral.integral_const_mul, Complex.real_smul, ← mul_assoc]
  congr 1
  push_cast
  field_simp
  rw [sq, hss]; ring

#print axioms amount_eq_sqrt_mul_fourierCoeffOn

lemma parseval_aux (f : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) :
    HasSum (fun n : ℤ => ‖amount f n‖ ^ 2) (∫ x in (-π)..π, ‖f x‖ ^ 2) := by
  have h := (hasSum_sq_fourierCoeffOn (neg_lt_self Real.pi_pos) hf).mul_left (2 * π)
  have hsq : ‖(Real.sqrt (2 * π) : ℂ)‖ ^ 2 = 2 * π := by
    rw [Complex.norm_real, Real.norm_eq_abs, sq_abs, Real.sq_sqrt (by positivity)]
  convert h using 1
  · funext n
    rw [amount_eq_sqrt_mul_fourierCoeffOn, norm_mul, mul_pow, hsq]
  · rw [smul_eq_mul, ← mul_assoc, show π - -π = 2 * π by ring,
      mul_inv_cancel₀ (by positivity), one_mul]

#print axioms parseval_aux

lemma integrableOn_norm_sq (f : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) :
    Integrable (fun x => ‖f x‖ ^ 2) (volume.restrict (Set.Ioc (-π) π)) := by
  have hf' : MemLp f ((2 : ℕ) : ENNReal) (volume.restrict (Set.Ioc (-π) π)) := by
    simpa using hf
  exact hf'.integrable_norm_pow (by norm_num)

#print axioms integrableOn_norm_sq

lemma continuous_harmonic (n : ℤ) : Continuous (harmonic n) := by
  unfold harmonic; fun_prop

#print axioms continuous_harmonic

lemma conj_harmonic_mul_harmonic (n m : ℤ) (x : ℝ) :
    (starRingEnd ℂ) (harmonic n x) * harmonic m x
      = Complex.exp (((m - n : ℤ) : ℂ) * x * Complex.I) / (2 * π) := by
  have hss : (Real.sqrt (2 * π) : ℂ) * (Real.sqrt (2 * π) : ℂ) = 2 * π := by
    rw [← Complex.ofReal_mul, Real.mul_self_sqrt (by positivity)]; push_cast; ring
  rw [harmonic, harmonic, map_div₀, ← Complex.exp_conj, Complex.conj_ofReal, div_mul_div_comm,
    ← Complex.exp_add, hss]
  congr 2
  simp only [map_mul, map_intCast, Complex.conj_ofReal, Complex.conj_I]
  push_cast; ring

#print axioms conj_harmonic_mul_harmonic

lemma amount_harmonic (m n : ℤ) : amount (harmonic m) n = if n = m then 1 else 0 := by
  unfold amount
  simp_rw [conj_harmonic_mul_harmonic]
  rw [intervalIntegral.integral_div]
  split_ifs with h
  · subst h
    simp
    field_simp
    ring
  · have hk : (((m - n : ℤ) : ℂ) * Complex.I) ≠ 0 := by
      refine mul_ne_zero ?_ Complex.I_ne_zero
      exact_mod_cast sub_ne_zero.2 (Ne.symm h)
    have : ∀ x : ℝ, Complex.exp (((m - n : ℤ) : ℂ) * x * Complex.I)
        = Complex.exp ((((m - n : ℤ) : ℂ) * Complex.I) * x) := fun x => by ring_nf
    simp_rw [this]
    rw [integral_exp_mul_complex hk]
    have e1 : Complex.exp ((((m - n : ℤ) : ℂ) * Complex.I) * (π : ℝ))
        = Complex.exp ((((m - n : ℤ) : ℂ) * Complex.I) * ((-π : ℝ) : ℂ)) := by
      rw [Complex.exp_eq_exp_iff_exists_int]
      refine ⟨m - n, ?_⟩
      push_cast; ring
    rw [e1, sub_self, zero_div, zero_div]

#print axioms amount_harmonic

lemma memLp_of_continuous (g : ℝ → ℂ) (hg : Continuous g) :
    MemLp g 2 (volume.restrict (Set.Ioc (-π) π)) := by
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := -π) (b := π)).exists_bound_of_continuousOn
    hg.continuousOn
  refine MemLp.of_bound hg.aestronglyMeasurable C ?_
  refine ae_restrict_of_forall_mem measurableSet_Ioc fun x hx => hC x ?_
  exact Set.Ioc_subset_Icc_self hx

#print axioms memLp_of_continuous

lemma intervalIntegrable_conj_mul (f : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) (n : ℤ) :
    IntervalIntegrable (fun x => (starRingEnd ℂ) (harmonic n x) * f x) volume (-π) π := by
  have hfi : IntervalIntegrable f volume (-π) π := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le (neg_le_self Real.pi_pos.le)]
    exact hf.integrable one_le_two
  exact hfi.continuousOn_mul (by
    have := continuous_harmonic n
    fun_prop)

#print axioms intervalIntegrable_conj_mul

lemma amount_sub (f g : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π)))
    (hg : MemLp g 2 (volume.restrict (Set.Ioc (-π) π))) (n : ℤ) :
    amount (fun x => f x - g x) n = amount f n - amount g n := by
  unfold amount
  rw [← intervalIntegral.integral_sub (intervalIntegrable_conj_mul f hf n)
    (intervalIntegrable_conj_mul g hg n)]
  congr 1
  funext x
  ring

#print axioms amount_sub

lemma continuous_partialSum (f : ℝ → ℂ) (N : ℕ) : Continuous (partialSum f N) := by
  unfold partialSum
  have := continuous_harmonic
  fun_prop

#print axioms continuous_partialSum

lemma amount_partialSum (f : ℝ → ℂ) (N : ℕ) (n : ℤ) :
    amount (partialSum f N) n
      = if n ∈ Finset.Icc (-(N : ℤ)) N then amount f n else 0 := by
  have h : amount (partialSum f N) n
      = ∑ m ∈ Finset.Icc (-(N : ℤ)) N, amount f m * amount (harmonic m) n := by
    unfold amount partialSum
    simp_rw [Finset.mul_sum]
    rw [intervalIntegral.integral_finsetSum]
    · refine Finset.sum_congr rfl fun m _ => ?_
      rw [← intervalIntegral.integral_const_mul]
      congr 1; funext x; unfold amount; ring
    · intro m _
      apply Continuous.intervalIntegrable
      have := continuous_harmonic m
      have := continuous_harmonic n
      fun_prop
  rw [h]
  simp_rw [amount_harmonic, mul_ite, mul_one, mul_zero]
  rw [Finset.sum_ite_eq]

#print axioms amount_partialSum

/-- Completeness of the trigonometric system: a finite-energy signal on one cycle `(−π, π)`
that is perpendicular to every harmonic `e_n`, `n ∈ ℤ`, is the zero signal, that is, zero
except on a set of total length zero. -/
theorem perpendicular_to_every_harmonic_is_zero (f : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π)))
    (hperp : ∀ n : ℤ, amount f n = 0) :
    f =ᵐ[volume.restrict (Set.Ioc (-π) π)] 0 := by
  have h := parseval_aux f hf
  simp only [hperp, norm_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow] at h
  have h0 : (∫ x in (-π)..π, ‖f x‖ ^ 2) = 0 := h.unique hasSum_zero
  rw [intervalIntegral.integral_of_le (neg_le_self Real.pi_pos.le)] at h0
  have h1 := (integral_eq_zero_iff_of_nonneg (fun x => by positivity)
    (integrableOn_norm_sq f hf)).1 h0
  filter_upwards [h1] with x hx
  simpa using hx

/-- Convergence in energy: for every finite-energy signal `f` on one cycle, the energy of the
gap between `f` and its partial sum, `‖f − S_N f‖₂² = ∫_{-π}^{π} |f x − S_N f x|² dx`,
falls to zero as `N → ∞`. -/
theorem energy_gap_tendsto_zero (f : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) :
    Tendsto (fun N : ℕ => ∫ x in (-π)..π, ‖f x - partialSum f N x‖ ^ 2) atTop (𝓝 0) := by
  have hT := parseval_aux f hf
  have key : ∀ N : ℕ, (∫ x in (-π)..π, ‖f x - partialSum f N x‖ ^ 2)
      = (∫ x in (-π)..π, ‖f x‖ ^ 2)
        - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, ‖amount f n‖ ^ 2 := by
    intro N
    set s := Finset.Icc (-(N : ℤ)) N
    have hP := memLp_of_continuous _ (continuous_partialSum f N)
    have hg := parseval_aux (fun x => f x - partialSum f N x) (hf.sub hP)
    have hS : HasSum (fun n : ℤ => if n ∈ s then ‖amount f n‖ ^ 2 else 0)
        (∑ n ∈ s, ‖amount f n‖ ^ 2) := by
      have := hasSum_sum_of_ne_finset_zero (s := s)
        (f := fun n : ℤ => if n ∈ s then ‖amount f n‖ ^ 2 else 0)
        (L := SummationFilter.unconditional ℤ) (fun n hn => by simp [hn])
      rwa [Finset.sum_congr rfl fun n (hn : n ∈ s) =>
        (show (if n ∈ s then ‖amount f n‖ ^ 2 else 0) = ‖amount f n‖ ^ 2 by simp [hn])] at this
    have hD := hT.sub hS
    refine hg.unique ?_
    convert hD using 1
    funext n
    rw [amount_sub f _ hf hP, amount_partialSum]
    split_ifs <;> simp
  simp_rw [key]
  have hlim : Tendsto (fun N : ℕ => ∑ n ∈ Finset.Icc (-(N : ℤ)) N, ‖amount f n‖ ^ 2) atTop
      (𝓝 (∫ x in (-π)..π, ‖f x‖ ^ 2)) :=
    (hT : Tendsto _ atTop _).comp Finset.tendsto_Icc_neg
  have := (tendsto_const_nhds (x := ∫ x in (-π)..π, ‖f x‖ ^ 2)).sub hlim
  rwa [sub_self] at this

/-- Parseval's identity for every finite-energy signal on one cycle: its energy
`‖f‖₂² = ∫_{-π}^{π} |f x|² dx` is the sum over all whole numbers `n` of the energies
`|⟨e_n, f⟩|²` of its harmonics. -/
theorem parseval_for_every_finite_energy_signal (f : ℝ → ℂ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) :
    HasSum (fun n : ℤ => ‖amount f n‖ ^ 2) (∫ x in (-π)..π, ‖f x‖ ^ 2) := by
  exact parseval_aux f hf

/-- The 44.1 kHz copy of the 500 Hz siren keeps the odd harmonics up to number 43:
harmonic 43 sits at 21,500 Hz, within 22,050 Hz, and harmonic 45, at 22,500 Hz, does not. -/
example : 500 * 43 = 21500 ∧ 500 * 43 ≤ 44100 / 2 ∧ 44100 / 2 < 500 * 45 := by norm_num

/-- A 48 kHz copy keeps the odd harmonics up to number 47, at 23,500 Hz. -/
example : 500 * 47 = 23500 ∧ 500 * 47 ≤ 48000 / 2 ∧ 48000 / 2 < 500 * 49 := by norm_num

#print axioms perpendicular_to_every_harmonic_is_zero
#print axioms energy_gap_tendsto_zero
#print axioms parseval_for_every_finite_energy_signal
