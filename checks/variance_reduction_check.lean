-- Variance reduction: stratifying with weights equal to the cell shares never raises the per-draw variance, a mirror dart is negatively correlated with its partner when the score falls in each coordinate, and a control variate with a known mean stays on target with a variance that is a bowl in c, lowest at c* = Cov(H, Y)/Var(Y).
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.ConditionalProbability
import Mathlib.MeasureTheory.Constructions.UnitInterval

open MeasureTheory ProbabilityTheory unitInterval

/-- A real number between `a` and `b` has absolute value at most `|a| + |b|`. -/
lemma abs_le_of_between_vr {a b y : ℝ} (h : a ≤ y ∧ y ≤ b) : |y| ≤ |a| + |b| :=
  abs_le.2 ⟨by linarith [neg_abs_le a, abs_nonneg b, h.1],
    by linarith [le_abs_self b, abs_nonneg a, h.2]⟩

/-- A product of two bounded, almost everywhere strongly measurable functions is integrable
for a finite measure. -/
lemma integrable_mul_of_between_vr {α : Type*} [MeasurableSpace α] {μ : Measure α}
    [IsFiniteMeasure μ] {φ ψ : α → ℝ} (hφ : AEStronglyMeasurable φ μ)
    (hψ : AEStronglyMeasurable ψ μ) (a b c d : ℝ) (h1 : ∀ x, a ≤ φ x ∧ φ x ≤ b)
    (h2 : ∀ x, c ≤ ψ x ∧ ψ x ≤ d) : Integrable (fun x => φ x * ψ x) μ :=
  Integrable.of_bound (hφ.mul hψ) ((|a| + |b|) * (|c| + |d|)) (ae_of_all _ fun x => by
    rw [Real.norm_eq_abs, abs_mul]
    exact mul_le_mul (abs_le_of_between_vr (h1 x)) (abs_le_of_between_vr (h2 x))
      (abs_nonneg _) (by positivity))

/-- A bounded, almost everywhere strongly measurable function is integrable for a finite
measure. -/
lemma integrable_of_between_vr {α : Type*} [MeasurableSpace α] {μ : Measure α}
    [IsFiniteMeasure μ] {φ : α → ℝ} (hφ : AEStronglyMeasurable φ μ) (a b : ℝ)
    (h1 : ∀ x, a ≤ φ x ∧ φ x ≤ b) : Integrable φ μ :=
  Integrable.of_bound hφ (|a| + |b|) (ae_of_all _ fun x => by
    rw [Real.norm_eq_abs]; exact abs_le_of_between_vr (h1 x))

