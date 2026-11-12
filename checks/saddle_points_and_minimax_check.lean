-- Saddle points: a plan and a price form a saddle point of the Lagrangian exactly when both orders of play give the same value and both players' best choices are reached, the price-setter-first value never exceeds the planner-first value, and at a saddle point the plan is optimal and the price is zero unless the rule binds.
import Mathlib.Data.EReal.Basic
import Mathlib.Data.NNReal.Basic
import Mathlib.Order.CompleteLattice.Basic
import Mathlib.Tactic.NormNum

open NNReal

/-! ### How the card's objects are written here

The plans form any type `α`. The cost is `f₀ : α → ℝ` and the rule is `f₁ x ≤ 0`, with
`f₁ : α → ℝ`. A price is a number `l ≥ 0`, written `l : ℝ≥0`. The Lagrangian (the bill) is
`f₀ x + l * f₁ x`.

The two orders of play may give the values `+∞` or `-∞`, so they are taken in `EReal`, the real
line with `⊥ = -∞` and `⊤ = +∞` added:
* `P x = ⨆ l, (f₀ x + l * f₁ x)`, the price setter's best reply to the plan `x`;
* `q l = ⨅ x, (f₀ x + l * f₁ x)`, the planner's best reply to the price `l` (the dual function);
* `p* = ⨅ x, P x`, planner first; `d* = ⨆ l, q l`, price setter first.

A saddle point is a pair `(xs, ls)` with `f₀ xs + l * f₁ xs ≤ f₀ xs + ls * f₁ xs ≤ f₀ x + ls * f₁ x`
for every price `l ≥ 0` and every plan `x`. -/

/-- The saddle-point theorem (Step 4 and its detailed proof). A plan `xs` and a price `ls ≥ 0`
form a saddle point of the Lagrangian `f₀ x + l * f₁ x` exactly when the two orders of play give
the same value and both players' best choices are reached: the price setter's best reply to `xs`
is the planner-first value `p*`, which equals the price-setter-first value `d*`, which is the
planner's best bill at the price `ls`. -/
theorem saddle_point_iff_equal_values_attained {α : Type*} (f₀ f₁ : α → ℝ) (xs : α) (ls : ℝ≥0) :
    ((∀ l : ℝ≥0, f₀ xs + l * f₁ xs ≤ f₀ xs + ls * f₁ xs) ∧
      (∀ x : α, f₀ xs + ls * f₁ xs ≤ f₀ x + ls * f₁ x)) ↔
    ((⨆ l : ℝ≥0, ((f₀ xs + l * f₁ xs : ℝ) : EReal)) =
        ⨅ x : α, ⨆ l : ℝ≥0, ((f₀ x + l * f₁ x : ℝ) : EReal) ∧
      (⨅ x : α, ⨆ l : ℝ≥0, ((f₀ x + l * f₁ x : ℝ) : EReal)) =
        ⨆ l : ℝ≥0, ⨅ x : α, ((f₀ x + l * f₁ x : ℝ) : EReal) ∧
      (⨆ l : ℝ≥0, ⨅ x : α, ((f₀ x + l * f₁ x : ℝ) : EReal)) =
        ⨅ x : α, ((f₀ x + ls * f₁ x : ℝ) : EReal)) := by
  constructor
  · rintro ⟨h_price, h_plan⟩
    have hA : (⨆ l : ℝ≥0, ((f₀ xs + l * f₁ xs : ℝ) : EReal)) = ((f₀ xs + ls * f₁ xs : ℝ) : EReal) :=
      le_antisymm (iSup_le fun l => EReal.coe_le_coe_iff.2 (h_price l))
        (le_iSup (fun l : ℝ≥0 => ((f₀ xs + l * f₁ xs : ℝ) : EReal)) ls)
    have hB : (⨅ x : α, ((f₀ x + ls * f₁ x : ℝ) : EReal)) = ((f₀ xs + ls * f₁ xs : ℝ) : EReal) :=
      le_antisymm (iInf_le (fun x : α => ((f₀ x + ls * f₁ x : ℝ) : EReal)) xs)
        (le_iInf fun x => EReal.coe_le_coe_iff.2 (h_plan x))
    have hwd := iSup_iInf_le_iInf_iSup
      (fun (l : ℝ≥0) (x : α) => ((f₀ x + l * f₁ x : ℝ) : EReal))
    have hp : (⨅ x : α, ⨆ l : ℝ≥0, ((f₀ x + l * f₁ x : ℝ) : EReal)) ≤
        ((f₀ xs + ls * f₁ xs : ℝ) : EReal) :=
      hA ▸ iInf_le (fun x : α => ⨆ l : ℝ≥0, ((f₀ x + l * f₁ x : ℝ) : EReal)) xs
    have hd : ((f₀ xs + ls * f₁ xs : ℝ) : EReal) ≤
        ⨆ l : ℝ≥0, ⨅ x : α, ((f₀ x + l * f₁ x : ℝ) : EReal) :=
      hB ▸ le_iSup (fun l : ℝ≥0 => ⨅ x : α, ((f₀ x + l * f₁ x : ℝ) : EReal)) ls
    refine ⟨?_, ?_, ?_⟩
    · rw [hA]; exact le_antisymm (hd.trans hwd) hp
    · exact le_antisymm (hp.trans hd) hwd
    · rw [hB]; exact le_antisymm (hwd.trans hp) hd
  · rintro ⟨h1, h2, h3⟩
    have hAB : (⨆ l : ℝ≥0, ((f₀ xs + l * f₁ xs : ℝ) : EReal)) =
        ⨅ x : α, ((f₀ x + ls * f₁ x : ℝ) : EReal) := h1.trans (h2.trans h3)
    have hle1 : ∀ l : ℝ≥0, ((f₀ xs + l * f₁ xs : ℝ) : EReal) ≤
        ⨅ x : α, ((f₀ x + ls * f₁ x : ℝ) : EReal) := fun l =>
      hAB ▸ le_iSup (fun l : ℝ≥0 => ((f₀ xs + l * f₁ xs : ℝ) : EReal)) l
    have hle2 : ∀ x : α, ((f₀ xs + ls * f₁ xs : ℝ) : EReal) ≤ ((f₀ x + ls * f₁ x : ℝ) : EReal) :=
      fun x => (hle1 ls).trans (iInf_le (fun x : α => ((f₀ x + ls * f₁ x : ℝ) : EReal)) x)
    refine ⟨fun l => ?_, fun x => EReal.coe_le_coe_iff.1 (hle2 x)⟩
    exact EReal.coe_le_coe_iff.1
      ((hle1 l).trans (iInf_le (fun x : α => ((f₀ x + ls * f₁ x : ℝ) : EReal)) xs))

