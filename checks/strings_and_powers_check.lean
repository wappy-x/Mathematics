-- Strings with repetition: the strings of length k over n options number n^k, the functions from a k-member set into an n-member set number n^k, and the subsets of an n-member set number 2^n.
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fintype.CardEmbedding
import Mathlib.Data.Nat.Choose.Sum

open Finset

/-- When each of k positions is filled from the same n options and repeats are allowed, the
number of strings is n multiplied by itself k times: the strings of length k (lists with exactly
k entries) drawn from a finite set of options number (number of options) ^ k. -/
theorem card_strings_eq_pow {α : Type*} [Fintype α] (k : ℕ) :
    Fintype.card (List.Vector α k) = Fintype.card α ^ k := by
  exact card_vector k

/-- A string is a function: a set of k members has n^k functions into a set of n members. -/
theorem card_functions_eq_pow {α β : Type*} [DecidableEq α] [Fintype α] [Fintype β] :
    Fintype.card (α → β) = Fintype.card β ^ Fintype.card α := by
  exact Fintype.card_fun

/-- Subsets are strings of yes and no: a set of n members (the squad) has 2^n subsets (the
travelling parties), the empty one and the whole set included. -/
theorem card_subsets_eq_two_pow {α : Type*} (s : Finset α) :
    s.powerset.card = 2 ^ s.card := by
  exact Finset.card_powerset s

-- The small picture: two positions over the digits 0, 1, 2 give 3 × 3 = 9 strings.
example : (Finset.univ : Finset (Fin 2 → Fin 3)).card = 9 := by decide
example : Fintype.card (List.Vector (Fin 3) 2) = 9 := by norm_num [card_vector]

-- The empty string: filling no positions can be done exactly one way, so n^0 = 1.
example : Fintype.card (List.Vector (Fin 10) 0) = 1 := by norm_num [card_vector]

-- PIN stages, 0 to 4 positions: 1, 10, 100, 1,000, 10,000.
example : (10 : ℕ) ^ 0 = 1 ∧ (10 : ℕ) ^ 1 = 10 ∧ (10 : ℕ) ^ 2 = 100 ∧ (10 : ℕ) ^ 3 = 1000 ∧
    (10 : ℕ) ^ 4 = 10000 := by norm_num

-- A four-digit PIN: 10 options at each of 4 positions, 10^4 = 10,000 PINs.
example : Fintype.card (List.Vector (Fin 10) 4) = 10000 := by norm_num [card_vector]
example : Fintype.card (Fin 4 → Fin 10) = 10000 := by norm_num [Fintype.card_fun]

-- The plate: three letters then three digits, 26^3 × 10^3 = 17,576 × 1,000 = 17,576,000.
example : Fintype.card (List.Vector (Fin 26) 3) = 17576 := by norm_num [card_vector]
example : Fintype.card (List.Vector (Fin 10) 3) = 1000 := by norm_num [card_vector]
example : Fintype.card (List.Vector (Fin 26) 3 × List.Vector (Fin 10) 3) = 17576000 := by
  norm_num [card_vector]

-- The squad of 20, each player in or out: 2^20 = 1,048,576 travelling parties.
example : (Finset.univ : Finset (Fin 20)).powerset.card = 1048576 := by
  norm_num [Finset.card_powerset]
example : Fintype.card (Fin 20 → Bool) = 1048576 := by norm_num [Fintype.card_fun]

-- The same total by adding only: row 20 of Pascal's triangle totals 1,048,576.
example : ∑ i ∈ range 21, Nat.choose 20 i = 1048576 := by decide
example : (List.map (Nat.choose 20) (List.range 6)) = [1, 20, 190, 1140, 4845, 15504] := by decide

-- A 12-player squad both ways: 2^12 = 4,096, and row 12 totals 4,096.
example : Fintype.card (Fin 12 → Bool) = 4096 := by norm_num [Fintype.card_fun]
example : ∑ i ∈ range 13, Nat.choose 12 i = 4096 := by decide

-- A byte: 8 positions over 2 options, 2^8 = 256.
example : Fintype.card (List.Vector Bool 8) = 256 := by norm_num [card_vector]

-- Mistake 1, adding the options: 10 + 10 + 10 + 10 = 40, not 10,000.
example : 10 + 10 + 10 + 10 = (40 : ℕ) ∧ (40 : ℕ) ≠ 10 ^ 4 := by norm_num

-- Mistake 2, no digit reused: 10 × 9 × 8 × 7 = 5,040 one-to-one PINs, fewer than 10,000.
example : Fintype.card (Fin 4 ↪ Fin 10) = 5040 := by
  rw [Fintype.card_embedding_eq]; decide
example : 10 * 9 * 8 * 7 = (5040 : ℕ) ∧ (5040 : ℕ) < 10 ^ 4 := by norm_num

-- Mistake 3, options and positions swapped: 4^10 = 1,048,576, not 10^4 = 10,000.
example : (4 : ℕ) ^ 10 = 1048576 ∧ (4 : ℕ) ^ 10 ≠ 10 ^ 4 ∧ (4 : ℕ) ^ 10 = 2 ^ 20 := by norm_num

-- Mistake 4, the plate read as one 36-symbol alphabet: 36^6 = 2,176,782,336, not 17,576,000.
example : (36 : ℕ) ^ 6 = 2176782336 ∧ (36 : ℕ) ^ 6 ≠ 26 ^ 3 * 10 ^ 3 := by norm_num

#print axioms card_strings_eq_pow
#print axioms card_functions_eq_pow
#print axioms card_subsets_eq_two_pow
