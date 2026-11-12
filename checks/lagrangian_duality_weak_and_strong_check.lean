-- Lagrangian duality: every non-negative price on the constraints gives a lower bound on the best cost, the bound is concave in the prices, and for the card's two pumps the best bound meets the best cost at £40 an hour with the price 0.40.
import Mathlib.Data.EReal.Basic
import Mathlib.Data.EReal.Inv
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Module.Pi
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

namespace LagrangianDuality

/-! ## The general problem

Plans have type `E`; `S` is the set of allowed plans (for the pumps, both powers at least 0).
`f0` is the cost to minimise, `f i x ≤ 0` (`i = 1, …, m`) are the "at most" rules and
`h j x = 0` (`j = 1, …, p`) the equality rules. Values that may be unbounded live in `EReal`,
the real line with `⊥ = -∞` and `⊤ = +∞`, so a minimum that is not reached is the greatest
lower bound, and an infeasible problem has best cost `+∞`, as on the card. -/

variable {E : Type*} {m p : ℕ}

/-- The Lagrangian `L(x, lam, nu) = f0 x + Σ lam i * f i x + Σ nu j * h j x`: the priced cost. -/
def lagrangian (f0 : E → ℝ) (f : Fin m → E → ℝ) (h : Fin p → E → ℝ)
    (lam : Fin m → ℝ) (nu : Fin p → ℝ) (x : E) : ℝ :=
  f0 x + ∑ i, lam i * f i x + ∑ j, nu j * h j x

/-- The dual function `q(lam, nu)`: the lowest priced cost over every allowed plan, legal or not
(the greatest lower bound in `EReal`). -/
noncomputable def dualFn (S : Set E) (f0 : E → ℝ) (f : Fin m → E → ℝ) (h : Fin p → E → ℝ)
    (lam : Fin m → ℝ) (nu : Fin p → ℝ) : EReal :=
  ⨅ x ∈ S, ((lagrangian f0 f h lam nu x : ℝ) : EReal)

/-- The legal plans: allowed, every "at most" rule `f i x ≤ 0` and every equality `h j x = 0`. -/
def feasible (S : Set E) (f : Fin m → E → ℝ) (h : Fin p → E → ℝ) : Set E :=
  {x | x ∈ S ∧ (∀ i, f i x ≤ 0) ∧ ∀ j, h j x = 0}

/-- The best cost `p⋆`: the greatest lower bound of the cost over the legal plans
(`+∞` when there are none). -/
noncomputable def pStar (S : Set E) (f0 : E → ℝ) (f : Fin m → E → ℝ) (h : Fin p → E → ℝ) :
    EReal :=
  ⨅ x ∈ feasible S f h, ((f0 x : ℝ) : EReal)

/-- The best bound `d⋆`: the highest the dual function gets over prices `lam ≥ 0` (entry by
entry) and `nu` of any sign. -/
noncomputable def dStar (S : Set E) (f0 : E → ℝ) (f : Fin m → E → ℝ) (h : Fin p → E → ℝ) :
    EReal :=
  ⨆ (lam : Fin m → ℝ) (_ : 0 ≤ lam) (nu : Fin p → ℝ), dualFn S f0 f h lam nu

/-- Weak duality at one price (helper). -/
theorem weak_aux (S : Set E) (f0 : E → ℝ) (f : Fin m → E → ℝ)
    (h : Fin p → E → ℝ) (lam : Fin m → ℝ) (hlam : 0 ≤ lam) (nu : Fin p → ℝ) :
    dualFn S f0 f h lam nu ≤ pStar S f0 f h := by
  refine le_iInf₂ fun x hx => ?_
  refine (iInf₂_le x hx.1).trans ?_
  refine EReal.coe_le_coe_iff.2 ?_
  obtain ⟨-, hf, hh⟩ := hx
  have h1 : ∑ i, lam i * f i x ≤ 0 :=
    Finset.sum_nonpos fun i _ => mul_nonpos_of_nonneg_of_nonpos (hlam i) (hf i)
  have h2 : ∑ j, nu j * h j x = 0 := Finset.sum_eq_zero fun j _ => by simp [hh j]
  simp only [lagrangian]
  linarith

