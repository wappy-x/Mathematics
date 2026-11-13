-- No arbitrage: in a market with no free money, two positions with the same payoff in every scenario cost the same, and a position that never pays less never costs less.
import Mathlib.Algebra.Module.Submodule.Defs
import Mathlib.Algebra.Module.Prod
import Mathlib.Algebra.Module.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fintype.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-!
Setting, as on the card.

* `Ω` is the finite list of scenarios: each complete way the year can end.
* A position is a pair `x : ℝ × (Ω → ℝ)`: `x.1` is its price today (negative if it pays
  to put on) and `x.2 ω` is what it is worth at expiry in scenario `ω`.
* The market `M` is the set of positions that can be held. It is a submodule: holding two
  positions at once adds prices and payoffs, and scaling by any real number (a negative
  one is selling short, on the same terms) scales both. No fees, no bid-ask gap, no
  default: that is what "linear" means here.
-/


variable {Ω : Type*}

/-- An arbitrage: nothing to pay going in (`p ≤ 0`), nothing to lose coming out
(`X ω ≥ 0` in every scenario), and money somewhere (`p < 0`, or `X ω > 0` in some
scenario). -/
def IsArbitrage (x : ℝ × (Ω → ℝ)) : Prop :=
  x.1 ≤ 0 ∧ (∀ ω, 0 ≤ x.2 ω) ∧ (x.1 < 0 ∨ ∃ ω, 0 < x.2 ω)

/-- No arbitrage: no position in the market is an arbitrage. -/
def NoArbitrage (M : Submodule ℝ (ℝ × (Ω → ℝ))) : Prop :=
  ∀ x ∈ M, ¬ IsArbitrage x

/-- The law of one price. In a market with finitely many scenarios, where positions can be
combined and scaled (short selling allowed) and no position is an arbitrage, two positions
that pay the same in every scenario must cost the same today. -/
theorem law_of_one_price [Fintype Ω] (M : Submodule ℝ (ℝ × (Ω → ℝ)))
    (hNA : NoArbitrage M) {A B : ℝ × (Ω → ℝ)} (hA : A ∈ M) (hB : B ∈ M)
    (hpay : ∀ ω, A.2 ω = B.2 ω) : A.1 = B.1 := by
  by_contra hne
  rcases lt_or_gt_of_ne hne with h | h
  · apply hNA (A - B) (M.sub_mem hA hB)
    refine ⟨?_, ?_, Or.inl ?_⟩
    · simp only [Prod.fst_sub]; linarith
    · intro ω; simp [hpay ω]
    · simp only [Prod.fst_sub]; linarith
  · apply hNA (B - A) (M.sub_mem hB hA)
    refine ⟨?_, ?_, Or.inl ?_⟩
    · simp only [Prod.fst_sub]; linarith
    · intro ω; simp [hpay ω]
    · simp only [Prod.fst_sub]; linarith

/-- The dominance rule. Under the same assumptions, a position whose payoff is never less
than another's in any scenario can never cost less today. -/
theorem dominance_rule [Fintype Ω] (M : Submodule ℝ (ℝ × (Ω → ℝ)))
    (hNA : NoArbitrage M) {A B : ℝ × (Ω → ℝ)} (hA : A ∈ M) (hB : B ∈ M)
    (hpay : ∀ ω, B.2 ω ≤ A.2 ω) : B.1 ≤ A.1 := by
  by_contra hlt
  replace hlt := not_le.mp hlt
  apply hNA (A - B) (M.sub_mem hA hB)
  refine ⟨?_, ?_, Or.inl ?_⟩
  · simp only [Prod.fst_sub]; linarith
  · intro ω; simp only [Prod.snd_sub, Pi.sub_apply]; linarith [hpay ω]
  · simp only [Prod.fst_sub]; linarith

/-- The strict dominance rule. If A never pays less than B and pays strictly more in some
scenario, then A is strictly dearer than B. -/
theorem strict_dominance_rule [Fintype Ω] (M : Submodule ℝ (ℝ × (Ω → ℝ)))
    (hNA : NoArbitrage M) {A B : ℝ × (Ω → ℝ)} (hA : A ∈ M) (hB : B ∈ M)
    (hpay : ∀ ω, B.2 ω ≤ A.2 ω) (hstrict : ∃ ω, B.2 ω < A.2 ω) : B.1 < A.1 := by
  by_contra hle
  replace hle := not_lt.mp hle
  apply hNA (A - B) (M.sub_mem hA hB)
  obtain ⟨ω0, h0⟩ := hstrict
  refine ⟨?_, ?_, Or.inr ⟨ω0, ?_⟩⟩
  · simp only [Prod.fst_sub]; linarith
  · intro ω; simp only [Prod.snd_sub, Pi.sub_apply]; linarith [hpay ω]
  · simp only [Prod.snd_sub, Pi.sub_apply]; linarith


/-! Worked numbers from the card, as exact fractions. Acme finishes at 130, 105 or 85;
the call is struck at 100. -/

-- The call's payoffs: 30, 5 and 0.
example : max ((130 : ℤ) - 100) 0 = 30 ∧ max ((105 : ℤ) - 100) 0 = 5 ∧
    max ((85 : ℤ) - 100) 0 = 0 := by decide

-- The two desks' notes both pay Acme's closing price, so they cancel in every scenario.
example : (130 : ℤ) - 130 = 0 ∧ (105 : ℤ) - 105 = 0 ∧ (85 : ℤ) - 85 = 0 := by decide

-- The dominating copy: 2/3 of a note and -170/3 dollars due at expiry
-- (0.666667 and -56.666667 on the card). It holds 30, 40/3 (13.33) and 0,
-- never less than the call's 30, 5 and 0.
example : (2 / 3 : ℚ) * 130 + (-170 / 3) = 30 ∧ (2 / 3 : ℚ) * 105 + (-170 / 3) = 40 / 3 ∧
    (2 / 3 : ℚ) * 85 + (-170 / 3) = 0 ∧ (5 : ℚ) ≤ 40 / 3 := by norm_num

-- The dominated copy: 1/4 of a note and -85/4 dollars due at expiry
-- (0.250000 and -21.250000 on the card). It holds 45/4 (11.25), 5 and 0,
-- never more than the call's 30, 5 and 0.
example : (1 / 4 : ℚ) * 130 + (-85 / 4) = 45 / 4 ∧ (1 / 4 : ℚ) * 105 + (-85 / 4) = 5 ∧
    (1 / 4 : ℚ) * 85 + (-85 / 4) = 0 ∧ (45 / 4 : ℚ) ≤ 30 := by norm_num

-- Add a 60 scenario and the dominating copy holds -50/3 (-16.666667) against the
-- call's 0, so it no longer dominates.
example : (2 / 3 : ℚ) * 60 + (-170 / 3) = -50 / 3 ∧ (-50 / 3 : ℚ) < 0 := by norm_num

#print axioms law_of_one_price
#print axioms dominance_rule
#print axioms strict_dominance_rule
