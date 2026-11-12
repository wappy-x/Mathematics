-- Linear interpolation: between two readings the straight line misses a curve whose bend is at most M by at most M h^2 / 8, and past the last reading no such cap exists.
import Mathlib.Analysis.Calculus.LocalExtr.Rolle
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic.NormNum

/-! Readings `ya = f a` and `yb = f b` are taken at times `a < b`, with spacing `h = b - a`.
The time `t` sits a fraction `s = (t - a) / (b - a)` of the way along, and the line through
the two readings reads `L(t) = (1 - s) * ya + s * yb`. The curve's bend is its second derivative
`deriv (deriv f)`, and `M` is a ceiling on its size. -/

/-- The line through `(a, ya)` and `(b, yb)`, read at `t`, in the card's weights form. -/
noncomputable def linInterp (a b ya yb t : ℝ) : ℝ :=
  (1 - (t - a) / (b - a)) * ya + (t - a) / (b - a) * yb

/-- Two applications of Rolle's theorem: a function with three zeros `p < q < r` has a point
strictly between `p` and `r` where its second derivative vanishes. -/
theorem linInterp_aux_rolle_twice (g : ℝ → ℝ) (p q r : ℝ) (hpq : p < q) (hqr : q < r)
    (hgc : ContinuousOn g (Set.Icc p r))
    (hg' : DifferentiableOn ℝ (deriv g) (Set.Ioo p r))
    (hp : g p = 0) (hq : g q = 0) (hr : g r = 0) :
    ∃ ξ ∈ Set.Ioo p r, deriv (deriv g) ξ = 0 := by
  obtain ⟨c1, hc1, hc1'⟩ := exists_deriv_eq_zero hpq
    (hgc.mono (Set.Icc_subset_Icc le_rfl hqr.le)) (hp.trans hq.symm)
  obtain ⟨c2, hc2, hc2'⟩ := exists_deriv_eq_zero hqr
    (hgc.mono (Set.Icc_subset_Icc hpq.le le_rfl)) (hq.trans hr.symm)
  have h12 : c1 < c2 := hc1.2.trans hc2.1
  have hsub : Set.Icc c1 c2 ⊆ Set.Ioo p r := fun x hx =>
    ⟨hc1.1.trans_le hx.1, hx.2.trans_lt hc2.2⟩
  obtain ⟨ξ, hξ, hξ'⟩ := exists_deriv_eq_zero h12 (hg'.continuousOn.mono hsub)
    (hc1'.trans hc2'.symm)
  exact ⟨ξ, hsub (Set.Ioo_subset_Icc_self hξ), hξ'⟩

/-- The line through the readings, in slope form. -/
theorem linInterp_eq_slope (a b ya yb x : ℝ) :
    linInterp a b ya yb x = ya + (yb - ya) / (b - a) * (x - a) := by
  unfold linInterp; ring

