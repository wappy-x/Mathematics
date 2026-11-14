-- Two roads and a mutation: a random test of k uniform independent draws catches a bug that shows on w of N inputs with chance 1 - (1 - w/N)^k, and on Hamming (7,4) the syndrome names every single flipped bit and agrees with nearest-codeword decoding on all 128 words.
import Mathlib.InformationTheory.Hamming
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum

open Finset

/-! ### The sampling theorem

A random test draws `k` inputs, each uniform over the `N` inputs and independent of the others.
That is the same as drawing one `k`-tuple uniformly from all `N ^ k` tuples, so the chance of an
event is the number of tuples in it divided by `N ^ k`. -/

/-- The chance that a random test of `k` inputs, each drawn uniformly and independently from all
`N` inputs, catches a bug that shows on `w` of them is `1 - (1 - w / N) ^ k`: one minus the chance
that every draw lands on an input where the bug is silent. Here the inputs are the type `α`
(`N = Fintype.card α`), the bug shows on the set `S` (`w = S.card`), and the test catches the bug
when at least one of its `k` draws lies in `S`. -/
theorem random_test_catch_probability {α : Type*} [Fintype α] [DecidableEq α]
    (S : Finset α) (k : ℕ) :
    ((univ.filter (fun f : Fin k → α => ∃ i, f i ∈ S)).card : ℝ) / (Fintype.card α : ℝ) ^ k
      = 1 - (1 - (S.card : ℝ) / Fintype.card α) ^ k := by
  have hc : (univ.filter (fun f : Fin k → α => ∃ i, f i ∈ S)).card
      = Fintype.card α ^ k - (Fintype.card α - S.card) ^ k := by
    have h1 : (univ.filter (fun f : Fin k → α => ¬ ∃ i, f i ∈ S)).card
        = (Fintype.card α - S.card) ^ k := by
      have : univ.filter (fun f : Fin k → α => ¬ ∃ i, f i ∈ S)
          = Fintype.piFinset (fun _ : Fin k => Sᶜ) := by
        ext f; simp [Fintype.mem_piFinset]
      rw [this, Fintype.card_piFinset, Finset.prod_const, Finset.card_univ, Fintype.card_fin,
        Finset.card_compl]
    have h2 := Finset.card_filter_add_card_filter_not
      (s := (univ : Finset (Fin k → α))) (fun f : Fin k → α => ∃ i, f i ∈ S)
    rw [Finset.card_univ, Fintype.card_fun, Fintype.card_fin, h1] at h2
    omega
  have hle : (Fintype.card α - S.card) ^ k ≤ Fintype.card α ^ k :=
    Nat.pow_le_pow_left (Nat.sub_le _ _) _
  have hS : S.card ≤ Fintype.card α := Finset.card_le_univ S
  rw [hc, Nat.cast_sub hle]
  push_cast [Nat.cast_sub hS]
  rcases Nat.eq_zero_or_pos (Fintype.card α) with h0 | hpos
  · rw [h0]
    rcases Nat.eq_zero_or_pos k with hk | hk
    · subst hk; simp
    · simp [zero_pow hk.ne']
  · have hN : (Fintype.card α : ℝ) ≠ 0 := by exact_mod_cast hpos.ne'
    rw [sub_div, div_self (pow_ne_zero _ hN), one_sub_div hN, div_pow]

/-! ### Hamming (7,4): the code under test

A word is 7 bits, positions 1 to 7 stored at indices 0 to 6. The data bits d1..d4 sit at
positions 3, 5, 6, 7. The three checks cover positions {1, 3, 5, 7}, {2, 3, 6, 7}, {4, 5, 6, 7}. -/

/-- A 7-bit word; position `p` (1 to 7) is stored at index `p - 1`. -/
abbrev Word := Fin 7 → ZMod 2

/-- A 4-bit message d1 d2 d3 d4. -/
abbrev Msg := Fin 4 → ZMod 2

/-- The encoder: data at positions 3, 5, 6, 7; check bit at positions 1, 2, 4. -/
def encode (m : Msg) : Word :=
  ![m 0 + m 1 + m 3, m 0 + m 2 + m 3, m 0, m 1 + m 2 + m 3, m 1, m 2, m 3]

/-- The shared read-out step: the bits at positions 3, 5, 6, 7. -/
def extract (c : Word) : Msg := ![c 2, c 4, c 5, c 6]

/-- The three check groups, as indices (position minus 1). -/
def checkGroup : Fin 3 → Finset (Fin 7) :=
  ![{0, 2, 4, 6}, {1, 2, 5, 6}, {3, 4, 5, 6}]

/-- The syndrome: the three check parities read as a binary number, low bit first. -/
def syndrome (r : Word) : ℕ :=
  ∑ j : Fin 3, (∑ i ∈ checkGroup j, r i).val * 2 ^ (j : ℕ)

/-- Flip the bit at position `p` (1 to 7); `p = 0` flips nothing. -/
def flipAt (r : Word) (p : ℕ) : Word := fun i => if (i : ℕ) + 1 = p then r i + 1 else r i

/-- Road 2: the syndrome names the bad position; flip it, then read out the data. -/
def road2 (r : Word) : Msg := extract (flipAt r (syndrome r))

/-- The syndrome of a single flip at position `p` of any codeword is `p`: checked on all
16 codewords times 7 positions, 112 one-flip words. -/
theorem syndrome_of_single_flip_is_position (m : Msg) (p : Fin 7) :
    syndrome (flipAt (encode m) ((p : ℕ) + 1)) = (p : ℕ) + 1 := by
  revert m p
  decide

/-- The two roads agree on all 128 received words: whenever the codeword for a message `m` is a
nearest codeword to `r` (no codeword differs from `r` in fewer positions), road 1 reads out `m`,
and `m` is exactly what the syndrome decoder (road 2) returns. -/
theorem two_roads_agree_on_all_words (r : Word) (m : Msg)
    (hnear : ∀ m' : Msg, hammingDist r (encode m) ≤ hammingDist r (encode m')) :
    extract (encode m) = road2 r := by
  have hdec : ∀ r : Word, encode (road2 r) = flipAt r (syndrome r) := by
    set_option maxRecDepth 20000 in decide
  have hone : ∀ r : Word, hammingDist r (flipAt r (syndrome r)) ≤ 1 := by
    set_option maxRecDepth 20000 in decide
  have hsep : ∀ m m' : Msg, hammingDist (encode m) (encode m') ≤ 2 → m = m' := by decide
  have hext : ∀ m : Msg, extract (encode m) = m := by decide
  have h1 : hammingDist r (encode (road2 r)) ≤ 1 := by rw [hdec]; exact hone r
  have h2 : hammingDist (encode m) (encode (road2 r)) ≤ 2 := by
    calc hammingDist (encode m) (encode (road2 r))
        ≤ hammingDist (encode m) r + hammingDist r (encode (road2 r)) := hammingDist_triangle _ _ _
      _ = hammingDist r (encode m) + hammingDist r (encode (road2 r)) := by rw [hammingDist_comm]
      _ ≤ 2 := by have := hnear (road2 r); omega
  rw [hext, hsep m (road2 r) h2]

