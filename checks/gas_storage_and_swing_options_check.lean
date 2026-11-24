-- Gas storage and swing contracts: if each forward is the average future price under the pricing weights, a store worth at least every fixed plan the pumps and space allow is worth at least its intrinsic value, and a swing contract is worth at least its fixed-month Europeans and at most one American option per right.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Probability.Process.Stopping

open MeasureTheory

/-- Full value is at least intrinsic value. A plan `x` buys `x m` units in month `m` (sells them
when `x m < 0`) at the month's price `S m`, pays `c` per unit moved, and discounts by `D m`.
The store allows a plan when it moves at most 25 units a month, keeps the inventory (the running
total of `x`) between 0 and 100 at the end of every month, and ends empty. If each forward is
the average future price under the pricing weights, `F m = E^Q[S m]`, and the full value `V` is
at least the average discounted cash of every allowed plan fixed today, then `V` is at least the
intrinsic value: the best value of an allowed plan on today's forward curve. -/
theorem full_value_ge_intrinsic {Ω : Type*} [MeasurableSpace Ω]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (S : Fin 12 → Ω → ℝ) (hS : ∀ m, Integrable (S m) Q)
    (F D : Fin 12 → ℝ) (c V : ℝ) (hF : ∀ m, F m = ∫ ω, S m ω ∂Q)
    (hV : ∀ x : Fin 12 → ℝ, (∀ m, -25 ≤ x m ∧ x m ≤ 25) →
      (∀ k, 0 ≤ ∑ m ∈ Finset.Iic k, x m ∧ ∑ m ∈ Finset.Iic k, x m ≤ 100) → ∑ m, x m = 0 →
      ∫ ω, ∑ m, D m * (-x m * S m ω - c * |x m|) ∂Q ≤ V) :
    sSup ((fun x : Fin 12 → ℝ => ∑ m, D m * (-x m * F m - c * |x m|)) ''
      {x | (∀ m, -25 ≤ x m ∧ x m ≤ 25) ∧
        (∀ k, 0 ≤ ∑ m ∈ Finset.Iic k, x m ∧ ∑ m ∈ Finset.Iic k, x m ≤ 100) ∧ ∑ m, x m = 0})
      ≤ V := by
  have hval : ∀ x : Fin 12 → ℝ,
      ∫ ω, ∑ m, D m * (-x m * S m ω - c * |x m|) ∂Q = ∑ m, D m * (-x m * F m - c * |x m|) := by
    intro x
    rw [integral_finsetSum (f := fun m ω => D m * (-x m * S m ω - c * |x m|)) _
      (fun m _ => (((hS m).const_mul (-x m)).sub (integrable_const (c * |x m|))).const_mul (D m))]
    refine Finset.sum_congr rfl (fun m _ => ?_)
    rw [integral_const_mul, integral_sub ((hS m).const_mul (-x m)) (integrable_const _),
      integral_const_mul, integral_const, hF m]
    simp
  apply csSup_le
  · refine ⟨_, (0 : Fin 12 → ℝ), ⟨fun m => by norm_num, fun k => by simp, by simp⟩, rfl⟩
  · rintro _ ⟨x, ⟨h1, h2, h3⟩, rfl⟩
    show ∑ m, D m * (-x m * F m - c * |x m|) ≤ V
    rw [← hval x]
    exact hV x h1 h2 h3

/-- Swing at most one American option per right. A right used at date `t` on price path `ω`
pays `pay t ω`, discounted (`t = ⊤` means never used). One American option is worth `A`: at
least the average of `pay τ` for every exercise rule `τ` that decides from the prices seen so far
(a stopping time). A swing with `n` rights uses its `k`-th right by such a rule `τ k`. Then the
swing's average payoff is at most `n` American options. -/
theorem swing_le_n_american {Ω : Type*} {mΩ : MeasurableSpace Ω} (Q : Measure Ω)
    (ℱ : Filtration ℕ mΩ) (pay : WithTop ℕ → Ω → ℝ) (A : ℝ)
    (hint : ∀ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ → Integrable (fun ω => pay (τ ω) ω) Q)
    (hA : ∀ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ → ∫ ω, pay (τ ω) ω ∂Q ≤ A)
    (n : ℕ) (τ : Fin n → Ω → WithTop ℕ) (hτ : ∀ k, IsStoppingTime ℱ (τ k)) :
    ∫ ω, ∑ k, pay (τ k ω) ω ∂Q ≤ n * A := by
  rw [integral_finsetSum _ (fun k _ => hint (τ k) (hτ k))]
  calc ∑ k, ∫ ω, pay (τ k ω) ω ∂Q ≤ ∑ _k : Fin n, A :=
        Finset.sum_le_sum (fun k _ => hA (τ k) (hτ k))
    _ = n * A := by simp

/-- Swing at least its fixed-month Europeans. Using one right, at strike `K`, in each month of a
set `s` of at most `n` months fixed today is a policy a swing with `n` rights allows. If the
swing's value `W` is at least the average discounted payoff of every such policy, then for every
such set `W` is at least the sum of the discounted European calls on those months. -/
theorem swing_ge_fixed_months {Ω : Type*} [MeasurableSpace Ω] (Q : Measure Ω)
    [IsProbabilityMeasure Q] (S : Fin 12 → Ω → ℝ) (hS : ∀ m, Integrable (S m) Q)
    (D : Fin 12 → ℝ) (K W : ℝ) (n : ℕ)
    (hW : ∀ s : Finset (Fin 12), s.card ≤ n →
      ∫ ω, ∑ m ∈ s, D m * max (S m ω - K) 0 ∂Q ≤ W) :
    ∀ s : Finset (Fin 12), s.card ≤ n → ∑ m ∈ s, D m * ∫ ω, max (S m ω - K) 0 ∂Q ≤ W := by
  intro s hs
  have h := hW s hs
  rw [integral_finsetSum (f := fun m ω => D m * max (S m ω - K) 0) _
    (fun m _ => (((hS m).sub (integrable_const K)).pos_part).const_mul (D m))] at h
  simpa only [integral_const_mul] using h

-- The intrinsic plan (Apr..Mar) moves at most 25 a month, keeps the store between 0 and 100
-- units, and ends empty.
example : ([0, 25, 25, 25, 25, 0, 0, -25, -25, -25, -25, 0] : List ℤ).all
      (fun a => -25 ≤ a ∧ a ≤ 25) ∧
    (List.scanl (· + ·) 0 ([0, 25, 25, 25, 25, 0, 0, -25, -25, -25, -25, 0] : List ℤ)).all
      (fun l => 0 ≤ l ∧ l ≤ 100) ∧
    ([0, 25, 25, 25, 25, 0, 0, -25, -25, -25, -25, 0] : List ℤ).sum = 0 := by decide

-- Inventory at the end of each month under the intrinsic plan, as in the picture.
example : (List.scanl (· + ·) 0 ([0, 25, 25, 25, 25, 0, 0, -25, -25, -25, -25, 0] : List ℤ)).tail
    = [0, 25, 50, 75, 100, 100, 100, 75, 50, 25, 0, 0] := by decide

-- A move of -25, 0 or +25 in each of 12 months gives 3^12 = 531,441 schedules to try.
example : 3 ^ 12 = 531441 := by norm_num

#print axioms full_value_ge_intrinsic
#print axioms swing_le_n_american
#print axioms swing_ge_fixed_months