/-- Chebyshev's sum inequality on the unit interval: a falling function and a rising function
are negatively correlated. -/
lemma chebyshev_unitInterval_vr (φ ψ : I → ℝ) (hφ : Antitone φ) (hψ : Monotone ψ) :
    ∫ x, φ x * ψ x ≤ (∫ x, φ x) * ∫ x, ψ x := by
  have bφ : ∀ x, φ 1 ≤ φ x ∧ φ x ≤ φ 0 := fun x => ⟨hφ le_one', hφ nonneg'⟩
  have bψ : ∀ x, ψ 0 ≤ ψ x ∧ ψ x ≤ ψ 1 := fun x => ⟨hψ nonneg', hψ le_one'⟩
  have mφ : AEStronglyMeasurable φ volume := hφ.measurable.aestronglyMeasurable
  have mψ : AEStronglyMeasurable ψ volume := hψ.measurable.aestronglyMeasurable
  have iφ : Integrable φ volume := integrable_of_between_vr mφ _ _ bφ
  have iψ : Integrable ψ volume := integrable_of_between_vr mψ _ _ bψ
  have iφψ : Integrable (fun x => φ x * ψ x) volume :=
    integrable_mul_of_between_vr mφ mψ _ _ _ _ bφ bψ
  set Eφ := ∫ x, φ x
  set Eψ := ∫ x, ψ x
  set Eφψ := ∫ x, φ x * ψ x
  have hG : ∀ y, ∫ x, (φ x - φ y) * (ψ x - ψ y)
      = Eφψ - φ y * Eψ - ψ y * Eφ + φ y * ψ y := by
    intro y
    have e : (fun x => (φ x - φ y) * (ψ x - ψ y))
        = fun x => ((φ x * ψ x - φ y * ψ x) - ψ y * φ x) + φ y * ψ y := by
      funext x; ring
    have i1 : Integrable (fun x => φ y * ψ x) volume := iψ.const_mul _
    have i2 : Integrable (fun x => ψ y * φ x) volume := iφ.const_mul _
    have i3 : Integrable (fun x => φ x * ψ x - φ y * ψ x) volume := iφψ.sub i1
    have i4 : Integrable (fun x => (φ x * ψ x - φ y * ψ x) - ψ y * φ x) volume := i3.sub i2
    rw [e, integral_add i4 (integrable_const _), integral_sub i3 i2, integral_sub iφψ i1,
      integral_const_mul, integral_const_mul, integral_const]
    simp only [probReal_univ, one_smul]
    rfl
  have hGle : ∀ y, Eφψ - φ y * Eψ - ψ y * Eφ + φ y * ψ y ≤ 0 := by
    intro y
    rw [← hG y]
    refine integral_nonpos fun x => ?_
    rcases le_total x y with h | h
    · have h1 := hφ h
      have h2 := hψ h
      exact mul_nonpos_of_nonneg_of_nonpos (by linarith) (by linarith)
    · have h1 := hφ h
      have h2 := hψ h
      exact mul_nonpos_of_nonpos_of_nonneg (by linarith) (by linarith)
  have hint : ∫ y, (Eφψ - φ y * Eψ - ψ y * Eφ + φ y * ψ y) ≤ 0 := integral_nonpos hGle
  have j1 : Integrable (fun y => φ y * Eψ) volume := iφ.mul_const _
  have j2 : Integrable (fun y => ψ y * Eφ) volume := iψ.mul_const _
  have j3 : Integrable (fun y => Eφψ - φ y * Eψ) volume := (integrable_const _).sub j1
  have j4 : Integrable (fun y => Eφψ - φ y * Eψ - ψ y * Eφ) volume := j3.sub j2
  rw [integral_add j4 iφψ, integral_sub j3 j2, integral_sub (integrable_const _) j1,
    integral_mul_const, integral_mul_const, integral_const] at hint
  simp at hint
  linarith

/-- **Stratified sampling with proportional allocation never does worse (Step 3).** Cut the
space into finitely many cells `A j` that are measurable, do not overlap and cover everything.
Cell `j` has share `p j = P (A j)`, mean `μ j` and variance `σ j ²` (the mean and variance of the
reading `X` given that the draw lands in `A j`); `μ` and `σ²` are the plain mean and variance.
For a reading with finite variance:
* the variance splits into a within-cell part plus a between-cell part,
  `Σ p j σ j² = σ² − Σ p j (μ j − μ)²`;
* so the per-draw variance of the stratified estimate with `n j = N p j` darts in cell `j`,
  `Σ p j σ j²` (its variance times `N`), is at most the plain per-draw variance `σ²`;
