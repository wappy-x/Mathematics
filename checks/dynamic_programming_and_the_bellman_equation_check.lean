-- Dynamic programming: the cheapest cost to finish a staged trip satisfies the Bellman equation, every tail of a cheapest plan is itself cheapest, and a plan built from the equation's minimising choices is cheapest.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Algebra.Order.Monoid.Defs
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

/-! Setting, in the card's notation.
* `σ` is the type of states `x` (the card: the bank, N or S).
* `U` is the type of choices `u` (the card: stay or cross); "finitely many choices" is
  `[Fintype U] [Nonempty U]`, and "finitely many stages" is a whole number `n` of legs.
* `c k x u` is the cost of choice `u` from state `x` on the leg after stage `k`, in an ordered
  additive cost type `C` (whole dollars, integers, rationals and reals are all instances).
* `f x u` is the state the choice lands in: known in advance, no chance involved.
* The state tells the whole story: `c` and `f` see only the stage, the state and the choice,
  never the route so far.
* Costs add up leg by leg: `planCost` is the sum of the leg costs along the plan.
A plan for `m` legs is a function `Fin m → U`. -/

namespace Bellman

variable {σ U C : Type*}

/-- The total cost `J_k(x; u_k, …)` of a plan of `m` legs started from state `x` at stage `k`:
the first leg's cost plus the cost of the rest of the plan from where that leg lands. -/
def planCost [AddCommMonoid C] (c : ℕ → σ → U → C) (f : σ → U → σ) :
    (m : ℕ) → ℕ → σ → (Fin m → U) → C
  | 0, _, _, _ => 0
  | m + 1, k, x, p => c k x (p 0) + planCost c f m (k + 1) (f x (p 0)) (Fin.tail p)

/-- The state reached from `x` after following the first `j` choices `p`. -/
def reach (f : σ → U → σ) : (j : ℕ) → σ → (Fin j → U) → σ
  | 0, x, _ => x
  | j + 1, x, p => reach f j (f x (p 0)) (Fin.tail p)

/-- The value function `V_k(x)` for a trip of `n` legs: the cheapest total cost, over every
plan for the remaining `n - k` legs, of finishing from state `x` at stage `k`. -/
def cheapest [AddCommMonoid C] [LinearOrder C] [Fintype U] [Nonempty U]
    (c : ℕ → σ → U → C) (f : σ → U → σ) (n k : ℕ) (x : σ) : C :=
  Finset.univ.inf' Finset.univ_nonempty (planCost c f (n - k) k x)

