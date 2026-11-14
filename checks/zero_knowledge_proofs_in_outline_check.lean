-- Zero-knowledge: Schnorr's protocol in a group of prime order q is complete, two answers to one commitment reveal the secret, and simulated transcripts match real ones exactly.
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Group
import Mathlib.Tactic.LinearCombination

/-! The setting of the card: a group `G` and a generator `g` whose powers form a cycle of
`q` elements, with `q` prime (`orderOf g = q`). Exponents work mod `q`, so the secret `x`,
the random `r`, the challenge `c` and the response `s` are elements of `ZMod q`; `g ^ a.val`
is `g` raised to the exponent `a`, read as a whole number from `0` to `q - 1`.
The bank stores `y = g ^ x`. One round: commitment `t = g ^ r`, challenge `c`,
response `s = r + c * x`. The bank accepts when `g ^ s = t * y ^ c`. -/

/-- Completeness: an honest prover always passes. For every secret `x`, every random `r`
and every challenge `c`, the response `s = r + c·x mod q` satisfies `g^s = t · y^c`
with `t = g^r` and `y = g^x`. -/
theorem schnorr_completeness {G : Type*} [Group G] {q : ℕ} [Fact q.Prime]
    (g : G) (hg : orderOf g = q) (x r c : ZMod q) :
    g ^ (r + c * x).val = g ^ r.val * (g ^ x.val) ^ c.val := by
  have hq : NeZero q := ⟨(Fact.out : q.Prime).ne_zero⟩
  rw [← pow_mul, ← pow_add, pow_eq_pow_iff_modEq, hg, ← ZMod.natCast_eq_natCast_iff]
  push_cast
  simp only [ZMod.natCast_zmod_val]
  ring

