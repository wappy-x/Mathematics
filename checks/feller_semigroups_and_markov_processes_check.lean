-- Feller semigroups: the averaging maps of a drifting share price are positive, stack in time, keep payoffs in C₀ and move continuously in the sup norm, their generator is drift times slope plus half the squared volatility times curvature, and the expected payoff solves the backward equation.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Topology.ContinuousMap.ZeroAtInfty
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Shift

open MeasureTheory ProbabilityTheory Filter Topology ZeroAtInfty

/-- The averaging operator of the drifting price `X_t = x + μ t + σ W_t`:
`P_t f(x) = E[f(x + μ t + σ √t Z)]`, with `Z` a standard normal draw. -/
noncomputable def fellerP (μ σ t : ℝ) (f : ℝ → ℝ) (x : ℝ) : ℝ :=
  ∫ z, f (x + μ * t + σ * Real.sqrt t * z) ∂(gaussianReal 0 1)

lemma feller_integrable_of_bdd (ν : Measure ℝ) [IsFiniteMeasure ν] (F : ℝ → ℝ)
    (hF : Continuous F) (M : ℝ) (hM : ∀ w, |F w| ≤ M) : Integrable F ν :=
  Integrable.mono' (integrable_const M) hF.aestronglyMeasurable
    (ae_of_all _ fun w => by simpa [Real.norm_eq_abs] using hM w)

lemma feller_integrable (g : ℝ → ℝ) (hg : Continuous g) (M : ℝ) (hM : ∀ y, |g y| ≤ M)
    (a b : ℝ) : Integrable (fun z => g (a + b * z)) (gaussianReal 0 1) :=
  feller_integrable_of_bdd _ _ (hg.comp (by fun_prop)) M (fun _ => hM _)

lemma feller_abs_le (g : ℝ → ℝ) (M : ℝ) (hM : ∀ y, |g y| ≤ M) (μ σ t x : ℝ) :
    |fellerP μ σ t g x| ≤ M := by
  have := norm_integral_le_of_norm_le_const (μ := gaussianReal 0 1)
    (f := fun z => g (x + μ * t + σ * Real.sqrt t * z)) (C := M)
    (ae_of_all _ (fun z => by simpa [Real.norm_eq_abs] using hM _))
  simpa [fellerP, Real.norm_eq_abs] using this

lemma feller_cont_param (g : ℝ → ℝ) (hg : Continuous g) (M : ℝ)
    (hM : ∀ y, |g y| ≤ M) (a b : ℝ → ℝ) (ha : Continuous a) (hb : Continuous b) :
    Continuous (fun p => ∫ z, g (a p + b p * z) ∂(gaussianReal 0 1)) := by
  refine continuous_of_dominated (bound := fun _ => M) (fun p => ?_)
    (fun p => ae_of_all _ (fun z => ?_)) (integrable_const M) (ae_of_all _ (fun z => ?_))
  · exact (hg.comp (by fun_prop)).aestronglyMeasurable
  · simpa [Real.norm_eq_abs] using hM _
  · exact hg.comp (by fun_prop)

lemma feller_cont_x (g : ℝ → ℝ) (hg : Continuous g) (M : ℝ) (hM : ∀ y, |g y| ≤ M)
    (μ σ t : ℝ) : Continuous (fellerP μ σ t g) :=
  feller_cont_param g hg M hM (fun x => x + μ * t) (fun _ => σ * Real.sqrt t)
    (by fun_prop) (by fun_prop)

lemma feller_cont_t (g : ℝ → ℝ) (hg : Continuous g) (M : ℝ) (hM : ∀ y, |g y| ≤ M)
    (μ σ x : ℝ) : Continuous (fun s => fellerP μ σ s g x) :=
  feller_cont_param g hg M hM (fun s => x + μ * s) (fun s => σ * Real.sqrt s)
    (by fun_prop) (by fun_prop)

noncomputable def fellerVar (σ t : ℝ) : NNReal := Real.toNNReal ((σ * Real.sqrt t) ^ 2)

lemma fellerP_eq_gauss (g : ℝ → ℝ) (hg : Continuous g) (μ σ t x : ℝ) :
    fellerP μ σ t g x = ∫ w, g (x + μ * t + w) ∂(gaussianReal 0 (fellerVar σ t)) := by
  have hmap : (gaussianReal 0 1).map (fun z => σ * Real.sqrt t * z) =
      gaussianReal 0 (fellerVar σ t) := by
    rw [gaussianReal_map_const_mul, gaussianReal_ext_iff]
    refine ⟨by simp, ?_⟩
    ext
    simp [fellerVar, Real.coe_toNNReal _ (sq_nonneg _)]
  rw [← hmap, integral_map (f := fun w => g (x + μ * t + w)) (by fun_prop)
    (hg.comp (by fun_prop)).aestronglyMeasurable]
  rfl

lemma fellerP_semigroup (g : ℝ → ℝ) (hg : Continuous g) (M : ℝ) (hM : ∀ y, |g y| ≤ M)
    (μ σ s t : ℝ) (hs : 0 ≤ s) (ht : 0 ≤ t) :
    fellerP μ σ (s + t) g = fellerP μ σ s (fellerP μ σ t g) := by
  funext x
  have hcont : Continuous (fellerP μ σ t g) := feller_cont_x g hg M hM μ σ t
  rw [fellerP_eq_gauss _ hg, fellerP_eq_gauss _ hcont]
  have hv : fellerVar σ (s + t) = fellerVar σ s + fellerVar σ t := by
    ext
    simp only [fellerVar, NNReal.coe_add, mul_pow,
      Real.sq_sqrt hs, Real.sq_sqrt ht, Real.sq_sqrt (add_nonneg hs ht)]
    rw [Real.coe_toNNReal _ (by positivity), Real.coe_toNNReal _ (by positivity),
      Real.coe_toNNReal _ (by positivity)]
    ring
  have hc := gaussianReal_conv_gaussianReal (m₁ := 0) (m₂ := 0)
    (v₁ := fellerVar σ s) (v₂ := fellerVar σ t)
  rw [zero_add] at hc
  rw [hv, ← hc, integral_conv]
  · congr 1
    funext w1
    rw [fellerP_eq_gauss _ hg]
    congr 1
    funext w2
    congr 1
    ring
  · rw [hc]
    exact feller_integrable_of_bdd _ _ (hg.comp (by fun_prop)) M (fun _ => hM _)

