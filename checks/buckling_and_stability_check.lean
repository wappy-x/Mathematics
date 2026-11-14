-- Buckling: a pinned column under end load P can rest in a bent shape only once P reaches Euler's load pi^2 E I / L^2, the n-th bent shape sin(n pi x / L) needs n^2 times that load, and bowing into the first shape changes the stored energy by (pi^2 a^2 / 4L)(pi^2 E I / L^2 - P).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Order.Bounds.Basic

open Real Set

lemma sin_mode_deriv (a c : ℝ) :
    deriv (fun x => a * Real.sin (c * x)) = fun x => a * c * Real.cos (c * x) := by
  funext x
  have h := (((hasDerivAt_id x).const_mul c).sin).const_mul a
  simp only [id] at h; rw [h.deriv]; ring

lemma sin_mode_deriv2 (a c : ℝ) :
    deriv (deriv (fun x => a * Real.sin (c * x))) = fun x => -(a * c ^ 2) * Real.sin (c * x) := by
  rw [sin_mode_deriv]
  funext x
  have h := (((hasDerivAt_id x).const_mul c).cos).const_mul (a * c)
  simp only [id] at h; rw [h.deriv]; ring

lemma integral_sin_mode_sq (L : ℝ) (hL : 0 < L) :
    ∫ x in (0 : ℝ)..L, Real.sin (π / L * x) ^ 2 = L / 2 := by
  have hc : π / L ≠ 0 := div_ne_zero pi_ne_zero hL.ne'
  rw [intervalIntegral.integral_comp_mul_left (fun x => Real.sin x ^ 2) hc, integral_sin_sq]
  have : π / L * L = π := by field_simp
  rw [this]; simp; field_simp

lemma integral_cos_mode_sq (L : ℝ) (hL : 0 < L) :
    ∫ x in (0 : ℝ)..L, Real.cos (π / L * x) ^ 2 = L / 2 := by
  have hc : π / L ≠ 0 := div_ne_zero pi_ne_zero hL.ne'
  rw [intervalIntegral.integral_comp_mul_left (fun x => Real.cos x ^ 2) hc, integral_cos_sq]
  have : π / L * L = π := by field_simp
  rw [this]; simp; field_simp

lemma picone_hasDerivAt (y : ℝ → ℝ) (hy : ContDiff ℝ 2 y) (w L x : ℝ)
    (hc : Real.cos (w * (x - L / 2)) ≠ 0) :
    HasDerivAt (fun x => deriv y x * y x
        + w * y x ^ 2 * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2)))
      (deriv (deriv y) x * y x + deriv y x ^ 2
        + 2 * w * y x * deriv y x * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2))
        + w ^ 2 * y x ^ 2 / Real.cos (w * (x - L / 2)) ^ 2) x := by
  have hy1 : Differentiable ℝ y := hy.differentiable (by norm_num)
  have hy2 : Differentiable ℝ (deriv y) :=
    ((contDiff_succ_iff_deriv (n := 1)).1 hy).2.2.differentiable (by norm_num)
  have ha : HasDerivAt (fun x => w * (x - L / 2)) w x := by
    simpa using ((hasDerivAt_id x).sub_const (L / 2)).const_mul w
  have h := (((hy2 x).hasDerivAt.mul (hy1 x).hasDerivAt).add
    ((((hy1 x).hasDerivAt.pow 2).const_mul w).mul ha.sin |>.div ha.cos hc))
  convert h using 1
  have hsc := Real.sin_sq_add_cos_sq (w * (x - L / 2))
  simp only [Pi.mul_apply, Pi.pow_apply]
  generalize Real.sin (w * (x - L / 2)) = s at hsc ⊢
  generalize Real.cos (w * (x - L / 2)) = c at hc hsc ⊢
  field_simp
  norm_num
  linear_combination (-(w ^ 2 * y x ^ 2)) * hsc

#print axioms sin_mode_deriv
#print axioms sin_mode_deriv2
#print axioms integral_sin_mode_sq
#print axioms integral_cos_mode_sq
#print axioms picone_hasDerivAt

