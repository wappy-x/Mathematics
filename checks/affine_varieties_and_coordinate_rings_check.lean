-- Affine varieties: two polynomials are the same function on a variety exactly when their difference lies in its vanishing ideal, so the coordinate ring k[V] = k[x₁, …, xₙ]/I(V) is the ring of polynomial functions on V, and for the real or complex cone x² + y² = z² that ideal is the multiples of x² + y² − z².
import Mathlib.RingTheory.Nullstellensatz
import Mathlib.RingTheory.Ideal.Quotient.Operations
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Algebra.MvPolynomial.Rename
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Algebra.MvPolynomial.Funext
import Mathlib.Algebra.MvPolynomial.Equiv
import Mathlib.Algebra.Polynomial.Degree.SmallDegree

/-! The field is `k`. The unknowns x₁, …, xₙ are `X 0, …, X (n-1)` in `MvPolynomial (Fin n) k`.
A system is `f : Fin s → MvPolynomial (Fin n) k`; its variety V(f₁, …, fₛ) is Mathlib's
`zeroLocus k (Ideal.span (Set.range f))`, a set of points `a : Fin n → k` of affine n-space.
The vanishing ideal I(V) is `vanishingIdeal k V`, and the coordinate ring k[V] is the quotient
`MvPolynomial (Fin n) k ⧸ vanishingIdeal k V`. `eval a g` is the value of g at the point a.
On the cone, x = X 0, y = X 1, z = X 2; a polynomial A(y, z) in two letters is placed in
k[x, y, z] by `rename Fin.succ`, which sends its letters to y and z. -/

open MvPolynomial

namespace AffineVarietiesCard

lemma cone_mem_iff {K : Type*} [Field K] (a : Fin 3 → K) :
    a ∈ zeroLocus K (Ideal.span {(X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) K)}) ↔
      eval a (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) K) = 0 := by
  rw [zeroLocus_span]
  simp only [Set.mem_singleton_iff, forall_eq, Set.mem_ofPred_eq, aeval_eq_eval]

lemma finSuccEquiv_rename_succ {K : Type*} [CommRing K] (A : MvPolynomial (Fin 2) K) :
    finSuccEquiv K 2 (rename Fin.succ A) = Polynomial.C A := by
  induction A using MvPolynomial.induction_on with
  | C r => simp [finSuccEquiv_apply]
  | add p q hp hq => simp [hp, hq]
  | mul_X p i hp => simp [hp, finSuccEquiv_X_succ]

lemma cone_division {K : Type*} [Field K] (g : MvPolynomial (Fin 3) K) :
    ∃ q : MvPolynomial (Fin 3) K, ∃ A B : MvPolynomial (Fin 2) K,
      g = q * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2) + (rename Fin.succ A + X 0 * rename Fin.succ B) := by
  set F := finSuccEquiv K 2
  set m : Polynomial (MvPolynomial (Fin 2) K) :=
    Polynomial.X ^ 2 + Polynomial.C (X 0 ^ 2 - X 1 ^ 2)
  have h1 : F (X 1) = Polynomial.C (X 0) := by
    rw [show (X 1 : MvPolynomial (Fin 3) K) = X (Fin.succ 0) from
      congrArg X (by decide)]
    exact finSuccEquiv_X_succ
  have h2 : F (X 2) = Polynomial.C (X 1) := by
    rw [show (X 2 : MvPolynomial (Fin 3) K) = X (Fin.succ 1) from
      congrArg X (by decide)]
    exact finSuccEquiv_X_succ
  have hFf : F (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2) = m := by
    simp only [map_add, map_sub, map_pow, h1, h2, finSuccEquiv_X_zero, F, m]
    ring
  have hm : m.Monic := Polynomial.monic_X_pow_add_C _ two_ne_zero
  have hmdeg : m.natDegree = 2 := Polynomial.natDegree_X_pow_add_C
  set r := F g %ₘ m with hr_def
  have hrdeg : r.natDegree ≤ 1 := by
    have := Polynomial.natDegree_modByMonic_lt (F g) hm (by
      intro h; have := congrArg Polynomial.natDegree h; simp [hmdeg] at this)
    rw [hmdeg] at this
    exact Nat.lt_succ_iff.mp this
  have hr := Polynomial.eq_X_add_C_of_natDegree_le_one hrdeg
  refine ⟨F.symm (F g /ₘ m), r.coeff 0, r.coeff 1, ?_⟩
  apply F.injective
  simp only [map_add, map_mul, hFf, finSuccEquiv_rename_succ, finSuccEquiv_X_zero,
    AlgEquiv.apply_symm_apply, F]
  linear_combination (Polynomial.modByMonic_add_div (F g) m).symm + hr

