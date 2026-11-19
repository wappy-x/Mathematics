-- Noether: in coordinates on a configuration space, if a field X keeps the kinetic-energy metric (Killing equation) and the potential (XV = 0) at the poses a motion passes through, the momentum g(q', X) paired with X stays constant along that motion.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Real

theorem noether_rate_algebra {n : ℕ} (G : Fin n → Fin n → ℝ) (hG : ∀ a b, G a b = G b a)
    (dg : Fin n → Fin n → Fin n → ℝ) (dX : Fin n → Fin n → ℝ) (x w dV : Fin n → ℝ) :
    ∑ i, (((1 / 2) * ∑ a, ∑ b, dg a b i * w a * w b - dV i) * x i
        + (∑ j, G i j * w j) * ∑ a, w a * dX i a)
      = (1 / 2) * ∑ a, ∑ b, (∑ i, (x i * dg a b i + G i b * dX i a + G a i * dX i b)) * w a * w b
        - ∑ i, x i * dV i := by
  have h1 : ∑ a, ∑ b, (∑ i, x i * dg a b i) * w a * w b
      = ∑ i, x i * ∑ a, ∑ b, dg a b i * w a * w b := by
    simp only [Finset.sum_mul, Finset.mul_sum]
    conv_lhs => arg 2; ext a; rw [Finset.sum_comm]
    conv_lhs => rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun a _ =>
      Finset.sum_congr rfl fun b _ => ?_
    ring
  have h2 : ∑ a, ∑ b, (∑ i, G i b * dX i a) * w a * w b
      = ∑ i, (∑ j, G i j * w j) * ∑ a, w a * dX i a := by
    simp only [Finset.sum_mul, Finset.mul_sum]
    conv_lhs => arg 2; ext a; rw [Finset.sum_comm]
    conv_lhs => rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun a _ =>
      Finset.sum_congr rfl fun b _ => ?_
    ring
  have h3 : ∑ a, ∑ b, (∑ i, G a i * dX i b) * w a * w b
      = ∑ i, (∑ j, G i j * w j) * ∑ a, w a * dX i a := by
    simp only [Finset.sum_mul, Finset.mul_sum]
    conv_lhs => arg 2; ext a; rw [Finset.sum_comm]
    conv_lhs => rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun a _ => Finset.sum_congr rfl fun b _ => ?_
    rw [hG b i]
    ring
  have hsplit : ∑ a, ∑ b, (∑ i, (x i * dg a b i + G i b * dX i a + G a i * dX i b)) * w a * w b
      = ∑ a, ∑ b, (∑ i, x i * dg a b i) * w a * w b
        + ∑ a, ∑ b, (∑ i, G i b * dX i a) * w a * w b
        + ∑ a, ∑ b, (∑ i, G a i * dX i b) * w a * w b := by
    simp only [Finset.sum_add_distrib, add_mul]
  rw [hsplit, h1, h2, h3, ← Finset.sum_add_distrib, ← Finset.sum_add_distrib, Finset.mul_sum,
    ← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring

theorem noether_clm_apply_eq_sum {n : ℕ} (L : (Fin n → ℝ) →L[ℝ] ℝ) (w : Fin n → ℝ) :
    L w = ∑ a, w a * L (Pi.single a 1) := by
  conv_lhs => rw [← Finset.univ_sum_single w]
  rw [map_sum]
  refine Finset.sum_congr rfl fun a _ => ?_
  rw [show (Pi.single a (w a) : Fin n → ℝ) = w a • Pi.single a 1 by
    rw [← Pi.single_smul, smul_eq_mul, mul_one], map_smul, smul_eq_mul]

theorem noether_rate_helper {n : ℕ}
    (g : Fin n → Fin n → (Fin n → ℝ) → ℝ) (X : Fin n → (Fin n → ℝ) → ℝ)
    (V : (Fin n → ℝ) → ℝ → ℝ) (q v : ℝ → Fin n → ℝ)
    (hsymm : ∀ a b x, g a b x = g b a x)
    (hX : ∀ i t, DifferentiableAt ℝ (X i) (q t))
    (hq : ∀ t, HasDerivAt q (v t) t)
    (hEL : ∀ t i, HasDerivAt (fun s => ∑ j, g i j (q s) * v s j)
      ((1 / 2) * ∑ a, ∑ b, fderiv ℝ (g a b) (q t) (Pi.single i 1) * v t a * v t b
        - fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1)) t)
    (t : ℝ) :
    HasDerivAt (fun s => ∑ i, ∑ j, g i j (q s) * v s j * X i (q s))
      ((1 / 2) * ∑ a, ∑ b,
          (∑ i, (X i (q t) * fderiv ℝ (g a b) (q t) (Pi.single i 1)
            + g i b (q t) * fderiv ℝ (X i) (q t) (Pi.single a 1)
            + g a i (q t) * fderiv ℝ (X i) (q t) (Pi.single b 1))) * v t a * v t b
        - ∑ i, X i (q t) * fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1)) t := by
  have hXq : ∀ i, HasDerivAt (fun s => X i (q s)) (fderiv ℝ (X i) (q t) (v t)) t :=
    fun i => (hX i t).hasFDerivAt.comp_hasDerivAt t (hq t)
  have hsum := HasDerivAt.sum (u := Finset.univ) (fun i _ => (hEL t i).mul (hXq i))
  convert hsum using 1
  · funext s
    simp only [Finset.sum_apply, Pi.mul_apply, Finset.sum_mul]
  · simp only [noether_clm_apply_eq_sum (fderiv ℝ (X _) (q t)) (v t)]
    exact (noether_rate_algebra (fun a b => g a b (q t)) (fun a b => hsymm a b (q t))
      (fun a b i => fderiv ℝ (g a b) (q t) (Pi.single i 1))
      (fun i a => fderiv ℝ (X i) (q t) (Pi.single a 1)) (fun i => X i (q t)) (v t)
      (fun i => fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1))).symm

