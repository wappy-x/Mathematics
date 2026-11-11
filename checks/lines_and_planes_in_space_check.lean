-- Lines and planes: a line whose direction is not level with a plane meets it at exactly one time t = (c - n·p) / (n·d), the foot of the perpendicular along the normal is the one closest point of the plane at distance |n·p - c| / |n|, two edges with a non-zero cross product span exactly the points that pass the plane's test, and the card's drone and panel numbers come out as it says.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Tactic.FinCases
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.LinearCombination

/-! A point or an arrow in space is a list of three real numbers, `p : Fin 3 → ℝ`, and
`![2, 3, 5]` is the point (2, 3, 5). Mathlib's `a ⬝ᵥ b` (`dotProduct`) is the dot product,
`a ⨯₃ b` (`crossProduct`) is the cross product, and the card's length `|a|` is `√(a ⬝ᵥ a)`
("square axes in one unit"). The line is every point `p + t • d` for a real number `t`
(negative `t` allowed: "a two-way line"), and the plane is every point `X` with `n ⬝ᵥ X = c`
("an endless sheet"). "Not all zeros" is `≠ 0`, and "the line is not level with the plane"
is `n ⬝ᵥ d ≠ 0`. -/

open Matrix

theorem dot_self_nonneg3 (v : Fin 3 → ℝ) : 0 ≤ v ⬝ᵥ v := by
  simp only [dotProduct, Fin.sum_univ_three]
  nlinarith [mul_self_nonneg (v 0), mul_self_nonneg (v 1), mul_self_nonneg (v 2)]

theorem dot_self_pos3 (v : Fin 3 → ℝ) (hv : v ≠ 0) : 0 < v ⬝ᵥ v := by
  rcases (dot_self_nonneg3 v).lt_or_eq with h | h
  · exact h
  · exfalso; apply hv
    simp only [dotProduct, Fin.sum_univ_three] at h
    have h0 : v 0 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1), sq_nonneg (v 2)]
    have h1 : v 1 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1), sq_nonneg (v 2)]
    have h2 : v 2 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1), sq_nonneg (v 2)]
    ext i; fin_cases i <;> simp [h0, h1, h2]

theorem cramer_cross (u v w : Fin 3 → ℝ) (i : Fin 3) :
    ((u ⨯₃ v) ⬝ᵥ (u ⨯₃ v)) * w i =
      ((w ⨯₃ v) ⬝ᵥ (u ⨯₃ v)) * u i + ((u ⨯₃ w) ⬝ᵥ (u ⨯₃ v)) * v i
        + ((u ⨯₃ v) ⬝ᵥ w) * (u ⨯₃ v) i := by
  fin_cases i <;> simp [cross_apply, dotProduct, Fin.sum_univ_three] <;> ring

/-- One meeting point. A line through `p` with direction `d` and a plane `n · X = c`, with
`d` and `n` not all zeros and the line not level with the plane (`n · d ≠ 0`), meet at
exactly one point: the line point `p + t d` passes the plane's test exactly when
`t = (c - n · p) / (n · d)`, the gap to close over the gap closed per step. -/
theorem line_meets_plane_at_one_time (p d n : Fin 3 → ℝ) (c : ℝ)
    (hd : d ≠ 0) (hn : n ≠ 0) (hlevel : n ⬝ᵥ d ≠ 0) (t : ℝ) :
    n ⬝ᵥ (p + t • d) = c ↔ t = (c - n ⬝ᵥ p) / (n ⬝ᵥ d) := by
  rw [dotProduct_add, dotProduct_smul, smul_eq_mul, eq_div_iff hlevel]
  constructor <;> intro h <;> linarith

