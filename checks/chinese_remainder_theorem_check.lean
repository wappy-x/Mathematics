-- The Chinese remainder theorem: when no two cycle lengths share a factor, every set of day numbers is read on exactly one day of the combined cycle, two days read the same exactly when they differ by whole combined cycles, and folding two cycles with an inverse builds that day.
import Mathlib.Data.Nat.ChineseRemainder
import Mathlib.Data.Int.ModEq
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.RingTheory.Coprime.Lemmas

open Finset

/-- Helper: agreeing modulo every coprime modulus is agreeing modulo the product. -/
theorem helper_modEq_prod_iff (k : ℕ) (m : Fin k → ℕ)
    (hcop : Pairwise fun i j => Nat.Coprime (m i) (m j)) (x y : ℕ) :
    (∀ i, x ≡ y [MOD m i]) ↔ x ≡ y [MOD ∏ i, m i] := by
  have hco : (List.finRange k).Pairwise (Function.onFun Nat.Coprime m) :=
    (List.nodup_finRange k).pairwise_of_forall_ne (fun i _ j _ hij => hcop hij)
  have h := Nat.modEq_list_map_prod_iff (a := x) (b := y) hco
  have hp : ((List.finRange k).map m).prod = ∏ i, m i := by
    rw [Fin.prod_univ_def]
  rw [hp] at h
  rw [h]
  simp

#print axioms helper_modEq_prod_iff


/-- The Chinese remainder theorem. Take any number of rotas with cycle lengths m, no two sharing a
factor, all counted from the same reset, and a day number on each (r below m on every rota).
Then exactly one day x below the combined cycle, the product of all the lengths, leaves day
number r on every rota. -/
theorem one_day_in_the_combined_cycle_fits (k : ℕ) (m r : Fin k → ℕ)
    (hcop : Pairwise fun i j => Nat.Coprime (m i) (m j)) (hr : ∀ i, r i < m i) :
    ∃! x : ℕ, x < ∏ i, m i ∧ ∀ i, x % m i = r i := by
  have hpos : ∀ i, m i ≠ 0 := fun i => (Nat.pos_of_ne_zero (by
    intro h; have := hr i; omega)).ne'
  have hP : 0 < ∏ i, m i := Nat.pos_of_ne_zero (Finset.prod_ne_zero_iff.mpr (fun i _ => hpos i))
  have hcop' : Set.Pairwise (↑(Finset.univ : Finset (Fin k))) (Function.onFun Nat.Coprime m) :=
    fun i _ j _ hij => hcop hij
  let c := Nat.chineseRemainderOfFinset r m Finset.univ (fun i _ => hpos i) hcop'
  have hc : ∀ i, (c : ℕ) ≡ r i [MOD m i] := fun i => c.prop i (Finset.mem_univ i)
  have hlt : (c : ℕ) < ∏ i, m i :=
    Nat.chineseRemainderOfFinset_lt_prod r m (fun i _ => hpos i) hcop'
  refine ⟨c, ⟨hlt, fun i => ?_⟩, ?_⟩
  · have := hc i
    unfold Nat.ModEq at this
    rw [this, Nat.mod_eq_of_lt (hr i)]
  · rintro y ⟨hy, hyr⟩
    have h1 : ∀ i, y ≡ (c : ℕ) [MOD m i] := fun i => by
      unfold Nat.ModEq
      rw [hyr i]
      have := hc i
      unfold Nat.ModEq at this
      rw [this, Nat.mod_eq_of_lt (hr i)]
    have h2 := (helper_modEq_prod_iff k m hcop y c).mp h1
    exact h2.eq_of_lt_of_lt hy hlt

/-- Why exactly one day fits, and why the answer repeats. On rotas whose lengths share no factor,
two days read the same day number on every rota exactly when they differ by a whole number of
combined cycles (the product of the lengths): 23 and 128 read the same, 23 and 24 do not. -/
theorem same_readings_iff_differ_by_combined_cycles (k : ℕ) (m : Fin k → ℕ)
    (hcop : Pairwise fun i j => Nat.Coprime (m i) (m j)) (x y : ℕ) :
    (∀ i, x % m i = y % m i) ↔ x ≡ y [MOD ∏ i, m i] := by
  exact helper_modEq_prod_iff k m hcop x y

