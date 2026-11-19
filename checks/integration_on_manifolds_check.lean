-- Integration on an oriented manifold: a top-degree form has the same integral in every chart whose change of coordinates has positive Jacobian, swapping two coordinate arrows flips the sign, and the sum over chart pieces does not depend on the partition of unity.
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.GroupTheory.Perm.Sign

open MeasureTheory

/-- One chart change: a top-degree form `f du¹ ∧ ⋯ ∧ duⁿ` pulls back along the change of
coordinates `u = T v` to `(f ∘ T) · det DT dv¹ ∧ ⋯ ∧ dvⁿ`. When the change of coordinates is
one-to-one with derivative `DT` and positive Jacobian `det DT > 0` (the two charts agree on the
orientation), the ordinary integral of the form's coefficient is the same in either chart. -/
theorem integral_top_form_same_in_oriented_charts {n : ℕ} {s : Set (Fin n → ℝ)}
    {T : (Fin n → ℝ) → (Fin n → ℝ)} {DT : (Fin n → ℝ) → ((Fin n → ℝ) →L[ℝ] (Fin n → ℝ))}
    (hs : MeasurableSet s) (hT : ∀ v ∈ s, HasFDerivWithinAt T (DT v) s v)
    (hinj : Set.InjOn T s) (hpos : ∀ v ∈ s, 0 < (DT v).det) (f : (Fin n → ℝ) → ℝ) :
    ∫ u in T '' s, f u = ∫ v in s, f (T v) * (DT v).det := by
  rw [integral_image_eq_integral_abs_det_fderiv_smul volume hs hT hinj f]
  refine setIntegral_congr_fun hs (fun v hv => ?_)
  simp only [smul_eq_mul, abs_of_pos (hpos v hv)]
  ring

/-- Orientation: swapping two arrows of an ordered list of `n` arrows (the columns of `A`)
reverses the sign of their determinant, so it moves the list to the other orientation class. -/
theorem det_swap_two_arrows {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) {i j : Fin n} (hij : i ≠ j) :
    (A.submatrix id (Equiv.swap i j)).det = -A.det := by
  rw [Matrix.det_permute', Equiv.Perm.sign_swap hij]
  simp

/-- Two partitions of unity give the same total: if the weights `ψ a` add to 1 at every point,
and so do the weights `χ b`, then adding the integrals of the pieces `ψ a · g` gives the same
answer as adding the integrals of the pieces `χ b · g` (the double sum over pairs of charts). -/
theorem sum_integral_partition_of_unity_independent {X : Type*} [MeasurableSpace X]
    (μ : Measure X) {ι κ : Type*} [Fintype ι] [Fintype κ] (ψ : ι → X → ℝ) (χ : κ → X → ℝ)
    (g : X → ℝ) (hψ : ∀ x, ∑ a, ψ a x = 1) (hχ : ∀ x, ∑ b, χ b x = 1)
    (hint : ∀ a b, Integrable (fun x => ψ a x * χ b x * g x) μ) :
    ∑ a, ∫ x, ψ a x * g x ∂μ = ∑ b, ∫ x, χ b x * g x ∂μ := by
  have key : ∀ a, ∫ x, ψ a x * g x ∂μ = ∑ b, ∫ x, ψ a x * χ b x * g x ∂μ := by
    intro a
    rw [← integral_finsetSum _ (fun b _ => hint a b)]
    refine integral_congr_ae (Filter.Eventually.of_forall fun x => ?_)
    simp only
    rw [← Finset.sum_mul, ← Finset.mul_sum, hχ x, mul_one]
  have key2 : ∀ b, ∫ x, χ b x * g x ∂μ = ∑ a, ∫ x, ψ a x * χ b x * g x ∂μ := by
    intro b
    rw [← integral_finsetSum _ (fun a _ => hint a b)]
    refine integral_congr_ae (Filter.Eventually.of_forall fun x => ?_)
    simp only
    rw [← Finset.sum_mul, ← Finset.sum_mul, hψ x, one_mul]
  simp_rw [key, key2]
  exact Finset.sum_comm

-- The rim: plan radius 3 km on a sphere of radius 5 km, so the rim sits 5 - 4 = 1 km up.
example : (5 : ℚ) ^ 2 - 3 ^ 2 = 4 ^ 2 := by norm_num

-- The integral of z dA over the plan, in units of π km³: 45 - (2/3)(125 - 64) = 13/3.
example : (45 : ℚ) - 2 / 3 * (125 - 4 ^ 3) = 13 / 3 := by norm_num

-- The total catch, in units of π mm/h × km²: 10 × (9 + 13/3) = 400/3 (418.879020 = 400π/3).
example : (10 : ℚ) * (9 + 13 / 3) = 400 / 3 := by norm_num

-- Slope area in place of level ground: 150π against 400π/3 is exactly 1.125 = 9/8 times.
example : (150 : ℚ) / (400 / 3) = 9 / 8 := by norm_num

-- The rim point due east: dx ∧ dy on (∂φ, ∂θ) is R² sin φ₀ cos φ₀ = 25 × 3/5 × 4/5 = 12.
example : (25 : ℚ) * (3 / 5) * (4 / 5) = 12 := by norm_num

-- The lake filled to the rim: a cap 1 km deep on radius 5 km holds π · 1² · (3·5 - 1)/3 = 14π/3 km³.
example : (1 : ℚ) ^ 2 * (3 * 5 - 1) / 3 = 14 / 3 := by norm_num

-- In dimension 3, the order (ρ, z, θ) is (ρ, θ, z) with one swap: sign -1.
example : Equiv.Perm.sign (Equiv.swap (1 : Fin 3) 2) = -1 := by decide

#print axioms integral_top_form_same_in_oriented_charts
#print axioms det_swap_two_arrows
#print axioms sum_integral_partition_of_unity_independent
