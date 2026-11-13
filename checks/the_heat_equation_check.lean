-- The heat equation: a sine bump of frequency n on a rod with ends at 0 solves u_t = κ u_xx while decaying as e^(-κ n² π² t), and with κ > 0 no point inside the rod ever gets hotter than the largest value at the start or at the ends.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Real Set

/-- One-sided first-derivative test: if `g` is largest at `t₀` among the earlier times of an
interval `(a, t₀]`, its derivative from the past at `t₀` is at least 0. -/
theorem heat_left_deriv_nonneg_of_max (g : ℝ → ℝ) (d a t₀ : ℝ) (ha : a < t₀)
    (hd : HasDerivWithinAt g d (Iic t₀) t₀) (hmax : ∀ s ∈ Ioo a t₀, g s ≤ g t₀) : 0 ≤ d := by
  rw [hasDerivWithinAt_iff_tendsto_slope, Iic_sdiff_right] at hd
  refine ge_of_tendsto hd ?_
  have hmem : Ioo a t₀ ∈ nhdsWithin t₀ (Iio t₀) := Ioo_mem_nhdsLT ha
  filter_upwards [hmem] with s hs
  rw [slope_def_field]
  exact div_nonneg_of_nonpos (by linarith [hmax s hs]) (by linarith [hs.2])

#print axioms heat_left_deriv_nonneg_of_max