/-- Whoever moves second can only gain (Step 3). In every two-player game, convex or not, with
any payoff `L x y` that the `x` player minimises and the `y` player maximises, the value when
the maximiser moves first, `max over y of min over x`, is at most the value when the minimiser
moves first, `min over x of max over y`. For a Lagrangian this is weak duality, `d* ≤ p*`. -/
theorem second_mover_can_only_gain {α β : Type*} (L : α → β → ℝ) :
    (⨆ y : β, ⨅ x : α, (L x y : EReal)) ≤ ⨅ x : α, ⨆ y : β, (L x y : EReal) := by
  exact iSup_iInf_le_iInf_iSup (fun (y : β) (x : α) => (L x y : EReal))

/-- The plan at a saddle point is optimal and the price proves it (Step 4, Optimality). If
`(xs, ls)` is a saddle point of the Lagrangian `f₀ x + l * f₁ x` over prices `l ≥ 0`, then `xs`
meets the rule, no plan meeting the rule costs less, and the price is zero unless the rule
binds: `ls * f₁ xs = 0`. -/
theorem saddle_point_plan_is_optimal {α : Type*} (f₀ f₁ : α → ℝ) (xs : α) (ls : ℝ≥0)
    (h_price : ∀ l : ℝ≥0, f₀ xs + l * f₁ xs ≤ f₀ xs + ls * f₁ xs)
    (h_plan : ∀ x : α, f₀ xs + ls * f₁ xs ≤ f₀ x + ls * f₁ x) :
    f₁ xs ≤ 0 ∧ (∀ x : α, f₁ x ≤ 0 → f₀ xs ≤ f₀ x) ∧ (ls : ℝ) * f₁ xs = 0 := by
  have hf : f₁ xs ≤ 0 := by
    have h := h_price (ls + 1)
    push_cast at h
    nlinarith
  have hl0 : (0 : ℝ) ≤ ls := ls.2
  have hz : (ls : ℝ) * f₁ xs = 0 := by
    have h := h_price 0
    push_cast at h
    nlinarith
  refine ⟨hf, fun x hx => ?_, hz⟩
  have h := h_plan x
  nlinarith

/-! ### The card's worked numbers, exactly

The card's decimals are exact fractions: 0.02 = 1/50, 0.03 = 3/100, 16.6667 = 50/3,
41.6667 = 125/3, 20.8333 = 125/6, 2.4 = 12/5, 79.5833 = 955/12. -/

