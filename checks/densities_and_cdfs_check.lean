-- Densities: if a random variable's chance of landing in every window is the area under a nonnegative curve of total area 1, then its CDF is the running area under that curve, its slope is the curve wherever the curve is continuous, windows are differences of the CDF, and single values carry chance zero.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Constructions.BorelSpace.Order
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Tactic.NormNum

open MeasureTheory Set

theorem densities_cdf_eq_integral_Iic {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (f : ℝ → ℝ) (hf_int : Integrable f)
    (hdens : ∀ a b, a ≤ b → (P {ω | a ≤ X ω ∧ X ω ≤ b}).toReal = ∫ x in a..b, f x)
    (x : ℝ) : (P {ω | X ω ≤ x}).toReal = ∫ t in Iic x, f t := by
  set s : ℕ → Set Ω := fun n => {ω | x - n ≤ X ω ∧ X ω ≤ x} with hs
  have hmono : Monotone s := by
    intro m n hmn ω hω
    simp only [hs, mem_ofPred_eq] at hω ⊢
    refine ⟨le_trans ?_ hω.1, hω.2⟩
    have : (m : ℝ) ≤ n := by exact_mod_cast hmn
    linarith
  have hU : (⋃ n, s n) = {ω | X ω ≤ x} := by
    ext ω
    simp only [hs, mem_iUnion, mem_ofPred_eq]
    constructor
    · rintro ⟨n, -, h⟩; exact h
    · intro h
      obtain ⟨n, hn⟩ := exists_nat_ge (x - X ω)
      exact ⟨n, by linarith, h⟩
  have h1 := tendsto_measure_iUnion_atTop (μ := P) hmono
  rw [hU] at h1
  have h2 : Filter.Tendsto (fun n => (P (s n)).toReal) Filter.atTop
      (nhds (P {ω | X ω ≤ x}).toReal) :=
    (ENNReal.tendsto_toReal (measure_ne_top P _)).comp h1
  have h3 : Filter.Tendsto (fun n : ℕ => ∫ t in (x - n)..x, f t) Filter.atTop
      (nhds (∫ t in Iic x, f t)) := by
    refine intervalIntegral_tendsto_integral_Iic x hf_int.integrableOn ?_
    exact Filter.tendsto_atBot_add_const_left _ x
      (Filter.tendsto_neg_atTop_atBot.comp tendsto_natCast_atTop_atTop) |>.congr
        (fun n => by simp [sub_eq_add_neg])
  have h4 : (fun n => (P (s n)).toReal) = fun n : ℕ => ∫ t in (x - n)..x, f t := by
    funext n
    exact hdens _ _ (by have : (0 : ℝ) ≤ n := n.cast_nonneg; linarith)
  rw [h4] at h2
  exact tendsto_nhds_unique h2 h3

#print axioms densities_cdf_eq_integral_Iic

/-- The density is the CDF's slope. Let `X` be a random variable with density `f`: `f` is never
negative, its total area is 1, and for every window `a ≤ b` the chance `P(a ≤ X ≤ b)` is the area
under `f` from `a` to `b`. Then wherever `f` is continuous, the CDF `F(y) = P(X ≤ y)` has slope
`f(x)` at `x`, that is `F'(x) = f(x)`. -/
theorem density_is_slope_of_cdf {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (hX : Measurable X) (f : ℝ → ℝ)
    (hf_nonneg : ∀ x, 0 ≤ f x) (hf_int : Integrable f) (hf_one : ∫ x, f x = 1)
    (hdens : ∀ a b, a ≤ b → (P {ω | a ≤ X ω ∧ X ω ≤ b}).toReal = ∫ x in a..b, f x)
    (x : ℝ) (hfx : ContinuousAt f x) :
    HasDerivAt (fun y => (P {ω | X ω ≤ y}).toReal) (f x) x := by
  have hF : (fun y => (P {ω | X ω ≤ y}).toReal) =
      fun y => (∫ t in Iic x, f t) + ∫ t in x..y, f t := by
    funext y
    rw [densities_cdf_eq_integral_Iic P X f hf_int hdens y,
      ← intervalIntegral.integral_Iic_sub_Iic hf_int.integrableOn hf_int.integrableOn]
    ring
  rw [hF]
  have := intervalIntegral.integral_hasDerivAt_right (a := x) (b := x)
    (hf_int.intervalIntegrable) hf_int.aestronglyMeasurable.stronglyMeasurableAtFilter hfx
  simpa using this.const_add (∫ t in Iic x, f t)

/-- The CDF is the running total of area, and windows are differences. For `X` with density `f`
as above, `F(x) = P(X ≤ x)` equals the area under `f` from the far left up to `x`, and for every
window `a ≤ b` the chance `P(a < X ≤ b)` equals `F(b) - F(a)`. -/
theorem cdf_is_running_area {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (hX : Measurable X) (f : ℝ → ℝ)
    (hf_nonneg : ∀ x, 0 ≤ f x) (hf_int : Integrable f) (hf_one : ∫ x, f x = 1)
    (hdens : ∀ a b, a ≤ b → (P {ω | a ≤ X ω ∧ X ω ≤ b}).toReal = ∫ x in a..b, f x) :
    (∀ x, (P {ω | X ω ≤ x}).toReal = ∫ t in Iic x, f t) ∧
      ∀ a b, a ≤ b →
        (P {ω | a < X ω ∧ X ω ≤ b}).toReal =
          (P {ω | X ω ≤ b}).toReal - (P {ω | X ω ≤ a}).toReal := by
  refine ⟨densities_cdf_eq_integral_Iic P X f hf_int hdens, ?_⟩
  intro a b hab
  have hmeas : MeasurableSet {ω | a < X ω ∧ X ω ≤ b} :=
    (measurableSet_lt measurable_const hX).inter (measurableSet_le hX measurable_const)
  have hsplit : {ω | X ω ≤ b} = {ω | X ω ≤ a} ∪ {ω | a < X ω ∧ X ω ≤ b} := by
    ext ω
    simp only [mem_ofPred_eq, mem_union]
    constructor
    · intro h
      by_cases h' : X ω ≤ a
      · exact Or.inl h'
      · exact Or.inr ⟨lt_of_not_ge h', h⟩
    · rintro (h | h)
      · linarith
      · exact h.2
  have hdisj : Disjoint {ω | X ω ≤ a} {ω | a < X ω ∧ X ω ≤ b} := by
    rw [Set.disjoint_left]
    intro ω h1 h2
    simp only [mem_ofPred_eq] at h1 h2
    linarith [h2.1]
  rw [hsplit, measure_union hdisj hmeas,
    ENNReal.toReal_add (measure_ne_top P _) (measure_ne_top P _)]
  ring

/-- A single value has chance zero. For `X` with density `f` as above, `P(X = x) = 0` for every
`x`, so "below `x`" and "at or below `x`" have the same chance: `P(X < x) = P(X ≤ x)`. -/
theorem single_value_has_chance_zero {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (hX : Measurable X) (f : ℝ → ℝ)
    (hf_nonneg : ∀ x, 0 ≤ f x) (hf_int : Integrable f) (hf_one : ∫ x, f x = 1)
    (hdens : ∀ a b, a ≤ b → (P {ω | a ≤ X ω ∧ X ω ≤ b}).toReal = ∫ x in a..b, f x)
    (x : ℝ) :
    P {ω | X ω = x} = 0 ∧ P {ω | X ω < x} = P {ω | X ω ≤ x} := by
  have h0 : P {ω | X ω = x} = 0 := by
    have h := hdens x x le_rfl
    simp only [intervalIntegral.integral_same] at h
    have hset : {ω | x ≤ X ω ∧ X ω ≤ x} = {ω | X ω = x} := by
      ext ω
      simp only [mem_ofPred_eq]
      constructor
      · rintro ⟨h1, h2⟩; linarith
      · intro h; exact ⟨h.ge, h.le⟩
    rw [hset, ENNReal.toReal_eq_zero_iff] at h
    exact h.resolve_right (measure_ne_top P _)
  refine ⟨h0, ?_⟩
  have hsplit : {ω | X ω ≤ x} = {ω | X ω < x} ∪ {ω | X ω = x} := by
    ext ω
    simp only [mem_ofPred_eq, mem_union]
    exact le_iff_lt_or_eq
  apply le_antisymm
  · exact measure_mono (fun ω (h : X ω < x) => le_of_lt h)
  · rw [hsplit]
    calc P ({ω | X ω < x} ∪ {ω | X ω = x}) ≤ P {ω | X ω < x} + P {ω | X ω = x} :=
          measure_union_le _ _
      _ = P {ω | X ω < x} := by rw [h0, add_zero]

/-! The card's hand table, as exact fractions of its printed four-place figures. -/

-- Sum of the six strip areas: 0.0287 + 0.0120 + 0.0042 + 0.0013 + 0.0003 + 0.0001 = 0.0466.
example : (287 + 120 + 42 + 13 + 3 + 1 : ℚ) / 10000 = 466 / 10000 := by norm_num

-- The hand sum falls short of F(-2) = 0.0478 by 0.0012.
example : (478 : ℚ) / 10000 - 466 / 10000 = 12 / 10000 := by norm_num

#print axioms density_is_slope_of_cdf
#print axioms cdf_is_running_area
#print axioms single_value_has_chance_zero
