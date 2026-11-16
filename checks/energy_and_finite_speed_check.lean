-- Wave energy is conserved, and nothing outruns the wave speed: for classical solutions of the string's wave equation, two motions that start alike on a cone's base agree inside the cone, the whole string's energy stays fixed when its ends are fixed or free, and the energy in a window shrinking at the wave speed only leaks out, at the rate of the card's leak formula.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set

/-- Chain rule along a curve `r ↦ (α r, β r)` for a differentiable function of two variables. -/
lemma wave_curve {f : ℝ × ℝ → ℝ} (hf : Differentiable ℝ f) {α β : ℝ → ℝ} {α' β' s : ℝ}
    (hα : HasDerivAt α α' s) (hβ : HasDerivAt β β' s) :
    HasDerivAt (fun r => f (α r, β r))
      (α' * fderiv ℝ f (α s, β s) (1, 0) + β' * fderiv ℝ f (α s, β s) (0, 1)) s := by
  have h2 := (hf (α s, β s)).hasFDerivAt.comp_hasDerivAt s (HasDerivAt.prodMk hα hβ)
  refine h2.congr_deriv ?_
  have : ((α', β') : ℝ × ℝ) = α' • ((1 : ℝ), (0 : ℝ)) + β' • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  rw [this, map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]

lemma wave_d1 {f : ℝ × ℝ → ℝ} (hf : Differentiable ℝ f) (x t : ℝ) :
    HasDerivAt (fun y => f (y, t)) (fderiv ℝ f (x, t) (1, 0)) x := by
  simpa using wave_curve hf (hasDerivAt_id x) (hasDerivAt_const x t)

lemma wave_d2 {f : ℝ × ℝ → ℝ} (hf : Differentiable ℝ f) (x t : ℝ) :
    HasDerivAt (fun s => f (x, s)) (fderiv ℝ f (x, t) (0, 1)) t := by
  simpa using wave_curve hf (hasDerivAt_const t x) (hasDerivAt_id t)

lemma wave_partial_contDiff {U : ℝ × ℝ → ℝ} (hU : ContDiff ℝ 2 U) (v : ℝ × ℝ) :
    ContDiff ℝ 1 (fun z => fderiv ℝ U z v) :=
  (hU.fderiv_right (m := 1) (by norm_num)).clm_apply contDiff_const

