-- The assignment problem: for any square table of whole-number costs, the cheapest pairing of rows to columns costs exactly the largest total of dual values that no cell exceeds.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.Hall.Basic
import Mathlib.Order.Int.LeastGreatest
import Mathlib.Tactic.Linarith

open Finset

/-! There are `n` drivers and `n` rounds (a square table; the card pads a short side).
`c i j` is the whole-number cost of driver `i` on round `j`. A plan is a pairing
`σ : Equiv.Perm (Fin n)` giving driver `i` the round `σ i`, every round used once;
its cost is the sum of its chosen cells, `∑ i, c i (σ i)`.
Dual values are a number `u i` for each driver and `v j` for each round with
`u i + v j ≤ c i j` for every cell; their total is `∑ i, u i + ∑ j, v j`. -/

/-- Egerváry's theorem (1931), the fact behind the Hungarian method: for every square
table of whole-number costs, the fewest total cost over all plans equals the largest
total of dual values that no cell's cost is exceeded by. There is one number `m` that
is both the least plan cost and the greatest dual-value total. -/
theorem min_plan_cost_eq_max_dual_total (n : ℕ) (c : Fin n → Fin n → ℤ) :
    ∃ m : ℤ,
      IsLeast {s | ∃ σ : Equiv.Perm (Fin n), s = ∑ i, c i (σ i)} m ∧
      IsGreatest {s | ∃ u v : Fin n → ℤ, (∀ i j, u i + v j ≤ c i j) ∧
        s = ∑ i, u i + ∑ j, v j} m := by
  classical
  -- dual totals are bounded above by the cost of the identity plan
  have weak : ∀ (u v : Fin n → ℤ), (∀ i j, u i + v j ≤ c i j) → ∀ σ : Equiv.Perm (Fin n),
      ∑ i, u i + ∑ j, v j ≤ ∑ i, c i (σ i) := by
    intro u v h σ
    calc ∑ i, u i + ∑ j, v j = ∑ i, (u i + v (σ i)) := by
          rw [Finset.sum_add_distrib, Equiv.sum_comp σ v]
      _ ≤ ∑ i, c i (σ i) := Finset.sum_le_sum fun i _ => h i (σ i)
  obtain ⟨S, ⟨u, v, h, hS⟩, hmax⟩ := Int.exists_greatest_of_bdd
    (P := fun s => ∃ u v : Fin n → ℤ, (∀ i j, u i + v j ≤ c i j) ∧ s = ∑ i, u i + ∑ j, v j)
    ⟨∑ i, c i ((1 : Equiv.Perm (Fin n)) i), by
      rintro z ⟨u, v, h, rfl⟩
      exact weak u v h 1⟩
    ⟨∑ i, (fun _ => -(∑ k, ∑ l, |c k l|)) i + ∑ j, (fun _ => (0 : ℤ)) j,
      fun _ => -(∑ k, ∑ l, |c k l|), fun _ => 0, by
        intro i j
        have h1 : |c i j| ≤ ∑ l, |c i l| :=
          Finset.single_le_sum (f := fun l => |c i l|) (fun l _ => abs_nonneg _)
            (Finset.mem_univ j)
        have h2 : ∑ l, |c i l| ≤ ∑ k, ∑ l, |c k l| :=
          Finset.single_le_sum (f := fun k => ∑ l, |c k l|)
            (fun k _ => Finset.sum_nonneg fun l _ => abs_nonneg _) (Finset.mem_univ i)
        have h3 := neg_abs_le (c i j)
        simp only
        linarith, rfl⟩
  -- tight cells
  let t : Fin n → Finset (Fin n) := fun i => univ.filter fun j => u i + v j = c i j
  have hall : ∀ A : Finset (Fin n), A.card ≤ (A.biUnion t).card := by
    intro A
    by_contra hlt
    push Not at hlt
    set N := A.biUnion t with hN
    let u' : Fin n → ℤ := fun i => u i + (if i ∈ A then 1 else 0)
    let v' : Fin n → ℤ := fun j => v j - (if j ∈ N then 1 else 0)
    have feas : ∀ i j, u' i + v' j ≤ c i j := by
      intro i j
      simp only [u', v']
      by_cases hi : i ∈ A
      · by_cases hj : j ∈ N
        · simp only [hi, hj, ite_true]; linarith [h i j]
        · simp only [hi, hj, ite_true, ite_false]
          have hne : u i + v j ≠ c i j := by
            intro heq
            apply hj
            rw [hN, Finset.mem_biUnion]
            exact ⟨i, hi, by simp [t, heq]⟩
          have := lt_of_le_of_ne (h i j) hne
          linarith
      · by_cases hj : j ∈ N
        · simp only [hi, hj, ite_true, ite_false]; linarith [h i j]
        · simp only [hi, hj, ite_false]; linarith [h i j]
    have hsum : ∑ i, u' i + ∑ j, v' j = S + A.card - N.card := by
      simp only [u', v', Finset.sum_add_distrib, Finset.sum_sub_distrib, hS]
      simp
      ring
    have := hmax _ ⟨u', v', feas, hsum.symm⟩
    omega
  obtain ⟨f, hfinj, hft⟩ := (Finset.all_card_le_biUnion_card_iff_exists_injective t).mp hall
  have hfbij : Function.Bijective f := hfinj.bijective_of_finite
  let σ : Equiv.Perm (Fin n) := Equiv.ofBijective f hfbij
  have hσ : ∑ i, c i (σ i) = S := by
    have : ∀ i, c i (σ i) = u i + v (σ i) := by
      intro i
      have := hft i
      simp only [t, Finset.mem_filter, Finset.mem_univ, true_and] at this
      simp [σ, this]
    rw [Finset.sum_congr rfl fun i _ => this i, Finset.sum_add_distrib, Equiv.sum_comp σ v, hS]
  refine ⟨S, ⟨⟨σ, hσ.symm⟩, ?_⟩, ⟨⟨u, v, h, hS⟩, ?_⟩⟩
  · rintro s ⟨τ, rfl⟩
    rw [hS]
    exact weak u v h τ
  · rintro s ⟨u₂, v₂, h₂, rfl⟩
    exact hmax _ ⟨u₂, v₂, h₂, rfl⟩

