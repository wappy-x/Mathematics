-- Nodes and cusps: every line through a point of a complex plane curve meets it to order at least the multiplicity, exactly the tangent lines meet it to higher order, a double point is a node exactly when its discriminant is nonzero, and the uneven zoom turns a doubled tangent into y^2 + αx^3.
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.Algebra.MvPolynomial.Polynomial
import Mathlib.Algebra.Polynomial.Coeff
import Mathlib.Basic.Complex.Basic
import Mathlib.Algebra.Squarefree.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.MvPolynomial.Funext
import Mathlib.Algebra.MvPolynomial.Monad
import Mathlib.Algebra.CharZero.Infinite
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Analysis.SpecialFunctions.Pow.Complex

open MvPolynomial

/-! Variables: `X 0` is `x` and `X 1` is `y`, so a plane curve is `F : MvPolynomial (Fin 2) ℂ`.
The point `P` is moved to the origin by `aeval (fun i => X i + C (P i)) F`, which is
`F(x₀ + x, y₀ + y)`. The line through `P` in direction `d = (u, v)` is
`s ↦ F(x₀ + u s, y₀ + v s)`, a polynomial in `s`. -/

lemma line_coeff_eq_eval_homogeneousComponent (G : MvPolynomial (Fin 2) ℂ) (d : Fin 2 → ℂ)
    (j : ℕ) :
    (aeval (fun i => Polynomial.C (d i) * Polynomial.X) G).coeff j =
      eval d (homogeneousComponent j G) := by
  rw [aeval_def, eval₂_eq', Polynomial.finsetSum_coeff, homogeneousComponent_apply, map_sum,
    Finset.sum_filter]
  refine Finset.sum_congr rfl fun m _ => ?_
  rw [eval_monomial, Finsupp.prod_fintype _ _ (by simp), Finsupp.degree_eq_sum]
  simp only [Fin.prod_univ_two, Fin.sum_univ_two, mul_pow]
  rw [show (Polynomial.C (d 0) ^ m 0 * Polynomial.X ^ m 0 * (Polynomial.C (d 1) ^ m 1 *
      Polynomial.X ^ m 1) : Polynomial ℂ) =
      Polynomial.C (d 0 ^ m 0 * d 1 ^ m 1) * Polynomial.X ^ (m 0 + m 1) by
    simp only [map_mul, map_pow, pow_add]; ring]
  rw [Algebra.algebraMap_eq_smul_one, smul_mul_assoc, one_mul, Polynomial.coeff_smul,
    Polynomial.coeff_C_mul, Polynomial.coeff_X_pow, smul_eq_mul]
  split_ifs with h1 h2 h2 <;> simp_all

#print axioms line_coeff_eq_eval_homogeneousComponent

lemma line_through_point_eq_aeval_shift (F : MvPolynomial (Fin 2) ℂ) (P d : Fin 2 → ℂ) :
    aeval (fun i => Polynomial.C (P i) + Polynomial.C (d i) * Polynomial.X) F =
      aeval (fun i => Polynomial.C (d i) * Polynomial.X) (aeval (fun i => X i + C (P i)) F) := by
  rw [aeval_eq_bind₁ (fun i => X i + C (P i)), aeval_bind₁]
  refine congrArg (fun g => aeval g F) (funext fun i => ?_)
  simp [add_comm]

#print axioms line_through_point_eq_aeval_shift

