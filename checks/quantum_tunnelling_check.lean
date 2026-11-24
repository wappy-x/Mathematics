-- Tunnelling: for a flat wall of height V₀ and width a met at energy 0 < E < V₀, the four matching equations force the chance of getting through to be T = 1 / (1 + V₀² sinh²(κa) / (4E(V₀ − E))), the chances of bouncing back and getting through add to 1, and for a thick wall T is 16E(V₀ − E)/V₀² times e^(−2κa).
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Complex.Trigonometric

open Filter Topology

lemma tunnelling_key (k κ X Y : ℝ) (hXY : X * Y = 1) (P r C D t : ℂ)
    (hP : Complex.normSq P = 1)
    (h₁ : 1 + r = C + D)
    (h₂ : Complex.I * (k : ℂ) * (1 - r) = (κ : ℂ) * (C - D))
    (h₃ : C * (X : ℂ) + D * (Y : ℂ) = t * P)
    (h₄ : (κ : ℂ) * (C * (X : ℂ) - D * (Y : ℂ)) = Complex.I * (k : ℂ) * t * P) :
    Complex.normSq t * ((κ ^ 2 + k ^ 2) ^ 2 * (X - Y) ^ 2 + 16 * k ^ 2 * κ ^ 2) =
        16 * k ^ 2 * κ ^ 2 ∧
      Complex.normSq r * (16 * k ^ 2 * κ ^ 2) =
        Complex.normSq t * ((κ ^ 2 + k ^ 2) ^ 2 * (X - Y) ^ 2) := by
  have hXYc : (X : ℂ) * (Y : ℂ) = 1 := by exact_mod_cast hXY
  have e1 : 2 * κ * C * X = t * P * (κ + Complex.I * k) := by linear_combination κ * h₃ + h₄
  have e2 : 2 * κ * D * Y = t * P * (κ - Complex.I * k) := by linear_combination κ * h₃ - h₄
  have e3 : 2 * Complex.I * k = (Complex.I * k + κ) * C + (Complex.I * k - κ) * D := by
    linear_combination Complex.I * k * h₁ + h₂
  have e4 : 2 * Complex.I * k * r = (Complex.I * k - κ) * C + (Complex.I * k + κ) * D := by
    linear_combination Complex.I * k * h₁ - h₂
  have f1 : ((4 * k * κ : ℝ) : ℂ) * Complex.I =
      t * P * ((((κ ^ 2 - k ^ 2) * (Y - X) : ℝ) : ℂ) + ((2 * κ * k * (X + Y) : ℝ) : ℂ) * Complex.I) := by
    push_cast
    linear_combination 2 * κ * e3 + (Complex.I * k + κ) * Y * e1 + (Complex.I * k - κ) * X * e2
      - ((Complex.I * k + κ) * 2 * κ * C + (Complex.I * k - κ) * 2 * κ * D) * hXYc
      + t * P * k ^ 2 * (Y - X) * Complex.I_sq
  have g1 : ((4 * k * κ : ℝ) : ℂ) * Complex.I * r =
      t * P * (((κ ^ 2 + k ^ 2) * (X - Y) : ℝ) : ℂ) := by
    push_cast
    linear_combination 2 * κ * e4 + (Complex.I * k - κ) * Y * e1 + (Complex.I * k + κ) * X * e2
      - ((Complex.I * k - κ) * 2 * κ * C + (Complex.I * k + κ) * 2 * κ * D) * hXYc
      + t * P * k ^ 2 * (Y - X) * Complex.I_sq
  have n1 := congrArg Complex.normSq f1
  have n2 := congrArg Complex.normSq g1
  simp only [Complex.normSq_mul, Complex.normSq_add_mul_I, Complex.normSq_ofReal,
    Complex.normSq_I, hP] at n1 n2
  constructor
  · linear_combination -n1 - 16 * Complex.normSq t * k ^ 2 * κ ^ 2 * hXY
  · linear_combination n2

