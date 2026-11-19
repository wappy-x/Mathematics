-- Riemann curvature tensor: in the globe's (polar angle, longitude) chart the curvature tensor built from the metric gives sectional curvature 1/R^2 for every plane, sec depends only on the plane, and a flat chart can have nonzero Christoffel symbols yet zero curvature.
import Mathlib.Analysis.Calculus.LineDeriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.Matrix.Notation

open Matrix

noncomputable section

namespace RiemannCurvature

variable {n : ℕ}

/-- `∂_l f` at the chart point `x`: the rate of change of `f` along the `l`-th chart direction. -/
def coordDeriv (l : Fin n) (f : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ) : ℝ :=
  lineDeriv ℝ f x (Pi.single l 1)

/-- The Christoffel symbols of the Levi-Civita connection of the metric `g` in a chart:
`Γ^k_ij = ½ g^kl (∂_i g_jl + ∂_j g_il − ∂_l g_ij)`, with `g^kl` the inverse matrix of `g_ij`. -/
def christoffel (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (k i j : Fin n) : ℝ :=
  (1 / 2) * ∑ l, (g x)⁻¹ k l *
    (coordDeriv i (fun y => g y j l) x + coordDeriv j (fun y => g y i l) x
      - coordDeriv l (fun y => g y i j) x)

/-- The card's component formula
`Rm^a_bcd = ∂_c Γ^a_db − ∂_d Γ^a_cb + Γ^a_ce Γ^e_db − Γ^a_de Γ^e_cb`,
with `Rm(∂_c, ∂_d) ∂_b = Rm^a_bcd ∂_a`. -/
def riemann (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (a b c d : Fin n) : ℝ :=
  coordDeriv c (fun y => christoffel g y a d b) x - coordDeriv d (fun y => christoffel g y a c b) x
    + ∑ e, (christoffel g x a c e * christoffel g x e d b
      - christoffel g x a d e * christoffel g x e c b)

/-- `Rm(∂_i, ∂_j, ∂_k, ∂_l) = g(Rm(∂_i, ∂_j) ∂_k, ∂_l)`: the tensor with its output turned into a number. -/
def curvatureForm (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (i j k l : Fin n) : ℝ :=
  ∑ a, g x a l * riemann g x a k i j

/-- `Rm(X, Y, Z, W)` for tangent vectors at `x`, given by their chart components. -/
def rmForm (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (X Y Z W : Fin n → ℝ) : ℝ :=
  ∑ i, ∑ j, ∑ k, ∑ l, curvatureForm g x i j k l * X i * Y j * Z k * W l

/-- The metric's dot product `g(X, Y)` at `x`. -/
def metricForm (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (X Y : Fin n → ℝ) : ℝ :=
  X ⬝ᵥ (g x *ᵥ Y)

/-- `sec(X, Y) = Rm(X, Y, Y, X) / (g(X, X) g(Y, Y) − g(X, Y)²)`. -/
def sectionalCurvature (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (X Y : Fin n → ℝ) : ℝ :=
  rmForm g x X Y Y X / (metricForm g x X X * metricForm g x Y Y - metricForm g x X Y ^ 2)

/-- The globe of radius `R` in the chart `(φ, θ) = (x 0, x 1)`: `ds² = R² dφ² + R² sin²φ dθ²`. -/
def sphereMetric (R : ℝ) : (Fin 2 → ℝ) → Matrix (Fin 2) (Fin 2) ℝ :=
  fun x => !![R ^ 2, 0; 0, R ^ 2 * Real.sin (x 0) ^ 2]

/-- The flat plane in polar coordinates `(r, θ) = (x 0, x 1)`: `ds² = dr² + r² dθ²`. -/
def polarMetric : (Fin 2 → ℝ) → Matrix (Fin 2) (Fin 2) ℝ :=
  fun x => !![1, 0; 0, x 0 ^ 2]

lemma inv_two (a b c d : ℝ) : (!![a, b; c, d])⁻¹ = (a*d - b*c)⁻¹ • !![d, -b; -c, a] := by
  rw [inv_def, adjugate_fin_two_of, det_fin_two_of, Ring.inverse_eq_inv']
#print axioms inv_two

lemma cd_zero (x : Fin 2 → ℝ) (h : ℝ → ℝ) :
    coordDeriv 0 (fun y : Fin 2 → ℝ => h (y 0)) x = deriv h (x 0) := by
  unfold coordDeriv lineDeriv
  simp
  exact deriv_comp_const_add (f := h) (a := x 0) (x := 0) |>.trans (by simp)
#print axioms cd_zero

lemma cd_one (x : Fin 2 → ℝ) (h : ℝ → ℝ) :
    coordDeriv 1 (fun y : Fin 2 → ℝ => h (y 0)) x = 0 := by
  unfold coordDeriv lineDeriv
  simp
#print axioms cd_one

lemma cd_const (l : Fin n) (x : Fin n → ℝ) (c : ℝ) : coordDeriv l (fun _ => c) x = 0 := by
  unfold coordDeriv lineDeriv
  simp
#print axioms cd_const

lemma cd_sq0 (x : Fin 2 → ℝ) : coordDeriv 0 (fun y : Fin 2 → ℝ => y 0 ^ 2) x = 2 * x 0 :=
  (cd_zero x (fun t => t ^ 2)).trans (by simp)
#print axioms cd_sq0

lemma cd_sq1 (x : Fin 2 → ℝ) : coordDeriv 1 (fun y : Fin 2 → ℝ => y 0 ^ 2) x = 0 :=
  cd_one x (fun t => t ^ 2)
#print axioms cd_sq1

lemma polar_chr (y : Fin 2 → ℝ) : christoffel polarMetric y =
    fun k i j => ![![![0, 0], ![0, -y 0]], ![![0, (y 0)⁻¹], ![(y 0)⁻¹, 0]]] k i j := by
  funext k i j
  fin_cases k <;> fin_cases i <;> fin_cases j <;>
    simp [christoffel, Fin.sum_univ_two, polarMetric, inv_two, cd_const, cd_sq0, cd_sq1]
  all_goals rcases eq_or_ne (y 0) 0 with h | h <;> [simp [h]; field_simp]
#print axioms polar_chr

lemma cd_neg0 (x : Fin 2 → ℝ) : coordDeriv 0 (fun y : Fin 2 → ℝ => -y 0) x = -1 :=
  (cd_zero x (fun t => -t)).trans (by simp)
#print axioms cd_neg0

lemma cd_neg1 (x : Fin 2 → ℝ) : coordDeriv 1 (fun y : Fin 2 → ℝ => -y 0) x = 0 :=
  cd_one x (fun t => -t)
#print axioms cd_neg1

lemma cd_inv0 (x : Fin 2 → ℝ) : coordDeriv 0 (fun y : Fin 2 → ℝ => (y 0)⁻¹) x = -((x 0) ^ 2)⁻¹ :=
  (cd_zero x (fun t => t⁻¹)).trans (by simp)
#print axioms cd_inv0

lemma cd_inv1 (x : Fin 2 → ℝ) : coordDeriv 1 (fun y : Fin 2 → ℝ => (y 0)⁻¹) x = 0 :=
  cd_one x (fun t => t⁻¹)
#print axioms cd_inv1

lemma polar_riemann (x : Fin 2 → ℝ) (hx : x 0 ≠ 0) (a b c d : Fin 2) :
    riemann polarMetric x a b c d = 0 := by
  fin_cases a <;> fin_cases b <;> fin_cases c <;> fin_cases d <;>
    simp [riemann, Fin.sum_univ_two, polar_chr, cd_const, cd_neg0, cd_neg1, cd_inv0, cd_inv1]
  all_goals field_simp; ring
#print axioms polar_riemann

lemma cd_ssq0 (R : ℝ) (x : Fin 2 → ℝ) : coordDeriv 0 (fun y : Fin 2 → ℝ => R ^ 2 * Real.sin (y 0) ^ 2) x
    = R ^ 2 * (2 * Real.sin (x 0) * Real.cos (x 0)) :=
  (cd_zero x (fun t => R ^ 2 * Real.sin t ^ 2)).trans (by simp)
#print axioms cd_ssq0

lemma cd_ssq1 (R : ℝ) (x : Fin 2 → ℝ) : coordDeriv 1 (fun y : Fin 2 → ℝ => R ^ 2 * Real.sin (y 0) ^ 2) x = 0 :=
  cd_one x (fun t => R ^ 2 * Real.sin t ^ 2)
#print axioms cd_ssq1

lemma sphere_chr (R : ℝ) (hR : R ≠ 0) (y : Fin 2 → ℝ) : christoffel (sphereMetric R) y =
    fun k i j => ![![![0, 0], ![0, -(Real.sin (y 0) * Real.cos (y 0))]],
      ![![0, Real.cos (y 0) / Real.sin (y 0)], ![Real.cos (y 0) / Real.sin (y 0), 0]]] k i j := by
  funext k i j
  fin_cases k <;> fin_cases i <;> fin_cases j <;>
    simp [christoffel, Fin.sum_univ_two, sphereMetric, inv_two, cd_const, cd_ssq0, cd_ssq1]
  all_goals rcases eq_or_ne (Real.sin (y 0)) 0 with h | h <;> [simp [h]; field_simp]
#print axioms sphere_chr

lemma cd_sc0 (x : Fin 2 → ℝ) : coordDeriv 0 (fun y : Fin 2 → ℝ => -(Real.sin (y 0) * Real.cos (y 0))) x
    = -(Real.cos (x 0) ^ 2 - Real.sin (x 0) ^ 2) :=
  (cd_zero x (fun t => -(Real.sin t * Real.cos t))).trans (by simp; ring)
#print axioms cd_sc0

lemma cd_sc1 (x : Fin 2 → ℝ) : coordDeriv 1 (fun y : Fin 2 → ℝ => -(Real.sin (y 0) * Real.cos (y 0))) x = 0 :=
  cd_one x (fun t => -(Real.sin t * Real.cos t))
#print axioms cd_sc1

lemma cd_cot0 (x : Fin 2 → ℝ) (hx : Real.sin (x 0) ≠ 0) :
    coordDeriv 0 (fun y : Fin 2 → ℝ => Real.cos (y 0) / Real.sin (y 0)) x
    = -(1 / Real.sin (x 0) ^ 2) := by
  refine (cd_zero x (fun t => Real.cos t / Real.sin t)).trans ?_
  have h := ((Real.hasDerivAt_cos (x 0)).div (Real.hasDerivAt_sin (x 0)) hx).deriv
  rw [show (fun t => Real.cos t / Real.sin t) = Real.cos / Real.sin from rfl, h]
  field_simp
  rw [← Real.sin_sq_add_cos_sq (x 0)]
  ring
#print axioms cd_cot0

lemma cd_cot1 (x : Fin 2 → ℝ) : coordDeriv 1 (fun y : Fin 2 → ℝ => Real.cos (y 0) / Real.sin (y 0)) x = 0 :=
  cd_one x (fun t => Real.cos t / Real.sin t)
#print axioms cd_cot1

lemma sphere_riemann (R : ℝ) (hR : R ≠ 0) (x : Fin 2 → ℝ) (hx : Real.sin (x 0) ≠ 0) :
    riemann (sphereMetric R) x = fun a b c d =>
      ![![![![0, 0], ![0, 0]], ![![0, Real.sin (x 0) ^ 2], ![-(Real.sin (x 0) ^ 2), 0]]],
        ![![![0, -1], ![1, 0]], ![![0, 0], ![0, 0]]]] a b c d := by
  funext a b c d
  fin_cases a <;> fin_cases b <;> fin_cases c <;> fin_cases d <;>
    simp [riemann, Fin.sum_univ_two, sphere_chr R hR, cd_const, cd_sc0, cd_sc1, cd_cot0 x hx, cd_cot1]
  all_goals field_simp
  all_goals first | ring1 | linear_combination (Real.sin_sq_add_cos_sq (x 0)) |
    linear_combination -(Real.sin_sq_add_cos_sq (x 0))
#print axioms sphere_riemann

lemma pair_det_ne_zero (X Y : Fin 2 → ℝ) (hXY : LinearIndependent ℝ ![X, Y]) :
    X 0 * Y 1 - X 1 * Y 0 ≠ 0 := by
  intro h0
  rw [LinearIndependent.pair_iff] at hXY
  have h1 := hXY (Y 1) (-X 1) (by
    ext i; fin_cases i <;> simp <;> linarith)
  have h2 := hXY (Y 0) (-X 0) (by
    ext i; fin_cases i <;> simp <;> linarith)
  have hX0 : X 0 = 0 := by linarith [h2.2]
  have hX1 : X 1 = 0 := by linarith [h1.2]
  have h3 := hXY 1 0 (by ext i; fin_cases i <;> simp [hX0, hX1])
  exact one_ne_zero h3.1
#print axioms pair_det_ne_zero

lemma riemann_antisymm (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (a b c d : Fin n) :
    riemann g x a b c d = -riemann g x a b d c := by
  simp only [riemann, Finset.sum_sub_distrib]
  ring
#print axioms riemann_antisymm

lemma curvatureForm_antisymm (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (i j k l : Fin n) : curvatureForm g x i j k l = -curvatureForm g x j i k l := by
  simp only [curvatureForm, ← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun a _ => ?_
  rw [riemann_antisymm g x a k i j]
  ring
#print axioms curvatureForm_antisymm

lemma rmForm_swap12 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y Z W : Fin n → ℝ) : rmForm g x X Y Z W = -rmForm g x Y X Z W := by
  unfold rmForm
  conv_rhs => rw [Finset.sum_comm]
  simp only [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ =>
    Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  rw [curvatureForm_antisymm g x i j k l]
  ring
#print axioms rmForm_swap12

lemma rmForm_swap34 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (hZW : ∀ i j k l, curvatureForm g x i j k l = -curvatureForm g x i j l k)
    (X Y Z W : Fin n → ℝ) : rmForm g x X Y Z W = -rmForm g x X Y W Z := by
  unfold rmForm
  simp only [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  conv_rhs => rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  rw [hZW i j k l]
  ring
#print axioms rmForm_swap34

lemma rmForm_lin1 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y Q S T : Fin n → ℝ) (a b : ℝ) :
    rmForm g x (a • X + b • Y) Q S T = a * rmForm g x X Q S T + b * rmForm g x Y Q S T := by
  simp only [rmForm, Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ =>
    Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  ring
#print axioms rmForm_lin1

lemma rmForm_lin2 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y P S T : Fin n → ℝ) (a b : ℝ) :
    rmForm g x P (a • X + b • Y) S T = a * rmForm g x P X S T + b * rmForm g x P Y S T := by
  simp only [rmForm, Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ =>
    Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  ring
#print axioms rmForm_lin2

lemma rmForm_lin3 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y P Q T : Fin n → ℝ) (a b : ℝ) :
    rmForm g x P Q (a • X + b • Y) T = a * rmForm g x P Q X T + b * rmForm g x P Q Y T := by
  simp only [rmForm, Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ =>
    Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  ring
#print axioms rmForm_lin3

lemma rmForm_lin4 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y P Q S : Fin n → ℝ) (a b : ℝ) :
    rmForm g x P Q S (a • X + b • Y) = a * rmForm g x P Q S X + b * rmForm g x P Q S Y := by
  simp only [rmForm, Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ =>
    Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  ring
#print axioms rmForm_lin4

lemma metricForm_lin1 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y Z : Fin n → ℝ) (a b : ℝ) :
    metricForm g x (a • X + b • Y) Z = a * metricForm g x X Z + b * metricForm g x Y Z := by
  simp only [metricForm, add_dotProduct, smul_dotProduct, smul_eq_mul]
#print axioms metricForm_lin1

lemma metricForm_lin2 (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (X Y Z : Fin n → ℝ) (a b : ℝ) :
    metricForm g x Z (a • X + b • Y) = a * metricForm g x Z X + b * metricForm g x Z Y := by
  simp only [metricForm, mulVec_add, mulVec_smul, dotProduct_add, dotProduct_smul, smul_eq_mul]
#print axioms metricForm_lin2

lemma metricForm_symm (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (hg : (g x).IsSymm) (X Y : Fin n → ℝ) : metricForm g x X Y = metricForm g x Y X := by
  unfold metricForm
  rw [dotProduct_mulVec, ← mulVec_transpose, hg.eq, dotProduct_comm]
#print axioms metricForm_symm

/-- On a globe of radius `R`, at any point where the `(φ, θ)` chart is regular (`sin φ ≠ 0`),
the curvature tensor built from the metric gives sectional curvature `1/R²` for every plane:
any two tangent vectors `X`, `Y` that span a real plane have `sec(X, Y) = 1/R²`. -/
theorem sphere_sectional_curvature_eq_one_div_radius_sq (R : ℝ) (hR : 0 < R)
    (x : Fin 2 → ℝ) (hx : Real.sin (x 0) ≠ 0)
    (X Y : Fin 2 → ℝ) (hXY : LinearIndependent ℝ ![X, Y]) :
    sectionalCurvature (sphereMetric R) x X Y = 1 / R ^ 2 := by
  have hdet := pair_det_ne_zero X Y hXY
  have hnum : rmForm (sphereMetric R) x X Y Y X
      = R ^ 2 * Real.sin (x 0) ^ 2 * (X 0 * Y 1 - X 1 * Y 0) ^ 2 := by
    simp [rmForm, curvatureForm, sphere_riemann R hR.ne' x hx, Fin.sum_univ_two, sphereMetric]
    ring
  have hden : metricForm (sphereMetric R) x X X * metricForm (sphereMetric R) x Y Y
      - metricForm (sphereMetric R) x X Y ^ 2
      = R ^ 4 * Real.sin (x 0) ^ 2 * (X 0 * Y 1 - X 1 * Y 0) ^ 2 := by
    simp [metricForm, dotProduct, mulVec, Fin.sum_univ_two, sphereMetric]
    ring
  rw [sectionalCurvature, hnum, hden]
  have hR' : R ≠ 0 := hR.ne'
  field_simp

/-- Sectional curvature depends only on the plane: if `Rm` changes sign when its last two slots
swap and the metric is symmetric, then replacing `X, Y` by any other basis
`aX + bY, cX + dY` of the same plane (determinant `ad − bc ≠ 0`) leaves sec unchanged. -/
theorem sectional_curvature_depends_only_on_plane
    (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) (hg : (g x).IsSymm)
    (hZW : ∀ i j k l, curvatureForm g x i j k l = -curvatureForm g x i j l k)
    (X Y : Fin n → ℝ) (a b c d : ℝ) (hD : a * d - b * c ≠ 0) :
    sectionalCurvature g x (a • X + b • Y) (c • X + d • Y) = sectionalCurvature g x X Y := by
  have h12 := rmForm_swap12 g x
  have h34 := rmForm_swap34 g x hZW
  have hXX : ∀ Z W, rmForm g x X X Z W = 0 := fun Z W => by linarith [h12 X X Z W]
  have hYY : ∀ Z W, rmForm g x Y Y Z W = 0 := fun Z W => by linarith [h12 Y Y Z W]
  have hXX' : ∀ P Q, rmForm g x P Q X X = 0 := fun P Q => by linarith [h34 P Q X X]
  have hYY' : ∀ P Q, rmForm g x P Q Y Y = 0 := fun P Q => by linarith [h34 P Q Y Y]
  have hnum : rmForm g x (a • X + b • Y) (c • X + d • Y) (c • X + d • Y) (a • X + b • Y)
      = (a * d - b * c) ^ 2 * rmForm g x X Y Y X := by
    simp only [rmForm_lin1, rmForm_lin2, rmForm_lin3, rmForm_lin4, hXX, hYY, hXX', hYY']
    rw [h12 Y X Y X, h12 Y X X Y, h34 X Y X Y]
    ring
  have hsym := metricForm_symm g x hg Y X
  have hden : metricForm g x (a • X + b • Y) (a • X + b • Y) * metricForm g x (c • X + d • Y) (c • X + d • Y)
      - metricForm g x (a • X + b • Y) (c • X + d • Y) ^ 2
      = (a * d - b * c) ^ 2 * (metricForm g x X X * metricForm g x Y Y - metricForm g x X Y ^ 2) := by
    simp only [metricForm_lin1, metricForm_lin2]
    rw [hsym]
    ring
  rw [sectionalCurvature, sectionalCurvature, hnum, hden]
  exact mul_div_mul_left _ _ (pow_ne_zero 2 hD)

/-- The flat plane in polar coordinates, away from the centre (`r > 0`): the Christoffel symbol
`Γ^r_θθ = −r` is not zero, yet every component of the curvature tensor is zero, so
`Γ` describes the chart's curving grid lines, not the surface. -/
theorem flat_polar_chart_christoffel_nonzero_curvature_zero (x : Fin 2 → ℝ) (hx : 0 < x 0) :
    christoffel polarMetric x 0 1 1 = -(x 0) ∧ ∀ a b c d, riemann polarMetric x a b c d = 0 := by
  refine ⟨by rw [polar_chr]; simp, polar_riemann x hx.ne'⟩

/-! The card's component count, `n²(n² − 1)/12` against "plane pairs minus Bianchi",
`N(N + 1)/2 − n(n − 1)(n − 2)(n − 3)/24` with `N = n(n − 1)/2`, for `n = 2, 3, 4`. -/

example : 2 ^ 2 * (2 ^ 2 - 1) / 12 = 1 ∧
    (2 * 1 / 2) * (2 * 1 / 2 + 1) / 2 - 2 * 1 * 0 * 0 / 24 = 1 := by norm_num

example : 3 ^ 2 * (3 ^ 2 - 1) / 12 = 6 ∧
    (3 * 2 / 2) * (3 * 2 / 2 + 1) / 2 - 3 * 2 * 1 * 0 / 24 = 6 := by norm_num

example : 4 ^ 2 * (4 ^ 2 - 1) / 12 = 20 ∧
    (4 * 3 / 2) * (4 * 3 / 2 + 1) / 2 - 4 * 3 * 2 * 1 / 24 = 20 := by norm_num

#print axioms sphere_sectional_curvature_eq_one_div_radius_sq
#print axioms sectional_curvature_depends_only_on_plane
#print axioms flat_polar_chart_christoffel_nonzero_curvature_zero

end RiemannCurvature

end
