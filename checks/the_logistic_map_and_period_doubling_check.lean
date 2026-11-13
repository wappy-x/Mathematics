-- The logistic map: for a dial r between 3 and 1 + √6 the steady share repels and the two-summer cycle attracts, with multiplier 4 + 2r - r^2.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.Order.Field

open Filter Topology

/-- The logistic map with dial `r`: next summer's share is `r * x * (1 - x)`. -/
def logistic (r x : ℝ) : ℝ := r * x * (1 - x)

lemma logistic_deriv_eq (r x : ℝ) : deriv (logistic r) x = r * (1 - 2 * x) := by
  have h : HasDerivAt (fun y : ℝ => r * y * (1 - y)) (r * 1 * (1 - x) + r * x * (0 - 1)) x :=
    ((hasDerivAt_id' x).const_mul r).mul ((hasDerivAt_const x (1:ℝ)).sub (hasDerivAt_id' x))
  have h' : HasDerivAt (logistic r) (r * 1 * (1 - x) + r * x * (0 - 1)) x := h
  rw [h'.deriv]; ring

lemma logistic_sub (r x y : ℝ) : logistic r x - logistic r y = r * (x - y) * (1 - x - y) := by
  unfold logistic; ring

lemma logistic_continuous (r : ℝ) : Continuous (logistic r) := by
  unfold logistic; fun_prop

lemma logistic_stable_iff_aux (r : ℝ) (h0 : 0 < r) :
    |4 + 2 * r - r ^ 2| < 1 ↔ 3 < r ∧ r < 1 + Real.sqrt 6 := by
  have hs : Real.sqrt 6 ^ 2 = 6 := Real.sq_sqrt (by norm_num)
  have hs0 : 0 ≤ Real.sqrt 6 := Real.sqrt_nonneg 6
  have hs1 : 1 < Real.sqrt 6 := by nlinarith
  rw [abs_lt]
  constructor
  · rintro ⟨h1, h2⟩
    refine ⟨by nlinarith, ?_⟩
    by_contra h
    rw [not_lt] at h
    nlinarith
  · rintro ⟨h1, h2⟩
    constructor
    · nlinarith
    · nlinarith

/-- Local attraction for a fixed point of a map whose difference quotient at the point is
controlled by a continuous function with value of size below 1. -/
lemma attract_of_factor (g Q : ℝ → ℝ) (a : ℝ) (hQ : Continuous Q) (hQa : |Q a| < 1)
    (hg : ∀ x, g x - a = (x - a) * Q x) :
    ∃ ε > 0, ∀ x₀ : ℝ, |x₀ - a| < ε → Tendsto (fun n : ℕ => g^[n] x₀) atTop (𝓝 a) := by
  set k := (1 + |Q a|) / 2 with hk
  have hk1 : k < 1 := by rw [hk]; linarith
  have hk0 : 0 ≤ k := by rw [hk]; positivity
  have hpos : 0 < (1 - |Q a|) / 2 := by linarith
  obtain ⟨ε, hε, hball⟩ := Metric.continuousAt_iff.mp hQ.continuousAt _ hpos
  refine ⟨ε, hε, fun x₀ hx₀ => ?_⟩
  have hbound : ∀ y, |y - a| < ε → |Q y| ≤ k := by
    intro y hy
    have := hball (by rw [Real.dist_eq]; exact hy)
    rw [Real.dist_eq] at this
    have h2 : |Q y| ≤ |Q y - Q a| + |Q a| := by
      have := abs_add_le (Q y - Q a) (Q a); simpa using this
    rw [hk]; linarith
  have key : ∀ n : ℕ, |g^[n] x₀ - a| ≤ k ^ n * |x₀ - a| := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Function.iterate_succ_apply', hg, abs_mul, pow_succ]
      have hy : |g^[n] x₀ - a| < ε := by
        have : k ^ n * |x₀ - a| ≤ |x₀ - a| := by
          have : k ^ n ≤ 1 := pow_le_one₀ hk0 hk1.le
          nlinarith [abs_nonneg (x₀ - a)]
        linarith
      have hq := hbound _ hy
      have := abs_nonneg (g^[n] x₀ - a)
      calc |g^[n] x₀ - a| * |Q (g^[n] x₀)| ≤ (k ^ n * |x₀ - a|) * k :=
            mul_le_mul ih hq (abs_nonneg _) (by positivity)
        _ = k ^ n * k * |x₀ - a| := by ring
  have hlim : Tendsto (fun n : ℕ => k ^ n * |x₀ - a|) atTop (𝓝 0) := by
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one hk0 hk1).mul_const |x₀ - a|
    simpa using this
  rw [tendsto_iff_norm_sub_tendsto_zero]
  exact squeeze_zero (fun n => norm_nonneg _) (fun n => by simpa [Real.norm_eq_abs] using key n) hlim

