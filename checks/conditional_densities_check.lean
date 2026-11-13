-- Conditional densities: conditioning on a shrinking band of heights tends to the joint density's slice divided by its area, the slice means averaged over heights give back the overall mean, and for the tilted bell each rescaled slice is a normal bell centred on the line of averages.
import Mathlib.Probability.ConditionalProbability
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory Real Filter Topology
open scoped ENNReal

/-- The density of height alone at h: the area of the joint density's slice at h. -/
noncomputable def marginalH (f : ℝ → ℝ → ℝ) (h : ℝ) : ℝ :=
  ∫ w, f h w

/-- The conditional density of weight given height h: the slice at h divided by its area. -/
noncomputable def condDensity (f : ℝ → ℝ → ℝ) (h w : ℝ) : ℝ :=
  f h w / marginalH f h

/-- The conditional mean E[W | H = h]: each weight times its slice density, added up. -/
noncomputable def condMean (f : ℝ → ℝ → ℝ) (h : ℝ) : ℝ :=
  ∫ w, w * condDensity f h w

/-- The tilted bell of the card: centre (μH, μW), spreads σH and σW, tilt ρ.
With zh = (h - μH)/σH, zw = (w - μW)/σW and c = √(1 - ρ^2), it is
1 / (2π σH σW c) · e^(-Q/2), where Q = (zh^2 - 2ρ zh zw + zw^2) / c^2. -/
noncomputable def tiltedBell (μH μW σH σW ρ : ℝ) (h w : ℝ) : ℝ :=
  1 / (2 * π * σH * σW * √(1 - ρ ^ 2)) *
    exp (-(((h - μH) / σH) ^ 2 - 2 * ρ * ((h - μH) / σH) * ((w - μW) / σW)
      + ((w - μW) / σW) ^ 2) / (√(1 - ρ ^ 2)) ^ 2 / 2)

/-- The plain normal bell with average μ and spread σ: 1 / (σ √(2π)) · e^(-z^2/2), z = (x - μ)/σ. -/
noncomputable def normalBell (μ σ : ℝ) (x : ℝ) : ℝ :=
  1 / (σ * √(2 * π)) * exp (-((x - μ) / σ) ^ 2 / 2)

