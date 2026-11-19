-- Algebraic cycles: a holomorphic 2-form vanishes on every complex line, so a complex curve sees only type (1, 1), and the card's slice, intersection and torus numbers check exactly.
import Mathlib.LinearAlgebra.Alternating.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Dimension.FreeAndStrongRankCondition
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Complex.Basic
import Mathlib.Tactic

open Complex Matrix

/-- A complex piece sees only type (p, p), in the card's case of a curve: a (2, 0)-form, that is a
complex-bilinear alternating form, gives 0 on every pair of vectors in a complex line, such as the
tangent pair (u, iu) of a complex curve. -/
theorem two_zero_form_vanishes_on_complex_line {V : Type*} [AddCommGroup V] [Module ℂ V]
    (σ : V [⋀^Fin 2]→ₗ[ℂ] ℂ) (S : Submodule ℂ V) (hS : Module.finrank ℂ S = 1)
    (x y : V) (hx : x ∈ S) (hy : y ∈ S) :
    σ ![x, y] = 0 := by
  obtain ⟨v, -, hv⟩ := (finrank_eq_one_iff' (K := ℂ) (V := S)).mp hS
  obtain ⟨a, ha⟩ := hv ⟨x, hx⟩
  obtain ⟨b, hb⟩ := hv ⟨y, hy⟩
  have hx' : a • (v : V) = x := by
    have := congrArg Subtype.val ha; simpa using this
  have hy' : b • (v : V) = y := by
    have := congrArg Subtype.val hb; simpa using this
  apply σ.map_linearDependent
  intro hLI
  have h := LinearIndependent.pair_iff.mp hLI
  by_cases ha0 : a = 0
  · have hx0 : x = 0 := by rw [← hx', ha0, zero_smul]
    have := h 1 0 (by simp [hx0])
    exact one_ne_zero this.1
  · have := h b (-a) (by
      rw [← hx', ← hy', smul_smul, smul_smul, ← add_smul]; ring_nf; exact zero_smul _ _)
    exact ha0 (neg_eq_zero.mp this.2)

/-- The plane slice: putting w = -x + y + z into x^4 - y^4 - z^4 + w^4 gives
2 (x - y)(x - z) q with q = x^2 + 2y^2 + 2z^2 - xy - xz + 3yz, so the slice is L + M + C. -/
theorem quartic_plane_slice_factors {R : Type*} [CommRing R] (x y z : R) :
    x ^ 4 - y ^ 4 - z ^ 4 + (-x + y + z) ^ 4
      = 2 * (x - y) * (x - z) * (x ^ 2 + 2 * y ^ 2 + 2 * z ^ 2 - x * y - x * z + 3 * y * z) := by
  ring

/-- On E × E with lattice basis (1, 0), (i, 0), (0, 1), (0, i), the form dz1 ∧ dz2 on the real
2-torus spanned by s and t equals (p13 - p24) + i (p14 + p23), where p_jk = s_j t_k - s_k t_j
(indices 1 to 4 on the card, 0 to 3 here). -/
theorem dz1_wedge_dz2_on_torus_class (s t : Fin 4 → ℝ) :
    ((s 0 : ℂ) + s 1 * I) * ((t 2 : ℂ) + t 3 * I) - ((s 2 : ℂ) + s 3 * I) * ((t 0 : ℂ) + t 1 * I)
      = (((s 0 * t 2 - s 2 * t 0) - (s 1 * t 3 - s 3 * t 1) : ℝ) : ℂ)
        + (((s 0 * t 3 - s 3 * t 0) + (s 1 * t 2 - s 2 * t 1) : ℝ) : ℂ) * I := by
  push_cast
  ring_nf
  rw [I_sq]
  ring

-- The conic's matrix has determinant 3/2 and leading minors 1, 7/4, 3/2: smooth, no real points.
example : !![(1 : ℚ), -1/2, -1/2; -1/2, 2, 3/2; -1/2, 3/2, 2].det = 3/2 := by
  norm_num [Matrix.det_fin_three]
example : (1 : ℚ) * 2 - (-1/2) ^ 2 = 7/4 := by norm_num

-- Discriminants: q on x = y (and on x = z) is 2y^2 + 2yz + 2z^2; q on x = 0 is 2y^2 + 3yz + 2z^2.
example : (2 : ℤ) ^ 2 - 4 * 2 * 2 = -12 := by norm_num
example : (3 : ℤ) ^ 2 - 4 * 2 * 2 = -7 := by norm_num
-- q at (1 : 1 : 1), the point of L and M, is 6, so C misses it.
example : (1 : ℤ) ^ 2 + 2 * 1 ^ 2 + 2 * 1 ^ 2 - 1 * 1 - 1 * 1 + 3 * 1 * 1 = 6 := by norm_num

-- Self-intersections from h = C + L + M, and h . h = 4.
example : (2 : ℤ) - 2 - 2 = -2 ∧ (1 : ℤ) - 2 - 1 = -2 ∧ (2 : ℤ) + 1 + 1 = 4 := by norm_num

-- The intersection matrix of C, L, M, and the cycles C + L and 3C - 2L.
example :
    let G : Matrix (Fin 3) (Fin 3) ℤ := !![-2, 2, 2; 2, -2, 1; 2, 1, -2]
    let W : Fin 3 → ℤ := ![1, 1, 0]
    W ⬝ᵥ (G *ᵥ ![1, 1, 1]) = 3 ∧ W ⬝ᵥ (G *ᵥ W) = 0 ∧ W ⬝ᵥ (G *ᵥ ![0, 0, 1]) = 3 := by
  decide
example :
    let G : Matrix (Fin 3) (Fin 3) ℤ := !![-2, 2, 2; 2, -2, 1; 2, 1, -2]
    let W : Fin 3 → ℤ := ![3, -2, 0]
    W ⬝ᵥ (G *ᵥ ![1, 1, 1]) = 4 ∧ W ⬝ᵥ (G *ᵥ W) = -50 ∧ W ⬝ᵥ (G *ᵥ ![0, 0, 1]) = 4 := by
  decide
-- [h - M] squared: 4 - 2 * 1 - 2 = 0.
example : (4 : ℤ) - 2 * 1 + (-2) = 0 := by norm_num

-- Euler number 24 of a quartic surface, so H^2 has rank 22 and type (1, 1) dimension 20.
example : (4 : ℤ) ^ 3 - 4 * 4 ^ 2 + 6 * 4 = 24 ∧ (24 : ℤ) - 2 = 22 ∧ (24 : ℤ) - 4 = 20 := by norm_num

-- E × E: dz1 ∧ dz2 on the four curves gives 0, on the real torus spanned by (1, 0), (0, i) gives i.
example : (1 : ℂ) * 0 - 0 * I = 0 := by simp
example : (0 : ℂ) * I - 1 * 0 = 0 := by simp
example : (1 : ℂ) * I - 1 * I = 0 := by ring
example : (1 : ℂ) * (-1) - I * I = 0 := by ring_nf; simp
example : (1 : ℂ) * I - 0 * 0 = I := by simp

#print axioms two_zero_form_vanishes_on_complex_line
#print axioms quartic_plane_slice_factors
#print axioms dz1_wedge_dz2_on_torus_class