lemma quadratic_form_eq_of_coeffs (A B Cc A' B' C' : ℂ) (hA : A = A') (hB : B = B')
    (hC : Cc = C') :
    (C A * X 0 ^ 2 + C B * X 0 * X 1 + C Cc * X 1 ^ 2 : MvPolynomial (Fin 2) ℂ) =
      C A' * X 0 ^ 2 + C B' * X 0 * X 1 + C C' * X 1 ^ 2 := by
  rw [hA, hB, hC]

#print axioms quadratic_form_eq_of_coeffs

lemma linear_mul_linear (a b c d : ℂ) :
    ((C a * X 0 + C b * X 1) * (C c * X 0 + C d * X 1) : MvPolynomial (Fin 2) ℂ) =
      C (a * c) * X 0 ^ 2 + C (a * d + b * c) * X 0 * X 1 + C (b * d) * X 1 ^ 2 := by
  simp only [map_mul, map_add]; ring

#print axioms linear_mul_linear

lemma const_mul_linear_sq (e u v : ℂ) :
    (C e * (C u * X 0 + C v * X 1) ^ 2 : MvPolynomial (Fin 2) ℂ) =
      C (e * u ^ 2) * X 0 ^ 2 + C (2 * e * u * v) * X 0 * X 1 + C (e * v ^ 2) * X 1 ^ 2 := by
  simp only [map_mul, map_pow, map_ofNat]; ring

#print axioms const_mul_linear_sq

lemma quadratic_form_coeffs_eq {A B Cc A' B' C' : ℂ}
    (h : (C A * X 0 ^ 2 + C B * X 0 * X 1 + C Cc * X 1 ^ 2 : MvPolynomial (Fin 2) ℂ) =
      C A' * X 0 ^ 2 + C B' * X 0 * X 1 + C C' * X 1 ^ 2) :
    A = A' ∧ B = B' ∧ Cc = C' := by
  have h1 := congrArg (eval ![1, 0]) h
  have h2 := congrArg (eval ![0, 1]) h
  have h3 := congrArg (eval ![1, 1]) h
  simp at h1 h2 h3
  refine ⟨h1, ?_, h2⟩
  linear_combination h3 - h1 - h2

#print axioms quadratic_form_coeffs_eq

lemma zoom_coeff (G : MvPolynomial (Fin 2) ℂ) (x y : ℂ) (k : ℕ) :
    (aeval ![Polynomial.C x * Polynomial.X ^ 2, Polynomial.C y * Polynomial.X ^ 3] G).coeff k =
      ∑ m ∈ G.support, if 2 * m 0 + 3 * m 1 = k then G.coeff m * (x ^ m 0 * y ^ m 1) else 0 := by
  rw [aeval_def, eval₂_eq', Polynomial.finsetSum_coeff]
  refine Finset.sum_congr rfl fun m _ => ?_
  simp only [Fin.prod_univ_two, Matrix.cons_val_zero, Matrix.cons_val_one]
  rw [show ((Polynomial.C x * Polynomial.X ^ 2) ^ m 0 * (Polynomial.C y * Polynomial.X ^ 3) ^ m 1 :
      Polynomial ℂ) = Polynomial.C (x ^ m 0 * y ^ m 1) * Polynomial.X ^ (2 * m 0 + 3 * m 1) by
    simp only [map_mul, map_pow, mul_pow, pow_add, pow_mul]; ring]
  rw [Algebra.algebraMap_eq_smul_one, smul_mul_assoc, one_mul, Polynomial.coeff_smul,
    Polynomial.coeff_C_mul, Polynomial.coeff_X_pow, smul_eq_mul]
  split_ifs with h1 h2 h2 <;> simp_all

#print axioms zoom_coeff

lemma coeff_eq_of_homogeneousComponent_eq {G H : MvPolynomial (Fin 2) ℂ} {n : ℕ}
    (h : homogeneousComponent n G = H) (m : Fin 2 →₀ ℕ) (hm : m 0 + m 1 = n) :
    G.coeff m = H.coeff m := by
  rw [← h, coeff_homogeneousComponent, Finsupp.degree_eq_sum, Fin.sum_univ_two, ite_eq_left hm]

#print axioms coeff_eq_of_homogeneousComponent_eq

/-- Multiplicity is the least order of contact with a line, and the tangent lines are the
lines of higher contact. Move the point `P` of the curve `F = 0` to the origin and let `m` be
the lowest total degree left, with lowest part `F_m`. Then along every line through `P` the
equation vanishes to order at least `m`; the coefficient of `s^m` is `F_m(u, v)`, so a line
meets the curve to order more than `m` exactly when it lies in the tangent cone `F_m = 0`;
and some line meets it to order exactly `m`. Hypotheses as on the card: the point is on the
curve, the field is `ℂ`, and `F` has no repeated factor. -/
theorem multiplicity_eq_least_line_contact_and_tangents_have_higher_contact
    (F : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) (m : ℕ)
    (hP : eval P F = 0) (hsq : Squarefree F)
    (hlow : ∀ j < m, homogeneousComponent j (aeval (fun i => X i + C (P i)) F) = 0)
    (hm : homogeneousComponent m (aeval (fun i => X i + C (P i)) F) ≠ 0) :
    (∀ d : Fin 2 → ℂ, ∀ j < m,
      (aeval (fun i => Polynomial.C (P i) + Polynomial.C (d i) * Polynomial.X) F).coeff j = 0) ∧
    (∀ d : Fin 2 → ℂ,
      (aeval (fun i => Polynomial.C (P i) + Polynomial.C (d i) * Polynomial.X) F).coeff m = 0 ↔
        eval d (homogeneousComponent m (aeval (fun i => X i + C (P i)) F)) = 0) ∧
    (∃ d : Fin 2 → ℂ,
      (aeval (fun i => Polynomial.C (P i) + Polynomial.C (d i) * Polynomial.X) F).coeff m ≠ 0) := by
  simp only [line_through_point_eq_aeval_shift, line_coeff_eq_eval_homogeneousComponent]
  refine ⟨fun d j hj => by rw [hlow j hj, map_zero], fun _ => trivial, ?_⟩
  by_contra h
  push Not at h
  exact hm (MvPolynomial.funext fun x => by rw [h x, map_zero])

/-- A double point is a node exactly when `D = B^2 - 4AC ≠ 0`. A nonzero quadratic part
`F_2 = A x^2 + B xy + C y^2` over `ℂ` is a product of two different (non-proportional)
tangent lines exactly when `D ≠ 0`, and is a constant times one line squared exactly when
`D = 0`. -/
theorem double_point_is_node_iff_discriminant_ne_zero (A B Cc : ℂ)
    (h : ¬ (A = 0 ∧ B = 0 ∧ Cc = 0)) :
    (B ^ 2 - 4 * A * Cc ≠ 0 ↔
      ∃ a b c d : ℂ, a * d - b * c ≠ 0 ∧
        (C A * X 0 ^ 2 + C B * X 0 * X 1 + C Cc * X 1 ^ 2 : MvPolynomial (Fin 2) ℂ) =
          (C a * X 0 + C b * X 1) * (C c * X 0 + C d * X 1)) ∧
    (B ^ 2 - 4 * A * Cc = 0 ↔
      ∃ e u v : ℂ, ¬ (u = 0 ∧ v = 0) ∧
        (C A * X 0 ^ 2 + C B * X 0 * X 1 + C Cc * X 1 ^ 2 : MvPolynomial (Fin 2) ℂ) =
          C e * (C u * X 0 + C v * X 1) ^ 2) := by
  refine ⟨⟨fun hD => ?_, fun ⟨a, b, c, d, hdet, hF⟩ => ?_⟩,
    ⟨fun hD => ?_, fun ⟨e, u, v, huv, hF⟩ => ?_⟩⟩
  · obtain ⟨s, hs⟩ := Complex.isSquare (B ^ 2 - 4 * A * Cc)
    have hs0 : s ≠ 0 := by rintro rfl; simp at hs; exact hD hs
    by_cases hA : A = 0
    · subst hA
      have hB : B ≠ 0 := by intro hB; apply hD; rw [hB]; ring
      refine ⟨0, 1, B, Cc, by simpa using hB, ?_⟩
      rw [linear_mul_linear]
      exact quadratic_form_eq_of_coeffs _ _ _ _ _ _ (by ring) (by ring) (by ring)
    · refine ⟨1, (B + s) / (2 * A), A, (B - s) / 2, ?_, ?_⟩
      · have hdet : 1 * ((B - s) / 2) - (B + s) / (2 * A) * A = -s := by
          field_simp; ring
        rw [hdet]
        exact neg_ne_zero.mpr hs0
      · rw [linear_mul_linear]
        refine quadratic_form_eq_of_coeffs _ _ _ _ _ _ (by ring) (by field_simp; ring) ?_
        field_simp
        linear_combination -hs
  · rw [linear_mul_linear] at hF
    obtain ⟨rfl, rfl, rfl⟩ := quadratic_form_coeffs_eq hF
    intro h'
    apply hdet
    have : (a * d - b * c) ^ 2 = 0 := by linear_combination h'
    exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
  · by_cases hA : A = 0
    · subst hA
      have hB : B = 0 := by simpa using hD
      subst hB
      have hC : Cc ≠ 0 := fun hC => h ⟨rfl, rfl, hC⟩
      refine ⟨Cc, 0, 1, by simp, ?_⟩
      rw [const_mul_linear_sq]
      exact quadratic_form_eq_of_coeffs _ _ _ _ _ _ (by ring) (by ring) (by ring)
    · refine ⟨A, 1, B / (2 * A), by simp, ?_⟩
      rw [const_mul_linear_sq]
      refine quadratic_form_eq_of_coeffs _ _ _ _ _ _ (by ring) (by field_simp) ?_
      field_simp
      linear_combination -hD
  · rw [const_mul_linear_sq] at hF
    obtain ⟨rfl, rfl, rfl⟩ := quadratic_form_coeffs_eq hF
    ring

/-- The cusp's uneven zoom. Take a curve already moved so the point is the origin, with
multiplicity 2 and quadratic part `y^2` (the one tangent turned to `y = 0`), and let `α` be
its coefficient of `x^3`. Replacing `x` by `s^2 x` and `y` by `s^3 y` gives
`s^6 (y^2 + α x^3) + s^7 (…)`: every coefficient below `s^6` is zero and the `s^6`
coefficient is `y^2 + α x^3`. -/
theorem cusp_uneven_zoom (G : MvPolynomial (Fin 2) ℂ)
    (h0 : homogeneousComponent 0 G = 0) (h1 : homogeneousComponent 1 G = 0)
    (h2 : homogeneousComponent 2 G = X 1 ^ 2) (x y : ℂ) :
    (∀ j < 6, (aeval ![Polynomial.C x * Polynomial.X ^ 2, Polynomial.C y * Polynomial.X ^ 3]
        G).coeff j = 0) ∧
    (aeval ![Polynomial.C x * Polynomial.X ^ 2, Polynomial.C y * Polynomial.X ^ 3] G).coeff 6 =
      y ^ 2 + G.coeff (Finsupp.single 0 3) * x ^ 3 := by
  have hX : ∀ m : Fin 2 →₀ ℕ, (X 1 ^ 2 : MvPolynomial (Fin 2) ℂ).coeff m =
      if m 0 = 0 ∧ m 1 = 2 then 1 else 0 := by
    intro m
    rw [coeff_X_pow]
    congr 1
    apply propext
    constructor
    · rintro rfl; simp
    · rintro ⟨h0', h1'⟩
      ext i; fin_cases i <;> simp [h0', h1']
  have hlow : ∀ m : Fin 2 →₀ ℕ, m 0 + m 1 ≤ 2 → ¬ (m 0 = 0 ∧ m 1 = 2) → G.coeff m = 0 := by
    intro m hm hne
    rcases (show m 0 + m 1 = 0 ∨ m 0 + m 1 = 1 ∨ m 0 + m 1 = 2 by omega) with h | h | h
    · simpa using coeff_eq_of_homogeneousComponent_eq h0 m h
    · simpa using coeff_eq_of_homogeneousComponent_eq h1 m h
    · rw [coeff_eq_of_homogeneousComponent_eq h2 m h, hX, ite_eq_right hne]
  refine ⟨fun j hj => ?_, ?_⟩
  · rw [zoom_coeff]
    refine Finset.sum_eq_zero fun m _ => ?_
    split_ifs with hk
    · rw [hlow m (by omega) (by omega), zero_mul]
    · rfl
  · rw [zoom_coeff, Finset.sum_eq_add (Finsupp.single 0 3) (Finsupp.single 1 2)]
    · have hc : G.coeff (Finsupp.single 1 2) = 1 := by
        rw [coeff_eq_of_homogeneousComponent_eq h2 _ (by simp), hX]; simp
      simp [hc, add_comm]
    · intro h; have := congrArg (fun f => f 0) h; simp at this
    · intro m _ ⟨ha, hb⟩
      split_ifs with hk
      · exfalso
        have : (m 0 = 3 ∧ m 1 = 0) ∨ (m 0 = 0 ∧ m 1 = 2) := by omega
        rcases this with ⟨e0, e1⟩ | ⟨e0, e1⟩
        · exact ha (by ext i; fin_cases i <;> simp [e0, e1])
        · exact hb (by ext i; fin_cases i <;> simp [e0, e1])
      · rfl
    · intro hn; rw [Finsupp.notMem_support_iff.mp hn]; simp
    · intro hn; rw [Finsupp.notMem_support_iff.mp hn]; simp

/-! The card's worked numbers. -/

-- node y^2 = x^2(x + 1) at the origin: F_2 = -x^2 + y^2, so A = -1, B = 0, C = 1 and D = 4
example : (0 : ℤ) ^ 2 - 4 * (-1) * 1 = 4 := by norm_num

-- node: the line y = x gives F(s, s) = -s^3, order 3, more than m = 2
example (s : ℤ) : s ^ 2 - s ^ 3 - s ^ 2 = -s ^ 3 := by ring

-- node: the parametrisation (t^2 - 1, t^3 - t) lies on y^2 = x^2(x + 1)
example (t : ℤ) : (t ^ 3 - t) ^ 2 = (t ^ 2 - 1) ^ 2 * ((t ^ 2 - 1) + 1) := by ring

-- node: velocities (2t, 3t^2 - 1) at t = -1 and t = 1 are (-2, 2) and (2, 2)
example : (2 * (-1 : ℤ), 3 * (-1 : ℤ) ^ 2 - 1) = (-2, 2) ∧
    (2 * (1 : ℤ), 3 * (1 : ℤ) ^ 2 - 1) = (2, 2) := by norm_num

-- Bezout: y = 2x meets the node cubic once more, at (3, 6) = (2^2 - 1, 2^3 - 2)
example : ((2 : ℤ) ^ 2 - 1, (2 : ℤ) ^ 3 - 2) = (3, 6) ∧ (6 : ℤ) ^ 2 = 3 ^ 2 * (3 + 1) := by
  norm_num

-- cusp y^2 = x^3: F_2 = y^2 has D = 0^2 - 4·0·1 = 0, and F_3 = -x^3 is -1 at the direction (1, 0)
example : (0 : ℤ) ^ 2 - 4 * 0 * 1 = 0 ∧ -((1 : ℤ) ^ 3) = -1 := by norm_num

-- cusp: (t^2, t^3) lies on y^2 = x^3, with velocity (2t, 3t^2) = (0, 0) at t = 0
example (t : ℤ) : (t ^ 3) ^ 2 = (t ^ 2) ^ 3 := by ring
example : (2 * (0 : ℤ), 3 * (0 : ℤ) ^ 2) = (0, 0) := by norm_num

-- neighbour y^2 = x^3 + x^2 - 4/27 moved to (-2/3, 0) is -x^3 + x^2 + y^2, so D = 0^2 - 4·1·1 = -4
example (x y : ℚ) :
    y ^ 2 - (x - 2 / 3) ^ 3 - (x - 2 / 3) ^ 2 + 4 / 27 = -x ^ 3 + x ^ 2 + y ^ 2 := by ring
example : (0 : ℤ) ^ 2 - 4 * 1 * 1 = -4 := by norm_num

-- house family y^2 = x^3 + x^2 + c: singular only at c = -x^3 - x^2 for x = 0 or x = -2/3,
-- that is c = 0 or c = -4/27, the zeros of the discriminant -c(4 + 27c)
example : -((0 : ℚ) ^ 3) - 0 ^ 2 = 0 ∧ -((-2 / 3 : ℚ) ^ 3) - (-2 / 3) ^ 2 = -4 / 27 := by norm_num
example : -(0 : ℚ) * (4 + 27 * 0) = 0 ∧ -(-4 / 27 : ℚ) * (4 + 27 * (-4 / 27)) = 0 := by norm_num

#print axioms multiplicity_eq_least_line_contact_and_tangents_have_higher_contact
#print axioms double_point_is_node_iff_discriminant_ne_zero
#print axioms cusp_uneven_zoom