lemma wave_mixed {U : ℝ × ℝ → ℝ} (hU : ContDiff ℝ 2 U) (z : ℝ × ℝ) :
    fderiv ℝ (fun z => fderiv ℝ U z (1, 0)) z (0, 1)
      = fderiv ℝ (fun z => fderiv ℝ U z (0, 1)) z (1, 0) := by
  have hd : Differentiable ℝ (fderiv ℝ U) :=
    (hU.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have h : ∀ v w : ℝ × ℝ, fderiv ℝ (fun z => fderiv ℝ U z v) z w = fderiv ℝ (fderiv ℝ U) z w v := by
    intro v w
    rw [fderiv_clm_apply (hd z) (differentiableAt_const v)]
    simp
  rw [h, h]
  exact (hU.contDiffAt.isSymmSndFDerivAt (by simp)) _ _

lemma wave_hasDerivAt_integral {G G' : ℝ → ℝ → ℝ} (a b t₀ : ℝ)
    (hG : Continuous (fun p : ℝ × ℝ => G p.1 p.2))
    (hG' : Continuous (fun p : ℝ × ℝ => G' p.1 p.2))
    (hd : ∀ t θ, HasDerivAt (fun s => G s θ) (G' t θ) t) :
    HasDerivAt (fun t => ∫ θ in a..b, G t θ) (∫ θ in a..b, G' t₀ θ) t₀ := by
  obtain ⟨M, hM⟩ := ((isCompact_closedBall t₀ 1).prod (isCompact_uIcc (a := a) (b := b))).exists_bound_of_continuousOn
    hG'.continuousOn
  have hc : ∀ t, Continuous (G t) := fun t => hG.comp (continuous_const.prodMk continuous_id)
  have hc' : ∀ t, Continuous (G' t) := fun t => hG'.comp (continuous_const.prodMk continuous_id)
  refine (intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le (bound := fun _ => M)
    (Metric.closedBall_mem_nhds t₀ one_pos) ?_ ?_ ?_ ?_ ?_ ?_).2
  · exact Filter.Eventually.of_forall fun t => (hc t).aestronglyMeasurable
  · exact (hc t₀).intervalIntegrable _ _
  · exact (hc' t₀).aestronglyMeasurable
  · exact Filter.Eventually.of_forall fun θ hθ t ht => hM (t, θ) ⟨ht, uIoc_subset_uIcc hθ⟩
  · exact intervalIntegrable_const
  · exact Filter.Eventually.of_forall fun θ _ t _ => hd t θ

lemma wave_integral_pos {f : ℝ → ℝ} {a b x : ℝ} (hf : Continuous f) (h0 : ∀ y, 0 ≤ f y)
    (hx : x ∈ Ioo a b) (hfx : 0 < f x) : 0 < ∫ y in a..b, f y := by
  have hab : a < b := hx.1.trans hx.2
  rw [intervalIntegral.integral_pos_iff_support_of_nonneg_ae (Filter.Eventually.of_forall h0)
    (hf.intervalIntegrable a b)]
  refine ⟨hab, ?_⟩
  have hopen : IsOpen (Function.support f ∩ Ioo a b) := hf.isOpen_support.inter isOpen_Ioo
  exact (hopen.measure_pos MeasureTheory.volume ⟨x, hfx.ne', hx⟩).trans_le
    (MeasureTheory.measure_mono (inter_subset_inter_right _ Ioo_subset_Ioc_self))

/-- First and second partial derivatives of a twice continuously differentiable `u x t`. -/
lemma wave_setup (u : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (Function.uncurry u)) :
    ∃ Ut Ux Utt Utx Uxt Uxx : ℝ × ℝ → ℝ,
      Continuous Ut ∧ Continuous Ux ∧ Continuous Utt ∧ Continuous Utx ∧ Continuous Uxt ∧
      Continuous Uxx ∧
      (∀ x t, HasDerivAt (fun s => u x s) (Ut (x, t)) t) ∧
      (∀ x t, HasDerivAt (fun y => u y t) (Ux (x, t)) x) ∧
      (∀ x t, deriv (fun s => deriv (fun r => u x r) s) t = Utt (x, t)) ∧
      (∀ x t, deriv (fun y => deriv (fun z => u z t) y) x = Uxx (x, t)) ∧
      (∀ z, Uxt z = Utx z) ∧
      (∀ (α β : ℝ → ℝ) (α' β' s : ℝ), HasDerivAt α α' s → HasDerivAt β β' s →
        HasDerivAt (fun r => Ut (α r, β r)) (α' * Utx (α s, β s) + β' * Utt (α s, β s)) s) ∧
      (∀ (α β : ℝ → ℝ) (α' β' s : ℝ), HasDerivAt α α' s → HasDerivAt β β' s →
        HasDerivAt (fun r => Ux (α r, β r)) (α' * Uxx (α s, β s) + β' * Uxt (α s, β s)) s) := by
  have hU : Differentiable ℝ (Function.uncurry u) := hu.differentiable (by norm_num)
  have h1 := wave_partial_contDiff hu ((0 : ℝ), (1 : ℝ))
  have h2 := wave_partial_contDiff hu ((1 : ℝ), (0 : ℝ))
  have dt := h1.differentiable (by norm_num)
  have dx := h2.differentiable (by norm_num)
  have ct := h1.continuous_fderiv (by norm_num)
  have cx := h2.continuous_fderiv (by norm_num)
  refine ⟨fun z => fderiv ℝ (Function.uncurry u) z (0, 1),
    fun z => fderiv ℝ (Function.uncurry u) z (1, 0),
    fun z => fderiv ℝ (fun z => fderiv ℝ (Function.uncurry u) z (0, 1)) z (0, 1),
    fun z => fderiv ℝ (fun z => fderiv ℝ (Function.uncurry u) z (0, 1)) z (1, 0),
    fun z => fderiv ℝ (fun z => fderiv ℝ (Function.uncurry u) z (1, 0)) z (0, 1),
    fun z => fderiv ℝ (fun z => fderiv ℝ (Function.uncurry u) z (1, 0)) z (1, 0),
    h1.continuous, h2.continuous, ct.clm_apply continuous_const, ct.clm_apply continuous_const,
    cx.clm_apply continuous_const, cx.clm_apply continuous_const,
    fun x t => wave_d2 hU x t, fun x t => wave_d1 hU x t, ?_, ?_, fun z => wave_mixed hu z,
    fun α β α' β' s hα hβ => wave_curve dt hα hβ, fun α β α' β' s hα hβ => wave_curve dx hα hβ⟩
  · intro x t
    have : (fun s => deriv (fun r => u x r) s)
        = fun s => fderiv ℝ (Function.uncurry u) (x, s) (0, 1) :=
      funext fun s => (wave_d2 hU x s).deriv
    rw [this]
    exact (wave_d2 dt x t).deriv
  · intro x t
    have : (fun y => deriv (fun z => u z t) y)
        = fun y => fderiv ℝ (Function.uncurry u) (y, t) (1, 0) :=
      funext fun y => (wave_d1 hU y t).deriv
    rw [this]
    exact (wave_d1 dx x t).deriv

/-- The moving-window energy identity, used by the first and third theorems. -/
lemma wave_window_core (ρ T c L x₀ t₀ : ℝ) (u : ℝ → ℝ → ℝ)
    (hρ : 0 < ρ) (hT : 0 < T) (hc : c = Real.sqrt (T / ρ)) (_ht₀ : 0 ≤ t₀)
    (h_base_left : 0 ≤ x₀ - c * t₀) (h_base_right : x₀ + c * t₀ ≤ L)
    (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hu_wave : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ),
      ρ * deriv (fun s => deriv (fun r => u x r) s) t
        = T * deriv (fun y => deriv (fun z => u z t) y) x) :
    let E_W : ℝ → ℝ := fun t =>
      ∫ x in (x₀ - c * (t₀ - t))..(x₀ + c * (t₀ - t)),
        ρ / 2 * deriv (fun s => u x s) t ^ 2 + T / 2 * deriv (fun y => u y t) x ^ 2
    (∀ t ∈ Ioo 0 t₀, HasDerivAt E_W
      (-(ρ * c / 2) *
        ((deriv (fun s => u (x₀ + c * (t₀ - t)) s) t
            - c * deriv (fun y => u y t) (x₀ + c * (t₀ - t))) ^ 2
          + (deriv (fun s => u (x₀ - c * (t₀ - t)) s) t
            + c * deriv (fun y => u y t) (x₀ - c * (t₀ - t))) ^ 2)) t) ∧
    AntitoneOn E_W (Icc 0 t₀) := by
  intro E_W
  obtain ⟨Ut, Ux, Utt, Utx, Uxt, Uxx, cUt, cUx, cUtt, cUtx, cUxt, cUxx, hdt, hdx, hdtt, hdxx,
    hsym, hcurt, hcurx⟩ := wave_setup u hu
  have hdt' : ∀ x t, deriv (fun s => u x s) t = Ut (x, t) := fun x t => (hdt x t).deriv
  have hdx' : ∀ x t, deriv (fun y => u y t) x = Ux (x, t) := fun x t => (hdx x t).deriv
  have hc0 : 0 ≤ c := hc ▸ Real.sqrt_nonneg _
  have hTc : T = ρ * c ^ 2 := by
    rw [hc, Real.sq_sqrt (div_nonneg hT.le hρ.le)]
    field_simp
  have hpde : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ), ρ * Utt (x, t) = T * Uxx (x, t) := by
    intro x hx t ht
    rw [← hdtt, ← hdxx]
    exact hu_wave x hx t ht
  obtain ⟨G, hG⟩ : ∃ G : ℝ → ℝ → ℝ, G = fun t θ => c * (t₀ - t) *
      (ρ / 2 * Ut (c * (t₀ - t) * θ + x₀, t) ^ 2 + T / 2 * Ux (c * (t₀ - t) * θ + x₀, t) ^ 2) :=
    ⟨_, rfl⟩
  obtain ⟨G', hG'⟩ : ∃ G' : ℝ → ℝ → ℝ, G' = fun t θ =>
      -c * (ρ / 2 * Ut (c * (t₀ - t) * θ + x₀, t) ^ 2 + T / 2 * Ux (c * (t₀ - t) * θ + x₀, t) ^ 2)
      + c * (t₀ - t) * (ρ * Ut (c * (t₀ - t) * θ + x₀, t) *
          (-(c * θ) * Utx (c * (t₀ - t) * θ + x₀, t) + Utt (c * (t₀ - t) * θ + x₀, t))
        + T * Ux (c * (t₀ - t) * θ + x₀, t) *
          (-(c * θ) * Uxx (c * (t₀ - t) * θ + x₀, t) + Uxt (c * (t₀ - t) * θ + x₀, t))) :=
    ⟨_, rfl⟩
  have hEW : E_W = fun t => ∫ θ in (-1 : ℝ)..1, G t θ := by
    funext t
    have h := intervalIntegral.smul_integral_comp_mul_add (a := (-1 : ℝ)) (b := 1)
      (f := fun x => ρ / 2 * Ut (x, t) ^ 2 + T / 2 * Ux (x, t) ^ 2) (c * (t₀ - t)) x₀
    rw [show c * (t₀ - t) * (-1) + x₀ = x₀ - c * (t₀ - t) by ring,
      show c * (t₀ - t) * 1 + x₀ = x₀ + c * (t₀ - t) by ring] at h
    simp only [E_W, hdt', hdx']
    rw [← h, hG, smul_eq_mul, ← intervalIntegral.integral_const_mul]
  have hGc : Continuous (fun p : ℝ × ℝ => G p.1 p.2) := by
    rw [hG]; dsimp only; fun_prop
  have hG'c : Continuous (fun p : ℝ × ℝ => G' p.1 p.2) := by
    rw [hG']; dsimp only; fun_prop
  have hGd : ∀ t θ, HasDerivAt (fun s => G s θ) (G' t θ) t := by
    intro t θ
    have hα : HasDerivAt (fun s => c * (t₀ - s) * θ + x₀) (-(c * θ)) t := by
      exact ((((hasDerivAt_id t).const_sub t₀).const_mul c).mul_const θ).add_const x₀
        |>.congr_deriv (by ring)
    have hβ : HasDerivAt (fun s : ℝ => s) 1 t := hasDerivAt_id' t
    have h1 := hcurt _ _ _ _ t hα hβ
    have h2 := hcurx _ _ _ _ t hα hβ
    have hr : HasDerivAt (fun s => c * (t₀ - s)) (-c) t := by
      exact ((hasDerivAt_id t).const_sub t₀).const_mul c |>.congr_deriv (by ring)
    have := hr.fun_mul (((h1.fun_pow 2).const_mul (ρ / 2)).fun_add ((h2.fun_pow 2).const_mul (T / 2)))
    rw [hG, hG']
    refine this.congr_deriv ?_
    simp only [Nat.cast_ofNat, Nat.reduceSub, pow_one]
    ring
  have hall : ∀ t, HasDerivAt E_W (∫ θ in (-1 : ℝ)..1, G' t θ) t := by
    intro t
    rw [hEW]
    exact wave_hasDerivAt_integral (-1) 1 t hGc hG'c hGd
  have hflux : ∀ t ∈ Ioo 0 t₀, ∫ θ in (-1 : ℝ)..1, G' t θ
      = -(ρ * c / 2) * ((Ut (x₀ + c * (t₀ - t), t) - c * Ux (x₀ + c * (t₀ - t), t)) ^ 2
        + (Ut (x₀ - c * (t₀ - t), t) + c * Ux (x₀ - c * (t₀ - t), t)) ^ 2) := by
    intro t ht
    have hr0 : 0 ≤ c * (t₀ - t) := mul_nonneg hc0 (by linarith [ht.2])
    have hr1 : c * (t₀ - t) ≤ c * t₀ := by nlinarith [ht.1]
    have hdom : ∀ θ ∈ uIcc (-1 : ℝ) 1, c * (t₀ - t) * θ + x₀ ∈ Icc 0 L := by
      intro θ hθ
      rw [uIcc_of_le (by norm_num)] at hθ
      have h1 : 0 ≤ c * (t₀ - t) * (θ + 1) := mul_nonneg hr0 (by linarith [hθ.1])
      have h2 : 0 ≤ c * (t₀ - t) * (1 - θ) := mul_nonneg hr0 (by linarith [hθ.2])
      constructor <;> nlinarith
    have hΦ : ∀ θ ∈ uIcc (-1 : ℝ) 1, HasDerivAt (fun θ => θ * (-c) *
        (ρ / 2 * Ut (c * (t₀ - t) * θ + x₀, t) ^ 2 + T / 2 * Ux (c * (t₀ - t) * θ + x₀, t) ^ 2)
        + T * Ut (c * (t₀ - t) * θ + x₀, t) * Ux (c * (t₀ - t) * θ + x₀, t)) (G' t θ) θ := by
      intro θ hθ
      have hα : HasDerivAt (fun θ => c * (t₀ - t) * θ + x₀) (c * (t₀ - t)) θ := by
        simpa using ((hasDerivAt_id θ).const_mul (c * (t₀ - t))).add_const x₀
      have hβ : HasDerivAt (fun _ : ℝ => t) 0 θ := hasDerivAt_const θ t
      have h1 := hcurt _ _ _ _ θ hα hβ
      have h2 := hcurx _ _ _ _ θ hα hβ
      have := (((hasDerivAt_id θ).mul_const (-c)).fun_mul (((h1.fun_pow 2).const_mul (ρ / 2)).fun_add
        ((h2.fun_pow 2).const_mul (T / 2)))).fun_add ((h1.const_mul T).fun_mul h2)
      refine this.congr_deriv ?_
      have hp := hpde _ (hdom θ hθ) t (le_of_lt ht.1)
      have hs := hsym (c * (t₀ - t) * θ + x₀, t)
      rw [hG']
      simp only [Nat.cast_ofNat, Nat.reduceSub, pow_one, id]
      linear_combination -(c * (t₀ - t)) * Ut (c * (t₀ - t) * θ + x₀, t) * hp
        - c * (t₀ - t) * T * Ux (c * (t₀ - t) * θ + x₀, t) * hs
    have hint : IntervalIntegrable (G' t) MeasureTheory.volume (-1) 1 :=
      (hG'c.comp (continuous_const.prodMk continuous_id)).intervalIntegrable _ _
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hΦ hint]
    rw [show c * (t₀ - t) * 1 + x₀ = x₀ + c * (t₀ - t) by ring,
      show c * (t₀ - t) * (-1) + x₀ = x₀ - c * (t₀ - t) by ring]
    linear_combination (Ut (x₀ + c * (t₀ - t), t) * Ux (x₀ + c * (t₀ - t), t)
      - c / 2 * Ux (x₀ + c * (t₀ - t), t) ^ 2 - Ut (x₀ - c * (t₀ - t), t) * Ux (x₀ - c * (t₀ - t), t)
      - c / 2 * Ux (x₀ - c * (t₀ - t), t) ^ 2) * hTc
  refine ⟨fun t ht => ?_, ?_⟩
  · rw [hdt', hdt', hdx', hdx']
    exact (hall t).congr_deriv (hflux t ht)
  · apply antitoneOn_of_deriv_nonpos (convex_Icc 0 t₀)
    · exact (continuous_iff_continuousAt.2 fun t => (hall t).continuousAt).continuousOn
    · exact fun t _ => (hall t).differentiableAt.differentiableWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      rw [(hall t).deriv, hflux t ht, neg_mul, neg_nonpos]
      positivity

#print axioms wave_curve
#print axioms wave_d1
#print axioms wave_d2
#print axioms wave_partial_contDiff
#print axioms wave_mixed
#print axioms wave_hasDerivAt_integral
#print axioms wave_integral_pos
#print axioms wave_setup
#print axioms wave_window_core

/-- Nothing outruns the wave speed (Steps 4 and 5). Let `u x t` and `v x t` be sideways
displacements of a string `0 ≤ x ≤ L`, both classical solutions (twice continuously
differentiable) of the wave equation `u_tt = c^2 u_xx` with wave speed `c > 0`, for all times
`t ≥ 0`. Take a point `x₀` and a time `t₀ ≥ 0` whose cone base, `x₀ - c t₀` to `x₀ + c t₀`,
lies on the string. If the two motions start with the same shape and the same speed on that
base, they agree at every point of the cone `|x - x₀| ≤ c (t₀ - t)`, `0 ≤ t ≤ t₀`. With `v = 0`:
a stretch of string that starts still and straight stays still until a signal from outside can
reach it at speed `c`; in general, two motions with the same start are the same motion, one
cone at a time. -/
theorem nothing_outruns_the_wave_speed (c L x₀ t₀ : ℝ) (u v : ℝ → ℝ → ℝ)
    (hc : 0 < c) (ht₀ : 0 ≤ t₀)
    (h_base_left : 0 ≤ x₀ - c * t₀) (h_base_right : x₀ + c * t₀ ≤ L)
    (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hv : ContDiff ℝ 2 (Function.uncurry v))
    (hu_wave : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ),
      deriv (fun s => deriv (fun r => u x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => u z t) y) x)
    (hv_wave : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ),
      deriv (fun s => deriv (fun r => v x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => v z t) y) x)
    (h_shape : ∀ x ∈ Icc (x₀ - c * t₀) (x₀ + c * t₀), u x 0 = v x 0)
    (h_speed : ∀ x ∈ Icc (x₀ - c * t₀) (x₀ + c * t₀),
      deriv (fun s => u x s) 0 = deriv (fun s => v x s) 0) :
    ∀ t ∈ Icc 0 t₀, ∀ x : ℝ, |x - x₀| ≤ c * (t₀ - t) → u x t = v x t := by
  obtain ⟨Ut, Ux, Utt, Utx, Uxt, Uxx, cUt, cUx, cUtt, cUtx, cUxt, cUxx, hdt, hdx, hdtt, hdxx,
    -, hcurt, hcurx⟩ := wave_setup u hu
  obtain ⟨Vt, Vx, Vtt, Vtx, Vxt, Vxx, cVt, cVx, cVtt, cVtx, cVxt, cVxx, hdtv, hdxv, hdttv, hdxxv,
    -, hcurtv, hcurxv⟩ := wave_setup v hv
  obtain ⟨w, hw⟩ : ∃ w : ℝ → ℝ → ℝ, w = fun x t => u x t - v x t := ⟨_, rfl⟩
  have hwC : ContDiff ℝ 2 (Function.uncurry w) := by
    have : Function.uncurry w = Function.uncurry u - Function.uncurry v := by
      rw [hw]; funext p; rfl
    rw [this]
    exact hu.sub hv
  have hwd : ∀ x s, HasDerivAt (fun r => w x r) (Ut (x, s) - Vt (x, s)) s := by
    intro x s; rw [hw]; exact (hdt x s).sub (hdtv x s)
  have hwt : ∀ x s, deriv (fun r => w x r) s = Ut (x, s) - Vt (x, s) := fun x s => (hwd x s).deriv
  have hwx : ∀ x s, deriv (fun y => w y s) x = Ux (x, s) - Vx (x, s) := by
    intro x s; rw [hw]; exact ((hdx x s).sub (hdxv x s)).deriv
  have hwtt : ∀ x t, deriv (fun s => deriv (fun r => w x r) s) t = Utt (x, t) - Vtt (x, t) := by
    intro x t
    simp only [hwt]
    exact ((hcurt _ _ _ _ t (hasDerivAt_const t x) (hasDerivAt_id' t)).sub
      (hcurtv _ _ _ _ t (hasDerivAt_const t x) (hasDerivAt_id' t))).deriv.trans (by ring)
  have hwxx : ∀ x t, deriv (fun y => deriv (fun z => w z t) y) x = Uxx (x, t) - Vxx (x, t) := by
    intro x t
    simp only [hwx]
    exact ((hcurx _ _ _ _ x (hasDerivAt_id' x) (hasDerivAt_const x t)).sub
      (hcurxv _ _ _ _ x (hasDerivAt_id' x) (hasDerivAt_const x t))).deriv.trans (by ring)
  have hwave : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ),
      1 * deriv (fun s => deriv (fun r => w x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => w z t) y) x := by
    intro x hx t ht
    have h1 := hu_wave x hx t ht
    have h2 := hv_wave x hx t ht
    rw [hdtt, hdxx] at h1
    rw [hdttv, hdxxv] at h2
    rw [hwtt, hwxx]
    linear_combination h1 - h2
  have key := wave_window_core 1 (c ^ 2) c L x₀ t₀ w one_pos (by positivity)
    (by rw [div_one, Real.sqrt_sq hc.le]) ht₀ h_base_left h_base_right hwC hwave
  obtain ⟨-, hanti⟩ := key
  simp only [hwt, hwx] at hanti
  have hE0 : ∫ x in (x₀ - c * (t₀ - 0))..(x₀ + c * (t₀ - 0)),
      1 / 2 * (Ut (x, 0) - Vt (x, 0)) ^ 2 + c ^ 2 / 2 * (Ux (x, 0) - Vx (x, 0)) ^ 2 = 0 := by
    rw [intervalIntegral.integral_of_le (by nlinarith), MeasureTheory.integral_Ioc_eq_integral_Ioo]
    apply MeasureTheory.setIntegral_eq_zero_of_forall_eq_zero
    intro y hy
    rw [sub_zero] at hy
    have hyI : y ∈ Icc (x₀ - c * t₀) (x₀ + c * t₀) := Ioo_subset_Icc_self hy
    have h1 : Ut (y, 0) - Vt (y, 0) = 0 := by
      rw [← (hdt y 0).deriv, ← (hdtv y 0).deriv, h_speed y hyI, sub_self]
    have h2 : Ux (y, 0) - Vx (y, 0) = 0 := by
      rw [← hwx]
      have : (fun z => w z 0) =ᶠ[nhds y] fun _ => 0 :=
        Filter.eventually_of_mem (Ioo_mem_nhds hy.1 hy.2) (fun z hz => by
          rw [hw]; exact sub_eq_zero.2 (h_shape z (Ioo_subset_Icc_self hz)))
      rw [this.deriv_eq]
      simp
    rw [h1, h2]
    ring
  have hz : ∀ s ∈ Icc 0 t₀, ∀ y ∈ Ioo (x₀ - c * (t₀ - s)) (x₀ + c * (t₀ - s)),
      Ut (y, s) - Vt (y, s) = 0 := by
    intro s hs y hy
    by_contra hne
    have hd : 0 < (Ut (y, s) - Vt (y, s)) ^ 2 :=
      lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hne))
    have hpos : 0 < ∫ x in (x₀ - c * (t₀ - s))..(x₀ + c * (t₀ - s)),
        1 / 2 * (Ut (x, s) - Vt (x, s)) ^ 2 + c ^ 2 / 2 * (Ux (x, s) - Vx (x, s)) ^ 2 := by
      refine wave_integral_pos (by fun_prop) (fun z => by positivity) hy ?_
      nlinarith [mul_nonneg (sq_nonneg c) (sq_nonneg (Ux (y, s) - Vx (y, s)))]
    have hle := hanti ⟨le_refl 0, ht₀⟩ hs hs.1
    linarith
  intro t ht x hx
  rw [abs_le] at hx
  have hxbase : x ∈ Icc (x₀ - c * t₀) (x₀ + c * t₀) := by
    constructor <;> nlinarith [ht.1, hc.le]
  have hw0 : w x 0 = 0 := by
    rw [hw]; exact sub_eq_zero.2 (h_shape x hxbase)
  rcases eq_or_lt_of_le ht.1 with h0 | hpos
  · rw [← h0]; exact h_shape x hxbase
  · obtain ⟨d, hd, hslope⟩ := exists_hasDerivAt_eq_slope (fun s => w x s)
      (fun s => Ut (x, s) - Vt (x, s)) hpos
      (fun s _ => (hwd x s).continuousAt.continuousWithinAt) (fun s _ => hwd x s)
    have hdt' : c * (t₀ - t) < c * (t₀ - d) := mul_lt_mul_of_pos_left (by linarith [hd.2]) hc
    rw [hz d ⟨hd.1.le, by linarith [hd.2, ht.2]⟩ x ⟨by linarith [hx.1], by linarith [hx.2]⟩,
      eq_comm, div_eq_zero_iff, hw0] at hslope
    rcases hslope with h' | h'
    · rw [hw] at h'
      exact sub_eq_zero.1 (by simpa using h')
    · linarith

/-- The whole string keeps its energy (Step 2). Let `u x t` be a classical solution (twice
continuously differentiable) of `ρ u_tt = T u_xx` on the string `0 ≤ x ≤ L`, `L > 0`, for all
times `t ≥ 0`, with mass per metre `ρ > 0` and tension `T > 0`, and no friction or driving
force. Let each end be fixed (`u = 0` there) or free (slope `u_x = 0` there) at all times. Then
the energy `E(t) = ∫₀ᴸ ((ρ/2) u_t^2 + (T/2) u_x^2) dx`, motion plus stretch, is the same at
every time `t ≥ 0` as at the start. -/
theorem string_energy_is_conserved (ρ T L : ℝ) (u : ℝ → ℝ → ℝ)
    (hρ : 0 < ρ) (hT : 0 < T) (hL : 0 < L)
    (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hu_wave : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ),
      ρ * deriv (fun s => deriv (fun r => u x r) s) t
        = T * deriv (fun y => deriv (fun z => u z t) y) x)
    (h_bridge : (∀ t ∈ Ici (0 : ℝ), u 0 t = 0) ∨
      (∀ t ∈ Ici (0 : ℝ), deriv (fun y => u y t) 0 = 0))
    (h_nut : (∀ t ∈ Ici (0 : ℝ), u L t = 0) ∨
      (∀ t ∈ Ici (0 : ℝ), deriv (fun y => u y t) L = 0)) :
    ∀ t ∈ Ici (0 : ℝ),
      (∫ x in (0 : ℝ)..L,
          ρ / 2 * deriv (fun s => u x s) t ^ 2 + T / 2 * deriv (fun y => u y t) x ^ 2)
        = ∫ x in (0 : ℝ)..L,
          ρ / 2 * deriv (fun s => u x s) 0 ^ 2 + T / 2 * deriv (fun y => u y 0) x ^ 2 := by
  obtain ⟨Ut, Ux, Utt, Utx, Uxt, Uxx, cUt, cUx, cUtt, cUtx, cUxt, cUxx, hdt, hdx, hdtt, hdxx,
    hsym, hcurt, hcurx⟩ := wave_setup u hu
  have hdt' : ∀ x t, deriv (fun s => u x s) t = Ut (x, t) := fun x t => (hdt x t).deriv
  have hdx' : ∀ x t, deriv (fun y => u y t) x = Ux (x, t) := fun x t => (hdx x t).deriv
  have hpde : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ), ρ * Utt (x, t) = T * Uxx (x, t) := by
    intro x hx t ht
    rw [← hdtt, ← hdxx]
    exact hu_wave x hx t ht
  obtain ⟨G, hG⟩ : ∃ G : ℝ → ℝ → ℝ,
      G = fun t x => ρ / 2 * Ut (x, t) ^ 2 + T / 2 * Ux (x, t) ^ 2 := ⟨_, rfl⟩
  obtain ⟨G', hG'⟩ : ∃ G' : ℝ → ℝ → ℝ,
      G' = fun t x => ρ * Ut (x, t) * Utt (x, t) + T * Ux (x, t) * Uxt (x, t) := ⟨_, rfl⟩
  have hE : ∀ t, (∫ x in (0 : ℝ)..L,
      ρ / 2 * deriv (fun s => u x s) t ^ 2 + T / 2 * deriv (fun y => u y t) x ^ 2)
        = ∫ x in (0 : ℝ)..L, G t x := by
    intro t
    simp only [hdt', hdx', hG]
  simp only [hE]
  have hGc : Continuous (fun p : ℝ × ℝ => G p.1 p.2) := by
    rw [hG]; dsimp only; fun_prop
  have hG'c : Continuous (fun p : ℝ × ℝ => G' p.1 p.2) := by
    rw [hG']; dsimp only; fun_prop
  have hGd : ∀ t x, HasDerivAt (fun s => G s x) (G' t x) t := by
    intro t x
    have h1 := hcurt _ _ _ _ t (hasDerivAt_const t x) (hasDerivAt_id' t)
    have h2 := hcurx _ _ _ _ t (hasDerivAt_const t x) (hasDerivAt_id' t)
    rw [hG, hG']
    refine (((h1.fun_pow 2).const_mul (ρ / 2)).fun_add ((h2.fun_pow 2).const_mul (T / 2))).congr_deriv ?_
    simp only [Nat.cast_ofNat, Nat.reduceSub, pow_one]
    ring
  have hall : ∀ t, HasDerivAt (fun t => ∫ x in (0 : ℝ)..L, G t x) (∫ x in (0 : ℝ)..L, G' t x) t :=
    fun t => wave_hasDerivAt_integral 0 L t hGc hG'c hGd
  have hend : ∀ t, 0 < t → ∀ y, ((∀ t ∈ Ici (0 : ℝ), u y t = 0) ∨
      (∀ t ∈ Ici (0 : ℝ), deriv (fun x => u x t) y = 0)) → Ut (y, t) * Ux (y, t) = 0 := by
    intro t ht y hy
    rcases hy with h | h
    · have h0 : Ut (y, t) = 0 := by
        rw [← hdt']
        have : (fun s => u y s) =ᶠ[nhds t] fun _ => 0 :=
          Filter.eventually_of_mem (Ioi_mem_nhds ht) (fun s hs => h s (mem_Ici.2 (le_of_lt (mem_Ioi.1 hs))))
        rw [this.deriv_eq]
        simp
      rw [h0, zero_mul]
    · rw [← hdx', h t ht.le, mul_zero]
  have hzero : ∀ t, 0 < t → ∫ x in (0 : ℝ)..L, G' t x = 0 := by
    intro t ht
    have hΦ : ∀ x ∈ uIcc 0 L, HasDerivAt (fun x => T * Ut (x, t) * Ux (x, t)) (G' t x) x := by
      intro x hx
      have h1 := hcurt _ _ _ _ x (hasDerivAt_id' x) (hasDerivAt_const x t)
      have h2 := hcurx _ _ _ _ x (hasDerivAt_id' x) (hasDerivAt_const x t)
      refine ((h1.const_mul T).fun_mul h2).congr_deriv ?_
      rw [uIcc_of_le hL.le] at hx
      have hp := hpde x hx t ht.le
      have hs := hsym (x, t)
      rw [hG']
      linear_combination (-Ut (x, t)) * hp - T * Ux (x, t) * hs
    have hint : IntervalIntegrable (G' t) MeasureTheory.volume 0 L :=
      (hG'c.comp (continuous_const.prodMk continuous_id)).intervalIntegrable _ _
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hΦ hint]
    have h0 := hend t ht 0 h_bridge
    have h1 := hend t ht L h_nut
    linear_combination T * h1 - T * h0
  intro t ht
  rcases eq_or_lt_of_le (show (0 : ℝ) ≤ t from ht) with h | h
  · rw [← h]
  · obtain ⟨d, hd, hslope⟩ := exists_hasDerivAt_eq_slope (fun t => ∫ x in (0 : ℝ)..L, G t x)
      (fun t => ∫ x in (0 : ℝ)..L, G' t x) h
      (continuous_iff_continuousAt.2 fun s => (hall s).continuousAt).continuousOn
      (fun s _ => hall s)
    rw [hzero d hd.1, eq_comm, div_eq_zero_iff] at hslope
    rcases hslope with h' | h'
    · linarith
    · linarith

/-- A window shrinking at the wave speed only leaks (Step 3 and its detailed proof). Let `u` be
a classical solution of `ρ u_tt = T u_xx` on the string `0 ≤ x ≤ L` for all times `t ≥ 0`, with
`ρ > 0`, `T > 0` and wave speed `c = √(T/ρ)`. Take the window from `x₋(t) = x₀ - c (t₀ - t)` to
`x₊(t) = x₀ + c (t₀ - t)`, whose walls move inward at `c`, with its base at `t = 0` on the
string. Its energy `E_W(t) = ∫_{x₋}^{x₊} ((ρ/2) u_t^2 + (T/2) u_x^2) dx` has rate
`dE_W/dt = -(ρ c / 2) [(u_t - c u_x)^2 at x₊ + (u_t + c u_x)^2 at x₋]` for `0 < t < t₀`, and so
it never rises over `0 ≤ t ≤ t₀`. -/
theorem window_energy_only_leaks (ρ T c L x₀ t₀ : ℝ) (u : ℝ → ℝ → ℝ)
    (hρ : 0 < ρ) (hT : 0 < T) (hc : c = Real.sqrt (T / ρ)) (ht₀ : 0 ≤ t₀)
    (h_base_left : 0 ≤ x₀ - c * t₀) (h_base_right : x₀ + c * t₀ ≤ L)
    (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hu_wave : ∀ x ∈ Icc 0 L, ∀ t ∈ Ici (0 : ℝ),
      ρ * deriv (fun s => deriv (fun r => u x r) s) t
        = T * deriv (fun y => deriv (fun z => u z t) y) x) :
    let E_W : ℝ → ℝ := fun t =>
      ∫ x in (x₀ - c * (t₀ - t))..(x₀ + c * (t₀ - t)),
        ρ / 2 * deriv (fun s => u x s) t ^ 2 + T / 2 * deriv (fun y => u y t) x ^ 2
    (∀ t ∈ Ioo 0 t₀, HasDerivAt E_W
      (-(ρ * c / 2) *
        ((deriv (fun s => u (x₀ + c * (t₀ - t)) s) t
            - c * deriv (fun y => u y t) (x₀ + c * (t₀ - t))) ^ 2
          + (deriv (fun s => u (x₀ - c * (t₀ - t)) s) t
            + c * deriv (fun y => u y t) (x₀ - c * (t₀ - t))) ^ 2)) t) ∧
    AntitoneOn E_W (Icc 0 t₀) := by
  exact wave_window_core ρ T c L x₀ t₀ u hρ hT hc ht₀ h_base_left h_base_right hu hu_wave

-- The wall identity from the detailed proof: with T = ρ c^2, -p - c e at the right wall is
-- minus a perfect square (a stands for u_t, b for u_x).
example (ρ c a b : ℝ) :
    -(-(ρ * c ^ 2) * a * b) - c * (ρ / 2 * a ^ 2 + ρ * c ^ 2 / 2 * b ^ 2)
      = -(ρ * c / 2) * (a - c * b) ^ 2 := by ring
-- Worked numbers from the card (65 cm string at 329.63 Hz), as exact fractions.
-- Wave speed: c = 2 L f₁ = 2 × 0.65 × 329.63 = 428.519 m/s, that is 42.8519 cm per ms.
example : (2 : ℚ) * (65 / 100) * (32963 / 100) = 428519 / 1000 := by norm_num
-- The pickup's cone at 0.60 ms: 32.5 ± 42.8519 × 0.60 cm runs from 6.78886 cm to 58.21114 cm.
example : (325 / 10 : ℚ) - 428519 / 10000 * (6 / 10) = 678886 / 100000 ∧
    (325 / 10 : ℚ) + 428519 / 10000 * (6 / 10) = 5821114 / 100000 := by norm_num
-- The tap ends at 6 cm, short of the base's left end, so the pickup is still at 0.60 ms.
example : (6 : ℚ) < 325 / 10 - 428519 / 10000 * (6 / 10) := by norm_num
-- First motion at the pickup: (32.5 - 6) / 42.8519 ms lies between 0.6184 ms and 0.6185 ms.
example : (6184 / 10000 : ℚ) < (325 / 10 - 6) / (428519 / 10000) ∧
    (325 / 10 - 6 : ℚ) / (428519 / 10000) < 6185 / 10000 := by norm_num
-- Timed wrongly from the tap's centre: (32.5 - 5) / 42.8519 ms is between 0.6417 and 0.6418 ms.
example : (6417 / 10000 : ℚ) < (325 / 10 - 5) / (428519 / 10000) ∧
    (325 / 10 - 5 : ℚ) / (428519 / 10000) < 6418 / 10000 := by norm_num
-- A second tap from 54 cm: its front reaches the pickup at (54 - 32.5) / 42.8519 ms, between
-- 0.5017 and 0.5018 ms, so after 0.45 ms and before 0.55 ms.
example : (45 / 100 : ℚ) < 5017 / 10000 ∧
    (5017 / 10000 : ℚ) < (54 - 325 / 10) / (428519 / 10000) ∧
    (54 - 325 / 10 : ℚ) / (428519 / 10000) < 5018 / 10000 ∧ (5018 / 10000 : ℚ) < 55 / 100 := by
  norm_num
-- The bridge window's right wall at 0.20 ms: 10 - 42.8519 × 0.20 = 1.42962 cm.
example : (10 : ℚ) - 428519 / 10000 * (2 / 10) = 142962 / 100000 := by norm_num

#print axioms nothing_outruns_the_wave_speed
#print axioms string_energy_is_conserved
#print axioms window_energy_only_leaks
