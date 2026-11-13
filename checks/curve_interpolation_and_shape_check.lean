-- Between the pillars: two forward curves reprice every quoted discount factor exactly when they have the same area on every gap, log-linear interpolation gives a flat forward equal to the segment forward, and the monotone convex parabola keeps that area while hitting its two end forwards.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open MeasureTheory

/-- Each quote fixes the area under the forward curve across one gap, and nothing else.
Take pillar dates 0 = t₀ < t₁ < ⋯ < tₙ and two forward curves f and g, each giving discount
factors D(t) = exp(−∫₀ᵗ forward). Then f and g hand back the same discount factor at every
pillar exactly when, on every gap [tᵢ₋₁, tᵢ], the area under f equals the area under g.
The shape inside a gap never enters. -/
theorem quotes_fix_areas_not_shapes (n : ℕ) (t : Fin (n + 1) → ℝ) (ht : StrictMono t)
    (h0 : t 0 = 0) (f g : ℝ → ℝ)
    (hf : IntervalIntegrable f volume 0 (t (Fin.last n)))
    (hg : IntervalIntegrable g volume 0 (t (Fin.last n))) :
    (∀ i : Fin (n + 1),
        Real.exp (-∫ u in (0 : ℝ)..t i, f u) = Real.exp (-∫ u in (0 : ℝ)..t i, g u)) ↔
      ∀ i : Fin n,
        ∫ u in t i.castSucc..t i.succ, f u = ∫ u in t i.castSucc..t i.succ, g u := by
  have hsub : ∀ i : Fin (n + 1), Set.uIcc 0 (t i) ⊆ Set.uIcc 0 (t (Fin.last n)) := by
    intro i
    apply Set.uIcc_subset_uIcc Set.left_mem_uIcc
    apply Set.mem_uIcc_of_le
    · rw [← h0]; exact ht.monotone (Fin.zero_le _)
    · exact ht.monotone (Fin.le_last _)
  have hfi : ∀ i, IntervalIntegrable f volume 0 (t i) := fun i => hf.mono_set (hsub i)
  have hgi : ∀ i, IntervalIntegrable g volume 0 (t i) := fun i => hg.mono_set (hsub i)
  have gap : ∀ (h : ℝ → ℝ), (∀ i, IntervalIntegrable h volume 0 (t i)) → ∀ i : Fin n,
      ∫ u in t i.castSucc..t i.succ, h u
        = (∫ u in (0:ℝ)..t i.succ, h u) - ∫ u in (0:ℝ)..t i.castSucc, h u := by
    intro h hh i
    rw [intervalIntegral.integral_interval_sub_left (hh _) (hh _)]
  have key : (∀ i : Fin (n + 1),
        Real.exp (-∫ u in (0 : ℝ)..t i, f u) = Real.exp (-∫ u in (0 : ℝ)..t i, g u)) ↔
      ∀ i : Fin (n + 1), ∫ u in (0 : ℝ)..t i, f u = ∫ u in (0 : ℝ)..t i, g u := by
    simp only [Real.exp_eq_exp, neg_inj]
  rw [key]
  constructor
  · intro H i
    rw [gap f hfi, gap g hgi, H, H]
  · intro H i
    induction i using Fin.induction with
    | zero => simp [h0]
    | succ i ih =>
      have := H i
      rw [gap f hfi, gap g hgi, ih] at this
      linarith

/-- Log-linear interpolation: between pillars a < b with positive discount factors D₀ and D₁,
set D(t) = D₀^(1−w) · D₁^w with w = (t − a)/(b − a). It hands back both quotes, and its
instantaneous forward rate −d/dt ln D(t) is the same at every t: the segment forward
m = (ln D₀ − ln D₁)/(b − a). -/
theorem log_linear_forward_is_segment_forward (a b D₀ D₁ : ℝ) (hab : a < b)
    (hD₀ : 0 < D₀) (hD₁ : 0 < D₁) :
    let D : ℝ → ℝ := fun s => D₀ ^ (1 - (s - a) / (b - a)) * D₁ ^ ((s - a) / (b - a))
    D a = D₀ ∧ D b = D₁ ∧
      ∀ s : ℝ, HasDerivAt (fun r => -Real.log (D r))
        ((Real.log D₀ - Real.log D₁) / (b - a)) s := by
  intro D
  have hba : b - a ≠ 0 := sub_ne_zero.mpr hab.ne'
  refine ⟨?_, ?_, ?_⟩
  · simp [D]
  · simp [D, div_self hba]
  · intro s
    have hfun : (fun r => -Real.log (D r)) = fun r =>
        ((Real.log D₀ - Real.log D₁) / (b - a)) * r
          + (-Real.log D₀ - (Real.log D₀ - Real.log D₁) / (b - a) * a) := by
      funext r
      simp only [D]
      rw [Real.log_mul (Real.rpow_pos_of_pos hD₀ _).ne' (Real.rpow_pos_of_pos hD₁ _).ne',
        Real.log_rpow hD₀, Real.log_rpow hD₁]
      field_simp
      ring
    rw [hfun]
    simpa using ((hasDerivAt_id s).const_mul ((Real.log D₀ - Real.log D₁) / (b - a))).add_const
      (-Real.log D₀ - (Real.log D₀ - Real.log D₁) / (b - a) * a)

