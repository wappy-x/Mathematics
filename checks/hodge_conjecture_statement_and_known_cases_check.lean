-- The Hodge conjecture: the 48 lines on the Fermat quartic x^4 + y^4 + z^4 + w^4 = 0 lie on the surface, each meets exactly 14 others, four coplanar ones give the plane class, their intersection matrix has rank 20, and the monomial count gives the Hodge numbers 1, 20, 1 of a quartic surface, so the lines fill all 20 directions of type (1, 1).
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Tactic

open Matrix

/-- `ζ = e^(iπ/4)`, a primitive 8th root of unity; its odd powers `ζ, ζ^3, ζ^5, ζ^7` are the
four numbers `a` with `a^4 = -1`. -/
noncomputable def ζ8 : ℂ := Complex.exp (Real.pi * Complex.I / 4)

/-- The three ways to split the coordinates `x_0, x_1, x_2, x_3` into two pairs:
`(0 1)(2 3)`, `(0 2)(1 3)` and `(0 3)(1 2)`. -/
def pairing (q : ℕ) : Fin 4 × Fin 4 × Fin 4 × Fin 4 :=
  if q = 0 then (0, 1, 2, 3) else if q = 1 then (0, 2, 1, 3) else (0, 3, 1, 2)

/-- Line number `r = 16 q + 4 s + t` (with `q < 3`, `s, t < 4`) is cut out by the two linear
forms `x_i - a x_j` and `x_k - b x_l`, where `(i, j, k, l)` is pairing `q`, `a = ζ^(2s+1)` and
`b = ζ^(2t+1)`. Each form is stored as its coefficient vector. -/
noncomputable def lineForm (r : Fin 48) : Fin 2 → Fin 4 → ℂ :=
  match pairing (r.val / 16) with
  | (i, j, k, l) =>
    ![Pi.single i 1 - ζ8 ^ (2 * (r.val / 4 % 4) + 1) • Pi.single j 1,
      Pi.single k 1 - ζ8 ^ (2 * (r.val % 4) + 1) • Pi.single l 1]

/-- Two lines meet exactly when their four defining linear forms are dependent, that is, when
the 4 × 4 determinant of those forms is zero. -/
def LinesMeet (r c : Fin 48) : Prop :=
  Matrix.det (Matrix.of ![lineForm r 0, lineForm r 1, lineForm c 0, lineForm c 1]) = 0

open Classical in
/-- The intersection matrix of the 48 lines on a K3 surface: `L · L = -2` on the diagonal,
and for two different lines `1` if they meet and `0` if not. -/
noncomputable def lineGram : Matrix (Fin 48) (Fin 48) ℚ :=
  Matrix.of fun r c => if r = c then -2 else if LinesMeet r c then 1 else 0

/-! ### Helper lemmas for the proofs below -/

lemma zeta8_isPrimitiveRoot : IsPrimitiveRoot ζ8 8 := by
  have h := Complex.isPrimitiveRoot_exp 8 (by norm_num)
  have e : ζ8 = Complex.exp (2 * Real.pi * Complex.I / (8 : ℕ)) := by
    unfold ζ8; congr 1; push_cast; ring
  rw [e]; exact h

#print axioms zeta8_isPrimitiveRoot

lemma zeta8_pow_eq_iff (m n : ℕ) : ζ8 ^ m = ζ8 ^ n ↔ m % 8 = n % 8 := by
  have hred : ∀ k : ℕ, ζ8 ^ k = ζ8 ^ (k % 8) := fun k => by
    conv_lhs => rw [← Nat.div_add_mod k 8, pow_add, pow_mul, zeta8_isPrimitiveRoot.pow_eq_one,
      one_pow, one_mul]
  rw [hred m, hred n]
  constructor
  · exact fun h => zeta8_isPrimitiveRoot.pow_inj (Nat.mod_lt _ (by norm_num))
      (Nat.mod_lt _ (by norm_num)) h
  · intro h; rw [h]

#print axioms zeta8_pow_eq_iff

