-- Phase portraits and nullclines: a continuous rate keeps one sign on any connected region that avoids its nullcline, the reserve x' = x(1 - y), y' = y(x - 1) rests only at (0, 0) and (1, 1), and V = x - ln x + y - ln y stays constant along its paths.
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Data.Sign.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.MeanValue

/-- A continuous function with no zero on a preconnected set keeps one sign there. -/
theorem sign_const_of_ne_zero_on_preconnected
    (h : ℝ × ℝ → ℝ) (hh : Continuous h) (S : Set (ℝ × ℝ)) (hS : IsPreconnected S)
    (hne : ∀ p ∈ S, h p ≠ 0) :
    ∀ p ∈ S, ∀ q ∈ S, SignType.sign (h p) = SignType.sign (h q) := by
  intro p hp q hq
  have hp0 := hne p hp
  have hq0 := hne q hq
  rcases lt_or_gt_of_ne hp0 with h1 | h1 <;> rcases lt_or_gt_of_ne hq0 with h2 | h2
  · rw [sign_neg h1, sign_neg h2]
  · exfalso
    obtain ⟨r, hr, hr0⟩ := hS.intermediate_value hp hq hh.continuousOn
      (show (0 : ℝ) ∈ Set.Icc (h p) (h q) from ⟨h1.le, h2.le⟩)
    exact hne r hr hr0
  · exfalso
    obtain ⟨r, hr, hr0⟩ := hS.intermediate_value hq hp hh.continuousOn
      (show (0 : ℝ) ∈ Set.Icc (h q) (h p) from ⟨h2.le, h1.le⟩)
    exact hne r hr hr0
  · rw [sign_pos h1, sign_pos h2]

#print axioms sign_const_of_ne_zero_on_preconnected

/-- Between the nullclines each rate keeps one sign: for a planar system x' = f(x, y),
y' = g(x, y) with continuous rates, on any connected region that meets neither the
x-nullcline (f = 0) nor the y-nullcline (g = 0), the signs of f and of g are the same at
every point. So one test point per region fixes the arrow for the whole region. -/
theorem rate_signs_constant_between_nullclines
    (f g : ℝ × ℝ → ℝ) (hf : Continuous f) (hg : Continuous g)
    (S : Set (ℝ × ℝ)) (hS : IsPreconnected S)
    (hfS : ∀ p ∈ S, f p ≠ 0) (hgS : ∀ p ∈ S, g p ≠ 0) :
    ∀ p ∈ S, ∀ q ∈ S, SignType.sign (f p) = SignType.sign (f q) ∧
      SignType.sign (g p) = SignType.sign (g q) := by
  intro p hp q hq
  exact ⟨sign_const_of_ne_zero_on_preconnected f hf S hS hfS p hp q hq,
    sign_const_of_ne_zero_on_preconnected g hg S hS hgS p hp q hq⟩

/-- The reserve x' = x(1 - y), y' = y(x - 1) has exactly two rests, where a nullcline of
each kind crosses: (0, 0) and (1, 1). -/
theorem reserve_rests :
    {p : ℝ × ℝ | p.1 * (1 - p.2) = 0 ∧ p.2 * (p.1 - 1) = 0} = {(0, 0), (1, 1)} := by
  ext ⟨a, b⟩
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff, Prod.mk.injEq]
  constructor
  · rintro ⟨h1, h2⟩
    rcases mul_eq_zero.mp h1 with ha | hb
    · subst ha
      left
      refine ⟨rfl, ?_⟩
      rcases mul_eq_zero.mp h2 with hb | hb
      · exact hb
      · norm_num at hb
    · right
      have hb1 : b = 1 := by linarith
      subst hb1
      refine ⟨?_, rfl⟩
      rcases mul_eq_zero.mp h2 with hb | hb
      · norm_num at hb
      · linarith
  · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) <;> norm_num

/-- Along any path of the reserve x' = x(1 - y), y' = y(x - 1) with both animals present,
V = x - ln x + y - ln y never changes. -/
theorem reserve_V_conserved (x y : ℝ → ℝ)
    (hx : ∀ t, HasDerivAt x (x t * (1 - y t)) t)
    (hy : ∀ t, HasDerivAt y (y t * (x t - 1)) t)
    (hpos : ∀ t, 0 < x t ∧ 0 < y t) :
    ∀ t, x t - Real.log (x t) + y t - Real.log (y t) =
      x 0 - Real.log (x 0) + y 0 - Real.log (y 0) := by
  set V : ℝ → ℝ := fun t => x t - Real.log (x t) + y t - Real.log (y t) with hVdef
  have hV : ∀ t, HasDerivAt V 0 t := by
    intro t
    have hxt := (hpos t).1
    have hyt := (hpos t).2
    have h1 := ((hx t).sub ((hx t).log hxt.ne')).add (hy t) |>.sub ((hy t).log hyt.ne')
    convert h1 using 1
    field_simp
    ring
  have hd : Differentiable ℝ V := fun t => (hV t).differentiableAt
  have hz : ∀ t, deriv V t = 0 := fun t => (hV t).deriv
  intro t
  exact is_const_of_deriv_eq_zero hd hz t 0

-- The card's whole-number checks, with f(x, y) = x(1 - y) and g(x, y) = y(x - 1).
-- (0, 1) is where two x-nullclines meet: x' = 0 but y' = -1, so it is not a rest.
example : (0 : ℤ) * (1 - 1) = 0 ∧ (1 : ℤ) * (0 - 1) = -1 := by norm_num
-- The start (2, 1): x' = 0, y' = +1, straight up.
example : (2 : ℤ) * (1 - 1) = 0 ∧ (1 : ℤ) * (2 - 1) = 1 := by norm_num
-- (1, 0) is where two y-nullclines meet: x' = 1, y' = 0, not a rest.
example : (1 : ℤ) * (1 - 0) = 1 ∧ (0 : ℤ) * (1 - 1) = 0 := by norm_num
-- The four test points and their signs: SE (2, 1/2) + +, NE (2, 2) - +,
-- NW (1/2, 2) - -, SW (1/2, 1/2) + -.
example : (0 : ℚ) < 2 * (1 - 1/2) ∧ (0 : ℚ) < 1/2 * (2 - 1) := by norm_num
example : (2 : ℚ) * (1 - 2) < 0 ∧ (0 : ℚ) < 2 * (2 - 1) := by norm_num
example : (1/2 : ℚ) * (1 - 2) < 0 ∧ (2 : ℚ) * (1/2 - 1) < 0 := by norm_num
example : (0 : ℚ) < 1/2 * (1 - 1/2) ∧ (1/2 : ℚ) * (1/2 - 1) < 0 := by norm_num
-- The cheetah peak on x = 1: y = 2 gives y - ln y = 2 - ln 2, the same level as the start,
-- since V(2, 1) - 1 = 2 - ln 2 + 1 - ln 1 - 1.
example : (2 : ℝ) - Real.log 2 + 1 - Real.log 1 - 1 = 2 - Real.log 2 := by simp

#print axioms rate_signs_constant_between_nullclines
#print axioms reserve_rests
#print axioms reserve_V_conserved
