-- Optimal transport: on a line the in-order pairing never costs more for any power p ≥ 1, prices give a floor under every plan, and a lump that must fill two holes has a plan but no map.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Dirac
import Mathlib.Topology.EMetricSpace.Lipschitz

open MeasureTheory
open scoped ENNReal

lemma abs_rpow_convex_comb (p : ℝ) (hp : 1 ≤ p) (x y l : ℝ) (hl0 : 0 ≤ l) (hl1 : l ≤ 1) :
    |l * x + (1 - l) * y| ^ p ≤ l * |x| ^ p + (1 - l) * |y| ^ p := by
  have h1 : |l * x + (1 - l) * y| ≤ l * |x| + (1 - l) * |y| := by
    calc |l * x + (1 - l) * y| ≤ |l * x| + |(1 - l) * y| := abs_add_le _ _
      _ = l * |x| + (1 - l) * |y| := by
        rw [abs_mul, abs_mul, abs_of_nonneg hl0, abs_of_nonneg (by linarith : (0:ℝ) ≤ 1 - l)]
  have h2 := (convexOn_rpow hp).2 (Set.mem_Ici.2 (abs_nonneg x)) (Set.mem_Ici.2 (abs_nonneg y))
    hl0 (by linarith : (0:ℝ) ≤ 1 - l) (by ring)
  simp only [smul_eq_mul] at h2
  calc |l * x + (1 - l) * y| ^ p ≤ (l * |x| + (1 - l) * |y|) ^ p :=
        Real.rpow_le_rpow (abs_nonneg _) h1 (by linarith)
    _ ≤ _ := h2

#print axioms abs_rpow_convex_comb

/-- The never-cross rule: for a power `p ≥ 1`, two grains at `a ≤ b` and two trench spots `s ≤ t`,
sending the grains in order (`a` to `s`, `b` to `t`) never costs more than the swapped pairing,
when carrying one unit a distance `d` costs `d ^ p`. -/
theorem in_order_pairing_never_costs_more (p : ℝ) (hp : 1 ≤ p) (a b s t : ℝ)
    (hab : a ≤ b) (hst : s ≤ t) :
    |a - s| ^ p + |b - t| ^ p ≤ |a - t| ^ p + |b - s| ^ p := by
  rcases eq_or_lt_of_le (show a - t ≤ b - s by linarith) with h | h
  · have e1 : a - s = a - t := by linarith
    have e2 : b - t = a - t := by linarith
    have e3 : b - s = a - t := by linarith
    rw [e1, e2, e3]
  · set x := a - t
    set y := b - s
    have hd : 0 < y - x := by linarith
    set l := (y - (a - s)) / (y - x) with hl
    have hl0 : 0 ≤ l := div_nonneg (by simp only [y]; linarith) hd.le
    have hl1 : l ≤ 1 := by
      rw [div_le_one hd]; simp only [x]; linarith
    have hu : a - s = l * x + (1 - l) * y := by
      simp only [hl]; field_simp; ring
    have hv : b - t = (1 - l) * x + (1 - (1 - l)) * y := by
      simp only [hl]; field_simp; simp only [x, y]; ring
    have k1 := abs_rpow_convex_comb p hp x y l hl0 hl1
    have k2 := abs_rpow_convex_comb p hp x y (1 - l) (by linarith) (by linarith)
    rw [hu, hv]
    nlinarith [k1, k2]

