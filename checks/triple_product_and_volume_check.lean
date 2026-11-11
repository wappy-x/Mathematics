-- Triple product: for any three edges a, b, c from one corner in space, the slanted box they span holds |(a × b) · c| cubic units, (a × b) · c is the determinant with rows a, b, c, cycling the edges keeps it while swapping two flips its sign, four points share a plane exactly when the triple product of the edges from one of them is zero, and the card's crate numbers come out as it says.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.AffineSpace.FiniteDimensional
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.Data.Fin.VecNotation

/-! An edge in space is a list of three real numbers, `a : Fin 3 → ℝ` (sideways, back, up),
and `![20, 0, 0]` is the edge (20, 0, 0). Mathlib's `a ⨯₃ b` (`crossProduct`) is the card's
cross product and `u ⬝ᵥ v` its dot product. `Matrix.det ![a, b, c]` is the determinant of the
3 by 3 matrix whose rows are `a`, `b`, `c`. `parallelepiped ![a, b, c]` is the slanted box on
the three edges from the corner 0: every point `s a + t b + u c` with `s`, `t`, `u` between 0
and 1, so its faces are flat and all three edges leave one shared corner. `volume` is the
ordinary volume on square axes (Lebesgue measure on `Fin 3 → ℝ`), in the edges' unit cubed.
`Coplanar ℝ {P, Q, R, S}` says the four points lie in one plane. -/

open MeasureTheory Matrix

/-- The triple product is the box's volume and a determinant. For any three edges `a`, `b`,
`c` leaving one corner, the slanted box (parallelepiped) on them holds `|(a × b) · c|` cubic
units: the triple product with its sign dropped. And the triple product itself,
`(a × b) · c`, is the determinant of the 3 by 3 matrix with rows `a`, `b`, `c`. -/
theorem triple_product_is_box_volume_and_determinant (a b c : Fin 3 → ℝ) :
    volume (parallelepiped ![a, b, c]) = ENNReal.ofReal |(a ⨯₃ b) ⬝ᵥ c| ∧
      (a ⨯₃ b) ⬝ᵥ c = Matrix.det ![a, b, c] := by
  have hdet : (a ⨯₃ b) ⬝ᵥ c = Matrix.det ![a, b, c] := by
    rw [dotProduct_comm, triple_product_permutation, triple_product_eq_det]
  refine ⟨?_, hdet⟩
  have h : (Pi.basisFun ℝ (Fin 3)).addHaar = volume := by
    rw [← addHaarMeasure_eq_volume_pi, ← Module.Basis.parallelepiped_basisFun, ← Module.Basis.addHaar_def]
  rw [← h, Measure.addHaar_parallelepiped, Pi.basisFun_det_apply, hdet]
  rfl

/-- The sign is the order. For any three edges, cycling them to the order `b`, `c`, `a`
keeps the triple product, and swapping two edges (`b` before `a`) flips its sign. -/
theorem triple_product_cycle_keeps_swap_flips (a b c : Fin 3 → ℝ) :
    (b ⨯₃ c) ⬝ᵥ a = (a ⨯₃ b) ⬝ᵥ c ∧ (b ⨯₃ a) ⬝ᵥ c = -((a ⨯₃ b) ⬝ᵥ c) := by
  constructor <;>
  · simp [cross_apply, dotProduct, Fin.sum_univ_succ]
    ring

/-- Zero means flat. Any four points `P`, `Q`, `R`, `S` in space lie in one plane exactly
when the triple product of the edges from `P` is zero:
`((Q − P) × (R − P)) · (S − P) = 0`. -/
theorem four_points_share_a_plane_iff_triple_product_zero (P Q R S : Fin 3 → ℝ) :
    Coplanar ℝ ({P, Q, R, S} : Set (Fin 3 → ℝ)) ↔ ((Q - P) ⨯₃ (R - P)) ⬝ᵥ (S - P) = 0 := by
  set v : Fin 3 → Fin 3 → ℝ := ![Q - P, R - P, S - P] with hv
  have hspan : vectorSpan ℝ ({P, Q, R, S} : Set (Fin 3 → ℝ)) = Submodule.span ℝ (Set.range v) := by
    rw [vectorSpan_eq_span_vsub_set_right ℝ (Set.mem_insert P _)]
    simp [hv, Set.image_insert_eq, Matrix.range_cons, Matrix.range_empty, Submodule.span_insert_zero]
    congr 1
    ext x
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    tauto
  rw [coplanar_iff_finrank_le_two, hspan,
    (triple_product_is_box_volume_and_determinant _ _ _).2]
  have hle : (Set.range v).finrank ℝ ≤ 3 := by
    simpa using finrank_range_le_card (R := ℝ) v
  have hli : LinearIndependent ℝ v ↔ Matrix.det (Matrix.of v) ≠ 0 := by
    rw [← isUnit_iff_ne_zero, ← Matrix.isUnit_iff_isUnit_det, ← linearIndependent_row_iff_isUnit]
    rfl
  have h3 : LinearIndependent ℝ v ↔ 3 = (Set.range v).finrank ℝ := by
    simpa using (linearIndependent_iff_card_eq_finrank_span (R := ℝ) (b := v))
  change Module.finrank ℝ (Submodule.span ℝ (Set.range v)) ≤ 2 ↔ Matrix.det (Matrix.of v) = 0
  have : Module.finrank ℝ (Submodule.span ℝ (Set.range v)) = (Set.range v).finrank ℝ := rfl
  rw [this]
  constructor
  · intro h
    by_contra hd
    have := h3.1 (hli.2 hd)
    omega
  · intro hd
    by_contra h
    have : 3 = (Set.range v).finrank ℝ := by omega
    exact (hli.1 (h3.2 this)) hd

