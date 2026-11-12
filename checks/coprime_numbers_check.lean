-- Coprime numbers: two whole numbers have greatest common divisor 1 exactly when some whole-number mix of them equals 1, neighbours are always coprime, and a gear stepping a slots at a time round b slots meets exactly b ÷ gcd(a, b) of them, so all b when the counts are coprime.
import Mathlib.Data.Int.GCD
import Mathlib.RingTheory.Coprime.Lemmas
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Data.Int.Interval
import Mathlib.Data.Set.Card
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.NormNum.Prime

/-- Coprime is a licence to build 1. Two whole numbers a and b are coprime (their greatest common
divisor is 1) exactly when some whole-number mix of them, a × x + b × y with counts x and y that
may be negative, equals 1. -/
theorem coprime_iff_some_mix_equals_one (a b : ℤ) :
    Int.gcd a b = 1 ↔ ∃ x y : ℤ, a * x + b * y = 1 := by
  rw [← Int.isCoprime_iff_gcd_eq_one]
  constructor
  · rintro ⟨u, v, h⟩
    exact ⟨u, v, by linarith⟩
  · rintro ⟨x, y, h⟩
    exact ⟨x, y, by linarith⟩

/-- Neighbours are always coprime: for every whole number n, the only common divisor of n and
n + 1 is 1. -/
theorem neighbours_are_coprime (n : ℤ) : Int.gcd n (n + 1) = 1 := by
  rw [← Int.isCoprime_iff_gcd_eq_one]
  exact ⟨-1, 1, by ring⟩

