-- Moving shapes with matrices: with a third coordinate of 1 on every point, turns, mirrors, scalings and shifts are 3 by 3 matrices that chain by multiplication (first move on the right), a turn about any pivot keeps the pivot and every distance, and signed area is multiplied by the determinant, which is 1 for a turn, -1 for the mirror and k × k for a scaling.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum

open Matrix Real

/-! A point (x, y) in homogeneous coordinates is the column `![x, y, 1]`; a direction (u, v) is
`![u, v, 0]`. `M *ᵥ c` is the matrix `M` times the column `c`. Angles are in radians, the axes
are at right angles with the same unit, and y counts upwards. The four moves of the card: -/

/-- `R θ`: turn by θ anticlockwise about the page corner (0, 0). -/
noncomputable def turnM (θ : ℝ) : Matrix (Fin 3) (Fin 3) ℝ :=
  !![cos θ, -sin θ, 0; sin θ, cos θ, 0; 0, 0, 1]

/-- `T(a, b)`: slide a across and b up. -/
def shiftM (a b : ℝ) : Matrix (Fin 3) (Fin 3) ℝ :=
  !![1, 0, a; 0, 1, b; 0, 0, 1]

/-- `F`: mirror in the up-axis. -/
def mirrorM : Matrix (Fin 3) (Fin 3) ℝ :=
  !![-1, 0, 0; 0, 1, 0; 0, 0, 1]

/-- `S(k)`: scale by k from the page corner. -/
def scaleM (k : ℝ) : Matrix (Fin 3) (Fin 3) ℝ :=
  !![k, 0, 0; 0, k, 0; 0, 0, 1]

/-- Signed area of the polygon with corners (x 0, y 0), (x 1, y 1), ..., taken in order and
closed up (the shoelace formula): positive when the corners run anticlockwise. -/
noncomputable def signedArea {n : ℕ} (x y : Fin n → ℝ) : ℝ :=
  (∑ i, (x i * y (finRotate n i) - x (finRotate n i) * y i)) / 2