/-- Prices give a floor under every plan: if the pile `μ` and the trench `ν` have equal totals
(both are probability distributions on the line) with finite average distance from the origin,
`γ` is any plan (coupling) whose row totals are `μ` and column totals are `ν`, and the price `f`
never changes faster than 1 per metre, then the plan's work is at least the gain in price,
`∫ f dν - ∫ f dμ ≤ ∫ |x - y| dγ`. -/
theorem price_floor_under_every_plan (μ ν : Measure ℝ) [IsProbabilityMeasure μ]
    [IsProbabilityMeasure ν] (hμ : Integrable (fun x => |x|) μ) (hν : Integrable (fun y => |y|) ν)
    (γ : Measure (ℝ × ℝ)) (hγμ : γ.map Prod.fst = μ) (hγν : γ.map Prod.snd = ν)
    (f : ℝ → ℝ) (hf : LipschitzWith 1 f) :
    ∫ y, f y ∂ν - ∫ x, f x ∂μ ≤ ∫ z, |z.1 - z.2| ∂γ := by
  have hfc : Continuous f := hf.continuous
  have hfm : Measurable f := hfc.measurable
  have hbound : ∀ x, |f x| ≤ |f 0| + |x| := by
    intro x
    have := hf.dist_le_mul x 0
    simp only [NNReal.coe_one, one_mul, Real.dist_eq, sub_zero] at this
    calc |f x| = |(f x - f 0) + f 0| := by ring_nf
      _ ≤ |f x - f 0| + |f 0| := abs_add_le _ _
      _ ≤ |x| + |f 0| := by linarith
      _ = |f 0| + |x| := by ring
  have hfint : ∀ (m : Measure ℝ) [IsProbabilityMeasure m], Integrable (fun x => |x|) m →
      Integrable f m := by
    intro m _ hm
    refine Integrable.mono' ((integrable_const |f 0|).add hm) hfc.aestronglyMeasurable ?_
    exact Filter.Eventually.of_forall (fun x => by simpa [Real.norm_eq_abs] using hbound x)
  have hfμ := hfint μ hμ
  have hfν := hfint ν hν
  have h1 : Integrable (fun z : ℝ × ℝ => f z.1) γ := by
    rw [← hγμ] at hfμ
    exact hfμ.comp_measurable measurable_fst
  have h2 : Integrable (fun z : ℝ × ℝ => f z.2) γ := by
    rw [← hγν] at hfν
    exact hfν.comp_measurable measurable_snd
  have a1 : Integrable (fun z : ℝ × ℝ => |z.1|) γ := by
    rw [← hγμ] at hμ
    exact hμ.comp_measurable measurable_fst
  have a2 : Integrable (fun z : ℝ × ℝ => |z.2|) γ := by
    rw [← hγν] at hν
    exact hν.comp_measurable measurable_snd
  have hd : Integrable (fun z : ℝ × ℝ => |z.1 - z.2|) γ := by
    refine Integrable.mono' (a1.add a2) ?_ ?_
    · exact (continuous_abs.comp (continuous_fst.sub continuous_snd)).aestronglyMeasurable
    · exact Filter.Eventually.of_forall (fun z => by
        simp only [Real.norm_eq_abs, abs_abs]
        exact abs_sub _ _)
  have eν : ∫ y, f y ∂ν = ∫ z, f z.2 ∂γ := by
    rw [← hγν, integral_map measurable_snd.aemeasurable hfc.aestronglyMeasurable]
  have eμ : ∫ x, f x ∂μ = ∫ z, f z.1 ∂γ := by
    rw [← hγμ, integral_map measurable_fst.aemeasurable hfc.aestronglyMeasurable]
  rw [eν, eμ, ← integral_sub h2 h1]
  refine integral_mono (h2.sub h1) hd (fun z => ?_)
  have := hf.dist_le_mul z.2 z.1
  simp only [NNReal.coe_one, one_mul, Real.dist_eq] at this
  calc f z.2 - f z.1 ≤ |f z.2 - f z.1| := le_abs_self _
    _ ≤ |z.2 - z.1| := this
    _ = |z.1 - z.2| := abs_sub_comm _ _

