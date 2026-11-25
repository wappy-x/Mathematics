-- P/poly: if a coin-flipping test errs on each n-bit input with chance below 2^-n, then one coin string is right on every input (Adleman's counting step), and the card's mod 2 table test has exactly (2^k - 1)(2^k - 2) such coin strings of k columns.
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.ZMod.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

theorem helper_bad_sum_bound (n m : ℕ)
    (L : (Fin n → Bool) → Bool) (M : (Fin n → Bool) → (Fin m → Bool) → Bool) :
    (Finset.univ.filter (fun r => ¬ ∀ x, M x r = L x)).card ≤
      ∑ x, (Finset.univ.filter (fun r => M x r ≠ L x)).card := by
  classical
  refine le_trans (Finset.card_le_card ?_) Finset.card_biUnion_le
  intro r hr
  simp only [Finset.mem_filter, Finset.mem_univ, true_and, not_forall] at hr
  obtain ⟨x, hx⟩ := hr
  simp only [Finset.mem_biUnion, Finset.mem_univ, Finset.mem_filter, true_and]
  exact ⟨x, hx⟩

#print axioms helper_bad_sum_bound

theorem helper_mulVec_kernel_line :
    ∀ E : Matrix (Fin 2) (Fin 2) (ZMod 2), E ≠ 0 →
      (∀ u : Fin 2 → ZMod 2, E.mulVec u = 0 → u 0 = 0) ∨
      (∀ u : Fin 2 → ZMod 2, E.mulVec u = 0 → u 1 = 0) ∨
      (∀ u : Fin 2 → ZMod 2, E.mulVec u = 0 → u 0 = u 1) := by
  decide

#print axioms helper_mulVec_kernel_line

theorem helper_mulVec_witnesses :
    (∀ u : Fin 2 → ZMod 2, u 0 = 0 → (!![1, 0; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec u = 0) ∧
    (∀ u : Fin 2 → ZMod 2, u 1 = 0 → (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec u = 0) ∧
    (∀ u : Fin 2 → ZMod 2, u 0 = u 1 → (!![1, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec u = 0) ∧
    (!![1, 0; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)) ≠ 0 ∧
    (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)) ≠ 0 ∧
    (!![1, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)) ≠ 0 := by
  decide

#print axioms helper_mulVec_witnesses

theorem helper_good_iff (k : ℕ) (r : Fin k → Fin 2 → ZMod 2) :
    (∀ E : Matrix (Fin 2) (Fin 2) (ZMod 2), E ≠ 0 → ∃ i, E.mulVec (r i) ≠ 0) ↔
      ((fun i => r i 0) ≠ 0 ∧ (fun i => r i 1) ≠ 0 ∧ (fun i => r i 0) ≠ (fun i => r i 1)) := by
  obtain ⟨w0, w1, w2, n0, n1, n2⟩ := helper_mulVec_witnesses
  constructor
  · intro h
    refine ⟨fun ha => ?_, fun hb => ?_, fun hab => ?_⟩
    · obtain ⟨i, hi⟩ := h _ n0
      exact hi (w0 _ (congrFun ha i))
    · obtain ⟨i, hi⟩ := h _ n1
      exact hi (w1 _ (congrFun hb i))
    · obtain ⟨i, hi⟩ := h _ n2
      exact hi (w2 _ (congrFun hab i))
  · rintro ⟨ha, hb, hab⟩ E hE
    by_contra hcon
    simp only [not_exists, not_not] at hcon
    rcases helper_mulVec_kernel_line E hE with h | h | h
    · exact ha (funext fun i => h _ (hcon i))
    · exact hb (funext fun i => h _ (hcon i))
    · exact hab (funext fun i => h _ (hcon i))

#print axioms helper_good_iff

theorem helper_card_pairs (k : ℕ) :
    (Finset.univ.filter (fun p : (Fin k → ZMod 2) × (Fin k → ZMod 2) =>
      p.1 ≠ 0 ∧ p.2 ≠ 0 ∧ p.1 ≠ p.2)).card = (2 ^ k - 1) * (2 ^ k - 2) := by
  classical
  have hcard : Fintype.card (Fin k → ZMod 2) = 2 ^ k := by
    simp [ZMod.card]
  rw [Finset.card_filter, Fintype.sum_prod_type]
  have inner : ∀ a : Fin k → ZMod 2,
      (∑ b : Fin k → ZMod 2, if a ≠ 0 ∧ b ≠ 0 ∧ a ≠ b then 1 else 0)
        = if a ≠ 0 then 2 ^ k - 2 else 0 := by
    intro a
    by_cases ha : a = 0
    · simp [ha]
    · rw [← Finset.card_filter]
      have : (Finset.univ.filter (fun b : Fin k → ZMod 2 => a ≠ 0 ∧ b ≠ 0 ∧ a ≠ b))
          = (Finset.univ.erase 0).erase a := by
        ext b
        simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_erase]
        constructor
        · rintro ⟨_, hb, hab⟩; exact ⟨Ne.symm hab, hb, trivial⟩
        · rintro ⟨hab, hb, -⟩; exact ⟨ha, hb, Ne.symm hab⟩
      rw [this, Finset.card_erase_of_mem (by simp [ha]), Finset.card_erase_of_mem (by simp),
        Finset.card_univ, hcard]
      simp only [ne_eq, ha, not_false_eq_true, ↓reduceIte]
      omega
  simp only [inner]
  rw [← Finset.sum_filter, Finset.sum_const, smul_eq_mul]
  congr 1
  have : (Finset.univ.filter (fun a : Fin k → ZMod 2 => a ≠ 0)) = Finset.univ.erase 0 := by
    ext a; simp
  rw [this, Finset.card_erase_of_mem (by simp), Finset.card_univ, hcard]

#print axioms helper_card_pairs

/-- Adleman's step (BPP is inside P/poly). Inputs are the bit strings x of length n, coin
strings r are the bit strings of length m, L x is the right answer and M x r is the coin-flipping
test's answer. If on every input the share of coin strings giving a wrong answer is below 2^-n
(here: the number of wrong coin strings times 2^n is less than 2^m), then some single coin string
r* is right on every input of length n, so it can be built in as the hint. -/
theorem adleman_one_coin_string_right_on_every_input (n m : ℕ)
    (L : (Fin n → Bool) → Bool) (M : (Fin n → Bool) → (Fin m → Bool) → Bool)
    (herr : ∀ x, (Finset.univ.filter (fun r => M x r ≠ L x)).card * 2 ^ n < 2 ^ m) :
    ∃ r : Fin m → Bool, ∀ x, M x r = L x := by
  by_contra h
  simp only [not_exists, not_forall] at h
  have hsum : (∑ x, (Finset.univ.filter (fun r => M x r ≠ L x)).card) * 2 ^ n
      < 2 ^ m * 2 ^ n := by
    rw [Finset.sum_mul]
    calc ∑ x, (Finset.univ.filter (fun r => M x r ≠ L x)).card * 2 ^ n
        < ∑ _x : Fin n → Bool, 2 ^ m :=
          Finset.sum_lt_sum_of_nonempty Finset.univ_nonempty (fun x _ => herr x)
      _ = 2 ^ m * 2 ^ n := by simp [Finset.sum_const, Finset.card_univ, mul_comm]
  have hlt := lt_of_mul_lt_mul_right hsum (Nat.zero_le _)
  have hbad := helper_bad_sum_bound n m L M
  have hall : (Finset.univ.filter (fun r => ¬ ∀ x, M x r = L x)) = Finset.univ := by
    apply Finset.filter_true_of_mem
    intro r _ hr
    obtain ⟨x, hx⟩ := h r
    exact hx (hr x)
  rw [hall, Finset.card_univ] at hbad
  simp only [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] at hbad
  omega

/-- The union bound in Adleman's step: if every input of length n is answered wrongly with chance
at most 2^-(n+1), then the coin strings that fool some input are at most half of all 2^m coin
strings, so at least half of them are right on every input. -/
theorem adleman_at_least_half_of_coin_strings_fool_nobody (n m : ℕ)
    (L : (Fin n → Bool) → Bool) (M : (Fin n → Bool) → (Fin m → Bool) → Bool)
    (herr : ∀ x, (Finset.univ.filter (fun r => M x r ≠ L x)).card * 2 ^ (n + 1) ≤ 2 ^ m) :
    2 ^ m ≤ 2 * (Finset.univ.filter (fun r => ∀ x, M x r = L x)).card := by
  have hsum : (2 * ∑ x, (Finset.univ.filter (fun r => M x r ≠ L x)).card) * 2 ^ n
      ≤ 2 ^ m * 2 ^ n := by
    rw [Finset.mul_sum, Finset.sum_mul]
    calc ∑ x, 2 * (Finset.univ.filter (fun r => M x r ≠ L x)).card * 2 ^ n
        ≤ ∑ _x : Fin n → Bool, 2 ^ m :=
          Finset.sum_le_sum (fun x _ => by
            have := herr x
            rw [pow_succ] at this
            have e : 2 * (Finset.univ.filter (fun r => M x r ≠ L x)).card * 2 ^ n
                = (Finset.univ.filter (fun r => M x r ≠ L x)).card * (2 ^ n * 2) := by ac_rfl
            rw [e]; exact this)
      _ = 2 ^ m * 2 ^ n := by simp [Finset.sum_const, Finset.card_univ, mul_comm]
  have hle := le_of_mul_le_mul_right hsum (Nat.two_pow_pos n)
  have hbad := helper_bad_sum_bound n m L M
  have hsplit := Finset.card_filter_add_card_filter_not
    (s := (Finset.univ : Finset (Fin m → Bool))) (fun r => ∀ x, M x r = L x)
  rw [Finset.card_univ] at hsplit
  simp only [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] at hsplit
  omega

open Classical in
/-- The table test mod 2: a run with column r passes a wrong C exactly when the error table
E = AB - C sends r to zero, and E ranges over every nonzero 2 by 2 table of bits. A coin string of
k columns is right on every input when no nonzero E sends all its columns to zero, and the number
of such coin strings, out of 4^k, is (2^k - 1)(2^k - 2). -/
theorem freivalds_mod_two_good_coin_strings (k : ℕ) :
    (Finset.univ.filter (fun r : Fin k → Fin 2 → ZMod 2 =>
      ∀ E : Matrix (Fin 2) (Fin 2) (ZMod 2), E ≠ 0 → ∃ i, E.mulVec (r i) ≠ 0)).card
      = (2 ^ k - 1) * (2 ^ k - 2) := by
  rw [← helper_card_pairs k]
  let e : (Fin k → Fin 2 → ZMod 2) ≃ (Fin k → ZMod 2) × (Fin k → ZMod 2) :=
    { toFun := fun r => (fun i => r i 0, fun i => r i 1)
      invFun := fun p i => ![p.1 i, p.2 i]
      left_inv := fun r => by
        funext i j
        fin_cases j <;> rfl
      right_inv := fun p => rfl }
  apply Finset.card_equiv e
  intro r
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  exact helper_good_iff k r

-- The adder family: 9k - 5 gates for k-bit numbers, so 13, 22 and 31 gates at 2, 3 and 4 bits.
example : (9 * 2 - 5, 9 * 3 - 5, 9 * 4 - 5) = (13, 22, 31) := by norm_num
-- Inputs of length 12: 4,096 in all, 256 with AB = C, 3,840 without (2,304 + 1,536).
example : 2 ^ 12 = 4096 ∧ 2 ^ 8 = 256 ∧ 4096 - 256 = 3840 ∧ 2304 + 1536 = 3840 := by norm_num
-- The unary circuits: both circuits on every string of lengths 1 to 12 make 16,380 runs.
example : (Finset.range 12).sum (fun i => 2 * 2 ^ (i + 1)) = 16380 := by decide
-- The union bound at n = 12: 4096 × 2^-13 = 1/2 < 1; at 12 runs it is exactly 1; at 2 runs, 1,024.
example : (4096 : ℚ) / 2 ^ 13 = 1 / 2 ∧ (4096 : ℚ) / 2 ^ 12 = 1 ∧ (4096 : ℚ) / 2 ^ 2 = 1024 := by
  norm_num
-- Good coin strings: 0 of 4 at k = 1, 6 of 16 at k = 2, 42 of 64 at k = 3.
example : ((2 ^ 1 - 1) * (2 ^ 1 - 2), (2 ^ 2 - 1) * (2 ^ 2 - 2), (2 ^ 3 - 1) * (2 ^ 3 - 2))
    = (0, 6, 42) := by norm_num
-- Bad coin strings 3·2^k - 2 out of 4^k: 10 of 16, 12,286 of 16,777,216, 24,574 of 67,108,864.
example : 4 ^ 2 - (2 ^ 2 - 1) * (2 ^ 2 - 2) = 3 * 2 ^ 2 - 2 ∧ 3 * 2 ^ 2 - 2 = 10 ∧
    4 ^ 12 - (2 ^ 12 - 1) * (2 ^ 12 - 2) = 12286 ∧ 4 ^ 12 = 16777216 ∧
    4 ^ 13 - (2 ^ 13 - 1) * (2 ^ 13 - 2) = 24574 ∧ 4 ^ 13 = 67108864 := by norm_num
-- The mistake: A = 10/00, B = 11/00, C = 00/00 has AB = 11/00 ≠ C, yet column r = 11 passes it,
-- while column r = 10 catches it.
example : (!![1, 0; 0, 0] * !![1, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)) = !![1, 1; 0, 0] ∧
    (!![1, 0; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec
      ((!![1, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec ![1, 1]) = 0 ∧
    (!![1, 0; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec
      ((!![1, 1; 0, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)).mulVec ![1, 0]) = ![1, 0] := by
  decide
-- Brute force for the self-reduction: 3 of the 16 pairs of 2-bit numbers give a + b = 4, none 7.
example : ((Finset.range 4 ×ˢ Finset.range 4).filter (fun p => p.1 + p.2 = 4)).card = 3 ∧
    ((Finset.range 4 ×ˢ Finset.range 4).filter (fun p => p.1 + p.2 = 7)).card = 0 := by decide

#print axioms adleman_one_coin_string_right_on_every_input
#print axioms adleman_at_least_half_of_coin_strings_fool_nobody
#print axioms freivalds_mod_two_good_coin_strings
