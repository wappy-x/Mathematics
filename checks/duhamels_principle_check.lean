-- Duhamel's principle: the sum of heat-kernel fresh starts u(x, t) = ∫₀ᵗ ∫ G(x − y, t − τ) f(y, τ) dy dτ solves the forced heat equation u_t = κ u_xx + f and starts at 0, a point heater gives the rise Q √(t_on/(πκ)) under it, and a point force on a wire gives a growing tent.
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv

open Real MeasureTheory Filter Topology

/-- The heat kernel on the line: G(x, t) = e^(-x^2/(4κt)) / √(4πκt), the spread of one unit
of heat dropped at a point, after time t. -/
noncomputable def heatKernel (κ t x : ℝ) : ℝ :=
  Real.exp (-x ^ 2 / (4 * κ * t)) / Real.sqrt (4 * π * κ * t)

noncomputable def gφ (ζ : ℝ) : ℝ := (Real.sqrt (2 * π))⁻¹ * Real.exp (-(1/2) * ζ ^ 2)

lemma gφ_nonneg (ζ : ℝ) : 0 ≤ gφ ζ := by unfold gφ; positivity

#print axioms gφ_nonneg

lemma gφ_continuous : Continuous gφ := by unfold gφ; fun_prop

#print axioms gφ_continuous

lemma gφ_integrable : Integrable gφ :=
  (integrable_exp_neg_mul_sq (by norm_num : (0:ℝ) < 1/2)).const_mul _

#print axioms gφ_integrable

lemma gφ_integral : ∫ ζ, gφ ζ = 1 := by
  unfold gφ
  rw [integral_const_mul, integral_gaussian, show π / (1/2) = 2 * π by ring]
  exact inv_mul_cancel₀ (Real.sqrt_pos.2 (by positivity)).ne'

#print axioms gφ_integral

lemma gφ_mul_integrable : Integrable (fun ζ => ζ * gφ ζ) := by
  have := (integrable_mul_exp_neg_mul_sq (by norm_num : (0:ℝ) < 1/2)).const_mul (Real.sqrt (2 * π))⁻¹
  refine this.congr (ae_of_all _ (fun ζ => ?_))
  simp only [gφ]; ring

#print axioms gφ_mul_integrable

lemma gφ_abs_mul_integrable : Integrable (fun ζ => |ζ| * gφ ζ) := by
  refine gφ_mul_integrable.norm.congr (ae_of_all _ (fun ζ => ?_))
  simp only [Real.norm_eq_abs, abs_mul, abs_of_nonneg (gφ_nonneg ζ)]

#print axioms gφ_abs_mul_integrable

lemma gφ_hasDerivAt (ζ : ℝ) : HasDerivAt gφ (-(ζ * gφ ζ)) ζ := by
  unfold gφ
  have h1 : HasDerivAt (fun ζ : ℝ => -(1/2) * ζ ^ 2) (-(1/2) * (2 * ζ)) ζ := by
    simpa using (hasDerivAt_pow 2 ζ).const_mul (-(1/2:ℝ))
  have := (h1.exp).const_mul (Real.sqrt (2 * π))⁻¹
  convert this using 1; ring

#print axioms gφ_hasDerivAt

lemma gφ_tendsto_atTop : Tendsto gφ atTop (𝓝 0) := by
  unfold gφ
  have h : Tendsto (fun ζ : ℝ => (1/2) * ζ ^ 2) atTop atTop :=
    (tendsto_pow_atTop two_ne_zero).const_mul_atTop (by norm_num)
  have := (tendsto_exp_neg_atTop_nhds_zero.comp h).const_mul (Real.sqrt (2 * π))⁻¹
  simp only [mul_zero] at this
  refine this.congr (fun ζ => ?_)
  simp [Function.comp]

#print axioms gφ_tendsto_atTop

lemma gφ_tendsto_atBot : Tendsto gφ atBot (𝓝 0) := by
  have : gφ = gφ ∘ (fun ζ => -ζ) := by funext ζ; simp [gφ]
  rw [this]
  exact gφ_tendsto_atTop.comp tendsto_neg_atBot_atTop

#print axioms gφ_tendsto_atBot