/-- Step 0, cutting rows and columns: taking `u i` off every cell of row `i` and `v j`
off every cell of column `j` lowers every plan's total by the same amount,
`∑ i, u i + ∑ j, v j`, because a plan uses each row once and each column once. -/
theorem cut_rows_and_columns_shifts_every_plan (n : ℕ) (c : Fin n → Fin n → ℤ)
    (u v : Fin n → ℤ) (σ : Equiv.Perm (Fin n)) :
    ∑ i, (c i (σ i) - u i - v (σ i)) = ∑ i, c i (σ i) - (∑ i, u i + ∑ j, v j) := by
  rw [Finset.sum_sub_distrib, Finset.sum_sub_distrib, Equiv.sum_comp σ v]
  ring

/-- The receipt: if the dual values satisfy `u i + v j ≤ c i j` for every cell, then
every plan costs at least their total. So a plan whose cost equals that total is
the cheapest, and checking this needs one comparison per cell. -/
theorem dual_total_le_every_plan (n : ℕ) (c : Fin n → Fin n → ℤ) (u v : Fin n → ℤ)
    (h : ∀ i j, u i + v j ≤ c i j) (σ : Equiv.Perm (Fin n)) :
    ∑ i, u i + ∑ j, v j ≤ ∑ i, c i (σ i) := by
  calc ∑ i, u i + ∑ j, v j = ∑ i, (u i + v (σ i)) := by
        rw [Finset.sum_add_distrib, Equiv.sum_comp σ v]
    _ ≤ ∑ i, c i (σ i) := Finset.sum_le_sum fun i _ => h i (σ i)

/-! The card's bakery: rows Ana, Ben, Cara, Dev (0 to 3);
columns Riverside, Hills, Coast, Town (0 to 3). -/

def bakery : Fin 4 → Fin 4 → ℤ :=
  ![![70, 24, 62, 21], ![41, 66, 47, 24], ![45, 64, 51, 23], ![27, 73, 27, 34]]

