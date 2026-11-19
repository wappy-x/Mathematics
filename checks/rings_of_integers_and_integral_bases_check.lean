-- Rings of integers: for a squarefree whole number d that is not a square, the algebraic integers of Q(√d) are exactly the whole combinations x + y·e, in one way only, of 1 and e = (1 + √d)/2 when d leaves remainder 1 on division by 4 and e = √d otherwise, and the discriminant of the basis 1, e is d or 4d.
import Mathlib.Algebra.QuadraticAlgebra.Integral
import Mathlib.Algebra.QuadraticAlgebra.Int
import Mathlib.RingTheory.Discriminant
import Mathlib.Algebra.Squarefree.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.GCDMonoid.IntegrallyClosed
import Mathlib.Data.ZMod.Basic

open QuadraticAlgebra

/-- The second integral-basis number of `ℚ(√d)`, written in the model
`QuadraticAlgebra ℚ d 0` of `ℚ(√d)`, where `ω` is `√d` (`ω ^ 2 = d`):
`(1 + √d)/2` when `d ≡ 1 (mod 4)`, and `√d` otherwise. -/
noncomputable def basisTwo (d : ℤ) : QuadraticAlgebra ℚ (d : ℚ) 0 :=
  if d % 4 = 1 then (2 : ℚ)⁻¹ • (1 + ω) else ω

theorem roi_intClosed : IsIntegrallyClosedIn ℤ ℚ :=
  (isIntegrallyClosed_iff_isIntegrallyClosedIn ℚ).mp inferInstance

theorem roi_isIntegral_iff (d : ℤ) (z : QuadraticAlgebra ℚ (d : ℚ) 0) :
    IsIntegral ℤ z ↔ (∃ t : ℤ, 2 * z.re = t) ∧ ∃ n : ℤ, z.re * z.re - d * z.im * z.im = n := by
  have := roi_intClosed
  rw [isIntegral_iff, trace_def, norm_def]
  simp only [Set.mem_range, algebraMap_int_eq, eq_intCast, zero_mul, add_zero]
  constructor
  · rintro ⟨⟨t, ht⟩, ⟨n, hn⟩⟩; exact ⟨⟨t, ht.symm⟩, ⟨n, hn.symm⟩⟩
  · rintro ⟨⟨t, ht⟩, ⟨n, hn⟩⟩; exact ⟨⟨t, ht.symm⟩, ⟨n, hn.symm⟩⟩

theorem roi_sqfree_rat (d : ℤ) (hsf : Squarefree d) (q : ℚ) (k : ℤ) (h : (d : ℚ) * q ^ 2 = k) :
    ∃ m : ℤ, q = m := by
  have hden : (q.den : ℚ) ≠ 0 := by positivity
  have hq : q = q.num / q.den := (Rat.num_div_den q).symm
  have key : d * q.num ^ 2 = k * (q.den : ℤ) ^ 2 := by
    have : (d : ℚ) * (q.num : ℚ) ^ 2 = (k : ℚ) * ((q.den : ℤ) : ℚ) ^ 2 := by
      rw [hq] at h; field_simp at h; push_cast; linarith
    exact_mod_cast this
  have hcop : IsCoprime ((q.den : ℤ) ^ 2) (q.num ^ 2) := by
    apply IsCoprime.pow
    rw [Int.isCoprime_iff_gcd_eq_one, Int.gcd_comm]
    exact q.reduced
  have hdvd : (q.den : ℤ) ^ 2 ∣ d := by
    have : (q.den : ℤ) ^ 2 ∣ q.num ^ 2 * d := ⟨k, by linarith [key]⟩
    exact hcop.dvd_of_dvd_mul_left this
  have hu : IsUnit (q.den : ℤ) := hsf _ (by rw [← sq]; exact hdvd)
  have h1 : q.den = 1 := by
    rcases Int.isUnit_iff.mp hu with h1 | h1 <;> omega
  exact ⟨q.num, by rw [hq, h1]; simp⟩

theorem roi_zmod_one : ∀ T U : ZMod 4, T ^ 2 - 1 * U ^ 2 = 0 → 2 * (T - U) = 0 := by decide
theorem roi_zmod_two : ∀ T U : ZMod 4, T ^ 2 - 2 * U ^ 2 = 0 → 2 * T = 0 ∧ 2 * U = 0 := by decide
theorem roi_zmod_three : ∀ T U : ZMod 4, T ^ 2 - 3 * U ^ 2 = 0 → 2 * T = 0 ∧ 2 * U = 0 := by decide

