-- Structured rate notes: a range accrual is priced exactly as long digitals at the band's bottom less short digitals at its top, an inverse floater's coupon is a floorlet spread and equally a fixed coupon plus a caplet spread, and on the card's coin model the backward tree gives the issuer's cheapest call policy.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Tactic.Linarith
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Rat.Defs
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- Range accrual, priced by its parts. Under any pricing law `μ` for the payment date (no
independence between fixings, no particular model), with every fixing paid on one date with one
discount factor `D`, a note of face `M` paying the coupon rate `c` for each of `n` fixings that lands
in the band `a ≤ L < b` is worth `M c D (1/n)` times the sum over the fixings of
(chance the fixing is at or above `a`) minus (chance it is at or above `b`): a long digital at the
bottom of the band less a short digital at the top, fixing by fixing. -/
theorem range_accrual_price_eq_long_short_digitals
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {n : ℕ} (L : Fin n → Ω → ℝ) (hL : ∀ j, Measurable (L j))
    (M c D a b : ℝ) (hab : a ≤ b) :
    D * ∫ ω, ∑ j, M * c / n * (if a ≤ L j ω ∧ L j ω < b then (1 : ℝ) else 0) ∂μ
      = M * c * D * (1 / n) *
          ∑ j, (μ.real {ω | a ≤ L j ω} - μ.real {ω | b ≤ L j ω}) := by
  have hA : ∀ j, MeasurableSet {ω | a ≤ L j ω} := fun j => measurableSet_le measurable_const (hL j)
  have hB : ∀ j, MeasurableSet {ω | b ≤ L j ω} := fun j => measurableSet_le measurable_const (hL j)
  have hfun : ∀ j, (fun ω => M * c / n * (if a ≤ L j ω ∧ L j ω < b then (1 : ℝ) else 0))
      = fun ω => M * c / n * ({ω | a ≤ L j ω} \ {ω | b ≤ L j ω}).indicator 1 ω := by
    intro j; ext ω
    by_cases h1 : a ≤ L j ω <;> by_cases h2 : L j ω < b <;>
      simp [h1, h2, not_le.mpr, not_lt.mp]
  have key : ∀ j, ∫ ω, M * c / n * (if a ≤ L j ω ∧ L j ω < b then (1 : ℝ) else 0) ∂μ
      = M * c / n * (μ.real {ω | a ≤ L j ω} - μ.real {ω | b ≤ L j ω}) := by
    intro j
    rw [hfun j, integral_const_mul, integral_indicator_one ((hA j).diff (hB j)),
      measureReal_sdiff _ (hB j)]
    intro ω hω; exact le_trans hab hω
  have hint : ∀ j ∈ (Finset.univ : Finset (Fin n)),
      Integrable (fun ω => M * c / n * (if a ≤ L j ω ∧ L j ω < b then (1 : ℝ) else 0)) μ := by
    intro j _
    rw [hfun j]
    exact ((integrable_const (1 : ℝ)).indicator ((hA j).diff (hB j))).const_mul _
  rw [integral_finsetSum _ hint]
  simp only [key, ← Finset.mul_sum]
  ring

/-- Inverse floater. For every rate `L`, the coupon rate `min(8%, max(0, 10% - 2L))` equals two
floorlets struck at 5% less two struck at 1%, `2[(5% - L)⁺ - (1% - L)⁺]`, and equally a fixed 8%
plus two caplets at 5% less two caplets at 1%, `8% + 2(L - 5%)⁺ - 2(L - 1%)⁺`. -/
theorem inverse_floater_eq_floor_spread_eq_fixed_plus_cap_spread (L : ℝ) :
    min (8 / 100) (max 0 (10 / 100 - 2 * L))
        = 2 * (max (5 / 100 - L) 0 - max (1 / 100 - L) 0) ∧
      min (8 / 100) (max 0 (10 / 100 - 2 * L))
        = 8 / 100 + 2 * max (L - 5 / 100) 0 - 2 * max (L - 1 / 100) 0 := by
  rcases le_total L (1 / 100) with h1 | h1
  · rw [max_eq_right (by linarith : (0:ℝ) ≤ 10 / 100 - 2 * L), min_eq_left (by linarith),
      max_eq_left (by linarith : (0:ℝ) ≤ 5 / 100 - L), max_eq_left (by linarith : (0:ℝ) ≤ 1 / 100 - L),
      max_eq_right (by linarith : L - 5 / 100 ≤ 0), max_eq_right (by linarith : L - 1 / 100 ≤ 0)]
    constructor <;> ring
  rcases le_total L (5 / 100) with h2 | h2
  · rw [max_eq_right (by linarith : (0:ℝ) ≤ 10 / 100 - 2 * L), min_eq_right (by linarith),
      max_eq_left (by linarith : (0:ℝ) ≤ 5 / 100 - L), max_eq_right (by linarith : 1 / 100 - L ≤ 0),
      max_eq_right (by linarith : L - 5 / 100 ≤ 0), max_eq_left (by linarith : 0 ≤ L - 1 / 100)]
    constructor <;> ring
  · rw [max_eq_left (by linarith : 10 / 100 - 2 * L ≤ (0:ℝ)), min_eq_right (by norm_num),
      max_eq_right (by linarith : 5 / 100 - L ≤ 0), max_eq_right (by linarith : 1 / 100 - L ≤ 0),
      max_eq_left (by linarith : 0 ≤ L - 5 / 100), max_eq_left (by linarith : 0 ≤ L - 1 / 100)]
    constructor <;> ring

