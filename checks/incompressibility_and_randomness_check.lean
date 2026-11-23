-- Incompressibility: for any fixed decompressor, at most 2^(n-c) - 1 bit strings of length n have a description shorter than n - c bits, so at least 2^n - 2^(n-c) + 1 of them are c-incompressible.
import Mathlib.Data.Set.Card
import Mathlib.Data.List.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Data.Set.Finite.List
import Mathlib.Data.Fintype.BigOperators

open Finset

/-! Files and descriptions are bit strings, `List Bool`. A decompressor `D` is any fixed
partial function from descriptions to files: `D d = some x` means `D` reads `d` and prints
`x`, and `D d = none` means `d` is not a valid description. The universal machine `U` of
the Kolmogorov complexity card is one such `D`, so the bound holds for `K` too. -/

/-- Helper: there are `2^m` bit strings of length `m`. -/
theorem ncard_length_eq (m : ℕ) : {d : List Bool | d.length = m}.ncard = 2 ^ m := by
  rw [← Nat.card_coe_set_eq]
  exact (Nat.card_eq_fintype_card (α := List.Vector Bool m)).trans (by simp [card_vector])

#print axioms ncard_length_eq

/-- Helper: there are `2^m - 1` bit strings shorter than `m`. -/
theorem ncard_length_lt (m : ℕ) : {d : List Bool | d.length < m}.ncard = 2 ^ m - 1 := by
  induction m with
  | zero => simp
  | succ k ih =>
    have hsplit : {d : List Bool | d.length < k + 1} =
        {d : List Bool | d.length < k} ∪ {d : List Bool | d.length = k} := by
      ext d; simp; omega
    have hdisj : Disjoint {d : List Bool | d.length < k} {d : List Bool | d.length = k} := by
      rw [Set.disjoint_left]; intro d h1 h2; simp at h1 h2; omega
    rw [hsplit, Set.ncard_union_eq hdisj (List.finite_length_lt Bool k)
      (List.finite_length_eq Bool k), ih, ncard_length_eq]
    have : 1 ≤ 2 ^ k := Nat.one_le_two_pow
    rw [pow_succ]; omega

#print axioms ncard_length_lt

/-- The counting bound: fix any decompressor `D` before the files are seen. Among the bit
strings `x` of length `n`, those with some description `d` shorter than `n - c` bits
(`D d = some x`, `|d| < n - c`) number at most `2^(n-c) - 1`. Counted with `encard`, so the
set's finiteness is part of the claim. -/
theorem few_files_have_a_description_shorter_than_n_minus_c
    (D : List Bool → Option (List Bool)) (n c : ℕ) :
    {x : List Bool | x.length = n ∧ ∃ d : List Bool, d.length < n - c ∧ D d = some x}.encard
      ≤ ((2 ^ (n - c) - 1 : ℕ) : ℕ∞) := by
  have hsub : {x : List Bool | x.length = n ∧ ∃ d : List Bool, d.length < n - c ∧ D d = some x}
      ⊆ (fun d => (D d).getD []) '' {d : List Bool | d.length < n - c} := by
    rintro x ⟨-, d, hd, hD⟩
    exact ⟨d, hd, by simp [hD]⟩
  calc _ ≤ _ := Set.encard_le_encard hsub
    _ ≤ _ := Set.encard_image_le _ _
    _ = _ := by
      rw [← (List.finite_length_lt Bool (n - c)).cast_ncard_eq, ncard_length_lt]

/-- Random strings abound: for any fixed decompressor `D`, at least `2^n - (2^(n-c) - 1)`
bit strings of length `n` are `c`-incompressible on `D`, meaning every description of them
is at least `n - c` bits long. With `c = 0`, at least one string of every length has no
description shorter than itself. -/
theorem many_files_are_c_incompressible
    (D : List Bool → Option (List Bool)) (n c : ℕ) :
    2 ^ n - (2 ^ (n - c) - 1)
      ≤ {x : List Bool | x.length = n ∧ ∀ d : List Bool, D d = some x → n - c ≤ d.length}.ncard := by
  set I := {x : List Bool | x.length = n ∧ ∀ d : List Bool, D d = some x → n - c ≤ d.length}
  set S := {x : List Bool | x.length = n ∧ ∃ d : List Bool, d.length < n - c ∧ D d = some x}
  have hL : {x : List Bool | x.length = n} ⊆ I ∪ S := by
    intro x hx
    by_cases h : ∀ d : List Bool, D d = some x → n - c ≤ d.length
    · exact Or.inl ⟨hx, h⟩
    · simp only [not_forall, not_le] at h
      obtain ⟨d, hD, hd⟩ := h
      exact Or.inr ⟨hx, d, hd, hD⟩
  have hSfin : S.Finite := (List.finite_length_eq Bool n).subset (fun x (hx : x ∈ S) => hx.1)
  have hS : S.ncard ≤ 2 ^ (n - c) - 1 := by
    have h := few_files_have_a_description_shorter_than_n_minus_c D n c
    rw [← hSfin.cast_ncard_eq] at h
    exact_mod_cast h
  have h1 := Set.ncard_le_ncard hL (((List.finite_length_eq Bool n).subset
    (fun x (hx : x ∈ I) => hx.1)).union hSfin)
  have h2 := Set.ncard_union_le I S
  rw [ncard_length_eq] at h1
  omega

/-- Step 1, the count of short strings: by the rules of sum and product there are `2^L`
bit strings of each length `L`, so the bit strings shorter than `m` number
`2^0 + 2^1 + ... + 2^(m-1) = 2^m - 1`. -/
theorem bit_strings_shorter_than_m_number_two_pow_m_minus_one (m : ℕ) :
    {d : List Bool | d.length < m}.ncard = 2 ^ m - 1 := by
  exact ncard_length_lt m

