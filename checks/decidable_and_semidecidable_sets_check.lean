-- Decidable and semidecidable: a set is decidable exactly when it and its complement are both semidecidable, the halting set is semidecidable but not decidable and its complement cannot be listed, and the dovetailing schedule visits every step slot exactly once.
import Mathlib.Computability.Halting
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

open Nat.Partrec (Code)

/-- **Post's theorem.** A set `L` of program texts (any type with a computable numbering) is
decidable, meaning one program always halts and answers whether `w ∈ L`, exactly when `L` is
semidecidable and its complement `Lᶜ` is semidecidable too. -/
theorem decidable_iff_semidecidable_and_compl_semidecidable {α : Type*} [Primcodable α]
    (L : Set α) :
    ComputablePred (fun w => w ∈ L) ↔
      REPred (fun w => w ∈ L) ∧ REPred (fun w => w ∈ Lᶜ) := by
  exact ComputablePred.computable_iff_re_compl_re'

/-- **A listable set that is not decidable, whose complement cannot be listed.** For programs
(Mathlib's codes for partial recursive functions) on a fixed input `n`, the set of programs that
halt is semidecidable, it is not decidable, and so the set of programs that never halt is not
semidecidable. This is the card's verdict on its HELLO set, carried by the halting problem that
the card's reduction starts from. -/
theorem halting_set_semidecidable_not_decidable_compl_not_semidecidable (n : ℕ) :
    REPred (fun c : Code => (c.eval n).Dom) ∧
      ¬ ComputablePred (fun c : Code => (c.eval n).Dom) ∧
      ¬ REPred (fun c : Code => ¬ (c.eval n).Dom) := by
  exact ⟨ComputablePred.halting_problem_re n, ComputablePred.halting_problem n,
    ComputablePred.halting_problem_not_re n⟩

/-- The dovetailing schedule: program `i` takes its step `t` at stage `s = i + t - 1`, in step
slot `W(i, t) = (s - 1) s / 2 + i`. -/
def slot (i t : ℕ) : ℕ := (i + t - 2) * (i + t - 1) / 2 + i

theorem slot_tri_succ (n : ℕ) : (n + 1) * (n + 1 + 1) / 2 = n * (n + 1) / 2 + (n + 1) := by
  have h : (n + 1) * (n + 1 + 1) = n * (n + 1) + (n + 1) * 2 := by ring
  rw [h, Nat.add_mul_div_right _ _ (by norm_num)]

theorem slot_tri_mono {m n : ℕ} (h : m ≤ n) : m * (m + 1) / 2 ≤ n * (n + 1) / 2 :=
  Nat.div_le_div_right (Nat.mul_le_mul h (Nat.add_le_add_right h 1))

theorem slot_succ_succ (a b : ℕ) :
    slot (a + 1) (b + 1) = (a + b) * (a + b + 1) / 2 + (a + 1) := by
  unfold slot
  have h1 : a + 1 + (b + 1) - 2 = a + b := by omega
  have h2 : a + 1 + (b + 1) - 1 = a + b + 1 := by omega
  rw [h1, h2]

theorem slot_diag_lt {k k' a : ℕ} (hk : k < k') (ha : a ≤ k) :
    k * (k + 1) / 2 + (a + 1) ≤ k' * (k' + 1) / 2 := by
  have h := slot_tri_mono (Nat.succ_le_of_lt hk)
  rw [Nat.succ_eq_add_one, slot_tri_succ] at h
  omega

#print axioms slot_tri_succ
#print axioms slot_tri_mono
#print axioms slot_succ_succ
#print axioms slot_diag_lt

