-- Monotone operators: the resolvent of a monotone operator never moves two points further apart, the Moreau envelope of |x| is the Huber function with gradient x minus the prox, and averaging a nonexpansive map converges to a fixed point.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Module
import Mathlib.Analysis.Asymptotics.Lemmas
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.MetricSpace.Sequences

open Filter Topology

/-- **The resolvent is firmly nonexpansive (Step 3).** Let `A` be a monotone operator on a
real inner product space: it sends each point to a set of points, and
`⟪a - a', x - y⟫ ≥ 0` whenever `a ∈ A x` and `a' ∈ A y`. Take a step `α > 0`. If `a` is a
resolvent output for the input `v` (that is, `v = a + α g` for some `g ∈ A a`, so
`a = J_{αA} v`) and `a'` is one for `v'`, then
`‖a - a'‖² ≤ ⟪a - a', v - v'⟫`, so `‖a - a'‖ ≤ ‖v - v'‖`, and the reflection
`R = 2J - I` is nonexpansive: `‖(2a - v) - (2a' - v')‖ ≤ ‖v - v'‖`. With `A` the
subdifferential of a convex function, `a` is the prox of `v`. -/
theorem resolvent_firmly_nonexpansive {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (A : E → Set E)
    (hA : ∀ x y a a', a ∈ A x → a' ∈ A y → 0 ≤ inner ℝ (a - a') (x - y))
    (α : ℝ) (hα : 0 < α) (v v' a a' : E)
    (ha : ∃ g ∈ A a, v = a + α • g) (ha' : ∃ g' ∈ A a', v' = a' + α • g') :
    ‖a - a'‖ ^ 2 ≤ inner ℝ (a - a') (v - v') ∧
      ‖a - a'‖ ≤ ‖v - v'‖ ∧
      ‖((2 : ℝ) • a - v) - ((2 : ℝ) • a' - v')‖ ≤ ‖v - v'‖ := by
  obtain ⟨g, hg, rfl⟩ := ha
  obtain ⟨g', hg', rfl⟩ := ha'
  have hm : 0 ≤ inner ℝ (g - g') (a - a') := hA a a' g g' hg hg'
  have hsplit : a + α • g - (a' + α • g') = (a - a') + α • (g - g') := by
    rw [smul_sub]; abel
  have h1 : ‖a - a'‖ ^ 2 ≤ inner ℝ (a - a') (a + α • g - (a' + α • g')) := by
    rw [hsplit, inner_add_right, inner_smul_right, real_inner_self_eq_norm_sq,
      real_inner_comm]
    nlinarith [mul_nonneg hα.le hm]
  set w := a + α • g - (a' + α • g')
  set d := a - a'
  have hcs : inner ℝ d w ≤ ‖d‖ * ‖w‖ := real_inner_le_norm d w
  have h2 : ‖d‖ ≤ ‖w‖ := by
    rcases (norm_nonneg d).eq_or_lt with h | h
    · rw [← h]; exact norm_nonneg _
    · nlinarith
  refine ⟨h1, h2, ?_⟩
  have hr : (2 : ℝ) • a - (a + α • g) - ((2 : ℝ) • a' - (a' + α • g')) = (2 : ℝ) • d - w := by
    simp only [d, w, smul_sub, two_smul]; abel
  rw [hr]
  have hsq : ‖(2 : ℝ) • d - w‖ ^ 2 ≤ ‖w‖ ^ 2 := by
    rw [norm_sub_sq_real, norm_smul, inner_smul_left]
    simp only [Real.norm_eq_abs, abs_two, RCLike.conj_to_real]
    nlinarith
  exact (pow_le_pow_iff_left₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).mp hsq

/-- The prox of `|x|` with step 1: soft thresholding. It moves `x` toward 0 by 1, and
sends every point between −1 and 1 to 0. -/
noncomputable def softThreshold (x : ℝ) : ℝ :=
  if 1 < x then x - 1 else if x < -1 then x + 1 else 0

/-- The Huber function: `x²/2` for `|x| ≤ 1` and `|x| - 1/2` otherwise. -/
noncomputable def huber (x : ℝ) : ℝ :=
  if |x| ≤ 1 then x ^ 2 / 2 else |x| - 1 / 2

theorem huber_soft_cases (x : ℝ) :
    (1 < x ∧ huber x = x - 1 / 2 ∧ softThreshold x = x - 1) ∨
    (x < -1 ∧ huber x = -x - 1 / 2 ∧ softThreshold x = x + 1) ∨
    (-1 ≤ x ∧ x ≤ 1 ∧ huber x = x ^ 2 / 2 ∧ softThreshold x = 0) := by
  unfold huber softThreshold
  rcases lt_or_ge 1 x with h | h
  · left
    have : ¬ |x| ≤ 1 := by rw [abs_le]; intro h'; linarith [h'.2]
    refine ⟨h, ?_, ?_⟩
    · rw [ite_eq_right this, abs_of_pos (by linarith : (0:ℝ) < x)]
    · rw [ite_eq_left h]
  · rcases lt_or_ge x (-1) with h' | h'
    · right; left
      have : ¬ |x| ≤ 1 := by rw [abs_le]; intro h''; linarith [h''.1]
      refine ⟨h', ?_, ?_⟩
      · rw [ite_eq_right this, abs_of_neg (by linarith : x < 0)]
      · rw [ite_eq_right (not_lt.mpr h), ite_eq_left h']
    · right; right
      have : |x| ≤ 1 := abs_le.mpr ⟨h', h⟩
      refine ⟨h', h, ?_, ?_⟩
      · rw [ite_eq_left this]
      · rw [ite_eq_right (not_lt.mpr h), ite_eq_right (not_lt.mpr h')]

theorem huber_le (x v : ℝ) : huber x ≤ |v| + (v - x) ^ 2 / 2 := by
  rcases le_or_gt 0 v with hv | hv
  · rw [abs_of_nonneg hv]
    rcases huber_soft_cases x with ⟨h1, h2, _⟩ | ⟨h1, h2, _⟩ | ⟨h1, h1', h2, _⟩ <;> rw [h2]
    · nlinarith [sq_nonneg (v - x + 1)]
    · nlinarith [sq_nonneg (v - x - 1)]
    · nlinarith [mul_nonneg hv (by linarith : (0:ℝ) ≤ 1 - x)]
  · rw [abs_of_neg hv]
    rcases huber_soft_cases x with ⟨h1, h2, _⟩ | ⟨h1, h2, _⟩ | ⟨h1, h1', h2, _⟩ <;> rw [h2]
    · nlinarith [sq_nonneg (v - x + 1)]
    · nlinarith [sq_nonneg (v - x - 1)]
    · nlinarith [mul_nonneg (neg_nonneg.mpr hv.le) (by linarith : (0:ℝ) ≤ 1 + x)]

theorem huber_value (x : ℝ) : |softThreshold x| + (softThreshold x - x) ^ 2 / 2 = huber x := by
  rcases huber_soft_cases x with ⟨h1, h2, h3⟩ | ⟨h1, h2, h3⟩ | ⟨h1, h1', h2, h3⟩ <;> rw [h2, h3]
  · rw [abs_of_nonneg (by linarith)]; ring
  · rw [abs_of_neg (by linarith)]; ring
  · simp

theorem huber_taylor (x y : ℝ) :
    |huber y - huber x - (y - x) * (x - softThreshold x)| ≤ (y - x) ^ 2 := by
  rw [abs_le]
  rcases huber_soft_cases x with ⟨h1, h2, h3⟩ | ⟨h1, h2, h3⟩ | ⟨h1, h1', h2, h3⟩ <;>
  rcases huber_soft_cases y with ⟨k1, k2, k3⟩ | ⟨k1, k2, k3⟩ | ⟨k1, k1', k2, k3⟩ <;>
  rw [h2, h3, k2] <;> constructor <;>
  nlinarith [sq_nonneg (y - x + 1), sq_nonneg (y - x - 1), sq_nonneg (y - x), sq_nonneg (y-1),
    sq_nonneg (y+1), sq_nonneg (x-1), sq_nonneg (x+1)]

/-- **The Moreau envelope of `|x|` is the Huber function (Step 4).** For every real `x`,
the smallest value of `|v| + (v - x)²/2` over all real `v` is `huber x`; that smallest
value is reached at the prox `v = softThreshold x`; and the Huber function has slope
`x - prox(x)` at `x`. -/
theorem moreau_envelope_of_abs_is_huber (x : ℝ) :
    IsLeast (Set.range fun v : ℝ => |v| + (v - x) ^ 2 / 2) (huber x) ∧
      |softThreshold x| + (softThreshold x - x) ^ 2 / 2 = huber x ∧
      HasDerivAt huber (x - softThreshold x) x := by
  refine ⟨⟨⟨softThreshold x, huber_value x⟩, ?_⟩, huber_value x, ?_⟩
  · rintro _ ⟨v, rfl⟩
    exact huber_le x v
  · rw [hasDerivAt_iff_isLittleO]
    have hO : (fun y => huber y - huber x - (y - x) • (x - softThreshold x)) =O[𝓝 x]
        (fun y => ‖y - x‖ ^ 2) := by
      refine Asymptotics.IsBigO.of_bound 1 (Eventually.of_forall fun y => ?_)
      simp only [smul_eq_mul, Real.norm_eq_abs, one_mul, sq_abs, abs_pow]
      exact huber_taylor x y
    exact hO.trans_isLittleO (Asymptotics.isLittleO_pow_sub_sub x (by norm_num))

theorem averaged_step_fejer {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (N : E → E) (hN : ∀ x y, ‖N x - N y‖ ≤ ‖x - y‖) (zs : E) (hzs : N zs = zs) (x : E) :
    ‖(1 / 2 : ℝ) • (x + N x) - zs‖ ^ 2 + ‖(1 / 2 : ℝ) • (x + N x) - x‖ ^ 2 ≤ ‖x - zs‖ ^ 2 := by
  have hb : ‖N x - zs‖ ≤ ‖x - zs‖ := by
    have := hN x zs; rwa [hzs] at this
  have e1 : (1 / 2 : ℝ) • (x + N x) - zs = (1 / 2 : ℝ) • ((x - zs) + (N x - zs)) := by module
  have e2 : (1 / 2 : ℝ) • (x + N x) - x = -((1 / 2 : ℝ) • ((x - zs) - (N x - zs))) := by module
  rw [e1, e2, norm_neg, norm_smul, norm_smul, mul_pow, mul_pow]
  generalize x - zs = a at hb ⊢
  generalize N x - zs = b at hb ⊢
  have hp := parallelogram_law_with_norm ℝ a b
  have : ‖b‖ ^ 2 ≤ ‖a‖ ^ 2 := pow_le_pow_left₀ (norm_nonneg _) hb 2
  norm_num
  nlinarith

theorem averaged_map_nonexpansive {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (N : E → E) (hN : ∀ x y, ‖N x - N y‖ ≤ ‖x - y‖) (x y : E) :
    ‖(1 / 2 : ℝ) • (x + N x) - (1 / 2 : ℝ) • (y + N y)‖ ≤ ‖x - y‖ := by
  rw [← smul_sub, norm_smul, add_sub_add_comm]
  have := norm_add_le (x - y) (N x - N y)
  have := hN x y
  norm_num
  linarith

/-- **Averaging a nonexpansive map converges (Step 5, Krasnoselskii-Mann).** Let `N` be a
nonexpansive map (`‖N x - N y‖ ≤ ‖x - y‖`) on a finite-dimensional real inner product space,
with at least one fixed point. Run `z_{k+1} = (z_k + N z_k)/2` from any start `z_0`. Then
every step is short, `‖z_{k+1} - z_k‖ ≤ ‖z_0 - z*‖ / √(k + 1)` for each fixed point `z*`,
and the points `z_k` converge to a fixed point of `N`. -/
theorem averaged_nonexpansive_iteration_converges {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
    (N : E → E) (hN : ∀ x y, ‖N x - N y‖ ≤ ‖x - y‖) (hfix : ∃ zs, N zs = zs)
    (z : ℕ → E) (hz : ∀ k, z (k + 1) = (1 / 2 : ℝ) • (z k + N (z k))) :
    (∀ zs, N zs = zs → ∀ k : ℕ, ‖z (k + 1) - z k‖ ≤ ‖z 0 - zs‖ / Real.sqrt ((k : ℝ) + 1)) ∧
      ∃ zbar, N zbar = zbar ∧ Tendsto z atTop (𝓝 zbar) := by
  -- Fejér monotonicity: distance to any fixed point shrinks, by at least the step.
  have fejer : ∀ zs, N zs = zs → ∀ k,
      ‖z (k + 1) - zs‖ ^ 2 + ‖z (k + 1) - z k‖ ^ 2 ≤ ‖z k - zs‖ ^ 2 := by
    intro zs hzs k
    rw [hz k]
    exact averaged_step_fejer N hN zs hzs (z k)
  -- Steps never grow.
  have step_anti : Antitone fun k => ‖z (k + 1) - z k‖ := by
    refine antitone_nat_of_succ_le fun k => ?_
    rw [hz (k + 1), hz k]
    exact averaged_map_nonexpansive N hN _ _
  have rate : ∀ zs, N zs = zs → ∀ k : ℕ,
      ‖z (k + 1) - z k‖ ≤ ‖z 0 - zs‖ / Real.sqrt ((k : ℝ) + 1) := by
    intro zs hzs k
    have hsum : ∀ n, ‖z n - zs‖ ^ 2 + ∑ j ∈ Finset.range n, ‖z (j + 1) - z j‖ ^ 2 ≤
        ‖z 0 - zs‖ ^ 2 := by
      intro n
      induction n with
      | zero => simp
      | succ n ih =>
        rw [Finset.sum_range_succ]
        have := fejer zs hzs n
        linarith
    have hlow : ((k : ℝ) + 1) * ‖z (k + 1) - z k‖ ^ 2 ≤
        ∑ j ∈ Finset.range (k + 1), ‖z (j + 1) - z j‖ ^ 2 := by
      have : ∀ j ∈ Finset.range (k + 1), ‖z (k + 1) - z k‖ ^ 2 ≤ ‖z (j + 1) - z j‖ ^ 2 := by
        intro j hj
        have hjk : j ≤ k := Nat.lt_succ_iff.mp (Finset.mem_range.mp hj)
        exact pow_le_pow_left₀ (norm_nonneg _) (step_anti hjk) 2
      have h := Finset.card_nsmul_le_sum (Finset.range (k + 1)) _ _ this
      simp only [Finset.card_range, nsmul_eq_mul] at h
      push_cast at h
      linarith
    have htot := hsum (k + 1)
    have hd : 0 ≤ ‖z (k + 1) - zs‖ ^ 2 := by positivity
    have hsq : 0 < Real.sqrt ((k : ℝ) + 1) := Real.sqrt_pos.mpr (by positivity)
    have hsq2 : Real.sqrt ((k : ℝ) + 1) ^ 2 = (k : ℝ) + 1 := Real.sq_sqrt (by positivity)
    rw [le_div_iff₀ hsq]
    have hs0 := norm_nonneg (z (k + 1) - z k)
    have hz0 := norm_nonneg (z 0 - zs)
    by_contra hcon
    rw [not_le] at hcon
    have : ‖z 0 - zs‖ ^ 2 < (‖z (k + 1) - z k‖ * Real.sqrt ((k : ℝ) + 1)) ^ 2 := by
      exact pow_lt_pow_left₀ hcon hz0 two_ne_zero
    rw [mul_pow, hsq2] at this
    nlinarith
  refine ⟨rate, ?_⟩
  obtain ⟨zs, hzs⟩ := hfix
  -- The distance to zs never grows, so the sequence is bounded.
  have dist_anti : ∀ w, N w = w → Antitone fun k => ‖z k - w‖ := by
    intro w hw
    refine antitone_nat_of_succ_le fun k => ?_
    have h := fejer w hw k
    have h2 : ‖z (k + 1) - w‖ ^ 2 ≤ ‖z k - w‖ ^ 2 := by
      nlinarith [sq_nonneg ‖z (k + 1) - z k‖]
    exact (pow_le_pow_iff_left₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).mp h2
  have hbdd : Bornology.IsBounded (Metric.closedBall zs ‖z 0 - zs‖) := Metric.isBounded_closedBall
  have hmem : ∀ n, z n ∈ Metric.closedBall zs ‖z 0 - zs‖ := by
    intro n
    rw [Metric.mem_closedBall, dist_eq_norm]
    exact dist_anti zs hzs (Nat.zero_le n)
  obtain ⟨zbar, -, φ, hφ, hlim⟩ := tendsto_subseq_of_bounded hbdd hmem
  -- Steps tend to zero.
  have hstep : Tendsto (fun k => z (k + 1) - z k) atTop (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    have hinv : Tendsto (fun k : ℕ => ‖z 0 - zs‖ / Real.sqrt ((k : ℝ) + 1)) atTop (𝓝 0) := by
      have h1 : Tendsto (fun k : ℕ => Real.sqrt ((k : ℝ) + 1)) atTop atTop := by
        refine Real.tendsto_sqrt_atTop.comp ?_
        exact tendsto_atTop_add_const_right _ 1 tendsto_natCast_atTop_atTop
      exact h1.const_div_atTop _
    exact squeeze_zero (fun k => norm_nonneg _) (rate zs hzs) hinv
  -- z_k - N z_k = 2 (z_k - z_{k+1}), so it tends to zero.
  have hres : Tendsto (fun k => z k - N (z k)) atTop (𝓝 0) := by
    have heq : ∀ k, z k - N (z k) = (-2 : ℝ) • (z (k + 1) - z k) := by
      intro k
      rw [hz k, smul_sub, smul_smul]
      norm_num
      rw [two_smul]; abel
    simp_rw [heq]
    simpa using hstep.const_smul (-2 : ℝ)
  have hNcont : Continuous N := by
    refine LipschitzWith.continuous (K := 1) (LipschitzWith.of_dist_le_mul fun x y => ?_)
    simp only [NNReal.coe_one, one_mul, dist_eq_norm]
    exact hN x y
  have hfixbar : N zbar = zbar := by
    have h1 : Tendsto (fun n => z (φ n) - N (z (φ n))) atTop (𝓝 (zbar - N zbar)) :=
      hlim.sub ((hNcont.tendsto zbar).comp hlim)
    have h2 : Tendsto (fun n => z (φ n) - N (z (φ n))) atTop (𝓝 0) :=
      hres.comp hφ.tendsto_atTop
    have := tendsto_nhds_unique h1 h2
    exact (sub_eq_zero.mp this).symm
  refine ⟨zbar, hfixbar, ?_⟩
  rw [tendsto_iff_norm_sub_tendsto_zero]
  have hsub : Tendsto (fun n => ‖z (φ n) - zbar‖) atTop (𝓝 0) :=
    (tendsto_iff_norm_sub_tendsto_zero.mp hlim)
  rw [Metric.tendsto_atTop] at hsub ⊢
  intro ε hε
  obtain ⟨n0, hn0⟩ := hsub ε hε
  refine ⟨φ n0, fun k hk => ?_⟩
  have h1 := hn0 n0 le_rfl
  simp only [Real.dist_eq, sub_zero, abs_norm] at h1 ⊢
  exact lt_of_le_of_lt (dist_anti zbar hfixbar hk) h1

-- The card's worked numbers for |x|: prox at 3 is 2, envelope at 3 is 5/2,
-- envelope at 0.4 = 2/5 is 2/25, and the proximal point method runs 3, 2, 1, 0.
example : softThreshold 3 = 2 := by norm_num [softThreshold]
example : huber 3 = 5 / 2 := by norm_num [huber, abs_of_pos]
example : softThreshold (2 / 5) = 0 := by norm_num [softThreshold]
example : huber (2 / 5) = 2 / 25 := by norm_num [huber, abs_of_pos]
example : softThreshold 2 = 1 ∧ softThreshold 1 = 0 := by norm_num [softThreshold]
-- Moreau's decomposition: x = prox(x) + clip(x), so 3 = 2 + 1 and 2/5 = 0 + 2/5.
example : softThreshold 3 + max (-1) (min 1 3) = (3 : ℝ) := by norm_num [softThreshold]
example : softThreshold (2 / 5) + max (-1) (min 1 (2 / 5)) = (2 / 5 : ℝ) := by
  norm_num [softThreshold]
-- Douglas-Rachford: yesterday's weights h = (0.6, 0.4, 0) are sqrt 0.06 from the model
-- u = (0.5, 0.6, -0.1); squared distance 3/50.
example : ((6 : ℚ) / 10 - 5 / 10) ^ 2 + (4 / 10 - 6 / 10) ^ 2 + (0 + 1 / 10) ^ 2 = 3 / 50 := by
  norm_num
-- The answer w = (0.45 + e, 0.55 - e, 0) with e = sqrt 0.06 / 4 sums to 1 and lies
-- exactly 0.15 from the model.
example : let e := Real.sqrt (3 / 50) / 4
    (9 / 20 + e) + (11 / 20 - e) + 0 = 1 ∧
      (9 / 20 + e - 1 / 2) ^ 2 + (11 / 20 - e - 3 / 5) ^ 2 + (0 + 1 / 10) ^ 2 = (3 / 20) ^ 2 := by
  intro e
  have he : e ^ 2 = 3 / 800 := by
    simp only [e, div_pow, Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 3 / 50)]
    norm_num
  constructor
  · ring
  · nlinarith [he]
-- Total-variation smoothing of the spreads b = (2, 4, 3, 10, 12, 9, 11, 3) bp with charge 3:
-- regimes 4, 9, 6 bp; fit 14 plus 3 times jumps 8 gives 38.
example : ((2 : ℚ) + 4 + 3 + 3) / 3 = 4 ∧ ((10 : ℚ) + 12 + 9 + 11 - 3 - 3) / 4 = 9 ∧
    ((3 : ℚ) + 3) / 1 = 6 := by norm_num
example : (1 / 2 : ℚ) * ((4 - 2) ^ 2 + (4 - 4) ^ 2 + (4 - 3) ^ 2 + (9 - 10) ^ 2 + (9 - 12) ^ 2 +
      (9 - 9) ^ 2 + (9 - 11) ^ 2 + (6 - 3) ^ 2) + 3 * (|(9 : ℚ) - 4| + |(6 : ℚ) - 9|) = 38 := by
  norm_num [abs_of_pos, abs_of_neg]
-- The dual certificate: the jump prices p = (2, 2, 3, 2, -1, -1, -3), all within 3, give
-- x = b - Dᵀp = (4, 4, 4, 9, 9, 9, 9, 6), and the dual value |b|²/2 - |x|²/2 = 242 - 204 = 38.
example : ((2 : ℤ) + 2, (4 : ℤ) - (2 - 2), (3 : ℤ) - (2 - 3), (10 : ℤ) - (3 - 2),
    (12 : ℤ) - (2 - (-1)), (9 : ℤ) - (-1 - (-1)), (11 : ℤ) - (-1 - (-3)), (3 : ℤ) - (-3)) =
    (4, 4, 4, 9, 9, 9, 9, 6) := by norm_num
example : ((2 : ℚ) ^ 2 + 4 ^ 2 + 3 ^ 2 + 10 ^ 2 + 12 ^ 2 + 9 ^ 2 + 11 ^ 2 + 3 ^ 2) / 2 -
    ((4 : ℚ) ^ 2 * 3 + 9 ^ 2 * 4 + 6 ^ 2) / 2 = 38 := by norm_num

#print axioms huber_soft_cases
#print axioms huber_le
#print axioms huber_value
#print axioms huber_taylor
#print axioms averaged_step_fejer
#print axioms averaged_map_nonexpansive
#print axioms resolvent_firmly_nonexpansive
#print axioms moreau_envelope_of_abs_is_huber
#print axioms averaged_nonexpansive_iteration_converges