lemma tunnelling_setup (K E V₀ a : ℝ) (hK : 0 < K) (hE : 0 < E) (hEV : E < V₀)
    (r C D t : ℂ)
    (h₁ : 1 + r = C + D)
    (h₂ : Complex.I * (Real.sqrt (K * E) : ℂ) * (1 - r) =
      (Real.sqrt (K * (V₀ - E)) : ℂ) * (C - D))
    (h₃ : C * Complex.exp ((Real.sqrt (K * (V₀ - E)) * a : ℝ)) +
        D * Complex.exp (-((Real.sqrt (K * (V₀ - E)) * a : ℝ) : ℂ)) =
      t * Complex.exp (Complex.I * ((Real.sqrt (K * E) * a : ℝ) : ℂ)))
    (h₄ : (Real.sqrt (K * (V₀ - E)) : ℂ) *
        (C * Complex.exp ((Real.sqrt (K * (V₀ - E)) * a : ℝ)) -
          D * Complex.exp (-((Real.sqrt (K * (V₀ - E)) * a : ℝ) : ℂ))) =
      Complex.I * (Real.sqrt (K * E) : ℂ) * t *
        Complex.exp (Complex.I * ((Real.sqrt (K * E) * a : ℝ) : ℂ))) :
    Complex.normSq t * ((K * V₀) ^ 2 * (2 * Real.sinh (Real.sqrt (K * (V₀ - E)) * a)) ^ 2
        + 16 * (K * E) * (K * (V₀ - E))) = 16 * (K * E) * (K * (V₀ - E)) ∧
      Complex.normSq r * (16 * (K * E) * (K * (V₀ - E))) =
        Complex.normSq t * ((K * V₀) ^ 2 * (2 * Real.sinh (Real.sqrt (K * (V₀ - E)) * a)) ^ 2) := by
  set k := Real.sqrt (K * E)
  set κ := Real.sqrt (K * (V₀ - E))
  have hk2 : k ^ 2 = K * E := Real.sq_sqrt (by nlinarith)
  have hκ2 : κ ^ 2 = K * (V₀ - E) := Real.sq_sqrt (by nlinarith)
  have hP : Complex.normSq (Complex.exp (Complex.I * ((k * a : ℝ) : ℂ))) = 1 := by
    rw [mul_comm, Complex.normSq_eq_norm_sq, Complex.norm_exp_ofReal_mul_I]; norm_num
  rw [← Complex.ofReal_neg, ← Complex.ofReal_exp, ← Complex.ofReal_exp] at h₃ h₄
  have hXY : Real.exp (κ * a) * Real.exp (-(κ * a)) = 1 := by
    rw [← Real.exp_add]; simp
  obtain ⟨c1, c2⟩ := tunnelling_key k κ _ _ hXY _ r C D t hP h₁ h₂ h₃ h₄
  have hs : 2 * Real.sinh (κ * a) = Real.exp (κ * a) - Real.exp (-(κ * a)) := by
    rw [Real.sinh_eq]; ring
  rw [hs, show K * V₀ = κ ^ 2 + k ^ 2 by rw [hk2, hκ2]; ring, ← hk2, ← hκ2]
  constructor
  · linear_combination c1
  · linear_combination c2

#print axioms tunnelling_key
#print axioms tunnelling_setup

