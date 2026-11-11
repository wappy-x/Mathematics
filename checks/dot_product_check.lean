-- The dot product: for lists of real numbers of any length, the square root of a list dotted with itself is its straight-line length, two arrows that go somewhere meet at a right angle exactly when their dot product is 0, the alignment score always lies between -1 and 1 and reaches 1 or -1 exactly for arrows on one line, and the card's shop and map numbers come out as it says.
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Data.Fin.VecNotation

/-! A list of `n` real numbers is a function `u : Fin n → ℝ`, and `![3, 4]` is the list
(3, 4). Mathlib's `u ⬝ᵥ v` (`dotProduct`) multiplies matching entries and adds them, and the
card's length `|u|` is `√(u ⬝ᵥ u)`. "Square axes and one unit of length" is Mathlib's
`EuclideanSpace ℝ (Fin n)`: `WithLp.toLp 2 u` is the same list read as an arrow on square
axes, `‖·‖` is its straight-line length and `InnerProductGeometry.angle` is the angle
between two arrows. "An arrow that goes somewhere" is a list that is not all zeros,
`u ≠ 0`. -/

open InnerProductGeometry

theorem dp_inner_toLp {n : ℕ} (u v : Fin n → ℝ) :
    inner ℝ (WithLp.toLp 2 u) (WithLp.toLp 2 v) = u ⬝ᵥ v := by
  rw [EuclideanSpace.inner_toLp_toLp, star_trivial, dotProduct_comm]

theorem dp_norm_toLp {n : ℕ} (u : Fin n → ℝ) :
    ‖WithLp.toLp 2 u‖ = √(u ⬝ᵥ u) := by
  rw [← dp_inner_toLp u u, real_inner_self_eq_norm_sq, Real.sqrt_sq (norm_nonneg _)]

#print axioms dp_inner_toLp
#print axioms dp_norm_toLp