theorem planCost_cast [AddCommMonoid C] (c : ℕ → σ → U → C) (f : σ → U → σ)
    {n n' : ℕ} (h : n = n') (k : ℕ) (x : σ) (q : Fin n' → U) :
    planCost c f n k x (q ∘ Fin.cast h) = planCost c f n' k x q := by
  subst h; rfl

#print axioms planCost_cast

theorem planCost_append [AddCommMonoid C] (c : ℕ → σ → U → C) (f : σ → U → σ) (m : ℕ) :
    ∀ (j k : ℕ) (x : σ) (a : Fin j → U) (b : Fin m → U),
      planCost c f (j + m) k x (Fin.append a b) =
        planCost c f j k x a + planCost c f m (k + j) (reach f j x a) b := by
  intro j
  induction j with
  | zero =>
    intro k x a b
    have ha : a = Fin.elim0 := Subsingleton.elim _ _
    subst ha
    rw [Fin.elim0_append, planCost_cast]
    simp [planCost, reach]
  | succ j ih =>
    intro k x a b
    rw [← Fin.cons_self_tail a, Fin.append_cons, planCost_cast]
    simp only [planCost, reach, Fin.cons_zero, Fin.tail_cons]
    rw [ih, add_assoc, show k + (1 + j) = k + (j + 1) by omega, ← add_assoc]

#print axioms planCost_append

theorem cheapest_eq [AddCommMonoid C] [LinearOrder C] [Fintype U] [Nonempty U]
    (c : ℕ → σ → U → C) (f : σ → U → σ) (n k : ℕ) (x : σ) (d : ℕ) (hd : n - k = d) :
    cheapest c f n k x =
      Finset.univ.inf' (Finset.univ_nonempty (α := Fin d → U)) (planCost c f d k x) := by
  subst hd; rfl

#print axioms cheapest_eq

theorem cheapest_of_sub_eq_zero [AddCommMonoid C] [LinearOrder C] [Fintype U] [Nonempty U]
    (c : ℕ → σ → U → C) (f : σ → U → σ) (n k : ℕ) (x : σ) (h : n - k = 0) :
    cheapest c f n k x = 0 := by
  rw [cheapest_eq c f n k x 0 h]
  obtain ⟨p, -, hp⟩ := Finset.exists_mem_eq_inf' (Finset.univ_nonempty (α := Fin 0 → U))
    (planCost c f 0 k x)
  rw [hp]
  rfl

#print axioms cheapest_of_sub_eq_zero

theorem cheapest_succ [AddCommMonoid C] [LinearOrder C] [IsOrderedAddMonoid C]
    [Fintype U] [Nonempty U] (c : ℕ → σ → U → C) (f : σ → U → σ) (m k : ℕ) (x : σ) :
    Finset.univ.inf' Finset.univ_nonempty (planCost c f (m + 1) k x) =
      Finset.univ.inf' Finset.univ_nonempty (fun u => c k x u +
        Finset.univ.inf' Finset.univ_nonempty (planCost c f m (k + 1) (f x u))) := by
  apply le_antisymm
  · apply Finset.le_inf'
    intro u _
    obtain ⟨q, -, hq⟩ := Finset.exists_mem_eq_inf' (Finset.univ_nonempty (α := Fin m → U))
      (planCost c f m (k + 1) (f x u))
    rw [hq]
    have := Finset.inf'_le (planCost c f (m + 1) k x) (Finset.mem_univ (Fin.cons u q))
    refine le_trans this (le_of_eq ?_)
    simp [planCost]
  · apply Finset.le_inf'
    intro p _
    calc Finset.univ.inf' Finset.univ_nonempty (fun u => c k x u +
          Finset.univ.inf' Finset.univ_nonempty (planCost c f m (k + 1) (f x u)))
        ≤ c k x (p 0) + Finset.univ.inf' Finset.univ_nonempty
            (planCost c f m (k + 1) (f x (p 0))) :=
          Finset.inf'_le (fun u => c k x u +
            Finset.univ.inf' Finset.univ_nonempty (planCost c f m (k + 1) (f x u)))
            (Finset.mem_univ (p 0))
      _ ≤ c k x (p 0) + planCost c f m (k + 1) (f x (p 0)) (Fin.tail p) :=
          add_le_add le_rfl (Finset.inf'_le _ (Finset.mem_univ _))
      _ = planCost c f (m + 1) k x p := rfl

#print axioms cheapest_succ

theorem plan_aux [AddCommMonoid C] [LinearOrder C] [Fintype U] [Nonempty U]
    (c : ℕ → σ → U → C) (f : σ → U → σ) (n : ℕ) :
    ∀ (m k : ℕ) (x : σ) (p : Fin m → U), n - k = m →
      (∀ i : Fin m,
        c (k + i) (reach f i x (fun t => p (Fin.castLE i.isLt.le t))) (p i) +
          cheapest c f n (k + i + 1) (f (reach f i x (fun t => p (Fin.castLE i.isLt.le t))) (p i)) =
        cheapest c f n (k + i) (reach f i x (fun t => p (Fin.castLE i.isLt.le t)))) →
      planCost c f m k x p = cheapest c f n k x := by
  intro m
  induction m with
  | zero =>
    intro k x p hm _
    rw [cheapest_of_sub_eq_zero c f n k x hm]
    rfl
  | succ m ih =>
    intro k x p hm hmin
    have h0 := hmin 0
    simp only [Fin.val_zero, add_zero] at h0
    have hrest := ih (k + 1) (f x (p 0)) (Fin.tail p) (by omega) (by
      intro i
      have hi := hmin i.succ
      have hr : reach f (i.succ : ℕ) x (fun t => p (Fin.castLE i.succ.isLt.le t)) =
          reach f i (f x (p 0)) (fun t => Fin.tail p (Fin.castLE i.isLt.le t)) := by
        show reach f (i : ℕ) (f x (p (Fin.castLE i.succ.isLt.le (0 : Fin ((i : ℕ) + 1)))))
          (Fin.tail (fun t : Fin ((i : ℕ) + 1) => p (Fin.castLE i.succ.isLt.le t))) = _
        have e0 : Fin.castLE i.succ.isLt.le (0 : Fin ((i : ℕ) + 1)) = 0 := Fin.ext (by simp)
        rw [e0]
        congr 1
      rw [hr] at hi
      simp only [Fin.val_succ] at hi
      rw [show k + 1 + (i : ℕ) = k + ((i : ℕ) + 1) by omega]
      exact hi)
    show c k x (p 0) + planCost c f m (k + 1) (f x (p 0)) (Fin.tail p) = _
    rw [hrest]
    exact h0

#print axioms plan_aux

/-- The Bellman equation. With finitely many stages and finitely many choices, costs that add
up leg by leg, and each choice landing in a known state, the cheapest cost from state `x` at
stage `k` is the smallest, over this leg's choices `u`, of the leg's cost plus the cheapest
cost from where it lands; at the finish nothing is left to pay. -/
theorem cheapest_cost_satisfies_bellman_equation [AddCommMonoid C] [LinearOrder C]
    [IsOrderedAddMonoid C] [Fintype U] [Nonempty U]
    (c : ℕ → σ → U → C) (f : σ → U → σ) (n : ℕ) :
    (∀ x, cheapest c f n n x = 0) ∧
    (∀ k < n, ∀ x, cheapest c f n k x =
      Finset.univ.inf' Finset.univ_nonempty (fun u => c k x u + cheapest c f n (k + 1) (f x u))) := by
  refine ⟨fun x => cheapest_of_sub_eq_zero c f n n x (Nat.sub_self n), ?_⟩
  intro k hk x
  obtain ⟨m, hm⟩ : ∃ m, n - k = m + 1 := ⟨n - k - 1, by omega⟩
  have hm' : n - (k + 1) = m := by omega
  rw [cheapest_eq c f n k x (m + 1) hm]
  simp only [cheapest_eq c f n (k + 1) _ m hm']
  exact cheapest_succ c f m k x

/-- The principle of optimality. Cut a cheapest plan anywhere, after its first `j` legs: the
remaining `m` legs form a cheapest plan from the state where the car then stands. -/
theorem tail_of_cheapest_plan_is_cheapest [AddCommMonoid C] [LinearOrder C]
    [IsOrderedCancelAddMonoid C] (c : ℕ → σ → U → C) (f : σ → U → σ)
    (j m k : ℕ) (x : σ) (a : Fin j → U) (b : Fin m → U)
    (hbest : ∀ q : Fin (j + m) → U,
      planCost c f (j + m) k x (Fin.append a b) ≤ planCost c f (j + m) k x q) :
    ∀ q : Fin m → U,
      planCost c f m (k + j) (reach f j x a) b ≤ planCost c f m (k + j) (reach f j x a) q := by
  intro q
  have h := hbest (Fin.append a q)
  rw [planCost_append, planCost_append] at h
  exact le_of_add_le_add_left h

/-- Reading the plan off the table. If at every stage the plan picks a choice that attains the
minimum in the Bellman equation, its total cost equals the cheapest cost, so it is a
cheapest plan. -/
theorem plan_from_bellman_minimisers_is_cheapest [AddCommMonoid C] [LinearOrder C]
    [Fintype U] [Nonempty U]
    (c : ℕ → σ → U → C) (f : σ → U → σ) (n k : ℕ) (x : σ) (p : Fin (n - k) → U)
    (hmin : ∀ i : Fin (n - k),
      c (k + i) (reach f i x (fun t => p (Fin.castLE i.isLt.le t))) (p i) +
          cheapest c f n (k + i + 1) (f (reach f i x (fun t => p (Fin.castLE i.isLt.le t))) (p i)) =
        cheapest c f n (k + i) (reach f i x (fun t => p (Fin.castLE i.isLt.le t)))) :
    planCost c f (n - k) k x p = cheapest c f n k x := by
  exact plan_aux c f n (n - k) k x p rfl hmin

/-! The card's river, in whole dollars. Banks: `0` is north, `1` is south. Choices: `0` is stay,
`1` is cross. Crossing flips the bank: `f x u = x + u` in `Fin 2`. -/

/-- The tolls on the card's picture: `toll k x u` for the leg after stage `k`. -/
def toll : ℕ → Fin 2 → Fin 2 → ℕ
  | 0, 0, 0 => 11 | 0, 0, 1 => 16 | 0, 1, 0 => 14 | 0, 1, 1 => 13
  | 1, 0, 0 => 19 | 1, 0, 1 => 22 | 1, 1, 0 => 12 | 1, 1, 1 => 15
  | 2, 0, 0 => 21 | 2, 0, 1 => 24 | 2, 1, 0 => 19 | 2, 1, 1 => 20
  | _, _, _ => 0

/-- Which bank a choice leaves the car on. -/
def move (x u : Fin 2) : Fin 2 := x + u

-- The table of best onward costs, filled right to left.
example : cheapest toll move 3 3 0 = 0 ∧ cheapest toll move 3 3 1 = 0 := by decide
example : cheapest toll move 3 2 0 = 21 ∧ cheapest toll move 3 2 1 = 19 := by decide
example : cheapest toll move 3 1 0 = 40 ∧ cheapest toll move 3 1 1 = 31 := by decide
example : cheapest toll move 3 0 0 = 47 ∧ cheapest toll move 3 0 1 = 45 := by decide
-- The hand arithmetic of the Bellman steps.
example : min (21 + 0) (24 + 0) = 21 ∧ min (19 + 0) (20 + 0) = 19 := by norm_num
example : min (19 + 21) (22 + 19) = 40 ∧ min (12 + 19) (15 + 21) = 31 := by norm_num
example : min (11 + 40) (16 + 31) = 47 ∧ min (14 + 31) (13 + 40) = 45 := by norm_num
-- The plan read off from the north bank: cross, stay, stay, costing 16 + 12 + 19 = 47.
example : planCost toll move 3 0 0 ![1, 0, 0] = 47 := by decide
example : 16 + 12 + 19 = 47 := by norm_num
-- Its tail from the south bank, stay then stay, costs 12 + 19 = 31 = V_1(S).
example : planCost toll move 2 1 1 ![0, 0] = 31 := by decide
-- Brute force: 2 × 2 × 2 = 8 routes from the north bank, costing 51, 54, 52, 53, 47, 48, 52, 55.
example : Fintype.card (Fin 3 → Fin 2) = 8 := by decide
example : [planCost toll move 3 0 0 ![0, 0, 0], planCost toll move 3 0 0 ![0, 0, 1],
    planCost toll move 3 0 0 ![0, 1, 0], planCost toll move 3 0 0 ![0, 1, 1],
    planCost toll move 3 0 0 ![1, 0, 0], planCost toll move 3 0 0 ![1, 0, 1],
    planCost toll move 3 0 0 ![1, 1, 0], planCost toll move 3 0 0 ![1, 1, 1]] =
    [51, 54, 52, 53, 47, 48, 52, 55] := by decide
-- Mistake 1, the cheaper toll on each leg with no look ahead: stay, stay, stay costs 51.
example : planCost toll move 3 0 0 ![0, 0, 0] = 51 := by decide
-- Mistake 2, each leg's cheapest toll ignoring the bank: 11 + 12 + 19 = 42, and no route costs 42.
example : 11 + 12 + 19 = 42 := by norm_num
example : ∀ p : Fin 3 → Fin 2, planCost toll move 3 0 0 p ≠ 42 := by decide
-- Dropping "costs add up": a 15 dollar rebate on north stay, stay, stay gives 51 − 15 = 36.
example : 51 - 15 = 36 := by norm_num
-- Counting: n · s · (m − 1) comparisons against m ^ n routes.
example : 3 * 2 * (2 - 1) = 6 ∧ 2 ^ 3 = 8 ∧ 2 ^ 3 - 1 = 7 := by norm_num
example : 10 * 2 * (2 - 1) = 20 ∧ 2 ^ 10 = 1024 := by norm_num
example : 30 * 2 * (2 - 1) = 60 ∧ 2 ^ 30 = 1073741824 := by norm_num
example : 12 * 2 * (2 - 1) = 24 ∧ 2 ^ 12 = 4096 := by norm_num
-- The curse of dimensionality: gauges with 10 levels each.
example : 10 ^ 1 = 10 ∧ 10 ^ 3 = 1000 ∧ 10 ^ 6 = 1000000 := by norm_num

#print axioms cheapest_cost_satisfies_bellman_equation
#print axioms tail_of_cheapest_plan_is_cheapest
#print axioms plan_from_bellman_minimisers_is_cheapest

end Bellman