/-- Weak duality (the card's main claim). For any problem at all, with no convexity: at every
price `lam ≥ 0` on the "at most" rules and every price `nu` on the equalities, the dual
function is a lower bound on the best cost, `q(lam, nu) ≤ p⋆`; so the best bound is too,
`d⋆ ≤ p⋆`. -/
theorem dual_function_le_best_cost (S : Set E) (f0 : E → ℝ) (f : Fin m → E → ℝ)
    (h : Fin p → E → ℝ) :
    (∀ (lam : Fin m → ℝ), 0 ≤ lam → ∀ nu : Fin p → ℝ, dualFn S f0 f h lam nu ≤ pStar S f0 f h) ∧
      dStar S f0 f h ≤ pStar S f0 f h := by
  exact ⟨fun lam hlam nu => weak_aux S f0 f h lam hlam nu,
    iSup_le fun lam => iSup_le fun hlam => iSup_le fun nu => weak_aux S f0 f h lam hlam nu⟩

/-- The dual function is always concave, again with no convexity of the problem: for any two
prices `(lam, nu)`, `(lam', nu')` and any weight `θ` between 0 and 1, the bound at the mixed
price is at least the mix of the two bounds,
`θ q(lam, nu) + (1 - θ) q(lam', nu') ≤ q(θ lam + (1 - θ) lam', θ nu + (1 - θ) nu')`. -/
theorem dual_function_concave (S : Set E) (f0 : E → ℝ) (f : Fin m → E → ℝ)
    (h : Fin p → E → ℝ) (lam lam' : Fin m → ℝ) (nu nu' : Fin p → ℝ) (θ : ℝ)
    (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1) :
    ((θ : ℝ) : EReal) * dualFn S f0 f h lam nu + ((1 - θ : ℝ) : EReal) * dualFn S f0 f h lam' nu'
      ≤ dualFn S f0 f h (θ • lam + (1 - θ) • lam') (θ • nu + (1 - θ) • nu') := by
  refine le_iInf₂ fun x hx => ?_
  have e1 : dualFn S f0 f h lam nu ≤ ((lagrangian f0 f h lam nu x : ℝ) : EReal) := iInf₂_le x hx
  have e2 : dualFn S f0 f h lam' nu' ≤ ((lagrangian f0 f h lam' nu' x : ℝ) : EReal) :=
    iInf₂_le x hx
  have hθ' : (0 : EReal) ≤ ((1 - θ : ℝ) : EReal) := EReal.coe_nonneg.2 (by linarith)
  have hθ : (0 : EReal) ≤ ((θ : ℝ) : EReal) := EReal.coe_nonneg.2 hθ0
  calc ((θ : ℝ) : EReal) * dualFn S f0 f h lam nu + ((1 - θ : ℝ) : EReal) * dualFn S f0 f h lam' nu'
      ≤ ((θ : ℝ) : EReal) * ((lagrangian f0 f h lam nu x : ℝ) : EReal)
        + ((1 - θ : ℝ) : EReal) * ((lagrangian f0 f h lam' nu' x : ℝ) : EReal) :=
        add_le_add (mul_le_mul_of_nonneg_left e1 hθ) (mul_le_mul_of_nonneg_left e2 hθ')
    _ = ((θ * lagrangian f0 f h lam nu x + (1 - θ) * lagrangian f0 f h lam' nu' x : ℝ) : EReal) := by
        simp [EReal.coe_add, EReal.coe_mul]
    _ = ((lagrangian f0 f h (θ • lam + (1 - θ) • lam') (θ • nu + (1 - θ) • nu') x : ℝ) : EReal) := by
        congr 1
        simp only [lagrangian, Pi.add_apply, Pi.smul_apply, smul_eq_mul, add_mul,
          Finset.sum_add_distrib, mul_assoc, ← Finset.mul_sum]
        ring

/-! ## The pumps

A plan is `x = (x1, x2)`, the two pump powers in kW, allowed when both are at least 0.
Cost `f0(x) = 0.30 x1 + 0.00625 x1^2 + 0.30 x2 + 0.00375 x2^2` in £ an hour; the one rule is the
shortfall `f1(x) = 140 - 2 x1 - 1.5 x2 ≤ 0` in litres a second; there are no equalities. -/

/-- Allowed plans: both pump powers at least 0. -/
def pumpPlans : Set (ℝ × ℝ) := {x | 0 ≤ x.1 ∧ 0 ≤ x.2}

/-- The hourly running cost of the two pumps, £ an hour. -/
def pumpCost (x : ℝ × ℝ) : ℝ := 0.30 * x.1 + 0.00625 * x.1 ^ 2 + 0.30 * x.2 + 0.00375 * x.2 ^ 2

/-- The one "at most" rule: the shortfall below 140 litres a second. -/
def pumpShortfall : Fin 1 → ℝ × ℝ → ℝ := fun _ x => 140 - 2 * x.1 - 1.5 * x.2

/-- No equality rules. -/
def noEq : Fin 0 → ℝ × ℝ → ℝ := ![]

/-- Strong duality for the pumps (Step 5), with the card's formula for the bound. For every
price `lam ≥ 0.20`, `q(lam) = 140 lam - (2 lam - 0.3)^2 / 0.025 - (1.5 lam - 0.3)^2 / 0.015`;
at the price `0.40` the bound is £40; the best cost and the best bound are both £40. -/
theorem pump_strong_duality :
    (∀ lam : ℝ, 0.20 ≤ lam → dualFn pumpPlans pumpCost pumpShortfall noEq (fun _ => lam) ![] =
        ((140 * lam - (2 * lam - 0.3) ^ 2 / 0.025 - (1.5 * lam - 0.3) ^ 2 / 0.015 : ℝ) : EReal)) ∧
      dualFn pumpPlans pumpCost pumpShortfall noEq (fun _ => 0.40) ![] = 40 ∧
      pStar pumpPlans pumpCost pumpShortfall noEq = 40 ∧
      dStar pumpPlans pumpCost pumpShortfall noEq = 40 := by
  have hq : ∀ lam : ℝ, 0.20 ≤ lam → dualFn pumpPlans pumpCost pumpShortfall noEq (fun _ => lam) ![] =
        ((140 * lam - (2 * lam - 0.3) ^ 2 / 0.025 - (1.5 * lam - 0.3) ^ 2 / 0.015 : ℝ) : EReal) := by
    intro lam hlam
    have hL : ∀ x : ℝ × ℝ, lagrangian pumpCost pumpShortfall noEq (fun _ => lam) ![] x =
        pumpCost x + lam * (140 - 2 * x.1 - 1.5 * x.2) := by
      intro x
      simp [lagrangian, pumpShortfall]
    apply le_antisymm
    · refine (iInf₂_le ((2 * lam - 0.3) / 0.0125, (1.5 * lam - 0.3) / 0.0075) ?_).trans ?_
      · constructor
        · show (0:ℝ) ≤ (2 * lam - 0.3) / 0.0125
          apply div_nonneg <;> norm_num; linarith
        · show (0:ℝ) ≤ (1.5 * lam - 0.3) / 0.0075
          apply div_nonneg <;> norm_num; linarith
      · refine le_of_eq (EReal.coe_eq_coe_iff.2 ?_)
        rw [hL]
        simp only [pumpCost]
        ring
    · refine le_iInf₂ fun x _ => EReal.coe_le_coe_iff.2 ?_
      rw [hL]
      simp only [pumpCost]
      have key : 0.30 * x.1 + 0.00625 * x.1 ^ 2 + 0.30 * x.2 + 0.00375 * x.2 ^ 2
            + lam * (140 - 2 * x.1 - 1.5 * x.2)
          - (140 * lam - (2 * lam - 0.3) ^ 2 / 0.025 - (1.5 * lam - 0.3) ^ 2 / 0.015)
          = 0.00625 * (x.1 - (2 * lam - 0.3) / 0.0125) ^ 2
            + 0.00375 * (x.2 - (1.5 * lam - 0.3) / 0.0075) ^ 2 := by ring
      have hpos : 0 ≤ 0.00625 * (x.1 - (2 * lam - 0.3) / 0.0125) ^ 2
            + 0.00375 * (x.2 - (1.5 * lam - 0.3) / 0.0075) ^ 2 := by positivity
      linarith
  have h40 : dualFn pumpPlans pumpCost pumpShortfall noEq (fun _ => 0.40) ![] = 40 := by
    rw [hq 0.40 (by norm_num)]
    norm_num
    rfl
  have hp_le : pStar pumpPlans pumpCost pumpShortfall noEq ≤ 40 := by
    refine (iInf₂_le ((40 : ℝ), (40 : ℝ)) ?_).trans (le_of_eq ?_)
    · refine ⟨⟨by norm_num, by norm_num⟩, fun i => ?_, fun j => j.elim0⟩
      simp [pumpShortfall]
      norm_num
    · simp only [pumpCost]
      norm_num
      rfl
  have hp_ge : 40 ≤ pStar pumpPlans pumpCost pumpShortfall noEq := by
    rw [← h40]
    exact (dual_function_le_best_cost _ _ _ _).1 _ (fun _ => by norm_num) _
  have hp : pStar pumpPlans pumpCost pumpShortfall noEq = 40 := le_antisymm hp_le hp_ge
  refine ⟨hq, h40, hp, le_antisymm ?_ ?_⟩
  · rw [← hp]
    exact (dual_function_le_best_cost _ _ _ _).2
  · rw [← h40]
    exact le_iSup₂_of_le (fun _ => (0.40 : ℝ)) (fun _ => by norm_num)
      (le_iSup_of_le ![] le_rfl)

/-! ## Worked numbers, by hand (exact rationals) -/

-- Trial price 0.35: pump 1 at (2.0 x 0.35 - 0.30) / 0.0125 = 32 kW, pump 2 at
-- (1.5 x 0.35 - 0.30) / 0.0075 = 30 kW.
example : (2 * 0.35 - 0.30 : ℚ) / 0.0125 = 32 ∧ (1.5 * 0.35 - 0.30 : ℚ) / 0.0075 = 30 := by
  norm_num
-- They deliver 64 + 45 = 109 L/s, short 31.
example : (2 * 32 + 1.5 * 30 : ℚ) = 109 ∧ (140 - 109 : ℚ) = 31 := by norm_num
-- Running cost f0(32, 30) = £28.375; bound 28.375 + 0.35 x 31 = £39.225.
example : (0.30 * 32 + 0.00625 * 32 ^ 2 + 0.30 * 30 + 0.00375 * 30 ^ 2 : ℚ) = 28.375 ∧
    (28.375 + 0.35 * 31 : ℚ) = 39.225 := by norm_num
-- Pumps switch on above prices 0.30 / 2.0 = 0.15 and 0.30 / 1.5 = 0.20.
example : (0.30 / 2 : ℚ) = 0.15 ∧ (0.30 / 1.5 : ℚ) = 0.20 := by norm_num
-- Step 4: deliveries 2.0 x1(lam) = 320 lam - 48 and 1.5 x2(lam) = 300 lam - 60, so the
-- shortfall is 248 - 620 lam.
example (lam : ℚ) : 2 * ((2 * lam - 0.30) / 0.0125) = 320 * lam - 48 ∧
    1.5 * ((1.5 * lam - 0.30) / 0.0075) = 300 * lam - 60 ∧
    140 - (320 * lam - 48) - (300 * lam - 60) = 248 - 620 * lam := by
  norm_num
  refine ⟨by ring, by ring, by ring⟩
-- The best price: 248 / 620 = 0.40, where both pumps run at 0.50 / 0.0125 = 0.30 / 0.0075 = 40 kW.
example : (248 / 620 : ℚ) = 0.40 ∧ (0.50 / 0.0125 : ℚ) = 40 ∧ (0.30 / 0.0075 : ℚ) = 40 := by
  norm_num
-- At (40, 40): 80 + 60 = 140 L/s, exactly the demand, and the cost is £40.00.
example : (2 * 40 + 1.5 * 40 : ℚ) = 140 ∧
    (0.30 * 40 + 0.00625 * 40 ^ 2 + 0.30 * 40 + 0.00375 * 40 ^ 2 : ℚ) = 40 := by norm_num
-- The strictly feasible plan (50, 50): 175 L/s at £55.00 an hour.
example : (2 * 50 + 1.5 * 50 : ℚ) = 175 ∧
    (0.30 * 50 + 0.00625 * 50 ^ 2 + 0.30 * 50 + 0.00375 * 50 ^ 2 : ℚ) = 55 := by norm_num
-- Gap at the trial price: 40 - 39.225 = 0.775 = 310 x 0.05^2, which is 1.9375 percent of 40.
example : (40 - 39.225 : ℚ) = 0.775 ∧ (310 * 0.05 ^ 2 : ℚ) = 0.775 ∧
    (0.775 / 40 * 100 : ℚ) = 1.9375 := by norm_num
-- Dual ascent with step 0.001 shrinks the distance by 1 - 620 x 0.001 = 0.38; it diverges past
-- step 2 / 620 = 1 / 310.
example : (1 - 620 * 0.001 : ℚ) = 0.38 ∧ (2 / 620 : ℚ) = 1 / 310 := by norm_num
-- The chart: q(lam) = 140 lam - (2 lam - 0.3)^2 / 0.025 - (1.5 lam - 0.3)^2 / 0.015 at
-- 0.20, 0.25, ..., 0.60 gives 27.600 33.025 36.900 39.225 40.000 39.225 36.900 33.025 27.600.
example : ([0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60] : List ℚ).map
      (fun lam => 140 * lam - (2 * lam - 0.3) ^ 2 / 0.025 - (1.5 * lam - 0.3) ^ 2 / 0.015) =
    [27.600, 33.025, 36.900, 39.225, 40.000, 39.225, 36.900, 33.025, 27.600] := by
  norm_num
-- What breaks: pump 2 fixed at 70 kW costs 21 + 18.375 = £39.375 and lifts 105 L/s; pump 1 then
-- runs at 17.5 kW, and the best plan costs £46.5390625 (pump 1 alone would cost £51.625).
example : (0.30 * 70 + 0.00375 * 70 ^ 2 : ℚ) = 39.375 ∧ (1.5 * 70 : ℚ) = 105 ∧
    ((140 - 105) / 2 : ℚ) = 17.5 ∧
    (39.375 + 0.30 * 17.5 + 0.00625 * 17.5 ^ 2 : ℚ) = 46.5390625 ∧
    (0.30 * 70 + 0.00625 * 70 ^ 2 : ℚ) = 51.625 := by norm_num
-- Its best bound is £44.40 at the price 0.375: pump 1 at 36 kW, and pump 2's priced cost
-- 39.375 - 0.375 x 105 is 0.
example : ((2 * 0.375 - 0.30) / 0.0125 : ℚ) = 36 ∧ (39.375 - 0.375 * 105 : ℚ) = 0 ∧
    (0.375 * 140 + 0.30 * 36 + 0.00625 * 36 ^ 2 - 0.375 * 2 * 36 : ℚ) = 44.4 := by norm_num

#print axioms weak_aux
#print axioms dual_function_le_best_cost
#print axioms dual_function_concave
#print axioms pump_strong_duality

end LagrangianDuality