/-! ### The card's tiny decompressor `D` on 16-bit files

`0` then 16 bits prints the file as written. `1`, two bits choosing a period `p` of 1, 2, 4
or 8, then `p` bits of pattern, prints the pattern repeated to fill 16 bits. -/

/-- Two bits, most significant first, pick the period 1, 2, 4 or 8. -/
def tinyPeriod : Bool → Bool → ℕ
  | false, false => 1
  | false, true => 2
  | true, false => 4
  | true, true => 8

/-- The card's tiny decompressor. -/
def tinyD : List Bool → Option (List Bool)
  | false :: rest => if rest.length = 16 then some rest else none
  | true :: a :: b :: pat =>
      if pat.length = tinyPeriod a b then
        some (List.flatten (List.replicate (16 / tinyPeriod a b) pat))
      else none
  | _ => none

-- `1 01 01` (5 bits) prints 0101010101010101: period 2, pattern 01.
example : tinyD [true, false, true, false, true]
    = some [false, true, false, true, false, true, false, true,
            false, true, false, true, false, true, false, true] := by decide
-- `0` then 0110100110010110 (17 bits) prints that file as written.
example : tinyD (false :: [false, true, true, false, true, false, false, true,
                          true, false, false, true, false, true, true, false])
    = some [false, true, true, false, true, false, false, true,
            true, false, false, true, false, true, true, false] := by decide
-- The four kinds of pattern description cost 4, 5, 7 and 11 bits.
example : [1, 2, 4, 8].map (3 + ·) = [4, 5, 7, 11] := by decide

/-! ### The card's whole-number worked examples -/

-- 2^16 = 65,536 files of 16 bits.
example : 2 ^ 16 = 65536 := by norm_num
-- The sum of 2^L over lengths below 16 - c against the closed form, for c = 1, 2, 4, 8.
example : ∑ L ∈ range 15, 2 ^ L = 2 ^ 15 - 1 ∧ 2 ^ 15 - 1 = 32767 := by decide
example : ∑ L ∈ range 14, 2 ^ L = 2 ^ 14 - 1 ∧ 2 ^ 14 - 1 = 16383 := by decide
example : ∑ L ∈ range 12, 2 ^ L = 2 ^ 12 - 1 ∧ 2 ^ 12 - 1 = 4095 := by decide
example : ∑ L ∈ range 8, 2 ^ L = 2 ^ 8 - 1 ∧ 2 ^ 8 - 1 = 255 := by decide
-- Files that need 16 - c bits or more: at least 32,769, 49,153, 61,441 and 65,281.
example : 65536 - 32767 = 32769 ∧ 65536 - 16383 = 49153 ∧
    65536 - 4095 = 61441 ∧ 65536 - 255 = 65281 := by decide
-- Tiny D: files by shortest description, from the period count 2^p - 2^(p/2), cover all 65,536.
example : 2 ^ 1 = 2 ∧ 2 ^ 2 - 2 ^ 1 = 2 ∧ 2 ^ 4 - 2 ^ 2 = 12 ∧ 2 ^ 8 - 2 ^ 4 = 240 ∧
    2 ^ 16 - 2 ^ 8 = 65280 ∧ 2 + 2 + 12 + 240 + 65280 = 65536 := by decide
-- Tiny D's counts sit under the bound: 256 below 15 bits, 16 below 11 and 8 bits, 0 below 4.
example : 256 ≤ 2 ^ 15 - 1 ∧ 16 ≤ 2 ^ 11 - 1 ∧ 16 ≤ 2 ^ 8 - 1 ∧ 0 ≤ 2 ^ 4 - 1 := by decide
-- With the file built in: 257 files below 15 bits, still under 32,767.
example : 257 ≤ 32767 := by decide
-- Keeping the first 8 bits of 16: 256 outputs, 256 files share each.
example : 2 ^ 16 / 2 ^ 8 = 256 ∧ 2 ^ 8 = 256 := by decide
-- A 1,048,576-byte file is 8,388,608 bits; 1% of that is 83,886 bits, rounded down.
example : 8 * 1048576 = 8388608 ∧ 8388608 / 100 = 83886 := by norm_num
-- Zip 1: 6,932 bytes is 55,456 bits; 10% is 5,545 bits; zip 2 is 1,282 bytes larger.
example : 6932 * 8 = 55456 ∧ 55456 / 10 = 5545 ∧ 8214 - 6932 = 1282 := by norm_num
-- The other passes: 16,291 - 6,932 = 9,359; 9,758 - 8,214 = 1,544; 8,354 - 6,932 = 1,422.
example : 16291 - 6932 = 9359 ∧ 9758 - 8214 = 1544 ∧ 8354 - 6932 = 1422 := by norm_num
-- The 328-byte generator: K(text) is at most 2,624 bits.
example : 8 * 328 = 2624 := by norm_num
-- The balance description saves 1000 - cost bits: -5, 2, 24, 113, 525.
example : (1000 : ℤ) - 1005 = -5 ∧ 1000 - 998 = 2 ∧ 1000 - 976 = 24 ∧
    1000 - 887 = 113 ∧ 1000 - 475 = 525 := by norm_num
-- 10 bits suffice for the count of ones, 0 to 1000.
example : 1000 < 2 ^ 10 := by norm_num

#print axioms few_files_have_a_description_shorter_than_n_minus_c
#print axioms many_files_are_c_incompressible
#print axioms bit_strings_shorter_than_m_number_two_pow_m_minus_one
