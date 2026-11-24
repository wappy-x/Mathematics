-- Invariant manifolds: a graph y = h(x) that satisfies the invariance equation h' f = g carries paths of the system, the saddle's gap y - x^2/3 shrinks like e^-t, and the centre curve's reduced equation x' = -x^3 - 2x^5 drives x to 0.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.Order.DenselyOrdered
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

open Filter Topology

/-- The invariance equation. For the planar system x' = f(x, y), y' = g(x, y), if the
smooth curve y = h(x) satisfies h'(x) f(x, h(x)) = g(x, h(x)) for every x, then solving
x' = f(x, h(x)) and setting y = h(x) gives a solution of the full system: the velocity
points along the curve, so the path moves along it. -/
theorem graph_solves_system_of_invariance_equation
    (f g : ℝ → ℝ → ℝ) (h h' : ℝ → ℝ)
    (hh : ∀ x, HasDerivAt h (h' x) x)
    (hinv : ∀ x, h' x * f x (h x) = g x (h x))
    (X : ℝ → ℝ) (hX : ∀ t, HasDerivAt X (f (X t) (h (X t))) t) :
    ∀ t, HasDerivAt (fun s => h (X s)) (g (X t) (h (X t))) t := by
  intro t
  have := (hh (X t)).comp t (hX t)
  rw [hinv] at this
  exact this

/-- The saddle x' = x, y' = -y + x^2. Along every path, the gap z = y - x^2/3 above the
unstable manifold y = x^2/3 obeys z' = -z, so z(t) = z(0) e^(-t): a path on the curve
stays on it, and every other path falls onto it. -/
theorem saddle_gap_decays_exponentially
    (x y : ℝ → ℝ)
    (hx : ∀ t, HasDerivAt x (x t) t)
    (hy : ∀ t, HasDerivAt y (-(y t) + (x t) ^ 2) t) (t : ℝ) :
    y t - (x t) ^ 2 / 3 = (y 0 - (x 0) ^ 2 / 3) * Real.exp (-t) := by
  have hF : ∀ s, HasDerivAt (fun s => (y s - (x s) ^ 2 / 3) * Real.exp s) 0 s := by
    intro s
    have h1 := (((hy s).sub (((hx s).pow 2).div_const 3)).mul (Real.hasDerivAt_exp s))
    convert h1 using 1
    simp only [Pi.sub_apply, Pi.pow_apply]
    push_cast
    ring
  have hc := is_const_of_deriv_eq_zero (fun s => (hF s).differentiableAt)
    (fun s => (hF s).deriv) t 0
  simp only [Real.exp_zero, mul_one] at hc
  rw [← hc, mul_assoc, ← Real.exp_add, add_neg_cancel, Real.exp_zero, mul_one]

/-- The reduced equation on the centre curve of x' = xy, y' = -y - x^2, cut off after the
x^5 term: x' = -x^3 - 2x^5. Every solution that runs for all t ≥ 0 tends to 0, so the
rest attracts (the Lyapunov score V = x^2/2 only falls). -/
theorem reduced_centre_equation_attracts
    (x : ℝ → ℝ)
    (hx : ∀ t, 0 ≤ t → HasDerivAt x (-(x t) ^ 3 - 2 * (x t) ^ 5) t) :
    Tendsto x atTop (𝓝 0) := by
  -- V = x^2 is antitone on [0, ∞)
  have hV : ∀ s, 0 ≤ s → HasDerivAt (fun s => (x s) ^ 2)
      (2 * (x s) * (-(x s) ^ 3 - 2 * (x s) ^ 5)) s := by
    intro s hs
    have := (hx s hs).pow 2
    convert this using 1
    push_cast
    ring
  have hanti : AntitoneOn (fun s => (x s) ^ 2) (Set.Ici 0) := by
    apply antitoneOn_of_deriv_nonpos (convex_Ici 0)
    · intro s hs
      exact (hV s hs).continuousAt.continuousWithinAt
    · intro s hs
      rw [interior_Ici] at hs
      exact (hV s (le_of_lt hs)).differentiableAt.differentiableWithinAt
    · intro s hs
      rw [interior_Ici] at hs
      rw [(hV s (le_of_lt hs)).deriv]
      nlinarith [pow_two_nonneg ((x s) ^ 2), pow_two_nonneg ((x s) ^ 3)]
  rw [Metric.tendsto_atTop]
  intro ε hε
  set e := ε ^ 2 with he
  have hepos : 0 < e := by positivity
  refine ⟨(x 0) ^ 2 / (2 * e ^ 2) + 1, ?_⟩
  intro n hn
  have hN0 : 0 ≤ (x 0) ^ 2 / (2 * e ^ 2) := by positivity
  have hn0 : 0 ≤ n := by linarith
  have hlt : (x n) ^ 2 < e := by
    by_contra hcon'
    have hcon := not_lt.mp hcon'
    have hge : ∀ s ∈ Set.Icc (0 : ℝ) n, e ≤ (x s) ^ 2 := by
      intro s hs
      exact le_trans hcon (hanti hs.1 hn0 hs.2)
    have hG : ∀ s, 0 ≤ s → HasDerivAt (fun s => (x s) ^ 2 + 2 * e ^ 2 * s)
        (2 * (x s) * (-(x s) ^ 3 - 2 * (x s) ^ 5) + 2 * e ^ 2) s := by
      intro s hs
      have := (hV s hs).add ((hasDerivAt_id s).const_mul (2 * e ^ 2))
      convert this using 1
      · funext u
        simp
      · ring
    have hGanti : AntitoneOn (fun s => (x s) ^ 2 + 2 * e ^ 2 * s) (Set.Icc 0 n) := by
      apply antitoneOn_of_deriv_nonpos (convex_Icc 0 n)
      · intro s hs
        exact (hG s hs.1).continuousAt.continuousWithinAt
      · intro s hs
        rw [interior_Icc] at hs
        exact (hG s (le_of_lt hs.1)).differentiableAt.differentiableWithinAt
      · intro s hs
        rw [interior_Icc] at hs
        rw [(hG s (le_of_lt hs.1)).deriv]
        have h1 := hge s ⟨le_of_lt hs.1, le_of_lt hs.2⟩
        have h2 : e ^ 2 ≤ ((x s) ^ 2) ^ 2 := by
          exact pow_le_pow_left₀ (le_of_lt hepos) h1 2
        nlinarith [pow_two_nonneg ((x s) ^ 3)]
    have key := hGanti ⟨le_refl 0, hn0⟩ ⟨hn0, le_refl n⟩ hn0
    simp only [mul_zero, add_zero] at key
    have h3 : (x 0) ^ 2 / (2 * e ^ 2) * (2 * e ^ 2) = (x 0) ^ 2 := by
      field_simp
    have h4 : 0 < 2 * e ^ 2 := by positivity
    nlinarith
  rw [Real.dist_eq, sub_zero]
  rw [he] at hlt
  exact abs_lt_of_sq_lt_sq' hlt (le_of_lt hε) |> fun h => abs_lt.mpr h

-- Saddle, Step 1: (2 + 1) a_2 = 1 gives a_2 = 1/3.
example : ((2 : ℚ) + 1) * (1 / 3) = 1 := by norm_num

-- Saddle: y = x^2/3 satisfies the invariance equation x h'(x) = -h(x) + x^2 exactly.
example (x : ℚ) : x * (2 * x / 3) = -(x ^ 2 / 3) + x ^ 2 := by ring

-- Centre curve, Step 3: matching powers gives a_2 = -1, a_4 = -2, a_6 = -12, a_8 = -112.
-- x^2: 0 = -a_2 - 1
example : (0 : ℤ) = -(-1) - 1 := by norm_num
-- x^4: 2 a_2 a_2 = -a_4
example : (2 : ℤ) * (-1) * (-1) = -(-2) := by norm_num
-- x^6: 2 a_2 a_4 + 4 a_4 a_2 = -a_6
example : (2 : ℤ) * (-1) * (-2) + 4 * (-2) * (-1) = -(-12) := by norm_num
-- x^8: 2 a_2 a_6 + 4 a_4 a_4 + 6 a_6 a_2 = -a_8
example : (2 : ℤ) * (-1) * (-12) + 4 * (-2) * (-2) + 6 * (-12) * (-1) = -(-112) := by norm_num

-- The twin y' = -y + x^2: x^2 gives 0 = -a_2 + 1, so a_2 = 1; x^4 gives 2 a_2 a_2 = -a_4, so a_4 = -2.
example : (0 : ℤ) = -1 + 1 := by norm_num
example : (2 : ℤ) * 1 * 1 = -(-2) := by norm_num

#print axioms graph_solves_system_of_invariance_equation
#print axioms saddle_gap_decays_exponentially
#print axioms reduced_centre_equation_attracts