theorem roi_dvd_four (x : ℤ) (h : ((x : ℤ) : ZMod 4) = 0) : 4 ∣ x :=
  (ZMod.intCast_zmod_eq_zero_iff_dvd x 4).mp h

theorem roi_cast_mod (d c : ℤ) (h : d % 4 = c) : ((d : ℤ) : ZMod 4) = ((c : ℤ) : ZMod 4) := by
  rw [← h]; exact (ZMod.intCast_mod d 4).symm

theorem roi_mod4_ne_zero (d : ℤ) (hsf : Squarefree d) : d % 4 ≠ 0 := by
  intro h
  have : (2 : ℤ) * 2 ∣ d := by omega
  have := hsf 2 this
  rw [Int.isUnit_iff] at this; omega

theorem roi_algTrace (d : ℤ) (z : QuadraticAlgebra ℚ (d : ℚ) 0) :
    Algebra.trace ℚ (QuadraticAlgebra ℚ (d : ℚ) 0) z = QuadraticAlgebra.trace z := by
  rw [Algebra.trace_eq_matrix_trace (QuadraticAlgebra.basis (d : ℚ) 0)]
  simp [Matrix.trace, Fin.sum_univ_two, Algebra.leftMulMatrix_eq_repr_mul, trace_def]
  ring

