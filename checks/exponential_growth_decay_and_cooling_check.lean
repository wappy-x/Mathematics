-- Growth, decay and cooling: a function whose rate is always k times itself is exactly its starting value times e^(kt), a body cooling at k times its gap from a fixed room is exactly the room plus the starting gap times e^(kt), and the amount halves (k < 0) or doubles (k > 0) over every stretch of length ln 2 / |k|.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Tactic.NormNum

open Real

theorem exp_ode_unique (k : ℝ) (y : ℝ → ℝ) (hy : ∀ t, HasDerivAt y (k * y t) t) :
    ∀ t, y t = y 0 * exp (k * t) := by
  have hg : ∀ t, HasDerivAt (fun s => y s * exp (-(k * s))) 0 t := by
    intro t
    have h1 : HasDerivAt (fun s => -(k * s)) (-(k * 1)) t :=
      ((hasDerivAt_id t).const_mul k).neg
    have h2 := h1.exp
    convert (hy t).mul h2 using 1
    ring
  have hc : ∀ t, y t * exp (-(k * t)) = y 0 * exp (-(k * 0)) := by
    intro t
    exact is_const_of_deriv_eq_zero
      (fun s => (hg s).differentiableAt) (fun s => (hg s).deriv) t 0
  intro t
  have := hc t
  simp only [mul_zero, neg_zero, exp_zero, mul_one] at this
  have he : exp (-(k * t)) * exp (k * t) = 1 := by
    rw [← exp_add]; simp
  calc y t = y t * (exp (-(k * t)) * exp (k * t)) := by rw [he, mul_one]
    _ = (y t * exp (-(k * t))) * exp (k * t) := by ring
    _ = y 0 * exp (k * t) := by rw [this]

#print axioms exp_ode_unique

/-- Growth and decay. For a fixed rate constant k, a quantity y has rate k times itself at every
time and starts at y0 exactly when it is y0 times e^(kt) at every time: the exponential is a
solution, and there is no other. -/
theorem rate_proportional_to_amount_iff_exponential (k y0 : ℝ) (y : ℝ → ℝ) :
    ((∀ t, HasDerivAt y (k * y t) t) ∧ y 0 = y0) ↔ ∀ t, y t = y0 * exp (k * t) := by
  constructor
  · rintro ⟨hy, h0⟩ t
    rw [exp_ode_unique k y hy t, h0]
  · intro h
    have hfun : y = fun t => y0 * exp (k * t) := funext h
    subst hfun
    refine ⟨fun t => ?_, by simp⟩
    have h1 : HasDerivAt (fun s => k * s) (k * 1) t := (hasDerivAt_id t).const_mul k
    convert h1.exp.const_mul y0 using 1
    ring

/-- Newton's law of cooling. With the room held at one temperature A, a temperature T whose rate
is always k times its gap from the room, T - A, and which starts at T0, is exactly the room plus
the starting gap shrunk by the exponential: T(t) = A + (T0 - A) e^(kt), and nothing else. -/
theorem cooling_iff_room_plus_exponential_gap (k A T0 : ℝ) (T : ℝ → ℝ) :
    ((∀ t, HasDerivAt T (k * (T t - A)) t) ∧ T 0 = T0) ↔
      ∀ t, T t = A + (T0 - A) * exp (k * t) := by
  have key := rate_proportional_to_amount_iff_exponential k (T0 - A) (fun t => T t - A)
  constructor
  · rintro ⟨hT, h0⟩ t
    have := key.mp ⟨fun s => by simpa using (hT s).sub_const A, by simp [h0]⟩ t
    linarith
  · intro h
    have h' : ∀ t, (fun t => T t - A) t = (T0 - A) * exp (k * t) := by
      intro t; show T t - A = _; rw [h t]; ring
    obtain ⟨hd, h0⟩ := key.mpr h'
    refine ⟨fun t => ?_, ?_⟩
    · have := (hd t).add_const A
      simpa using this
    · have h0' : T 0 - A = T0 - A := h0
      linarith

/-- Half-life and doubling time. If y has rate k times itself, then over any stretch of length
ln 2 / (-k) it halves when k < 0, and over any stretch of length ln 2 / k it doubles when k > 0,
whenever the stretch starts. -/
theorem half_life_and_doubling_time (k : ℝ) (y : ℝ → ℝ) (hy : ∀ t, HasDerivAt y (k * y t) t) :
    (k < 0 → ∀ t, y (t + log 2 / (-k)) = y t / 2) ∧
      (0 < k → ∀ t, y (t + log 2 / k) = 2 * y t) := by
  have he := exp_ode_unique k y hy
  constructor
  · intro hk t
    rw [he (t + _), he t, mul_add, exp_add]
    have : k * (log 2 / (-k)) = -log 2 := by
      have hk' : k ≠ 0 := hk.ne
      rw [div_neg, mul_neg, mul_div_cancel₀ _ hk']
    rw [this, exp_neg, exp_log (by norm_num)]
    ring
  · intro hk t
    rw [he (t + _), he t, mul_add, exp_add]
    have : k * (log 2 / k) = log 2 := mul_div_cancel₀ _ hk.ne'
    rw [this, exp_log (by norm_num)]
    ring

-- The account: 4% of 5,000 dollars is 200 dollars a year at the start.
example : (5000 : ℚ) * 4 / 100 = 200 := by norm_num
-- The coffee: the gap starts at 80 - 20 = 60 C; one half-life halves it to 30, so the coffee is at 50 C.
example : (80 : ℤ) - 20 = 60 := by norm_num
example : (20 : ℚ) + 60 / 2 = 50 := by norm_num

#print axioms rate_proportional_to_amount_iff_exponential
#print axioms cooling_iff_room_plus_exponential_gap
#print axioms half_life_and_doubling_time