/-- The shortest way to a plane runs along the normal. For a plane `n · X = c` with `n` not
all zeros and any point `p`, the foot `F = p - ((n · p - c) / (n · n)) n` lies on the plane,
its distance from `p` is `D = |n · p - c| / |n|`, and every other point of the plane is
further from `p` than `D`. -/
theorem foot_of_perpendicular_is_closest (n p : Fin 3 → ℝ) (c : ℝ) (hn : n ≠ 0)
    (F : Fin 3 → ℝ) (hF : F = p - ((n ⬝ᵥ p - c) / (n ⬝ᵥ n)) • n) :
    n ⬝ᵥ F = c ∧
    √((p - F) ⬝ᵥ (p - F)) = |n ⬝ᵥ p - c| / √(n ⬝ᵥ n) ∧
    ∀ Y : Fin 3 → ℝ, n ⬝ᵥ Y = c → Y ≠ F →
      |n ⬝ᵥ p - c| / √(n ⬝ᵥ n) < √((p - Y) ⬝ᵥ (p - Y)) := by
  have hpos := dot_self_pos3 n hn
  set k := (n ⬝ᵥ p - c) / (n ⬝ᵥ n) with hk
  have hpF : p - F = k • n := by rw [hF]; abel
  have hFc : n ⬝ᵥ F = c := by
    rw [hF, dotProduct_sub, dotProduct_smul, smul_eq_mul, hk]
    field_simp; ring
  have hdist : √((p - F) ⬝ᵥ (p - F)) = |n ⬝ᵥ p - c| / √(n ⬝ᵥ n) := by
    rw [hpF, dotProduct_smul, smul_dotProduct, smul_eq_mul, smul_eq_mul, ← mul_assoc,
      Real.sqrt_mul (mul_self_nonneg k), Real.sqrt_mul_self_eq_abs, hk, abs_div,
      abs_of_pos hpos]
    have hs : 0 < √(n ⬝ᵥ n) := Real.sqrt_pos.mpr hpos
    have hss : √(n ⬝ᵥ n) * √(n ⬝ᵥ n) = n ⬝ᵥ n := Real.mul_self_sqrt hpos.le
    field_simp
    rw [Real.sq_sqrt hpos.le]
  refine ⟨hFc, hdist, ?_⟩
  intro Y hY hYF
  have hsplit : p - Y = (p - F) + (F - Y) := by abel
  have horth : (p - F) ⬝ᵥ (F - Y) = 0 := by
    rw [hpF, smul_dotProduct, dotProduct_sub, hFc, hY, sub_self, smul_zero]
  have hFY : 0 < (F - Y) ⬝ᵥ (F - Y) := dot_self_pos3 _ (sub_ne_zero.mpr (Ne.symm hYF))
  have heq : (p - Y) ⬝ᵥ (p - Y) = (p - F) ⬝ᵥ (p - F) + (F - Y) ⬝ᵥ (F - Y) := by
    rw [hsplit, add_dotProduct, dotProduct_add, dotProduct_add, dotProduct_comm (F - Y) (p - F),
      horth]; ring
  rw [← hdist]
  apply Real.sqrt_lt_sqrt (dot_self_nonneg3 _)
  rw [heq]; linarith

/-- The plane is exactly the points that pass the test. For a corner `A` and two edges `u`
and `v` whose cross product `n = u × v` is not all zeros, the points `A + s u + r v` reached
from the corner along the edges are exactly the points `X` with `n · X = c`, where
`c = n · A`. -/
theorem plane_from_edges_is_normal_test (A u v : Fin 3 → ℝ) (hn : u ⨯₃ v ≠ 0) :
    {X : Fin 3 → ℝ | ∃ s r : ℝ, X = A + s • u + r • v} =
      {X : Fin 3 → ℝ | (u ⨯₃ v) ⬝ᵥ X = (u ⨯₃ v) ⬝ᵥ A} := by
  ext X
  simp only [Set.mem_ofPred_eq]
  constructor
  · rintro ⟨s, r, rfl⟩
    rw [dotProduct_add, dotProduct_add, dotProduct_smul, dotProduct_smul,
      dotProduct_comm (u ⨯₃ v) u, dotProduct_comm (u ⨯₃ v) v, dot_self_cross, dot_cross_self]
    simp
  · intro h
    have hpos := dot_self_pos3 _ hn
    set w := X - A with hw
    have hw0 : (u ⨯₃ v) ⬝ᵥ w = 0 := by rw [hw, dotProduct_sub, h, sub_self]
    refine ⟨((w ⨯₃ v) ⬝ᵥ (u ⨯₃ v)) / ((u ⨯₃ v) ⬝ᵥ (u ⨯₃ v)),
      ((u ⨯₃ w) ⬝ᵥ (u ⨯₃ v)) / ((u ⨯₃ v) ⬝ᵥ (u ⨯₃ v)), ?_⟩
    ext i
    have hc := cramer_cross u v w i
    rw [hw0, zero_mul, add_zero] at hc
    have hwi : w i = X i - A i := by rw [hw]; rfl
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    rw [hwi] at hc
    field_simp
    linear_combination hc

-- The normal from the edges: (10, 0, 0) × (0, 4.8, 3.6) = (0, −36, 48), with
-- 4.8 = 24/5 and 3.6 = 18/5, and its length is √3600 = 60.
example : (![10, 0, 0] : Fin 3 → ℚ) ⨯₃ ![0, 24 / 5, 18 / 5] = ![0, -36, 48] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![0, -36, 48] = 3600 := by decide
example : √(3600 : ℝ) = 60 := by norm_num
-- The plane's level: c = n · A = 0 for the corner (0, 0, 0).
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![0, 0, 0] = 0 := by decide
-- The drone's gap: −36 × 3 + 48 × 5 − 0 = 132; the gap per step: −36 × 1 + 48 × (−2) = −132.
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![2, 3, 5] = 132 := by decide
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![2, 1, -2] = -132 := by decide
-- Touchdown: t = (0 − 132) / (−132) = 1, and (2, 3, 5) + 1 (2, 1, −2) = (4, 4, 3),
-- which passes the plane's test.
example : ((0 : ℚ) - 132) / (-132) = 1 := by norm_num
example : (![2, 3, 5] : Fin 3 → ℤ) + (1 : ℤ) • ![2, 1, -2] = ![4, 4, 3] := by decide
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![4, 4, 3] = 0 := by decide
-- On the panel: (4, 4, 3) is 40 / 10 = 4 m along the 10 m edge and
-- 30 / 6 = 5 m up the 6 m edge (0, 24/5, 18/5), whose length is √36 = 6.
example : (![4, 4, 3] : Fin 3 → ℚ) ⬝ᵥ ![10, 0, 0] / 10 = 4 ∧
    (![4, 4, 3] : Fin 3 → ℚ) ⬝ᵥ ![0, 24 / 5, 18 / 5] / 6 = 5 ∧
    (![0, 24 / 5, 18 / 5] : Fin 3 → ℚ) ⬝ᵥ ![0, 24 / 5, 18 / 5] = 36 := by
  simp [dotProduct, Fin.sum_univ_three]; norm_num
