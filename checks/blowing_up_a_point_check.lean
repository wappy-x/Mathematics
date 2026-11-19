-- Blowing up: in the chart y = t x, a plane curve of multiplicity m at the origin loses exactly x^m, what is left meets the line of directions at the tangent slopes, a simple tangent slope gives a smooth point there, and away from the origin the direction through a point is forced.
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Algebra.Polynomial.AlgebraMap
import Mathlib.LinearAlgebra.Projectivization.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

open MvPolynomial

/-! Coordinates: a plane curve over a field `k` is `F = 0` for `F : MvPolynomial (Fin 2) k`,
with `x = X 0` and `y = X 1`. The chart `y = t x` of the blow-up has coordinates `(x, t)`,
again written `X 0` and `X 1`; the exceptional line `E` is `x = 0` there.
`F` has multiplicity `m` at the origin when every term `c xⁱ yʲ` of `F` has `i + j ≥ m` and
the lowest-degree part `F_m = homogeneousComponent m F` is not zero. -/

/-- The substitution `y = t x` of the chart: it sends `F(x, y)` to `F(x, t x)`. -/
noncomputable def chartSubst {k : Type*} [Field k] (F : MvPolynomial (Fin 2) k) :
    MvPolynomial (Fin 2) k :=
  aeval (![X 0, X 0 * X 1] : Fin 2 → MvPolynomial (Fin 2) k) F

/-- The slope polynomial `F_m(1, t)`: the lowest-degree part of `F` read along slope `t`. -/
noncomputable def slopePoly {k : Type*} [Field k] (F : MvPolynomial (Fin 2) k) (m : ℕ) :
    Polynomial k :=
  aeval (![1, Polynomial.X] : Fin 2 → Polynomial k) (homogeneousComponent m F)

/-- The blow-up of the plane at the origin: pairs (point `(x, y)`, direction `(u : v)` in the
projective line `ℙ¹`) with the point on the line through the origin in that direction,
`x v = y u`. The test is the same for every representative `(u, v)` of the direction. -/
def blowUp (k : Type*) [Field k] : Set ((Fin 2 → k) × Projectivization k (Fin 2 → k)) :=
  {q | q.1 0 * q.2.rep 1 = q.1 1 * q.2.rep 0}

theorem blowup_eval_aeval_poly {k : Type*} [Field k] (f : Fin 2 → Polynomial k)
    (P : MvPolynomial (Fin 2) k) (t : k) :
    (aeval f P).eval t = eval (fun i => (f i).eval t) P := by
  induction P using MvPolynomial.induction_on with
  | C a => simp
  | add p q hp hq => simp [hp, hq]
  | mul_X p n hp => simp [hp]

#print axioms blowup_eval_aeval_poly

theorem blowup_eval_zero_line {k : Type*} [Field k] (P : MvPolynomial (Fin 2) k) (t : k) :
    eval ![0, t] P = (aeval (![0, Polynomial.X] : Fin 2 → Polynomial k) P).eval t := by
  rw [blowup_eval_aeval_poly]
  have hf : (fun i => (![(0 : Polynomial k), Polynomial.X] i).eval t) = ![0, t] := by
    funext i; fin_cases i <;> simp
  rw [hf]

#print axioms blowup_eval_zero_line

theorem blowup_aeval_pderiv {k : Type*} [Field k] (P : MvPolynomial (Fin 2) k) :
    aeval (![0, Polynomial.X] : Fin 2 → Polynomial k) (pderiv 1 P) =
      Polynomial.derivative (aeval (![0, Polynomial.X] : Fin 2 → Polynomial k) P) := by
  induction P using MvPolynomial.induction_on with
  | C a => simp
  | add p q hp hq => simp [hp, hq]
  | mul_X p n hp =>
    rw [Derivation.leibniz]
    fin_cases n
    · simp [hp, pderiv_X]
    · simp [hp, pderiv_X]; ring

#print axioms blowup_aeval_pderiv

