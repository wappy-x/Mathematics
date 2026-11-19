-- The resultant: two polynomials over ℚ whose top coefficients are not both zero share a complex root exactly when the determinant of their Sylvester matrix is zero, and that determinant always lies in the ideal they generate, so it eliminates a variable.
import Mathlib.RingTheory.Polynomial.Resultant.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! The field is ℚ and roots are sought in ℂ. A polynomial f in the letter t is `f : ℚ[X]`.
The card writes f = a_m t^m + … + a_0 and g = b_n t^n + … + b_0 with stated sizes m and n, so
`f.natDegree ≤ m`, `g.natDegree ≤ n`, and the top coefficients are `f.coeff m` and `g.coeff n`.
Res_t(f, g) is Mathlib's `resultant f g m n`, the determinant of the (m + n) × (m + n)
Sylvester matrix `sylvester f g m n`. (Mathlib lays the shifted coefficient lists out as columns,
lowest power first; reversing both orders and transposing gives the card's grid, with the same
determinant, as the product formula `a_m^n ∏ g(α)` confirms.) `aeval z f` is f's value at a complex
number z. The ideal ⟨f, g⟩ is `Ideal.span {f, g}`, and a constant r sits in it as `C r`. -/

open Polynomial

namespace ResultantsCard

/-- Helper: when f's top coefficient at size m is nonzero, padding g's size does not change
whether the resultant vanishes. -/
theorem resultant_eq_zero_iff_default_of_coeff_left {K : Type*} [Field K]
    (f g : K[X]) (m n : ℕ) (hf : f.natDegree ≤ m) (hg : g.natDegree ≤ n)
    (h : f.coeff m ≠ 0) : resultant f g m n = 0 ↔ resultant f g = 0 := by
  have hm : f.natDegree = m := le_antisymm hf (le_natDegree_of_ne_zero h)
  subst hm
  have hf0 : f ≠ 0 := by rintro rfl; simp at h
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hg
  rw [resultant_add_right_deg f g f.natDegree g.natDegree k le_rfl]
  simp [hf0]

/-- Helper: with one top coefficient nonzero, the resultant at sizes m, n vanishes exactly when
the resultant at the true degrees does. -/
theorem resultant_eq_zero_iff_default {K : Type*} [Field K]
    (f g : K[X]) (m n : ℕ) (hf : f.natDegree ≤ m) (hg : g.natDegree ≤ n)
    (htop : f.coeff m ≠ 0 ∨ g.coeff n ≠ 0) : resultant f g m n = 0 ↔ resultant f g = 0 := by
  rcases htop with h | h
  · exact resultant_eq_zero_iff_default_of_coeff_left f g m n hf hg h
  · rw [resultant_comm f g m n, resultant_comm f g f.natDegree g.natDegree]
    have := resultant_eq_zero_iff_default_of_coeff_left g f n m hg hf h
    simp [this]

/-- The card's main claim. Let f and g be polynomials over ℚ written with sizes m and n, whose
top coefficients a_m and b_n are not both zero. Then their resultant, the determinant of the
Sylvester matrix, is zero exactly when f and g share a root in ℂ, and exactly when gcd(f, g)
has degree at least 1. -/
theorem resultant_eq_zero_iff_common_complex_root
    (f g : ℚ[X]) (m n : ℕ) (hf : f.natDegree ≤ m) (hg : g.natDegree ≤ n)
    (htop : f.coeff m ≠ 0 ∨ g.coeff n ≠ 0) :
    (resultant f g m n = 0 ↔ ∃ z : ℂ, aeval z f = 0 ∧ aeval z g = 0) ∧
    (resultant f g m n = 0 ↔ 1 ≤ (gcd f g).natDegree) := by
  have hne : f ≠ 0 ∨ g ≠ 0 := by
    rcases htop with h | h
    · left; rintro rfl; simp at h
    · right; rintro rfl; simp at h
  have h1 : resultant f g m n = 0 ↔ ¬ IsCoprime f g := by
    rw [resultant_eq_zero_iff_default f g m n hf hg htop, resultant_eq_zero_iff]
    simp [hne]
  have hgcd : gcd f g ≠ 0 := by
    intro h
    rw [gcd_eq_zero_iff] at h
    tauto
  refine ⟨?_, ?_⟩
  · rw [h1, isCoprime_iff_aeval_ne_zero_of_isAlgClosed ℚ ℂ f g]
    push Not
    rfl
  · rw [h1, ← gcd_isUnit_iff, isUnit_iff_degree_eq_zero, degree_eq_natDegree hgcd]
    norm_cast
    omega

