-- Bijections and double counting: a one-to-one and onto rule between two finite collections forces equal sizes, a rule naming every target exactly d times makes the first collection d times the second, and these give C(n, 2) = n(n - 1)/2 and C(n, k) = C(n, n - k), with the card's 20-team league numbers checked.
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

/-- The card's two counting rules, for any two finite collections `A` and `B` and any rule
`f` sending each member of `A` to a member of `B`.
Bijection rule: if `f` is one to one and onto, then `|A| = |B|`.
Division rule: if every member `b` of `B` is named by exactly `d` members of `A`, the same `d`
for every `b`, then `|A| = d × |B|`. -/
theorem bijection_and_double_counting {A B : Type*} [Fintype A] [Fintype B] [DecidableEq B]
    (f : A → B) :
    (Function.Bijective f → Fintype.card A = Fintype.card B) ∧
      (∀ d : ℕ, (∀ b : B, (Finset.univ.filter (fun a => f a = b)).card = d) →
        Fintype.card A = d * Fintype.card B) := by
  refine ⟨fun hf => Fintype.card_of_bijective hf, fun d hd => ?_⟩
  rw [← Finset.card_univ, Finset.card_eq_sum_card_fiberwise (f := f) (t := Finset.univ)
    (fun _ _ => Finset.mem_univ _)]
  simp only [hd, Finset.sum_const, Finset.card_univ]
  exact Nat.mul_comm _ _

/-- Every team plays every other team once: with `n` teams the matches number
`C(n, 2) = n(n − 1) / 2`. -/
theorem choose_two_eq_half_n_mul_pred (n : ℕ) : n.choose 2 = n * (n - 1) / 2 := by
  exact Nat.choose_two_right n

/-- Choosing who is in is choosing who is out: for `k` of `n`, `C(n, k) = C(n, n − k)`. -/
theorem choose_eq_choose_sub (n k : ℕ) (hk : k ≤ n) : n.choose k = n.choose (n - k) := by
  exact (Nat.choose_symm hk).symm

-- The 20-team league: 20 teams, 19 opponents each, 380 fixture slips, 2 per match, 190 matches.
example : 20 * 19 = 380 := by decide
example : 380 / 2 = 190 ∧ 380 = 2 * 190 := by decide
example : Nat.choose 20 2 = 190 := by decide
example : 20 * (20 - 1) / 2 = 190 := by decide
-- The slips and the matches, listed as pairs of teams and counted.
example : ((Finset.univ : Finset (Fin 20 × Fin 20)).filter (fun p => p.1 ≠ p.2)).card = 380 := by
  decide +kernel
example : ((Finset.univ : Finset (Fin 20 × Fin 20)).filter (fun p => p.1 < p.2)).card = 190 := by
  decide +kernel
-- The five-team picture: 25 cells, 5 blank, 20 line-ends, 10 matches.
example : 5 * 5 = 25 ∧ 5 * 5 - 5 = 20 ∧ 5 * 4 = 20 ∧ 20 / 2 = 10 := by decide
example : Nat.choose 5 2 = 10 := by decide
-- Matches for 2, 3, 4, 5 and 6 teams: 1, 3, 6, 10, 15.
example : Nat.choose 2 2 = 1 ∧ Nat.choose 3 2 = 3 ∧ Nat.choose 4 2 = 6 ∧
    Nat.choose 5 2 = 10 ∧ Nat.choose 6 2 = 15 := by decide
-- The playoff six and the fourteen left out: 38760 each.
example : Nat.choose 20 6 = 38760 := by decide
example : Nat.choose 20 14 = 38760 := by decide
-- The mistakes: stopping at the slips gives 380; letting a team play itself gives 400 slips, 200 matches.
example : 20 * 20 = 400 ∧ 400 / 2 = 200 := by decide

#print axioms bijection_and_double_counting
#print axioms choose_two_eq_half_n_mul_pred
#print axioms choose_eq_choose_sub
