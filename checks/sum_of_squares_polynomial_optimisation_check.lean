-- Sums of squares: a real polynomial of degree at most 2d is a sum of squares exactly when a positive semidefinite Gram matrix on the monomials 1, x, ..., x^d reproduces it, every never-negative polynomial in one variable is a sum of two squares, and Motzkin's polynomial is never negative yet no floor shift of it is a sum of squares.
import Mathlib.Algebra.Ring.SumsOfSquares
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.MvPolynomial.Basic
import Mathlib.Tactic
import Mathlib.RingTheory.MvPolynomial.MonomialOrder.DegLex
import Mathlib.Algebra.MvPolynomial.NoZeroDivisors
import Mathlib.Analysis.InnerProductSpace.Positive
import Mathlib.Algebra.Order.Star.Real
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.SmallDegreeVieta

open Polynomial

/-! The card's notation.
* `p : ℝ[X]` is a polynomial in one real variable `x`; `d` is half its degree, so the monomial
  list is `m(x) = (1, x, ..., x^d)`, indexed by `Fin (d + 1)`.
* `Q` is the Gram matrix, rows and columns counted from 0. The sandwich `m(x)ᵀ Q m(x)` is
  `∑ i, ∑ j, Q i j * x^i * x^j`.
* "Sum of squares" is Mathlib's `IsSumSq`; "positive semidefinite" is `Matrix.PosSemidef`.
* Motzkin's polynomial lives in `MvPolynomial (Fin 2) ℝ`, with `X 0` for `x` and `X 1` for `y`. -/

theorem isSumSq_map_ringHom {R S F : Type*} [Semiring R] [Semiring S] [FunLike F R S]
    [RingHomClass F R S] (φ : F) {s : R} (hs : IsSumSq s) : IsSumSq (φ s) := by
  induction hs with
  | zero => simp [IsSumSq.zero]
  | sq_add a _ ih => simpa [map_add, map_mul] using IsSumSq.sq_add (φ a) ih