/-- The gears. A small gear with a teeth drives a big gear with b slots, numbered 0 to b − 1.
After k turns of the small gear, tooth 0 drops into slot (k × a) mod b. Over all turns, tooth 0
meets exactly b ÷ gcd(a, b) different slots; so it meets every one of the b slots exactly when
a and b are coprime. -/
theorem slots_met_by_tooth_zero (a b : ℕ) (hb : 0 < b) :
    Set.ncard {s : ℕ | ∃ k : ℕ, k * a % b = s} = b / Nat.gcd a b ∧
      (Set.ncard {s : ℕ | ∃ k : ℕ, k * a % b = s} = b ↔ Nat.Coprime a b) := by
  have hg : 0 < Nat.gcd a b := Nat.gcd_pos_of_pos_right a hb
  have hgb : Nat.gcd a b ∣ b := Nat.gcd_dvd_right a b
  have hS : {s : ℕ | ∃ k : ℕ, k * a % b = s} =
      (fun m => Nat.gcd a b * m) '' Set.Iio (b / Nat.gcd a b) := by
    ext s
    simp only [Set.mem_ofPred_eq, Set.mem_image, Set.mem_Iio]
    constructor
    · rintro ⟨k, rfl⟩
      have hd : Nat.gcd a b ∣ k * a % b :=
        (Nat.dvd_mod_iff hgb).2 (Dvd.dvd.mul_left (Nat.gcd_dvd_left a b) k)
      obtain ⟨m, hm⟩ := hd
      refine ⟨m, ?_, hm.symm⟩
      rw [Nat.lt_div_iff_mul_lt' hgb, ← hm]
      exact Nat.mod_lt _ hb
    · rintro ⟨m, hm, rfl⟩
      rw [Nat.lt_div_iff_mul_lt' hgb] at hm
      rcases Nat.eq_zero_or_pos m with rfl | hm0
      · exact ⟨0, by simp⟩
      · have hlt : Nat.gcd a b < b := by
          calc Nat.gcd a b = Nat.gcd a b * 1 := (mul_one _).symm
            _ ≤ Nat.gcd a b * m := Nat.mul_le_mul_left _ hm0
            _ < b := hm
        obtain ⟨x, -, hx⟩ := Nat.exists_mul_mod_eq_gcd hlt
        refine ⟨x * m, ?_⟩
        calc x * m * a % b = (a * x % b) * m % b := by
              rw [Nat.mod_mul_mod]
              congr 1
              ring
          _ = Nat.gcd a b * m % b := by rw [hx]
          _ = Nat.gcd a b * m := Nat.mod_eq_of_lt hm
  have hcard : Set.ncard {s : ℕ | ∃ k : ℕ, k * a % b = s} = b / Nat.gcd a b := by
    rw [hS, Set.ncard_image_of_injective _ (fun x y h => Nat.eq_of_mul_eq_mul_left hg h)]
    have : Set.Iio (b / Nat.gcd a b) = ((Finset.range (b / Nat.gcd a b) : Finset ℕ) : Set ℕ) := by
      ext; simp
    rw [this, Set.ncard_coe_finset, Finset.card_range]
  refine ⟨hcard, ?_⟩
  rw [hcard, Nat.div_eq_self]
  constructor
  · rintro (h | h)
    · omega
    · exact h
  · intro h
    exact Or.inr h

-- The card's gears: 15 and 28 share only 1; 15 and 27 share 3.
example : Nat.gcd 15 28 = 1 ∧ Nat.Coprime 15 28 := by norm_num
example : Nat.gcd 15 27 = 3 ∧ ¬ Nat.Coprime 15 27 := by norm_num
-- The mix: seven 28s take away thirteen 15s lands on 1.
example : (28 : ℤ) * 7 - 15 * 13 = 1 := by decide
-- 15 and 27: the smallest mix is 3.
example : (27 : ℤ) * 4 - 15 * 7 = 3 := by decide
-- Counts from -9 to 9 never mix 15 and 27 to 1 or 2.
example : ∀ i ∈ Finset.Icc (-9 : ℤ) 9, ∀ j ∈ Finset.Icc (-9 : ℤ) 9,
    15 * i + 27 * j ≠ 1 ∧ 15 * i + 27 * j ≠ 2 := by decide
-- Adding alone (counts 0 to 9), 15s and 28s never make 1.
example : ∀ i ∈ Finset.range 10, ∀ j ∈ Finset.range 10, 15 * i + 28 * j ≠ 1 := by decide
-- On the 28-gear tooth 0 starts at slots 0, 15, 2, 17 and meets all 28 slots.
example : (List.range 4).map (fun k => k * 15 % 28) = [0, 15, 2, 17] := by decide
example : ((Finset.range 28).image (fun k => k * 15 % 28)).card = 28 := by decide
-- On the 27-gear tooth 0 meets only nine slots, all multiples of 3.
example : (List.range 9).map (fun k => k * 15 % 27) = [0, 15, 3, 18, 6, 21, 9, 24, 12] := by
  decide
example : (Finset.range 27).image (fun k => k * 15 % 27) = {0, 15, 3, 18, 6, 21, 9, 24, 12} := by
  decide
-- Pairings used: 15 × 28 = 420 of 420, and 15 × 9 = 135 of 405.
example : 15 * 28 = 420 ∧ 15 * 27 = 405 ∧ 15 * 9 = 135 := by decide
example : Nat.lcm 15 28 = 420 ∧ Nat.lcm 15 27 = 135 := by norm_num
-- Neighbours 27 and 28: 28 − 27 = 1, so they are coprime.
example : (28 : ℤ) - 27 = 1 ∧ Nat.Coprime 27 28 := by norm_num
-- Lowest terms: 15/27 cancels to 5/9; 15/28 does not cancel.
example : (15 : ℚ) / 27 = 5 / 9 := by norm_num
example : ((15 : ℚ) / 28).num = 15 ∧ ((15 : ℚ) / 28).den = 28 := by
  decide +kernel
-- Neither 15 nor 28 is prime, yet they are coprime.
example : ¬ Nat.Prime 15 ∧ ¬ Nat.Prime 28 ∧ Nat.Coprime 15 28 := by norm_num

#print axioms coprime_iff_some_mix_equals_one
#print axioms neighbours_are_coprime
#print axioms slots_met_by_tooth_zero
