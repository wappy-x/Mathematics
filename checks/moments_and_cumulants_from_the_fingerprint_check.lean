-- Moments and cumulants: the cumulants read off the log-fingerprint at zero add over independent pieces, shift and scale by fixed rules, and the first four are the mean, the variance, the third central moment and the fourth central moment less three times the variance squared.
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.TaylorExpansion
import Mathlib.Probability.Independence.CharacteristicFunction
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv

open MeasureTheory ProbabilityTheory Complex

variable {Ω : Type*} {mΩ : MeasurableSpace Ω}

/-- The k-th cumulant of a real random variable `X` under the probability `P`: the k-th
derivative at `t = 0` of the log-fingerprint `t ↦ log φ_X(t)`, divided by `i ^ k`.
Here `φ_X = charFun (P.map X)` is the fingerprint `t ↦ E[e^{itX}]`. -/
noncomputable def cumulant (X : Ω → ℝ) (P : Measure Ω) (k : ℕ) : ℂ :=
  (I ^ k)⁻¹ * iteratedDeriv k (fun t : ℝ => Complex.log (charFun (P.map X) t)) 0

lemma cum_aux_ev_slit {φ : ℝ → ℂ} (hc : ContinuousAt φ 0) (h0 : φ 0 = 1) :
    ∀ᶠ t in nhds (0:ℝ), φ t ∈ slitPlane := by
  apply hc.eventually_mem
  rw [h0]; exact isOpen_slitPlane.mem_nhds one_mem_slitPlane

#print axioms cum_aux_ev_slit

lemma cum_aux_arg_ev {h : ℝ → ℂ} (hc : ContinuousAt h 0) (h0 : h 0 = 1) :
    ∀ᶠ t in nhds (0:ℝ), h t ≠ 0 ∧ arg (h t) ∈ Set.Ioo (-(Real.pi/2)) (Real.pi/2) := by
  have ha : ContinuousAt arg (h 0) := by rw [h0]; exact continuousAt_arg one_mem_slitPlane
  have hca : ContinuousAt (fun t => arg (h t)) 0 := ha.comp hc
  have h1 : ∀ᶠ t in nhds (0:ℝ), arg (h t) ∈ Set.Ioo (-(Real.pi/2)) (Real.pi/2) := by
    apply hca.eventually_mem
    simp only [h0, arg_one]
    exact Ioo_mem_nhds (by linarith [Real.pi_pos]) (by linarith [Real.pi_pos])
  filter_upwards [h1, cum_aux_ev_slit hc h0] with t ht1 ht2
  exact ⟨slitPlane_ne_zero ht2, ht1⟩

#print axioms cum_aux_arg_ev

lemma cum_aux_log_mul_ev {f g : ℝ → ℂ} (hf : ContinuousAt f 0) (hg : ContinuousAt g 0)
    (hf0 : f 0 = 1) (hg0 : g 0 = 1) :
    ∀ᶠ t in nhds (0:ℝ), log (f t * g t) = log (f t) + log (g t) := by
  filter_upwards [cum_aux_arg_ev hf hf0, cum_aux_arg_ev hg hg0] with t hft hgt
  apply log_mul hft.1 hgt.1
  constructor <;> linarith [hft.2.1, hft.2.2, hgt.2.1, hgt.2.2]

#print axioms cum_aux_log_mul_ev

lemma cum_aux_memLp_map {P : Measure Ω} {X : Ω → ℝ} {n : ℕ} (h : MemLp X n P) :
    MemLp id n (P.map X) :=
  (memLp_map_measure_iff aestronglyMeasurable_id h.aestronglyMeasurable.aemeasurable).2 h

#print axioms cum_aux_memLp_map

lemma cum_aux_contDiffAt_log {μ : Measure ℝ} [IsProbabilityMeasure μ] {n : ℕ}
    (h : MemLp id n μ) : ContDiffAt ℝ n (fun t => log (charFun μ t)) 0 := by
  have h1 : charFun μ 0 ∈ slitPlane := by simp
  exact ((contDiffAt_log h1).restrict_scalars ℝ).comp 0 (contDiff_charFun h).contDiffAt