/-- Monge can fail, Kantorovich cannot: with all the sand in one lump at 0 m and two half-holes at
-1 m and +1 m, no map pushes the lump onto the holes, but a plan with the right totals exists
that sends half each way at average distance 1 m. -/
theorem lump_into_two_holes_plan_but_no_map :
    (¬ ∃ T : ℝ → ℝ, Measurable T ∧
        (Measure.dirac (0 : ℝ)).map T =
          (1 / 2 : ℝ≥0∞) • Measure.dirac (-1 : ℝ) + (1 / 2 : ℝ≥0∞) • Measure.dirac (1 : ℝ)) ∧
    ∃ γ : Measure (ℝ × ℝ),
      γ.map Prod.fst = Measure.dirac (0 : ℝ) ∧
      γ.map Prod.snd =
        (1 / 2 : ℝ≥0∞) • Measure.dirac (-1 : ℝ) + (1 / 2 : ℝ≥0∞) • Measure.dirac (1 : ℝ) ∧
      ∫ z, |z.1 - z.2| ∂γ = 1 := by
  refine ⟨?_, ?_⟩
  · rintro ⟨T, hT, hmap⟩
    rw [Measure.map_dirac' hT] at hmap
    have h := congrArg (fun m : Measure ℝ => m {1}) hmap
    simp only [Measure.add_apply, Measure.smul_apply, smul_eq_mul] at h
    rw [Measure.dirac_apply' _ (measurableSet_singleton _),
      Measure.dirac_apply' _ (measurableSet_singleton _),
      Measure.dirac_apply' _ (measurableSet_singleton _)] at h
    have hne : (-1 : ℝ) ∉ ({1} : Set ℝ) := by norm_num
    rw [Set.indicator_of_notMem hne, Set.indicator_of_mem (Set.mem_singleton _)] at h
    simp only [Pi.one_apply, mul_zero, mul_one, zero_add] at h
    by_cases hT0 : T 0 ∈ ({1} : Set ℝ)
    · rw [Set.indicator_of_mem hT0] at h
      simp only [Pi.one_apply] at h
      norm_num at h
      exact ne_of_gt (ENNReal.inv_lt_one.2 (by norm_num)) h
    · rw [Set.indicator_of_notMem hT0] at h
      norm_num at h
      exact (ENNReal.inv_ne_zero.2 ENNReal.ofNat_ne_top) h.symm
  · refine ⟨(1 / 2 : ℝ≥0∞) • Measure.dirac ((0 : ℝ), (-1 : ℝ)) +
      (1 / 2 : ℝ≥0∞) • Measure.dirac ((0 : ℝ), (1 : ℝ)), ?_, ?_, ?_⟩
    · rw [Measure.map_add _ _ measurable_fst, Measure.map_smul, Measure.map_smul,
        Measure.map_dirac' measurable_fst, Measure.map_dirac' measurable_fst, ← add_smul,
        ENNReal.add_halves, one_smul]
      all_goals exact measurable_fst.aemeasurable
    · rw [Measure.map_add _ _ measurable_snd, Measure.map_smul, Measure.map_smul,
        Measure.map_dirac' measurable_snd, Measure.map_dirac' measurable_snd]
      all_goals exact measurable_snd.aemeasurable
    · rw [integral_add_measure, integral_smul_measure, integral_smul_measure,
        integral_dirac, integral_dirac]
      · norm_num
      · exact (integrable_dirac (by simp)).smul_measure (by simp)
      · exact (integrable_dirac (by simp)).smul_measure (by simp)

-- Worked numbers, by hand (exact fractions, in metres).
-- Price floor with f(x) = x: trench centre 7/2 minus pile centre 1.
example : (7 / 2 : ℚ) - 1 = 5 / 2 := by norm_num
-- E[X^2] = 1/4 + 11/12 = 7/6 and E[Y^2] = (4^3 - 3^3)/3 = 37/3.
example : (1 / 4 : ℚ) + 11 / 12 = 7 / 6 := by norm_num
example : ((4 : ℚ) ^ 3 - 3 ^ 3) / 3 = 37 / 3 := by norm_num
-- E[X F(X)] = 1/10 + 31/60 = 37/60, and E[XY] in order = 3 × 1 + 37/60 = 217/60.
example : (1 / 10 : ℚ) + 31 / 60 = 37 / 60 := by norm_num
example : (3 : ℚ) * 1 + 37 / 60 = 217 / 60 := by norm_num
-- W2^2 = 7/6 + 37/3 - 2 × 217/60 = 94/15 = (5/2)^2 + 1/60.
example : (7 / 6 : ℚ) + 37 / 3 - 2 * (217 / 60) = 94 / 15 := by norm_num
example : (94 / 15 : ℚ) = (5 / 2) ^ 2 + 1 / 60 := by norm_num
-- Monge map at 0.5 m: F(1/2) = (1/2)^2 / 2 = 1/8, so the sand lands at 3 + 1/8 and is carried 21/8.
example : ((1 / 2 : ℚ) ^ 2 / 2 = 1 / 8) ∧ (3 + 1 / 8 - 1 / 2 : ℚ) = 21 / 8 := by norm_num
-- Brute force over 6 loads: 6! = 720 plans.
example : Nat.factorial 6 = 720 := by decide

#print axioms in_order_pairing_never_costs_more
#print axioms price_floor_under_every_plan
#print axioms lump_into_two_holes_plan_but_no_map
