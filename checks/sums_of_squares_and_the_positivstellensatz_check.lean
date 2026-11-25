-- Sums of squares: over the real numbers a sum of squares is never negative and a Positivstellensatz certificate proves a system has no real point, Motzkin's polynomial is never negative yet no sum of squares, and the link and the wall has a constant-multiplier certificate exactly when the circle's weight is at least 1/(r² − 1).
import Mathlib.Algebra.Ring.SumsOfSquares
import Mathlib.Algebra.MvPolynomial.Basic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic

/-! The card's notation.
* The field is ℝ. The n real unknowns are `X 0, …, X (n-1)` in `MvPolynomial (Fin n) ℝ`;
  a real point is `x : Fin n → ℝ`, and `MvPolynomial.eval x f` is the value of `f` there.
* "Sum of squares" is Mathlib's `IsSumSq`: a finite sum `q₁ * q₁ + ⋯ + qₘ * qₘ`.
* The inequalities are `g i ≥ 0` for `i : Fin r`; the equations are `h j = 0` for `j : Fin s`.
  A group of the inequalities is `S : Finset (Fin r)`, and its product is `∏ i ∈ S, g i`
  (the empty group gives 1).
* A certificate is one sum of squares `σ S` per group and any polynomial multiplier `lam j`
  per equation, with `-1 = ∑ S, σ S * ∏ i ∈ S, g i + ∑ j, lam j * h j`.
* "Positive semidefinite" is Mathlib's `Matrix.PosSemidef`.
* Motzkin's polynomial lives in `MvPolynomial (Fin 2) ℝ`, with `X 0` for x and `X 1` for y. -/

open MvPolynomial

namespace SumsOfSquaresPositivstellensatzCard

theorem motzkin_nonneg_real (x y : ℝ) : 0 ≤ x ^ 4 * y ^ 2 + x ^ 2 * y ^ 4 - 3 * x ^ 2 * y ^ 2 + 1 := by
  have hu : 0 ≤ x ^ 2 := sq_nonneg x
  have hv : 0 ≤ y ^ 2 := sq_nonneg y
  nlinarith [mul_nonneg (mul_nonneg hu hv) (sq_nonneg (x ^ 2 - 1)), mul_nonneg (mul_nonneg hu hv) (sq_nonneg (y ^ 2 - 1)),
    sq_nonneg (x ^ 2 * y ^ 2 - 1), sq_nonneg (x^2 - y^2), mul_nonneg hu hv, sq_nonneg (x*y), mul_nonneg (mul_nonneg hu hv) (sq_nonneg (x ^ 2 - y ^ 2)),
    mul_nonneg (add_nonneg hu hv) (sq_nonneg (x^2*y^2 - 1))]

theorem isSumSq_repr {σ : Type*} {p : MvPolynomial σ ℝ} (hp : IsSumSq p) :
    ∃ (m : ℕ) (q : Fin m → MvPolynomial σ ℝ), p = ∑ i, q i * q i := by
  induction hp with
  | zero => exact ⟨0, Fin.elim0, by simp⟩
  | sq_add a hs ih =>
    obtain ⟨m, q, rfl⟩ := ih
    exact ⟨m + 1, Fin.cons a q, by simp [Fin.sum_univ_succ]⟩