/-! ### The card's worked numbers -/

/-- The pinned word 1001110. -/
def pin : Word := ![1, 0, 0, 1, 1, 1, 0]

/-- The message with bits of `x` (0 to 15), d1 the high bit. -/
def msgOf (x : ℕ) : Msg := fun i => ((x / 2 ^ (3 - (i : ℕ))) % 2 : ℕ)

-- The encoder's four basic codewords equal the columns of the Hamming card's generator matrix.
example : encode ![1, 0, 0, 0] = ![1, 1, 1, 0, 0, 0, 0] := by decide
example : encode ![0, 1, 0, 0] = ![1, 0, 0, 1, 1, 0, 0] := by decide
example : encode ![0, 0, 1, 0] = ![0, 1, 0, 1, 0, 1, 0] := by decide
example : encode ![0, 0, 0, 1] = ![1, 1, 0, 1, 0, 0, 1] := by decide

-- Check sums on 1001110 are 2, 1, 3 and the syndrome is 6.
example : (∑ i ∈ checkGroup 0, (pin i).val, ∑ i ∈ checkGroup 1, (pin i).val,
    ∑ i ∈ checkGroup 2, (pin i).val) = (2, 1, 3) := by decide
example : syndrome pin = 6 := by decide

-- Road 2: flip position 6 to get 1001100, read out 0100.
example : flipAt pin 6 = ![1, 0, 0, 1, 1, 0, 0] := by decide
example : road2 pin = ![0, 1, 0, 0] := by decide

-- Road 1: distances from 1001110 to the 16 codewords; the nearest is 1001100 (message 0100), at 1.
example : (List.range 16).map (fun x => hammingDist pin (encode (msgOf x)))
    = [4, 4, 3, 3, 1, 5, 2, 2, 5, 5, 2, 6, 4, 4, 3, 3] := by decide

-- A bug on 1 word in 128 needs 588 random draws for a 99% catch: (127/128)^588 ≤ 1/100 < (127/128)^587,
-- written with whole numbers by multiplying through by 100 · 128^k.
set_option exponentiation.threshold 600 in
example : 127 ^ 588 * 100 ≤ 128 ^ 588 ∧ 128 ^ 587 < 127 ^ 587 * 100 := by norm_num

#print axioms random_test_catch_probability
#print axioms syndrome_of_single_flip_is_position
#print axioms two_roads_agree_on_all_words
