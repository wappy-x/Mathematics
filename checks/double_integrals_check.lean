-- Double integrals: for a depth with no jumps on a region described by strips both ways, the double integral equals the strips-of-strips integral in either order, the card's catchment holds exactly 40 mm·km^2 of rain both ways, and the unbounded spike gives π/4 one way and −π/4 the other.
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Tactic.NormNum

open Set MeasureTheory Real

theorem dbl_aux_closed {a b : ℝ} {g₁ g₂ : ℝ → ℝ}
    (hg₁ : ContinuousOn g₁ (Icc a b)) (hg₂ : ContinuousOn g₂ (Icc a b)) :
    IsClosed {p : ℝ × ℝ | p.1 ∈ Icc a b ∧ p.2 ∈ Icc (g₁ p.1) (g₂ p.1)} := by
  have hS : IsClosed (Prod.fst ⁻¹' Icc a b : Set (ℝ × ℝ)) := isClosed_Icc.preimage continuous_fst
  have c₁ : ContinuousOn (fun p : ℝ × ℝ => g₁ p.1) (Prod.fst ⁻¹' Icc a b) :=
    hg₁.comp continuousOn_fst (fun p hp => hp)
  have c₂ : ContinuousOn (fun p : ℝ × ℝ => g₂ p.1) (Prod.fst ⁻¹' Icc a b) :=
    hg₂.comp continuousOn_fst (fun p hp => hp)
  have h1 := hS.isClosed_le c₁ continuous_snd.continuousOn
  have h2 := h1.isClosed_le continuous_snd.continuousOn (c₂.mono (fun p hp => hp.1))
  convert h2 using 1
  ext p
  simp only [mem_ofPred_eq, mem_preimage, mem_Icc]
  tauto

/-- North-strip Fubini (helper). -/
theorem dbl_aux_north
    (f : ℝ × ℝ → ℝ) (D : Set (ℝ × ℝ)) {a b : ℝ} {g₁ g₂ : ℝ → ℝ}
    (hab : a ≤ b) (hg : ∀ x ∈ Icc a b, g₁ x ≤ g₂ x)
    (hDm : MeasurableSet D) (hfi : IntegrableOn f D)
    (hD_north : D = {p | p.1 ∈ Icc a b ∧ p.2 ∈ Icc (g₁ p.1) (g₂ p.1)}) :
    (∫ p in D, f p) = ∫ x in a..b, ∫ y in g₁ x..g₂ x, f (x, y) := by
  rw [← integral_indicator hDm, Measure.volume_eq_prod,
    integral_prod _ ((integrable_indicator_iff hDm).2 hfi)]
  have key : ∀ x, (∫ y, D.indicator f (x, y)) =
      (Icc a b).indicator (fun x => ∫ y in Icc (g₁ x) (g₂ x), f (x, y)) x := by
    intro x
    by_cases hx : x ∈ Icc a b
    · rw [indicator_of_mem hx, ← integral_indicator measurableSet_Icc]
      congr 1
      ext y
      simp only [indicator, hD_north, mem_ofPred_eq, hx, true_and]
    · rw [indicator_of_notMem hx]
      have : ∀ y, D.indicator f (x, y) = 0 := by
        intro y
        apply indicator_of_notMem
        rw [hD_north]
        exact fun h => hx h.1
      simp [this]
  simp_rw [key]
  rw [integral_indicator measurableSet_Icc, integral_Icc_eq_integral_Ioc,
    intervalIntegral.integral_of_le hab]
  apply setIntegral_congr_fun measurableSet_Ioc
  intro x hx
  simp only
  rw [intervalIntegral.integral_of_le (hg x (Ioc_subset_Icc_self hx)),
    integral_Icc_eq_integral_Ioc]

/-- East-strip Fubini (helper). -/
theorem dbl_aux_east
    (f : ℝ × ℝ → ℝ) (D : Set (ℝ × ℝ)) {c d : ℝ} {h₁ h₂ : ℝ → ℝ}
    (hcd : c ≤ d) (hh : ∀ y ∈ Icc c d, h₁ y ≤ h₂ y)
    (hDm : MeasurableSet D) (hfi : IntegrableOn f D)
    (hD_east : D = {p | p.2 ∈ Icc c d ∧ p.1 ∈ Icc (h₁ p.2) (h₂ p.2)}) :
    (∫ p in D, f p) = ∫ y in c..d, ∫ x in h₁ y..h₂ y, f (x, y) := by
  rw [← integral_indicator hDm, Measure.volume_eq_prod,
    integral_prod_symm _ ((integrable_indicator_iff hDm).2 hfi)]
  have key : ∀ y, (∫ x, D.indicator f (x, y)) =
      (Icc c d).indicator (fun y => ∫ x in Icc (h₁ y) (h₂ y), f (x, y)) y := by
    intro y
    by_cases hy : y ∈ Icc c d
    · rw [indicator_of_mem hy, ← integral_indicator measurableSet_Icc]
      congr 1
      ext x
      simp only [indicator, hD_east, mem_ofPred_eq, hy, true_and]
    · rw [indicator_of_notMem hy]
      have : ∀ x, D.indicator f (x, y) = 0 := by
        intro x
        apply indicator_of_notMem
        rw [hD_east]
        exact fun h => hy h.1
      simp [this]
  simp_rw [key]
  rw [integral_indicator measurableSet_Icc, integral_Icc_eq_integral_Ioc,
    intervalIntegral.integral_of_le hcd]
  apply setIntegral_congr_fun measurableSet_Ioc
  intro y hy
  simp only
  rw [intervalIntegral.integral_of_le (hh y (Ioc_subset_Icc_self hy)),
    integral_Icc_eq_integral_Ioc]

#print axioms dbl_aux_closed
#print axioms dbl_aux_north
#print axioms dbl_aux_east

theorem catch_inner_north (x : ℝ) :
    (∫ y in (0 : ℝ)..x / 2, (6 + 3 * y + x * y)) = 3 * x + 3 / 8 * x ^ 2 + 1 / 8 * x ^ 3 := by
  have hd : ∀ y ∈ uIcc (0 : ℝ) (x / 2),
      HasDerivAt (fun y => 6 * y + 3 * y ^ 2 / 2 + x * y ^ 2 / 2) (6 + 3 * y + x * y) y := by
    intro y _
    have h := (((hasDerivAt_id y).const_mul 6).add (((hasDerivAt_pow 2 y).const_mul 3).div_const 2)).add
      (((hasDerivAt_pow 2 y).const_mul x).div_const 2)
    exact h.congr_deriv (by norm_num; ring)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd ((by fun_prop : Continuous fun y : ℝ => 6 + 3 * y + x * y).intervalIntegrable _ _)]
  ring

theorem catch_inner_east (y : ℝ) :
    (∫ x in 2 * y..4, (6 + 3 * y + x * y)) = 24 + 8 * y - 6 * y ^ 2 - 2 * y ^ 3 := by
  have hd : ∀ x ∈ uIcc (2 * y) 4,
      HasDerivAt (fun x => (6 + 3 * y) * x + y * x ^ 2 / 2) (6 + 3 * y + x * y) x := by
    intro x _
    have h := ((hasDerivAt_id x).const_mul (6 + 3 * y)).add (((hasDerivAt_pow 2 x).const_mul y).div_const 2)
    exact h.congr_deriv (by norm_num; ring)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd ((by fun_prop : Continuous fun x : ℝ => 6 + 3 * y + x * y).intervalIntegrable _ _)]
  ring

theorem catch_outer_north :
    (∫ x in (0 : ℝ)..4, ∫ y in (0 : ℝ)..x / 2, (6 + 3 * y + x * y)) = 40 := by
  simp only [catch_inner_north]
  have hd : ∀ x ∈ uIcc (0 : ℝ) 4,
      HasDerivAt (fun x => 3 * x ^ 2 / 2 + x ^ 3 / 8 + x ^ 4 / 32)
        (3 * x + 3 / 8 * x ^ 2 + 1 / 8 * x ^ 3) x := by
    intro x _
    have h := ((((hasDerivAt_pow 2 x).const_mul 3).div_const 2).add ((hasDerivAt_pow 3 x).div_const 8)).add
      ((hasDerivAt_pow 4 x).div_const 32)
    exact h.congr_deriv (by norm_num; ring)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd ((by fun_prop : Continuous fun x : ℝ => 3 * x + 3 / 8 * x ^ 2 + 1 / 8 * x ^ 3).intervalIntegrable _ _)]
  norm_num

