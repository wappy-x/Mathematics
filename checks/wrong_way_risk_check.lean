-- Wrong-way risk: CVA equals the independent CVA plus the loss share times a covariance, two falling functions of one score have nonnegative covariance, and a put's CVA never exceeds the loss share times the discounted strike times the default chance.
import Mathlib.Probability.Moments.Covariance
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory ProbabilityTheory

/-- Covariance as "average of the product minus product of the averages", needing only
that the two variables and their product have finite averages. -/
lemma covariance_eq_integral_mul_sub_of_integrable
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {F G : Ω → ℝ} (hF : Integrable F μ) (hG : Integrable G μ)
    (hFG : Integrable (fun ω => F ω * G ω) μ) :
    cov[F, G; μ] = ∫ ω, F ω * G ω ∂μ - (∫ ω, F ω ∂μ) * ∫ ω, G ω ∂μ := by
  unfold covariance
  set a := ∫ ω, F ω ∂μ
  set b := ∫ ω, G ω ∂μ
  have h : ∀ ω, (F ω - a) * (G ω - b) = (F ω * G ω - b * F ω) - (a * G ω - a * b) := by
    intro ω; ring
  simp_rw [h]
  have j1 : Integrable (fun ω => F ω * G ω - b * F ω) μ := hFG.sub (hF.const_mul b)
  have j2 : Integrable (fun ω => a * G ω - a * b) μ := (hG.const_mul a).sub (integrable_const _)
  have j3 : Integrable (fun ω => b * F ω) μ := hF.const_mul b
  have j4 : Integrable (fun ω => a * G ω) μ := hG.const_mul a
  rw [integral_sub j1 j2, integral_sub hFG j3, integral_sub j4 (integrable_const _),
    integral_const_mul, integral_const_mul, integral_const]
  simp
  ring

/-- The covariance split of CVA. For any exposure `X` with a finite average, any default
event `Def` with indicator `B`, any loss share `L`, rate `r` and horizon `T`:
CVA = L · E[e^{-rT} X B] equals the independent CVA `L · p · P`, where `p` is the default
chance and `P = E[e^{-rT} X]` is the clean price, plus the wrong-way term
`L · Cov(e^{-rT} X, B)`. The split is exact and needs no model. -/
theorem cva_eq_independent_cva_add_wrong_way_term
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : Ω → ℝ) (hX : Integrable X μ) (Def : Set Ω) (hDef : MeasurableSet Def)
    (L r T : ℝ) :
    L * ∫ ω, Real.exp (-r * T) * X ω * Def.indicator 1 ω ∂μ
      = L * μ.real Def * (∫ ω, Real.exp (-r * T) * X ω ∂μ)
        + L * cov[fun ω => Real.exp (-r * T) * X ω, Def.indicator 1; μ] := by
  have hB : Integrable (Def.indicator (1 : Ω → ℝ)) μ :=
    (integrable_const (1 : ℝ)).indicator hDef
  have hcX : Integrable (fun ω => Real.exp (-r * T) * X ω) μ := hX.const_mul _
  have hprod : Integrable (fun ω => Real.exp (-r * T) * X ω * Def.indicator 1 ω) μ := by
    refine hcX.mul_bdd (c := 1) ?_ ?_
    · exact (measurable_const.indicator hDef).aestronglyMeasurable
    · refine Filter.Eventually.of_forall (fun ω => ?_)
      by_cases h : ω ∈ Def <;> simp [h]
  rw [covariance_eq_integral_mul_sub_of_integrable hcX hB hprod, integral_indicator_one hDef]
  ring

