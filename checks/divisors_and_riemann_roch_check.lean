-- Divisors and Riemann-Roch: on a smooth Weierstrass cubic the functions with poles only at O, of pole order at most n, form an n-dimensional space, points are linearly equivalent only when equal, and P + Q ~ (4, -9) + O on y^2 = x^3 + x^2 + 1.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.RingTheory.Polynomial.Basic
import Mathlib.LinearAlgebra.Dimension.Free
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Data.Int.Interval

open Polynomial WeierstrassCurve

/-- The `F`-linear map `(p, q) ↦ p + q Y` into the coordinate ring. -/
noncomputable def coordPairMap {F : Type*} [Field F] (W : WeierstrassCurve.Affine F) :
    (F[X] × F[X]) →ₗ[F] W.CoordinateRing where
  toFun v := v.1 • (1 : W.CoordinateRing) + v.2 • Affine.CoordinateRing.mk W (X : F[X][X])
  map_add' v w := by
    simp only [Prod.fst_add, Prod.snd_add, add_smul]
    abel
  map_smul' c v := by
    simp only [Prod.smul_fst, Prod.smul_snd, smul_assoc, RingHom.id_apply, smul_add]

#print axioms coordPairMap

lemma coordPairMap_bijective {F : Type*} [Field F] (W : WeierstrassCurve.Affine F) :
    Function.Bijective (coordPairMap W) := by
  refine ⟨?_, ?_⟩
  · rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro v hv
    obtain ⟨h1, h2⟩ := Affine.CoordinateRing.smul_basis_eq_zero hv
    exact Prod.ext h1 h2
  · intro f
    obtain ⟨p, q, h⟩ := Affine.CoordinateRing.exists_smul_basis_eq f
    exact ⟨(p, q), h⟩

#print axioms coordPairMap_bijective

lemma degree_norm_le_iff {F : Type*} [Field F] (W : WeierstrassCurve.Affine F)
    (n : ℕ) (hn : 1 ≤ n) (p q : F[X]) :
    (Algebra.norm F[X] (coordPairMap W (p, q))).degree ≤ n ↔
      p.degree < ((n / 2 + 1 : ℕ) : WithBot ℕ) ∧ q.degree < (((n - 1) / 2 : ℕ) : WithBot ℕ) := by
  change (Algebra.norm F[X] (p • (1 : W.CoordinateRing) +
    q • Affine.CoordinateRing.mk W (X : F[X][X]))).degree ≤ n ↔ _
  rw [Affine.CoordinateRing.degree_norm_smul_basis, max_le_iff]
  apply and_congr
  · obtain h | ⟨d, h⟩ : p.degree = ⊥ ∨ ∃ d : ℕ, p.degree = (d : WithBot ℕ) := by
      cases p.degree <;> simp; exact ⟨_, rfl⟩
    · simp [h]
    · rw [h, nsmul_eq_mul]
      norm_cast
      omega
  · obtain h | ⟨d, h⟩ : q.degree = ⊥ ∨ ∃ d : ℕ, q.degree = (d : WithBot ℕ) := by
      cases q.degree <;> simp; exact ⟨_, rfl⟩
    · simp [h]
    · rw [h, nsmul_eq_mul]
      norm_cast
      omega

#print axioms degree_norm_le_iff