theorem blowup_strict_transform_exists {k : Type*} [Field k]
    (F : MvPolynomial (Fin 2) k) (m : ℕ)
    (hlow : ∀ d ∈ F.support, m ≤ d.degree) :
    ∃ G : MvPolynomial (Fin 2) k, chartSubst F = X 0 ^ m * G ∧
      aeval (![0, Polynomial.X] : Fin 2 → Polynomial k) G = slopePoly F m := by
  refine ⟨∑ d ∈ F.support, C (F.coeff d) * X 0 ^ (d.degree - m) * X 1 ^ (d 1), ?_, ?_⟩
  · unfold chartSubst
    conv_lhs => rw [F.as_sum]
    rw [map_sum, Finset.mul_sum]
    refine Finset.sum_congr rfl fun d hd => ?_
    obtain ⟨e, he⟩ := Nat.exists_eq_add_of_le (hlow d hd)
    have hdeg : d.degree = d 0 + d 1 := by rw [Finsupp.degree_eq_sum, Fin.sum_univ_two]
    rw [aeval_monomial, Finsupp.prod_fintype _ _ (by simp), Fin.prod_univ_two, he,
      Nat.add_sub_cancel_left]
    have h0 : d 0 + d 1 = m + e := hdeg ▸ he
    simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_fin_one,
      algebraMap_eq, mul_pow]
    rw [show C (F.coeff d) * ((X 0 : MvPolynomial (Fin 2) k) ^ d 0 * (X 0 ^ d 1 * X 1 ^ d 1)) =
      C (F.coeff d) * X 0 ^ (d 0 + d 1) * X 1 ^ d 1 by ring, h0, pow_add]
    ring
  · unfold slopePoly
    rw [homogeneousComponent_apply, map_sum, map_sum, Finset.sum_filter]
    refine Finset.sum_congr rfl fun d hd => ?_
    by_cases h : d.degree = m
    · simp [h, aeval_monomial, Finsupp.prod_fintype _ _ (by simp : ∀ i, (![(1 : Polynomial k), Polynomial.X] i) ^ 0 = 1)]
    · have : d.degree - m ≠ 0 := by have := hlow d hd; omega
      simp [h, this]

#print axioms blowup_strict_transform_exists

theorem blowup_slopePoly_ne_zero {k : Type*} [Field k]
    (F : MvPolynomial (Fin 2) k) (m : ℕ) (hm : homogeneousComponent m F ≠ 0) :
    slopePoly F m ≠ 0 := by
  obtain ⟨d, hd⟩ := MvPolynomial.ne_zero_iff.mp hm
  rw [coeff_homogeneousComponent] at hd
  split_ifs at hd with hdeg
  swap; · exact absurd rfl hd
  intro h0
  have hc := congrArg (fun p => Polynomial.coeff p (d 1)) h0
  simp only [slopePoly, homogeneousComponent_apply, map_sum, Polynomial.coeff_zero] at hc
  simp [aeval_monomial, Finsupp.prod_fintype _ _ (by simp : ∀ i, (![(1 : Polynomial k), Polynomial.X] i) ^ 0 = 1), Polynomial.finsetSum_coeff] at hc
  rw [Finset.sum_eq_single d] at hc
  · simp at hc; exact hd hc
  · intro b hb hbd
    rw [Finset.mem_filter] at hb
    split_ifs with h1
    · exfalso; apply hbd
      have hb' : b.degree = b 0 + b 1 := by rw [Finsupp.degree_eq_sum, Fin.sum_univ_two]
      have hd' : d.degree = d 0 + d 1 := by rw [Finsupp.degree_eq_sum, Fin.sum_univ_two]
      ext i; fin_cases i
      · simp; omega
      · simp; omega
    · rfl
  · intro hdn
    exact absurd (Finset.mem_filter.mpr ⟨MvPolynomial.mem_support_iff.mpr hd, hdeg⟩) hdn

#print axioms blowup_slopePoly_ne_zero