/-- Two falling functions have positive covariance (Step 6). If `f` and `g` are both
non-increasing functions of the share score `Y`, with finite averages of `f(Y)`, `g(Y)`
and their product, then `Cov(f(Y), g(Y)) ≥ 0`. With `f` the discounted put payoff and
`g` the conditional default chance, this makes the wrong-way term nonnegative. -/
theorem covariance_nonneg_of_antitone_antitone
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (Y : Ω → ℝ) (hY : Measurable Y) (f g : ℝ → ℝ) (hf : Antitone f) (hg : Antitone g)
    (hfi : Integrable (fun ω => f (Y ω)) μ) (hgi : Integrable (fun ω => g (Y ω)) μ)
    (hfgi : Integrable (fun ω => f (Y ω) * g (Y ω)) μ) :
    0 ≤ cov[fun ω => f (Y ω), fun ω => g (Y ω); μ] := by
  set F : Ω → ℝ := fun ω => f (Y ω)
  set G : Ω → ℝ := fun ω => g (Y ω)
  rw [covariance_eq_integral_mul_sub_of_integrable hfi hgi hfgi]
  have hpt : ∀ z : Ω × Ω, 0 ≤ (F z.1 - F z.2) * (G z.1 - G z.2) := by
    intro z
    rcases le_total (Y z.1) (Y z.2) with h | h
    · exact mul_nonneg (sub_nonneg.mpr (hf h)) (sub_nonneg.mpr (hg h))
    · exact mul_nonneg_of_nonpos_of_nonpos (sub_nonpos.mpr (hf h)) (sub_nonpos.mpr (hg h))
  have hnn : 0 ≤ ∫ z, (F z.1 - F z.2) * (G z.1 - G z.2) ∂(μ.prod μ) :=
    integral_nonneg hpt
  have hexp : ∀ z : Ω × Ω, (F z.1 - F z.2) * (G z.1 - G z.2)
      = ((F z.1 * G z.1 - F z.1 * G z.2) - F z.2 * G z.1) + F z.2 * G z.2 := by
    intro z; ring
  have i1 : Integrable (fun z : Ω × Ω => F z.1 * G z.1) (μ.prod μ) := hfgi.comp_fst μ
  have i2 : Integrable (fun z : Ω × Ω => F z.1 * G z.2) (μ.prod μ) := hfi.mul_prod hgi
  have i3 : Integrable (fun z : Ω × Ω => F z.2 * G z.1) (μ.prod μ) := by
    have := hgi.mul_prod (μ := μ) (ν := μ) hfi
    simpa [mul_comm] using this
  have i4 : Integrable (fun z : Ω × Ω => F z.2 * G z.2) (μ.prod μ) := hfgi.comp_snd μ
  simp_rw [hexp] at hnn
  have i12 : Integrable (fun z : Ω × Ω => F z.1 * G z.1 - F z.1 * G z.2) (μ.prod μ) :=
    i1.sub i2
  have i123 : Integrable
      (fun z : Ω × Ω => F z.1 * G z.1 - F z.1 * G z.2 - F z.2 * G z.1) (μ.prod μ) :=
    i12.sub i3
  rw [integral_add i123 i4, integral_sub i12 i3, integral_sub i1 i2] at hnn
  have e1 : ∫ z, F z.1 * G z.1 ∂(μ.prod μ) = ∫ ω, F ω * G ω ∂μ := by
    rw [integral_fun_fst (fun ω => F ω * G ω)]; simp
  have e4 : ∫ z, F z.2 * G z.2 ∂(μ.prod μ) = ∫ ω, F ω * G ω ∂μ := by
    rw [integral_fun_snd (fun ω => F ω * G ω)]; simp
  have e2 : ∫ z, F z.1 * G z.2 ∂(μ.prod μ) = (∫ ω, F ω ∂μ) * ∫ ω, G ω ∂μ :=
    integral_prod_mul F G
  have e3 : ∫ z, F z.2 * G z.1 ∂(μ.prod μ) = (∫ ω, F ω ∂μ) * ∫ ω, G ω ∂μ := by
    have : ∫ z, F z.2 * G z.1 ∂(μ.prod μ) = ∫ z, G z.1 * F z.2 ∂(μ.prod μ) := by
      congr 1; ext z; ring
    rw [this, integral_prod_mul G F, mul_comm]
  rw [e1, e2, e3, e4] at hnn
  linarith

/-- The ceiling no model can pass (Step 7). A put with strike `K ≥ 0` on a share price
that is never negative never pays more than `K`, so with recovery `R ≤ 1` its CVA,
`(1 - R) · E[e^{-rT} max(K - S_T, 0) · B]`, is at most `(1 - R) · K · e^{-rT} · p`,
where `p` is the default chance. -/
theorem put_cva_le_loss_share_mul_discounted_strike_mul_default_chance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (S_T : Ω → ℝ) (hS : ∀ ω, 0 ≤ S_T ω) (K : ℝ) (hK : 0 ≤ K) (R : ℝ) (hR : R ≤ 1)
    (r T : ℝ) (Def : Set Ω) (hDef : MeasurableSet Def) :
    (1 - R) * ∫ ω, Real.exp (-r * T) * max (K - S_T ω) 0 * Def.indicator 1 ω ∂μ
      ≤ (1 - R) * K * Real.exp (-r * T) * μ.real Def := by
  have hLs : 0 ≤ 1 - R := by linarith
  have hc : 0 ≤ Real.exp (-r * T) := (Real.exp_pos _).le
  have hrhs : (1 - R) * K * Real.exp (-r * T) * μ.real Def
      = (1 - R) * ∫ ω, Real.exp (-r * T) * K * Def.indicator 1 ω ∂μ := by
    rw [integral_const_mul, integral_indicator_one hDef]
    ring
  rw [hrhs]
  apply mul_le_mul_of_nonneg_left _ hLs
  by_cases hi : Integrable
      (fun ω => Real.exp (-r * T) * max (K - S_T ω) 0 * Def.indicator 1 ω) μ
  · apply integral_mono hi
    · exact ((integrable_const (1 : ℝ)).indicator hDef).const_mul _
    · intro ω
      have hm : max (K - S_T ω) 0 ≤ K := max_le (by linarith [hS ω]) hK
      have hb : 0 ≤ Def.indicator (1 : Ω → ℝ) ω := by
        by_cases h : ω ∈ Def <;> simp [h]
      have := mul_le_mul_of_nonneg_left hm hc
      exact mul_le_mul_of_nonneg_right this hb
  · rw [integral_undef hi]
    apply integral_nonneg
    intro ω
    have hb : 0 ≤ Def.indicator (1 : Ω → ℝ) ω := by
      by_cases h : ω ∈ Def <;> simp [h]
    exact mul_nonneg (mul_nonneg hc hK) hb

-- The card's chart: the $100-strike put pays $40, $30, $20, $10 at year-end prices
-- $60, $70, $80, $90, and nothing at $100 or above.
example : max ((100 : ℤ) - 60) 0 = 40 := by decide
example : max ((100 : ℤ) - 70) 0 = 30 := by decide
example : max ((100 : ℤ) - 80) 0 = 20 := by decide
example : max ((100 : ℤ) - 90) 0 = 10 := by decide
example : ∀ s ∈ ([100, 110, 120, 130, 140] : List ℤ), max (100 - s) 0 = 0 := by decide

#print axioms covariance_eq_integral_mul_sub_of_integrable
#print axioms cva_eq_independent_cva_add_wrong_way_term
#print axioms covariance_nonneg_of_antitone_antitone
#print axioms put_cva_le_loss_share_mul_discounted_strike_mul_default_chance
