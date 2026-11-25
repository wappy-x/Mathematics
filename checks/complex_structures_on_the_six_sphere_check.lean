-- The six-sphere: the octonion quarter-turn rule J(v) = x × v on the six-sphere squares to minus the identity, yet its Nijenhuis tensor equals −4 x × (X × Y) and has length 4 on suitable unit arrows, so it is almost complex and not complex.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination

open Matrix

/-- The seven-dimensional (octonion) cross product: `u × v` is the imaginary part of the
octonion product of two imaginary octonions, with units `e₁, …, e₇` (indices `0, …, 6` here)
and the card's table `e₁e₂ = e₄, e₂e₃ = e₅, …` (every index shifted by one, mod 7).
Component `c` is `u_{c+1}v_{c+3} − u_{c+3}v_{c+1} + u_{c+4}v_{c+5} − u_{c+5}v_{c+4}
+ u_{c+2}v_{c+6} − u_{c+6}v_{c+2}`, indices mod 7. Mathlib has no octonions, so it is
written out. -/
def octCross {R : Type*} [CommRing R] (u v : Fin 7 → R) : Fin 7 → R := fun c =>
  u (c + 1) * v (c + 3) - u (c + 3) * v (c + 1)
    + u (c + 4) * v (c + 5) - u (c + 5) * v (c + 4)
    + u (c + 2) * v (c + 6) - u (c + 6) * v (c + 2)

/-- The card's `B(U, V)`: how fast the octonion rule turns along `U`, applied to `V`, at the
point `x`; it is the tangent part of `U × V`, that is `U × V − (x · (U × V)) x`. -/
def turnRate {R : Type*} [CommRing R] (x U V : Fin 7 → R) : Fin 7 → R :=
  octCross U V - (x ⬝ᵥ octCross U V) • x

/-- The Nijenhuis tensor of the octonion rule `J_x(v) = x × v` at the point `x`, through the
card's torsion-free-connection formula
`N_J(X,Y) = B(JX,Y) − B(JY,X) − J B(X,Y) + J B(Y,X)`. -/
def nijenhuisOct {R : Type*} [CommRing R] (x X Y : Fin 7 → R) : Fin 7 → R :=
  turnRate x (octCross x X) Y - turnRate x (octCross x Y) X
    - octCross x (turnRate x X Y) + octCross x (turnRate x Y X)

theorem octCross_octCross_self {R : Type*} [CommRing R] (x v : Fin 7 → R) :
    octCross x (octCross x v) = (x ⬝ᵥ v) • x - (x ⬝ᵥ x) • v := by
  ext i; fin_cases i <;> simp [octCross, dotProduct, Fin.sum_univ_seven] <;> ring

#print axioms octCross_octCross_self

theorem dot_octCross_self {R : Type*} [CommRing R] (x v : Fin 7 → R) :
    x ⬝ᵥ octCross x v = 0 := by
  simp [octCross, dotProduct, Fin.sum_univ_seven]; ring

#print axioms dot_octCross_self

theorem octCross_dot_octCross {R : Type*} [CommRing R] (u v : Fin 7 → R) :
    octCross u v ⬝ᵥ octCross u v = (u ⬝ᵥ u) * (v ⬝ᵥ v) - (u ⬝ᵥ v) ^ 2 := by
  simp [octCross, dotProduct, Fin.sum_univ_seven]; ring

#print axioms octCross_dot_octCross

theorem dot_octCross_eq {R : Type*} [CommRing R] (x X Y : Fin 7 → R) :
    x ⬝ᵥ octCross X Y = octCross x X ⬝ᵥ Y := by
  simp [octCross, dotProduct, Fin.sum_univ_seven]; ring

#print axioms dot_octCross_eq

theorem octCross_anti {R : Type*} [CommRing R] (u v : Fin 7 → R) :
    octCross u v = -octCross v u := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_anti

theorem octCross_self {R : Type*} [CommRing R] (x : Fin 7 → R) :
    octCross x x = 0 := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_self

theorem octCross_sub_smul {R : Type*} [CommRing R] (x a b : Fin 7 → R) (c : R) :
    octCross x (a - c • b) = octCross x a - c • octCross x b := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_sub_smul

theorem octCross_neg {R : Type*} [CommRing R] (x v : Fin 7 → R) :
    octCross x (-v) = -octCross x v := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_neg

theorem octCross_polar {R : Type*} [CommRing R] (a b c : Fin 7 → R) :
    octCross a (octCross c b) + octCross c (octCross a b)
      = (a ⬝ᵥ b) • c + (c ⬝ᵥ b) • a - (2 * (a ⬝ᵥ c)) • b := by
  ext i; fin_cases i <;> simp [octCross, dotProduct, Fin.sum_univ_seven] <;> ring

