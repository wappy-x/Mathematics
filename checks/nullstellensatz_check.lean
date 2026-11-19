-- The Nullstellensatz: over an algebraically closed field such as ℂ, a polynomial system in finitely many unknowns has no common solution exactly when 1 is a combination of its equations, and a polynomial vanishes at every solution exactly when some power of it is such a combination.
import Mathlib.RingTheory.Nullstellensatz
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Algebra.DualNumber
import Mathlib.Tactic.FinCases

/-! The field is `k`, algebraically closed (`IsAlgClosed k`); ℂ is the card's case.
The unknowns are `x₁, …, xₙ`, written `X 0, …, X (n-1)` in `MvPolynomial (Fin n) k`.
A system is `f : Fin s → MvPolynomial (Fin n) k`, read as the equations `f i = 0`;
a point is `x : Fin n → k`, and `eval x (f i)` is the value of `f i` there.
A combination of the equations is `∑ i, a i * f i` with polynomial multipliers `a i`.
Mathlib's `zeroLocus k I` is the variety V(I), `vanishingIdeal k V` is I(V), and
`I.radical` is √I, the polynomials with some power in I. -/

open MvPolynomial

namespace NullstellensatzCard

/-- Helper: over an algebraically closed field, V(I) is empty exactly when 1 ∈ I. -/
theorem zeroLocus_eq_empty_iff_one_mem_aux
    {k : Type*} [Field k] [IsAlgClosed k] {n : ℕ} (I : Ideal (MvPolynomial (Fin n) k)) :
    zeroLocus k I = ∅ ↔ (1 : MvPolynomial (Fin n) k) ∈ I := by
  constructor
  · intro h
    have h1 : (1 : MvPolynomial (Fin n) k) ∈ I.radical := by
      rw [← vanishingIdeal_zeroLocus_eq_radical (K := k) I, h, vanishingIdeal_empty]
      exact Submodule.mem_top
    obtain ⟨m, hm⟩ := h1
    simpa using hm
  · intro h
    have hI : I = ⊤ := (Ideal.eq_top_iff_one I).2 h
    rw [hI, zeroLocus_top]
    rfl

/-- The card's main claim. Over an algebraically closed field k (such as ℂ), with finitely many
unknowns: the system f₁ = 0, …, fₛ = 0 has no common solution exactly when 1 is a combination
a₁f₁ + ⋯ + aₛfₛ of its equations (weak form); and a polynomial g is zero at every common
solution exactly when some power g^m is such a combination (strong form). -/
theorem no_solution_iff_one_is_combination_and_vanishing_iff_power_is_combination
    {k : Type*} [Field k] [IsAlgClosed k] {n s : ℕ} (f : Fin s → MvPolynomial (Fin n) k) :
    ((¬ ∃ x : Fin n → k, ∀ i, eval x (f i) = 0) ↔
        ∃ a : Fin s → MvPolynomial (Fin n) k, ∑ i, a i * f i = 1) ∧
    ∀ g : MvPolynomial (Fin n) k,
      ((∀ x : Fin n → k, (∀ i, eval x (f i) = 0) → eval x g = 0) ↔
        ∃ m : ℕ, ∃ a : Fin s → MvPolynomial (Fin n) k, ∑ i, a i * f i = g ^ m) := by
  set I : Ideal (MvPolynomial (Fin n) k) := Ideal.span (Set.range f) with hI
  have hZ : ∀ x : Fin n → k, x ∈ zeroLocus k I ↔ ∀ i, eval x (f i) = 0 := by
    intro x
    rw [hI, zeroLocus_span]
    simp
  have hmem : ∀ p, p ∈ I ↔ ∃ a : Fin s → MvPolynomial (Fin n) k, ∑ i, a i * f i = p :=
    fun p => Ideal.mem_span_range_iff_exists_fun
  constructor
  · rw [← hmem, ← zeroLocus_eq_empty_iff_one_mem_aux I, Set.eq_empty_iff_forall_notMem]
    simp only [hZ, not_exists]
  · intro g
    have hrad := vanishingIdeal_zeroLocus_eq_radical (K := k) I
    have h1 : (∀ x : Fin n → k, (∀ i, eval x (f i) = 0) → eval x g = 0) ↔
        g ∈ vanishingIdeal k (zeroLocus k I) := by
      rw [mem_vanishingIdeal_iff]
      simp only [hZ]
      exact Iff.rfl
    rw [h1, hrad, Ideal.mem_radical_iff]
    simp only [hmem]

