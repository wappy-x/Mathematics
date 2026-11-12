-- Adding and subtracting: adding two whole numbers column by column with carrying, and taking a smaller number from a bigger one column by column with borrowing, always gives the right answer, and adding the change back to the bill gives back the note.
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.Tactic.NormNum

/-! Written numbers are lists of base-ten digits, ones column first, as `Nat.digits 10` gives
them: 75 is `[5, 7]`. Lining two such lists up entry by entry puts ones under ones and tens
under tens. -/

/-- Column addition with carrying, worked right to left (ones column first). In each column add
the two digits and the carry; write the ones digit of that total and carry the tens one column
left. A column missing from the shorter number counts as 0. A carry left over at the end becomes
a new column in front. -/
def addColumns : ℕ → List ℕ → List ℕ → List ℕ
  | carry, [], [] => if carry = 0 then [] else [carry]
  | carry, a :: as, [] => (a + carry) % 10 :: addColumns ((a + carry) / 10) as []
  | carry, [], b :: bs => (b + carry) % 10 :: addColumns ((b + carry) / 10) [] bs
  | carry, a :: as, b :: bs => (a + b + carry) % 10 :: addColumns ((a + b + carry) / 10) as bs

/-- Column subtraction with borrowing, worked right to left (ones column first). In each column
take the bottom digit and any borrow from the top digit. If the column is short, trade one from
the next column left down into ten here and borrow it there. A column missing from the bottom
number counts as 0. -/
def subColumns : ℕ → List ℕ → List ℕ → List ℕ
  | _, [], _ => []
  | borrow, a :: as, [] =>
      if borrow ≤ a then (a - borrow) :: subColumns 0 as []
      else (a + 10 - borrow) :: subColumns 1 as []
  | borrow, a :: as, b :: bs =>
      if b + borrow ≤ a then (a - b - borrow) :: subColumns 0 as bs
      else (a + 10 - b - borrow) :: subColumns 1 as bs

