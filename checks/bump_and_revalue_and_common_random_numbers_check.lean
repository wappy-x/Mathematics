-- Bump and revalue: a central bump is off from the true slope by at most a sixth of the bump squared times the third-slope bound, a one-sided bump carries an extra half bump of the second slope, and with shared draws a call's paired difference over the full gap never exceeds the path's discounted growth factor.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Taylor

/-- Fencing step: a function starting inside its bound, with slope bounded by the bound's slope,
stays inside its bound on the interval. -/
lemma bump_bound_step (k k' B B' : ℝ → ℝ) (a b : ℝ)
    (hk : ∀ y ∈ Set.Icc a b, HasDerivAt k (k' y) y)
    (hB : ∀ y, HasDerivAt B (B' y) y)
    (h0 : |k a| ≤ B a) (hb : ∀ y ∈ Set.Icc a b, |k' y| ≤ B' y) :
    ∀ y ∈ Set.Icc a b, |k y| ≤ B y := by
  intro y hy
  have := image_norm_le_of_norm_deriv_right_le_deriv_boundary (f := k) (f' := k') (a := a) (b := b)
    (fun z hz => (hk z hz).continuousAt.continuousWithinAt)
    (fun z hz => (hk z (Set.Ico_subset_Icc_self hz)).hasDerivWithinAt)
    (B := B) (B' := B') (by simpa using h0) hB
    (fun z hz => by simpa using hb z (Set.Ico_subset_Icc_self hz)) hy
  simpa using this

/-- Third-order Taylor bound on the right of `x`. -/
lemma bump_taylor3_right (f f' f'' f''' : ℝ → ℝ) (x h M : ℝ) (hh : 0 ≤ h)
    (hf : ∀ y ∈ Set.Icc x (x + h), HasDerivAt f (f' y) y)
    (hf' : ∀ y ∈ Set.Icc x (x + h), HasDerivAt f' (f'' y) y)
    (hf'' : ∀ y ∈ Set.Icc x (x + h), HasDerivAt f'' (f''' y) y)
    (hM : ∀ y ∈ Set.Icc x (x + h), |f''' y| ≤ M) :
    |f (x + h) - f x - h * f' x - h ^ 2 / 2 * f'' x| ≤ M * h ^ 3 / 6 := by
  have hx : x ∈ Set.Icc x (x + h) := ⟨le_rfl, by linarith⟩
  -- step A
  have hA : ∀ y ∈ Set.Icc x (x + h), |f'' y - f'' x| ≤ M * (y - x) := by
    apply bump_bound_step (fun y => f'' y - f'' x) f''' (fun y => M * (y - x)) (fun _ => M)
    · intro y hy; simpa using (hf'' y hy).sub_const (f'' x)
    · intro y; simpa using ((hasDerivAt_id' y).sub_const x).const_mul M
    · simp
    · exact hM
  -- step B
  have hB : ∀ y ∈ Set.Icc x (x + h),
      |f' y - f' x - (y - x) * f'' x| ≤ M * (y - x) ^ 2 / 2 := by
    apply bump_bound_step (fun y => f' y - f' x - (y - x) * f'' x) (fun y => f'' y - f'' x)
      (fun y => M * (y - x) ^ 2 / 2) (fun y => M * (y - x))
    · intro y hy
      have := ((hf' y hy).sub_const (f' x)).sub (((hasDerivAt_id' y).sub_const x).mul_const (f'' x))
      convert this using 1; simp
    · intro y
      have := ((((hasDerivAt_id' y).sub_const x).pow 2).const_mul M).div_const 2
      convert this using 1; simp; ring
    · simp
    · exact hA
  -- step C
  have hC : ∀ y ∈ Set.Icc x (x + h),
      |f y - f x - (y - x) * f' x - (y - x) ^ 2 / 2 * f'' x| ≤ M * (y - x) ^ 3 / 6 := by
    apply bump_bound_step (fun y => f y - f x - (y - x) * f' x - (y - x) ^ 2 / 2 * f'' x)
      (fun y => f' y - f' x - (y - x) * f'' x)
      (fun y => M * (y - x) ^ 3 / 6) (fun y => M * (y - x) ^ 2 / 2)
    · intro y hy
      have := (((hf y hy).sub_const (f x)).sub
        (((hasDerivAt_id' y).sub_const x).mul_const (f' x))).sub
        (((((hasDerivAt_id' y).sub_const x).pow 2).div_const 2).mul_const (f'' x))
      convert this using 1; simp
    · intro y
      have := ((((hasDerivAt_id' y).sub_const x).pow 3).const_mul M).div_const 6
      convert this using 1; simp; ring
    · simp
    · exact hB
  have := hC (x + h) ⟨by linarith, le_rfl⟩
  simpa using this

#print axioms bump_bound_step
#print axioms bump_taylor3_right

/-- Central difference error: if the pricer `f` has a first, second and third slope
(`f'`, `f''`, `f'''`) everywhere between the bumped inputs `x - h` and `x + h`, and the
third slope stays within `M` in size there, then pricing above and below and dividing by
the full gap `2h` misses the true slope `f' x` by at most one sixth of the bump squared
times `M`. The second slope (gamma) has cancelled. -/
theorem central_difference_error_le (f f' f'' f''' : ℝ → ℝ) (x h M : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Set.Icc (x - h) (x + h), HasDerivAt f (f' y) y)
    (hf' : ∀ y ∈ Set.Icc (x - h) (x + h), HasDerivAt f' (f'' y) y)
    (hf'' : ∀ y ∈ Set.Icc (x - h) (x + h), HasDerivAt f'' (f''' y) y)
    (hM : ∀ y ∈ Set.Icc (x - h) (x + h), |f''' y| ≤ M) :
    |(f (x + h) - f (x - h)) / (2 * h) - f' x| ≤ h ^ 2 / 6 * M := by
  have sub_r : Set.Icc x (x + h) ⊆ Set.Icc (x - h) (x + h) :=
    Set.Icc_subset_Icc (by linarith) le_rfl
  have hR := bump_taylor3_right f f' f'' f''' x h M hh.le
    (fun y hy => hf y (sub_r hy)) (fun y hy => hf' y (sub_r hy))
    (fun y hy => hf'' y (sub_r hy)) (fun y hy => hM y (sub_r hy))
  -- reflected function
  have mem : ∀ y ∈ Set.Icc (-x) (-x + h), -y ∈ Set.Icc (x - h) (x + h) := by
    intro y hy; constructor <;> linarith [hy.1, hy.2]
  have hL := bump_taylor3_right (fun y => f (-y)) (fun y => -f' (-y)) (fun y => f'' (-y))
    (fun y => -f''' (-y)) (-x) h M hh.le
    (fun y hy => by
      have := (hf (-y) (mem y hy)).comp y (hasDerivAt_neg y)
      convert this using 1 <;> first | rfl | ring)
    (fun y hy => by
      have := ((hf' (-y) (mem y hy)).comp y (hasDerivAt_neg y)).neg
      convert this using 1 <;> first | rfl | ring)
    (fun y hy => by
      have := (hf'' (-y) (mem y hy)).comp y (hasDerivAt_neg y)
      convert this using 1 <;> first | rfl | ring)
    (fun y hy => by simpa [abs_neg] using hM (-y) (mem y hy))
  simp only [neg_neg, neg_add_rev] at hL
  have e1 : -h + x = x - h := by ring
  rw [e1] at hL
  have h2 : (0:ℝ) < 2 * h := by linarith
  rw [div_sub' (ne_of_gt h2), abs_div, abs_of_pos h2, div_le_iff₀ h2]
  have key : f (x + h) - f (x - h) - 2 * h * f' x =
      (f (x + h) - f x - h * f' x - h ^ 2 / 2 * f'' x) -
      (f (x - h) - f x - h * -f' x - h ^ 2 / 2 * f'' x) := by ring
  have : |f (x + h) - f (x - h) - 2 * h * f' x| ≤ M * h ^ 3 / 6 + M * h ^ 3 / 6 := by
    rw [key]; exact (abs_sub _ _).trans (add_le_add hR hL)
  calc |f (x + h) - f (x - h) - 2 * h * f' x| ≤ M * h ^ 3 / 6 + M * h ^ 3 / 6 := this
    _ = h ^ 2 / 6 * M * (2 * h) := by ring

/-- One-sided bump: under the same smoothness between `x` and `x + h`, the forward
difference equals the true slope plus half a bump of the second slope (gamma),
up to at most one sixth of the bump squared times the bound `M` on the third slope.
So a one-sided bump is biased by about `h * f'' x / 2`, first order in the bump. -/
theorem forward_difference_bias_le (f f' f'' f''' : ℝ → ℝ) (x h M : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Set.Icc x (x + h), HasDerivAt f (f' y) y)
    (hf' : ∀ y ∈ Set.Icc x (x + h), HasDerivAt f' (f'' y) y)
    (hf'' : ∀ y ∈ Set.Icc x (x + h), HasDerivAt f'' (f''' y) y)
    (hM : ∀ y ∈ Set.Icc x (x + h), |f''' y| ≤ M) :
    |(f (x + h) - f x) / h - f' x - h / 2 * f'' x| ≤ h ^ 2 / 6 * M := by
  have hR := bump_taylor3_right f f' f'' f''' x h M hh.le hf hf' hf'' hM
  have e : (f (x + h) - f x) / h - f' x - h / 2 * f'' x =
      (f (x + h) - f x - h * f' x - h ^ 2 / 2 * f'' x) / h := by
    field_simp
  rw [e, abs_div, abs_of_pos hh, div_le_iff₀ hh]
  calc _ ≤ M * h ^ 3 / 6 := hR
    _ = h ^ 2 / 6 * M * h := by ring

/-- Common random numbers cannot run away: on one simulated path that multiplies the
share by `a ≥ 0`, the discounted call payoffs `D * max (s * a - K) 0` started at `S + h`
and `S - h` differ by at most the gap `2h` times `D * a`, so the paired difference divided
by `2h` is at most `D * a` in size, however small the bump `h > 0` is. -/
theorem common_random_numbers_paired_difference_le (D a K S h : ℝ)
    (hD : 0 ≤ D) (ha : 0 ≤ a) (hh : 0 < h) :
    |(D * max ((S + h) * a - K) 0 - D * max ((S - h) * a - K) 0) / (2 * h)| ≤ D * a := by
  have h2 : (0:ℝ) < 2 * h := by linarith
  rw [abs_div, abs_of_pos h2, div_le_iff₀ h2, ← mul_sub, abs_mul, abs_of_nonneg hD]
  have hlip : |max ((S + h) * a - K) 0 - max ((S - h) * a - K) 0| ≤
      |((S + h) * a - K) - ((S - h) * a - K)| := abs_max_sub_max_le_abs _ _ _
  have e : ((S + h) * a - K) - ((S - h) * a - K) = 2 * h * a := by ring
  rw [e, abs_of_nonneg (a := 2 * h * a) (mul_nonneg h2.le ha)] at hlip
  calc D * |max ((S + h) * a - K) 0 - max ((S - h) * a - K) 0| ≤ D * (2 * h * a) :=
        mul_le_mul_of_nonneg_left hlip hD
    _ = D * a * (2 * h) := by ring

#print axioms central_difference_error_le
#print axioms forward_difference_bias_le
#print axioms common_random_numbers_paired_difference_le