/-- The card's formula, for any ideal I of k[x₁, …, xₙ] with k algebraically closed:
V(I) is empty exactly when 1 ∈ I, and I(V(I)) = √I. -/
theorem zeroLocus_eq_empty_iff_one_mem_and_vanishingIdeal_zeroLocus_eq_radical
    {k : Type*} [Field k] [IsAlgClosed k] {n : ℕ} (I : Ideal (MvPolynomial (Fin n) k)) :
    (zeroLocus k I = ∅ ↔ (1 : MvPolynomial (Fin n) k) ∈ I) ∧
    vanishingIdeal k (zeroLocus k I) = I.radical := by
  exact ⟨zeroLocus_eq_empty_iff_one_mem_aux I, vanishingIdeal_zeroLocus_eq_radical I⟩

/-- System 2 over ℂ, I = ⟨y − x², y⟩ with x = X 0 and y = X 1: its only point is (0, 0),
so x vanishes on V(I); yet x is not in I, while x² is. The points know x only through its square. -/
theorem system_two_x_vanishes_not_in_ideal_square_in_ideal :
    let I : Ideal (MvPolynomial (Fin 2) ℂ) := Ideal.span {X 1 - X 0 ^ 2, X 1}
    zeroLocus ℂ I = {0} ∧ X 0 ∈ vanishingIdeal ℂ (zeroLocus ℂ I) ∧
      X 0 ∉ I ∧ X 0 ^ 2 ∈ I := by
  intro I
  have hZ : zeroLocus ℂ I = {0} := by
    ext x
    simp only [I, zeroLocus_span, Set.mem_insert_iff, Set.mem_singleton_iff, forall_eq_or_imp,
      forall_eq, Set.mem_ofPred_eq, map_sub, map_pow, aeval_X]
    constructor
    · rintro ⟨h1, h2⟩
      have h0 : x 0 = 0 := by
        rw [h2, zero_sub, neg_eq_zero] at h1
        exact pow_eq_zero_iff (two_ne_zero) |>.1 h1
      funext i
      fin_cases i
      · exact h0
      · exact h2
    · rintro rfl
      simp
  refine ⟨hZ, ?_, ?_, ?_⟩
  · rw [hZ, mem_vanishingIdeal_singleton_iff]
    simp
  · intro hx
    let φ : MvPolynomial (Fin 2) ℂ →ₐ[ℂ] DualNumber ℂ :=
      aeval (fun i : Fin 2 => if i = 0 then DualNumber.eps else 0)
    have hle : I ≤ RingHom.ker φ := by
      rw [Ideal.span_le]
      intro p hp
      simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hp
      rcases hp with rfl | rfl
      · simp [φ, DualNumber.eps_pow_two]
      · simp [φ]
    have h := hle hx
    rw [RingHom.mem_ker] at h
    have h2 : TrivSqZeroExt.snd (φ (X 0)) = (1 : ℂ) := by
      simp [φ, DualNumber.snd_eps]
    rw [h] at h2
    simp at h2
  · have : (X 0 ^ 2 : MvPolynomial (Fin 2) ℂ) = (-1) * (X 1 - X 0 ^ 2) + 1 * X 1 := by ring
    rw [this]
    exact Ideal.add_mem _ (Ideal.mul_mem_left _ _ (Ideal.subset_span (by simp)))
      (Ideal.mul_mem_left _ _ (Ideal.subset_span (by simp)))

/-! Worked numbers from the card, checked exactly. In `Fin 2`: x = X 0, y = X 1; in `Fin 3`, z = X 2. -/

-- System 1's certificate: y · (x) − (xy − 1) = 1, so x y = 1 and x = 0 have no common solution.
example : (X 1 * X 0 - (X 0 * X 1 - 1) : MvPolynomial (Fin 2) ℤ) = 1 := by ring