/-- **Distinct tangent directions become smooth points.** Over a field `k`, let the plane curve
`F = 0` have multiplicity `m` at the origin, and let `G` be its strict transform in the chart
`y = t x`, so `F(x, t x) = x^m G(x, t)`. If `r ∈ k` is a simple root (a root that is not
repeated) of the slope polynomial `F_m(1, t)`, then the point `(x, t) = (0, r)` lies on the
strict transform, on the exceptional line, and the strict transform is smooth there: its
slope in the `t` direction at `(0, r)` is not zero. -/
theorem simple_tangent_slope_gives_smooth_point {k : Type*} [Field k]
    (F : MvPolynomial (Fin 2) k) (m : ℕ)
    (hlow : ∀ d ∈ F.support, m ≤ d.degree) (hm : homogeneousComponent m F ≠ 0)
    (G : MvPolynomial (Fin 2) k) (hG : chartSubst F = X 0 ^ m * G)
    (r : k) (hr : Polynomial.rootMultiplicity r (slopePoly F m) = 1) :
    eval ![0, r] G = 0 ∧ eval ![0, r] (pderiv 1 G) ≠ 0 := by
  obtain ⟨G0, hG0, hφ⟩ := blowup_strict_transform_exists F m hlow
  have hGG : G = G0 := by
    rw [hG] at hG0
    exact mul_left_cancel₀ (pow_ne_zero _ (X_ne_zero 0)) hG0
  subst hGG
  have hne : slopePoly F m ≠ 0 := by
    intro h; rw [h, Polynomial.rootMultiplicity_zero] at hr; exact zero_ne_one hr
  have hroot : (slopePoly F m).IsRoot r := ((Polynomial.rootMultiplicity_pos hne).mp (by omega))
  have hder : ¬ (Polynomial.derivative (slopePoly F m)).IsRoot r := by
    intro hd
    have := (Polynomial.one_lt_rootMultiplicity_iff_isRoot hne).mpr ⟨hroot, hd⟩
    omega
  refine ⟨?_, ?_⟩
  · rw [blowup_eval_zero_line, hφ]; exact hroot
  · rw [blowup_eval_zero_line, blowup_aeval_pderiv, hφ]; exact hder

/-- **Exactly `x^m` comes out, and the rest meets `E` at the tangent slopes.** Over a field
`k`, let the plane curve `F = 0` have multiplicity `m` at the origin. Substituting `y = t x`
gives `F(x, t x) = x^m G(x, t)` for a polynomial `G`, the strict transform, and `x^(m+1)`
does not divide `F(x, t x)`. Where `G` meets the exceptional line `x = 0` is decided by the
lowest-degree part alone: `G(0, t) = F_m(1, t)` for every `t`. -/
theorem strict_transform_meets_E_at_tangent_slopes {k : Type*} [Field k]
    (F : MvPolynomial (Fin 2) k) (m : ℕ)
    (hlow : ∀ d ∈ F.support, m ≤ d.degree) (hm : homogeneousComponent m F ≠ 0) :
    ∃ G : MvPolynomial (Fin 2) k,
      chartSubst F = X 0 ^ m * G ∧
      ¬ (X 0 ^ (m + 1) ∣ chartSubst F) ∧
      ∀ t : k, eval ![0, t] G = eval ![1, t] (homogeneousComponent m F) := by
  obtain ⟨G0, hG0, hφ⟩ := blowup_strict_transform_exists F m hlow
  refine ⟨G0, hG0, ?_, ?_⟩
  · rintro ⟨H, hH⟩
    rw [hG0, pow_succ, mul_assoc] at hH
    have h1 := mul_left_cancel₀ (pow_ne_zero _ (X_ne_zero 0)) hH
    apply blowup_slopePoly_ne_zero F m hm
    rw [← hφ, h1]
    simp
  · intro t
    rw [blowup_eval_zero_line, hφ, slopePoly, blowup_eval_aeval_poly]
    have hf : (fun i => (![(1 : Polynomial k), Polynomial.X] i).eval t) = ![1, t] := by
      funext i; fin_cases i <;> simp
    rw [hf]

