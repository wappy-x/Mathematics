-- Counting chances: when every outcome of a finite sample space is equally likely, the chance of an event is its count over the count of all outcomes, and on a 52-card deck 5,148 of the 2,598,960 five-card hands are flushes.
import Mathlib.Probability.UniformOn
import Mathlib.Data.Fin.Tuple.NatAntidiagonal
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-- Favourable over possible: on a finite sample space `Ω`, if every single outcome has
the same chance under the probability `P`, then the chance of any event `A` is the
number of outcomes in `A` divided by the number of outcomes in `Ω`. -/
theorem prob_eq_card_div_card_of_equally_likely {Ω : Type*} [Fintype Ω] [MeasurableSpace Ω]
    [MeasurableSingletonClass Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (h : ∀ ω ω' : Ω, P {ω} = P {ω'}) (A : Finset Ω) :
    P (A : Set Ω) = (A.card : ℝ≥0∞) / Fintype.card Ω := by
  obtain ⟨ω₀⟩ := nonempty_of_isProbabilityMeasure P
  have hA : P (A : Set Ω) = A.card * P {ω₀} := by
    rw [← sum_measure_singleton]
    simp [h _ ω₀]
  have hU : (Fintype.card Ω : ℝ≥0∞) * P {ω₀} = 1 := by
    rw [← measure_univ (μ := P), ← Finset.coe_univ, ← sum_measure_singleton]
    simp [h _ ω₀]
  have : Nonempty Ω := ⟨ω₀⟩
  have hc : P {ω₀} = 1 / (Fintype.card Ω : ℝ≥0∞) :=
    (ENNReal.eq_div_iff (Nat.cast_ne_zero.2 Fintype.card_ne_zero)
      (ENNReal.natCast_ne_top _)).2 hU
  rw [hA, hc, mul_one_div]

/-- Counting flushes: in a deck of `r` ranks in each of `s` suits (a card is a rank and a
suit), the hands of `k ≥ 1` cards that all share one suit number `s × C(r, k)`:
pick the suit, then pick `k` of its `r` ranks. -/
theorem card_flushes (r s k : ℕ) (hk : 1 ≤ k) :
    ((Finset.univ.powersetCard k : Finset (Finset (Fin r × Fin s))).filter
        (fun H => ∃ t : Fin s, ∀ c ∈ H, c.2 = t)).card = s * r.choose k := by
  classical
  have key : ((Finset.univ.powersetCard k : Finset (Finset (Fin r × Fin s))).filter
        (fun H => ∃ t : Fin s, ∀ c ∈ H, c.2 = t)) =
      (Finset.univ : Finset (Fin s)).biUnion
        (fun t => (Finset.univ.filter (fun c : Fin r × Fin s => c.2 = t)).powersetCard k) := by
    ext H
    simp only [Finset.mem_filter, Finset.mem_powersetCard, Finset.mem_biUnion,
      Finset.mem_univ, true_and]
    constructor
    · rintro ⟨⟨_, hc⟩, t, ht⟩
      exact ⟨t, fun c hcH => Finset.mem_filter.2 ⟨Finset.mem_univ _, ht c hcH⟩, hc⟩
    · rintro ⟨t, ht, hc⟩
      exact ⟨⟨Finset.subset_univ _, hc⟩, t, fun c hcH => (Finset.mem_filter.1 (ht hcH)).2⟩
  rw [key, Finset.card_biUnion]
  · have hcard : ∀ t : Fin s,
        (Finset.univ.filter (fun c : Fin r × Fin s => c.2 = t)).card = r := by
      intro t
      have : Finset.univ.filter (fun c : Fin r × Fin s => c.2 = t) =
          (Finset.univ : Finset (Fin r)) ×ˢ {t} := by
        ext c
        simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_product,
          Finset.mem_singleton]
      rw [this, Finset.card_product, Finset.card_univ, Fintype.card_fin,
        Finset.card_singleton, mul_one]
    simp [Finset.card_powersetCard, hcard]
  · intro t _ t' _ htt'
    rw [Function.onFun, Finset.disjoint_left]
    intro H h1 h2
    rw [Finset.mem_powersetCard] at h1 h2
    have hne : H.Nonempty := by
      rw [← Finset.card_pos, h1.2]; omega
    obtain ⟨c, hc⟩ := hne
    have e1 := (Finset.mem_filter.1 (h1.1 hc)).2
    have e2 := (Finset.mem_filter.1 (h2.1 hc)).2
    exact htt' (e1.symm.trans e2)

