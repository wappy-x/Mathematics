-- Conics: lines through one point on a smooth conic match its other points one for one with their slopes, a conic is singular exactly when its matrix has determinant 0, and the card's circle, triangles and counts are exact.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Set.Function
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FinCases

/-- The conic's polynomial F(x, y) = a x^2 + b xy + c y^2 + d x + e y + f. -/
def conicF {K : Type*} [Field K] (a b c d e f x y : K) : K :=
  a * x ^ 2 + b * x * y + c * y ^ 2 + d * x + e * y + f

/-- The conic's symmetric 3 by 3 matrix M, with the three cross terms b, d, e halved. -/
def conicMatrix {K : Type*} [Field K] (a b c d e f : K) : Matrix (Fin 3) (Fin 3) K :=
  !![a, b / 2, d / 2; b / 2, c, e / 2; d / 2, e / 2, f]

/-- A_2(t) = a + b t + c t^2: the coefficient of s^2 in F(x0 + s, y0 + t s). -/
def coeffA2 {K : Type*} [Field K] (a b c t : K) : K :=
  a + b * t + c * t ^ 2

/-- A_1(t) = 2 a x0 + b (y0 + t x0) + 2 c t y0 + d + e t: the coefficient of s in
F(x0 + s, y0 + t s). -/
def coeffA1 {K : Type*} [Field K] (a b c d e x0 y0 t : K) : K :=
  2 * a * x0 + b * (y0 + t * x0) + 2 * c * t * y0 + d + e * t

/-- The second meeting point of the line of slope t through P = (x0, y0) with the conic:
step s = -A_1/A_2 in x, so the point (x0 + s, y0 + t s). -/
def secondPoint {K : Type*} [Field K] (a b c d e x0 y0 t : K) : K × K :=
  (x0 - coeffA1 a b c d e x0 y0 t / coeffA2 a b c t,
   y0 - t * (coeffA1 a b c d e x0 y0 t / coeffA2 a b c t))

/-- Halving: over a field where 2 ≠ 0, 2 u = 0 forces u = 0. -/
theorem conic_half_eq_zero {K : Type*} [Field K] (h2 : (2 : K) ≠ 0) {u : K}
    (h : 2 * u = 0) : u = 0 :=
  (mul_eq_zero.mp h).resolve_left h2

/-- Writing b = 2 b', d = 2 d', e = 2 e' turns the conic's matrix into one with no halves. -/
theorem conicMatrix_double {K : Type*} [Field K] (h2 : (2 : K) ≠ 0) (a b c d e f : K) :
    conicMatrix a (2 * b) c (2 * d) (2 * e) f = !![a, b, d; b, c, e; d, e, f] := by
  simp only [conicMatrix, mul_div_cancel_left₀ _ h2]

/-- A symmetric 3 by 3 matrix with a nonzero vector in its kernel has determinant 0. -/
theorem sym3_det_eq_zero_of_kernel {K : Type*} [Field K] (a b c d e f x y z : K)
    (hne : ¬(x = 0 ∧ y = 0 ∧ z = 0))
    (h1 : a * x + b * y + d * z = 0) (h2 : b * x + c * y + e * z = 0)
    (h3 : d * x + e * y + f * z = 0) :
    (!![a, b, d; b, c, e; d, e, f] : Matrix (Fin 3) (Fin 3) K).det = 0 := by
  refine Matrix.exists_mulVec_eq_zero_iff.mp ⟨![x, y, z], ?_, ?_⟩
  · intro h
    apply hne
    refine ⟨?_, ?_, ?_⟩
    · simpa using congrFun h 0
    · simpa using congrFun h 1
    · simpa using congrFun h 2
  · ext i
    fin_cases i
    · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]; linear_combination h1
    · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]; linear_combination h2
    · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]; linear_combination h3