/-- **The blow-up changes nothing away from the origin and puts a whole line over it.** Over a
field `k`, a point `p = (x, y)` other than the origin lies on exactly one direction of the
blow-up, its own direction `(x : y)`; the origin lies on every direction, so the whole
projective line `ℙ¹` of directions sits over it as the exceptional line `E`. -/
theorem blowup_direction_forced_off_origin (k : Type*) [Field k] :
    (∀ (p : Fin 2 → k) (hp : p ≠ 0) (ℓ : Projectivization k (Fin 2 → k)),
        (p, ℓ) ∈ blowUp k ↔ ℓ = Projectivization.mk k p hp) ∧
      ∀ ℓ : Projectivization k (Fin 2 → k), ((0 : Fin 2 → k), ℓ) ∈ blowUp k := by
  refine ⟨fun p hp ℓ => ?_, fun ℓ => by simp [blowUp]⟩
  simp only [blowUp, Set.mem_ofPred_eq]
  constructor
  · intro h
    rw [← Projectivization.mk_rep ℓ, Projectivization.mk_eq_mk_iff']
    by_cases h0 : p 0 = 0
    · have h1 : p 1 ≠ 0 := by
        intro h1; apply hp; funext i; fin_cases i <;> simp [h0, h1]
      have hv0 : ℓ.rep 0 = 0 := by
        rw [h0, zero_mul] at h
        exact (mul_eq_zero.mp h.symm).resolve_left h1
      refine ⟨ℓ.rep 1 / p 1, ?_⟩
      funext i; fin_cases i
      · simp [h0, hv0]
      · simp; field_simp
    · refine ⟨ℓ.rep 0 / p 0, ?_⟩
      funext i; fin_cases i
      · simp; field_simp
      · simp; field_simp; linear_combination -h
  · rintro rfl
    obtain ⟨a, ha⟩ := Projectivization.exists_smul_eq_mk_rep k p hp
    rw [← ha]
    simp only [Pi.smul_apply, Units.smul_def, smul_eq_mul]
    ring

-- The node y² = x²(x + 1): substituting y = t x pulls out x², leaving t² − x − 1.
example (x t : ℤ) : (t * x) ^ 2 - x ^ 3 - x ^ 2 = x ^ 2 * (t ^ 2 - x - 1) := by ring
-- On E (x = 0) the strict transform is t² − 1, zero at the two tangent slopes t = 1 and t = −1.
example : (1 : ℤ) ^ 2 - 0 - 1 = 0 ∧ (-1 : ℤ) ^ 2 - 0 - 1 = 0 := by norm_num
-- The gradient (−1, 2t) of t² − x − 1 is (−1, 2) at t = 1 and (−1, −2) at t = −1: not zero.
example : ((-1 : ℤ), 2 * 1) = (-1, 2) ∧ ((-1 : ℤ), 2 * (-1)) = (-1, -2) := by norm_num
-- The chart x = s y: F(s y, y) = y²(1 − s² − s³ y); on E (y = 0) it is 1 − s², and 1 at s = 0.
example (s y : ℤ) : y ^ 2 - (s * y) ^ 3 - (s * y) ^ 2 = y ^ 2 * (1 - s ^ 2 - s ^ 3 * y) := by ring
example : (1 : ℤ) - 1 ^ 2 = 0 ∧ (1 : ℤ) - (-1) ^ 2 = 0 ∧ (1 : ℤ) - 0 ^ 2 = 1 := by norm_num
-- The parametrisation x = t² − 1, y = t³ − t lies on the nodal cubic, and t = ±1 both give the node.
example (t : ℤ) : (t ^ 3 - t) ^ 2 - (t ^ 2 - 1) ^ 3 - (t ^ 2 - 1) ^ 2 = 0 := by ring
example : ((1 : ℤ) ^ 2 - 1, (1 : ℤ) ^ 3 - 1) = (0, 0) ∧
    ((-1 : ℤ) ^ 2 - 1, (-1 : ℤ) ^ 3 - (-1)) = (0, 0) := by norm_num
-- Over 𝔽₇ the nodal cubic has 6 points and the strict transform 7.
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 =>
    p.2 ^ 2 - p.1 ^ 3 - p.1 ^ 2 = 0).card = 6 := by decide
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 =>
    p.2 ^ 2 - p.1 - 1 = 0).card = 7 := by decide
-- Over 𝔽₇ the curve is singular only at the node, and the strict transform nowhere.
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 =>
    p.2 ^ 2 - p.1 ^ 3 - p.1 ^ 2 = 0 ∧ -3 * p.1 ^ 2 - 2 * p.1 = 0 ∧ 2 * p.2 = 0) =
      {((0 : ZMod 7), (0 : ZMod 7))} := by decide
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 =>
    p.2 ^ 2 - p.1 - 1 = 0 ∧ (-1 : ZMod 7) = 0 ∧ 2 * p.2 = 0).card = 0 := by decide