/-- The −1 to 1 bound (Cauchy–Schwarz). For any two lists `u` and `v` of real numbers of the
same length, neither all zeros, the alignment score `(u · v) / (|u| |v|)`, with
`|u| = √(u · u)`, is never below −1 and never above 1. It equals 1 or −1 exactly when `u` is
some number of copies of `v`, that is, when the two arrows lie on one line. -/
theorem alignment_score_between_minus_one_and_one {n : ℕ} (u v : Fin n → ℝ)
    (hu : u ≠ 0) (hv : v ≠ 0) :
    -1 ≤ (u ⬝ᵥ v) / (√(u ⬝ᵥ u) * √(v ⬝ᵥ v)) ∧
    (u ⬝ᵥ v) / (√(u ⬝ᵥ u) * √(v ⬝ᵥ v)) ≤ 1 ∧
    ((u ⬝ᵥ v) / (√(u ⬝ᵥ u) * √(v ⬝ᵥ v)) = 1 ∨
        (u ⬝ᵥ v) / (√(u ⬝ᵥ u) * √(v ⬝ᵥ v)) = -1 ↔
      ∃ r : ℝ, u = r • v) := by
  have key := abs_real_inner_div_norm_mul_norm_eq_one_iff (WithLp.toLp 2 v) (WithLp.toLp 2 u)
  have hle := abs_real_inner_div_norm_mul_norm_le_one (WithLp.toLp 2 v) (WithLp.toLp 2 u)
  rw [real_inner_comm, dp_inner_toLp, dp_norm_toLp, dp_norm_toLp, mul_comm (√(v ⬝ᵥ v))] at key hle
  refine ⟨(abs_le.mp hle).1, (abs_le.mp hle).2, ?_⟩
  rw [← abs_eq (zero_le_one' ℝ), key]
  constructor
  · rintro ⟨-, r, -, h⟩
    exact ⟨r, (WithLp.toLp_injective 2) (by simpa using h)⟩
  · rintro ⟨r, rfl⟩
    refine ⟨(WithLp.toLp_injective 2).ne (by simpa using hv), r, ?_, by simp⟩
    rintro rfl
    exact hu (zero_smul ℝ v)

/-- The length rule. On square axes with one unit of length, the straight-line length of
the arrow with entries `u` is the square root of `u` dotted with itself. -/
theorem length_is_sqrt_of_dot_with_itself {n : ℕ} (u : Fin n → ℝ) :
    ‖WithLp.toLp 2 u‖ = √(u ⬝ᵥ u) := by
  exact dp_norm_toLp u

/-- The right-angle test. For two lists `u` and `v` of real numbers of the same length,
neither all zeros, read as arrows on square axes, the arrows meet at a right angle exactly
when `u · v = 0`. -/
theorem right_angle_iff_dot_product_zero {n : ℕ} (u v : Fin n → ℝ)
    (hu : u ≠ 0) (hv : v ≠ 0) :
    angle (WithLp.toLp 2 u) (WithLp.toLp 2 v) = Real.pi / 2 ↔ u ⬝ᵥ v = 0 := by
  rw [← inner_eq_zero_iff_angle_eq_pi_div_two, dp_inner_toLp]

-- The weekly shop: 2 × 3 + 3 × 2 + 1 × 4 = 6 + 6 + 4 = 16 dollars.
example : (![2, 3, 1] : Fin 3 → ℤ) ⬝ᵥ ![3, 2, 4] = 16 := by decide
-- The second road: (5, 5, 5) squared is 75, take away 14 and 29, halve: 16 again.
example : ((![2 + 3, 3 + 2, 1 + 4] : Fin 3 → ℤ) ⬝ᵥ ![5, 5, 5]
    - (![2, 3, 1] : Fin 3 → ℤ) ⬝ᵥ ![2, 3, 1] - (![3, 2, 4] : Fin 3 → ℤ) ⬝ᵥ ![3, 2, 4]) = 2 * 16 := by
  decide
-- The cyclist's leg: (3, 4) · (3, 4) = 9 + 16 = 25, and its length is √25 = 5.
example : (![3, 4] : Fin 2 → ℤ) ⬝ᵥ ![3, 4] = 25 := by decide
example : √(25 : ℝ) = 5 := by norm_num
-- The right angle: (3, 4) · (4, −3) = 12 − 12 = 0.
example : (![3, 4] : Fin 2 → ℤ) ⬝ᵥ ![4, -3] = 0 := by decide
-- Pythagoras on the tips: the gap (−1, 7) has squared length 50 = 25 + 25.
example : (![3 - 4, 4 - (-3)] : Fin 2 → ℤ) = ![-1, 7] ∧
    (![-1, 7] : Fin 2 → ℤ) ⬝ᵥ ![-1, 7] = 25 + 25 ∧
    (![4, -3] : Fin 2 → ℤ) ⬝ᵥ ![4, -3] = 25 := by decide
-- Same way, twice as long: (3, 4) · (6, 8) = 18 + 32 = 50, (6, 8) is √100 = 10 long,
-- and the alignment score is 50 / (5 × 10) = 1.
example : (![3, 4] : Fin 2 → ℤ) ⬝ᵥ ![6, 8] = 50 ∧
    (![6, 8] : Fin 2 → ℤ) ⬝ᵥ ![6, 8] = 100 := by decide
example : √(100 : ℝ) = 10 ∧ (50 : ℝ) / (5 * 10) = 1 := by norm_num
-- The four mistakes: adding gives 15, totals times totals 54, back to front 17, and 25 is
-- the leg's length squared, not its length 5.
example : (2 + 3) + (3 + 2) + (1 + 4) = 15 ∧ (2 + 3 + 1) * (3 + 2 + 4) = 54 ∧
    (![2, 3, 1] : Fin 3 → ℤ) ⬝ᵥ ![4, 2, 3] = 17 ∧ (25 : ℤ) ≠ 5 := by decide
-- The twelve directions, each 5 long: the dot product with (3, 4) runs 15, 24, 25, 20, 7,
-- 0, −15, −24, −25, −20, −7, 0 (score times 25), and every one obeys
-- (u · v)² ≤ (u · u)(v · v).
example : [(![5, 0] : Fin 2 → ℤ), ![4, 3], ![3, 4], ![0, 5], ![-3, 4], ![-4, 3],
      ![-5, 0], ![-4, -3], ![-3, -4], ![0, -5], ![3, -4], ![4, -3]].map
      (fun d => (![3, 4] : Fin 2 → ℤ) ⬝ᵥ d) =
    [15, 24, 25, 20, 7, 0, -15, -24, -25, -20, -7, 0] := by decide
example : ∀ d ∈ [(![5, 0] : Fin 2 → ℤ), ![4, 3], ![3, 4], ![0, 5], ![-3, 4], ![-4, 3],
      ![-5, 0], ![-4, -3], ![-3, -4], ![0, -5], ![3, -4], ![4, -3]],
    d ⬝ᵥ d = 25 ∧
    ((![3, 4] : Fin 2 → ℤ) ⬝ᵥ d) ^ 2 ≤ ((![3, 4] : Fin 2 → ℤ) ⬝ᵥ ![3, 4]) * (d ⬝ᵥ d) := by
  decide

#print axioms alignment_score_between_minus_one_and_one
#print axioms length_is_sqrt_of_dot_with_itself
#print axioms right_angle_iff_dot_product_zero
