-- Mean curvature flow: a round sphere moving inward at speed 2/r (a circle at 1/r, an n-dimensional sphere at n/r) has radius squared falling in a straight line, r^2 = r0^2 - 4t, so it is gone by t = r0^2/4, and r = sqrt(r0^2 - 4t) does solve the flow.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.MeanValue

/-- Helper: a positive radius moving at speed c/r inward, dr/dt = -c/r with c ≥ 0, has
r(t)^2 = r0^2 - 2ct on [0, T), and so 2cT ≤ r0^2. -/
theorem radius_sq_law_aux (c : ℝ) (hc : 0 ≤ c) (r : ℝ → ℝ) (r₀ T : ℝ) (h0 : r 0 = r₀)
    (hpos : ∀ t ∈ Set.Ico 0 T, 0 < r t)
    (hflow : ∀ t ∈ Set.Ico 0 T, HasDerivAt r (-c / r t) t) :
    (∀ t ∈ Set.Ico 0 T, r t ^ 2 = r₀ ^ 2 - 2 * c * t) ∧ 2 * c * T ≤ r₀ ^ 2 := by
  have key : ∀ t ∈ Set.Ico 0 T, r t ^ 2 = r₀ ^ 2 - 2 * c * t := by
    intro t ht
    have hsub : Set.Icc 0 t ⊆ Set.Ico 0 T := fun x hx => ⟨hx.1, lt_of_le_of_lt hx.2 ht.2⟩
    have hd : ∀ x ∈ Set.Ico 0 T, HasDerivAt (fun s => r s ^ 2 + 2 * c * s) 0 x := by
      intro x hx
      have h1 := ((hflow x hx).pow 2).add ((hasDerivAt_id x).const_mul (2 * c))
      have hne : r x ≠ 0 := (hpos x hx).ne'
      convert h1 using 1
      · funext s
        simp only [Pi.add_apply, Pi.pow_apply, id]
      · field_simp
        push_cast
        ring
    have hconst := constant_of_has_deriv_right_zero (f := fun s => r s ^ 2 + 2 * c * s)
      (a := 0) (b := t)
      (fun x hx => (hd x (hsub hx)).continuousAt.continuousWithinAt)
      (fun x hx => (hd x (hsub (Set.Ico_subset_Icc_self hx))).hasDerivWithinAt)
      t ⟨ht.1, le_refl t⟩
    simp only [h0, mul_zero, add_zero] at hconst
    linarith
  refine ⟨key, ?_⟩
  rcases hc.eq_or_lt with hc0 | hcpos
  · rw [← hc0]; nlinarith [sq_nonneg r₀]
  · by_contra hT
    replace hT := not_le.mp hT
    set t := r₀ ^ 2 / (2 * c) with ht_def
    have h2c : 0 < 2 * c := by linarith
    have htT : t < T := by rw [ht_def, div_lt_iff₀ h2c]; linarith
    have ht0 : 0 ≤ t := div_nonneg (sq_nonneg _) h2c.le
    have hmem : t ∈ Set.Ico 0 T := ⟨ht0, htT⟩
    have hk := key t hmem
    have : 2 * c * t = r₀ ^ 2 := by rw [ht_def]; field_simp
    have hp := hpos t hmem
    nlinarith

#print axioms radius_sq_law_aux

/-- A round sphere under mean curvature flow keeps its shape, and its radius r(t) moves at speed
2H = 2/r inward: dr/dt = -2/r. If the radius starts at r0 and stays positive on the time interval
[0, T), then its square falls in a straight line, r(t)^2 = r0^2 - 4t, and the sphere cannot last
past t = r0^2/4 (for r0 = 10 cm, past t = 25). -/
theorem sphere_radius_sq_law (r : ℝ → ℝ) (r₀ T : ℝ) (h0 : r 0 = r₀)
    (hpos : ∀ t ∈ Set.Ico 0 T, 0 < r t)
    (hflow : ∀ t ∈ Set.Ico 0 T, HasDerivAt r (-2 / r t) t) :
    (∀ t ∈ Set.Ico 0 T, r t ^ 2 = r₀ ^ 2 - 4 * t) ∧ T ≤ r₀ ^ 2 / 4 := by
  obtain ⟨h1, h2⟩ := radius_sq_law_aux 2 (by norm_num) r r₀ T h0 hpos hflow
  refine ⟨fun t ht => by rw [h1 t ht]; ring, by linarith⟩