* with equality exactly when every cell of positive share has the same mean as the whole. -/
theorem stratified_proportional_never_worse {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] [Fintype ι] (A : ι → Set Ω) (hA : ∀ j, MeasurableSet (A j))
    (hdisj : Pairwise (Function.onFun Disjoint A)) (hcover : ⋃ j, A j = Set.univ)
    (X : Ω → ℝ) (hX : MemLp X 2 P) :
    (∑ j, (P (A j)).toReal * variance X (P[|A j])
        = variance X P - ∑ j, (P (A j)).toReal * (∫ ω, X ω ∂(P[|A j]) - ∫ ω, X ω ∂P) ^ 2) ∧
    (∑ j, (P (A j)).toReal * variance X (P[|A j]) ≤ variance X P) ∧
    (∑ j, (P (A j)).toReal * variance X (P[|A j]) = variance X P ↔
      ∀ j, P (A j) ≠ 0 → ∫ ω, X ω ∂(P[|A j]) = ∫ ω, X ω ∂P) := by
  have hXi : Integrable X P := hX.integrable one_le_two
  have hX2 : Integrable (fun ω => X ω ^ 2) P := hX.integrable_sq
  -- shares and the reduction of a conditional average to a set integral
  have hp0 : ∀ j, (P (A j)).toReal = 0 ↔ P (A j) = 0 := fun j => by
    rw [ENNReal.toReal_eq_zero_iff]; simp [measure_ne_top P (A j)]
  have hK : ∀ j (Z : Ω → ℝ),
      (P (A j)).toReal * ∫ ω, Z ω ∂(P[|A j]) = ∫ ω in A j, Z ω ∂P := by
    intro j Z
    rw [ProbabilityTheory.cond, integral_smul_measure, ENNReal.toReal_inv, smul_eq_mul]
    by_cases h : (P (A j)).toReal = 0
    · have h0 : P (A j) = 0 := (hp0 j).1 h
      rw [h, Measure.restrict_eq_zero.2 h0]; simp
    · field_simp
  have hsum : ∀ Z : Ω → ℝ, Integrable Z P → ∑ j, ∫ ω in A j, Z ω ∂P = ∫ ω, Z ω ∂P := by
    intro Z hZ
    rw [← integral_iUnion_fintype hA hdisj (fun j => hZ.integrableOn), hcover, setIntegral_univ]
  have hone : ∀ j, ∫ ω in A j, (1 : ℝ) ∂P = (P (A j)).toReal := by
    intro j; rw [setIntegral_const, measureReal_def, smul_eq_mul, mul_one]
  have hpsum : ∑ j, (P (A j)).toReal = 1 := by
    have := hsum (fun _ => (1 : ℝ)) (integrable_const 1)
    simp only [hone, integral_const, smul_eq_mul, mul_one] at this
    rw [this]; simp
  set p : ι → ℝ := fun j => (P (A j)).toReal with hp_def
  set mj : ι → ℝ := fun j => ∫ ω, X ω ∂(P[|A j]) with hmj_def
  set m : ℝ := ∫ ω, X ω ∂P with hm_def
  set a : ι → ℝ := fun j => ∫ ω in A j, X ω ^ 2 ∂P with ha_def
  have hb : ∀ j, ∫ ω in A j, X ω ∂P = p j * mj j := fun j => (hK j X).symm
  have hVj : ∀ j, p j * variance X (P[|A j]) = a j - p j * mj j ^ 2 := by
    intro j
    rw [variance_eq_integral (hX.aemeasurable.mono_ac cond_absolutelyContinuous)]
    show (P (A j)).toReal * _ = _
    rw [hK j]
    have e : (fun ω => (X ω - ∫ ω, X ω ∂(P[|A j])) ^ 2)
        = fun ω => (X ω ^ 2 + (-2 * mj j) * X ω) + mj j ^ 2 := by
      funext ω; simp only [hmj_def]; ring
    have i1 : IntegrableOn (fun ω => X ω ^ 2 + (-2 * mj j) * X ω) (A j) P :=
      (hX2.add (hXi.const_mul _)).integrableOn
    have i2 : IntegrableOn (fun ω => (-2 * mj j) * X ω) (A j) P := (hXi.const_mul _).integrableOn
    rw [e, integral_add i1 (integrable_const _), integral_add hX2.integrableOn i2, integral_const_mul,
      setIntegral_const, hb j, measureReal_def, smul_eq_mul]
    simp only [ha_def, hp_def]
    ring
  have hvar : variance X P = (∑ j, a j) - m ^ 2 := by
    rw [variance_eq_sub hX, hsum _ hX2]
    simp [Pi.pow_apply, hm_def]
  have hbsum : ∑ j, p j * mj j = m := by
    exact (Finset.sum_congr rfl fun j _ => (hb j).symm).trans (hsum X hXi)
  have e1 : ∑ j, p j * variance X (P[|A j]) = (∑ j, a j) - ∑ j, p j * mj j ^ 2 := by
    rw [← Finset.sum_sub_distrib]; exact Finset.sum_congr rfl fun j _ => hVj j
  have e2 : ∑ j, p j * (mj j - m) ^ 2
      = ∑ j, p j * mj j ^ 2 - 2 * m * ∑ j, p j * mj j + m ^ 2 * ∑ j, p j := by
    rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun j _ => by ring
  have hpsum' : ∑ j, p j = 1 := hpsum
  have main : ∑ j, p j * variance X (P[|A j]) = variance X P - ∑ j, p j * (mj j - m) ^ 2 := by
    rw [e1, e2, hvar, hbsum, hpsum']; ring
  have hnn : ∀ j ∈ Finset.univ, 0 ≤ p j * (mj j - m) ^ 2 :=
    fun j _ => mul_nonneg ENNReal.toReal_nonneg (sq_nonneg _)
  refine ⟨main, ?_, ?_⟩
  · rw [main]; linarith [Finset.sum_nonneg hnn]
  · rw [main]
    constructor
    · intro h j hj
      have h0 : ∑ j, p j * (mj j - m) ^ 2 = 0 := by linarith
      have := (Finset.sum_eq_zero_iff_of_nonneg hnn).1 h0 j (Finset.mem_univ j)
      rcases mul_eq_zero.1 this with h1 | h1
      · exact absurd ((hp0 j).1 h1) hj
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h1
        exact sub_eq_zero.1 this
    · intro h
      have h0 : ∑ j, p j * (mj j - m) ^ 2 = 0 := by
        refine Finset.sum_eq_zero fun j _ => ?_
        by_cases hj : P (A j) = 0
        · simp [hp_def, hj]
        · simp [hmj_def, h j hj, hm_def]
      linarith

/-- **A mirror dart is negatively correlated with its dart (Step 1).** A dart lands at `(U, V)`,
uniform on the unit square; its mirror is `(1 − U, 1 − V)`. If the score `f` falls (or stays
level) as either coordinate grows, and `f²` has a finite average, then the covariance of the
dart's score and the mirror's score is at most 0. So a mirror pair never does worse than two
independent darts. -/
theorem mirror_covariance_nonpos (f : I × I → ℝ) (hf : Antitone f) (hf2 : MemLp f 2 volume) :
    cov[f, fun x => f (σ x.1, σ x.2); volume] ≤ 0 := by
  have hmp : MeasurePreserving (fun x : I × I => (σ x.1, σ x.2)) volume volume :=
    measurePreserving_symm.prod measurePreserving_symm
  have hg2 : MemLp (fun x : I × I => f (σ x.1, σ x.2)) 2 volume :=
    hf2.comp_measurePreserving hmp
  have hb : ∀ x, f 1 ≤ f x ∧ f x ≤ f 0 := fun x =>
    ⟨hf ⟨le_one', le_one'⟩, hf ⟨nonneg', nonneg'⟩⟩
  have hbg : ∀ x : I × I, f 1 ≤ f (σ x.1, σ x.2) ∧ f (σ x.1, σ x.2) ≤ f 0 := fun x => hb _
  have hfi : Integrable f volume := integrable_of_between_vr hf2.aestronglyMeasurable _ _ hb
  have hfgi : Integrable (fun x : I × I => f x * f (σ x.1, σ x.2)) volume :=
    integrable_mul_of_between_vr hf2.aestronglyMeasurable hg2.aestronglyMeasurable _ _ _ _ hb hbg
  -- sections
  have hsec_anti : ∀ u, Antitone fun v => f (u, v) := fun u v v' h => hf ⟨le_rfl, h⟩
  have hsec_int : ∀ u, Integrable (fun v => f (u, v)) volume := fun u =>
    integrable_of_between_vr (hsec_anti u).measurable.aestronglyMeasurable _ _ fun v => hb _
  set F : I → ℝ := fun u => ∫ v, f (u, v)
  have hFanti : Antitone F := fun u u' h =>
    integral_mono (hsec_int u') (hsec_int u) fun v => hf ⟨h, le_rfl⟩
  have hFσ : ∀ u, ∫ v, f (u, σ v) = F u := fun u =>
    measurePreserving_symm.integral_comp symmMeasurableEquiv.measurableEmbedding
      (fun v => f (u, v))
  have hFσmono : Monotone fun u => F (σ u) := fun u u' h =>
    hFanti (symm_le_symm.2 h)
  have hEf : ∫ x, f x = ∫ u, F u := by
    rw [Measure.volume_eq_prod, integral_prod f hfi]
  have hEg : ∫ x : I × I, f (σ x.1, σ x.2) = ∫ x, f x := by
    rw [Measure.volume_eq_prod]
    exact (measurePreserving_symm.prod measurePreserving_symm).integral_comp
      (symmMeasurableEquiv.prodCongr symmMeasurableEquiv).measurableEmbedding f
  have hEFσ : ∫ u, F (σ u) = ∫ u, F u :=
    measurePreserving_symm.integral_comp symmMeasurableEquiv.measurableEmbedding F
  have hinner : ∀ u, ∫ v, f (u, v) * f (σ u, σ v) ≤ F u * F (σ u) := by
    intro u
    have := chebyshev_unitInterval_vr (fun v => f (u, v)) (fun v => f (σ u, σ v))
      (hsec_anti u) (fun v v' h => hsec_anti (σ u) (symm_le_symm.2 h))
    rwa [hFσ (σ u)] at this
  have hFF : Integrable (fun u => F u * F (σ u)) volume :=
    integrable_mul_of_between_vr hFanti.measurable.aestronglyMeasurable
      hFσmono.measurable.aestronglyMeasurable (F 1) (F 0) (F (σ 0)) (F (σ 1))
      (fun u => ⟨hFanti le_one', hFanti nonneg'⟩) (fun u => ⟨hFσmono nonneg', hFσmono le_one'⟩)
  have hEfg : ∫ x, f x * f (σ x.1, σ x.2) ≤ (∫ u, F u) * ∫ u, F u := by
    have h1 : ∫ x, f x * f (σ x.1, σ x.2) = ∫ u, ∫ v, f (u, v) * f (σ u, σ v) := by
      rw [Measure.volume_eq_prod]
      exact integral_prod (fun x : I × I => f x * f (σ x.1, σ x.2)) hfgi
    rw [h1]
    calc ∫ u, ∫ v, f (u, v) * f (σ u, σ v) ≤ ∫ u, F u * F (σ u) :=
          integral_mono (hfgi.integral_prod_left) hFF hinner
      _ ≤ (∫ u, F u) * ∫ u, F (σ u) := chebyshev_unitInterval_vr F _ hFanti hFσmono
      _ = (∫ u, F u) * ∫ u, F u := by rw [hEFσ]
  rw [covariance_eq_sub hf2 hg2]
  simp only [Pi.mul_apply]
  rw [hEg, hEf]
  linarith

/-- **A control variate stays on target, and its variance is a bowl in `c` (Step 2).** Let `H`
be the score and `Y` a side reading, both with finite variance, where the mean `ν` of `Y` is known
exactly and `Y` has positive variance. For every fixed number `c`, the corrected score
`H − c (Y − ν)` has the same mean as `H`, its variance is
`Var(H) − 2c Cov(H, Y) + c² Var(Y)`, that variance is never below `Var(H) − Cov(H, Y)²/Var(Y)`,
and it reaches that lowest value exactly at `c = c* = Cov(H, Y)/Var(Y)`. -/
theorem control_variate_unbiased_and_best_coefficient {Ω : Type*} [MeasurableSpace Ω]
    {P : Measure Ω} [IsProbabilityMeasure P] (H Y : Ω → ℝ) (ν c : ℝ)
    (hH : MemLp H 2 P) (hY : MemLp Y 2 P) (hν : ∫ ω, Y ω ∂P = ν) (hVY : 0 < variance Y P) :
    ∫ ω, (H ω - c * (Y ω - ν)) ∂P = ∫ ω, H ω ∂P ∧
    variance (fun ω => H ω - c * (Y ω - ν)) P
        = variance H P - 2 * c * cov[H, Y; P] + c ^ 2 * variance Y P ∧
    variance H P - cov[H, Y; P] ^ 2 / variance Y P ≤ variance (fun ω => H ω - c * (Y ω - ν)) P ∧
    (variance (fun ω => H ω - c * (Y ω - ν)) P = variance H P - cov[H, Y; P] ^ 2 / variance Y P ↔
      c = cov[H, Y; P] / variance Y P) := by
  have hHi : Integrable H P := hH.integrable one_le_two
  have hYi : Integrable Y P := hY.integrable one_le_two
  have hV : variance (fun ω => H ω - c * (Y ω - ν)) P
      = variance H P - 2 * c * cov[H, Y; P] + c ^ 2 * variance Y P := by
    have e : (fun ω => H ω - c * (Y ω - ν)) = fun ω => (H ω - c * Y ω) + c * ν := by
      funext ω; ring
    have hm : AEStronglyMeasurable (fun ω => H ω - c * Y ω) P :=
      hH.aestronglyMeasurable.sub (hY.aestronglyMeasurable.const_mul c)
    rw [e, variance_add_const (X := fun ω => H ω - c * Y ω) hm (c * ν)]
    rw [variance_fun_sub hH (hY.const_mul c), covariance_const_mul_right, variance_const_mul]
    ring
  set v := variance Y P
  set C := cov[H, Y; P]
  have hv : v ≠ 0 := hVY.ne'
  have key : variance H P - 2 * c * C + c ^ 2 * v
      = (variance H P - C ^ 2 / v) + v * (c - C / v) ^ 2 := by
    field_simp; ring
  refine ⟨?_, hV, ?_, ?_⟩
  · have h1 : Integrable (fun ω => Y ω - ν) P := hYi.sub (integrable_const ν)
    have h2 : Integrable (fun ω => c * (Y ω - ν)) P := h1.const_mul c
    rw [integral_sub hHi h2, integral_const_mul, integral_sub hYi (integrable_const ν), hν]
    simp
  · rw [hV, key]
    have : 0 ≤ v * (c - C / v) ^ 2 := mul_nonneg hVY.le (sq_nonneg _)
    linarith
  · rw [hV, key]
    constructor
    · intro h
      have h2 : v * (c - C / v) ^ 2 = 0 := by linarith
      rcases mul_eq_zero.1 h2 with h3 | h3
      · exact absurd h3 hv
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h3
        linarith
    · intro h
      rw [h]; simp

-- The 10 by 10 grid: cell (i, j) is crossed by the arc when its lower-left corner is inside
-- the circle of radius 10 and its upper-right corner is outside. Exactly 17 cells are crossed.
example : ((Finset.range 10 ×ˢ Finset.range 10).filter
    (fun p : ℕ × ℕ => p.1 * p.1 + p.2 * p.2 < 100 ∧ 100 < (p.1 + 1) ^ 2 + (p.2 + 1) ^ 2)).card
    = 17 := by decide
-- The arc can visit at most 9 + 9 + 1 = 19 cells, and passes through the two grid corners
-- (0.6, 0.8) and (0.8, 0.6), each of which saves one cell: 19 - 2 = 17.
example : 9 + 9 + 1 = 19 ∧ 6 ^ 2 + 8 ^ 2 = 10 ^ 2 ∧ 8 ^ 2 + 6 ^ 2 = 10 ^ 2 ∧ 19 - 2 = 17 := by decide
-- The grid has 100 cells, one dart each: N = 100.
example : 10 * 10 = 100 := by decide
-- The control's known mean: E[U²] = 1/3, so ν = 1/3 + 1/3 = 2/3.
example : (1 : ℚ) / 3 + 1 / 3 = 2 / 3 := by norm_num
-- Var(U²) = 1/5 - 1/9 = 4/45, so Var(Y) = 2 · 4/45 = 8/45.
example : (1 : ℚ) / 5 - (1 / 3) ^ 2 = 4 / 45 ∧ 2 * ((1 : ℚ) / 5 - 1 / 9) = 8 / 45 := by norm_num
-- The last term of the control variance at c = -3: 9 · 8/45 = 8/5 (the card's 1.6).
example : (-3 : ℚ) ^ 2 * (8 / 45) = 8 / 5 := by norm_num
-- Cov(H, Y) = 4 · π/8 - π · 2/3 = -π/6.
example : 4 * (Real.pi / 8) - Real.pi * (2 / 3) = -(Real.pi / 6) := by ring
-- The best coefficient: c* = (-π/6) / (8/45) = -15π/16.
example : -(Real.pi / 6) / (8 / 45) = -(15 * Real.pi / 16) := by ring
-- The middle term of the control variance at c = -3: -2 · (-3) · (-π/6) = -π.
example : -2 * (-3) * (-(Real.pi / 6)) = -Real.pi := by ring
-- The lens where both mirror darts hit: π/4 + π/4 - 1 = π/2 - 1.
example : Real.pi / 4 + Real.pi / 4 - 1 = Real.pi / 2 - 1 := by ring
-- A wrong control mean of 1/2 with c = -3 shifts the average by -c (ν - 1/2) = 1/2.
example : -(-3 : ℚ) * (2 / 3 - 1 / 2) = 1 / 2 := by norm_num
-- Stratified bound: at most 17 crossed cells × variance 4 × weight (1/100)² = 17/2500.
example : (17 : ℚ) * 4 * (1 / 100) ^ 2 = 17 / 2500 := by norm_num
-- The unweighted design: 75 darts left, 25 right, 100 in all.
example : 75 + 25 = 100 := by decide

#print axioms stratified_proportional_never_worse
#print axioms mirror_covariance_nonpos
#print axioms control_variate_unbiased_and_best_coefficient
#print axioms abs_le_of_between_vr
#print axioms integrable_mul_of_between_vr
#print axioms integrable_of_between_vr
#print axioms chebyshev_unitInterval_vr