theorem catch_outer_east :
    (∫ y in (0 : ℝ)..2, ∫ x in 2 * y..4, (6 + 3 * y + x * y)) = 40 := by
  simp only [catch_inner_east]
  have hd : ∀ y ∈ uIcc (0 : ℝ) 2,
      HasDerivAt (fun y => 24 * y + 4 * y ^ 2 - 2 * y ^ 3 - y ^ 4 / 2)
        (24 + 8 * y - 6 * y ^ 2 - 2 * y ^ 3) y := by
    intro y _
    have h := ((((hasDerivAt_id y).const_mul 24).add ((hasDerivAt_pow 2 y).const_mul 4)).sub
      ((hasDerivAt_pow 3 y).const_mul 2)).sub ((hasDerivAt_pow 4 y).div_const 2)
    exact h.congr_deriv (by norm_num; ring)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd ((by fun_prop : Continuous fun y : ℝ => 24 + 8 * y - 6 * y ^ 2 - 2 * y ^ 3).intervalIntegrable _ _)]
  norm_num

#print axioms catch_inner_north
#print axioms catch_inner_east
#print axioms catch_outer_north
#print axioms catch_outer_east

theorem spike_inner_y {x : ℝ} (hx : 0 < x) :
    (∫ y in (0 : ℝ)..1, (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2) = 1 / (1 + x ^ 2) := by
  have hd : ∀ y ∈ uIcc (0 : ℝ) 1,
      HasDerivAt (fun y => y / (x ^ 2 + y ^ 2)) ((x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2) y := by
    intro y _
    have hne : x ^ 2 + y ^ 2 ≠ 0 := by positivity
    have h := (hasDerivAt_id y).div ((hasDerivAt_pow 2 y).const_add (x ^ 2)) hne
    exact h.congr_deriv (by simp only [id]; field_simp; ring)
  have hc : Continuous fun y : ℝ => (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2 :=
    Continuous.div (by fun_prop) (by fun_prop) (fun y => by positivity)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd (hc.intervalIntegrable _ _)]
  ring

theorem spike_inner_x {y : ℝ} (hy : 0 < y) :
    (∫ x in (0 : ℝ)..1, (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2) = -(1 / (1 + y ^ 2)) := by
  have hd : ∀ x ∈ uIcc (0 : ℝ) 1,
      HasDerivAt (fun x => -(x / (x ^ 2 + y ^ 2))) ((x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2) x := by
    intro x _
    have hne : x ^ 2 + y ^ 2 ≠ 0 := by positivity
    have h := ((hasDerivAt_id x).div ((hasDerivAt_pow 2 x).add_const (y ^ 2)) hne).neg
    exact h.congr_deriv (by simp only [id]; field_simp; ring)
  have hc : Continuous fun x : ℝ => (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2 :=
    Continuous.div (by fun_prop) (by fun_prop) (fun x => by positivity)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd (hc.intervalIntegrable _ _)]
  ring

#print axioms spike_inner_y
#print axioms spike_inner_x

/-- **Fubini: strips of strips, in either order.** A region D of the plane is described by
north strips: x runs from a to b, and at each x the strip runs from y = g₁(x) up to y = g₂(x),
with g₁ ≤ g₂ and both ends moving continuously with x. The same region D is also described by
east strips: y runs from c to d, and at each y the strip runs from x = h₁(y) to x = h₂(y), with
h₁ ≤ h₂ and both ends moving continuously with y. If the depth f has no jumps on D (so it is
also bounded there, D being closed and bounded), then the double integral of f over D (the
area integral with respect to area in the plane) equals the north-strips integral
∫ from a to b of [∫ from g₁(x) to g₂(x) of f(x, y) dy] dx, and it also equals the east-strips
integral ∫ from c to d of [∫ from h₁(y) to h₂(y) of f(x, y) dx] dy. -/
theorem double_integral_eq_iterated_either_order
    (f : ℝ × ℝ → ℝ) (D : Set (ℝ × ℝ)) {a b c d : ℝ} {g₁ g₂ h₁ h₂ : ℝ → ℝ}
    (hab : a ≤ b) (hg₁ : ContinuousOn g₁ (Icc a b)) (hg₂ : ContinuousOn g₂ (Icc a b))
    (hg : ∀ x ∈ Icc a b, g₁ x ≤ g₂ x)
    (hcd : c ≤ d) (hh₁ : ContinuousOn h₁ (Icc c d)) (hh₂ : ContinuousOn h₂ (Icc c d))
    (hh : ∀ y ∈ Icc c d, h₁ y ≤ h₂ y)
    (hD_north : D = {p | p.1 ∈ Icc a b ∧ p.2 ∈ Icc (g₁ p.1) (g₂ p.1)})
    (hD_east : D = {p | p.2 ∈ Icc c d ∧ p.1 ∈ Icc (h₁ p.2) (h₂ p.2)})
    (hf : ContinuousOn f D) :
    (∫ p in D, f p) = ∫ x in a..b, ∫ y in g₁ x..g₂ x, f (x, y) ∧
    (∫ p in D, f p) = ∫ y in c..d, ∫ x in h₁ y..h₂ y, f (x, y) := by
  have hcl : IsClosed D := hD_north ▸ dbl_aux_closed hg₁ hg₂
  have hsub : D ⊆ Icc a b ×ˢ Icc c d := by
    intro p hp
    have h1 := hp
    have h2 := hp
    rw [hD_north] at h1
    rw [hD_east] at h2
    exact ⟨h1.1, h2.1⟩
  have hcpt : IsCompact D := (isCompact_Icc.prod isCompact_Icc).of_isClosed_subset hcl hsub
  have hfi : IntegrableOn f D := hf.integrableOn_compact hcpt
  exact ⟨dbl_aux_north f D hab hg hcl.measurableSet hfi hD_north,
    dbl_aux_east f D hcd hh hcl.measurableSet hfi hD_east⟩

/-- **The catchment.** On the triangle with corners (0, 0), (4, 0) and (4, 2) km, that is
0 ≤ x ≤ 4 and 0 ≤ y ≤ x/2, the rain depth is f(x, y) = 6 + 3y + xy mm. The double integral of
the depth over the triangle is exactly 40 mm·km^2 (40,000 m^3). North strips (x from 0 to 4,
y from 0 to x/2) give 40, and east strips (y from 0 to 2, x from 2y to 4) give 40 too. -/
theorem catchment_rain_eq_forty :
    (∫ p in {p : ℝ × ℝ | p.1 ∈ Icc 0 4 ∧ p.2 ∈ Icc 0 (p.1 / 2)}, (6 + 3 * p.2 + p.1 * p.2)) = 40 ∧
    (∫ x in (0 : ℝ)..4, ∫ y in (0 : ℝ)..x / 2, (6 + 3 * y + x * y)) = 40 ∧
    (∫ y in (0 : ℝ)..2, ∫ x in 2 * y..4, (6 + 3 * y + x * y)) = 40 := by
  refine ⟨?_, catch_outer_north, catch_outer_east⟩
  have h := double_integral_eq_iterated_either_order
    (fun p : ℝ × ℝ => 6 + 3 * p.2 + p.1 * p.2)
    {p : ℝ × ℝ | p.1 ∈ Icc 0 4 ∧ p.2 ∈ Icc 0 (p.1 / 2)}
    (a := 0) (b := 4) (c := 0) (d := 2)
    (g₁ := fun _ => 0) (g₂ := fun x => x / 2) (h₁ := fun y => 2 * y) (h₂ := fun _ => 4)
    (by norm_num) continuousOn_const (by fun_prop)
    (fun x hx => by linarith [hx.1])
    (by norm_num) (by fun_prop) continuousOn_const
    (fun y hy => by linarith [hy.2])
    rfl
    (by
      ext p
      simp only [mem_ofPred_eq, mem_Icc]
      constructor
      · rintro ⟨⟨h1, h2⟩, h3, h4⟩
        exact ⟨⟨h3, by linarith⟩, by linarith, h2⟩
      · rintro ⟨⟨h1, h2⟩, h3, h4⟩
        exact ⟨⟨by linarith, h4⟩, h1, by linarith⟩)
    (by fun_prop)
  exact h.1.trans catch_outer_north

/-- **Drop boundedness and the orders disagree.** The spike (x^2 − y^2)/(x^2 + y^2)^2 on the unit
square 0 ≤ x ≤ 1, 0 ≤ y ≤ 1 runs off to infinity near (0, 0). Integrating in y first, then x,
gives +π/4; integrating in x first, then y, gives −π/4. (At the single point (0, 0) Lean's
division by zero gives 0; one point changes no integral.) -/
theorem spike_iterated_integrals_disagree :
    (∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1, (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2) = π / 4 ∧
    (∫ y in (0 : ℝ)..1, ∫ x in (0 : ℝ)..1, (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) ^ 2) = -(π / 4) := by
  constructor
  · rw [intervalIntegral.integral_congr_ae (g := fun x : ℝ => 1 / (1 + x ^ 2))
      (Filter.Eventually.of_forall fun x hx => by
        rw [uIoc_of_le zero_le_one] at hx
        exact spike_inner_y hx.1)]
    have := integral_one_div_one_add_sq (a := 0) (b := 1)
    rw [this, arctan_one, arctan_zero, sub_zero]
  · rw [intervalIntegral.integral_congr_ae (g := fun y : ℝ => -(1 / (1 + y ^ 2)))
      (Filter.Eventually.of_forall fun y hy => by
        rw [uIoc_of_le zero_le_one] at hy
        exact spike_inner_x hy.1)]
    have := integral_one_div_one_add_sq (a := 0) (b := 1)
    rw [intervalIntegral.integral_neg, this, arctan_one, arctan_zero, sub_zero]

-- The depth 6 + 3y + xy matches the three gauges: 6 mm at (0, 0), 6 mm at (4, 0), 20 mm at (4, 2).
example : (6 : ℚ) + 3 * 0 + 0 * 0 = 6 ∧ (6 : ℚ) + 3 * 0 + 4 * 0 = 6 ∧ (6 : ℚ) + 3 * 2 + 4 * 2 = 20 := by
  norm_num
-- The catchment's area: half of 4 km by 2 km is 4 km^2.
example : (4 : ℚ) * 2 / 2 = 4 := by norm_num
-- The north strip at x = 2 carries 3·2 + (3/8)·2^2 + (1/8)·2^3 = 8.5 = 17/2 mm·km^2 per km.
example : (3 : ℚ) * 2 + 3 / 8 * 2 ^ 2 + 1 / 8 * 2 ^ 3 = 17 / 2 := by norm_num
-- Adding the north strips: 3·16/2 + 3·64/24 + 256/32 = 24 + 8 + 8 = 40.
example : (3 : ℚ) * 16 / 2 + 3 * 64 / 24 + 256 / 32 = 40 := by norm_num
-- The east strip at y = 1 carries 24 + 8 − 6 − 2 = 24 mm·km^2 per km.
example : (24 : ℚ) + 8 * 1 - 6 * 1 ^ 2 - 2 * 1 ^ 3 = 24 := by norm_num
-- Adding the east strips: 24·2 + 8·2^2/2 − 6·2^3/3 − 2·2^4/4 = 48 + 16 − 16 − 8 = 40.
example : (24 : ℚ) * 2 + 8 * 2 ^ 2 / 2 - 6 * 2 ^ 3 / 3 - 2 * 2 ^ 4 / 4 = 40 := by norm_num
-- Units: 40 mm·km^2 at 1,000 m^3 per mm·km^2 is 40,000 m^3.
example : (40 : ℕ) * 1000 = 40000 := by norm_num
-- The Step 1 bracket: (22·8 + 20·8)/n with n = 336 cells a side is exactly 1 mm·km^2.
example : ((22 : ℚ) * 8 + 20 * 8) / 336 = 1 := by norm_num
-- The spike's inner y-integral at x = 0.5 is 1/(1 + 0.5^2) = 0.8 = 4/5.
example : (1 : ℚ) / (1 + (1 / 2) ^ 2) = 4 / 5 := by norm_num

#print axioms double_integral_eq_iterated_either_order
#print axioms catchment_rain_eq_forty
#print axioms spike_iterated_integrals_disagree
