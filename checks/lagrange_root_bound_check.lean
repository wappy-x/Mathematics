-- Lagrange's root bound: on a prime clock a whole-number polynomial of degree d reads 0 at no more than d of the numbers 0 to p - 1, so x^(p-1) - 1 splits into (x - 1)...(x - (p - 1)) and Wilson's theorem follows.
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.Coeff
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Int.ModEq
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.FieldTheory.Finite.Basic

open Polynomial

namespace LagrangeRootBound

/-- **Lagrange's root bound.** Let `p` be prime and `f` a polynomial with whole-number
coefficients whose degree on the `p`-clock is `d`: the coefficient of `x^d` is not a multiple
of `p`, and every higher coefficient is. Then `f(x) ≡ 0 (mod p)` has at most `d` roots among
`0, 1, …, p - 1`. -/
theorem lagrange_root_bound (p : ℕ) (hp : p.Prime) (f : ℤ[X]) (d : ℕ)
    (hd : ¬ (p : ℤ) ∣ f.coeff d) (htop : ∀ k, d < k → (p : ℤ) ∣ f.coeff k) :
    ((Finset.range p).filter (fun x : ℕ => (p : ℤ) ∣ f.eval (x : ℤ))).card ≤ d := by
  have := Fact.mk hp
  classical
  set g : (ZMod p)[X] := f.map (Int.castRingHom (ZMod p)) with hg
  have hgd : g.coeff d ≠ 0 := by
    rw [hg, coeff_map]
    simpa [ZMod.intCast_zmod_eq_zero_iff_dvd] using hd
  have hg0 : g ≠ 0 := fun h => hgd (by rw [h, coeff_zero])
  have hdeg : g.natDegree ≤ d := by
    rw [natDegree_le_iff_coeff_eq_zero]
    intro k hk
    rw [hg, coeff_map]
    simpa [ZMod.intCast_zmod_eq_zero_iff_dvd] using htop k (by exact_mod_cast hk)
  calc ((Finset.range p).filter (fun x : ℕ => (p : ℤ) ∣ f.eval (x : ℤ))).card
      ≤ g.roots.toFinset.card := by
        apply Finset.card_le_card_of_injOn (fun x : ℕ => (x : ZMod p))
        · intro x hx
          simp only [Finset.coe_filter, Finset.mem_range] at hx
          simp only [Finset.mem_coe, Multiset.mem_toFinset, mem_roots hg0, IsRoot.def]
          have h1 := (ZMod.intCast_zmod_eq_zero_iff_dvd _ p).2 hx.2
          have h2 : ((x : ℕ) : ZMod p) = ((x : ℤ) : ZMod p) := (Int.cast_natCast x).symm
          rw [h2, hg, eval_intCast_map]
          simpa using h1
        · intro x hx y hy hxy
          simp only [Finset.coe_filter, Finset.mem_range] at hx hy
          simpa [ZMod.natCast_eq_natCast_iff', Nat.mod_eq_of_lt hx.1, Nat.mod_eq_of_lt hy.1]
            using hxy
    _ ≤ Multiset.card g.roots := Multiset.toFinset_card_le _
    _ ≤ g.natDegree := card_roots' g
    _ ≤ d := hdeg

/-- **`x^(p-1) - 1` splits completely.** On a prime clock, every one of `1, …, p - 1` is a
root of `x^(p-1) - 1`, so it is the product `(x - 1)(x - 2)⋯(x - (p - 1))`, coefficient by
coefficient. -/
theorem X_pow_sub_one_eq_prod_X_sub (p : ℕ) [Fact p.Prime] :
    (X ^ (p - 1) - 1 : (ZMod p)[X]) = ∏ a ∈ Finset.Ico 1 p, (X - C (a : ZMod p)) := by
  classical
  have hp2 := (Fact.out : p.Prime).two_le
  have hQm : (X ^ (p - 1) - C 1 : (ZMod p)[X]).Monic := monic_X_pow_sub_C 1 (by omega)
  have hQdeg : (X ^ (p - 1) - C 1 : (ZMod p)[X]).natDegree = p - 1 := natDegree_X_pow_sub_C 1
  rw [C_1] at hQm hQdeg
  have hPm : (∏ a ∈ Finset.Ico 1 p, (X - C (a : ZMod p))).Monic :=
    monic_prod_of_monic _ _ (fun a _ => monic_X_sub_C _)
  have hPdeg : (∏ a ∈ Finset.Ico 1 p, (X - C (a : ZMod p))).natDegree = p - 1 := by
    rw [natDegree_prod_of_monic _ _ (fun a _ => monic_X_sub_C _)]
    simp only [natDegree_X_sub_C, Finset.sum_const, smul_eq_mul, mul_one, Nat.card_Ico]
  refine eq_of_monic_of_dvd_of_natDegree_le hPm hQm ?_ (by rw [hQdeg, hPdeg])
  have hmap : (Finset.Ico 1 p).val.map (fun a : ℕ => X - C (a : ZMod p)) =
      ((Finset.Ico 1 p).val.map (fun a : ℕ => (a : ZMod p))).map (fun a => X - C a) := by
    rw [Multiset.map_map]; rfl
  rw [Finset.prod_eq_multiset_prod, hmap,
    Multiset.prod_X_sub_C_dvd_iff_le_roots hQm.ne_zero, Multiset.le_iff_subset]
  · intro x hx
    obtain ⟨a, ha, rfl⟩ := Multiset.mem_map.1 hx
    have ha' : a ∈ Finset.Ico 1 p := ha
    rw [Finset.mem_Ico] at ha'
    rw [mem_roots hQm.ne_zero, IsRoot.def, eval_sub, eval_pow, eval_X, eval_one, sub_eq_zero]
    apply ZMod.pow_card_sub_one_eq_one
    rw [Ne, ZMod.natCast_eq_zero_iff]
    exact fun h => absurd (Nat.le_of_dvd (by omega) h) (by omega)
  · apply Multiset.Nodup.map_on _ (Finset.nodup _)
    intro x hx y hy hxy
    have hx' : x ∈ Finset.Ico 1 p := hx
    have hy' : y ∈ Finset.Ico 1 p := hy
    rw [Finset.mem_Ico] at hx' hy'
    simpa [ZMod.natCast_eq_natCast_iff', Nat.mod_eq_of_lt hx'.2, Nat.mod_eq_of_lt hy'.2] using hxy

/-- **Wilson's theorem, by Lagrange's route.** Comparing constant terms in the splitting of
`x^(p-1) - 1` gives `(p - 1)! ≡ -1 (mod p)` for every prime `p`. -/
theorem wilson_from_root_bound (p : ℕ) (hp : p.Prime) :
    ((p - 1).factorial : ℤ) ≡ -1 [ZMOD p] := by
  have := Fact.mk hp
  have h := congrArg (eval (0 : ZMod p)) (X_pow_sub_one_eq_prod_X_sub p)
  have hp1 : p - 1 ≠ 0 := by have := hp.two_le; omega
  rw [eval_sub, eval_pow, eval_X, eval_one, zero_pow hp1, zero_sub, eval_prod] at h
  simp only [eval_sub, eval_X, eval_C, zero_sub] at h
  rw [Finset.prod_neg, Nat.card_Ico,
    ZMod.pow_card_sub_one_eq_one (neg_ne_zero.2 one_ne_zero), one_mul] at h
  have hfac : ((p - 1).factorial : ZMod p) = ∏ a ∈ Finset.Ico 1 p, (a : ZMod p) := by
    rw [← Nat.cast_prod]
    congr 1
    have : p = p - 1 + 1 := by have := hp.two_le; omega
    conv_rhs => rw [this]
    exact (Finset.prod_Ico_id_eq_factorial _).symm
  rw [← ZMod.intCast_eq_intCast_iff]
  push_cast
  rw [hfac, ← h]

-- x^2 ≡ 1 on the 7-clock: exactly the roots 1 and 6 (6 × 6 = 36 reads 1).
example : (Finset.range 7).filter (fun x : ℕ => (7 : ℤ) ∣ (x : ℤ) ^ 2 - 1) = {1, 6} := by decide
-- x^2 ≡ 1 on the 8-clock: four roots, 1, 3, 5, 7; and (3 - 1)(3 + 1) = 8 reads 0.
example : (Finset.range 8).filter (fun x : ℕ => (8 : ℤ) ∣ (x : ℤ) ^ 2 - 1) = {1, 3, 5, 7} ∧
    (3 - 1) * (3 + 1) % 8 = 0 := by decide
-- Roots of x^2 = 1 on the clocks 3 to 16: 2 2 2 2 2 4 2 2 2 4 2 2 4 4.
example : (List.range' 3 14).map (fun n => ((Finset.range n).filter (fun x => x ^ 2 % n = 1)).card)
    = [2, 2, 2, 2, 2, 4, 2, 2, 2, 4, 2, 2, 4, 4] := by decide
-- All 294 quadratics a x^2 + b x + c on the 7-clock (a from 1 to 6) have at most 2 roots.
example : ∀ a ∈ Finset.Icc 1 6, ∀ b ∈ Finset.range 7, ∀ c ∈ Finset.range 7,
    ((Finset.range 7).filter (fun x => (a * x ^ 2 + b * x + c) % 7 = 0)).card ≤ 2 := by decide
-- Each of 1 to 6 to the sixth power reads 1 on the 7-clock.
example : ∀ x ∈ Finset.Icc 1 6, x ^ 6 % 7 = 1 := by decide
-- (x - 1)...(x - 6) multiplied out: constant term first, 720, -1764, 1624, -735, 175, -21, 1.
example : ((X - 1) * (X - 2) * (X - 3) * (X - 4) * (X - 5) * (X - 6) : ℤ[X]) =
    X ^ 6 - 21 * X ^ 5 + 175 * X ^ 4 - 735 * X ^ 3 + 1624 * X ^ 2 - 1764 * X + 720 := by ring
-- Those coefficients on the 7-clock: 6, 0, 0, 0, 0, 0, 1, which is x^6 - 1.
example : [720, -1764, 1624, -735, 175, -21, 1].map (fun c : ℤ => c % 7) = [6, 0, 0, 0, 0, 0, 1] := by
  decide
-- 6! = 720 = 103 × 7 - 1, so 6! ≡ -1 (mod 7).
example : Nat.factorial 6 = 720 ∧ (720 : ℤ) = 103 * 7 - 1 ∧ (720 : ℤ) ≡ -1 [ZMOD 7] := by decide
-- Traps: 7x^2 - 7 reads 0 at all 7 numbers, x^2 + 1 at none, and -720 reads 1.
example : ((Finset.range 7).filter (fun x : ℕ => (7 : ℤ) ∣ 7 * (x : ℤ) ^ 2 - 7)).card = 7 ∧
    ((Finset.range 7).filter (fun x : ℕ => (7 : ℤ) ∣ (x : ℤ) ^ 2 + 1)).card = 0 ∧
    (-720 : ℤ) % 7 = 1 := by decide

#print axioms lagrange_root_bound
#print axioms X_pow_sub_one_eq_prod_X_sub
#print axioms wilson_from_root_bound

end LagrangeRootBound
