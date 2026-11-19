-- Differential form: every k-form is a sum of its weights times shadow determinants, the wedge of two one-forms is a two-by-two determinant, and swapping a k-form and an l-form multiplies by (-1)^(kl).
import Mathlib.LinearAlgebra.ExteriorPower.Pairing
import Mathlib.LinearAlgebra.ExteriorPower.Basis
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Finset.Sort
import Mathlib.Data.Real.Basic

open scoped BigOperators

/-- A k-form at a point of n-dimensional space (a rule that takes k directions, is linear in
each, and flips sign when two directions swap) is fixed by its weights: on any k edges it equals
the sum, over every sorted list `I` of k different axes, of its value on the unit arrows along
those axes times the k-by-k determinant of the edges' parts along the axes in `I`, the signed
size of the box's shadow on that coordinate k-plane. For k = 2 this says every two-form is
`∑_{i<j} ω_ij dx^i ∧ dx^j`. -/
theorem k_form_eq_sum_weights_mul_shadow_dets {n k : ℕ}
    (ω : (Fin n → ℝ) [⋀^Fin k]→ₗ[ℝ] ℝ) (v : Fin k → Fin n → ℝ) :
    ω v = ∑ I : {I : Finset (Fin n) // I.card = k},
      ω (fun m => Pi.single (I.1.orderEmbOfFin I.2 m) (1 : ℝ)) *
        Matrix.det (Matrix.of fun m j => v j (I.1.orderEmbOfFin I.2 m)) := by
  set b := Pi.basisFun ℝ (Fin n)
  set B := b.exteriorPower k
  set φ := exteriorPower.alternatingMapLinearEquiv ω
  rw [← exteriorPower.alternatingMapLinearEquiv_apply_ιMulti ω v, ← B.sum_repr
    (exteriorPower.ιMulti ℝ k v), map_sum]
  refine Fintype.sum_equiv (ι := ↥(Set.powersetCard (Fin n) k))
    (κ := {I : Finset (Fin n) // I.card = k}) (Equiv.refl _) _ _ ?_
  intro s
  rw [map_smul, smul_eq_mul, mul_comm, exteriorPower.basis_repr_apply,
    exteriorPower.ιMultiDual_apply_ιMulti, exteriorPower.basis_apply,
    exteriorPower.ιMulti_family, exteriorPower.alternatingMapLinearEquiv_apply_ιMulti,
    ← Matrix.det_transpose, Set.powersetCard.ofFinEmbEquiv_symm_apply]
  congr 2
  funext m
  simp [b]
  rfl

/-- The wedge of two one-forms, taken in Mathlib's exterior algebra of the dual space, measures
two directions by `(α ∧ β)(u, v) = α(u) β(v) - α(v) β(u)`: the first form on the first direction
times the second form on the second, minus the same with the directions swapped. -/
theorem wedge_of_one_forms_apply {V : Type*} [AddCommGroup V] [Module ℝ V]
    (α β : Module.Dual ℝ V) (u v : V) :
    exteriorPower.pairingDual ℝ V 2 (exteriorPower.ιMulti ℝ 2 ![α, β])
        (exteriorPower.ιMulti ℝ 2 ![u, v]) = α u * β v - α v * β u := by
  rw [exteriorPower.pairingDual_ιMulti_ιMulti, Matrix.det_fin_two]
  simp
  ring

/-- The sign rule: for a k-form `α` and an l-form `β`, `α ∧ β = (-1)^(kl) β ∧ α`. -/
theorem wedge_comm_sign {V : Type*} [AddCommGroup V] [Module ℝ V] {k l : ℕ}
    (α : ⋀[ℝ]^k (Module.Dual ℝ V)) (β : ⋀[ℝ]^l (Module.Dual ℝ V)) :
    (α : ExteriorAlgebra ℝ (Module.Dual ℝ V)) * β =
      (-1 : ℝ) ^ (k * l) • ((β : ExteriorAlgebra ℝ (Module.Dual ℝ V)) * α) := by
  have amem : α.1 ∈ ⋀[ℝ]^k (Module.Dual ℝ V) := α.2
  have bmem : β.1 ∈ ⋀[ℝ]^l (Module.Dual ℝ V) := β.2
  rw [← (Submodule.ext_iff.mp (ExteriorAlgebra.ιMulti_span_fixedDegree ℝ _))] at amem bmem
  refine Submodule.span_induction₂ (p := fun x y _ _ ↦
    x * y = (-1 : ℝ) ^ (k * l) • (y * x)) ?_ ?_ ?_ ?_ ?_ ?_ ?_ amem bmem
  · rintro x y ⟨mx, rfl⟩ ⟨my, rfl⟩
    rw [ExteriorAlgebra.ιMulti_mul_ιMulti_anticomm, Units.smul_def, Units.val_pow_eq_pow_val,
      Units.val_neg, Units.val_one, ← Int.cast_smul_eq_zsmul ℝ]
    push_cast
    rw [mul_comm]
  all_goals try simp +contextual [add_mul, mul_add, smul_add]
  all_goals intro r x y _ _ h; rw [smul_comm]

-- The band on the weather map: u = (120, 50) km, v = (30, 90) km; the ground shadow
-- u₁v₂ - u₂v₁ is 9300 km², and -9300 km² with the arrows swapped.
example : Matrix.det !![(120 : ℤ), 30; 50, 90] = 9300 := by
  norm_num [Matrix.det_fin_two]
example : Matrix.det !![(30 : ℤ), 120; 90, 50] = -9300 := by
  norm_num [Matrix.det_fin_two]

-- The hillside field: u = (40, 10, 0) m, v = (-6, 24, 18) m; its three shadows
-- dy∧dz, dz∧dx, dx∧dy are 180, -720 and 1020 m².
example : (10 : ℤ) * 18 - 0 * 24 = 180 := by norm_num
example : (0 : ℤ) * (-6) - 40 * 18 = -720 := by norm_num
example : (40 : ℤ) * 24 - 10 * (-6) = 1020 := by norm_num

-- The rain form with weights P = 3/2, Q = -2, R = -6 (mm/h) on the field: -4410 L/h,
-- and the same from the three-by-three slab determinant of q, u and v.
example : (3 / 2 : ℚ) * 180 + (-2) * (-720) + (-6) * 1020 = -4410 := by norm_num
example : Matrix.det !![(3 / 2 : ℚ), -2, -6; 40, 10, 0; -6, 24, 18] = -4410 := by
  norm_num [Matrix.det_fin_three]

-- A two-form in n dimensions has one weight per pair of axes: 1, 3, 6, 10 for n = 2, 3, 4, 5.
example : [2, 3, 4, 5].map (fun n => n * (n - 1) / 2) = [1, 3, 6, 10] := by decide
example : Fintype.card {I : Finset (Fin 4) // I.card = 2} = 6 := by decide

#print axioms k_form_eq_sum_weights_mul_shadow_dets
#print axioms wedge_of_one_forms_apply
#print axioms wedge_comm_sign