theorem coeff_double_sumSq {m : ℕ} (q : Fin m → MvPolynomial (Fin 2) ℝ) (e : Fin 2 →₀ ℕ)
    (he : ∀ i a b, a ∈ (q i).support → b ∈ (q i).support → a + b = e + e → a = e) :
    (∑ i, q i * q i).coeff (e + e) = ∑ i, (q i).coeff e ^ 2 := by
  classical
  rw [coeff_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [coeff_mul, Finset.sum_eq_single (e, e)]
  · ring
  · rintro ⟨a, b⟩ hab hne
    have hab' : a + b = e + e := Finset.mem_antidiagonal.mp hab
    by_contra hz
    have ha : a ∈ (q i).support := by
      rw [mem_support_iff]; intro h0; exact hz (by simp [h0])
    have hb : b ∈ (q i).support := by
      rw [mem_support_iff]; intro h0; exact hz (by simp [h0])
    have h1 := he i a b ha hb hab'
    rw [h1] at hab'
    exact hne (Prod.ext h1 (add_left_cancel hab'))
  · intro h
    exact absurd (Finset.mem_antidiagonal.mpr rfl : (e, e) ∈ Finset.antidiagonal (e + e)) h

theorem weight_bound_sumSq {m : ℕ} (q : Fin m → MvPolynomial (Fin 2) ℝ)
    (φ τ : (Fin 2 →₀ ℕ) → ℤ) (hφ : ∀ a b, φ (a + b) = φ a + φ b)
    (hτ : ∀ a b, τ (a + b) = τ a + τ b) (hinj : ∀ a b, φ a = φ b → τ a = τ b → a = b) (c : ℤ)
    (hF : ∀ d ∈ (∑ i, q i * q i).support, φ d ≤ 2 * c) :
    ∀ i, ∀ a ∈ (q i).support, φ a ≤ c := by
  classical
  intro i₀ a₀ ha₀
  set U := Finset.univ.biUnion (fun i => (q i).support) with hU
  have a₀U : a₀ ∈ U := Finset.mem_biUnion.mpr ⟨i₀, Finset.mem_univ _, ha₀⟩
  obtain ⟨e1, he1U, he1⟩ := Finset.exists_max_image U φ ⟨a₀, a₀U⟩
  set U' := U.filter (fun a => φ a = φ e1) with hU'
  have e1U' : e1 ∈ U' := Finset.mem_filter.mpr ⟨he1U, rfl⟩
  obtain ⟨e, heU', he⟩ := Finset.exists_max_image U' τ ⟨e1, e1U'⟩
  obtain ⟨heU, hφe⟩ := Finset.mem_filter.mp heU'
  have memU : ∀ i a, a ∈ (q i).support → a ∈ U := fun i a ha =>
    Finset.mem_biUnion.mpr ⟨i, Finset.mem_univ _, ha⟩
  have hext : ∀ i a b, a ∈ (q i).support → b ∈ (q i).support → a + b = e + e → a = e := by
    intro i a b ha hb hab
    have hsum := congrArg φ hab
    rw [hφ, hφ] at hsum
    have h1 := he1 a (memU i a ha)
    have h2 := he1 b (memU i b hb)
    have hφa : φ a = φ e1 := by omega
    have hφb : φ b = φ e1 := by omega
    have aU' : a ∈ U' := Finset.mem_filter.mpr ⟨memU i a ha, hφa⟩
    have bU' : b ∈ U' := Finset.mem_filter.mpr ⟨memU i b hb, hφb⟩
    have hsum2 := congrArg τ hab
    rw [hτ, hτ] at hsum2
    have h3 := he a aU'
    have h4 := he b bU'
    exact hinj a e (by omega) (by omega)
  have hco := coeff_double_sumSq q e hext
  obtain ⟨j, -, hj⟩ := Finset.mem_biUnion.mp heU
  have hpos : 0 < ∑ i, (q i).coeff e ^ 2 := by
    refine lt_of_lt_of_le ?_ (Finset.single_le_sum (fun i _ => sq_nonneg ((q i).coeff e))
      (Finset.mem_univ j))
    have hj' := mem_support_iff.mp hj
    positivity
  have hmem : e + e ∈ (∑ i, q i * q i).support := by
    rw [mem_support_iff, hco]; exact hpos.ne'
  have := hF _ hmem
  rw [hφ] at this
  have := he1 a₀ a₀U
  omega

theorem motzkin_sub_C_eq (γ : ℝ) :
    (X 0 ^ 4 * X 1 ^ 2 + X 0 ^ 2 * X 1 ^ 4 - 3 * X 0 ^ 2 * X 1 ^ 2 + 1 - C γ : MvPolynomial (Fin 2) ℝ) =
      monomial (Finsupp.single 0 4 + Finsupp.single 1 2) 1
        + monomial (Finsupp.single 0 2 + Finsupp.single 1 4) 1
        + monomial (Finsupp.single 0 2 + Finsupp.single 1 2) (-3)
        + monomial 0 (1 - γ) := by
  have h1 : ∀ a b : ℕ, ∀ c : ℝ, (monomial (Finsupp.single 0 a + Finsupp.single 1 b) c : MvPolynomial (Fin 2) ℝ)
      = C c * (X 0 ^ a * X 1 ^ b) := by
    intro a b c
    rw [X_pow_eq_monomial, X_pow_eq_monomial, monomial_mul_monomial, C_mul_monomial, one_mul, mul_one]
  rw [h1, h1, h1, ← C_apply, map_sub, map_neg, C_1]
  have h3 : (C 3 : MvPolynomial (Fin 2) ℝ) = 3 := map_ofNat C 3
  rw [h3]
  ring

/-- The card's main claim, the direction it proves. Over ℝ, a sum of squares is never negative;
and if −1 equals a sum, over groups S of the inequalities g_i ≥ 0, of a sum of squares σ_S times
the product of that group, plus polynomial multiples λ_j of the equations h_j = 0, then the system
g_i ≥ 0 (all i), h_j = 0 (all j) has no real point. With no inequalities this is the real
Nullstellensatz certificate −1 = σ + Σ λ_j h_j. -/
theorem sum_of_squares_never_negative_and_certificate_means_no_real_point
    {n r s : ℕ} :
    (∀ p : MvPolynomial (Fin n) ℝ, IsSumSq p → ∀ x : Fin n → ℝ, 0 ≤ eval x p) ∧
    ∀ (g : Fin r → MvPolynomial (Fin n) ℝ) (h : Fin s → MvPolynomial (Fin n) ℝ)
      (σ : Finset (Fin r) → MvPolynomial (Fin n) ℝ) (lam : Fin s → MvPolynomial (Fin n) ℝ),
      (∀ S, IsSumSq (σ S)) →
      (-1 : MvPolynomial (Fin n) ℝ) = ∑ S : Finset (Fin r), σ S * ∏ i ∈ S, g i + ∑ j, lam j * h j →
      ¬ ∃ x : Fin n → ℝ, (∀ i, 0 ≤ eval x (g i)) ∧ ∀ j, eval x (h j) = 0 := by
  have key : ∀ p : MvPolynomial (Fin n) ℝ, IsSumSq p → ∀ x : Fin n → ℝ, 0 ≤ eval x p := by
    intro p hp x
    induction hp with
    | zero => simp
    | sq_add a hs ih =>
      rw [map_add, map_mul]
      exact add_nonneg (mul_self_nonneg _) ih
  refine ⟨key, ?_⟩
  rintro g h σ lam hσ hcert ⟨x, hg, hh⟩
  have := congrArg (eval x) hcert
  rw [map_neg, map_one, map_add, map_sum, map_sum] at this
  have h1 : 0 ≤ ∑ S : Finset (Fin r), eval x (σ S * ∏ i ∈ S, g i) := by
    refine Finset.sum_nonneg fun S _ => ?_
    rw [map_mul, map_prod]
    exact mul_nonneg (key _ (hσ S) x) (Finset.prod_nonneg fun i _ => hg i)
  have h2 : ∑ j, eval x (lam j * h j) = 0 := by
    refine Finset.sum_eq_zero fun j _ => ?_
    rw [map_mul, hh j, mul_zero]
  linarith

/-- Motzkin's polynomial M(x, y) = x⁴y² + x²y⁴ − 3x²y² + 1 is never negative (by AM-GM), yet
it is no sum of squares, and neither is M − γ for any floor γ. -/
theorem motzkin_never_negative_and_no_sum_of_squares :
    let M : MvPolynomial (Fin 2) ℝ :=
      X 0 ^ 4 * X 1 ^ 2 + X 0 ^ 2 * X 1 ^ 4 - 3 * X 0 ^ 2 * X 1 ^ 2 + 1
    (∀ v : Fin 2 → ℝ, 0 ≤ eval v M) ∧ ∀ γ : ℝ, ¬ IsSumSq (M - C γ) := by
  intro M
  refine ⟨fun v => by simpa [M] using motzkin_nonneg_real (v 0) (v 1), fun γ hγ => ?_⟩
  obtain ⟨m, q, hq⟩ := isSumSq_repr hγ
  have hEq := motzkin_sub_C_eq γ
  have hsupp : ∀ d ∈ (∑ i, q i * q i).support, d = Finsupp.single 0 4 + Finsupp.single 1 2 ∨
      d = Finsupp.single 0 2 + Finsupp.single 1 4 ∨ d = Finsupp.single 0 2 + Finsupp.single 1 2 ∨
      d = 0 := by
    intro d hd
    rw [← hq, hEq, mem_support_iff] at hd
    by_contra hne
    simp only [not_or] at hne
    obtain ⟨n1, n2, n3, n4⟩ := hne
    apply hd
    simp only [AddMonoidAlgebra.coeff_add, Finsupp.add_apply, coeff_monomial, Ne.symm n1,
      Ne.symm n2, Ne.symm n3, Ne.symm n4, ite_false, add_zero]
  have b1 := weight_bound_sumSq q (fun a => (a 0 : ℤ) + a 1) (fun a => (a 0 : ℤ))
    (fun a b => by simp only [Finsupp.add_apply]; push_cast; ring)
    (fun a b => by simp only [Finsupp.add_apply]; push_cast; ring)
    (fun a b h1 h2 => by ext j; fin_cases j <;> simp <;> omega) 3
    (fun d hd => by rcases hsupp d hd with rfl | rfl | rfl | rfl <;> simp)
  have b2 := weight_bound_sumSq q (fun a => (a 0 : ℤ) - 2 * a 1) (fun a => (a 0 : ℤ))
    (fun a b => by simp only [Finsupp.add_apply]; push_cast; ring)
    (fun a b => by simp only [Finsupp.add_apply]; push_cast; ring)
    (fun a b h1 h2 => by ext j; fin_cases j <;> simp <;> omega) 0
    (fun d hd => by rcases hsupp d hd with rfl | rfl | rfl | rfl <;> simp)
  have b3 := weight_bound_sumSq q (fun a => (a 1 : ℤ) - 2 * a 0) (fun a => (a 1 : ℤ))
    (fun a b => by simp only [Finsupp.add_apply]; push_cast; ring)
    (fun a b => by simp only [Finsupp.add_apply]; push_cast; ring)
    (fun a b h1 h2 => by ext j; fin_cases j <;> simp <;> omega) 0
    (fun d hd => by rcases hsupp d hd with rfl | rfl | rfl | rfl <;> simp)
  set e : Fin 2 →₀ ℕ := Finsupp.single 0 1 + Finsupp.single 1 1 with he
  have hext : ∀ i a b, a ∈ (q i).support → b ∈ (q i).support → a + b = e + e → a = e := by
    intro i a b ha hb hab
    have ha1 := b1 i a ha
    have ha2 := b2 i a ha
    have ha3 := b3 i a ha
    have hb1 := b1 i b hb
    have hb2 := b2 i b hb
    have hb3 := b3 i b hb
    have h0 := congrArg (fun f => f 0) hab
    have h1 := congrArg (fun f => f 1) hab
    simp only [Finsupp.add_apply, he] at h0 h1
    simp at h0 h1 ha1 ha2 ha3 hb1 hb2 hb3
    ext j; fin_cases j <;> simp [he] <;> omega
  have hco := coeff_double_sumSq q e hext
  rw [← hq, hEq] at hco
  have hval : (monomial (Finsupp.single 0 4 + Finsupp.single 1 2) 1
        + monomial (Finsupp.single 0 2 + Finsupp.single 1 4) 1
        + monomial (Finsupp.single 0 2 + Finsupp.single 1 2) (-3)
        + monomial 0 (1 - γ) : MvPolynomial (Fin 2) ℝ).coeff (e + e) = -3 := by
    have k1 : Finsupp.single 0 4 + Finsupp.single 1 2 ≠ e + e := by
      intro h; have := congrArg (fun f => f 0) h; simp [he] at this
    have k2 : Finsupp.single 0 2 + Finsupp.single 1 4 ≠ e + e := by
      intro h; have := congrArg (fun f => f 1) h; simp [he] at this
    have k3 : Finsupp.single 0 2 + Finsupp.single 1 2 = e + e := by
      ext j; fin_cases j <;> simp [he]
    have k4 : (0 : Fin 2 →₀ ℕ) ≠ e + e := by
      intro h; have := congrArg (fun f => f 0) h; simp [he] at this
    simp only [AddMonoidAlgebra.coeff_add, Finsupp.add_apply, coeff_monomial, k1, k2, k3, k4,
      ite_false, ite_true]
    ring
  rw [hval] at hco
  have : 0 ≤ ∑ i, (q i).coeff e ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
  linarith

/-- Step 4, the link and the wall at x ≥ r, with r > 1. With σ₁ = c a constant at least 0 and
λ = −s a constant, the certificate −1 = σ₀ + c(x − r) − s(x² + y² − 1) forces σ₀'s Gram matrix
on (1, x, y) to be `[[r c − s − 1, −c/2, 0], [−c/2, s, 0], [0, 0, s]]`. Some c ≥ 0 makes it
positive semidefinite exactly when s ≥ 1/(r² − 1); for r = 2 that is s ≥ 1/3. -/
theorem wall_certificate_exists_iff_circle_weight_at_least
    (r s : ℝ) (hr : 1 < r) :
    (∃ c : ℝ, 0 ≤ c ∧
      (!![r * c - s - 1, -c / 2, 0; -c / 2, s, 0; 0, 0, s] : Matrix (Fin 3) (Fin 3) ℝ).PosSemidef)
      ↔ 1 / (r ^ 2 - 1) ≤ s := by
  have hr2 : 0 < r ^ 2 - 1 := by nlinarith
  constructor
  · rintro ⟨c, hc, hP⟩
    have := hP.dotProduct_mulVec_nonneg ![1, r, 0]
    simp [dotProduct, Fin.sum_univ_three, Matrix.mulVec] at this
    rw [div_le_iff₀ hr2]
    nlinarith
  · intro hs
    have hs' : 1 ≤ s * (r ^ 2 - 1) := by rwa [div_le_iff₀ hr2] at hs
    have spos : 0 < s := by
      by_contra hneg
      push Not at hneg
      nlinarith
    refine ⟨2 * s * r, by positivity, ?_⟩
    refine Matrix.PosSemidef.of_dotProduct_mulVec_nonneg ?_ ?_
    · ext i j
      fin_cases i <;> fin_cases j <;> simp [Matrix.conjTranspose]
    · intro x
      simp [dotProduct, Fin.sum_univ_three, Matrix.mulVec]
      nlinarith [mul_nonneg spos.le (sq_nonneg (x 1 - r * x 0)), mul_nonneg spos.le (sq_nonneg (x 2)),
        mul_nonneg (sub_nonneg.mpr hs') (sq_nonneg (x 0))]

/-! The card's worked examples, checked exactly. -/

-- p(0) = 5, p(−1) = 4, p(−3) = 20 for p = x⁴ + 4x³ + 6x² + 4x + 5.
example : (fun x : ℤ => x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5) 0 = 5 ∧
    (fun x : ℤ => x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5) (-1) = 4 ∧
    (fun x : ℤ => x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5) (-3) = 20 := by
  norm_num

-- The opening certificate: p = ((x + 1)²)² + 2², as polynomials.
example : (Polynomial.X ^ 4 + 4 * Polynomial.X ^ 3 + 6 * Polynomial.X ^ 2 + 4 * Polynomial.X + 5
    : Polynomial ℝ) = ((Polynomial.X + 1) ^ 2) ^ 2 + 2 ^ 2 := by
  ring

-- Step 1: the three certificates at t = 1, 0, −1, and the false one at t = 2 (a weight −2).
example (x : ℝ) : x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5 = (x ^ 2 + 2 * x + 1) ^ 2 + 4 ∧
    x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5 = (x ^ 2 + 2 * x) ^ 2 + 2 * (x + 1) ^ 2 + 3 ∧
    x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5 = (x ^ 2 + 2 * x - 1) ^ 2 + 4 * (x + 1) ^ 2 ∧
    x ^ 4 + 4 * x ^ 3 + 6 * x ^ 2 + 4 * x + 5 = (x ^ 2 + 2 * x + 2) ^ 2 - 2 * (x + 1) ^ 2 + 3 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> ring

-- Step 1: p = (u² + 1)(v² + 1) with u = x, v = x + 2, and its two ends.
example (u v : ℝ) : (u ^ 2 + 1) * (v ^ 2 + 1) = (u * v + 1) ^ 2 + (u - v) ^ 2 ∧
    (u ^ 2 + 1) * (v ^ 2 + 1) = (u * v - 1) ^ 2 + (u + v) ^ 2 ∧
    (u ^ 2 + 1) * ((u + 2) ^ 2 + 1) = u ^ 4 + 4 * u ^ 3 + 6 * u ^ 2 + 4 * u + 5 := by
  refine ⟨?_, ?_, ?_⟩ <;> ring

-- Step 1: det Q(t) = 2(t + 1)(t − 1)(t − 3); the minor on rows 1 and 2 is 2 − 2t.
example (t : ℝ) :
    (!![5, 2, t; 2, 6 - 2 * t, 2; t, 2, 1] : Matrix (Fin 3) (Fin 3) ℝ).det
      = 2 * (t + 1) * (t - 1) * (t - 3) ∧ (6 - 2 * t) * 1 - 2 * 2 = 2 - 2 * t := by
  constructor
  · simp [Matrix.det_fin_three]; ring
  · ring

-- Step 2: M(1, 1) = 0 (and at all four points (±1, ±1)), and Artin's identity
-- (x² + y²)² M = x²y²(x² + y² + 1)(x² + y² − 2)² + (x² − y²)².
example : ∀ x ∈ ({1, -1} : Finset ℤ), ∀ y ∈ ({1, -1} : Finset ℤ),
    x ^ 4 * y ^ 2 + x ^ 2 * y ^ 4 - 3 * x ^ 2 * y ^ 2 + 1 = 0 := by
  decide

example (x y : ℝ) : (x ^ 2 + y ^ 2) ^ 2 * (x ^ 4 * y ^ 2 + x ^ 2 * y ^ 4 - 3 * x ^ 2 * y ^ 2 + 1) =
    x ^ 2 * y ^ 2 * (x ^ 2 + y ^ 2 + 1) * (x ^ 2 + y ^ 2 - 2) ^ 2 + (x ^ 2 - y ^ 2) ^ 2 := by
  ring

-- The link and the wall: −1 = (1/3)((x − 2)² + y²) + (4/3)(x − 2) − (1/3)(x² + y² − 1).
example (x y : ℝ) :
    (-1 : ℝ) = 1 / 3 * ((x - 2) ^ 2 + y ^ 2) + 4 / 3 * (x - 2) - 1 / 3 * (x ^ 2 + y ^ 2 - 1) := by
  ring

-- Step 4 at r = 2: the bound 1/(r² − 1) is 1/3, and s = 1/3, c = 4/3 meets the minor
-- s(2c − s − 1) ≥ c²/4 with equality.
example : (1 : ℚ) / (2 ^ 2 - 1) = 1 / 3 ∧
    (1 / 3 : ℚ) * (2 * (4 / 3) - 1 / 3 - 1) = (4 / 3) ^ 2 / 4 := by
  norm_num

-- What breaks over ℂ: (x² + y² − 1) − (x + 2)(x − 2) = y² + 3, and the real certificate
-- −1 = (1/3)y² − (1/3)(y² + 3).
example (x y : ℝ) : (x ^ 2 + y ^ 2 - 1) - (x + 2) * (x - 2) = y ^ 2 + 3 ∧
    (-1 : ℝ) = 1 / 3 * y ^ 2 - 1 / 3 * (y ^ 2 + 3) := by
  constructor <;> ring

-- The arm, 3 m and 2 m links, target 4 m: the difference 8a − 21, b² − 135/64 in the ideal,
-- and the certificate that the elbow cannot clear 2 m.
example (a b : ℝ) : (a ^ 2 + b ^ 2 - 9) - ((a - 4) ^ 2 + b ^ 2 - 4) = 8 * a - 21 ∧
    (a ^ 2 + b ^ 2 - 9) - 1 / 8 * (a + 21 / 8) * (8 * a - 21) = b ^ 2 - 135 / 64 ∧
    64 / 121 * ((b - 2) ^ 2 + 4 * (b - 2) - (b ^ 2 - 135 / 64)) = -1 := by
  refine ⟨?_, ?_, ?_⟩ <;> ring

#print axioms motzkin_nonneg_real
#print axioms isSumSq_repr
#print axioms coeff_double_sumSq
#print axioms weight_bound_sumSq
#print axioms motzkin_sub_C_eq
#print axioms sum_of_squares_never_negative_and_certificate_means_no_real_point
#print axioms motzkin_never_negative_and_no_sum_of_squares
#print axioms wall_certificate_exists_iff_circle_weight_at_least

end SumsOfSquaresPositivstellensatzCard