/-- Step 4 of the card: the resultant lies in the ideal ⟨f, g⟩. Whatever the coefficients are
(fractions, or polynomials in another letter such as the gauge height c), there are polynomials
U and V with U f + V g = Res_t(f, g), so the resultant is free of t and vanishes at every common
solution: it eliminates t. The Sylvester matrix must have at least one row, m + n ≥ 1. -/
theorem resultant_mem_ideal_span {R : Type*} [CommRing R]
    (f g : R[X]) (m n : ℕ) (hf : f.natDegree ≤ m) (hg : g.natDegree ≤ n) (hmn : 1 ≤ m + n) :
    C (resultant f g m n) ∈ Ideal.span ({f, g} : Set R[X]) := by
  obtain ⟨p, q, -, -, e⟩ := exists_mul_add_mul_eq_C_resultant f g hf hg (by omega)
  rw [← e, Ideal.mem_span_pair]
  exact ⟨p, q, by ring⟩

/-- The product formula: the resultant equals f's top coefficient to the power n = deg g, times
the product of g's values at the complex roots of f, each root counted as often as it repeats. -/
theorem resultant_eq_leadingCoeff_pow_mul_prod_eval_roots (f g : ℚ[X]) :
    ((resultant f g : ℚ) : ℂ) =
      (f.leadingCoeff : ℂ) ^ g.natDegree *
        ((f.map (algebraMap ℚ ℂ)).roots.map (fun α => aeval α g)).prod := by
  have hs : (f.map (algebraMap ℚ ℂ)).Splits := IsAlgClosed.splits _
  have := resultant_eq_prod_eval (f.map (algebraMap ℚ ℂ)) (g.map (algebraMap ℚ ℂ)) g.natDegree
    (by rw [natDegree_map]) hs
  rw [resultant_map_map, natDegree_map, leadingCoeff_map] at this
  simp only [eq_ratCast] at this
  rw [this]
  congr 2
  refine Multiset.map_congr rfl fun α _ => ?_
  simp [eval_map_algebraMap]

/-! Worked numbers from the card, checked exactly. -/

/-- The gears: f = 4t² − 1 and g = 8t² − 20t + 8; the card's Sylvester grid has determinant 0. -/
example : Matrix.det !![(4 : ℚ), 0, -1, 0; 0, 4, 0, -1; 8, -20, 8, 0; 0, 8, -20, 8] = 0 := by
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]
  ring

/-- The shared root t = 1/2: f(1/2) = 0 and g(1/2) = 0, while g(−1/2) = 20. -/
example : (4 * (1/2 : ℚ) ^ 2 - 1 = 0) ∧ (8 * (1/2 : ℚ) ^ 2 - 20 * (1/2) + 8 = 0) ∧
    (8 * (-1/2 : ℚ) ^ 2 - 20 * (-1/2) + 8 = 20) := by
  norm_num

/-- The product formula for the gears: 4² × g(1/2) × g(−1/2) = 16 × 0 × 20 = 0. -/
example : (4 : ℚ) ^ 2 * 0 * 20 = 0 := by
  norm_num

/-- The cancelling pair: A = 4t − 8 and B = −2t − 1 give A f + B g = 0. -/
example : ((4 * X - 8) * (4 * X ^ 2 - 1) + (-2 * X - 1) * (8 * X ^ 2 - 20 * X + 8) : ℚ[X]) = 0 := by
  ring

