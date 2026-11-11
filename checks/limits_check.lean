-- Limits: the fraction (x^2 - 1)/(x - 1) heads for 2 as x heads for 1, any straight line of nonzero slope m meets an output tolerance with an input distance of tolerance ÷ |m|, and a rule that jumps from 0 to 1 at 1 has no limit there.
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum

open Filter Topology

/-- The card's main example. As x heads for 1, with x = 1 itself left out, the fraction
(x^2 - 1)/(x - 1) heads for 2. In Mathlib's terms: the fraction tends to 2 along the inputs
near 1 other than 1 (the filter `𝓝[≠] 1`), which unfolds to the card's promise: for every
output tolerance there is an input distance keeping every x with 0 < |x - 1| < distance
within that tolerance of 2. The value of the fraction at 1 is never tested. -/
theorem fraction_tends_to_two_at_one :
    Tendsto (fun x : ℝ => (x ^ 2 - 1) / (x - 1)) (𝓝[≠] (1 : ℝ)) (𝓝 2) := by
  have h1 : Tendsto (fun x : ℝ => x + 1) (𝓝[≠] (1 : ℝ)) (𝓝 2) := by
    have : Tendsto (fun x : ℝ => x + 1) (𝓝 (1 : ℝ)) (𝓝 (1 + 1)) :=
      (continuous_id.add continuous_const).tendsto 1
    norm_num at this
    exact this.mono_left nhdsWithin_le_nhds
  refine h1.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with x hx
  have hx' : x - 1 ≠ 0 := sub_ne_zero.mpr hx
  field_simp
  ring

/-- The linear case, Steps 3 and 4. For a straight line m x + c with slope m not zero, at any
point a: for every output tolerance ε > 0, the input distance ε / |m| is positive and keeps
every x with 0 < |x - a| < ε / |m| within ε of the line's value m a + c. -/
theorem line_distance_is_tolerance_over_slope (m c a : ℝ) (hm : m ≠ 0) (ε : ℝ) (hε : 0 < ε) :
    0 < ε / |m| ∧
      ∀ x : ℝ, 0 < |x - a| → |x - a| < ε / |m| → |(m * x + c) - (m * a + c)| < ε := by
  have hm' : 0 < |m| := abs_pos.mpr hm
  refine ⟨div_pos hε hm', fun x _ hx => ?_⟩
  have e : (m * x + c) - (m * a + c) = m * (x - a) := by ring
  rw [e, abs_mul]
  calc |m| * |x - a| < |m| * (ε / |m|) := mul_lt_mul_of_pos_left hx hm'
    _ = ε := by field_simp

/-- Step 5, the jump. The rule giving 0 for x below 1 and 1 from 1 upwards has no limit at 1:
there is no value L that the outputs head for as x heads for 1, with 1 itself left out. -/
theorem jump_has_no_limit_at_one :
    ¬ ∃ L : ℝ, Tendsto (fun x : ℝ => if x < 1 then (0 : ℝ) else 1) (𝓝[≠] (1 : ℝ)) (𝓝 L) := by
  rintro ⟨L, hL⟩
  have hlt : Tendsto (fun x : ℝ => if x < 1 then (0 : ℝ) else 1) (𝓝[<] (1 : ℝ)) (𝓝 L) :=
    hL.mono_left (nhdsWithin_mono _ (fun x hx => by simpa using ne_of_lt (show x < 1 from hx)))
  have hgt : Tendsto (fun x : ℝ => if x < 1 then (0 : ℝ) else 1) (𝓝[>] (1 : ℝ)) (𝓝 L) :=
    hL.mono_left (nhdsWithin_mono _ (fun x hx => by simpa using ne_of_gt (show 1 < x from hx)))
  have h0 : Tendsto (fun x : ℝ => if x < 1 then (0 : ℝ) else 1) (𝓝[<] (1 : ℝ)) (𝓝 0) := by
    refine tendsto_const_nhds.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with x hx
    simp [show x < 1 from hx]
  have h1 : Tendsto (fun x : ℝ => if x < 1 then (0 : ℝ) else 1) (𝓝[>] (1 : ℝ)) (𝓝 1) := by
    refine tendsto_const_nhds.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with x hx
    simp [not_lt.mpr (le_of_lt (show 1 < x from hx))]
  have e0 : L = 0 := tendsto_nhds_unique hlt h0
  have e1 : L = 1 := tendsto_nhds_unique hgt h1
  rw [e0] at e1
  norm_num at e1

-- The card's numbers, exactly, as fractions. Just below and just above 1 (x = 999/1000 and 1001/1000).
example : (((999 / 1000 : ℚ) ^ 2 - 1) = -1999 / 1000000) ∧ ((999 / 1000 : ℚ) - 1 = -1 / 1000) ∧
    ((999 / 1000 : ℚ) ^ 2 - 1) / ((999 / 1000 : ℚ) - 1) = 1999 / 1000 := by norm_num
example : (((1001 / 1000 : ℚ) ^ 2 - 1) = 2001 / 1000000) ∧ ((1001 / 1000 : ℚ) - 1 = 1 / 1000) ∧
    ((1001 / 1000 : ℚ) ^ 2 - 1) / ((1001 / 1000 : ℚ) - 1) = 2001 / 1000 := by norm_num
-- At x = 1 top and bottom are both 0.
example : (1 : ℤ) ^ 2 - 1 = 0 ∧ (1 : ℤ) - 1 = 0 := by decide
-- The cancelling: x^2 - 1 = (x - 1)(x + 1), checked at whole numbers.
example : (5 : ℤ) ^ 2 - 1 = (5 - 1) * (5 + 1) ∧ (-3 : ℤ) ^ 2 - 1 = (-3 - 1) * (-3 + 1) := by decide
-- Both lines pass through (1, 2): x + 1 and 3x - 1.
example : (1 : ℤ) + 1 = 2 ∧ 3 * (1 : ℤ) - 1 = 2 := by decide
-- Reusing distance 1/1000 for 3x - 1 fails: x = 10009/10000 misses 2 by 27/10000, more than 1/1000.
example : |3 * (10009 / 10000 : ℚ) - 1 - 2| = 27 / 10000 ∧ (1 / 1000 : ℚ) < 27 / 10000 := by
  norm_num [abs_of_pos]
-- The jump: the best candidate 1/2 misses both outputs 0 and 1 by 1/2, more than the tolerance 1/4.
example : |(0 : ℚ) - 1 / 2| = 1 / 2 ∧ |(1 : ℚ) - 1 / 2| = 1 / 2 ∧ (1 / 4 : ℚ) < 1 / 2 := by
  norm_num [abs_of_pos]

#print axioms fraction_tends_to_two_at_one
#print axioms line_distance_is_tolerance_over_slope
#print axioms jump_has_no_limit_at_one