/-! ### The card's target redemption note on a coin

Three half-year dates. Each date the rate is in band ("hit") with chance one half. A hit earns a raw
coupon of 30, clipped to what is left of the target 50; the face 1000 is repaid the day the coupons
reach 50, or at date 3. Discount 0.98 a period. The issuer may call at 980 after date 1 and at 985
after date 2. -/

/-- Discount factor per period, 0.98. -/
def coinDisc : ℚ := 49 / 50

/-- The issuer's call price after date `i`: 980 after date 1, 985 after date 2. -/
def callPrice (i : ℕ) : ℚ := if i = 1 then 980 else 985

/-- Backward tree: value just before the coupon at date `i`, with `earned` already paid, `hit`
saying whether date `i` is in band and `k` dates still to come. With `call` the issuer takes
`min (call price, value of staying alive)` just after the coupon. -/
def treeNode (call : Bool) : ℕ → ℕ → ℚ → Bool → ℚ
  | 0, _, earned, hit => min (if hit then 30 else 0) (50 - earned) + 1000
  | k + 1, i, earned, hit =>
    let cpn := min (if hit then 30 else 0) (50 - earned)
    if earned + cpn = 50 then cpn + 1000
    else
      let alive := coinDisc *
        (treeNode call k (i + 1) (earned + cpn) true + treeNode call k (i + 1) (earned + cpn) false) / 2
      cpn + (if call then min (callPrice i) alive else alive)

/-- The note's value today from the backward tree. -/
def treeValue (call : Bool) : ℚ :=
  coinDisc * (treeNode call 2 1 0 true + treeNode call 2 1 0 false) / 2

/-- Present value along one coin path `(b₁, b₂, b₃)` when the issuer calls after the dates where
the rule `pol`, which sees only the history so far, says so. -/
def pathValue (pol : List Bool → Bool) (b₁ b₂ b₃ : Bool) : ℚ :=
  let c₁ : ℚ := if b₁ then 30 else 0
  if pol [b₁] then coinDisc * (c₁ + callPrice 1)
  else
    let c₂ : ℚ := min (if b₂ then 30 else 0) (50 - c₁)
    if c₁ + c₂ = 50 then coinDisc * c₁ + coinDisc ^ 2 * (c₂ + 1000)
    else if pol [b₁, b₂] then coinDisc * c₁ + coinDisc ^ 2 * (c₂ + callPrice 2)
    else
      let c₃ : ℚ := min (if b₃ then 30 else 0) (50 - c₁ - c₂)
      coinDisc * c₁ + coinDisc ^ 2 * c₂ + coinDisc ^ 3 * (c₃ + 1000)

/-- Value today under a call rule: the average over the eight equally likely coin paths. -/
def policyValue (pol : List Bool → Bool) : ℚ :=
  (∑ p : Bool × Bool × Bool, pathValue pol p.1 p.2.1 p.2.2) / 8

/-- Issuer call priced backwards. On the card's coin note, the backward tree's callable value is the
smallest value the issuer can reach with any rule that decides "call or not" from the history so
far, and some rule reaches it. -/
theorem callable_tree_value_eq_min_over_call_rules :
    (∀ pol : List Bool → Bool, treeValue true ≤ policyValue pol) ∧
      ∃ pol : List Bool → Bool, policyValue pol = treeValue true := by
  have hT : treeValue true = 9751 / 10 := by
    norm_num [treeValue, treeNode, coinDisc, callPrice, min_def]
  rw [hT]
  refine ⟨fun pol => ?_, ⟨fun _ => true, ?_⟩⟩
  · simp only [policyValue, Fintype.sum_prod_type, Fintype.sum_bool]
    cases h1 : pol [true] <;> cases h2 : pol [false] <;> cases h3 : pol [true, true] <;>
      cases h4 : pol [true, false] <;> cases h5 : pol [false, true] <;>
      cases h6 : pol [false, false] <;>
      norm_num [pathValue, coinDisc, callPrice, min_def, h1, h2, h3, h4, h5, h6]
  · simp only [policyValue, Fintype.sum_prod_type, Fintype.sum_bool]
    norm_num [pathValue, coinDisc, callPrice]

/-- Each month's range coupon: $1,000 × 6% ÷ 12 = $5. -/
example : (1000 : ℚ) * (6 / 100) / 12 = 5 := by norm_num

/-- The inverse floater's ceiling: 2 × (5% − 1%) = 8%. -/
example : (2 : ℚ) * (5 / 100 - 1 / 100) = 8 / 100 := by norm_num

/-- Target note, uncalled, by the backward tree: $980.93443. -/
example : treeValue false = 98093443 / 100000 := by norm_num [treeValue, treeNode, coinDisc, min_def]

/-- Target note, uncalled, by walking all eight paths (never calling): the same $980.93443. -/
example : policyValue (fun _ => false) = 98093443 / 100000 := by simp only [policyValue, Fintype.sum_prod_type, Fintype.sum_bool]; norm_num [pathValue, coinDisc, min_def]

/-- Target note, callable, by the backward tree: $975.10. -/
example : treeValue true = 9751 / 10 := by norm_num [treeValue, treeNode, coinDisc, callPrice, min_def]

#print axioms range_accrual_price_eq_long_short_digitals
#print axioms inverse_floater_eq_floor_spread_eq_fixed_plus_cap_spread
#print axioms callable_tree_value_eq_min_over_call_rules