-- The best plan: Ana-Hills, Ben-Riverside, Cara-Town, Dev-Coast, 24 + 41 + 23 + 27 = 115 miles.
example : ∃ σ : Equiv.Perm (Fin 4), σ 0 = 1 ∧ σ 1 = 0 ∧ σ 2 = 3 ∧ σ 3 = 2 ∧
    ∑ i, bakery i (σ i) = 115 := by decide
-- No plan of the 24 costs less than 115, none more than 221, and exactly one costs 115.
example : ∀ σ : Equiv.Perm (Fin 4), 115 ≤ ∑ i, bakery i (σ i) ∧ ∑ i, bakery i (σ i) ≤ 221 := by
  decide
example : ∃ σ : Equiv.Perm (Fin 4), ∑ i, bakery i (σ i) = 221 := by decide
example : (univ.filter fun σ : Equiv.Perm (Fin 4) => ∑ i, bakery i (σ i) = 115).card = 1 := by
  decide
example : Fintype.card (Equiv.Perm (Fin 4)) = 24 := by decide
-- The receipt: u = (21, 41, 40, 27), v = (0, 3, 0, -17); no cell is beaten, and the total is 115.
example : ∀ i j, ![21, 41, 40, 27] i + ![0, 3, 0, -17] j ≤ bakery i j := by decide
example : ∑ i, (![21, 41, 40, 27] : Fin 4 → ℤ) i + ∑ j, (![0, 3, 0, -17] : Fin 4 → ℤ) j = 115 := by
  decide
-- Step 1: row cuts 21 + 24 + 23 + 27 = 95, column cuts 0, 3, 0, 0, first bound 98.
example : ∑ i, (![21, 24, 23, 27] : Fin 4 → ℤ) i = 95 := by decide
example : ∀ i j, ![21, 24, 23, 27] i + ![0, 3, 0, 0] j ≤ bakery i j := by decide
example : (95 : ℤ) + (0 + 3 + 0 + 0) = 98 := by norm_num
-- Step 4: delta = 41 - 24 = 17, and the bound rises by 17 * (4 - 3) to 115.
example : (41 : ℤ) - 24 = 17 ∧ 17 * (2 : ℤ) - 17 * 1 = 17 * (4 - 3) ∧ (98 : ℤ) + 17 * (4 - 3) = 115 := by
  norm_num
-- The driver-by-driver grab: Ana-Town, Ben-Riverside, Cara-Coast, Dev-Hills, 186 miles, 71 more.
example : ∃ σ : Equiv.Perm (Fin 4), σ 0 = 3 ∧ σ 1 = 0 ∧ σ 2 = 2 ∧ σ 3 = 1 ∧
    ∑ i, bakery i (σ i) = 186 := by decide
example : (186 : ℤ) - 115 = 71 := by norm_num
-- Each driver's nearest round, clashes ignored: 21 + 24 + 23 + 27 = 95.
example : (21 : ℤ) + 24 + 23 + 27 = 95 := by norm_num
-- A ban on Dev driving Hills typed as 0: the best becomes 113 with Dev on Hills.
example : ∀ σ : Equiv.Perm (Fin 4),
    113 ≤ ∑ i, (Function.update bakery 3 ![27, 0, 27, 34]) i (σ i) := by decide
example : ∃ σ : Equiv.Perm (Fin 4), σ 3 = 1 ∧
    ∑ i, (Function.update bakery 3 ![27, 0, 27, 34]) i (σ i) = 113 := by decide
-- Typed as 1000: the best is 115 again, with Dev on Coast.
example : ∀ σ : Equiv.Perm (Fin 4),
    115 ≤ ∑ i, (Function.update bakery 3 ![27, 1000, 27, 34]) i (σ i) := by decide
example : ∃ σ : Equiv.Perm (Fin 4), σ 3 = 2 ∧
    ∑ i, (Function.update bakery 3 ![27, 1000, 27, 34]) i (σ i) = 115 := by decide
-- Thirty vans: 30! plans.
example : Nat.factorial 30 = 265252859812191058636308480000000 := by decide

#print axioms min_plan_cost_eq_max_dual_total
#print axioms cut_rows_and_columns_shifts_every_plan
#print axioms dual_total_le_every_plan