#print axioms octCross_polar

theorem dot_octCross_octCross {R : Type*} [CommRing R] (x X Y : Fin 7 → R) :
    x ⬝ᵥ octCross (octCross x X) Y = (x ⬝ᵥ X) * (x ⬝ᵥ Y) - (x ⬝ᵥ x) * (X ⬝ᵥ Y) := by
  rw [dot_octCross_eq, octCross_octCross_self]
  simp [sub_dotProduct, smul_dotProduct]

#print axioms dot_octCross_octCross

theorem nijenhuisOct_eq {R : Type*} [CommRing R] (x X Y : Fin 7 → R) :
    nijenhuisOct x X Y = (-4 : R) • octCross x (octCross X Y)
      + (3 * (x ⬝ᵥ Y)) • X - (3 * (x ⬝ᵥ X)) • Y := by
  have h1 := octCross_polar Y X x
  have h2 := octCross_polar X Y x
  rw [octCross_anti Y X, octCross_neg, dotProduct_comm Y X, dotProduct_comm Y x] at h1
  rw [dotProduct_comm X x] at h2
  unfold nijenhuisOct turnRate
  rw [octCross_sub_smul, octCross_sub_smul, octCross_self, dot_octCross_octCross,
    dot_octCross_octCross, octCross_anti (octCross x X) Y, octCross_anti (octCross x Y) X,
    octCross_anti Y X, octCross_neg, dotProduct_comm Y X]
  ext i
  have e1 := congrFun h1 i
  have e2 := congrFun h2 i
  simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, Pi.neg_apply, smul_eq_mul,
    Pi.zero_apply] at e1 e2 ⊢
  linear_combination e2 - e1

#print axioms nijenhuisOct_eq

/-- The octonion rule is almost complex: at a point `x` of the six-sphere (`|x|² = 1`) and
for a tangent arrow `v` (`x · v = 0`), the turned arrow `J v = x × v` is again tangent, has
the same length as `v`, and turning twice reverses `v`: `x × (x × v) = −v`. -/
theorem octonion_rule_squares_to_neg_one (x v : Fin 7 → ℝ) (hx : x ⬝ᵥ x = 1)
    (hv : x ⬝ᵥ v = 0) :
    octCross x (octCross x v) = -v ∧ x ⬝ᵥ octCross x v = 0 ∧
      octCross x v ⬝ᵥ octCross x v = v ⬝ᵥ v := by
  refine ⟨?_, dot_octCross_self x v, ?_⟩
  · rw [octCross_octCross_self, hx, hv]; simp
  · rw [octCross_dot_octCross, hx, hv]; ring

/-- The closed form of the Nijenhuis tensor: at a point `x` of the six-sphere and for tangent
arrows `X`, `Y` there, `N_J(X, Y) = −4 x × (X × Y)`. -/
theorem nijenhuis_eq_neg_four_cross (x X Y : Fin 7 → ℝ) (hx : x ⬝ᵥ x = 1)
    (hX : x ⬝ᵥ X = 0) (hY : x ⬝ᵥ Y = 0) :
    nijenhuisOct x X Y = (-4 : ℝ) • octCross x (octCross X Y) := by
  rw [nijenhuisOct_eq, hX, hY]; simp

/-- The octonion rule is not complex: at a point `x` of the six-sphere, for unit tangent
arrows `X`, `Y` with `Y` perpendicular to both `X` and `J X = x × X`, the Nijenhuis tensor
has squared length 16 (length 4), so it is not zero. -/
theorem nijenhuis_sq_length_eq_sixteen (x X Y : Fin 7 → ℝ) (hx : x ⬝ᵥ x = 1)
    (hX : x ⬝ᵥ X = 0) (hY : x ⬝ᵥ Y = 0) (hXX : X ⬝ᵥ X = 1) (hYY : Y ⬝ᵥ Y = 1)
    (hXY : X ⬝ᵥ Y = 0) (hJXY : octCross x X ⬝ᵥ Y = 0) :
    nijenhuisOct x X Y ⬝ᵥ nijenhuisOct x X Y = 16 := by
  rw [nijenhuis_eq_neg_four_cross x X Y hx hX hY, smul_dotProduct, dotProduct_smul,
    octCross_dot_octCross, octCross_dot_octCross, hx, hXX, hYY, hXY, dot_octCross_eq, hJXY]
  simp; norm_num

