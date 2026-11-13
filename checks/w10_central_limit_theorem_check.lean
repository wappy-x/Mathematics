-- The central limit theorem, proved: for independent copies of one real law with finite positive variance, the chance that the standardised sum is at most x tends to the standard normal chance Φ(x) at every x, and with a finite third moment every test function with bounded third derivative has its average within a constant over √n of its normal average.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.MeasureTheory.Group.IntegralConvolution
import Mathlib.MeasureTheory.Measure.Portmanteau
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas

open MeasureTheory ProbabilityTheory Filter
open scoped Real Topology

lemma clt_aux_taylor (h : ℝ → ℝ) (hh : ContDiff ℝ 3 h) (M : ℝ)
    (hM : ∀ u, |iteratedDeriv 3 h u| ≤ M) (y : ℝ) :
    |h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)| ≤ M * |y| ^ 3 / 6 := by
  rcases eq_or_ne y 0 with rfl | hy
  · simp
  obtain ⟨x', -, hx'⟩ := taylor_mean_remainder_lagrange_iteratedDeriv (n := 2) (x₀ := 0) (x := y)
    hy.symm (hh.contDiffOn.of_le (by norm_num))
  have hu : UniqueDiffOn ℝ (Set.uIcc (0:ℝ) y) := uniqueDiffOn_uIcc hy.symm
  have h0 : (0:ℝ) ∈ Set.uIcc 0 y := Set.left_mem_uIcc
  have e : ∀ k, k ≤ 3 → iteratedDerivWithin k h (Set.uIcc 0 y) 0 = iteratedDeriv k h 0 :=
    fun k hk => iteratedDerivWithin_eq_iteratedDeriv hu (hh.contDiffAt.of_le (by
      exact_mod_cast hk)) h0
  rw [taylor_within_apply] at hx'
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, smul_eq_mul,
    e 0 (by norm_num), e 1 (by norm_num), e 2 (by norm_num)] at hx'
  have : h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)
      = iteratedDeriv (2 + 1) h x' * (y - 0) ^ (2 + 1) / ↑(2 + 1).factorial := by
    rw [← hx']; simp [iteratedDeriv_zero]; ring
  rw [this]
  simp only [sub_zero, Nat.factorial, Nat.reduceAdd]
  rw [abs_div, abs_mul, abs_pow]
  norm_num
  have := hM x'
  have : 0 ≤ |y| ^ 3 := by positivity
  nlinarith

lemma clt_aux_moments (μ : Measure ℝ) [IsProbabilityMeasure μ] (hμ : MemLp id 3 μ) :
    Integrable (fun y : ℝ => y) μ ∧ Integrable (fun y : ℝ => y ^ 2) μ ∧
      Integrable (fun y : ℝ => |y| ^ 3) μ := by
  refine ⟨?_, ?_, ?_⟩
  · exact memLp_one_iff_integrable.1 (hμ.mono_exponent (by norm_num))
  · have h2 : MemLp id ((2 : ℕ) : ENNReal) μ := hμ.mono_exponent (by norm_num)
    simpa [sq_abs] using h2.integrable_norm_pow (by norm_num)
  · have h3 : MemLp id ((3 : ℕ) : ENNReal) μ := by simpa using hμ
    simpa using h3.integrable_norm_pow (by norm_num)

lemma clt_aux_remainder (μ : Measure ℝ) [IsProbabilityMeasure μ] (hμ : MemLp id 3 μ)
    (h : ℝ → ℝ) (hh : ContDiff ℝ 3 h) (M : ℝ) (hM : ∀ u, |iteratedDeriv 3 h u| ≤ M) :
    Integrable (fun y => h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2))
        μ ∧
      |∫ y, (h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)) ∂μ|
        ≤ M / 6 * ∫ y, |y| ^ 3 ∂μ := by
  obtain ⟨-, -, i3⟩ := clt_aux_moments μ hμ
  have hb : ∀ᵐ y ∂μ, ‖h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)‖
      ≤ M / 6 * |y| ^ 3 := ae_of_all _ fun y => by
    rw [Real.norm_eq_abs]; have := clt_aux_taylor h hh M hM y; linarith
  refine ⟨Integrable.mono' (i3.const_mul (M / 6)) ?_ hb, ?_⟩
  · exact (hh.continuous.sub (by fun_prop)).aestronglyMeasurable
  · have := norm_integral_le_of_norm_le (i3.const_mul (M / 6)) hb
    rw [integral_const_mul, Real.norm_eq_abs] at this
    exact this