lemma cone_standard_zero {K : Type*} [RCLike K] (A B : MvPolynomial (Fin 2) K)
    (h : ∀ a : Fin 3 → K, eval a (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) K) = 0 →
      eval a (rename Fin.succ A + X 0 * rename Fin.succ B) = 0) :
    A = 0 ∧ B = 0 := by
  let s : Fin 2 → Set K :=
    ![(fun r : ℝ => (r : K)) '' Set.Ioo 0 1, (fun r : ℝ => (r : K)) '' Set.Ioo 2 3]
  have hs : ∀ i, (s i).Infinite := by
    intro i
    fin_cases i
    · exact (Set.Ioo_infinite (by norm_num)).image RCLike.ofReal_injective.injOn
    · exact (Set.Ioo_infinite (by norm_num)).image RCLike.ofReal_injective.injOn
  have key : ∀ x ∈ Set.pi Set.univ s, eval x A = 0 ∧ eval x B = 0 := by
    intro x hx
    obtain ⟨y, ⟨hy0, hy1⟩, hyx⟩ := hx 0 (Set.mem_univ _)
    obtain ⟨z, ⟨hz0, hz1⟩, hzx⟩ := hx 1 (Set.mem_univ _)
    set w := Real.sqrt (z ^ 2 - y ^ 2)
    have hw : w ^ 2 = z ^ 2 - y ^ 2 := Real.sq_sqrt (by nlinarith)
    have hwpos : 0 < w := Real.sqrt_pos.2 (by nlinarith)
    have hwK : (w : K) ^ 2 + x 0 ^ 2 - x 1 ^ 2 = 0 := by
      have := congrArg (fun r : ℝ => (r : K)) hw
      rw [← hyx, ← hzx]
      push_cast at this
      linear_combination this
    have E : ∀ c : K, c ^ 2 = (w : K) ^ 2 → eval x A + c * eval x B = 0 := by
      intro c hc
      have := h (Fin.cons c x) (by
        simp only [map_add, map_sub, map_pow, eval_X]
        change c ^ 2 + x 0 ^ 2 - x 1 ^ 2 = 0
        rw [hc]; exact hwK)
      simpa [eval_rename, Fin.cons_comp_succ] using this
    have E1 := E (w : K) rfl
    have E2 := E (-(w : K)) (by ring)
    have hw0 : (w : K) ≠ 0 := RCLike.ofReal_ne_zero.2 hwpos.ne'
    have hB : (w : K) * eval x B = 0 := by
      have : (2 : K) * ((w : K) * eval x B) = 0 := by linear_combination E1 - E2
      exact (mul_eq_zero.1 this).resolve_left two_ne_zero
    have hB' : eval x B = 0 := (mul_eq_zero.1 hB).resolve_left hw0
    refine ⟨?_, hB'⟩
    linear_combination E1 - (w : K) * hB'
  refine ⟨funext_set s hs fun x hx => ?_, funext_set s hs fun x hx => ?_⟩
  · rw [(key x hx).1, map_zero]
  · rw [(key x hx).2, map_zero]


