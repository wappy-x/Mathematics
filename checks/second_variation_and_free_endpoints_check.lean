-- The second variation: with strict Legendre and no conjugate point up to the end, the second variation is positive for every nonzero pinned nudge; past the conjugate point pi the equator's bulge has negative cost; and for length, transversality at a sliding end means meeting the end curve at right angles.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Analysis.Calculus.ContDiff.Basic

open Real Set
open Filter Topology

/-- **Jacobi's test: strict Legendre and no conjugate point make the second variation positive.**
The second variation of a stationary path on `[a, b]` is
`δ²J[η] = ∫ (P η'² + Q η²) dt` with weights `P = F_pp / 2` and `Q`.
Suppose the strict Legendre condition `P > 0` holds on `[a, b]`, and the Jacobi field `u`
(the solution of the Jacobi equation `(P u')' = Q u` with `u(a) = 0`, `u'(a) = 1`) has no
conjugate point in `(a, b]`, that is, no zero there. Then every smooth nudge `η` pinned at both
ends (`η(a) = η(b) = 0`) and not zero everywhere has `δ²J[η] > 0`: the stationary path is a
strict local minimum. -/
theorem second_variation_pos_of_legendre_and_no_conjugate_point
    (P Q u η : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hP : ContDiff ℝ 1 P) (hQ : Continuous Q) (hu : ContDiff ℝ 2 u)
    (hlegendre : ∀ t ∈ Icc a b, 0 < P t)
    (hjacobi : ∀ t ∈ Icc a b, deriv (fun s => P s * deriv u s) t = Q t * u t)
    (hu_a : u a = 0) (hu'_a : deriv u a = 1)
    (hno_conj : ∀ t ∈ Ioc a b, u t ≠ 0)
    (hη : ContDiff ℝ 1 η) (hη_a : η a = 0) (hη_b : η b = 0)
    (hη_ne : ∃ t ∈ Icc a b, η t ≠ 0) :
    0 < ∫ t in a..b, (P t * deriv η t ^ 2 + Q t * η t ^ 2) := by
  -- regularity
  have hPdiff : Differentiable ℝ P := hP.differentiable (by norm_num)
  have hPc : Continuous P := hP.continuous
  have hu2 := contDiff_succ_iff_deriv.mp (show ContDiff ℝ (1 + 1) u from hu)
  have hudiff : Differentiable ℝ u := hu2.1
  have hu'C : ContDiff ℝ 1 (deriv u) := hu2.2.2
  have hu'diff : Differentiable ℝ (deriv u) := hu'C.differentiable (by norm_num)
  have huc : Continuous u := hudiff.continuous
  have hu'c : Continuous (deriv u) := hu'C.continuous
  have hηdiff : Differentiable ℝ η := hη.differentiable (by norm_num)
  have hηc : Continuous η := hη.continuous
  have hη'c : Continuous (deriv η) := hη.continuous_deriv le_rfl
  -- the pieces
  set f : ℝ → ℝ := fun t => P t * deriv η t ^ 2 + Q t * η t ^ 2 with hf
  set h : ℝ → ℝ := fun t => P t * (deriv η t - η t * deriv u t / u t) ^ 2 with hh
  set g : ℝ → ℝ := fun t => (P t * deriv u t) * (η t ^ 2 / u t) with hg
  have hfc : Continuous f := by
    simp only [hf]; fun_prop
  have hgd : ∀ t ∈ Ioc a b, HasDerivAt g (f t - h t) t := by
    intro t ht
    have hut : u t ≠ 0 := hno_conj t ht
    have h1 : HasDerivAt (fun s => P s * deriv u s) (Q t * u t) t := by
      have hd : DifferentiableAt ℝ (fun s => P s * deriv u s) t := (hPdiff t).mul (hu'diff t)
      have := hd.hasDerivAt
      rwa [hjacobi t (Ioc_subset_Icc_self ht)] at this
    have h2 : HasDerivAt (fun s => η s ^ 2 / u s)
        (((2 : ℕ) * η t ^ (2 - 1) * deriv η t * u t - η t ^ 2 * deriv u t) / u t ^ 2) t :=
      ((hηdiff t).hasDerivAt.pow 2).div (hudiff t).hasDerivAt hut
    convert h1.mul h2 using 1
    simp only [hf, hh]
    field_simp
    ring
  have hhcont : ContinuousOn h (Ioc a b) := by
    simp only [hh]
    exact hPc.continuousOn.mul ((hη'c.continuousOn.sub
      ((hηc.continuousOn.mul hu'c.continuousOn).div huc.continuousOn
        (fun t ht => hno_conj t ht))).pow 2)
  have hhnn : ∀ t ∈ Ioc a b, 0 ≤ h t := fun t ht =>
    mul_nonneg (hlegendre t (Ioc_subset_Icc_self ht)).le (sq_nonneg _)
  have hhint : ∀ x y, a < x → x ≤ y → y ≤ b → IntervalIntegrable h MeasureTheory.volume x y := by
    intro x y hx hxy hy
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le hxy]
    exact hhcont.mono (Icc_subset_Ioc hx hy)
  -- the identity on [c, b]
  have hid : ∀ c ∈ Ioc a b, ∫ t in c..b, f t = (∫ t in c..b, h t) - g c := by
    intro c hc
    have hfint : IntervalIntegrable f MeasureTheory.volume c b := hfc.intervalIntegrable _ _
    have hint := hhint c b hc.1 hc.2 le_rfl
    have hftc : ∫ t in c..b, (f t - h t) = g b - g c := by
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt
      · intro x hx
        rw [uIcc_of_le hc.2] at hx
        exact hgd x ⟨lt_of_lt_of_le hc.1 hx.1, hx.2⟩
      · exact hfint.sub hint
    rw [intervalIntegral.integral_sub hfint hint] at hftc
    have hgb : g b = 0 := by simp [hg, hη_b]
    rw [hgb] at hftc
    linarith
  -- the boundary term vanishes at a
  have hglim : Tendsto g (𝓝[>] a) (𝓝 0) := by
    have hle : 𝓝[>] a ≤ 𝓝[≠] a := nhdsWithin_mono _ (fun x hx => ne_of_gt hx)
    have hηs : Tendsto (slope η a) (𝓝[>] a) (𝓝 (deriv η a)) :=
      (hasDerivAt_iff_tendsto_slope.mp (hηdiff a).hasDerivAt).mono_left hle
    have hus : Tendsto (slope u a) (𝓝[>] a) (𝓝 1) := by
      have := (hasDerivAt_iff_tendsto_slope.mp (hudiff a).hasDerivAt).mono_left hle
      rwa [hu'_a] at this
    have hpre : Tendsto (fun c => P c * deriv u c) (𝓝[>] a) (𝓝 (P a * deriv u a)) :=
      ((hPc.mul hu'c).tendsto a).mono_left nhdsWithin_le_nhds
    have hηt : Tendsto η (𝓝[>] a) (𝓝 0) := by
      have := (hηc.tendsto a).mono_left (nhdsWithin_le_nhds (s := Ioi a))
      rwa [hη_a] at this
    have hall := hpre.mul (hηt.mul (hηs.div hus one_ne_zero))
    rw [zero_mul, mul_zero] at hall
    refine hall.congr' ?_
    filter_upwards [Ioo_mem_nhdsGT hab] with c hc
    have hca : c - a ≠ 0 := sub_ne_zero.mpr (ne_of_gt hc.1)
    have huc0 : u c ≠ 0 := hno_conj c ⟨hc.1, hc.2.le⟩
    simp only [hg, Pi.div_apply, slope_def_field, hη_a, hu_a, sub_zero]
    field_simp
  -- the left integral converges
  have hflim : Tendsto (fun c => ∫ t in c..b, f t) (𝓝[>] a) (𝓝 (∫ t in a..b, f t)) := by
    have hcont : Continuous (fun c => ∫ t in c..b, f t) := by
      have := (intervalIntegral.continuous_primitive (μ := MeasureTheory.volume)
        (fun x y => hfc.intervalIntegrable x y) b).neg
      refine this.congr ?_
      intro c
      simp [intervalIntegral.integral_symm b c]
    exact (hcont.tendsto a).mono_left nhdsWithin_le_nhds
  -- positivity of the square term on a small window
  obtain ⟨t0, ht0, hηt0⟩ := hη_ne
  have ht0a : a < t0 := by
    rcases eq_or_lt_of_le ht0.1 with h' | h'
    · exact absurd (h' ▸ hη_a) hηt0
    · exact h'
  have ht0b : t0 < b := by
    rcases eq_or_lt_of_le ht0.2 with h' | h'
    · exact absurd (h' ▸ hη_b) hηt0
    · exact h'
  have hrc : ContinuousOn (fun t => η t / u t) (Icc t0 b) :=
    hηc.continuousOn.div huc.continuousOn
      (fun t ht => hno_conj t ⟨lt_of_lt_of_le ht0a ht.1, ht.2⟩)
  have hrd : ∀ x ∈ Ioo t0 b, HasDerivAt (fun t => η t / u t)
      ((deriv η x * u x - η x * deriv u x) / u x ^ 2) x := fun x hx =>
    (hηdiff x).hasDerivAt.div (hudiff x).hasDerivAt
      (hno_conj x ⟨ht0a.trans hx.1, hx.2.le⟩)
  obtain ⟨s, hs, hseq⟩ := exists_hasDerivAt_eq_slope (fun t => η t / u t) _ ht0b hrc hrd
  have hsI : s ∈ Ioc a b := ⟨ht0a.trans hs.1, hs.2.le⟩
  have hus0 : u s ≠ 0 := hno_conj s hsI
  have hut0 : u t0 ≠ 0 := hno_conj t0 ⟨ht0a, ht0b.le⟩
  have hhs : 0 < h s := by
    have hne : deriv η s - η s * deriv u s / u s ≠ 0 := by
      intro hz
      have hnum : deriv η s * u s - η s * deriv u s
          = (deriv η s - η s * deriv u s / u s) * u s := by field_simp
      have hseq' : (deriv η s * u s - η s * deriv u s) / u s ^ 2
          = (η b / u b - η t0 / u t0) / (b - t0) := hseq
      rw [hnum, hz, zero_mul, zero_div, hη_b, zero_div, zero_sub] at hseq'
      exact div_ne_zero (neg_ne_zero.mpr (div_ne_zero hηt0 hut0))
        (sub_ne_zero.mpr ht0b.ne') hseq'.symm
    exact mul_pos (hlegendre s (Ioc_subset_Icc_self hsI))
      (lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hne)))
  have hcs : ContinuousAt h s := hhcont.continuousAt (Ioc_mem_nhds hsI.1 hs.2)
  obtain ⟨ε, hε, hball⟩ := Metric.eventually_nhds_iff.mp (hcs.eventually (lt_mem_nhds hhs))
  set s1 := max (s - ε / 2) t0 with hs1def
  set s2 := min (s + ε / 2) b with hs2def
  have hs1 : s1 < s := max_lt (by linarith) hs.1
  have hs2 : s < s2 := lt_min (by linarith) hs.2
  have ha1 : a < s1 := lt_of_lt_of_le ht0a (le_max_right _ _)
  have hs1b : s1 ≤ b := (hs1.trans hs.2).le
  have hs2b : s2 ≤ b := min_le_right _ _
  have ha2 : a < s2 := ha1.trans (hs1.trans hs2)
  have hH : 0 < ∫ t in s1..s2, h t := by
    apply intervalIntegral.intervalIntegral_pos_of_pos_on
      (hhint s1 s2 ha1 (hs1.trans hs2).le hs2b) _ (hs1.trans hs2)
    intro y hy
    apply hball
    rw [Real.dist_eq, abs_sub_lt_iff]
    have h1 : s - ε / 2 ≤ s1 := le_max_left _ _
    have h2 : s2 ≤ s + ε / 2 := min_le_left _ _
    constructor <;> linarith [hy.1, hy.2]
  have hφ : Tendsto (fun c => (∫ t in c..b, f t) + g c) (𝓝[>] a)
      (𝓝 ((∫ t in a..b, f t) + 0)) := hflim.add hglim
  have hev : ∀ᶠ c in 𝓝[>] a, (∫ t in s1..s2, h t) ≤ (∫ t in c..b, f t) + g c := by
    filter_upwards [Ioo_mem_nhdsGT ha1] with c hc
    rw [hid c ⟨hc.1, hc.2.le.trans hs1b⟩, sub_add_cancel,
      ← intervalIntegral.integral_add_adjacent_intervals (hhint c s1 hc.1 hc.2.le hs1b)
        (hhint s1 b ha1 hs1b le_rfl),
      ← intervalIntegral.integral_add_adjacent_intervals
        (hhint s1 s2 ha1 (hs1.trans hs2).le hs2b) (hhint s2 b ha2 hs2b le_rfl)]
    have n1 : 0 ≤ ∫ t in c..s1, h t := intervalIntegral.integral_nonneg hc.2.le
      (fun t ht => hhnn t ⟨hc.1.trans_le ht.1, ht.2.trans hs1b⟩)
    have n2 : 0 ≤ ∫ t in s2..b, h t := intervalIntegral.integral_nonneg hs2b
      (fun t ht => hhnn t ⟨ha2.trans_le ht.1, ht.2⟩)
    linarith
  have := ge_of_tendsto hφ hev
  show 0 < ∫ t in a..b, f t
  linarith

/-- **Past the conjugate point the stationary path is a saddle.** For the equator,
`J[y] = ∫₀ᵀ (y'² - y²) dt`. The bulge `η(t) = sin(π t / T)` is pinned at both ends and has
`J[η] = π² / (2T) - T / 2`, which is negative once the trip is longer than `π`
(at `T = 4` it is `2 (π²/16 - 1) ≈ -0.7663`). -/
theorem bulge_second_variation_eq_and_neg_past_pi (T : ℝ) (hT : 0 < T) :
    sin (π * 0 / T) = 0 ∧ sin (π * T / T) = 0 ∧
    (∫ t in (0 : ℝ)..T, (deriv (fun s => sin (π * s / T)) t ^ 2 - sin (π * t / T) ^ 2))
      = π ^ 2 / (2 * T) - T / 2 ∧
    (π < T → π ^ 2 / (2 * T) - T / 2 < 0) := by
  have hT0 : T ≠ 0 := hT.ne'
  refine ⟨by simp, by rw [mul_div_assoc, div_self hT0, mul_one, sin_pi], ?_, ?_⟩
  · have hd : ∀ t, HasDerivAt (fun s => sin (π * s / T)) (cos (π * t / T) * (π / T)) t := by
      intro t
      have h1 : HasDerivAt (fun s => π * s / T) (π / T) t := by
        simpa using ((hasDerivAt_id t).const_mul π).div_const T
      exact h1.sin
    have hfun : (fun t => deriv (fun s => sin (π * s / T)) t ^ 2 - sin (π * t / T) ^ 2)
        = fun t => (cos (π * t / T) * (π / T)) ^ 2 - sin (π * t / T) ^ 2 := by
      funext t; rw [(hd t).deriv]
    rw [hfun]
    set F : ℝ → ℝ := fun t => (π ^ 2 / T ^ 2 - 1) / 2 * t
      + (π ^ 2 / T ^ 2 + 1) / 2 * (sin (2 * π * t / T) * (T / (2 * π))) with hF
    have hFd : ∀ x ∈ uIcc 0 T, HasDerivAt F
        ((cos (π * x / T) * (π / T)) ^ 2 - sin (π * x / T) ^ 2) x := by
      intro x _
      have h1 : HasDerivAt (fun s => 2 * π * s / T) (2 * π / T) x := by
        simpa using ((hasDerivAt_id x).const_mul (2 * π)).div_const T
      have h2 := (((hasDerivAt_id x).const_mul ((π ^ 2 / T ^ 2 - 1) / 2)).add
        ((h1.sin.mul_const (T / (2 * π))).const_mul ((π ^ 2 / T ^ 2 + 1) / 2)))
      have h3 : HasDerivAt F ((π ^ 2 / T ^ 2 - 1) / 2 * 1 + (π ^ 2 / T ^ 2 + 1) / 2 *
          (cos (2 * π * x / T) * (2 * π / T) * (T / (2 * π)))) x := h2
      convert h3 using 1
      have hc : cos (2 * π * x / T) = 2 * cos (π * x / T) ^ 2 - 1 := by
        rw [show 2 * π * x / T = 2 * (π * x / T) by ring, cos_two_mul]
      · rw [hc]
        have hs := sin_sq_add_cos_sq (π * x / T)
        have hpi : π ≠ 0 := pi_pos.ne'
        field_simp
        nlinarith [hs]
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hFd]
    · simp only [hF]
      have : 2 * π * T / T = 2 * π := by field_simp
      rw [this, sin_two_pi]
      simp only [mul_zero, zero_div, sin_zero, zero_mul, add_zero]
      field_simp
      ring
    · apply Continuous.intervalIntegrable
      fun_prop
  · intro h
    have hpT : π ^ 2 < T ^ 2 := by nlinarith [pi_pos]
    rw [sub_neg, div_lt_iff₀ (by positivity)]
    nlinarith

/-- **Transversality for length means right angles.** For the length cost per step
`F(p) = √(1 + p²)`, with slope pull `F_p = F'(p)`, the transversality condition
`F + (c' - y') F_p = 0` at an end sliding on a curve of slope `c'` holds exactly when
`1 + c' y' = 0`: the path meets the end curve at right angles. -/
theorem length_transversality_iff_right_angle (y' c' : ℝ) :
    sqrt (1 + y' ^ 2) + (c' - y') * deriv (fun p : ℝ => sqrt (1 + p ^ 2)) y' = 0 ↔
      1 + c' * y' = 0 := by
  have hpos : 0 < 1 + y' ^ 2 := by positivity
  have hs : 0 < sqrt (1 + y' ^ 2) := sqrt_pos.mpr hpos
  have hsq : sqrt (1 + y' ^ 2) ^ 2 = 1 + y' ^ 2 := sq_sqrt hpos.le
  have hd : HasDerivAt (fun p : ℝ => sqrt (1 + p ^ 2)) (2 * y' / (2 * sqrt (1 + y' ^ 2))) y' := by
    have h1 : HasDerivAt (fun p : ℝ => 1 + p ^ 2) (2 * y') y' := by
      simpa using ((hasDerivAt_id y').pow 2).const_add 1
    convert h1.sqrt hpos.ne' using 1
  rw [hd.deriv]
  have key : sqrt (1 + y' ^ 2) + (c' - y') * (2 * y' / (2 * sqrt (1 + y' ^ 2)))
      = (1 + c' * y') / sqrt (1 + y' ^ 2) := by
    field_simp
    nlinarith [hsq]
  rw [key, div_eq_zero_iff]
  constructor
  · rintro (h | h)
    · exact h
    · exact absurd h hs.ne'
  · intro h; exact Or.inl h

-- The card's exact worked numbers.
-- Legendre for F = p² - y²: the slope weight F_pp is 2 > 0.
example (y p : ℝ) : deriv (fun q : ℝ => deriv (fun r : ℝ => r ^ 2 - y ^ 2) q) p = 2 := by
  simp
-- The Jacobi field sin t is positive on (0, π) and returns to 0 at π: the conjugate point.
example : sin π = 0 ∧ ∀ t ∈ Ioo 0 π, 0 < sin t :=
  ⟨sin_pi, fun _ ht => sin_pos_of_pos_of_lt_pi ht.1 ht.2⟩
-- At T = 4 the bulge's cost π²/(2T) - T/2 is 2(π²/16 - 1), and π < 4 makes it negative.
example : π ^ 2 / (2 * 4) - 4 / 2 = 2 * (π ^ 2 / 16 - 1) := by ring
example : 2 * (π ^ 2 / 16 - 1) < 0 := by nlinarith [pi_lt_four, pi_pos]
-- The pipe: transversality 1 + c' y' = 0 with coast slope c' = -1 gives y' = 1.
example : (1 : ℤ) + (-1) * 1 = 0 := by norm_num
-- The end (1, 1) lies on the coast y = 2 - x, and the squared length 1² + 1² = 2 is the least
-- squared distance from (0, 0) to any coast point (s, 2 - s).
example : (1 : ℤ) = 2 - 1 ∧ (1 : ℤ) ^ 2 + 1 ^ 2 = 2 := by norm_num
example (s : ℝ) : 2 ≤ s ^ 2 + (2 - s) ^ 2 := by nlinarith [sq_nonneg (s - 1)]
-- The wrong pipe due east to (2, 0) has squared length 4, longer than 2.
example : (2 : ℤ) ^ 2 + 0 ^ 2 = 4 ∧ (2 : ℤ) < 4 := by norm_num

#print axioms second_variation_pos_of_legendre_and_no_conjugate_point
#print axioms bulge_second_variation_eq_and_neg_past_pi
#print axioms length_transversality_iff_right_angle
