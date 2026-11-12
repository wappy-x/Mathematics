-- Two-point boundary problems: on the stiff spring bed y'' = k^2 y, the far end of a shot moves by sinh(k)/k per unit of start slope, while the boundary problem itself has the solution α sinh(k(1-x))/sinh k + β sinh(kx)/sinh k and moves by no more than its end heights do.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Tactic

open Real

/-- The exact solution of the stiff-bed boundary problem y'' = k^2 y on 0 ≤ x ≤ 1 with
y(0) = α and y(1) = β: α sinh(k(1-x))/sinh k + β sinh(kx)/sinh k. -/
noncomputable def bedSolution (α β k : ℝ) (x : ℝ) : ℝ :=
  α * Real.sinh (k * (1 - x)) / Real.sinh k + β * Real.sinh (k * x) / Real.sinh k

theorem bed_first_order_zero (c : ℝ) (f : ℝ → ℝ) (hf : ∀ x, HasDerivAt f (c * f x) x)
    (h0 : f 0 = 0) : ∀ x, f x = 0 := by
  have hg : ∀ x, HasDerivAt (fun t => f t * Real.exp (-c * t)) 0 x := by
    intro x
    have h1 : HasDerivAt (fun t => -c * t) (-c) x := by
      simpa using (hasDerivAt_id x).const_mul (-c)
    have h2 := (hf x).mul h1.exp
    convert h2 using 1
    ring
  have hconst := is_const_of_deriv_eq_zero (fun x => (hg x).differentiableAt)
    (fun x => (hg x).deriv)
  intro x
  have := hconst x 0
  simp only [h0, zero_mul] at this
  rcases mul_eq_zero.mp this with h | h
  · exact h
  · exact absurd h (Real.exp_pos _).ne'

#print axioms bed_first_order_zero

