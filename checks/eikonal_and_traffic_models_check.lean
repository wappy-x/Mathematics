-- Eikonal and traffic: the first arrival time from point sources, distance over speed, solves the eikonal equation in the viscosity sense, the later arrival does not, and on a triangular flow rule an observer is overtaken at most at the capacity rate minus critical density times its speed.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Topology.Order.LocalExtr
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.FDeriv.Norm
import Mathlib.Analysis.Calculus.FDeriv.Const
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Tactic.Module

open Set

/-- The arrival time of sound from the towers `a 0, ..., a m`, travelling at speed `c` in straight
lines: the shortest distance to a tower, divided by `c`. -/
noncomputable def arrivalTime {E : Type*} [NormedAddCommGroup E] {m : ℕ}
    (a : Fin (m + 1) → E) (c : ℝ) (x : E) : ℝ :=
  (Finset.univ.inf' Finset.univ_nonempty fun k => ‖x - a k‖) / c

/-- Helper: the cone `y ↦ ‖y - p‖ / c` is differentiable away from its tip, with gradient of length `1/c`. -/
theorem eikonal_cone_hasFDerivAt
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (p x : E) (hx : x ≠ p) {c : ℝ} (hc : 0 < c) :
    ∃ D : E →L[ℝ] ℝ, HasFDerivAt (fun y => ‖y - p‖ / c) D x ∧ ‖D‖ = 1 / c := by
  have : Nontrivial E := nontrivial_of_ne x p hx
  have hxp : x - p ≠ 0 := sub_ne_zero.mpr hx
  have hd : DifferentiableAt ℝ (‖·‖) (x - p) := (contDiffAt_norm ℝ (n := 1) hxp).differentiableAt (by norm_num)
  have h1 : HasFDerivAt (fun y : E => ‖y - p‖) ((fderiv ℝ (‖·‖) (x - p)).comp (ContinuousLinearMap.id ℝ E)) x :=
    hd.hasFDerivAt.comp x ((hasFDerivAt_id x).sub_const p)
  refine ⟨c⁻¹ • ((fderiv ℝ (‖·‖) (x - p)).comp (ContinuousLinearMap.id ℝ E)), ?_, ?_⟩
  · have := h1.const_smul c⁻¹
    convert this using 1
    funext y
    simp [div_eq_inv_mul]
  · rw [norm_smul, ContinuousLinearMap.comp_id, norm_fderiv_norm hd, Real.norm_eq_abs,
      abs_of_pos (inv_pos.mpr hc)]
    simp

#print axioms eikonal_cone_hasFDerivAt

open Filter Topology in
/-- Helper: a one-sided Lipschitz bound from below near `x` bounds the derivative from below in every direction. -/
theorem eikonal_lower_slope_bound
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {φ : E → ℝ} {x : E} {L : E →L[ℝ] ℝ} (hφ : HasFDerivAt φ L x) {b : ℝ}
    (h : ∀ᶠ y in 𝓝 x, -(b * ‖y - x‖) ≤ φ y - φ x) (v : E) : -(b * ‖v‖) ≤ L v := by
  have hg : HasDerivAt (fun t : ℝ => φ (x + t • v)) (L v) 0 := by
    have h2 : HasDerivAt (fun t : ℝ => x + t • v) v 0 := by
      simpa using ((hasDerivAt_id (0 : ℝ)).smul_const v).const_add x
    exact hφ.comp_hasDerivAt_of_eq 0 h2 (by simp)
  have ht : Tendsto (fun t : ℝ => x + t • v) (𝓝[>] 0) (𝓝 x) := by
    have : Continuous (fun t : ℝ => x + t • v) := by fun_prop
    have := this.tendsto 0
    simp only [zero_smul, add_zero] at this
    exact this.mono_left nhdsWithin_le_nhds
  have hev := (ht.eventually h).and self_mem_nhdsWithin
  refine ge_of_tendsto hg.tendsto_slope_zero_right ?_
  filter_upwards [hev] with t ⟨h1, h2⟩
  have h2 : (0:ℝ) < t := h2
  simp only [zero_add, zero_smul, add_zero, add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
    abs_of_pos h2, smul_eq_mul] at h1 ⊢
  rw [le_inv_mul_iff₀ h2]
  linarith

#print axioms eikonal_lower_slope_bound

/-- The first arrival time `T(x) = min_k |x - a_k| / c`, for sound at one constant speed `c > 0`
from finitely many towers, solves the eikonal problem: `T = 0` at each tower; where one tower is
strictly nearest, `T` is differentiable with `|∇T| = 1/c`; and at every point that is not a tower,
ridge points included, `T` is a viscosity solution of `|∇T| = 1/c`: a test function touching `T`
from above has slope at most `1/c`, and one touching from below has slope at least `1/c`. -/
theorem first_arrival_is_viscosity_solution_of_eikonal
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    {m : ℕ} (a : Fin (m + 1) → E) {c : ℝ} (hc : 0 < c) :
    (∀ k, arrivalTime a c (a k) = 0) ∧
    (∀ x i, x ≠ a i → (∀ j, j ≠ i → ‖x - a i‖ < ‖x - a j‖) →
      DifferentiableAt ℝ (arrivalTime a c) x ∧ ‖fderiv ℝ (arrivalTime a c) x‖ = 1 / c) ∧
    (∀ x, (∀ k, x ≠ a k) → ∀ φ : E → ℝ, DifferentiableAt ℝ φ x →
      (IsLocalMax (fun y => arrivalTime a c y - φ y) x → ‖fderiv ℝ φ x‖ ≤ 1 / c) ∧
      (IsLocalMin (fun y => arrivalTime a c y - φ y) x → 1 / c ≤ ‖fderiv ℝ φ x‖)) := by
  -- the arrival time lies below each tower's cone
  have hle : ∀ y k, arrivalTime a c y ≤ ‖y - a k‖ / c := fun y k =>
    div_le_div_of_nonneg_right (Finset.inf'_le _ (Finset.mem_univ k)) hc.le
  refine ⟨fun k => ?_, fun x i hxi hnear => ?_, fun x hx φ hφ => ⟨fun hmax => ?_, fun hmin => ?_⟩⟩
  · apply le_antisymm
    · simpa using hle (a k) k
    · exact div_nonneg (Finset.le_inf' _ _ fun j _ => norm_nonneg _) hc.le
  · have hev : ∀ᶠ y in nhds x, ∀ j, j ≠ i → ‖y - a i‖ < ‖y - a j‖ := by
      rw [Filter.eventually_all]
      intro j
      by_cases hj : j = i
      · exact Filter.Eventually.of_forall fun y h => absurd hj h
      · have h1 : ContinuousAt (fun y : E => ‖y - a i‖) x := by fun_prop
        have h2 : ContinuousAt (fun y : E => ‖y - a j‖) x := by fun_prop
        filter_upwards [h1.eventually_lt h2 (hnear j hj)] with y hy _ using hy
    have heq : arrivalTime a c =ᶠ[nhds x] fun y => ‖y - a i‖ / c := by
      filter_upwards [hev] with y hy
      unfold arrivalTime
      congr 1
      apply le_antisymm (Finset.inf'_le _ (Finset.mem_univ i))
      refine Finset.le_inf' _ _ fun j _ => ?_
      by_cases hj : j = i
      · rw [hj]
      · exact (hy j hj).le
    obtain ⟨D, hD, hDn⟩ := eikonal_cone_hasFDerivAt (a i) x hxi hc
    have hT : HasFDerivAt (arrivalTime a c) D x := hD.congr_of_eventuallyEq heq
    exact ⟨hT.differentiableAt, by rw [hT.fderiv, hDn]⟩
  · -- touching from above: one-sided Lipschitz bound
    have hlip : ∀ y, arrivalTime a c x - ‖y - x‖ / c ≤ arrivalTime a c y := by
      intro y
      unfold arrivalTime
      rw [← sub_div]
      apply div_le_div_of_nonneg_right _ hc.le
      refine Finset.le_inf' _ _ fun j _ => ?_
      have h1 : Finset.univ.inf' Finset.univ_nonempty (fun k => ‖x - a k‖) ≤ ‖x - a j‖ :=
        Finset.inf'_le (fun k => ‖x - a k‖) (Finset.mem_univ j)
      have h2 : ‖x - a j‖ ≤ ‖y - x‖ + ‖y - a j‖ := by
        calc ‖x - a j‖ = ‖-(y - x) + (y - a j)‖ := by congr 1; abel
          _ ≤ ‖-(y - x)‖ + ‖y - a j‖ := norm_add_le _ _
          _ = ‖y - x‖ + ‖y - a j‖ := by rw [norm_neg]
      linarith
    have hb : ∀ᶠ y in nhds x, -(c⁻¹ * ‖y - x‖) ≤ φ y - φ x := by
      filter_upwards [hmax] with y hy
      have := hlip y
      rw [div_eq_inv_mul] at this
      linarith
    have key := eikonal_lower_slope_bound hφ.hasFDerivAt hb
    refine ContinuousLinearMap.opNorm_le_bound _ (by positivity) fun v => ?_
    rw [Real.norm_eq_abs, abs_le, one_div]
    have h1 := key v
    have h2 := key (-v)
    rw [map_neg, norm_neg] at h2
    constructor <;> linarith
  · -- touching from below: compare with the nearest tower's cone
    obtain ⟨k, -, hk⟩ := Finset.exists_mem_eq_inf' Finset.univ_nonempty (fun k => ‖x - a k‖)
    have hTx : arrivalTime a c x = ‖x - a k‖ / c := by unfold arrivalTime; rw [hk]
    obtain ⟨D, hD, hDn⟩ := eikonal_cone_hasFDerivAt (a k) x (hx k) hc
    have hmax' : IsLocalMax (fun y => φ y - ‖y - a k‖ / c) x := by
      filter_upwards [hmin] with y hy
      have := hle y k
      linarith
    have h0 := hmax'.hasFDerivAt_eq_zero (hφ.hasFDerivAt.sub hD)
    rw [sub_eq_zero] at h0
    rw [h0, hDn]

/-- The later arrival from two distinct towers, `max(|x - a|, |x - b|) / c`, is not a viscosity
solution of `|∇T| = 1/c`: at some point that is not a tower, a test function touches it from below
with slope shorter than `1/c`. -/
theorem later_arrival_is_not_viscosity_solution
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (a b : E) (hab : a ≠ b) {c : ℝ} (hc : 0 < c) :
    ∃ x : E, x ≠ a ∧ x ≠ b ∧ ∃ φ : E → ℝ, DifferentiableAt ℝ φ x ∧
      IsLocalMin (fun y => max ‖y - a‖ ‖y - b‖ / c - φ y) x ∧ ‖fderiv ℝ φ x‖ < 1 / c := by
  have hba : b - a ≠ 0 := sub_ne_zero.mpr hab.symm
  have hxa : a + (1 / 2 : ℝ) • (b - a) - a = (1 / 2 : ℝ) • (b - a) := by module
  have hxb : a + (1 / 2 : ℝ) • (b - a) - b = -((1 / 2 : ℝ) • (b - a)) := by module
  refine ⟨a + (1 / 2 : ℝ) • (b - a), ?_, ?_, fun _ => 0, differentiableAt_const _, ?_, ?_⟩
  · intro h
    rw [h, sub_self, eq_comm, smul_eq_zero] at hxa
    norm_num at hxa
    exact hba hxa
  · intro h
    rw [h, sub_self, eq_comm, neg_eq_zero, smul_eq_zero] at hxb
    norm_num at hxb
    exact hba hxb
  · refine Filter.Eventually.of_forall fun y => ?_
    simp only [sub_zero]
    apply div_le_div_of_nonneg_right _ hc.le
    rw [hxa, hxb, norm_neg, norm_smul, max_self]
    have h1 : ‖b - a‖ ≤ ‖y - a‖ + ‖y - b‖ := by
      calc ‖b - a‖ = ‖(y - a) - (y - b)‖ := by congr 1; abel
        _ ≤ ‖y - a‖ + ‖y - b‖ := norm_sub_le _ _
    have h2 := le_max_left ‖y - a‖ ‖y - b‖
    have h3 := le_max_right ‖y - a‖ ‖y - b‖
    rw [Real.norm_of_nonneg (by norm_num)]
    linarith
  · rw [fderiv_const_apply, norm_zero]
    positivity

/-- Newell's observers: on the triangular flow rule `q(ρ) = min(v_f ρ, w (ρ_j - ρ))`, an observer
moving at speed `v` with `-w ≤ v ≤ v_f` is overtaken at most at the rate `q_c - ρ_c v`, over all
densities from 0 to `ρ_j`, where `ρ_c = w ρ_j / (v_f + w)` and `q_c = v_f ρ_c`. That rate is 0 for
the observer riding free traffic (`v = v_f`) and `ρ_j w` for the one riding the backward wave
(`v = -w`). -/
theorem max_overtaking_rate_triangular
    {vf w ρj v : ℝ} (hvf : 0 < vf) (hw : 0 < w) (hρj : 0 < ρj) (hv₁ : -w ≤ v) (hv₂ : v ≤ vf) :
    IsGreatest ((fun ρ => min (vf * ρ) (w * (ρj - ρ)) - ρ * v) '' Icc 0 ρj)
        (vf * (w * ρj / (vf + w)) - w * ρj / (vf + w) * v) ∧
      vf * (w * ρj / (vf + w)) - w * ρj / (vf + w) * vf = 0 ∧
      vf * (w * ρj / (vf + w)) - w * ρj / (vf + w) * (-w) = ρj * w := by
  have hs : 0 < vf + w := by linarith
  set ρc := w * ρj / (vf + w) with hρc
  have hkey : vf * ρc = w * (ρj - ρc) := by
    rw [hρc]; field_simp; ring
  have hρc0 : 0 ≤ ρc := by positivity
  have hρc1 : ρc ≤ ρj := by
    rw [hρc, div_le_iff₀ hs]; nlinarith
  refine ⟨⟨⟨ρc, ⟨hρc0, hρc1⟩, ?_⟩, ?_⟩, by ring, ?_⟩
  · simp only
    rw [← hkey, min_self]
  · rintro _ ⟨ρ, ⟨h0, h1⟩, rfl⟩
    simp only
    rcases le_total ρ ρc with h | h
    · have := min_le_left (vf * ρ) (w * (ρj - ρ))
      nlinarith
    · have := min_le_right (vf * ρ) (w * (ρj - ρ))
      nlinarith
  · have : vf * ρc + ρc * w = ρj * w := by
      rw [hkey]; ring
    linarith

-- The seat at (30, 40) m is 50 m from the tower at (0, 0) m: 30² + 40² = 50².
example : (30 : ℕ) ^ 2 + 40 ^ 2 = 50 ^ 2 := by norm_num

-- Capacity of the lane: ρ_c = 18 × 150 / (90 + 18) = 25 cars/km, q_c = 90 × 25 = 18 × (150 − 25) = 2250 cars/h.
example : (18 * 150 / (90 + 18) : ℚ) = 25 ∧ (90 * 25 : ℚ) = 2250 ∧ (18 * (150 - 25) : ℚ) = 2250 := by
  norm_num

-- Tail speed by Rankine-Hugoniot: (0 − 1350) / (150 − 15) = −10 km/h.
example : ((0 - 1350) / (150 - 15) : ℚ) = -10 := by norm_num

-- The jam ends at 18 × (1/10) / (18 − 10) h = 9/40 h = 13.5 min, at −18 × (9/40 − 1/10) = −9/4 km.
example : (18 * (1 / 10) / (18 - 10) : ℚ) = 9 / 40 ∧ (60 * (9 / 40) : ℚ) = 27 / 2 ∧
    (-18 * (9 / 40 - 1 / 10) : ℚ) = -9 / 4 := by norm_num

-- Total delay D = ρ_j |s| w τ² / (2 (w − |s|)) = 150 × ½ × 1 km × 9/40 h = 135/8 = 16.875 car-hours.
example : (150 * 10 * 18 * (1 / 10) ^ 2 / (2 * (18 - 10)) : ℚ) = 135 / 8 ∧
    (150 * (1 / 2) * 1 * (9 / 40) : ℚ) = 135 / 8 := by norm_num

-- Cars delayed: (1350 + 15 × 10) × 9/40 = 337.5; delay per car (135/8) / (675/2) h = 1/20 h = 3 min.
example : ((1350 + 15 * 10) * (9 / 40) : ℚ) = 675 / 2 ∧ ((135 / 8) / (675 / 2) : ℚ) = 1 / 20 ∧
    (60 * (1 / 20) : ℚ) = 3 := by norm_num

-- Mistakes: ending the jam at reopening gives 150 × ½ × 1 × 1/10 = 7.5 car-hours; a tail at
-- 18 km/h gives a 1.8 km jam of 270 cars, though only 15 × 1.8 + 135 = 162 arrived.
example : (150 * (1 / 2) * 1 * (1 / 10) : ℚ) = 15 / 2 ∧ (150 * (18 * (1 / 10)) : ℚ) = 270 ∧
    (15 * (18 * (1 / 10)) + 1350 * (1 / 10) : ℚ) = 162 := by norm_num

-- Try lines: arriving 20 cars/km, s = −90 × 20 / 130 = −180/13 km/h, jam ends at 13/30 h = 26 min,
-- delay 45 car-hours; blocked 12 min, jam ends at 9/20 h = 27 min, delay 67.5 car-hours.
example : (-90 * 20 / (150 - 20) : ℚ) = -180 / 13 ∧
    ((1 / 10) * 18 / (18 - 180 / 13) : ℚ) = 13 / 30 ∧
    (150 * (1 / 2) * (180 / 13 * (1 / 10)) * (13 / 30) : ℚ) = 45 ∧
    ((2 / 10) * 18 / (18 - 10) : ℚ) = 9 / 20 ∧
    (150 * (1 / 2) * (10 * (2 / 10)) * (9 / 20) : ℚ) = 135 / 2 := by norm_num

#print axioms first_arrival_is_viscosity_solution_of_eikonal
#print axioms later_arrival_is_not_viscosity_solution
#print axioms max_overtaking_rate_triangular
