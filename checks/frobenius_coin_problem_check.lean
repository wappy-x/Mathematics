-- The coin problem: with two coprime stamp values a and b, the amount a b - a - b cannot be paid and every larger amount can, exactly (a - 1)(b - 1)/2 amounts cannot be paid, and with counts allowed below 0, a x + b y + c z = n has answers exactly when the gcd of the three sizes divides n.
import Mathlib.Data.Int.GCD
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Zify

/-- Two payable amounts never add up to a b - a - b. -/
theorem frob_not_both (a b : ℕ) (cop : Nat.Coprime a b) (x y x' y' : ℕ) :
    (a : ℤ) * x + b * y + (a * x' + b * y') + a + b ≠ a * b := by
  intro h
  have h' : a * (x + x' + 1) + b * (y + y' + 1) = a * b := by
    have : ((a * (x + x' + 1) + b * (y + y' + 1) : ℕ) : ℤ) = ((a * b : ℕ) : ℤ) := by
      push_cast; linarith
    exact_mod_cast this
  have hd : a ∣ (y + y' + 1) * b := by
    have h1 : a ∣ a * (x + x' + 1) + b * (y + y' + 1) := h' ▸ dvd_mul_right a b
    have h2 := (Nat.dvd_add_right (dvd_mul_right a (x + x' + 1))).mp h1
    rwa [mul_comm] at h2
  have hs : a ∣ y + y' + 1 := Nat.Coprime.dvd_of_dvd_mul_right cop hd
  rcases Nat.eq_zero_or_pos a with ha | ha
  · subst ha
    rw [zero_dvd_iff] at hs
    omega
  · have hle : a ≤ y + y' + 1 := Nat.le_of_dvd (by omega) hs
    have : b * a ≤ b * (y + y' + 1) := Nat.mul_le_mul_left b hle
    nlinarith

/-- Every whole number is a x + b y with 0 ≤ x < b. -/
theorem frob_canon (a b : ℕ) (cop : Nat.Coprime a b) (hb : 0 < b) (m : ℤ) :
    ∃ x : ℕ, x < b ∧ ∃ y : ℤ, (a : ℤ) * x + b * y = m := by
  have hg := Nat.gcd_eq_gcd_ab a b
  rw [cop.gcd_eq_one] at hg
  set u := Nat.gcdA a b
  set v := Nat.gcdB a b
  have hbz : (0 : ℤ) < b := by exact_mod_cast hb
  refine ⟨((u * m) % b).toNat, ?_, a * ((u * m) / b) + v * m, ?_⟩
  · have h1 := Int.emod_lt_of_pos (u * m) hbz
    have h2 := Int.emod_nonneg (u * m) hbz.ne'
    omega
  · have h2 := Int.emod_nonneg (u * m) hbz.ne'
    rw [Int.toNat_of_nonneg h2]
    have h3 := Int.emod_add_mul_ediv (u * m) b
    push_cast at hg
    linear_combination (a : ℤ) * h3 + m * hg.symm

/-- For 0 ≤ n ≤ a b - a - b, exactly one of n and a b - a - b - n is payable. -/
theorem frob_compl (a b : ℕ) (cop : Nat.Coprime a b) (hb : 0 < b) (n m : ℕ)
    (hnm : (n : ℤ) + m = a * b - a - b) :
    (∃ x y : ℕ, a * x + b * y = m) ↔ ¬ ∃ x y : ℕ, a * x + b * y = n := by
  constructor
  · rintro ⟨x, y, hxy⟩ ⟨x', y', hxy'⟩
    apply frob_not_both a b cop x' y' x y
    have h1 : ((a * x + b * y : ℕ) : ℤ) = m := by exact_mod_cast hxy
    have h2 : ((a * x' + b * y' : ℕ) : ℤ) = n := by exact_mod_cast hxy'
    push_cast at h1 h2
    linarith
  · intro hn
    obtain ⟨x, hx, y, hxy⟩ := frob_canon a b cop hb n
    have hy : y < 0 := by
      by_contra hy
      push Not at hy
      apply hn
      refine ⟨x, y.toNat, ?_⟩
      have : ((a * x + b * y.toNat : ℕ) : ℤ) = n := by
        push_cast; rw [Int.toNat_of_nonneg hy]; exact hxy
      exact_mod_cast this
    refine ⟨b - 1 - x, (-1 - y).toNat, ?_⟩
    have : ((a * (b - 1 - x) + b * (-1 - y).toNat : ℕ) : ℤ) = m := by
      have e1 : ((b - 1 - x : ℕ) : ℤ) = b - 1 - x := by omega
      push_cast
      rw [e1, Int.toNat_of_nonneg (by omega)]
      linear_combination -hnm - hxy
    exact_mod_cast this

#print axioms frob_not_both
#print axioms frob_canon
#print axioms frob_compl

/-- The two-size theorem. When the stamp values a and b share no factor above 1, the amount
a b - a - b cannot be paid with counts of 0 or more, and every larger amount can:
5 × 7 − 5 − 7 = 23. (The difference is taken in the integers, so for a value of 1 it is −1
and every amount can be paid.) -/
theorem largest_unpayable_amount_is_ab_minus_a_minus_b (a b : ℕ) (cop : Nat.Coprime a b) :
    (¬ ∃ x y : ℕ, (a : ℤ) * x + b * y = a * b - a - b) ∧
      ∀ n : ℕ, (a : ℤ) * b - a - b < n → ∃ x y : ℕ, a * x + b * y = n := by
  refine ⟨?_, ?_⟩
  · rintro ⟨x, y, h⟩
    exact frob_not_both a b cop x y 0 0 (by push_cast; linarith)
  · intro n hn
    rcases Nat.eq_zero_or_pos b with hb | hb
    · subst hb
      have ha : a = 1 := Nat.coprime_zero_right a |>.mp cop
      exact ⟨n, 0, by subst ha; ring⟩
    · obtain ⟨x, hx, y, hxy⟩ := frob_canon a b cop hb n
      have hy : 0 ≤ y := by
        by_contra hy
        push Not at hy
        have hx' : (x : ℤ) ≤ b - 1 := by omega
        have : (a : ℤ) * x ≤ a * (b - 1) := by
          apply mul_le_mul_of_nonneg_left hx'; positivity
        nlinarith
      refine ⟨x, y.toNat, ?_⟩
      have : ((a * x + b * y.toNat : ℕ) : ℤ) = n := by
        push_cast; rw [Int.toNat_of_nonneg hy]; exact hxy
      exact_mod_cast this

/-- The gap count. When a and b share no factor above 1, only finitely many amounts cannot be
paid with counts of 0 or more, and there are exactly (a - 1)(b - 1)/2 of them:
4 × 6 / 2 = 12 for 5 and 7. -/
theorem unpayable_amounts_number_half_of_a_minus_one_times_b_minus_one (a b : ℕ)
    (cop : Nat.Coprime a b) :
    {n : ℕ | ¬ ∃ x y : ℕ, a * x + b * y = n}.Finite ∧
      {n : ℕ | ¬ ∃ x y : ℕ, a * x + b * y = n}.ncard = (a - 1) * (b - 1) / 2 := by
  classical
  rcases Nat.eq_zero_or_pos a with ha | ha
  · subst ha
    have hb : b = 1 := Nat.coprime_zero_left b |>.mp cop
    subst hb
    have : {n : ℕ | ¬ ∃ x y : ℕ, 0 * x + 1 * y = n} = ∅ := by
      ext n; simp
    rw [this]; simp
  rcases Nat.eq_zero_or_pos b with hb | hb
  · subst hb
    have ha1 : a = 1 := Nat.coprime_zero_right a |>.mp cop
    subst ha1
    have : {n : ℕ | ¬ ∃ x y : ℕ, 1 * x + 0 * y = n} = ∅ := by
      ext n; simp
    rw [this]; simp
  set N := (a - 1) * (b - 1) with hNdef
  have hN : (N : ℤ) = a * b - a - b + 1 := by
    rw [hNdef]; push_cast [Nat.cast_sub (show 1 ≤ a by omega), Nat.cast_sub (show 1 ≤ b by omega)]
    ring
  set T := (Finset.range N).filter (fun n => ¬ ∃ x y : ℕ, a * x + b * y = n) with hT
  set P := (Finset.range N).filter (fun n => ∃ x y : ℕ, a * x + b * y = n) with hP
  have hS : {n : ℕ | ¬ ∃ x y : ℕ, a * x + b * y = n} = (T : Set ℕ) := by
    ext n
    simp only [Set.mem_ofPred_eq, hT, Finset.coe_filter, Finset.mem_range]
    constructor
    · intro h
      refine ⟨?_, h⟩
      by_contra hn
      push Not at hn
      apply h
      apply (largest_unpayable_amount_is_ab_minus_a_minus_b a b cop).2 n
      have : (N : ℤ) ≤ n := by exact_mod_cast hn
      linarith
    · exact fun h => h.2
  rw [hS]
  refine ⟨Finset.finite_toSet T, ?_⟩
  rw [Set.ncard_coe_finset]
  have hsum : P.card + T.card = N := by
    rw [hP, hT]; simpa using Finset.card_filter_add_card_filter_not
      (s := Finset.range N) (fun n => ∃ x y : ℕ, a * x + b * y = n)
  have key : ∀ n, n < N → ((((N - 1 - n : ℕ) : ℤ) + n = a * b - a - b) ∧
      ((n : ℤ) + ((N - 1 - n : ℕ) : ℤ) = a * b - a - b)) := by
    intro n hn
    have : ((N - 1 - n : ℕ) : ℤ) = N - 1 - n := by omega
    constructor <;> linarith
  have hTP : T.card = P.card := by
    apply Finset.card_nbij' (fun n => N - 1 - n) (fun n => N - 1 - n)
    · intro n hn
      simp only [hT, hP, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn ⊢
      refine ⟨by omega, ?_⟩
      exact (frob_compl a b cop hb n (N - 1 - n) (key n hn.1).2).mpr hn.2
    · intro n hn
      simp only [hT, hP, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn ⊢
      refine ⟨by omega, ?_⟩
      intro h
      exact (frob_compl a b cop hb (N - 1 - n) n (key n hn.1).1).mp hn.2 h
    · intro n hn
      simp only [hT, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn
      show N - 1 - (N - 1 - n) = n
      omega
    · intro n hn
      simp only [hP, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn
      show N - 1 - (N - 1 - n) = n
      omega
  omega

/-- Three sizes with counts allowed below 0: a x + b y + c z = n has whole-number answers
exactly when the greatest common divisor of the three sizes divides n. -/
theorem three_sizes_solvable_iff_gcd_dvd (a b c n : ℤ) :
    (∃ x y z : ℤ, a * x + b * y + c * z = n) ↔ ((Int.gcd (Int.gcd a b) c : ℤ) ∣ n) := by
  set g := Int.gcd (Int.gcd a b) c
  constructor
  · rintro ⟨x, y, z, h⟩
    rw [← h]
    have hgd : (g : ℤ) ∣ (Int.gcd a b : ℤ) := Int.gcd_dvd_left _ _
    have hgc : (g : ℤ) ∣ c := Int.gcd_dvd_right _ _
    have hga : (g : ℤ) ∣ a := hgd.trans (Int.gcd_dvd_left _ _)
    have hgb : (g : ℤ) ∣ b := hgd.trans (Int.gcd_dvd_right _ _)
    exact dvd_add (dvd_add (hga.mul_right x) (hgb.mul_right y)) (hgc.mul_right z)
  · rintro ⟨k, hk⟩
    have h1 := Int.gcd_eq_gcd_ab a b
    have h2 := Int.gcd_eq_gcd_ab (Int.gcd a b : ℤ) c
    refine ⟨Int.gcdA a b * Int.gcdA (Int.gcd a b) c * k,
      Int.gcdB a b * Int.gcdA (Int.gcd a b) c * k, Int.gcdB (Int.gcd a b) c * k, ?_⟩
    rw [hk]
    linear_combination (-(k : ℤ)) * h2 - (Int.gcdA (Int.gcd a b) c * k) * h1

-- Stamps of 5 and 7: up to 23, the amounts that cannot be paid are exactly these 12.
-- (Counts of 24 or more of either stamp overshoot 23, so searching counts below 24 is complete.)
example : (Finset.range 24).filter
      (fun n => ¬ ∃ x ∈ Finset.range 24, ∃ y ∈ Finset.range 24, 5 * x + 7 * y = n)
    = {1, 2, 3, 4, 6, 8, 9, 11, 13, 16, 18, 23} := by decide

-- The formula and the count for 5 and 7.
example : 5 * 7 - 5 - 7 = 23 := by norm_num
example : (5 - 1) * (7 - 1) / 2 = 12 := by norm_num

-- From 24 on: five amounts in a row, one per row, and adding 5s covers the rest.
example : 24 = 2 * 5 + 2 * 7 ∧ 25 = 5 * 5 ∧ 26 = 1 * 5 + 3 * 7 ∧ 27 = 4 * 5 + 1 * 7 ∧ 28 = 4 * 7 := by
  norm_num

-- The doorsteps: the piles 0, 7, 14, 21, 28 of 7s land in rows 0, 2, 4, 1, 3; one 5 below 28 is 23.
example : [0, 7, 14, 21, 28].map (· % 5) = [0, 2, 4, 1, 3] := by decide
example : 4 * 7 - 5 = 23 := by norm_num

-- The usual mistakes: the product 35 is seven 5s, and 4 × 6 = 24 forgets to halve.
example : 5 * 7 = 7 * 5 + 0 * 7 ∧ (5 - 1) * (7 - 1) = 24 := by norm_num

-- Allowing a stamp handed back makes every amount work: 3 × 5 − 2 × 7 = 1.
example : (3 : ℤ) * 5 - 2 * 7 = 1 := by norm_num

-- Boxes of 6, 9 and 20: 43 cannot be made, and 44 to 49 (one per row of 6) can.
example : ¬ ∃ x ∈ Finset.range 8, ∃ y ∈ Finset.range 5, ∃ z ∈ Finset.range 3,
    6 * x + 9 * y + 20 * z = 43 := by decide
example : 44 = 4 * 6 + 20 ∧ 45 = 5 * 9 ∧ 46 = 6 + 2 * 20 ∧ 47 = 3 * 9 + 20 ∧ 48 = 8 * 6 ∧
    49 = 9 + 2 * 20 := by norm_num

-- The box doorsteps 0, 49, 20, 9, 40, 29 land in rows 0 to 5; one 6 below 49 is 43.
example : [0, 49, 20, 9, 40, 29].map (· % 6) = [0, 1, 2, 3, 4, 5] := by decide
example : 49 - 6 = 43 := by norm_num

-- Bezout twice for 6, 9 and 20, and the gcds of 6, 9, 20 and of 6, 9, 15.
example : (6 : ℤ) * (-1) + 9 * 1 = 3 ∧ (3 : ℤ) * 7 + 20 * (-1) = 1 ∧
    (6 : ℤ) * (-7) + 9 * 7 + 20 * (-1) = 1 := by norm_num
example : Int.gcd (Int.gcd 6 9) 20 = 1 ∧ Int.gcd (Int.gcd 6 9) 15 = 3 := by decide

#print axioms largest_unpayable_amount_is_ab_minus_a_minus_b
#print axioms unpayable_amounts_number_half_of_a_minus_one_times_b_minus_one
#print axioms three_sizes_solvable_iff_gcd_dvd