/-- How to rebuild the day: one fold. If the cycle lengths a and b share no factor, multiplying
by a has an undoer t on the b-cycle (a × t leaves 1). With any such undoer, starting from day
number r on the a-cycle and taking (s − r) × t steps of a lands on a day that still reads r on
the a-cycle and now reads s on the b-cycle. -/
theorem fold_two_rotas_with_an_inverse (a b : ℕ) (hab : Nat.Coprime a b) :
    (∃ t : ℤ, (a : ℤ) * t ≡ 1 [ZMOD b]) ∧
      ∀ t : ℤ, (a : ℤ) * t ≡ 1 [ZMOD b] → ∀ r s : ℤ,
        r + a * ((s - r) * t) ≡ r [ZMOD a] ∧ r + a * ((s - r) * t) ≡ s [ZMOD b] := by
  have hex : ∃ t : ℤ, (a : ℤ) * t ≡ 1 [ZMOD b] := by
    obtain ⟨u, v, huv⟩ : ∃ u v : ℤ, (a : ℤ) * u + b * v = 1 := by
      have := Nat.isCoprime_iff_coprime.mpr hab
      obtain ⟨u, v, h⟩ := this
      exact ⟨u, v, by linear_combination h⟩
    refine ⟨u, ?_⟩
    rw [Int.modEq_iff_dvd]
    exact ⟨v, by linear_combination -huv⟩
  refine ⟨hex, fun t ht r s => ⟨?_, ?_⟩⟩
  · rw [Int.modEq_iff_dvd]
    exact ⟨-((s - r) * t), by ring⟩
  · have h1 : (a : ℤ) * t * (s - r) ≡ 1 * (s - r) [ZMOD b] := ht.mul_right _
    have h2 : r + a * ((s - r) * t) = r + a * t * (s - r) := by ring
    rw [h2]
    have h3 : r + (a : ℤ) * t * (s - r) ≡ r + 1 * (s - r) [ZMOD b] := h1.add_left r
    simpa using h3

-- The card's rotas: 3, 5 and 7 days share no factor, and the combined cycle is 105 days.
example : Nat.Coprime 3 5 ∧ Nat.Coprime 3 7 ∧ Nat.Coprime 5 7 ∧ 3 * 5 * 7 = 105 := by decide
-- The answer read off against each rota: 23 = 7 × 3 + 2, 23 = 4 × 5 + 3, 23 = 3 × 7 + 2.
example : 23 = 7 * 3 + 2 ∧ 23 = 4 * 5 + 3 ∧ 23 = 3 * 7 + 2 := by decide
example : 23 % 3 = 2 ∧ 23 % 5 = 3 ∧ 23 % 7 = 2 := by decide
-- First fold: 3 leaves 3 on the 5-cycle, undone by 2; steps 2; day 8 of 15.
example : 3 % 5 = 3 ∧ 3 * 2 % 5 = 1 ∧ (3 - 2) * 2 % 5 = 2 ∧ 2 + 3 * 2 = 8 ∧ 3 * 5 = 15 := by decide
example : 8 % 3 = 2 ∧ 8 % 5 = 3 := by decide
-- Second fold: 15 leaves 1 on the 7-cycle, undone by 1; day 8 sits on week day 1; one step; day 23 of 105.
example : 15 % 7 = 1 ∧ 15 * 1 % 7 = 1 ∧ 8 % 7 = 1 ∧ 8 + 15 * 1 = 23 ∧ 15 * 7 = 105 := by decide
-- The scripts subtract: 2 − 8 = −6, which is 1 forward on a 7-cycle.
example : (2 - 8 : ℤ) = -6 ∧ (-6 : ℤ) % 7 = 1 := by decide
-- Scanning all 105 days finds only day 23; two cycles out, 23 and 128.
example : (List.range 105).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 7 = 2) = [23] := by decide
example : (List.range 210).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 7 = 2) = [23, 128] := by
  decide
-- Cleaning alone allows 2, 5, 8; deliveries 3, 8, 13; 8, 23, 38 fit both.
example : (List.range 40).filter (fun d => d % 3 = 2 ∧ d % 5 = 3) = [8, 23, 38] := by decide
-- How many rotas each day 0 to 29 matches, as in the chart.
example : (List.range 30).map (fun d =>
      (if d % 3 = 2 then 1 else 0) + (if d % 5 = 3 then 1 else 0) + (if d % 7 = 2 then 1 else 0)) =
    [0, 0, 2, 1, 0, 1, 0, 0, 2, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 3, 0, 0, 1, 0, 1, 1] := by
  decide
-- The mistake of adding the day numbers: 2 + 3 + 2 = 7, which is day 1 of the 3-day cycle, not day 2.
example : 2 + 3 + 2 = 7 ∧ 7 % 3 = 1 := by decide
-- A 6-day cycle for the week: 3 and 6 share a factor, so 3 has no undoer on the 6-cycle.
example : ¬ Nat.Coprime 3 6 ∧ ∀ t ∈ Finset.range 6, 3 * t % 6 ≠ 1 := by decide
-- Readings that agree fit day 8 in 30; readings that clash fit no day.
example : (List.range 30).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 6 = 2) = [8] := by decide
example : (List.range 30).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 6 = 1) = [] := by decide
-- Try changing: with the week moved on by one (day numbers 2, 3, 3), still one day in 105, now day 38.
example : (List.range 105).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 7 = 3) = [38] := by decide

#print axioms one_day_in_the_combined_cycle_fits
#print axioms same_readings_iff_differ_by_combined_cycles
#print axioms fold_two_rotas_with_an_inverse
