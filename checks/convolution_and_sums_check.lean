-- Convolution: for independent real random variables, the law of their sum is the convolution of their two laws, its density is the integral of f(x) g(s - x) when they have densities, and convolution of laws is commutative and associative.
import Mathlib.MeasureTheory.Group.Convolution
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Group.LIntegral
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Measure.Haar.Unique

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-- The law of an independent sum is the convolution of the two laws. Let `P` be a probability
on the outcome space `Ω`, and `X`, `Y` two measurable real readings that are independent, with
laws `μ = P.map X` and `ν = P.map Y`. Then the law of the sum `S = X + Y` is the convolution
`μ ∗ ν` (Mathlib's `Measure.conv`: the product law `μ ⊗ ν` carried through addition), and in
both forms of the card's definition: for every Borel set `B` of totals, `P(S ∈ B)` is the
product-law measure of the pairs `(x, y)` with `x + y ∈ B`, and it is also the average over `x`
(against `μ`) of `ν(B - x)`, the `ν`-measure of the `y` with `x + y ∈ B`. -/
theorem law_of_independent_sum_eq_convolution {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] {X Y : Ω → ℝ}
    (hX : Measurable X) (hY : Measurable Y) (hXY : IndepFun X Y P) :
    P.map (X + Y) = (P.map X) ∗ (P.map Y) ∧
      ∀ B : Set ℝ, MeasurableSet B →
        P.map (X + Y) B = ((P.map X).prod (P.map Y)) {p : ℝ × ℝ | p.1 + p.2 ∈ B} ∧
        P.map (X + Y) B = ∫⁻ x, (P.map Y) {y : ℝ | x + y ∈ B} ∂(P.map X) := by
  have hconv := hXY.map_add_eq_map_conv_map hX hY
  refine ⟨hconv, fun B hB => ⟨?_, ?_⟩⟩
  · rw [hconv, Measure.conv, Measure.map_apply (by fun_prop) hB]
    rfl
  · rw [hconv, Measure.conv, Measure.map_apply (by fun_prop) hB,
      Measure.prod_apply (measurable_add hB)]
    rfl

/-- Densities convolve. Let `X`, `Y` be independent measurable real readings on a probability
space, and suppose the law of `X` has a density `f` against length (Lebesgue measure): a
non-negative Borel function, allowed the value `∞`, with `P(X ∈ B) = ∫_B f`. Then the sum
`X + Y` has the density `s ↦ ∫ f(s - y) ν(dy)`, where `ν` is the law of `Y`, with no density
needed for `Y`. If the law of `Y` also has a density `g`, the sum has the density
`h(s) = ∫ f(x) g(s - x) dx`. -/
theorem density_of_independent_sum_eq_convolution_of_densities {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] {X Y : Ω → ℝ}
    (hX : Measurable X) (hY : Measurable Y) (hXY : IndepFun X Y P)
    {f : ℝ → ℝ≥0∞} (hf : Measurable f) (hfX : P.map X = volume.withDensity f) :
    P.map (X + Y) = volume.withDensity (fun s => ∫⁻ y, f (s - y) ∂(P.map Y)) ∧
      ∀ g : ℝ → ℝ≥0∞, Measurable g → P.map Y = volume.withDensity g →
        P.map (X + Y) = volume.withDensity (fun s => ∫⁻ x, f x * g (s - x)) := by
  have key : ∀ (ν : Measure ℝ) [SFinite ν],
      (volume.withDensity f) ∗ ν = volume.withDensity (fun s => ∫⁻ y, f (s - y) ∂ν) := by
    intro ν _
    have hh : Measurable (fun s => ∫⁻ y, f (s - y) ∂ν) :=
      Measurable.lintegral_prod_right' (f := fun p : ℝ × ℝ => f (p.1 - p.2)) (by fun_prop)
    refine Measure.ext_of_lintegral _ fun φ hφ => ?_
    rw [Measure.lintegral_conv hφ,
      lintegral_withDensity_eq_lintegral_mul _ hf
        (Measurable.lintegral_prod_right' (f := fun p : ℝ × ℝ => φ (p.1 + p.2)) (by fun_prop)),
      lintegral_withDensity_eq_lintegral_mul _ hh hφ]
    simp only [Pi.mul_apply]
    calc ∫⁻ x, f x * ∫⁻ y, φ (x + y) ∂ν
        = ∫⁻ x, ∫⁻ y, f x * φ (x + y) ∂ν := by
          refine lintegral_congr fun x => ?_
          rw [lintegral_const_mul _ (by fun_prop)]
      _ = ∫⁻ y, ∫⁻ x, f x * φ (x + y) ∂volume ∂ν :=
          lintegral_lintegral_swap (by fun_prop)
      _ = ∫⁻ y, ∫⁻ s, f (s - y) * φ s ∂volume ∂ν := by
          refine lintegral_congr fun y => ?_
          rw [← lintegral_add_right_eq_self (fun s => f (s - y) * φ s) y]
          simp only [add_sub_cancel_right]
      _ = ∫⁻ s, ∫⁻ y, f (s - y) * φ s ∂ν ∂volume :=
          lintegral_lintegral_swap (by fun_prop)
      _ = ∫⁻ s, (∫⁻ y, f (s - y) ∂ν) * φ s := by
          refine lintegral_congr fun s => ?_
          rw [lintegral_mul_const _ (by fun_prop)]
  have h1 := hXY.map_add_eq_map_conv_map hX hY
  rw [hfX] at h1
  rw [key] at h1
  refine ⟨h1, fun g hg hgY => ?_⟩
  rw [h1, hgY]
  congr 1
  funext s
  rw [lintegral_withDensity_eq_lintegral_mul _ hg (by fun_prop),
    ← lintegral_sub_left_eq_self (fun x => f x * g (s - x)) s]
  refine lintegral_congr fun y => ?_
  simp only [Pi.mul_apply, sub_sub_cancel]
  ring

/-- The order and the grouping of independent summands do not matter: for any three
probability laws `μ`, `ν`, `ρ` on the line, `μ ∗ ν = ν ∗ μ` and `(μ ∗ ν) ∗ ρ = μ ∗ (ν ∗ ρ)`. -/
theorem convolution_of_laws_comm_and_assoc (μ ν ρ : Measure ℝ) [IsProbabilityMeasure μ]
    [IsProbabilityMeasure ν] [IsProbabilityMeasure ρ] :
    μ ∗ ν = ν ∗ μ ∧ (μ ∗ ν) ∗ ρ = μ ∗ (ν ∗ ρ) := by
  exact ⟨Measure.conv_comm μ ν, Measure.conv_assoc μ ν ρ⟩

/-! The card's worked numbers, in exact fractions or whole-number counts. -/

/-- The step formula `(p * q)(k) = ∑ a, p(a) q(k - a)` for laws on the whole numbers 0, 1, 2, ...,
here applied to chance counts. -/
def slide (p q : ℕ → ℕ) (k : ℕ) : ℕ := ∑ a ∈ Finset.range (k + 1), p a * q (k - a)

/-- The tenths ruler: count 1 (chance 1/10) on each of 0, 1, ..., 9 tenths of a metre. -/
def tenths (a : ℕ) : ℕ := if a < 10 then 1 else 0

/-- The fifths ruler: count 1 (chance 1/5) on each of 0, 2, 4, 6, 8 tenths of a metre. -/
def fifths (b : ℕ) : ℕ := if b < 10 ∧ b % 2 = 0 then 1 else 0

-- Tenths plus fifths: the chances times 50 on totals 0 to 17 tenths, by the slide formula.
example : (List.range 18).map (slide tenths fifths)
    = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1] := by decide

-- The same numbers from listing all 50 pairs and adding their chances (the product-law form).
example : ∀ k < 18, slide tenths fifths k
    = ∑ a ∈ Finset.range 10, ∑ b ∈ Finset.range 10,
        tenths a * fifths b * (if a + b = k then 1 else 0) := by decide

-- p * q = q * p, and (p * q) * p = p * (q * p), at every total that can occur.
example : ∀ k < 18, slide tenths fifths k = slide fifths tenths k := by decide
example : ∀ k < 27, slide (slide tenths fifths) tenths k
    = slide tenths (slide fifths tenths) k := by decide

-- The 10 by 10 grid read at cell midpoints: 1 + 2 + 3 + 4 = 10 pairs of cells with a + b ≤ 3.
example : ((Finset.range 10 ×ˢ Finset.range 10).filter (fun c => c.1 + c.2 ≤ 3)).card = 10 := by
  decide

-- The grid undercounts 1/8 by 1/(4n): 10/100, 1225/10000 and 124750/1000000.
example : (1 : ℚ) / 8 - 10 / 100 = 1 / (4 * 10) := by norm_num
example : (1 : ℚ) / 8 - 1225 / 10000 = 1 / (4 * 100) := by norm_num
example : (1 : ℚ) / 8 - 124750 / 1000000 = 1 / (4 * 1000) := by norm_num

-- The corner of the board, and the slices 1/2 - x integrated from 0 to 1/2: both 1/8.
example : (1 : ℚ) / 2 * (1 / 2) / 2 = 1 / 8 := by norm_num
example : (1 : ℚ) / 2 * (1 / 2) - (1 / 2) ^ 2 / 2 = 1 / 8 := by norm_num

-- The middle band: P(0.5 ≤ S ≤ 1.5) = 1 - 1/8 - 1/8 = 3/4.
example : (1 : ℚ) - 1 / 8 - 1 / 8 = 3 / 4 := by norm_num

-- x exact, y on the fifths ruler: 1/5 × (1/2 + 3/10 + 1/10) = 9/50.
example : (1 : ℚ) / 5 * (1 / 2 + 3 / 10 + 1 / 10) = 9 / 50 := by norm_num

-- The mistake of multiplying CDFs: F(1/2) × F(1/2) = 1/4, not 1/8.
example : (1 : ℚ) / 2 * (1 / 2) = 1 / 4 ∧ (1 : ℚ) / 4 ≠ 1 / 8 := by norm_num

#print axioms law_of_independent_sum_eq_convolution
#print axioms density_of_independent_sum_eq_convolution_of_densities
#print axioms convolution_of_laws_comm_and_assoc