theorem noether_sin_deriv (r : ℝ) (ψ : ℝ → ℝ) (ω t c : ℝ) (hψ : HasDerivAt ψ ω t) :
    deriv (fun s => r * sin (ψ s + c)) t = r * (cos (ψ t + c) * ω) :=
  (((hψ.add_const c).sin).const_mul r).deriv

theorem noether_cos_deriv (r : ℝ) (ψ : ℝ → ℝ) (ω t c : ℝ) (hψ : HasDerivAt ψ ω t) :
    deriv (fun s => r * cos (ψ s + c)) t = r * (-sin (ψ t + c) * ω) :=
  (((hψ.add_const c).cos).const_mul r).deriv

#print axioms noether_rate_algebra
#print axioms noether_clm_apply_eq_sum
#print axioms noether_rate_helper
#print axioms noether_sin_deriv
#print axioms noether_cos_deriv

/-- Noether's theorem, geometric form. Work in a chart with coordinates q = (q_1, ..., q_n).
The kinetic-energy metric has components g_ab(q): symmetric and positive definite, so the kinetic
energy is ½ ∑ g_ab q_a' q_b'. The potential V(q, t) may change with time. A motion q(t), with
velocity v(t), obeys Lagrange's equation: the momentum p_i = ∑_j g_ij q_j' changes at the rate
∂L/∂q_i = ½ ∑ ∂_i g_ab q_a' q_b' − ∂_i V, so every force comes from L.
If, at every pose the motion passes through, the field X (components X^i) satisfies the Killing
equation (ℒ_X g)_ab = ∑_i (X^i ∂_i g_ab + g_ib ∂_a X^i + g_ai ∂_b X^i) = 0, and the potential does
not change along X (XV = ∑_i X^i ∂_i V = 0 at each instant), then the paired momentum
J_X = g(q', X) = ∑_i ∑_j g_ij q_j' X^i takes the same value at every time. No coordinate needs to be
missing from L. -/
theorem noether_killing_momentum_conserved {n : ℕ}
    (g : Fin n → Fin n → (Fin n → ℝ) → ℝ) (X : Fin n → (Fin n → ℝ) → ℝ)
    (V : (Fin n → ℝ) → ℝ → ℝ) (q v : ℝ → Fin n → ℝ)
    (hsymm : ∀ a b x, g a b x = g b a x)
    (hpos : ∀ x (w : Fin n → ℝ), w ≠ 0 → 0 < ∑ a, ∑ b, g a b x * w a * w b)
    (hX : ∀ i t, DifferentiableAt ℝ (X i) (q t))
    (hq : ∀ t, HasDerivAt q (v t) t)
    (hEL : ∀ t i, HasDerivAt (fun s => ∑ j, g i j (q s) * v s j)
      ((1 / 2) * ∑ a, ∑ b, fderiv ℝ (g a b) (q t) (Pi.single i 1) * v t a * v t b
        - fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1)) t)
    (hKilling : ∀ t a b, ∑ i, (X i (q t) * fderiv ℝ (g a b) (q t) (Pi.single i 1)
      + g i b (q t) * fderiv ℝ (X i) (q t) (Pi.single a 1)
      + g a i (q t) * fderiv ℝ (X i) (q t) (Pi.single b 1)) = 0)
    (hXV : ∀ t, ∑ i, X i (q t) * fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1) = 0) :
    ∀ t₁ t₂, (∑ i, ∑ j, g i j (q t₁) * v t₁ j * X i (q t₁))
      = ∑ i, ∑ j, g i j (q t₂) * v t₂ j * X i (q t₂) := by
  have hd := noether_rate_helper g X V q v hsymm hX hq hEL
  have hzero : ∀ t, HasDerivAt (fun s => ∑ i, ∑ j, g i j (q s) * v s j * X i (q s)) 0 t := by
    intro t
    have := hd t
    simp only [hKilling, hXV, zero_mul, Finset.sum_const_zero, mul_zero, sub_zero] at this
    exact this
  exact is_const_of_deriv_eq_zero (fun t => (hzero t).differentiableAt)
    (fun t => (hzero t).deriv)

