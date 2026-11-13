-- Solving backwards: a continuous one-way model whose bracket straddles the quote hits that quote exactly once, bisection traps a root in a bracket that halves every step, and the leftover residual divided by the flattest slope bounds the distance to the answer.
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Order.Monotone.Basic
import Mathlib.Tactic.NormNum

open Set

/-- A continuous function with a sign change on a bracket has a zero there. -/
theorem root_of_sign_change {f : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hcont : ContinuousOn f (Icc a b)) (hsign : f a * f b ≤ 0) :
    ∃ x ∈ Icc a b, f x = 0 := by
  by_cases ha0 : f a = 0
  · exact ⟨a, ⟨le_rfl, hab⟩, ha0⟩
  rcases lt_or_gt_of_ne ha0 with ha | ha
  · have hb : 0 ≤ f b := by
      by_contra hb
      rw [not_le] at hb
      nlinarith [mul_pos_of_neg_of_neg ha hb]
    obtain ⟨x, hx, hfx⟩ := intermediate_value_Icc hab hcont ⟨ha.le, hb⟩
    exact ⟨x, hx, hfx⟩
  · have hb : f b ≤ 0 :=
      nonpos_of_mul_nonpos_left (by linarith [mul_comm (f a) (f b)]) ha
    obtain ⟨x, hx, hfx⟩ := intermediate_value_Icc' hab hcont ⟨hb, ha.le⟩
    exact ⟨x, hx, hfx⟩

#print axioms root_of_sign_change

/-- Subtract the quote and every inverse problem is one problem. If the model `g` moves
continuously with the input on the bracket from `l` to `u`, moves one way only there, and the
residuals `g l - y` and `g u - y` at the two ends have opposite signs (or one is zero), then
exactly one input in the bracket reproduces the quoted number `y`. -/
theorem exists_unique_inverse_in_bracket {g : ℝ → ℝ} {l u y : ℝ} (hlu : l ≤ u)
    (hcont : ContinuousOn g (Icc l u))
    (hone_way : StrictMonoOn g (Icc l u) ∨ StrictAntiOn g (Icc l u))
    (hbracket : (g l - y) * (g u - y) ≤ 0) :
    ∃! x, x ∈ Icc l u ∧ g x = y := by
  have hsurj : ∃ x ∈ Icc l u, g x = y := by
    have hc : ContinuousOn (fun z => g z - y) (Icc l u) := hcont.sub continuousOn_const
    obtain ⟨x, hx, hfx⟩ := root_of_sign_change hlu hc hbracket
    exact ⟨x, hx, by linarith⟩
  obtain ⟨x, hx, hgx⟩ := hsurj
  have hinj : InjOn g (Icc l u) := by
    rcases hone_way with h | h
    · exact h.injOn
    · exact h.injOn
  exact ⟨x, ⟨hx, hgx⟩, fun z ⟨hz, hgz⟩ => hinj hz hx (hgz.trans hgx.symm)⟩

/-- One bisection test: price the midpoint and keep the half whose ends still straddle zero. -/
noncomputable def bisectStep (f : ℝ → ℝ) (p : ℝ × ℝ) : ℝ × ℝ :=
  if f p.1 * f ((p.1 + p.2) / 2) ≤ 0 then (p.1, (p.1 + p.2) / 2)
  else ((p.1 + p.2) / 2, p.2)

/-- The bracket left after `t` bisection tests, starting from `(l, u)`. -/
noncomputable def bisectBracket (f : ℝ → ℝ) (l u : ℝ) (t : ℕ) : ℝ × ℝ :=
  (bisectStep f)^[t] (l, u)