/-- Riemann-Roch on a genus-one curve for the divisor D = nO: on a smooth cubic
y^2 + a₁xy + a₃y = x^3 + a₂x^2 + a₄x + a₆ over a field, the functions with poles only at
the point at infinity O are the elements of the coordinate ring, and the pole order at O of
such a function f is the degree in x of its norm f · f̄. The space L(nO) of functions with
pole order at most n at O has dimension ℓ(nO) = n = deg(nO) + 1 - 1 for every n ≥ 1. -/
theorem finrank_functions_with_poles_only_at_infinity
    {F : Type*} [Field F] (W : WeierstrassCurve.Affine F) [W.IsElliptic] (n : ℕ) (hn : 1 ≤ n) :
    Module.finrank F
      (Submodule.span F {f : W.CoordinateRing | (Algebra.norm F[X] f).degree ≤ n}) = n := by
  set e := LinearEquiv.ofBijective (coordPairMap W) (coordPairMap_bijective W)
  set T : Submodule F (F[X] × F[X]) :=
    (degreeLT F (n / 2 + 1)).prod (degreeLT F ((n - 1) / 2))
  have hS : {f : W.CoordinateRing | (Algebra.norm F[X] f).degree ≤ n} =
      (e : (F[X] × F[X]) →ₗ[F] W.CoordinateRing) '' (T : Set (F[X] × F[X])) := by
    ext f
    obtain ⟨⟨p, q⟩, rfl⟩ := (coordPairMap_bijective W).2 f
    simp only [Set.mem_ofPred_eq, Set.mem_image, SetLike.mem_coe]
    rw [degree_norm_le_iff W n hn]
    constructor
    · rintro ⟨hp, hq⟩
      exact ⟨(p, q), ⟨mem_degreeLT.mpr hp, mem_degreeLT.mpr hq⟩, rfl⟩
    · rintro ⟨⟨p', q'⟩, ⟨hp, hq⟩, h⟩
      have h' : (p', q') = (p, q) := (coordPairMap_bijective W).1 h
      obtain ⟨rfl, rfl⟩ := Prod.ext_iff.mp h'
      exact ⟨mem_degreeLT.mp hp, mem_degreeLT.mp hq⟩
  rw [hS, Submodule.span_image, Submodule.span_eq, LinearEquiv.finrank_map_eq,
    ((Submodule.prodEquiv _ _).trans
      ((degreeLTEquiv F _).prodCongr (degreeLTEquiv F _))).finrank_eq,
    Module.finrank_prod, Module.finrank_fin_fun, Module.finrank_fin_fun]
  omega

/-- On a smooth cubic two single points are linearly equivalent only when they are equal:
the class of the divisor P - O (the ideal class of ⟨X - x, Y - y⟩ in the coordinate ring,
and 0 for O itself) determines the point P. -/
theorem point_linearly_equivalent_iff_eq
    {F : Type*} [Field F] [DecidableEq F] (W : WeierstrassCurve.Affine F) [W.IsElliptic]
    (P Q : W.Point) :
    Affine.Point.toClass P = Affine.Point.toClass Q ↔ P = Q := by
  exact Affine.Point.toClass_injective.eq_iff

/-- The card's smooth neighbour of the nodal cubic: y^2 = x^3 + x^2 + 1 over ℚ. -/
def cardCubic : WeierstrassCurve.Affine ℚ :=
  (⟨0, 1, 0, 0, 1⟩ : WeierstrassCurve ℚ).toAffine

/-- On y^2 = x^3 + x^2 + 1, P = (0, 1), Q = (-1, -1) and (4, -9) are smooth points, and
P + Q ~ (4, -9) + O: the divisor classes of P - O and Q - O add up to that of (4, -9) - O. -/
theorem P_add_Q_linearly_equivalent :
    ∃ (hP : cardCubic.Nonsingular 0 1) (hQ : cardCubic.Nonsingular (-1) (-1))
      (hR : cardCubic.Nonsingular 4 (-9)),
      Affine.Point.toClass (.some _ _ hP) + Affine.Point.toClass (.some _ _ hQ) =
        Affine.Point.toClass (.some _ _ hR) := by
  have hP : cardCubic.Nonsingular 0 1 := by
    rw [Affine.nonsingular_iff', Affine.equation_iff']; norm_num [cardCubic]
  have hQ : cardCubic.Nonsingular (-1) (-1) := by
    rw [Affine.nonsingular_iff', Affine.equation_iff']; norm_num [cardCubic]
  have hR : cardCubic.Nonsingular 4 (-9) := by
    rw [Affine.nonsingular_iff', Affine.equation_iff']; norm_num [cardCubic]
  refine ⟨hP, hQ, hR, ?_⟩
  rw [← map_add, Affine.Point.add_of_X_ne (by norm_num)]
  congr 1
  rw [Affine.Point.some.injEq]
  simp only [Affine.addX, Affine.addY, Affine.negAddY, Affine.negY,
    Affine.slope_of_X_ne (show (0 : ℚ) ≠ -1 by norm_num)]
  norm_num [cardCubic]

-- The cubic is smooth: its discriminant Δ = 16 · (-31) is not 0.
example : cardCubic.Δ = -496 := by
  simp only [cardCubic, WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄,
    WeierstrassCurve.b₆, WeierstrassCurve.b₈]
  norm_num

