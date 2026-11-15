-- Separation: a point outside a closed convex set holding a ball around 0, in any real normed space, is split from the set by a bounded linear functional whose level-1 wall supports the set, and such walls rebuild the set (the bipolar theorem).
import Mathlib.Analysis.Convex.Gauge
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Analysis.Normed.Operator.Basic
import Mathlib.Tactic.NormNum

/-- Separation with a supporting wall. Let `C` be a closed convex set in a real normed space
that holds the ball of radius `r > 0` around 0, and let `x₀` lie outside `C`. Then some bounded
linear functional `φ` never beats the gauge `s_C`, scores every point of `C` at most 1, scores
`x₀` at its gauge `s_C(x₀) > 1`, and has norm at most `1 / r`. Its level-1 wall touches `C` at the
shrunken point `x₀ / s_C(x₀)`, which lies in `C` and scores exactly 1. -/
theorem closed_convex_set_point_separated_by_supporting_wall
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {C : Set E} (hconv : Convex ℝ C) (hclosed : IsClosed C)
    {r : ℝ} (hr : 0 < r) (hball : Metric.ball (0 : E) r ⊆ C)
    {x₀ : E} (hx₀ : x₀ ∉ C) :
    ∃ φ : E →L[ℝ] ℝ,
      (∀ x, φ x ≤ gauge C x) ∧
      (∀ x ∈ C, φ x ≤ 1) ∧
      φ x₀ = gauge C x₀ ∧ 1 < gauge C x₀ ∧
      ‖φ‖ ≤ 1 / r ∧
      (gauge C x₀)⁻¹ • x₀ ∈ C ∧ φ ((gauge C x₀)⁻¹ • x₀) = 1 := by
  have hB : Metric.ball (0 : E) r ∈ nhds (0 : E) := Metric.ball_mem_nhds 0 hr
  have hC0 : C ∈ nhds (0 : E) := Filter.mem_of_superset hB hball
  have habs : Absorbent ℝ C := absorbent_nhds_zero hC0
  have h0 : (0 : E) ∈ C := mem_of_mem_nhds hC0
  have hmem : ∀ x, gauge C x ≤ 1 → x ∈ C := fun x hx => by
    have := (gauge_le_one_iff_mem_closure hconv hC0).1 hx
    rwa [hclosed.closure_eq] at this
  set g := gauge C x₀ with hg
  have hgt : 1 < g := by
    by_contra h
    exact hx₀ (hmem x₀ (not_lt.1 h))
  have hgpos : 0 < g := by linarith
  have hne : x₀ ≠ 0 := fun h => hx₀ (h ▸ h0)
  have hbound : ∀ x, gauge C x ≤ ‖x‖ / r := fun x => by
    have := gauge_mono (absorbent_nhds_zero hB) hball x
    rwa [gauge_ball hr.le] at this
  obtain ⟨φ, hφ₁, hφ₂⟩ := exists_extension_of_le_sublinear
    (LinearPMap.mkSpanSingleton x₀ g hne) (gauge C)
    (fun c hc => gauge_smul_of_nonneg hc.le) (gauge_add_le hconv habs) (by
      rintro ⟨x, hx⟩
      obtain ⟨y, rfl⟩ := Submodule.mem_span_singleton.1 hx
      rw [LinearPMap.mkSpanSingleton'_apply]
      simp only [smul_eq_mul]
      obtain h | h := le_or_gt y 0
      · exact (mul_nonpos_of_nonpos_of_nonneg h hgpos.le).trans (gauge_nonneg _)
      · rw [gauge_smul_of_nonneg h.le, smul_eq_mul, RingHom.id_apply, hg])
  have hφx₀ : φ x₀ = g := by
    have := hφ₁ ⟨x₀, Submodule.mem_span_singleton_self x₀⟩
    rw [this]
    exact LinearPMap.mkSpanSingleton'_apply_self _ _ _ _
  have hφb : ∀ x, ‖φ x‖ ≤ (1 / r) * ‖x‖ := fun x => by
    rw [Real.norm_eq_abs, abs_le]
    have h1 := (hφ₂ x).trans (hbound x)
    have h2 := (hφ₂ (-x)).trans (hbound (-x))
    rw [map_neg, norm_neg] at h2
    constructor <;> [skip; skip] <;> rw [one_div_mul_eq_div] <;> linarith
  refine ⟨φ.mkContinuous (1 / r) hφb, hφ₂, fun x hx => (hφ₂ x).trans (gauge_le_one_of_mem hx),
    hφx₀, hgt, LinearMap.mkContinuous_norm_le _ (by positivity) hφb, ?_, ?_⟩
  · apply hmem
    rw [gauge_smul_of_nonneg (inv_nonneg.2 hgpos.le), smul_eq_mul, ← hg, inv_mul_cancel₀ hgpos.ne']
  · simp only [LinearMap.mkContinuous_apply, map_smul, smul_eq_mul, hφx₀]
    exact inv_mul_cancel₀ hgpos.ne'

/-- The bipolar theorem. For a closed convex set `C` holding 0 in a real normed space, the plans
that every bounded functional scoring `C` at most 1 also scores at most 1 are exactly `C`. -/
theorem bipolar_of_closed_convex_set_holding_zero
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {C : Set E} (hconv : Convex ℝ C) (hclosed : IsClosed C) (h0 : (0 : E) ∈ C) :
    {x : E | ∀ φ ∈ {φ : E →L[ℝ] ℝ | ∀ y ∈ C, φ y ≤ 1}, φ x ≤ 1} = C := by
  ext x
  constructor
  · intro hx
    by_contra hxC
    obtain ⟨f, u, hf, hu⟩ := geometric_hahn_banach_closed_point hconv hclosed hxC
    have hu0 : 0 < u := by simpa using hf 0 h0
    have := hx (u⁻¹ • f) (fun y hy => by
      simp only [FunLike.coe_smul, Pi.smul_apply, smul_eq_mul]
      rw [inv_mul_le_iff₀ hu0, mul_one]; exact (hf y hy).le)
    simp only [FunLike.coe_smul, Pi.smul_apply, smul_eq_mul] at this
    rw [inv_mul_le_iff₀ hu0, mul_one] at this
    linarith
  · intro hx φ hφ
    exact hφ x hx

/-- Two sets instead of a point. Two disjoint convex sets `A` and `B` in a real normed space, with
`A` open, are split by one bounded linear functional: `φ y < φ z` for every `y` in `A` and `z` in
`B`. -/
theorem disjoint_convex_sets_with_open_one_separated
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {A B : Set E} (hA : Convex ℝ A) (hAo : IsOpen A) (hB : Convex ℝ B) (hAB : Disjoint A B) :
    ∃ φ : E →L[ℝ] ℝ, ∀ y ∈ A, ∀ z ∈ B, φ y < φ z := by
  obtain ⟨f, u, hf, hu⟩ := geometric_hahn_banach_open hA hAo hB hAB
  exact ⟨f, fun y hy z hz => (hf y hy).trans_le (hu z hz)⟩

-- The cheaper bundle (11, -1) against the bands: forecast (50, 150), all-high (60, 180),
-- worst list (60, 120).
example : (11 : ℤ) * 50 - 1 * 150 = 400 := by norm_num
example : (11 : ℤ) * 60 - 1 * 180 = 480 := by norm_num
example : (11 : ℤ) * 60 - 1 * 120 = 540 := by norm_num
-- The worst list is the largest bill over the four corner price lists of the bands.
example : max (max ((11 : ℤ) * 40 - 120) (11 * 40 - 180)) (max (11 * 60 - 120) (11 * 60 - 180)) = 540 := by
  norm_num
-- The gauge is the larger of 540 / 500 and 11 / 12, which is 27 / 25 = 1.08.
example : max ((540 : ℚ) / 500) (11 / 12) = 27 / 25 := by norm_num
-- The supporting point (11, -1) / (27 / 25) has bill exactly 500 at (60, 120).
example : 60 * ((11 : ℚ) / (27 / 25)) + 120 * ((-1) / (27 / 25)) = 500 := by norm_num
-- Ball radius r = 500 / 180, norm of the wall 120 / 500, and 120 / 500 ≤ 1 / r.
example : (120 : ℚ) / 500 ≤ 1 / (500 / 180) := by norm_num
-- Convexity: the halfway mix of (10, 0) and (0, 4) is (5, 2).
example : ((10 : ℚ) + 0) / 2 = 5 ∧ ((0 : ℚ) + 4) / 2 = 2 := by norm_num
-- The week, in whole numbers: plan in quarter-MWh (12, -5 or 4 a quarter, i.e. 3, -1.25 or 1 MWh),
-- prices in fifths of the forecast (5 = forecast, 6 = top of the band, 4 = bottom), so every bill
-- is 20 times its value in pounds: forecast £8,110, all-high £9,732, worst £11,792; 28 selling hours.
example :
    let q : ℕ → ℤ := fun h =>
      (if h % 24 < 6 then 50 else if h % 24 < 16 then 90 else if h % 24 < 20 then 150 else 70)
        - (if 120 ≤ h then 10 else 0)
    let x : ℕ → ℤ := fun h =>
      if h % 24 < 5 then 12 else if 16 ≤ h % 24 ∧ h % 24 < 20 then -5 else 4
    ((List.range 168).map (fun h => 5 * q h * x h)).sum = 20 * 8110 ∧
    ((List.range 168).map (fun h => 6 * q h * x h)).sum = 20 * 9732 ∧
    ((List.range 168).map (fun h => (if 0 ≤ x h then 6 else 4) * q h * x h)).sum = 20 * 11792 ∧
    ((List.range 168).filter (fun h => x h < 0)).length = 28 := by
  decide +kernel

#print axioms closed_convex_set_point_separated_by_supporting_wall
#print axioms bipolar_of_closed_convex_set_holding_zero
#print axioms disjoint_convex_sets_with_open_one_separated
