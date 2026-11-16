-- Leray's weak solutions: the laminar pipe profile passes the weak form against every test bump that vanishes at the wall, the carrying term does no work on a divergence-free periodic flow, and fast wiggles tend weakly to zero while their squares do not.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.SpecificLimits.Basic

open MeasureTheory Real Filter Topology

lemma leray_hasDerivAt_x (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 1 F) (x y : ℝ) :
    HasDerivAt (fun t => F (t, y)) (fderiv ℝ F (x, y) (1, 0)) x := by
  have h1 := ((hF.differentiable one_ne_zero) (x, y)).hasFDerivAt
  have h2 : HasDerivAt (fun t : ℝ => (t, y)) ((1:ℝ), (0:ℝ)) x :=
    (hasDerivAt_id x).prodMk (hasDerivAt_const x y)
  exact h1.comp_hasDerivAt x h2

lemma leray_hasDerivAt_y (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 1 F) (x y : ℝ) :
    HasDerivAt (fun t => F (x, t)) (fderiv ℝ F (x, y) (0, 1)) y := by
  have h1 := ((hF.differentiable one_ne_zero) (x, y)).hasFDerivAt
  have h2 : HasDerivAt (fun t : ℝ => (x, t)) ((0:ℝ), (1:ℝ)) y :=
    (hasDerivAt_const y x).prodMk (hasDerivAt_id y)
  exact h1.comp_hasDerivAt y h2

lemma leray_cont_fderiv_apply (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 1 F) (v : ℝ × ℝ) :
    Continuous (fun p => fderiv ℝ F p v) :=
  (hF.continuous_fderiv one_ne_zero).clm_apply continuous_const

lemma leray_box_dy (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 1 F)
    (hp : ∀ x y, F (x, y + 2 * π) = F (x, y)) :
    ∫ p in Set.Icc (0:ℝ) (2 * π) ×ˢ Set.Icc (0:ℝ) (2 * π), fderiv ℝ F p (0, 1) = 0 := by
  have hc := leray_cont_fderiv_apply F hF (0, 1)
  rw [Measure.volume_eq_prod, setIntegral_prod]
  · have : ∀ x : ℝ, ∫ y in Set.Icc (0:ℝ) (2 * π), fderiv ℝ F (x, y) (0, 1) = 0 := by
      intro x
      rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le (by positivity)]
      rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
        (fun y _ => leray_hasDerivAt_y F hF x y)]
      · have := hp x 0
        simp only [zero_add] at this
        rw [this]; ring
      · exact (hc.comp (Continuous.prodMk_right x)).intervalIntegrable _ _
    simp [this]
  · exact (hc.continuousOn).integrableOn_compact (isCompact_Icc.prod isCompact_Icc)

lemma leray_box_dx (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 1 F)
    (hp : ∀ x y, F (x + 2 * π, y) = F (x, y)) :
    ∫ p in Set.Icc (0:ℝ) (2 * π) ×ˢ Set.Icc (0:ℝ) (2 * π), fderiv ℝ F p (1, 0) = 0 := by
  have hc := leray_cont_fderiv_apply F hF (1, 0)
  rw [Measure.volume_eq_prod, ← setIntegral_prod_swap, setIntegral_prod]
  · have : ∀ y : ℝ, ∫ x in Set.Icc (0:ℝ) (2 * π), fderiv ℝ F (x, y) (1, 0) = 0 := by
      intro y
      rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le (by positivity)]
      rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
        (fun x _ => leray_hasDerivAt_x F hF x y)]
      · have := hp 0 y
        simp only [zero_add] at this
        rw [this]; ring
      · exact (hc.comp (Continuous.prodMk_left y)).intervalIntegrable _ _
    simp [this]
  · exact ((hc.comp continuous_swap).continuousOn).integrableOn_compact
      (isCompact_Icc.prod isCompact_Icc)

