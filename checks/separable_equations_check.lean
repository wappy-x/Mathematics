-- Separable equations: on an interval where h(y) is not zero, y solves y' = g(t) h(y) exactly when H(y(t)) = G(t) + C for antiderivatives H of 1/h and G of g, every zero of h gives a constant solution, and the snowball V' = -(3/10) V^(2/3) from 1000 cm^3 follows (10 - t/10)^3 until 100 minutes and V = 0 after.
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open Set

/-- Divide by the unknown's part and integrate both sides. Take a rate law `y' = g(t) h(y)` and
an open interval `(a, b)` of times on which `y` has a slope and `h(y(t))` is never zero. Let `G`
be an antiderivative of `g` there, and let `H` have slope `1 / h` at every value `y` takes there.
Then `y` solves the law on the interval exactly when `H(y(t)) = G(t) + C` for one constant `C`
and every `t` in the interval. -/
theorem separable_iff_integrated (g h y G H : ℝ → ℝ) (a b : ℝ)
    (hy : ∀ t ∈ Ioo a b, DifferentiableAt ℝ y t)
    (hh : ∀ t ∈ Ioo a b, h (y t) ≠ 0)
    (hG : ∀ t ∈ Ioo a b, HasDerivAt G (g t) t)
    (hH : ∀ t ∈ Ioo a b, HasDerivAt H (1 / h (y t)) (y t)) :
    (∀ t ∈ Ioo a b, HasDerivAt y (g t * h (y t)) t) ↔
      ∃ C : ℝ, ∀ t ∈ Ioo a b, H (y t) = G t + C := by
  have hcomp : ∀ t ∈ Ioo a b, HasDerivAt (H ∘ y) (1 / h (y t) * deriv y t) t := fun t ht =>
    (hH t ht).comp t (hy t ht).hasDerivAt
  constructor
  · intro hlaw
    have hdiff : DifferentiableOn ℝ (H ∘ y) (Ioo a b) := fun t ht =>
      (hcomp t ht).differentiableAt.differentiableWithinAt
    have hGd : DifferentiableOn ℝ G (Ioo a b) := fun t ht =>
      (hG t ht).differentiableAt.differentiableWithinAt
    obtain ⟨C, hC⟩ := isOpen_Ioo.exists_eq_add_of_deriv_eq isPreconnected_Ioo hdiff hGd
      (fun t ht => by
        rw [(hcomp t ht).deriv, (hG t ht).deriv, (hlaw t ht).deriv]
        field_simp [hh t ht])
    exact ⟨C, fun t ht => hC ht⟩
  · rintro ⟨C, hC⟩ t ht
    have h1 : HasDerivAt (fun s => G s + C) (g t) t := (hG t ht).add_const C
    have heq : (H ∘ y) =ᶠ[nhds t] (fun s => G s + C) :=
      Filter.eventually_of_mem (isOpen_Ioo.mem_nhds ht) (fun s hs => hC s hs)
    have h2 : HasDerivAt (fun s => G s + C) (1 / h (y t) * deriv y t) t :=
      (hcomp t ht).congr_of_eventuallyEq heq.symm
    have h3 : 1 / h (y t) * deriv y t = g t := h2.unique h1
    have h4 : deriv y t = g t * h (y t) := by
      rw [← h3]; field_simp [hh t ht]
    rw [← h4]
    exact (hy t ht).hasDerivAt

/-- Put back what the division lost. Every zero `c` of `h` gives a constant solution: `y` held at
`c` for all time obeys `y' = g(t) h(y)`, whatever the time part `g` is. -/
theorem zero_of_h_is_constant_solution (g h : ℝ → ℝ) (c : ℝ) (hc : h c = 0) (t : ℝ) :
    HasDerivAt (fun _ : ℝ => c) (g t * h c) t := by
  rw [hc, mul_zero]
  exact hasDerivAt_const t c