/-- The card's main claim. Let V be the variety of a system f₁, …, fₛ of polynomials over a field
k. Two polynomials g and h give the same class in the coordinate ring k[V] = k[x₁, …, xₙ]/I(V)
exactly when they agree at every point of V; and k[V] is the ring of polynomial functions on V:
sending each class to the function it defines on V is a ring isomorphism onto those functions,
with nothing lost and nothing doubled. -/
theorem same_function_on_variety_iff_same_class_in_coordinate_ring
    {k : Type*} [Field k] {n s : ℕ} (f : Fin s → MvPolynomial (Fin n) k) :
    let V : Set (Fin n → k) := zeroLocus k (Ideal.span (Set.range f))
    (∀ g h : MvPolynomial (Fin n) k,
      (Ideal.Quotient.mk (vanishingIdeal k V) g = Ideal.Quotient.mk (vanishingIdeal k V) h ↔
        ∀ a ∈ V, eval a g = eval a h)) ∧
    ∃ e : (MvPolynomial (Fin n) k ⧸ vanishingIdeal k V) ≃+*
        (RingHom.pi fun a : V => (eval (a : Fin n → k) : MvPolynomial (Fin n) k →+* k)).range,
      ∀ g : MvPolynomial (Fin n) k,
        ((e (Ideal.Quotient.mk (vanishingIdeal k V) g) : V → k) = fun a : V => eval (a : Fin n → k) g) := by
  intro V
  refine ⟨fun g h => ?_, ?_⟩
  · rw [Ideal.Quotient.eq, mem_vanishingIdeal_iff]
    simp only [aeval_eq_eval, map_sub, sub_eq_zero]
  · set φ := (RingHom.pi fun a : V => (eval (a : Fin n → k) : MvPolynomial (Fin n) k →+* k))
    have hker : RingHom.ker φ = vanishingIdeal k V := by
      ext p
      simp only [RingHom.mem_ker, mem_vanishingIdeal_iff, aeval_eq_eval, φ]
      constructor
      · intro h a ha
        exact congrFun h ⟨a, ha⟩
      · intro h
        funext a
        exact h a a.2
    exact ⟨(Ideal.quotEquivOfEq hker.symm).trans (RingHom.quotientKerEquivRange φ),
      fun g => rfl⟩

/-- The theorem proved on the card: over the real or the complex numbers, the polynomials that
vanish at every point of the cone x² + y² = z² are exactly the multiples of x² + y² − z²,
that is I(V(f)) = ⟨f⟩ for f = x² + y² − z². -/
theorem cone_vanishing_ideal_eq_multiples_of_equation {K : Type*} [RCLike K] :
    vanishingIdeal K (zeroLocus K (Ideal.span {(X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) K)}))
      = Ideal.span {(X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) K)} := by
  apply le_antisymm
  · intro g hg
    obtain ⟨q, A, B, rfl⟩ := cone_division g
    have hAB := cone_standard_zero A B (fun a ha => by
      have := (mem_vanishingIdeal_iff.1 hg) a ((cone_mem_iff a).2 ha)
      rw [aeval_eq_eval, map_add, map_mul, ha, mul_zero, zero_add] at this
      exact this)
    obtain ⟨rfl, rfl⟩ := hAB
    simp only [map_zero, mul_zero, add_zero]
    exact Ideal.mul_mem_left _ _ (Ideal.mem_span_singleton_self _)
  · exact le_vanishingIdeal_zeroLocus _