-- System 1 has no point over F_p for p = 2, 3, 5, 7.
example : (Finset.univ.filter fun q : ZMod 2 × ZMod 2 => q.1 * q.2 = 1 ∧ q.1 = 0).card = 0 := by decide
example : (Finset.univ.filter fun q : ZMod 3 × ZMod 3 => q.1 * q.2 = 1 ∧ q.1 = 0).card = 0 := by decide
example : (Finset.univ.filter fun q : ZMod 5 × ZMod 5 => q.1 * q.2 = 1 ∧ q.1 = 0).card = 0 := by decide
example : (Finset.univ.filter fun q : ZMod 7 × ZMod 7 => q.1 * q.2 = 1 ∧ q.1 = 0).card = 0 := by decide

-- System 2: x² = (−1)(y − x²) + (1)(y).
example : (X 0 ^ 2 : MvPolynomial (Fin 2) ℤ) = (-1) * (X 1 - X 0 ^ 2) + 1 * X 1 := by ring

-- Rabinowitsch's certificate for system 2 with f = x: 1 = (−z²)(y − x²) + (z²)(y) + (xz + 1)(1 − xz).
example : (-(X 2 ^ 2) * (X 1 - X 0 ^ 2) + X 2 ^ 2 * X 1 + (X 0 * X 2 + 1) * (1 - X 0 * X 2) :
    MvPolynomial (Fin 3) ℤ) = 1 := by ring

-- Break 1: zeros of x² + 1 over F_p for p = 2, 3, 5, 7 are 1, 0, 2, 0.
example : (Finset.univ.filter fun x : ZMod 2 => x ^ 2 + 1 = 0).card = 1 := by decide
example : (Finset.univ.filter fun x : ZMod 3 => x ^ 2 + 1 = 0).card = 0 := by decide
example : (Finset.univ.filter fun x : ZMod 5 => x ^ 2 + 1 = 0).card = 2 := by decide
example : (Finset.univ.filter fun x : ZMod 7 => x ^ 2 + 1 = 0).card = 0 := by decide

-- Break 1, real certificate: x² + (−1)(x² + 1) = −1.
example : (X 0 ^ 2 + (-1) * (X 0 ^ 2 + 1) : MvPolynomial (Fin 1) ℤ) = -1 := by ring

-- Break 2: the arm aimed 6 m away has elbow a = 41/12, b² = −385/144 on both circles.
example : ((41 : ℚ) / 12) ^ 2 + (-385 / 144) - 9 = 0 := by norm_num
example : ((41 : ℚ) / 12) ^ 2 - 12 * (41 / 12) + (-385 / 144) + 32 = 0 := by norm_num

-- Break 2: subtracting the two circle equations leaves 12a − 41 (a = X 0, b = X 1).
example : ((X 0 ^ 2 + X 1 ^ 2 - 9) - (X 0 ^ 2 - 12 * X 0 + X 1 ^ 2 + 32) : MvPolynomial (Fin 2) ℚ)
    = 12 * X 0 - 41 := by ring

-- Break 2, real certificate: (144/385)b² − (144/385)(b² + 385/144) = −1.
example : (C (144 / 385) * X 1 ^ 2 - C (144 / 385) * (X 1 ^ 2 + C (385 / 144)) :
    MvPolynomial (Fin 2) ℚ) = -1 := by
  rw [mul_add, ← sub_sub, sub_self, zero_sub, ← C_mul]; norm_num

-- The arm at 4 m: elbow a = 21/8, b² = 135/64 reaches 3 m from the shoulder.
example : ((21 : ℚ) / 8) ^ 2 + 135 / 64 = 9 := by norm_num

end NullstellensatzCard

open NullstellensatzCard

#print axioms zeroLocus_eq_empty_iff_one_mem_aux
#print axioms no_solution_iff_one_is_combination_and_vanishing_iff_power_is_combination
#print axioms zeroLocus_eq_empty_iff_one_mem_and_vanishingIdeal_zeroLocus_eq_radical
#print axioms system_two_x_vanishes_not_in_ideal_square_in_ideal
