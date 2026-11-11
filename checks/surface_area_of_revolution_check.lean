-- Surface area: the frustum bands swept by chords of a non-negative profile with a continuous slope add up, as the bands thin, to the integral of 2π f(x) √(1 + f'(x)^2), and a slice of a ball of radius R and height h has area 2πRh, so the whole ball has 4πR^2.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow

open Set Filter Topology Real

/-- The slant width moves by at most the change in rise: √(h² + A²) ≤ √(h² + B²) + |A − B|. -/
lemma sa_sqrt_le (h A B : ℝ) : √(h ^ 2 + A ^ 2) ≤ √(h ^ 2 + B ^ 2) + |A - B| := by
  have hB : |B| ≤ √(h ^ 2 + B ^ 2) := Real.abs_le_sqrt (by nlinarith)
  have hs := Real.sq_sqrt (show 0 ≤ h ^ 2 + B ^ 2 by positivity)
  have key : h ^ 2 + A ^ 2 ≤ (√(h ^ 2 + B ^ 2) + |A - B|) ^ 2 := by
    have h1 : B * (A - B) ≤ |B| * |A - B| := by rw [← abs_mul]; exact le_abs_self _
    have h2 : |B| * |A - B| ≤ √(h ^ 2 + B ^ 2) * |A - B| :=
      mul_le_mul_of_nonneg_right hB (abs_nonneg _)
    have h3 : |A - B| ^ 2 = (A - B) ^ 2 := sq_abs _
    nlinarith
  calc √(h ^ 2 + A ^ 2) ≤ √((√(h ^ 2 + B ^ 2) + |A - B|) ^ 2) := Real.sqrt_le_sqrt key
    _ = √(h ^ 2 + B ^ 2) + |A - B| := Real.sqrt_sq (by positivity)

/-- One band against its strip of the integral, for short enough steps. -/
lemma sa_band_close (f f' : ℝ → ℝ) (a b : ℝ)
    (hf_deriv : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hf'_cont : ContinuousOn f' (Icc a b)) (ε : ℝ) (hε : 0 < ε) :
    ∃ δ > 0, ∀ u v, u ∈ Icc a b → v ∈ Icc a b → u ≤ v → v - u < δ →
      |π * (f u + f v) * √((v - u) ^ 2 + (f v - f u) ^ 2) -
        ∫ x in u..v, 2 * π * f x * √(1 + f' x ^ 2)| ≤ ε * (v - u) := by
  have hfc : ContinuousOn f (Icc a b) := fun x hx => (hf_deriv x hx).continuousWithinAt
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hfc
  obtain ⟨M', hM'⟩ := isCompact_Icc.exists_bound_of_continuousOn hf'_cont
  have hM0 : ∀ x ∈ Icc a b, |f x| ≤ |M| := fun x hx => (hM x hx).trans (le_abs_self _)
  have hM'0 : ∀ x ∈ Icc a b, |f' x| ≤ |M'| := fun x hx => (hM' x hx).trans (le_abs_self _)
  have hgc : ContinuousOn (fun x => 2 * π * f x * √(1 + f' x ^ 2)) (Icc a b) :=
    (continuousOn_const.mul hfc).mul ((continuousOn_const.add (hf'_cont.pow 2)).sqrt)
  set ρ := ε / (4 * π * (1 + |M'|)) with hρdef
  set η := ε / (4 * π * (|M| + 1)) with hηdef
  have hρ : 0 < ρ := by positivity
  have hη : 0 < η := by positivity
  obtain ⟨δ1, hδ1, hu1⟩ := Metric.uniformContinuousOn_iff.mp
    (isCompact_Icc.uniformContinuousOn_of_continuous hfc) ρ hρ
  obtain ⟨δ2, hδ2, hu2⟩ := Metric.uniformContinuousOn_iff.mp
    (isCompact_Icc.uniformContinuousOn_of_continuous hf'_cont) η hη
  refine ⟨min δ1 δ2, lt_min hδ1 hδ2, ?_⟩
  intro u v hu hv huv hδ
  have hsub : Icc u v ⊆ Icc a b := Icc_subset_Icc hu.1 hv.2
  have hclose : ∀ y ∈ Icc u v, ∀ z ∈ Icc u v, dist z y < min δ1 δ2 := by
    intro y hy z hz
    rw [Real.dist_eq, abs_lt]
    constructor <;> linarith [hy.1, hy.2, hz.1, hz.2]
  have huI : u ∈ Icc u v := ⟨le_rfl, huv⟩
  have hvI : v ∈ Icc u v := ⟨huv, le_rfl⟩
  -- the rise over the step is at most |M'| times the step
  have hrise : |f v - f u| ≤ |M'| * (v - u) := by
    have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := f) (f' := f') (s := Icc u v)
      (C := |M'|) (fun x hx => (hf_deriv x (hsub hx)).mono hsub)
      (fun x hx => hM'0 x (hsub hx)) (convex_Icc u v) huI hvI
    rwa [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 huv)] at this
  have hD : √((v - u) ^ 2 + (f v - f u) ^ 2) ≤ (1 + |M'|) * (v - u) := by
    have := sa_sqrt_le (v - u) (f v - f u) 0
    rw [show (0 : ℝ) ^ 2 = 0 by norm_num, add_zero, Real.sqrt_sq (sub_nonneg.2 huv),
      sub_zero] at this
    linarith
  -- pointwise comparison
  have hpt : ∀ y ∈ Icc u v,
      |π * (f u + f v) * √((v - u) ^ 2 + (f v - f u) ^ 2) -
        (v - u) * (2 * π * f y * √(1 + f' y ^ 2))| ≤ ε * (v - u) := by
    intro y hy
    have hyab := hsub hy
    -- the rise is close to the slope at y times the step
    have hlin : |f v - f u - (v - u) * f' y| ≤ η * (v - u) := by
      have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
        (f := fun z => f z - f' y * z) (f' := fun z => f' z - f' y) (s := Icc u v)
        (C := η) (fun x hx => ((hf_deriv x (hsub hx)).mono hsub).sub
          ((hasDerivWithinAt_id x _).const_mul (f' y) |>.congr_deriv (by simp)))
        (fun z hz => by
          rw [Real.norm_eq_abs, ← Real.dist_eq]
          exact (hu2 z (hsub hz) y hyab (lt_of_lt_of_le (hclose y hy z hz) (min_le_right _ _))).le)
        (convex_Icc u v) huI hvI
      rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 huv)] at this
      convert this using 2; ring
    set D := √((v - u) ^ 2 + (f v - f u) ^ 2) with hDdef
    have hE : √((v - u) ^ 2 + ((v - u) * f' y) ^ 2) = (v - u) * √(1 + f' y ^ 2) := by
      rw [show (v - u) ^ 2 + ((v - u) * f' y) ^ 2 = (v - u) ^ 2 * (1 + f' y ^ 2) by ring,
        Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq (sub_nonneg.2 huv)]
    set E := (v - u) * √(1 + f' y ^ 2) with hEdef
    have hDE : |D - E| ≤ η * (v - u) := by
      rw [abs_sub_le_iff]
      constructor
      · have := sa_sqrt_le (v - u) (f v - f u) ((v - u) * f' y)
        rw [hE] at this; linarith
      · have := sa_sqrt_le (v - u) ((v - u) * f' y) (f v - f u)
        rw [hE, abs_sub_comm] at this; linarith
    have hfu : |f u - f y| ≤ ρ := by
      rw [← Real.dist_eq]
      exact (hu1 u hu y hyab (lt_of_lt_of_le (hclose y hy u huI) (min_le_left _ _))).le
    have hfv : |f v - f y| ≤ ρ := by
      rw [← Real.dist_eq]
      exact (hu1 v hv y hyab (lt_of_lt_of_le (hclose y hy v hvI) (min_le_left _ _))).le
    have hfy : |f y| ≤ |M| := hM0 y hyab
    have hD0 : 0 ≤ D := Real.sqrt_nonneg _
    have hexp : π * (f u + f v) * D - (v - u) * (2 * π * f y * √(1 + f' y ^ 2)) =
        π * ((f u - f y + (f v - f y)) * D + 2 * f y * (D - E)) := by
      rw [hEdef]; ring
    rw [hexp, abs_mul, abs_of_pos Real.pi_pos]
    have hA : |(f u - f y + (f v - f y)) * D| ≤ 2 * ρ * ((1 + |M'|) * (v - u)) := by
      rw [abs_mul, abs_of_nonneg hD0]
      have : |f u - f y + (f v - f y)| ≤ 2 * ρ := (abs_add_le _ _).trans (by linarith)
      exact mul_le_mul this hD hD0 (by positivity)
    have hB : |2 * f y * (D - E)| ≤ 2 * |M| * (η * (v - u)) := by
      rw [abs_mul, abs_mul, abs_two]
      exact mul_le_mul (by linarith) hDE (abs_nonneg _) (by positivity)
    have hsum := (abs_add_le _ _).trans (add_le_add hA hB)
    have hh : 0 ≤ v - u := sub_nonneg.2 huv
    have e1 : π * (2 * ρ * ((1 + |M'|) * (v - u))) = ε / 2 * (v - u) := by
      rw [hρdef]; field_simp; ring
    have e2 : π * (2 * |M| * (η * (v - u))) ≤ ε / 2 * (v - u) := by
      rw [hηdef]
      have : π * (2 * |M| * (ε / (4 * π * (|M| + 1)) * (v - u))) =
          ε / 2 * (v - u) * (|M| / (|M| + 1)) := by field_simp; ring
      rw [this]
      have : |M| / (|M| + 1) ≤ 1 := by
        rw [div_le_one (by positivity)]; linarith
      have : 0 ≤ ε / 2 * (v - u) := by positivity
      nlinarith
    calc π * |(f u - f y + (f v - f y)) * D + 2 * f y * (D - E)|
        ≤ π * (2 * ρ * ((1 + |M'|) * (v - u)) + 2 * |M| * (η * (v - u))) :=
          mul_le_mul_of_nonneg_left hsum Real.pi_pos.le
      _ ≤ ε * (v - u) := by rw [mul_add]; linarith
  -- integrate the pointwise comparison
  rcases eq_or_lt_of_le huv with heq | hlt
  · subst heq; simp
  have hpos : 0 < v - u := sub_pos.2 hlt
  set T := π * (f u + f v) * √((v - u) ^ 2 + (f v - f u) ^ 2) with hT
  have hgi : IntervalIntegrable (fun x => 2 * π * f x * √(1 + f' x ^ 2)) MeasureTheory.volume u v :=
    (hgc.mono hsub).intervalIntegrable_of_Icc huv
  have : T - ∫ x in u..v, 2 * π * f x * √(1 + f' x ^ 2) =
      ∫ x in u..v, (T / (v - u) - 2 * π * f x * √(1 + f' x ^ 2)) := by
    rw [intervalIntegral.integral_sub intervalIntegrable_const hgi, intervalIntegral.integral_const,
      smul_eq_mul]
    field_simp
  rw [this]
  have hb := intervalIntegral.norm_integral_le_of_norm_le_const (a := u) (b := v) (C := ε)
    (f := fun x => T / (v - u) - 2 * π * f x * √(1 + f' x ^ 2)) (fun x hx => by
      rw [uIoc_of_le huv] at hx
      have := hpt x (Ioc_subset_Icc_self hx)
      rw [Real.norm_eq_abs]
      rw [show T / (v - u) - 2 * π * f x * √(1 + f' x ^ 2) =
        (T - (v - u) * (2 * π * f x * √(1 + f' x ^ 2))) / (v - u) by field_simp]
      rw [abs_div, abs_of_pos hpos, div_le_iff₀ hpos]
      exact this)
  rw [Real.norm_eq_abs, abs_of_pos hpos] at hb
  exact hb

/-- **Surface area of revolution.** Spin the profile x ↦ f(x), from height a to height b
(a ≤ b), once round the axis. The radius f(x) is never negative there, and the slope f'(x)
exists at every height of [a, b] (one-sided at the ends, so it is finite there) and has no
jumps. Cut [a, b] into n equal height steps and join the profile's points with chords; each
chord, spun, sweeps a frustum band of area π (r₁ + r₂) ℓ, where r₁, r₂ are its edge radii and
ℓ = √(Δx^2 + (r₂ − r₁)^2) is its slant width. As n grows, the total of the n bands tends to
∫ from a to b of 2π f(x) √(1 + f'(x)^2) dx: each ring is circumference times slant length,
and the slant length is the arc-length element, not the step along the axis. -/
theorem frustum_band_sums_tend_to_surface_area_integral (f f' : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hf_nonneg : ∀ x ∈ Icc a b, 0 ≤ f x)
    (hf_deriv : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hf'_cont : ContinuousOn f' (Icc a b)) :
    Tendsto (fun n : ℕ => ∑ i ∈ Finset.range n,
        π * (f (a + i * (b - a) / n) + f (a + (i + 1) * (b - a) / n)) *
          √(((b - a) / n) ^ 2 + (f (a + (i + 1) * (b - a) / n) - f (a + i * (b - a) / n)) ^ 2))
      atTop (𝓝 (∫ x in a..b, 2 * π * f x * √(1 + f' x ^ 2))) := by
  have hfc : ContinuousOn f (Icc a b) := fun x hx => (hf_deriv x hx).continuousWithinAt
  have hgc : ContinuousOn (fun x => 2 * π * f x * √(1 + f' x ^ 2)) (Icc a b) :=
    (continuousOn_const.mul hfc).mul ((continuousOn_const.add (hf'_cont.pow 2)).sqrt)
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hba : 0 ≤ b - a := sub_nonneg.2 hab
  obtain ⟨δ, hδ, hloc⟩ := sa_band_close f f' a b hf_deriv hf'_cont (ε / (b - a + 1))
    (by positivity)
  obtain ⟨N, hN⟩ := exists_nat_gt ((b - a) / δ)
  refine ⟨N + 1, fun n hn => ?_⟩
  have hnpos : (0 : ℝ) < n := by exact_mod_cast (show 0 < n by omega)
  have hNn : (N : ℝ) < n := by exact_mod_cast (show N < n by omega)
  have hstep : (b - a) / n < δ := by
    rw [div_lt_iff₀ hnpos]
    rw [div_lt_iff₀ hδ] at hN
    nlinarith
  set x : ℕ → ℝ := fun k => a + k * (b - a) / n with hxdef
  have hx_mem : ∀ k ≤ n, x k ∈ Icc a b := by
    intro k hk
    have hk' : (k : ℝ) ≤ n := by exact_mod_cast hk
    have h0 : 0 ≤ (k : ℝ) * (b - a) / n := by positivity
    have h1 : (k : ℝ) * (b - a) / n ≤ b - a := by
      rw [div_le_iff₀ hnpos]; nlinarith
    exact ⟨by simp only [hxdef]; linarith, by simp only [hxdef]; linarith⟩
  have hx0 : x 0 = a := by simp [hxdef]
  have hxn : x n = b := by simp only [hxdef]; field_simp; ring
  have hxs : ∀ k : ℕ, x (k + 1) = a + ((k : ℝ) + 1) * (b - a) / n := by
    intro k; simp only [hxdef]; push_cast; ring
  have hint : (∫ x in a..b, 2 * π * f x * √(1 + f' x ^ 2)) =
      ∑ k ∈ Finset.range n, ∫ y in x k..x (k + 1), 2 * π * f y * √(1 + f' y ^ 2) := by
    rw [intervalIntegral.sum_integral_adjacent_intervals, hx0, hxn]
    intro k hk
    have hmono : x k ≤ x (k + 1) := by
      rw [hxs]; simp only [hxdef]
      have : (0 : ℝ) ≤ (b - a) / n := by positivity
      have e : ((k : ℝ) + 1) * (b - a) / n = (k : ℝ) * (b - a) / n + (b - a) / n := by ring
      rw [e]; linarith
    exact (hgc.mono (Icc_subset_Icc (hx_mem k hk.le).1 (hx_mem (k + 1) hk).2)).intervalIntegrable_of_Icc
      hmono
  rw [Real.dist_eq, hint, ← Finset.sum_sub_distrib]
  have hterm : ∀ k ∈ Finset.range n,
      |π * (f (a + k * (b - a) / n) + f (a + (k + 1) * (b - a) / n)) *
          √(((b - a) / n) ^ 2 + (f (a + (k + 1) * (b - a) / n) - f (a + k * (b - a) / n)) ^ 2) -
        ∫ y in x k..x (k + 1), 2 * π * f y * √(1 + f' y ^ 2)| ≤ ε / (b - a + 1) * ((b - a) / n) := by
    intro k hk
    rw [Finset.mem_range] at hk
    have hu := hx_mem k hk.le
    have hv := hx_mem (k + 1) hk
    rw [hxs] at hv ⊢
    have hvu : a + ((k : ℝ) + 1) * (b - a) / n - (a + k * (b - a) / n) = (b - a) / n := by
      field_simp; ring
    have := hloc _ _ hu hv (by linarith [hvu, show (0 : ℝ) ≤ (b - a) / n by positivity])
      (by rw [hvu]; exact hstep)
    rw [hvu] at this
    exact this
  calc |∑ k ∈ Finset.range n, _| ≤ ∑ k ∈ Finset.range n, |_| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ k ∈ Finset.range n, ε / (b - a + 1) * ((b - a) / n) := Finset.sum_le_sum hterm
    _ = ε / (b - a + 1) * (b - a) := by
      rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]; field_simp
    _ < ε := by
      rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]; nlinarith

/-- **On a ball, radius times slant factor is the ball's radius.** Stand a ball of radius R > 0
on its lowest point; at height x its profile has radius f(x) = √(2Rx − x^2) (for the card's
bowl, R = 4 and f(x) = √(8x − x^2)). At every height strictly between the bottom and the top,
the radius times the slant factor √(1 + f'(x)^2) equals R. -/
theorem ball_radius_times_slant_factor_eq_radius (R x : ℝ) (hR : 0 < R)
    (hx : x ∈ Ioo 0 (2 * R)) :
    √(2 * R * x - x ^ 2) * √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2) = R := by
  obtain ⟨hx0, hx1⟩ := hx
  have hq : 0 < 2 * R * x - x ^ 2 := by nlinarith
  have h1 : HasDerivAt (fun t => 2 * R * t - t ^ 2) (2 * R - 2 * x) x := by
    have := ((hasDerivAt_id' x).const_mul (2 * R)).sub (hasDerivAt_pow 2 x)
    convert this using 1
    norm_num
  rw [(h1.sqrt hq.ne').deriv]
  have hs : 0 < √(2 * R * x - x ^ 2) := Real.sqrt_pos.mpr hq
  have hss : √(2 * R * x - x ^ 2) ^ 2 = 2 * R * x - x ^ 2 := Real.sq_sqrt hq.le
  rw [← Real.sqrt_mul hq.le, div_pow, mul_pow, hss,
    show (2 * R * x - x ^ 2) * (1 + (2 * R - 2 * x) ^ 2 / (2 ^ 2 * (2 * R * x - x ^ 2))) = R ^ 2 by
      field_simp; ring]
  exact Real.sqrt_sq hR.le

/-- **Archimedes: a slice of a ball has the area of the tube round it.** For a ball of radius
R > 0 with profile f(x) = √(2Rx − x^2), the spun area between heights a and b, with
0 ≤ a ≤ b ≤ 2R, is ∫ from a to b of 2π f(x) √(1 + f'(x)^2) dx = 2πR(b − a): the slice's height
times the circumference 2πR. The steep ends cost nothing, so the whole ball, a = 0 and b = 2R,
has area 4πR^2. -/
theorem ball_slice_area_eq_two_pi_R_h (R a b : ℝ) (hR : 0 < R) (ha : 0 ≤ a) (hab : a ≤ b)
    (hb : b ≤ 2 * R) :
    (∫ x in a..b, 2 * π * √(2 * R * x - x ^ 2) *
        √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2)) = 2 * π * R * (b - a) ∧
      (∫ x in (0 : ℝ)..2 * R, 2 * π * √(2 * R * x - x ^ 2) *
        √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2)) = 4 * π * R ^ 2 := by
  have key : ∀ a b : ℝ, a ≤ b → 0 ≤ a → b ≤ 2 * R →
      (∫ x in a..b, 2 * π * √(2 * R * x - x ^ 2) *
        √(1 + deriv (fun t => √(2 * R * t - t ^ 2)) x ^ 2)) = 2 * π * R * (b - a) := by
    intro a b hab ha hb
    rw [intervalIntegral.integral_congr_Ioo_of_le hab (g := fun _ => 2 * π * R)]
    · simp [intervalIntegral.integral_const]; ring
    · intro x hx
      simp only
      rw [mul_assoc, ball_radius_times_slant_factor_eq_radius R x hR
        ⟨by linarith [hx.1], by linarith [hx.2]⟩]
  refine ⟨key a b hab ha hb, ?_⟩
  rw [key 0 (2 * R) (by linarith) le_rfl le_rfl]; ring

/-! The card's exact worked numbers. -/

-- The bowl's radius squared at x = 3: 8 · 3 − 3^2 = 15, so the radius is √15 ≈ 3.872983 cm.
example : 8 * 3 - 3 ^ 2 = 15 := by decide
-- The slope there is (4 − 3)/√15, so the slant factor squared is 1 + 1/15 = 16/15.
example : 1 + (4 - 3 : ℚ) ^ 2 / 15 = 16 / 15 := by norm_num
-- Radius times slant factor, squared: 15 · 16/15 = 16 = 4^2, so the product is 4 cm.
example : (15 : ℚ) * (16 / 15) = 4 ^ 2 := by norm_num
-- Step 4's algebra: f^2 + (4 − x)^2 = 8x − x^2 + 16 − 8x + x^2 = 16 at every height.
example : ∀ x : ℝ, (8 * x - x ^ 2) + (4 - x) ^ 2 = 16 := by intro x; ring
-- The bowl: 2π · 4 · 6 = 48π cm^2 (about 150.796447).
example : 2 * π * 4 * 6 = 48 * π := by ring
-- The whole ball, h = 2R = 8: 2π · 4 · 8 = 64π = 4π · 4^2 cm^2 (about 201.061930).
example : 2 * π * 4 * 8 = 4 * π * 4 ^ 2 := by ring
-- The band from x = 1 to x = 2: radii squared 8 − 1 = 7 and 16 − 4 = 12 (radii 2.6458 and
-- 3.4641 cm); the rim at x = 6 has radius squared 48 − 36 = 12 too (3.464102 cm).
example : 8 * 1 - 1 ^ 2 = 7 ∧ 8 * 2 - 2 ^ 2 = 12 ∧ 8 * 6 - 6 ^ 2 = 12 := by decide
-- That centimetre of bowl truly has 2π · 4 · 1 = 8π cm^2 (about 25.1327).
example : 2 * π * 4 * (2 - 1) = 8 * π := by ring
-- Step 1's algebra: if similar triangles give r₂(L − ℓ) = r₁L, the frustum's area
-- πr₂L − πr₁(L − ℓ) (big cone minus tip) equals π(r₁ + r₂)ℓ.
example : ∀ r₁ r₂ L ℓ : ℝ, r₂ * (L - ℓ) = r₁ * L →
    π * r₂ * L - π * r₁ * (L - ℓ) = π * (r₁ + r₂) * ℓ := by
  intro r₁ r₂ L ℓ h; linear_combination π * h
-- The signed radius x − 3 on [0, 6]: its antiderivative x^2/2 − 3x gives 18 − 18 = 0, so the
-- two cones cancel; each cone's slant squared is 3^2 + 3^2 = 18.
example : ((6 : ℚ) ^ 2 / 2 - 3 * 6) - (0 ^ 2 / 2 - 3 * 0) = 0 ∧ (3 : ℚ) ^ 2 + 3 ^ 2 = 18 := by
  norm_num
-- Silver: 48π cm^2 times 0.002 = 1/500 cm is 12π/125 cm^3 (about 0.301593).
example : 48 * π * (1 / 500) = 12 * π / 125 := by ring

#print axioms sa_sqrt_le
#print axioms sa_band_close
#print axioms frustum_band_sums_tend_to_surface_area_integral
#print axioms ball_radius_times_slant_factor_eq_radius
#print axioms ball_slice_area_eq_two_pi_R_h
