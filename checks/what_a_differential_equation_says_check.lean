-- A differential equation: every curve obeying Newton's cooling rule T' = -0.1 (T - 20) on an open interval containing 0 is 20 + C e^(-0.1 t) for one constant C, every such curve obeys the rule, and the start T(0) = 80 forces C = 60, so the cup reads 50 °C exactly at t = 10 ln 2.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Topology.Connected.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Tactic

open Real Set

/-- Every solution is in the family. Let T be a temperature curve that obeys the cooling rule
T' = -0.1 (T - 20) at every time of an interval (open, in one piece) containing the start 0.
Then there is one constant C with T(t) = 20 + C e^(-0.1 t) at every time of that interval. -/
theorem cooling_solution_in_family (T : ℝ → ℝ) (I : Set ℝ) (hIo : IsOpen I)
    (hIc : IsPreconnected I) (h0 : (0 : ℝ) ∈ I)
    (hT : ∀ t ∈ I, HasDerivAt T (-(1 / 10) * (T t - 20)) t) :
    ∃ C : ℝ, ∀ t ∈ I, T t = 20 + C * exp (-(1 / 10) * t) := by
  set g : ℝ → ℝ := fun t => (T t - 20) * exp ((1 / 10) * t) with hg
  have hgd : ∀ t ∈ I, HasDerivAt g 0 t := by
    intro t ht
    have h1 : HasDerivAt g ((-(1 / 10) * (T t - 20)) * exp ((1 / 10) * t)
        + (T t - 20) * (exp ((1 / 10) * t) * ((1 / 10) * 1))) t :=
      ((hT t ht).sub_const 20).mul (((hasDerivAt_id' t).const_mul (1 / 10 : ℝ)).exp)
    exact h1.congr_deriv (by ring)
  have hdiff : DifferentiableOn ℝ g I := fun t ht => (hgd t ht).differentiableAt.differentiableWithinAt
  have heq : I.EqOn (deriv g) 0 := fun t ht => (hgd t ht).deriv
  refine ⟨T 0 - 20, fun t ht => ?_⟩
  have hc := hIo.is_const_of_deriv_eq_zero hIc hdiff heq ht h0
  simp only [hg, mul_zero, exp_zero, mul_one] at hc
  have he : exp ((1 / 10) * t) * exp (-(1 / 10) * t) = 1 := by
    rw [← exp_add]; ring_nf; exact exp_zero
  have : T t - 20 = (T 0 - 20) * exp (-(1 / 10) * t) := by
    rw [← hc]
    calc T t - 20 = (T t - 20) * (exp ((1 / 10) * t) * exp (-(1 / 10) * t)) := by rw [he, mul_one]
      _ = _ := by ring
  linarith

/-- Every member of the family passes: for every constant C, the curve 20 + C e^(-0.1 t) has slope
equal to what the rule demands, -0.1 (T - 20), at every time t. -/
theorem cooling_family_solves (C t : ℝ) :
    HasDerivAt (fun s => 20 + C * exp (-(1 / 10) * s))
      (-(1 / 10) * ((20 + C * exp (-(1 / 10) * t)) - 20)) t := by
  have h : HasDerivAt (fun s => 20 + C * exp (-(1 / 10) * s))
      (C * (exp (-(1 / 10) * t) * (-(1 / 10) * 1))) t :=
    ((((hasDerivAt_id' t).const_mul (-(1 / 10) : ℝ)).exp).const_mul C).const_add 20
  exact h.congr_deriv (by ring)

/-- The starting value picks one curve. If T obeys the cooling rule on an open interval in one
piece containing 0 and the cup reads 80 °C at the pour, then T(t) = 20 + 60 e^(-0.1 t) throughout,
and within that interval the cup reads 50 °C exactly at t = 10 ln 2. -/
theorem coffee_from_80_unique (T : ℝ → ℝ) (I : Set ℝ) (hIo : IsOpen I)
    (hIc : IsPreconnected I) (h0 : (0 : ℝ) ∈ I)
    (hT : ∀ t ∈ I, HasDerivAt T (-(1 / 10) * (T t - 20)) t) (hstart : T 0 = 80) :
    (∀ t ∈ I, T t = 20 + 60 * exp (-(1 / 10) * t)) ∧
      (∀ t ∈ I, T t = 50 ↔ t = 10 * log 2) := by
  obtain ⟨C, hC⟩ := cooling_solution_in_family T I hIo hIc h0 hT
  have hC0 := hC 0 h0
  simp only [mul_zero, exp_zero, mul_one] at hC0
  have hC60 : C = 60 := by linarith
  subst hC60
  refine ⟨hC, fun t ht => ?_⟩
  rw [hC t ht]
  have hl : exp (-(1 / 10) * (10 * log 2)) = 1 / 2 := by
    rw [show -(1 / 10) * (10 * log 2) = -log 2 by ring, exp_neg, exp_log (by norm_num)]
    norm_num
  constructor
  · intro h
    have h2 : exp (-(1 / 10) * t) = exp (-(1 / 10) * (10 * log 2)) := by rw [hl]; linarith
    rw [exp_eq_exp] at h2
    linarith
  · intro h
    rw [h, hl]
    norm_num

-- Rate at the pour: -0.1 × (80 - 20) = -6 °C per minute; at 50 °C: -0.1 × (50 - 20) = -3.
example : -(1 / 10 : ℝ) * (80 - 20) = -6 ∧ -(1 / 10 : ℝ) * (50 - 20) = -3 := by norm_num

-- The family's constant: T(0) = 20 + C = 80 forces C = 60.
example (C : ℝ) (h : 20 + C * exp (-(1 / 10) * 0) = 80) : C = 60 := by simp at h; linarith

-- Mistake, forget the room: 80 e^(-0.1 t) misses the rule by exactly -2 °C per minute at every time.
example (t : ℝ) : deriv (fun s => 80 * exp (-(1 / 10) * s)) t
    - (-(1 / 10) * (80 * exp (-(1 / 10) * t) - 20)) = -2 := by
  have h : HasDerivAt (fun s => 80 * exp (-(1 / 10) * s)) (80 * (exp (-(1 / 10) * t) * (-(1 / 10) * 1))) t :=
    (((hasDerivAt_id' t).const_mul (-(1 / 10) : ℝ)).exp).const_mul 80
  rw [h.deriv]
  ring

-- Mistake, lose the minus sign: 20 + 60 e^(+0.1 t) reads 140 °C at t = 10 ln 2,
-- and misses the rule by 12 at the pour (slope +6 against the demanded -6).
example : 20 + 60 * exp ((1 / 10) * (10 * log 2)) = 140 ∧
    deriv (fun s => 20 + 60 * exp ((1 / 10) * s)) 0
      - (-(1 / 10) * ((20 + 60 * exp ((1 / 10) * 0)) - 20)) = 12 := by
  have h : HasDerivAt (fun s => 20 + 60 * exp ((1 / 10) * s)) (60 * (exp ((1 / 10) * 0) * ((1 / 10) * 1))) 0 :=
    ((((hasDerivAt_id' (0:ℝ)).const_mul (1 / 10 : ℝ)).exp).const_mul 60).const_add 20
  rw [h.deriv]
  refine ⟨?_, ?_⟩
  · rw [show (1 / 10 : ℝ) * (10 * log 2) = log 2 by ring, exp_log (by norm_num)]
    norm_num
  · simp
    norm_num

-- Mistake, check the start only: the tangent line 80 - 6t reaches 50 °C at t = 5,
-- where it misses the rule by -6 - (-0.1 × (50 - 20)) = -3.
example : (80 : ℝ) - 6 * 5 = 50 ∧ (-6 : ℝ) - (-(1 / 10) * ((80 - 6 * 5) - 20)) = -3 := by norm_num

-- The leaking bucket h' = -√h: starts of 1 and 4 cm give (1 - t/2)^2 and (2 - t/2)^2 before
-- emptying; both read 0 at t = 4, but 1/4 and 9/4 cm at t = 1.
example : ((2 : ℝ) - 4 / 2) ^ 2 = 0 ∧ ((1 : ℝ) - 1 / 2) ^ 2 = 1 / 4 ∧
    ((2 : ℝ) - 1 / 2) ^ 2 = 9 / 4 := by norm_num

#print axioms cooling_solution_in_family
#print axioms cooling_family_solves
#print axioms coffee_from_80_unique