/-- **The exact chance of getting through a flat wall.** Write Schrodinger's equation as
`ψ'' = K (V − E) ψ` with `K = 2m/ħ² > 0`, and let the wall be `V = V₀` for `0 < x < a`,
`V = 0` elsewhere. The electron is below the top, `0 < E < V₀`. Outside the wall the wave
turns at `k = √(K E)`, inside it dies away at the rate `κ = √(K (V₀ − E))`, and the wave is
`e^{ikx} + r e^{−ikx}` on the left, `C e^{κx} + D e^{−κx}` inside, `t e^{ikx}` on the right.
If the wave and its slope agree at both faces `x = 0` and `x = a` (the four matching
equations), then the chance of getting through, `T = |t|²`, is
`T = 1 / (1 + V₀² sinh²(κa) / (4E(V₀ − E)))`. -/
theorem tunnelling_transmission_eq (K E V₀ a : ℝ) (hK : 0 < K) (hE : 0 < E) (hEV : E < V₀)
    (r C D t : ℂ)
    (h₁ : 1 + r = C + D)
    (h₂ : Complex.I * (Real.sqrt (K * E) : ℂ) * (1 - r) =
      (Real.sqrt (K * (V₀ - E)) : ℂ) * (C - D))
    (h₃ : C * Complex.exp ((Real.sqrt (K * (V₀ - E)) * a : ℝ)) +
        D * Complex.exp (-((Real.sqrt (K * (V₀ - E)) * a : ℝ) : ℂ)) =
      t * Complex.exp (Complex.I * ((Real.sqrt (K * E) * a : ℝ) : ℂ)))
    (h₄ : (Real.sqrt (K * (V₀ - E)) : ℂ) *
        (C * Complex.exp ((Real.sqrt (K * (V₀ - E)) * a : ℝ)) -
          D * Complex.exp (-((Real.sqrt (K * (V₀ - E)) * a : ℝ) : ℂ))) =
      Complex.I * (Real.sqrt (K * E) : ℂ) * t *
        Complex.exp (Complex.I * ((Real.sqrt (K * E) * a : ℝ) : ℂ))) :
    Complex.normSq t =
      1 / (1 + V₀ ^ 2 * Real.sinh (Real.sqrt (K * (V₀ - E)) * a) ^ 2 / (4 * E * (V₀ - E))) := by
  obtain ⟨c1, -⟩ := tunnelling_setup K E V₀ a hK hE hEV r C D t h₁ h₂ h₃ h₄
  set s := Real.sinh (Real.sqrt (K * (V₀ - E)) * a)
  have hd : 0 < 4 * E * (V₀ - E) := by have := sub_pos.2 hEV; positivity
  have h' : Complex.normSq t * (V₀ ^ 2 * s ^ 2 + 4 * E * (V₀ - E)) = 4 * E * (V₀ - E) := by
    have hK2 : (0 : ℝ) < 4 * K ^ 2 := by positivity
    apply mul_left_cancel₀ hK2.ne'
    linear_combination c1
  have hq : 0 ≤ V₀ ^ 2 * s ^ 2 / (4 * E * (V₀ - E)) := div_nonneg (by positivity) hd.le
  rw [eq_div_iff (by linarith)]
  field_simp
  linear_combination h'

/-- **Nothing is lost: R + T = 1.** Under the same wall, energy and matching equations, the
chance of bouncing back, `R = |r|²`, and the chance of getting through, `T = |t|²`, add to 1. -/
theorem tunnelling_reflection_add_transmission (K E V₀ a : ℝ) (hK : 0 < K) (hE : 0 < E)
    (hEV : E < V₀) (r C D t : ℂ)
    (h₁ : 1 + r = C + D)
    (h₂ : Complex.I * (Real.sqrt (K * E) : ℂ) * (1 - r) =
      (Real.sqrt (K * (V₀ - E)) : ℂ) * (C - D))
    (h₃ : C * Complex.exp ((Real.sqrt (K * (V₀ - E)) * a : ℝ)) +
        D * Complex.exp (-((Real.sqrt (K * (V₀ - E)) * a : ℝ) : ℂ)) =
      t * Complex.exp (Complex.I * ((Real.sqrt (K * E) * a : ℝ) : ℂ)))
    (h₄ : (Real.sqrt (K * (V₀ - E)) : ℂ) *
        (C * Complex.exp ((Real.sqrt (K * (V₀ - E)) * a : ℝ)) -
          D * Complex.exp (-((Real.sqrt (K * (V₀ - E)) * a : ℝ) : ℂ))) =
      Complex.I * (Real.sqrt (K * E) : ℂ) * t *
        Complex.exp (Complex.I * ((Real.sqrt (K * E) * a : ℝ) : ℂ))) :
    Complex.normSq r + Complex.normSq t = 1 := by
  obtain ⟨c1, c2⟩ := tunnelling_setup K E V₀ a hK hE hEV r C D t h₁ h₂ h₃ h₄
  have hpos : 0 < 16 * (K * E) * (K * (V₀ - E)) := by have := sub_pos.2 hEV; positivity
  apply mul_right_cancel₀ hpos.ne'
  linear_combination c2 + c1