lemma clt_aux_integrable (μ : Measure ℝ) [IsProbabilityMeasure μ] (hμ : MemLp id 3 μ)
    (h : ℝ → ℝ) (hh : ContDiff ℝ 3 h) (M : ℝ) (hM : ∀ u, |iteratedDeriv 3 h u| ≤ M) :
    Integrable h μ ∧ ∫ y, h y ∂μ =
      ∫ y, (h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)) ∂μ
        + (h 0 + iteratedDeriv 1 h 0 * ∫ y, y ∂μ + iteratedDeriv 2 h 0 * (∫ y, y ^ 2 ∂μ) / 2) := by
  obtain ⟨i1, i2, -⟩ := clt_aux_moments μ hμ
  obtain ⟨iR, -⟩ := clt_aux_remainder μ hμ h hh M hM
  have ip : Integrable (fun y : ℝ => h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2) μ :=
    ((integrable_const _).add (i1.const_mul _)).add ((i2.const_mul _).div_const _)
  have e : h = fun y => (h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2))
      + (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2) := by
    funext y; ring
  refine ⟨e ▸ iR.add ip, ?_⟩
  conv_lhs => rw [e]
  have i01 : Integrable (fun y : ℝ => h 0 + iteratedDeriv 1 h 0 * y) μ :=
    (integrable_const _).add (i1.const_mul _)
  have i22 : Integrable (fun y : ℝ => iteratedDeriv 2 h 0 * y ^ 2 / 2) μ :=
    (i2.const_mul _).div_const _
  have i11 : Integrable (fun y : ℝ => iteratedDeriv 1 h 0 * y) μ := i1.const_mul _
  rw [integral_add iR ip, integral_add i01 i22, integral_add (integrable_const _) i11,
    integral_const, integral_const_mul, integral_div, integral_const_mul]
  simp [mul_div_assoc]

lemma clt_aux_point (ν γ : Measure ℝ) [IsProbabilityMeasure ν] [IsProbabilityMeasure γ]
    (hν : MemLp id 3 ν) (hγ : MemLp id 3 γ) (h1 : ∫ y, y ∂ν = ∫ y, y ∂γ)
    (h2 : ∫ y, y ^ 2 ∂ν = ∫ y, y ^ 2 ∂γ)
    (h : ℝ → ℝ) (hh : ContDiff ℝ 3 h) (M : ℝ) (hM : ∀ u, |iteratedDeriv 3 h u| ≤ M) :
    |∫ y, h y ∂ν - ∫ y, h y ∂γ| ≤ M / 6 * (∫ y, |y| ^ 3 ∂ν + ∫ y, |y| ^ 3 ∂γ) := by
  rw [(clt_aux_integrable ν hν h hh M hM).2, (clt_aux_integrable γ hγ h hh M hM).2, h1, h2]
  have a := (clt_aux_remainder ν hν h hh M hM).2
  have b := (clt_aux_remainder γ hγ h hh M hM).2
  set A := ∫ y, (h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)) ∂ν
  set B := ∫ y, (h y - (h 0 + iteratedDeriv 1 h 0 * y + iteratedDeriv 2 h 0 * y ^ 2 / 2)) ∂γ
  calc _ = |A - B| := by ring_nf
    _ ≤ |A| + |B| := abs_sub _ _
    _ ≤ _ := by rw [mul_add]; exact add_le_add a b

lemma clt_aux_memLp_conv (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hμ : MemLp id 3 μ) (hν : MemLp id 3 ν) : MemLp id 3 (μ ∗ ν) := by
  unfold Measure.conv
  rw [memLp_map_measure_iff aestronglyMeasurable_id (by fun_prop)]
  exact (hμ.comp_measurePreserving (measurePreserving_fst (μ := μ) (ν := ν))).add
    (hν.comp_measurePreserving (measurePreserving_snd (μ := μ) (ν := ν)))