/-- The monotone convex parabola on one gap [a, b], with x = (t − a)/(b − a):
f(t) = m + g₀(1 − 4x + 3x²) + g₁(3x² − 2x). It starts at m + g₀, ends at m + g₁, and its
area over the gap is m(b − a), the same as the flat segment forward, so the quote survives. -/
theorem monotone_convex_parabola_keeps_area (a b m g₀ g₁ : ℝ) (hab : a < b) :
    let f : ℝ → ℝ := fun s =>
      m + g₀ * (1 - 4 * ((s - a) / (b - a)) + 3 * ((s - a) / (b - a)) ^ 2)
        + g₁ * (3 * ((s - a) / (b - a)) ^ 2 - 2 * ((s - a) / (b - a)))
    f a = m + g₀ ∧ f b = m + g₁ ∧ ∫ s in a..b, f s = m * (b - a) := by
  intro f
  have hba : b - a ≠ 0 := sub_ne_zero.mpr hab.ne'
  refine ⟨?_, ?_, ?_⟩
  · simp [f]
  · norm_num [f, div_self hba]
  · let F : ℝ → ℝ := fun s =>
      m * s + g₀ * (b - a) * ((s - a) / (b - a) - 2 * ((s - a) / (b - a)) ^ 2
          + ((s - a) / (b - a)) ^ 3)
        + g₁ * (b - a) * (((s - a) / (b - a)) ^ 3 - ((s - a) / (b - a)) ^ 2)
    have hF : ∀ s ∈ Set.uIcc a b, HasDerivAt F (f s) s := by
      intro s _
      have hx : HasDerivAt (fun r : ℝ => (r - a) / (b - a)) (1 / (b - a)) s :=
        ((hasDerivAt_id s).sub_const a).div_const (b - a)
      have h := (((hasDerivAt_id s).const_mul m).add
        (((hx.sub ((hx.pow 2).const_mul 2)).add (hx.pow 3)).const_mul (g₀ * (b - a)))).add
        (((hx.pow 3).sub (hx.pow 2)).const_mul (g₁ * (b - a)))
      refine h.congr_deriv ?_
      simp only [f]
      push_cast
      generalize (s - a) / (b - a) = x
      field_simp
      ring
    have hcont : Continuous f := by
      simp only [f]; fun_prop
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF (hcont.intervalIntegrable _ _)]
    simp only [F, sub_self, div_self hba]
    field_simp
    ring

-- Worked numbers in basis points a year (exact rationals). Zero rates 430, 400, 380, 390, 420, 450.
-- Segment forwards (z_i t_i − z_{i−1} t_{i−1}) / h_i: 2 to 5 years, 5 to 10, 10 to 30.
example : ((390 : ℚ) * 5 - 380 * 2) / 3 = 1190 / 3 := by norm_num
example : ((420 : ℚ) * 10 - 390 * 5) / 5 = 450 := by norm_num
example : ((450 : ℚ) * 30 - 420 * 10) / 20 = 465 := by norm_num
-- Pillar forward at ten years: (h₁₁ m₁₀ + h₁₀ m₁₁)/(h₁₀ + h₁₁) = (20·450 + 5·465)/25 = 453.
example : ((20 : ℚ) * 450 + 5 * 465) / 25 = 453 := by norm_num
-- Pillar forward at five years: (5 · 1190/3 + 3 · 450)/8 = 1250/3, so g₀ = −100/3 and g₁ = 3 on 5 to 10.
example : ((5 : ℚ) * (1190 / 3) + 3 * 450) / 8 = 1250 / 3 := by norm_num
example : (1250 / 3 : ℚ) - 450 = -100 / 3 := by norm_num
-- Region 3 turning point on 5 to 10: η = 3g₁/(g₁ − g₀) = 27/109, about 0.2477.
example : (3 * 3 : ℚ) / (3 - (-100 / 3)) = 27 / 109 := by norm_num
-- Short end reflected: 430 − (420 − 430)/2 = 435.
example : (430 : ℚ) - (420 - 430) / 2 = 435 := by norm_num
-- Both bracketed pieces of the parabola average to zero on [0, 1]: 1 − 2 + 1 = 0 and 1 − 1 = 0.
example : (1 : ℚ) - 4 / 2 + 3 / 3 = 0 := by norm_num
example : (3 : ℚ) / 3 - 2 / 2 = 0 := by norm_num

#print axioms quotes_fix_areas_not_shapes
#print axioms log_linear_forward_is_segment_forward
#print axioms monotone_convex_parabola_keeps_area