/-- If a conic contains the whole line through P = (x0, y0) of slope t, its matrix is
singular. -/
theorem conic_det_eq_zero_of_line {K : Type*} [Field K] (h2 : (2 : K) ≠ 0)
    (a b c d e f x0 y0 t : K) (hP : conicF a b c d e f x0 y0 = 0)
    (hA2 : coeffA2 a b c t = 0) (hA1 : coeffA1 a b c d e x0 y0 t = 0) :
    (conicMatrix a b c d e f).det = 0 := by
  obtain ⟨b, rfl⟩ : ∃ b', b = 2 * b' := ⟨b / 2, by field_simp⟩
  obtain ⟨d, rfl⟩ : ∃ d', d = 2 * d' := ⟨d / 2, by field_simp⟩
  obtain ⟨e, rfl⟩ : ∃ e', e = 2 * e' := ⟨e / 2, by field_simp⟩
  rw [conicMatrix_double h2]
  simp only [conicF] at hP
  simp only [coeffA2] at hA2
  have hL1 : a * x0 + b * (y0 + t * x0) + c * t * y0 + d + e * t = 0 :=
    conic_half_eq_zero h2 (by simp only [coeffA1] at hA1; linear_combination hA1)
  -- M P = (p1, p2, p3) and M D = (q1, q2, q3) for P = (x0, y0, 1), D = (1, t, 0).
  by_cases hz : b * x0 + c * y0 + e = 0 ∧ b + c * t = 0
  · obtain ⟨hp2, -⟩ := hz
    refine sym3_det_eq_zero_of_kernel a b c d e f x0 y0 1 (by simp) ?_ ?_ ?_
    · linear_combination hL1 - t * hp2
    · linear_combination hp2
    · linear_combination hP - x0 * hL1 + (x0 * t - y0) * hp2
  · set p2 := b * x0 + c * y0 + e with hp2def
    set q2 := b + c * t with hq2def
    refine sym3_det_eq_zero_of_kernel a b c d e f (q2 * x0 - p2) (q2 * y0 - p2 * t) q2
      ?_ ?_ ?_ ?_
    · rintro ⟨h1, -, h3⟩
      apply hz
      refine ⟨?_, h3⟩
      rw [h3] at h1
      linear_combination -h1
    · linear_combination q2 * hL1 - p2 * hA2
    · ring
    · linear_combination q2 * hP - (x0 * q2 + p2) * hL1 + x0 * p2 * hA2

