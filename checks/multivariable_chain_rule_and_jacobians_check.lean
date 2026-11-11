-- Chain rule in several variables: when f is differentiable at a and g is differentiable at f(a), the Jacobian matrix of g after f at a is the Jacobian of g read at f(a) times the Jacobian of f read at a, the card's hiker feels the temperature fall at exactly 12 °C per hour, and a map with partial derivatives but no derivative breaks the rule.
import Mathlib.Analysis.Calculus.FDeriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Pi
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Prod

open Matrix

/-- **The chain rule in several variables.** Let f send points with n coordinates to points
with m coordinates, and g send points with m coordinates to points with k coordinates.
The Jacobian matrix of a map at a point is its table of rates: entry (i, j) is the rate of
output i per unit of input j (here `LinearMap.toMatrix'` of the derivative `fderiv`).
If f is differentiable at a and g is differentiable at the point f(a) that f delivers, then
the Jacobian of g after f at a is the product of the two tables, outer map on the left, each
read where the chain actually is: J_{g ∘ f}(a) = J_g(f(a)) J_f(a). -/
theorem jacobian_comp_eq_mul {n m k : ℕ}
    (f : (Fin n → ℝ) → (Fin m → ℝ)) (g : (Fin m → ℝ) → (Fin k → ℝ)) (a : Fin n → ℝ)
    (hf : DifferentiableAt ℝ f a) (hg : DifferentiableAt ℝ g (f a)) :
    LinearMap.toMatrix' (fderiv ℝ (g ∘ f) a : (Fin n → ℝ) →ₗ[ℝ] (Fin k → ℝ)) =
      LinearMap.toMatrix' (fderiv ℝ g (f a) : (Fin m → ℝ) →ₗ[ℝ] (Fin k → ℝ)) *
        LinearMap.toMatrix' (fderiv ℝ f a : (Fin n → ℝ) →ₗ[ℝ] (Fin m → ℝ)) := by
  rw [fderiv_comp a hg hf, ← LinearMap.toMatrix'_comp]
  rfl

/-- **The hiker.** She walks the path p(t) = (2t, t^2) km (east, north). The weather map
G(x, y) = (13 - x - y^2, 5 + xy + 3y) gives air temperature A in °C and wind w in km/h, and
the felt temperature is F(A, w) = A - 0.02 w (30 - A) (written 1/50 here). One hour in, the
felt temperature F(G(p(t))) is falling at exactly 12 °C per hour: its rate at t = 1 is -12. -/
theorem hiker_felt_temperature_rate :
    HasDerivAt
      (fun t : ℝ =>
        let x := 2 * t
        let y := t ^ 2
        let A := 13 - x - y ^ 2
        let w := 5 + x * y + 3 * y
        A - 1 / 50 * w * (30 - A))
      (-12) 1 := by
  have hx : HasDerivAt (fun t : ℝ => 2 * t) 2 1 := by
    simpa using HasDerivAt.const_mul (2:ℝ) (hasDerivAt_id' (x := (1:ℝ)))
  have hy : HasDerivAt (fun t : ℝ => t ^ 2) 2 1 := by
    simpa using hasDerivAt_pow 2 (1:ℝ)
  have hA : HasDerivAt (fun t : ℝ => 13 - 2 * t - (t ^ 2) ^ 2) (-6) 1 := by
    have h1 := HasDerivAt.sub (HasDerivAt.sub (hasDerivAt_const (1:ℝ) (13:ℝ)) hx) (hy.pow 2)
    convert h1 using 1; norm_num
  have hw : HasDerivAt (fun t : ℝ => 5 + 2 * t * t ^ 2 + 3 * t ^ 2) 12 1 := by
    have h1 := HasDerivAt.add (HasDerivAt.add (hasDerivAt_const (1:ℝ) (5:ℝ)) (HasDerivAt.mul hx hy)) (HasDerivAt.const_mul 3 hy)
    convert h1 using 1; norm_num
  have h := HasDerivAt.sub hA (HasDerivAt.mul (HasDerivAt.const_mul (1/50 : ℝ) hw) (HasDerivAt.sub (hasDerivAt_const (1:ℝ) (30:ℝ)) hA))
  convert h using 1
  · norm_num

/-- **Partial derivatives are not enough.** The field q(x, y) = x^2 y / (x^2 + y^2), with
q = 0 at the origin (Lean's division by zero already gives 0 there), has both partial
derivatives 0 at the origin, so the chain rule with partials would predict rate 0 along the
walk t ↦ (t, t). The real rate along that walk is 1/2, and q is not differentiable at the
origin. -/
theorem crease_partials_zero_but_rate_half :
    let q : ℝ × ℝ → ℝ := fun v => v.1 ^ 2 * v.2 / (v.1 ^ 2 + v.2 ^ 2)
    HasDerivAt (fun x : ℝ => q (x, 0)) 0 0 ∧
    HasDerivAt (fun y : ℝ => q (0, y)) 0 0 ∧
    HasDerivAt (fun t : ℝ => q (t, t)) (1 / 2) 0 ∧
    ¬ DifferentiableAt ℝ q (0, 0) := by
  intro q
  have h1 : HasDerivAt (fun x : ℝ => q (x, 0)) 0 0 := by
    have : (fun x : ℝ => q (x, 0)) = fun _ => 0 := by
      funext x; simp [q]
    rw [this]; exact hasDerivAt_const _ _
  have h2 : HasDerivAt (fun y : ℝ => q (0, y)) 0 0 := by
    have : (fun y : ℝ => q (0, y)) = fun _ => 0 := by
      funext y; simp [q]
    rw [this]; exact hasDerivAt_const _ _
  have h3 : HasDerivAt (fun t : ℝ => q (t, t)) (1 / 2) 0 := by
    have : (fun t : ℝ => q (t, t)) = fun t => (1 / 2) * t := by
      funext t
      simp only [q]
      rcases eq_or_ne t 0 with rfl | ht
      · simp
      · have : t ^ 2 + t ^ 2 ≠ 0 := by positivity
        field_simp
        ring
    rw [this]
    simpa using HasDerivAt.const_mul (1/2 : ℝ) (hasDerivAt_id' (x := (0:ℝ)))
  refine ⟨h1, h2, h3, ?_⟩
  intro hd
  set L := fderiv ℝ q (0, 0)
  have hL := hd.hasFDerivAt
  have c1 : HasDerivAt (fun x : ℝ => ((x, 0) : ℝ × ℝ)) ((1 : ℝ), (0 : ℝ)) 0 :=
    HasDerivAt.prodMk (hasDerivAt_id' (x := (0:ℝ))) (hasDerivAt_const (0:ℝ) (0:ℝ))
  have c2 : HasDerivAt (fun y : ℝ => ((0, y) : ℝ × ℝ)) ((0 : ℝ), (1 : ℝ)) 0 :=
    HasDerivAt.prodMk (hasDerivAt_const (0:ℝ) (0:ℝ)) (hasDerivAt_id' (x := (0:ℝ)))
  have c3 : HasDerivAt (fun t : ℝ => ((t, t) : ℝ × ℝ)) ((1 : ℝ), (1 : ℝ)) 0 :=
    HasDerivAt.prodMk (hasDerivAt_id' (x := (0:ℝ))) (hasDerivAt_id' (x := (0:ℝ)))
  have e1 : L (1, 0) = 0 := by
    have := HasFDerivAt.comp_hasDerivAt (f := fun x : ℝ => ((x, 0) : ℝ × ℝ)) (0:ℝ) hL c1
    exact h1.unique this |>.symm
  have e2 : L (0, 1) = 0 := by
    have := HasFDerivAt.comp_hasDerivAt (f := fun y : ℝ => ((0, y) : ℝ × ℝ)) (0:ℝ) hL c2
    exact h2.unique this |>.symm
  have e3 : L (1, 1) = 1 / 2 := by
    have := HasFDerivAt.comp_hasDerivAt (f := fun t : ℝ => ((t, t) : ℝ × ℝ)) (0:ℝ) hL c3
    exact h3.unique this |>.symm
  have : ((1 : ℝ), (1 : ℝ)) = (1, 0) + (0, 1) := by simp
  rw [this, map_add, e1, e2] at e3
  norm_num at e3

-- Worked numbers, by hand. Position at 1 h: (2 × 1, 1 × 1) = (2, 1); air and wind there.
example : (13 : ℚ) - 2 - 1 ^ 2 = 10 ∧ (5 : ℚ) + 2 * 1 + 3 * 1 = 10 := by norm_num
-- Felt temperature there: 10 - 0.02 × 10 × 20 = 6.
example : (10 : ℚ) - 1 / 50 * 10 * (30 - 10) = 6 := by norm_num
-- The felt row: 1 + 0.02 × 10 = 1.2 and -0.02 × 20 = -0.4.
example : (1 : ℚ) + 1 / 50 * 10 = 6 / 5 ∧ -(1 / 50 : ℚ) * (30 - 10) = -2 / 5 := by norm_num
-- Weather rates per hour: J_G J_p = (-6, 12).
example : (!![-1, -2; 1, 5] : Matrix (Fin 2) (Fin 2) ℚ) * (!![2; 2] : Matrix (Fin 2) (Fin 1) ℚ) =
    !![-6; 12] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- The three tables multiply to -12 °C per hour.
example : (!![6 / 5, -2 / 5] : Matrix (Fin 1) (Fin 2) ℚ) *
    (!![-1, -2; 1, 5] : Matrix (Fin 2) (Fin 2) ℚ) * (!![2; 2] : Matrix (Fin 2) (Fin 1) ℚ) =
    !![-12] := by
  ext i j; fin_cases i; fin_cases j; norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- The four routes: -2.40, -4.80, -0.80, -4.00 add to -12.
example : (6 / 5 : ℚ) * (-1) * 2 + 6 / 5 * (-2) * 2 + (-2 / 5) * 1 * 2 + (-2 / 5) * 5 * 2 = -12 := by
  norm_num
-- Left pair first: J_F J_G = (-1.60, -4.40), and its dot product with the velocity (2, 2) is -12.
example : (!![6 / 5, -2 / 5] : Matrix (Fin 1) (Fin 2) ℚ) *
    (!![-1, -2; 1, 5] : Matrix (Fin 2) (Fin 2) ℚ) = !![-8 / 5, -22 / 5] := by
  ext i j; fin_cases i; fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (-8 / 5 : ℚ) * 2 + (-22 / 5) * 2 = -12 := by norm_num
-- Mistake 1, weather table read at (1, 1): rows (-1, -2), (1, 4) give -11.20.
example : (!![6 / 5, -2 / 5] : Matrix (Fin 1) (Fin 2) ℚ) *
    (!![-1, -2; 1, 4] : Matrix (Fin 2) (Fin 2) ℚ) * (!![2; 2] : Matrix (Fin 2) (Fin 1) ℚ) =
    !![-56 / 5] := by
  ext i j; fin_cases i; fin_cases j; norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Mistake 2, weather table transposed: -2.40.
example : (!![6 / 5, -2 / 5] : Matrix (Fin 1) (Fin 2) ℚ) *
    (!![-1, -2; 1, 5] : Matrix (Fin 2) (Fin 2) ℚ)ᵀ * (!![2; 2] : Matrix (Fin 2) (Fin 1) ℚ) =
    !![-12 / 5] := by
  ext i j; fin_cases i; fin_cases j
  norm_num [Matrix.mul_apply, Fin.sum_univ_two, Matrix.vecMul, dotProduct]
-- Mistake 3, wind ignored, felt taken as air: the air rate alone, -1 × 2 + (-2) × 2 = -6.
example : (-1 : ℚ) * 2 + (-2) * 2 = -6 := by norm_num

#print axioms jacobian_comp_eq_mul
#print axioms hiker_felt_temperature_rate
#print axioms crease_partials_zero_but_rate_half
