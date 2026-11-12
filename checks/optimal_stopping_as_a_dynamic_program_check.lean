-- Optimal stopping: backward induction gives the best stop-or-wait rule over every rule that sees only past prices, and the set of prices where stopping wins only grows as the deadline nears.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

open Finset

namespace OptimalStopping

/-! ## The setting

A finite set `S` of prices (states), the reward `r x` paid on selling at `x`, the chance
`p x y` that the price moves from `x` to `y` in one month, and the storage cost `c` per month.
The deadline is month `N`. Numbers live in any ordered field `𝕜` (the reals, or the rationals
used for the card's exact example). -/

variable {𝕜 : Type*} [Field 𝕜] [LinearOrder 𝕜] [IsStrictOrderedRing 𝕜]
variable {S : Type*} [Fintype S]

/-- Value with `m` months left: `m = 0` is the deadline, where the block must be sold. -/
def valueLeft (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) : ℕ → S → 𝕜
  | 0, x => r x
  | m + 1, x => max (r x) (-c + ∑ y, p x y * valueLeft p r c m y)

/-- The card's `V_k(x)`: the value in month `k` of an `N`-month season, `V_N(x) = x`,
`V_k(x) = max(x, W_k(x))`. -/
def V (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (N k : ℕ) (x : S) : 𝕜 :=
  valueLeft p r c (N - k) x

/-- The card's wait value `W_k(x) = -c + ∑ p(x' | x) V_{k+1}(x')`, for `k < N`. -/
def W (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (N k : ℕ) (x : S) : 𝕜 :=
  -c + ∑ y, p x y * V p r c N (k + 1) y

/-- A stopping rule that decides from the prices seen so far: given the list of prices up to
and including today's, `σ` says stop (`true`) or wait (`false`). It may depend on the whole
past path, and on the month, which is the length of that list. -/
abbrev Rule (S : Type*) := List S → Bool

/-- The average net result of following rule `σ` with `m` months left, past prices `h`, and
today's price `x`: on stopping, take `r x`; on waiting, pay `c` and average over next month.
At the deadline (`m = 0`) the block is sold whatever the rule says. Stopping is final. -/
def ruleValue (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (σ : Rule S) : ℕ → List S → S → 𝕜
  | 0, _, x => r x
  | m + 1, h, x =>
      if σ (h ++ [x]) then r x
      else -c + ∑ y, p x y * ruleValue p r c σ m (h ++ [x]) y

/-- The card's bar rule for an `N`-month season: in month `k` (the price list has `k + 1`
entries), sell at price `x` exactly when `x ≥ W_k(x)`. -/
def barRule (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (N : ℕ) : Rule S := fun h =>
  match h.getLast? with
  | none => false
  | some x => decide (W p r c N (h.length - 1) x ≤ r x)

/-- Any rule averages at most the table value, from any past and any number of months left. -/
theorem ruleValue_le_valueLeft
    (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (hp : ∀ x y, 0 ≤ p x y) (σ : Rule S) :
    ∀ (m : ℕ) (h : List S) (x : S), ruleValue p r c σ m h x ≤ valueLeft p r c m x := by
  intro m
  induction m with
  | zero => intro h x; simp [ruleValue, valueLeft]
  | succ m ih =>
    intro h x
    simp only [ruleValue, valueLeft]
    split_ifs
    · exact le_max_left _ _
    · refine le_trans ?_ (le_max_right _ _)
      have : ∑ y, p x y * ruleValue p r c σ m (h ++ [x]) y ≤ ∑ y, p x y * valueLeft p r c m y :=
        Finset.sum_le_sum fun y _ => mul_le_mul_of_nonneg_left (ih _ y) (hp x y)
      exact add_le_add le_rfl this

omit [IsStrictOrderedRing 𝕜] in
/-- The bar rule averages exactly the table value, whenever the past has `N - m` entries. -/
theorem ruleValue_barRule
    (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (N : ℕ) :
    ∀ (m : ℕ) (h : List S) (x : S), h.length + m = N →
      ruleValue p r c (barRule p r c N) m h x = valueLeft p r c m x := by
  intro m
  induction m with
  | zero => intro h x _; simp [ruleValue, valueLeft]
  | succ m ih =>
    intro h x hN
    have hW : W p r c N h.length x = -c + ∑ y, p x y * valueLeft p r c m y := by
      simp only [W, V]
      congr 2
      have : N - (h.length + 1) = m := by omega
      rw [this]
    have hb : barRule p r c N (h ++ [x]) = decide (W p r c N h.length x ≤ r x) := by
      simp [barRule]
    simp only [ruleValue, valueLeft, hb, hW]
    by_cases hc : -c + ∑ y, p x y * valueLeft p r c m y ≤ r x
    · simp [hc]
    · have hsum : ∑ y, p x y * ruleValue p r c (barRule p r c N) m (h ++ [x]) y
          = ∑ y, p x y * valueLeft p r c m y := by
        refine Finset.sum_congr rfl fun y _ => ?_
        rw [ih (h ++ [x]) y (by simp; omega)]
      simp only [hc, decide_false, Bool.false_eq_true, ite_false, hsum]
      exact (max_eq_right (le_of_lt (not_le.mp hc))).symm

/-- One more month left never lowers the value. -/
theorem valueLeft_mono_succ
    (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜) (hp : ∀ x y, 0 ≤ p x y) :
    ∀ (m : ℕ) (x : S), valueLeft p r c m x ≤ valueLeft p r c (m + 1) x := by
  intro m
  induction m with
  | zero => intro x; simp only [valueLeft]; exact le_max_left _ _
  | succ m ih =>
    intro x
    simp only [valueLeft]
    refine max_le_max le_rfl ?_
    have : ∑ y, p x y * valueLeft p r c m y ≤ ∑ y, p x y * valueLeft p r c (m + 1) y :=
      Finset.sum_le_sum fun y _ => mul_le_mul_of_nonneg_left (ih y) (hp x y)
    exact add_le_add le_rfl this

#print axioms ruleValue_le_valueLeft
#print axioms ruleValue_barRule
#print axioms valueLeft_mono_succ

/-- **Optimal stopping is backward induction.** If the price is a Markov chain (the chances
`p x y` are not negative and each row adds up to 1), then for a season with deadline `N`:
no rule that decides from the prices seen so far averages more than the table value `V_0(x)`,
and the rule "sell when the price is at least the wait value" averages exactly `V_0(x)`. -/
theorem optimal_stopping_is_backward_induction
    (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜)
    (hp : ∀ x y, 0 ≤ p x y) (hsum : ∀ x, ∑ y, p x y = 1) (N : ℕ) (x : S) :
    (∀ σ : Rule S, ruleValue p r c σ N [] x ≤ V p r c N 0 x) ∧
      ruleValue p r c (barRule p r c N) N [] x = V p r c N 0 x := by
  refine ⟨fun σ => ?_, ?_⟩
  · simpa [V] using ruleValue_le_valueLeft p r c hp σ N [] x
  · simpa [V] using ruleValue_barRule p r c N N [] x (by simp)

/-- **More months left can only help:** `V_k(x) ≥ V_{k+1}(x)` at every price, for every
month `k` before the deadline. -/
theorem value_falls_toward_deadline
    (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜)
    (hp : ∀ x y, 0 ≤ p x y) (hsum : ∀ x, ∑ y, p x y = 1) (N k : ℕ) (hk : k < N) (x : S) :
    V p r c N (k + 1) x ≤ V p r c N k x := by
  have h1 : N - k = (N - (k + 1)) + 1 := by omega
  simp only [V]
  rw [h1]
  exact valueLeft_mono_succ p r c hp _ x

/-- **The bar falls toward the deadline:** if selling wins at price `x` in month `k`
(`x ≥ W_k(x)`), then selling also wins at `x` in month `k + 1`. So every sell price stays a
sell price, and the bar `b_k`, the lowest sell price, satisfies `b_{k+1} ≤ b_k`. -/
theorem stopping_set_grows_toward_deadline
    (p : S → S → 𝕜) (r : S → 𝕜) (c : 𝕜)
    (hp : ∀ x y, 0 ≤ p x y) (hsum : ∀ x, ∑ y, p x y = 1) (N k : ℕ) (hk : k + 1 < N) (x : S)
    (hstop : W p r c N k x ≤ r x) :
    W p r c N (k + 1) x ≤ r x := by
  refine le_trans ?_ hstop
  simp only [W]
  have : ∑ y, p x y * V p r c N (k + 1 + 1) y ≤ ∑ y, p x y * V p r c N (k + 1) y :=
    Finset.sum_le_sum fun y _ =>
      mul_le_mul_of_nonneg_left (value_falls_toward_deadline p r c hp hsum N (k + 1) hk y) (hp x y)
  exact add_le_add le_rfl this

/-! ## The card's model, in exact rational arithmetic

Prices `60, 70, …, 140` (£ thousand) at grid steps `i = 0, …, 8`. From step `i` the price
rises with chance `1/2 - (i - 4)/50` and falls with chance `1/2 + (i - 4)/50`; at the grid's
ends the blocked move stays put. Storage costs 1 a month; the season runs 6 months. -/

/-- The forward price at grid step `i`, £ thousand. -/
def price (i : Fin 9) : ℚ := 60 + 10 * (i : ℚ)

/-- Chance of a rise from grid step `i`. -/
def upChance (i : Fin 9) : ℚ := 1 / 2 - ((i : ℚ) - 4) / 50

/-- The card's transition chances, with a blocked move at either end staying put. -/
def chance (i j : Fin 9) : ℚ :=
  (if (j : ℕ) = min ((i : ℕ) + 1) 8 then upChance i else 0) +
    (if (j : ℕ) = (i : ℕ) - 1 then 1 - upChance i else 0)

/-- The card's bars, months June (`k = 0`) to November (`k = 5`): 100, 100, 90, 90, 80, 80. -/
def bar : Fin 6 → ℚ := ![100, 100, 90, 90, 80, 80]

-- The card's model is a Markov chain: chances are not negative and each row adds up to 1.
example : ∀ i j, 0 ≤ chance i j := by decide +kernel
example : ∀ i, ∑ j, chance i j = 1 := by decide +kernel

-- One bar per month, at the card's values: in month k, sell at price x exactly when x ≥ b_k.
example : ∀ k : Fin 6, ∀ i : Fin 9,
    (W chance price 1 6 k i ≤ price i ↔ bar k ≤ price i) := by decide +kernel

-- The value of the block on 1 June at £80,000, exactly (82.3598…, shown as 82.36 on the card).
example : V chance price 1 6 0 2 = 12868727317 / 156250000 := by decide +kernel

-- Hand checks for 1 November (V_6(x) = x): wait values 70.20 > 70, 79.80 < 80, 89.40 < 90.
example : (44 : ℚ) / 100 * 60 + 56 / 100 * 80 - 1 = 351 / 5 ∧ (70 : ℚ) < 351 / 5 := by norm_num
example : (46 : ℚ) / 100 * 70 + 54 / 100 * 90 - 1 = 399 / 5 ∧ (399 : ℚ) / 5 < 80 := by norm_num
example : (48 : ℚ) / 100 * 80 + 52 / 100 * 100 - 1 = 447 / 5 ∧ (447 : ℚ) / 5 < 90 := by norm_num

-- 1 October at 80: 0.46 × 70.20 + 0.54 × 90 − 1 = 79.892 < 80, so sell; the bar is 80.
example : (46 : ℚ) / 100 * (351 / 5) + 54 / 100 * 90 - 1 < 80 := by norm_num

-- The story season: sold on 1 September at 90 after three months' storage, net 87.
example : 90 - 3 * 1 = 87 := by norm_num

-- Road 3 lists every pair of stop sets for October and November: 512 × 512 = 262,144.
example : 2 ^ 9 * 2 ^ 9 = 262144 := by norm_num

#print axioms optimal_stopping_is_backward_induction
#print axioms value_falls_toward_deadline
#print axioms stopping_set_grows_toward_deadline

end OptimalStopping