/-- A smooth conic with one point is a line in disguise. Over a field where 1 + 1 ≠ 0, take
a conic a x^2 + b xy + c y^2 + d x + e y + f = 0 whose matrix M has det M ≠ 0 (smooth), and a
point P = (x0, y0) of the field on it. Then the line of slope t through P meets the conic once
more, at (x0 - A_1/A_2, y0 - t A_1/A_2), and this matches the slopes t (with A_2(t) ≠ 0, the
second meeting in the plane, and A_1(t) ≠ 0, the line not tangent at P) one for one with all
the other points of the conic off the vertical line through P. (The vertical line, the slopes
with A_2 = 0 and the tangent slope account for the points at infinity and P itself, counted
projectively.) Over ℚ this says the slopes are a rational coordinate for every other rational
point. -/
theorem smooth_conic_rational_parametrisation {K : Type*} [Field K] (h2 : (2 : K) ≠ 0)
    (a b c d e f x0 y0 : K) (hsmooth : (conicMatrix a b c d e f).det ≠ 0)
    (hP : conicF a b c d e f x0 y0 = 0) :
    Set.BijOn (secondPoint a b c d e x0 y0)
      {t | coeffA2 a b c t ≠ 0 ∧ coeffA1 a b c d e x0 y0 t ≠ 0}
      {Q | conicF a b c d e f Q.1 Q.2 = 0 ∧ Q.1 ≠ x0} := by
  refine ⟨?_, ?_, ?_⟩
  · -- Maps to: F(x0 + s, y0 + t s) = s (A_2 s + A_1) = 0 with s = -A_1/A_2 ≠ 0.
    rintro t ⟨hA2, hA1⟩
    simp only [Set.mem_ofPred_eq, secondPoint]
    refine ⟨?_, ?_⟩
    · set s := coeffA1 a b c d e x0 y0 t / coeffA2 a b c t with hsdef
      have hAs : coeffA2 a b c t * s = coeffA1 a b c d e x0 y0 t := mul_div_cancel₀ _ hA2
      have hexp : conicF a b c d e f (x0 - s) (y0 - t * s) = conicF a b c d e f x0 y0 +
          s * (coeffA2 a b c t * s - coeffA1 a b c d e x0 y0 t) := by
        simp only [conicF, coeffA2, coeffA1]; ring
      rw [hexp, hP, hAs, sub_self, mul_zero, add_zero]
    · intro h
      have : coeffA1 a b c d e x0 y0 t / coeffA2 a b c t = 0 := by linear_combination -h
      rcases div_eq_zero_iff.mp this with h' | h'
      · exact hA1 h'
      · exact hA2 h'
  · -- One to one: the x-step s ≠ 0 is read off the first coordinate, then t from the second.
    rintro t ⟨hA2, hA1⟩ t' ⟨hA2', hA1'⟩ h
    simp only [secondPoint, Prod.mk.injEq] at h
    obtain ⟨h1, h2'⟩ := h
    have hs : coeffA1 a b c d e x0 y0 t / coeffA2 a b c t =
        coeffA1 a b c d e x0 y0 t' / coeffA2 a b c t' := by linear_combination -h1
    have hs0 : coeffA1 a b c d e x0 y0 t / coeffA2 a b c t ≠ 0 := div_ne_zero hA1 hA2
    rw [← hs] at h2'
    have : (t - t') * (coeffA1 a b c d e x0 y0 t / coeffA2 a b c t) = 0 := by
      linear_combination -h2'
    exact sub_eq_zero.mp ((mul_eq_zero.mp this).resolve_right hs0)
  · -- Onto: the slope of the line from P to Q works, since the conic holds no line.
    rintro ⟨x, y⟩ ⟨hQ, hx⟩
    simp only at hQ hx
    have hs : x - x0 ≠ 0 := sub_ne_zero.mpr hx
    set t := (y - y0) / (x - x0) with ht
    have hy : y = y0 + t * (x - x0) := by rw [ht]; field_simp; ring
    have hline : coeffA2 a b c t * (x - x0) + coeffA1 a b c d e x0 y0 t = 0 := by
      have hexp : conicF a b c d e f x y = conicF a b c d e f x0 y0 +
          (x - x0) * (coeffA2 a b c t * (x - x0) + coeffA1 a b c d e x0 y0 t) := by
        rw [hy]; simp only [conicF, coeffA2, coeffA1]; ring
      rw [hQ, hP, zero_add] at hexp
      exact (mul_eq_zero.mp hexp.symm).resolve_left hs
    have hA2 : coeffA2 a b c t ≠ 0 := by
      intro hA2
      rw [hA2, zero_mul, zero_add] at hline
      exact hsmooth (conic_det_eq_zero_of_line h2 a b c d e f x0 y0 t hP hA2 hline)
    have hA1 : coeffA1 a b c d e x0 y0 t ≠ 0 := by
      intro hA1
      rw [hA1, add_zero] at hline
      exact hs ((mul_eq_zero.mp hline).resolve_left hA2)
    refine ⟨t, ⟨hA2, hA1⟩, ?_⟩
    have hdiv : coeffA1 a b c d e x0 y0 t / coeffA2 a b c t = -(x - x0) := by
      rw [div_eq_iff hA2]; linear_combination hline
    simp only [secondPoint, hdiv, Prod.mk.injEq]
    constructor
    · ring
    · rw [hy]; ring

/-- Smoothness is det M ≠ 0. Over a field where 1 + 1 ≠ 0, the projective conic
a x^2 + b xy + c y^2 + d xz + e yz + f z^2 = 0 has a singular point, a point (x : y : z) not
all zero where all three partial derivatives vanish, exactly when det M = 0. -/
theorem conic_singular_iff_det_eq_zero {K : Type*} [Field K] (h2 : (2 : K) ≠ 0)
    (a b c d e f : K) :
    (∃ x y z : K, (x, y, z) ≠ (0, 0, 0) ∧
        2 * a * x + b * y + d * z = 0 ∧
        b * x + 2 * c * y + e * z = 0 ∧
        d * x + e * y + 2 * f * z = 0) ↔
      (conicMatrix a b c d e f).det = 0 := by
  obtain ⟨b, rfl⟩ : ∃ b', b = 2 * b' := ⟨b / 2, by field_simp⟩
  obtain ⟨d, rfl⟩ : ∃ d', d = 2 * d' := ⟨d / 2, by field_simp⟩
  obtain ⟨e, rfl⟩ : ∃ e', e = 2 * e' := ⟨e / 2, by field_simp⟩
  rw [conicMatrix_double h2]
  constructor
  · rintro ⟨x, y, z, hne, e1, e2, e3⟩
    refine sym3_det_eq_zero_of_kernel a b c d e f x y z ?_
      (conic_half_eq_zero h2 (by linear_combination e1))
      (conic_half_eq_zero h2 (by linear_combination e2))
      (conic_half_eq_zero h2 (by linear_combination e3))
    rintro ⟨rfl, rfl, rfl⟩
    exact hne rfl
  · intro hdet
    obtain ⟨v, hv, hMv⟩ := Matrix.exists_mulVec_eq_zero_iff.mpr hdet
    have c0 := congrFun hMv 0
    have c1 := congrFun hMv 1
    have c2 := congrFun hMv 2
    simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] at c0 c1 c2
    refine ⟨v 0, v 1, v 2, ?_, ?_, ?_, ?_⟩
    · intro h
      simp only [Prod.mk.injEq] at h
      apply hv
      ext i
      fin_cases i
      · exact h.1
      · exact h.2.1
      · exact h.2.2
    · linear_combination 2 * c0
    · linear_combination 2 * c1
    · linear_combination 2 * c2