/-- **A thick wall gives a plain exponential.** For `0 < E < V₀` and `κ = √(K (V₀ − E))`, the
exact chance `T(a) = 1 / (1 + V₀² sinh²(κa) / (4E(V₀ − E)))` divided by the WKB exponential
`e^{−2κa}` tends to the fixed factor `16E(V₀ − E)/V₀²` as the width `a` grows: for a thick
wall, `T ≈ 16E(V₀ − E)/V₀² · e^{−2κa}`. -/
theorem tunnelling_thick_wall_limit (K E V₀ : ℝ) (hK : 0 < K) (hE : 0 < E) (hEV : E < V₀) :
    Tendsto (fun a : ℝ =>
        1 / (1 + V₀ ^ 2 * Real.sinh (Real.sqrt (K * (V₀ - E)) * a) ^ 2 / (4 * E * (V₀ - E))) *
          Real.exp (2 * Real.sqrt (K * (V₀ - E)) * a))
      atTop (𝓝 (16 * E * (V₀ - E) / V₀ ^ 2)) := by
  set κ := Real.sqrt (K * (V₀ - E))
  have hκ : 0 < κ := Real.sqrt_pos.2 (mul_pos hK (sub_pos.2 hEV))
  have hM : 0 < 4 * E * (V₀ - E) := by have := sub_pos.2 hEV; positivity
  have hV : 0 < V₀ := by linarith
  set M := 4 * E * (V₀ - E) with hMdef
  set g : ℝ → ℝ := fun u => 1 / (u + V₀ ^ 2 * (1 - u) ^ 2 / (4 * M)) with hgdef
  have hu : Tendsto (fun a : ℝ => (Real.exp (2 * κ * a))⁻¹) atTop (𝓝 0) :=
    tendsto_inv_atTop_zero.comp
      (Real.tendsto_exp_atTop.comp (tendsto_id.const_mul_atTop (by positivity : 0 < 2 * κ)))
  have hg : Tendsto g (𝓝 0) (𝓝 (g 0)) := by
    have hc : ContinuousAt (fun u : ℝ => u + V₀ ^ 2 * (1 - u) ^ 2 / (4 * M)) 0 := by fun_prop
    have hne : (0 : ℝ) + V₀ ^ 2 * (1 - 0) ^ 2 / (4 * M) ≠ 0 := by positivity
    exact (continuousAt_const.div hc hne).tendsto
  have hlim := hg.comp hu
  have hg0 : g 0 = 16 * E * (V₀ - E) / V₀ ^ 2 := by
    simp only [hgdef, hMdef]; field_simp; ring
  rw [hg0] at hlim
  refine hlim.congr' (Eventually.of_forall fun a => ?_)
  simp only [Function.comp, hgdef]
  have hX : 0 < Real.exp (κ * a) := Real.exp_pos _
  rw [show 2 * κ * a = κ * a + κ * a by ring, Real.exp_add, Real.sinh_eq, Real.exp_neg]
  field_simp
  ring

-- The card's example, E = 1 eV and V₀ = 2 eV: the factor V₀² / (4E(V₀ − E)) is exactly 1.
example : ((2 : ℚ) ^ 2 / (4 * 1 * (2 - 1)) = 1) := by norm_num

-- The thick-wall factor 16E(V₀ − E)/V₀² is exactly 4 for that example.
example : ((16 : ℚ) * 1 * (2 - 1) / 2 ^ 2 = 4) := by norm_num

-- Of 1,000,000 electrons, 23,547 get through and 976,453 bounce back: none are lost.
example : (23547 : ℕ) + 976453 = 1000000 := by norm_num

#print axioms tunnelling_transmission_eq
#print axioms tunnelling_reflection_add_transmission
#print axioms tunnelling_thick_wall_limit
