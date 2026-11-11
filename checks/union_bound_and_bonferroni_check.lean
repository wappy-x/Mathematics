-- Stopping the sieve early: for any finite family of finite sets, the inclusion-exclusion sum cut off after an odd number of layers is at least the size of the union and cut off after an even number is at most it, with the union bound and the one-day tally 1 - (-1)^m C(k-1, m) behind it.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Finset.Powerset
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.Ring.Parity
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

open Finset

variable {ι α : Type*} [DecidableEq α]

/-- The layer total `S_j`: for every choice `t` of `j` sets from the family, the number of
members the chosen sets all share, added up. (The shared members of a nonempty choice all lie in
the union, so they are found by filtering the union.) -/
def layerTotal (s : Finset ι) (A : ι → Finset α) (j : ℕ) : ℕ :=
  ∑ t ∈ s.powersetCard j, #{a ∈ s.biUnion A | ∀ i ∈ t, a ∈ A i}

/-- The sieve stopped after `m` layers: `S_1 - S_2 + S_3 - ...`, keeping layers `1` to `m`. -/
def sieveStop (s : Finset ι) (A : ι → Finset α) (m : ℕ) : ℤ :=
  ∑ j ∈ Icc 1 m, (-1 : ℤ) ^ (j + 1) * (layerTotal s A j : ℤ)