/-- The standard form on the cone, over the real or the complex numbers: every polynomial
function on the cone x² + y² = z² is A(y, z) + x·B(y, z) for exactly one pair of polynomials
A and B in y and z. -/
theorem cone_function_has_unique_standard_form {K : Type*} [RCLike K]
    (g : MvPolynomial (Fin 3) K) :
    ∃! p : MvPolynomial (Fin 2) K × MvPolynomial (Fin 2) K,
      ∀ a ∈ (zeroLocus K (Ideal.span {(X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) K)}) :
          Set (Fin 3 → K)),
        eval a g = eval a (rename Fin.succ p.1 + X 0 * rename Fin.succ p.2) := by
  obtain ⟨q, A, B, hg⟩ := cone_division g
  refine ⟨(A, B), fun a ha => ?_, fun p hp => ?_⟩
  · rw [hg, map_add, map_mul, (cone_mem_iff a).1 ha, mul_zero, zero_add]
  · have hz := cone_standard_zero (p.1 - A) (p.2 - B) (fun a ha => by
      have h1 := hp a ((cone_mem_iff a).2 ha)
      have h2 : eval a g = eval a (rename Fin.succ A + X 0 * rename Fin.succ B) := by
        rw [hg, map_add, map_mul, ha, mul_zero, zero_add]
      simp only [map_add, map_mul, map_sub] at h1 h2 ⊢
      linear_combination h2 - h1)
    exact Prod.ext (sub_eq_zero.1 hz.1) (sub_eq_zero.1 hz.2)

/-! Worked numbers from the card, checked exactly. x = X 0, y = X 1, z = X 2. -/

-- The squared distance reduces in one swap: x² + y² + z² − 2z² = 1 · (x² + y² − z²).
example : (X 0 ^ 2 + X 1 ^ 2 + X 2 ^ 2 - 2 * X 2 ^ 2 : MvPolynomial (Fin 3) ℤ)
    = 1 * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2) := by ring

-- A second formula: 2x² + 2y² − 2z² = 2 · (x² + y² − z²), the same function 2z².
example : (2 * X 0 ^ 2 + 2 * X 1 ^ 2 - 2 * X 2 ^ 2 : MvPolynomial (Fin 3) ℤ)
    = 2 * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2) := by ring

-- (9, 12, 15) is on the cone, and there x² + y² + z² = 81 + 144 + 225 = 450 = 2 × 15².
example : (9 : ℤ) ^ 2 + 12 ^ 2 = 15 ^ 2 := by norm_num
example : (81 : ℤ) + 144 + 225 = 450 ∧ (2 : ℤ) * 15 ^ 2 = 450 := by norm_num

-- On the wall z = 3 the squared distance is 2 × 3² = 18.
example : (2 : ℤ) * 3 ^ 2 = 18 := by norm_num

-- A hidden member of I(V): x⁴ − x²z² − y⁴ + y²z² = (x² − y²)(x² + y² − z²).
example : (X 0 ^ 4 - X 0 ^ 2 * X 2 ^ 2 - X 1 ^ 4 + X 1 ^ 2 * X 2 ^ 2 : MvPolynomial (Fin 3) ℤ)
    = (X 0 ^ 2 - X 1 ^ 2) * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2) := by ring

-- x² + z² against 2z²: 18 and 18 at (3, 0, 3), but 9 and 18 at (0, 3, 3).
example : (3 : ℤ) ^ 2 + 3 ^ 2 = 2 * 3 ^ 2 ∧ (0 : ℤ) ^ 2 + 3 ^ 2 = 9 ∧ (2 : ℤ) * 3 ^ 2 = 18 := by
  norm_num

-- Functions of degree at most d, for d = 0 to 5: (d+1)(d+2)/2 + d(d+1)/2 = (d+1)² = C(d+3, 3) − C(d+1, 3),
-- giving 1, 4, 9, 16, 25, 36.
example : ∀ d ∈ Finset.range 6,
    (d + 1) * (d + 2) / 2 + d * (d + 1) / 2 = (d + 1) ^ 2 ∧
      (d + 1) ^ 2 = Nat.choose (d + 3) 3 - Nat.choose (d + 1) 3 := by decide
example : (List.range 6).map (fun d => (d + 1) ^ 2) = [1, 4, 9, 16, 25, 36] := by decide

-- Degree at most 2: 10 monomials minus 1 multiple of f leaves 9 functions.
example : Nat.choose 5 3 = 10 ∧ Nat.choose 5 3 - Nat.choose 3 3 = 9 := by decide