lemma gauss_int_z : ∫ z, z ∂(gaussianReal 0 1) = 0 := by
  simp

lemma gauss_integrable_z : Integrable (fun z : ℝ => z) (gaussianReal 0 1) :=
  (memLp_id_gaussianReal 1).integrable le_rfl

lemma gauss_integrable_z2 : Integrable (fun z : ℝ => z ^ 2) (gaussianReal 0 1) :=
  (memLp_id_gaussianReal 2).integrable_sq

lemma gauss_integrable_z4 : Integrable (fun z : ℝ => z ^ 4) (gaussianReal 0 1) := by
  have h := (memLp_id_gaussianReal' (μ := 0) (v := 1) 4 (by norm_num)).integrable_norm_pow'
    (p := 4)
  simpa [Real.norm_eq_abs, Even.pow_abs (by decide : Even 4)] using h

lemma gauss_int_z2 : ∫ z, z ^ 2 ∂(gaussianReal 0 1) = 1 := by
  have h := variance_eq_sub (μ := gaussianReal 0 1) (memLp_id_gaussianReal 2)
  simp only [variance_id_gaussianReal] at h
  have h0 : ∫ z, id z ∂(gaussianReal 0 1) = 0 := gauss_int_z
  simp only [h0] at h
  simp only [Pi.pow_apply, id, NNReal.coe_one] at h
  norm_num at h
  linarith

lemma gauss_int_lin (a b : ℝ) : ∫ z, (a + b * z) ∂(gaussianReal 0 1) = a := by
  rw [integral_add (integrable_const _) (gauss_integrable_z.const_mul b), integral_const,
    integral_const_mul, gauss_int_z]
  simp

lemma gauss_int_sq (a b : ℝ) : ∫ z, (a + b * z) ^ 2 ∂(gaussianReal 0 1) = a ^ 2 + b ^ 2 := by
  have : (fun z : ℝ => (a + b * z) ^ 2) = fun z => (a ^ 2 + (2 * a * b) * z) + b ^ 2 * z ^ 2 := by
    funext z; ring
  rw [this]
  have h1 : ∫ z, ((a ^ 2 + (2 * a * b) * z) + b ^ 2 * z ^ 2) ∂(gaussianReal 0 1) =
      ∫ z, (a ^ 2 + (2 * a * b) * z) ∂(gaussianReal 0 1) +
        ∫ z, b ^ 2 * z ^ 2 ∂(gaussianReal 0 1) :=
    integral_add ((integrable_const _).add (gauss_integrable_z.const_mul _))
      (gauss_integrable_z2.const_mul _)
  rw [h1, gauss_int_lin, integral_const_mul, gauss_int_z2, mul_one]

lemma feller_bdd_of_tendsto (g : ℝ → ℝ) (hg : Continuous g)
    (h : Tendsto g (cocompact ℝ) (𝓝 0)) : ∃ M, ∀ y, |g y| ≤ M := by
  let G : C₀(ℝ, ℝ) := ⟨⟨g, hg⟩, h⟩
  refine ⟨‖G.toBCF‖, fun y => ?_⟩
  have := G.toBCF.norm_coe_le_norm y
  rw [Real.norm_eq_abs] at this
  exact this

lemma feller_bdd (f : C₀(ℝ, ℝ)) : ∃ M, ∀ y, |f y| ≤ M :=
  feller_bdd_of_tendsto f (map_continuous f) (zero_at_infty f)

lemma feller_tendsto_zero (f : C₀(ℝ, ℝ)) (μ σ t : ℝ) :
    Tendsto (fellerP μ σ t f) (cocompact ℝ) (𝓝 0) := by
  obtain ⟨M, hM⟩ := feller_bdd f
  have : (cocompact ℝ).IsCountablyGenerated := by
    rw [cocompact_eq_atBot_atTop]; infer_instance
  have h := tendsto_integral_filter_of_dominated_convergence (μ := gaussianReal 0 1)
    (l := cocompact ℝ) (F := fun x z => (f : ℝ → ℝ) (x + μ * t + σ * Real.sqrt t * z))
    (f := fun _ => (0 : ℝ)) (fun _ => M)
    (Eventually.of_forall fun x => ((map_continuous f).comp (by fun_prop)).aestronglyMeasurable)
    (Eventually.of_forall fun x => ae_of_all _ fun z => by
      simpa [Real.norm_eq_abs] using hM _)
    (integrable_const M) (ae_of_all _ fun z => ?_)
  · simp only [integral_zero] at h
    exact h
  · have h1 : Tendsto (fun x : ℝ => x + μ * t + σ * Real.sqrt t * z) (cocompact ℝ)
        (cocompact ℝ) := by
      have := (Homeomorph.addRight (μ * t + σ * Real.sqrt t * z)).isClosedEmbedding.tendsto_cocompact
      refine this.congr (fun x => ?_)
      simp [add_assoc]
    exact (zero_at_infty f).comp h1

lemma feller_taylor2 (F F1 F2 : ℝ → ℝ) (h1 : ∀ y, HasDerivAt F (F1 y) y)
    (h2 : ∀ y, HasDerivAt F1 (F2 y) y) (x y K : ℝ)
    (hK : ∀ u, |u| ≤ |y| → |F2 (x + u) - F2 x| ≤ K) :
    |F (x + y) - F x - F1 x * y - F2 x / 2 * y ^ 2| ≤ K * y ^ 2 := by
  have hK0 : 0 ≤ K := by simpa using hK 0 (by simp)
  set s := Metric.closedBall (0 : ℝ) |y| with hs_def
  have hs : Convex ℝ s := convex_closedBall _ _
  have h0 : (0 : ℝ) ∈ s := Metric.mem_closedBall_self (abs_nonneg _)
  have hys : y ∈ s := by simp [s]
  have hmem : ∀ u ∈ s, |u| ≤ |y| := fun u hu => by simpa [s] using hu
  let G1 : ℝ → ℝ := fun u => F1 (x + u) - F1 x - F2 x * u
  have hG1 : ∀ u, HasDerivAt G1 (F2 (x + u) - F2 x) u := by
    intro u
    have ha : HasDerivAt (fun u => F1 (x + u)) (F2 (x + u)) u :=
      HasDerivAt.comp_const_add x u (h2 (x + u))
    have := (ha.sub_const (F1 x)).sub ((hasDerivAt_id' u).const_mul (F2 x))
    convert this using 1
    ring
  have bG1 : ∀ u ∈ s, |G1 u| ≤ K * |u| := by
    intro u hu
    have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := G1)
      (fun v _ => (hG1 v).hasDerivWithinAt)
      (fun v hv => by simpa [Real.norm_eq_abs] using hK v (hmem v hv)) hs h0 hu
    simpa [G1, Real.norm_eq_abs] using this
  let G : ℝ → ℝ := fun u => F (x + u) - F x - F1 x * u - F2 x / 2 * u ^ 2
  have hG : ∀ u, HasDerivAt G (G1 u) u := by
    intro u
    have ha : HasDerivAt (fun u => F (x + u)) (F1 (x + u)) u :=
      HasDerivAt.comp_const_add x u (h1 (x + u))
    have := ((ha.sub_const (F x)).sub ((hasDerivAt_id' u).const_mul (F1 x))).sub
      ((hasDerivAt_pow 2 u).const_mul (F2 x / 2))
    convert this using 1
    simp only [G1]
    push_cast
    ring
  have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := G) (C := K * |y|)
    (fun v _ => (hG v).hasDerivWithinAt)
    (fun v hv => by
      rw [Real.norm_eq_abs]
      exact (bG1 v hv).trans (mul_le_mul_of_nonneg_left (hmem v hv) hK0)) hs h0 hys
  simp only [G, Real.norm_eq_abs] at this
  simpa [mul_assoc, ← sq, sq_abs] using this

lemma fellerP_hasDerivAt (g g' : ℝ → ℝ) (hd : ∀ y, HasDerivAt g (g' y) y)
    (hc' : Continuous g') (M' : ℝ) (hM' : ∀ y, |g' y| ≤ M') (hc : Continuous g) (M : ℝ)
    (hM : ∀ y, |g y| ≤ M) (μ σ t x : ℝ) :
    HasDerivAt (fellerP μ σ t g) (fellerP μ σ t g' x) x := by
  have := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := gaussianReal 0 1)
    (F := fun y z => g (y + μ * t + σ * Real.sqrt t * z))
    (F' := fun y z => g' (y + μ * t + σ * Real.sqrt t * z)) (x₀ := x)
    (bound := fun _ => M') (s := Set.univ) Filter.univ_mem
    (Eventually.of_forall fun y => (hc.comp (by fun_prop)).aestronglyMeasurable)
    (feller_integrable g hc M hM (x + μ * t) (σ * Real.sqrt t))
    ((hc'.comp (by fun_prop)).aestronglyMeasurable)
    (ae_of_all _ fun z y _ => by simpa [Real.norm_eq_abs] using hM' _) (integrable_const M')
    (ae_of_all _ fun z y _ => by
      have := HasDerivAt.comp_add_const y (μ * t + σ * Real.sqrt t * z)
        (hd (y + (μ * t + σ * Real.sqrt t * z)))
      simp only [← add_assoc] at this
      exact this)
  exact this.2

lemma feller_lin (g1 g2 g3 : ℝ → ℝ) (h1 : Continuous g1) (h2 : Continuous g2)
    (h3 : Continuous g3) (M1 M2 M3 : ℝ) (b1 : ∀ y, |g1 y| ≤ M1) (b2 : ∀ y, |g2 y| ≤ M2)
    (b3 : ∀ y, |g3 y| ≤ M3) (μ σ s x h : ℝ) :
    (fellerP μ σ s g1 x - fellerP μ σ s g2 x) / h - fellerP μ σ s g3 x =
      fellerP μ σ s (fun y => (g1 y - g2 y) / h - g3 y) x := by
  have i1 := feller_integrable g1 h1 M1 b1 (x + μ * s) (σ * Real.sqrt s)
  have i2 := feller_integrable g2 h2 M2 b2 (x + μ * s) (σ * Real.sqrt s)
  have i3 := feller_integrable g3 h3 M3 b3 (x + μ * s) (σ * Real.sqrt s)
  have e1 := integral_sub (μ := gaussianReal 0 1)
    (f := fun z => (g1 (x + μ * s + σ * Real.sqrt s * z) - g2 (x + μ * s + σ * Real.sqrt s * z)) / h)
    (g := fun z => g3 (x + μ * s + σ * Real.sqrt s * z)) ((i1.sub i2).div_const h) i3
  have e3 := integral_sub (μ := gaussianReal 0 1)
    (f := fun z => g1 (x + μ * s + σ * Real.sqrt s * z))
    (g := fun z => g2 (x + μ * s + σ * Real.sqrt s * z)) i1 i2
  simp only [fellerP]
  rw [e1, integral_div, e3]

/-- The averaging maps of the drifting price form a Feller semigroup on `C₀(ℝ)`:
a payoff between 0 and 1 stays between 0 and 1 (positive and sub-Markov);
`P_0 f = f` and `P_{s+t} f = P_s (P_t f)` (semigroup); `P_t f` is again continuous and
vanishes far out (Feller); and `P_h f → f` uniformly in the price as `h → 0`
(strongly continuous in the sup norm). -/
theorem drifting_price_semigroup_is_feller (μ σ : ℝ) :
    (∀ (f : C₀(ℝ, ℝ)) (t : ℝ), 0 ≤ t → (∀ y, 0 ≤ f y ∧ f y ≤ 1) →
        ∀ x, 0 ≤ fellerP μ σ t f x ∧ fellerP μ σ t f x ≤ 1) ∧
    (∀ f : C₀(ℝ, ℝ), fellerP μ σ 0 f = f) ∧
    (∀ (f : C₀(ℝ, ℝ)) (s t : ℝ), 0 ≤ s → 0 ≤ t →
        fellerP μ σ (s + t) f = fellerP μ σ s (fellerP μ σ t f)) ∧
    (∀ (f : C₀(ℝ, ℝ)) (t : ℝ), 0 ≤ t → ∃ g : C₀(ℝ, ℝ), ⇑g = fellerP μ σ t f) ∧
    (∀ f : C₀(ℝ, ℝ), TendstoUniformly (fun h => fellerP μ σ h f) f (𝓝[≥] 0)) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro f t _ hf x
    obtain ⟨M, hM⟩ := feller_bdd f
    have hi := feller_integrable f (map_continuous f) M hM (x + μ * t) (σ * Real.sqrt t)
    refine ⟨integral_nonneg fun z => (hf _).1, ?_⟩
    have := integral_mono hi (integrable_const (1 : ℝ) (μ := gaussianReal 0 1))
      (fun z => (hf _).2)
    simpa [fellerP] using this
  · intro f
    funext x
    simp [fellerP]
  · intro f s t hs ht
    obtain ⟨M, hM⟩ := feller_bdd f
    exact fellerP_semigroup f (map_continuous f) M hM μ σ s t hs ht
  · intro f t _
    obtain ⟨M, hM⟩ := feller_bdd f
    exact ⟨⟨⟨fellerP μ σ t f, feller_cont_x f (map_continuous f) M hM μ σ t⟩,
      feller_tendsto_zero f μ σ t⟩, rfl⟩
  · intro f
    rw [Metric.tendstoUniformly_iff]
    intro ε hε
    obtain ⟨M, hM⟩ := feller_bdd f
    have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
    obtain ⟨δ, hδ, hδf⟩ := Metric.uniformContinuous_iff.1
      (ZeroAtInftyContinuousMap.uniformContinuous f) (ε / 2) (by positivity)
    set K := 2 * M / δ ^ 2 with hK
    have hK0 : 0 ≤ K := by positivity
    have key : ∀ x y, |f (x + y) - f x| ≤ ε / 2 + K * y ^ 2 := by
      intro x y
      by_cases hy : |y| < δ
      · have h1 := hδf (a := x + y) (b := x) (by simpa [Real.dist_eq] using hy)
        rw [Real.dist_eq] at h1
        have : 0 ≤ K * y ^ 2 := by positivity
        linarith
      · replace hy := not_lt.1 hy
        have h1 : 1 ≤ y ^ 2 / δ ^ 2 := by
          rw [le_div_iff₀ (by positivity), one_mul, ← sq_abs y]
          exact pow_le_pow_left₀ hδ.le hy 2
        have h2 : |f (x + y) - f x| ≤ 2 * M := by
          have := abs_sub (f (x + y)) (f x)
          linarith [hM (x + y), hM x]
        have h3 : K * y ^ 2 = 2 * M * (y ^ 2 / δ ^ 2) := by rw [hK]; ring
        have h4 : 2 * M * 1 ≤ 2 * M * (y ^ 2 / δ ^ 2) :=
          mul_le_mul_of_nonneg_left h1 (by positivity)
        linarith
    have hcont : Tendsto (fun h : ℝ => K * ((μ * h) ^ 2 + σ ^ 2 * h)) (𝓝 0) (𝓝 0) := by
      have : Continuous (fun h : ℝ => K * ((μ * h) ^ 2 + σ ^ 2 * h)) := by fun_prop
      simpa using this.tendsto 0
    have e1 : ∀ᶠ h in 𝓝[≥] (0 : ℝ), K * ((μ * h) ^ 2 + σ ^ 2 * h) < ε / 2 :=
      nhdsWithin_le_nhds (hcont.eventually (gt_mem_nhds (by positivity)))
    have hev : ∀ᶠ h in 𝓝[≥] (0 : ℝ), K * ((μ * h) ^ 2 + σ ^ 2 * h) < ε / 2 ∧ 0 ≤ h :=
      e1.and self_mem_nhdsWithin
    filter_upwards [hev] with h ⟨hh, h0⟩ x
    rw [Real.dist_eq]
    have hint := feller_integrable f (map_continuous f) M hM (x + μ * h) (σ * Real.sqrt h)
    have heq : fellerP μ σ h f x - f x =
        ∫ z, (f (x + (μ * h + σ * Real.sqrt h * z)) - f x) ∂(gaussianReal 0 1) := by
      rw [integral_sub _ (integrable_const _), integral_const]
      · simp only [fellerP, probReal_univ, one_smul]
        congr 2
        funext z
        congr 1
        ring
      · refine hint.congr (ae_of_all _ fun z => ?_)
        simp only
        congr 1
        ring
    have hbint : Integrable (fun z => ε / 2 + K * (μ * h + σ * Real.sqrt h * z) ^ 2)
        (gaussianReal 0 1) := by
      have : Integrable (fun z : ℝ => (μ * h + σ * Real.sqrt h * z) ^ 2) (gaussianReal 0 1) := by
        have e : (fun z : ℝ => (μ * h + σ * Real.sqrt h * z) ^ 2) =
            fun z => ((μ * h) ^ 2 + (2 * (μ * h) * (σ * Real.sqrt h)) * z) +
              (σ * Real.sqrt h) ^ 2 * z ^ 2 := by funext z; ring
        rw [e]
        exact ((integrable_const _).add (gauss_integrable_z.const_mul _)).add
          (gauss_integrable_z2.const_mul _)
      exact (integrable_const _).add (this.const_mul K)
    rw [abs_sub_comm, heq]
    calc |∫ z, (f (x + (μ * h + σ * Real.sqrt h * z)) - f x) ∂(gaussianReal 0 1)|
        ≤ ∫ z, (ε / 2 + K * (μ * h + σ * Real.sqrt h * z) ^ 2) ∂(gaussianReal 0 1) := by
          have := norm_integral_le_of_norm_le
            (f := fun z => f (x + (μ * h + σ * Real.sqrt h * z)) - f x) hbint
            (ae_of_all _ fun z => by
            simpa [Real.norm_eq_abs] using key x (μ * h + σ * Real.sqrt h * z))
          simpa [Real.norm_eq_abs] using this
      _ = ε / 2 + K * ((μ * h) ^ 2 + σ ^ 2 * h) := by
          rw [integral_add (integrable_const _) _, integral_const, integral_const_mul,
            gauss_int_sq]
          · simp only [probReal_univ, one_smul, mul_pow, Real.sq_sqrt h0]
          · exact (hbint.sub (integrable_const (ε / 2))).congr
              (ae_of_all _ fun z => by simp)
      _ < ε := by linarith

/-- Reading the generator: for a payoff in `C₀(ℝ)` with two continuous slopes and
`f'`, `f''` also in `C₀(ℝ)`, the rate `(P_h f - f)/h` converges in the sup norm to
`A f = μ f' + ½ σ² f''`, so `f` lies in the domain `D(A)`. -/
theorem drifting_price_generator (μ σ : ℝ) (f : C₀(ℝ, ℝ)) (hf : ContDiff ℝ 2 (f : ℝ → ℝ))
    (hf1 : Tendsto (deriv (f : ℝ → ℝ)) (cocompact ℝ) (𝓝 0))
    (hf2 : Tendsto (deriv (deriv (f : ℝ → ℝ))) (cocompact ℝ) (𝓝 0)) :
    TendstoUniformly (fun h x => (fellerP μ σ h f x - f x) / h)
      (fun x => μ * deriv (f : ℝ → ℝ) x + σ ^ 2 / 2 * deriv (deriv (f : ℝ → ℝ)) x)
      (𝓝[>] 0) := by
  set f1 := deriv (f : ℝ → ℝ) with hf1_def
  set f2 := deriv f1 with hf2_def
  have hd1 : ContDiff ℝ 1 f1 := by
    have := (contDiff_succ_iff_deriv (n := 1)).1 hf
    exact this.2.2
  have hD : ∀ y, HasDerivAt (f : ℝ → ℝ) (f1 y) y := fun y =>
    ((hf.differentiable (by norm_num)) y).hasDerivAt
  have hD1 : ∀ y, HasDerivAt f1 (f2 y) y := fun y =>
    ((hd1.differentiable (by norm_num)) y).hasDerivAt
  have hc2 : Continuous f2 := hd1.continuous_deriv le_rfl
  obtain ⟨M2, hM2⟩ := feller_bdd_of_tendsto f2 hc2 hf2
  have hM20 : 0 ≤ M2 := (abs_nonneg _).trans (hM2 0)
  obtain ⟨M, hM⟩ := feller_bdd f
  rw [Metric.tendstoUniformly_iff]
  intro ε hε
  set ε' := ε / (4 * (σ ^ 2 + 1)) with hε'
  have hε'0 : 0 < ε' := by positivity
  obtain ⟨δ, hδ, hδf⟩ := Metric.uniformContinuous_iff.1
    (hc2.uniformContinuous_of_tendsto_cocompact hf2) ε' hε'0
  set K := 2 * M2 / δ ^ 2 with hK
  have hK0 : 0 ≤ K := by positivity
  have Rb : ∀ x y, |f (x + y) - f x - f1 x * y - f2 x / 2 * y ^ 2| ≤
      ε' * y ^ 2 + K * y ^ 4 := by
    intro x y
    by_cases hy : |y| < δ
    · have := feller_taylor2 f f1 f2 hD hD1 x y ε' (fun u hu => by
        have := hδf (a := x + u) (b := x) (by
          rw [Real.dist_eq]; simpa using lt_of_le_of_lt hu hy)
        rw [Real.dist_eq] at this
        exact this.le)
      have : 0 ≤ K * y ^ 4 := by positivity
      linarith
    · replace hy := not_lt.1 hy
      have := feller_taylor2 f f1 f2 hD hD1 x y (2 * M2) (fun u _ => by
        have := abs_sub (f2 (x + u)) (f2 x)
        linarith [hM2 (x + u), hM2 x])
      have h1 : δ ^ 2 ≤ y ^ 2 := by
        rw [← sq_abs y]; exact pow_le_pow_left₀ hδ.le hy 2
      have h2 : 2 * M2 * y ^ 2 ≤ K * y ^ 4 := by
        rw [hK, div_mul_eq_mul_div, le_div_iff₀ (by positivity)]
        have : y ^ 4 = y ^ 2 * y ^ 2 := by ring
        rw [this]
        have := mul_le_mul_of_nonneg_left h1 (by positivity : 0 ≤ 2 * M2 * y ^ 2)
        linarith
      have : 0 ≤ ε' * y ^ 2 := by positivity
      linarith
  obtain ⟨C4, hC4⟩ : ∃ C4, ∫ z, z ^ 4 ∂(gaussianReal 0 1) = C4 := ⟨_, rfl⟩
  set Φ : ℝ → ℝ := fun h => ε' * (μ ^ 2 * h + σ ^ 2) + 8 * K * (μ ^ 4 * h ^ 3 + σ ^ 4 * h * C4)
    + M2 * μ ^ 2 * h / 2 with hΦ
  have hΦc : Continuous Φ := by fun_prop
  have hΦ0 : Φ 0 < ε := by
    simp only [hΦ]
    have : ε' * σ ^ 2 < ε := by
      rw [hε', div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
      nlinarith [sq_nonneg σ]
    simpa using this
  have e1 : ∀ᶠ h in 𝓝[>] (0 : ℝ), Φ h < ε :=
    nhdsWithin_le_nhds (hΦc.continuousAt.eventually (gt_mem_nhds hΦ0))
  filter_upwards [e1, self_mem_nhdsWithin] with h hΦh (hpos : 0 < h) x
  rw [Real.dist_eq]
  -- the shifts
  set a := μ * h
  set b := σ * Real.sqrt h
  have hb2 : b ^ 2 = σ ^ 2 * h := by simp [b, mul_pow, Real.sq_sqrt hpos.le]
  have hint := feller_integrable f (map_continuous f) M hM (x + μ * h) (σ * Real.sqrt h)
  have hlin : Integrable (fun z : ℝ => a + b * z) (gaussianReal 0 1) :=
    (integrable_const _).add (gauss_integrable_z.const_mul _)
  have hsq : Integrable (fun z : ℝ => (a + b * z) ^ 2) (gaussianReal 0 1) := by
    have e : (fun z : ℝ => (a + b * z) ^ 2) =
        fun z => (a ^ 2 + (2 * a * b) * z) + b ^ 2 * z ^ 2 := by funext z; ring
    rw [e]
    exact ((integrable_const _).add (gauss_integrable_z.const_mul _)).add
      (gauss_integrable_z2.const_mul _)
  set R : ℝ → ℝ := fun z => f (x + (a + b * z)) - f x - f1 x * (a + b * z) -
    f2 x / 2 * (a + b * z) ^ 2 with hR
  have hRint : Integrable R (gaussianReal 0 1) := by
    have h0 : Integrable (fun z => f (x + (a + b * z))) (gaussianReal 0 1) :=
      hint.congr (ae_of_all _ fun z => by simp only [a, b]; congr 1; ring)
    exact ((h0.sub (integrable_const _)).sub (hlin.const_mul _)).sub (hsq.const_mul _)
  have hRval : ∫ z, R z ∂(gaussianReal 0 1) =
      fellerP μ σ h f x - f x - f1 x * a - f2 x / 2 * (a ^ 2 + b ^ 2) := by
    have h0 : Integrable (fun z => f (x + (a + b * z))) (gaussianReal 0 1) :=
      hint.congr (ae_of_all _ fun z => by simp only [a, b]; congr 1; ring)
    have e1 := integral_sub (μ := gaussianReal 0 1)
      (f := fun z => f (x + (a + b * z)) - f x - f1 x * (a + b * z))
      (g := fun z => f2 x / 2 * (a + b * z) ^ 2)
      ((h0.sub (integrable_const _)).sub (hlin.const_mul _)) (hsq.const_mul _)
    have e2 := integral_sub (μ := gaussianReal 0 1)
      (f := fun z => f (x + (a + b * z)) - f x) (g := fun z => f1 x * (a + b * z))
      (h0.sub (integrable_const _)) (hlin.const_mul _)
    have e3 := integral_sub (μ := gaussianReal 0 1)
      (f := fun z => f (x + (a + b * z))) (g := fun _ => f x) h0 (integrable_const _)
    have e4 : ∫ z, f (x + (a + b * z)) ∂(gaussianReal 0 1) = fellerP μ σ h f x := by
      simp only [fellerP, a, b]
      congr 1
      funext z
      congr 1
      ring
    simp only [hR]
    rw [e1, e2, e3, e4, integral_const_mul, integral_const_mul, gauss_int_lin, gauss_int_sq,
      integral_const]
    simp only [probReal_univ, one_smul]
  have hRbound : |∫ z, R z ∂(gaussianReal 0 1)| ≤
      ε' * (a ^ 2 + b ^ 2) + 8 * K * (a ^ 4 + b ^ 4 * C4) := by
    have hB : Integrable (fun z : ℝ => ε' * (a + b * z) ^ 2 + 8 * K * (a ^ 4 + b ^ 4 * z ^ 4))
        (gaussianReal 0 1) :=
      (hsq.const_mul _).add (((integrable_const _).add (gauss_integrable_z4.const_mul _)).const_mul _)
    have := norm_integral_le_of_norm_le hB (ae_of_all _ fun z => by
      rw [Real.norm_eq_abs]
      refine (Rb x (a + b * z)).trans ?_
      have h4 : (a + b * z) ^ 4 ≤ 8 * (a ^ 4 + b ^ 4 * z ^ 4) := by
        have := sq_nonneg (a - b * z)
        have h2 : (a + b * z) ^ 2 ≤ 2 * (a ^ 2 + (b * z) ^ 2) := by nlinarith
        have h3 : (a ^ 2 + (b * z) ^ 2) ^ 2 ≤ 2 * (a ^ 4 + (b * z) ^ 4) := by
          nlinarith [sq_nonneg (a ^ 2 - (b * z) ^ 2)]
        have h5 : ((a + b * z) ^ 2) ^ 2 ≤ (2 * (a ^ 2 + (b * z) ^ 2)) ^ 2 :=
          pow_le_pow_left₀ (sq_nonneg _) h2 2
        have : (b * z) ^ 4 = b ^ 4 * z ^ 4 := by ring
        nlinarith
      have := mul_le_mul_of_nonneg_left h4 hK0
      linarith)
    rw [Real.norm_eq_abs] at this
    refine this.trans (le_of_eq ?_)
    have e1 := integral_add (μ := gaussianReal 0 1)
      (f := fun z => ε' * (a + b * z) ^ 2) (g := fun z => 8 * K * (a ^ 4 + b ^ 4 * z ^ 4))
      (hsq.const_mul _)
      (((integrable_const _).add (gauss_integrable_z4.const_mul _)).const_mul _)
    have e2 := integral_add (μ := gaussianReal 0 1)
      (f := fun _ => a ^ 4) (g := fun z => b ^ 4 * z ^ 4)
      (integrable_const _) (gauss_integrable_z4.const_mul _)
    rw [e1, integral_const_mul, integral_const_mul, gauss_int_sq, e2, integral_const,
      integral_const_mul, hC4]
    simp
  have hiden : (fellerP μ σ h f x - f x) / h - (μ * f1 x + σ ^ 2 / 2 * f2 x) =
      (∫ z, R z ∂(gaussianReal 0 1)) / h + f2 x * μ ^ 2 * h / 2 := by
    rw [hRval, hb2]
    simp only [a]
    field_simp
    ring
  rw [abs_sub_comm, hiden]
  calc |(∫ z, R z ∂(gaussianReal 0 1)) / h + f2 x * μ ^ 2 * h / 2|
      ≤ |∫ z, R z ∂(gaussianReal 0 1)| / h + M2 * μ ^ 2 * h / 2 := by
        refine (abs_add_le _ _).trans ?_
        rw [abs_div, abs_of_pos hpos]
        gcongr
        rw [abs_div, abs_mul, abs_mul, abs_of_pos hpos, abs_of_nonneg (sq_nonneg μ)]
        have := hM2 x
        gcongr
        norm_num
    _ ≤ (ε' * (a ^ 2 + b ^ 2) + 8 * K * (a ^ 4 + b ^ 4 * C4)) / h + M2 * μ ^ 2 * h / 2 := by
        gcongr
    _ = Φ h := by
        have hb4 : b ^ 4 = (σ ^ 2 * h) ^ 2 := by rw [← hb2]; ring
        rw [hb4, hb2]
        simp only [hΦ, a]
        field_simp
    _ < ε := hΦh

/-- The backward equation: for a payoff `f` in the generator's domain (as above), the
expected payoff `u(t, x) = P_t f(x)` starts at the payoff, `u(0, x) = f(x)`, and for every
horizon `t ≥ 0` changes at the rate the generator gives:
`∂_t u = μ ∂_x u + ½ σ² ∂_xx u`. -/
theorem drifting_price_backward_equation (μ σ : ℝ) (f : C₀(ℝ, ℝ))
    (hf : ContDiff ℝ 2 (f : ℝ → ℝ))
    (hf1 : Tendsto (deriv (f : ℝ → ℝ)) (cocompact ℝ) (𝓝 0))
    (hf2 : Tendsto (deriv (deriv (f : ℝ → ℝ))) (cocompact ℝ) (𝓝 0)) :
    (∀ x, fellerP μ σ 0 f x = f x) ∧
    ∀ t : ℝ, 0 ≤ t → ∀ x : ℝ,
      HasDerivWithinAt (fun s => fellerP μ σ s f x)
        (μ * deriv (fellerP μ σ t f) x + σ ^ 2 / 2 * deriv (deriv (fellerP μ σ t f)) x)
        (Set.Ici 0) t := by
  have TU := drifting_price_generator μ σ f hf hf1 hf2
  refine ⟨fun x => by rw [(drifting_price_semigroup_is_feller μ σ).2.1 f], fun t ht x => ?_⟩
  set f1 := deriv (f : ℝ → ℝ) with hf1_def
  set f2 := deriv f1 with hf2_def
  have hd1 : ContDiff ℝ 1 f1 := ((contDiff_succ_iff_deriv (n := 1)).1 hf).2.2
  have hD : ∀ y, HasDerivAt (f : ℝ → ℝ) (f1 y) y := fun y =>
    ((hf.differentiable (by norm_num)) y).hasDerivAt
  have hD1 : ∀ y, HasDerivAt f1 (f2 y) y := fun y =>
    ((hd1.differentiable (by norm_num)) y).hasDerivAt
  have hc1 : Continuous f1 := hd1.continuous
  have hc2 : Continuous f2 := hd1.continuous_deriv le_rfl
  obtain ⟨M, hM⟩ := feller_bdd f
  obtain ⟨M1, hM1⟩ := feller_bdd_of_tendsto f1 hc1 hf1
  obtain ⟨M2, hM2⟩ := feller_bdd_of_tendsto f2 hc2 hf2
  set A : ℝ → ℝ := fun y => μ * f1 y + σ ^ 2 / 2 * f2 y with hA
  have hAc : Continuous A := by fun_prop
  have hAb : ∀ y, |A y| ≤ |μ| * M1 + σ ^ 2 / 2 * M2 := fun y => by
    calc |μ * f1 y + σ ^ 2 / 2 * f2 y| ≤ |μ * f1 y| + |σ ^ 2 / 2 * f2 y| := abs_add_le _ _
      _ = |μ| * |f1 y| + σ ^ 2 / 2 * |f2 y| := by
          rw [abs_mul, abs_mul, abs_of_nonneg (by positivity : (0 : ℝ) ≤ σ ^ 2 / 2)]
      _ ≤ |μ| * M1 + σ ^ 2 / 2 * M2 := by
          gcongr
          · exact hM1 y
          · exact hM2 y
  have hx1 : deriv (fellerP μ σ t f) = fellerP μ σ t f1 := funext fun y =>
    (fellerP_hasDerivAt f f1 hD hc1 M1 hM1 (map_continuous f) M hM μ σ t y).deriv
  have hx2 : deriv (fellerP μ σ t f1) = fellerP μ σ t f2 := funext fun y =>
    (fellerP_hasDerivAt f1 f2 hD1 hc2 M2 hM2 hc1 M1 hM1 μ σ t y).deriv
  have hAeq : μ * deriv (fellerP μ σ t f) x + σ ^ 2 / 2 * deriv (deriv (fellerP μ σ t f)) x =
      fellerP μ σ t A x := by
    rw [hx1, hx2]
    have i1 := feller_integrable f1 hc1 M1 hM1 (x + μ * t) (σ * Real.sqrt t)
    have i2 := feller_integrable f2 hc2 M2 hM2 (x + μ * t) (σ * Real.sqrt t)
    have e := integral_add (μ := gaussianReal 0 1)
      (f := fun z => μ * f1 (x + μ * t + σ * Real.sqrt t * z))
      (g := fun z => σ ^ 2 / 2 * f2 (x + μ * t + σ * Real.sqrt t * z))
      (i1.const_mul _) (i2.const_mul _)
    simp only [fellerP, hA]
    rw [e, integral_const_mul, integral_const_mul]
  rw [hAeq]
  have hψc : Continuous (fun s => fellerP μ σ s A x) := feller_cont_t A hAc _ hAb μ σ x
  have Q : ∀ s h ε, 0 ≤ s → 0 < h → (∀ y, |A y - (fellerP μ σ h f y - f y) / h| < ε) →
      |(fellerP μ σ (s + h) f x - fellerP μ σ s f x) / h - fellerP μ σ s A x| ≤ ε := by
    intro s h ε hs hh hy
    rw [fellerP_semigroup f (map_continuous f) M hM μ σ s h hs hh.le,
      feller_lin _ _ A (feller_cont_x f (map_continuous f) M hM μ σ h) (map_continuous f) hAc
        M M _ (fun y => feller_abs_le f M hM μ σ h y) hM hAb]
    refine feller_abs_le _ ε (fun y => ?_) μ σ s x
    rw [abs_sub_comm]
    exact (hy y).le
  rw [hasDerivWithinAt_iff_tendsto_slope, Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  have TUe := Metric.tendstoUniformly_iff.1 TU (ε / 2) (half_pos hε)
  rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff] at TUe
  obtain ⟨δ1, hδ1, H1⟩ := TUe
  obtain ⟨δ2, hδ2, H2⟩ := Metric.continuous_iff.1 hψc t (ε / 2) (half_pos hε)
  refine ⟨min δ1 δ2, lt_min hδ1 hδ2, fun y hy hyd => ?_⟩
  have hy0 : 0 ≤ y := hy.1
  have hyt : y ≠ t := hy.2
  have hd1' : |y - t| < δ1 := by
    rw [← Real.dist_eq]; exact lt_of_lt_of_le hyd (min_le_left _ _)
  have hd2' : dist y t < δ2 := lt_of_lt_of_le hyd (min_le_right _ _)
  simp only [slope_def_field]
  rw [Real.dist_eq]
  rcases lt_or_gt_of_ne hyt with hlt | hgt
  · have hk : 0 < t - y := by linarith
    have hkd : dist (t - y) 0 < δ1 := by
      rw [Real.dist_eq, sub_zero, abs_of_pos hk]
      rw [abs_of_neg (by linarith)] at hd1'
      linarith
    have hq := Q y (t - y) (ε / 2) hy0 hk (fun z => by
      have := H1 hkd hk z
      rwa [Real.dist_eq] at this)
    have e : y + (t - y) = t := by ring
    rw [e] at hq
    have hs := H2 y hd2'
    rw [Real.dist_eq] at hs
    have e2 : (fellerP μ σ y f x - fellerP μ σ t f x) / (y - t) =
        (fellerP μ σ t f x - fellerP μ σ y f x) / (t - y) := by
      rw [← neg_sub t y, div_neg, ← neg_div, neg_sub]
    rw [e2]
    calc |(fellerP μ σ t f x - fellerP μ σ y f x) / (t - y) - fellerP μ σ t A x|
        ≤ |(fellerP μ σ t f x - fellerP μ σ y f x) / (t - y) - fellerP μ σ y A x| +
          |fellerP μ σ y A x - fellerP μ σ t A x| := abs_sub_le _ _ _
      _ < ε / 2 + ε / 2 := add_lt_add_of_le_of_lt hq hs
      _ = ε := by ring
  · have hk : 0 < y - t := by linarith
    have hkd : dist (y - t) 0 < δ1 := by
      rw [Real.dist_eq, sub_zero]; exact hd1'
    have hq := Q t (y - t) (ε / 2) ht hk (fun z => by
      have := H1 hkd hk z
      rwa [Real.dist_eq] at this)
    have e : t + (y - t) = y := by ring
    rw [e] at hq
    linarith

-- Reading the generator 5 f' + 200 f'': ½ σ² = 200 gives σ² = 400 = 20², so σ = 20.
example : (2 : ℚ) * 200 = 20 ^ 2 := by norm_num

-- Grid rates σ²/(2δ²) ± μ/(2δ) with μ = 5, σ² = 400: up and down rates at δ = 5, 5/2, 5/4, 5/8.
example : (400 : ℚ) / (2 * 5 ^ 2) + 5 / (2 * 5) = 17 / 2 ∧
    (400 : ℚ) / (2 * 5 ^ 2) - 5 / (2 * 5) = 15 / 2 := by norm_num
example : (400 : ℚ) / (2 * (5 / 2) ^ 2) + 5 / (2 * (5 / 2)) = 33 ∧
    (400 : ℚ) / (2 * (5 / 2) ^ 2) - 5 / (2 * (5 / 2)) = 31 := by norm_num
example : (400 : ℚ) / (2 * (5 / 4) ^ 2) + 5 / (2 * (5 / 4)) = 130 ∧
    (400 : ℚ) / (2 * (5 / 4) ^ 2) - 5 / (2 * (5 / 4)) = 126 := by norm_num
example : (400 : ℚ) / (2 * (5 / 8) ^ 2) + 5 / (2 * (5 / 8)) = 516 ∧
    (400 : ℚ) / (2 * (5 / 8) ^ 2) - 5 / (2 * (5 / 8)) = 508 := by norm_num

-- Reading drift and variance rate off the δ = 5 row: (8.5 - 7.5) × 5 = 5 and (8.5 + 7.5) × 5² = 400.
example : ((17 : ℚ) / 2 - 15 / 2) * 5 = 5 ∧ ((17 : ℚ) / 2 + 15 / 2) * 5 ^ 2 = 400 := by norm_num

-- Flipped curvature sign: the zigzag grows at 800/δ² a year: 32, 128, 512, 2048.
example : (800 : ℚ) / 5 ^ 2 = 32 ∧ (800 : ℚ) / (5 / 2) ^ 2 = 128 ∧
    (800 : ℚ) / (5 / 4) ^ 2 = 512 ∧ (800 : ℚ) / (5 / 8) ^ 2 = 2048 := by norm_num

#print axioms drifting_price_semigroup_is_feller
#print axioms drifting_price_generator
#print axioms drifting_price_backward_equation
#print axioms feller_integrable_of_bdd
#print axioms feller_integrable
#print axioms feller_abs_le
#print axioms feller_cont_param
#print axioms feller_cont_x
#print axioms feller_cont_t
#print axioms fellerVar
#print axioms fellerP_eq_gauss
#print axioms fellerP_semigroup
#print axioms gauss_int_z
#print axioms gauss_integrable_z
#print axioms gauss_integrable_z2
#print axioms gauss_integrable_z4
#print axioms gauss_int_z2
#print axioms gauss_int_lin
#print axioms gauss_int_sq
#print axioms feller_bdd_of_tendsto
#print axioms feller_bdd
#print axioms feller_tendsto_zero
#print axioms feller_taylor2
#print axioms fellerP_hasDerivAt
#print axioms feller_lin