/-- Each member of the union is counted in layer `j` once per `j`-set of headings it lies under. -/
lemma layerTotal_eq_sum_choose (s : Finset ι) (A : ι → Finset α) (j : ℕ) :
    layerTotal s A j = ∑ a ∈ s.biUnion A, (#{i ∈ s | a ∈ A i}).choose j := by
  unfold layerTotal
  conv_lhs => arg 2; ext t; rw [card_filter]
  rw [sum_comm]
  refine sum_congr rfl fun a _ => ?_
  rw [← card_filter, ← card_powersetCard]
  congr 1
  ext t
  simp only [mem_filter, mem_powersetCard, subset_iff]
  constructor
  · rintro ⟨⟨h1, h2⟩, h3⟩
    exact ⟨fun i hi => ⟨h1 hi, h3 i hi⟩, h2⟩
  · rintro ⟨h1, h2⟩
    exact ⟨⟨fun i hi => (h1 hi).1, h2⟩, fun i hi => (h1 hi).2⟩

/-- The one-day tally, stated first as a helper so the sieve proof can use it. -/
lemma one_day_tally_aux (k m : ℕ) (hk : 1 ≤ k) :
    ∑ j ∈ Icc 1 m, (-1 : ℤ) ^ (j + 1) * (k.choose j : ℤ) =
      1 - (-1 : ℤ) ^ m * ((k - 1).choose m : ℤ) := by
  obtain ⟨n, rfl⟩ : ∃ n, k = n + 1 := ⟨k - 1, by omega⟩
  simp only [Nat.add_sub_cancel]
  induction m with
  | zero => simp
  | succ m ih =>
    rw [sum_Icc_succ_top (by omega), ih, Nat.choose_succ_succ', Nat.cast_add]
    ring

/-- The stopped sieve, member by member. -/
lemma sieveStop_eq_sum (s : Finset ι) (A : ι → Finset α) (m : ℕ) :
    sieveStop s A m = ∑ a ∈ s.biUnion A,
      (1 - (-1 : ℤ) ^ m * ((#{i ∈ s | a ∈ A i} - 1).choose m : ℤ)) := by
  unfold sieveStop
  simp_rw [layerTotal_eq_sum_choose, Nat.cast_sum, mul_sum]
  rw [sum_comm]
  refine sum_congr rfl fun a ha => ?_
  apply one_day_tally_aux
  obtain ⟨i, hi, hai⟩ := mem_biUnion.mp ha
  exact card_pos.mpr ⟨i, mem_filter.mpr ⟨hi, hai⟩⟩

/-- The Bonferroni inequalities. For any finite family of finite sets, with any overlaps, stop
the inclusion-exclusion sieve after `m` whole layers: if `m` is odd the total never falls below
the size of the union, and if `m` is even it never rises above it. -/
theorem sieve_stopped_early_brackets_union (s : Finset ι) (A : ι → Finset α) (m : ℕ) :
    (Odd m → (#(s.biUnion A) : ℤ) ≤ sieveStop s A m) ∧
    (Even m → sieveStop s A m ≤ (#(s.biUnion A) : ℤ)) := by
  have hU : (#(s.biUnion A) : ℤ) = ∑ a ∈ s.biUnion A, (1 : ℤ) := by simp
  rw [sieveStop_eq_sum, hU]
  constructor
  · intro hm
    apply sum_le_sum
    intro a _
    rw [hm.neg_one_pow]
    have : (0 : ℤ) ≤ ((#{i ∈ s | a ∈ A i} - 1).choose m : ℤ) := by positivity
    linarith
  · intro hm
    apply sum_le_sum
    intro a _
    rw [hm.neg_one_pow]
    have : (0 : ℤ) ≤ ((#{i ∈ s | a ∈ A i} - 1).choose m : ℤ) := by positivity
    linarith

/-- The union bound (Boole's inequality): the things in at least one of finitely many finite sets
are never more numerous than the sizes of the sets added up. -/
theorem card_union_le_sum_card (s : Finset ι) (A : ι → Finset α) :
    #(s.biUnion A) ≤ ∑ i ∈ s, #(A i) := by
  exact card_biUnion_le

/-- One day under `k ≥ 1` headings: its tally in the sieve stopped after `m` layers,
`C(k,1) - C(k,2) + ... ± C(k,m)`, collapses to `1 - (-1)^m C(k-1, m)`. -/
theorem one_day_tally_eq (k m : ℕ) (hk : 1 ≤ k) :
    ∑ j ∈ Icc 1 m, (-1 : ℤ) ^ (j + 1) * (k.choose j : ℤ) =
      1 - (-1 : ℤ) ^ m * ((k - 1).choose m : ℤ) := by
  exact one_day_tally_aux k m hk

-- The card's September log: days 1 to 30, rain on 12, wind on 8, fog on 5.
def rainy : Finset ℕ := Icc 1 12
def windy : Finset ℕ := {8, 9, 10, 12, 13, 14, 15, 16}
def foggy : Finset ℕ := {11, 12, 17, 18, 19}
def weather : Fin 3 → Finset ℕ := ![rainy, windy, foggy]

-- The published totals: 12, 8 and 5; the pair overlaps 4, 2, 1; one day under all three.
example : #rainy = 12 ∧ #windy = 8 ∧ #foggy = 5 := by decide
example : #(rainy ∩ windy) = 4 ∧ #(rainy ∩ foggy) = 2 ∧ #(windy ∩ foggy) = 1 ∧
    #(rainy ∩ windy ∩ foggy) = 1 := by decide

-- The true count: 19 bad days, by listing the log.
example : #(rainy ∪ windy ∪ foggy) = 19 := by decide

-- Layer totals S1 = 25, S2 = 7, S3 = 1, and the sieve stopped after 1, 2, 3 layers: 25, 18, 19.
example : layerTotal univ weather 1 = 25 ∧ layerTotal univ weather 2 = 7 ∧
    layerTotal univ weather 3 = 1 := by decide
example : sieveStop univ weather 1 = 25 ∧ sieveStop univ weather 2 = 18 ∧
    sieveStop univ weather 3 = 19 := by decide
example : #((univ : Finset (Fin 3)).biUnion weather) = 19 := by decide

-- The worked table: 12 + 8 + 5 = 25, 4 + 2 + 1 = 7, 25 - 7 = 18, 25 - 7 + 1 = 19, 14 + 4 + 1 = 19.
example : (12 + 8 + 5 : ℤ) = 25 ∧ (4 + 2 + 1 : ℤ) = 7 ∧ (25 - 7 : ℤ) = 18 ∧
    (25 - 7 + 1 : ℤ) = 19 ∧ (14 + 4 + 1 : ℤ) = 19 := by norm_num

-- Step 2: 14 days at 0 extra, four at 1, one at 2, so 6 too many, and 25 - 6 = 19.
example : (14 * 0 + 4 * 1 + 1 * 2 : ℤ) = 6 ∧ (25 - 6 : ℤ) = 19 := by norm_num

-- The mistakes: 25 - 7 - 1 = 17 (triple subtracted), 25 - 4 = 21 (half a layer).
example : (25 - 7 - 1 : ℤ) = 17 ∧ (25 - 4 : ℤ) = 21 := by norm_num

-- A day under 3 headings scores 3, 0, 1, 1 for m = 1 to 4; under 4 headings 4, -2, 2, 1.
example : (List.range 4).map (fun i => ∑ j ∈ Icc 1 (i + 1), (-1 : ℤ) ^ (j + 1) * (Nat.choose 3 j : ℤ))
    = [3, 0, 1, 1] := by decide
example : (List.range 4).map (fun i => ∑ j ∈ Icc 1 (i + 1), (-1 : ℤ) ^ (j + 1) * (Nat.choose 4 j : ℤ))
    = [4, -2, 2, 1] := by decide

#print axioms layerTotal_eq_sum_choose
#print axioms one_day_tally_aux
#print axioms sieveStop_eq_sum
#print axioms sieve_stopped_early_brackets_union
#print axioms card_union_le_sum_card
#print axioms one_day_tally_eq