lemma map_eq_withDensity {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (H W : Ω → ℝ) (hH : Measurable H) (hW : Measurable W)
    (f : ℝ → ℝ → ℝ)
    (hjoint : ∀ S : Set (ℝ × ℝ), MeasurableSet S →
      P {ω | (H ω, W ω) ∈ S} = ∫⁻ p in S, ENNReal.ofReal (f p.1 p.2)) :
    P.map (fun ω => (H ω, W ω)) =
      (volume : Measure (ℝ × ℝ)).withDensity (fun p => ENNReal.ofReal (f p.1 p.2)) := by
  ext S hS
  rw [Measure.map_apply (hH.prodMk hW) hS, withDensity_apply _ hS]
  exact hjoint S hS

#print axioms map_eq_withDensity

lemma integral_normalBell (μ σ : ℝ) (hσ : 0 < σ) : ∫ x, normalBell μ σ x = 1 := by
  unfold normalBell
  rw [integral_const_mul]
  have h1 : ∀ x : ℝ, rexp (-((x - μ) / σ) ^ 2 / 2) = rexp (-(1 / (2 * σ ^ 2)) * (x - μ) ^ 2) := by
    intro x; congr 1; field_simp
  simp_rw [h1]
  rw [integral_sub_right_eq_self (fun x => rexp (-(1 / (2 * σ ^ 2)) * x ^ 2)) μ, integral_gaussian]
  have h2 : π / (1 / (2 * σ ^ 2)) = (σ * √(2 * π)) ^ 2 := by
    rw [mul_pow, sq_sqrt (by positivity)]; field_simp
  rw [h2, sqrt_sq (by positivity)]
  have : 0 < σ * √(2 * π) := by positivity
  field_simp

#print axioms integral_normalBell

lemma tiltedBell_eq_mul (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW)
    (hρ : |ρ| < 1) (h w : ℝ) :
    tiltedBell μH μW σH σW ρ h w =
      normalBell μH σH h * normalBell (μW + ρ * σW * ((h - μH) / σH)) (σW * √(1 - ρ ^ 2)) w := by
  have hc : 0 < 1 - ρ ^ 2 := by
    have := abs_lt.mp hρ; nlinarith
  have hs : 0 < √(1 - ρ ^ 2) := sqrt_pos.mpr hc
  have hs2 : (√(1 - ρ ^ 2)) ^ 2 = 1 - ρ ^ 2 := sq_sqrt hc.le
  unfold tiltedBell normalBell
  rw [mul_mul_mul_comm, ← exp_add]
  congr 1
  · have h2π : (√(2 * π)) ^ 2 = 2 * π := sq_sqrt (by positivity)
    have : 0 < √(2 * π) := by positivity
    field_simp
    rw [h2π]
  · congr 1
    rw [hs2]
    field_simp
    rw [hs2]
    ring

#print axioms tiltedBell_eq_mul

/-- Step 2 and its detailed proof: the conditional density is the limit of ordinary conditioning
on a thin band. Suppose height H and weight W have a joint density f (never negative; the chance
that (H, W) lands in a region is the volume under f above it), the slice at h₀ has positive area,
f is continuous near the line H = h₀, and near that line f stays below one integrable function of
the weight. Then for every range R of weights, the chance that W lies in R, given that H lies in
the band from h₀ to h₀ + δ, tends as δ shrinks to 0 to the area over R under the rescaled slice
at h₀. -/
theorem band_conditioning_tendsto_condDensity {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (H W : Ω → ℝ) (hH : Measurable H) (hW : Measurable W)
    (f : ℝ → ℝ → ℝ) (hf_nonneg : ∀ h w, 0 ≤ f h w) (hf_meas : Measurable (Function.uncurry f))
    (hjoint : ∀ S : Set (ℝ × ℝ), MeasurableSet S →
      P {ω | (H ω, W ω) ∈ S} = ∫⁻ p in S, ENNReal.ofReal (f p.1 p.2))
    (h₀ : ℝ) (hpos : 0 < marginalH f h₀)
    (hcont : ∃ ε > 0, ContinuousOn (Function.uncurry f) (Set.Ioo (h₀ - ε) (h₀ + ε) ×ˢ Set.univ))
    (hdom : ∃ G : ℝ → ℝ, Integrable G ∧ ∀ᶠ t in 𝓝 h₀, ∀ w, f t w ≤ G w)
    (R : Set ℝ) (hR : MeasurableSet R) :
    Tendsto (fun δ : ℝ => (P[|H ⁻¹' Set.Icc h₀ (h₀ + δ)] (W ⁻¹' R)).toReal) (𝓝[>] 0)
      (𝓝 (∫ w in R, condDensity f h₀ w)) := by
  obtain ⟨ε₁, hε₁, hcont⟩ := hcont
  obtain ⟨G, hG, hdom⟩ := hdom
  obtain ⟨ε₂, hε₂, hdom⟩ := Metric.eventually_nhds_iff.mp hdom
  set ε := min ε₁ ε₂ with hε
  have hεpos : 0 < ε := lt_min hε₁ hε₂
  set I := Set.Ioo (h₀ - ε) (h₀ + ε) with hI
  have hIo : IsOpen I := isOpen_Ioo
  have h₀I : h₀ ∈ I := ⟨by linarith, by linarith⟩
  have hIdom : ∀ t ∈ I, ∀ w, f t w ≤ G w := by
    intro t ht
    apply hdom
    rw [Real.dist_eq, abs_lt]
    have := min_le_right ε₁ ε₂
    constructor <;> linarith [ht.1, ht.2]
  have hIcont : ∀ w, ContinuousOn (fun t => f t w) I := by
    intro w
    have hsub : I ⊆ Set.Ioo (h₀ - ε₁) (h₀ + ε₁) := by
      intro t ht
      have := min_le_left ε₁ ε₂
      exact ⟨by linarith [ht.1], by linarith [ht.2]⟩
    have : (fun t => f t w) = Function.uncurry f ∘ fun t => (t, w) := rfl
    rw [this]
    refine hcont.comp (Continuous.continuousOn (by fun_prop)) ?_
    intro t ht
    exact ⟨hsub ht, Set.mem_univ _⟩
  have hfm : ∀ t, Measurable (fun w => f t w) := fun t =>
    hf_meas.comp (measurable_const.prodMk measurable_id)
  have hint : ∀ t ∈ I, Integrable (fun w => f t w) := by
    intro t ht
    refine hG.mono' (hfm t).aestronglyMeasurable (Eventually.of_forall fun w => ?_)
    rw [Real.norm_eq_abs, abs_of_nonneg (hf_nonneg t w)]
    exact hIdom t ht w
  set g : Set ℝ → ℝ → ℝ := fun B t => ∫ w in B, f t w with hg
  have hgcont : ∀ B, ContinuousOn (g B) I := by
    intro B
    refine continuousOn_of_dominated (bound := G) (fun t _ => (hfm t).aestronglyMeasurable)
      (fun t ht => Eventually.of_forall fun w => ?_) hG.integrableOn
      (Eventually.of_forall fun w => hIcont w)
    rw [Real.norm_eq_abs, abs_of_nonneg (hf_nonneg t w)]
    exact hIdom t ht w
  have hgnn : ∀ B t, 0 ≤ g B t := fun B t => integral_nonneg (fun w => hf_nonneg t w)
  have hIcc : ∀ δ, 0 < δ → δ < ε → Set.Icc h₀ (h₀ + δ) ⊆ I := by
    intro δ hδ hδε t ht
    exact ⟨by linarith [ht.1], by linarith [ht.2]⟩
  have hprob : ∀ B, MeasurableSet B → ∀ δ, 0 < δ → δ < ε →
      P (H ⁻¹' Set.Icc h₀ (h₀ + δ) ∩ W ⁻¹' B) = ENNReal.ofReal (∫ t in h₀..h₀ + δ, g B t) := by
    intro B hB δ hδ hδε
    have hset : H ⁻¹' Set.Icc h₀ (h₀ + δ) ∩ W ⁻¹' B = {ω | (H ω, W ω) ∈ Set.Icc h₀ (h₀ + δ) ×ˢ B} := by
      ext ω; simp
    rw [hset, hjoint _ (measurableSet_Icc.prod hB), Measure.volume_eq_prod,
      setLIntegral_prod (fun p : ℝ × ℝ => ENNReal.ofReal (f p.1 p.2))
        (hf_meas.ennreal_ofReal.aemeasurable)]
    rw [setLIntegral_congr_fun measurableSet_Icc (g := fun t => ENNReal.ofReal (g B t))
      (fun t ht => (ofReal_integral_eq_lintegral_ofReal (hint t (hIcc δ hδ hδε ht)).integrableOn
        (Eventually.of_forall fun w => hf_nonneg t w)).symm)]
    rw [← ofReal_integral_eq_lintegral_ofReal
      (((hgcont B).mono (hIcc δ hδ hδε)).integrableOn_compact isCompact_Icc)
      (Eventually.of_forall fun t => hgnn B t)]
    rw [intervalIntegral.integral_of_le (by linarith), integral_Icc_eq_integral_Ioc]
  have hderiv : ∀ B, Tendsto (fun δ => δ⁻¹ * ∫ t in h₀..h₀ + δ, g B t) (𝓝[>] 0) (𝓝 (g B h₀)) := by
    intro B
    have hd : HasDerivAt (fun u => ∫ t in h₀..u, g B t) (g B h₀) h₀ :=
      intervalIntegral.integral_hasDerivAt_right (IntervalIntegrable.refl)
        ((hgcont B).stronglyMeasurableAtFilter hIo h₀ h₀I)
        ((hgcont B).continuousAt (hIo.mem_nhds h₀I))
    have := hd.tendsto_slope_zero_right
    simpa [intervalIntegral.integral_same, smul_eq_mul] using this
  have hgU : g Set.univ h₀ = marginalH f h₀ := by
    simp [hg, marginalH]
  have hlim := (hderiv R).div (hderiv Set.univ) (by rw [hgU]; exact hpos.ne')
  have htarget : ∫ w in R, condDensity f h₀ w = g R h₀ / g Set.univ h₀ := by
    rw [hgU]; unfold condDensity; rw [integral_div]
  rw [htarget]
  refine hlim.congr' ?_
  filter_upwards [Ioo_mem_nhdsGT hεpos] with δ hδ
  obtain ⟨hδ0, hδε⟩ := hδ
  have hA : MeasurableSet (H ⁻¹' Set.Icc h₀ (h₀ + δ)) := hH measurableSet_Icc
  rw [cond_apply hA, ENNReal.toReal_mul, ENNReal.toReal_inv]
  have hU : H ⁻¹' Set.Icc h₀ (h₀ + δ) = H ⁻¹' Set.Icc h₀ (h₀ + δ) ∩ W ⁻¹' Set.univ := by simp
  rw [hprob R hR δ hδ0 hδε]
  rw [hU, hprob Set.univ MeasurableSet.univ δ hδ0 hδε]
  rw [ENNReal.toReal_ofReal (intervalIntegral.integral_nonneg (by linarith) fun t _ => hgnn _ t),
    ENNReal.toReal_ofReal (intervalIntegral.integral_nonneg (by linarith) fun t _ => hgnn _ t)]
  simp only [Pi.div_apply]
  rw [mul_div_mul_left _ _ (inv_ne_zero hδ0.ne'), div_eq_inv_mul]

/-- Step 5: the slices put back together give the whole. If (H, W) has joint density f and the
mean of W exists, then the slice means E[W | H = h], weighted by how common each height is,
average back to the overall mean E[W] (the tower rule with integrals in place of sums). -/
theorem integral_condMean_mul_marginalH {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (H W : Ω → ℝ) (hH : Measurable H) (hW : Measurable W)
    (f : ℝ → ℝ → ℝ) (hf_nonneg : ∀ h w, 0 ≤ f h w) (hf_meas : Measurable (Function.uncurry f))
    (hjoint : ∀ S : Set (ℝ × ℝ), MeasurableSet S →
      P {ω | (H ω, W ω) ∈ S} = ∫⁻ p in S, ENNReal.ofReal (f p.1 p.2))
    (hmean : Integrable W P) :
    ∫ h, condMean f h * marginalH f h = ∫ ω, W ω ∂P := by
  have hmap := map_eq_withDensity P H W hH hW f hjoint
  set g : ℝ × ℝ → NNReal := fun p => (f p.1 p.2).toNNReal with hg
  have hgm : Measurable g := hf_meas.real_toNNReal
  have hdens : (fun p : ℝ × ℝ => ENNReal.ofReal (f p.1 p.2)) = fun p => (g p : ℝ≥0∞) := rfl
  have hWeq : ∫ ω, W ω ∂P = ∫ p : ℝ × ℝ, f p.1 p.2 * p.2 := by
    have : ∫ ω, W ω ∂P = ∫ p, p.2 ∂(P.map (fun ω => (H ω, W ω))) := by
      rw [integral_map (hH.prodMk hW).aemeasurable measurable_snd.aestronglyMeasurable]
    rw [this, hmap, hdens, integral_withDensity_eq_integral_smul hgm]
    congr 1; ext p
    simp [hg, smul_eq_mul, NNReal.smul_def, Real.coe_toNNReal _ (hf_nonneg _ _)]
  -- integrability of p.2 * f
  have hint2 : Integrable (fun p : ℝ × ℝ => f p.1 p.2 * p.2) (volume.prod volume) := by
    have h1 : Integrable (fun p : ℝ × ℝ => p.2) (P.map (fun ω => (H ω, W ω))) := by
      rw [integrable_map_measure measurable_snd.aestronglyMeasurable
        (hH.prodMk hW).aemeasurable]
      exact hmean
    rw [hmap, hdens, integrable_withDensity_iff_integrable_smul hgm] at h1
    rw [← Measure.volume_eq_prod]
    refine h1.congr (Eventually.of_forall fun p => ?_)
    simp [hg, smul_eq_mul, NNReal.smul_def, Real.coe_toNNReal _ (hf_nonneg _ _)]
  -- integrability of f
  have hint1 : Integrable (Function.uncurry f) (volume.prod volume) := by
    have hP : P.map (fun ω => (H ω, W ω)) Set.univ = 1 := by
      rw [Measure.map_apply (hH.prodMk hW) MeasurableSet.univ]; simp
    rw [hmap, withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ] at hP
    refine ⟨hf_meas.aestronglyMeasurable, ?_⟩
    have hnn : 0 ≤ᵐ[volume.prod volume] Function.uncurry f :=
      Eventually.of_forall fun (p : ℝ × ℝ) => hf_nonneg p.1 p.2
    rw [hasFiniteIntegral_iff_ofReal hnn, ← Measure.volume_eq_prod]
    have : (fun p : ℝ × ℝ => ENNReal.ofReal (Function.uncurry f p)) =
        fun p => ENNReal.ofReal (f p.1 p.2) := rfl
    rw [this, hP]; exact ENNReal.one_lt_top
  rw [hWeq, Measure.volume_eq_prod, integral_prod _ hint2]
  refine integral_congr_ae ?_
  filter_upwards [hint1.prod_right_ae] with h hh
  simp only [Function.uncurry_apply_pair] at hh
  unfold condMean condDensity
  by_cases hm : marginalH f h = 0
  · rw [hm, mul_zero]
    have hz : (fun w => f h w) =ᵐ[volume] 0 := by
      unfold marginalH at hm
      exact (integral_eq_zero_iff_of_nonneg (fun w => hf_nonneg h w) hh).mp hm
    symm
    refine integral_eq_zero_of_ae ?_
    filter_upwards [hz] with w hw
    simp only [Pi.zero_apply] at hw ⊢
    rw [hw, zero_mul]
  · have : (fun w => w * (f h w / marginalH f h)) = fun w => (f h w * w) / marginalH f h := by
      ext w; ring
    rw [this, integral_div, div_mul_cancel₀ _ hm]

/-- Steps 3 and 4: for the tilted bell, the slice at height h divided by its area is a normal
bell in weight, centred at μW + ρ σW (h - μH)/σH (the line of averages: ρ times as many weight
spreads out as the height is height spreads out) with spread σW √(1 - ρ^2). -/
theorem condDensity_tiltedBell (μH μW σH σW ρ : ℝ) (hσH : 0 < σH) (hσW : 0 < σW)
    (hρ : |ρ| < 1) (h w : ℝ) :
    condDensity (tiltedBell μH μW σH σW ρ) h w =
      normalBell (μW + ρ * σW * ((h - μH) / σH)) (σW * √(1 - ρ ^ 2)) w := by
  have hc : 0 < 1 - ρ ^ 2 := by
    have := abs_lt.mp hρ; nlinarith
  have hpos : 0 < normalBell μH σH h := by unfold normalBell; positivity
  unfold condDensity marginalH
  simp_rw [tiltedBell_eq_mul μH μW σH σW ρ hσH hσW hρ h]
  rw [integral_const_mul, integral_normalBell _ _ (by positivity), mul_one]
  field_simp

-- The card's exact numbers. Height 180 cm is 5/7 of a height spread above 175 cm.
example : ((180 : ℚ) - 175) / 7 = 5 / 7 := by norm_num
-- Slice centre at 180 cm: 78 + 12 × 0.5 × 5/7 = 576/7 kg (82.2857 kg).
example : (78 : ℚ) + 12 * (1 / 2) * (5 / 7) = 576 / 7 := by norm_num
-- Slice spread squared: 12^2 × (1 - 0.5^2) = 108, so the spread is √108 (10.3923 kg).
example : (12 : ℚ) ^ 2 * (1 - (1 / 2) ^ 2) = 108 := by norm_num
-- The line of averages 78 + (6/7)(h - 175) at 161, 168, 175, 182 and 189 cm.
example : (78 : ℚ) + 6 / 7 * (161 - 175) = 66 ∧ (78 : ℚ) + 6 / 7 * (168 - 175) = 72 ∧
    (78 : ℚ) + 6 / 7 * (175 - 175) = 78 ∧ (78 : ℚ) + 6 / 7 * (182 - 175) = 84 ∧
    (78 : ℚ) + 6 / 7 * (189 - 175) = 90 := by norm_num
-- The line's slope is ρ σW / σH = 0.5 × 12 / 7 = 6/7 kg per cm.
example : (1 / 2 : ℚ) * 12 / 7 = 6 / 7 := by norm_num
-- The spread line at 180 cm: 78 + 12 × 5/7 = 606/7 kg (86.571 kg).
example : (78 : ℚ) + 12 * (5 / 7) = 606 / 7 := by norm_num
-- Reverse slice at 90 kg, one weight spread up: 175 + 7 × 0.5 × 1 = 178.5 cm.
example : (175 : ℚ) + 7 * (1 / 2) * ((90 - 78) / 12) = 357 / 2 := by norm_num
-- The line of averages run backwards from 90 kg: 175 + (7/6)(90 - 78) = 189 cm.
example : (175 : ℚ) + 7 / 6 * (90 - 78) = 189 := by norm_num

#print axioms band_conditioning_tendsto_condDensity
#print axioms integral_condMean_mul_marginalH
#print axioms condDensity_tiltedBell
