-- Inflections and Cayley-Bacharach: over ℂ, a cubic through eight of the nine meeting points of two cubics is a combination of them and passes through the ninth, a smooth point of a cubic is a flex exactly when the Hessian vanishes there, and the Fermat cubic has Hessian −216xyz and exactly nine flexes.
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.LinearAlgebra.Projectivization.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Set.Card
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.ComputeDegree
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.Polynomial.Roots

open MvPolynomial
open scoped LinearAlgebra.Projectivization

/-! Variables: `X 0`, `X 1`, `X 2` are `x`, `y`, `z`, so a plane curve is a homogeneous
`F : MvPolynomial (Fin 3) ℂ`. A point `(x : y : z)` of the projective plane is
`p : ℙ ℂ (Fin 3 → ℂ)`, and `p.rep` is one nonzero vector of coordinates for it; for a
homogeneous polynomial, whether it is zero there does not depend on that choice. -/

/-- The Hessian of `F`: the determinant of the 3 × 3 matrix of second partial derivatives,
a polynomial again (of degree 3 when `F` is a cubic). -/
noncomputable def hessian (F : MvPolynomial (Fin 3) ℂ) : MvPolynomial (Fin 3) ℂ :=
  (Matrix.of fun i j => pderiv i (pderiv j F)).det

/-- `v` gives a smooth point of the curve `F = 0`: `F(v) = 0` and the row of first partials
`(F_x, F_y, F_z)` at `v` is not all zero. -/
def IsSmoothPoint (F : MvPolynomial (Fin 3) ℂ) (v : Fin 3 → ℂ) : Prop :=
  eval v F = 0 ∧ ∃ i, eval v (pderiv i F) ≠ 0

/-- `v` gives an inflection point (flex) of the cubic `F = 0`: `F(v) = 0`, and some line
through it, `v + t w` with `w` not a multiple of `v`, meets the curve three times at `v`:
`F(v + t w) = t^3 F(w)` for every `t`, a triple root at `t = 0`. -/
def IsFlex (F : MvPolynomial (Fin 3) ℂ) (v : Fin 3 → ℂ) : Prop :=
  eval v F = 0 ∧ ∃ w : Fin 3 → ℂ, LinearIndependent ℂ ![v, w] ∧
    ∀ t : ℂ, eval (v + t • w) F = t ^ 3 * eval w F

/-- The Fermat cubic `x^3 + y^3 - z^3`. -/
noncomputable def fermat : MvPolynomial (Fin 3) ℂ := X 0 ^ 3 + X 1 ^ 3 - X 2 ^ 3

/-! Helper lemmas for the Hessian test. -/

noncomputable def cub (c : Fin 10 → ℂ) : MvPolynomial (Fin 3) ℂ :=
  C (c 0) * X 0 ^ 3 + C (c 1) * X 1 ^ 3 + C (c 2) * X 2 ^ 3 + C (c 3) * X 0 ^ 2 * X 1 +
  C (c 4) * X 0 ^ 2 * X 2 + C (c 5) * X 1 ^ 2 * X 0 + C (c 6) * X 1 ^ 2 * X 2 +
  C (c 7) * X 2 ^ 2 * X 0 + C (c 8) * X 2 ^ 2 * X 1 + C (c 9) * X 0 * X 1 * X 2

lemma cub_add (c d : Fin 10 → ℂ) : cub c + cub d = cub (c + d) := by
  simp only [cub, Pi.add_apply, map_add]; ring

lemma monomial_eq3 (d : Fin 3 →₀ ℕ) (r : ℂ) :
    monomial d r = C r * X 0 ^ d 0 * X 1 ^ d 1 * X 2 ^ d 2 := by
  rw [monomial_eq, Finsupp.prod_fintype _ _ (by simp), Fin.prod_univ_three]; ring

set_option linter.unusedTactic false in
lemma exists_cub {F : MvPolynomial (Fin 3) ℂ} (hF : F.IsHomogeneous 3) :
    ∃ c, F = cub c := by
  rw [F.as_sum]
  apply Finset.sum_induction _ (fun G => ∃ c, G = cub c)
  · rintro a b ⟨c, rfl⟩ ⟨d, rfl⟩; exact ⟨c + d, cub_add c d⟩
  · exact ⟨0, by simp [cub]⟩
  · intro d hd
    have h := hF (mem_support_iff.mp hd)
    have h3 : d 0 + d 1 + d 2 = 3 := by
      simpa [Finsupp.weight_eq_sum, Fin.sum_univ_three] using h
    rw [monomial_eq3]
    generalize F.coeff d = r
    generalize d 0 = a at h3 ⊢
    generalize d 1 = b at h3 ⊢
    generalize d 2 = e at h3 ⊢
    obtain rfl : e = 3 - a - b := by omega
    have ha : a ≤ 3 := by omega
    have hb : b ≤ 3 := by omega
    interval_cases a <;> interval_cases b <;> (try (exfalso; omega)) <;>
      simp only [pow_zero, pow_one, mul_one, Nat.reduceSub] <;>
      first
      | (refine ⟨fun i => if i = 0 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 1 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 2 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 3 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 4 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 5 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 6 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 7 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 8 then r else 0, ?_⟩; simp [cub]; (try ring1); done)
      | (refine ⟨fun i => if i = 9 then r else 0, ?_⟩; simp [cub]; (try ring1); done)

@[simp] lemma pderiv_ofNat (i : Fin 3) (n : ℕ) [n.AtLeastTwo] :
    pderiv i (no_index (OfNat.ofNat n) : MvPolynomial (Fin 3) ℂ) = 0 := by
  rw [← map_ofNat C n, pderiv_C]

@[simp] lemma pderiv_natCast' (i : Fin 3) (n : ℕ) :
    pderiv i (n : MvPolynomial (Fin 3) ℂ) = 0 := (pderiv i).map_natCast n

lemma taylor3 {F : MvPolynomial (Fin 3) ℂ} (hF : F.IsHomogeneous 3) (v w : Fin 3 → ℂ) (t : ℂ) :
    eval (v + t • w) F = eval v F + t * ∑ i, w i * eval v (pderiv i F) +
      t ^ 2 / 2 * ∑ i, ∑ j, w i * w j * eval v (pderiv i (pderiv j F)) + t ^ 3 * eval w F := by
  obtain ⟨c, rfl⟩ := exists_cub hF
  simp [cub, Fin.sum_univ_three, pderiv_X, Pi.single_apply]
  ring

lemma bil_vv {F : MvPolynomial (Fin 3) ℂ} (hF : F.IsHomogeneous 3) (v : Fin 3 → ℂ) :
    ∑ i, ∑ j, v i * v j * eval v (pderiv i (pderiv j F)) = 6 * eval v F := by
  obtain ⟨c, rfl⟩ := exists_cub hF
  simp [cub, Fin.sum_univ_three, pderiv_X, Pi.single_apply]
  ring

lemma bil_vw {F : MvPolynomial (Fin 3) ℂ} (hF : F.IsHomogeneous 3) (v w : Fin 3 → ℂ) :
    ∑ i, ∑ j, v i * w j * eval v (pderiv i (pderiv j F)) = 2 * ∑ j, w j * eval v (pderiv j F) := by
  obtain ⟨c, rfl⟩ := exists_cub hF
  simp [cub, Fin.sum_univ_three, pderiv_X, Pi.single_apply]
  ring

lemma euler1 {F : MvPolynomial (Fin 3) ℂ} (hF : F.IsHomogeneous 3) (v : Fin 3 → ℂ) :
    ∑ i, v i * eval v (pderiv i F) = 3 * eval v F := by
  obtain ⟨c, rfl⟩ := exists_cub hF
  simp [cub, Fin.sum_univ_three, pderiv_X, Pi.single_apply]
  ring

lemma eval_hessian (F : MvPolynomial (Fin 3) ℂ) (v : Fin 3 → ℂ) :
    eval v (hessian F) = (Matrix.of fun i j => eval v (pderiv i (pderiv j F))).det := by
  rw [hessian, RingHom.map_det]; rfl
/-- The bilinear form of a 3 × 3 matrix. -/
def bform (M : Matrix (Fin 3) (Fin 3) ℂ) (x y : Fin 3 → ℂ) : ℂ := ∑ i, ∑ j, x i * y j * M i j

lemma bform_symm (M : Matrix (Fin 3) (Fin 3) ℂ) (hM : ∀ i j, M i j = M j i) (x y : Fin 3 → ℂ) :
    bform M x y = bform M y x := by
  simp only [bform, Fin.sum_univ_three, hM 1 0, hM 2 0, hM 2 1]; ring

lemma det_congr_form (M : Matrix (Fin 3) (Fin 3) ℂ) (hM : ∀ i j, M i j = M j i)
    (v w u : Fin 3 → ℂ) (h11 : bform M v v = 0) (h12 : bform M v w = 0) :
    (Matrix.det ![v, w, u]) ^ 2 * M.det = -(bform M v u) ^ 2 * bform M w w := by
  set P : Matrix (Fin 3) (Fin 3) ℂ := ![v, w, u] with hP
  have hdet : (P * M * P.transpose).det = P.det ^ 2 * M.det := by
    rw [Matrix.det_mul, Matrix.det_mul, Matrix.det_transpose]; ring
  have hent : ∀ i j, (P * M * P.transpose) i j = bform M (P i) (P j) := by
    intro i j
    simp only [Matrix.mul_apply, Matrix.transpose_apply, bform, Fin.sum_univ_three]; ring
  rw [← hdet, Matrix.det_fin_three]
  simp only [hent]
  have e0 : P 0 = v := rfl
  have e1 : P 1 = w := rfl
  have e2 : P 2 = u := rfl
  rw [e0, e1, e2, bform_symm M hM w v, bform_symm M hM u v, bform_symm M hM u w, h11, h12]
  ring

lemma dot_star_ne_zero {x : Fin 3 → ℂ} (hx : x ≠ 0) : x ⬝ᵥ star x ≠ 0 := by
  intro h
  apply hx
  have h' : ((Complex.normSq (x 0) + Complex.normSq (x 1) + Complex.normSq (x 2) : ℝ) : ℂ) = 0 := by
    rw [← h]; simp [dotProduct, Fin.sum_univ_three, Complex.mul_conj]
  have h'' : Complex.normSq (x 0) + Complex.normSq (x 1) + Complex.normSq (x 2) = 0 := by
    exact_mod_cast h'
  have a0 := Complex.normSq_nonneg (x 0)
  have a1 := Complex.normSq_nonneg (x 1)
  have a2 := Complex.normSq_nonneg (x 2)
  have z0 : x 0 = 0 := Complex.normSq_eq_zero.mp (by linarith)
  have z1 : x 1 = 0 := Complex.normSq_eq_zero.mp (by linarith)
  have z2 : x 2 = 0 := Complex.normSq_eq_zero.mp (by linarith)
  funext i
  fin_cases i
  · exact z0
  · exact z1
  · exact z2

