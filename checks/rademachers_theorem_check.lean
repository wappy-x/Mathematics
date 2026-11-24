-- Rademacher's theorem: a function on n-dimensional space that is Lipschitz is differentiable, with a gradient of length at most its Lipschitz constant, at almost every point.
import Mathlib.Analysis.Calculus.Rademacher
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace

open MeasureTheory
open scoped NNReal Gradient

/-- Rademacher's theorem: if a real function `f` on n-dimensional space is Lipschitz with
constant `L` (its values at two points never differ by more than `L` times their distance),
then `f` is differentiable, that is, has a tangent plane, at every point outside a set of
Lebesgue measure zero. -/
theorem lipschitz_differentiable_ae {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ} {L : ℝ≥0}
    (hf : LipschitzWith L f) :
    ∀ᵐ p ∂(volume : Measure (EuclideanSpace ℝ (Fin n))), DifferentiableAt ℝ f p := by
  exact hf.ae_differentiableAt

/-- The card's formula in gradient form: for a real function `f` on n-dimensional space that is
Lipschitz with constant `L`, at almost every point `p` the tangent plane built from the gradient
`∇ f p` predicts `f` with an error that shrinks faster than the step, and that gradient has
length at most `L`. -/
theorem lipschitz_hasGradientAt_ae_norm_le {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {L : ℝ≥0} (hf : LipschitzWith L f) :
    ∀ᵐ p ∂(volume : Measure (EuclideanSpace ℝ (Fin n))),
      HasGradientAt f (∇ f p) p ∧ ‖∇ f p‖ ≤ L := by
  filter_upwards [hf.ae_differentiableAt] with p hp
  refine ⟨hp.hasGradientAt, ?_⟩
  have h1 : ‖∇ f p‖ = ‖fderiv ℝ f p‖ := by
    simp only [gradient]
    exact (InnerProductSpace.toDual ℝ _).symm.norm_map _
  rw [h1]
  exact norm_fderiv_le_of_lipschitz ℝ hf

/-- Finitely many real values: a map from n-dimensional space to m-dimensional space that is
Lipschitz with constant `L` is differentiable at almost every point. -/
theorem lipschitz_differentiable_ae_vector {n m : ℕ}
    {f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin m)} {L : ℝ≥0}
    (hf : LipschitzWith L f) :
    ∀ᵐ p ∂(volume : Measure (EuclideanSpace ℝ (Fin n))), DifferentiableAt ℝ f p := by
  exact hf.ae_differentiableAt

-- Worked numbers from the card, in exact fractions (metres).
-- Mower A = (1.5, 2.0): its distance to the centre is 2.5, since 1.5^2 + 2.0^2 = 6.25 = 2.5^2.
example : (3 / 2 : ℚ) ^ 2 + 2 ^ 2 = (5 / 2) ^ 2 := by norm_num
-- d(A) = 2.5 - 1 = 1.5.
example : (5 / 2 : ℚ) - 1 = 3 / 2 := by norm_num
-- The gradient at A is A divided by its length: (1.5/2.5, 2.0/2.5) = (0.6, 0.8), of length 1.
example : (3 / 2 : ℚ) / (5 / 2) = 3 / 5 ∧ (2 : ℚ) / (5 / 2) = 4 / 5 := by norm_num
example : (3 / 5 : ℚ) ^ 2 + (4 / 5) ^ 2 = 1 := by norm_num
-- Mower B = (0.3, 0.4): distance 0.5 to the centre, so d(B) = 1 - 0.5 = 0.5, gradient (-0.6, -0.8).
example : (3 / 10 : ℚ) ^ 2 + (4 / 10) ^ 2 = (1 / 2) ^ 2 := by norm_num
example : (-3 / 5 : ℚ) ^ 2 + (-4 / 5) ^ 2 = 1 := by norm_num
-- Step 0.1 east from A: the plane predicts 1.5 + 0.6 × 0.1 = 1.56.
example : (3 / 2 : ℚ) + 3 / 5 * (1 / 10) = 39 / 25 := by norm_num
-- At the fence point P, d(1.1, 0) = d(0.9, 0) = 0.1; their average 0.1 over step 0.1 is error 1.
example : ((1 / 10 : ℚ) + 1 / 10) / 2 / (1 / 10) = 1 := by norm_num
-- The slice y = 0.5 meets the fence where x^2 = 1 - 0.25 = 0.75.
example : (1 : ℚ) - (1 / 2) ^ 2 = 3 / 4 := by norm_num

#print axioms lipschitz_differentiable_ae
#print axioms lipschitz_hasGradientAt_ae_norm_le
#print axioms lipschitz_differentiable_ae_vector