-- Over 𝔽₇ the map (x, t) ↦ (x, t x) sends the strict transform's 7 points onto the curve's 6.
example : ((Finset.univ.filter fun p : ZMod 7 × ZMod 7 => p.2 ^ 2 - p.1 - 1 = 0).image
    fun p => (p.1, p.2 * p.1)).card = 6 := by decide
-- Mistake 1: the total transform x²t² − x³ − x² has 7 singular points over 𝔽₇, all of E.
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 =>
    p.1 ^ 2 * p.2 ^ 2 - p.1 ^ 3 - p.1 ^ 2 = 0 ∧
      2 * p.1 * p.2 ^ 2 - 3 * p.1 ^ 2 - 2 * p.1 = 0 ∧ 2 * p.1 ^ 2 * p.2 = 0).card = 7 := by decide
-- Mistake 2: dividing by x once, x t² − x² − x, leaves 2 singular points over 𝔽₇.
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 =>
    p.1 * p.2 ^ 2 - p.1 ^ 2 - p.1 = 0 ∧
      p.2 ^ 2 - 2 * p.1 - 1 = 0 ∧ 2 * p.1 * p.2 = 0).card = 2 := by decide
-- Over 𝔽₁₁ the curve has 10 points and the strict transform 11.
example : (Finset.univ.filter fun p : ZMod 11 × ZMod 11 =>
    p.2 ^ 2 - p.1 ^ 3 - p.1 ^ 2 = 0).card = 10 := by decide
example : (Finset.univ.filter fun p : ZMod 11 × ZMod 11 =>
    p.2 ^ 2 - p.1 - 1 = 0).card = 11 := by decide
-- The cusp y² = x³: one blow-up gives t² − x.
example (x t : ℤ) : (t * x) ^ 2 - x ^ 3 = x ^ 2 * (t ^ 2 - x) := by ring
-- The tacnode y² = x⁴(x + 1): one blow-up gives the house node t² − x³ − x², a second gives u² − x − 1.
example (x t : ℤ) : (t * x) ^ 2 - x ^ 5 - x ^ 4 = x ^ 2 * (t ^ 2 - x ^ 3 - x ^ 2) := by ring
example (x u : ℤ) : (u * x) ^ 2 - x ^ 3 - x ^ 2 = x ^ 2 * (u ^ 2 - x - 1) := by ring
-- y² = x⁵: two blow-ups, t² − x³ and then u² − x.
example (x t : ℤ) : (t * x) ^ 2 - x ^ 5 = x ^ 2 * (t ^ 2 - x ^ 3) := by ring
example (x u : ℤ) : (u * x) ^ 2 - x ^ 3 = x ^ 2 * (u ^ 2 - x) := by ring
-- The triple point y³ − x²y + x⁴: m = 3, strict transform t³ − t + x, slopes −1, 0, 1.
example (x t : ℤ) : (t * x) ^ 3 - x ^ 2 * (t * x) + x ^ 4 = x ^ 3 * (t ^ 3 - t + x) := by ring
example : (-1 : ℤ) ^ 3 - (-1) = 0 ∧ (0 : ℤ) ^ 3 - 0 = 0 ∧ (1 : ℤ) ^ 3 - 1 = 0 := by norm_num
-- Sums of m(m − 1)/2: node 1, cusp 1, tacnode 1 + 1, y² = x⁵ 1 + 1, triple point 3.
example : 2 * (2 - 1) / 2 = 1 ∧ 2 * (2 - 1) / 2 + 2 * (2 - 1) / 2 = 2 ∧ 3 * (3 - 1) / 2 = 3 := by
  norm_num
-- Genus count for the nodal cubic: (3 − 1)(3 − 2)/2 − 1 = 0.
example : (3 - 1) * (3 - 2) / 2 - 1 = 0 := by norm_num
-- The figure's ends at t = 3/2: x = 5/4, y = 15/8.
example : ((3 : ℚ) / 2) ^ 2 - 1 = 5 / 4 ∧ ((3 : ℚ) / 2) ^ 3 - 3 / 2 = 15 / 8 := by norm_num

#print axioms simple_tangent_slope_gives_smooth_point
#print axioms strict_transform_meets_E_at_tangent_slopes
#print axioms blowup_direction_forced_off_origin
