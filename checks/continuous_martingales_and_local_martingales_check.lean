-- Continuous martingales and local martingales: optional stopping holds for a continuous martingale at a bounded stopping time, a bounded continuous local martingale is a martingale, and one over the distance of a 3-dimensional Brownian motion started 1 unit out has mean 2 Phi(1/sqrt t) - 1 < 1.
import Mathlib.Probability.Martingale.OptionalSampling
import Mathlib.Probability.Process.LocalProperty
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.MeasureTheory.Function.JacobianOneDim
import Mathlib.MeasureTheory.Integral.Pi
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory
open scoped NNReal ENNReal


section CMLMHelpers

open Real Filter Topology

lemma cmlm_dyad_le_iff (n : ℕ) (r s : ℝ≥0) :
    (⌈r * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n ≤ s ↔ r ≤ (⌊s * 2 ^ n⌋₊ : ℝ≥0) / 2 ^ n := by
  have h2 : (0 : ℝ≥0) < 2 ^ n := by positivity
  rw [div_le_iff₀ h2, le_div_iff₀ h2, ← Nat.le_floor_iff (by positivity), Nat.ceil_le]

#print axioms cmlm_dyad_le_iff

lemma cmlm_dyad_bounds (n : ℕ) (r : ℝ≥0) :
    r ≤ (⌈r * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n ∧ (⌈r * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n ≤ r + (1 / 2) ^ n := by
  have h2 : (0 : ℝ≥0) < 2 ^ n := by positivity
  constructor
  · rw [le_div_iff₀ h2]; exact Nat.le_ceil _
  · rw [div_le_iff₀ h2, add_mul, div_pow, one_pow, div_mul_cancel₀ _ h2.ne']
    exact (Nat.ceil_lt_add_one (by positivity)).le

#print axioms cmlm_dyad_bounds

lemma cmlm_dyad_tendsto (r : ℝ≥0) :
    Tendsto (fun n : ℕ => (⌈r * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n) atTop (𝓝 r) := by
  have h : Tendsto (fun n : ℕ => r + (1 / 2 : ℝ≥0) ^ n) atTop (𝓝 r) := by
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one (r := (1 / 2 : ℝ≥0)) (by positivity)
      (by norm_num)).const_add r
    simpa using this
  exact tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h
    (fun n => (cmlm_dyad_bounds n r).1) (fun n => (cmlm_dyad_bounds n r).2)

#print axioms cmlm_dyad_tendsto

lemma cmlm_dyad_isStoppingTime {Ω : Type*} {mΩ : MeasurableSpace Ω} {ℱ : Filtration ℝ≥0 mΩ}
    {τ : Ω → WithTop ℝ≥0} (hτ : IsStoppingTime ℱ τ) (hfin : ∀ ω, τ ω ≠ ⊤) (n : ℕ) :
    IsStoppingTime ℱ
      (fun ω => (((⌈(τ ω).untopA * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n : ℝ≥0) : WithTop ℝ≥0)) := by
  intro s
  have hset : {ω | (((⌈(τ ω).untopA * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n : ℝ≥0) : WithTop ℝ≥0) ≤ s}
      = {ω | τ ω ≤ (((⌊s * 2 ^ n⌋₊ : ℝ≥0) / 2 ^ n : ℝ≥0) : WithTop ℝ≥0)} := by
    ext ω
    simp only [Set.mem_ofPred_eq, WithTop.coe_le_coe, cmlm_dyad_le_iff]
    exact WithTop.untopA_le_iff (hfin ω)
  rw [hset]
  have hq : ((⌊s * 2 ^ n⌋₊ : ℝ≥0) / 2 ^ n) ≤ s := by
    rw [div_le_iff₀ (by positivity)]; exact Nat.floor_le (by positivity)
  exact ℱ.mono hq _ (hτ _)

#print axioms cmlm_dyad_isStoppingTime

theorem cmlm_thm1_aux
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hM : Martingale M ℱ P) (hcont : ∀ ω, Continuous (fun t ↦ M t ω))
    {τ : Ω → WithTop ℝ≥0} (hτ : IsStoppingTime ℱ τ) {T : ℝ≥0} (hτT : ∀ ω, τ ω ≤ T) :
    P[stoppedValue M τ] = P[M 0] := by
  have hfin : ∀ ω, τ ω ≠ ⊤ := fun ω h => by
    have := hτT ω; rw [h] at this; exact WithTop.coe_ne_top (top_le_iff.1 this)
  set σ : ℕ → Ω → WithTop ℝ≥0 := fun n ω =>
    (((⌈(τ ω).untopA * 2 ^ n⌉₊ : ℝ≥0) / 2 ^ n : ℝ≥0) : WithTop ℝ≥0) with hσ
  have hσst : ∀ n, IsStoppingTime ℱ (σ n) := fun n => cmlm_dyad_isStoppingTime hτ hfin n
  have hσle : ∀ n ω, σ n ω ≤ ((T + 1 : ℝ≥0) : WithTop ℝ≥0) := by
    intro n ω
    simp only [hσ, WithTop.coe_le_coe]
    have h1 := (cmlm_dyad_bounds n (τ ω).untopA).2
    have h2 : (τ ω).untopA ≤ T := (WithTop.untopA_le_iff (hfin ω)).2 (hτT ω)
    have h3 : (1 / 2 : ℝ≥0) ^ n ≤ 1 := pow_le_one₀ (by positivity) (by norm_num)
    calc _ ≤ (τ ω).untopA + (1 / 2) ^ n := h1
      _ ≤ T + 1 := add_le_add h2 h3
  have hcount : ∀ n, (Set.range (σ n)).Countable := fun n =>
    (Set.countable_range (fun k : ℕ => (((k : ℝ≥0) / 2 ^ n : ℝ≥0) : WithTop ℝ≥0))).mono
      (by rintro _ ⟨ω, rfl⟩; exact ⟨_, rfl⟩)
  have key : ∀ n, stoppedValue M (σ n) =ᵐ[P] P[M (T + 1) | (hσst n).measurableSpace] := fun n =>
    hM.stoppedValue_ae_eq_condExp_of_le_const_of_countable_range (hσst n) (hσle n) (hcount n)
  have hle : ∀ n, (hσst n).measurableSpace ≤ mΩ := fun n =>
    (hσst n).measurableSpace_le_of_le (hσle n)
  set F : ℕ → Ω → ℝ := fun n => P[M (T + 1) | (hσst n).measurableSpace] with hF
  have hUI : UniformIntegrable F 1 P := (hM.integrable (T + 1)).uniformIntegrable_condExp hle
  have hpt : ∀ ω, Tendsto (fun n => stoppedValue M (σ n) ω) atTop (𝓝 (stoppedValue M τ ω)) := by
    intro ω
    simp only [stoppedValue, hσ, WithTop.untopD_coe]
    exact ((hcont ω).tendsto _).comp (cmlm_dyad_tendsto _)
  have hFlim : ∀ᵐ ω ∂P, Tendsto (fun n => F n ω) atTop (𝓝 (stoppedValue M τ ω)) := by
    filter_upwards [ae_all_iff.2 key] with ω hω
    exact (hpt ω).congr hω
  have hFm : ∀ n, AEStronglyMeasurable (F n) P := fun n =>
    (stronglyMeasurable_condExp.mono (hle n)).aestronglyMeasurable
  have hTIM := tendstoInMeasure_of_tendsto_ae hFm hFlim
  have hmem : MemLp (stoppedValue M τ) 1 P := hUI.memLp_of_tendstoInMeasure hTIM
  have hL1 := tendsto_Lp_finite_of_tendstoInMeasure le_rfl ENNReal.one_ne_top hFm hmem
    hUI.1 hTIM
  have hint : Tendsto (fun n => ∫ ω, F n ω ∂P) atTop (𝓝 (∫ ω, stoppedValue M τ ω ∂P)) :=
    tendsto_integral_of_L1' _ (Eventually.of_forall fun n => integrable_condExp) hL1
  have hconst : ∀ n, ∫ ω, F n ω ∂P = P[M 0] := fun n => by
    rw [hF]; dsimp only
    rw [integral_condExp (hle n), ← integral_condExp (ℱ.le 0)]
    exact integral_congr_ae (hM.condExp_ae_eq (zero_le))
  simp_rw [hconst] at hint
  exact tendsto_nhds_unique hint tendsto_const_nhds

#print axioms cmlm_thm1_aux

theorem cmlm_thm2_aux
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {X : ℝ≥0 → Ω → ℝ}
    (hadapt : StronglyAdapted ℱ X)
    (hloc : Locally (fun Y ↦ Martingale Y ℱ P) ℱ X P)
    {C : ℝ} (hbound : ∀ t ω, |X t ω| ≤ C) :
    Martingale X ℱ P := by
  obtain ⟨τ, hτ, hmart⟩ := hloc
  set Y : ℕ → ℝ≥0 → Ω → ℝ := fun n =>
    stoppedProcess (fun i ↦ {ω | ⊥ < τ n ω}.indicator (X i)) (τ n) with hY
  have hYb : ∀ n r ω, ‖Y n r ω‖ ≤ C := by
    intro n r ω
    simp only [hY, stoppedProcess]
    exact (norm_indicator_le_norm_self _ _).trans (hbound _ ω)
  have hlim : ∀ᵐ ω ∂P, ∀ r, Tendsto (fun n => Y n r ω) atTop (𝓝 (X r ω)) := by
    filter_upwards [hτ.tendsto_top] with ω hω r
    have hev : ∀ᶠ n in atTop, (r : WithTop ℝ≥0) < τ n ω :=
      hω (Ioi_mem_nhds (WithTop.coe_lt_top r))
    refine tendsto_const_nhds.congr' ?_
    filter_upwards [hev] with n hn
    simp only [hY]
    rw [stoppedProcess_eq_of_le hn.le]
    have : ω ∈ {ω | ⊥ < τ n ω} := lt_of_le_of_lt bot_le hn
    rw [Set.indicator_of_mem this]
  have hXint : ∀ r, Integrable (X r) P := fun r =>
    Integrable.of_bound ((hadapt r).mono (ℱ.le r)).aestronglyMeasurable C
      (Eventually.of_forall fun ω => by rw [Real.norm_eq_abs]; exact hbound r ω)
  refine ⟨hadapt, fun s r hsr => ?_⟩
  have h1 : P[X r | ℱ s] =ᵐ[P] P[X s | ℱ s] := by
    refine tendsto_condExp_unique (fun n => Y n r) (fun n => Y n s) (X r) (X s)
      (fun n => (hmart n).integrable r) (fun n => (hmart n).integrable s) ?_ ?_
      (fun _ => C) (integrable_const C) (fun _ => C) (integrable_const C)
      (fun n => Eventually.of_forall fun ω => hYb n r ω)
      (fun n => Eventually.of_forall fun ω => hYb n s ω) ?_
    · filter_upwards [hlim] with ω hω using hω r
    · filter_upwards [hlim] with ω hω using hω s
    · intro n
      refine ((hmart n).condExp_ae_eq hsr).trans ?_
      rw [condExp_of_stronglyMeasurable (ℱ.le s) ((hmart n).stronglyAdapted s)
        ((hmart n).integrable s)]
  refine h1.trans ?_
  rw [condExp_of_stronglyMeasurable (ℱ.le s) (hadapt s) (hXint s)]

#print axioms cmlm_thm2_aux

lemma cmlm_gauss_line {q : ℝ} (hq : 0 < q) :
    ∫⁻ s : ℝ, ENNReal.ofReal ((√(2 * π))⁻¹ * rexp (-(q / 2) * s ^ 2)) = ENNReal.ofReal (1 / √q) := by
  rw [← ofReal_integral_eq_lintegral_ofReal]
  · rw [integral_const_mul, integral_gaussian]
    congr 1
    have h1 : π / (q / 2) = (2 * π) / q := by field_simp
    rw [h1, Real.sqrt_div (by positivity)]
    have : 0 < √(2 * π) := by positivity
    have : 0 < √q := Real.sqrt_pos.2 hq
    field_simp
  · exact (integrable_exp_neg_mul_sq (by positivity)).const_mul _
  · exact Filter.Eventually.of_forall fun s => by positivity

#print axioms cmlm_gauss_line

lemma cmlm_gauss_1d {t : ℝ≥0} (ht : 0 < t) (s a : ℝ) :
    ∫ w, rexp (-(s ^ 2 / 2) * (a + w) ^ 2) ∂gaussianReal 0 t
      = (√(1 + s ^ 2 * t))⁻¹ * rexp (-(s ^ 2 * a ^ 2) / (2 * (1 + s ^ 2 * t))) := by
  have htR : (0 : ℝ) < t := by exact_mod_cast ht
  have hu : 0 < 1 + s ^ 2 * (t : ℝ) := by positivity
  set β : ℝ := (1 + s ^ 2 * t) / (2 * t) with hβ
  set γ : ℝ := s ^ 2 * t * a / (1 + s ^ 2 * t) with hγ
  set δ : ℝ := s ^ 2 * a ^ 2 / (2 * (1 + s ^ 2 * t)) with hδ
  have hβpos : 0 < β := by positivity
  rw [integral_gaussianReal_eq_integral_smul ht.ne']
  have hpt : ∀ w : ℝ, gaussianPDFReal 0 t w • rexp (-(s ^ 2 / 2) * (a + w) ^ 2)
      = ((√(2 * π * t))⁻¹ * rexp (-δ)) * rexp (-β * (w + γ) ^ 2) := by
    intro w
    rw [gaussianPDFReal_def, smul_eq_mul, mul_assoc, ← Real.exp_add, mul_assoc _ (rexp (-δ)), ← Real.exp_add]
    congr 2
    rw [hβ, hγ, hδ]
    field_simp
    ring
  simp_rw [hpt]
  rw [integral_const_mul, integral_add_right_eq_self (fun w => rexp (-β * w ^ 2)), integral_gaussian]
  have h1 : π / β = (2 * π * t) / (1 + s ^ 2 * t) := by rw [hβ]; field_simp
  rw [h1, Real.sqrt_div (by positivity)]
  have : 0 < √(2 * π * t) := by positivity
  have : 0 < √(1 + s ^ 2 * t) := Real.sqrt_pos.2 hu
  rw [hδ, neg_div]
  field_simp

#print axioms cmlm_gauss_1d

lemma cmlm_inner_pi {t : ℝ≥0} (ht : 0 < t) (s : ℝ) :
    ∫ v : Fin 3 → ℝ, rexp (-(((1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2) / 2) * s ^ 2)
        ∂Measure.pi (fun _ => gaussianReal 0 t)
      = ((√(1 + s ^ 2 * t))⁻¹) ^ 3 * rexp (-(s ^ 2) / (2 * (1 + s ^ 2 * t))) := by
  have hpt : ∀ v : Fin 3 → ℝ, rexp (-(((1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2) / 2) * s ^ 2)
      = ∏ i : Fin 3, (fun (i : Fin 3) (x : ℝ) =>
          rexp (-(s ^ 2 / 2) * ((if i = 0 then 1 else 0) + x) ^ 2)) i (v i) := by
    intro v
    simp only [Fin.prod_univ_three]
    rw [← Real.exp_add, ← Real.exp_add]; congr 1; simp; ring
  simp_rw [hpt]
  rw [integral_fintype_prod_eq_prod (f := fun (i : Fin 3) (x : ℝ) =>
          rexp (-(s ^ 2 / 2) * ((if i = 0 then 1 else 0) + x) ^ 2))]
  simp only [Fin.prod_univ_three, cmlm_gauss_1d ht]
  simp
  ring

#print axioms cmlm_inner_pi

lemma cmlm_change {T : ℝ} (hT : 0 < T) :
    ∫⁻ s : ℝ, ENNReal.ofReal ((√(2 * π))⁻¹ *
        (((√(1 + s ^ 2 * T))⁻¹) ^ 3 * rexp (-(s ^ 2) / (2 * (1 + s ^ 2 * T)))))
      = gaussianReal 0 1 (Set.Ioo (-(1 / √T)) (1 / √T)) := by
  set f : ℝ → ℝ := fun s => s * (√(1 + s ^ 2 * T))⁻¹ with hf
  set g : ℝ → ℝ := fun u => u * (√(1 - T * u ^ 2))⁻¹ with hg
  have hu : ∀ s : ℝ, 0 < 1 + s ^ 2 * T := fun s => by positivity
  have hsq : ∀ s : ℝ, f s ^ 2 = s ^ 2 / (1 + s ^ 2 * T) := by
    intro s; rw [hf]; dsimp only; rw [mul_pow, inv_pow, Real.sq_sqrt (hu s).le]; ring
  have hgf : ∀ s, g (f s) = s := by
    intro s
    have h1 : 1 - T * f s ^ 2 = ((√(1 + s ^ 2 * T))⁻¹) ^ 2 := by
      rw [hsq, inv_pow, Real.sq_sqrt (hu s).le]; field_simp; ring
    rw [hg]; dsimp only
    rw [h1, Real.sqrt_sq (by positivity), inv_inv, hf]; dsimp only
    have : 0 < √(1 + s ^ 2 * T) := Real.sqrt_pos.2 (hu s)
    field_simp
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq1 : (1 / √T) ^ 2 = 1 / T := by rw [div_pow, Real.sq_sqrt hT.le]; ring
  have himg : f '' Set.univ = Set.Ioo (-(1 / √T)) (1 / √T) := by
    ext u
    simp only [Set.image_univ, Set.mem_range, Set.mem_Ioo]
    constructor
    · rintro ⟨s, rfl⟩
      have : f s ^ 2 < (1 / √T) ^ 2 := by
        rw [hsq, hsq1, div_lt_div_iff₀ (hu s) hT]; nlinarith
      have := abs_lt_of_sq_lt_sq this (by positivity)
      exact abs_lt.1 this
    · rintro ⟨h1, h2⟩
      have hu2 : u ^ 2 < 1 / T := hsq1 ▸ sq_lt_sq' h1 h2
      have hv : 0 < 1 - T * u ^ 2 := by
        rw [lt_div_iff₀ hT] at hu2; nlinarith
      refine ⟨g u, ?_⟩
      have h3 : 1 + g u ^ 2 * T = ((√(1 - T * u ^ 2))⁻¹) ^ 2 := by
        rw [hg]; dsimp only
        have hv' : (1 - u ^ 2 * T) ≠ 0 := by intro h; nlinarith
        rw [mul_pow, inv_pow, Real.sq_sqrt hv.le]; field_simp; ring
      rw [hf]; dsimp only
      rw [h3, Real.sqrt_sq (by positivity), inv_inv, hg]; dsimp only
      have : 0 < √(1 - T * u ^ 2) := Real.sqrt_pos.2 hv
      rw [mul_assoc, inv_mul_cancel₀ this.ne', mul_one]
  have hinj : Set.InjOn f Set.univ := fun a _ b _ hab => by
    rw [← hgf a, ← hgf b, hab]
  have hder : ∀ s ∈ Set.univ, HasDerivWithinAt f (((√(1 + s ^ 2 * T))⁻¹) ^ 3) Set.univ s := by
    intro s _
    apply HasDerivAt.hasDerivWithinAt
    have h1 : HasDerivAt (fun s : ℝ => 1 + s ^ 2 * T) (2 * s * T) s := by
      have := ((hasDerivAt_pow 2 s).mul_const T).const_add 1
      convert this using 1; push_cast; ring
    have h2 := (h1.sqrt (hu s).ne').inv (Real.sqrt_pos.2 (hu s)).ne'
    have h3 := (hasDerivAt_id s).mul h2
    refine h3.congr_deriv ?_
    have : 0 < √(1 + s ^ 2 * T) := Real.sqrt_pos.2 (hu s)
    have hs2 := Real.sq_sqrt (hu s).le
    simp only [Pi.inv_apply, id, one_mul]
    field_simp
    rw [hs2]; ring
  rw [gaussianReal_apply 0 one_ne_zero, ← himg,
    lintegral_image_eq_lintegral_abs_deriv_mul MeasurableSet.univ hder hinj, Measure.restrict_univ]
  refine lintegral_congr fun s => ?_
  have : 0 < √(1 + s ^ 2 * T) := Real.sqrt_pos.2 (hu s)
  rw [gaussianPDF, ← ENNReal.ofReal_mul (abs_nonneg _), abs_of_pos (by positivity)]
  congr 1
  rw [gaussianPDFReal_def]
  dsimp only
  rw [sub_zero, hsq]
  have e : -(s ^ 2 / (1 + s ^ 2 * T)) / (2 * ((1 : ℝ≥0) : ℝ)) = -(s ^ 2) / (2 * (1 + s ^ 2 * T)) := by
    push_cast; field_simp
  rw [e]
  push_cast
  ring_nf

#print axioms cmlm_change

lemma cmlm_ioo_cdf {x : ℝ} (hx : 0 < x) :
    (gaussianReal 0 1).real (Set.Ioo (-x) x) = 2 * cdf (gaussianReal 0 1) x - 1 ∧
    (gaussianReal 0 1).real (Set.Ioo (-x) x) < 1 := by
  set G := gaussianReal 0 1 with hG
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have hsym : G.real (Set.Iic (-x)) = G.real (Set.Ici x) := by
    have hm : G.map (fun y => -y) = G := by rw [hG, gaussianReal_map_neg, neg_zero]
    conv_lhs => rw [← hm]
    rw [measureReal_def, Measure.map_apply measurable_neg measurableSet_Iic, measureReal_def]
    congr 2
    ext y; simp
  have hici : G.real (Set.Ici x) = G.real (Set.Ioi x) := measureReal_congr Ioi_ae_eq_Ici.symm
  have hioi : G.real (Set.Ioi x) = 1 - G.real (Set.Iic x) := by
    rw [← Set.compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic]
  have hiio : G.real (Set.Iio x) = G.real (Set.Iic x) := measureReal_congr Iio_ae_eq_Iic
  have hdiff : Set.Ioo (-x) x = Set.Iio x \ Set.Iic (-x) := by
    ext y; simp [and_comm]
  have hioo : G.real (Set.Ioo (-x) x) = 2 * cdf G x - 1 := by
    rw [hdiff, measureReal_sdiff (Set.Iic_subset_Iio.2 (by linarith)) measurableSet_Iic, hiio,
      hsym, hici, hioi, cdf_eq_real]
    ring
  refine ⟨hioo, ?_⟩
  have hpos : 0 < G.real (Set.Ioi x) := by
    rw [measureReal_def]
    refine ENNReal.toReal_pos ?_ (measure_ne_top _ _)
    intro h0
    have := gaussianReal_absolutelyContinuous' 0 (v := 1) one_ne_zero h0
    simp at this
  rw [hioo, cdf_eq_real]
  linarith

#print axioms cmlm_ioo_cdf

theorem cmlm_thm3_aux
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {B : Fin 3 → ℝ≥0 → Ω → ℝ} (hB : ∀ i, IsBrownianReal (B i) P)
    (hind : iIndepFun (fun i ω ↦ fun s ↦ B i s ω) P) {t : ℝ≥0} (ht : 0 < t) :
    P[fun ω ↦ 1 / Real.sqrt ((1 + B 0 t ω) ^ 2 + (B 1 t ω) ^ 2 + (B 2 t ω) ^ 2)]
        = 2 * cdf (gaussianReal 0 1) (1 / Real.sqrt t) - 1 ∧
      P[fun ω ↦ 1 / Real.sqrt ((1 + B 0 t ω) ^ 2 + (B 1 t ω) ^ 2 + (B 2 t ω) ^ 2)] < 1 := by
  have htR : (0 : ℝ) < t := by exact_mod_cast ht
  set μ3 := Measure.pi (fun _ : Fin 3 => gaussianReal 0 t) with hμ3
  have hmeas : ∀ i, AEMeasurable (B i t) P := fun i => (hB i).aemeasurable t
  have hind' : iIndepFun (fun i ω => B i t ω) P :=
    hind.comp (fun _ (f : ℝ≥0 → ℝ) => f t) (fun _ => measurable_pi_apply t)
  have hmap : P.map (fun ω i => B i t ω) = μ3 := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hmeas).1 hind', hμ3]
    congr; funext i; exact ((hB i).hasLaw_eval t).map_eq
  set h : (Fin 3 → ℝ) → ℝ := fun v => 1 / √((1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2) with hh
  have hhm : Measurable h := by fun_prop
  have hint : P[fun ω ↦ 1 / Real.sqrt ((1 + B 0 t ω) ^ 2 + (B 1 t ω) ^ 2 + (B 2 t ω) ^ 2)]
      = ∫ v, h v ∂μ3 := by
    rw [← hmap, integral_map (AEMeasurable.of_eval hmeas) hhm.aestronglyMeasurable]
  have := nullSingletonClass_gaussianReal (μ := 0) ht.ne'
  have hae : ∀ᵐ v ∂μ3, v 0 ≠ -1 := by
    rw [ae_iff]
    simpa using Measure.pi_hyperplane (fun _ : Fin 3 => gaussianReal 0 t) 0 (-1)
  have hval : ∫ v, h v ∂μ3 = (gaussianReal 0 1).real (Set.Ioo (-(1 / √(t : ℝ))) (1 / √(t : ℝ))) := by
    rw [integral_eq_lintegral_of_nonneg_ae (Filter.Eventually.of_forall fun v => by positivity)
      hhm.aestronglyMeasurable, measureReal_def]
    congr 1
    rw [← cmlm_change htR]
    have h1 : ∫⁻ v, ENNReal.ofReal (h v) ∂μ3 = ∫⁻ v, (∫⁻ s : ℝ, ENNReal.ofReal
        ((√(2 * π))⁻¹ * rexp (-(((1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2) / 2) * s ^ 2))) ∂μ3 := by
      refine lintegral_congr_ae ?_
      filter_upwards [hae] with v hv
      have hq : 0 < (1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2 := by
        have : 1 + v 0 ≠ 0 := fun h0 => hv (by linarith)
        positivity
      rw [cmlm_gauss_line hq]
    rw [h1, lintegral_lintegral_swap (by fun_prop)]
    refine lintegral_congr fun s => ?_
    rw [← ofReal_integral_eq_lintegral_ofReal, integral_const_mul, cmlm_inner_pi ht]
    · refine (integrable_const ((√(2 * π))⁻¹)).mono' (by fun_prop) ?_
      refine Filter.Eventually.of_forall fun v => ?_
      rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
      have : rexp (-(((1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2) / 2) * s ^ 2) ≤ 1 := by
        rw [Real.exp_le_one_iff]
        have : 0 ≤ ((1 + v 0) ^ 2 + (v 1) ^ 2 + (v 2) ^ 2) / 2 * s ^ 2 := by positivity
        linarith
      have h0 : 0 ≤ (√(2 * π))⁻¹ := by positivity
      nlinarith
    · exact Filter.Eventually.of_forall fun v => by positivity
  rw [hint, hval]
  exact cmlm_ioo_cdf (by positivity)

#print axioms cmlm_thm3_aux

end CMLMHelpers

/-- Optional stopping in continuous time: if `M` is a martingale with continuous paths and
`τ` is a stopping time with `τ ≤ T` on every path for a fixed time `T`, then the average of
`M` at the stopping time equals its average at time 0: `E[M_τ] = E[M_0]`. -/
theorem optional_stopping_bounded_continuous
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hM : Martingale M ℱ P) (hcont : ∀ ω, Continuous (fun t ↦ M t ω))
    {τ : Ω → WithTop ℝ≥0} (hτ : IsStoppingTime ℱ τ) {T : ℝ≥0} (hτT : ∀ ω, τ ω ≤ T) :
    P[stoppedValue M τ] = P[M 0] := by
  exact cmlm_thm1_aux hM hcont hτ hτT

/-- A bounded local martingale is a martingale: if an adapted process `X` with continuous
paths becomes a martingale when frozen along some localising sequence of stopping times,
and `|X_t| ≤ C` for all times and paths, then `X` itself is a martingale. -/
theorem bounded_local_martingale_is_martingale
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {X : ℝ≥0 → Ω → ℝ}
    (hadapt : StronglyAdapted ℱ X) (hcont : ∀ ω, Continuous (fun t ↦ X t ω))
    (hloc : Locally (fun Y ↦ Martingale Y ℱ P) ℱ X P)
    {C : ℝ} (hbound : ∀ t ω, |X t ω| ≤ C) :
    Martingale X ℱ P := by
  exact cmlm_thm2_aux hadapt hloc hbound

/-- One over the distance is not a true martingale: let `B` be a 3-dimensional Brownian
motion (three independent real Brownian motions) started at distance 1 from the origin,
at the point `(1, 0, 0)`. For every time `t > 0` the average reading `E[1/|B_t|]` equals
`2 Φ(1/√t) - 1`, where `Φ` is the standard normal distribution function, and this is
strictly less than the starting reading 1. -/
theorem mean_inverse_distance_brownian_three_dim
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {B : Fin 3 → ℝ≥0 → Ω → ℝ} (hB : ∀ i, IsBrownianReal (B i) P)
    (hind : iIndepFun (fun i ω ↦ fun s ↦ B i s ω) P) {t : ℝ≥0} (ht : 0 < t) :
    P[fun ω ↦ 1 / Real.sqrt ((1 + B 0 t ω) ^ 2 + (B 1 t ω) ^ 2 + (B 2 t ω) ^ 2)]
        = 2 * cdf (gaussianReal 0 1) (1 / Real.sqrt t) - 1 ∧
      P[fun ω ↦ 1 / Real.sqrt ((1 + B 0 t ω) ^ 2 + (B 1 t ω) ^ 2 + (B 2 t ω) ^ 2)] < 1 := by
  exact cmlm_thm3_aux hB hind ht

/-! Exact checks of the card's own formulas. -/

/-- Step 4: the three curvatures of one over the distance cancel, at the point `(1, 2, 2)`
where the distance is 3. -/
example : ((-1 / 3 ^ 3 + 3 * 1 ^ 2 / 3 ^ 5) + (-1 / 3 ^ 3 + 3 * 2 ^ 2 / 3 ^ 5)
    + (-1 / 3 ^ 3 + 3 * 2 ^ 2 / 3 ^ 5) : ℚ) = 0 := by norm_num

/-- Step 5 shell formula `((ρ + 1) - |ρ - 1|) / (2ρ) = 1 / max ρ 1` at radius 3: the shell
average is `1/3`. -/
example : (((3 + 1) - |(3 : ℚ) - 1|) / (2 * 3)) = 1 / max (3 : ℚ) 1 ∧
    1 / max (3 : ℚ) 1 = 1 / 3 := by norm_num

/-- The same shell formula at radius `1/2`, inside the start distance: the average is 1. -/
example : (((1 / 2 + 1) - |(1 / 2 : ℚ) - 1|) / (2 * (1 / 2))) = 1 := by norm_num


#print axioms optional_stopping_bounded_continuous
#print axioms bounded_local_martingale_is_martingale
#print axioms mean_inverse_distance_brownian_three_dim