-- The table: e₁e₂ = e₄.
example : octCross (![1, 0, 0, 0, 0, 0, 0] : Fin 7 → ℚ) ![0, 1, 0, 0, 0, 0, 0]
    = ![0, 0, 0, 1, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross]

-- The card's point x = (2/7, 3/7, 6/7, 0, 0, 0, 0) is on the sphere, and the arrow
-- v = (3, −2, 0, 1, 0, 0, 0) is tangent there, with squared length 14.
example : (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ⬝ᵥ ![2/7, 3/7, 6/7, 0, 0, 0, 0] = 1 ∧
    (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ⬝ᵥ ![3, -2, 0, 1, 0, 0, 0] = 0 ∧
    (![3, -2, 0, 1, 0, 0, 0] : Fin 7 → ℚ) ⬝ᵥ ![3, -2, 0, 1, 0, 0, 0] = 14 := by
  simp [dotProduct, Fin.sum_univ_seven]; norm_num

-- One turn: J v = x × v = (3/7, −2/7, 0, −13/7, 12/7, 6/7, −18/7).
example : octCross (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ![3, -2, 0, 1, 0, 0, 0]
    = ![3/7, -2/7, 0, -13/7, 12/7, 6/7, -18/7] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- Two turns: x × (x × v) = (−3, 2, 0, −1, 0, 0, 0) = −v.
example : octCross (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ)
    (octCross ![2/7, 3/7, 6/7, 0, 0, 0, 0] ![3, -2, 0, 1, 0, 0, 0])
    = ![-3, 2, 0, -1, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- The Nijenhuis tensor at x for X = e₄, Y = e₅ is (−24/7, 0, 8/7, 0, 0, 12/7, 0),
-- of squared length 16.
example : nijenhuisOct (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ![0, 0, 0, 1, 0, 0, 0]
    ![0, 0, 0, 0, 1, 0, 0] = ![-24/7, 0, 8/7, 0, 0, 12/7, 0] := by
  ext i; fin_cases i <;>
    simp [nijenhuisOct, turnRate, octCross, dotProduct, Fin.sum_univ_seven] <;> norm_num

example : (![-24/7, 0, 8/7, 0, 0, 12/7, 0] : Fin 7 → ℚ) ⬝ᵥ ![-24/7, 0, 8/7, 0, 0, 12/7, 0]
    = 16 := by
  simp [dotProduct, Fin.sum_univ_seven]; norm_num

-- The seven-dimensional product breaks the Jacobi identity: for e₁, e₂, e₃ the sum
-- e₁ × (e₂ × e₃) + e₂ × (e₃ × e₁) + e₃ × (e₁ × e₂) is 3e₆.
example : octCross (![1, 0, 0, 0, 0, 0, 0] : Fin 7 → ℚ)
      (octCross ![0, 1, 0, 0, 0, 0, 0] ![0, 0, 1, 0, 0, 0, 0])
    + octCross ![0, 1, 0, 0, 0, 0, 0] (octCross ![0, 0, 1, 0, 0, 0, 0] ![1, 0, 0, 0, 0, 0, 0])
    + octCross ![0, 0, 1, 0, 0, 0, 0] (octCross ![1, 0, 0, 0, 0, 0, 0] ![0, 1, 0, 0, 0, 0, 0])
    = ![0, 0, 0, 0, 0, 3, 0] := by
  ext i; fin_cases i <;> norm_num [octCross]

-- What breaks, off the sphere: at 2x, turning v twice gives (−12, 8, 0, −4, 0, 0, 0) = −4v.
example : octCross (![4/7, 6/7, 12/7, 0, 0, 0, 0] : Fin 7 → ℚ)
    (octCross ![4/7, 6/7, 12/7, 0, 0, 0, 0] ![3, -2, 0, 1, 0, 0, 0])
    = ![-12, 8, 0, -4, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- What breaks, not tangent: for v = e₁ at x, turning twice gives
-- (−45/49, 6/49, 12/49, 0, 0, 0, 0), not −e₁.
example : octCross (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ)
    (octCross ![2/7, 3/7, 6/7, 0, 0, 0, 0] ![1, 0, 0, 0, 0, 0, 0])
    = ![-45/49, 6/49, 12/49, 0, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- The sphere test of Step 4: for n from 1 to 8, the Euler number 2 is a multiple of
-- (n − 1)! exactly for n = 1, 2, 3 (the spheres S², S⁴, S⁶).
example : (List.range' 1 8).filter (fun n => 2 % (n - 1).factorial == 0) = [1, 2, 3] := by
  decide

#print axioms octonion_rule_squares_to_neg_one
#print axioms nijenhuis_eq_neg_four_cross
#print axioms nijenhuis_sq_length_eq_sixteen