lemma hessian_test
    (F : MvPolynomial (Fin 3) ℂ) (hF : F.IsHomogeneous 3)
    (v : Fin 3 → ℂ) (hv : v ≠ 0) (hs : IsSmoothPoint F v) :
    IsFlex F v ↔ eval v (hessian F) = 0 := by
  obtain ⟨hFv, i0, hi0⟩ := hs
  set g : Fin 3 → ℂ := fun i => eval v (pderiv i F) with hg
  set M : Matrix (Fin 3) (Fin 3) ℂ := Matrix.of fun i j => eval v (pderiv i (pderiv j F)) with hMdef
  have hMs : ∀ i j, M i j = M j i := by intro i j; simp [M, pderiv_comm]
  have hg0 : g ≠ 0 := fun h => hi0 (congrFun h i0)
  have hgu : g ⬝ᵥ star g ≠ 0 := dot_star_ne_zero hg0
  have hgv : g ⬝ᵥ v = 0 := by
    have := euler1 hF v
    rw [hFv, mul_zero] at this
    rw [← this, dotProduct]; exact Finset.sum_congr rfl fun i _ => mul_comm _ _
  have hS1 : ∀ w, ∑ i, w i * eval v (pderiv i F) = g ⬝ᵥ w := fun w => by
    rw [dotProduct]; exact Finset.sum_congr rfl fun i _ => mul_comm _ _
  have hS2 : ∀ w, ∑ i, ∑ j, w i * w j * eval v (pderiv i (pderiv j F)) = bform M w w :=
    fun w => rfl
  have hB11 : bform M v v = 0 := by
    have := bil_vv hF v; rw [hFv, mul_zero] at this; exact this
  have hB12 : ∀ w, bform M v w = 2 * (g ⬝ᵥ w) := fun w => by
    rw [← hS1]; exact bil_vw hF v w
  have key : ∀ w, g ⬝ᵥ w = 0 → LinearIndependent ℂ ![v, w] → Matrix.det ![v, w, star g] ≠ 0 := by
    intro w hgw hlin hdet
    obtain ⟨x, hx0, hx⟩ := Matrix.exists_vecMul_eq_zero_iff.mpr hdet
    have hrow : x 0 • v + x 1 • w + x 2 • star g = 0 := by
      funext j
      have := congrFun hx j
      simp only [Matrix.vecMul, dotProduct, Fin.sum_univ_three] at this
      simpa using this
    have hx2 : x 2 = 0 := by
      have := congrArg (fun y => g ⬝ᵥ y) hrow
      simp only [dotProduct_add, dotProduct_smul, hgv, hgw, smul_eq_mul, dotProduct_zero] at this
      simpa [hgu] using this
    rw [hx2, zero_smul, add_zero] at hrow
    obtain ⟨h0, h1⟩ := LinearIndependent.pair_iff.mp hlin _ _ hrow
    apply hx0
    funext i; fin_cases i <;> simp [h0, h1, hx2]
  rw [eval_hessian]
  constructor
  · rintro ⟨_, w, hlin, ht⟩
    have e1 := taylor3 hF v w 1
    have e2 := taylor3 hF v w (-1)
    rw [ht, hS1, hS2, hFv] at e1 e2
    have hgw : g ⬝ᵥ w = 0 := by linear_combination (e2 - e1) / 2
    have hww : bform M w w = 0 := by linear_combination -(e1 + e2)
    have hd := det_congr_form M hMs v w (star g) hB11 (by rw [hB12, hgw, mul_zero])
    rw [hww, mul_zero] at hd
    exact (mul_eq_zero.mp hd).resolve_left (pow_ne_zero 2 (key w hgw hlin))
  · intro hdet
    set w := crossProduct g (star v) with hw
    have hgw : g ⬝ᵥ w = 0 := dot_self_cross g (star v)
    have hvv : v ⬝ᵥ star v ≠ 0 := dot_star_ne_zero hv
    have hw0 : w ≠ 0 := by
      intro h
      have := cross_dot_cross g (star v) (star g) v
      rw [← hw, h, zero_dotProduct, hgv, zero_mul, sub_zero] at this
      exact mul_ne_zero hgu (by rw [dotProduct_comm]; exact hvv) this.symm
    have hlin : LinearIndependent ℂ ![v, w] := by
      rw [LinearIndependent.pair_iff]
      intro s t hst
      have := congrArg (fun y => y ⬝ᵥ star v) hst
      have hwv : w ⬝ᵥ star v = 0 := by
        rw [dotProduct_comm]; exact dot_cross_self g (star v)
      simp only [add_dotProduct, smul_dotProduct, hwv, smul_eq_mul, mul_zero, add_zero,
        zero_dotProduct] at this
      have hs : s = 0 := (mul_eq_zero.mp this).resolve_right hvv
      refine ⟨hs, ?_⟩
      rw [hs, zero_smul, zero_add] at hst
      exact (smul_eq_zero.mp hst).resolve_right hw0
    have hd := det_congr_form M hMs v w (star g) hB11 (by rw [hB12, hgw, mul_zero])
    rw [hdet, mul_zero, hB12] at hd
    have hww : bform M w w = 0 := by
      have h2 : (2 * (g ⬝ᵥ star g)) ^ 2 ≠ 0 := pow_ne_zero 2 (mul_ne_zero two_ne_zero hgu)
      have : (2 * (g ⬝ᵥ star g)) ^ 2 * bform M w w = 0 := by linear_combination hd
      exact (mul_eq_zero.mp this).resolve_left h2
    refine ⟨hFv, w, hlin, fun t => ?_⟩
    rw [taylor3 hF, hS1, hS2, hFv, hgw, hww]; ring

/-! Helper lemmas for the Fermat cubic. -/

lemma fermat_hessian : hessian fermat = -216 * X 0 * X 1 * X 2 := by
  rw [hessian, Matrix.det_fin_three]
  simp [fermat, pderiv_X, Pi.single_apply]
  ring

lemma fermat_hom : fermat.IsHomogeneous 3 :=
  ((isHomogeneous_X_pow _ _).add (isHomogeneous_X_pow _ _)).sub (isHomogeneous_X_pow _ _)

lemma eval_fermat (v : Fin 3 → ℂ) : eval v fermat = v 0 ^ 3 + v 1 ^ 3 - v 2 ^ 3 := by
  simp [fermat]

lemma vec_eq_zero {v : Fin 3 → ℂ} (h0 : v 0 = 0) (h1 : v 1 = 0) (h2 : v 2 = 0) : v = 0 := by
  funext i; fin_cases i
  · exact h0
  · exact h1
  · exact h2

