-- Bifurcations: a resting state where the rate's slope is not zero survives a small turn of the dial, unique and with the same stability; the fishery x' = x(1 - x) - h has two rests below catch 1/4, one at 1/4 and none above; and past the fold no stock lasts pi / sqrt(h - 1/4) years.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Basic.Sign.Basic
import Mathlib

open Real

/-- Helper: the positive-slope case of `rest_persists_of_slope_ne_zero`. -/
theorem rest_persists_pos_aux (f f' : ℝ → ℝ → ℝ) (x₀ h₀ : ℝ)
    (hf : Continuous (fun p : ℝ × ℝ => f p.1 p.2))
    (hderiv : ∀ x h, HasDerivAt (fun y => f y h) (f' x h) x)
    (hf' : Continuous (fun p : ℝ × ℝ => f' p.1 p.2))
    (hrest : f x₀ h₀ = 0) (hslope : 0 < f' x₀ h₀) :
    ∃ ε > 0, ∃ δ > 0, ∀ h, |h - h₀| < δ →
      (∃! x, |x - x₀| < ε ∧ f x h = 0) ∧ (∀ x, |x - x₀| < ε → 0 < f' x h) := by
  have hev : ∀ᶠ p in nhds (x₀, h₀), 0 < f' p.1 p.2 :=
    hf'.continuousAt.eventually (lt_mem_nhds hslope)
  obtain ⟨ρ, hρ, hball⟩ := Metric.eventually_nhds_iff.mp hev
  have hbox : ∀ x h, |x - x₀| < ρ → |h - h₀| < ρ → 0 < f' x h := by
    intro x h hx hh
    have := @hball (x, h) (by
      rw [Prod.dist_eq, max_lt_iff, Real.dist_eq, Real.dist_eq]; exact ⟨hx, hh⟩)
    exact this
  have hmono : ∀ h, |h - h₀| < ρ → StrictMonoOn (fun y => f y h) (Set.Ioo (x₀ - ρ) (x₀ + ρ)) := by
    intro h hh
    apply strictMonoOn_of_deriv_pos (convex_Ioo _ _)
    · intro y _
      exact (hderiv y h).continuousAt.continuousWithinAt
    · intro y hy
      rw [interior_Ioo] at hy
      rw [(hderiv y h).deriv]
      apply hbox y h _ hh
      rw [abs_lt]; constructor <;> linarith [hy.1, hy.2]
  set a := x₀ - ρ / 2
  set b := x₀ + ρ / 2
  have ha_mem : a ∈ Set.Ioo (x₀ - ρ) (x₀ + ρ) := ⟨by simp [a]; linarith, by simp [a]; linarith⟩
  have hb_mem : b ∈ Set.Ioo (x₀ - ρ) (x₀ + ρ) := ⟨by simp [b]; linarith, by simp [b]; linarith⟩
  have h0_mem : x₀ ∈ Set.Ioo (x₀ - ρ) (x₀ + ρ) := ⟨by linarith, by linarith⟩
  have hρ0 : |h₀ - h₀| < ρ := by simpa using hρ
  have hfa : f a h₀ < 0 := by
    have := hmono h₀ hρ0 ha_mem h0_mem (by simp [a]; linarith)
    simpa [hrest] using this
  have hfb : 0 < f b h₀ := by
    have := hmono h₀ hρ0 h0_mem hb_mem (by simp [b]; linarith)
    simpa [hrest] using this
  have hca : Continuous (fun h => f a h) := hf.comp (Continuous.prodMk continuous_const continuous_id)
  have hcb : Continuous (fun h => f b h) := hf.comp (Continuous.prodMk continuous_const continuous_id)
  obtain ⟨δ₁, hδ₁, h1⟩ := Metric.eventually_nhds_iff.mp
    (hca.continuousAt.eventually (gt_mem_nhds hfa) : ∀ᶠ h in nhds h₀, f a h < 0)
  obtain ⟨δ₂, hδ₂, h2⟩ := Metric.eventually_nhds_iff.mp
    (hcb.continuousAt.eventually (lt_mem_nhds hfb) : ∀ᶠ h in nhds h₀, 0 < f b h)
  refine ⟨ρ, hρ, min ρ (min δ₁ δ₂), lt_min hρ (lt_min hδ₁ hδ₂), ?_⟩
  intro h hh
  have hhρ : |h - h₀| < ρ := lt_of_lt_of_le hh (min_le_left _ _)
  have hh1 : f a h < 0 := h1 (by rw [Real.dist_eq]; exact lt_of_lt_of_le hh (le_trans (min_le_right _ _) (min_le_left _ _)))
  have hh2 : 0 < f b h := h2 (by rw [Real.dist_eq]; exact lt_of_lt_of_le hh (le_trans (min_le_right _ _) (min_le_right _ _)))
  refine ⟨?_, fun x hx => hbox x h hx hhρ⟩
  have hcont : ContinuousOn (fun y => f y h) (Set.Icc a b) :=
    fun y _ => (hderiv y h).continuousAt.continuousWithinAt
  have hab : a ≤ b := by simp [a, b]; linarith
  obtain ⟨c, hc, hfc⟩ := intermediate_value_Icc hab hcont ⟨hh1.le, hh2.le⟩
  have hcρ : |c - x₀| < ρ := by
    have hc1 : x₀ - ρ / 2 ≤ c := hc.1
    have hc2 : c ≤ x₀ + ρ / 2 := hc.2
    rw [abs_lt]; constructor <;> linarith
  refine ⟨c, ⟨hcρ, hfc⟩, ?_⟩
  rintro y ⟨hy, hfy⟩
  have hymem : y ∈ Set.Ioo (x₀ - ρ) (x₀ + ρ) := by
    rw [abs_lt] at hy; exact ⟨by linarith [hy.1], by linarith [hy.2]⟩
  have hcmem : c ∈ Set.Ioo (x₀ - ρ) (x₀ + ρ) := by
    rw [abs_lt] at hcρ; exact ⟨by linarith [hcρ.1], by linarith [hcρ.2]⟩
  exact (hmono h hhρ).injOn hymem hcmem (hfy.trans hfc.symm)

#print axioms rest_persists_pos_aux

/-- Step 0, a rest with a nonzero slope cannot vanish. Take a one-variable rate law
`x' = f x h` that ignores the clock, with dial `h`. Suppose the rate is continuous in the stock
and the dial together, its slope in the stock `f' x h` exists everywhere and is continuous in
both, and `x₀` is a rest at dial `h₀` with nonzero slope. Then there is a box around the point:
for every dial value close enough to `h₀` there is exactly one rest near `x₀`, and throughout
the box the slope keeps the sign it had at `x₀` (so the rest keeps its stability). Rests can
meet, split or trade stability only where the slope is zero. -/
theorem rest_persists_of_slope_ne_zero (f f' : ℝ → ℝ → ℝ) (x₀ h₀ : ℝ)
    (hf : Continuous (fun p : ℝ × ℝ => f p.1 p.2))
    (hderiv : ∀ x h, HasDerivAt (fun y => f y h) (f' x h) x)
    (hf' : Continuous (fun p : ℝ × ℝ => f' p.1 p.2))
    (hrest : f x₀ h₀ = 0) (hslope : f' x₀ h₀ ≠ 0) :
    ∃ ε > 0, ∃ δ > 0, ∀ h, |h - h₀| < δ →
      (∃! x, |x - x₀| < ε ∧ f x h = 0) ∧
      (∀ x, |x - x₀| < ε → SignType.sign (f' x h) = SignType.sign (f' x₀ h₀)) := by
  rcases lt_or_gt_of_ne hslope with hneg | hpos
  · obtain ⟨ε, hε, δ, hδ, H⟩ := rest_persists_pos_aux (fun x h => -f x h) (fun x h => -f' x h)
      x₀ h₀ hf.neg (fun x h => (hderiv x h).neg) hf'.neg (by simp [hrest]) (by linarith)
    refine ⟨ε, hε, δ, hδ, fun h hh => ⟨?_, fun x hx => ?_⟩⟩
    · obtain ⟨c, ⟨hc1, hc2⟩, hcu⟩ := (H h hh).1
      refine ⟨c, ⟨hc1, by simpa using hc2⟩, fun y ⟨hy1, hy2⟩ => hcu y ⟨hy1, by simp [hy2]⟩⟩
    · have := (H h hh).2 x hx
      rw [sign_neg (by linarith), sign_neg hneg]
  · obtain ⟨ε, hε, δ, hδ, H⟩ := rest_persists_pos_aux f f' x₀ h₀ hf hderiv hf' hrest hpos
    refine ⟨ε, hε, δ, hδ, fun h hh => ⟨(H h hh).1, fun x hx => ?_⟩⟩
    rw [sign_pos ((H h hh).2 x hx), sign_pos hpos]

/-- Steps 1 and 2, the fishery's fold. For the fixed-catch law `x' = x(1 - x) - h`:
below catch 1/4 there are exactly two rests, `1/2 ± sqrt(1/4 - h)`, the upper one with
negative slope `1 - 2x` (stable) and the lower one with positive slope (unstable);
at catch 1/4 the only rest is half capacity; above 1/4 there is no rest at all. -/
theorem fishery_fold (h : ℝ) :
    (h < 1 / 4 →
      {x : ℝ | x * (1 - x) - h = 0} = {1 / 2 - √(1 / 4 - h), 1 / 2 + √(1 / 4 - h)} ∧
      1 / 2 - √(1 / 4 - h) ≠ 1 / 2 + √(1 / 4 - h) ∧
      1 - 2 * (1 / 2 + √(1 / 4 - h)) < 0 ∧ 0 < 1 - 2 * (1 / 2 - √(1 / 4 - h))) ∧
    (h = 1 / 4 → {x : ℝ | x * (1 - x) - h = 0} = {1 / 2}) ∧
    (1 / 4 < h → {x : ℝ | x * (1 - x) - h = 0} = ∅) := by
  refine ⟨fun hh => ?_, fun hh => ?_, fun hh => ?_⟩
  · have hpos : 0 < √(1 / 4 - h) := Real.sqrt_pos.mpr (by linarith)
    have hsq : √(1 / 4 - h) ^ 2 = 1 / 4 - h := Real.sq_sqrt (by linarith)
    refine ⟨?_, by intro e; linarith, by linarith, by linarith⟩
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
    constructor
    · intro hx
      have : (x - (1 / 2 - √(1 / 4 - h))) * (x - (1 / 2 + √(1 / 4 - h))) = 0 := by
        nlinarith
      rcases mul_eq_zero.mp this with e | e
      · left; linarith
      · right; linarith
    · rintro (e | e) <;> subst e <;> nlinarith
  · subst hh
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff]
    constructor
    · intro hx
      have : (x - 1 / 2) ^ 2 = 0 := by nlinarith
      have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
      linarith
    · rintro rfl; norm_num
  · ext x
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
    intro hx
    nlinarith [sq_nonneg (x - 1 / 2)]

/-- Step 3, past the fold the collapse comes within pi / a years. If the catch `h` is above
1/4 and `a = sqrt(h - 1/4)`, then no stock following `x' = x(1 - x) - h` (continuous on
`[0, T]`, obeying the law inside) lasts as long as `pi / a` years: `T < pi / a`. -/
theorem fishery_collapse_within_pi_div (h T : ℝ) (x : ℝ → ℝ) (hh : 1 / 4 < h)
    (hcont : ContinuousOn x (Set.Icc 0 T))
    (hlaw : ∀ t ∈ Set.Ioo 0 T, HasDerivAt x (x t * (1 - x t) - h) t) :
    T < π / √(h - 1 / 4) := by
  set a := √(h - 1 / 4) with ha_def
  have ha : 0 < a := Real.sqrt_pos.mpr (by linarith)
  have ha2 : a ^ 2 = h - 1 / 4 := Real.sq_sqrt (by linarith)
  have hpia : 0 < π / a := div_pos Real.pi_pos ha
  rcases le_or_gt T 0 with hT | hT
  · linarith
  set φ : ℝ → ℝ := fun t => Real.arctan ((x t - 1 / 2) / a) with hφ
  have hφc : ContinuousOn φ (Set.Icc 0 T) :=
    Real.continuous_arctan.comp_continuousOn ((hcont.sub continuousOn_const).div_const a)
  have hφd : ∀ t ∈ Set.Ioo 0 T, HasDerivAt φ (-a) t := by
    intro t ht
    have h1 := (((hlaw t ht).sub_const (1 / 2)).div_const a).arctan
    convert h1 using 1
    have hne : a ^ 2 + (x t - 1 / 2) ^ 2 ≠ 0 := by positivity
    field_simp
    nlinarith [ha2]
  obtain ⟨c, _, hc⟩ := exists_hasDerivAt_eq_slope φ (fun _ => -a) hT hφc hφd
  have hT' : φ 0 - φ T = a * T := by
    field_simp at hc
    linarith
  have hb1 := Real.arctan_lt_pi_div_two ((x 0 - 1 / 2) / a)
  have hb2 := Real.neg_pi_div_two_lt_arctan ((x T - 1 / 2) / a)
  have : a * T < π := by
    simp only [hφ] at hT'
    linarith
  rw [lt_div_iff₀ ha]
  linarith

-- Completing the square: x(1 - x) - h = (1/4 - h) - (x - 1/2)^2.
example (x h : ℝ) : x * (1 - x) - h = (1 / 4 - h) - (x - 1 / 2) ^ 2 := by ring
-- Catch 0.21: sqrt(0.25 - 0.21) = 0.2, so the rests are 0.3 and 0.7.
example : √((1 : ℝ) / 4 - 21 / 100) = 1 / 5 := by
  rw [show (1 : ℝ) / 4 - 21 / 100 = (1 / 5) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : (3 / 10 : ℚ) * (1 - 3 / 10) - 21 / 100 = 0 ∧ (7 / 10 : ℚ) * (1 - 7 / 10) - 21 / 100 = 0 := by
  norm_num
-- Their slopes 1 - 2x: +0.40 and -0.40.
example : (1 - 2 * (3 / 10) : ℚ) = 2 / 5 ∧ (1 - 2 * (7 / 10) : ℚ) = -2 / 5 := by norm_num
-- Catch 0.24: rests 0.4 and 0.6, slopes +0.20 and -0.20.
example : (2 / 5 : ℚ) * (1 - 2 / 5) - 24 / 100 = 0 ∧ (3 / 5 : ℚ) * (1 - 3 / 5) - 24 / 100 = 0 ∧
    (1 - 2 * (2 / 5) : ℚ) = 1 / 5 ∧ (1 - 2 * (3 / 5) : ℚ) = -1 / 5 := by norm_num
-- Catch 0.25: the fold, a single rest at 0.5.
example : (1 / 2 : ℚ) * (1 - 1 / 2) - 1 / 4 = 0 := by norm_num
-- Catch 0.26: a = sqrt(0.26 - 0.25) = 0.1.
example : √((26 : ℝ) / 100 - 1 / 4) = 1 / 10 := by
  rw [show (26 : ℝ) / 100 - 1 / 4 = (1 / 10) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- The arctangent arguments from 0.7: (0.7 - 0.5)/0.1 = 2 and (0 - 0.5)/0.1 = -5.
example : ((7 / 10 - 1 / 2) / (1 / 10) : ℚ) = 2 ∧ ((0 - 1 / 2) / (1 / 10) : ℚ) = -5 := by norm_num
-- Share rule E = 1/2: rests 0 and 1/2, yield 1/4.
example : (1 / 2 : ℚ) * (1 - 1 / 2 - 1 / 2) = 0 ∧ (1 / 2 : ℚ) * (1 - 1 / 2) = 1 / 4 := by norm_num
-- Pitchfork at mu = 1/4: rests 0 and ±1/2, slope mu - 3u^2 = -1/2 at ±1/2.
example : (1 / 4 : ℚ) * (1 / 2) - (1 / 2) ^ 3 = 0 ∧ (1 / 4 : ℚ) * (-1 / 2) - (-1 / 2) ^ 3 = 0 ∧
    (1 / 4 - 3 * (1 / 2) ^ 2 : ℚ) = -1 / 2 := by norm_num

#print axioms rest_persists_of_slope_ne_zero
#print axioms fishery_fold
#print axioms fishery_collapse_within_pi_div
