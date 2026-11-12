-- Fixed points: near a fixed point where the rule's slope is continuous and below 1 in size, pressing the rule converges and the ratio of successive errors tends to that slope; a decreasing contraction puts the fixed point between the last two guesses with error at most q/(1+q) times the last step; and relaxing a rule keeps its fixed points and sets its slope to 1 - ω(1 - g'(x*)), which is zero for ω = 1/(1 - g'(x*)).
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Tactic

open Set Filter Topology

namespace FixedPointContraction

/-- Fixed-point iteration: the guess after `k` presses of the rule `g`, starting from `x₀`. -/
def press (g : ℝ → ℝ) (x₀ : ℝ) (k : ℕ) : ℝ := g^[k] x₀

/-- The relaxed rule `g_ω(x) = (1 - ω) x + ω g(x)`: move only a share `ω` of the way from the
current guess to where the plain rule points. -/
def relax (g : ℝ → ℝ) (ω : ℝ) : ℝ → ℝ := fun x => (1 - ω) * x + ω * g x

/-- Mean value step: across `u < v` the change in `g` is a slope value times the change in `x`. -/
lemma exists_mul_of_lt (g g' : ℝ → ℝ) {u v : ℝ} (huv : u < v)
    (hc : ContinuousOn g (Icc u v)) (hd : ∀ x ∈ Ioo u v, HasDerivAt g (g' x) x) :
    ∃ c ∈ Ioo u v, g v - g u = g' c * (v - u) := by
  obtain ⟨c, hc', h⟩ := exists_hasDerivAt_eq_slope (f := g) (f' := g') huv hc hd
  refine ⟨c, hc', ?_⟩
  rw [h]
  field_simp [(sub_pos.mpr huv).ne']

lemma press_succ (g : ℝ → ℝ) (x₀ : ℝ) (k : ℕ) : press g x₀ (k + 1) = g (press g x₀ k) := by
  simp [press, Function.iterate_succ_apply']

/-- The rate law. Let `x*` be a fixed point of `g`, let `g` have a slope `g'` that is continuous
on an interval around `x*`, and let the slope at the fixed point be below 1 in size,
`|g'(x*)| < 1`. Then there is a radius `δ > 0` such that pressing `g` from any start within `δ`
of `x*` converges to `x*`, and, as long as no guess lands exactly on `x*`, the ratio of successive
errors `e_(k+1)/e_k` tends to the slope at the fixed point, `g'(x*)`, sign included. -/
theorem error_ratio_tends_to_slope_at_fixed_point
    (g g' : ℝ → ℝ) (xs r : ℝ) (hr : 0 < r)
    (hfix : g xs = xs)
    (hderiv : ∀ x ∈ Ioo (xs - r) (xs + r), HasDerivAt g (g' x) x)
    (hcont : ContinuousOn g' (Ioo (xs - r) (xs + r)))
    (hslope : |g' xs| < 1) :
    ∃ δ > 0, ∀ x₀ ∈ Icc (xs - δ) (xs + δ),
      Tendsto (fun k : ℕ => press g x₀ k) atTop (𝓝 xs) ∧
      ((∀ k : ℕ, press g x₀ k ≠ xs) →
        Tendsto (fun k : ℕ => (press g x₀ (k + 1) - xs) / (press g x₀ k - xs))
          atTop (𝓝 (g' xs))) := by
  -- the slope stays below a fixed `L < 1` in size near `x*`
  set L := (1 + |g' xs|) / 2 with hL
  have hL1 : L < 1 := by rw [hL]; linarith
  have hL0 : 0 ≤ L := by rw [hL]; positivity
  have hca : ContinuousAt g' xs := hcont.continuousAt (Ioo_mem_nhds (by linarith) (by linarith))
  obtain ⟨δ0, hδ0, hδ0'⟩ := Metric.continuousAt_iff.mp hca ((1 - |g' xs|) / 2) (by linarith)
  set δ := min (δ0 / 2) (r / 2) with hδ
  have hδpos : 0 < δ := lt_min (by linarith) (by linarith)
  have hδr : δ < r := lt_of_le_of_lt (min_le_right _ _) (by linarith)
  have hδδ0 : δ < δ0 := lt_of_le_of_lt (min_le_left _ _) (by linarith)
  have hIsub : ∀ x, |x - xs| ≤ δ → x ∈ Ioo (xs - r) (xs + r) := by
    intro x hx
    rw [abs_le] at hx
    constructor <;> linarith
  have hslopeL : ∀ x, |x - xs| ≤ δ → |g' x| ≤ L := by
    intro x hx
    have h1 : dist x xs < δ0 := by rw [Real.dist_eq]; linarith
    have h2 := hδ0' h1
    rw [Real.dist_eq] at h2
    have h3 : |g' x| ≤ |g' x - g' xs| + |g' xs| := by
      have := abs_add_le (g' x - g' xs) (g' xs)
      simpa using this
    rw [hL]; linarith
  have hgcont : ∀ u v, |u - xs| ≤ δ → |v - xs| ≤ δ → ContinuousOn g (Icc u v) := by
    intro u v hu hv y hy
    have hy' : |y - xs| ≤ δ := by
      rw [abs_le] at hu hv ⊢
      constructor <;> linarith [hy.1, hy.2]
    exact (hderiv y (hIsub y hy')).continuousAt.continuousWithinAt
  -- one press shrinks the error by at least the factor `L`
  have hstep : ∀ x, |x - xs| ≤ δ → |g x - xs| ≤ L * |x - xs| := by
    intro x hx
    rcases lt_trichotomy x xs with h | h | h
    · obtain ⟨c, hc, he⟩ := exists_mul_of_lt g g' h (hgcont x xs hx (by simp; linarith))
        (fun y hy => hderiv y (hIsub y (by
          rw [abs_le] at hx ⊢; constructor <;> linarith [hy.1, hy.2])))
      have hcL : |g' c| ≤ L := hslopeL c (by
        rw [abs_le] at hx ⊢; constructor <;> linarith [hc.1, hc.2])
      have : g x - xs = g' c * (x - xs) := by rw [hfix] at he; linear_combination -he
      rw [this, abs_mul]
      exact mul_le_mul_of_nonneg_right hcL (abs_nonneg _)
    · subst h; simp [hfix]
    · obtain ⟨c, hc, he⟩ := exists_mul_of_lt g g' h (hgcont xs x (by simp; linarith) hx)
        (fun y hy => hderiv y (hIsub y (by
          rw [abs_le] at hx ⊢; constructor <;> linarith [hy.1, hy.2])))
      have hcL : |g' c| ≤ L := hslopeL c (by
        rw [abs_le] at hx ⊢; constructor <;> linarith [hc.1, hc.2])
      have : g x - xs = g' c * (x - xs) := by rw [hfix] at he; linear_combination he
      rw [this, abs_mul]
      exact mul_le_mul_of_nonneg_right hcL (abs_nonneg _)
  refine ⟨δ, hδpos, fun x₀ hx₀ => ?_⟩
  have hx₀' : |x₀ - xs| ≤ δ := by
    rw [abs_le]; constructor <;> linarith [hx₀.1, hx₀.2]
  have hbound : ∀ k : ℕ, |press g x₀ k - xs| ≤ L ^ k * |x₀ - xs| := by
    intro k
    induction k with
    | zero => simp [press]
    | succ k ih =>
      have hk : |press g x₀ k - xs| ≤ δ := by
        have : L ^ k ≤ 1 := pow_le_one₀ hL0 hL1.le
        calc |press g x₀ k - xs| ≤ L ^ k * |x₀ - xs| := ih
          _ ≤ 1 * |x₀ - xs| := mul_le_mul_of_nonneg_right this (abs_nonneg _)
          _ ≤ δ := by linarith
      rw [press_succ, pow_succ]
      calc |g (press g x₀ k) - xs| ≤ L * |press g x₀ k - xs| := hstep _ hk
        _ ≤ L * (L ^ k * |x₀ - xs|) := mul_le_mul_of_nonneg_left ih hL0
        _ = L ^ k * L * |x₀ - xs| := by ring
  have hconv : Tendsto (fun k : ℕ => press g x₀ k) atTop (𝓝 xs) := by
    have hpow : Tendsto (fun k : ℕ => L ^ k * |x₀ - xs|) atTop (𝓝 0) := by
      simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hL0 hL1).mul_const |x₀ - xs|
    have h0 : Tendsto (fun k : ℕ => press g x₀ k - xs) atTop (𝓝 0) := by
      rw [tendsto_zero_iff_abs_tendsto_zero]
      exact squeeze_zero (fun k => abs_nonneg _) hbound hpow
    simpa using h0.add_const xs
  refine ⟨hconv, fun hne => ?_⟩
  have hslp := (hasDerivAt_iff_tendsto_slope).mp (hderiv xs (by constructor <;> linarith))
  have hw : Tendsto (fun k : ℕ => press g x₀ k) atTop (𝓝[≠] xs) :=
    tendsto_nhdsWithin_iff.mpr ⟨hconv, Eventually.of_forall (fun k => hne k)⟩
  have hcomp := hslp.comp hw
  refine hcomp.congr (fun k => ?_)
  simp only [Function.comp, slope_def_field, press_succ, hfix]

/-- The sharper one-step bound. Let `g` map the interval `I = [a, b]` into itself, with a fixed
point `x*` in `I`, and let `g` be decreasing with slope between `-q` and `0` on `I`, where
`0 ≤ q < 1`. Then from any start in `I` the fixed point lies between the last two guesses
(`e_(k+1)` and `e_k` never share a sign), and the error after any press is at most
`q/(1+q)` times that press's step: `|e_(k+1)| ≤ q/(1+q) · |d_(k+1)|`. -/
theorem decreasing_contraction_error_le_q_div_one_add_q_step
    (g g' : ℝ → ℝ) (a b q xs : ℝ)
    (hmaps : MapsTo g (Icc a b) (Icc a b))
    (hxs : xs ∈ Icc a b) (hfix : g xs = xs)
    (hcont : ContinuousOn g (Icc a b))
    (hderiv : ∀ x ∈ Ioo a b, HasDerivAt g (g' x) x)
    (hslope : ∀ x ∈ Ioo a b, -q ≤ g' x ∧ g' x ≤ 0)
    (hq0 : 0 ≤ q) (hq1 : q < 1) :
    ∀ x₀ ∈ Icc a b, ∀ k : ℕ,
      (press g x₀ (k + 1) - xs) * (press g x₀ k - xs) ≤ 0 ∧
      |press g x₀ (k + 1) - xs| ≤ q / (1 + q) * |press g x₀ (k + 1) - press g x₀ k| := by
  -- each press multiplies the error by a slope value between `-q` and `0`
  have hmul : ∀ x ∈ Icc a b, ∃ c, -q ≤ c ∧ c ≤ 0 ∧ g x - xs = c * (x - xs) := by
    intro x hx
    rcases lt_trichotomy x xs with h | h | h
    · obtain ⟨c, hc, he⟩ := exists_mul_of_lt g g' h
        (hcont.mono (Icc_subset_Icc hx.1 hxs.2))
        (fun y hy => hderiv y ⟨lt_of_le_of_lt hx.1 hy.1, lt_of_lt_of_le hy.2 hxs.2⟩)
      have hcm : c ∈ Ioo a b := ⟨lt_of_le_of_lt hx.1 hc.1, lt_of_lt_of_le hc.2 hxs.2⟩
      refine ⟨g' c, (hslope c hcm).1, (hslope c hcm).2, ?_⟩
      rw [hfix] at he
      linear_combination -he
    · exact ⟨0, by linarith, le_refl _, by subst h; simp [hfix]⟩
    · obtain ⟨c, hc, he⟩ := exists_mul_of_lt g g' h
        (hcont.mono (Icc_subset_Icc hxs.1 hx.2))
        (fun y hy => hderiv y ⟨lt_of_le_of_lt hxs.1 hy.1, lt_of_lt_of_le hy.2 hx.2⟩)
      have hcm : c ∈ Ioo a b := ⟨lt_of_le_of_lt hxs.1 hc.1, lt_of_lt_of_le hc.2 hx.2⟩
      refine ⟨g' c, (hslope c hcm).1, (hslope c hcm).2, ?_⟩
      rw [hfix] at he
      linear_combination he
  intro x₀ hx₀ k
  have hin : ∀ k : ℕ, press g x₀ k ∈ Icc a b := by
    intro k
    induction k with
    | zero => simpa [press] using hx₀
    | succ k ih => rw [press_succ]; exact hmaps ih
  obtain ⟨c, hcq, hc0, hce⟩ := hmul _ (hin k)
  rw [press_succ, hce]
  set e := press g x₀ k - xs
  constructor
  · have : c * e * e = c * (e * e) := by ring
    rw [this]
    exact mul_nonpos_of_nonpos_of_nonneg hc0 (mul_self_nonneg e)
  · have hd : g (press g x₀ k) - press g x₀ k = (c - 1) * e := by
      have : g (press g x₀ k) = c * e + xs := by linarith
      rw [this]; simp only [e]; ring
    rw [hd, abs_mul, abs_mul, abs_of_nonpos hc0, abs_of_neg (by linarith : c - 1 < 0)]
    have h1q : 0 < 1 + q := by linarith
    have key : q / (1 + q) * (-(c - 1) * |e|) - -c * |e| = (q + c) / (1 + q) * |e| := by
      field_simp
      ring
    have : 0 ≤ (q + c) / (1 + q) * |e| :=
      mul_nonneg (div_nonneg (by linarith) h1q.le) (abs_nonneg _)
    linarith

/-- Relaxation. For any weight `ω ≠ 0` the relaxed rule `g_ω` has exactly the same fixed points
as `g`. Where `g` has slope `g'(x*)`, the relaxed rule has slope `1 - ω (1 - g'(x*))`. When that
slope is not exactly 1, the weight `ω = 1/(1 - g'(x*))` makes the relaxed slope zero. -/
theorem relaxation_keeps_fixed_points_and_best_weight_zeroes_slope
    (g : ℝ → ℝ) (xs s : ℝ) (hg : HasDerivAt g s xs) :
    (∀ ω : ℝ, ω ≠ 0 → ∀ x : ℝ, relax g ω x = x ↔ g x = x) ∧
    (∀ ω : ℝ, HasDerivAt (relax g ω) (1 - ω * (1 - s)) xs) ∧
    (s ≠ 1 → HasDerivAt (relax g (1 / (1 - s))) 0 xs) := by
  refine ⟨?_, ?_, ?_⟩
  · intro ω hω x
    simp only [relax]
    constructor
    · intro h
      have : ω * (g x - x) = 0 := by linarith
      rcases mul_eq_zero.mp this with h' | h'
      · exact absurd h' hω
      · linarith
    · intro h
      rw [h]; ring
  · intro ω
    have h : HasDerivAt (fun x => (1 - ω) * x + ω * g x) ((1 - ω) * 1 + ω * s) xs :=
      ((hasDerivAt_id' xs).const_mul _).add (hg.const_mul _)
    unfold relax
    convert h using 1
    ring
  · intro hs
    have h1 : (1 : ℝ) - s ≠ 0 := sub_ne_zero.mpr (Ne.symm hs)
    have h : HasDerivAt (fun x => (1 - 1 / (1 - s)) * x + 1 / (1 - s) * g x)
        ((1 - 1 / (1 - s)) * 1 + 1 / (1 - s) * s) xs :=
      ((hasDerivAt_id' xs).const_mul _).add (hg.const_mul _)
    unfold relax
    convert h using 1
    field_simp
    ring

-- The card's "try" with inflow Q = 40: the steady depth is exactly 4 m, since sqrt 4 = 2 and
-- 12 sqrt 4 + 2 · 4 · sqrt 4 = 24 + 16 = 40.
example : 12 * Real.sqrt 4 + 2 * 4 * Real.sqrt 4 = 40 := by norm_num
-- Cardano's road solves s^3 + (a/b) s = Q/b in s = sqrt x: with a/b = 6 and Q/b = 20, s = 2.
example : (2 : ℤ) ^ 3 + 6 * 2 = 20 := by decide
-- Rule A at depth 4: (Q - a sqrt 4)/b = (40 - 24)/2 = 8 = 2^3, and squaring the cube root 2 gives 4.
example : ((40 : ℤ) - 12 * 2) / 2 = 2 ^ 3 ∧ (2 : ℤ) ^ 2 = 4 := by decide
-- Rule B at depth 4: (Q - b · 4 · sqrt 4)/a = (40 - 16)/12 = 2, and 2^2 = 4, so both rules fix 4.
example : ((40 : ℤ) - 2 * 4 * 2) / 12 = 2 ∧ (2 : ℤ) ^ 2 = 4 := by decide
-- The slope of Rule A at 4 is -a/(3 b x*) = -12/(3 · 2 · 4) = -1/2; Rule B's is its reciprocal, -2.
example : -(12 : ℚ) / (3 * 2 * 4) = -1 / 2 ∧ 1 / (-(1 : ℚ) / 2) = -2 := by norm_num
-- The shelf's 25-year mortgage has 25 · 12 = 300 monthly payments.
example : 25 * 12 = 300 := by decide

#print axioms exists_mul_of_lt
#print axioms press_succ
#print axioms error_ratio_tends_to_slope_at_fixed_point
#print axioms decreasing_contraction_error_le_q_div_one_add_q_step
#print axioms relaxation_keeps_fixed_points_and_best_weight_zeroes_slope

end FixedPointContraction