lemma fermat_flex_iff (v : Fin 3 → ℂ) (hv : v ≠ 0) :
    IsFlex fermat v ↔ v 0 ^ 3 + v 1 ^ 3 - v 2 ^ 3 = 0 ∧ v 0 * v 1 * v 2 = 0 := by
  by_cases hon : v 0 ^ 3 + v 1 ^ 3 - v 2 ^ 3 = 0
  · have hs : IsSmoothPoint fermat v := by
      refine ⟨by rw [eval_fermat]; exact hon, ?_⟩
      by_contra hc
      push Not at hc
      have e0 := hc 0
      have e1 := hc 1
      have e2 := hc 2
      simp [fermat, pderiv_X] at e0 e1 e2
      exact hv (vec_eq_zero e0 e1 e2)
    rw [hessian_test fermat fermat_hom v hv hs, fermat_hessian]
    simp only [hon, true_and]
    simp only [map_mul, map_neg, eval_X, map_ofNat]
    constructor
    · intro h
      have : (-216 : ℂ) ≠ 0 := by norm_num
      have h' : (-216 : ℂ) * (v 0 * v 1 * v 2) = 0 := by linear_combination h
      exact (mul_eq_zero.mp h').resolve_left this
    · intro h; linear_combination (-216 : ℂ) * h
  · constructor
    · rintro ⟨h, _⟩; rw [eval_fermat] at h; exact absurd h hon
    · rintro ⟨h, _⟩; exact absurd h hon

noncomputable def ω : ℂ := (-1 + Complex.I * (Real.sqrt 3 : ℂ)) / 2

lemma hω : ω ^ 2 + ω + 1 = 0 := by
  have h3 : ((Real.sqrt 3 : ℝ) : ℂ) ^ 2 = 3 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
  have hI := Complex.I_sq
  unfold ω
  linear_combination (((Real.sqrt 3 : ℝ) : ℂ) ^ 2 * hI - h3) / 4

lemma hω3 : ω ^ 3 = 1 := by linear_combination (ω - 1) * hω
lemma hω6 : ω ^ 6 = 1 := by
  rw [show ω ^ 6 = (ω ^ 3) ^ 2 by ring, hω3]; norm_num
lemma hω1 : ω ≠ 1 := by intro h; have := hω; rw [h] at this; norm_num at this
lemma hω0 : ω ≠ 0 := by intro h; have := hω; rw [h] at this; norm_num at this
lemma hω2 : ω ^ 2 ≠ 1 := by
  intro h
  have h' : ω = -2 := by linear_combination hω - h
  have := hω; rw [h'] at this; norm_num at this
lemma hω21 : ω ^ 2 ≠ ω := by
  intro h
  have : ω * (ω - 1) = 0 := by linear_combination h
  rcases mul_eq_zero.mp this with h0 | h1
  · exact hω0 h0
  · exact hω1 (by linear_combination h1)

lemma hωn1 : ω ≠ -1 := by intro h; have := hω; rw [h] at this; norm_num at this
lemma hω2n1 : ω ^ 2 ≠ -1 := by
  intro h; apply hω0; linear_combination hω - h
lemma hω20 : ω ^ 2 ≠ 0 := pow_ne_zero 2 hω0
lemma hωω : ω * ω = ω ^ 2 := by ring
lemma hωω2 : ω * ω ^ 2 = 1 := by linear_combination hω3
lemma hω2ω : ω ^ 2 * ω = 1 := by linear_combination hω3
lemma hω2ω2 : ω ^ 2 * ω ^ 2 = ω := by linear_combination ω * hω3

lemma cube_root {z : ℂ} (h : z ^ 3 = 1) : z = 1 ∨ z = ω ∨ z = ω ^ 2 := by
  have : (z - 1) * (z - ω) * (z - ω ^ 2) = 0 := by
    linear_combination h + (-z ^ 2 + ω * z - ω + 1) * hω
  rcases mul_eq_zero.mp this with h12 | h3
  · rcases mul_eq_zero.mp h12 with h1 | h2
    · left; linear_combination h1
    · right; left; linear_combination h2
  · right; right; linear_combination h3

/-- The nine flexes of the Fermat cubic, as coordinate vectors. -/
noncomputable def fvec : Fin 9 → Fin 3 → ℂ :=
  ![![0, 1, 1], ![0, 1, ω], ![0, 1, ω ^ 2], ![1, 0, 1], ![1, 0, ω], ![1, 0, ω ^ 2],
    ![1, -1, 0], ![1, -ω, 0], ![1, -ω ^ 2, 0]]

lemma fvec_ne (k : Fin 9) : fvec k ≠ 0 := by
  intro h
  fin_cases k
  · have := congrFun h 1; simp [fvec] at this
  · have := congrFun h 1; simp [fvec] at this
  · have := congrFun h 1; simp [fvec] at this
  all_goals (have := congrFun h 0; simp [fvec] at this)

noncomputable def fpt (k : Fin 9) : ℙ ℂ (Fin 3 → ℂ) := Projectivization.mk ℂ (fvec k) (fvec_ne k)

lemma fvec_flex (k : Fin 9) :
    fvec k 0 ^ 3 + fvec k 1 ^ 3 - fvec k 2 ^ 3 = 0 ∧ fvec k 0 * fvec k 1 * fvec k 2 = 0 := by
  fin_cases k <;> simp [fvec] <;> ring_nf <;> simp [hω3, hω6]

lemma fpt_injective : Function.Injective fpt := by
  intro i j h
  rw [fpt, fpt, Projectivization.mk_eq_mk_iff'] at h
  obtain ⟨a, ha⟩ := h
  have h0 := congrFun ha 0
  have h1 := congrFun ha 1
  have h2 := congrFun ha 2
  fin_cases i <;> fin_cases j <;> simp [fvec] at h0 h1 h2 ⊢ <;> subst_vars <;>
    simp_all [hω1, hω21, hω1.symm, hω2.symm, hω21.symm, hω0, hω0.symm, hωn1, hω20.symm]

lemma fpt_hit (p : ℙ ℂ (Fin 3 → ℂ)) (k : Fin 9) (a : ℂ) (h : a • fvec k = p.rep) : fpt k = p := by
  conv_rhs => rw [← Projectivization.mk_rep p]
  rw [fpt, Projectivization.mk_eq_mk_iff']
  refine ⟨a⁻¹, ?_⟩
  have ha : a ≠ 0 := by
    rintro rfl; rw [zero_smul] at h; exact p.rep_ne_zero h.symm
  rw [← h, smul_smul, inv_mul_cancel₀ ha, one_smul]

/-! Cayley-Bacharach infrastructure. -/

/-- A cubic form as a function of its 10 coefficients. -/
def E3 (c : Fin 10 → ℂ) (v : Fin 3 → ℂ) : ℂ :=
  c 0 * v 0 ^ 3 + c 1 * v 1 ^ 3 + c 2 * v 2 ^ 3 + c 3 * v 0 ^ 2 * v 1 +
  c 4 * v 0 ^ 2 * v 2 + c 5 * v 1 ^ 2 * v 0 + c 6 * v 1 ^ 2 * v 2 +
  c 7 * v 2 ^ 2 * v 0 + c 8 * v 2 ^ 2 * v 1 + c 9 * v 0 * v 1 * v 2

/-- The mixed term of a cubic form along `a` in direction `b`. -/
def A3 (c : Fin 10 → ℂ) (a b : Fin 3 → ℂ) : ℂ :=
  b 0 * (3 * c 0 * a 0 ^ 2 + 2 * c 3 * a 0 * a 1 + 2 * c 4 * a 0 * a 2 + c 5 * a 1 ^ 2 +
      c 7 * a 2 ^ 2 + c 9 * a 1 * a 2) +
  b 1 * (3 * c 1 * a 1 ^ 2 + c 3 * a 0 ^ 2 + 2 * c 5 * a 1 * a 0 + 2 * c 6 * a 1 * a 2 +
      c 8 * a 2 ^ 2 + c 9 * a 0 * a 2) +
  b 2 * (3 * c 2 * a 2 ^ 2 + c 4 * a 0 ^ 2 + c 6 * a 1 ^ 2 + 2 * c 7 * a 2 * a 0 +
      2 * c 8 * a 2 * a 1 + c 9 * a 0 * a 1)

/-- A conic (quadratic form) as a function of its 6 coefficients. -/
def E2 (q : Fin 6 → ℂ) (v : Fin 3 → ℂ) : ℂ :=
  q 0 * v 0 ^ 2 + q 1 * v 1 ^ 2 + q 2 * v 2 ^ 2 + q 3 * v 0 * v 1 + q 4 * v 0 * v 2 +
  q 5 * v 1 * v 2

/-- The polar bilinear form of a conic. -/
noncomputable def B2 (q : Fin 6 → ℂ) (u v : Fin 3 → ℂ) : ℂ :=
  q 0 * u 0 * v 0 + q 1 * u 1 * v 1 + q 2 * u 2 * v 2 + q 3 * (u 0 * v 1 + u 1 * v 0) / 2 +
  q 4 * (u 0 * v 2 + u 2 * v 0) / 2 + q 5 * (u 1 * v 2 + u 2 * v 1) / 2

lemma eval_cub (c : Fin 10 → ℂ) (v : Fin 3 → ℂ) : eval v (cub c) = E3 c v := by
  simp [cub, E3]

lemma E3_smul (c : Fin 10 → ℂ) (s : ℂ) (v : Fin 3 → ℂ) : E3 c (s • v) = s ^ 3 * E3 c v := by
  simp [E3]; ring

lemma E3_bin (c : Fin 10 → ℂ) (s t : ℂ) (a b : Fin 3 → ℂ) :
    E3 c (s • a + t • b) = s ^ 3 * E3 c a + s ^ 2 * t * A3 c a b + s * t ^ 2 * A3 c b a +
      t ^ 3 * E3 c b := by
  simp [E3, A3]; ring

lemma E3_add_smul (c : Fin 10 → ℂ) (s t : ℂ) (a b : Fin 3 → ℂ) :
    E3 c (s • a + t • b) = s ^ 3 * E3 c a + s ^ 2 * t * A3 c a b + s * t ^ 2 * A3 c b a +
      t ^ 3 * E3 c b := E3_bin c s t a b

lemma E2_lin3 (q : Fin 6 → ℂ) (x y z : ℂ) (a b c : Fin 3 → ℂ) :
    E2 q (x • a + y • b + z • c) = x ^ 2 * E2 q a + y ^ 2 * E2 q b + z ^ 2 * E2 q c +
      2 * x * y * B2 q a b + 2 * x * z * B2 q a c + 2 * y * z * B2 q b c := by
  simp [E2, B2]; ring

lemma B2_self (q : Fin 6 → ℂ) (v : Fin 3 → ℂ) : B2 q v v = E2 q v := by
  simp [E2, B2]; ring

lemma B2_symm (q : Fin 6 → ℂ) (u v : Fin 3 → ℂ) : B2 q u v = B2 q v u := by
  simp [B2]; ring

lemma B2_lin3 (q : Fin 6 → ℂ) (u : Fin 3 → ℂ) (x y z : ℂ) (a b c : Fin 3 → ℂ) :
    B2 q u (x • a + y • b + z • c) = x * B2 q u a + y * B2 q u b + z * B2 q u c := by
  simp [B2]; ring

lemma E2_smul (q : Fin 6 → ℂ) (s : ℂ) (v : Fin 3 → ℂ) : E2 q (s • v) = s ^ 2 * E2 q v := by
  simp [E2]; ring

lemma cramer (a b c v : Fin 3 → ℂ) :
    (a ⬝ᵥ crossProduct b c) • v = (v ⬝ᵥ crossProduct b c) • a + (v ⬝ᵥ crossProduct c a) • b +
      (v ⬝ᵥ crossProduct a b) • c := by
  funext i
  fin_cases i <;> simp [cross_apply, dotProduct, Fin.sum_univ_three] <;> ring

lemma dual_cramer (a b c n : Fin 3 → ℂ) :
    (a ⬝ᵥ crossProduct b c) • n = (n ⬝ᵥ a) • crossProduct b c + (n ⬝ᵥ b) • crossProduct c a +
      (n ⬝ᵥ c) • crossProduct a b := by
  funext i
  fin_cases i <;> simp [cross_apply, dotProduct, Fin.sum_univ_three] <;> ring

/-- The conic `(n ⬝ v) (m ⬝ v)`, a pair of lines. -/
def lp (n m : Fin 3 → ℂ) : Fin 6 → ℂ :=
  ![n 0 * m 0, n 1 * m 1, n 2 * m 2, n 0 * m 1 + n 1 * m 0, n 0 * m 2 + n 2 * m 0,
    n 1 * m 2 + n 2 * m 1]

lemma E2_lp (n m v : Fin 3 → ℂ) : E2 (lp n m) v = (n ⬝ᵥ v) * (m ⬝ᵥ v) := by
  simp [E2, lp, dotProduct, Fin.sum_univ_three]; ring

/-- The cubic `(n ⬝ v) Q(v)`, a line times a conic. -/
def lc (n : Fin 3 → ℂ) (q : Fin 6 → ℂ) : Fin 10 → ℂ :=
  ![n 0 * q 0, n 1 * q 1, n 2 * q 2, n 0 * q 3 + n 1 * q 0, n 0 * q 4 + n 2 * q 0,
    n 1 * q 3 + n 0 * q 1, n 1 * q 5 + n 2 * q 1, n 2 * q 4 + n 0 * q 2, n 2 * q 5 + n 1 * q 2,
    n 0 * q 5 + n 1 * q 4 + n 2 * q 3]

lemma E3_lc (n : Fin 3 → ℂ) (q : Fin 6 → ℂ) (v : Fin 3 → ℂ) :
    E3 (lc n q) v = (n ⬝ᵥ v) * E2 q v := by
  simp [E3, E2, lc, dotProduct, Fin.sum_univ_three]; ring

lemma E2_eq_zero_of_forall {q : Fin 6 → ℂ} (h : ∀ v, E2 q v = 0) : q = 0 := by
  have h0 := h ![1, 0, 0]
  have h1 := h ![0, 1, 0]
  have h2 := h ![0, 0, 1]
  have h3 := h ![1, 1, 0]
  have h4 := h ![1, 0, 1]
  have h5 := h ![0, 1, 1]
  simp [E2] at h0 h1 h2 h3 h4 h5
  funext i
  fin_cases i
  · exact h0
  · exact h1
  · exact h2
  · show q 3 = 0; linear_combination h3 - h0 - h1
  · show q 4 = 0; linear_combination h4 - h0 - h2
  · show q 5 = 0; linear_combination h5 - h1 - h2

/-- The evaluation of cubics at a family of points, as a linear map. -/
def evC {ι : Type*} (pts : ι → Fin 3 → ℂ) : (Fin 10 → ℂ) →ₗ[ℂ] (ι → ℂ) where
  toFun c i := E3 c (pts i)
  map_add' c d := by funext i; simp [E3]; ring
  map_smul' s c := by funext i; simp [E3]; ring

/-- The evaluation of conics at a family of points, as a linear map. -/
def evQ {ι : Type*} (pts : ι → Fin 3 → ℂ) : (Fin 6 → ℂ) →ₗ[ℂ] (ι → ℂ) where
  toFun c i := E2 c (pts i)
  map_add' c d := by funext i; simp [E2]; ring
  map_smul' s c := by funext i; simp [E2]; ring

/-- The data of the Cayley-Bacharach theorem: nine distinct points, two cubics through them,
and no tenth common zero. -/
structure Cfg (p : Fin 9 → Fin 3 → ℂ) (f g : Fin 10 → ℂ) : Prop where
  ne : ∀ i, p i ≠ 0
  np : ∀ i j, i ≠ j → ∀ c : ℂ, p i ≠ c • p j
  zf : ∀ i, E3 f (p i) = 0
  zg : ∀ i, E3 g (p i) = 0
  ten : ∀ v : Fin 10 → Fin 3 → ℂ, (∀ m, v m ≠ 0) → (∀ m m', m ≠ m' → ∀ c : ℂ, v m ≠ c • v m') →
    (∀ m, E3 f (v m) = 0) → (∀ m, E3 g (v m) = 0) → False

lemma Cfg.cross_ne {p f g} (h : Cfg p f g) {i j : Fin 9} (hij : i ≠ j) :
    crossProduct (p i) (p j) ≠ 0 := by
  rw [crossProduct_ne_zero_iff_linearIndependent, LinearIndependent.pair_iff' (h.ne i)]
  intro a ha
  exact h.np j i (Ne.symm hij) a ha.symm

lemma span_of_perp (a b v : Fin 3 → ℂ) (hab : crossProduct a b ≠ 0)
    (hv : crossProduct a b ⬝ᵥ v = 0) : ∃ s t : ℂ, v = s • a + t • b := by
  set c := star (crossProduct a b) with hc
  have hD : a ⬝ᵥ crossProduct b c ≠ 0 := by
    rw [triple_product_permutation, triple_product_permutation, dotProduct_comm]
    exact dot_star_ne_zero hab
  have e := cramer a b c v
  have hv' : v ⬝ᵥ crossProduct a b = 0 := by rw [dotProduct_comm]; exact hv
  rw [hv', zero_smul, add_zero] at e
  refine ⟨(v ⬝ᵥ crossProduct b c) / (a ⬝ᵥ crossProduct b c),
    (v ⬝ᵥ crossProduct c a) / (a ⬝ᵥ crossProduct b c), ?_⟩
  funext i
  have ei := congrFun e i
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul] at ei ⊢
  field_simp
  linear_combination ei

lemma det_zero_of_perp (n a b c : Fin 3 → ℂ) (hn : n ≠ 0) (ha : n ⬝ᵥ a = 0)
    (hb : n ⬝ᵥ b = 0) (hc : n ⬝ᵥ c = 0) : a ⬝ᵥ crossProduct b c = 0 := by
  have e := dual_cramer a b c n
  rw [ha, hb, hc] at e
  simp only [zero_smul, add_zero] at e
  exact (smul_eq_zero.mp e).resolve_right hn

lemma line_vanish (c : Fin 10 → ℂ) (a b : Fin 3 → ℂ) (s1 t1 s2 t2 : ℂ) (hs1 : s1 ≠ 0)
    (ht1 : t1 ≠ 0) (hs2 : s2 ≠ 0) (ht2 : t2 ≠ 0) (hdet : s1 * t2 - s2 * t1 ≠ 0)
    (ha : E3 c a = 0) (hb : E3 c b = 0) (h1 : E3 c (s1 • a + t1 • b) = 0)
    (h2 : E3 c (s2 • a + t2 • b) = 0) (s t : ℂ) : E3 c (s • a + t • b) = 0 := by
  rw [E3_bin, ha, hb] at h1 h2 ⊢
  have e1 : s1 * A3 c a b + t1 * A3 c b a = 0 := by
    have : s1 * t1 * (s1 * A3 c a b + t1 * A3 c b a) = 0 := by linear_combination h1
    exact (mul_eq_zero.mp this).resolve_left (mul_ne_zero hs1 ht1)
  have e2 : s2 * A3 c a b + t2 * A3 c b a = 0 := by
    have : s2 * t2 * (s2 * A3 c a b + t2 * A3 c b a) = 0 := by linear_combination h2
    exact (mul_eq_zero.mp this).resolve_left (mul_ne_zero hs2 ht2)
  have hA : A3 c a b = 0 := by
    have : (s1 * t2 - s2 * t1) * A3 c a b = 0 := by linear_combination t2 * e1 - t1 * e2
    exact (mul_eq_zero.mp this).resolve_left hdet
  have hB : A3 c b a = 0 := by
    have : (s1 * t2 - s2 * t1) * A3 c b a = 0 := by linear_combination s1 * e2 - s2 * e1
    exact (mul_eq_zero.mp this).resolve_left hdet
  rw [hA, hB]; ring

lemma Cfg.ten_line {p f g} (h : Cfg p f g) (a b : Fin 3 → ℂ) (hab : LinearIndependent ℂ ![a, b])
    (hf : ∀ t : ℂ, E3 f (a + t • b) = 0) (hg : ∀ t : ℂ, E3 g (a + t • b) = 0) : False := by
  refine h.ten (fun m => a + ((m : ℕ) : ℂ) • b) ?_ ?_ (fun m => hf _) (fun m => hg _)
  · intro m hm
    have := LinearIndependent.pair_iff.mp hab 1 ((m : ℕ) : ℂ) (by rw [one_smul]; exact hm)
    exact one_ne_zero this.1
  · intro m m' hmm' c hc
    have := LinearIndependent.pair_iff.mp hab (1 - c) (((m : ℕ) : ℂ) - c * ((m' : ℕ) : ℂ)) (by
      rw [sub_smul, sub_smul, one_smul, mul_smul]
      have : a + ((m : ℕ) : ℂ) • b - c • (a + ((m' : ℕ) : ℂ) • b) = 0 := by rw [hc]; simp
      rw [← this, smul_add]; abel)
    have hc1 : c = 1 := by linear_combination -this.1
    have := this.2
    rw [hc1, one_mul, sub_eq_zero, Nat.cast_inj] at this
    exact hmm' (Fin.ext this)

lemma Cfg.no_four {p f g} (h : Cfg p f g) {n : Fin 3 → ℂ} (hn : n ≠ 0) {i j k l : Fin 9}
    (hij : i ≠ j) (hik : i ≠ k) (hil : i ≠ l) (hjk : j ≠ k) (hjl : j ≠ l) (hkl : k ≠ l)
    (hi : n ⬝ᵥ p i = 0) (hj : n ⬝ᵥ p j = 0) (hk : n ⬝ᵥ p k = 0) (hl : n ⬝ᵥ p l = 0) : False := by
  have hc := h.cross_ne hij
  have hk' : crossProduct (p i) (p j) ⬝ᵥ p k = 0 := by
    rw [dotProduct_comm]; exact det_zero_of_perp n _ _ _ hn hk hi hj
  have hl' : crossProduct (p i) (p j) ⬝ᵥ p l = 0 := by
    rw [dotProduct_comm]; exact det_zero_of_perp n _ _ _ hn hl hi hj
  obtain ⟨s1, t1, e1⟩ := span_of_perp _ _ _ hc hk'
  obtain ⟨s2, t2, e2⟩ := span_of_perp _ _ _ hc hl'
  have hs1 : s1 ≠ 0 := by
    intro hs; apply h.np k j (Ne.symm hjk) t1; rw [e1, hs]; simp
  have ht1 : t1 ≠ 0 := by
    intro ht; apply h.np k i (Ne.symm hik) s1; rw [e1, ht]; simp
  have hs2 : s2 ≠ 0 := by
    intro hs; apply h.np l j (Ne.symm hjl) t2; rw [e2, hs]; simp
  have ht2 : t2 ≠ 0 := by
    intro ht; apply h.np l i (Ne.symm hil) s2; rw [e2, ht]; simp
  have hdet : s1 * t2 - s2 * t1 ≠ 0 := by
    intro hd
    apply h.np k l hkl (s1 / s2)
    rw [e1, e2]
    funext x
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    field_simp
    linear_combination (-(p j x)) * hd
  have hli := (crossProduct_ne_zero_iff_linearIndependent).mp hc
  have key : ∀ c : Fin 10 → ℂ, (∀ m, E3 c (p m) = 0) → ∀ t : ℂ, E3 c (p i + t • p j) = 0 := by
    intro c hc0 t
    have := line_vanish c (p i) (p j) s1 t1 s2 t2 hs1 ht1 hs2 ht2 hdet (hc0 i) (hc0 j)
      (by rw [← e1]; exact hc0 k) (by rw [← e2]; exact hc0 l) 1 t
    rwa [one_smul] at this
  exact h.ten_line _ _ hli (key f h.zf) (key g h.zg)

lemma Cfg.card_line {p f g} (h : Cfg p f g) {n : Fin 3 → ℂ} (hn : n ≠ 0) :
    (Finset.univ.filter (fun i => n ⬝ᵥ p i = 0)).card ≤ 3 := by
  by_contra hc
  rw [not_le] at hc
  set s := Finset.univ.filter (fun i => n ⬝ᵥ p i = 0) with hs
  obtain ⟨i, hi⟩ : s.Nonempty := Finset.card_pos.mp (by omega)
  have : 2 < (s.erase i).card := by rw [Finset.card_erase_of_mem hi]; omega
  obtain ⟨j, k, l, hj, hk, hl, hjk, hjl, hkl⟩ := Finset.two_lt_card_iff.mp this
  simp only [hs, Finset.mem_erase, Finset.mem_filter, Finset.mem_univ, true_and] at hi hj hk hl
  exact h.no_four hn (Ne.symm hj.1) (Ne.symm hk.1) (Ne.symm hl.1) hjk hjl hkl hi hj.2 hk.2 hl.2

lemma Cfg.no_four_col {p f g} (h : Cfg p f g) {a b c d : Fin 9} (hab : a ≠ b) (hac : a ≠ c)
    (had : a ≠ d) (hbc : b ≠ c) (hbd : b ≠ d) (hcd : c ≠ d)
    (h1 : crossProduct (p a) (p b) ⬝ᵥ p c = 0) (h2 : crossProduct (p a) (p b) ⬝ᵥ p d = 0) :
    False := by
  refine h.no_four (h.cross_ne hab) hab hac had hbc hbd hcd ?_ ?_ h1 h2
  · rw [dotProduct_comm]; exact dot_self_cross _ _
  · rw [dotProduct_comm]; exact dot_cross_self _ _

/-- A linear map from `ℂ^N` that can single out each coordinate is onto. -/
lemma finrank_ker_of_sep {N : ℕ} {ι : Type*} [Fintype ι] [DecidableEq ι]
    (L : (Fin N → ℂ) →ₗ[ℂ] (ι → ℂ))
    (hsep : ∀ i, ∃ c, L c i ≠ 0 ∧ ∀ j, j ≠ i → L c j = 0) :
    Module.finrank ℂ (LinearMap.ker L) + Fintype.card ι = N := by
  choose c hc0 hc1 using hsep
  have hr : LinearMap.range L = ⊤ := by
    rw [eq_top_iff]
    intro y _
    refine ⟨∑ i, (y i / L (c i) i) • c i, ?_⟩
    funext j
    simp only [map_sum, map_smul, Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
    rw [Finset.sum_eq_single j]
    · field_simp [hc0 j]
    · intro b _ hb; rw [hc1 b j (Ne.symm hb), mul_zero]
    · simp
  have := L.finrank_range_add_finrank_ker
  rw [hr, finrank_top, Module.finrank_fintype_fun_eq_card, Module.finrank_fin_fun] at this
  omega

lemma conic_exists (p : Fin 9 → Fin 3 → ℂ) (T : Finset (Fin 9)) (hT : T.card ≤ 5) :
    ∃ q : Fin 6 → ℂ, q ≠ 0 ∧ ∀ s ∈ T, E2 q (p s) = 0 := by
  have hker : LinearMap.ker (evQ (fun s : T => p s)) ≠ ⊥ := by
    apply LinearMap.ker_ne_bot_of_finrank_lt
    rw [Module.finrank_fintype_fun_eq_card, Module.finrank_fin_fun, Fintype.card_coe]
    omega
  obtain ⟨q, hq, hq0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot hker
  refine ⟨q, hq0, fun s hs => ?_⟩
  have := congrFun (LinearMap.mem_ker.mp hq) ⟨s, hs⟩
  exact this

lemma cross_dot_left (a b : Fin 3 → ℂ) : crossProduct a b ⬝ᵥ a = 0 := by
  rw [dotProduct_comm]; exact dot_self_cross _ _

lemma cross_dot_right (a b : Fin 3 → ℂ) : crossProduct a b ⬝ᵥ b = 0 := by
  rw [dotProduct_comm]; exact dot_cross_self _ _

lemma on_perm {a b c : Fin 3 → ℂ} (h : crossProduct a b ⬝ᵥ c = 0) :
    crossProduct b c ⬝ᵥ a = 0 ∧ crossProduct c a ⬝ᵥ b = 0 ∧ crossProduct b a ⬝ᵥ c = 0 ∧
      crossProduct a c ⬝ᵥ b = 0 ∧ crossProduct c b ⬝ᵥ a = 0 := by
  simp only [cross_apply, dotProduct, Fin.sum_univ_three, Matrix.cons_val_zero,
    Matrix.cons_val_one, Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons] at h ⊢
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> first | linear_combination h | linear_combination -h

lemma Cfg.sep_conic {p f g} (h : Cfg p f g) (T : Finset (Fin 9)) (hT : T.card = 5) (t : Fin 9)
    (ht : t ∈ T) : ∃ q, E2 q (p t) ≠ 0 ∧ ∀ s ∈ T, s ≠ t → E2 q (p s) = 0 := by
  have h4 : (T.erase t).card = 4 := by rw [Finset.card_erase_of_mem ht, hT]
  obtain ⟨w, hw⟩ : (T.erase t).Nonempty := Finset.card_pos.mp (by omega)
  have h3 : ((T.erase t).erase w).card = 3 := by rw [Finset.card_erase_of_mem hw, h4]
  obtain ⟨x, y, z, hxy, hxz, hyz, hU⟩ := Finset.card_eq_three.mp h3
  have hx : x ∈ (T.erase t).erase w := by rw [hU]; simp
  have hy : y ∈ (T.erase t).erase w := by rw [hU]; simp
  have hz : z ∈ (T.erase t).erase w := by rw [hU]; simp
  simp only [Finset.mem_erase] at hw hx hy hz
  have hcover : ∀ s ∈ T, s ≠ t → s = w ∨ s = x ∨ s = y ∨ s = z := by
    intro s hs hst
    by_cases hsw : s = w
    · exact Or.inl hsw
    have : s ∈ (T.erase t).erase w := by simp [hs, hst, hsw]
    rw [hU] at this
    simp only [Finset.mem_insert, Finset.mem_singleton] at this
    tauto
  by_cases A : crossProduct (p w) (p x) ⬝ᵥ p t ≠ 0 ∧ crossProduct (p y) (p z) ⬝ᵥ p t ≠ 0
  · refine ⟨lp (crossProduct (p w) (p x)) (crossProduct (p y) (p z)), ?_, ?_⟩
    · rw [E2_lp]; exact mul_ne_zero A.1 A.2
    · intro s hs hst
      rw [E2_lp]
      rcases hcover s hs hst with rfl | rfl | rfl | rfl <;>
        simp [cross_dot_left, cross_dot_right]
  by_cases B : crossProduct (p w) (p y) ⬝ᵥ p t ≠ 0 ∧ crossProduct (p x) (p z) ⬝ᵥ p t ≠ 0
  · refine ⟨lp (crossProduct (p w) (p y)) (crossProduct (p x) (p z)), ?_, ?_⟩
    · rw [E2_lp]; exact mul_ne_zero B.1 B.2
    · intro s hs hst
      rw [E2_lp]
      rcases hcover s hs hst with rfl | rfl | rfl | rfl <;>
        simp [cross_dot_left, cross_dot_right]
  exfalso
  rw [not_and_or, not_not, not_not] at A B
  rcases A with A | A <;> rcases B with B | B
  · exact h.no_four_col (Ne.symm hw.1) (Ne.symm hx.2.1) (Ne.symm hy.2.1) (Ne.symm hx.1)
      (Ne.symm hy.1) hxy (on_perm A).2.1 (on_perm B).2.1
  · exact h.no_four_col (Ne.symm hx.2.1) (Ne.symm hw.1) (Ne.symm hz.2.1) hx.1 hxz
      (Ne.symm hz.1) (on_perm A).2.2.2.2 (on_perm B).2.1
  · exact h.no_four_col (Ne.symm hy.2.1) (Ne.symm hz.2.1) (Ne.symm hw.1) hyz hy.1
      hz.1 (on_perm A).2.1 (on_perm B).2.2.2.2
  · exact h.no_four_col (Ne.symm hz.2.1) (Ne.symm hy.2.1) (Ne.symm hx.2.1) (Ne.symm hyz)
      (Ne.symm hxz) (Ne.symm hxy) (on_perm A).2.2.2.2 (on_perm B).2.2.2.2

lemma Cfg.conic_unique {p f g} (h : Cfg p f g) (T : Finset (Fin 9)) (hT : T.card = 5)
    (q1 q2 : Fin 6 → ℂ) (hq1 : q1 ≠ 0) (h1 : ∀ s ∈ T, E2 q1 (p s) = 0)
    (h2 : ∀ s ∈ T, E2 q2 (p s) = 0) : ∃ c : ℂ, q2 = c • q1 := by
  classical
  have hk := finrank_ker_of_sep (evQ (fun s : T => p s)) (by
    rintro ⟨t, ht⟩
    obtain ⟨q, hq, hq'⟩ := h.sep_conic T hT t ht
    refine ⟨q, hq, ?_⟩
    rintro ⟨s, hs⟩ hst
    exact hq' s hs (fun e => hst (Subtype.ext e)))
  rw [Fintype.card_coe, hT] at hk
  have hk1 : Module.finrank ℂ (LinearMap.ker (evQ (fun s : T => p s))) = 1 := by omega
  have m1 : q1 ∈ LinearMap.ker (evQ (fun s : T => p s)) :=
    LinearMap.mem_ker.mpr (funext fun s => h1 s s.2)
  have m2 : q2 ∈ LinearMap.ker (evQ (fun s : T => p s)) :=
    LinearMap.mem_ker.mpr (funext fun s => h2 s s.2)
  obtain ⟨c, hc⟩ := (finrank_eq_one_iff_of_ne_zero' (⟨q1, m1⟩ : LinearMap.ker _)
    (by simpa using hq1)).mp hk1 ⟨q2, m2⟩
  exact ⟨c, (congrArg Subtype.val hc).symm⟩

lemma E3_lin (s t : ℂ) (f g : Fin 10 → ℂ) (v : Fin 3 → ℂ) :
    E3 (s • f + t • g) v = s * E3 f v + t * E3 g v := by
  simp [E3]; ring

lemma ten_zeros (c : Fin 10 → ℂ) : ∃ v : Fin 10 → Fin 3 → ℂ, (∀ m, v m ≠ 0) ∧
    (∀ m m', m ≠ m' → ∀ s : ℂ, v m ≠ s • v m') ∧ ∀ m, E3 c (v m) = 0 := by
  by_cases hall : ∀ d, E3 c d = 0
  · refine ⟨fun m => ![1, ((m : ℕ) : ℂ), 0], ?_, ?_, fun m => hall _⟩
    · intro m hm
      have := congrFun hm 0
      simp at this
    · intro m m' hmm' s hs
      have h0 := congrFun hs 0
      have h1 := congrFun hs 1
      simp at h0 h1
      rw [← h0, one_mul, Nat.cast_inj] at h1
      exact hmm' (Fin.ext h1)
  push Not at hall
  obtain ⟨d, hd⟩ := hall
  have hd0 : d ≠ 0 := by rintro rfl; simp [E3] at hd
  obtain ⟨a, ha⟩ : ∃ a : Fin 3 → ℂ, crossProduct d a ≠ 0 := by
    by_contra hcon
    push Not at hcon
    have e0 := hcon ![1, 0, 0]
    have e1 := hcon ![0, 1, 0]
    apply hd0
    have c01 := congrFun e0 1
    have c02 := congrFun e0 2
    have c12 := congrFun e1 2
    simp [cross_apply] at c01 c02 c12
    funext i
    fin_cases i
    · simpa using c12
    · simpa using c02
    · simpa using c01
  set b := star (crossProduct d a) with hb
  set D := crossProduct d a ⬝ᵥ b with hD
  have hD0 : D ≠ 0 := dot_star_ne_zero ha
  have hroot : ∀ u : Fin 3 → ℂ, ∃ z : ℂ, E3 c (u + z • d) = 0 := by
    intro u
    obtain ⟨z, hz⟩ := Complex.exists_root (f := Polynomial.C (E3 c d) * Polynomial.X ^ 3 +
      Polynomial.C (A3 c d u) * Polynomial.X ^ 2 + Polynomial.C (A3 c u d) * Polynomial.X +
      Polynomial.C (E3 c u)) (by rw [Polynomial.degree_cubic hd]; norm_num)
    refine ⟨z, ?_⟩
    have e := E3_bin c 1 z u d
    rw [one_smul] at e
    rw [e]
    simp [Polynomial.IsRoot] at hz
    linear_combination hz
  choose z hz using fun m : Fin 10 => hroot (a + ((m : ℕ) : ℂ) • b)
  have h1 : ∀ m : Fin 10, crossProduct b d ⬝ᵥ (a + ((m : ℕ) : ℂ) • b + z m • d) = D := by
    intro m
    simp only [dotProduct_add, dotProduct_smul, cross_dot_left, cross_dot_right, smul_eq_mul,
      mul_zero, add_zero]
    rw [hD]
    simp only [cross_apply, dotProduct, Fin.sum_univ_three, Matrix.cons_val_zero,
      Matrix.cons_val_one, Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
    ring
  have h2 : ∀ m : Fin 10, crossProduct d a ⬝ᵥ (a + ((m : ℕ) : ℂ) • b + z m • d) =
      ((m : ℕ) : ℂ) * D := by
    intro m
    simp only [dotProduct_add, dotProduct_smul, cross_dot_left, cross_dot_right, smul_eq_mul,
      mul_zero, add_zero, zero_add]
    rw [hD]
  refine ⟨fun m => a + ((m : ℕ) : ℂ) • b + z m • d, ?_, ?_, hz⟩
  · intro m hm
    have := h1 m
    simp only at hm
    rw [hm, dotProduct_zero] at this
    exact hD0 this.symm
  · intro m m' hmm' s hs
    simp only at hs
    have e1 := h1 m
    have e2 := h2 m
    rw [hs, dotProduct_smul, h1 m', smul_eq_mul] at e1
    rw [hs, dotProduct_smul, h2 m', smul_eq_mul] at e2
    have hs1 : s = 1 := by
      have : (s - 1) * D = 0 := by linear_combination e1
      exact sub_eq_zero.mp ((mul_eq_zero.mp this).resolve_right hD0)
    rw [hs1] at e2
    have : (((m' : ℕ) : ℂ) - ((m : ℕ) : ℂ)) * D = 0 := by linear_combination e2
    have := sub_eq_zero.mp ((mul_eq_zero.mp this).resolve_right hD0)
    rw [Nat.cast_inj] at this
    exact hmm' (Fin.ext this.symm)

lemma Cfg.indep {p f g} (h : Cfg p f g) : LinearIndependent ℂ ![f, g] := by
  rw [LinearIndependent.pair_iff]
  intro s t hst
  have hz : ∀ v, s * E3 f v + t * E3 g v = 0 := by
    intro v; rw [← E3_lin, hst]; simp [E3]
  by_contra hne
  by_cases ht : t = 0
  · have hs : s ≠ 0 := by rintro rfl; exact hne ⟨rfl, ht⟩
    have hf : ∀ v, E3 f v = 0 := by
      intro v; have := hz v; rw [ht, zero_mul, add_zero] at this
      exact (mul_eq_zero.mp this).resolve_left hs
    obtain ⟨v, hv0, hvn, hvz⟩ := ten_zeros g
    exact h.ten v hv0 hvn (fun m => hf _) hvz
  · obtain ⟨v, hv0, hvn, hvz⟩ := ten_zeros f
    refine h.ten v hv0 hvn hvz (fun m => ?_)
    have := hz (v m)
    rw [hvz m, mul_zero, zero_add] at this
    exact (mul_eq_zero.mp this).resolve_left ht

/-- One coordinate of the parabola `A + u B + u^2 C`, as a polynomial in `u`. -/
noncomputable def gP (A B C : Fin 3 → ℂ) (i : Fin 3) : Polynomial ℂ :=
  Polynomial.C (A i) + Polynomial.C (B i) * Polynomial.X + Polynomial.C (C i) * Polynomial.X ^ 2

/-- A cubic along the parabola `A + u B + u^2 C`, as a polynomial in `u`. -/
noncomputable def gpoly (c : Fin 10 → ℂ) (A B C : Fin 3 → ℂ) : Polynomial ℂ :=
  Polynomial.C (c 0) * gP A B C 0 * gP A B C 0 * gP A B C 0 +
  Polynomial.C (c 1) * gP A B C 1 * gP A B C 1 * gP A B C 1 +
  Polynomial.C (c 2) * gP A B C 2 * gP A B C 2 * gP A B C 2 +
  Polynomial.C (c 3) * gP A B C 0 * gP A B C 0 * gP A B C 1 +
  Polynomial.C (c 4) * gP A B C 0 * gP A B C 0 * gP A B C 2 +
  Polynomial.C (c 5) * gP A B C 1 * gP A B C 1 * gP A B C 0 +
  Polynomial.C (c 6) * gP A B C 1 * gP A B C 1 * gP A B C 2 +
  Polynomial.C (c 7) * gP A B C 2 * gP A B C 2 * gP A B C 0 +
  Polynomial.C (c 8) * gP A B C 2 * gP A B C 2 * gP A B C 1 +
  Polynomial.C (c 9) * gP A B C 0 * gP A B C 1 * gP A B C 2

lemma gpoly_eval (c : Fin 10 → ℂ) (A B C : Fin 3 → ℂ) (u : ℂ) :
    (gpoly c A B C).eval u = E3 c (A + u • B + u ^ 2 • C) := by
  simp [gpoly, gP, E3]
  ring

lemma gP_deg (A B C : Fin 3 → ℂ) (i : Fin 3) : (gP A B C i).natDegree ≤ 2 := by
  unfold gP; compute_degree

lemma gpoly_deg (c : Fin 10 → ℂ) (A B C : Fin 3 → ℂ) : (gpoly c A B C).natDegree ≤ 6 := by
  have h3 : ∀ (a : ℂ) (i j k : Fin 3),
      (Polynomial.C a * gP A B C i * gP A B C j * gP A B C k).natDegree ≤ 6 := by
    intro a i j k
    refine (Polynomial.natDegree_mul_le_of_le (Polynomial.natDegree_mul_le_of_le
      (Polynomial.natDegree_mul_le_of_le (Polynomial.natDegree_C a).le (gP_deg A B C i))
        (gP_deg A B C j)) (gP_deg A B C k)).trans ?_
    omega
  rw [gpoly]
  iterate 9 refine Polynomial.natDegree_add_le_of_degree_le ?_ (h3 _ _ _ _)
  exact h3 _ _ _ _

/-- The polar form of a conic at `u`, as a vector. -/
noncomputable def Bvec (q : Fin 6 → ℂ) (u : Fin 3 → ℂ) : Fin 3 → ℂ :=
  ![q 0 * u 0 + q 3 * u 1 / 2 + q 4 * u 2 / 2, q 1 * u 1 + q 3 * u 0 / 2 + q 5 * u 2 / 2,
    q 2 * u 2 + q 4 * u 0 / 2 + q 5 * u 1 / 2]

lemma B2_eq_dot (q : Fin 6 → ℂ) (u v : Fin 3 → ℂ) : B2 q u v = Bvec q u ⬝ᵥ v := by
  simp [B2, Bvec, dotProduct, Fin.sum_univ_three]; ring

lemma triple_cross (a e t b : Fin 3 → ℂ) :
    a ⬝ᵥ crossProduct e (crossProduct t b) = (a ⬝ᵥ t) * (e ⬝ᵥ b) - (a ⬝ᵥ b) * (e ⬝ᵥ t) := by
  simp [cross_apply, dotProduct, Fin.sum_univ_three]; ring

lemma tp_eq (a b c : Fin 3 → ℂ) : a ⬝ᵥ crossProduct b c = crossProduct a b ⬝ᵥ c := by
  simp [cross_apply, dotProduct, Fin.sum_univ_three]; ring

lemma Cfg.conic_card {p f g} (h : Cfg p f g) (q : Fin 6 → ℂ) (hq : q ≠ 0) :
    (Finset.univ.filter (fun i => E2 q (p i) = 0)).card ≤ 7 := by
  by_contra hc
  rw [not_le] at hc
  set Qs := Finset.univ.filter (fun i => E2 q (p i) = 0) with hQs
  have memQ : ∀ i, i ∈ Qs ↔ E2 q (p i) = 0 := by intro i; simp [hQs]
  -- a base point where the polar form is not identically zero
  obtain ⟨i0, hi0, w0, hw0⟩ : ∃ i0 ∈ Qs, ∃ w, B2 q (p i0) w ≠ 0 := by
    by_contra hall
    push Not at hall
    obtain ⟨i0, hi0⟩ : Qs.Nonempty := Finset.card_pos.mp (by omega)
    obtain ⟨i1, hi1⟩ : (Qs.erase i0).Nonempty :=
      Finset.card_pos.mp (by rw [Finset.card_erase_of_mem hi0]; omega)
    rw [Finset.mem_erase] at hi1
    have hn := h.cross_ne (Ne.symm hi1.1)
    have hl := h.card_line hn
    obtain ⟨i2, hi2, hi2n⟩ := Finset.exists_mem_notMem_of_card_lt_card (by omega :
      (Finset.univ.filter (fun i => crossProduct (p i0) (p i1) ⬝ᵥ p i = 0)).card < Qs.card)
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hi2n
    have hD : p i0 ⬝ᵥ crossProduct (p i1) (p i2) ≠ 0 := by rw [tp_eq]; exact hi2n
    apply hq
    apply E2_eq_zero_of_forall
    intro v
    have e := congrArg (E2 q) (cramer (p i0) (p i1) (p i2) v)
    rw [E2_smul, E2_lin3, (memQ _).1 hi0, (memQ _).1 hi1.2, (memQ _).1 hi2, hall i0 hi0,
      hall i0 hi0, hall i1 hi1.2] at e
    have : (p i0 ⬝ᵥ crossProduct (p i1) (p i2)) ^ 2 * E2 q v = 0 := by linear_combination e
    exact (mul_eq_zero.mp this).resolve_left (pow_ne_zero 2 hD)
  set p0 := p i0 with hp0
  set t := Bvec q p0 with ht
  have htdot : ∀ v, B2 q p0 v = t ⬝ᵥ v := fun v => B2_eq_dot q p0 v
  have ht0 : t ≠ 0 := by
    intro h0; apply hw0; rw [htdot, h0, zero_dotProduct]
  have Ep : E2 q p0 = 0 := (memQ i0).1 hi0
  have htp0 : t ⬝ᵥ p0 = 0 := by rw [← htdot, B2_self]; exact Ep
  obtain ⟨e, hte⟩ : ∃ e : Fin 3 → ℂ, t ⬝ᵥ e = 1 :=
    ⟨(t ⬝ᵥ star t)⁻¹ • star t, by
      rw [dotProduct_smul, smul_eq_mul, inv_mul_cancel₀ (dot_star_ne_zero ht0)]⟩
  obtain ⟨fv, htf, hD0⟩ : ∃ fv : Fin 3 → ℂ, t ⬝ᵥ fv = 0 ∧ p0 ⬝ᵥ crossProduct e fv ≠ 0 := by
    refine ⟨crossProduct t (star p0), dot_self_cross _ _, ?_⟩
    rw [triple_cross, dotProduct_comm p0 t, htp0, dotProduct_comm e t, hte, zero_mul, zero_sub,
      mul_one, neg_ne_zero]
    exact dot_star_ne_zero (h.ne i0)
  set D := p0 ⬝ᵥ crossProduct e fv with hDdef
  have coord : ∀ v, D • v = (v ⬝ᵥ crossProduct e fv) • p0 + (v ⬝ᵥ crossProduct fv p0) • e +
      (v ⬝ᵥ crossProduct p0 e) • fv := fun v => cramer p0 e fv v
  have Bpe : B2 q p0 e = 1 := by rw [htdot, hte]
  have Bpf : B2 q p0 fv = 0 := by rw [htdot, htf]
  have expand : ∀ x y z : ℂ, E2 q (x • p0 + y • e + z • fv) =
      y ^ 2 * E2 q e + z ^ 2 * E2 q fv + 2 * x * y + 2 * y * z * B2 q e fv := by
    intro x y z; rw [E2_lin3, Ep, Bpe, Bpf]; ring
  by_cases hQf : E2 q fv = 0
  · -- the conic is a pair of lines
    obtain ⟨m, hm⟩ : ∃ m : Fin 3 → ℂ, ∀ u, m ⬝ᵥ u = 2 * B2 q e u - E2 q e * (t ⬝ᵥ u) :=
      ⟨(2 : ℂ) • Bvec q e - E2 q e • t, fun u => by
        simp [sub_dotProduct, smul_dotProduct, B2_eq_dot]⟩
    have hm0 : m ≠ 0 := by
      intro h0
      have := hm p0
      rw [h0, zero_dotProduct, B2_symm, Bpe, htp0] at this
      norm_num at this
    have key : ∀ v, E2 q v = (t ⬝ᵥ v) * (m ⬝ᵥ v) := by
      intro v
      have h1 : E2 q (D • v) = (t ⬝ᵥ (D • v)) * (m ⬝ᵥ (D • v)) := by
        rw [coord v, expand, hm, B2_lin3, dotProduct_add, dotProduct_add, dotProduct_smul,
          dotProduct_smul, dotProduct_smul, htp0, hte, htf, B2_symm q e p0, Bpe, B2_self, hQf]
        simp only [smul_eq_mul]
        ring
      rw [E2_smul, dotProduct_smul, dotProduct_smul, smul_eq_mul, smul_eq_mul] at h1
      have : D ^ 2 * (E2 q v - (t ⬝ᵥ v) * (m ⬝ᵥ v)) = 0 := by linear_combination h1
      exact sub_eq_zero.mp ((mul_eq_zero.mp this).resolve_left (pow_ne_zero 2 hD0))
    have hsub : Qs ⊆ (Finset.univ.filter fun i => t ⬝ᵥ p i = 0) ∪
        (Finset.univ.filter fun i => m ⬝ᵥ p i = 0) := by
      intro i hi
      rw [memQ, key] at hi
      simp only [Finset.mem_union, Finset.mem_filter, Finset.mem_univ, true_and]
      exact mul_eq_zero.mp hi
    have h1 := (Finset.card_le_card hsub).trans (Finset.card_union_le _ _)
    have h2 := h.card_line ht0
    have h3 := h.card_line hm0
    omega
  · -- a parametrized conic
    set A0 := e - (E2 q e / 2) • p0 with hA0
    set B0 := fv - B2 q e fv • p0 with hB0
    set C0 := (-(E2 q fv / 2)) • p0 with hC0
    have hY : ∀ i ∈ Qs, i ≠ i0 → p i ⬝ᵥ crossProduct fv p0 ≠ 0 := by
      intro i hi hne hY0
      have E := expand (p i ⬝ᵥ crossProduct e fv) (p i ⬝ᵥ crossProduct fv p0)
        (p i ⬝ᵥ crossProduct p0 e)
      rw [← coord, E2_smul, (memQ i).1 hi, hY0] at E
      have hZ : p i ⬝ᵥ crossProduct p0 e = 0 := by
        have : (p i ⬝ᵥ crossProduct p0 e) ^ 2 * E2 q fv = 0 := by linear_combination -E
        exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp ((mul_eq_zero.mp this).resolve_right hQf)
      have c := coord (p i)
      rw [hY0, hZ, zero_smul, zero_smul, add_zero, add_zero] at c
      apply h.np i i0 hne ((p i ⬝ᵥ crossProduct e fv) / D)
      funext k
      have ck := congrFun c k
      simp only [Pi.smul_apply, smul_eq_mul] at ck ⊢
      rw [← hp0]
      field_simp
      linear_combination ck
    have hrep : ∀ i ∈ Qs, i ≠ i0 → D • p i = (p i ⬝ᵥ crossProduct fv p0) •
        (A0 + ((p i ⬝ᵥ crossProduct p0 e) / (p i ⬝ᵥ crossProduct fv p0)) • B0 +
          ((p i ⬝ᵥ crossProduct p0 e) / (p i ⬝ᵥ crossProduct fv p0)) ^ 2 • C0) := by
      intro i hi hne
      have hYi := hY i hi hne
      have E := expand (p i ⬝ᵥ crossProduct e fv) (p i ⬝ᵥ crossProduct fv p0)
        (p i ⬝ᵥ crossProduct p0 e)
      rw [← coord, E2_smul, (memQ i).1 hi, mul_zero] at E
      rw [coord]
      funext k
      simp only [hA0, hB0, hC0, Pi.add_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul]
      field_simp
      linear_combination (-(p0 k)) * E
    have hzero : ∀ c : Fin 10 → ℂ, (∀ i, E3 c (p i) = 0) →
        ∀ u : ℂ, E3 c (A0 + u • B0 + u ^ 2 • C0) = 0 := by
      intro c hc
      have hpoly : gpoly c A0 B0 C0 = 0 := by
        apply Polynomial.eq_zero_of_natDegree_lt_card_of_eval_eq_zero
          (f := fun i : (Qs.erase i0) =>
            (p i ⬝ᵥ crossProduct p0 e) / (p i ⬝ᵥ crossProduct fv p0))
        · rintro ⟨i, hi⟩ ⟨j, hj⟩ hij
          simp only at hij
          rw [Finset.mem_erase] at hi hj
          apply Subtype.ext
          simp only
          by_contra hne
          apply h.np i j hne ((p i ⬝ᵥ crossProduct fv p0) / (p j ⬝ᵥ crossProduct fv p0))
          have hi' := hrep i hi.2 hi.1
          have hj' := hrep j hj.2 hj.1
          rw [hij] at hi'
          have key : D • p i = D • (((p i ⬝ᵥ crossProduct fv p0) /
              (p j ⬝ᵥ crossProduct fv p0)) • p j) := by
            rw [smul_comm D, hj', smul_smul, div_mul_cancel₀ _ (hY j hj.2 hj.1), hi']
          exact smul_right_injective _ hD0 key
        · rintro ⟨i, hi⟩
          rw [Finset.mem_erase] at hi
          rw [gpoly_eval]
          have e1 := congrArg (E3 c) (hrep i hi.2 hi.1)
          rw [E3_smul, E3_smul, hc i, mul_zero] at e1
          exact (mul_eq_zero.mp e1.symm).resolve_left (pow_ne_zero 3 (hY i hi.2 hi.1))
        · rw [Fintype.card_coe, Finset.card_erase_of_mem hi0]
          have := gpoly_deg c A0 B0 C0
          omega
      intro u
      have := congrArg (Polynomial.eval u) hpoly
      rw [gpoly_eval] at this
      simpa using this
    have tγ : ∀ u : ℂ, t ⬝ᵥ (A0 + u • B0 + u ^ 2 • C0) = 1 := by
      intro u
      simp only [hA0, hB0, hC0, dotProduct_add, dotProduct_sub, dotProduct_smul, hte, htp0, htf,
        smul_eq_mul]
      ring
    have φγ : ∀ u : ℂ, crossProduct p0 e ⬝ᵥ (A0 + u • B0 + u ^ 2 • C0) = u * D := by
      intro u
      simp only [hA0, hB0, hC0, dotProduct_add, dotProduct_sub, dotProduct_smul, cross_dot_left,
        cross_dot_right, smul_eq_mul]
      rw [← tp_eq, ← hDdef]
      ring
    refine h.ten (fun m => A0 + ((m : ℕ) : ℂ) • B0 + ((m : ℕ) : ℂ) ^ 2 • C0) ?_ ?_
      (fun m => hzero f h.zf _) (fun m => hzero g h.zg _)
    · intro m hm
      have := tγ ((m : ℕ) : ℂ)
      rw [hm, dotProduct_zero] at this
      exact zero_ne_one this
    · intro m m' hmm' s hs
      have e1 := tγ ((m : ℕ) : ℂ)
      have e2 := φγ ((m : ℕ) : ℂ)
      rw [hs, dotProduct_smul, tγ, smul_eq_mul, mul_one] at e1
      rw [hs, dotProduct_smul, φγ, smul_eq_mul, e1, one_mul] at e2
      have : (((m' : ℕ) : ℂ) - ((m : ℕ) : ℂ)) * D = 0 := by linear_combination e2
      have := sub_eq_zero.mp ((mul_eq_zero.mp this).resolve_right hD0)
      rw [Nat.cast_inj] at this
      exact hmm' (Fin.ext this.symm)

lemma E2_smul_coef (c : ℂ) (q : Fin 6 → ℂ) (v : Fin 3 → ℂ) : E2 (c • q) v = c * E2 q v := by
  simp [E2]; ring

/-- One attempt at a cubic through seven of the eight points `i ≠ k` that misses `j`: it either
succeeds, or finds a conic through the seven points other than `a`. -/
lemma Cfg.attempt {p f g} (h : Cfg p f g) (k j a : Fin 9) (hjk : j ≠ k) (hak : a ≠ k)
    (haj : a ≠ j) :
    (∃ c : Fin 10 → ℂ, E3 c (p j) ≠ 0 ∧ ∀ i, i ≠ k → i ≠ j → E3 c (p i) = 0) ∨
    (∃ q : Fin 6 → ℂ, q ≠ 0 ∧ ∀ i, i ≠ k → i ≠ a → E2 q (p i) = 0) := by
  set R := ((Finset.univ.erase k).erase j).erase a with hR
  have hRc : R.card = 6 := by
    rw [hR, Finset.card_erase_of_mem (by simp [hak, haj]),
      Finset.card_erase_of_mem (by simp [hjk]), Finset.card_erase_of_mem (Finset.mem_univ _)]
    rfl
  have memR : ∀ i, i ∈ R ↔ i ≠ a ∧ i ≠ j ∧ i ≠ k := by intro i; simp [hR]
  set L := Finset.univ.filter (fun i => crossProduct (p j) (p a) ⬝ᵥ p i = 0) with hL
  have hLc : L.card ≤ 3 := h.card_line (h.cross_ne (Ne.symm haj))
  have hjL : j ∈ L := by simp [hL, cross_dot_left]
  have haL : a ∈ L := by simp [hL, cross_dot_right]
  have hcap : (R ∩ L).card ≤ 1 := by
    have : R ∩ L ⊆ (L.erase j).erase a := by
      intro i hi
      rw [Finset.mem_inter, memR] at hi
      simp [hi.1.1, hi.1.2.1, hi.2]
    refine (Finset.card_le_card this).trans ?_
    rw [Finset.card_erase_of_mem (by simp [haj, haL]), Finset.card_erase_of_mem hjL]
    omega
  have hC : 1 < (R \ L).card := by
    have := Finset.card_sdiff_add_card_inter R L
    omega
  obtain ⟨b, hb, c, hc, hbc⟩ := Finset.one_lt_card.mp hC
  rw [Finset.mem_sdiff, memR] at hb hc
  simp only [hL, Finset.mem_filter, Finset.mem_univ, true_and] at hb hc
  -- the conics through the five other points
  have conic : ∀ x, x ∈ R → ∃ q : Fin 6 → ℂ, q ≠ 0 ∧ ∀ i ∈ R.erase x, E2 q (p i) = 0 := by
    intro x hx
    exact conic_exists p (R.erase x) (by rw [Finset.card_erase_of_mem hx, hRc])
  obtain ⟨qb, hqb0, hqb⟩ := conic b ((memR b).2 hb.1)
  obtain ⟨qc, hqc0, hqc⟩ := conic c ((memR c).2 hc.1)
  -- a line times a conic
  have good : ∀ x, x ∉ L → x ∈ R → ∀ q : Fin 6 → ℂ, (∀ i ∈ R.erase x, E2 q (p i) = 0) →
      E2 q (p j) ≠ 0 →
      ∃ c : Fin 10 → ℂ, E3 c (p j) ≠ 0 ∧ ∀ i, i ≠ k → i ≠ j → E3 c (p i) = 0 := by
    intro x hxL hxR q hq hqj
    refine ⟨lc (crossProduct (p a) (p x)) q, ?_, ?_⟩
    · rw [E3_lc]
      refine mul_ne_zero ?_ hqj
      intro h0
      apply hxL
      simp only [hL, Finset.mem_filter, Finset.mem_univ, true_and]
      exact (on_perm h0).2.1
    · intro i hik hij
      rw [E3_lc]
      by_cases hia : i = a
      · rw [hia, cross_dot_left, zero_mul]
      by_cases hix : i = x
      · rw [hix, cross_dot_right, zero_mul]
      rw [hq i (by simp [Finset.mem_erase, hix, memR, hia, hij, hik]), mul_zero]
  by_cases hb' : E2 qb (p j) ≠ 0
  · exact Or.inl (good b (by simpa [hL] using hb.2) ((memR b).2 hb.1) qb hqb hb')
  by_cases hc' : E2 qc (p j) ≠ 0
  · exact Or.inl (good c (by simpa [hL] using hc.2) ((memR c).2 hc.1) qc hqc hc')
  rw [not_not] at hb' hc'
  right
  set T := insert j ((R.erase b).erase c) with hT
  have hTc : T.card = 5 := by
    rw [hT, Finset.card_insert_of_notMem (by simp [memR]),
      Finset.card_erase_of_mem (by simp [hbc.symm, memR, hc.1]),
      Finset.card_erase_of_mem ((memR b).2 hb.1), hRc]
  have memT : ∀ i ∈ T, i = j ∨ (i ∈ R.erase b ∧ i ∈ R.erase c) := by
    intro i hi
    rw [hT, Finset.mem_insert, Finset.mem_erase, Finset.mem_erase] at hi
    rcases hi with hi | ⟨hic, hib, hiR⟩
    · exact Or.inl hi
    · exact Or.inr ⟨Finset.mem_erase.mpr ⟨hib, hiR⟩, Finset.mem_erase.mpr ⟨hic, hiR⟩⟩
  obtain ⟨l, hl⟩ := h.conic_unique T hTc qb qc hqb0
    (fun i hi => by rcases memT i hi with rfl | hi; exact hb'; exact hqb i hi.1)
    (fun i hi => by rcases memT i hi with rfl | hi; exact hc'; exact hqc i hi.2)
  have hl0 : l ≠ 0 := by rintro rfl; apply hqc0; rw [hl, zero_smul]
  refine ⟨qb, hqb0, fun i hik hia => ?_⟩
  by_cases hij : i = j
  · rw [hij]; exact hb'
  by_cases hib : i = b
  · have := hqc i (by rw [hib]; simp [hbc, memR, hb.1])
    rw [hl, E2_smul_coef] at this
    exact (mul_eq_zero.mp this).resolve_left hl0
  exact hqb i (by simp [Finset.mem_erase, hib, memR, hia, hij, hik])

lemma Cfg.sep_cubic {p f g} (h : Cfg p f g) (k j : Fin 9) (hjk : j ≠ k) :
    ∃ c : Fin 10 → ℂ, E3 c (p j) ≠ 0 ∧ ∀ i, i ≠ k → i ≠ j → E3 c (p i) = 0 := by
  have hc : 1 < ((Finset.univ.erase k).erase j).card := by
    rw [Finset.card_erase_of_mem (by simp [hjk]), Finset.card_erase_of_mem (Finset.mem_univ _)]
    decide
  obtain ⟨a1, h1, a2, h2, h12⟩ := Finset.one_lt_card.mp hc
  simp only [Finset.mem_erase, Finset.mem_univ, and_true] at h1 h2
  rcases h.attempt k j a1 hjk h1.2 h1.1 with r1 | ⟨q1, hq1, hv1⟩
  · exact r1
  rcases h.attempt k j a2 hjk h2.2 h2.1 with r2 | ⟨q2, hq2, hv2⟩
  · exact r2
  exfalso
  obtain ⟨T, hTs, hTc⟩ := Finset.exists_subset_card_eq (s := (Finset.univ.erase k).erase a1 |>.erase a2)
    (n := 5) (by
      rw [Finset.card_erase_of_mem (by simp [Ne.symm h12, h2.2]),
        Finset.card_erase_of_mem (by simp [h1.2]), Finset.card_erase_of_mem (Finset.mem_univ _)]
      decide)
  have memT : ∀ i ∈ T, i ≠ k ∧ i ≠ a1 ∧ i ≠ a2 := by
    intro i hi
    have := hTs hi
    simp only [Finset.mem_erase, Finset.mem_univ, and_true] at this
    exact ⟨this.2.2, this.2.1, this.1⟩
  obtain ⟨l, hl⟩ := h.conic_unique T hTc q1 q2 hq1
    (fun i hi => hv1 i (memT i hi).1 (memT i hi).2.1)
    (fun i hi => hv2 i (memT i hi).1 (memT i hi).2.2)
  have hl0 : l ≠ 0 := by rintro rfl; apply hq2; rw [hl, zero_smul]
  have hall : ∀ i, i ≠ k → E2 q1 (p i) = 0 := by
    intro i hik
    by_cases hia : i = a1
    · have := hv2 i hik (by rw [hia]; exact h12)
      rw [hl, E2_smul_coef] at this
      exact (mul_eq_zero.mp this).resolve_left hl0
    exact hv1 i hik hia
  have hcard := h.conic_card q1 hq1
  have hsub : Finset.univ.erase k ⊆ Finset.univ.filter (fun i => E2 q1 (p i) = 0) := by
    intro i hi
    simp only [Finset.mem_erase, Finset.mem_univ, and_true] at hi
    simp [hall i hi]
  have := Finset.card_le_card hsub
  rw [Finset.card_erase_of_mem (Finset.mem_univ _)] at this
  simp at this
  omega

lemma Cfg.main {p f g} (h : Cfg p f g) (k : Fin 9) (c : Fin 10 → ℂ)
    (hc : ∀ i, i ≠ k → E3 c (p i) = 0) : ∃ a b : ℂ, c = a • f + b • g := by
  classical
  set L := evC (fun i : {i : Fin 9 // i ≠ k} => p i.1) with hLdef
  have hk := finrank_ker_of_sep L (by
    rintro ⟨j, hj⟩
    obtain ⟨c, hc0, hc1⟩ := h.sep_cubic k j hj
    refine ⟨c, hc0, ?_⟩
    rintro ⟨i, hi⟩ hij
    exact hc1 i hi (fun e => hij (Subtype.ext e)))
  have hcard : Fintype.card {i : Fin 9 // i ≠ k} = 8 := by
    rw [Fintype.card_subtype_compl, Fintype.card_fin, Fintype.card_unique]
  rw [hcard] at hk
  have hli := h.indep
  have hspan : Submodule.span ℂ (Set.range ![f, g]) = LinearMap.ker L := by
    apply Submodule.eq_of_le_of_finrank_eq
    · rw [Submodule.span_le]
      rintro _ ⟨i, rfl⟩
      rw [SetLike.mem_coe, LinearMap.mem_ker]
      funext j
      fin_cases i
      · exact h.zf j.1
      · exact h.zg j.1
    · rw [finrank_span_eq_card hli]
      simp only [Fintype.card_fin]
      omega
  have hmem : c ∈ LinearMap.ker L := LinearMap.mem_ker.mpr (funext fun i => hc i.1 i.2)
  rw [← hspan, Submodule.mem_span_range_iff_exists_fun] at hmem
  obtain ⟨w, hw⟩ := hmem
  refine ⟨w 0, w 1, ?_⟩
  rw [← hw, Fin.sum_univ_two]
  rfl

lemma cub_lin (a b : ℂ) (f g : Fin 10 → ℂ) : cub (a • f + b • g) = a • cub f + b • cub g := by
  simp only [cub, Pi.add_apply, Pi.smul_apply, smul_eq_mul, map_add, map_mul,
    MvPolynomial.smul_eq_C_mul]
  ring

/-- **Cayley-Bacharach.** Let `F` and `G` be cubics over `ℂ` that meet in exactly nine
distinct points `P_1, …, P_9` of the projective plane (so they share no curve). If a cubic
`C` passes through eight of them, then `C = aF + bG` for some numbers `a` and `b`, and so
`C` passes through the ninth as well. -/
theorem cubic_through_eight_of_nine_passes_through_ninth
    (F G C : MvPolynomial (Fin 3) ℂ)
    (hF : F.IsHomogeneous 3) (hG : G.IsHomogeneous 3) (hC : C.IsHomogeneous 3)
    (P : Fin 9 → ℙ ℂ (Fin 3 → ℂ)) (hP : Function.Injective P)
    (hFG : {p : ℙ ℂ (Fin 3 → ℂ) | eval p.rep F = 0 ∧ eval p.rep G = 0} = Set.range P)
    (k : Fin 9) (hC8 : ∀ i, i ≠ k → eval (P i).rep C = 0) :
    (∃ a b : ℂ, C = a • F + b • G) ∧ eval (P k).rep C = 0 := by
  obtain ⟨f, rfl⟩ := exists_cub hF
  obtain ⟨g, rfl⟩ := exists_cub hG
  obtain ⟨c, rfl⟩ := exists_cub hC
  have memset : ∀ i, eval (P i).rep (cub f) = 0 ∧ eval (P i).rep (cub g) = 0 := by
    intro i
    have : P i ∈ {p : ℙ ℂ (Fin 3 → ℂ) | eval p.rep (cub f) = 0 ∧ eval p.rep (cub g) = 0} := by
      rw [hFG]; exact ⟨i, rfl⟩
    exact this
  have hcfg : Cfg (fun i => (P i).rep) f g := by
    refine ⟨fun i => (P i).rep_ne_zero, ?_, fun i => by rw [← eval_cub]; exact (memset i).1,
      fun i => by rw [← eval_cub]; exact (memset i).2, ?_⟩
    · intro i j hij a ha
      apply hij
      apply hP
      rw [← Projectivization.mk_rep (P i), ← Projectivization.mk_rep (P j),
        Projectivization.mk_eq_mk_iff']
      exact ⟨a, ha.symm⟩
    · intro v hv0 hvn hvf hvg
      have hin : ∀ m, ∃ i, P i = Projectivization.mk ℂ (v m) (hv0 m) := by
        intro m
        have : Projectivization.mk ℂ (v m) (hv0 m) ∈ Set.range P := by
          rw [← hFG]
          obtain ⟨a, ha⟩ := Projectivization.exists_smul_eq_mk_rep ℂ (v m) (hv0 m)
          show eval (Projectivization.mk ℂ (v m) (hv0 m)).rep (cub f) = 0 ∧
            eval (Projectivization.mk ℂ (v m) (hv0 m)).rep (cub g) = 0
          rw [← ha, eval_cub, eval_cub, Units.smul_def, E3_smul, E3_smul, hvf m, hvg m]
          simp
        exact this
      choose σ hσ using hin
      have hinj : Function.Injective σ := by
        intro m m' hmm
        by_contra hne
        have e := hσ m
        rw [hmm, hσ m', Projectivization.mk_eq_mk_iff'] at e
        obtain ⟨a, ha⟩ := e
        exact hvn m' m (Ne.symm hne) a ha.symm
      have := Fintype.card_le_of_injective σ hinj
      simp at this
  obtain ⟨a, b, hab⟩ := hcfg.main k c (fun i hi => by rw [← eval_cub]; exact hC8 i hi)
  refine ⟨⟨a, b, by rw [hab, cub_lin]⟩, ?_⟩
  rw [eval_cub, hab, E3_lin, ← eval_cub, ← eval_cub, (memset k).1, (memset k).2]
  ring

/-- **The Hessian test for a flex.** Let `F` be a cubic over `ℂ` and `v` a smooth point of
the curve `F = 0` in the projective plane. Then `v` is an inflection point (its tangent line
meets the curve three times there) exactly when the Hessian is zero at `v`. -/
theorem smooth_point_is_flex_iff_hessian_eq_zero
    (F : MvPolynomial (Fin 3) ℂ) (hF : F.IsHomogeneous 3)
    (v : Fin 3 → ℂ) (hv : v ≠ 0) (hs : IsSmoothPoint F v) :
    IsFlex F v ↔ eval v (hessian F) = 0 := by
  exact hessian_test F hF v hv hs

/-- **The nine flexes of the Fermat cubic.** The Hessian of `x^3 + y^3 - z^3` is `-216 xyz`,
and the curve has exactly nine inflection points in the complex projective plane. -/
theorem fermat_cubic_hessian_and_nine_flexes :
    hessian fermat = -216 * X 0 * X 1 * X 2 ∧
      {p : ℙ ℂ (Fin 3 → ℂ) | IsFlex fermat p.rep}.ncard = 9 := by
  refine ⟨fermat_hessian, ?_⟩
  have hS : {p : ℙ ℂ (Fin 3 → ℂ) | IsFlex fermat p.rep} = Set.range fpt := by
    ext p
    simp only [Set.mem_ofPred_eq, Set.mem_range]
    rw [fermat_flex_iff _ p.rep_ne_zero]
    constructor
    · rintro ⟨hc, hprod⟩
      set v := p.rep with hvdef
      have hv : v ≠ 0 := p.rep_ne_zero
      rcases mul_eq_zero.mp hprod with h01 | h2
      · rcases mul_eq_zero.mp h01 with h0 | h1
        · -- x = 0
          have h1 : v 1 ≠ 0 := by
            intro h1
            have : v 2 ^ 3 = 0 := by rw [h0, h1] at hc; linear_combination -hc
            exact hv (vec_eq_zero h0 h1 (pow_eq_zero_iff (by norm_num) |>.mp this))
          have hz : (v 2 / v 1) ^ 3 = 1 := by
            rw [div_pow, div_eq_one_iff_eq (pow_ne_zero 3 h1)]
            rw [h0] at hc; linear_combination -hc
          have e : ∀ k, fvec k 0 = 0 → fvec k 1 = 1 → fvec k 2 = v 2 / v 1 → fpt k = p := by
            intro k a0 a1 a2
            refine fpt_hit p k (v 1) ?_
            rw [← hvdef]
            funext i; fin_cases i
            · simp [a0, h0]
            · simp [a1]
            · simp [a2]; field_simp
          rcases cube_root hz with hz | hz | hz
          · exact ⟨0, e 0 (by simp [fvec]) (by simp [fvec]) (by simp [fvec, hz])⟩
          · exact ⟨1, e 1 (by simp [fvec]) (by simp [fvec]) (by simp [fvec, hz])⟩
          · exact ⟨2, e 2 (by simp [fvec]) (by simp [fvec]) (by simp [fvec, hz])⟩
        · -- y = 0
          have h0 : v 0 ≠ 0 := by
            intro h0
            have : v 2 ^ 3 = 0 := by rw [h0, h1] at hc; linear_combination -hc
            exact hv (vec_eq_zero h0 h1 (pow_eq_zero_iff (by norm_num) |>.mp this))
          have hz : (v 2 / v 0) ^ 3 = 1 := by
            rw [div_pow, div_eq_one_iff_eq (pow_ne_zero 3 h0)]
            rw [h1] at hc; linear_combination -hc
          have e : ∀ k, fvec k 0 = 1 → fvec k 1 = 0 → fvec k 2 = v 2 / v 0 → fpt k = p := by
            intro k a0 a1 a2
            refine fpt_hit p k (v 0) ?_
            rw [← hvdef]
            funext i; fin_cases i
            · simp [a0]
            · simp [a1, h1]
            · simp [a2]; field_simp
          rcases cube_root hz with hz | hz | hz
          · exact ⟨3, e 3 (by simp [fvec]) (by simp [fvec]) (by simp [fvec, hz])⟩
          · exact ⟨4, e 4 (by simp [fvec]) (by simp [fvec]) (by simp [fvec, hz])⟩
          · exact ⟨5, e 5 (by simp [fvec]) (by simp [fvec]) (by simp [fvec, hz])⟩
      · -- z = 0
        have h0 : v 0 ≠ 0 := by
          intro h0
          have : v 1 ^ 3 = 0 := by rw [h0, h2] at hc; linear_combination hc
          exact hv (vec_eq_zero h0 (pow_eq_zero_iff (by norm_num) |>.mp this) h2)
        have hz : (-(v 1 / v 0)) ^ 3 = 1 := by
          rw [neg_pow, div_pow]
          field_simp
          rw [h2] at hc; linear_combination -hc
        have e : ∀ k, fvec k 0 = 1 → fvec k 1 = v 1 / v 0 → fvec k 2 = 0 → fpt k = p := by
          intro k a0 a1 a2
          refine fpt_hit p k (v 0) ?_
          rw [← hvdef]
          funext i; fin_cases i
          · simp [a0]
          · simp [a1]; field_simp
          · simp [a2, h2]
        rcases cube_root hz with hz | hz | hz
        · exact ⟨6, e 6 (by simp [fvec]) (by simp [fvec]; linear_combination hz) (by simp [fvec])⟩
        · exact ⟨7, e 7 (by simp [fvec]) (by simp [fvec]; linear_combination hz) (by simp [fvec])⟩
        · exact ⟨8, e 8 (by simp [fvec]) (by simp [fvec]; linear_combination hz) (by simp [fvec])⟩
    · rintro ⟨k, rfl⟩
      obtain ⟨a, ha⟩ := Projectivization.exists_smul_eq_mk_rep ℂ (fvec k) (fvec_ne k)
      rw [fpt, ← ha]
      obtain ⟨c1, c2⟩ := fvec_flex k
      simp only [Units.smul_def, Pi.smul_apply, smul_eq_mul]
      constructor
      · linear_combination (a : ℂ) ^ 3 * c1
      · linear_combination (a : ℂ) ^ 3 * c2
  rw [hS, Set.ncard_range_of_injective fpt_injective, Nat.card_eq_fintype_card, Fintype.card_fin]

/-! The card's worked numbers. -/

-- the Fermat Hessian matrix is diagonal, 6x, 6y, −6z, with determinant −216xyz
example (x y z : ℤ) :
    !![6 * x, 0, 0; 0, 6 * y, 0; 0, 0, -6 * z].det = -216 * x * y * z := by
  simp [Matrix.det_fin_three] <;> ring

-- 6 · 6 · (−6) = −216
example : (6 : ℤ) * 6 * (-6) = -216 := by norm_num

-- the tangent x = z at (1 : 0 : 1): F(1 : t : 1) = 1 + t^3 − 1 = t^3, a triple root
example (t : ℤ) : (1 : ℤ) ^ 3 + t ^ 3 - 1 ^ 3 = t ^ 3 := by ring

-- the nine flexes: the three real ones (0 : 1 : 1), (1 : 0 : 1), (1 : −1 : 0) lie on the curve,
-- on xyz = 0, and on the line x + y = z
example : (0 : ℤ) ^ 3 + 1 ^ 3 - 1 ^ 3 = 0 ∧ (1 : ℤ) ^ 3 + 0 ^ 3 - 1 ^ 3 = 0 ∧
    (1 : ℤ) ^ 3 + (-1) ^ 3 - 0 ^ 3 = 0 := by norm_num
example : (0 : ℤ) + 1 = 1 ∧ (1 : ℤ) + 0 = 1 ∧ (1 : ℤ) + (-1) = 0 := by norm_num

-- Bezout: 3 × 3 = 9 meetings; degree of H is 3(d − 2) = 3; flexes 3d(d − 2) = 9 for d = 3
example : 3 * 3 = 9 ∧ 3 * (3 - 2) = 3 ∧ 3 * 3 * (3 - 2) = 9 := by norm_num

-- cubics have 10 coefficients; 8 conditions leave 10 − 8 = 2 free, filled by F and G
example : Nat.choose (3 + 2) 2 = 10 ∧ 10 - 8 = 2 := by decide

-- the real flex tangents x = z, y = z, x + y = 0 and the flex line x + y = z rebuild the curve
example (x y z : ℤ) :
    x ^ 3 + y ^ 3 - z ^ 3 = (x + y - z) ^ 3 - 3 * (x - z) * (y - z) * (x + y) := by ring

-- the line x + y = z times the conic is F + 3xyz, a member of the family aF + b·xyz
example (x y z : ℤ) :
    (x + y - z) * (x ^ 2 - x * y + y ^ 2 + x * z + y * z + z ^ 2) =
      x ^ 3 + y ^ 3 - z ^ 3 + 3 * x * y * z := by ring

-- mod 7, ω becomes 2: 2^3 = 8 = 1 and 2^2 + 2 + 1 = 0
example : (2 : ZMod 7) ^ 3 = 1 ∧ (2 : ZMod 7) ^ 2 + 2 + 1 = 0 := by decide

-- mod 7 the Fermat cubic has 9 points: 6 with z = 1, and 3 at infinity (x : 1 : 0) with x^3 = −1
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 => p.1 ^ 3 + p.2 ^ 3 = 1).card = 6 ∧
    (Finset.univ.filter fun x : ZMod 7 => x ^ 3 + 1 = 0).card = 3 := by decide

-- the house curve y^2 = x^2(x + 1), F = y^2 z − x^3 − x^2 z, along x = t^2 − 1, y = t^3 − t, z = 1:
-- H = 8(t − 1)^3 (t + 1)^3 (3t^2 + 1)
example (t : ℤ) :
    !![-6 * (t ^ 2 - 1) - 2, 0, -2 * (t ^ 2 - 1);
       0, 2, 2 * (t ^ 3 - t);
       -2 * (t ^ 2 - 1), 2 * (t ^ 3 - t), 0].det =
      8 * (t - 1) ^ 3 * (t + 1) ^ 3 * (3 * t ^ 2 + 1) := by
  simp [Matrix.det_fin_three] <;> ring

-- the plain 2 × 2 Hessian of y^2 = x^3 + x^2 + 1 is −12x − 4, zero at x = −1/3 ...
example (x : ℚ) : (-6 * x - 2) * 2 - 0 ^ 2 = -12 * x - 4 := by ring
example : -12 * (-1 / 3 : ℚ) - 4 = 0 := by norm_num

-- ... but the true Hessian of F = y^2 z − x^3 − x^2 z − z^3 at (−1 : y : 3) is −24, never 0
example (y : ℤ) :
    !![-6 * (-1) - 2 * 3, 0, -2 * (-1);
       0, 2 * 3, 2 * y;
       -2 * (-1), 2 * y, -6 * 3].det = -24 := by
  simp [Matrix.det_fin_three] <;> ring

-- two conics give lines, not conics: (x − 1)(1 − y) is 0 at three corners of the square, −4 at the fourth
example : ((1 : ℤ) - 1) * (1 - 1) = 0 ∧ ((1 : ℤ) - 1) * (1 - (-1)) = 0 ∧
    ((-1 : ℤ) - 1) * (1 - 1) = 0 ∧ ((-1 : ℤ) - 1) * (1 - (-1)) = -4 := by norm_num

#print axioms cubic_through_eight_of_nine_passes_through_ninth
#print axioms smooth_point_is_flex_iff_hessian_eq_zero
#print axioms fermat_cubic_hessian_and_nine_flexes
#print axioms cub_add
#print axioms monomial_eq3
#print axioms exists_cub
#print axioms pderiv_ofNat
#print axioms pderiv_natCast'
#print axioms taylor3
#print axioms bil_vv
#print axioms bil_vw
#print axioms euler1
#print axioms eval_hessian
#print axioms bform_symm
#print axioms det_congr_form
#print axioms dot_star_ne_zero
#print axioms hessian_test
#print axioms fermat_hessian
#print axioms fermat_hom
#print axioms eval_fermat
#print axioms vec_eq_zero
#print axioms fermat_flex_iff
#print axioms hω
#print axioms hω3
#print axioms hω6
#print axioms hω1
#print axioms hω0
#print axioms hω2
#print axioms hω21
#print axioms hωn1
#print axioms hω2n1
#print axioms hω20
#print axioms hωω
#print axioms hωω2
#print axioms hω2ω
#print axioms hω2ω2
#print axioms cube_root
#print axioms fvec_ne
#print axioms fvec_flex
#print axioms fpt_injective
#print axioms fpt_hit
#print axioms eval_cub
#print axioms E3_smul
#print axioms E3_bin
#print axioms E3_add_smul
#print axioms E2_lin3
#print axioms B2_self
#print axioms B2_symm
#print axioms B2_lin3
#print axioms E2_smul
#print axioms cramer
#print axioms dual_cramer
#print axioms E2_lp
#print axioms E3_lc
#print axioms E2_eq_zero_of_forall
#print axioms Cfg.cross_ne
#print axioms span_of_perp
#print axioms det_zero_of_perp
#print axioms line_vanish
#print axioms Cfg.ten_line
#print axioms Cfg.no_four
#print axioms Cfg.card_line
#print axioms Cfg.no_four_col
#print axioms finrank_ker_of_sep
#print axioms conic_exists
#print axioms cross_dot_left
#print axioms cross_dot_right
#print axioms on_perm
#print axioms Cfg.sep_conic
#print axioms Cfg.conic_unique
#print axioms E3_lin
#print axioms ten_zeros
#print axioms Cfg.indep
#print axioms gpoly_eval
#print axioms gP_deg
#print axioms gpoly_deg
#print axioms B2_eq_dot
#print axioms triple_cross
#print axioms tp_eq
#print axioms Cfg.conic_card
#print axioms E2_smul_coef
#print axioms Cfg.attempt
#print axioms Cfg.sep_cubic
#print axioms Cfg.main
#print axioms cub_lin
