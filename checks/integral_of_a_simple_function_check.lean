-- The integral of a simple function: for a non-negative simple function on any measure space, the sum of value times measure over its level sets equals the sum of weight times measure for any way of writing it as weighted indicators of measurable sets, and this integral adds, scales and respects order.
import Mathlib.MeasureTheory.Function.SimpleFunc
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.Lebesgue.Add

open MeasureTheory
open scoped NNReal ENNReal


variable {α : Type*} [MeasurableSpace α]

/-- The card's definition, in standard form: for each of the finitely many values `a` that the
simple function `s` takes, multiply `a` by the measure of the set where `s` equals `a`, and add.
Values are finite and at least zero (`ℝ≥0`); measures may be infinite, with `0 * ∞ = 0`. -/
noncomputable def standardFormIntegral (s : SimpleFunc α ℝ≥0) (μ : Measure α) : ℝ≥0∞ :=
  ∑ a ∈ s.range, (a : ℝ≥0∞) * μ (s ⁻¹' {a})


/-- Helper: the standard-form total is the Lebesgue integral of `s`, viewed in `ℝ≥0∞`. -/
theorem standardFormIntegral_eq_lintegral (s : SimpleFunc α ℝ≥0) (μ : Measure α) :
    standardFormIntegral s μ = ∫⁻ x, (s x : ℝ≥0∞) ∂μ := by
  rw [standardFormIntegral, ← SimpleFunc.map_lintegral, ← SimpleFunc.lintegral_eq_lintegral]
  rfl

/-- Any way of writing a simple function gives the same total. If `s` equals
`c₁ 1_{B₁} + ... + c_m 1_{B_m}` at every point, with finite weights `c_j ≥ 0` and measurable sets
`B_j` that may overlap, then weight times measure added over the `B_j` equals value times measure
added over the level sets of `s`. -/
theorem integral_of_simple_function_any_representation (μ : Measure α) (s : SimpleFunc α ℝ≥0)
    {m : ℕ} (c : Fin m → ℝ≥0) (B : Fin m → Set α) (hB : ∀ j, MeasurableSet (B j))
    (hs : ∀ x, s x = ∑ j, (B j).indicator (fun _ => c j) x) :
    standardFormIntegral s μ = ∑ j, (c j : ℝ≥0∞) * μ (B j) := by
  rw [standardFormIntegral_eq_lintegral]
  have h : (fun x => (s x : ℝ≥0∞)) = fun x => ∑ j, (B j).indicator (fun _ => (c j : ℝ≥0∞)) x := by
    funext x
    rw [hs x, ENNReal.ofNNReal_finsetSum]
    refine Finset.sum_congr rfl fun j _ => ?_
    by_cases hx : x ∈ B j <;> simp [Set.indicator, hx]
  rw [h, lintegral_finsetSum _ fun j _ => measurable_const.indicator (hB j)]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [lintegral_indicator_const (hB j)]

/-- The integral adds and scales: for non-negative simple functions `s`, `t` and a number
`c ≥ 0`, the integral of `s + t` is the integral of `s` plus the integral of `t`, and the
integral of `c s` is `c` times the integral of `s`. -/
theorem integral_of_simple_function_add_and_scale (μ : Measure α) (s t : SimpleFunc α ℝ≥0)
    (c : ℝ≥0) :
    standardFormIntegral (s + t) μ = standardFormIntegral s μ + standardFormIntegral t μ ∧
      standardFormIntegral (c • s) μ = (c : ℝ≥0∞) * standardFormIntegral s μ := by
  refine ⟨?_, ?_⟩
  · simp only [standardFormIntegral_eq_lintegral, FunLike.coe_add, Pi.add_apply,
      ENNReal.coe_add]
    exact lintegral_add_left (SimpleFunc.measurable s).coe_nnreal_ennreal _
  · simp only [standardFormIntegral_eq_lintegral, FunLike.coe_smul, Pi.smul_apply,
      smul_eq_mul, ENNReal.coe_mul]
    exact lintegral_const_mul _ (SimpleFunc.measurable s).coe_nnreal_ennreal

/-- A lower staircase never has the larger total: if `s ≤ t` at every point, the integral of
`s` is at most the integral of `t`. -/
theorem integral_of_simple_function_mono (μ : Measure α) (s t : SimpleFunc α ℝ≥0)
    (hst : s ≤ t) :
    standardFormIntegral s μ ≤ standardFormIntegral t μ := by
  rw [standardFormIntegral_eq_lintegral, standardFormIntegral_eq_lintegral]
  exact lintegral_mono fun x => ENNReal.coe_le_coe.2 (hst x)


-- The card's die: faces pay 0, 0, 0, 2, 2, 6, each face with probability 1/6.
-- Point by point: (0 + 0 + 0 + 2 + 2 + 6)/6 = 5/3.
example : ((0 + 0 + 0 + 2 + 2 + 6 : ℚ) / 6) = 5 / 3 := by norm_num
-- By level sets: 0 on faces 1-3, 2 on faces 4-5, 6 on face 6: 0 × 3/6 + 2 × 2/6 + 6 × 1/6 = 5/3.
example : (0 : ℚ) * (3 / 6) + 2 * (2 / 6) + 6 * (1 / 6) = 5 / 3 := by norm_num

#print axioms standardFormIntegral_eq_lintegral
#print axioms integral_of_simple_function_any_representation
#print axioms integral_of_simple_function_add_and_scale
#print axioms integral_of_simple_function_mono