/-- The card's main claim. Let `d` be a squarefree whole number that is not a square, and
`K = ℚ(√d)`. A number `z` of `K` is an algebraic integer (a root of a monic polynomial with whole
coefficients) exactly when `z = x + y·e` for whole numbers `x, y`, and then the pair `x, y` is
unique. Here `e = (1 + √d)/2` when `d` leaves remainder 1 on division by 4, and `e = √d`
otherwise. So `1, e` is an integral basis of the ring of integers `O_K`. -/
theorem ring_of_integers_quadratic_field (d : ℤ) (hsf : Squarefree d) (hns : ¬ IsSquare d)
    (z : QuadraticAlgebra ℚ (d : ℚ) 0) :
    IsIntegral ℤ z ↔
      ∃! xy : ℤ × ℤ, z = (xy.1 : QuadraticAlgebra ℚ (d : ℚ) 0) +
        (xy.2 : QuadraticAlgebra ℚ (d : ℚ) 0) * basisTwo d := by
  rw [roi_isIntegral_iff]
  by_cases hd : d % 4 = 1
  · have hd' : (d : ℚ) = 4 * ((d / 4 : ℤ) : ℚ) + 1 := by exact_mod_cast (by omega : d = 4 * (d / 4) + 1)
    constructor
    · rintro ⟨⟨t, ht⟩, ⟨n, hn⟩⟩
      obtain ⟨u, hu⟩ := roi_sqfree_rat d hsf (2 * z.im) (t ^ 2 - 4 * n) (by
        push_cast; rw [← ht, ← hn]; ring)
      have heq : t ^ 2 - d * u ^ 2 = 4 * n := by
        have : (t : ℚ) ^ 2 - d * (u : ℚ) ^ 2 = 4 * n := by rw [← ht, ← hu, ← hn]; ring
        exact_mod_cast this
      have hz : ((2 * (t - u) : ℤ) : ZMod 4) = 0 := by
        have hc := congrArg (Int.cast : ℤ → ZMod 4) heq
        push_cast at hc ⊢
        rw [roi_cast_mod d 1 hd] at hc
        have h4 : (4 : ZMod 4) = 0 := by decide
        rw [h4, zero_mul] at hc
        exact roi_zmod_one _ _ (by simpa using hc)
      obtain ⟨k, hk⟩ := roi_dvd_four _ hz
      refine ⟨⟨k, u⟩, ?_, ?_⟩
      · have hk' : (t : ℚ) = 2 * k + u := by exact_mod_cast (by omega : t = 2 * k + u)
        ext <;> simp [basisTwo, hd] <;> linarith
      · rintro ⟨x, y⟩ hxy
        have h1 := congrArg QuadraticAlgebra.re hxy
        have h2 := congrArg QuadraticAlgebra.im hxy
        simp [basisTwo, hd] at h1 h2
        have hy : (y : ℚ) = u := by linarith
        have hy' : y = u := by exact_mod_cast hy
        have hx : (x : ℚ) = k := by
          have hk' : (t : ℚ) = 2 * k + u := by exact_mod_cast (by omega : t = 2 * k + u)
          linarith
        have hx' : x = k := by exact_mod_cast hx
        simp [hx', hy']
    · rintro ⟨⟨x, y⟩, rfl, -⟩
      refine ⟨⟨2 * x + y, ?_⟩, ⟨x * x + x * y - (d / 4) * y * y, ?_⟩⟩
      · simp [basisTwo, hd]; ring
      · simp [basisTwo, hd]; rw [hd']; push_cast; ring
  · have hd0 := roi_mod4_ne_zero d hsf
    constructor
    · rintro ⟨⟨t, ht⟩, ⟨n, hn⟩⟩
      obtain ⟨u, hu⟩ := roi_sqfree_rat d hsf (2 * z.im) (t ^ 2 - 4 * n) (by
        push_cast; rw [← ht, ← hn]; ring)
      have heq : t ^ 2 - d * u ^ 2 = 4 * n := by
        have : (t : ℚ) ^ 2 - d * (u : ℚ) ^ 2 = 4 * n := by rw [← ht, ← hu, ← hn]; ring
        exact_mod_cast this
      have hz : ((2 * t : ℤ) : ZMod 4) = 0 ∧ ((2 * u : ℤ) : ZMod 4) = 0 := by
        have hc := congrArg (Int.cast : ℤ → ZMod 4) heq
        push_cast at hc ⊢
        have h4 : (4 : ZMod 4) = 0 := by decide
        rw [h4, zero_mul] at hc
        have : d % 4 = 2 ∨ d % 4 = 3 := by omega
        rcases this with h | h
        · rw [roi_cast_mod d 2 h] at hc
          exact roi_zmod_two _ _ (by simpa using hc)
        · rw [roi_cast_mod d 3 h] at hc
          exact roi_zmod_three _ _ (by simpa using hc)
      obtain ⟨k, hk⟩ := roi_dvd_four _ hz.1
      obtain ⟨l, hl⟩ := roi_dvd_four _ hz.2
      have hk' : (t : ℚ) = 2 * k := by exact_mod_cast (by omega : t = 2 * k)
      have hl' : (u : ℚ) = 2 * l := by exact_mod_cast (by omega : u = 2 * l)
      refine ⟨⟨k, l⟩, ?_, ?_⟩
      · ext <;> simp [basisTwo, hd] <;> linarith
      · rintro ⟨x, y⟩ hxy
        have h1 := congrArg QuadraticAlgebra.re hxy
        have h2 := congrArg QuadraticAlgebra.im hxy
        simp [basisTwo, hd] at h1 h2
        have hy : (y : ℚ) = l := by linarith
        have hy' : y = l := by exact_mod_cast hy
        have hx : (x : ℚ) = k := by linarith
        have hx' : x = k := by exact_mod_cast hx
        simp [hx', hy']
    · rintro ⟨⟨x, y⟩, rfl, -⟩
      refine ⟨⟨2 * x, ?_⟩, ⟨x * x - d * y * y, ?_⟩⟩
      · simp [basisTwo, hd]
      · simp [basisTwo, hd]

/-- The field discriminant. With the same hypotheses, the discriminant of the integral basis
`1, e` (the determinant of its trace matrix) is `d_K = d` when `d ≡ 1 (mod 4)` and
`d_K = 4d` otherwise. -/
theorem discriminant_quadratic_field (d : ℤ) (hsf : Squarefree d) (hns : ¬ IsSquare d) :
    Algebra.discr ℚ ![(1 : QuadraticAlgebra ℚ (d : ℚ) 0), basisTwo d] =
      if d % 4 = 1 then (d : ℚ) else 4 * d := by
  rw [Algebra.discr_def, Matrix.det_fin_two]
  simp only [Algebra.traceMatrix_apply, Algebra.traceForm_apply, roi_algTrace, trace_def]
  by_cases hd : d % 4 = 1
  · simp [basisTwo, hd]
    ring
  · simp [basisTwo, hd]
    ring

/-- The half that gets in. For `d ≡ 1 (mod 4)`, `ω = (1 + √d)/2` satisfies
`ω ^ 2 = ω + (d - 1)/4`, a monic equation with whole coefficients, so `ω` is an algebraic
integer; for `d ≡ 2` or `3 (mod 4)` it is not. -/
theorem half_is_integral_iff (d : ℤ) (hsf : Squarefree d) (hns : ¬ IsSquare d) :
    IsIntegral ℤ ((2 : ℚ)⁻¹ • (1 + ω) : QuadraticAlgebra ℚ (d : ℚ) 0) ↔ d % 4 = 1 := by
  rw [roi_isIntegral_iff]
  simp only [re_smul, im_smul, re_add, im_add, re_one, im_one, re_omega, im_omega, smul_eq_mul]
  constructor
  · rintro ⟨-, ⟨n, hn⟩⟩
    have : (1 : ℚ) - d = 4 * n := by linarith
    have : (1 : ℤ) - d = 4 * n := by exact_mod_cast this
    omega
  · intro hd
    have hd' : (d : ℚ) = 4 * ((d / 4 : ℤ) : ℚ) + 1 := by exact_mod_cast (by omega : d = 4 * (d / 4) + 1)
    refine ⟨⟨1, by norm_num⟩, ⟨-(d / 4), ?_⟩⟩
    rw [hd']; push_cast; ring

-- The card's whole-number worked examples.
-- 5 leaves remainder 1 on division by 4; −5 leaves remainder 3.
example : (5 : ℤ) % 4 = 1 ∧ (-5 : ℤ) % 4 = 3 := by decide
-- In Z[φ] (φ² = 1 + φ), the tenth power of the golden ratio is 34 + 55φ.
example : (ω : QuadraticAlgebra ℤ 1 1) ^ 10 = ⟨34, 55⟩ := by decide
-- In 1, √5 coordinates the same number is (123 + 55√5)/2: 34 + 55/2 = 123/2.
example : (34 : ℚ) + 55 / 2 = 123 / 2 := by norm_num
-- Candidates for d = 5: norms 1/4, −5/4 and (1 − 5)/4 = −1; only the last is whole.
example : QuadraticAlgebra.norm (⟨1/2, 0⟩ : QuadraticAlgebra ℚ 5 0) = 1/4 := by
  simp [QuadraticAlgebra.norm_def]; norm_num
example : QuadraticAlgebra.norm (⟨0, 1/2⟩ : QuadraticAlgebra ℚ 5 0) = -5/4 := by
  simp [QuadraticAlgebra.norm_def]; norm_num
example : QuadraticAlgebra.norm (⟨1/2, 1/2⟩ : QuadraticAlgebra ℚ 5 0) = -1 := by
  simp [QuadraticAlgebra.norm_def]; norm_num
-- Discriminants by trace matrices: 1, √5 has traces 2, 0, 10, giving 2·10 − 0² = 20;
-- 1, φ has traces 2, 1, 3, giving 2·3 − 1² = 5; the index of Z[√5] is 2, as 20 = 2² · 5.
example : (2 : ℤ) * 10 - 0 ^ 2 = 20 ∧ (2 : ℤ) * 3 - 1 ^ 2 = 5 ∧ (20 : ℤ) = 2 ^ 2 * 5 := by
  norm_num
-- House example: (1 + √−5)(1 − √−5) = 6 in Z[√−5], and 6 = 2 · 3.
example : (⟨1, 1⟩ : QuadraticAlgebra ℤ (-5) 0) * ⟨1, -1⟩ = 6 := by decide
-- (1 + √−5)/2 has norm 6/4, not whole, so halves stay out; d_K = 4 · (−5) = −20.
example : (6 : ℤ) % 4 ≠ 0 ∧ 4 * (-5 : ℤ) = -20 := by decide
-- d = 45 is not squarefree: 45 = 3² · 5, so Q(√45) = Q(√5).
example : (45 : ℤ) = 3 ^ 2 * 5 := by norm_num
-- d = −3: the norm form x² + xy + y² of Z[ω] takes the value 1 six times on the grid
-- −3..3, while a² + 3b² of Z[√−3] takes it twice.
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun p => p.1 ^ 2 + p.1 * p.2 + p.2 ^ 2 = 1)).card = 6 := by decide
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun p => p.1 ^ 2 + 3 * p.2 ^ 2 = 1)).card = 2 := by decide

#print axioms roi_intClosed
#print axioms roi_isIntegral_iff
#print axioms roi_sqfree_rat
#print axioms roi_zmod_one
#print axioms roi_zmod_two
#print axioms roi_zmod_three
#print axioms roi_dvd_four
#print axioms roi_cast_mod
#print axioms roi_mod4_ne_zero
#print axioms roi_algTrace
#print axioms ring_of_integers_quadratic_field
#print axioms discriminant_quadratic_field
#print axioms half_is_integral_iff