/-- **Dovetailing reaches every cell, once.** Every step slot `w ≥ 1` is the slot `W(i, t)` of
exactly one cell, program `i ≥ 1` at its step `t ≥ 1`; so walking the grid one diagonal at a
time reaches every (program, step) pair after finitely many slots, and never visits one twice. -/
theorem dovetail_slot_bijective (w : ℕ) (hw : 1 ≤ w) :
    ∃! p : ℕ × ℕ, 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ slot p.1 p.2 = w := by
  have hex : ∃ k, w ≤ (k + 1) * (k + 1 + 1) / 2 := by
    refine ⟨w, ?_⟩
    rw [Nat.le_div_iff_mul_le (by norm_num)]
    nlinarith
  classical
  let k := Nat.find hex
  have hk : w ≤ (k + 1) * (k + 1 + 1) / 2 := Nat.find_spec hex
  have hlow : k * (k + 1) / 2 < w := by
    rcases Nat.eq_zero_or_eq_succ_pred k with h0 | hs
    · rw [h0]; simp; omega
    · have hmin := Nat.find_min hex (show k.pred < k by omega)
      have e : k.pred + 1 = k := by omega
      rw [e] at hmin
      omega
  rw [slot_tri_succ] at hk
  refine ⟨(w - k * (k + 1) / 2 - 1 + 1, k - (w - k * (k + 1) / 2 - 1) + 1), ⟨by simp, by simp, ?_⟩, ?_⟩
  · simp only
    rw [slot_succ_succ]
    have e : w - k * (k + 1) / 2 - 1 + (k - (w - k * (k + 1) / 2 - 1)) = k := by omega
    rw [e]
    omega
  · rintro ⟨i, t⟩ ⟨hi, ht, hs⟩
    simp only at hi ht hs
    obtain ⟨a, rfl⟩ : ∃ a, i = a + 1 := ⟨i - 1, by omega⟩
    obtain ⟨b, rfl⟩ : ∃ b, t = b + 1 := ⟨t - 1, by omega⟩
    rw [slot_succ_succ] at hs
    have hkk : a + b = k := by
      rcases lt_trichotomy (a + b) k with h | h | h
      · have := slot_diag_lt h (Nat.le_add_right a b)
        omega
      · exact h
      · have := slot_diag_lt h (show w - k * (k + 1) / 2 - 1 ≤ k by omega)
        omega
    rw [hkk] at hs
    ext <;> simp only <;> omega

/-! ### The card's worked numbers -/

-- The grid table in Step 2: the order in which the lister visits each cell.
example : [slot 1 1, slot 1 2, slot 2 1, slot 1 3, slot 2 2, slot 3 1,
    slot 1 4, slot 2 3, slot 3 2, slot 4 1] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] := by decide

-- `-[-]!` is program 2,304, prints at step 513, at stage 2,816 and step slot 3,965,824.
example : 2 + 2 * 255 + 1 = 513 := by norm_num
example : 2304 + 513 - 1 = 2816 := by norm_num
example : 2815 * 2816 / 2 = 3963520 := by norm_num
example : 3963520 + 2304 = 3965824 := by norm_num
example : slot 2304 513 = 3965824 := by decide

-- Program numbers: 948 programs shorter than 5 symbols, and 948 + 1,356 = 2,304.
example : 5 + 26 + 140 + 777 = 948 := by norm_num
example : 948 + 1356 = 2304 := by norm_num
example : 5 + 26 + 140 + 777 + 4425 = 5373 := by norm_num

/-- Symbols in the card's order `+ - < > [ ] !`, as `0` to `6`: `[` is `4`, `]` is `5`. -/
def depthStep : Option ℕ → Fin 7 → Option ℕ
  | none, _ => none
  | some d, c =>
    if c = 4 then some (d + 1) else if c = 5 then (if d = 0 then none else some (d - 1)) else some d

/-- A program is a string whose brackets match: depth never below 0, ends at 0. -/
def wellFormed (p : List (Fin 7)) : Bool := p.foldl depthStep (some 0) == some 0

/-- All strings of length `n`, in alphabet order. -/
def strings : ℕ → List (List (Fin 7))
  | 0 => [[]]
  | n + 1 => (strings n).flatMap fun p => (List.finRange 7).map fun c => p ++ [c]

/-- The queue: programs of lengths 1 to `n`, by length, then alphabet. -/
def queue (n : ℕ) : List (List (Fin 7)) :=
  (List.range n).flatMap fun k => (strings (k + 1)).filter wellFormed

-- There are 5, 26, 140, 777 and 4,425 programs of lengths 1 to 5: 5,373 in all.
example : ((List.range 5).map fun k => ((strings (k + 1)).filter wellFormed).length) =
    [5, 26, 140, 777, 4425] := by decide +kernel
example : (queue 5).length = 5373 := by decide +kernel

-- `!` is program 5, `+[]` is program 52, and `-[-]!` is program 2,304.
example : (queue 5).idxOf [6] + 1 = 5 := by decide +kernel
example : (queue 5).idxOf [0, 4, 5] + 1 = 52 := by decide +kernel
example : (queue 5).idxOf [1, 4, 1, 5, 6] + 1 = 2304 := by decide +kernel

#print axioms decidable_iff_semidecidable_and_compl_semidecidable
#print axioms halting_set_semidecidable_not_decidable_compl_not_semidecidable
#print axioms dovetail_slot_bijective