theorem poly_sos_step (a t : ℝ[X]) (ht : t = 0 ∨ 0 < t.leadingCoeff) :
    (a * a + t = 0 ∨ 0 < (a * a + t).leadingCoeff) ∧
      (a * a).natDegree ≤ (a * a + t).natDegree ∧ t.natDegree ≤ (a * a + t).natDegree := by
  by_cases ha : a = 0
  · subst ha; simpa using ht
  have hA : a * a ≠ 0 := mul_ne_zero ha ha
  have hlcA : 0 < (a * a).leadingCoeff := by
    rw [leadingCoeff_mul]; exact mul_self_pos.mpr (leadingCoeff_ne_zero.mpr ha)
  rcases ht with rfl | ht
  · simp [ha]
  have ht0 : t ≠ 0 := by rintro rfl; simp at ht
  rcases lt_trichotomy (a * a).natDegree t.natDegree with h | h | h
  · have hd : (a * a).degree < t.degree := degree_lt_degree h
    rw [natDegree_add_eq_right_of_natDegree_lt h, leadingCoeff_add_of_degree_lt hd]
    exact ⟨Or.inr ht, h.le, le_rfl⟩
  · have hd : (a * a).degree = t.degree := by
      rw [degree_eq_natDegree hA, degree_eq_natDegree ht0, h]
    have hne : (a * a).leadingCoeff + t.leadingCoeff ≠ 0 := by linarith
    have hdeg := degree_add_eq_of_leadingCoeff_add_ne_zero hne
    rw [hd, max_self] at hdeg
    have hn : (a * a + t).natDegree = t.natDegree := natDegree_eq_of_degree_eq hdeg
    rw [hn, leadingCoeff_add_of_degree_eq hd hne]
    exact ⟨Or.inr (by linarith), h.le, le_rfl⟩
  · have hd : t.degree < (a * a).degree := degree_lt_degree h
    rw [natDegree_add_eq_left_of_natDegree_lt h, leadingCoeff_add_of_degree_lt' hd]
    exact ⟨Or.inr hlcA, le_rfl, h.le⟩

theorem poly_sos_lc {t : ℝ[X]} (ht : IsSumSq t) : t = 0 ∨ 0 < t.leadingCoeff := by
  induction ht with
  | zero => exact Or.inl rfl
  | sq_add a _ ih => exact (poly_sos_step a _ ih).1

theorem mv_sos_step {σ : Type*} (m : MonomialOrder σ) (a t : MvPolynomial σ ℝ)
    (ht : t = 0 ∨ 0 < m.leadingCoeff t) :
    (a * a + t = 0 ∨ 0 < m.leadingCoeff (a * a + t)) ∧
      m.toSyn (m.degree (a * a)) ≤ m.toSyn (m.degree (a * a + t)) ∧
      m.toSyn (m.degree t) ≤ m.toSyn (m.degree (a * a + t)) := by
  by_cases ha : a = 0
  · subst ha; simpa [m.zero_le] using ht
  have hA : a * a ≠ 0 := mul_ne_zero ha ha
  have hlcA : 0 < m.leadingCoeff (a * a) := by
    rw [m.leadingCoeff_mul]; exact mul_self_pos.mpr (m.leadingCoeff_ne_zero_iff.mpr ha)
  rcases ht with rfl | ht
  · simp [ha, m.zero_le]
  rcases lt_trichotomy (m.toSyn (m.degree (a * a))) (m.toSyn (m.degree t)) with h | h | h
  · rw [m.degree_add_eq_right_of_lt h, add_comm, m.leadingCoeff_add_of_lt h]
    exact ⟨Or.inr ht, h.le, le_rfl⟩
  · have hd : m.degree (a * a) = m.degree t := m.toSyn.injective h
    have hc : (a * a + t).coeff (m.degree (a * a)) = m.leadingCoeff (a * a) + m.leadingCoeff t := by
      rw [AddMonoidAlgebra.coeff_add, Finsupp.add_apply]; unfold MonomialOrder.leadingCoeff; rw [← hd]
    have hpos : 0 < (a * a + t).coeff (m.degree (a * a)) := by rw [hc]; linarith
    have hle : m.toSyn (m.degree (a * a)) ≤ m.toSyn (m.degree (a * a + t)) :=
      m.le_degree (MvPolynomial.mem_support_iff.mpr hpos.ne')
    have hge : m.toSyn (m.degree (a * a + t)) ≤ m.toSyn (m.degree (a * a)) := by
      have := m.degree_add_le (f := a * a) (g := t); rwa [h, max_self, ← h] at this
    have heq : m.degree (a * a + t) = m.degree (a * a) := m.toSyn.injective (le_antisymm hge hle)
    refine ⟨Or.inr ?_, hle, h ▸ hle⟩
    rw [MonomialOrder.leadingCoeff, heq]; exact hpos
  · rw [m.degree_add_of_lt h, m.leadingCoeff_add_of_lt h]
    exact ⟨Or.inr hlcA, le_rfl, h.le⟩

theorem mv_sos_lc {σ : Type*} (m : MonomialOrder σ) {t : MvPolynomial σ ℝ} (ht : IsSumSq t) :
    t = 0 ∨ 0 < m.leadingCoeff t := by
  induction ht with
  | zero => exact Or.inl rfl
  | sq_add a _ ih => exact (mv_sos_step m a _ ih).1

theorem coeff_aeval_y_zero (f : MvPolynomial (Fin 2) ℝ) (k : ℕ) :
    (MvPolynomial.aeval ![(X : ℝ[X]), 0] f).coeff k = f.coeff (Finsupp.single 0 k) := by
  induction f using MvPolynomial.induction_on' with
  | monomial u c =>
    rw [MvPolynomial.aeval_monomial, Finsupp.prod_fintype _ _ (by simp), Fin.prod_univ_two,
      MvPolynomial.coeff_monomial, Polynomial.algebraMap_eq]
    have hu : u = Finsupp.single 0 k ↔ u 0 = k ∧ u 1 = 0 := by
      rw [Finsupp.ext_iff, Fin.forall_fin_two]; simp
    simp only [hu]
    rcases Nat.eq_zero_or_pos (u 1) with h1 | h1
    · simp [h1, eq_comm]
    · simp [h1.ne', zero_pow h1.ne']
  | add p q hp hq => simp [hp, hq]

theorem coeff_aeval_x_zero (f : MvPolynomial (Fin 2) ℝ) (k : ℕ) :
    (MvPolynomial.aeval ![0, (X : ℝ[X])] f).coeff k = f.coeff (Finsupp.single 1 k) := by
  induction f using MvPolynomial.induction_on' with
  | monomial u c =>
    rw [MvPolynomial.aeval_monomial, Finsupp.prod_fintype _ _ (by simp), Fin.prod_univ_two,
      MvPolynomial.coeff_monomial, Polynomial.algebraMap_eq]
    have hu : u = Finsupp.single 1 k ↔ u 0 = 0 ∧ u 1 = k := by
      rw [Finsupp.ext_iff, Fin.forall_fin_two]; simp
    simp only [hu]
    rcases Nat.eq_zero_or_pos (u 0) with h0 | h0
    · simp [h0, eq_comm]
    · simp [h0.ne', zero_pow h0.ne']
  | add p q hp hq => simp [hp, hq]

theorem motzkin_good_support (a : MvPolynomial (Fin 2) ℝ) (hdeg : a.totalDegree ≤ 3)
    (hx : (MvPolynomial.aeval ![0, (X : ℝ[X])] a).natDegree = 0)
    (hy : (MvPolynomial.aeval ![(X : ℝ[X]), 0] a).natDegree = 0)
    (u : Fin 2 →₀ ℕ) (hu : a.coeff u ≠ 0) :
    (u 0 = 0 ∧ u 1 = 0) ∨ (u 0 = 1 ∧ u 1 = 1) ∨ (u 0 = 2 ∧ u 1 = 1) ∨ (u 0 = 1 ∧ u 1 = 2) := by
  have h1 : u 0 + u 1 ≤ 3 := by
    have := MvPolynomial.le_totalDegree (MvPolynomial.mem_support_iff.mpr hu)
    rw [Finsupp.sum_fintype _ _ (by simp), Fin.sum_univ_two] at this
    exact this.trans hdeg
  have h2 : u 1 = 0 → u 0 = 0 := by
    intro h
    by_contra h0
    have hu' : u = Finsupp.single 0 (u 0) := by
      ext i; fin_cases i <;> simp [h]
    have hc := coeff_aeval_y_zero a (u 0)
    rw [← hu', Polynomial.coeff_eq_zero_of_natDegree_lt (by omega)] at hc
    exact hu hc.symm
  have h3 : u 0 = 0 → u 1 = 0 := by
    intro h
    by_contra h0
    have hu' : u = Finsupp.single 1 (u 1) := by
      ext i; fin_cases i <;> simp [h]
    have hc := coeff_aeval_x_zero a (u 1)
    rw [← hu', Polynomial.coeff_eq_zero_of_natDegree_lt (by omega)] at hc
    exact hu hc.symm
  omega

theorem motzkin_coeff_mul_self_nonneg (a : MvPolynomial (Fin 2) ℝ)
    (hgood : ∀ u : Fin 2 →₀ ℕ, a.coeff u ≠ 0 →
      (u 0 = 0 ∧ u 1 = 0) ∨ (u 0 = 1 ∧ u 1 = 1) ∨ (u 0 = 2 ∧ u 1 = 1) ∨ (u 0 = 1 ∧ u 1 = 2)) :
    0 ≤ (a * a).coeff (Finsupp.single 0 2 + Finsupp.single 1 2) := by
  classical
  set c : Fin 2 →₀ ℕ := Finsupp.single 0 1 + Finsupp.single 1 1 with hc
  rw [MvPolynomial.coeff_mul, Finset.sum_eq_single (c, c)]
  · exact mul_self_nonneg _
  · intro b hb hne
    rw [Finset.mem_antidiagonal] at hb
    have e0 := congrArg (fun f => f 0) hb
    have e1 := congrArg (fun f => f 1) hb
    simp only [Finsupp.add_apply, Finsupp.single_apply] at e0 e1
    norm_num at e0 e1
    by_contra hprod
    rcases mul_ne_zero_iff.mp hprod with ⟨hb1, hb2⟩
    have g1 := hgood _ hb1
    have g2 := hgood _ hb2
    apply hne
    have : b.1 0 = 1 ∧ b.1 1 = 1 ∧ b.2 0 = 1 ∧ b.2 1 = 1 := by omega
    ext i <;> fin_cases i <;> simp [hc, this]
  · intro h
    exfalso; apply h
    rw [Finset.mem_antidiagonal, hc]
    ext i; fin_cases i <;> simp

theorem motzkin_aux {s : MvPolynomial (Fin 2) ℝ} (hs : IsSumSq s) :
    s.totalDegree ≤ 6 → (MvPolynomial.aeval ![0, (X : ℝ[X])] s).natDegree = 0 →
      (MvPolynomial.aeval ![(X : ℝ[X]), 0] s).natDegree = 0 →
      0 ≤ s.coeff (Finsupp.single 0 2 + Finsupp.single 1 2) := by
  induction hs with
  | zero => intros; simp
  | @sq_add a t ht ih =>
    intro hd hx hy
    have hT := mv_sos_step MonomialOrder.degLex a t (mv_sos_lc _ ht)
    have hdA : (a * a).totalDegree ≤ 6 :=
      (MvPolynomial.degLex_totalDegree_monotone hT.2.1).trans hd
    have hdt : t.totalDegree ≤ 6 := (MvPolynomial.degLex_totalDegree_monotone hT.2.2).trans hd
    have key : ∀ φ : MvPolynomial (Fin 2) ℝ →ₐ[ℝ] ℝ[X], (φ (a * a + t)).natDegree = 0 →
        (φ a).natDegree = 0 ∧ (φ t).natDegree = 0 := by
      intro φ h0
      have hP := poly_sos_step (φ a) (φ t) (poly_sos_lc (isSumSq_map_ringHom φ ht))
      rw [map_add, map_mul] at h0
      rw [h0] at hP
      refine ⟨?_, Nat.le_zero.mp hP.2.2⟩
      by_cases hz : φ a = 0
      · simp [hz]
      have := hP.2.1
      rw [natDegree_mul hz hz] at this
      omega
    obtain ⟨hxa, hxt⟩ := key _ hx
    obtain ⟨hya, hyt⟩ := key _ hy
    have hda : a.totalDegree ≤ 3 := by
      by_cases ha : a = 0
      · simp [ha]
      rw [MvPolynomial.totalDegree_mul_of_isDomain ha ha] at hdA
      omega
    rw [AddMonoidAlgebra.coeff_add, Finsupp.add_apply]
    exact add_nonneg (motzkin_coeff_mul_self_nonneg a (motzkin_good_support a hda hxa hya))
      (ih hdt hxt hyt)

theorem gram_add {d : ℕ} (Q R : Matrix (Fin (d + 1)) (Fin (d + 1)) ℝ) :
    ∑ i : Fin (d + 1), ∑ j : Fin (d + 1), C ((Q + R) i j) * X ^ (i : ℕ) * X ^ (j : ℕ) =
      (∑ i : Fin (d + 1), ∑ j : Fin (d + 1), C (Q i j) * X ^ (i : ℕ) * X ^ (j : ℕ)) +
      ∑ i : Fin (d + 1), ∑ j : Fin (d + 1), C (R i j) * X ^ (i : ℕ) * X ^ (j : ℕ) := by
  simp only [Matrix.add_apply, C_add, add_mul, Finset.sum_add_distrib]

theorem gram_vecMulVec {d : ℕ} (v : Fin (d + 1) → ℝ) :
    ∑ i : Fin (d + 1), ∑ j : Fin (d + 1), C (Matrix.vecMulVec v v i j) * X ^ (i : ℕ) * X ^ (j : ℕ) =
      (∑ i : Fin (d + 1), C (v i) * X ^ (i : ℕ)) * (∑ j : Fin (d + 1), C (v j) * X ^ (j : ℕ)) := by
  rw [Finset.sum_mul_sum]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  rw [Matrix.vecMulVec_apply, C_mul]; ring

theorem poly_eq_sum_fin {d : ℕ} (a : ℝ[X]) (ha : a.natDegree ≤ d) :
    a = ∑ i : Fin (d + 1), C (a.coeff i) * X ^ (i : ℕ) := by
  rw [Fin.sum_univ_eq_sum_range (fun i => C (a.coeff i) * X ^ i)]
  conv_lhs => rw [a.as_sum_range' (d + 1) (by omega)]
  simp [C_mul_X_pow_eq_monomial]

theorem poly_eval_nonneg_of_right {q : ℝ[X]} {r : ℝ} (h : ∀ x, r < x → 0 ≤ q.eval x) :
    0 ≤ q.eval r :=
  ge_of_tendsto ((q.continuous.tendsto r).mono_left nhdsWithin_le_nhds)
    (eventually_nhdsWithin_of_forall (s := Set.Ioi r) h)

theorem poly_eval_nonpos_of_left {q : ℝ[X]} {r : ℝ} (h : ∀ x, x < r → q.eval x ≤ 0) :
    q.eval r ≤ 0 :=
  le_of_tendsto ((q.continuous.tendsto r).mono_left nhdsWithin_le_nhds)
    (eventually_nhdsWithin_of_forall (s := Set.Iio r) h)

#print axioms isSumSq_map_ringHom
#print axioms poly_sos_step
#print axioms poly_sos_lc
#print axioms mv_sos_step
#print axioms mv_sos_lc
#print axioms coeff_aeval_y_zero
#print axioms coeff_aeval_x_zero
#print axioms motzkin_good_support
#print axioms motzkin_coeff_mul_self_nonneg
#print axioms motzkin_aux
#print axioms gram_add
#print axioms gram_vecMulVec
#print axioms poly_eq_sum_fin
#print axioms poly_eval_nonneg_of_right
#print axioms poly_eval_nonpos_of_left

/-- Step 1 of the card: let `p` be a real polynomial of degree at most `2d`. Then `p` is a sum of
squares of polynomials exactly when some positive semidefinite matrix `Q`, sandwiched between two
copies of the monomial list `(1, x, ..., x^d)`, reproduces it: `p = m(x)ᵀ Q m(x)`. -/
theorem isSumSq_iff_exists_posSemidef_gram (p : ℝ[X]) (d : ℕ) (hdeg : p.natDegree ≤ 2 * d) :
    IsSumSq p ↔ ∃ Q : Matrix (Fin (d + 1)) (Fin (d + 1)) ℝ, Q.PosSemidef ∧
      p = ∑ i : Fin (d + 1), ∑ j : Fin (d + 1), C (Q i j) * X ^ (i : ℕ) * X ^ (j : ℕ) := by
  constructor
  · intro hp
    revert hdeg
    induction hp with
    | zero =>
      intro _
      exact ⟨0, Matrix.PosSemidef.zero, by simp⟩
    | @sq_add a t ht ih =>
      intro hdeg
      have hs := poly_sos_step a t (poly_sos_lc ht)
      obtain ⟨Q, hQ, hQt⟩ := ih (hs.2.2.trans hdeg)
      have hda : a.natDegree ≤ d := by
        by_cases ha : a = 0
        · simp [ha]
        have := hs.2.1.trans hdeg
        rw [natDegree_mul ha ha] at this
        omega
      let v : Fin (d + 1) → ℝ := fun i => a.coeff i
      refine ⟨Matrix.vecMulVec v v + Q, ?_, ?_⟩
      · have h1 := Matrix.posSemidef_vecMulVec_self_star v
        simp only [star_trivial] at h1
        exact h1.add hQ
      · rw [gram_add, gram_vecMulVec, ← hQt, ← poly_eq_sum_fin a hda]
  · rintro ⟨Q, hQ, rfl⟩
    obtain ⟨m, v, rfl⟩ := Matrix.posSemidef_iff_eq_sum_vecMulVec.mp hQ
    have : ∑ i : Fin (d + 1), ∑ j : Fin (d + 1),
        C ((∑ k, Matrix.vecMulVec (v k) (star (v k))) i j) * X ^ (i : ℕ) * X ^ (j : ℕ) =
        ∑ k, (∑ i : Fin (d + 1), C (v k i) * X ^ (i : ℕ)) *
          (∑ i : Fin (d + 1), C (v k i) * X ^ (i : ℕ)) := by
      simp_rw [← gram_vecMulVec, Matrix.sum_apply, star_trivial, map_sum, Finset.sum_mul]
      conv_rhs => rw [Finset.sum_comm]
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [Finset.sum_comm]
    rw [this]
    exact IsSumSq.sum_mul_self _ _

/-- Hilbert's one-variable case, proved in the card's fold: a real polynomial that is never
negative is a sum of two squares of real polynomials. -/
theorem exists_sq_add_sq_of_eval_nonneg (p : ℝ[X]) (hp : ∀ x : ℝ, 0 ≤ p.eval x) :
    ∃ a b : ℝ[X], p = a ^ 2 + b ^ 2 := by
  induction hn : p.natDegree using Nat.strong_induction_on generalizing p with
  | _ n ih =>
  by_cases hp0 : p = 0
  · exact ⟨0, 0, by simp [hp0]⟩
  by_cases hroot : ∃ r, p.IsRoot r
  · obtain ⟨r, hr⟩ := hroot
    set q := p /ₘ (X - C r) with hq
    have hpq : p = (X - C r) * q := (mul_divByMonic_eq_iff_isRoot.mpr hr).symm
    have hqr : q.IsRoot r := by
      have h1 : 0 ≤ q.eval r := poly_eval_nonneg_of_right fun x hx => by
        have := hp x
        rw [hpq, eval_mul] at this
        simp only [eval_sub, eval_X, eval_C] at this
        exact (mul_nonneg_iff_of_pos_left (sub_pos.mpr hx)).mp this
      have h2 : q.eval r ≤ 0 := poly_eval_nonpos_of_left fun x hx => by
        have := hp x
        rw [hpq, eval_mul] at this
        simp only [eval_sub, eval_X, eval_C] at this
        by_contra hc
        push Not at hc
        have : (x - r) * q.eval x < 0 := mul_neg_of_neg_of_pos (sub_neg.mpr hx) hc
        linarith
      exact le_antisymm h2 h1
    set s := q /ₘ (X - C r) with hs
    have hqs : q = (X - C r) * s := (mul_divByMonic_eq_iff_isRoot.mpr hqr).symm
    have hps : p = (X - C r) ^ 2 * s := by rw [hpq, hqs]; ring
    have hne : ∀ x, x ≠ r → 0 ≤ s.eval x := fun x hx => by
      have := hp x
      rw [hps] at this
      simp only [eval_mul, eval_pow, eval_sub, eval_X, eval_C] at this
      have hpos : 0 < (x - r) ^ 2 := by
        have : x - r ≠ 0 := sub_ne_zero.mpr hx
        positivity
      exact (mul_nonneg_iff_of_pos_left hpos).mp this
    have hs_nonneg : ∀ x, 0 ≤ s.eval x := by
      intro x
      by_cases hx : x = r
      · subst hx; exact poly_eval_nonneg_of_right fun y hy => hne y hy.ne'
      · exact hne x hx
    have hs0 : s ≠ 0 := by
      rintro h0
      rw [h0, mul_zero] at hps
      exact hp0 hps
    have hdeg : s.natDegree < n := by
      rw [← hn, hps, natDegree_mul (pow_ne_zero 2 (X_sub_C_ne_zero r)) hs0, natDegree_pow,
        natDegree_X_sub_C]
      omega
    obtain ⟨a, b, hab⟩ := ih _ hdeg s hs_nonneg rfl
    exact ⟨(X - C r) * a, (X - C r) * b, by rw [hps, hab]; ring⟩
  push Not at hroot
  by_cases hn0 : p.natDegree = 0
  · have hpC := eq_C_of_natDegree_eq_zero hn0
    have hc : 0 ≤ p.coeff 0 := by have := hp 0; rwa [hpC, eval_C] at this
    refine ⟨C (Real.sqrt (p.coeff 0)), 0, ?_⟩
    rw [← C_pow, Real.sq_sqrt hc]
    simpa using hpC
  have hnu : ¬ IsUnit p := fun hu => hn0 (natDegree_eq_zero_of_isUnit hu)
  obtain ⟨f, hf, hfp⟩ := WfDvdMonoid.exists_irreducible_factor hnu hp0
  obtain ⟨k, hk⟩ := hfp
  have hf_noroot : ∀ x, ¬ f.IsRoot x := fun x hx => hroot x (by
    rw [hk, IsRoot, eval_mul, hx.eq_zero, zero_mul])
  have hf0 : f ≠ 0 := hf.ne_zero
  have hfpos : 0 < f.natDegree := natDegree_pos_iff_degree_pos.mpr (degree_pos_of_irreducible hf)
  have hf1 : f.natDegree ≠ 1 := by
    intro h1
    obtain ⟨x, hx⟩ := exists_root_of_degree_eq_one (by rw [degree_eq_natDegree hf0, h1]; rfl)
    exact hf_noroot x hx
  have hf2 : f.natDegree = 2 := by have := hf.natDegree_le_two; omega
  have hquad := eq_quadratic_of_degree_le_two (p := f) (by rw [degree_eq_natDegree hf0, hf2]; rfl)
  set c2 := f.coeff 2
  set c1 := f.coeff 1
  set c0 := f.coeff 0
  have hc2 : c2 ≠ 0 := by
    have : f.leadingCoeff ≠ 0 := leadingCoeff_ne_zero.mpr hf0
    rwa [leadingCoeff, hf2] at this
  set u : ℝ := -c1 / (2 * c2) with hu
  set w : ℝ := c0 / c2 - u ^ 2 with hw
  have e1 : c1 = c2 * (-(2 * u)) := by rw [hu]; field_simp
  have e0 : c0 = c2 * (u ^ 2 + w) := by rw [hw]; field_simp; ring
  have hfg : f = C c2 * ((X - C u) ^ 2 + C w) := by
    rw [hquad, e1, e0]
    simp only [map_mul, map_neg, map_add, map_pow, map_ofNat]
    ring
  have hwpos : 0 < w := by
    by_contra hw0
    push Not at hw0
    apply hf_noroot (u + Real.sqrt (-w))
    rw [IsRoot, hfg]
    simp only [eval_mul, eval_add, eval_pow, eval_sub, eval_X, eval_C]
    rw [add_sub_cancel_left, Real.sq_sqrt (neg_nonneg.mpr hw0)]
    ring
  set g : ℝ[X] := (X - C u) ^ 2 + C w with hg
  set s : ℝ[X] := C c2 * k with hs
  have hps : p = g * s := by rw [hk, hfg, hs]; ring
  have hgpos : ∀ x, 0 < g.eval x := fun x => by
    simp only [hg, eval_add, eval_pow, eval_sub, eval_X, eval_C]
    positivity
  have hs_nonneg : ∀ x, 0 ≤ s.eval x := fun x => by
    have := hp x
    rw [hps, eval_mul] at this
    exact (mul_nonneg_iff_of_pos_left (hgpos x)).mp this
  have hs0 : s ≠ 0 := by
    rintro h0
    rw [h0, mul_zero] at hps
    exact hp0 hps
  have hgdeg : g.natDegree = 2 := by
    rw [hg, natDegree_add_C, natDegree_pow, natDegree_X_sub_C]
  have hg0 : g ≠ 0 := by
    intro h0; rw [h0] at hgdeg; simp at hgdeg
  have hdeg : s.natDegree < n := by
    rw [← hn, hps, natDegree_mul hg0 hs0, hgdeg]
    omega
  obtain ⟨a, b, hab⟩ := ih _ hdeg s hs_nonneg rfl
  have hw' : C (Real.sqrt w) ^ 2 = C w := by rw [← C_pow, Real.sq_sqrt hwpos.le]
  refine ⟨(X - C u) * a - C (Real.sqrt w) * b, (X - C u) * b + C (Real.sqrt w) * a, ?_⟩
  rw [hps, hab, hg, ← hw']
  ring

/-- Step 6 of the card: Motzkin's polynomial `M(x, y) = x⁴y² + x²y⁴ - 3x²y² + 1` is never
negative, yet for every floor `g` the polynomial `M - g` is not a sum of squares. -/
theorem motzkin_nonneg_and_not_isSumSq :
    let M : MvPolynomial (Fin 2) ℝ :=
      MvPolynomial.X 0 ^ 4 * MvPolynomial.X 1 ^ 2 + MvPolynomial.X 0 ^ 2 * MvPolynomial.X 1 ^ 4
        - 3 * MvPolynomial.X 0 ^ 2 * MvPolynomial.X 1 ^ 2 + 1
    (∀ v : Fin 2 → ℝ, 0 ≤ MvPolynomial.eval v M) ∧
      ∀ g : ℝ, ¬ IsSumSq (M - MvPolynomial.C g) := by
  intro M
  refine ⟨fun v => ?_, fun g hg => ?_⟩
  · simp only [M, map_add, map_sub, map_mul, map_pow, MvPolynomial.eval_X, map_one, map_ofNat]
    have key : (1 + v 0 ^ 2 + v 1 ^ 2) *
        (v 0 ^ 4 * v 1 ^ 2 + v 0 ^ 2 * v 1 ^ 4 - 3 * v 0 ^ 2 * v 1 ^ 2 + 1)
      = (v 0 ^ 2 * v 1 - v 1) ^ 2 + (v 0 * v 1 ^ 2 - v 0) ^ 2 + (v 0 ^ 2 * v 1 ^ 2 - 1) ^ 2
        + 1 / 4 * (v 0 * v 1 ^ 3 - v 0 ^ 3 * v 1) ^ 2
        + 3 / 4 * (v 0 * v 1 ^ 3 + v 0 ^ 3 * v 1 - 2 * v 0 * v 1) ^ 2 := by ring
    have hpos : 0 < 1 + v 0 ^ 2 + v 1 ^ 2 := by positivity
    have hprod : 0 ≤ (1 + v 0 ^ 2 + v 1 ^ 2) *
        (v 0 ^ 4 * v 1 ^ 2 + v 0 ^ 2 * v 1 ^ 4 - 3 * v 0 ^ 2 * v 1 ^ 2 + 1) := by
      rw [key]; positivity
    exact (mul_nonneg_iff_of_pos_left hpos).mp hprod
  · have h3 : (3 : MvPolynomial (Fin 2) ℝ) = MvPolynomial.C 3 := (map_ofNat MvPolynomial.C 3).symm
    have hdeg : (M - MvPolynomial.C g).totalDegree ≤ 6 := by
      simp only [M]
      rw [h3]
      refine (MvPolynomial.totalDegree_sub _ _).trans (max_le ?_ (by simp))
      refine (MvPolynomial.totalDegree_add _ _).trans (max_le ?_ (by simp))
      refine (MvPolynomial.totalDegree_sub _ _).trans (max_le ?_ ?_)
      · refine (MvPolynomial.totalDegree_add _ _).trans (max_le ?_ ?_) <;>
          exact (MvPolynomial.totalDegree_mul _ _).trans (by simp [MvPolynomial.totalDegree_X_pow])
      · refine (MvPolynomial.totalDegree_mul _ _).trans ?_
        refine (Nat.add_le_add_right (MvPolynomial.totalDegree_mul _ _) _).trans ?_
        simp [MvPolynomial.totalDegree_X_pow]
    have hx : (MvPolynomial.aeval ![0, (X : ℝ[X])] (M - MvPolynomial.C g)).natDegree = 0 := by
      simp [M, MvPolynomial.aeval_X]
    have hy : (MvPolynomial.aeval ![(X : ℝ[X]), 0] (M - MvPolynomial.C g)).natDegree = 0 := by
      simp [M, MvPolynomial.aeval_X]
    have hc : (M - MvPolynomial.C g).coeff (Finsupp.single 0 2 + Finsupp.single 1 2) = -3 := by
      simp only [M]
      rw [h3, ← MvPolynomial.C_1]
      simp only [MvPolynomial.X_pow_eq_monomial, MvPolynomial.monomial_mul_monomial,
        MvPolynomial.C_mul_monomial, MvPolynomial.coeff_sub, AddMonoidAlgebra.coeff_add, Finsupp.add_apply,
        MvPolynomial.coeff_monomial, MvPolynomial.coeff_C]
      simp [Finsupp.ext_iff, Fin.forall_fin_two, Finsupp.single_apply]
    have := motzkin_aux hg hdeg hx hy
    linarith

-- The hedge cost p(x) = x⁴ - 4x³ + 6x² - 4x + 5 is (x - 1)⁴ + 4, so it is never below 4.
example : (X ^ 4 - 4 * X ^ 3 + 6 * X ^ 2 - 4 * X + 5 : ℝ[X]) = (X ^ 2 - 2 * X + 1) ^ 2 + 4 ∧
    (X ^ 2 - 2 * X + 1 : ℝ[X]) ^ 2 = (X - 1) ^ 4 := by
  constructor <;> ring

-- Sample ratios: p(0) = 5, p(1) = 4, p(2) = 5, p(3) = 20 (£ thousand).
example : (fun x : ℤ => x ^ 4 - 4 * x ^ 3 + 6 * x ^ 2 - 4 * x + 5) 0 = 5 ∧
    (fun x : ℤ => x ^ 4 - 4 * x ^ 3 + 6 * x ^ 2 - 4 * x + 5) 1 = 4 ∧
    (fun x : ℤ => x ^ 4 - 4 * x ^ 3 + 6 * x ^ 2 - 4 * x + 5) 2 = 5 ∧
    (fun x : ℤ => x ^ 4 - 4 * x ^ 3 + 6 * x ^ 2 - 4 * x + 5) 3 = 20 := by
  norm_num

-- The Gram matrix at g = 4, t = 1 is v vᵀ with v = (1, -2, 1), and m(x)ᵀ Q m(x) = p - 4.
example : (!![1, -2, 1; -2, 4, -2; 1, -2, 1] : Matrix (Fin 3) (Fin 3) ℤ)
    = Matrix.vecMulVec ![1, -2, 1] ![1, -2, 1] := by
  ext i j; fin_cases i <;> fin_cases j <;> rfl

example : (X ^ 4 - 4 * X ^ 3 + 6 * X ^ 2 - 4 * X + 5 - 4 : ℝ[X]) =
    ∑ i : Fin 3, ∑ j : Fin 3,
      C ((!![1, -2, 1; -2, 4, -2; 1, -2, 1] : Matrix (Fin 3) (Fin 3) ℝ) i j)
        * X ^ (i : ℕ) * X ^ (j : ℕ) := by
  simp [Fin.sum_univ_three, map_ofNat]; ring

-- Step 3: the full determinant of Q(g, t) factors as 2(1 - t)(4 - g - (t - 1)²).
example (g t : ℝ) :
    (!![5 - g, -2, t; -2, 6 - 2 * t, -2; t, -2, 1] : Matrix (Fin 3) (Fin 3) ℝ).det
      = 2 * (1 - t) * (4 - g - (t - 1) ^ 2) := by
  simp [Matrix.det_fin_three]; ring

-- Without the PSD rule: at g = 10, t = 1 the corner entry 5 - 10 = -5 is negative, so Q is not PSD.
example : ¬ (!![5 - 10, -2, 1; -2, 6 - 2 * 1, -2; 1, -2, 1] : Matrix (Fin 3) (Fin 3) ℝ).PosSemidef := by
  intro h
  have := h.diag_nonneg (i := 0)
  norm_num at this

-- Below the best floor: p - 3 = (x² - 2x + 1)² + 1².
example : (X ^ 4 - 4 * X ^ 3 + 6 * X ^ 2 - 4 * X + 5 - 3 : ℝ[X]) = (X ^ 2 - 2 * X + 1) ^ 2 + 1 ^ 2 := by
  ring

-- Step 4, the dual: the moment matrix of x = 1 is all ones, so ⟨Q, Y⟩ is the sum of Q's entries, 0,
-- and the dual value L(p) = p(1) = 1 - 4 + 6 - 4 + 5 = 4.
example : (1 : ℤ) - 2 + 1 - 2 + 4 - 2 + 1 - 2 + 1 = 0 ∧ (1 : ℤ) - 4 + 6 - 4 + 5 = 4 := by
  norm_num

-- The fold: a product of two sums of two squares is a sum of two squares.
example (a b c d : ℝ) : (a ^ 2 + b ^ 2) * (c ^ 2 + d ^ 2) = (a * c - b * d) ^ 2 + (a * d + b * c) ^ 2 := by
  ring

-- Motzkin's polynomial is 0 at (1, 1).
example : (1 : ℤ) ^ 4 * 1 ^ 2 + 1 ^ 2 * 1 ^ 4 - 3 * 1 ^ 2 * 1 ^ 2 + 1 = 0 := by
  norm_num

-- Step 7: (1 + x² + y²) M is a sum of five squares, exactly.
example (x y : ℚ) :
    (1 + x ^ 2 + y ^ 2) * (x ^ 4 * y ^ 2 + x ^ 2 * y ^ 4 - 3 * x ^ 2 * y ^ 2 + 1)
      = (x ^ 2 * y - y) ^ 2 + (x * y ^ 2 - x) ^ 2 + (x ^ 2 * y ^ 2 - 1) ^ 2
        + 1 / 4 * (x * y ^ 3 - x ^ 3 * y) ^ 2 + 3 / 4 * (x * y ^ 3 + x ^ 3 * y - 2 * x * y) ^ 2 := by
  ring

-- Try changing: with constant 7 in place of 5, p - 6 = (x - 1)⁴, so the floor is 6.
example : (X ^ 4 - 4 * X ^ 3 + 6 * X ^ 2 - 4 * X + 7 - 6 : ℝ[X]) = (X - 1) ^ 4 := by
  ring

#print axioms isSumSq_iff_exists_posSemidef_gram
#print axioms exists_sq_add_sq_of_eval_nonneg
#print axioms motzkin_nonneg_and_not_isSumSq