/-- The bisection invariant after `t` steps. -/
theorem bisect_invariant {f : ℝ → ℝ} {l u : ℝ} (hlu : l ≤ u) (hsign : f l * f u ≤ 0) (t : ℕ) :
    l ≤ (bisectBracket f l u t).1 ∧ (bisectBracket f l u t).2 ≤ u ∧
    (bisectBracket f l u t).2 - (bisectBracket f l u t).1 = (u - l) / 2 ^ t ∧
    f (bisectBracket f l u t).1 * f (bisectBracket f l u t).2 ≤ 0 := by
  induction t with
  | zero => simp [bisectBracket, hsign]
  | succ n ih =>
    have hstep : bisectBracket f l u (n + 1) = bisectStep f (bisectBracket f l u n) := by
      simp only [bisectBracket]
      rw [Function.iterate_succ_apply']
    rw [hstep]
    obtain ⟨h1, h2, h3, h4⟩ := ih
    set a := (bisectBracket f l u n).1
    set b := (bisectBracket f l u n).2
    have hw : 0 ≤ (u - l) / 2 ^ n := by positivity
    have hpow : (2 : ℝ) ^ (n + 1) = 2 ^ n * 2 := pow_succ 2 n
    have hab : a ≤ b := by linarith
    unfold bisectStep
    split_ifs with hc
    · refine ⟨h1, by linarith, ?_, hc⟩
      rw [hpow, ← div_div]
      linarith
    · refine ⟨by linarith, h2, ?_, ?_⟩
      · rw [hpow, ← div_div]
        linarith
      · rw [not_le] at hc
        change 0 < f a * f ((a + b) / 2) at hc
        have key : (f a * f ((a + b) / 2)) * (f ((a + b) / 2) * f b)
            = f ((a + b) / 2) ^ 2 * (f a * f b) := by ring
        have : (f a * f ((a + b) / 2)) * (f ((a + b) / 2) * f b) ≤ 0 := by
          rw [key]
          exact mul_nonpos_of_nonneg_of_nonpos (sq_nonneg _) h4
        rw [mul_comm] at this
        exact nonpos_of_mul_nonpos_left this hc

#print axioms bisect_invariant

/-- Halving cannot fail and cannot hurry. If the residual `f` is continuous on the bracket from
`l` to `u` and has opposite signs at the ends, then after `t` tests the bracket `(a, b)` still
lies inside the starting one, its width is exactly the starting width divided by `2 ^ t`, and it
still contains a zero of `f`. So its midpoint is within half that width of a zero. -/
theorem bisection_halves_and_traps_root {f : ℝ → ℝ} {l u : ℝ} (hlu : l ≤ u)
    (hcont : ContinuousOn f (Icc l u)) (hsign : f l * f u ≤ 0) (t : ℕ) :
    l ≤ (bisectBracket f l u t).1 ∧ (bisectBracket f l u t).2 ≤ u ∧
    (bisectBracket f l u t).2 - (bisectBracket f l u t).1 = (u - l) / 2 ^ t ∧
    ∃ x ∈ Icc (bisectBracket f l u t).1 (bisectBracket f l u t).2, f x = 0 ∧
      |((bisectBracket f l u t).1 + (bisectBracket f l u t).2) / 2 - x| ≤ (u - l) / 2 ^ (t + 1) := by
  obtain ⟨h1, h2, h3, h4⟩ := bisect_invariant hlu hsign t
  set a := (bisectBracket f l u t).1
  set b := (bisectBracket f l u t).2
  have hw : 0 ≤ (u - l) / 2 ^ t := by positivity
  have hab : a ≤ b := by linarith
  obtain ⟨x, hx, hfx⟩ := root_of_sign_change hab (hcont.mono (Icc_subset_Icc h1 h2)) h4
  refine ⟨h1, h2, h3, x, hx, hfx, ?_⟩
  have hpow : (2 : ℝ) ^ (t + 1) = 2 ^ t * 2 := pow_succ 2 t
  rw [hpow, ← div_div, abs_le]
  obtain ⟨hx1, hx2⟩ := hx
  constructor <;> linarith

/-- Residual to answer: the distance from a guess `x` to the true answer `xs` is at most the
leftover residual `|f x|` divided by the flattest the slope gets on the bracket, provided that
slope `m` has not gone flat (`0 < m`). -/
theorem dist_to_root_le_residual_div_min_slope {f : ℝ → ℝ} {l u x xs m : ℝ}
    (hcont : ContinuousOn f (Icc l u)) (hdiff : DifferentiableOn ℝ f (Ioo l u))
    (hm : 0 < m) (hslope : ∀ z ∈ Ioo l u, m ≤ |deriv f z|)
    (hx : x ∈ Icc l u) (hxs : xs ∈ Icc l u) (hroot : f xs = 0) :
    |x - xs| ≤ |f x| / m := by
  have key : ∀ p q : ℝ, p < q → p ∈ Icc l u → q ∈ Icc l u →
      m * (q - p) ≤ |f q - f p| := by
    intro p q hpq hp hq
    obtain ⟨c, hc, hderiv⟩ := exists_deriv_eq_slope f hpq
      (hcont.mono (Icc_subset_Icc hp.1 hq.2))
      (hdiff.mono (Ioo_subset_Ioo hp.1 hq.2))
    have hcm : m ≤ |deriv f c| := hslope c ⟨by linarith [hp.1, hc.1], by linarith [hq.2, hc.2]⟩
    have hqp : 0 < q - p := by linarith
    have : f q - f p = deriv f c * (q - p) := by
      rw [hderiv]; field_simp
    rw [this, abs_mul, abs_of_pos hqp]
    exact mul_le_mul_of_nonneg_right hcm hqp.le
  rw [le_div_iff₀ hm]
  rcases lt_trichotomy x xs with h | h | h
  · have := key x xs h hx hxs
    rw [hroot, zero_sub, abs_neg] at this
    rw [abs_of_neg (by linarith : x - xs < 0)]
    linarith
  · subst h; simp
  · have := key xs x h hxs hx
    rw [hroot, sub_zero] at this
    rw [abs_of_pos (by linarith : 0 < x - xs)]
    linarith

-- The card's halving count: from the bracket 0.01 to 1.00 (width 99/100), forty halvings bring the
-- width under 0.000000000001, and thirty-nine do not.
example : (99 / 100 : ℚ) / 2 ^ 40 ≤ 1 / 10 ^ 12 := by norm_num
example : (1 / 10 ^ 12 : ℚ) < (99 / 100) / 2 ^ 39 := by norm_num
-- Counting the first end, that is 41 trips through the pricer.
example : 1 + 40 = 41 := by norm_num

#print axioms exists_unique_inverse_in_bracket
#print axioms bisection_halves_and_traps_root
#print axioms dist_to_root_le_residual_div_min_slope