/-- The rate formula behind Noether's theorem (the card's Step 4), with no symmetry assumed.
Along any motion obeying Lagrange's equation, for a symmetric metric g and any field X
differentiable at the motion's poses, the paired momentum J = ∑_i ∑_j g_ij q_j' X^i changes at
the rate dJ/dt = ½ ∑_ab (ℒ_X g)_ab q_a' q_b' − XV: half the Lie derivative of the metric fed the
velocity twice, minus the change of the potential along the field. -/
theorem noether_momentum_rate {n : ℕ}
    (g : Fin n → Fin n → (Fin n → ℝ) → ℝ) (X : Fin n → (Fin n → ℝ) → ℝ)
    (V : (Fin n → ℝ) → ℝ → ℝ) (q v : ℝ → Fin n → ℝ)
    (hsymm : ∀ a b x, g a b x = g b a x)
    (hX : ∀ i t, DifferentiableAt ℝ (X i) (q t))
    (hq : ∀ t, HasDerivAt q (v t) t)
    (hEL : ∀ t i, HasDerivAt (fun s => ∑ j, g i j (q s) * v s j)
      ((1 / 2) * ∑ a, ∑ b, fderiv ℝ (g a b) (q t) (Pi.single i 1) * v t a * v t b
        - fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1)) t)
    (t : ℝ) :
    HasDerivAt (fun s => ∑ i, ∑ j, g i j (q s) * v s j * X i (q s))
      ((1 / 2) * ∑ a, ∑ b,
          (∑ i, (X i (q t) * fderiv ℝ (g a b) (q t) (Pi.single i 1)
            + g i b (q t) * fderiv ℝ (X i) (q t) (Pi.single a 1)
            + g a i (q t) * fderiv ℝ (X i) (q t) (Pi.single b 1))) * v t a * v t b
        - ∑ i, X i (q t) * fderiv ℝ (fun x => V x t) (q t) (Pi.single i 1)) t := by
  exact noether_rate_helper g X V q v hsymm hX hq hEL t

/-- The skater with her arms carried round rigidly. The body has moment of inertia I_0 and turns
by the angle ψ(t) with spin rate ω = ψ'(t). Arm h (h = 1, 2, here indexed 0, 1) is a point mass m at
radius r and angle ψ + (h − 1)π, at (x_h, y_h) = (r cos, r sin) of that angle. Then the paired
momentum J = I_0 ψ' + m ∑_h (x_h y_h' − y_h x_h') equals I ω with I = I_0 + 2 m r². -/
theorem skater_rigid_momentum (I₀ m r : ℝ) (ψ : ℝ → ℝ) (ω t : ℝ) (hψ : HasDerivAt ψ ω t) :
    I₀ * ω + m * ∑ h : Fin 2,
        (r * cos (ψ t + (h : ℕ) * π) * deriv (fun s => r * sin (ψ s + (h : ℕ) * π)) t
          - r * sin (ψ t + (h : ℕ) * π) * deriv (fun s => r * cos (ψ s + (h : ℕ) * π)) t)
      = (I₀ + 2 * m * r ^ 2) * ω := by
  have hterm : ∀ h : Fin 2,
      r * cos (ψ t + (h : ℕ) * π) * deriv (fun s => r * sin (ψ s + (h : ℕ) * π)) t
        - r * sin (ψ t + (h : ℕ) * π) * deriv (fun s => r * cos (ψ s + (h : ℕ) * π)) t
        = r ^ 2 * ω := by
    intro h
    rw [noether_sin_deriv r ψ ω t _ hψ, noether_cos_deriv r ψ ω t _ hψ]
    have := sin_sq_add_cos_sq (ψ t + (h : ℕ) * π)
    linear_combination (r ^ 2 * ω) * this
  rw [Finset.sum_congr rfl fun h _ => hterm h]
  simp
  ring

-- Worked numbers: body 4/5 kg m², arms 3 kg each, pulled from 13/20 m to 1/5 m.
-- Inertia arms out: 0.80 + 2 × 3.0 × 0.65² = 3.3350 kg m².
example : (4 / 5 : ℚ) + 2 * 3 * (13 / 20) ^ 2 = 667 / 200 := by norm_num
-- Inertia arms in: 0.80 + 2 × 3.0 × 0.20² = 1.0400 kg m².
example : (4 / 5 : ℚ) + 2 * 3 * (1 / 5) ^ 2 = 26 / 25 := by norm_num
-- Ratio of inertias 3.3350 ÷ 1.0400 = 667/208 (about 3.2067).
example : (667 / 200 : ℚ) / (26 / 25) = 667 / 208 := by norm_num
-- Final spin 1.5 × 667/208 = 2001/416 rev/s (about 4.8101), from J = I ω kept fixed.
example : (3 / 2 : ℚ) * (667 / 200) / (26 / 25) = 2001 / 416 := by norm_num

#print axioms noether_killing_momentum_conserved
#print axioms noether_momentum_rate
#print axioms skater_rigid_momentum