/-- The line plus a multiple of `(x - a)(x - b)` has an explicit derivative. -/
theorem linInterp_aux_hasDerivAt (a b ya yb K x : ℝ) :
    HasDerivAt (fun y => linInterp a b ya yb y + K * ((y - a) * (y - b)))
      ((yb - ya) / (b - a) + K * ((x - b) + (x - a))) x := by
  have h1 : HasDerivAt (fun y : ℝ => y - a) 1 x := (hasDerivAt_id' x).sub_const a
  have h2 : HasDerivAt (fun y : ℝ => y - b) 1 x := (hasDerivAt_id' x).sub_const b
  have h := ((h1.const_mul ((yb - ya) / (b - a))).const_add ya).add ((h1.mul h2).const_mul K)
  simp only [linInterp_eq_slope]
  convert h using 1; ring

/-- The derivative of that explicit derivative is `2K`. -/
theorem linInterp_aux_hasDerivAt2 (a b ya yb K x : ℝ) :
    HasDerivAt (fun y => (yb - ya) / (b - a) + K * ((y - b) + (y - a))) (2 * K) x := by
  have h1 : HasDerivAt (fun y : ℝ => y - a) 1 x := (hasDerivAt_id' x).sub_const a
  have h2 : HasDerivAt (fun y : ℝ => y - b) 1 x := (hasDerivAt_id' x).sub_const b
  have h := ((h2.add h1).const_mul K).const_add ((yb - ya) / (b - a))
  convert h using 1; ring

#print axioms linInterp_aux_rolle_twice
#print axioms linInterp_eq_slope
#print axioms linInterp_aux_hasDerivAt
#print axioms linInterp_aux_hasDerivAt2

/-- The error formula (proved here so both theorems below can use it). -/
theorem linInterp_aux_error_formula (f : ℝ → ℝ) (a b t : ℝ) (hab : a < b)
    (hfc : ContinuousOn f (Set.Icc (min a t) (max b t)))
    (hf : DifferentiableOn ℝ f (Set.Ioo (min a t) (max b t)))
    (hf' : DifferentiableOn ℝ (deriv f) (Set.Ioo (min a t) (max b t))) :
    ∃ ξ ∈ Set.Ioo (min a t) (max b t),
      f t - linInterp a b (f a) (f b) t = 1 / 2 * deriv (deriv f) ξ * ((t - a) * (t - b)) := by
  set L := linInterp a b (f a) (f b) t with hL
  have hba : b - a ≠ 0 := sub_ne_zero.mpr hab.ne'
  -- Points where the formula holds trivially: t = a or t = b.
  by_cases hta : t = a
  · subst hta
    refine ⟨(min t t + max b t) / 2, ?_, ?_⟩
    · have : min t t < max b t := (min_le_left t t).trans_lt (hab.trans_le (le_max_left b t))
      constructor <;> linarith
    · simp [hL, linInterp]
  by_cases htb : t = b
  · subst htb
    refine ⟨(min a t + max t t) / 2, ?_, ?_⟩
    · have : min a t < max t t := (min_le_left a t).trans_lt (hab.trans_le (le_max_left t t))
      constructor <;> linarith
    · simp only [hL, linInterp, sub_self, mul_zero, div_self hba]; ring
  have hprod : (t - a) * (t - b) ≠ 0 :=
    mul_ne_zero (sub_ne_zero.mpr hta) (sub_ne_zero.mpr htb)
  set K := (f t - L) / ((t - a) * (t - b)) with hK
  set φ : ℝ → ℝ := fun y => linInterp a b (f a) (f b) y + K * ((y - a) * (y - b)) with hφ
  set g : ℝ → ℝ := fun y => f y - φ y with hg
  set lo := min a t
  set hi := max b t
  have hφd : ∀ x, HasDerivAt φ ((f b - f a) / (b - a) + K * ((x - b) + (x - a))) x :=
    fun x => linInterp_aux_hasDerivAt a b (f a) (f b) K x
  -- derivative of g on the open interval
  have hdg : ∀ x ∈ Set.Ioo lo hi,
      deriv g x = deriv f x - ((f b - f a) / (b - a) + K * ((x - b) + (x - a))) := by
    intro x hx
    have hfx : DifferentiableAt ℝ f x := (hf x hx).differentiableAt (Ioo_mem_nhds hx.1 hx.2)
    exact (hfx.hasDerivAt.sub (hφd x)).deriv
  have hdg_ev : ∀ x ∈ Set.Ioo lo hi, deriv g =ᶠ[nhds x]
      fun y => deriv f y - ((f b - f a) / (b - a) + K * ((y - b) + (y - a))) := by
    intro x hx
    filter_upwards [Ioo_mem_nhds hx.1 hx.2] with y hy using hdg y hy
  have hg'd : DifferentiableOn ℝ (deriv g) (Set.Ioo lo hi) := by
    intro x hx
    have hfx : DifferentiableAt ℝ (deriv f) x :=
      (hf' x hx).differentiableAt (Ioo_mem_nhds hx.1 hx.2)
    have : DifferentiableAt ℝ
        (fun y => deriv f y - ((f b - f a) / (b - a) + K * ((y - b) + (y - a)))) x :=
      hfx.sub (linInterp_aux_hasDerivAt2 a b (f a) (f b) K x).differentiableAt
    exact ((hdg_ev x hx).differentiableAt_iff.mpr this).differentiableWithinAt
  have hd2g : ∀ x ∈ Set.Ioo lo hi, deriv (deriv g) x = deriv (deriv f) x - 2 * K := by
    intro x hx
    have hfx : DifferentiableAt ℝ (deriv f) x :=
      (hf' x hx).differentiableAt (Ioo_mem_nhds hx.1 hx.2)
    rw [(hdg_ev x hx).deriv_eq]
    exact (hfx.hasDerivAt.sub (linInterp_aux_hasDerivAt2 a b (f a) (f b) K x)).deriv
  have hgc : ContinuousOn g (Set.Icc lo hi) := by
    refine hfc.sub ?_
    exact fun x _ => (hφd x).continuousAt.continuousWithinAt
  have hga : g a = 0 := by simp [hg, hφ, linInterp]
  have hgb : g b = 0 := by
    simp only [hg, hφ, linInterp, sub_self, mul_zero, zero_mul, div_self hba]; ring
  have hgt : g t = 0 := by
    simp only [hg, hφ]
    rw [← hL, hK, div_mul_cancel₀ _ hprod]; ring
  -- three zeros, sorted by case
  obtain ⟨ξ, hξ, hξ0⟩ : ∃ ξ ∈ Set.Ioo lo hi, deriv (deriv g) ξ = 0 := by
    rcases lt_or_gt_of_ne hta with h1 | h1
    · have e1 : lo = t := min_eq_right h1.le
      have e2 : hi = b := max_eq_left (h1.trans hab).le
      rw [e1, e2] at hgc hg'd ⊢
      exact linInterp_aux_rolle_twice g t a b h1 hab hgc hg'd hgt hga hgb
    · have e1 : lo = a := min_eq_left h1.le
      rcases lt_or_gt_of_ne htb with h2 | h2
      · have e2 : hi = b := max_eq_left h2.le
        rw [e1, e2] at hgc hg'd ⊢
        exact linInterp_aux_rolle_twice g a t b h1 h2 hgc hg'd hga hgt hgb
      · have e2 : hi = t := max_eq_right h2.le
        rw [e1, e2] at hgc hg'd ⊢
        exact linInterp_aux_rolle_twice g a b t hab h2 hgc hg'd hga hgb hgt
  refine ⟨ξ, hξ, ?_⟩
  rw [hd2g ξ hξ] at hξ0
  have hKv : K = 1 / 2 * deriv (deriv f) ξ := by linarith
  have : f t - L = K * ((t - a) * (t - b)) := by
    rw [hK, div_mul_cancel₀ _ hprod]
  rw [this, hKv]

#print axioms linInterp_aux_error_formula


/-- Between two readings the line misses the curve by at most `M h² / 8`: if the curve is
continuous on `[a, b]`, has a bend (a second derivative) between the readings, and that bend is
at most `M` in size there, then for every `t` between the readings
`|f t - L t| ≤ M (b - a)² / 8`. -/
theorem linear_interpolation_error_le (f : ℝ → ℝ) (a b M t : ℝ) (hab : a < b)
    (hfc : ContinuousOn f (Set.Icc a b))
    (hf : DifferentiableOn ℝ f (Set.Ioo a b))
    (hf' : DifferentiableOn ℝ (deriv f) (Set.Ioo a b))
    (hM : ∀ x ∈ Set.Ioo a b, |deriv (deriv f) x| ≤ M)
    (ht : t ∈ Set.Icc a b) :
    |f t - linInterp a b (f a) (f b) t| ≤ M * (b - a) ^ 2 / 8 := by
  have hmin : min a t = a := min_eq_left ht.1
  have hmax : max b t = b := max_eq_left ht.2
  have hfc' : ContinuousOn f (Set.Icc (min a t) (max b t)) := by rwa [hmin, hmax]
  have hf1 : DifferentiableOn ℝ f (Set.Ioo (min a t) (max b t)) := by rwa [hmin, hmax]
  have hf2 : DifferentiableOn ℝ (deriv f) (Set.Ioo (min a t) (max b t)) := by rwa [hmin, hmax]
  obtain ⟨ξ, hξ, heq⟩ := linInterp_aux_error_formula f a b t hab hfc' hf1 hf2
  rw [hmin, hmax] at hξ
  have hMξ := hM ξ hξ
  have hM0 : 0 ≤ M := (abs_nonneg _).trans hMξ
  rw [heq, abs_mul, abs_mul]
  have hp : |(t - a) * (t - b)| = (t - a) * (b - t) := by
    rw [abs_of_nonpos (mul_nonpos_of_nonneg_of_nonpos (by linarith [ht.1]) (by linarith [ht.2]))]
    ring
  rw [hp]
  have h4 : (t - a) * (b - t) ≤ (b - a) ^ 2 / 4 := by nlinarith [sq_nonneg (2 * t - a - b)]
  have h0 : 0 ≤ (t - a) * (b - t) := mul_nonneg (by linarith [ht.1]) (by linarith [ht.2])
  rw [show |(1 / 2 : ℝ)| = 1 / 2 by norm_num]
  calc 1 / 2 * |deriv (deriv f) ξ| * ((t - a) * (b - t))
      ≤ 1 / 2 * M * ((t - a) * (b - t)) := by gcongr
    _ ≤ 1 / 2 * M * ((b - a) ^ 2 / 4) := by gcongr
    _ = M * (b - a) ^ 2 / 8 := by ring

/-- The error formula, inside or outside the readings: for any time `t`, if the curve is
twice differentiable across the span of `a`, `b` and `t`, the line misses it by exactly
`½ f''(ξ) (t - a)(t - b)` for some `ξ` strictly between the smallest and largest of the three. -/
theorem linear_interpolation_error_formula (f : ℝ → ℝ) (a b t : ℝ) (hab : a < b)
    (hfc : ContinuousOn f (Set.Icc (min a t) (max b t)))
    (hf : DifferentiableOn ℝ f (Set.Ioo (min a t) (max b t)))
    (hf' : DifferentiableOn ℝ (deriv f) (Set.Ioo (min a t) (max b t))) :
    ∃ ξ ∈ Set.Ioo (min a t) (max b t),
      f t - linInterp a b (f a) (f b) t = 1 / 2 * deriv (deriv f) ξ * ((t - a) * (t - b)) := by
  exact linInterp_aux_error_formula f a b t hab hfc hf hf'

/-- Past the last reading the same ceiling caps nothing: for any ceiling `M > 0` on the bend,
however large a size `C` you name, some time `t` past `b` and some curve whose bend is at most `M`
everywhere make the line through the readings at `a` and `b` miss by more than `C`. -/
theorem extrapolation_error_has_no_cap (a b M C : ℝ) (hab : a < b) (hM : 0 < M) :
    ∃ t, b < t ∧ ∃ f : ℝ → ℝ, Differentiable ℝ f ∧ Differentiable ℝ (deriv f) ∧
      (∀ x, |deriv (deriv f) x| ≤ M) ∧ C < |f t - linInterp a b (f a) (f b) t| := by
  set f : ℝ → ℝ := fun x => M / 2 * ((x - a) * (x - b)) with hfdef
  have hd1 : ∀ x, HasDerivAt f (M / 2 * ((x - b) + (x - a))) x := by
    intro x
    have h1 : HasDerivAt (fun y : ℝ => y - a) 1 x := (hasDerivAt_id' x).sub_const a
    have h2 : HasDerivAt (fun y : ℝ => y - b) 1 x := (hasDerivAt_id' x).sub_const b
    convert (h1.mul h2).const_mul (M / 2) using 1; ring
  have hdf : deriv f = fun x => M / 2 * ((x - b) + (x - a)) := funext fun x => (hd1 x).deriv
  have hd2 : ∀ x, HasDerivAt (fun x => M / 2 * ((x - b) + (x - a))) M x := by
    intro x
    have h1 : HasDerivAt (fun y : ℝ => y - a) 1 x := (hasDerivAt_id' x).sub_const a
    have h2 : HasDerivAt (fun y : ℝ => y - b) 1 x := (hasDerivAt_id' x).sub_const b
    convert (h2.add h1).const_mul (M / 2) using 1; ring
  have hddf : deriv (deriv f) = fun _ => M := by
    rw [hdf]; exact funext fun x => (hd2 x).deriv
  set d : ℝ := 1 + 2 * |C| / M with hd
  have hd1' : 1 ≤ d := by
    have : 0 ≤ 2 * |C| / M := div_nonneg (by positivity) hM.le
    linarith
  refine ⟨b + d, by linarith, f, fun x => (hd1 x).differentiableAt, ?_, ?_, ?_⟩
  · rw [hdf]; exact fun x => (hd2 x).differentiableAt
  · intro x; rw [hddf, abs_of_pos hM]
  · have hfa : f a = 0 := by simp [hfdef]
    have hfb : f b = 0 := by simp [hfdef]
    rw [hfa, hfb]
    have hL0 : linInterp a b 0 0 (b + d) = 0 := by simp [linInterp]
    rw [hL0, sub_zero]
    simp only [hfdef]
    have hpos : 0 ≤ M / 2 * ((b + d - a) * (b + d - b)) := by
      apply mul_nonneg (by linarith) (mul_nonneg (by linarith) (by linarith))
    rw [abs_of_nonneg hpos]
    have hMd : M * d = M + 2 * |C| := by
      rw [hd, mul_add, mul_one, mul_div_cancel₀ _ hM.ne']
    have hC := le_abs_self C
    have h1 : d ≤ (b + d - a) := by linarith
    have h2 : M / 2 * ((b + d - a) * (b + d - b)) ≥ M / 2 * (d * d) := by
      have : b + d - b = d := by ring
      rw [this]
      gcongr
    have h3 : d ≤ d * d := by nlinarith
    have h4 : M / 2 * (d * d) ≥ M / 2 * d := by gcongr
    nlinarith

/-! The card's exact worked numbers. Tide heights are in tenths of a millimetre,
yields in basis points (hundredths of a percent). -/

-- 9:20 am is a third of the way from 9 to 10: weights 2/3 and 1/3.
example : ((28 / 3 : ℝ) - 9) / (10 - 9) = 1 / 3 := by norm_num
-- The weights form and the slope form give the same line at 9:20 (2.5956 m and 1.7126 m).
example : linInterp 9 10 25956 17126 (28 / 3) = 25956 + 1 / 3 * (17126 - 25956) := by
  norm_num [linInterp]
-- Inside, the factor (t - a)(b - t) at 9:20 is 2/9, under its ceiling h²/4 = 1/4.
example : ((28 / 3 : ℝ) - 9) * (10 - 28 / 3) = 2 / 9 ∧ (2 / 9 : ℝ) ≤ 1 / 4 := by norm_num
-- At 1 pm the factor (t - 9)(t - 10) is 12.
example : ((13 : ℝ) - 9) * (13 - 10) = 12 := by norm_num
-- At 1 pm the weights are -3 and 4, so reading errors of δ move the line by up to 7 δ.
example : 1 - ((13 : ℝ) - 9) / (10 - 9) = -3 ∧ ((13 : ℝ) - 9) / (10 - 9) = 4 ∧
    |(-3 : ℝ)| + |(4 : ℝ)| = 7 := by norm_num
-- Yield curve: 3.925% at 4 years (between 3.90% and 3.95%), 4.400% at 15 years.
example : linInterp 3 5 390 395 4 = 785 / 2 := by norm_num [linInterp]
example : linInterp 10 20 420 460 15 = 440 := by norm_num [linInterp]
-- The 20-to-30-year line (4.60% to 4.40%) extended to 50 years reads 4.000%.
example : linInterp 20 30 460 440 50 = 400 := by norm_num [linInterp]

#print axioms linear_interpolation_error_le
#print axioms linear_interpolation_error_formula
#print axioms extrapolation_error_has_no_cap