lemma zeta8_pow_four : ζ8 ^ 4 = -1 := by
  unfold ζ8
  rw [← Complex.exp_nat_mul]
  have : ((4 : ℕ) : ℂ) * (Real.pi * Complex.I / 4) = Real.pi * Complex.I := by push_cast; ring
  rw [this, Complex.exp_pi_mul_I]

#print axioms zeta8_pow_four

lemma zeta8_odd_pow_four (m : ℕ) : (ζ8 ^ (2 * m + 1)) ^ 4 = -1 := by
  rw [← pow_mul, show (2 * m + 1) * 4 = 8 * m + 4 by ring, pow_add, pow_mul,
    zeta8_isPrimitiveRoot.pow_eq_one, one_pow, one_mul, zeta8_pow_four]

#print axioms zeta8_odd_pow_four

/-- The two forms of a line in pairing `q`, with coefficients `a` and `b`. -/
noncomputable def lineFormAux (q : ℕ) (a b : ℂ) : Fin 2 → Fin 4 → ℂ :=
  match pairing q with
  | (i, j, k, l) => ![Pi.single i 1 - a • Pi.single j 1, Pi.single k 1 - b • Pi.single l 1]

lemma lineForm_eq (r : Fin 48) : lineForm r = lineFormAux (r.val / 16)
    (ζ8 ^ (2 * (r.val / 4 % 4) + 1)) (ζ8 ^ (2 * (r.val % 4) + 1)) := rfl

#print axioms lineForm_eq