-- A wall z = 3 + c·y with c = p/q, put into f and multiplied by q².
example (p q x y : ℚ) (hq : q ≠ 0) :
    q ^ 2 * (x ^ 2 + y ^ 2 - (3 + p / q * y) ^ 2)
      = q ^ 2 * x ^ 2 + (q ^ 2 - p ^ 2) * y ^ 2 - 6 * p * q * y - 9 * q ^ 2 := by
  field_simp; ring

-- c = 1/2: 4x² + 3y² − 12y − 36, an ellipse; x = 0 at y = −2 and y = 6, so z = 2 and z = 6.
example (x y : ℚ) : 4 * (x ^ 2 + y ^ 2 - (3 + y / 2) ^ 2) = 4 * x ^ 2 + 3 * y ^ 2 - 12 * y - 36 := by
  ring
example : (3 : ℚ) * (-2) ^ 2 - 12 * (-2) - 36 = 0 ∧ (3 : ℚ) * 6 ^ 2 - 12 * 6 - 36 = 0 := by norm_num
example : (3 : ℚ) + (-2) / 2 = 2 ∧ (3 : ℚ) + 6 / 2 = 6 := by norm_num

-- The ellipse's ends are at squared distances 2 · 2² = 8 and 2 · 6² = 72 from the bulb.
example : (2 : ℤ) * 2 ^ 2 = 8 ∧ (2 : ℤ) * 6 ^ 2 = 72 := by norm_num

-- c = 1: x² − 6y − 9 meets x = 0 at y = −3/2; c = 2: x² − 3y² − 12y − 9 at y = −3 and −1;
-- c = 3/2: 4x² − 5y² − 36y − 36 at y = −6 and −6/5.
example : -6 * (-3 / 2 : ℚ) - 9 = 0 := by norm_num
example : -3 * (-3 : ℚ) ^ 2 - 12 * (-3) - 9 = 0 ∧ -3 * (-1 : ℚ) ^ 2 - 12 * (-1) - 9 = 0 := by
  norm_num
example : -5 * (-6 : ℚ) ^ 2 - 36 * (-6) - 36 = 0 ∧ -5 * (-6 / 5 : ℚ) ^ 2 - 36 * (-6 / 5) - 36 = 0 := by
  norm_num

-- Points on the cone over F₃, F₅ and F₇: 9, 25 and 49.
example : (Finset.univ.filter fun a : ZMod 3 × ZMod 3 × ZMod 3 =>
    a.1 ^ 2 + a.2.1 ^ 2 = a.2.2 ^ 2).card = 9 := by decide
example : (Finset.univ.filter fun a : ZMod 5 × ZMod 5 × ZMod 5 =>
    a.1 ^ 2 + a.2.1 ^ 2 = a.2.2 ^ 2).card = 25 := by decide
example : (Finset.univ.filter fun a : ZMod 7 × ZMod 7 × ZMod 7 =>
    a.1 ^ 2 + a.2.1 ^ 2 = a.2.2 ^ 2).card = 49 := by decide

-- Over F₃, x³ − x is zero at every point of the cone ...
example : ∀ x y z : ZMod 3, x ^ 2 + y ^ 2 = z ^ 2 → x ^ 3 - x = 0 := by decide

-- ... and its standard form is −xy² + xz² − x, since x³ − x = x·f + (−xy² + xz² − x).
example : (X 0 ^ 3 - X 0 : MvPolynomial (Fin 3) ℤ)
    = X 0 * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2) + (-(X 0 * X 1 ^ 2) + X 0 * X 2 ^ 2 - X 0) := by ring

end AffineVarietiesCard

open AffineVarietiesCard

#print axioms same_function_on_variety_iff_same_class_in_coordinate_ring
#print axioms cone_vanishing_ideal_eq_multiples_of_equation
#print axioms cone_function_has_unique_standard_form
#print axioms cone_mem_iff
#print axioms finSuccEquiv_rename_succ
#print axioms cone_division
#print axioms cone_standard_zero
