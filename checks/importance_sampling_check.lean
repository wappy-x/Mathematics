-- Importance sampling: drawing from a proposal density g that is positive wherever h f is not zero, and weighting each outcome h(Y) by f(Y)/g(Y), gives an average equal to the integral of h f, so the n-draw estimate is unbiased, and with independent draws and a finite second moment M₂ its variance is (M₂ − I²)/n.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open MeasureTheory ProbabilityTheory Finset

lemma is_density_eq (g : ℝ → ℝ) :
    volume.withDensity (fun x => ENNReal.ofReal (g x))
      = volume.withDensity (fun x => (((g x).toNNReal : NNReal) : ENNReal)) := rfl

lemma is_aesm (f g h : ℝ → ℝ) (hg_meas : Measurable g)
    (hhf : Integrable (fun x => h x * f x)) :
    AEStronglyMeasurable (fun x => h x * (f x / g x))
      (volume.withDensity (fun x => ENNReal.ofReal (g x))) := by
  have h1 : AEStronglyMeasurable (fun x => h x * f x)
      (volume.withDensity (fun x => ENNReal.ofReal (g x))) :=
    hhf.aestronglyMeasurable.mono_ac (withDensity_absolutelyContinuous _ _)
  have h2 := (h1.aemeasurable.div hg_meas.aemeasurable).aestronglyMeasurable
  refine h2.congr (Filter.Eventually.of_forall fun x => ?_)
  simp only [Pi.div_apply]
  ring

lemma is_weight_mul (f g h : ℝ → ℝ) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x) (x : ℝ) :
    (g x).toNNReal • (h x * (f x / g x)) = h x * f x := by
  rw [NNReal.smul_def, Real.coe_toNNReal _ (hg_nonneg x), smul_eq_mul]
  by_cases hz : h x * f x = 0
  · rw [← mul_div_assoc, hz]; simp
  · have := hcover x hz
    field_simp

lemma is_weight_sq (f g h : ℝ → ℝ) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x) (x : ℝ) :
    (g x).toNNReal • (h x * (f x / g x)) ^ 2 = h x ^ 2 * f x ^ 2 / g x := by
  rw [NNReal.smul_def, Real.coe_toNNReal _ (hg_nonneg x), smul_eq_mul]
  by_cases hz : h x * f x = 0
  · have : h x ^ 2 * f x ^ 2 = 0 := by rw [← mul_pow, hz]; simp
    rw [this, ← mul_div_assoc, hz]; simp
  · have := hcover x hz
    field_simp

lemma is_integral (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x) :
    ∫ x, h x * (f x / g x) ∂(volume.withDensity (fun x => ENNReal.ofReal (g x)))
      = ∫ x, h x * f x := by
  rw [is_density_eq, integral_withDensity_eq_integral_smul hg_meas.real_toNNReal]
  simp_rw [is_weight_mul f g h hg_nonneg hcover]

lemma is_integrable (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hhf : Integrable (fun x => h x * f x))
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x) :
    Integrable (fun x => h x * (f x / g x))
      (volume.withDensity (fun x => ENNReal.ofReal (g x))) := by
  rw [is_density_eq, integrable_withDensity_iff_integrable_smul hg_meas.real_toNNReal]
  simp_rw [is_weight_mul f g h hg_nonneg hcover]
  exact hhf

lemma is_integral_sq (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x) :
    ∫ x, (h x * (f x / g x)) ^ 2 ∂(volume.withDensity (fun x => ENNReal.ofReal (g x)))
      = ∫ x, h x ^ 2 * f x ^ 2 / g x := by
  rw [is_density_eq, integral_withDensity_eq_integral_smul hg_meas.real_toNNReal]
  simp_rw [is_weight_sq f g h hg_nonneg hcover]

lemma is_integrable_sq (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x)
    (hM₂ : Integrable (fun x => h x ^ 2 * f x ^ 2 / g x)) :
    Integrable (fun x => (h x * (f x / g x)) ^ 2)
      (volume.withDensity (fun x => ENNReal.ofReal (g x))) := by
  rw [is_density_eq, integrable_withDensity_iff_integrable_smul hg_meas.real_toNNReal]
  simp_rw [is_weight_sq f g h hg_nonneg hcover]
  exact hM₂

#print axioms is_density_eq
#print axioms is_aesm
#print axioms is_weight_mul
#print axioms is_weight_sq
#print axioms is_integral
#print axioms is_integrable
#print axioms is_integral_sq
#print axioms is_integrable_sq