/-- Gaussian integration by parts (Stein's identity). -/

lemma stein (k k' : ℝ → ℝ) (B B' : ℝ) (hk : ∀ ζ, HasDerivAt k (k' ζ) ζ) (hkb : ∀ ζ, |k ζ| ≤ B)
    (hk'b : ∀ ζ, |k' ζ| ≤ B') (hk'c : Continuous k') :
    ∫ ζ, ζ * gφ ζ * k ζ = ∫ ζ, gφ ζ * k' ζ := by
  have hkc : Continuous k := continuous_iff_continuousAt.2 (fun ζ => (hk ζ).continuousAt)
  have h1 : Integrable (k * fun ζ => -(ζ * gφ ζ)) := by
    refine Integrable.mono' (gφ_abs_mul_integrable.const_mul B) ?_ (ae_of_all _ (fun ζ => ?_))
    · exact (hkc.mul (continuous_id.mul gφ_continuous).neg).aestronglyMeasurable
    · simp only [Pi.mul_apply, norm_mul, Real.norm_eq_abs, abs_neg, abs_mul, abs_of_nonneg (gφ_nonneg ζ)]
      exact mul_le_mul_of_nonneg_right (hkb ζ) (mul_nonneg (abs_nonneg _) (gφ_nonneg ζ))
  have h2 : Integrable (k' * gφ) := by
    refine Integrable.mono' (gφ_integrable.const_mul B') ?_ (ae_of_all _ (fun ζ => ?_))
    · exact (hk'c.mul gφ_continuous).aestronglyMeasurable
    · simp only [Pi.mul_apply, norm_mul, Real.norm_eq_abs, abs_of_nonneg (gφ_nonneg ζ)]
      exact mul_le_mul_of_nonneg_right (hk'b ζ) (gφ_nonneg ζ)
  have hlim : ∀ l : Filter ℝ, Tendsto gφ l (𝓝 0) → Tendsto (k * gφ) l (𝓝 0) := by
    intro l hl
    refine squeeze_zero_norm (a := fun ζ => B * gφ ζ) (fun ζ => ?_) ?_
    · simp only [Pi.mul_apply, norm_mul, Real.norm_eq_abs, abs_of_nonneg (gφ_nonneg ζ)]
      exact mul_le_mul_of_nonneg_right (hkb ζ) (gφ_nonneg ζ)
    · simpa using hl.const_mul B
  have := integral_mul_deriv_eq_deriv_mul (u := k) (v := gφ) (u' := k') (v' := fun ζ => -(ζ * gφ ζ))
    (fun ζ _ => hk ζ) (fun ζ _ => gφ_hasDerivAt ζ) h1 h2 (hlim _ gφ_tendsto_atBot) (hlim _ gφ_tendsto_atTop)
  simp only [sub_zero, zero_sub, mul_neg, integral_neg, neg_inj] at this
  calc ∫ ζ, ζ * gφ ζ * k ζ = ∫ ζ, k ζ * (ζ * gφ ζ) := by congr 1; funext ζ; ring
    _ = ∫ ζ, k' ζ * gφ ζ := this
    _ = _ := by congr 1; funext ζ; ring

#print axioms stein

noncomputable def Sm (κ : ℝ) (h : ℝ → ℝ → ℝ) (x s τ : ℝ) : ℝ :=
  ∫ ζ, gφ ζ * h (x - Real.sqrt (2 * κ * s) * ζ) τ

lemma uncurry_comp {X : Type*} [TopologicalSpace X] {h : ℝ → ℝ → ℝ} (hc : Continuous (Function.uncurry h))
    {a b : X → ℝ} (ha : Continuous a) (hb : Continuous b) : Continuous (fun p => h (a p) (b p)) :=
  hc.comp (ha.prodMk hb)

#print axioms uncurry_comp

lemma gφ_mul_le {h : ℝ → ℝ → ℝ} {M : ℝ} (hb : ∀ y τ, |h y τ| ≤ M) (ζ y τ : ℝ) :
    ‖gφ ζ * h y τ‖ ≤ M * gφ ζ := by
  rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg (gφ_nonneg ζ), mul_comm]
  exact mul_le_mul_of_nonneg_right (hb y τ) (gφ_nonneg ζ)

#print axioms gφ_mul_le

lemma Sm_integrable {h : ℝ → ℝ → ℝ} {M : ℝ} (hc : Continuous (Function.uncurry h))
    (hb : ∀ y τ, |h y τ| ≤ M) (κ x s τ : ℝ) :
    Integrable (fun ζ => gφ ζ * h (x - Real.sqrt (2 * κ * s) * ζ) τ) :=
  Integrable.mono' (gφ_integrable.const_mul M)
    (gφ_continuous.mul (uncurry_comp hc (by fun_prop) continuous_const)).aestronglyMeasurable
    (ae_of_all _ (fun ζ => gφ_mul_le hb _ _ _))

#print axioms Sm_integrable

lemma Sm_abs_le (κ : ℝ) {h : ℝ → ℝ → ℝ} {M : ℝ} (hb : ∀ y τ, |h y τ| ≤ M) (x s τ : ℝ) :
    |Sm κ h x s τ| ≤ M := by
  have := norm_integral_le_of_norm_le (gφ_integrable.const_mul M)
    (ae_of_all _ (fun ζ => gφ_mul_le hb ζ (x - Real.sqrt (2 * κ * s) * ζ) τ))
  rwa [integral_const_mul, gφ_integral, mul_one] at this

#print axioms Sm_abs_le

lemma Sm_zero (κ : ℝ) (h : ℝ → ℝ → ℝ) (x τ : ℝ) : Sm κ h x 0 τ = h x τ := by
  simp [Sm, integral_mul_const, gφ_integral]

#print axioms Sm_zero

lemma Sm_continuous (κ : ℝ) {h : ℝ → ℝ → ℝ} {M : ℝ} (hc : Continuous (Function.uncurry h))
    (hb : ∀ y τ, |h y τ| ≤ M) : Continuous (fun p : ℝ × ℝ × ℝ => Sm κ h p.1 p.2.1 p.2.2) := by
  unfold Sm
  refine continuous_of_dominated (bound := fun ζ => M * gφ ζ) (fun p => ?_)
    (fun p => ae_of_all _ (fun ζ => gφ_mul_le hb _ _ _)) (gφ_integrable.const_mul M)
    (ae_of_all _ (fun ζ => ?_))
  · exact (gφ_continuous.mul (uncurry_comp hc (by fun_prop) continuous_const)).aestronglyMeasurable
  · exact continuous_const.mul (uncurry_comp hc (by fun_prop) (by fun_prop))

#print axioms Sm_continuous

lemma Sm_hasDerivAt_x (κ : ℝ) {h hx : ℝ → ℝ → ℝ} {M : ℝ} (hc : Continuous (Function.uncurry h))
    (hxc : Continuous (Function.uncurry hx)) (hb : ∀ y τ, |h y τ| ≤ M) (hbx : ∀ y τ, |hx y τ| ≤ M)
    (hd : ∀ y τ, HasDerivAt (fun y => h y τ) (hx y τ) y) (x s τ : ℝ) :
    HasDerivAt (fun x => Sm κ h x s τ) (Sm κ hx x s τ) x := by
  unfold Sm
  set σ := Real.sqrt (2 * κ * s)
  have := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume) (x₀ := x) (s := Set.univ)
    (F := fun x ζ => gφ ζ * h (x - σ * ζ) τ) (F' := fun x ζ => gφ ζ * hx (x - σ * ζ) τ)
    (bound := fun ζ => M * gφ ζ) Filter.univ_mem
    (Eventually.of_forall (fun x => (Sm_integrable hc hb κ x s τ).aestronglyMeasurable))
    (Sm_integrable hc hb κ x s τ) (Sm_integrable hxc hbx κ x s τ).aestronglyMeasurable
    (ae_of_all _ (fun ζ x _ => gφ_mul_le hbx _ _ _)) (gφ_integrable.const_mul M)
    (ae_of_all _ (fun ζ x _ => ?_))
  · exact this.2
  · have := (hd (x - σ * ζ) τ).comp x ((hasDerivAt_id x).sub_const (σ * ζ))
    simpa using this.const_mul (gφ ζ)

#print axioms Sm_hasDerivAt_x

lemma sqrt_hasDerivAt (κ s : ℝ) (hκ : 0 < κ) (hs : 0 < s) :
    HasDerivAt (fun s => Real.sqrt (2 * κ * s)) (κ / Real.sqrt (2 * κ * s)) s := by
  have h0 : 2 * κ * s ≠ 0 := by positivity
  have := ((hasDerivAt_id s).const_mul (2 * κ)).sqrt (by simpa using h0)
  convert this using 1
  · rfl
  show κ / √(2 * κ * s) = 2 * κ * 1 / (2 * √(2 * κ * s))
  have hp : 0 < Real.sqrt (2 * κ * s) := Real.sqrt_pos.2 (by positivity)
  field_simp

#print axioms sqrt_hasDerivAt

lemma Sm_hasDerivAt_s (κ : ℝ) (hκ : 0 < κ) {h hx hxx : ℝ → ℝ → ℝ} {M : ℝ}
    (hc : Continuous (Function.uncurry h)) (hxc : Continuous (Function.uncurry hx))
    (hxxc : Continuous (Function.uncurry hxx))
    (hb : ∀ y τ, |h y τ| ≤ M) (hbx : ∀ y τ, |hx y τ| ≤ M) (hbxx : ∀ y τ, |hxx y τ| ≤ M)
    (hd : ∀ y τ, HasDerivAt (fun y => h y τ) (hx y τ) y)
    (hd2 : ∀ y τ, HasDerivAt (fun y => hx y τ) (hxx y τ) y) (x s τ : ℝ) (hs : 0 < s) :
    HasDerivAt (fun s => Sm κ h x s τ) (κ * Sm κ hxx x s τ) s := by
  unfold Sm
  set σ : ℝ → ℝ := fun s => Real.sqrt (2 * κ * s) with hσ
  have hσpos : ∀ r, 0 < r → 0 < σ r := fun r hr => Real.sqrt_pos.2 (by positivity)
  set c := κ / σ (s / 2)
  have hM : 0 ≤ M := (abs_nonneg _).trans (hb 0 0)
  have key := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume) (x₀ := s)
    (s := Set.Ioi (s / 2))
    (F := fun r ζ => gφ ζ * h (x - σ r * ζ) τ)
    (F' := fun r ζ => gφ ζ * (hx (x - σ r * ζ) τ * -(κ / σ r * ζ)))
    (bound := fun ζ => M * c * (|ζ| * gφ ζ)) (Ioi_mem_nhds (by linarith))
    (Eventually.of_forall (fun r => (Sm_integrable hc hb κ x r τ).aestronglyMeasurable))
    (Sm_integrable hc hb κ x s τ)
    ((gφ_continuous.mul ((uncurry_comp hxc (by fun_prop) continuous_const).mul
      (by fun_prop))).aestronglyMeasurable)
    (ae_of_all _ (fun ζ r hr => ?_)) ((gφ_abs_mul_integrable).const_mul (M * c))
    (ae_of_all _ (fun ζ r hr => ?_))
  · have hk : ∀ ζ, HasDerivAt (fun ζ => hx (x - σ s * ζ) τ) (hxx (x - σ s * ζ) τ * (-(σ s))) ζ := by
      intro ζ
      have := (hd2 (x - σ s * ζ) τ).comp ζ (((hasDerivAt_id ζ).const_mul (σ s)).const_sub x)
      exact this.congr_deriv (by simp)
    have hst := stein (fun ζ => hx (x - σ s * ζ) τ) (fun ζ => hxx (x - σ s * ζ) τ * (-(σ s))) M (M * σ s)
      hk (fun ζ => hbx _ _) (fun ζ => by
        rw [abs_mul, abs_neg, abs_of_pos (hσpos s hs)]
        exact mul_le_mul_of_nonneg_right (hbxx _ _) (hσpos s hs).le)
      ((uncurry_comp hxxc (by fun_prop) continuous_const).mul continuous_const)
    have e1 : (∫ ζ, gφ ζ * (hx (x - σ s * ζ) τ * -(κ / σ s * ζ)))
        = -(κ / σ s) * ∫ ζ, ζ * gφ ζ * hx (x - σ s * ζ) τ := by
      rw [← integral_const_mul]; congr 1; funext ζ; ring
    have e2 : (∫ ζ, gφ ζ * (hxx (x - σ s * ζ) τ * -σ s))
        = -(σ s) * ∫ ζ, gφ ζ * hxx (x - σ s * ζ) τ := by
      rw [← integral_const_mul]; congr 1; funext ζ; ring
    have := key.2
    rw [e1, hst, e2] at this
    convert this using 1
    have := (hσpos s hs).ne'
    rw [← mul_assoc, neg_mul_neg, div_mul_cancel₀ _ this]
  · have hr' : 0 < r := by simp only [Set.mem_Ioi] at hr; linarith
    have hr2 : s / 2 < r := hr
    have hle : σ (s / 2) ≤ σ r := Real.sqrt_le_sqrt (by nlinarith)
    have hcr : κ / σ r ≤ c := div_le_div_of_nonneg_left hκ.le (hσpos _ (by linarith)) hle
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_neg, abs_mul, abs_of_nonneg (gφ_nonneg ζ),
      abs_of_pos (div_pos hκ (hσpos r hr'))]
    have := hbx (x - σ r * ζ) τ
    have h1 : 0 ≤ gφ ζ := gφ_nonneg ζ
    have h2 : 0 ≤ |ζ| := abs_nonneg ζ
    have h3 : 0 ≤ κ / σ r := (div_pos hκ (hσpos r hr')).le
    calc gφ ζ * (|hx (x - σ r * ζ) τ| * (κ / σ r * |ζ|)) ≤ gφ ζ * (M * (c * |ζ|)) := by gcongr
      _ = _ := by ring
  · have hr' : 0 < r := by simp only [Set.mem_Ioi] at hr; linarith
    have := (hd (x - σ r * ζ) τ).comp r (((sqrt_hasDerivAt κ r hκ hr').mul_const ζ).const_sub x)
    exact this.const_mul (gφ ζ)

#print axioms Sm_hasDerivAt_s

lemma Sm_max (κ : ℝ) (hκ : 0 < κ) (h : ℝ → ℝ → ℝ) (x s τ : ℝ) :
    Sm κ h x s τ = Sm κ h x (max s 0) τ := by
  rcases le_total s 0 with hs | hs
  · rw [max_eq_right hs]
    unfold Sm
    rw [Real.sqrt_eq_zero'.2 (by nlinarith), mul_zero, Real.sqrt_zero]
  · rw [max_eq_left hs]

#print axioms Sm_max

lemma Sm_lip_nonneg (κ : ℝ) (hκ : 0 < κ) {h hx hxx : ℝ → ℝ → ℝ} {M : ℝ}
    (hc : Continuous (Function.uncurry h)) (hxc : Continuous (Function.uncurry hx))
    (hxxc : Continuous (Function.uncurry hxx))
    (hb : ∀ y τ, |h y τ| ≤ M) (hbx : ∀ y τ, |hx y τ| ≤ M) (hbxx : ∀ y τ, |hxx y τ| ≤ M)
    (hd : ∀ y τ, HasDerivAt (fun y => h y τ) (hx y τ) y)
    (hd2 : ∀ y τ, HasDerivAt (fun y => hx y τ) (hxx y τ) y) (x τ a b : ℝ) (ha : 0 ≤ a) (hab : a ≤ b) :
    |Sm κ h x b τ - Sm κ h x a τ| ≤ κ * M * (b - a) := by
  rcases eq_or_lt_of_le hab with rfl | hlt
  · simp
  obtain ⟨c, hc', heq⟩ := exists_hasDerivAt_eq_slope (fun s => Sm κ h x s τ)
    (fun s => κ * Sm κ hxx x s τ) hlt
    (((Sm_continuous κ hc hb).comp (by fun_prop : Continuous fun s : ℝ => (x, s, τ))).continuousOn)
    (fun s hs => Sm_hasDerivAt_s κ hκ hc hxc hxxc hb hbx hbxx hd hd2 x s τ (by linarith [hs.1]))
  have hba : 0 < b - a := by linarith
  have : Sm κ h x b τ - Sm κ h x a τ = κ * Sm κ hxx x c τ * (b - a) := by
    rw [heq]; field_simp
  rw [this, abs_mul, abs_mul, abs_of_pos hκ, abs_of_pos hba]
  have := Sm_abs_le κ hbxx x c τ
  gcongr

#print axioms Sm_lip_nonneg

lemma Sm_lip (κ : ℝ) (hκ : 0 < κ) {h hx hxx : ℝ → ℝ → ℝ} {M : ℝ}
    (hc : Continuous (Function.uncurry h)) (hxc : Continuous (Function.uncurry hx))
    (hxxc : Continuous (Function.uncurry hxx))
    (hb : ∀ y τ, |h y τ| ≤ M) (hbx : ∀ y τ, |hx y τ| ≤ M) (hbxx : ∀ y τ, |hxx y τ| ≤ M)
    (hd : ∀ y τ, HasDerivAt (fun y => h y τ) (hx y τ) y)
    (hd2 : ∀ y τ, HasDerivAt (fun y => hx y τ) (hxx y τ) y) (x τ a b : ℝ) :
    |Sm κ h x b τ - Sm κ h x a τ| ≤ κ * M * |b - a| := by
  have hM : 0 ≤ M := (abs_nonneg _).trans (hb 0 0)
  rw [Sm_max κ hκ h x b, Sm_max κ hκ h x a]
  have hmax := abs_max_sub_max_le_abs b a 0
  have hk : 0 ≤ κ * M := by positivity
  rcases le_total (max a 0) (max b 0) with hle | hle
  · have := Sm_lip_nonneg κ hκ hc hxc hxxc hb hbx hbxx hd hd2 x τ _ _ (le_max_right a 0) hle
    calc _ ≤ κ * M * (max b 0 - max a 0) := this
      _ ≤ κ * M * |max b 0 - max a 0| := by gcongr; exact le_abs_self _
      _ ≤ _ := by gcongr
  · have := Sm_lip_nonneg κ hκ hc hxc hxxc hb hbx hbxx hd hd2 x τ _ _ (le_max_right b 0) hle
    rw [abs_sub_comm]
    calc _ ≤ κ * M * (max a 0 - max b 0) := this
      _ ≤ κ * M * |max b 0 - max a 0| := by gcongr; rw [abs_sub_comm]; exact le_abs_self _
      _ ≤ _ := by gcongr

#print axioms Sm_lip

lemma heat_eq_Sm (κ : ℝ) (hκ : 0 < κ) (h : ℝ → ℝ → ℝ) (x s τ : ℝ) (hs : 0 < s) :
    ∫ y, heatKernel κ s (x - y) * h y τ = Sm κ h x s τ := by
  have h1 := integral_sub_left_eq_self (fun z => heatKernel κ s z * h (x - z) τ) volume x
  simp only [sub_sub_cancel] at h1
  rw [h1]
  set σ := Real.sqrt (2 * κ * s) with hσ
  have hσpos : 0 < σ := Real.sqrt_pos.2 (by positivity)
  have hσsq : σ ^ 2 = 2 * κ * s := Real.sq_sqrt (by positivity)
  have h2 := Measure.integral_comp_mul_left (fun z => heatKernel κ s z * h (x - z) τ) σ
  rw [abs_of_pos (inv_pos.2 hσpos), smul_eq_mul] at h2
  have h3 : ∫ y, heatKernel κ s y * h (x - y) τ = σ * ∫ ζ, heatKernel κ s (σ * ζ) * h (x - σ * ζ) τ := by
    rw [h2, ← mul_assoc, mul_inv_cancel₀ hσpos.ne', one_mul]
  rw [h3, ← integral_const_mul]
  unfold Sm
  congr 1; funext ζ
  rw [← mul_assoc]
  congr 1
  unfold heatKernel gφ
  have hs4 : Real.sqrt (4 * π * κ * s) = Real.sqrt (2 * π) * σ := by
    rw [hσ, ← Real.sqrt_mul (by positivity)]; congr 1; ring
  have hexp : -(σ * ζ) ^ 2 / (4 * κ * s) = -(1/2) * ζ ^ 2 := by
    rw [mul_pow, hσsq]; field_simp; ring
  rw [hs4, hexp]
  have : 0 < Real.sqrt (2 * π) := Real.sqrt_pos.2 (by positivity)
  field_simp

#print axioms heat_eq_Sm

noncomputable def Dm (κ : ℝ) (h : ℝ → ℝ → ℝ) (x t : ℝ) : ℝ := ∫ τ in (0:ℝ)..t, Sm κ h x (t - τ) τ

lemma Sm_path_cont (κ : ℝ) {h : ℝ → ℝ → ℝ} {M : ℝ} (hc : Continuous (Function.uncurry h))
    (hb : ∀ y τ, |h y τ| ≤ M) (x t : ℝ) : Continuous (fun τ => Sm κ h x (t - τ) τ) :=
  (Sm_continuous κ hc hb).comp (by fun_prop : Continuous fun τ : ℝ => (x, t - τ, τ))

#print axioms Sm_path_cont

lemma Dm_hasDerivAt_x (κ : ℝ) {h hx : ℝ → ℝ → ℝ} {M : ℝ} (hc : Continuous (Function.uncurry h))
    (hxc : Continuous (Function.uncurry hx)) (hb : ∀ y τ, |h y τ| ≤ M) (hbx : ∀ y τ, |hx y τ| ≤ M)
    (hd : ∀ y τ, HasDerivAt (fun y => h y τ) (hx y τ) y) (x t : ℝ) :
    HasDerivAt (fun x => Dm κ h x t) (Dm κ hx x t) x := by
  unfold Dm
  exact (intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume) (x₀ := x)
    (s := Set.univ) (F := fun x τ => Sm κ h x (t - τ) τ) (F' := fun x τ => Sm κ hx x (t - τ) τ)
    (bound := fun _ => M) Filter.univ_mem
    (Eventually.of_forall (fun x => (Sm_path_cont κ hc hb x t).aestronglyMeasurable))
    ((Sm_path_cont κ hc hb x t).intervalIntegrable _ _)
    ((Sm_path_cont κ hxc hbx x t).aestronglyMeasurable)
    (ae_of_all _ (fun τ _ x _ => by rw [Real.norm_eq_abs]; exact Sm_abs_le κ hbx _ _ _))
    intervalIntegrable_const
    (ae_of_all _ (fun τ _ x _ => Sm_hasDerivAt_x κ hc hxc hb hbx hd x (t - τ) τ))).2

#print axioms Dm_hasDerivAt_x

lemma Dm_continuous_x (κ : ℝ) {h : ℝ → ℝ → ℝ} {M : ℝ} (hc : Continuous (Function.uncurry h))
    (hb : ∀ y τ, |h y τ| ≤ M) (t : ℝ) : Continuous (fun x => Dm κ h x t) := by
  unfold Dm
  exact intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
    (f := fun x τ => Sm κ h x (t - τ) τ)
    ((Sm_continuous κ hc hb).comp (by fun_prop : Continuous fun p : ℝ × ℝ => (p.1, t - p.2, p.2))) 0 t

#print axioms Dm_continuous_x

lemma Dm_abs_le (κ : ℝ) {h : ℝ → ℝ → ℝ} {M : ℝ} (hb : ∀ y τ, |h y τ| ≤ M) (x t : ℝ) :
    |Dm κ h x t| ≤ M * |t| := by
  have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := t) (C := M)
    (f := fun τ => Sm κ h x (t - τ) τ) (fun τ _ => by rw [Real.norm_eq_abs]; exact Sm_abs_le κ hb _ _ _)
  simpa [Dm] using this

#print axioms Dm_abs_le

lemma Dm_hasDerivAt_t (κ : ℝ) (hκ : 0 < κ) {h hx hxx : ℝ → ℝ → ℝ} {M : ℝ}
    (hc : Continuous (Function.uncurry h)) (hxc : Continuous (Function.uncurry hx))
    (hxxc : Continuous (Function.uncurry hxx))
    (hb : ∀ y τ, |h y τ| ≤ M) (hbx : ∀ y τ, |hx y τ| ≤ M) (hbxx : ∀ y τ, |hxx y τ| ≤ M)
    (hd : ∀ y τ, HasDerivAt (fun y => h y τ) (hx y τ) y)
    (hd2 : ∀ y τ, HasDerivAt (fun y => hx y τ) (hxx y τ) y) (x t₀ : ℝ) (ht₀ : 0 < t₀) :
    HasDerivAt (fun t => Dm κ h x t) (κ * Dm κ hxx x t₀ + h x t₀) t₀ := by
  have hM : 0 ≤ M := (abs_nonneg _).trans (hb 0 0)
  set A : ℝ → ℝ := fun t => ∫ τ in (0:ℝ)..t₀, Sm κ h x (t - τ) τ with hA
  set B : ℝ → ℝ := fun t => ∫ τ in t₀..t, Sm κ h x (t - τ) τ with hB
  set C : ℝ → ℝ := fun t => ∫ τ in t₀..t, Sm κ h x 0 τ with hC
  have hsplit : (fun t => Dm κ h x t) = fun t => A t + (C t + (B t - C t)) := by
    funext t
    simp only [A, B, Dm, add_sub_cancel]
    exact (intervalIntegral.integral_add_adjacent_intervals
      ((Sm_path_cont κ hc hb x t).intervalIntegrable _ _)
      ((Sm_path_cont κ hc hb x t).intervalIntegrable _ _)).symm
  rw [hsplit]
  -- the old slabs
  have hAd : HasDerivAt A (κ * Dm κ hxx x t₀) t₀ := by
    have key := intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_lip (μ := volume) (x₀ := t₀)
      (a := 0) (b := t₀)
      (s := Set.univ) (F := fun t τ => Sm κ h x (t - τ) τ) (F' := fun τ => κ * Sm κ hxx x (t₀ - τ) τ)
      (bound := fun _ => κ * M) Filter.univ_mem
      (Eventually.of_forall (fun t => (Sm_path_cont κ hc hb x t).aestronglyMeasurable))
      ((Sm_path_cont κ hc hb x t₀).intervalIntegrable _ _)
      ((continuous_const.mul (Sm_path_cont κ hxxc hbxx x t₀)).aestronglyMeasurable)
      (ae_of_all _ (fun τ _ => ?_)) intervalIntegrable_const ?_
    · have := key.2
      simp only [intervalIntegral.integral_const_mul] at this
      exact this
    · refine LipschitzOnWith.of_dist_le_mul (fun t₁ _ t₂ _ => ?_)
      rw [Real.dist_eq, Real.dist_eq, Real.coe_nnabs, abs_of_nonneg (mul_nonneg hκ.le hM)]
      have := Sm_lip κ hκ hc hxc hxxc hb hbx hbxx hd hd2 x τ (t₂ - τ) (t₁ - τ)
      rwa [show t₁ - τ - (t₂ - τ) = t₁ - t₂ by ring] at this
    · filter_upwards [Measure.ae_ne volume t₀] with τ hne hτ
      rw [Set.uIoc_of_le ht₀.le] at hτ
      have hpos : 0 < t₀ - τ := by
        rcases lt_or_eq_of_le hτ.2 with h' | h'
        · linarith
        · exact absurd h' hne
      have := (Sm_hasDerivAt_s κ hκ hc hxc hxxc hb hbx hbxx hd hd2 x (t₀ - τ) τ hpos).comp t₀
        ((hasDerivAt_id t₀).sub_const τ)
      simp only [mul_one] at this
      exact this
  -- the newest slab
  have hC0 : Continuous fun τ => Sm κ h x 0 τ :=
    (Sm_continuous κ hc hb).comp (by fun_prop : Continuous fun τ : ℝ => (x, (0:ℝ), τ))
  have hCd : HasDerivAt C (h x t₀) t₀ := by
    have hCd' : HasDerivAt C (Sm κ h x 0 t₀) t₀ := (hC0.integral_hasStrictDerivAt t₀ t₀).hasDerivAt
    rwa [Sm_zero] at hCd'
  have hRd : HasDerivAt (fun t => B t - C t) 0 t₀ := by
    rw [hasDerivAt_iff_isLittleO]
    have hR0 : B t₀ - C t₀ = 0 := by simp [B, C]
    simp only [hR0, sub_zero, smul_zero]
    refine Asymptotics.IsBigO.trans_isLittleO (g := fun t => ‖t - t₀‖ ^ 2) ?_
      (Asymptotics.isLittleO_pow_sub_sub t₀ one_lt_two)
    refine Asymptotics.IsBigO.of_bound (κ * M) (Eventually.of_forall (fun t => ?_))
    have hBC : B t - C t = ∫ τ in t₀..t, (Sm κ h x (t - τ) τ - Sm κ h x 0 τ) := by
      simp only [B, C]
      rw [intervalIntegral.integral_sub ((Sm_path_cont κ hc hb x t).intervalIntegrable _ _)
        (hC0.intervalIntegrable _ _)]
    rw [hBC]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := t₀) (b := t)
      (C := κ * M * |t - t₀|)
      (f := fun τ => Sm κ h x (t - τ) τ - Sm κ h x 0 τ) (fun τ hτ => by
        rw [Real.norm_eq_abs]
        exact (Sm_lip κ hκ hc hxc hxxc hb hbx hbxx hd hd2 x τ 0 (t - τ)).trans (by
          have hk : 0 ≤ κ * M := by positivity
          refine mul_le_mul_of_nonneg_left ?_ hk
          rw [sub_zero]
          rcases Set.mem_uIoc.1 hτ with h' | h'
          · rw [abs_of_nonneg (by linarith), abs_of_nonneg (by linarith)]; linarith
          · rw [abs_of_nonpos (by linarith), abs_of_nonpos (by linarith)]; linarith))
    calc _ ≤ κ * M * |t - t₀| * |t - t₀| := this
      _ = κ * M * ‖‖t - t₀‖ ^ 2‖ := by rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_pow, abs_abs, sq]; ring
  convert hAd.add (hCd.add hRd) using 1
  ring

#print axioms Dm_hasDerivAt_t

/-- Duhamel's principle for the forced heat equation on the whole line. Let κ > 0 and let the
source f(x, t) be bounded and continuous, with bounded continuous derivatives f_x, f_xx and f_t.
Add up the fresh starts: u(x, t) = ∫₀ᵗ ∫ G(x − y, t − τ) f(y, τ) dy dτ, each slab f(·, τ) spread
by its own age t − τ. Then u is twice differentiable in x, solves u_t = κ u_xx + f at every
point with t > 0, and tends to 0 as t → 0⁺. (The free part from a start g is the heat kernel
card's blend; adding it solves the whole problem by linearity.) -/
theorem duhamel_fresh_starts_solve_forced_heat_equation (κ : ℝ) (hκ : 0 < κ)
    (f fx fxx ft : ℝ → ℝ → ℝ)
    (hf : Continuous (Function.uncurry f)) (hfx_c : Continuous (Function.uncurry fx))
    (hfxx_c : Continuous (Function.uncurry fxx)) (hft_c : Continuous (Function.uncurry ft))
    (hfx : ∀ x t, HasDerivAt (fun y => f y t) (fx x t) x)
    (hfxx : ∀ x t, HasDerivAt (fun y => fx y t) (fxx x t) x)
    (hft : ∀ x t, HasDerivAt (fun s => f x s) (ft x t) t)
    (hbd : ∃ M, ∀ x t, |f x t| ≤ M ∧ |fx x t| ≤ M ∧ |fxx x t| ≤ M ∧ |ft x t| ≤ M) :
    let u : ℝ → ℝ → ℝ := fun x t =>
      ∫ τ in (0 : ℝ)..t, ∫ y, heatKernel κ (t - τ) (x - y) * f y τ
    (∀ t, 0 < t → ContDiff ℝ 2 (fun x => u x t)) ∧
    (∀ x t, 0 < t →
      HasDerivAt (fun s => u x s) (κ * deriv (deriv (fun z => u z t)) x + f x t) t) ∧
    (∀ x₀, Tendsto (fun p : ℝ × ℝ => u p.1 p.2) (𝓝[{p | 0 < p.2}] (x₀, 0)) (𝓝 0)) := by
  intro u
  obtain ⟨M, hM⟩ := hbd
  have hb : ∀ y τ, |f y τ| ≤ M := fun y τ => (hM y τ).1
  have hbx : ∀ y τ, |fx y τ| ≤ M := fun y τ => (hM y τ).2.1
  have hbxx : ∀ y τ, |fxx y τ| ≤ M := fun y τ => (hM y τ).2.2.1
  have hu : ∀ x t, 0 < t → u x t = Dm κ f x t := by
    intro x t ht
    simp only [u, Dm]
    refine intervalIntegral.integral_congr_ae ?_
    filter_upwards [Measure.ae_ne volume t] with τ hne hτ
    rw [Set.uIoc_of_le ht.le] at hτ
    have hpos : 0 < t - τ := by
      rcases lt_or_eq_of_le hτ.2 with h' | h'
      · linarith
      · exact absurd h' hne
    exact heat_eq_Sm κ hκ f x (t - τ) τ hpos
  have hd1 : ∀ t, deriv (fun x => Dm κ f x t) = fun x => Dm κ fx x t := fun t => funext fun x =>
    (Dm_hasDerivAt_x κ hf hfx_c hb hbx hfx x t).deriv
  have hd2 : ∀ t, deriv (fun x => Dm κ fx x t) = fun x => Dm κ fxx x t := fun t => funext fun x =>
    (Dm_hasDerivAt_x κ hfx_c hfxx_c hbx hbxx hfxx x t).deriv
  have hut : ∀ t, 0 < t → (fun x => u x t) = fun x => Dm κ f x t := fun t ht =>
    funext fun x => hu x t ht
  refine ⟨fun t ht => ?_, fun x t ht => ?_, fun x₀ => ?_⟩
  · rw [hut t ht, show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
    refine ⟨fun x => (Dm_hasDerivAt_x κ hf hfx_c hb hbx hfx x t).differentiableAt,
      fun h => absurd h (by decide), ?_⟩
    rw [hd1, contDiff_one_iff_deriv, hd2]
    exact ⟨fun x => (Dm_hasDerivAt_x κ hfx_c hfxx_c hbx hbxx hfxx x t).differentiableAt,
      Dm_continuous_x κ hfxx_c hbxx t⟩
  · rw [hut t ht, hd1, hd2]
    refine (Dm_hasDerivAt_t κ hκ hf hfx_c hfxx_c hb hbx hbxx hfx hfxx x t ht).congr_of_eventuallyEq ?_
    filter_upwards [Ioi_mem_nhds ht] with s hs
    exact hu x s hs
  · refine squeeze_zero_norm' (a := fun p : ℝ × ℝ => M * |p.2|) ?_ ?_
    · filter_upwards [self_mem_nhdsWithin] with p hp
      rw [Real.norm_eq_abs, hu p.1 p.2 hp]
      exact Dm_abs_le κ hb p.1 p.2
    · refine tendsto_nhdsWithin_of_tendsto_nhds ?_
      have : Continuous fun p : ℝ × ℝ => M * |p.2| := by fun_prop
      simpa using this.tendsto (x₀, 0)

/-- The point heater, worked to a closed form: under a point source of strength Q that has run
for a time t_on, the sum of the fresh starts by age, Q ∫₀^{t_on} G(0, a) da, equals
Q √(t_on/(πκ)). So the rise under the band grows as the square root of the run time. -/
theorem point_heater_rise_under_band (κ Q t_on : ℝ) (hκ : 0 < κ) (hton : 0 ≤ t_on) :
    Q * ∫ a in (0 : ℝ)..t_on, heatKernel κ a 0 = Q * Real.sqrt (t_on / (π * κ)) := by
  have hc : 0 < 4 * π * κ := by positivity
  have h1 : ∀ a ∈ Set.uIcc (0:ℝ) t_on, heatKernel κ a 0 = (Real.sqrt (4 * π * κ))⁻¹ * a ^ (-(1/2:ℝ)) := by
    intro a ha
    rw [Set.uIcc_of_le hton] at ha
    have ha0 : 0 ≤ a := ha.1
    unfold heatKernel
    rw [Real.rpow_neg ha0, ← Real.sqrt_eq_rpow, Real.sqrt_mul hc.le]
    simp [mul_comm]
  rw [intervalIntegral.integral_congr h1, intervalIntegral.integral_const_mul,
    integral_rpow (Or.inl (by norm_num))]
  congr 1
  rw [Real.zero_rpow (by norm_num), show (-(1/2:ℝ)) + 1 = 1/2 by norm_num, ← Real.sqrt_eq_rpow,
    Real.sqrt_div' _ (by positivity : 0 ≤ π * κ)]
  have : Real.sqrt (4 * π * κ) = 2 * Real.sqrt (π * κ) := by
    rw [show 4 * π * κ = 2^2 * (π * κ) by ring, Real.sqrt_mul (by norm_num), Real.sqrt_sq (by norm_num)]
  rw [this]
  have : 0 < Real.sqrt (π * κ) := Real.sqrt_pos.2 (by positivity)
  field_simp
  ring

/-- The same recipe for waves: a point force F switched on at t₀ on a wire of mass μ per metre and
wave speed c > 0 launches, at each moment τ, a d'Alembert box of height F/(2μc) covering
|x| < c(t − τ). Stacking the boxes from t₀ to t gives the growing tent
u(x, t) = F/(2μc) · max(0, t − t₀ − |x|/c). -/
theorem wave_point_force_boxes_stack_to_tent (c F μ t₀ x t : ℝ) (hc : 0 < c) :
    (∫ τ in t₀..t, if |x| < c * (t - τ) then F / (2 * μ * c) else 0)
      = F / (2 * μ * c) * max 0 (t - t₀ - |x| / c) := by
  set k := F / (2 * μ * c)
  set s := t - |x| / c
  have hiff : ∀ τ, |x| < c * (t - τ) ↔ τ < s := by
    intro τ
    simp only [s]
    rw [← div_lt_iff₀' hc]
    constructor <;> intro h <;> linarith
  have hfun : (fun τ => if |x| < c * (t - τ) then k else 0) = Set.indicator (Set.Iio s) (fun _ => k) := by
    funext τ
    simp only [Set.indicator, Set.mem_Iio, hiff]
  rw [hfun]
  have hs_le : s ≤ t := by simp only [s]; have := abs_nonneg x; have : 0 ≤ |x| / c := by positivity
                           linarith
  rcases le_total t₀ t with h | h
  · rw [intervalIntegral.integral_of_le h, integral_indicator measurableSet_Iio, Measure.restrict_restrict measurableSet_Iio,
      setIntegral_const]
    have hset : Set.Iio s ∩ Set.Ioc t₀ t = Set.Ioo t₀ s := by
      ext τ; simp only [Set.mem_inter_iff, Set.mem_Iio, Set.mem_Ioc, Set.mem_Ioo]
      constructor
      · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, by linarith⟩
    rw [hset, Measure.real, Real.volume_Ioo, ENNReal.toReal_ofReal', smul_eq_mul, mul_comm]
    congr 1
    simp only [s]; rw [max_comm]; ring_nf
  · rw [intervalIntegral.integral_symm, intervalIntegral.integral_of_le h, integral_indicator measurableSet_Iio,
      Measure.restrict_restrict measurableSet_Iio]
    have hset : Set.Iio s ∩ Set.Ioc t t₀ = ∅ := by
      ext τ; simp only [Set.mem_inter_iff, Set.mem_Iio, Set.mem_Ioc, Set.mem_empty_iff_false, iff_false]
      rintro ⟨h1, h2, _⟩; linarith
    rw [hset]
    have : t - t₀ - |x| / c ≤ 0 := by have : 0 ≤ |x| / c := by positivity
                                      linarith
    simp [max_eq_left this]

-- Worked numbers from the card, in exact fractions.
-- Heat capacity per metre of rod: ρc_p · A = 3.45 × 10⁶ × 10⁻⁴ = 345 J/(K m).
example : (345 * 10 ^ 4 : ℚ) * (1 / 10 ^ 4) = 345 := by norm_num
-- Source strength Q = P/(ρ c_p A) = 10/345 = 2/69 K m/s (0.0289855 on the card).
example : (10 : ℚ) / ((345 * 10 ^ 4) * (1 / 10 ^ 4)) = 2 / 69 := by norm_num
-- Slope beside the band: Q/(2κ) = (2/69)/(2 × 1.11 × 10⁻⁴) = 10⁶/7659 K/m (130.565 on the card).
example : (2 / 69 : ℚ) / (2 * (111 / 10 ^ 6)) = 10 ^ 6 / 7659 := by norm_num
-- That slope carries exactly the heater's power out of both sides: 2κ · ρc_p A · Q/(2κ) = 10 W.
example : 2 * (111 / 10 ^ 6 : ℚ) * ((345 * 10 ^ 4) * (1 / 10 ^ 4)) * (10 ^ 6 / 7659) = 10 := by
  norm_num
-- Heat budget: 10 W for 60 s is 600 J.
example : (10 : ℚ) * 60 = 600 := by norm_num
-- Wire: centre speed F/(2μc) = 0.2/(2 × 0.01 × 100) = 1/10 m/s.
example : (1 / 5 : ℚ) / (2 * (1 / 100) * 100) = 1 / 10 := by norm_num
-- Wire: c = √(T_s/μ) = √(100/0.01) = 100 m/s, since 100/0.01 = 100².
example : (100 : ℚ) / (1 / 100) = 100 ^ 2 := by norm_num
-- Wire at 4 ms: centre 0.1 × 0.004 = 0.0004 m (0.4 mm); 0.1 m out, 0.1 × (0.004 − 0.1/100) = 0.0003 m.
example : (1 / 10 : ℚ) * (4 / 1000) = 4 / 10000 := by norm_num
example : (1 / 10 : ℚ) * (4 / 1000 - (1 / 10) / 100) = 3 / 10000 := by norm_num
-- Wire momentum at 4 ms equals the impulse F (t − t₀) = 0.2 × 0.004 = 0.0008 kg m/s.
example : (1 / 5 : ℚ) * (4 / 1000) = 8 / 10000 := by norm_num

#print axioms duhamel_fresh_starts_solve_forced_heat_equation
#print axioms point_heater_rise_under_band
#print axioms wave_point_force_boxes_stack_to_tent