-- The crate: a = (20, 0, 0), b = (5, 15, 0), c = (4, 3, 12) in dm.
-- The floor arrow a × b = (0, 0, 300), as long as the floor's area: 300² = 90000.
example : (![20, 0, 0] : Fin 3 → ℤ) ⨯₃ ![5, 15, 0] = ![0, 0, 300] := by decide
example : (![0, 0, 300] : Fin 3 → ℤ) ⬝ᵥ ![0, 0, 300] = 300 ^ 2 := by decide
-- Dot with the post: (a × b) · c = 3600 litres, and the determinant with rows a, b, c is 3600.
example : ((![20, 0, 0] : Fin 3 → ℤ) ⨯₃ ![5, 15, 0]) ⬝ᵥ ![4, 3, 12] = 3600 := by decide
example : Matrix.det ![(![20, 0, 0] : Fin 3 → ℤ), ![5, 15, 0], ![4, 3, 12]] = 3600 := by
  decide
-- The height: 3600 / 300 = 12 dm.
example : (3600 : ℤ) / 300 = 12 := by decide
-- Order: a · (b × c) = 3600 and (b × a) · c = −3600.
example : (![20, 0, 0] : Fin 3 → ℤ) ⬝ᵥ (![5, 15, 0] ⨯₃ ![4, 3, 12]) = 3600 := by decide
example : ((![5, 15, 0] : Fin 3 → ℤ) ⨯₃ ![20, 0, 0]) ⬝ᵥ ![4, 3, 12] = -3600 := by decide
-- The post is 13 dm long (4² + 3² + 12² = 13²), so floor area × post = 300 × 13 = 3900, the
-- second mistake.
example : (![4, 3, 12] : Fin 3 → ℤ) ⬝ᵥ ![4, 3, 12] = 13 ^ 2 ∧ (300 : ℤ) * 13 = 3900 := by
  decide
-- The flat lid: edges from P are a, b and a + b = (25, 15, 0); the triple product is 0.
example : ((![20, 0, 0] : Fin 3 → ℤ) ⨯₃ ![5, 15, 0]) ⬝ᵥ ![25, 15, 0] = 0 := by decide
-- The sagging lid: third edge (25, 15, −1/2) gives −150, a gap of −150 / 300 = −1/2 dm.
example : ((![20, 0, 0] : Fin 3 → ℚ) ⨯₃ ![5, 15, 0]) ⬝ᵥ ![25, 15, -1/2] = -150 ∧
    (-150 : ℚ) / 300 = -1/2 := by
  simp [cross_apply, dotProduct, Fin.sum_univ_succ]; norm_num
-- The bent front: P = O, Q = a, R = c, S = (24, 5/2, 12) give 120.
example : ((![20, 0, 0] : Fin 3 → ℚ) ⨯₃ ![4, 3, 12]) ⬝ᵥ ![24, 5/2, 12] = 120 := by
  simp [cross_apply, dotProduct, Fin.sum_univ_succ]; norm_num
-- Mistake 3: the corner positions Q = (24, 3, 12), R = (9, 18, 12), S = (29, 18, 12) of the
-- flat lid used as edges give −3600.
example : ((![24, 3, 12] : Fin 3 → ℤ) ⨯₃ ![9, 18, 12]) ⬝ᵥ ![29, 18, 12] = -3600 := by decide
-- The second box, rows (1, 2, 3), (2, −1, 1), (0, 3, 1): triple product 10, determinant 10.
example : ((![1, 2, 3] : Fin 3 → ℤ) ⨯₃ ![2, -1, 1]) ⬝ᵥ ![0, 3, 1] = 10 := by decide
example : Matrix.det ![(![1, 2, 3] : Fin 3 → ℤ), ![2, -1, 1], ![0, 3, 1]] = 10 := by decide
-- Try changing: post straight up (0, 0, 12) gives 3600; post (4, 3, 6) gives 1800;
-- corner sagging to 11, third edge (25, 15, −1), gives −300.
example : ((![20, 0, 0] : Fin 3 → ℤ) ⨯₃ ![5, 15, 0]) ⬝ᵥ ![0, 0, 12] = 3600 := by decide
example : ((![20, 0, 0] : Fin 3 → ℤ) ⨯₃ ![5, 15, 0]) ⬝ᵥ ![4, 3, 6] = 1800 := by decide
example : ((![20, 0, 0] : Fin 3 → ℤ) ⨯₃ ![5, 15, 0]) ⬝ᵥ ![25, 15, -1] = -300 := by decide

#print axioms triple_product_is_box_volume_and_determinant
#print axioms triple_product_cycle_keeps_swap_flips
#print axioms four_points_share_a_plane_iff_triple_product_zero
