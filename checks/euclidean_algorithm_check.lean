-- Euclid's algorithm: for whole numbers a and b, not both 0, repeatedly swapping the pair for (divisor, remainder) reaches a zero remainder, and the number divided by at that moment is the biggest number dividing both a and b.
import Mathlib.Logic.Function.Iterate
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum.GCD

/-- One division of Euclid's algorithm: the pair (a, b) becomes (b, remainder of a divided by b). -/
def euclidStep (p : ℕ × ℕ) : ℕ × ℕ := (p.2, p.1 % p.2)

theorem euclidStep_gcd (p : ℕ × ℕ) : Nat.gcd (euclidStep p).1 (euclidStep p).2 = Nat.gcd p.1 p.2 := by
  obtain ⟨a, b⟩ := p
  simp only [euclidStep]
  rw [Nat.gcd_comm b (a % b), ← Nat.gcd_rec, Nat.gcd_comm]

#print axioms euclidStep_gcd

theorem euclidStep_iter_gcd (n : ℕ) (p : ℕ × ℕ) :
    Nat.gcd (euclidStep^[n] p).1 (euclidStep^[n] p).2 = Nat.gcd p.1 p.2 := by
  induction n generalizing p with
  | zero => rfl
  | succ n ih =>
    rw [Function.iterate_succ_apply, ih, euclidStep_gcd]

#print axioms euclidStep_iter_gcd

theorem euclidStep_reaches_zero (b : ℕ) : ∀ a : ℕ, ∃ n : ℕ, (euclidStep^[n] (a, b)).2 = 0 := by
  induction b using Nat.strong_induction_on with
  | _ b ih =>
    intro a
    rcases Nat.eq_zero_or_pos b with hb | hb
    · exact ⟨0, by simp [hb]⟩
    · obtain ⟨n, hn⟩ := ih (a % b) (Nat.mod_lt a hb) b
      exact ⟨n + 1, by
        rw [Function.iterate_succ_apply]
        simpa [euclidStep] using hn⟩

#print axioms euclidStep_reaches_zero

/-- Euclid's algorithm. Take two whole numbers a and b, at least one above zero. Divide, keep the
remainder, and repeat with the divisor and that remainder. After some number n of divisions a
remainder is zero (and none was zero before), and the number divided by at that moment, the last
non-zero remainder, is above zero, divides both a and b, and is at least as big as every number
dividing both: it is the greatest common divisor. -/
theorem euclid_last_nonzero_remainder_is_greatest_common_divisor (a b : ℕ) (h : 0 < a ∨ 0 < b) :
    ∃ n : ℕ, (euclidStep^[n] (a, b)).2 = 0 ∧ (∀ m < n, (euclidStep^[m] (a, b)).2 ≠ 0) ∧
      0 < (euclidStep^[n] (a, b)).1 ∧
      (euclidStep^[n] (a, b)).1 ∣ a ∧ (euclidStep^[n] (a, b)).1 ∣ b ∧
      ∀ d : ℕ, d ∣ a → d ∣ b → d ≤ (euclidStep^[n] (a, b)).1 := by
  have hex : ∃ n : ℕ, (euclidStep^[n] (a, b)).2 = 0 := euclidStep_reaches_zero b a
  have hpos : 0 < Nat.gcd a b := by
    rcases h with h | h
    · exact Nat.gcd_pos_of_pos_left _ h
    · exact Nat.gcd_pos_of_pos_right _ h
  classical
  refine ⟨Nat.find hex, Nat.find_spec hex, fun m hm => Nat.find_min hex hm, ?_⟩
  have hg := euclidStep_iter_gcd (Nat.find hex) (a, b)
  rw [Nat.find_spec hex, Nat.gcd_zero_right] at hg
  simp only at hg
  rw [hg]
  refine ⟨hpos, Nat.gcd_dvd_left a b, Nat.gcd_dvd_right a b, ?_⟩
  intro d hda hdb
  exact Nat.le_of_dvd hpos (Nat.dvd_gcd hda hdb)

/-- The swap loses nothing. If a = q × b + r, then the numbers dividing both a and b are exactly
the numbers dividing both b and r. -/
theorem common_divisors_unchanged_by_division (a b q r d : ℕ) (hdiv : a = q * b + r) :
    (d ∣ a ∧ d ∣ b) ↔ (d ∣ b ∧ d ∣ r) := by
  subst hdiv
  constructor
  · rintro ⟨h1, h2⟩
    exact ⟨h2, (Nat.dvd_add_right (Dvd.dvd.mul_left h2 q)).mp h1⟩
  · rintro ⟨h2, h3⟩
    exact ⟨Nat.dvd_add (Dvd.dvd.mul_left h2 q) h3, h2⟩

/-- Why "at least one number above zero" is needed: every whole number divides 0, so 0 and 0 have
no biggest common divisor. -/
theorem zero_and_zero_have_no_greatest_common_divisor :
    ¬ ∃ g : ℕ, ∀ d : ℕ, d ∣ 0 → d ∣ 0 → d ≤ g := by
  rintro ⟨g, hg⟩
  have := hg (g + 1) (dvd_zero _) (dvd_zero _)
  omega

-- The drums, 1071 m and 462 m: three divisions.
example : 1071 = 2 * 462 + 147 ∧ 462 = 3 * 147 + 21 ∧ 147 = 7 * 21 + 0 := by norm_num
example : euclidStep (1071, 462) = (462, 147) ∧ euclidStep (462, 147) = (147, 21) ∧
    euclidStep (147, 21) = (21, 0) := by decide
-- The run stops after 3 divisions, at 21, with no zero remainder before.
example : euclidStep^[3] (1071, 462) = (21, 0) ∧ (euclidStep^[1] (1071, 462)).2 ≠ 0 ∧
    (euclidStep^[2] (1071, 462)).2 ≠ 0 := by decide
example : Nat.gcd 1071 462 = 21 := by norm_num
-- The second road: every length up to 462 tried, and 21 is the biggest dividing both.
example : ∀ d ∈ Finset.Icc 1 462, d ∣ 1071 → d ∣ 462 → d ≤ 21 := by decide +kernel
-- Pieces at 21 m: 51 and 22, 73 in all.
example : 1071 / 21 = 51 ∧ 462 / 21 = 22 ∧ 51 + 22 = 73 := by norm_num
-- The mistakes: cut at 7 m gives 153 and 66 (219 pieces); at 3 m, 357 and 154 (511 pieces);
-- stopping at 147 m leaves 21 m stranded on the 462 m drum.
example : 1071 / 7 = 153 ∧ 462 / 7 = 66 ∧ 153 + 66 = 219 := by norm_num
example : 1071 / 3 = 357 ∧ 462 / 3 = 154 ∧ 357 + 154 = 511 := by norm_num
example : 462 % 147 = 21 ∧ ¬ (147 ∣ 462) := by decide
-- The slowest pair its size: gcd(55, 34) = 1 after 8 divisions; Lamé's ceiling 5 × 2 = 10.
example : euclidStep^[8] (55, 34) = (1, 0) ∧ (euclidStep^[7] (55, 34)).2 ≠ 0 ∧ 5 * 2 = 10 := by
  decide
-- Swap the drums: the first division leaves 462 over and flips the pair into order.
example : euclidStep (462, 1071) = (1071, 462) := by decide
-- Change 462 to 460: the last non-zero remainder is 1, so the drums are coprime.
example : Nat.gcd 1071 460 = 1 := by norm_num

#print axioms euclid_last_nonzero_remainder_is_greatest_common_divisor
#print axioms common_divisors_unchanged_by_division
#print axioms zero_and_zero_have_no_greatest_common_divisor