-- Flight to the hit: the dive (2, 1, −2) is √9 = 3 m long, so t = 1 is 3 m of flight.
example : (![2, 1, -2] : Fin 3 → ℤ) ⬝ᵥ ![2, 1, -2] = 9 := by decide
example : √(9 : ℝ) = 3 := by norm_num
-- Drone to plane: D = 132 / 60 = 2.2 m = 11/5 m. With the normal (0, −3, 4), the gap is 11
-- and the length √25 = 5, so D = 11 / 5 again.
example : (132 : ℚ) / 60 = 11 / 5 := by norm_num
example : (![0, -3, 4] : Fin 3 → ℤ) ⬝ᵥ ![2, 3, 5] = 11 ∧
    (![0, -3, 4] : Fin 3 → ℤ) ⬝ᵥ ![0, -3, 4] = 25 := by decide
example : √(25 : ℝ) = 5 := by norm_num
-- The foot: (2, 3, 5) − (132 / 3600) (0, −36, 48) = (2, 4.32, 3.24) = (2, 108/25, 81/25),
-- on the plane, and 2.2 m from the drone: (p − F) · (p − F) = 121/25 = (11/5)².
example : (![2, 3, 5] : Fin 3 → ℚ) - (132 / 3600 : ℚ) • ![0, -36, 48] = ![2, 108 / 25, 81 / 25] := by
  ext i; fin_cases i <;> simp <;> norm_num
example : (![0, -36, 48] : Fin 3 → ℚ) ⬝ᵥ ![2, 108 / 25, 81 / 25] = 0 := by
  simp [dotProduct, Fin.sum_univ_three]; norm_num
example : (![0, -33 / 25, 44 / 25] : Fin 3 → ℚ) ⬝ᵥ ![0, -33 / 25, 44 / 25] = (11 / 5) ^ 2 := by
  simp [dotProduct, Fin.sum_univ_three]; norm_num
-- Mast to flight line: q − p = (5, 1.5, 5) − (2, 3, 5) = (3, −3/2, 0), and
-- (3, −3/2, 0) × (2, 1, −2) = (3, 6, 6), of length √81 = 9; over the base 3 that is E = 3 m.
example : (![5, 3 / 2, 5] : Fin 3 → ℚ) - ![2, 3, 5] = ![3, -3 / 2, 0] := by
  ext i; fin_cases i <;> simp <;> norm_num
example : (![3, -3 / 2, 0] : Fin 3 → ℚ) ⨯₃ ![2, 1, -2] = ![3, 6, 6] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : (![3, 6, 6] : Fin 3 → ℤ) ⬝ᵥ ![3, 6, 6] = 81 := by decide
example : √(81 : ℝ) = 9 ∧ (9 : ℝ) / 3 = 3 := by norm_num
-- Reached at t = 1/2: (2, 3, 5) + (1/2)(2, 1, −2) = (3, 7/2, 4), which is 3 m from the mast
-- tip (5, 3/2, 5): (2, −2, 1) · (2, −2, 1) = 9.
example : (![2, 3, 5] : Fin 3 → ℚ) + (1 / 2 : ℚ) • ![2, 1, -2] = ![3, 7 / 2, 4] := by
  ext i; fin_cases i <;> simp <;> norm_num
example : (![2, -2, 1] : Fin 3 → ℤ) ⬝ᵥ ![2, -2, 1] = 9 := by decide
-- Level flight: (0, −36, 48) · (1, 4, 3) = −144 + 144 = 0, so there is no touchdown.
example : (![0, -36, 48] : Fin 3 → ℤ) ⬝ᵥ ![1, 4, 3] = 0 := by decide
-- Mistake 3, straight down: on the plane −3y + 4z = 0 the point below the drone has
-- z = 9/4, so the drop is 5 − 9/4 = 11/4 = 2.75 m, not 2.2 m.
example : (![0, -3, 4] : Fin 3 → ℚ) ⬝ᵥ ![2, 3, 9 / 4] = 0 ∧ (5 : ℚ) - 9 / 4 = 11 / 4 := by
  simp [dotProduct, Fin.sum_univ_three]; norm_num

#print axioms dot_self_nonneg3
#print axioms dot_self_pos3
#print axioms cramer_cross
#print axioms line_meets_plane_at_one_time
#print axioms foot_of_perpendicular_is_closest
#print axioms plane_from_edges_is_normal_test