/-- The pinned column of length `L`, stiffness `E I`, under end load `P` can rest bent:
some twice continuously differentiable sideways bow `y` satisfies the balance
`E I y'' + P y = 0` along the column, is zero at both pins (`y 0 = 0`, `y L = 0`),
and is not zero somewhere between them. -/
def PinnedColumnCanRestBent (E I L P : ℝ) : Prop :=
  ∃ y : ℝ → ℝ, ContDiff ℝ 2 y ∧
    (∀ x ∈ Icc 0 L, E * I * deriv (deriv y) x + P * y x = 0) ∧
    y 0 = 0 ∧ y L = 0 ∧ ∃ x ∈ Icc 0 L, y x ≠ 0

/-- **Euler's critical load (Steps 0 and 1).** For an ideal pinned column (straight, elastic,
small slopes, the load along its axis) with stiffness `E I > 0` and length `L > 0`, the
smallest end load at which a bent resting shape exists is `P_cr = π² E I / L²`. Below it the
straight column is the only resting shape; at it, a bent shape becomes possible. -/
theorem euler_critical_load_is_least_bending_load (E I L : ℝ)
    (hE : 0 < E) (hI : 0 < I) (hL : 0 < L) :
    IsLeast {P : ℝ | PinnedColumnCanRestBent E I L P} (π ^ 2 * E * I / L ^ 2) := by
  have hEI : 0 < E * I := mul_pos hE hI
  constructor
  · -- the first mode sin(πx/L) rests bent at Euler's load
    refine ⟨fun x => 1 * Real.sin (π / L * x), by fun_prop, ?_, by simp, ?_,
      ⟨L / 2, ⟨by positivity, by linarith⟩, ?_⟩⟩
    · intro x _
      rw [sin_mode_deriv2]
      field_simp
      ring
    · have : π / L * L = π := by field_simp
      simp [this]
    · have : π / L * (L / 2) = π / 2 := by field_simp
      simp [this]
  · -- below Euler's load only the straight column rests (Picone's identity)
    rintro P ⟨y, hy, hbal, h0, hL0, x0, hx0, hne⟩
    by_contra hlt
    push Not at hlt
    set k := P / (E * I) with hk_def
    have hy2 : ∀ x ∈ Icc 0 L, deriv (deriv y) x = -k * y x := by
      intro x hx
      have := hbal x hx
      rw [hk_def]; field_simp; linarith
    have hk : k < (π / L) ^ 2 := by
      rw [hk_def, div_lt_iff₀ hEI]
      calc P < π ^ 2 * E * I / L ^ 2 := hlt
        _ = (π / L) ^ 2 * (E * I) := by field_simp
    set t := (max k 0 + (π / L) ^ 2) / 2 with ht_def
    have hmax : max k 0 < (π / L) ^ 2 := max_lt hk (by positivity)
    have ht0 : 0 ≤ t := by have := le_max_right k 0; rw [ht_def]; positivity
    have hkt : k < t := by have := le_max_left k 0; rw [ht_def]; linarith
    have htlt : t < (π / L) ^ 2 := by rw [ht_def]; linarith
    set w := Real.sqrt t with hw_def
    have hw0 : 0 ≤ w := Real.sqrt_nonneg t
    have hw2 : w ^ 2 = t := Real.sq_sqrt ht0
    have hwlt : w < π / L := by
      rw [hw_def]
      calc Real.sqrt t < Real.sqrt ((π / L) ^ 2) := Real.sqrt_lt_sqrt ht0 htlt
        _ = π / L := Real.sqrt_sq (by positivity)
    have hwL : w * L < π := by rwa [lt_div_iff₀ hL] at hwlt
    have hcpos : ∀ x ∈ Icc 0 L, 0 < Real.cos (w * (x - L / 2)) := by
      intro x hx
      apply Real.cos_pos_of_mem_Ioo
      constructor
      · nlinarith [hx.1, hx.2]
      · nlinarith [hx.1, hx.2]
    set F : ℝ → ℝ := fun x => deriv y x * y x
        + w * y x ^ 2 * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2)) with hF
    have hFd : ∀ x ∈ Icc 0 L, HasDerivAt F
        (deriv (deriv y) x * y x + deriv y x ^ 2
        + 2 * w * y x * deriv y x * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2))
        + w ^ 2 * y x ^ 2 / Real.cos (w * (x - L / 2)) ^ 2) x :=
      fun x hx => picone_hasDerivAt y hy w L x (hcpos x hx).ne'
    have hFd' : ∀ x ∈ Icc 0 L, deriv (deriv y) x * y x + deriv y x ^ 2
        + 2 * w * y x * deriv y x * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2))
        + w ^ 2 * y x ^ 2 / Real.cos (w * (x - L / 2)) ^ 2
        = (deriv y x + w * y x * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2))) ^ 2
          + (w ^ 2 - k) * y x ^ 2 := by
      intro x hx
      have hc := (hcpos x hx).ne'
      have hsc := Real.sin_sq_add_cos_sq (w * (x - L / 2))
      rw [hy2 x hx]
      generalize Real.sin (w * (x - L / 2)) = s at hsc ⊢
      generalize Real.cos (w * (x - L / 2)) = c at hc hsc ⊢
      field_simp
      linear_combination (-(w ^ 2 * y x ^ 2)) * hsc
    have hmono : MonotoneOn F (Icc 0 L) := by
      apply monotoneOn_of_deriv_nonneg (convex_Icc 0 L)
      · exact fun x hx => (hFd x hx).continuousAt.continuousWithinAt
      · rw [interior_Icc]
        exact fun x hx => (hFd x (Ioo_subset_Icc_self hx)).differentiableAt.differentiableWithinAt
      · rw [interior_Icc]
        intro x hx
        have hx' := Ioo_subset_Icc_self hx
        rw [(hFd x hx').deriv, hFd' x hx']
        have : 0 ≤ w ^ 2 - k := by rw [hw2]; linarith
        positivity
    have hF0 : F 0 = 0 := by simp [hF, h0]
    have hFL : F L = 0 := by simp [hF, hL0]
    have hFz : ∀ x ∈ Icc 0 L, F x = 0 := by
      intro x hx
      have h1 := hmono ⟨le_refl 0, hL.le⟩ hx hx.1
      have h2 := hmono hx ⟨hL.le, le_refl L⟩ hx.2
      linarith
    have hyz : ∀ x ∈ Ioo 0 L, y x = 0 := by
      intro x hx
      have hx' := Ioo_subset_Icc_self hx
      have hev : F =ᶠ[nhds x] fun _ => (0 : ℝ) := by
        filter_upwards [Ioo_mem_nhds hx.1 hx.2] with z hz
        exact hFz z (Ioo_subset_Icc_self hz)
      have hd0 : HasDerivAt F 0 x := (hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq hev
      have heq := (hFd x hx').unique hd0
      rw [hFd' x hx'] at heq
      have hpos : 0 < w ^ 2 - k := by rw [hw2]; linarith
      have hsq := sq_nonneg (deriv y x + w * y x * Real.sin (w * (x - L / 2)) / Real.cos (w * (x - L / 2)))
      have : (w ^ 2 - k) * y x ^ 2 = 0 := by nlinarith [sq_nonneg (y x), mul_nonneg hpos.le (sq_nonneg (y x))]
      rcases mul_eq_zero.1 this with h | h
      · linarith
      · exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h
    apply hne
    rcases eq_or_lt_of_le hx0.1 with h | h
    · rw [← h]; exact h0
    rcases eq_or_lt_of_le hx0.2 with h' | h'
    · rw [h']; exact hL0
    exact hyz x0 ⟨h, h'⟩

/-- **The higher modes (Step 1).** For every mode number `n ≥ 1`, the shape
`y = sin(nπx/L)` with `n` half-waves solves the pinned-column balance `E I y'' + P y = 0`
at the load `P = n² π² E I / L²`, which is `n²` times Euler's load: the S-shape (`n = 2`)
needs four times as much. -/
theorem pinned_column_mode_n_load (E I L : ℝ) (hL : 0 < L) (n : ℕ) (hn : 1 ≤ n) :
    let y : ℝ → ℝ := fun x => Real.sin (n * π * x / L)
    let P : ℝ := (n : ℝ) ^ 2 * (π ^ 2 * E * I / L ^ 2)
    (∀ x, E * I * deriv (deriv y) x + P * y x = 0) ∧ y 0 = 0 ∧ y L = 0 ∧
      ∃ x ∈ Icc 0 L, y x ≠ 0 := by
  intro y P
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hy : y = fun x => 1 * Real.sin (n * π / L * x) := by
    funext x; simp only [y, one_mul]; congr 1; ring
  refine ⟨?_, ?_, ?_, ⟨L / (2 * n), ⟨by positivity, ?_⟩, ?_⟩⟩
  · intro x
    rw [hy, sin_mode_deriv2]
    simp only [P]
    field_simp
    ring
  · simp [y]
  · simp only [y]
    have : (n : ℝ) * π * L / L = (n : ℕ) * π := by field_simp
    rw [this, Real.sin_nat_mul_pi]
  · rw [div_le_iff₀ (by positivity)]
    have h1n : (1 : ℝ) ≤ n := by exact_mod_cast hn
    nlinarith
  · simp only [y]
    have : (n : ℝ) * π * (L / (2 * n)) / L = π / 2 := by field_simp
    rw [this, Real.sin_pi_div_two]; norm_num

/-- **Stability is an energy question (Step 4).** Bow the pinned column into
`y = a sin(πx/L)`. The bending energy `½ ∫₀ᴸ E I (y'')² dx` minus the work `P · ½ ∫₀ᴸ (y')² dx`
released as the load moves down equals `(π² a² / 4L)(π² E I / L² − P)`: positive below
Euler's load (the straight column is stable), negative above it (unstable). -/
theorem bowing_energy_change (E I L P a : ℝ) (hL : 0 < L) :
    let y : ℝ → ℝ := fun x => a * Real.sin (π * x / L)
    (1 / 2) * (∫ x in (0 : ℝ)..L, E * I * (deriv (deriv y) x) ^ 2)
      - P * ((1 / 2) * ∫ x in (0 : ℝ)..L, (deriv y x) ^ 2)
      = π ^ 2 * a ^ 2 / (4 * L) * (π ^ 2 * E * I / L ^ 2 - P) := by
  intro y
  have hy : y = fun x => a * Real.sin (π / L * x) := by
    funext x; simp only [y]; congr 1; ring
  rw [hy, sin_mode_deriv2, sin_mode_deriv]
  have h1 : (fun x => E * I * (-(a * (π / L) ^ 2) * Real.sin (π / L * x)) ^ 2)
      = fun x => (E * I * a ^ 2 * (π / L) ^ 4) * Real.sin (π / L * x) ^ 2 := by
    funext x; ring
  have h2 : (fun x => (a * (π / L) * Real.cos (π / L * x)) ^ 2)
      = fun x => (a ^ 2 * (π / L) ^ 2) * Real.cos (π / L * x) ^ 2 := by
    funext x; ring
  simp only [h1, h2, intervalIntegral.integral_const_mul, integral_sin_mode_sq L hL,
    integral_cos_mode_sq L hL]
  field_simp
  ring

-- The card's exact ratios. Lengths in tenths of a millimetre where the card has decimals.
-- Inside diameter: 48.3 - 2 x 4.0 = 40.3 mm.
example : (483 : ℕ) - 2 * 40 = 403 := by norm_num
-- Flagpole, K = 2: the load is 1/K^2 = 1/4 of the pinned load.
example : (1 : ℚ) / 2 ^ 2 = 1 / 4 := by norm_num
-- Fixed-fixed, K = 1/2: the load is 1/K^2 = 4 times the pinned load.
example : (1 : ℚ) / (1 / 2) ^ 2 = 4 := by norm_num
-- Effective lengths K L for the 3 m tube: 6 m (flagpole) and 3/2 m (fixed-fixed).
example : (2 : ℚ) * 3 = 6 ∧ (1 / 2 : ℚ) * 3 = 3 / 2 := by norm_num
-- Fixed-fixed, L = 3 m: inflection points at L/4 = 3/4 m and 3L/4 = 9/4 m; the stretch between is the pinned 3/2 m tube.
example : (3 : ℚ) * 3 / 4 - 3 / 4 = 3 / 2 := by norm_num
-- Cutting the tube from 3 m to 2 m raises the load by (3/2)^2 = 9/4.
example : ((3 : ℚ) / 2) ^ 2 = 9 / 4 := by norm_num
-- The S-shape, n = 2, needs 2^2 = 4 times Euler's load.
example : (2 : ℕ) ^ 2 = 4 := by norm_num

#print axioms euler_critical_load_is_least_bending_load
#print axioms pinned_column_mode_n_load
#print axioms bowing_energy_change
