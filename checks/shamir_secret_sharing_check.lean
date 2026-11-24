-- Secret sharing: over a prime field, any k shares of a polynomial of degree below k rebuild its value at 0 by Lagrange's weights, and any k − 1 shares fit exactly one choice of coefficients for every possible secret.
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Algebra.Field.ZMod
import Mathlib.Tactic.NormNum.Prime
import Mathlib.LinearAlgebra.Vandermonde
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse

open Polynomial

/-- Helper: the matrix of powers `x j ^ (i + 1)` is invertible when the positions are distinct
and never 0, since it is the diagonal of the positions times a Vandermonde matrix. -/
theorem helper_matrix_isUnit {F : Type*} [Field F] (n : ℕ) (x : Fin n → F)
    (hx : Function.Injective x) (hx0 : ∀ j, x j ≠ 0) :
    IsUnit (Matrix.of fun j (i : Fin n) => x j ^ (i.val + 1)) := by
  have hM : (Matrix.of fun j (i : Fin n) => x j ^ (i.val + 1)) =
      Matrix.diagonal x * Matrix.vandermonde x := by
    ext j i
    simp [Matrix.diagonal_mul, Matrix.vandermonde, pow_succ']
  rw [hM, Matrix.isUnit_iff_isUnit_det, Matrix.det_mul, Matrix.det_diagonal, isUnit_iff_ne_zero]
  exact mul_ne_zero (Finset.prod_ne_zero_iff.mpr fun j _ => hx0 j)
    (Matrix.det_vandermonde_ne_zero_iff.mpr hx)

#print axioms helper_matrix_isUnit

/-- Shamir's rebuilding formula. On the clock of a prime `p` hours, let `f` be the dealer's
polynomial, of degree at most `k − 1`, and let `k` officers hold the shares `(x j, f(x j))` at
distinct positions that are never 0. Then the secret `f(0)` is the weighted sum of the share
values, where the weight of share `j` is the product of `x m / (x m − x j)` over the other
shares `m`. -/
theorem shamir_secret_eq_lagrange_sum {p : ℕ} [Fact p.Prime] (k : ℕ)
    (x : Fin k → ZMod p) (hx : Function.Injective x) (hx0 : ∀ j, x j ≠ 0)
    (f : (ZMod p)[X]) (hf : f.degree < k) :
    f.eval 0 = ∑ j, f.eval (x j) * ∏ m ∈ Finset.univ.erase j, x m / (x m - x j) := by
  have hvs : Set.InjOn x (Finset.univ : Finset (Fin k)) := hx.injOn
  have hdeg : f.degree < (Finset.univ : Finset (Fin k)).card := by simpa using hf
  have h := congrArg (eval 0) (Lagrange.eq_interpolate hvs hdeg)
  rw [h]
  simp only [Lagrange.interpolate_apply, eval_finsetSum, eval_mul, eval_C, Lagrange.basis,
    eval_prod, Lagrange.basisDivisor, eval_sub, eval_X]
  refine Finset.sum_congr rfl fun j _ => ?_
  congr 1
  refine Finset.prod_congr rfl fun m _ => ?_
  rw [← neg_sub (x j) (x m), div_neg]
  ring

/-- Step 3, the secrecy claim. On the clock of a prime `p` hours, fix `k − 1` positions that are
distinct and never 0, any values `y` the officers might hold there, and any candidate secret `s`.
Exactly one choice of the random coefficients `a₁, …, a_{k−1}` makes the dealer's polynomial
`s + a₁ x + … + a_{k−1} x^{k−1}` produce those shares. So the shares are equally likely for every
secret, and they say nothing about it. -/
theorem shamir_k_sub_one_shares_fit_each_secret_once {p : ℕ} [Fact p.Prime] (k : ℕ)
    (x : Fin (k - 1) → ZMod p) (hx : Function.Injective x) (hx0 : ∀ j, x j ≠ 0)
    (y : Fin (k - 1) → ZMod p) (s : ZMod p) :
    Fintype.card {a : Fin (k - 1) → ZMod p //
      ∀ j, s + ∑ i : Fin (k - 1), a i * x j ^ (i.val + 1) = y j} = 1 := by
  set M : Matrix (Fin (k - 1)) (Fin (k - 1)) (ZMod p) :=
    Matrix.of fun j (i : Fin (k - 1)) => x j ^ (i.val + 1) with hMdef
  have hU : IsUnit M := helper_matrix_isUnit (k - 1) x hx hx0
  have key : ∀ a : Fin (k - 1) → ZMod p,
      (∀ j, s + ∑ i : Fin (k - 1), a i * x j ^ (i.val + 1) = y j) ↔
        M.mulVec a = fun j => y j - s := by
    intro a
    rw [funext_iff]
    refine forall_congr' fun j => ?_
    simp only [hMdef, Matrix.mulVec, dotProduct, Matrix.of_apply]
    rw [eq_sub_iff_add_eq, add_comm]
    simp_rw [mul_comm (x j ^ _)]
  obtain ⟨a, ha⟩ := Matrix.mulVec_surjective_iff_isUnit.mpr hU (fun j => y j - s)
  rw [Fintype.card_eq_one_iff]
  refine ⟨⟨a, (key a).mpr ha⟩, fun b => ?_⟩
  apply Subtype.ext
  exact Matrix.mulVec_injective_iff_isUnit.mpr hU (((key b.1).mp b.2).trans ha.symm)

/-- Step 1. On the clock of a prime `p` hours, two polynomials of degree at most `k − 1` that
agree at `k` distinct positions are the same polynomial. -/
theorem shamir_k_shares_fix_the_polynomial {p : ℕ} [Fact p.Prime] (k : ℕ)
    (x : Fin k → ZMod p) (hx : Function.Injective x)
    (f g : (ZMod p)[X]) (hf : f.degree < k) (hg : g.degree < k)
    (hfg : ∀ j, f.eval (x j) = g.eval (x j)) :
    f = g := by
  have hvs : Set.InjOn x (Finset.univ : Finset (Fin k)) := hx.injOn
  exact Polynomial.eq_of_degrees_lt_of_eval_index_eq _ hvs (by simpa using hf) (by simpa using hg)
    fun j _ => hfg j

-- The card's shares of f(x) = 1234 + 166x + 94x^2 on the clock of 7919 hours.
example : ((1234 + 166 * 1 + 94 * 1 ^ 2 : ℕ) : ZMod 7919) = 1494 := by decide
example : ((1234 + 166 * 2 + 94 * 2 ^ 2 : ℕ) : ZMod 7919) = 1942 := by decide
example : ((1234 + 166 * 3 + 94 * 3 ^ 2 : ℕ) : ZMod 7919) = 2578 := by decide
example : ((1234 + 166 * 4 + 94 * 4 ^ 2 : ℕ) : ZMod 7919) = 3402 := by decide
example : ((1234 + 166 * 5 + 94 * 5 ^ 2 : ℕ) : ZMod 7919) = 4414 := by decide

-- Reciprocals on the clock: 1/2 = 3960, 1/3 = 2640, 1/6 = 1320.
example : (2 * 3960 : ZMod 7919) = 1 ∧ (3 * 2640 : ZMod 7919) = 1 ∧ (6 * 1320 : ZMod 7919) = 1 := by
  decide

-- Shares 1, 2, 3 with weights 3, 7916 (that is, −3) and 1 rebuild 1234.
example : (3 * 1494 + 7916 * 1942 + 1 * 2578 : ZMod 7919) = 1234 := by decide

-- Shares 2, 4, 5: weights 20/6 = 2643, 10/(−2) = 7914, 8/3 = 5282; terms 1194, 6747, 1212; secret 1234.
example : (20 * 1320 : ZMod 7919) = 2643 ∧ (7914 : ZMod 7919) = -5 ∧ (8 * 2640 : ZMod 7919) = 5282 := by
  decide
example : (2643 * 1942 : ZMod 7919) = 1194 ∧ (7914 * 3402 : ZMod 7919) = 6747 ∧
    (5282 * 4414 : ZMod 7919) = 1212 := by
  decide
example : (2643 * 1942 + 7914 * 3402 + 5282 * 4414 : ZMod 7919) = 1234 := by decide

-- Shares 1 and 2 also fit secret 0, as 0 + 2017x + 7396x^2, and secret 4321, as 4321 + 7414x + 5597x^2.
example : (0 + 2017 * 1 + 7396 * 1 ^ 2 : ZMod 7919) = 1494 ∧ (0 + 2017 * 2 + 7396 * 2 ^ 2 : ZMod 7919) = 1942 := by
  decide
example : (4321 + 7414 * 1 + 5597 * 1 ^ 2 : ZMod 7919) = 1494 ∧
    (4321 + 7414 * 2 + 5597 * 2 ^ 2 : ZMod 7919) = 1942 := by
  decide

-- Share 2 typed as 1943 rebuilds 1231 from shares 1, 2, 3.
example : (3 * 1494 + 7916 * 1943 + 1 * 2578 : ZMod 7919) = 1231 := by decide

-- On a clock of 7920 hours, 2 has no reciprocal: 2 and 7920 share the factor 2.
example : Nat.gcd 2 7920 = 2 := by norm_num

-- 7919 is prime, and two shares give 1 chance in 7919^2 = 62,710,561.
example : Nat.Prime 7919 := by norm_num
example : 7919 ^ 2 = 62710561 := by norm_num

#print axioms shamir_secret_eq_lagrange_sum
#print axioms shamir_k_sub_one_shares_fit_each_secret_once
#print axioms shamir_k_shares_fix_the_polynomial