/-- Helper: column addition with any starting carry below 10. -/
theorem addColumns_digits_aux : ∀ (k m n c : ℕ), m + n ≤ k → c < 10 →
    addColumns c (Nat.digits 10 m) (Nat.digits 10 n) = Nat.digits 10 (m + n + c) := by
  intro k
  induction k with
  | zero =>
    intro m n c hk hc
    have hm : m = 0 := by omega
    have hn : n = 0 := by omega
    subst hm hn
    by_cases h : c = 0
    · subst h; simp [addColumns]
    · simp [addColumns, h, Nat.digits_of_lt 10 c h hc]
  | succ k ih =>
    intro m n c hk hc
    rcases Nat.eq_zero_or_pos m with hm | hm <;> rcases Nat.eq_zero_or_pos n with hn | hn
    · subst hm hn
      by_cases h : c = 0
      · subst h; simp [addColumns]
      · simp [addColumns, h, Nat.digits_of_lt 10 c h hc]
    · subst hm
      rw [Nat.digits_def' (by norm_num) hn]
      simp only [Nat.digits_zero, addColumns]
      have ih' := ih 0 (n / 10) ((n % 10 + c) / 10) (by omega) (by omega)
      simp only [Nat.digits_zero] at ih'
      rw [ih']
      rw [Nat.digits_def' (by norm_num) (by omega : 0 < 0 + n + c)]
      have e1 : (n % 10 + c) % 10 = (0 + n + c) % 10 := by omega
      have e2 : 0 + n / 10 + (n % 10 + c) / 10 = (0 + n + c) / 10 := by omega
      rw [e1, e2]
    · subst hn
      rw [Nat.digits_def' (by norm_num) hm]
      simp only [Nat.digits_zero, addColumns]
      have ih' := ih (m / 10) 0 ((m % 10 + c) / 10) (by omega) (by omega)
      simp only [Nat.digits_zero] at ih'
      rw [ih']
      rw [Nat.digits_def' (by norm_num) (by omega : 0 < m + 0 + c)]
      have e1 : (m % 10 + c) % 10 = (m + 0 + c) % 10 := by omega
      have e2 : m / 10 + 0 + (m % 10 + c) / 10 = (m + 0 + c) / 10 := by omega
      rw [e1, e2]
    · rw [Nat.digits_def' (by norm_num) hm, Nat.digits_def' (by norm_num) hn]
      simp only [addColumns]
      rw [ih (m / 10) (n / 10) ((m % 10 + n % 10 + c) / 10) (by omega) (by omega)]
      rw [Nat.digits_def' (by norm_num) (by omega : 0 < m + n + c)]
      have e1 : (m % 10 + n % 10 + c) % 10 = (m + n + c) % 10 := by omega
      have e2 : m / 10 + n / 10 + (m % 10 + n % 10 + c) / 10 = (m + n + c) / 10 := by omega
      rw [e1, e2]

#print axioms addColumns_digits_aux

/-- Helper: column subtraction with a borrow of 0 or 1. -/
theorem subColumns_digits_aux : ∀ (m n b : ℕ), b ≤ 1 → n + b ≤ m →
    (∀ d ∈ subColumns b (Nat.digits 10 m) (Nat.digits 10 n), d < 10) ∧
      Nat.ofDigits 10 (subColumns b (Nat.digits 10 m) (Nat.digits 10 n)) = m - n - b := by
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
    intro n b hb hnb
    rcases Nat.eq_zero_or_pos m with hm | hm
    · subst hm
      simp [subColumns]
    · rw [Nat.digits_def' (by norm_num) hm]
      rcases Nat.eq_zero_or_pos n with hn | hn
      · subst hn
        simp only [Nat.digits_zero, subColumns]
        by_cases h : b ≤ m % 10
        · simp only [h, ite_true]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) 0 0 (by omega) (by omega)
          simp only [Nat.digits_zero] at h1 h2
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega
        · simp only [h, ite_false]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) 0 1 (by omega) (by omega)
          simp only [Nat.digits_zero] at h1 h2
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega
      · rw [Nat.digits_def' (by norm_num) hn]
        simp only [subColumns]
        by_cases h : n % 10 + b ≤ m % 10
        · simp only [h, ite_true]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) (n / 10) 0 (by omega) (by omega)
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega
        · simp only [h, ite_false]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) (n / 10) 1 (by omega) (by omega)
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega

#print axioms subColumns_digits_aux

/-- Carrying gives the right answer every time: adding the written digits of any two whole
numbers column by column, ones under ones, trading ten in a column for one in the next, writes
out exactly the digits of their sum. -/
theorem column_addition_gives_the_sum (m n : ℕ) :
    addColumns 0 (Nat.digits 10 m) (Nat.digits 10 n) = Nat.digits 10 (m + n) := by
  have := addColumns_digits_aux (m + n) m n 0 le_rfl (by norm_num)
  simpa using this

/-- Borrowing gives the right answer every time the bill is no bigger than the note: taking the
written digits of the bill from those of the note column by column, trading one in a column for
ten in the next column right when a column is short, writes out a proper number (every digit
0 to 9) whose value is the note take away the bill. -/
theorem column_subtraction_gives_the_difference (note bill : ℕ) (h : bill ≤ note) :
    (∀ d ∈ subColumns 0 (Nat.digits 10 note) (Nat.digits 10 bill), d < 10) ∧
      Nat.ofDigits 10 (subColumns 0 (Nat.digits 10 note) (Nat.digits 10 bill)) = note - bill := by
  have := subColumns_digits_aux note bill 0 (by norm_num) (by omega)
  simpa using this

/-- Subtraction checks itself: when the bill is no bigger than the note, the change (the note
take away the bill) added back to the bill gives back the note. -/
theorem change_add_bill_eq_note (note bill : ℕ) (h : bill ≤ note) :
    (note - bill) + bill = note := by
  omega

-- 75 + 75 by columns: 5 + 5 is 10, write 0 carry 1; 7 + 7 + 1 is 15, write 5 carry 1 in front.
example : addColumns 0 [5, 7] [5, 7] = [0, 5, 1] := by norm_num [addColumns]
example : Nat.digits 10 150 = [0, 5, 1] := by norm_num
example : 75 + 75 = 150 := by norm_num
-- Twelve apples at 75 cents: 84 tens and 60 ones make 900 cents.
example : 12 * 7 = 84 ∧ 12 * 5 = 60 := by norm_num
example : 84 * 10 + 60 = 900 := by norm_num
example : 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 = 900 := by norm_num
-- 1000 take away 900 by columns: the thousand comes down as ten hundreds; the change is 100.
example : subColumns 0 [0, 0, 0, 1] [0, 0, 9] = [0, 0, 1, 0] := by decide
example : 1000 - 900 = 100 := by norm_num
-- The check: 100 + 900 gives back the 1000.
example : 100 + 900 = 1000 := by norm_num
-- One friend's three apples, and four shares make the whole basket.
example : 75 + 75 + 75 = 225 := by norm_num
example : 225 + 225 + 225 + 225 = 900 := by norm_num
-- The change is four quarters.
example : 25 + 25 + 25 + 25 = 100 := by norm_num

#print axioms column_addition_gives_the_sum
#print axioms column_subtraction_gives_the_difference
#print axioms change_add_bill_eq_note
