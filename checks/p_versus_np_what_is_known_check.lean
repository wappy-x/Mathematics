-- P versus NP: one stage of the oracle construction fools every machine that asks fewer than 2^L questions, the factoring formula has 3b^2 variables and 20b^2 - 22b + 2 clauses, 2^n beats n^3 from n = 10 on, and the card's whole-number examples are exact.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Card
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Data.Fintype.BigOperators

/-- One stage of the Baker-Gill-Solovay oracle B (the first barrier, relativisation).
An oracle is a set of strings of length L, written as a yes/no function on `Fin L → Bool`.
A deterministic machine's answer `run A` may depend on the oracle A. Run on the empty
oracle, it asks the questions in Q, at most L^i of them, and 2^L > L^i. So its answer is
unchanged on any oracle that also says no to every question in Q. Then some oracle B,
holding at most one string, makes the machine answer "does B hold a string of length L?"
wrongly. -/
theorem oracle_stage_fools_machine (L i : ℕ)
    (run : ((Fin L → Bool) → Bool) → Bool) (Q : Finset (Fin L → Bool))
    (hQ : Q.card ≤ L ^ i) (hL : L ^ i < 2 ^ L)
    (hrun : ∀ A : (Fin L → Bool) → Bool, (∀ q ∈ Q, A q = false) →
      run A = run (fun _ => false)) :
    ∃ B : (Fin L → Bool) → Bool,
      (∀ s t, B s = true → B t = true → s = t) ∧
      ¬ (run B = true ↔ ∃ s, B s = true) := by
  have hcard : Q.card < (Finset.univ : Finset (Fin L → Bool)).card := by
    rw [Finset.card_univ, Fintype.card_fun, Fintype.card_bool, Fintype.card_fin]
    omega
  obtain ⟨s0, -, hs0⟩ := Finset.exists_mem_notMem_of_card_lt_card hcard
  by_cases h0 : run (fun _ => false) = true
  · refine ⟨fun _ => false, ?_, ?_⟩
    · intro s t hs; simp at hs
    · simp [h0]
  · refine ⟨fun t => decide (t = s0), ?_, ?_⟩
    · intro s t hs ht
      simp only [decide_eq_true_eq] at hs ht
      rw [hs, ht]
    · have hB : run (fun t => decide (t = s0)) = run (fun _ => false) := by
        apply hrun
        intro q hq
        simp only [decide_eq_false_iff_not]
        rintro rfl
        exact hs0 hq
      rw [hB]
      simp [h0]

/-- The factoring formula's size, counted by hand on the card. With b ≥ 2 bits per factor:
variables = 2b inputs + b^2 partial products + (b - 1) rows of 2b adder outputs = 3b^2, and
clauses = 4b^2 (AND gates) + (16b - 16) (row 1) + (b - 2)(16b - 8) (later rows)
+ 2b (product bits) + 2 (p ≥ 2, q ≥ 2) = 20b^2 - 22b + 2. -/
theorem factor_formula_size (b : ℕ) (hb : 2 ≤ b) :
    2 * b + b ^ 2 + (b - 1) * (2 * b) = 3 * b ^ 2 ∧
    4 * b ^ 2 + (16 * b - 16) + (b - 2) * (16 * b - 8) + 2 * b + 2
      = 20 * b ^ 2 - 22 * b + 2 := by
  obtain ⟨c, rfl⟩ : ∃ c, b = c + 2 := ⟨b - 2, by omega⟩
  have e1 : c + 2 - 1 = c + 1 := by omega
  have e2 : 16 * (c + 2) - 16 = 16 * c + 16 := by omega
  have e3 : c + 2 - 2 = c := by omega
  have e4 : 16 * (c + 2) - 8 = 16 * c + 24 := by omega
  have e5 : 20 * (c + 2) ^ 2 = (20 * c ^ 2 + 58 * c + 36) + 22 * (c + 2) := by ring
  have e6 : 20 * (c + 2) ^ 2 - 22 * (c + 2) = 20 * c ^ 2 + 58 * c + 36 := by omega
  rw [e1, e2, e3, e4, e6]
  constructor <;> ring

/-- Brute force passes a polynomial budget for good: from n = 10 on, n^3 < 2^n. -/
theorem cube_lt_two_pow (n : ℕ) (hn : 10 ≤ n) : n ^ 3 < 2 ^ n := by
  induction n, hn using Nat.le_induction with
  | base => norm_num
  | succ k hk ih =>
    have h1 : 3 * k ^ 2 + 3 * k + 1 ≤ k ^ 3 := by nlinarith
    calc (k + 1) ^ 3 = k ^ 3 + (3 * k ^ 2 + 3 * k + 1) := by ring
      _ ≤ k ^ 3 + k ^ 3 := by omega
      _ < 2 ^ k + 2 ^ k := by omega
      _ = 2 ^ (k + 1) := by ring

-- The oracle stage at L = 10: the machine asks 1,023 of the 1,024 strings.
example : 2 ^ 10 - 1 < 2 ^ 10 ∧ 2 ^ 10 = 1024 := by norm_num

-- Factoring 60,491 with b = 8 bits per factor.
example : 60491 < 2 ^ 16 ∧ 2 ^ 16 = 65536 := by norm_num
example : 3 * 8 ^ 2 = 192 := by norm_num
example : 20 * 8 ^ 2 - 22 * 8 + 2 = 1106 ∧ 20 * 8 ^ 2 = 1280 ∧ 22 * 8 = 176 := by norm_num
example : 251 * 241 = 60491 := by norm_num
example : 60491 % 241 = 0 ∧ 60491 / 241 = 251 := by norm_num

-- A 2048-bit RSA key, b = 1024.
example : 3 * 1024 ^ 2 = 3145728 := by norm_num
example : 20 * 1024 ^ 2 - 22 * 1024 + 2 = 20948994 := by norm_num

-- The smaller key in "Try changing": b = 4, N = 143 = 11 × 13.
example : 3 * 4 ^ 2 = 48 ∧ 20 * 4 ^ 2 - 22 * 4 + 2 = 234 ∧ 11 * 13 = 143 := by norm_num

-- The budget table, and the crossing point.
example : 2 ^ 10 = 1024 ∧ 10 ^ 3 = 1000 := by norm_num
example : 2 ^ 20 = 1048576 ∧ 20 ^ 3 = 8000 := by norm_num
example : 2 ^ 40 = 1099511627776 ∧ 40 ^ 3 = 64000 := by norm_num
example : 2 ^ 60 = 1152921504606846976 ∧ 60 ^ 3 = 216000 := by norm_num
example : 2 ^ 9 = 512 ∧ 9 ^ 3 = 729 ∧ 2 ^ 9 < 9 ^ 3 := by norm_num

-- Brute force over 12 rota bits tries 4,096 settings.
example : 2 ^ 12 = 4096 := by norm_num

#print axioms oracle_stage_fools_machine
#print axioms factor_formula_size
#print axioms cube_lt_two_pow