#print axioms logistic_deriv_eq
#print axioms logistic_sub
#print axioms logistic_continuous
#print axioms logistic_stable_iff_aux
#print axioms attract_of_factor


/-- Past a dial of 3 the steady share repels and a two-summer cycle takes over.
For a dial `r` with `3 < r < 1 + √6`: the steady share `1 - 1/r` is a fixed point whose slope
has size above 1, so it repels; the two shares `x± = (r + 1 ± √((r+1)(r-3)))/(2r)` are different
and the map swaps them; and every start close enough to `x₋` is pulled onto the cycle:
even summers tend to `x₋` and odd summers tend to `x₊`. -/
theorem logistic_two_cycle_takes_over (r : ℝ) (h3 : 3 < r) (h6 : r < 1 + Real.sqrt 6) :
    logistic r (1 - 1 / r) = 1 - 1 / r ∧
    1 < |deriv (logistic r) (1 - 1 / r)| ∧
    (r + 1 - Real.sqrt ((r + 1) * (r - 3))) / (2 * r) ≠
      (r + 1 + Real.sqrt ((r + 1) * (r - 3))) / (2 * r) ∧
    logistic r ((r + 1 - Real.sqrt ((r + 1) * (r - 3))) / (2 * r)) =
      (r + 1 + Real.sqrt ((r + 1) * (r - 3))) / (2 * r) ∧
    logistic r ((r + 1 + Real.sqrt ((r + 1) * (r - 3))) / (2 * r)) =
      (r + 1 - Real.sqrt ((r + 1) * (r - 3))) / (2 * r) ∧
    ∃ ε > 0, ∀ x₀ : ℝ, |x₀ - (r + 1 - Real.sqrt ((r + 1) * (r - 3))) / (2 * r)| < ε →
      Tendsto (fun n : ℕ => (logistic r)^[2 * n] x₀) atTop
        (𝓝 ((r + 1 - Real.sqrt ((r + 1) * (r - 3))) / (2 * r))) ∧
      Tendsto (fun n : ℕ => (logistic r)^[2 * n + 1] x₀) atTop
        (𝓝 ((r + 1 + Real.sqrt ((r + 1) * (r - 3))) / (2 * r))) := by
  have hr0 : r ≠ 0 := by linarith
  have hr : 0 < r := by linarith
  set s := Real.sqrt ((r + 1) * (r - 3)) with hs_def
  have hprod : 0 < (r + 1) * (r - 3) := by nlinarith
  have hs2 : s ^ 2 = (r + 1) * (r - 3) := Real.sq_sqrt hprod.le
  have hs0 : 0 < s := Real.sqrt_pos.mpr hprod
  have hA : logistic r ((r + 1 - s) / (2 * r)) = (r + 1 + s) / (2 * r) := by
    unfold logistic; field_simp; nlinarith [hs2]
  have hB : logistic r ((r + 1 + s) / (2 * r)) = (r + 1 - s) / (2 * r) := by
    unfold logistic; field_simp; nlinarith [hs2]
  refine ⟨?_, ?_, ?_, hA, hB, ?_⟩
  · unfold logistic; field_simp; ring
  · rw [logistic_deriv_eq]
    have : r * (1 - 2 * (1 - 1 / r)) = 2 - r := by field_simp; ring
    rw [this, abs_of_neg (by linarith)]; linarith
  · intro h
    field_simp at h
    linarith
  · set a := (r + 1 - s) / (2 * r) with ha
    set b := (r + 1 + s) / (2 * r) with hb
    let Q : ℝ → ℝ := fun x => r * (1 - x - a) * (r * (1 - logistic r x - b))
    have hQ : Continuous Q := by
      have := logistic_continuous r
      fun_prop
    have hQa : Q a = 4 + 2 * r - r ^ 2 := by
      show r * (1 - a - a) * (r * (1 - logistic r a - b)) = _
      rw [hA, ha, hb]
      field_simp
      nlinarith [hs2]
    have hQa1 : |Q a| < 1 := by
      rw [hQa]
      exact (logistic_stable_iff_aux r hr).mpr ⟨h3, h6⟩
    have hg : ∀ x, (logistic r)^[2] x - a = (x - a) * Q x := by
      intro x
      show logistic r (logistic r x) - a = _
      have e1 : a = logistic r b := hB.symm
      have e2 : b = logistic r a := hA.symm
      calc logistic r (logistic r x) - a = logistic r (logistic r x) - logistic r b := by rw [← e1]
        _ = r * (logistic r x - b) * (1 - logistic r x - b) := logistic_sub _ _ _
        _ = r * (logistic r x - logistic r a) * (1 - logistic r x - b) := by rw [← e2]
        _ = r * (r * (x - a) * (1 - x - a)) * (1 - logistic r x - b) := by rw [logistic_sub]
        _ = (x - a) * Q x := by simp only [Q]; ring
    obtain ⟨ε, hε, hatt⟩ := attract_of_factor _ Q a hQ hQa1 hg
    refine ⟨ε, hε, fun x₀ hx₀ => ?_⟩
    have h1 : Tendsto (fun n : ℕ => (logistic r)^[2 * n] x₀) atTop (𝓝 a) := by
      have := hatt x₀ hx₀
      simpa [Function.iterate_mul] using this
    refine ⟨h1, ?_⟩
    have h2 := ((logistic_continuous r).tendsto a).comp h1
    rw [hA] at h2
    refine h2.congr (fun n => ?_)
    simp only [Function.comp, Function.iterate_succ_apply']

/-- The cycle's multiplier: for a dial above 3, the product of the map's slopes at the two
cycle shares `x₋` and `x₊` is `4 + 2r - r^2`. -/
theorem logistic_two_cycle_multiplier (r : ℝ) (h3 : 3 < r) :
    deriv (logistic r) ((r + 1 - Real.sqrt ((r + 1) * (r - 3))) / (2 * r)) *
      deriv (logistic r) ((r + 1 + Real.sqrt ((r + 1) * (r - 3))) / (2 * r)) =
      4 + 2 * r - r ^ 2 := by
  have hr0 : r ≠ 0 := by linarith
  have hprod : 0 ≤ (r + 1) * (r - 3) := by nlinarith
  have hs2 := Real.sq_sqrt hprod
  rw [logistic_deriv_eq, logistic_deriv_eq]
  field_simp
  nlinarith [hs2]

/-- The cycle is born at 3 and breaks at 1 + √6: for a dial between 0 and 4, the multiplier
`4 + 2r - r^2` lies strictly between -1 and 1 exactly when `3 < r < 1 + √6`. -/
theorem logistic_two_cycle_stable_iff (r : ℝ) (h0 : 0 < r) (h4 : r ≤ 4) :
    |4 + 2 * r - r ^ 2| < 1 ↔ 3 < r ∧ r < 1 + Real.sqrt 6 :=
  logistic_stable_iff_aux r h0

-- Dial 3.2 = 16/5: steady share 0.6875 = 11/16 with slope 2 - r = -1.2.
example : logistic (16 / 5) (11 / 16) = 11 / 16 := by norm_num [logistic]
example : (2 : ℚ) - 16 / 5 = -6 / 5 := by norm_num
-- Dial 3.2: under the root (r + 1)(r - 3) = 0.84, multiplier 4 + 2r - r^2 = 0.16.
example : ((16 : ℚ) / 5 + 1) * (16 / 5 - 3) = 21 / 25 := by norm_num
example : (4 : ℚ) + 2 * (16 / 5) - (16 / 5) ^ 2 = 4 / 25 := by norm_num
-- Dial 3.2: the cycle shares add to 4.2/3.2 = 1.3125 and multiply to 4.2/10.24 = 0.41015625.
example : ((16 : ℚ) / 5 + 1) / (16 / 5) = 21 / 16 := by norm_num
example : ((16 : ℚ) / 5 + 1) / (16 / 5) ^ 2 = 105 / 256 := by norm_num
-- Dial 3.5 = 7/2: the formula's shares 3/7 and 6/7 are swapped, but the multiplier is -1.25.
example : logistic (7 / 2) (3 / 7) = 6 / 7 := by norm_num [logistic]
example : logistic (7 / 2) (6 / 7) = 3 / 7 := by norm_num [logistic]
example : (4 : ℚ) + 2 * (7 / 2) - (7 / 2) ^ 2 = -5 / 4 := by norm_num
-- Dial 2.8 = 14/5: (r + 1)(r - 3) = -0.76, so no real cycle; the share settles on 9/14.
example : ((14 : ℚ) / 5 + 1) * (14 / 5 - 3) = -19 / 25 := by norm_num
example : logistic (14 / 5) (9 / 14) = 9 / 14 := by norm_num [logistic]

#print axioms logistic_two_cycle_takes_over
#print axioms logistic_two_cycle_multiplier
#print axioms logistic_two_cycle_stable_iff