/-- The tips at t = 1/2: cos θ = 3/5 and sin θ = 4/5, so tip A is at (3, 4) and tip B at (6, 8). -/
example : (1 - (1/2 : ℚ) ^ 2) / (1 + (1/2) ^ 2) = 3/5 ∧ 2 * (1/2 : ℚ) / (1 + (1/2) ^ 2) = 4/5 ∧
    5 * (3/5 : ℚ) = 3 ∧ 5 * (4/5 : ℚ) = 4 ∧ 10 * (3/5 : ℚ) = 6 ∧ 10 * (4/5 : ℚ) = 8 := by
  norm_num

/-- Gauge B at 9 cm: g = 9t² − 20t + 9 and the determinant is 425 = 16 × 5/4 × 85/4. -/
example : Matrix.det !![(4 : ℚ), 0, -1, 0; 0, 4, 0, -1; 9, -20, 9, 0; 0, 9, -20, 9] = 425 ∧
    (16 : ℚ) * (5/4) * (85/4) = 425 := by
  refine ⟨?_, by norm_num⟩
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]
  ring

/-- Eliminating t: with gauge height c, Res_t(4t² − 1, ct² − 20t + c) = 25c² − 1600
= 25(c − 8)(c + 8), which is also 2500((3/5)² + (c/10)² − 1). -/
example (c : ℚ) :
    Matrix.det !![(4 : ℚ), 0, -1, 0; 0, 4, 0, -1; c, -20, c, 0; 0, c, -20, c] = 25 * c ^ 2 - 1600 ∧
    25 * c ^ 2 - 1600 = 25 * (c - 8) * (c + 8) ∧
    2500 * ((3/5) ^ 2 + (c/10) ^ 2 - 1) = 25 * c ^ 2 - 1600 := by
  refine ⟨?_, by ring, by ring⟩
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]
  ring

/-- The robot arm, target (4, 0) m: eliminating v from v² + u² − 9 and v² + (u − 4)² − 4 gives
64u² − 336u + 441 = (8u − 21)², so u = 21/8 m and v² = 135/64. -/
example (u : ℚ) :
    Matrix.det !![(1 : ℚ), 0, u ^ 2 - 9, 0; 0, 1, 0, u ^ 2 - 9;
      1, 0, (u - 4) ^ 2 - 4, 0; 0, 1, 0, (u - 4) ^ 2 - 4] = 64 * u ^ 2 - 336 * u + 441 ∧
    64 * u ^ 2 - 336 * u + 441 = (8 * u - 21) ^ 2 ∧
    9 - (21/8 : ℚ) ^ 2 = 135/64 := by
  refine ⟨?_, by ring, by norm_num⟩
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]
  ring

/-- Target (6, 0) m: the eliminant 144u² − 984u + 1681 vanishes at u = 41/12, where
v² = 9 − u² = −385/144 < 0, so there is no real elbow. -/
example : 144 * (41/12 : ℚ) ^ 2 - 984 * (41/12) + 1681 = 0 ∧ 9 - (41/12 : ℚ) ^ 2 = -385/144 := by
  norm_num

/-- What breaks: ct − 1 and ct − 2 have resultant −c, zero at c = 0 where both top
coefficients vanish and the pair reads −1 and −2. -/
example (c : ℚ) : Matrix.det !![c, -1; c, -2] = -c := by
  simp [Matrix.det_fin_two]
  ring

/-- Gauges at x = 6 cm and x = 12 cm: f = 11t² + 1 and g = 22t² + 2 = 2f, determinant 0. -/
example : Matrix.det !![(11 : ℚ), 0, 1, 0; 0, 11, 0, 1; 22, 0, 2, 0; 0, 22, 0, 2] = 0 := by
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]
  ring

end ResultantsCard

open ResultantsCard

#print axioms resultant_eq_zero_iff_common_complex_root
#print axioms resultant_mem_ideal_span
#print axioms resultant_eq_leadingCoeff_pow_mul_prod_eval_roots
#print axioms resultant_eq_zero_iff_default_of_coeff_left
#print axioms resultant_eq_zero_iff_default