/-- Every move is one multiplication. No 2 by 2 matrix can slide the plane by a nonzero (a, b),
because a matrix cannot move the origin. Put a 1 under every point and it works: T(a, b) adds
(a, b), R(θ) turns by θ about the page corner, F negates x, S(k) multiplies both coordinates by
k, and the 1 stays 1. A direction (0 underneath) ignores every shift. Any chain of moves, made
right to left, equals the single product of their matrices, and a product of matrices with
bottom row `0 0 1` still has bottom row `0 0 1`. -/
theorem homogeneous_moves_are_matrices_and_chains_multiply :
    (∀ a b : ℝ, ![a, b] ≠ 0 →
        ¬ ∃ M : Matrix (Fin 2) (Fin 2) ℝ, ∀ v : Fin 2 → ℝ, M *ᵥ v = v + ![a, b]) ∧
    (∀ a b x y : ℝ, shiftM a b *ᵥ ![x, y, 1] = ![x + a, y + b, 1]) ∧
    (∀ θ x y : ℝ, turnM θ *ᵥ ![x, y, 1] = ![x * cos θ - y * sin θ, x * sin θ + y * cos θ, 1]) ∧
    (∀ x y : ℝ, mirrorM *ᵥ ![x, y, 1] = ![-x, y, 1]) ∧
    (∀ k x y : ℝ, scaleM k *ᵥ ![x, y, 1] = ![k * x, k * y, 1]) ∧
    (∀ a b u v : ℝ, shiftM a b *ᵥ ![u, v, 0] = ![u, v, 0]) ∧
    (∀ (L : List (Matrix (Fin 3) (Fin 3) ℝ)) (c : Fin 3 → ℝ),
        L.prod *ᵥ c = L.foldr (fun M w => M *ᵥ w) c) ∧
    (∀ L : List (Matrix (Fin 3) (Fin 3) ℝ), (∀ M ∈ L, M 2 = ![0, 0, 1]) →
        L.prod 2 = ![0, 0, 1]) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rintro a b hab ⟨M, hM⟩
    have h := hM 0
    rw [Matrix.mulVec_zero, zero_add] at h
    exact hab h.symm
  · intro a b x y
    ext i; fin_cases i <;> simp [shiftM, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
  · intro θ x y
    ext i; fin_cases i <;> simp [turnM, Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> ring
  · intro x y
    ext i; fin_cases i <;> simp [mirrorM, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
  · intro k x y
    ext i; fin_cases i <;> simp [scaleM, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
  · intro a b u v
    ext i; fin_cases i <;> simp [shiftM, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
  · intro L c
    induction L with
    | nil => simp
    | cons M L ih => rw [List.prod_cons, List.foldr_cons, ← ih, Matrix.mulVec_mulVec]
  · intro L hL
    induction L with
    | nil =>
      ext j; fin_cases j <;> simp
    | cons M L ih =>
      have hM := hL M (by simp)
      have ih' := ih (fun N hN => hL N (by simp [hN]))
      rw [List.prod_cons]
      ext j
      have h0 : M 2 0 = 0 := by rw [hM]; simp
      have h1 : M 2 1 = 0 := by rw [hM]; simp
      have h2 : M 2 2 = 1 := by rw [hM]; simp
      rw [Matrix.mul_apply, Fin.sum_univ_three, h0, h1, h2, ih']
      simp

/-- Turning about a pivot. H = T(p, q) R(θ) T(-p, -q) (slide the pivot to the page corner, turn,
slide back) sends (x, y) to the pivot plus the turned offset, so the pivot (p, q) stays put, and
it keeps every distance: any two points are exactly as far apart after the move as before. -/
theorem turn_about_pivot_keeps_pivot_and_distances (p q θ : ℝ) :
    let H := shiftM p q * turnM θ * shiftM (-p) (-q)
    (∀ x y : ℝ, H *ᵥ ![x, y, 1] =
        ![p + (x - p) * cos θ - (y - q) * sin θ, q + (x - p) * sin θ + (y - q) * cos θ, 1]) ∧
    H *ᵥ ![p, q, 1] = ![p, q, 1] ∧
    (∀ x y x' y' : ℝ,
        ((H *ᵥ ![x, y, 1]) 0 - (H *ᵥ ![x', y', 1]) 0) ^ 2 +
          ((H *ᵥ ![x, y, 1]) 1 - (H *ᵥ ![x', y', 1]) 1) ^ 2 =
        (x - x') ^ 2 + (y - y') ^ 2) := by
  intro H
  have hH : ∀ x y : ℝ, H *ᵥ ![x, y, 1] =
      ![p + (x - p) * cos θ - (y - q) * sin θ, q + (x - p) * sin θ + (y - q) * cos θ, 1] := by
    intro x y
    ext i; fin_cases i <;>
      simp [H, shiftM, turnM, Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> ring
  refine ⟨hH, ?_, ?_⟩
  · rw [hH]; simp
  · intro x y x' y'
    rw [hH, hH]
    simp
    linear_combination ((x - x') ^ 2 + (y - y') ^ 2) * sin_sq_add_cos_sq θ

/-- Area follows the determinant. Any move whose matrix M has bottom row `0 0 1` multiplies the
signed area of every polygon by det M (the determinant of its top-left 2 by 2 block). For a turn
det = 1, so area is kept; for the mirror det = -1, so the signed area changes sign; for a
scaling by k det = k × k; a shift has det = 1. -/
theorem signed_area_scales_by_det_turn_keeps_mirror_flips_scale_squares :
    (∀ (M : Matrix (Fin 3) (Fin 3) ℝ), M 2 = ![0, 0, 1] →
      ∀ (n : ℕ) (x y : Fin n → ℝ),
        signedArea (fun i => (M *ᵥ ![x i, y i, 1]) 0) (fun i => (M *ᵥ ![x i, y i, 1]) 1) =
          M.det * signedArea x y) ∧
    (∀ θ : ℝ, (turnM θ).det = 1) ∧ mirrorM.det = -1 ∧
    (∀ k : ℝ, (scaleM k).det = k * k) ∧ (∀ a b : ℝ, (shiftM a b).det = 1) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro M hM n x y
    have h0 : M 2 0 = 0 := by rw [hM]; simp
    have h1 : M 2 1 = 0 := by rw [hM]; simp
    have h2 : M 2 2 = 1 := by rw [hM]; simp
    have hdet : M.det = M 0 0 * M 1 1 - M 0 1 * M 1 0 := by
      rw [Matrix.det_fin_three, h0, h1, h2]; ring
    have key : ∀ i, (M *ᵥ ![x i, y i, 1]) 0 * (M *ᵥ ![x (finRotate n i), y (finRotate n i), 1]) 1
        - (M *ᵥ ![x (finRotate n i), y (finRotate n i), 1]) 0 * (M *ᵥ ![x i, y i, 1]) 1
        = M.det * (x i * y (finRotate n i) - x (finRotate n i) * y i)
          + (M 0 0 * M 1 2 - M 0 2 * M 1 0) * (x i - x (finRotate n i))
          + (M 0 1 * M 1 2 - M 0 2 * M 1 1) * (y i - y (finRotate n i)) := by
      intro i
      rw [hdet]
      simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]
      ring
    unfold signedArea
    rw [Finset.sum_congr rfl (fun i _ => key i), Finset.sum_add_distrib, Finset.sum_add_distrib,
      ← Finset.mul_sum, ← Finset.mul_sum, ← Finset.mul_sum]
    simp only [Finset.sum_sub_distrib, Equiv.sum_comp (finRotate n) x,
      Equiv.sum_comp (finRotate n) y]
    ring
  · intro θ
    rw [Matrix.det_fin_three]; simp [turnM]; nlinarith [sin_sq_add_cos_sq θ]
  · rw [Matrix.det_fin_three]; simp [mirrorM]
  · intro k
    rw [Matrix.det_fin_three]; simp [scaleM]
  · intro a b
    rw [Matrix.det_fin_three]; simp [shiftM]

/-! The card's numbers. The logo has corners A (3, 1), B (7, 1), C (7, 3), D (3, 3).
cos 30° = √3/2 and sin 30° = 1/2 exactly, so the card's decimals 0.866025 and 1.732051 are
written here as √3/2 and √3. -/

-- The logo's signed area is 4 × 2 = 8.
example : signedArea ![(3 : ℝ), 7, 7, 3] ![1, 1, 3, 3] = 8 := by
  norm_num [signedArea, Fin.sum_univ_four, finRotate_apply]

-- Turning 30° about A: H's top rows are cos 30, -sin 30, 7/2 - 3√3/2 and sin 30, cos 30,
-- -1/2 - √3/2 (the card's 0.901924 and -1.366025).
example : shiftM 3 1 * turnM (π / 6) * shiftM (-3) (-1) =
    !![√3 / 2, -1 / 2, 7 / 2 - 3 * √3 / 2; 1 / 2, √3 / 2, -1 / 2 - √3 / 2; 0, 0, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [shiftM, turnM, Matrix.mul_apply, Fin.sum_univ_three, cos_pi_div_six,
      sin_pi_div_six] <;> ring

-- A stays at (3, 1); B goes to (3 + 2√3, 3); C to (2 + 2√3, 3 + √3); D to (2, 1 + √3).
example : (shiftM 3 1 * turnM (π / 6) * shiftM (-3) (-1)) *ᵥ ![3, 1, 1] = ![3, 1, 1] := by
  ext i; fin_cases i <;>
    simp [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six] <;> ring
example : (shiftM 3 1 * turnM (π / 6) * shiftM (-3) (-1)) *ᵥ ![7, 1, 1] =
    ![3 + 2 * √3, 3, 1] := by
  ext i; fin_cases i <;>
    simp [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six] <;> ring
example : (shiftM 3 1 * turnM (π / 6) * shiftM (-3) (-1)) *ᵥ ![7, 3, 1] =
    ![2 + 2 * √3, 3 + √3, 1] := by
  ext i; fin_cases i <;>
    simp [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six] <;> ring
example : (shiftM 3 1 * turnM (π / 6) * shiftM (-3) (-1)) *ᵥ ![3, 3, 1] =
    ![2, 1 + √3, 1] := by
  ext i; fin_cases i <;>
    simp [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six] <;> ring

-- The up arrow (0, 1, 0) turns to (-1/2, √3/2, 0) and is never shifted.
example : (shiftM 3 1 * turnM (π / 6) * shiftM (-3) (-1)) *ᵥ ![0, 1, 0] =
    ![-1 / 2, √3 / 2, 0] := by
  ext i; fin_cases i <;>
    norm_num [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six]

-- Scale 3/2 about A: C goes to (9, 4), and the scaled logo's area is 18.
example : (shiftM 3 1 * scaleM (3 / 2) * shiftM (-3) (-1)) *ᵥ ![7, 3, 1] = ![9, 4, 1] := by
  ext i; fin_cases i <;>
    norm_num [shiftM, scaleM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
example : signedArea ![(3 : ℝ), 9, 9, 3] ![1, 1, 4, 4] = 18 := by
  norm_num [signedArea, Fin.sum_univ_four, finRotate_apply]

-- Mirror in the line x = 3: B goes to (-1, 1), and the mirrored logo's signed area is -8.
example : (shiftM 3 1 * mirrorM * shiftM (-3) (-1)) *ᵥ ![7, 1, 1] = ![-1, 1, 1] := by
  ext i; fin_cases i <;>
    norm_num [shiftM, mirrorM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
example : signedArea ![(3 : ℝ), -1, -1, 3] ![1, 1, 3, 3] = -8 := by
  norm_num [signedArea, Fin.sum_univ_four, finRotate_apply]

-- The mistakes. R alone moves A to (3√3/2 - 1/2, 3/2 + √3/2); the slides in the wrong order
-- move A to (3√3 - 4, 2 + √3); the sine signs swapped send B to (3 + 2√3, -1).
example : turnM (π / 6) *ᵥ ![3, 1, 1] = ![3 * √3 / 2 - 1 / 2, 3 / 2 + √3 / 2, 1] := by
  ext i; fin_cases i <;>
    simp [turnM, Matrix.mulVec, dotProduct, Fin.sum_univ_three, cos_pi_div_six,
      sin_pi_div_six] <;> ring
example : (shiftM (-3) (-1) * turnM (π / 6) * shiftM 3 1) *ᵥ ![3, 1, 1] =
    ![3 * √3 - 4, 2 + √3, 1] := by
  ext i; fin_cases i <;>
    simp [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six] <;> ring
example : (shiftM 3 1 * turnM (-(π / 6)) * shiftM (-3) (-1)) *ᵥ ![7, 1, 1] =
    ![3 + 2 * √3, -1, 1] := by
  ext i; fin_cases i <;>
    simp [shiftM, turnM, Matrix.mul_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_three,
      cos_pi_div_six, sin_pi_div_six] <;> ring

#print axioms homogeneous_moves_are_matrices_and_chains_multiply
#print axioms turn_about_pivot_keeps_pivot_and_distances
#print axioms signed_area_scales_by_det_turn_keeps_mirror_flips_scale_squares