/-- The snowball. The volume `V(t) = (max(10 - t/10, 0))^3`, which follows the separated formula
`(10 - t/10)^3` until 100 minutes and the lost constant solution `V = 0` after, starts at
1000 cm^3 and obeys the melting law `V' = -(3/10) V^(2/3)` at every time, the seam at 100 minutes
included. -/
theorem snowball_follows_formula_then_puddle (V : ℝ → ℝ)
    (hV : ∀ t, V t = max (10 - t / 10) 0 ^ 3) :
    V 0 = 1000 ∧
      (∀ t, HasDerivAt V (-(3 / 10) * V t ^ ((2 : ℝ) / 3)) t) ∧
      (∀ t ≤ 100, V t = (10 - t / 10) ^ 3) ∧
      (∀ t ≥ 100, V t = 0) := by
  have hle : ∀ t ≤ 100, V t = (10 - t / 10) ^ 3 := by
    intro t ht
    rw [hV, max_eq_left (by linarith)]
  have hge : ∀ t ≥ 100, V t = 0 := by
    intro t ht
    rw [hV, max_eq_right (by linarith)]
    norm_num
  have hpoly : ∀ t, HasDerivAt (fun s : ℝ => (10 - s / 10) ^ 3)
      (-(3 / 10) * (10 - t / 10) ^ 2) t := by
    intro t
    have h0 : HasDerivAt (fun s : ℝ => 10 - s / 10) (-(1 / 10)) t := by
      have := ((hasDerivAt_id t).div_const 10).const_sub 10
      simpa using this
    have := h0.pow 3
    convert this using 1
    push_cast
    ring
  refine ⟨?_, ?_, hle, hge⟩
  · rw [hle 0 (by norm_num)]; norm_num
  · intro t
    rcases lt_trichotomy t 100 with h | h | h
    · have hu : 0 ≤ 10 - t / 10 := by linarith
      have hpow : V t ^ ((2 : ℝ) / 3) = (10 - t / 10) ^ 2 := by
        rw [hle t h.le, ← Real.rpow_natCast, ← Real.rpow_mul hu]
        norm_num
      rw [hpow]
      have heq : V =ᶠ[nhds t] (fun s : ℝ => (10 - s / 10) ^ 3) :=
        Filter.eventually_of_mem (isOpen_Iio.mem_nhds h) (fun s hs => hle s (le_of_lt hs))
      exact (hpoly t).congr_of_eventuallyEq heq
    · subst h
      have h0 : V 100 = 0 := hge 100 le_rfl
      have hval : -(3 / 10) * V 100 ^ ((2 : ℝ) / 3) = 0 := by
        rw [h0, Real.zero_rpow (by norm_num)]; ring
      rw [hval]
      have hL : HasDerivWithinAt V 0 (Iic 100) 100 := by
        have := (hpoly 100).hasDerivWithinAt (s := Iic 100)
        have hz : -(3 / 10) * (10 - (100 : ℝ) / 10) ^ 2 = 0 := by norm_num
        rw [hz] at this
        exact this.congr (fun s hs => hle s hs) (hle 100 le_rfl)
      have hR : HasDerivWithinAt V 0 (Ici 100) 100 := by
        have := (hasDerivAt_const (100 : ℝ) (0 : ℝ)).hasDerivWithinAt (s := Ici 100)
        exact this.congr (fun s hs => hge s hs) (hge 100 le_rfl)
      have := hL.union hR
      rw [Iic_union_Ici, hasDerivWithinAt_univ] at this
      exact this
    · have h0 : V t = 0 := hge t h.le
      have hval : -(3 / 10) * V t ^ ((2 : ℝ) / 3) = 0 := by
        rw [h0, Real.zero_rpow (by norm_num)]; ring
      rw [hval]
      have heq : V =ᶠ[nhds t] (fun _ : ℝ => (0 : ℝ)) :=
        Filter.eventually_of_mem (isOpen_Ioi.mem_nhds h) (fun s hs => hge s (le_of_lt hs))
      exact (hasDerivAt_const t (0 : ℝ)).congr_of_eventuallyEq heq

-- The constant from the start: 3 × 1000^(1/3) = 3 × 10 = 30, since 10^3 = 1000.
example : (10 : ℕ) ^ 3 = 1000 ∧ 3 * 10 = 30 := by norm_num

-- The rate at the start: 0.3 × 1000^(2/3) = 3/10 × 10^2 = 30 cm^3 a minute.
example : (3 / 10 : ℚ) * 10 ^ 2 = 30 := by norm_num

-- The volume every 10 minutes, t = 10 i: (10 - 0.1 t)^3 = (10 - i)^3, from 1000 down to 0 at 100 minutes.
example : (List.range 11).map (fun i : ℕ => (10 - (i : ℤ)) ^ 3) =
    [1000, 729, 512, 343, 216, 125, 64, 27, 8, 1, 0] := by decide

-- At 50 minutes: (10 - 5)^3 = 125 cm^3.
example : ((10 : ℚ) - 1 / 10 * 50) ^ 3 = 125 := by norm_num

-- All gone at 100 minutes: 10 - 0.1 × 100 = 0.
example : (10 : ℚ) - 1 / 10 * 100 = 0 := by norm_num

-- The formula pushed past 100 minutes: -1 cm^3 at 110 and -8 cm^3 at 120.
example : ((10 : ℚ) - 1 / 10 * 110) ^ 3 = -1 ∧ ((10 : ℚ) - 1 / 10 * 120) ^ 3 = -8 := by norm_num

-- The mistake of adding the constant after cubing: 1000 - (0.1 × 50)^3 = 875.
example : (1000 : ℚ) - (1 / 10 * 50) ^ 3 = 875 := by norm_num

#print axioms separable_iff_integrated
#print axioms zero_of_h_is_constant_solution
#print axioms snowball_follows_formula_then_puddle