-- The planner's reply to the price 2.4 = 12/5: x₁ = 25 λ = 60 and x₂ = (50/3) λ = 40 L/s.
example : (25 : ℚ) * (12 / 5) = 60 ∧ (50 / 3 : ℚ) * (12 / 5) = 40 := by norm_num

-- The best price: the shortfall 100 - (125/3) λ is zero at λ* = 12/5.
example : (100 : ℚ) - 125 / 3 * (12 / 5) = 0 := by norm_num

-- Power at the saddle plan: 0.02 × 3600 + 0.03 × 1600 = 72 + 48 = 120 kW, £24 an hour at £0.20.
example : (1 / 50 : ℚ) * 60 ^ 2 = 72 ∧ (3 / 100 : ℚ) * 40 ^ 2 = 48 ∧
    (1 / 50 : ℚ) * 60 ^ 2 + 3 / 100 * 40 ^ 2 = 120 ∧ (120 : ℚ) * (1 / 5) = 24 := by norm_num

-- Dual value: q(12/5) = 100 × 12/5 - (125/6) × (12/5)² = 240 - 120 = 120 kW, so the gap is 0.
example : (100 : ℚ) * (12 / 5) = 240 ∧ (125 / 6 : ℚ) * (12 / 5) ^ 2 = 120 ∧
    (100 : ℚ) * (12 / 5) - 125 / 6 * (12 / 5) ^ 2 = 120 := by norm_num

-- The chart: q(λ) = 100 λ - (125/6) λ² at λ = 2 and 2.8 is 350/3 = 116.6667 kW, and 0 at 4.8.
example : (100 : ℚ) * 2 - 125 / 6 * 2 ^ 2 = 350 / 3 ∧
    (100 : ℚ) * (14 / 5) - 125 / 6 * (14 / 5) ^ 2 = 350 / 3 ∧
    (100 : ℚ) * (24 / 5) - 125 / 6 * (24 / 5) ^ 2 = 0 := by norm_num

-- Price capped at 2: the reply is (50, 100/3) L/s, 250/3 = 83.3333 delivered, 50/3 = 16.6667 short.
example : (25 : ℚ) * 2 = 50 ∧ (50 / 3 : ℚ) * 2 = 100 / 3 ∧ (50 : ℚ) + 100 / 3 = 250 / 3 ∧
    (100 : ℚ) - 250 / 3 = 50 / 3 := by norm_num

-- Two equal pumps (try changing): λ* = 2, plan (50, 50), power 0.02 × 2500 × 2 = 100 kW.
example : (100 : ℚ) / 50 = 2 ∧ (1 / 50 : ℚ) * 50 ^ 2 + 1 / 50 * 50 ^ 2 = 100 := by norm_num

-- More demand (try changing): λ* = 120 / (125/3) = 2.88, plan (72, 48), power 172.8 kW, £34.56.
example : (120 : ℚ) / (125 / 3) = 72 / 25 ∧ (25 : ℚ) * (72 / 25) = 72 ∧
    (50 / 3 : ℚ) * (72 / 25) = 48 ∧ (1 / 50 : ℚ) * 72 ^ 2 + 3 / 100 * 48 ^ 2 = 864 / 5 ∧
    (864 / 5 : ℚ) * (1 / 5) = 864 / 25 := by norm_num

-- Penalty kick [[58, 95], [93, 70]] with plain choices: the kicker moving first can guarantee
-- max (min 58 95) (min 93 70) = 70; the keeper moving first holds the kicker to
-- min (max 58 93) (max 95 70) = 93.
example : max (min 58 95) (min 93 70) = (70 : ℕ) ∧ min (max 58 93) (max 95 70) = (93 : ℕ) := by
  decide

-- Penalty kick with mixing: both orders give (95 × 93 - 58 × 70) / (95 + 93 - 58 - 70) = 955/12.
example : ((95 : ℚ) * 93 - 58 * 70) / (95 + 93 - 58 - 70) = 955 / 12 := by norm_num

-- Price adjustment: the error shrinks by 1 - 0.01 × 125/3 = 7/12 = 0.5833 each step, and a step
-- converges only below 2 / (125/3) = 0.048; at 0.04 the ratio is 1 - 0.04 × 125/3 = -2/3.
example : (1 : ℚ) - 1 / 100 * (125 / 3) = 7 / 12 ∧ (2 : ℚ) / (125 / 3) = 6 / 125 ∧
    (1 : ℚ) - 4 / 100 * (125 / 3) = -2 / 3 := by norm_num

#print axioms saddle_point_iff_equal_values_attained
#print axioms second_mover_can_only_gain
#print axioms saddle_point_plan_is_optimal