/-- Special soundness (extraction): if two different challenges `c ≠ c'` for the same
commitment `t` are both answered correctly, with responses `s` and `s'`, then the secret is
`x = (s - s') / (c - c') mod q`. -/
theorem schnorr_two_answers_reveal_secret {G : Type*} [Group G] {q : ℕ} [Fact q.Prime]
    (g : G) (hg : orderOf g = q) (x : ZMod q) (y t : G) (hy : y = g ^ x.val)
    (c c' s s' : ZMod q) (hc : c ≠ c')
    (h1 : g ^ s.val = t * y ^ c.val) (h2 : g ^ s'.val = t * y ^ c'.val) :
    x = (s - s') / (c - c') := by
  have hq : NeZero q := ⟨(Fact.out : q.Prime).ne_zero⟩
  subst hy
  rw [← pow_mul] at h1 h2
  have ht : t = g ^ ((s.val : ℤ) - ((x.val * c.val : ℕ) : ℤ)) := by
    rw [zpow_sub, zpow_natCast, zpow_natCast, h1]; group
  rw [ht, ← zpow_natCast, ← zpow_natCast, ← zpow_add, zpow_eq_zpow_iff_modEq, hg,
    ← ZMod.intCast_eq_intCast_iff] at h2
  push_cast at h2
  simp only [ZMod.natCast_zmod_val] at h2
  have hcc : c - c' ≠ 0 := sub_ne_zero.mpr hc
  rw [eq_div_iff hcc]
  linear_combination h2

/-- Honest-verifier zero knowledge: the conversation can be faked without the secret.
Listing every real transcript `(g^r, c, r + c·x)` over all `r` and `c`, and every simulated
transcript `(g^s · (y^c)⁻¹, c, s)` over all `c` and `s` (made without `x`), gives exactly the
same list, each transcript counted the same number of times. So with `r` (or `s`) and `c`
chosen uniformly at random, real and simulated transcripts have the same distribution. -/
theorem schnorr_simulator_matches_real_transcripts {G : Type*} [Group G] {q : ℕ}
    [Fact q.Prime] (g : G) (hg : orderOf g = q) (x : ZMod q) (y : G) (hy : y = g ^ x.val) :
    ((Finset.univ : Finset (ZMod q × ZMod q)).val.map
        fun rc => (g ^ rc.1.val, rc.2, rc.1 + rc.2 * x)) =
      ((Finset.univ : Finset (ZMod q × ZMod q)).val.map
        fun cs => (g ^ cs.2.val * (y ^ cs.1.val)⁻¹, cs.1, cs.2)) := by
  have hq : NeZero q := ⟨(Fact.out : q.Prime).ne_zero⟩
  let e : ZMod q × ZMod q ≃ ZMod q × ZMod q :=
    { toFun := fun rc => (rc.2, rc.1 + rc.2 * x)
      invFun := fun cs => (cs.2 - cs.1 * x, cs.1)
      left_inv := fun rc => by simp
      right_inv := fun cs => by simp }
  have hcomp : (fun rc : ZMod q × ZMod q => (g ^ rc.1.val, rc.2, rc.1 + rc.2 * x)) =
      (fun cs : ZMod q × ZMod q => (g ^ cs.2.val * (y ^ cs.1.val)⁻¹, cs.1, cs.2)) ∘ e := by
    funext rc
    simp only [Function.comp, e, Equiv.coe_fn_mk, Prod.mk.injEq, and_true]
    rw [hy, schnorr_completeness g hg x rc.1 rc.2]
    group
  rw [hcomp, ← Multiset.map_map, Multiset.map_univ_val_equiv]

/-! The card's worked numbers: p = 23, q = 11, g = 4, secret x = 7. -/

-- The powers 4^0 to 4^10 mod 23, and 4^11 = 1: a cycle of 11.
example : (List.range 11).map (fun k => (4 : ZMod 23) ^ k) =
    [1, 4, 16, 18, 3, 12, 2, 8, 9, 13, 6] := by decide
example : (4 : ZMod 23) ^ 11 = 1 := by decide
-- The bank stores y = 4^7 mod 23 = 8.
example : (4 : ZMod 23) ^ 7 = 8 := by decide
-- The laptop commits t = 4^5 mod 23 = 12.
example : (4 : ZMod 23) ^ 5 = 12 := by decide
-- The response s = 5 + 3·7 = 26, which is 4 mod 11.
example : 5 + 3 * 7 = 26 ∧ 26 % 11 = 4 := by decide
-- The check: 4^4 mod 23 = 3, 8^3 mod 23 = 6, and 12 · 6 mod 23 = 3.
example : (4 : ZMod 23) ^ 4 = 3 ∧ (8 : ZMod 23) ^ 3 = 6 ∧ (12 : ZMod 23) * 8 ^ 3 = 3 := by
  decide
-- Second challenge 8 with the same r = 5: s' = 5 + 8·7 mod 11 = 6.
example : (5 + 8 * 7) % 11 = 6 := by decide
-- Extraction: (4 - 6) mod 11 = 9, the inverse of (3 - 8) mod 11 is 2, and 9 · 2 = 7 mod 11.
example : (4 - 6 : ZMod 11) = 9 ∧ (3 - 8 : ZMod 11) * 2 = 1 ∧ (9 * 2 : ZMod 11) = 7 := by
  decide
-- Fiat-Shamir example: r = 9 gives t = 4^9 mod 23 = 13; with c = 6, s = 9 + 6·7 mod 11 = 7.
example : (4 : ZMod 23) ^ 9 = 13 ∧ (9 + 6 * 7) % 11 = 7 := by decide
-- Six rounds of q = 11 bring a cheater under 1 in a million; five are not enough.
example : 11 ^ 6 = 1771561 ∧ 10 ^ 6 < 11 ^ 6 ∧ 11 ^ 5 < 10 ^ 6 := by norm_num
-- Brute force: 4^k mod 23 first equals 8 at k = 7, the 8th try.
example : (List.range 11).findIdx (fun k => (4 : ZMod 23) ^ k = 8) = 7 := by decide

#print axioms schnorr_completeness
#print axioms schnorr_two_answers_reveal_secret
#print axioms schnorr_simulator_matches_real_transcripts
