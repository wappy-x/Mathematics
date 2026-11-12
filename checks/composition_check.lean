-- Composing functions: for every price over $5, taking 20% off then a $5 coupon gives 0.8 × price − 5 while the coupon first gives 0.8 × price − 4, so the coupon-first order always costs exactly $1 more; the do-nothing rule changes no chain, regrouping a chain of three changes nothing, and the card's jacket and coat numbers come out as it says.
import Mathlib.Algebra.Order.Ring.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- The 20% offer `f`: keep four fifths of the price. -/
def percentOff (price : ℚ) : ℚ := 4 / 5 * price

/-- The $5 coupon `g`: take five dollars off the price. -/
def couponOff (price : ℚ) : ℚ := price - 5

/-- Order changes the answer. For any price over $5, "g after f" (20% off first, then the
coupon) collapses to the one rule `0.8 × price − 5`, and "f after g" (the coupon first, then
20% off) collapses to `0.8 × price − 4`. So the coupon-first order costs exactly $1 more,
whatever the price: through the 20%, the $5 coupon is worth only $4. -/
theorem coupon_first_costs_one_dollar_more (price : ℚ) (h : 5 < price) :
    (couponOff ∘ percentOff) price = 4 / 5 * price - 5 ∧
      (percentOff ∘ couponOff) price = 4 / 5 * price - 4 ∧
      (percentOff ∘ couponOff) price = (couponOff ∘ percentOff) price + 1 := by
  have h1 : (couponOff ∘ percentOff) price = 4 / 5 * price - 5 := by
    simp [Function.comp, couponOff, percentOff]
  have h2 : (percentOff ∘ couponOff) price = 4 / 5 * price - 4 := by
    simp only [Function.comp, couponOff, percentOff]; ring
  refine ⟨h1, h2, ?_⟩
  rw [h1, h2]; ring

/-- The do-nothing rule changes no chain: putting the identity on either end of any function
`f` gives back `f`. -/
theorem identity_changes_nothing {α β : Type*} (f : α → β) :
    id ∘ f = f ∧ f ∘ id = f := by
  exact ⟨rfl, rfl⟩

/-- With three rules in a queue, only the queue order matters: collapsing the first pair or
the last pair into one rule first gives the same chain. -/
theorem composing_is_associative {α β γ δ : Type*} (f : α → β) (g : β → γ) (h : γ → δ) :
    h ∘ (g ∘ f) = (h ∘ g) ∘ f := by
  rfl

-- The jacket: 20% off $50, then the coupon.
example : percentOff 50 = 40 := by norm_num [percentOff]
example : couponOff 40 = 35 := by norm_num [couponOff]
example : (couponOff ∘ percentOff) 50 = 35 := by norm_num [couponOff, percentOff]
-- The coupon first, then 20% off.
example : couponOff 50 = 45 := by norm_num [couponOff]
example : percentOff 45 = 36 := by norm_num [percentOff]
example : (percentOff ∘ couponOff) 50 = 36 := by norm_num [couponOff, percentOff]
-- The gap, and the coupon seen through the 20%.
example : (36 : ℚ) - 35 = 1 := by norm_num
example : percentOff 5 = 4 := by norm_num [percentOff]
-- The same orders on an $80 coat.
example : (couponOff ∘ percentOff) 80 = 59 := by norm_num [couponOff, percentOff]
example : (percentOff ∘ couponOff) 80 = 60 := by norm_num [couponOff, percentOff]
-- Do nothing, then 20% off: what the 20% does alone.
example : (percentOff ∘ id) 50 = 40 := by norm_num [percentOff]
-- The mistake: taking the 20% off the $50 tag instead of the $45 left.
example : percentOff 50 = 40 ∧ percentOff (couponOff 50) = 36 := by norm_num [couponOff, percentOff]

#print axioms coupon_first_costs_one_dollar_more
#print axioms identity_changes_nothing
#print axioms composing_is_associative