/-- The reweighting identity. Let `f` be the real density and `h` the quantity averaged, with
`h f` integrable, so the answer is `I = ∫ h(x) f(x) dx`. Let `g` be a proposal density (measurable,
never negative) that covers the answer: `g(x) > 0` wherever `h(x) f(x) ≠ 0`. If a draw `Y` has
density `g`, then the average of the weighted outcome `h(Y) w(Y)`, with weight `w = f / g`, is
exactly `I`: `E_g[h(Y) w(Y)] = ∫ h f`. -/
theorem importance_sampling_reweighting_identity
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hhf : Integrable (fun x => h x * f x))
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x)
    (Y : Ω → ℝ) (hY : Measurable Y)
    (hY_law : P.map Y = volume.withDensity (fun x => ENNReal.ofReal (g x))) :
    P[fun ω => h (Y ω) * (f (Y ω) / g (Y ω))] = ∫ x, h x * f x := by
  have haesm := is_aesm f g h hg_meas hhf
  rw [← hY_law] at haesm
  have hmap := integral_map hY.aemeasurable haesm
  rw [hY_law, is_integral f g h hg_meas hg_nonneg hcover] at hmap
  exact hmap.symm

/-- The estimate is unbiased. Under the same assumptions, let `Y₁, …, Yₙ` (with `n ≥ 1`) each
have density `g`. The estimate `Îₙ = (1/n) ∑ h(Yᵢ) w(Yᵢ)` has average exactly `I = ∫ h f`, for
any proposal that covers the answer. -/
theorem importance_sampling_estimate_unbiased
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hhf : Integrable (fun x => h x * f x))
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x)
    (n : ℕ) (hn : 0 < n) (Y : Fin n → Ω → ℝ) (hY : ∀ i, Measurable (Y i))
    (hY_law : ∀ i, P.map (Y i) = volume.withDensity (fun x => ENNReal.ofReal (g x))) :
    P[fun ω => (1 / (n : ℝ)) * ∑ i, h (Y i ω) * (f (Y i ω) / g (Y i ω))] = ∫ x, h x * f x := by
  have hint : ∀ i, Integrable (fun ω => h (Y i ω) * (f (Y i ω) / g (Y i ω))) P := fun i => by
    have := is_integrable f g h hg_meas hg_nonneg hhf hcover
    rw [← hY_law i] at this
    exact this.comp_measurable (hY i)
  have hE : ∀ i, P[fun ω => h (Y i ω) * (f (Y i ω) / g (Y i ω))] = ∫ x, h x * f x :=
    fun i => importance_sampling_reweighting_identity f g h hg_meas hg_nonneg hhf hcover (Y i) (hY i) (hY_law i)
  rw [integral_const_mul, integral_finsetSum _ (fun i _ => hint i)]
  simp_rw [hE]
  simp only [sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  field_simp

/-- The error formula. Under the same assumptions, let `Y₁, …, Yₙ` be independent draws, each
with density `g`, and let the second moment `M₂ = ∫ h(x)² f(x)² / g(x) dx` be finite. Then the
estimate `Îₙ = (1/n) ∑ h(Yᵢ) w(Yᵢ)` has variance `(M₂ − I²) / n`, so its standard error is
`√((M₂ − I²) / n)`. -/
theorem importance_sampling_variance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (f g h : ℝ → ℝ) (hg_meas : Measurable g) (hg_nonneg : ∀ x, 0 ≤ g x)
    (hhf : Integrable (fun x => h x * f x))
    (hcover : ∀ x, h x * f x ≠ 0 → 0 < g x)
    (hM₂ : Integrable (fun x => h x ^ 2 * f x ^ 2 / g x))
    (n : ℕ) (Y : Fin n → Ω → ℝ) (hY : ∀ i, Measurable (Y i))
    (hY_law : ∀ i, P.map (Y i) = volume.withDensity (fun x => ENNReal.ofReal (g x)))
    (hindep : iIndepFun Y P) :
    Var[fun ω => (1 / (n : ℝ)) * ∑ i, h (Y i ω) * (f (Y i ω) / g (Y i ω)); P] =
      ((∫ x, h x ^ 2 * f x ^ 2 / g x) - (∫ x, h x * f x) ^ 2) / n := by
  set ν := volume.withDensity (fun x => ENNReal.ofReal (g x)) with hν
  have haesm : AEStronglyMeasurable (fun x => h x * (f x / g x)) ν :=
    is_aesm f g h hg_meas hhf
  set ψ := haesm.mk _ with hψdef
  have hψm : Measurable ψ := haesm.stronglyMeasurable_mk.measurable
  have hψae : (fun x => h x * (f x / g x)) =ᵐ[ν] ψ := haesm.ae_eq_mk
  -- pull back the a.e. equality along each draw
  have hpull : ∀ i, ∀ᵐ ω ∂P, h (Y i ω) * (f (Y i ω) / g (Y i ω)) = ψ (Y i ω) := fun i => by
    have : ∀ᵐ x ∂(P.map (Y i)), h x * (f x / g x) = ψ x := by rw [hY_law i]; exact hψae
    exact ae_of_ae_map (hY i).aemeasurable this
  have hsum : (fun ω => (1 / (n : ℝ)) * ∑ i, h (Y i ω) * (f (Y i ω) / g (Y i ω)))
      =ᵐ[P] (fun ω => (1 / (n : ℝ)) * ∑ i, ψ (Y i ω)) := by
    filter_upwards [ae_all_iff.2 hpull] with ω hω
    simp_rw [hω]
  rw [variance_congr hsum, variance_const_mul]
  -- moments of ψ under ν
  have hI : ∫ x, ψ x ∂ν = ∫ x, h x * f x := by
    rw [← integral_congr_ae hψae]; exact is_integral f g h hg_meas hg_nonneg hcover
  have hsq : (fun x => (h x * (f x / g x)) ^ 2) =ᵐ[ν] (fun x => ψ x ^ 2) :=
    hψae.mono fun x hx => by
      have hx' : h x * (f x / g x) = ψ x := hx
      simp only [hx']
  have hI2 : ∫ x, ψ x ^ 2 ∂ν = ∫ x, h x ^ 2 * f x ^ 2 / g x := by
    rw [← integral_congr_ae hsq]
    exact is_integral_sq f g h hg_meas hg_nonneg hcover
  have hint2 : Integrable (fun x => ψ x ^ 2) ν :=
    (is_integrable_sq f g h hg_meas hg_nonneg hcover hM₂).congr hsq
  have hmem : ∀ i, MemLp (fun ω => ψ (Y i ω)) 2 P := fun i => by
    have hm : AEStronglyMeasurable (fun ω => ψ (Y i ω)) P :=
      (hψm.comp (hY i)).aestronglyMeasurable
    rw [memLp_two_iff_integrable_sq hm]
    have : Integrable (fun x => ψ x ^ 2) (P.map (Y i)) := by rw [hY_law i]; exact hint2
    exact this.comp_measurable (hY i)
  have hvar : ∀ i, Var[fun ω => ψ (Y i ω); P]
      = (∫ x, h x ^ 2 * f x ^ 2 / g x) - (∫ x, h x * f x) ^ 2 := fun i => by
    rw [variance_eq_sub (hmem i)]
    have e1 : P[(fun ω => ψ (Y i ω)) ^ 2] = ∫ x, ψ x ^ 2 ∂ν := by
      rw [← hY_law i, integral_map (hY i).aemeasurable
        ((hψm.pow_const 2).aestronglyMeasurable)]
      rfl
    have e2 : P[fun ω => ψ (Y i ω)] = ∫ x, ψ x ∂ν := by
      rw [← hY_law i, integral_map (hY i).aemeasurable hψm.aestronglyMeasurable]
    rw [e1, e2, hI, hI2]
  have hind : iIndepFun (fun i ω => ψ (Y i ω)) P :=
    hindep.comp (fun _ => ψ) (fun _ => hψm)
  have hfun : (fun ω => ∑ i, ψ (Y i ω)) = ∑ i ∈ (univ : Finset (Fin n)), (fun ω => ψ (Y i ω)) := by
    ext ω; simp
  rw [hfun, IndepFun.variance_sum (fun i _ => hmem i)
    (fun i _ j _ hij => hind.indepFun hij)]
  simp_rw [hvar]
  simp only [sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  · have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
    field_simp

-- The bolts' line c = 4.75 = 19/4: c²/2 = 11.28125 and c² = 22.5625, exactly.
example : ((19 : ℚ) / 4) ^ 2 / 2 = 11 + 9 / 32 := by norm_num
example : ((19 : ℚ) / 4) ^ 2 = 22 + 9 / 16 := by norm_num
-- Step 3: the ratio of two bell curves. The exponent of f(y)/g(y), with g centred on θ, is
-- −y²/2 + (y − θ)²/2 = −θy + θ²/2: the y² terms cancel.
example (y θ : ℝ) : -y ^ 2 / 2 + (y - θ) ^ 2 / 2 = -θ * y + θ ^ 2 / 2 := by ring
-- Completing the square for M₂: −x² + (x − θ)²/2 = −(x + θ)²/2 + θ².
example (x θ : ℝ) : -x ^ 2 + (x - θ) ^ 2 / 2 = -(x + θ) ^ 2 / 2 + θ ^ 2 := by ring
-- Step 4: past the line, y = c + t gives y²/2 = c²/2 + ct + t²/2.
example (c t : ℝ) : (c + t) ^ 2 / 2 = c ^ 2 / 2 + c * t + t ^ 2 / 2 := by ring
-- Drop the e^(θ²/2) and the weight on the line becomes e^(−c²) instead of e^(−c²/2):
-- the missing factor's exponent is c²/2 = 11.28125.
example : ((19 : ℚ) / 4) ^ 2 - ((19 : ℚ) / 4) ^ 2 / 2 = 361 / 32 := by norm_num
-- Thin tails: spread s = 1/2 gives the x² coefficient −1 + 1/(2s²) = 1 > 0, since s² = 1/4 < 1/2;
-- at s² = 1/2 the coefficient is exactly 0.
example : (-1 : ℚ) + 1 / (2 * (1 / 2) ^ 2) = 1 ∧ ((1 : ℚ) / 2) ^ 2 < 1 / 2 := by norm_num
example : (-1 : ℚ) + 1 / (2 * (1 / 2)) = 0 := by norm_num

#print axioms importance_sampling_reweighting_identity
#print axioms importance_sampling_estimate_unbiased
#print axioms importance_sampling_variance