/-- Second-derivative test: if `f` is largest at an inside point `x₀` of `(a, b)`, has slope
`f'` on `(a, b)`, and `f'` has derivative `c` at `x₀`, then `c ≤ 0`. -/
theorem heat_second_deriv_nonpos_of_max (f f' : ℝ → ℝ) (a b x₀ c : ℝ) (hx₀ : x₀ ∈ Ioo a b)
    (hf : ∀ y ∈ Ioo a b, HasDerivAt f (f' y) y) (hc : HasDerivAt f' c x₀)
    (hmax : ∀ y ∈ Ioo a b, f y ≤ f x₀) : c ≤ 0 := by
  by_contra hpos
  push Not at hpos
  have hloc : IsLocalMax f x₀ :=
    Filter.mem_of_superset (Ioo_mem_nhds hx₀.1 hx₀.2) fun y hy => hmax y hy
  have h0 : f' x₀ = 0 := IsLocalMax.hasDerivAt_eq_zero hloc (hf x₀ hx₀)
  have hsl := (hasDerivAt_iff_tendsto_slope_left_right.mp hc).2
  have hev : ∀ᶠ y in nhdsWithin x₀ (Ioi x₀), 0 < slope f' x₀ y :=
    hsl.eventually (Ioi_mem_nhds hpos)
  have hev2 : ∀ᶠ y in nhdsWithin x₀ (Ioi x₀), y < b :=
    nhdsWithin_le_nhds (Iio_mem_nhds hx₀.2)
  obtain ⟨u, hu, hsub⟩ := mem_nhdsGT_iff_exists_Ioo_subset.mp (hev.and hev2)
  have hpos' : ∀ y ∈ Ioo x₀ u, 0 < f' y := by
    intro y hy
    have h := (hsub hy).1
    rw [slope_def_field, h0, sub_zero] at h
    exact (div_pos_iff_of_pos_right (by linarith [hy.1])).mp h
  have hu' : x₀ < u := hu
  set y₁ := (x₀ + u) / 2 with hy₁_def
  have hy₁ : y₁ ∈ Ioo x₀ u := ⟨by rw [hy₁_def]; linarith, by rw [hy₁_def]; linarith⟩
  have hy₁b : y₁ < b := (hsub hy₁).2
  have hsubI : Icc x₀ y₁ ⊆ Ioo a b := fun z hz => ⟨by linarith [hz.1, hx₀.1], by linarith [hz.2]⟩
  have hcont : ContinuousOn f (Icc x₀ y₁) := fun z hz =>
    (hf z (hsubI hz)).continuousAt.continuousWithinAt
  obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope f f' hy₁.1 hcont
    (fun z hz => hf z (hsubI (Ioo_subset_Icc_self hz)))
  have hξpos : 0 < f' ξ := hpos' ξ ⟨hξ.1, hξ.2.trans hy₁.2⟩
  rw [hξeq] at hξpos
  have : 0 < f y₁ - f x₀ := (div_pos_iff_of_pos_right (by linarith [hy₁.1])).mp hξpos
  linarith [hmax y₁ ⟨by linarith [hx₀.1, hy₁.1], hy₁b⟩]

#print axioms heat_second_deriv_nonpos_of_max

/-- A sine bump of frequency `n` keeps its shape and decays at rate `κ n² π²`:
`u(x, t) = e^(-κ n² π² t) sin(n π x)` satisfies the heat equation `u_t = κ u_xx` at every
place and time, its ends stay at 0, and it starts as `sin(n π x)`. -/
theorem sine_bump_decays_at_rate_kappa_n_sq_pi_sq (κ : ℝ) (n : ℕ) :
    (∀ x t : ℝ,
      deriv (fun s => exp (-(κ * n ^ 2 * π ^ 2) * s) * sin (n * π * x)) t
        = κ * deriv (deriv (fun y => exp (-(κ * n ^ 2 * π ^ 2) * t) * sin (n * π * y))) x) ∧
    (∀ t : ℝ, exp (-(κ * n ^ 2 * π ^ 2) * t) * sin (n * π * 0) = 0 ∧
              exp (-(κ * n ^ 2 * π ^ 2) * t) * sin (n * π * 1) = 0) ∧
    (∀ x : ℝ, exp (-(κ * n ^ 2 * π ^ 2) * 0) * sin (n * π * x) = sin (n * π * x)) := by
  refine ⟨fun x t => ?_, fun t => ?_, fun x => ?_⟩
  · have ht : HasDerivAt (fun s => exp (-(κ * n ^ 2 * π ^ 2) * s) * sin (n * π * x))
        (exp (-(κ * n ^ 2 * π ^ 2) * t) * (-(κ * n ^ 2 * π ^ 2) * 1) * sin (n * π * x)) t :=
      (((hasDerivAt_id t).const_mul _).exp).mul_const _
    have hx1 : ∀ y, HasDerivAt (fun y => exp (-(κ * n ^ 2 * π ^ 2) * t) * sin (n * π * y))
        (exp (-(κ * n ^ 2 * π ^ 2) * t) * (cos (n * π * y) * (n * π * 1))) y := fun y =>
      (((hasDerivAt_id y).const_mul _).sin).const_mul _
    have hd1 : deriv (fun y => exp (-(κ * n ^ 2 * π ^ 2) * t) * sin (n * π * y))
        = fun y => exp (-(κ * n ^ 2 * π ^ 2) * t) * (cos (n * π * y) * (n * π * 1)) :=
      funext fun y => (hx1 y).deriv
    have hx2 : HasDerivAt (fun y => exp (-(κ * n ^ 2 * π ^ 2) * t) * (cos (n * π * y) * (n * π * 1)))
        (exp (-(κ * n ^ 2 * π ^ 2) * t) * ((-sin (n * π * x) * (n * π * 1)) * (n * π * 1))) x :=
      ((((hasDerivAt_id x).const_mul _).cos).mul_const _).const_mul _
    rw [ht.deriv, hd1, hx2.deriv]
    ring
  · simp [Real.sin_nat_mul_pi]
  · simp

/-- The maximum principle: let `u` solve the heat equation `u_t = κ u_xx` with `κ > 0`
(heat flows down the temperature slope) and no heat source, on the rod `0 ≤ x ≤ 1` over the
times `0 ≤ t ≤ T`. If `u ≤ M` at the start and at both ends, then `u ≤ M` everywhere on the
rod over that time: no point inside ever gets hotter than the start or the ends.
Here `ux`, `uxx` and `ut` are the slope, the bend and the warming rate (one-sided from the past,
so it also makes sense at the last moment `t = T`). -/
theorem heat_maximum_principle (κ T M : ℝ) (hκ : 0 < κ) (u ux uxx ut : ℝ → ℝ → ℝ)
    (hcont : ContinuousOn (fun p : ℝ × ℝ => u p.1 p.2) (Icc 0 1 ×ˢ Icc 0 T))
    (hux : ∀ x ∈ Ioo (0 : ℝ) 1, ∀ t ∈ Ioc 0 T, HasDerivAt (fun y => u y t) (ux x t) x)
    (huxx : ∀ x ∈ Ioo (0 : ℝ) 1, ∀ t ∈ Ioc 0 T, HasDerivAt (fun y => ux y t) (uxx x t) x)
    (hut : ∀ x ∈ Ioo (0 : ℝ) 1, ∀ t ∈ Ioc 0 T,
      HasDerivWithinAt (fun s => u x s) (ut x t) (Iic t) t)
    (hpde : ∀ x ∈ Ioo (0 : ℝ) 1, ∀ t ∈ Ioc 0 T, ut x t = κ * uxx x t)
    (hstart : ∀ x ∈ Icc (0 : ℝ) 1, u x 0 ≤ M)
    (hends : ∀ t ∈ Icc 0 T, u 0 t ≤ M ∧ u 1 t ≤ M) :
    ∀ x ∈ Icc (0 : ℝ) 1, ∀ t ∈ Icc 0 T, u x t ≤ M := by
  intro x₁ hx₁ t₁ ht₁
  by_contra hgt
  push Not at hgt
  have hT : 0 ≤ T := ht₁.1.trans ht₁.2
  set ε := (u x₁ t₁ - M) / (T + 1) with hε_def
  have hε : 0 < ε := div_pos (by linarith) (by linarith)
  have hεt₁ : ε * t₁ < u x₁ t₁ - M := by
    have h1 : ε * (T + 1) = u x₁ t₁ - M := by rw [hε_def]; field_simp
    nlinarith [ht₁.2]
  set K : Set (ℝ × ℝ) := Icc 0 1 ×ˢ Icc 0 T
  have hK : IsCompact K := isCompact_Icc.prod isCompact_Icc
  have hvcont : ContinuousOn (fun p : ℝ × ℝ => u p.1 p.2 - ε * p.2) K :=
    hcont.sub (continuousOn_const.mul continuous_snd.continuousOn)
  have hmemK : (x₁, t₁) ∈ K := ⟨hx₁, ht₁⟩
  obtain ⟨⟨x₀, t₀⟩, hp₀, hmax⟩ := hK.exists_isMaxOn ⟨_, hmemK⟩ hvcont
  have hmax' : ∀ y ∈ Icc (0 : ℝ) 1, ∀ s ∈ Icc 0 T, u y s - ε * s ≤ u x₀ t₀ - ε * t₀ :=
    fun y hy s hs => hmax (show (y, s) ∈ K from ⟨hy, hs⟩)
  have hbig : M < u x₀ t₀ - ε * t₀ := by
    have := hmax' x₁ hx₁ t₁ ht₁
    linarith
  obtain ⟨hx₀, ht₀⟩ := hp₀
  simp only [mem_Icc] at hx₀ ht₀
  -- the largest value is not on the bottom edge or the two ends
  have hεt₀ : 0 ≤ ε * t₀ := mul_nonneg hε.le ht₀.1
  have hx0 : x₀ ≠ 0 := by
    rintro rfl; linarith [(hends t₀ ⟨ht₀.1, ht₀.2⟩).1]
  have hx1 : x₀ ≠ 1 := by
    rintro rfl; linarith [(hends t₀ ⟨ht₀.1, ht₀.2⟩).2]
  have ht0 : t₀ ≠ 0 := by
    rintro rfl; linarith [hstart x₀ ⟨hx₀.1, hx₀.2⟩]
  have hxI : x₀ ∈ Ioo (0 : ℝ) 1 :=
    ⟨lt_of_le_of_ne hx₀.1 (Ne.symm hx0), lt_of_le_of_ne hx₀.2 hx1⟩
  have htI : t₀ ∈ Ioc (0 : ℝ) T := ⟨lt_of_le_of_ne ht₀.1 (Ne.symm ht0), ht₀.2⟩
  -- in time: warming rate at least ε
  have htime : 0 ≤ ut x₀ t₀ - ε := by
    refine heat_left_deriv_nonneg_of_max (fun s => u x₀ s - ε * s) _ 0 t₀ htI.1 ?_ ?_
    · have h2 : HasDerivWithinAt (fun s : ℝ => ε * s) ε (Iic t₀) t₀ := by
        simpa using (hasDerivWithinAt_id t₀ (Iic t₀)).const_mul ε
      exact (hut x₀ hxI t₀ htI).sub h2
    · intro s hs
      exact hmax' x₀ hx₀ s ⟨hs.1.le, hs.2.le.trans ht₀.2⟩
  -- in space: bend at most 0
  have hspace : uxx x₀ t₀ ≤ 0 := by
    refine heat_second_deriv_nonpos_of_max (fun y => u y t₀) (fun y => ux y t₀) 0 1 x₀ _ hxI
      (fun y hy => hux y hy t₀ htI) (huxx x₀ hxI t₀ htI) ?_
    intro y hy
    have := hmax' y ⟨hy.1.le, hy.2.le⟩ t₀ ⟨ht₀.1, ht₀.2⟩
    simpa using this
  have := hpde x₀ hxI t₀ htI
  nlinarith

/-- Half-lives: at the arch's half-life `t = ln 2 / (κ π²)`, a sine bump of frequency `n` has
shrunk to `(1/2)^(n²)` of its height. So the arch (`n = 1`) has halved, and the double bump
(`n = 2`) is at `(1/2)^4 = 0.0625`: it fades four times faster. -/
theorem height_at_arch_half_life (κ : ℝ) (hκ : 0 < κ) (n : ℕ) :
    exp (-(κ * n ^ 2 * π ^ 2) * (log 2 / (κ * π ^ 2))) = (1 / 2 : ℝ) ^ (n ^ 2) := by
  have hpi : π ^ 2 ≠ 0 := by positivity
  have h : -(κ * n ^ 2 * π ^ 2) * (log 2 / (κ * π ^ 2)) = ((n ^ 2 : ℕ) : ℝ) * log (1 / 2) := by
    rw [one_div, log_inv]; push_cast; field_simp
  rw [h, exp_nat_mul, exp_log (by norm_num)]

-- The double bump's decay rate is 4 times the arch's: n² goes from 1 to 4.
example : (2 : ℕ) ^ 2 = 4 * 1 ^ 2 := by decide
-- The double bump after one half-life of the arch: (1/2)^4 = 0.0625.
example : (1 / 2 : ℚ) ^ (2 ^ 2) = 625 / 10000 := by norm_num
-- A grid step takes half the old value plus a quarter of each neighbour: the weights sum to 1.
example : (1 / 2 : ℚ) + 1 / 4 + 1 / 4 = 1 := by norm_num
-- The heater's steady peak: 20 / 8 = 2.5.
example : (20 / 8 : ℚ) = 25 / 10 := by norm_num

#print axioms sine_bump_decays_at_rate_kappa_n_sq_pi_sq
#print axioms heat_maximum_principle
#print axioms height_at_arch_half_life