theorem bed_second_order_zero (k : ℝ) (hk : k ≠ 0) (u u' : ℝ → ℝ)
    (hu : ∀ x, HasDerivAt u (u' x) x) (hu' : ∀ x, HasDerivAt u' (k ^ 2 * u x) x)
    (h0 : u 0 = 0) (h0' : u' 0 = 0) : ∀ x, u x = 0 := by
  have hv := bed_first_order_zero (-k) (fun x => u' x - k * u x)
    (fun x => by
      convert (hu' x).sub ((hu x).const_mul k) using 1
      ring) (by simp [h0, h0'])
  have hw := bed_first_order_zero k (fun x => u' x + k * u x)
    (fun x => by
      convert (hu' x).add ((hu x).const_mul k) using 1
      ring) (by simp [h0, h0'])
  intro x
  have h1 := hv x
  have h2 := hw x
  have : 2 * k * u x = 0 := by linarith
  rcases mul_eq_zero.mp this with h | h
  · exact absurd h (mul_ne_zero two_ne_zero hk)
  · exact h

#print axioms bed_second_order_zero

theorem bed_shot_hasDerivAt (k α s x : ℝ) (hk : k ≠ 0) :
    HasDerivAt (fun t => α * Real.cosh (k * t) + s * Real.sinh (k * t) / k)
      (α * k * Real.sinh (k * x) + s * Real.cosh (k * x)) x := by
  have hl : HasDerivAt (fun t => k * t) k x := by simpa using (hasDerivAt_id x).const_mul k
  have := ((hl.cosh).const_mul α).add (((hl.sinh).const_mul s).div_const k)
  convert this using 1
  field_simp

#print axioms bed_shot_hasDerivAt

theorem bed_shot_hasDerivAt' (k α s x : ℝ) :
    HasDerivAt (fun t => α * k * Real.sinh (k * t) + s * Real.cosh (k * t))
      (k ^ 2 * (α * Real.cosh (k * x) + s * Real.sinh (k * x) / k)) x := by
  have hl : HasDerivAt (fun t => k * t) k x := by simpa using (hasDerivAt_id x).const_mul k
  have := ((hl.sinh).const_mul (α * k)).add ((hl.cosh).const_mul s)
  convert this using 1
  by_cases hk : k = 0
  · subst hk; simp
  · field_simp

#print axioms bed_shot_hasDerivAt'

theorem bed_hasDerivAt (α β k x : ℝ) :
    HasDerivAt (bedSolution α β k)
      ((-(α * k) * Real.cosh (k * (1 - x)) + β * k * Real.cosh (k * x)) / Real.sinh k) x := by
  have hl : HasDerivAt (fun t => k * t) k x := by simpa using (hasDerivAt_id x).const_mul k
  have hm : HasDerivAt (fun t => k * (1 - t)) (-k) x := by
    simpa using ((hasDerivAt_id x).const_sub 1).const_mul k
  have := (((hm.sinh).const_mul α).div_const (Real.sinh k)).add
    (((hl.sinh).const_mul β).div_const (Real.sinh k))
  exact this.congr_deriv (by ring)

#print axioms bed_hasDerivAt

theorem bed_hasDerivAt' (α β k x : ℝ) :
    HasDerivAt (fun t => (-(α * k) * Real.cosh (k * (1 - t)) + β * k * Real.cosh (k * t)) / Real.sinh k)
      (k ^ 2 * bedSolution α β k x) x := by
  have hl : HasDerivAt (fun t => k * t) k x := by simpa using (hasDerivAt_id x).const_mul k
  have hm : HasDerivAt (fun t => k * (1 - t)) (-k) x := by
    simpa using ((hasDerivAt_id x).const_sub 1).const_mul k
  have := (((hm.cosh).const_mul (-(α * k))).add ((hl.cosh).const_mul (β * k))).div_const (Real.sinh k)
  convert this using 1
  unfold bedSolution
  ring

#print axioms bed_hasDerivAt'

theorem bed_sinh_add_le (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) :
    Real.sinh a + Real.sinh b ≤ Real.sinh (a + b) := by
  rw [Real.sinh_add]
  have h1 := Real.one_le_cosh a
  have h2 := Real.one_le_cosh b
  have h3 := Real.sinh_nonneg_iff.mpr ha
  have h4 := Real.sinh_nonneg_iff.mpr hb
  nlinarith

#print axioms bed_sinh_add_le

/-- Shooting's magnification on the stiff bed. Take k > 0 and, for each start slope s, a solution
y s of y'' = k^2 y with start height y(0) = α and start slope y'(0) = s. Then the height at x
moves by sinh(kx)/k per unit of start slope: the derivative of y s x with respect to s is
sinh(kx)/k at every s. At the far end x = 1 that is sinh(k)/k, and at midspan sinh(k/2)/k. -/
theorem stiff_bed_shooting_magnification (k α : ℝ) (hk : 0 < k) (y : ℝ → ℝ → ℝ)
    (hd : ∀ s, Differentiable ℝ (y s)) (hd' : ∀ s, Differentiable ℝ (deriv (y s)))
    (hode : ∀ s x, deriv (deriv (y s)) x = k ^ 2 * y s x)
    (h0 : ∀ s, y s 0 = α) (h1 : ∀ s, deriv (y s) 0 = s) :
    ∀ x s₀, HasDerivAt (fun s => y s x) (Real.sinh (k * x) / k) s₀ := by
  have key : ∀ s x, y s x = α * Real.cosh (k * x) + s * Real.sinh (k * x) / k := by
    intro s
    have := bed_second_order_zero k hk.ne'
      (fun x => y s x - (α * Real.cosh (k * x) + s * Real.sinh (k * x) / k))
      (fun x => deriv (y s) x - (α * k * Real.sinh (k * x) + s * Real.cosh (k * x)))
      (fun x => ((hd s x).hasDerivAt).sub (bed_shot_hasDerivAt k α s x hk.ne'))
      (fun x => by
        have := ((hd' s x).hasDerivAt).sub (bed_shot_hasDerivAt' k α s x)
        rw [hode] at this
        convert this using 1
        ring)
      (by simp [h0]) (by simp [h1])
    intro x
    have := this x
    linarith
  intro x s₀
  have hfun : (fun s => y s x) = fun s => α * Real.cosh (k * x) + s * Real.sinh (k * x) / k := by
    funext s; exact key s x
  rw [hfun]
  have := ((hasDerivAt_id s₀).mul_const (Real.sinh (k * x))).div_const k
  have := this.const_add (α * Real.cosh (k * x))
  simpa using this

/-- The stiff-bed boundary problem has the closed-form solution
y = α sinh(k(1-x))/sinh k + β sinh(kx)/sinh k: it starts at height α, ends at height β,
and obeys y'' = k^2 y everywhere. -/
theorem stiff_bed_exact_solution (α β k : ℝ) (hk : 0 < k) :
    bedSolution α β k 0 = α ∧ bedSolution α β k 1 = β ∧
    Differentiable ℝ (bedSolution α β k) ∧ Differentiable ℝ (deriv (bedSolution α β k)) ∧
    ∀ x, deriv (deriv (bedSolution α β k)) x = k ^ 2 * bedSolution α β k x := by
  have hs : Real.sinh k ≠ 0 := (Real.sinh_pos_iff.mpr hk).ne'
  have hD : deriv (bedSolution α β k) =
      fun t => (-(α * k) * Real.cosh (k * (1 - t)) + β * k * Real.cosh (k * t)) / Real.sinh k := by
    funext t; exact (bed_hasDerivAt α β k t).deriv
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · unfold bedSolution; field_simp; simp
  · unfold bedSolution; field_simp; simp
  · exact fun x => (bed_hasDerivAt α β k x).differentiableAt
  · rw [hD]; exact fun x => (bed_hasDerivAt' α β k x).differentiableAt
  · intro x; rw [hD]; exact (bed_hasDerivAt' α β k x).deriv

/-- The stiff-bed problem is well conditioned: on the span 0 ≤ x ≤ 1, changing the end heights
from α, β to α', β' changes the solution anywhere by at most the larger of the two changes. -/
theorem stiff_bed_well_conditioned (α β α' β' k x : ℝ) (hk : 0 < k) (hx0 : 0 ≤ x) (hx1 : x ≤ 1) :
    |bedSolution α β k x - bedSolution α' β' k x| ≤ max |α - α'| |β - β'| := by
  have hS : 0 < Real.sinh k := Real.sinh_pos_iff.mpr hk
  set A := Real.sinh (k * (1 - x)) / Real.sinh k with hA
  set B := Real.sinh (k * x) / Real.sinh k with hB
  have hA0 : 0 ≤ A := div_nonneg (Real.sinh_nonneg_iff.mpr (by nlinarith)) hS.le
  have hB0 : 0 ≤ B := div_nonneg (Real.sinh_nonneg_iff.mpr (by nlinarith)) hS.le
  have hAB : A + B ≤ 1 := by
    rw [hA, hB, ← add_div, div_le_one hS]
    have := bed_sinh_add_le (k * (1 - x)) (k * x) (by nlinarith) (by nlinarith)
    have e : k * (1 - x) + k * x = k := by ring
    rw [e] at this
    exact this
  have hdiff : bedSolution α β k x - bedSolution α' β' k x = (α - α') * A + (β - β') * B := by
    unfold bedSolution; rw [hA, hB]; ring
  rw [hdiff]
  set M := max |α - α'| |β - β'|
  have h1 : |α - α'| ≤ M := le_max_left _ _
  have h2 : |β - β'| ≤ M := le_max_right _ _
  have hM : 0 ≤ M := le_trans (abs_nonneg _) h1
  calc |(α - α') * A + (β - β') * B|
      ≤ |(α - α') * A| + |(β - β') * B| := abs_add_le _ _
    _ = |α - α'| * A + |β - β'| * B := by
        rw [abs_mul, abs_mul, abs_of_nonneg hA0, abs_of_nonneg hB0]
    _ ≤ M * A + M * B := by gcongr
    _ = M * (A + B) := by ring
    _ ≤ M * 1 := by gcongr
    _ = M := mul_one M

-- One Thomas sweep costs 8 flops per unknown, less 7: 113 flops for the 15 unknowns of 16 intervals.
example : 8 * 15 - 7 = 113 := by norm_num

-- Finite differences with N = 16 intervals have N - 1 = 15 unknown heights;
-- collocation of degree n = 8 has n + 1 = 9 unknown values.
example : 16 - 1 = 15 ∧ 8 + 1 = 9 := by norm_num

#print axioms stiff_bed_shooting_magnification
#print axioms stiff_bed_exact_solution
#print axioms stiff_bed_well_conditioned