/-- The unit circle from P = (-1, 0): the slope t gives the point
((1 - t^2)/(1 + t^2), 2t/(1 + t^2)), and every rational slope matches exactly one rational
point of x^2 + y^2 = 1 other than P, with the slope read back as t = y/(x + 1). -/
theorem circle_rational_parametrisation :
    Set.BijOn (fun t : ℚ => ((1 - t ^ 2) / (1 + t ^ 2), 2 * t / (1 + t ^ 2))) Set.univ
        {Q : ℚ × ℚ | Q.1 ^ 2 + Q.2 ^ 2 = 1 ∧ Q ≠ (-1, 0)} ∧
      ∀ t : ℚ, (2 * t / (1 + t ^ 2)) / ((1 - t ^ 2) / (1 + t ^ 2) + 1) = t := by
  have hden : ∀ t : ℚ, 1 + t ^ 2 ≠ 0 := fun t => by positivity
  have hback : ∀ t : ℚ, (2 * t / (1 + t ^ 2)) / ((1 - t ^ 2) / (1 + t ^ 2) + 1) = t := by
    intro t
    have h1 := hden t
    rw [div_add_one h1, div_div_div_cancel_right₀ h1]
    have : (1 - t ^ 2 + (1 + t ^ 2)) = 2 := by ring
    rw [this]
    field_simp
  refine ⟨⟨?_, ?_, ?_⟩, hback⟩
  · intro t _
    have h1 := hden t
    refine ⟨?_, ?_⟩
    · field_simp
      ring
    · intro h
      simp only [Prod.mk.injEq] at h
      have h' := h.1
      rw [div_eq_iff h1] at h'
      linarith
  · intro t _ t' _ h
    rw [← hback t, ← hback t']
    simp only [Prod.mk.injEq] at h
    rw [h.1, h.2]
  · rintro ⟨x, y⟩ ⟨hQ, hne⟩
    simp only at hQ
    have hx : x + 1 ≠ 0 := by
      intro hx
      have hx' : x = -1 := by linarith
      subst hx'
      have : y = 0 := by nlinarith
      exact hne (by rw [this])
    refine ⟨y / (x + 1), Set.mem_univ _, ?_⟩
    have hd : (x + 1) ^ 2 + y ^ 2 = 2 * (x + 1) := by linear_combination hQ
    simp only [Prod.mk.injEq]
    constructor
    · rw [div_eq_iff (hden _)]
      field_simp
      linear_combination (-x - 1) * hQ
    · rw [div_eq_iff (hden _)]
      field_simp
      linear_combination (-y) * hQ

-- The circle's matrix has det M = -1; the tilted ellipse x^2 + xy + y^2 - 1 has det M = -3/4.
example : (conicMatrix (1 : ℚ) 0 1 0 0 (-1)).det = -1 := by
  simp [conicMatrix, Matrix.det_fin_three]
example : (conicMatrix (1 : ℚ) 1 1 0 0 (-1)).det = -3 / 4 := by
  simp [conicMatrix, Matrix.det_fin_three]; norm_num
-- The line pair x^2 - y^2 has det M = 0.
example : (conicMatrix (1 : ℚ) 0 (-1) 0 0 0).det = 0 := by
  simp [conicMatrix, Matrix.det_fin_three]
-- Circle from (-1, 0), slope 1/2: A_2 = 5/4, A_1 = -2, second point (3/5, 4/5).
example : coeffA2 (1 : ℚ) 0 1 (1 / 2) = 5 / 4 ∧ coeffA1 (1 : ℚ) 0 1 0 0 (-1) 0 (1 / 2) = -2 ∧
    secondPoint (1 : ℚ) 0 1 0 0 (-1) 0 (1 / 2) = (3 / 5, 4 / 5) := by
  norm_num [coeffA2, coeffA1, secondPoint]
-- Slopes 2/3 and 1/4 on the circle give (5/13, 12/13) and (15/17, 8/17).
example : secondPoint (1 : ℚ) 0 1 0 0 (-1) 0 (2 / 3) = (5 / 13, 12 / 13) ∧
    secondPoint (1 : ℚ) 0 1 0 0 (-1) 0 (1 / 4) = (15 / 17, 8 / 17) := by
  norm_num [coeffA2, coeffA1, secondPoint]
-- Tilted ellipse x^2 + xy + y^2 = 1 from (-1, 0), slope 1/2: the point (3/7, 5/7).
example : secondPoint (1 : ℚ) 1 1 0 0 (-1) 0 (1 / 2) = (3 / 7, 5 / 7) := by
  norm_num [coeffA2, coeffA1, secondPoint]
-- The right triangles 3-4-5, 5-12-13, 8-15-17.
example : 3 ^ 2 + 4 ^ 2 = 5 ^ 2 ∧ 5 ^ 2 + 12 ^ 2 = 13 ^ 2 ∧ 8 ^ 2 + 15 ^ 2 = 17 ^ 2 := by
  norm_num
-- The 120-degree triangles a^2 + ab + b^2 = c^2: 3-5-7, 7-8-13, 5-16-19.
example : 3 ^ 2 + 3 * 5 + 5 ^ 2 = 7 ^ 2 ∧ 7 ^ 2 + 7 * 8 + 8 ^ 2 = 13 ^ 2 ∧
    5 ^ 2 + 5 * 16 + 16 ^ 2 = 19 ^ 2 := by
  norm_num
-- The circle x^2 + y^2 = 1 over F_7 has 8 points.
example : (Finset.univ.filter (fun p : ZMod 7 × ZMod 7 => p.1 ^ 2 + p.2 ^ 2 = 1)).card = 8 := by
  decide
-- Squares mod 3 are only 0 and 1.
example : ∀ k : ZMod 3, k ^ 2 = 0 ∨ k ^ 2 = 1 := by decide
-- Line pair x^2 - y^2 from (1, 1), slopes 1/2 and 3: (-1/3, 1/3) and (1/2, -1/2), both on y = -x.
example : secondPoint (1 : ℚ) 0 (-1) 0 0 1 1 (1 / 2) = (-1 / 3, 1 / 3) ∧
    secondPoint (1 : ℚ) 0 (-1) 0 0 1 1 3 = (1 / 2, -1 / 2) := by
  norm_num [coeffA2, coeffA1, secondPoint]

#print axioms conic_half_eq_zero
#print axioms conicMatrix_double
#print axioms sym3_det_eq_zero_of_kernel
#print axioms conic_det_eq_zero_of_line
#print axioms smooth_conic_rational_parametrisation
#print axioms conic_singular_iff_det_eq_zero
#print axioms circle_rational_parametrisation
