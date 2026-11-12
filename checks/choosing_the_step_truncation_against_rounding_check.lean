-- Choosing the step: the error law A h^p + B η / h^k has one best step, the (p+k)-th root of kBη/(pA), with error (1 + p/k) A h^p there, and a wiggle of height a and width w moves the slope by 2πa/w.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.MeanValue

/-! A difference formula for the `k`-th derivative with order of accuracy `p` has total error
about `E h = A * h ^ p + B * η / h ^ k` at step `h > 0`: a truncation part `A * h ^ p`
and a rounding part `B * η / h ^ k`, where `η` is the noise in each value of `f`.
The best step `h⋆` is written `hs`; the root is Mathlib's real power `x ^ (1 / (p + k))`. -/

/-- The best step for any difference formula: with `A, B, η > 0` and orders `p, k ≥ 1`,
the error `E h = A h^p + B η / h^k` falls for `0 < h ≤ h⋆` and rises for `h ≥ h⋆`,
where `h⋆ = (k B η / (p A))^(1/(p+k))`, so `h⋆` is its only minimum on `h > 0`.
At `h⋆` the rounding part is `p/k` times the truncation part,
and the total error is `E⋆ = (1 + p/k) A (h⋆)^p`. -/
theorem best_step_minimizes_error_law (A B η : ℝ) (p k : ℕ)
    (hA : 0 < A) (hB : 0 < B) (hη : 0 < η) (hp : 0 < p) (hk : 0 < k) :
    let E : ℝ → ℝ := fun h => A * h ^ p + B * η / h ^ k
    let hs : ℝ := ((k : ℝ) * B * η / ((p : ℝ) * A)) ^ ((1 : ℝ) / ((p : ℝ) + k))
    0 < hs ∧
    hs ^ (p + k) = (k : ℝ) * B * η / ((p : ℝ) * A) ∧
    StrictAntiOn E (Set.Ioc 0 hs) ∧
    StrictMonoOn E (Set.Ici hs) ∧
    (∀ h : ℝ, 0 < h → h ≠ hs → E hs < E h) ∧
    B * η / hs ^ k = ((p : ℝ) / k) * (A * hs ^ p) ∧
    E hs = (1 + (p : ℝ) / k) * A * hs ^ p := by
  intro E hs
  have hpR : (0 : ℝ) < p := by exact_mod_cast hp
  have hkR : (0 : ℝ) < k := by exact_mod_cast hk
  have hc : 0 < (k : ℝ) * B * η / ((p : ℝ) * A) := by positivity
  have hspos : 0 < hs := Real.rpow_pos_of_pos hc _
  have hspow : hs ^ (p + k) = (k : ℝ) * B * η / ((p : ℝ) * A) := by
    have hne : ((p : ℝ) + k) ≠ 0 := by positivity
    rw [← Real.rpow_natCast, ← Real.rpow_mul hc.le]
    push_cast
    rw [one_div_mul_cancel hne, Real.rpow_one]
  have hkey : (p : ℝ) * A * hs ^ (p + k) = k * B * η := by
    rw [hspow]; field_simp
  clear_value hs
  obtain ⟨p', rfl⟩ : ∃ p', p = p' + 1 := ⟨p - 1, by omega⟩
  obtain ⟨k', rfl⟩ : ∃ k', k = k' + 1 := ⟨k - 1, by omega⟩
  -- derivative
  have hd : ∀ h : ℝ, 0 < h → HasDerivAt E
      (A * (((p' + 1 : ℕ) : ℝ) * h ^ p') - B * η * (((k' + 1 : ℕ) : ℝ) * h ^ k') / (h ^ (k' + 1)) ^ 2) h := by
    intro h hh
    have h1 := (hasDerivAt_pow (p' + 1) h).const_mul A
    have h2 := (hasDerivAt_const h (B * η)).div (hasDerivAt_pow (k' + 1) h) (pow_ne_zero _ hh.ne')
    simp only [Nat.add_sub_cancel] at h1 h2
    convert h1.add h2 using 1
    ring
  have hderiv : ∀ h : ℝ, 0 < h → deriv E h =
      (A * (((p' + 1 : ℕ) : ℝ) * h ^ p') - B * η * (((k' + 1 : ℕ) : ℝ) * h ^ k') / (h ^ (k' + 1)) ^ 2) :=
    fun h hh => (hd h hh).deriv
  -- sign of derivative
  have hsign : ∀ h : ℝ, 0 < h →
      (A * (((p' + 1 : ℕ) : ℝ) * h ^ p') - B * η * (((k' + 1 : ℕ) : ℝ) * h ^ k') / (h ^ (k' + 1)) ^ 2)
        = h ^ k' * (((p' + 1 : ℕ) : ℝ) * A * h ^ (p' + 1 + (k' + 1)) - (k' + 1 : ℕ) * B * η)
            / (h ^ (k' + 1)) ^ 2 := by
    intro h hh
    have : h ^ (k' + 1) ≠ 0 := pow_ne_zero _ hh.ne'
    field_simp
    ring
  have hcont : ∀ S : Set ℝ, S ⊆ Set.Ioi 0 → ContinuousOn E S :=
    fun S hS x hx => (hd x (hS hx)).continuousAt.continuousWithinAt
  have hanti : StrictAntiOn E (Set.Ioc 0 hs) := by
    apply strictAntiOn_of_deriv_neg (convex_Ioc 0 hs) (hcont _ Set.Ioc_subset_Ioi_self)
    intro h hh
    rw [interior_Ioc] at hh
    rw [hderiv h hh.1, hsign h hh.1]
    apply div_neg_of_neg_of_pos _ (pow_pos (pow_pos hh.1 _) _)
    apply mul_neg_of_pos_of_neg (pow_pos hh.1 _)
    rw [sub_neg, ← hkey]
    apply mul_lt_mul_of_pos_left _ (by positivity)
    exact pow_lt_pow_left₀ hh.2 hh.1.le (by omega)
  have hmono : StrictMonoOn E (Set.Ici hs) := by
    apply strictMonoOn_of_deriv_pos (convex_Ici hs)
      (hcont _ (fun x hx => lt_of_lt_of_le hspos hx))
    intro h hh
    rw [interior_Ici] at hh
    have h0 : 0 < h := hspos.trans hh
    rw [hderiv h h0, hsign h h0]
    apply div_pos _ (by positivity)
    apply mul_pos (pow_pos h0 _)
    rw [sub_pos, ← hkey]
    apply mul_lt_mul_of_pos_left _ (by positivity)
    exact pow_lt_pow_left₀ hh hspos.le (by omega)
  have hratio : B * η / hs ^ (k' + 1) = (((p' + 1 : ℕ) : ℝ) / ((k' + 1 : ℕ) : ℝ)) * (A * hs ^ (p' + 1)) := by
    have hne : hs ^ (k' + 1) ≠ 0 := pow_ne_zero _ hspos.ne'
    have hkne : ((k' + 1 : ℕ) : ℝ) ≠ 0 := by positivity
    rw [pow_add] at hkey
    field_simp
    linear_combination (-1 : ℝ) * hkey
  refine ⟨hspos, hspow, hanti, hmono, ?_, hratio, ?_⟩
  · intro h hh hne
    rcases lt_or_gt_of_ne hne with hlt | hgt
    · exact hanti ⟨hh, hlt.le⟩ ⟨hspos, le_rfl⟩ hlt
    · exact hmono (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr hgt.le) hgt
  · show A * hs ^ (p' + 1) + B * η / hs ^ (k' + 1) = _
    rw [hratio]; ring

/-- The best step for a second derivative: the central second difference has
`k = 2`, `p = 2`, truncation constant `|f''''| / 12` and noise multiplier `4`,
so with `F = |f''''| > 0` and `η > 0` its error `E h = (F/12) h^2 + 4 η / h^2`
is smallest at `h⋆ = (48 η / F)^(1/4)`, a fourth root of the noise,
and the best error there is `E⋆ = 2 sqrt(η F / 3)`, a square root of the noise. -/
theorem second_difference_best_step (F η : ℝ) (hF : 0 < F) (hη : 0 < η) :
    let E : ℝ → ℝ := fun h => F / 12 * h ^ 2 + 4 * η / h ^ 2
    let hs : ℝ := (48 * η / F) ^ ((1 : ℝ) / 4)
    0 < hs ∧
    (∀ h : ℝ, 0 < h → E hs ≤ E h) ∧
    E hs = 2 * Real.sqrt (η * F / 3) := by
  intro E hs
  have hc : 0 < 48 * η / F := by positivity
  have hspos : 0 < hs := Real.rpow_pos_of_pos hc _
  have h4 : hs ^ 4 = 48 * η / F := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul hc.le]
    norm_num
  clear_value hs
  have h4' : 4 * η = F * hs ^ 4 / 12 := by
    rw [h4]; field_simp; ring
  refine ⟨hspos, ?_, ?_⟩
  · intro h hh
    have key : E h - E hs = F / 12 * (h ^ 2 - hs ^ 2) ^ 2 / h ^ 2 := by
      show F / 12 * h ^ 2 + 4 * η / h ^ 2 - (F / 12 * hs ^ 2 + 4 * η / hs ^ 2) = _
      rw [h4']
      field_simp
      ring
    have : 0 ≤ E h - E hs := by rw [key]; positivity
    linarith
  · show F / 12 * hs ^ 2 + 4 * η / hs ^ 2 = _
    have hsq : η * F / 3 = (F * hs ^ 2 / 12) ^ 2 := by
      have : η = F * hs ^ 4 / 48 := by linarith
      rw [this]; ring
    rw [hsq, Real.sqrt_sq (by positivity), h4']
    field_simp
    ring

/-- Differentiation is ill-posed: add a wiggle `a sin(2π (y - x) / w)` of height `a > 0`
and width `w > 0` to a function `f` with slope `f'` at `x`.
Every value moves by at most `a`, yet the slope at `x` moves by exactly `2π a / w`,
which grows without limit as `w` shrinks. -/
theorem wiggle_moves_slope (f : ℝ → ℝ) (f' x a w : ℝ) (ha : 0 < a) (hw : 0 < w)
    (hf : HasDerivAt f f' x) :
    let g : ℝ → ℝ := fun y => f y + a * Real.sin (2 * Real.pi * (y - x) / w)
    (∀ y : ℝ, |g y - f y| ≤ a) ∧
    HasDerivAt g (f' + 2 * Real.pi * a / w) x := by
  intro g
  refine ⟨fun y => ?_, ?_⟩
  · show |f y + a * Real.sin (2 * Real.pi * (y - x) / w) - f y| ≤ a
    rw [add_sub_cancel_left, abs_mul, abs_of_pos ha]
    exact mul_le_of_le_one_right ha.le (Real.abs_sin_le_one _)
  · have h1 : HasDerivAt (fun y => 2 * Real.pi * (y - x) / w) (2 * Real.pi * 1 / w) x :=
      (((hasDerivAt_id x).sub_const x).const_mul (2 * Real.pi)).div_const w
    have h2 := (h1.sin.const_mul a)
    have h3 := hf.add h2
    convert h3 using 1
    simp
    ring

/-! The table's exponents and constants, checked exactly. -/

-- The best error falls like `η ^ (p / (p + k))`: 1/2 forward, 2/3 central, 1/2 second.
example : ((1 : ℚ) / (1 + 1), (2 : ℚ) / (2 + 1), (2 : ℚ) / (2 + 2)) = (1 / 2, 2 / 3, 1 / 2) := by
  norm_num

-- Second difference: `k B / (p A)` with `B = 4`, `A = F / 12` gives `48 / F`.
example : (2 : ℚ) * 4 / (2 * (1 / 12)) = 48 := by norm_num

#print axioms best_step_minimizes_error_law
#print axioms second_difference_best_step
#print axioms wiggle_moves_slope