-- Discriminant of x^3 + ax^2 + bx + c at a = 1, b = 0, c = 1, as printed: -31.
example : (18 * 1 * 0 * 1 - 4 * 1 ^ 3 * 1 + 1 ^ 2 * 0 ^ 2 - 4 * 0 ^ 3 - 27 * 1 ^ 2 : ℤ) = -31 := by
  norm_num

-- Genus of a smooth plane cubic: (3 - 1)(3 - 2)/2 = 1.
example : (3 - 1) * (3 - 2) / 2 = 1 := by norm_num

-- P = (0, 1), Q = (-1, -1), R = (4, 9) and -R = (4, -9) lie on y^2 = x^3 + x^2 + 1.
example : (1 : ℤ) ^ 2 = 0 ^ 3 + 0 ^ 2 + 1 ∧ (-1 : ℤ) ^ 2 = (-1) ^ 3 + (-1) ^ 2 + 1 ∧
    (9 : ℤ) ^ 2 = 4 ^ 3 + 4 ^ 2 + 1 ∧ (-9 : ℤ) ^ 2 = 4 ^ 3 + 4 ^ 2 + 1 := by norm_num

-- The line y = 2x + 1 passes through P, Q and R.
example : (2 * 0 + 1 : ℤ) = 1 ∧ (2 * (-1) + 1 : ℤ) = -1 ∧ (2 * 4 + 1 : ℤ) = 9 := by norm_num

-- On the line: x^3 + x^2 + 1 - (2x + 1)^2 = x^3 - 3x^2 - 4x = (x - 4) x (x + 1).
example (x : ℤ) : x ^ 3 + x ^ 2 + 1 - (2 * x + 1) ^ 2 = (x - 4) * x * (x + 1) ∧
    (x - 4) * x * (x + 1) = x ^ 3 - 3 * x ^ 2 - 4 * x := by
  constructor <;> ring

-- L(P + Q): a + bx + cy vanishing at R = (4, 9) gives a + 4b + 9c = 0; kernel x - 4 and y - 9.
example : (-4 + 4 * 1 + 9 * 0 : ℤ) = 0 ∧ (-9 + 4 * 0 + 9 * 1 : ℤ) = 0 := by norm_num

-- Second solution: (y - 9) - (y - 2x - 1) - 2(x - 4) = 0, so (y - 9)/(y - 2x - 1) = 1 + 2u.
example (x y : ℤ) : (y - 9) - (y - 2 * x - 1) - 2 * (x - 4) = 0 := by ring

-- Riemann-Roch at D = P + Q: 2 + 1 - 1 = 2; with genus 0 wrongly: 3; at D = 0 without ℓ(K - D): 0.
example : (2 + 1 - 1 : ℤ) = 2 ∧ (2 + 1 - 0 : ℤ) = 3 ∧ (0 + 1 - 1 : ℤ) = 0 := by norm_num

-- The monomials x^i y^j (j ≤ 1) with pole order 2i + 3j ≤ n at O: ℓ(nO) = 1, 1, 2, 3, 4, 5, 6.
example : (List.range 7).map (fun n => ((Finset.range 4 ×ˢ Finset.range 2).filter
    (fun e : ℕ × ℕ => 2 * e.1 + 3 * e.2 ≤ n)).card) = [1, 1, 2, 3, 4, 5, 6] := by decide

-- P + Q ~ 2O fails: h = a + bx vanishing at x = 0 and x = -1 has determinant 1·(-1) - 0·1 = -1.
example : (1 * (-1) - 0 * 1 : ℤ) = -1 := by norm_num

-- Nodal cubic y^2 = x^3 + x^2: x = t^2 - 1, y = t^3 - t fits at t = -3, ..., 3.
example : ∀ t ∈ Finset.Icc (-3 : ℤ) 3,
    (t * (t ^ 2 - 1)) ^ 2 = (t ^ 2 - 1) ^ 3 + (t ^ 2 - 1) ^ 2 := by
  intro t _
  ring

#print axioms finrank_functions_with_poles_only_at_infinity
#print axioms point_linearly_equivalent_iff_eq
#print axioms P_add_Q_linearly_equivalent