/-- The same law with n equal bends: a round n-dimensional sphere moves at speed n/r, so
dr/dt = -n/r gives r(t)^2 = r0^2 - 2nt and an end time of at most r0^2/(2n). The case n = 1 is a
circle under curve shortening, r^2 = r0^2 - 2t, gone by t = 50 when r0 = 10; the case n = 2 is the
sphere above. -/
theorem round_sphere_radius_sq_law (n : ℕ) (r : ℝ → ℝ) (r₀ T : ℝ) (h0 : r 0 = r₀)
    (hpos : ∀ t ∈ Set.Ico 0 T, 0 < r t)
    (hflow : ∀ t ∈ Set.Ico 0 T, HasDerivAt r (-(n : ℝ) / r t) t) :
    (∀ t ∈ Set.Ico 0 T, r t ^ 2 = r₀ ^ 2 - 2 * n * t) ∧ 2 * n * T ≤ r₀ ^ 2 := by
  exact radius_sq_law_aux (n : ℝ) (Nat.cast_nonneg n) r r₀ T h0 hpos hflow

/-- The shrinking law really is a solution: while 4t < r0^2, the radius r(t) = sqrt(r0^2 - 4t)
has derivative -2/r(t), the sphere's mean curvature flow speed. -/
theorem sphere_radius_sqrt_solves_flow (r₀ t : ℝ) (ht : 4 * t < r₀ ^ 2) :
    HasDerivAt (fun s => Real.sqrt (r₀ ^ 2 - 4 * s)) (-2 / Real.sqrt (r₀ ^ 2 - 4 * t)) t := by
  have hf : HasDerivAt (fun s => r₀ ^ 2 - 4 * s) (-4) t := by
    simpa using ((hasDerivAt_id t).const_mul 4).const_sub (r₀ ^ 2)
  have hpos : 0 < r₀ ^ 2 - 4 * t := by linarith
  have h := hf.sqrt hpos.ne'
  have hs : 0 < Real.sqrt (r₀ ^ 2 - 4 * t) := Real.sqrt_pos.mpr hpos
  convert h using 1
  field_simp
  ring

-- The card's worked numbers, radius 10 cm.
-- Sphere: rate of r^2 is 2r * (-2/r) = -4; gone at 100/4 = 25; radius 6 at t = 16.
example : (2 : ℝ) * 10 * (-2 / 10) = -4 := by norm_num
example : (100 : ℝ) / 4 = 25 := by norm_num
example : Real.sqrt (100 - 4 * 16) = 6 := by
  rw [show (100 : ℝ) - 4 * 16 = 6 ^ 2 by norm_num]; exact Real.sqrt_sq (by norm_num)
-- Sphere area 4 pi 10^2 = 400 pi, lost at (2/10)^2 * 400 pi = 16 pi per unit time, gone at 25.
example : (2 / 10 : ℝ) ^ 2 * (4 * Real.pi * 10 ^ 2) = 16 * Real.pi := by ring
example : (400 * Real.pi) / (16 * Real.pi) = 25 := by
  have := Real.pi_pos; field_simp; norm_num
-- Circle: r^2 = 100 - 2t, gone at 100/2 = 50; enclosed area 100 pi lost at 2 pi, gone at 50.
example : (100 : ℝ) / 2 = 50 := by norm_num
example : (100 * Real.pi) / (2 * Real.pi) = 50 := by
  have := Real.pi_pos; field_simp; norm_num
-- Peanut: area 225 pi / 2, lost at 2 pi, gone at 225/4. A 3 cm cylinder is gone at 3^2/2 = 9/2.
example : (225 * Real.pi / 2) / (2 * Real.pi) = 225 / 4 := by
  have := Real.pi_pos; field_simp; norm_num
example : (3 : ℝ) ^ 2 / 2 = 9 / 2 := by norm_num

#print axioms sphere_radius_sq_law
#print axioms round_sphere_radius_sq_law
#print axioms sphere_radius_sqrt_solves_flow
