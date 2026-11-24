-- Indices: on a prime clock p with a primitive root g, indices add when numbers multiply and a k-th power multiplies the index by k (both counted mod p - 1), so for a nonzero target a the congruence x^k ≡ a has exactly gcd(k, p - 1) nonzero answers when a^((p - 1)/gcd(k, p - 1)) ≡ 1 and none otherwise.
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.NormNum.GCD

/-- The card's main claim. On a prime clock p, take a target a that is not 0 and a power k, and
let d = gcd(k, p - 1). If a^((p - 1)/d) leaves 1, then x^k ≡ a has exactly d answers among the
nonzero remainders; otherwise it has none. -/
theorem power_congruence_has_gcd_answers_or_none (p : ℕ) [Fact p.Prime] (k : ℕ) (a : ZMod p)
    (ha : a ≠ 0) :
    (Finset.univ.filter (fun x : ZMod p => x ≠ 0 ∧ x ^ k = a)).card =
      if a ^ ((p - 1) / Nat.gcd k (p - 1)) = 1 then Nat.gcd k (p - 1) else 0 := by
  classical
  set n := p - 1 with hn
  set d := Nat.gcd k n with hd
  have hp := (Fact.out : p.Prime)
  have hn0 : 0 < n := by have := hp.two_le; omega
  have hcardG : Fintype.card (ZMod p)ˣ = n := ZMod.card_units p
  have hNcardG : Nat.card (ZMod p)ˣ = n := by rw [Nat.card_eq_fintype_card, hcardG]
  have hd0 : 0 < d := Nat.gcd_pos_of_pos_right _ hn0
  have hdn : d ∣ n := Nat.gcd_dvd_right _ _
  have hdk : d ∣ k := Nat.gcd_dvd_left _ _
  set ua : (ZMod p)ˣ := Units.mk0 a ha with hua
  -- Step A: move the count to the unit group.
  have hA : (Finset.univ.filter (fun x : ZMod p => x ≠ 0 ∧ x ^ k = a)).card =
      (Finset.univ.filter (fun u : (ZMod p)ˣ => u ^ k = ua)).card := by
    symm
    refine Finset.card_bij (fun u _ => (u : ZMod p)) ?_ ?_ ?_
    · intro u hu
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hu ⊢
      refine ⟨u.ne_zero, ?_⟩
      rw [← Units.val_pow_eq_pow_val, hu, hua, Units.val_mk0]
    · intro u _ v _ h
      exact Units.ext h
    · intro x hx
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hx
      refine ⟨Units.mk0 x hx.1, ?_, rfl⟩
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      apply Units.ext
      rw [Units.val_pow_eq_pow_val, Units.val_mk0, hx.2, hua, Units.val_mk0]
  -- The kernel count.
  have hker : (Finset.univ.filter (fun u : (ZMod p)ˣ => u ^ k = 1)).card = d := by
    have h := IsCyclic.card_powMonoidHom_ker (ZMod p)ˣ k
    rw [hNcardG, Nat.gcd_comm, ← hd] at h
    rw [← h, Nat.card_eq_fintype_card, ← Fintype.card_subtype]
    apply Fintype.card_congr
    exact Equiv.subtypeEquivRight (fun u => by simp [MonoidHom.mem_ker])
  -- The range test.
  have hrange : ua ∈ Set.range (powMonoidHom k : (ZMod p)ˣ →* (ZMod p)ˣ) ↔
      a ^ (n / d) = 1 := by
    have hconv : a ^ (n / d) = 1 ↔ ua ^ (n / d) = 1 := by
      rw [← Units.val_eq_one, Units.val_pow_eq_pow_val, hua, Units.val_mk0]
    rw [hconv]
    constructor
    · rintro ⟨u, hu⟩
      rw [← hu, powMonoidHom_apply, ← pow_mul]
      obtain ⟨k', hk'⟩ := hdk
      have : k * (n / d) = n * k' := by
        rw [hk', mul_comm d k', mul_assoc, Nat.mul_div_cancel' hdn, mul_comm]
      rw [this, pow_mul, ← hcardG, pow_card_eq_one, one_pow]
    · intro h1
      have hnd0 : 0 < n / d := Nat.div_pos (Nat.le_of_dvd hn0 hdn) hd0
      set R := (powMonoidHom k : (ZMod p)ˣ →* (ZMod p)ˣ).range
      set S := Finset.univ.filter (fun u : (ZMod p)ˣ => u ^ (n / d) = 1)
      have hS : S.card ≤ n / d := by
        have := IsCyclic.card_pow_eq_one_le (α := (ZMod p)ˣ) hnd0
        convert this
      have hRS : (R : Set (ZMod p)ˣ).toFinset ⊆ S := by
        intro v hv
        rw [Set.mem_toFinset] at hv
        obtain ⟨u, rfl⟩ := hv
        simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]
        rw [powMonoidHom_apply, ← pow_mul]
        obtain ⟨k', hk'⟩ := hdk
        have : k * (n / d) = n * k' := by
          rw [hk', mul_comm d k', mul_assoc, Nat.mul_div_cancel' hdn, mul_comm]
        rw [this, pow_mul, ← hcardG, pow_card_eq_one, one_pow]
      have hRc : (R : Set (ZMod p)ˣ).toFinset.card = n / d := by
        have := IsCyclic.card_powMonoidHom_range (ZMod p)ˣ k
        rw [hNcardG, Nat.gcd_comm] at this
        rw [← this, Set.toFinset_card, ← Nat.card_eq_fintype_card]
        rfl
      have heq := Finset.eq_of_subset_of_card_le hRS (by rw [hRc]; exact hS)
      have hmem : ua ∈ S := by simp [S, h1]
      rw [← heq, Set.mem_toFinset] at hmem
      exact hmem
  rw [hA]
  split_ifs with h
  · have hmem := hrange.mpr h
    have h1 : (1 : (ZMod p)ˣ) ∈ Set.range (powMonoidHom k : (ZMod p)ˣ →* (ZMod p)ˣ) :=
      ⟨1, by simp⟩
    have := MonoidHom.card_fiber_eq_of_mem_range
      (powMonoidHom k : (ZMod p)ˣ →* (ZMod p)ˣ) hmem h1
    simp only [powMonoidHom_apply] at this
    rw [this, hker]
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro u _ hu
    exact h (hrange.mp ⟨u, hu⟩)

/-- Indices add when numbers multiply, on a clock of size p - 1. With g a primitive root of the
prime clock p, if i is an index of a and j an index of b, then m is an index of a b exactly when
m ≡ i + j (mod p - 1). -/
theorem index_of_product_is_sum_of_indices (p : ℕ) [Fact p.Prime] (g : ZMod p)
    (hg : IsPrimitiveRoot g (p - 1)) (a b : ZMod p) (i j m : ℕ) (ha : g ^ i = a) (hb : g ^ j = b) :
    g ^ m = a * b ↔ m ≡ i + j [MOD p - 1] := by
  have hfin : IsOfFinOrder g := by
    have hp := (Fact.out : p.Prime)
    apply orderOf_pos_iff.mp
    rw [← hg.eq_orderOf]
    have := hp.two_le
    omega
  rw [← ha, ← hb, ← pow_add, hfin.pow_eq_pow_iff_modEq, ← hg.eq_orderOf]

/-- A k-th power multiplies the index by k. With g a primitive root of the prime clock p, if i
is an index of x and j an index of a, then x^k ≡ a (mod p) exactly when k i ≡ j (mod p - 1). -/
theorem power_congruence_iff_index_congruence (p : ℕ) [Fact p.Prime] (g : ZMod p)
    (hg : IsPrimitiveRoot g (p - 1)) (x a : ZMod p) (i j k : ℕ) (hx : g ^ i = x) (ha : g ^ j = a) :
    x ^ k = a ↔ k * i ≡ j [MOD p - 1] := by
  have hfin : IsOfFinOrder g := by
    have hp := (Fact.out : p.Prime)
    apply orderOf_pos_iff.mp
    rw [← hg.eq_orderOf]
    have := hp.two_le
    omega
  rw [← hx, ← ha, ← pow_mul, mul_comm i k, hfin.pow_eq_pow_iff_modEq, ← hg.eq_orderOf]

-- The index table mod 13 with base 2: the powers 2^0 .. 2^11 visit every nonzero remainder once.
example : (List.range 12).map (fun i => (2 : ZMod 13) ^ i) = [1, 2, 4, 8, 3, 6, 12, 11, 9, 5, 10, 7] := by
  decide
-- 7 x 11: indices 11 + 7 = 18 ≡ 6 (mod 12), and 2^6 = 12 = 77 mod 13.
example : 11 + 7 ≡ 6 [MOD 12] ∧ (2 : ZMod 13) ^ 6 = 12 ∧ (7 * 11 : ZMod 13) = 12 := by decide
-- 5 / 7: index 9 - 11 ≡ 10 (mod 12), 2^10 = 10, and 7 x 10 = 5.
example : 10 + 11 ≡ 9 [MOD 12] ∧ (2 : ZMod 13) ^ 10 = 10 ∧ (7 * 10 : ZMod 13) = 5 := by decide
-- x^5 ≡ 7: 5 i ≡ 11 (mod 12) at i = 7, x = 2^7 = 11, 11^5 = 7, and 11 is the only answer.
example : 5 * 7 ≡ 11 [MOD 12] ∧ (2 : ZMod 13) ^ 7 = 11 ∧ (11 : ZMod 13) ^ 5 = 7 := by decide
example : Finset.univ.filter (fun x : ZMod 13 => x ^ 5 = 7) = {11} := by decide
-- x^3 ≡ 5: 3 i ≡ 9 (mod 12) at i = 3, 7, 11; the test 5^4 = 1 passes; answers 8, 11, 7.
example : 3 * 3 ≡ 9 [MOD 12] ∧ 3 * 7 ≡ 9 [MOD 12] ∧ 3 * 11 ≡ 9 [MOD 12] ∧ (5 : ZMod 13) ^ 4 = 1 := by
  decide
example : Finset.univ.filter (fun x : ZMod 13 => x ^ 3 = 5) = {7, 8, 11} := by decide
-- x^3 ≡ 2: the test 2^4 = 3 fails, and there is no answer.
example : (2 : ZMod 13) ^ 4 = 3 ∧ Finset.univ.filter (fun x : ZMod 13 => x ^ 3 = 2) = ∅ := by decide
-- The usual mistake: working mod 13 gives x = 10, but 10^5 = 4, not 7.
example : (10 : ZMod 13) ^ 5 = 4 := by decide

#print axioms power_congruence_has_gcd_answers_or_none
#print axioms index_of_product_is_sum_of_indices
#print axioms power_congruence_iff_index_congruence