/-- The determinant of two lines' forms, by the pairings `q` and `q'` of the two lines;
`a, b` are the first line's coefficients and `c, d` the second's. -/
noncomputable def detExpr (q q' : ℕ) (a b c d : ℂ) : ℂ :=
  if q = q' then (if q = 1 then (a - c) * (b - d) else -((a - c) * (b - d)))
  else if q = 0 ∧ q' = 1 then a * d - b * c
  else if q = 1 ∧ q' = 0 then b * c - a * d
  else if q = 0 ∧ q' = 2 then a * b * d - c
  else if q = 2 ∧ q' = 0 then b * c * d - a
  else if q = 1 ∧ q' = 2 then a * b - c * d
  else c * d - a * b

lemma det_lineFormAux (q q' : ℕ) (hq : q < 3) (hq' : q' < 3) (a b c d : ℂ) :
    Matrix.det (Matrix.of ![lineFormAux q a b 0, lineFormAux q a b 1,
      lineFormAux q' c d 0, lineFormAux q' c d 1]) = detExpr q q' a b c d := by
  interval_cases q <;> interval_cases q' <;>
    simp (config := { decide := true }) [lineFormAux, pairing, detExpr,
      Matrix.det_succ_row_zero, Fin.sum_univ_succ, Pi.single_apply] <;> ring

#print axioms det_lineFormAux

/-- When two lines meet, as a condition on the exponents of `ζ` mod 8. -/
def condB (q q' A B C D : ℕ) : Bool :=
  if q = q' then (A % 8 == C % 8 || B % 8 == D % 8)
  else if (q = 0 ∧ q' = 1) ∨ (q = 1 ∧ q' = 0) then (A + D) % 8 == (B + C) % 8
  else if q = 0 ∧ q' = 2 then (A + B + D) % 8 == C % 8
  else if q = 2 ∧ q' = 0 then (B + C + D) % 8 == A % 8
  else (A + B) % 8 == (C + D) % 8

lemma detExpr_eq_zero_iff (q q' : ℕ) (hq : q < 3) (hq' : q' < 3) (A B C D : ℕ) :
    detExpr q q' (ζ8 ^ A) (ζ8 ^ B) (ζ8 ^ C) (ζ8 ^ D) = 0 ↔ condB q q' A B C D = true := by
  interval_cases q <;> interval_cases q' <;>
    simp only [detExpr, condB, ← pow_add] <;> simp <;>
    simp only [sub_eq_zero, zeta8_pow_eq_iff] <;> constructor <;> intro h <;> omega

#print axioms detExpr_eq_zero_iff

/-- The meeting rule on line numbers, computable. -/
def meetB (r c : Fin 48) : Bool :=
  condB (r.val / 16) (c.val / 16) (2 * (r.val / 4 % 4) + 1) (2 * (r.val % 4) + 1)
    (2 * (c.val / 4 % 4) + 1) (2 * (c.val % 4) + 1)

lemma linesMeet_iff (r c : Fin 48) : LinesMeet r c ↔ meetB r c = true := by
  have hr := r.isLt
  have hc := c.isLt
  unfold LinesMeet meetB
  rw [lineForm_eq r, lineForm_eq c, det_lineFormAux _ _ (by omega) (by omega),
    detExpr_eq_zero_iff _ _ (by omega) (by omega)]

#print axioms linesMeet_iff

/-- The intersection matrix over `ℤ`, computable. -/
def gramZ (r c : Fin 48) : ℤ := if r = c then -2 else if meetB r c then 1 else 0

lemma lineGram_eq : lineGram = (Matrix.of gramZ).map (Int.cast : ℤ → ℚ) := by
  ext r c
  by_cases h1 : r = c <;> by_cases h2 : meetB r c = true <;>
    simp [lineGram, gramZ, h1, h2, linesMeet_iff]

#print axioms lineGram_eq

lemma quartic_aux (u v w y a b : ℂ) (h0 : u = a * v) (h1 : w = b * y) (ha : a ^ 4 = -1)
    (hb : b ^ 4 = -1) : u ^ 4 + v ^ 4 + w ^ 4 + y ^ 4 = 0 := by
  subst h0 h1
  linear_combination v ^ 4 * ha + y ^ 4 * hb

#print axioms quartic_aux

def selS : Fin 20 → Fin 48 := ![0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 16, 17, 18, 20, 21, 22, 32, 33, 34, 36]

def certB : Matrix (Fin 20) (Fin 48) ℤ :=
  !![1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, -1, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 2, -1, 2, 0, -1, 0, 0, 0, 0, 1, 0, 3, 0, -2, 1, -3, 0, 3, 0, 1, 1, -1;
    0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, -1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 2, -2, 1, 0, -1, 1, 0, 0, 0, 1, 0, 3, -1, -1, 0, -2, 0, 3, 1, 0, 2, -2;
    0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1, -1, 2, 2, -2, 2, -1, -1, 1, 0, 0, 0, 1, 0, 3, -1, -1, 1, -3, 0, 3, 0, 1, 2, -2;
    0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, -2, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 3, -2, 2, 0, -2, 1, 0, 0, 0, 1, 0, 3, 0, -2, 1, -3, -1, 4, 0, 1, 2, -2;
    0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1;
    0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, -1, 1, -1, 1, 1, -1, 0, 0, 0, 0, 0, -1, 0, 1, 0, 2, 0, -2, 0, -1, 0, 1;
    0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, -1, 0, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 0, -1, 1, 0, 1, 1, -1, -1, -1, 0, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, -1, 0, 0, 0, 0, 0, -1, 1, 0, 1, 0, 0, -1, -1, 1, -1, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, -1, 1, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, 0, -1, 0, 0, -1, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 1, 0, -1, 0, -1, -1, 1, 1, 0, 0, 0, 0, 0, -1, 0, 1, -1, 1, 1, -1, 1, 0, -1, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 1, -1, 0, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, -1, 0, 1, 0, 1, 0, 0, -1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 0, 1, -1, 1, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, 0, -1, 0, 0, -1, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 1, -1, -1, 1, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 1, -1, 1, 1, -1, 1, 0, -1, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, 0, -1, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, -1, 0, 1, 0, 1, 0, 0, -1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 1, 0, 0, 1, -1, 0, -1, 0, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1, 0, 1, 0, -1, 0, -1, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, -1, 1, -1, 1, 0, 0, 1, -1, 0, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, -1, 0, 0, 0, 0, -1, 1, -1, 1]

def certX : Matrix (Fin 20) (Fin 20) ℤ :=
  !![-85, -71, -86, -100, 21, 48, 31, 6, 23, 21, 30, 30, 4, 26, 34, 12, 16, 28, 16, 4;
    -71, -82, -85, -94, 24, 42, 26, 17, 30, 33, 34, 20, -6, 30, 28, -2, 20, 24, 4, 16;
    -86, -85, -105, -110, 29, 54, 29, 13, 33, 28, 36, 26, -6, 36, 38, 6, 20, 28, 12, 12;
    -100, -94, -110, -132, 30, 60, 38, 14, 30, 32, 40, 36, 4, 32, 44, 12, 16, 32, 16, 8;
    21, 24, 29, 30, -18, -18, -8, -9, -12, -7, -6, 0, 6, -10, -8, 2, -4, -8, -4, 0;
    48, 42, 54, 60, -18, -36, -18, -6, -18, -12, -16, -12, 4, -16, -20, -4, -8, -16, -8, 0;
    31, 26, 29, 38, -8, -18, -18, -1, -6, -9, -10, -12, -2, -6, -12, -6, -4, -8, -4, 0;
    6, 17, 13, 14, -9, -6, -1, -17, -13, -12, -4, 6, 6, -4, 2, 10, -4, -4, 4, -4;
    23, 30, 33, 30, -12, -18, -6, -13, -26, -17, -10, 4, 14, -14, -4, 10, -12, -8, 4, -8;
    21, 33, 28, 32, -7, -12, -9, -12, -17, -25, -14, -2, 8, -10, -6, 8, -8, -4, 8, -12;
    30, 34, 36, 40, -6, -16, -10, -4, -10, -14, -20, -12, 0, -12, -12, 0, -8, -8, 0, -8;
    30, 20, 26, 36, 0, -12, -12, 6, 4, -2, -12, -24, -12, -4, -16, -12, 0, -8, -8, 0;
    4, -6, -6, 4, 6, 4, -2, 6, 14, 8, 0, -12, -20, 8, -4, -12, 8, 0, -8, 8;
    26, 30, 36, 32, -10, -16, -6, -4, -14, -10, -12, -4, 8, -20, -12, 0, -8, -8, 0, -8;
    34, 28, 38, 44, -8, -20, -12, 2, -4, -6, -12, -16, -4, -12, -24, -12, 0, -8, -8, 0;
    12, -2, 6, 12, 2, -4, -6, 10, 10, 8, 0, -12, -12, 0, -12, -20, 8, 0, -8, 8;
    16, 20, 20, 16, -4, -8, -4, -4, -12, -8, -8, 0, 8, -8, 0, 8, -16, -8, 0, -8;
    28, 24, 28, 32, -8, -16, -8, -4, -8, -4, -8, -8, 0, -8, -8, 0, -8, -16, -8, 0;
    16, 4, 12, 16, -4, -8, -4, 4, 4, 8, 0, -8, -8, 0, -8, -8, 0, -8, -16, 8;
    4, 16, 12, 8, 0, 0, 0, -4, -8, -12, -8, 0, 8, -8, 0, 8, -8, 0, 8, -16]

lemma count_meet : ∀ r : Fin 48,
    (Finset.univ.filter (fun c => c ≠ r ∧ meetB r c = true)).card = 14 := by
  decide +kernel

#print axioms count_meet

lemma plane_sums : ∀ (q : Fin 3) (s : Fin 4) (c : Fin 48),
    ∑ t : Fin 4, gramZ ⟨16 * q.val + 4 * s.val + t.val, by omega⟩ c = 1 ∧
    ∑ t : Fin 4, gramZ ⟨16 * q.val + 4 * t.val + s.val, by omega⟩ c = 1 := by
  decide +kernel

#print axioms plane_sums

lemma gram_factor : ∀ r c : Fin 48,
    gramZ r c = ∑ k : Fin 20, gramZ r (selS k) * certB k c := by
  decide +kernel

#print axioms gram_factor

lemma gram_minor_inverse : ∀ i j : Fin 20,
    ∑ k : Fin 20, gramZ (selS i) (selS k) * certX k j = if i = j then 8 else 0 := by
  decide +kernel

#print axioms gram_minor_inverse

/-- The cycle side of `ρ = 20` on the Fermat quartic: the intersection matrix of its 48 lines
(self-intersection `-2`, and `1` or `0` for two different lines as they meet or not) has rank
exactly 20 over `ℚ`. Intersection numbers depend only on classes, so the 48 line classes span
20 dimensions of `Hdg^1`; with `h^(1,1) = 20` this fills every direction of type (1, 1), and
the Hodge conjecture for `p = 1` holds on this surface by explicit curves. -/
theorem fermat_quartic_lines_intersection_rank_eq_twenty : lineGram.rank = 20 := by
  rw [lineGram_eq]
  apply le_antisymm
  · have hfac : (Matrix.of gramZ).map (Int.cast : ℤ → ℚ) =
        ((Matrix.of gramZ).map (Int.cast : ℤ → ℚ)).submatrix id selS *
          certB.map (Int.cast : ℤ → ℚ) := by
      ext r c
      simp only [Matrix.mul_apply, Matrix.map_apply, Matrix.submatrix_apply, Matrix.of_apply, id]
      rw [gram_factor r c]
      push_cast
      rfl
    rw [hfac]
    exact (Matrix.rank_mul_le_left _ _).trans (Matrix.rank_le_width _)
  · have hinv : ((Matrix.of gramZ).map (Int.cast : ℤ → ℚ)).submatrix selS selS *
        ((1 / 8 : ℚ) • certX.map (Int.cast : ℤ → ℚ)) = 1 := by
      ext i j
      simp only [Matrix.mul_apply, Matrix.smul_apply, Matrix.map_apply, Matrix.submatrix_apply,
        Matrix.of_apply, smul_eq_mul, Matrix.one_apply]
      have h := gram_minor_inverse i j
      calc ∑ k, (gramZ (selS i) (selS k) : ℚ) * (1 / 8 * (certX k j : ℚ))
          = 1 / 8 * ((∑ k, gramZ (selS i) (selS k) * certX k j : ℤ) : ℚ) := by
            push_cast
            rw [Finset.mul_sum]
            refine Finset.sum_congr rfl fun k _ => ?_
            ring
        _ = _ := by rw [h]; split_ifs <;> norm_num
    calc (20 : ℕ) = (1 : Matrix (Fin 20) (Fin 20) ℚ).rank := by rw [Matrix.rank_one]; simp
      _ = _ := by rw [← hinv]
      _ ≤ _ := Matrix.rank_mul_le_left _ _
      _ ≤ _ := Matrix.rank_submatrix_le _ _ _

/-- The Hodge side of a smooth quartic surface, by counting monomials: in
`ℂ[x, y, z, w] / (x^3, y^3, z^3, w^3)` the monomials (each exponent at most 2) of degree 0, 4
and 8 number 1, 19 and 1, so `h^(2,0) = 1`, `h^(1,1) = 19 + 1 = 20`, `h^(0,2) = 1`. Their sum
is `b_2 = 22`, the Euler number `4^3 - 4·4^2 + 6·4 = 24` minus 2, and `2 + 2 h^(2,0) - h^(1,1)`
is the signature `(4 - 4^2)·4/3 = -16`. -/
theorem quartic_hodge_numbers_by_monomials :
    let jac : ℕ → ℕ := fun k =>
      (Finset.univ.filter (fun e : Fin 4 → Fin 3 => ∑ i, (e i : ℕ) = k)).card
    jac 0 = 1 ∧ jac 4 = 19 ∧ jac 8 = 1 ∧
      jac 0 + (jac 4 + 1) + jac 8 = 4 ^ 3 - 4 * 4 ^ 2 + 6 * 4 - 2 ∧
      (2 + 2 * (jac 0 : ℤ) - (jac 4 + 1)) * 3 = (4 - 4 ^ 2) * 4 := by
  decide +kernel

open Classical in
/-- The 48 lines on the Fermat quartic: every point of every line satisfies
`x_0^4 + x_1^4 + x_2^4 + x_3^4 = 0`; each line meets exactly 14 of the other 47; and the four
lines in each of the 24 planes `x_i = a x_j` (or `x_k = b x_l`) add up to the plane class `h`,
which has `h · L = 1` for every line `L`. -/
theorem fermat_quartic_lines_on_surface_meet_fourteen_plane_class :
    (∀ (r : Fin 48) (x : Fin 4 → ℂ), lineForm r 0 ⬝ᵥ x = 0 → lineForm r 1 ⬝ᵥ x = 0 →
        ∑ i, x i ^ 4 = 0) ∧
      (∀ r : Fin 48, (Finset.univ.filter (fun c => c ≠ r ∧ LinesMeet r c)).card = 14) ∧
      (∀ (q : Fin 3) (s : Fin 4) (c : Fin 48),
        ∑ t : Fin 4, lineGram ⟨16 * q.val + 4 * s.val + t.val, by omega⟩ c = 1 ∧
        ∑ t : Fin 4, lineGram ⟨16 * q.val + 4 * t.val + s.val, by omega⟩ c = 1) := by
  refine ⟨?_, ?_, ?_⟩
  · intro r x h0 h1
    have hr := r.isLt
    have hq : r.val / 16 < 3 := by omega
    have ha := zeta8_odd_pow_four (r.val / 4 % 4)
    have hb := zeta8_odd_pow_four (r.val % 4)
    rw [lineForm_eq] at h0 h1
    generalize ζ8 ^ (2 * (r.val / 4 % 4) + 1) = a at h0 ha
    generalize ζ8 ^ (2 * (r.val % 4) + 1) = b at h1 hb
    generalize r.val / 16 = q at hq h0 h1
    simp only [Fin.sum_univ_four]
    interval_cases q <;>
      simp [lineFormAux, pairing, dotProduct, Fin.sum_univ_four, Pi.single_apply] at h0 h1
    · linear_combination quartic_aux (x 0) (x 1) (x 2) (x 3) a b (by linear_combination h0)
        (by linear_combination h1) ha hb
    · linear_combination quartic_aux (x 0) (x 2) (x 1) (x 3) a b (by linear_combination h0)
        (by linear_combination h1) ha hb
    · linear_combination quartic_aux (x 0) (x 3) (x 1) (x 2) a b (by linear_combination h0)
        (by linear_combination h1) ha hb
  · intro r
    have e : (Finset.univ.filter (fun c => c ≠ r ∧ LinesMeet r c)) =
        Finset.univ.filter (fun c => c ≠ r ∧ meetB r c = true) := by
      ext c; simp [linesMeet_iff]
    rw [e]
    convert count_meet r
  · intro q s c
    have key := plane_sums q s c
    simp only [lineGram_eq, Matrix.map_apply, Matrix.of_apply]
    exact_mod_cast key

-- 3 pairings times 4 choices of a times 4 choices of b: 48 lines.
example : 3 * 4 * 4 = 48 := by norm_num
-- Each line is a sphere, genus 0: L · L = 2g - 2 = -2.
example : (2 * 0 - 2 : ℤ) = -2 := by norm_num
-- Four coplanar lines meet in 6 pairs: h^2 = 4 × (-2) + 2 × 6 = 4.
example : Nat.choose 4 2 = 6 := by decide
example : (4 * (-2) + 2 * 6 : ℤ) = 4 := by norm_num
-- Euler number 64 - 64 + 24 = 24, so b_2 = 24 - 2 = 22 = 1 + 20 + 1.
example : (4 ^ 3 - 4 * 4 ^ 2 + 6 * 4 : ℤ) = 24 ∧ (24 - 2 : ℤ) = 1 + 20 + 1 := by norm_num
-- Signature (4 - 16) × 4 / 3 = -16 = 2 + 2 × 1 - 20, and b+ = (22 - 16) / 2 = 3 = 2 × 1 + 1.
example : ((4 - 16) * 4 : ℤ) = -16 * 3 ∧ (2 + 2 * 1 - 20 : ℤ) = -16 ∧
    ((22 + -16) / 2 : ℤ) = 2 * 1 + 1 := by norm_num
-- Kollár: 5^3 divides 125, and h^2 = 125 l, so l = h^2 / 125.
example : 5 ^ 3 ∣ 125 := by decide

#print axioms fermat_quartic_lines_intersection_rank_eq_twenty
#print axioms quartic_hodge_numbers_by_monomials
#print axioms fermat_quartic_lines_on_surface_meet_fourteen_plane_class