/-- The standard deck, 13 ranks in each of 4 suits: there are 2,598,960 five-card hands,
and 5,148 of them are flushes (all five cards of one suit). -/
theorem standard_deck_hands_and_flushes :
    (Finset.univ.powersetCard 5 : Finset (Finset (Fin 13 × Fin 4))).card = 2598960 ∧
    ((Finset.univ.powersetCard 5 : Finset (Finset (Fin 13 × Fin 4))).filter
        (fun H => ∃ t : Fin 4, ∀ c ∈ H, c.2 = t)).card = 5148 := by
  refine ⟨?_, ?_⟩
  · rw [Finset.card_powersetCard, Finset.card_univ, Fintype.card_prod, Fintype.card_fin,
      Fintype.card_fin]
    decide
  · rw [card_flushes 13 4 5 (by norm_num)]
    decide

/-! The card's worked numbers. -/

-- Hands of five, order ignored: C(52, 5) = 2,598,960.
example : Nat.choose 52 5 = 2598960 := by decide
-- Five ranks from one suit: 13 × 12 × 11 × 10 × 9 = 154,440, and 154,440 / 120 = 1,287 = C(13, 5).
example : 13 * 12 * 11 * 10 * 9 = 154440 ∧ 154440 / 120 = 1287 ∧ Nat.choose 13 5 = 1287 := by decide
-- Flushes: 4 suits × 1,287 = 5,148.
example : 4 * Nat.choose 13 5 = 5148 := by decide
-- Ordered deals: 52 × 51 × 50 × 49 × 48 = 311,875,200, and dividing by 5! = 120 gives 2,598,960.
example : 52 * 51 * 50 * 49 * 48 = 311875200 ∧ Nat.factorial 5 = 120 ∧ 311875200 / 120 = 2598960 := by
  decide
-- Ordered flushes: 52 × 12 × 11 × 10 × 9 = 617,760, and 617,760 / 120 = 5,148.
example : 52 * 12 * 11 * 10 * 9 = 617760 ∧ 617760 / 120 = 5148 := by decide
-- The ordered ratio equals the unordered one: 617,760 / 311,875,200 = 5,148 / 2,598,960.
example : 617760 * 2598960 = 5148 * 311875200 := by norm_num
-- Poker's flush, the 40 straight flushes (10 in each suit) removed: 5,148 − 40 = 5,108.
example : 4 * 10 = 40 ∧ 5148 - 40 = 5108 := by decide
-- The suit shapes by formula, and their six counts add up to all 2,598,960 hands.
example : 4 * Nat.choose 13 5 = 5148 ∧
    4 * 3 * Nat.choose 13 4 * Nat.choose 13 1 = 111540 ∧
    4 * 3 * Nat.choose 13 3 * Nat.choose 13 2 = 267696 ∧
    4 * 3 * Nat.choose 13 3 * Nat.choose 13 1 ^ 2 = 580008 ∧
    4 * 3 * Nat.choose 13 2 ^ 2 * Nat.choose 13 1 = 949104 ∧
    4 * Nat.choose 13 2 * Nat.choose 13 1 ^ 3 = 685464 ∧
    5148 + 111540 + 267696 + 580008 + 949104 + 685464 = 2598960 := by decide
-- The suit patterns (cards in each of the 4 named suits, adding to 5) number 56.
example : (Finset.Nat.antidiagonalTuple 4 5).card = 56 := by decide
-- Two dice told apart: 36 pairs, and 6 of them sum to 7.
example : (Finset.univ : Finset (Fin 6 × Fin 6)).card = 36 ∧
    ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
      (fun p => p.1.val + 1 + (p.2.val + 1) = 7)).card = 6 := by decide

#print axioms prob_eq_card_div_card_of_equally_likely
#print axioms card_flushes
#print axioms standard_deck_hands_and_flushes