lemma clt_aux_integrable_conv (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (f : ℝ → ℝ) (hf : Integrable f (μ ∗ ν)) : Integrable (fun x => ∫ y, f (x + y) ∂ν) μ := by
  unfold Measure.conv at hf
  have : Integrable (fun p : ℝ × ℝ => f (p.1 + p.2)) (μ.prod ν) :=
    (integrable_map_measure hf.1 (by fun_prop)).mp hf
  exact this.integral_prod_left

lemma clt_aux_swap (ν γ : Measure ℝ) [IsProbabilityMeasure ν] [IsProbabilityMeasure γ]
    (hν : MemLp id 3 ν) (hγ : MemLp id 3 γ) (h1 : ∫ y, y ∂ν = ∫ y, y ∂γ)
    (h2 : ∫ y, y ^ 2 ∂ν = ∫ y, y ^ 2 ∂γ) (M : ℝ)
    (A B : ℕ → Measure ℝ) (hA0 : A 0 = Measure.dirac 0) (hB0 : B 0 = Measure.dirac 0)
    (hA : ∀ n, A (n + 1) = A n ∗ ν) (hB : ∀ n, B (n + 1) = B n ∗ γ) (n : ℕ)
    (h : ℝ → ℝ) (hh : ContDiff ℝ 3 h) (hM : ∀ u, |iteratedDeriv 3 h u| ≤ M) :
    |∫ y, h y ∂(A n) - ∫ y, h y ∂(B n)|
      ≤ n * (M / 6 * (∫ y, |y| ^ 3 ∂ν + ∫ y, |y| ^ 3 ∂γ)) := by
  set K := M / 6 * (∫ y, |y| ^ 3 ∂ν + ∫ y, |y| ^ 3 ∂γ)
  have hPA : ∀ n, IsProbabilityMeasure (A n) := by
    intro n; induction n with
    | zero => rw [hA0]; infer_instance
    | succ n ih => rw [hA]; infer_instance
  have hPB : ∀ n, IsProbabilityMeasure (B n) := by
    intro n; induction n with
    | zero => rw [hB0]; infer_instance
    | succ n ih => rw [hB]; infer_instance
  have hLA : ∀ n, MemLp id 3 (A n) := by
    intro n; induction n with
    | zero =>
      rw [hA0]
      exact memLp_of_bounded (a := 0) (b := 0) (by simp) aestronglyMeasurable_id 3
    | succ n ih => rw [hA]; exact clt_aux_memLp_conv _ _ ih hν
  have hLB : ∀ n, MemLp id 3 (B n) := by
    intro n; induction n with
    | zero =>
      rw [hB0]
      exact memLp_of_bounded (a := 0) (b := 0) (by simp) aestronglyMeasurable_id 3
    | succ n ih => rw [hB]; exact clt_aux_memLp_conv _ _ ih hγ
  have shift : ∀ (g : ℝ → ℝ), ContDiff ℝ 3 g → (∀ u, |iteratedDeriv 3 g u| ≤ M) → ∀ x : ℝ,
      ContDiff ℝ 3 (fun t => g (x + t)) ∧ ∀ u, |iteratedDeriv 3 (fun t => g (x + t)) u| ≤ M :=
    fun g hg hgM x => ⟨hg.comp (contDiff_const.add contDiff_id),
      by rw [iteratedDeriv_comp_const_add]; exact fun u => hgM _⟩
  induction n generalizing h with
  | zero => simp [hA0, hB0]
  | succ n ih =>
    rw [hA, hB]
    have I1 := (clt_aux_integrable _ (clt_aux_memLp_conv _ _ (hLA n) hν) h hh M hM).1
    have I2 := (clt_aux_integrable _ (clt_aux_memLp_conv _ _ (hLA n) hγ) h hh M hM).1
    have I3 := (clt_aux_integrable _ (clt_aux_memLp_conv _ _ (hLB n) hγ) h hh M hM).1
    have t1 : |∫ y, h y ∂(A n ∗ ν) - ∫ y, h y ∂(A n ∗ γ)| ≤ K := by
      rw [integral_conv I1, integral_conv I2, ← integral_sub (clt_aux_integrable_conv _ _ h I1)
        (clt_aux_integrable_conv _ _ h I2)]
      have := norm_integral_le_of_norm_le_const (μ := A n) (C := K) (ae_of_all _ fun x => by
        rw [Real.norm_eq_abs]
        exact clt_aux_point ν γ hν hγ h1 h2 _ (shift h hh hM x).1 M (shift h hh hM x).2)
      simpa using this
    have t2 : |∫ y, h y ∂(A n ∗ γ) - ∫ y, h y ∂(B n ∗ γ)| ≤ n * K := by
      rw [Measure.conv_comm (A n) γ, Measure.conv_comm (B n) γ] at *
      rw [integral_conv I2, integral_conv I3, ← integral_sub (clt_aux_integrable_conv _ _ h I2)
        (clt_aux_integrable_conv _ _ h I3)]
      have := norm_integral_le_of_norm_le_const (μ := γ) (C := n * K) (ae_of_all _ fun x => by
        rw [Real.norm_eq_abs]
        exact ih _ (shift h hh hM x).1 (shift h hh hM x).2)
      simpa using this
    calc _ ≤ |∫ y, h y ∂(A n ∗ ν) - ∫ y, h y ∂(A n ∗ γ)|
          + |∫ y, h y ∂(A n ∗ γ) - ∫ y, h y ∂(B n ∗ γ)| := abs_sub_le _ _ _
      _ ≤ K + n * K := add_le_add t1 t2
      _ = _ := by push_cast; ring

/-- A copy of Mathlib's private `tendstoInDistribution_inv_sqrt_mul_var_mul_sum_sub`. -/
lemma clt_aux_tendstoInDistribution {Ω Ω' : Type*} {mΩ : MeasurableSpace Ω}
    {mΩ' : MeasurableSpace Ω'} {P : Measure Ω} {P' : Measure Ω'} [IsProbabilityMeasure P]
    [IsProbabilityMeasure P'] {X : ℕ → Ω → ℝ} {Y : Ω' → ℝ}
    (hY : HasLaw Y (gaussianReal 0 1) P')
    (hX : Var[X 0; P] ≠ 0) (hindep : iIndepFun X P)
    (hident : ∀ (i : ℕ), IdentDistrib (X i) (X 0) P P) :
    TendstoInDistribution
      (fun (n : ℕ) ω ↦ (√(n * Var[X 0; P]))⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * P[X 0]))
      atTop Y (fun _ ↦ P) P' := by
  have mX0 := (hident 0).aemeasurable_fst
  have intX0 : Integrable (X 0) P := memLp_one_iff_integrable.1 <|
    (memLp_two_of_variance_ne_zero mX0.aestronglyMeasurable hX).mono_exponent (by simp)
  have (n : ℕ) ω : (√(n * Var[X 0; P]))⁻¹ * (∑ k ∈ Finset.range n, X k ω - n * P[X 0]) =
      (√n)⁻¹ * ∑ k ∈ Finset.range n, (X k ω - P[X 0]) / √Var[X 0; P] := by
    rw [← Finset.sum_div, Finset.sum_sub_distrib]
    simp [field]
  simp_rw [this]
  convert tendstoInDistribution_inv_sqrt_mul_sum hY ?_ ?_ ?_ ?_
  · rw [integral_div, integral_sub intX0 (by simp)]
    simp
  · simp only [Pi.pow_apply, div_pow]
    rw [integral_div, ← variance_eq_integral mX0, Real.sq_sqrt (variance_nonneg _ _), div_self hX]
  · exact hindep.comp (fun _ x ↦ (x - P[X 0]) / √Var[X 0; P]) (by fun_prop)
  · convert! fun n ↦ (hident n).comp (u := fun x ↦ (x - P[X 0]) / √Var[X 0; P]) (by fun_prop)

#print axioms clt_aux_taylor
#print axioms clt_aux_moments
#print axioms clt_aux_remainder
#print axioms clt_aux_integrable
#print axioms clt_aux_point
#print axioms clt_aux_memLp_conv
#print axioms clt_aux_integrable_conv
#print axioms clt_aux_swap
#print axioms clt_aux_tendstoInDistribution

variable {Ω : Type*} [MeasurableSpace Ω]

/-- The central limit theorem. Let X₀, X₁, X₂, … be independent real random variables on a
probability space, all with the same law as X₀, with finite variance (X₀ in L²) and positive
variance σ² = Var X₀. Write μ for the mean of X₀ and S_n = X₀ + … + X_{n-1}. Then for every
real x, the chance P((S_n − nμ)/(σ√n) ≤ x) tends, as n → ∞, to the standard normal chance
Φ(x) = ∫_{-∞}^{x} e^{-y²/2}/√(2π) dy. -/
theorem central_limit_theorem (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL2 : MemLp (X 0) 2 P) (hvar : 0 < Var[X 0; P]) (x : ℝ) :
    Tendsto
      (fun n : ℕ => P.real {ω | (∑ k ∈ Finset.range n, X k ω - n * P[X 0]) /
          (Real.sqrt (Var[X 0; P]) * Real.sqrt n) ≤ x})
      atTop
      (𝓝 (∫ y in Set.Iic x, Real.exp (-y ^ 2 / 2) / Real.sqrt (2 * π))) := by
  have T := clt_aux_tendstoInDistribution (P' := gaussianReal 0 1) (HasLaw.id) hvar.ne' hindep
    hident
  have hfr : (gaussianReal 0 1 : Measure ℝ).map id (frontier (Set.Iic x)) = 0 := by
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    simp
  have key := ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto' T.tendsto
    (E := Set.Iic x) hfr
  have key2 := (ENNReal.tendsto_toReal (by
    simp only [ProbabilityMeasure.coe_mk, Measure.map_id]; exact measure_ne_top _ _)).comp key
  convert key2 using 1
  · funext n
    simp only [Function.comp_apply, ProbabilityMeasure.coe_mk]
    rw [Measure.map_apply₀ (T.forall_aemeasurable n) measurableSet_Iic.nullMeasurableSet,
      measureReal_def]
    congr 1
    congr 1
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, Set.mem_Iic]
    rw [Real.sqrt_mul (Nat.cast_nonneg _), div_eq_inv_mul, mul_comm (Real.sqrt n)]
  · simp only [ProbabilityMeasure.coe_mk, Measure.map_id]
    rw [gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal
      (setIntegral_nonneg measurableSet_Iic fun y _ => gaussianPDFReal_nonneg _ _ _)]
    congr 1
    apply integral_congr_ae
    filter_upwards with y
    simp [gaussianPDFReal, div_eq_inv_mul]

/-- Lindeberg's swap bound, the third-moment case. Let X₀, X₁, … be independent copies of one
real law with finite third moment and positive variance σ², mean μ, and
ρ = E|X₀ − μ|³. Let h be three times continuously differentiable with |h'''| ≤ M₃ everywhere,
and let G be standard normal. Then for every n ≥ 1, with Z_n = (S_n − nμ)/(σ√n),
|E h(Z_n) − E h(G)| ≤ M₃/(6√n) · (ρ/σ³ + E|G|³). -/
theorem lindeberg_smooth_bound (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hL3 : MemLp (X 0) 3 P) (hvar : 0 < Var[X 0; P])
    (h : ℝ → ℝ) (hh : ContDiff ℝ 3 h) (M₃ : ℝ) (hM : ∀ u, |iteratedDeriv 3 h u| ≤ M₃)
    (n : ℕ) (hn : 1 ≤ n) :
    |(∫ ω, h ((∑ k ∈ Finset.range n, X k ω - n * P[X 0]) /
          (Real.sqrt (Var[X 0; P]) * Real.sqrt n)) ∂P)
        - ∫ y, h y ∂(gaussianReal 0 1)|
      ≤ M₃ / (6 * Real.sqrt n) *
        ((∫ ω, |X 0 ω - P[X 0]| ^ 3 ∂P) / Real.sqrt (Var[X 0; P]) ^ 3
          + ∫ y, |y| ^ 3 ∂(gaussianReal 0 1)) := by
  set μ0 := P[X 0] with hμ0
  set σ := Real.sqrt (Var[X 0; P]) with hσ
  have hσpos : 0 < σ := Real.sqrt_pos.2 hvar
  have hnpos : (0:ℝ) < n := by exact_mod_cast hn
  set s := Real.sqrt n with hs
  have hspos : 0 < s := Real.sqrt_pos.2 hnpos
  have hs2 : s ^ 2 = n := Real.sq_sqrt hnpos.le
  set c := σ * s with hc
  have hcpos : 0 < c := mul_pos hσpos hspos
  have mX : ∀ i, AEMeasurable (X i) P := fun i => (hident i).aemeasurable_fst
  set ξ : ℕ → Ω → ℝ := fun k ω => (X k ω - μ0) / c with hξ
  have mξ : ∀ i, AEMeasurable (ξ i) P := fun i => ((mX i).sub_const _).div_const _
  have indξ : iIndepFun ξ P := hindep.comp (fun _ x => (x - μ0) / c) (fun _ => by fun_prop)
  have identξ : ∀ i, IdentDistrib (ξ i) (ξ 0) P P := fun i =>
    (hident i).comp (u := fun x => (x - μ0) / c) (by fun_prop)
  have intX0 : Integrable (X 0) P := hL3.integrable (by norm_num)
  -- the law of one scaled summand
  set ν := P.map (ξ 0) with hν
  have hνL : MemLp id 3 ν := by
    rw [hν, memLp_map_measure_iff aestronglyMeasurable_id (mξ 0)]
    have e : (id ∘ ξ 0) = fun ω => (X 0 ω - μ0) * c⁻¹ := by
      funext ω; simp [hξ, div_eq_mul_inv]
    rw [e]; exact (hL3.sub (memLp_const μ0)).mul_const c⁻¹
  have hν1 : ∫ y, y ∂ν = 0 := by
    rw [hν, integral_map (mξ 0) (by fun_prop)]
    simp only [hξ]
    rw [integral_div, integral_sub intX0 (integrable_const _)]
    simp [hμ0]
  have hν2 : ∫ y, y ^ 2 ∂ν = 1 / n := by
    rw [hν, integral_map (mξ 0) (by fun_prop)]
    simp only [hξ, div_pow]
    rw [integral_div, ← variance_eq_integral (mX 0), hc, mul_pow, hσ,
      Real.sq_sqrt hvar.le, hs2]
    field_simp
  have hν3 : ∫ y, |y| ^ 3 ∂ν = (∫ ω, |X 0 ω - μ0| ^ 3 ∂P) / c ^ 3 := by
    rw [hν, integral_map (mξ 0) (by fun_prop)]
    simp only [hξ, abs_div, abs_of_pos hcpos, div_pow]
    rw [integral_div]
  -- the Gaussian piece
  set v : NNReal := ⟨(s⁻¹) ^ 2, sq_nonneg _⟩ with hv
  set γ := gaussianReal 0 v with hγ
  have hγmap : (gaussianReal 0 1).map (fun y => s⁻¹ * y) = γ := by
    rw [gaussianReal_map_const_mul, hγ]
    congr 1
    · simp
    · ext; simp [hv]; rfl
  have hγL : MemLp id 3 γ := memLp_id_gaussianReal' 3 (by simp)
  have hγ1 : ∫ y, y ∂γ = 0 := integral_id_gaussianReal
  have hγ2 : ∫ y, y ^ 2 ∂γ = 1 / n := by
    have := variance_eq_integral (μ := γ) (X := id) aemeasurable_id
    rw [variance_id_gaussianReal] at this
    simp only [id] at this
    rw [hγ1] at this
    simp only [sub_zero] at this
    rw [← this, hv]
    simp [inv_pow, hs2]
    rfl
  have hγ3 : ∫ y, |y| ^ 3 ∂γ = s⁻¹ ^ 3 * ∫ y, |y| ^ 3 ∂(gaussianReal 0 1) := by
    rw [← hγmap, integral_map (by fun_prop) (by fun_prop)]
    simp only [abs_mul, mul_pow, abs_inv, abs_of_pos hspos]
    rw [integral_const_mul]
  -- the two chains of measures
  set A : ℕ → Measure ℝ := fun m => P.map (∑ k ∈ Finset.range m, ξ k) with hA
  set B : ℕ → Measure ℝ := fun m => gaussianReal 0 (m * v) with hB
  have hA0 : A 0 = Measure.dirac 0 := by
    show P.map (fun _ => (0:ℝ)) = _
    simp [Measure.map_const]
  have hB0 : B 0 = Measure.dirac 0 := by simp [hB, gaussianReal_zero_var]
  have hAs : ∀ m, A (m + 1) = A m ∗ ν := by
    intro m
    simp only [hA, Finset.sum_range_succ]
    rw [IndepFun.map_add_eq_map_conv_map₀ (Finset.aemeasurable_sum _ fun i _ => mξ i) (mξ m)
      (indξ.indepFun_sum_range_succ₀ mξ m), (identξ m).map_eq]
  have hBs : ∀ m, B (m + 1) = B m ∗ γ := by
    intro m
    simp only [hB, hγ, gaussianReal_conv_gaussianReal]
    congr 1
    · simp
    · push_cast; ring
  have key := clt_aux_swap ν γ hνL hγL (by rw [hν1, hγ1]) (by rw [hν2, hγ2]) M₃ A B hA0 hB0
    hAs hBs n h hh hM
  have eA : ∫ y, h y ∂(A n) = ∫ ω, h ((∑ k ∈ Finset.range n, X k ω - n * μ0) / (σ * s)) ∂P := by
    simp only [hA]
    rw [integral_map (Finset.aemeasurable_sum _ fun i _ => mξ i) hh.continuous.aestronglyMeasurable]
    congr 1; funext ω
    congr 1
    simp only [Finset.sum_apply, hξ, hc]
    rw [← Finset.sum_div, Finset.sum_sub_distrib]
    simp
  have eB : B n = gaussianReal 0 1 := by
    simp only [hB]
    congr 1
    apply NNReal.eq
    rw [NNReal.coe_mul, NNReal.coe_natCast, NNReal.coe_one]
    show (n:ℝ) * (s⁻¹ ^ 2) = 1
    rw [inv_pow, hs2]
    exact mul_inv_cancel₀ hnpos.ne'
  rw [eA, eB, hν3, hγ3] at key
  refine key.trans (le_of_eq ?_)
  rw [hc, ← hs2]
  field_simp

/-- The telescoping step of the second road: for complex numbers a and b of size at most 1,
|aⁿ − bⁿ| ≤ n·|a − b|. -/
theorem norm_pow_sub_pow_le_of_norm_le_one (a b : ℂ) (ha : ‖a‖ ≤ 1) (hb : ‖b‖ ≤ 1) (n : ℕ) :
    ‖a ^ n - b ^ n‖ ≤ n * ‖a - b‖ := by
  induction n with
  | zero => simp
  | succ n ih =>
    have e : a ^ (n + 1) - b ^ (n + 1) = a * (a ^ n - b ^ n) + (a - b) * b ^ n := by ring
    rw [e]
    calc ‖a * (a ^ n - b ^ n) + (a - b) * b ^ n‖
        ≤ ‖a * (a ^ n - b ^ n)‖ + ‖(a - b) * b ^ n‖ := norm_add_le _ _
      _ = ‖a‖ * ‖a ^ n - b ^ n‖ + ‖a - b‖ * ‖b‖ ^ n := by rw [norm_mul, norm_mul, norm_pow]
      _ ≤ 1 * (n * ‖a - b‖) + ‖a - b‖ * 1 := by
        gcongr
        exact pow_le_one₀ (norm_nonneg _) hb
      _ = _ := by push_cast; ring

-- One fair die: mean 7/2.
example : (∑ i ∈ Finset.range 6, ((i : ℚ) + 1)) / 6 = 7 / 2 := by
  norm_num [Finset.sum_range_succ]

-- Variance of one roll: 35/12.
example : (∑ i ∈ Finset.range 6, ((i : ℚ) + 1 - 7 / 2) ^ 2) / 6 = 35 / 12 := by
  norm_num [Finset.sum_range_succ]

-- Variance of the total of 100 rolls: 875/3.
example : (100 : ℚ) * (35 / 12) = 875 / 3 := by norm_num

-- Third absolute central moment of one roll: ρ = 51/8.
example : (∑ i ∈ Finset.range 6, |(i : ℚ) + 1 - 7 / 2| ^ 3) / 6 = 51 / 8 := by
  norm_num [Finset.sum_range_succ, abs_of_nonneg, abs_of_nonpos]

-- Mean of the total of 100 rolls: 350.
example : (100 : ℚ) * (7 / 2) = 350 := by norm_num

-- Two rolls: 21 of the 36 pairs total 7 or less, so P(Z₂ ≤ 0) = 21/36 = 7/12.
example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => p.1.val + 1 + (p.2.val + 1) ≤ 7)).card = 21 := by decide
example : (21 : ℚ) / 36 = 7 / 12 := by norm_num

-- Six of the 36 pairs total exactly 7, the pairs sitting on the cut.
example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => p.1.val + 1 + (p.2.val + 1) = 7)).card = 6 := by decide

-- One roll copied 100 times: P(one roll ≤ 3) = 3/6 = 1/2.
example : ((Finset.univ : Finset (Fin 6)).filter (fun i => i.val + 1 ≤ 3)).card = 3 := by decide

#print axioms central_limit_theorem
#print axioms lindeberg_smooth_bound
#print axioms norm_pow_sub_pow_le_of_norm_le_one