#print axioms cum_aux_contDiffAt_log

lemma cum_aux_iteratedDeriv_comp_mul (f : ℝ → ℂ) (a : ℝ) (n : ℕ) :
    iteratedDeriv n (fun t => f (a * t)) = fun t => (a:ℂ) ^ n * iteratedDeriv n f (a * t) := by
  induction n generalizing f with
  | zero => simp
  | succ n ih =>
    rw [iteratedDeriv_succ']
    have : deriv (fun t => f (a * t)) = fun t => (a:ℂ) * deriv f (a * t) := by
      funext t; rw [deriv_comp_mul_left a f t]; simp [Complex.real_smul]
    rw [this]
    funext t
    rw [iteratedDeriv_const_mul_field, ih, iteratedDeriv_succ']; ring

#print axioms cum_aux_iteratedDeriv_comp_mul

lemma cum_aux_moment {P : Measure Ω} [IsProbabilityMeasure P] {Y : Ω → ℝ} {n : ℕ}
    (h : MemLp Y n P) :
    iteratedDeriv n (charFun (P.map Y)) 0 = I ^ n * ((∫ ω, Y ω ^ n ∂P : ℝ) : ℂ) := by
  rw [iteratedDeriv_charFun_zero (cum_aux_memLp_map h),
    integral_map h.aestronglyMeasurable.aemeasurable (by fun_prop)]

#print axioms cum_aux_moment

lemma cum_aux_charFun_affine {P : Measure Ω} {X : Ω → ℝ} (hX : AEMeasurable X P) (a c t : ℝ) :
    charFun (P.map (fun ω => a * X ω + c)) t
      = charFun (P.map X) (a * t) * cexp (((c * t : ℝ) : ℂ) * I) := by
  have h1 : (fun ω => a * X ω + c) = (fun x => x + c) ∘ (fun ω => a * X ω) := rfl
  rw [h1, ← AEMeasurable.map_map_of_aemeasurable (by fun_prop) (by fun_prop),
    charFun_map_add_const, charFun_map_mul_comp hX]
  simp [mul_comm]

#print axioms cum_aux_charFun_affine

lemma cum_aux_hasDerivAt_D1 {φ : ℝ → ℂ} {t : ℝ} (ht : φ t ≠ 0)
    (h0 : DifferentiableAt ℝ φ t) (h1 : DifferentiableAt ℝ (deriv φ) t) :
    HasDerivAt (fun s => deriv φ s / φ s)
      (deriv (deriv φ) t / φ t - (deriv φ t / φ t) ^ 2) t := by
  have := h1.hasDerivAt.div h0.hasDerivAt ht
  convert this using 1; field_simp

#print axioms cum_aux_hasDerivAt_D1

lemma cum_aux_hasDerivAt_D2 {φ : ℝ → ℂ} {t : ℝ} (ht : φ t ≠ 0)
    (h0 : DifferentiableAt ℝ φ t) (h1 : DifferentiableAt ℝ (deriv φ) t)
    (h2 : DifferentiableAt ℝ (deriv (deriv φ)) t) :
    HasDerivAt (fun s => deriv (deriv φ) s / φ s - (deriv φ s / φ s) ^ 2)
      (deriv (deriv (deriv φ)) t / φ t - 3 * (deriv φ t * deriv (deriv φ) t) / φ t ^ 2
        + 2 * (deriv φ t / φ t) ^ 3) t := by
  have := (h2.hasDerivAt.div h0.hasDerivAt ht).sub
    ((h1.hasDerivAt.div h0.hasDerivAt ht).pow 2)
  convert this using 1
  simp only [Pi.div_apply, Nat.cast_ofNat, show (2:ℕ) - 1 = 1 from rfl, pow_one]
  field_simp; ring

#print axioms cum_aux_hasDerivAt_D2

lemma cum_aux_hasDerivAt_D3 {φ : ℝ → ℂ} {t : ℝ} (ht : φ t ≠ 0)
    (h0 : DifferentiableAt ℝ φ t) (h1 : DifferentiableAt ℝ (deriv φ) t)
    (h2 : DifferentiableAt ℝ (deriv (deriv φ)) t)
    (h3 : DifferentiableAt ℝ (deriv (deriv (deriv φ))) t) :
    HasDerivAt (fun s => deriv (deriv (deriv φ)) s / φ s
        - 3 * (deriv φ s * deriv (deriv φ) s) / φ s ^ 2 + 2 * (deriv φ s / φ s) ^ 3)
      (deriv (deriv (deriv (deriv φ))) t / φ t
        - 4 * (deriv φ t * deriv (deriv (deriv φ)) t) / φ t ^ 2
        - 3 * deriv (deriv φ) t ^ 2 / φ t ^ 2
        + 12 * (deriv φ t ^ 2 * deriv (deriv φ) t) / φ t ^ 3
        - 6 * deriv φ t ^ 4 / φ t ^ 4) t := by
  have := ((h3.hasDerivAt.div h0.hasDerivAt ht).sub
    (((h1.hasDerivAt.mul h2.hasDerivAt).const_mul 3).div (h0.hasDerivAt.pow 2)
      (pow_ne_zero 2 ht))).add (((h1.hasDerivAt.div h0.hasDerivAt ht).pow 3).const_mul 2)
  convert this using 1
  simp only [Pi.div_apply, Pi.pow_apply, Pi.mul_apply, Nat.cast_ofNat,
    show (2:ℕ) - 1 = 1 from rfl, show (3:ℕ) - 1 = 2 from rfl, pow_one]
  field_simp; ring

#print axioms cum_aux_hasDerivAt_D3

/-- The log-fingerprint's derivatives at zero, for a centred fingerprint. -/
lemma cum_aux_log_derivs {φ : ℝ → ℂ} (n : ℕ) (hφ : ContDiff ℝ n φ) (hn : 2 ≤ n)
    (h0 : φ 0 = 1) (h1 : deriv φ 0 = 0) :
    iteratedDeriv 2 (fun t => log (φ t)) 0 = iteratedDeriv 2 φ 0 ∧
    (3 ≤ n → iteratedDeriv 3 (fun t => log (φ t)) 0 = iteratedDeriv 3 φ 0) ∧
    (4 ≤ n → iteratedDeriv 4 (fun t => log (φ t)) 0
      = iteratedDeriv 4 φ 0 - 3 * (iteratedDeriv 2 φ 0) ^ 2) := by
  have hd0 : Differentiable ℝ φ := by
    simpa using hφ.differentiable_iteratedDeriv 0 (by exact_mod_cast (by omega : 0 < n))
  have hd1 : Differentiable ℝ (deriv φ) := by
    simpa using hφ.differentiable_iteratedDeriv 1 (by exact_mod_cast (by omega : 1 < n))
  have hslit := cum_aux_ev_slit hd0.continuous.continuousAt h0
  have e1 : deriv (fun t => log (φ t)) =ᶠ[nhds 0] fun t => deriv φ t / φ t := by
    filter_upwards [hslit] with t ht
    exact ((hd0 t).hasDerivAt.clog_real ht).deriv
  have e2 : deriv (deriv (fun t => log (φ t))) =ᶠ[nhds 0]
      fun t => deriv (deriv φ) t / φ t - (deriv φ t / φ t) ^ 2 := by
    filter_upwards [e1.deriv, hslit] with t ht hs
    rw [ht]; exact (cum_aux_hasDerivAt_D1 (slitPlane_ne_zero hs) (hd0 t) (hd1 t)).deriv
  refine ⟨?_, fun h3 => ?_, fun h4 => ?_⟩
  · simp only [iteratedDeriv_succ, iteratedDeriv_zero]
    rw [e2.eq_of_nhds]; simp [h0, h1]
  · have hd2 : Differentiable ℝ (deriv (deriv φ)) := by
      have := hφ.differentiable_iteratedDeriv 2 (by exact_mod_cast (by omega : 2 < n))
      simpa [iteratedDeriv_succ] using this
    simp only [iteratedDeriv_succ, iteratedDeriv_zero]
    rw [e2.deriv_eq, (cum_aux_hasDerivAt_D2 (by simp [h0]) (hd0 0) (hd1 0) (hd2 0)).deriv]
    simp [h0, h1]
  · have hd2 : Differentiable ℝ (deriv (deriv φ)) := by
      have := hφ.differentiable_iteratedDeriv 2 (by exact_mod_cast (by omega : 2 < n))
      simpa [iteratedDeriv_succ] using this
    have hd3 : Differentiable ℝ (deriv (deriv (deriv φ))) := by
      have := hφ.differentiable_iteratedDeriv 3 (by exact_mod_cast (by omega : 3 < n))
      simpa [iteratedDeriv_succ] using this
    have e3 : deriv (deriv (deriv (fun t => log (φ t)))) =ᶠ[nhds 0]
        fun t => deriv (deriv (deriv φ)) t / φ t
          - 3 * (deriv φ t * deriv (deriv φ) t) / φ t ^ 2 + 2 * (deriv φ t / φ t) ^ 3 := by
      filter_upwards [e2.deriv, hslit] with t ht hs
      rw [ht]
      exact (cum_aux_hasDerivAt_D2 (slitPlane_ne_zero hs) (hd0 t) (hd1 t) (hd2 t)).deriv
    simp only [iteratedDeriv_succ, iteratedDeriv_zero]
    rw [e3.deriv_eq,
      (cum_aux_hasDerivAt_D3 (by simp [h0]) (hd0 0) (hd1 0) (hd2 0) (hd3 0)).deriv]
    simp [h0, h1]

#print axioms cum_aux_log_derivs

/-- Cumulants add over independent pieces: if `X` and `Y` are independent and both have a
finite k-th moment, the k-th cumulant of `X + Y` is the k-th cumulant of `X` plus the
k-th cumulant of `Y`. -/
theorem cumulant_add_of_indepFun (P : Measure Ω) [IsProbabilityMeasure P]
    (X Y : Ω → ℝ) (k : ℕ) (hXY : IndepFun X Y P)
    (hX : MemLp X k P) (hY : MemLp Y k P) :
    cumulant (fun ω => X ω + Y ω) P k = cumulant X P k + cumulant Y P k := by
  have mX := hX.aestronglyMeasurable.aemeasurable
  have mY := hY.aestronglyMeasurable.aemeasurable
  have hmul := hXY.charFun_map_fun_add_eq_mul mX mY
  have hev : (fun t : ℝ => log (charFun (P.map fun ω => X ω + Y ω) t)) =ᶠ[nhds 0]
      (fun t => log (charFun (P.map X) t)) + (fun t => log (charFun (P.map Y) t)) := by
    rw [hmul]
    exact cum_aux_log_mul_ev continuous_charFun.continuousAt continuous_charFun.continuousAt
      (by simp) (by simp)
  unfold cumulant
  rw [(hev.iteratedDeriv k).eq_of_nhds,
    iteratedDeriv_add (cum_aux_contDiffAt_log (cum_aux_memLp_map hX))
      (cum_aux_contDiffAt_log (cum_aux_memLp_map hY)), mul_add]

/-- Shifts and scales: for fixed numbers `a` (a scale) and `c` (a shift), the first cumulant
of `a X + c` is `a κ₁(X) + c`, and for `k ≥ 2` the k-th cumulant of `a X + c` is
`a ^ k κ_k(X)`, whenever the moment the cumulant needs is finite. -/
theorem cumulant_affine (P : Measure Ω) [IsProbabilityMeasure P] (X : Ω → ℝ) (a c : ℝ) :
    (MemLp X 1 P →
      cumulant (fun ω => a * X ω + c) P 1 = a * cumulant X P 1 + c) ∧
    (∀ k : ℕ, 2 ≤ k → MemLp X k P →
      cumulant (fun ω => a * X ω + c) P k = (a : ℂ) ^ k * cumulant X P k) := by
  -- the log-fingerprint of `a X + c` near zero
  have key : ∀ k : ℕ, MemLp X k P →
      iteratedDeriv k (fun t : ℝ => log (charFun (P.map fun ω => a * X ω + c) t)) 0
        = (a : ℂ) ^ k * iteratedDeriv k (fun t : ℝ => log (charFun (P.map X) t)) 0
          + iteratedDeriv k (fun t : ℝ => ((c * t : ℝ) : ℂ) * I) 0 := by
    intro k hX
    have mX := hX.aestronglyMeasurable.aemeasurable
    set ψ : ℝ → ℂ := fun t => log (charFun (P.map X) t) with hψ
    have hc1 : ContinuousAt (fun t : ℝ => charFun (P.map X) (a * t)) 0 :=
      (continuous_charFun.comp (continuous_const.mul continuous_id)).continuousAt
    have hc2 : ContinuousAt (fun t : ℝ => cexp (((c * t : ℝ) : ℂ) * I)) 0 := by
      fun_prop
    have hlogexp : ∀ᶠ t in nhds (0:ℝ), log (cexp (((c * t : ℝ) : ℂ) * I)) = ((c * t : ℝ) : ℂ) * I := by
      have hct : ContinuousAt (fun t : ℝ => c * t) 0 := by fun_prop
      have : ∀ᶠ t in nhds (0:ℝ), c * t ∈ Set.Ioo (-Real.pi) Real.pi := by
        apply hct.eventually_mem
        simp only [mul_zero]
        exact Ioo_mem_nhds (by linarith [Real.pi_pos]) Real.pi_pos
      filter_upwards [this] with t ht
      apply log_exp <;> simp [ht.1, ht.2.le]
    have hev : (fun t : ℝ => log (charFun (P.map fun ω => a * X ω + c) t)) =ᶠ[nhds 0]
        (fun t => ψ (a * t)) + (fun t : ℝ => ((c * t : ℝ) : ℂ) * I) := by
      filter_upwards [cum_aux_log_mul_ev hc1 hc2 (by simp) (by simp), hlogexp] with t h1 h2
      simp only [Pi.add_apply, hψ]
      rw [cum_aux_charFun_affine mX, h1, h2]
    have hF : ContDiffAt ℝ k (fun t => ψ (a * t)) 0 := by
      have h0 : ContDiffAt ℝ k ψ (a * 0) := by
        rw [mul_zero]; exact cum_aux_contDiffAt_log (cum_aux_memLp_map hX)
      exact h0.comp (f := fun t : ℝ => a * t) 0 (by fun_prop)
    have hL : ContDiffAt ℝ k (fun t : ℝ => ((c * t : ℝ) : ℂ) * I) 0 := by
      have : ContDiff ℝ k (fun t : ℝ => ((c * t : ℝ) : ℂ) * I) :=
        (ofRealCLM.contDiff.comp (contDiff_const.mul contDiff_id)).mul contDiff_const
      exact this.contDiffAt
    rw [(hev.iteratedDeriv k).eq_of_nhds, iteratedDeriv_add hF hL,
      cum_aux_iteratedDeriv_comp_mul]
    simp only [mul_zero]
  have hdL : deriv (fun t : ℝ => ((c * t : ℝ) : ℂ) * I) = fun _ => (c : ℂ) * I := by
    funext t
    have := (((hasDerivAt_id t).const_mul c).ofReal_comp).mul_const I
    simpa using this.deriv
  refine ⟨fun hX => ?_, fun k hk hX => ?_⟩
  · unfold cumulant
    rw [key 1 (by exact_mod_cast hX)]
    simp only [iteratedDeriv_one, hdL]
    field_simp
  · unfold cumulant
    rw [key k hX]
    obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
    have hL0 : iteratedDeriv (j + 1) (fun t : ℝ => ((c * t : ℝ) : ℂ) * I) 0 = 0 := by
      rw [iteratedDeriv_succ', hdL, iteratedDeriv_const]
      simp [show j ≠ 0 by omega]
    rw [hL0]
    ring

/-- The first four cumulants, with `μ = E[X]`: `κ₁` is the mean, `κ₂ = E[(X - μ)²]` the
variance, `κ₃ = E[(X - μ)³]` the third central moment, and `κ₄ = E[(X - μ)⁴] - 3 κ₂²`,
each whenever the moment it needs is finite. -/
theorem cumulant_one_to_four (P : Measure Ω) [IsProbabilityMeasure P] (X : Ω → ℝ) :
    (MemLp X 1 P → cumulant X P 1 = ((∫ ω, X ω ∂P : ℝ) : ℂ)) ∧
    (MemLp X 2 P → cumulant X P 2 =
      ((∫ ω, (X ω - ∫ ω', X ω' ∂P) ^ 2 ∂P : ℝ) : ℂ)) ∧
    (MemLp X 3 P → cumulant X P 3 =
      ((∫ ω, (X ω - ∫ ω', X ω' ∂P) ^ 3 ∂P : ℝ) : ℂ)) ∧
    (MemLp X 4 P → cumulant X P 4 =
      ((∫ ω, (X ω - ∫ ω', X ω' ∂P) ^ 4 ∂P
        - 3 * (∫ ω, (X ω - ∫ ω', X ω' ∂P) ^ 2 ∂P) ^ 2 : ℝ) : ℂ)) := by
  set m : ℝ := ∫ ω, X ω ∂P with hm
  -- the first cumulant
  have part1 : MemLp X 1 P → cumulant X P 1 = (m : ℂ) := by
    intro hX
    have hd : DifferentiableAt ℝ (charFun (P.map X)) 0 :=
      (contDiff_charFun (cum_aux_memLp_map (n := 1) (by exact_mod_cast hX))).differentiable
        (by norm_num) 0
    have h1 := cum_aux_moment (n := 1) (by exact_mod_cast hX)
    simp only [iteratedDeriv_one, pow_one] at h1
    unfold cumulant
    rw [iteratedDeriv_one, (hd.hasDerivAt.clog_real (by simp)).deriv, h1]
    simp [hm, ← mul_assoc]
  -- centring: the cumulants of order at least two are those of `X - m`
  set Y : Ω → ℝ := fun ω => X ω - m with hY
  have hshift : ∀ k : ℕ, 2 ≤ k → MemLp X k P → cumulant X P k = cumulant Y P k := by
    intro k hk hX
    have := (cumulant_affine P X 1 (-m)).2 k hk hX
    have hfun : (fun ω => (1:ℝ) * X ω + -m) = Y := by funext ω; simp [hY]; ring
    rw [hfun] at this
    rw [this]; simp
  have core : ∀ k : ℕ, 2 ≤ k → MemLp X k P →
      cumulant X P k = (I ^ k)⁻¹ * iteratedDeriv k (fun t => log (charFun (P.map Y) t)) 0 ∧
      ContDiff ℝ k (charFun (P.map Y)) ∧ charFun (P.map Y) 0 = 1 ∧
      deriv (charFun (P.map Y)) 0 = 0 ∧ MemLp Y k P := by
    intro k hk hX
    have hYk : MemLp Y k P := hX.sub (memLp_const m)
    have hX1 : MemLp X 1 P := hX.mono_exponent (by exact_mod_cast (by omega : 1 ≤ k))
    have hY1 : MemLp Y 1 P := hX1.sub (memLp_const m)
    refine ⟨hshift k hk hX, contDiff_charFun (cum_aux_memLp_map hYk), by simp, ?_, hYk⟩
    have h1 := cum_aux_moment (n := 1) (by exact_mod_cast hY1)
    simp only [iteratedDeriv_one, pow_one] at h1
    rw [h1, hY]
    simp only
    rw [integral_sub (hX1.integrable le_rfl) (integrable_const m)]
    simp [hm]
  refine ⟨part1, fun hX => ?_, fun hX => ?_, fun hX => ?_⟩
  · obtain ⟨e, hc, h0, h1, hYk⟩ := core 2 le_rfl hX
    rw [e, ((cum_aux_log_derivs 2 hc le_rfl h0 h1).1), cum_aux_moment hYk]
    field_simp
    rfl
  · obtain ⟨e, hc, h0, h1, hYk⟩ := core 3 (by norm_num) hX
    rw [e, ((cum_aux_log_derivs 3 hc (by norm_num) h0 h1).2.1 le_rfl), cum_aux_moment hYk]
    field_simp
    rfl
  · obtain ⟨e, hc, h0, h1, hYk⟩ := core 4 (by norm_num) hX
    have hY2 : MemLp Y 2 P := hYk.mono_exponent (by norm_num)
    rw [e, ((cum_aux_log_derivs 4 hc (by norm_num) h0 h1).2.2 le_rfl), cum_aux_moment hYk,
      cum_aux_moment hY2]
    have hI4 : I ^ 4 = 1 := by rw [show (4:ℕ) = 2 * 2 from rfl, pow_mul, I_sq]; norm_num
    rw [hI4]
    push_cast
    rw [I_sq]
    ring

/-! Worked numbers from the card, in thousands of dollars, as exact fractions.
One home claims 0, 2 or 20 with chances 95/100, 4/100, 1/100. -/

-- One home's moments E[X^k], k = 1..4: 0.28, 4.16, 80.32, 1600.64.
example : (4/100 : ℚ) * 2 + 1/100 * 20 = 28/100 := by norm_num
example : (4/100 : ℚ) * 2^2 + 1/100 * 20^2 = 416/100 := by norm_num
example : (4/100 : ℚ) * 2^3 + 1/100 * 20^3 = 8032/100 := by norm_num
example : (4/100 : ℚ) * 2^4 + 1/100 * 20^4 = 160064/100 := by norm_num

-- One home's cumulants from its moments: 4.0816, 76.869504, 1462.64164864.
example : (416/100 : ℚ) - (28/100)^2 = 40816/10000 := by norm_num
example : (8032/100 : ℚ) - 3 * (416/100) * (28/100) + 2 * (28/100)^3
    = 76869504/1000000 := by norm_num
example : (160064/100 : ℚ) - 4 * (8032/100) * (28/100) - 3 * (416/100)^2
    + 12 * (416/100) * (28/100)^2 - 6 * (28/100)^4 = 146264164864/100000000 := by norm_num

-- 1,000 homes: 1,000 times each, 280, 4,081.6, 76,869.504, 1,462,641.64864.
example : (1000 : ℚ) * (28/100) = 280 := by norm_num
example : (1000 : ℚ) * (40816/10000) = 40816/10 := by norm_num
example : (1000 : ℚ) * (76869504/1000000) = 76869504/1000 := by norm_num
example : (1000 : ℚ) * (146264164864/100000000) = 146264164864/100000 := by norm_num

-- The profit 350 - S: first cumulant 350 - 280 = 70, third flips sign.
example : (-1 : ℚ) * 280 + 350 = 70 := by norm_num
example : (-1 : ℚ) ^ 3 * (76869504/1000) = -(76869504/1000) := by norm_num

-- Adding fourth central moments over the homes gives 1,512,620.02432, not the true
-- fourth central moment of the total, 51,441,017.32864.
example : (1000 : ℚ) * (146264164864/100000000 + 3 * (40816/10000)^2)
    = 151262002432/100000 := by norm_num
example : (146264164864/100000 : ℚ) + 3 * (40816/10)^2 = 5144101732864/100000 := by norm_num

-- One fair die: kappa_2 = 35/12, kappa_4 = -259/24, so the standardised total of n dice
-- has fourth cumulant (-222/175)/n, that is -1.268571.../n.
example : ((1 + 4 + 9 + 16 + 25 + 36) / 6 : ℚ) - (21/6)^2 = 35/12 := by norm_num
example : (((1 - 7/2)^4 + (2 - 7/2)^4 + (3 - 7/2)^4 + (4 - 7/2)^4 + (5 - 7/2)^4
    + (6 - 7/2)^4) / 6 : ℚ) - 3 * (35/12)^2 = -259/24 := by norm_num
example : (-259/24 : ℚ) / (35/12)^2 = -222/175 := by norm_num
example : (((1 - 7/2)^3 + (2 - 7/2)^3 + (3 - 7/2)^3 + (4 - 7/2)^3 + (5 - 7/2)^3
    + (6 - 7/2)^3) / 6 : ℚ) = 0 := by norm_num

#print axioms cumulant_add_of_indepFun
#print axioms cumulant_affine
#print axioms cumulant_one_to_four
