-- Cross product: for any two arrows u and v in three dimensions, u × v is square to both, its length is |u| |v| sin θ (the parallelogram's area), its squared length is |u|² |v|² − (u · v)², the rows u, v, u × v have determinant (u × v) · (u × v) so the three are right-handed, swapping the edges reverses the arrow, and the card's solar-panel numbers come out as it says.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Data.Fin.VecNotation

/-! An arrow in space is a list of three real numbers, `u : Fin 3 → ℝ`, with parts
`u 0` east, `u 1` north, `u 2` up, and `![10, 0, 0]` is the arrow (10, 0, 0). Mathlib's
`u ⨯₃ v` (`crossProduct`) is the card's formula
`(u₂ v₃ − u₃ v₂, u₃ v₁ − u₁ v₃, u₁ v₂ − u₂ v₁)`, and `u ⬝ᵥ v` is the dot product. The card's
length `|u|` is `√(u ⬝ᵥ u)`. The angle `θ` between the edges is
`InnerProductGeometry.angle` on `EuclideanSpace ℝ (Fin 3)`, where `WithLp.toLp 2 u` is the
same list read as an arrow on square axes. Right-handed axes are built into the formula:
`Matrix.det ![u, v, w]` is the determinant with rows `u`, `v`, `w`, and a positive value
means the three keep the handedness of east, north, up. -/

open Matrix InnerProductGeometry

/-- The cross product's three facts. For any two arrows `u` and `v` in three dimensions, the
arrow `w = u × v` is square to both edges (`w · u = 0` and `w · v = 0`), and its length is
one edge times the other's height above it: `|w| = |u| |v| sin θ`, with `θ` the angle
between the edges. -/
theorem cross_product_square_to_both_with_area_as_length (u v : Fin 3 → ℝ) :
    (u ⨯₃ v) ⬝ᵥ u = 0 ∧ (u ⨯₃ v) ⬝ᵥ v = 0 ∧
    √((u ⨯₃ v) ⬝ᵥ (u ⨯₃ v)) =
      √(u ⬝ᵥ u) * √(v ⬝ᵥ v) * Real.sin (angle (WithLp.toLp 2 u) (WithLp.toLp 2 v)) := by
  have h2 : (u ⨯₃ v) ⬝ᵥ (u ⨯₃ v) = (u ⬝ᵥ u) * (v ⬝ᵥ v) - (u ⬝ᵥ v) ^ 2 := by
    rw [cross_dot_cross, dotProduct_comm v u]; ring
  have hin : ∀ a b : Fin 3 → ℝ, inner ℝ (WithLp.toLp 2 a) (WithLp.toLp 2 b) = a ⬝ᵥ b := by
    intro a b
    rw [EuclideanSpace.inner_toLp_toLp, dotProduct_comm]; simp
  refine ⟨?_, ?_, ?_⟩
  · rw [dotProduct_comm]; exact dot_self_cross u v
  · rw [dotProduct_comm]; exact dot_cross_self u v
  · have key := sin_angle_mul_norm_mul_norm (WithLp.toLp 2 u) (WithLp.toLp 2 v)
    rw [norm_eq_sqrt_real_inner, norm_eq_sqrt_real_inner, hin, hin, hin] at key
    rw [h2, mul_comm _ (Real.sin _), key]
    congr 1; ring

/-- Step 2, the area squared. For any two arrows `u` and `v` in three dimensions, the squares
of the three parts of `u × v` add to `|u|² |v|² − (u · v)²`, the parallelogram's base
squared times its height squared. -/
theorem cross_product_length_sq_eq_area_sq (u v : Fin 3 → ℝ) :
    (u ⨯₃ v) ⬝ᵥ (u ⨯₃ v) = (u ⬝ᵥ u) * (v ⬝ᵥ v) - (u ⬝ᵥ v) ^ 2 := by
  rw [cross_dot_cross, dotProduct_comm v u]; ring

/-- Step 4, the right-hand rule and order. For any two arrows `u` and `v` in three
dimensions, the determinant with rows `u`, `v`, `u × v` equals `(u × v) · (u × v)`, so it is
positive whenever the edges are not parallel (the three are right-handed), and swapping the
edges reverses the arrow: `v × u = −(u × v)`. -/
theorem cross_product_right_handed_and_order_reverses (u v : Fin 3 → ℝ) :
    Matrix.det ![u, v, u ⨯₃ v] = (u ⨯₃ v) ⬝ᵥ (u ⨯₃ v) ∧
    (LinearIndependent ℝ ![u, v] → 0 < Matrix.det ![u, v, u ⨯₃ v]) ∧
    v ⨯₃ u = -(u ⨯₃ v) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [← triple_product_eq_det, ← triple_product_permutation]
  · intro h
    rw [← triple_product_eq_det, ← triple_product_permutation]
    have hne : u ⨯₃ v ≠ 0 := crossProduct_ne_zero_iff_linearIndependent.mpr h
    obtain ⟨i, hi⟩ := Function.ne_iff.mp hne
    have hp : 0 < (u ⨯₃ v) i * (u ⨯₃ v) i := mul_self_pos.mpr hi
    simp only [dotProduct, Fin.sum_univ_three]
    have h0 := mul_self_nonneg ((u ⨯₃ v) 0)
    have h1 := mul_self_nonneg ((u ⨯₃ v) 1)
    have h2 := mul_self_nonneg ((u ⨯₃ v) 2)
    fin_cases i <;> simp only [Fin.zero_eta, Fin.mk_one, Fin.reduceFinMk] at hp <;> linarith
  · exact (cross_anticomm u v).symm

-- The panel: u = (10, 0, 0) and v = (0, 4.8, 3.6) = (0, 24/5, 18/5) give w = (0, −36, 48).
example : (![10, 0, 0] : Fin 3 → ℚ) ⨯₃ ![0, 24/5, 18/5] = ![0, -36, 48] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
-- Square to the slope: −36 × 4.8 + 48 × 3.6 = 0; and square to the bottom edge.
example : (![0, -36, 48] : Fin 3 → ℚ) ⬝ᵥ ![0, 24/5, 18/5] = 0 ∧
    (![0, -36, 48] : Fin 3 → ℚ) ⬝ᵥ ![10, 0, 0] = 0 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- The area: 0² + 36² + 48² = 3600 = 60², and the edges are 10 m and 6 m long, so 10 × 6 = 60.
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![0, -36, 48] = 3600 ∧ (3600 : ℤ) = 60 ^ 2 := by
  decide
example : (![0, 24/5, 18/5] : Fin 3 → ℚ) ⬝ᵥ ![0, 24/5, 18/5] = 6 ^ 2 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : √((3600 : ℝ)) = 60 := by
  rw [show (3600 : ℝ) = 60 ^ 2 by norm_num]; exact Real.sqrt_sq (by norm_num)
-- Swapping the edges: v × u = (0, 36, −48).
example : (![0, 24/5, 18/5] : Fin 3 → ℚ) ⨯₃ ![10, 0, 0] = ![0, 36, -48] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
-- The determinant with rows u, v, w is 3600.
example : Matrix.det ![(![10, 0, 0] : Fin 3 → ℚ), ![0, 24/5, 18/5], ![0, -36, 48]] = 3600 := by
  erw [Matrix.det_fin_three]; simp; norm_num
-- Case 2, the panel turned: u = (8, 6, 0), v = (−2.88, 3.84, 3.6) give (21.6, −28.8, 48),
-- whose squared length is still 3600.
example : (![8, 6, 0] : Fin 3 → ℚ) ⨯₃ ![-72/25, 96/25, 18/5] = ![108/5, -144/5, 48] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : (![108/5, -144/5, 48] : Fin 3 → ℚ) ⬝ᵥ ![108/5, -144/5, 48] = 3600 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- The mistake: middle part in the wrong order gives (0, 36, 48), whose dot with v is
-- 345.6 = 1728/5, not 0.
example : (![0, 36, 48] : Fin 3 → ℚ) ⬝ᵥ ![0, 24/5, 18/5] = 1728/5 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num

#print axioms cross_product_square_to_both_with_area_as_length
#print axioms cross_product_length_sq_eq_area_sq
#print axioms cross_product_right_handed_and_order_reverses
