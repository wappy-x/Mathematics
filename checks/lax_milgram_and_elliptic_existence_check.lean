-- Lax-Milgram: a conductivity held between two positive constants gives exactly one weak solution of steady heat, with slope size at most the load's size over the smallest conductivity.
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Function.LpOrder
import Mathlib.Analysis.InnerProductSpace.LaxMilgram

open MeasureTheory

theorem lm_integrable_mul {X : Type*} [MeasurableSpace X] {μ : Measure X} (g h : Lp ℝ 2 μ) :
    Integrable (fun x => (g : X → ℝ) x * (h : X → ℝ) x) μ := by
  have := L2.integrable_inner (𝕜 := ℝ) g h
  simpa [mul_comm] using this

theorem lm_integral_mul_eq_inner {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (g h : Lp ℝ 2 μ) :
    ∫ x, (g : X → ℝ) x * (h : X → ℝ) x ∂μ = inner ℝ g h := by
  rw [L2.inner_def]
  simp [mul_comm]

theorem lm_integral_abs_mul_le {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (g h : Lp ℝ 2 μ) :
    ∫ x, |(g : X → ℝ) x| * |(h : X → ℝ) x| ∂μ ≤ ‖g‖ * ‖h‖ := by
  have e : ∫ x, |(g : X → ℝ) x| * |(h : X → ℝ) x| ∂μ
      = ∫ x, ((|g| : Lp ℝ 2 μ) : X → ℝ) x * ((|h| : Lp ℝ 2 μ) : X → ℝ) x ∂μ := by
    apply integral_congr_ae
    filter_upwards [Lp.coeFn_abs g, Lp.coeFn_abs h] with x hg hh
    rw [hg, hh]
  rw [e, lm_integral_mul_eq_inner, ← norm_abs_eq_norm g, ← norm_abs_eq_norm h]
  exact real_inner_le_norm _ _

theorem lm_integrable_kmul {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (hk : Measurable k) (C : ℝ) (hC : ∀ x, |k x| ≤ C) (g h : Lp ℝ 2 μ) :
    Integrable (fun x => k x * (g : X → ℝ) x * (h : X → ℝ) x) μ := by
  have := (lm_integrable_mul g h).bdd_mul (c := C) hk.aestronglyMeasurable
    (Filter.Eventually.of_forall fun x => by simpa using hC x)
  simpa [mul_assoc] using this

theorem lm_form_add_left {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (hk : Measurable k) (C : ℝ) (hC : ∀ x, |k x| ≤ C) (g₁ g₂ h : Lp ℝ 2 μ) :
    ∫ x, k x * ((g₁ + g₂ : Lp ℝ 2 μ) : X → ℝ) x * (h : X → ℝ) x ∂μ
      = ∫ x, k x * (g₁ : X → ℝ) x * (h : X → ℝ) x ∂μ
        + ∫ x, k x * (g₂ : X → ℝ) x * (h : X → ℝ) x ∂μ := by
  rw [← integral_add (lm_integrable_kmul k hk C hC g₁ h) (lm_integrable_kmul k hk C hC g₂ h)]
  apply integral_congr_ae
  filter_upwards [Lp.coeFn_add g₁ g₂] with x hx
  rw [hx]; simp only [Pi.add_apply]; ring

theorem lm_form_add_right {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (hk : Measurable k) (C : ℝ) (hC : ∀ x, |k x| ≤ C) (g h₁ h₂ : Lp ℝ 2 μ) :
    ∫ x, k x * (g : X → ℝ) x * ((h₁ + h₂ : Lp ℝ 2 μ) : X → ℝ) x ∂μ
      = ∫ x, k x * (g : X → ℝ) x * (h₁ : X → ℝ) x ∂μ
        + ∫ x, k x * (g : X → ℝ) x * (h₂ : X → ℝ) x ∂μ := by
  rw [← integral_add (lm_integrable_kmul k hk C hC g h₁) (lm_integrable_kmul k hk C hC g h₂)]
  apply integral_congr_ae
  filter_upwards [Lp.coeFn_add h₁ h₂] with x hx
  rw [hx]; simp only [Pi.add_apply]; ring

theorem lm_form_smul_left {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (c : ℝ) (g h : Lp ℝ 2 μ) :
    ∫ x, k x * ((c • g : Lp ℝ 2 μ) : X → ℝ) x * (h : X → ℝ) x ∂μ
      = c * ∫ x, k x * (g : X → ℝ) x * (h : X → ℝ) x ∂μ := by
  rw [← integral_const_mul]
  apply integral_congr_ae
  filter_upwards [Lp.coeFn_smul c g] with x hx
  rw [hx]; simp only [Pi.smul_apply, smul_eq_mul]; ring

theorem lm_form_smul_right {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (c : ℝ) (g h : Lp ℝ 2 μ) :
    ∫ x, k x * (g : X → ℝ) x * ((c • h : Lp ℝ 2 μ) : X → ℝ) x ∂μ
      = c * ∫ x, k x * (g : X → ℝ) x * (h : X → ℝ) x ∂μ := by
  rw [← integral_const_mul]
  apply integral_congr_ae
  filter_upwards [Lp.coeFn_smul c h] with x hx
  rw [hx]; simp only [Pi.smul_apply, smul_eq_mul]; ring

theorem lm_cs_interval {a b : ℝ} (hab : a ≤ b) (g : ℝ → ℝ)
    (hg : IntervalIntegrable g volume a b)
    (hg2 : IntervalIntegrable (fun t => g t ^ 2) volume a b) :
    (∫ t in a..b, g t) ^ 2 ≤ (b - a) * ∫ t in a..b, g t ^ 2 := by
  set G := ∫ t in a..b, g t with hG
  set G2 := ∫ t in a..b, g t ^ 2 with hG2
  have hnn : 0 ≤ ∫ t in a..b, ((b - a) * g t - G) ^ 2 :=
    intervalIntegral.integral_nonneg hab (fun t _ => sq_nonneg _)
  have hexp : ∫ t in a..b, ((b - a) * g t - G) ^ 2
      = (b - a) ^ 2 * G2 - 2 * (b - a) * G * G + G ^ 2 * (b - a) := by
    have e : ∀ t, ((b - a) * g t - G) ^ 2
        = ((b - a) ^ 2 * g t ^ 2 - (2 * (b - a) * G) * g t) + G ^ 2 := fun t => by ring
    simp_rw [e]
    rw [intervalIntegral.integral_add ((hg2.const_mul _).sub (hg.const_mul _))
        intervalIntegrable_const,
      intervalIntegral.integral_sub (hg2.const_mul _) (hg.const_mul _),
      intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const, smul_eq_mul]
    ring
  rw [hexp] at hnn
  rcases hab.eq_or_lt with h | h
  · subst h
    simp [hG]
  · have hba : 0 < b - a := sub_pos.2 h
    have : 0 ≤ (b - a) * ((b - a) * G2 - G ^ 2) := by nlinarith
    nlinarith [(mul_nonneg_iff_of_pos_left hba).1 this]

theorem lm_energy_form {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (hk : Measurable k) (kmin kmax : ℝ) (hkmin : 0 < kmin)
    (hbounds : ∀ x, kmin ≤ k x ∧ k x ≤ kmax) (g h : Lp ℝ 2 μ) :
    |∫ x, k x * (g : X → ℝ) x * (h : X → ℝ) x ∂μ| ≤ kmax * ‖g‖ * ‖h‖ ∧
    kmin * ‖g‖ ^ 2 ≤ ∫ x, k x * (g : X → ℝ) x * (g : X → ℝ) x ∂μ := by
  have hkabs : ∀ x, |k x| ≤ kmax := fun x =>
    abs_le.2 ⟨by linarith [hbounds x], (hbounds x).2⟩
  rcases isEmpty_or_nonempty X with hX | hX
  · have hg : g = 0 := Lp.ext (Filter.Eventually.of_forall fun x => isEmptyElim x)
    subst hg
    simp [integral_of_isEmpty]
  constructor
  · calc |∫ x, k x * (g : X → ℝ) x * (h : X → ℝ) x ∂μ|
        ≤ ∫ x, |k x * (g : X → ℝ) x * (h : X → ℝ) x| ∂μ := abs_integral_le_integral_abs
      _ ≤ ∫ x, kmax * (|(g : X → ℝ) x| * |(h : X → ℝ) x|) ∂μ := by
          apply integral_mono (lm_integrable_kmul k hk kmax hkabs g h).abs
            ((lm_integrable_mul g h).abs.const_mul kmax |>.congr
              (Filter.Eventually.of_forall fun x => by simp [abs_mul]))
          intro x
          dsimp only
          rw [abs_mul, abs_mul, mul_assoc]
          exact mul_le_mul_of_nonneg_right (hkabs x) (by positivity)
      _ = kmax * ∫ x, |(g : X → ℝ) x| * |(h : X → ℝ) x| ∂μ := integral_const_mul _ _
      _ ≤ kmax * (‖g‖ * ‖h‖) := by
          apply mul_le_mul_of_nonneg_left (lm_integral_abs_mul_le g h)
          linarith [hbounds (Classical.arbitrary X)]
      _ = kmax * ‖g‖ * ‖h‖ := by ring
  · calc kmin * ‖g‖ ^ 2 = ∫ x, kmin * ((g : X → ℝ) x * (g : X → ℝ) x) ∂μ := by
          rw [integral_const_mul, lm_integral_mul_eq_inner, real_inner_self_eq_norm_sq]
      _ ≤ ∫ x, k x * (g : X → ℝ) x * (g : X → ℝ) x ∂μ := by
          apply integral_mono ((lm_integrable_mul g g).const_mul kmin)
            (lm_integrable_kmul k hk kmax hkabs g g)
          intro x
          dsimp only
          rw [mul_assoc]
          exact mul_le_mul_of_nonneg_right (hbounds x).1 (mul_self_nonneg _)

#print axioms lm_integrable_mul
#print axioms lm_integral_mul_eq_inner
#print axioms lm_integral_abs_mul_le
#print axioms lm_integrable_kmul
#print axioms lm_form_add_left
#print axioms lm_form_add_right
#print axioms lm_form_smul_left
#print axioms lm_form_smul_right
#print axioms lm_cs_interval
#print axioms lm_energy_form

/-- **Lax-Milgram for steady heat.** Work with the slopes of the temperature profiles: they form a
closed subspace `V` of the square-integrable functions (for the wall, the slopes `u'` of the
profiles in `H^1_0(0, L)`, where the slope size `‖u'‖` is the size used on the card). The energy
form is `a(u, v) = ∫ k u' v'`. If the conductivity `k` is measurable and lies between
`k_min > 0` and `k_max` everywhere, then for every bounded load `ℓ` there is exactly one `u` with
`a(u, v) = ℓ(v)` for every test slope `v`, and every such solution has slope size at most
`‖ℓ‖ / k_min`. -/
theorem lax_milgram_unique_weak_solution {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (V : Submodule ℝ (Lp ℝ 2 μ)) (hV : IsClosed (V : Set (Lp ℝ 2 μ)))
    (k : X → ℝ) (hk : Measurable k) (kmin kmax : ℝ) (hkmin : 0 < kmin)
    (hbounds : ∀ x, kmin ≤ k x ∧ k x ≤ kmax) (ℓ : V →L[ℝ] ℝ) :
    (∃! u : V, ∀ v : V,
        ∫ x, k x * ((u : Lp ℝ 2 μ) : X → ℝ) x * ((v : Lp ℝ 2 μ) : X → ℝ) x ∂μ = ℓ v) ∧
    ∀ u : V, (∀ v : V,
        ∫ x, k x * ((u : Lp ℝ 2 μ) : X → ℝ) x * ((v : Lp ℝ 2 μ) : X → ℝ) x ∂μ = ℓ v) →
      ‖u‖ ≤ ‖ℓ‖ / kmin := by
  have : CompleteSpace V := hV.completeSpace_coe
  have hkabs : ∀ x, |k x| ≤ kmax := fun x =>
    abs_le.2 ⟨by linarith [hbounds x], (hbounds x).2⟩
  set b : V → V → ℝ := fun u v =>
    ∫ x, k x * ((u : Lp ℝ 2 μ) : X → ℝ) x * ((v : Lp ℝ 2 μ) : X → ℝ) x ∂μ with hb
  have hcoer : ∀ u : V, kmin * ‖u‖ ^ 2 ≤ b u u := fun u => by
    have := (lm_energy_form k hk kmin kmax hkmin hbounds
      (u : Lp ℝ 2 μ) u).2
    simpa [hb] using this
  have hbound : ∀ u v : V, ‖b u v‖ ≤ kmax * ‖u‖ * ‖v‖ := fun u v => by
    have := (lm_energy_form k hk kmin kmax hkmin hbounds
      (u : Lp ℝ 2 μ) v).1
    simpa [hb] using this
  let B₀ : V →ₗ[ℝ] V →ₗ[ℝ] ℝ := LinearMap.mk₂ ℝ b
    (fun u₁ u₂ v => lm_form_add_left k hk kmax hkabs (u₁ : Lp ℝ 2 μ) (u₂ : Lp ℝ 2 μ) (v : Lp ℝ 2 μ))
    (fun c u v => lm_form_smul_left k c (u : Lp ℝ 2 μ) (v : Lp ℝ 2 μ))
    (fun u v₁ v₂ => lm_form_add_right k hk kmax hkabs (u : Lp ℝ 2 μ) (v₁ : Lp ℝ 2 μ) (v₂ : Lp ℝ 2 μ))
    (fun c u v => lm_form_smul_right k c (u : Lp ℝ 2 μ) (v : Lp ℝ 2 μ))
  let B : V →L[ℝ] V →L[ℝ] ℝ := B₀.mkContinuous₂ kmax hbound
  have hBapp : ∀ u v, B u v = b u v := fun u v => rfl
  have hcB : IsCoercive B := ⟨kmin, hkmin, fun u => by
    rw [hBapp]; nlinarith [hcoer u]⟩
  have hsol : ∀ u : V, (∀ v, b u v = ℓ v) → ‖u‖ ≤ ‖ℓ‖ / kmin := by
    intro u hu
    rw [le_div_iff₀ hkmin]
    have h1 := hcoer u
    rw [hu u] at h1
    have h2 : ℓ u ≤ ‖ℓ‖ * ‖u‖ := (Real.le_norm_self (ℓ u)).trans (ℓ.le_opNorm u)
    rcases (norm_nonneg u).eq_or_lt with h0 | hpos
    · rw [← h0, zero_mul]; exact norm_nonneg ℓ
    · nlinarith
  refine ⟨?_, hsol⟩
  let f : V := (InnerProductSpace.toDual ℝ V).symm ℓ
  refine ⟨hcB.continuousLinearEquivOfBilin.symm f, ?_, ?_⟩
  · intro v
    show B _ v = ℓ v
    rw [← hcB.continuousLinearEquivOfBilin_apply, ContinuousLinearEquiv.apply_symm_apply,
      InnerProductSpace.toDual_symm_apply]
  · intro u hu
    rw [ContinuousLinearEquiv.eq_symm_apply]
    symm
    apply hcB.unique_continuousLinearEquivOfBilin
    intro w
    rw [InnerProductSpace.toDual_symm_apply, hBapp]
    exact (hu w).symm

/-- **The two constants.** If the conductivity lies between `k_min > 0` and `k_max`, the energy
form is bounded with `M = k_max` and coercive with `α = k_min`:
`|∫ k g h| ≤ k_max ‖g‖ ‖h‖` and `∫ k g² ≥ k_min ‖g‖²` for all square-integrable slopes `g`, `h`. -/
theorem energy_form_bounded_and_coercive {X : Type*} [MeasurableSpace X] {μ : Measure X}
    (k : X → ℝ) (hk : Measurable k) (kmin kmax : ℝ) (hkmin : 0 < kmin)
    (hbounds : ∀ x, kmin ≤ k x ∧ k x ≤ kmax) (g h : Lp ℝ 2 μ) :
    |∫ x, k x * (g : X → ℝ) x * (h : X → ℝ) x ∂μ| ≤ kmax * ‖g‖ * ‖h‖ ∧
    kmin * ‖g‖ ^ 2 ≤ ∫ x, k x * (g : X → ℝ) x * (g : X → ℝ) x ∂μ := by
  exact lm_energy_form k hk kmin kmax hkmin hbounds g h

/-- **From slope size to the rise.** A profile `u(x) = ∫₀ˣ g` pinned to zero at both faces of
`(0, L)` (so `∫₀ᴸ g = 0`), with a square-integrable slope `g`, obeys
`u(x)² ≤ x (L − x) / L · ∫₀ᴸ g²` at every point; at the middle this is `(√L / 2)² ‖u'‖²`. -/
theorem rise_sq_le_of_pinned {L : ℝ} (hL : 0 < L) (g : ℝ → ℝ)
    (hg : IntervalIntegrable g volume 0 L)
    (hg2 : IntervalIntegrable (fun t => g t ^ 2) volume 0 L)
    (hpin : ∫ t in (0 : ℝ)..L, g t = 0) {x : ℝ} (hx0 : 0 ≤ x) (hxL : x ≤ L) :
    (∫ t in (0 : ℝ)..x, g t) ^ 2 ≤ x * (L - x) / L * ∫ t in (0 : ℝ)..L, g t ^ 2 := by
  have s1 : Set.uIcc 0 x ⊆ Set.uIcc 0 L := by
    rw [Set.uIcc_of_le hx0, Set.uIcc_of_le hL.le]; exact Set.Icc_subset_Icc le_rfl hxL
  have s2 : Set.uIcc x L ⊆ Set.uIcc 0 L := by
    rw [Set.uIcc_of_le hxL, Set.uIcc_of_le hL.le]; exact Set.Icc_subset_Icc hx0 le_rfl
  have hgx := hg.mono_set s1
  have hgxL := hg.mono_set s2
  have hg2x := hg2.mono_set s1
  have hg2xL := hg2.mono_set s2
  have h1 := lm_cs_interval hx0 g hgx hg2x
  have h2 := lm_cs_interval hxL g hgxL hg2xL
  have e1 := intervalIntegral.integral_add_adjacent_intervals hgx hgxL
  have e2 := intervalIntegral.integral_add_adjacent_intervals hg2x hg2xL
  rw [hpin] at e1
  rw [← e2, div_mul_eq_mul_div, le_div_iff₀ hL]
  set u := ∫ t in (0 : ℝ)..x, g t
  set w := ∫ t in x..L, g t
  have hw : w = -u := by linarith
  rw [hw, neg_sq] at h2
  rw [sub_zero] at h1
  nlinarith [mul_le_mul_of_nonneg_left h1 (sub_nonneg.2 hxL), mul_le_mul_of_nonneg_left h2 hx0]

-- The wall's exact numbers (k in W/(m K), lengths in m, heating 1000 W/m³).
-- M / α = 1.8 / 0.04 = 45.
example : ((18 : ℚ) / 10) / (4 / 100) = 45 := by norm_num
-- Slope at the bare face: 300 (1 + 0.30 / (2 · 1.8 · 1.25)) / (1.8 + 0.30 / 1.25) = 8000/51 K/m.
example : (300 : ℚ) * (1 + (3 / 10) / (2 * (18 / 10) * (5 / 4))) / (18 / 10 + (3 / 10) / (5 / 4))
    = 8000 / 51 := by norm_num
-- Joint rise: (8000/51) · 0.30 − 1000 · 0.09 / 3.6 = 375/17 K.
example : (8000 : ℚ) / 51 * (3 / 10) - 1000 * (9 / 100) / (36 / 10) = 375 / 17 := by norm_num
-- Heat out of each face, 1.8 · 8000/51 and (375/17) / 1.25, adds to F S = 1000 · 0.30 = 300 W/m².
example : (18 : ℚ) / 10 * (8000 / 51) + (375 / 17) / (5 / 4) = 1000 * (3 / 10) := by norm_num
-- Peak position 8000/51 · 1.8 / 1000 = 24/85 m and peak rise (8000/51)² · 1.8 / 2000 = 57600/2601 K.
example : (8000 : ℚ) / 51 * (18 / 10) / 1000 = 24 / 85 := by norm_num
example : ((8000 : ℚ) / 51) ^ 2 * (18 / 10) / 2000 = 57600 / 2601 := by norm_num

#print axioms lax_milgram_unique_weak_solution
#print axioms energy_form_bounded_and_coercive
#print axioms rise_sq_le_of_pinned