lemma leray_fderiv_wE (w u₁ u₂ : ℝ × ℝ → ℝ) (hw : ContDiff ℝ 1 w) (h₁ : ContDiff ℝ 1 u₁)
    (h₂ : ContDiff ℝ 1 u₂) (p v : ℝ × ℝ) :
    fderiv ℝ (fun q => w q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) p v
      = fderiv ℝ w p v * ((u₁ p ^ 2 + u₂ p ^ 2) / 2)
        + w p * (u₁ p * fderiv ℝ u₁ p v + u₂ p * fderiv ℝ u₂ p v) := by
  have hw' := ((hw.differentiable one_ne_zero) p).hasFDerivAt
  have h₁' := ((h₁.differentiable one_ne_zero) p).hasFDerivAt
  have h₂' := ((h₂.differentiable one_ne_zero) p).hasFDerivAt
  have h := hw'.mul (((h₁'.pow 2).add (h₂'.pow 2)).mul_const (1 / 2 : ℝ))
  have h3 := h.congr_of_eventuallyEq (f₁ := fun q => w q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2))
    (Filter.Eventually.of_forall fun q => by simp only [Pi.mul_apply, Pi.add_apply]; ring)
  rw [h3.fderiv]
  simp
  ring

lemma leray_bump_hasDerivAt (s : ℝ) :
    HasDerivAt (fun s : ℝ => 16 * s ^ 2 * (1 - s) ^ 2) (32 * s * (1 - s) * (1 - 2 * s)) s := by
  have h := (((hasDerivAt_id' s).pow 2).const_mul 16).mul
    (((hasDerivAt_const s (1:ℝ)).sub (hasDerivAt_id' s)).pow 2)
  exact h.congr_deriv (by simp; ring)

lemma leray_bump_deriv_bound (s : ℝ) (hs : s ∈ Set.Ioc (0:ℝ) 1) :
    |32 * s * (1 - s) * (1 - 2 * s)| ≤ 32 := by
  obtain ⟨h0, h1⟩ := hs
  have ha : 0 ≤ s * (1 - s) := by nlinarith
  have hb : s * (1 - s) ≤ 1 := by nlinarith
  have hc : |1 - 2 * s| ≤ 1 := by rw [abs_le]; constructor <;> linarith
  rw [show 32 * s * (1 - s) * (1 - 2 * s) = 32 * (s * (1 - s)) * (1 - 2 * s) by ring,
    abs_mul, abs_mul, abs_of_nonneg ha]
  have := abs_nonneg (1 - 2 * s)
  norm_num
  nlinarith

lemma leray_sin_bump_bound (k : ℝ) (hk : k ≠ 0) :
    |∫ s in (0:ℝ)..1, sin (k * s) * (16 * s ^ 2 * (1 - s) ^ 2)| ≤ 32 / |k| := by
  have he : ∫ s in (0:ℝ)..1, sin (k * s) * (16 * s ^ 2 * (1 - s) ^ 2)
      = ∫ s in (0:ℝ)..1, (16 * s ^ 2 * (1 - s) ^ 2) * sin (k * s) := by
    congr 1; funext s; ring
  have hp := intervalIntegral.integral_mul_deriv_eq_deriv_mul (a := 0) (b := 1)
    (u := fun s : ℝ => 16 * s ^ 2 * (1 - s) ^ 2) (v := fun s => -cos (k * s) / k)
    (u' := fun s => 32 * s * (1 - s) * (1 - 2 * s)) (v' := fun s => sin (k * s))
    (fun s _ => leray_bump_hasDerivAt s)
    (fun s _ => by
      have h := (((hasDerivAt_id' s).const_mul k).cos.neg).div_const k
      exact h.congr_deriv (by field_simp))
    ((by fun_prop : Continuous fun s : ℝ => 32 * s * (1 - s) * (1 - 2 * s)).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun s : ℝ => sin (k * s)).intervalIntegrable _ _)
  rw [he, hp]
  norm_num
  have hb := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := 1)
    (C := 32 / |k|) (f := fun s => 32 * s * (1 - s) * (1 - 2 * s) * (-cos (k * s) / k))
    (fun s hs => by
      rw [Set.uIoc_of_le zero_le_one] at hs
      rw [Real.norm_eq_abs, abs_mul, abs_div, abs_neg]
      have h1 := leray_bump_deriv_bound s hs
      have h2 := abs_cos_le_one (k * s)
      have hk' : 0 < |k| := abs_pos.mpr hk
      rw [mul_div_assoc']
      apply div_le_div_of_nonneg_right _ hk'.le
      nlinarith [abs_nonneg (32 * s * (1 - s) * (1 - 2 * s)), abs_nonneg (cos (k * s))])
  rw [Real.norm_eq_abs] at hb
  simpa using hb

lemma leray_cos_bump_bound (k : ℝ) (hk : k ≠ 0) :
    |∫ s in (0:ℝ)..1, cos (k * s) * (16 * s ^ 2 * (1 - s) ^ 2)| ≤ 32 / |k| := by
  have he : ∫ s in (0:ℝ)..1, cos (k * s) * (16 * s ^ 2 * (1 - s) ^ 2)
      = ∫ s in (0:ℝ)..1, (16 * s ^ 2 * (1 - s) ^ 2) * cos (k * s) := by
    congr 1; funext s; ring
  have hp := intervalIntegral.integral_mul_deriv_eq_deriv_mul (a := 0) (b := 1)
    (u := fun s : ℝ => 16 * s ^ 2 * (1 - s) ^ 2) (v := fun s => sin (k * s) / k)
    (u' := fun s => 32 * s * (1 - s) * (1 - 2 * s)) (v' := fun s => cos (k * s))
    (fun s _ => leray_bump_hasDerivAt s)
    (fun s _ => by
      have h := (((hasDerivAt_id' s).const_mul k).sin).div_const k
      exact h.congr_deriv (by field_simp))
    ((by fun_prop : Continuous fun s : ℝ => 32 * s * (1 - s) * (1 - 2 * s)).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun s : ℝ => cos (k * s)).intervalIntegrable _ _)
  rw [he, hp]
  norm_num
  have hb := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := 1)
    (C := 32 / |k|) (f := fun s => 32 * s * (1 - s) * (1 - 2 * s) * (sin (k * s) / k))
    (fun s hs => by
      rw [Set.uIoc_of_le zero_le_one] at hs
      rw [Real.norm_eq_abs, abs_mul, abs_div]
      have h1 := leray_bump_deriv_bound s hs
      have h2 := abs_sin_le_one (k * s)
      have hk' : 0 < |k| := abs_pos.mpr hk
      rw [mul_div_assoc']
      apply div_le_div_of_nonneg_right _ hk'.le
      nlinarith [abs_nonneg (32 * s * (1 - s) * (1 - 2 * s)), abs_nonneg (sin (k * s))])
  rw [Real.norm_eq_abs] at hb
  simpa using hb

lemma leray_bump_integral :
    ∫ s in (0:ℝ)..1, 16 * s ^ 2 * (1 - s) ^ 2 = 8 / 15 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun s : ℝ => 16 * s ^ 3 / 3 - 8 * s ^ 4 + 16 * s ^ 5 / 5)]
  · norm_num
  · intro s _
    have h := ((((hasDerivAt_id s).pow 3).const_mul 16).div_const 3).sub
      ((((hasDerivAt_id s).pow 4).const_mul 8)) |>.add
      ((((hasDerivAt_id s).pow 5).const_mul 16).div_const 5)
    convert h using 1
    · funext x; simp
    · simp; ring
  · exact (by fun_prop : Continuous fun s : ℝ => 16 * s ^ 2 * (1 - s) ^ 2).intervalIntegrable _ _

lemma leray_tendsto_of_bound (I : ℕ → ℝ) (c : ℝ) (hc : 0 < c)
    (h : ∀ n : ℕ, 1 ≤ n → |I n| ≤ 32 / |c * n|) : Tendsto I atTop (𝓝 0) := by
  apply squeeze_zero_norm' _ (tendsto_const_div_atTop_nhds_zero_nat (32 / c))
  filter_upwards [eventually_ge_atTop 1] with n hn
  rw [Real.norm_eq_abs]
  have hn' : (0:ℝ) < n := by exact_mod_cast hn
  have := h n hn
  rw [abs_of_pos (mul_pos hc hn')] at this
  rw [div_div]
  exact this

#print axioms leray_hasDerivAt_x
#print axioms leray_hasDerivAt_y
#print axioms leray_cont_fderiv_apply
#print axioms leray_box_dy
#print axioms leray_box_dx
#print axioms leray_fderiv_wE
#print axioms leray_bump_hasDerivAt
#print axioms leray_bump_deriv_bound
#print axioms leray_sin_bump_bound
#print axioms leray_cos_bump_bound
#print axioms leray_bump_integral
#print axioms leray_tendsto_of_bound

/-- The pipe, checked (Step 1). In a pipe of radius `R > 0`, the laminar profile
`w(r) = Umax (1 - r²/R²)` with pressure drop `G = 4 μ Umax / R²` satisfies the weak form
against every test field `v = φ(r) e_z` along the pipe: if `φ` is continuously differentiable
and zero on the wall (`φ R = 0`), the friction side `∫ μ w' φ' 2πr dr` over one cross-section
equals the push side `∫ G φ 2πr dr`. Such test fields are divergence-free because they do not
change along the pipe. -/
theorem laminar_profile_is_weak_solution_against_wall_vanishing_tests
    (R μ Umax : ℝ) (hR : 0 < R) (φ : ℝ → ℝ) (hφ : ContDiff ℝ 1 φ) (hwall : φ R = 0) :
    ∫ r in (0:ℝ)..R,
        μ * deriv (fun s => Umax * (1 - (s / R) ^ 2)) r * deriv φ r * (2 * π * r)
      = ∫ r in (0:ℝ)..R, (4 * μ * Umax / R ^ 2) * φ r * (2 * π * r) := by
  have hR0 : R ≠ 0 := hR.ne'
  have hd : ∀ r, deriv (fun s => Umax * (1 - (s / R) ^ 2)) r = Umax * (-(2 * r / R ^ 2)) := by
    intro r
    have h : HasDerivAt (fun s => Umax * (1 - (s / R) ^ 2))
        (Umax * (0 - (2 * (r / R) ^ (2 - 1) * (1 / R)))) r :=
      (((hasDerivAt_id r).div_const R).pow 2 |>.const_sub 1).const_mul Umax |>.congr_deriv
        (by simp)
    rw [h.deriv]
    have : (r / R) ^ (2 - 1) * (1 / R) = r / R ^ 2 := by
      rw [show (2:ℕ) - 1 = 1 from rfl, pow_one]; field_simp
    rw [mul_assoc 2, this]
    ring
  have hL : ∫ r in (0:ℝ)..R,
        μ * deriv (fun s => Umax * (1 - (s / R) ^ 2)) r * deriv φ r * (2 * π * r)
      = (-(4 * π * μ * Umax / R ^ 2)) * ∫ r in (0:ℝ)..R, r ^ 2 * deriv φ r := by
    rw [← intervalIntegral.integral_const_mul]
    congr 1; funext r
    rw [hd]; field_simp; ring
  have hRt : ∫ r in (0:ℝ)..R, (4 * μ * Umax / R ^ 2) * φ r * (2 * π * r)
      = (4 * π * μ * Umax / R ^ 2) * ∫ r in (0:ℝ)..R, (2 * r) * φ r := by
    rw [← intervalIntegral.integral_const_mul]
    congr 1; funext r
    ring
  have hparts : ∫ r in (0:ℝ)..R, r ^ 2 * deriv φ r
      = R ^ 2 * φ R - 0 ^ 2 * φ 0 - ∫ r in (0:ℝ)..R, (2 * r) * φ r := by
    apply intervalIntegral.integral_mul_deriv_eq_deriv_mul
    · intro x _
      simpa using hasDerivAt_pow 2 x
    · intro x _
      exact ((hφ.differentiable one_ne_zero) x).hasDerivAt
    · exact (by fun_prop : Continuous fun r : ℝ => 2 * r).intervalIntegrable _ _
    · exact (hφ.continuous_deriv le_rfl).intervalIntegrable _ _
  rw [hL, hRt, hparts, hwall]
  ring

/-- The carrying term does no work (Step 2), on the card's repeating square box of side `2π`.
For a continuously differentiable velocity field `u = (u₁, u₂)` that repeats with period `2π`
in each direction, `b(u, u, u) = ∫ ((u·∇)u)·u = -½ ∫ (∇·u) |u|²` over the box. So when the flow
is divergence-free, `b(u, u, u) = 0`, and the energy balance follows. -/
theorem carrying_term_equals_minus_half_divergence_energy
    (u₁ u₂ : ℝ × ℝ → ℝ) (h₁ : ContDiff ℝ 1 u₁) (h₂ : ContDiff ℝ 1 u₂)
    (hp₁x : ∀ x y, u₁ (x + 2 * π, y) = u₁ (x, y)) (hp₁y : ∀ x y, u₁ (x, y + 2 * π) = u₁ (x, y))
    (hp₂x : ∀ x y, u₂ (x + 2 * π, y) = u₂ (x, y)) (hp₂y : ∀ x y, u₂ (x, y + 2 * π) = u₂ (x, y)) :
    ∫ p in Set.Icc (0:ℝ) (2 * π) ×ˢ Set.Icc (0:ℝ) (2 * π),
        ((u₁ p * fderiv ℝ u₁ p (1, 0) + u₂ p * fderiv ℝ u₁ p (0, 1)) * u₁ p
          + (u₁ p * fderiv ℝ u₂ p (1, 0) + u₂ p * fderiv ℝ u₂ p (0, 1)) * u₂ p)
      = -(1 / 2) * ∫ p in Set.Icc (0:ℝ) (2 * π) ×ˢ Set.Icc (0:ℝ) (2 * π),
          (fderiv ℝ u₁ p (1, 0) + fderiv ℝ u₂ p (0, 1)) * (u₁ p ^ 2 + u₂ p ^ 2) := by
  set S := Set.Icc (0:ℝ) (2 * π) ×ˢ Set.Icc (0:ℝ) (2 * π) with hS
  have hSc : IsCompact S := isCompact_Icc.prod isCompact_Icc
  have hE : ContDiff ℝ 1 (fun q => (u₁ q ^ 2 + u₂ q ^ 2) / 2) :=
    ((h₁.pow 2).add (h₂.pow 2)).div_const 2
  have hF₁ : ContDiff ℝ 1 (fun q => u₁ q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) := h₁.mul hE
  have hF₂ : ContDiff ℝ 1 (fun q => u₂ q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) := h₂.mul hE
  have I₁ := leray_box_dx _ hF₁ (fun x y => by simp only [hp₁x, hp₂x])
  have I₂ := leray_box_dy _ hF₂ (fun x y => by simp only [hp₁y, hp₂y])
  have c₁ := leray_cont_fderiv_apply u₁ h₁ (1, 0)
  have c₂ := leray_cont_fderiv_apply u₁ h₁ (0, 1)
  have c₃ := leray_cont_fderiv_apply u₂ h₂ (1, 0)
  have c₄ := leray_cont_fderiv_apply u₂ h₂ (0, 1)
  have k₁ := h₁.continuous
  have k₂ := h₂.continuous
  have iL : IntegrableOn (fun p => (u₁ p * fderiv ℝ u₁ p (1, 0) + u₂ p * fderiv ℝ u₁ p (0, 1))
      * u₁ p + (u₁ p * fderiv ℝ u₂ p (1, 0) + u₂ p * fderiv ℝ u₂ p (0, 1)) * u₂ p) S :=
    (by fun_prop : Continuous _).continuousOn.integrableOn_compact hSc
  have iR : IntegrableOn (fun p => (1 / 2) * ((fderiv ℝ u₁ p (1, 0) + fderiv ℝ u₂ p (0, 1))
      * (u₁ p ^ 2 + u₂ p ^ 2))) S :=
    (by fun_prop : Continuous _).continuousOn.integrableOn_compact hSc
  have iF₁ : IntegrableOn (fun p => fderiv ℝ (fun q => u₁ q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) p
      (1, 0)) S :=
    (leray_cont_fderiv_apply _ hF₁ _).continuousOn.integrableOn_compact hSc
  have iF₂ : IntegrableOn (fun p => fderiv ℝ (fun q => u₂ q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) p
      (0, 1)) S :=
    (leray_cont_fderiv_apply _ hF₂ _).continuousOn.integrableOn_compact hSc
  have hsum := integral_add iF₁ iF₂
  rw [I₁, I₂, add_zero] at hsum
  have hsum2 := integral_add iL iR
  have hpt : ∀ p, fderiv ℝ (fun q => u₁ q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) p (1, 0)
      + fderiv ℝ (fun q => u₂ q * ((u₁ q ^ 2 + u₂ q ^ 2) / 2)) p (0, 1)
      = ((u₁ p * fderiv ℝ u₁ p (1, 0) + u₂ p * fderiv ℝ u₁ p (0, 1)) * u₁ p
          + (u₁ p * fderiv ℝ u₂ p (1, 0) + u₂ p * fderiv ℝ u₂ p (0, 1)) * u₂ p)
        + (1 / 2) * ((fderiv ℝ u₁ p (1, 0) + fderiv ℝ u₂ p (0, 1)) * (u₁ p ^ 2 + u₂ p ^ 2)) := by
    intro p
    rw [leray_fderiv_wE _ _ _ h₁ h₁ h₂, leray_fderiv_wE _ _ _ h₂ h₁ h₂]
    ring
  simp_rw [hpt] at hsum
  rw [hsum2, integral_const_mul] at hsum
  linarith

/-- Weak is not strong (Step 4). Against the bump `φ(s) = 16 s² (1 - s)²` across the diameter,
the wiggles `sin(nπs)` average to zero as `n` grows, but their squares average to `4/15`
(the card's 0.266667), not to zero. -/
theorem wiggles_converge_weakly_but_not_their_squares :
    Tendsto (fun n : ℕ => ∫ s in (0:ℝ)..1, sin (n * π * s) * (16 * s ^ 2 * (1 - s) ^ 2))
        atTop (𝓝 0) ∧
      Tendsto (fun n : ℕ => ∫ s in (0:ℝ)..1, sin (n * π * s) ^ 2 * (16 * s ^ 2 * (1 - s) ^ 2))
        atTop (𝓝 (4 / 15)) := by
  constructor
  · apply leray_tendsto_of_bound _ π pi_pos
    intro n hn
    have hn' : (0:ℝ) < n := by exact_mod_cast hn
    have := leray_sin_bump_bound (n * π) (mul_pos hn' pi_pos).ne'
    rw [mul_comm (n:ℝ) π] at this ⊢
    exact this
  · have hJ : Tendsto (fun n : ℕ =>
        ∫ s in (0:ℝ)..1, cos ((2 * n * π) * s) * (16 * s ^ 2 * (1 - s) ^ 2)) atTop (𝓝 0) := by
      apply leray_tendsto_of_bound _ (2 * π) (by positivity)
      intro n hn
      have hn' : (0:ℝ) < n := by exact_mod_cast hn
      have := leray_cos_bump_bound (2 * n * π) (by positivity)
      rwa [show (2 * π * n : ℝ) = 2 * n * π by ring]
    have hfun : (fun n : ℕ => ∫ s in (0:ℝ)..1, sin (n * π * s) ^ 2 * (16 * s ^ 2 * (1 - s) ^ 2))
        = fun n : ℕ => 4 / 15 - (1 / 2) *
          ∫ s in (0:ℝ)..1, cos ((2 * n * π) * s) * (16 * s ^ 2 * (1 - s) ^ 2) := by
      funext n
      have e : ∀ s : ℝ, sin (n * π * s) ^ 2 * (16 * s ^ 2 * (1 - s) ^ 2)
          = (1 / 2) * (16 * s ^ 2 * (1 - s) ^ 2)
            - (1 / 2) * (cos ((2 * n * π) * s) * (16 * s ^ 2 * (1 - s) ^ 2)) := by
        intro s
        rw [sin_sq_eq_half_sub, show 2 * (n * π * s) = 2 * n * π * s by ring]
        ring
      simp_rw [e]
      rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul,
        intervalIntegral.integral_const_mul, leray_bump_integral]
      · norm_num
      · exact (by fun_prop : Continuous fun s : ℝ =>
          (1 / 2) * (16 * s ^ 2 * (1 - s) ^ 2)).intervalIntegrable _ _
      · exact (by fun_prop : Continuous fun s : ℝ =>
          (1 / 2) * (cos ((2 * n * π) * s) * (16 * s ^ 2 * (1 - s) ^ 2))).intervalIntegrable _ _
    rw [hfun]
    have := (tendsto_const_nhds (x := (4 / 15 : ℝ))).sub (hJ.const_mul (1 / 2))
    rw [mul_zero, sub_zero] at this
    exact this

-- Worked numbers, by hand, in exact fractions (R = 1/40 m, mean speed 1 m/s,
-- centre speed 2 m/s, μ = 1/1000 Pa s, ν = 1/1000000 m²/s).
-- Reynolds number: 1 × 0.05 ÷ 0.000001 = 50,000.
example : (1 * (5 / 100) / (1 / 1000000) : ℚ) = 50000 := by norm_num
-- Pressure drop G = 4 μ Umax / R² = 12.8 Pa/m.
example : (4 * (1 / 1000) * 2 / (1 / 40) ^ 2 : ℚ) = 64 / 5 := by norm_num
-- Wall stress 2 μ Umax / R = 0.16 Pa.
example : (2 * (1 / 1000) * 2 / (1 / 40) : ℚ) = 4 / 25 := by norm_num
-- Wall drag per metre equals the push on the whole cross-section (both 0.008 π N/m).
example : (4 / 25 * 2 * (1 / 40) : ℚ) = 64 / 5 * (1 / 40) ^ 2 := by norm_num
-- Bump A: friction side π μ Umax equals push side G π R² / 4 (both π/500 N/m).
example : ((1 / 1000) * 2 : ℚ) = 64 / 5 * (1 / 40) ^ 2 / 4 := by norm_num
-- Mistake: the mean speed in 4 μ U / R² gives 6.4 Pa/m.
example : (4 * (1 / 1000) * 1 / (1 / 40) ^ 2 : ℚ) = 32 / 5 := by norm_num
-- The squares' limit: half of ∫ φ = 16 · (1/30) = 8/15.
example : (16 * (1 / 30) / 2 : ℚ) = 4 / 15 := by norm_num

#print axioms laminar_profile_is_weak_solution_against_wall_vanishing_tests
#print axioms carrying_term_equals_minus_half_divergence_energy
#print axioms wiggles_converge_weakly_but_not_their_squares
