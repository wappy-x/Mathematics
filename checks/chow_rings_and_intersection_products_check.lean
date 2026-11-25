-- The Chow ring: in Z[a, b]/(a^2, b^2) two curve classes multiply to exactly (d1 e2 + e1 d2) points, in Z[H]/(H^(n+1)) classes of degrees d and e multiply to exactly d e points, and the card's counts 6, 2 and 5 come out of the ring.
import Mathlib.RingTheory.Ideal.Quotient.Basic
import Mathlib.Algebra.MvPolynomial.CommRing
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Coeff
import Mathlib.Tactic.LinearCombination

open MvPolynomial

/-- The Chow ring of `P^1 x P^1`, as the card presents it: `Z[a, b]/(a^2, b^2)`. -/
abbrev ChowP1P1 : Type := MvPolynomial (Fin 2) ℤ ⧸ Ideal.span {(X 0 : MvPolynomial (Fin 2) ℤ) ^ 2, X 1 ^ 2}

/-- The class `a` of a vertical line `x = constant`. -/
noncomputable abbrev vA : ChowP1P1 := Ideal.Quotient.mk _ (X 0)

/-- The class `b` of a horizontal line `y = constant`. -/
noncomputable abbrev hB : ChowP1P1 := Ideal.Quotient.mk _ (X 1)

/-- The Chow ring of `P^n`, as the card presents it: `Z[H]/(H^(n+1))`. -/
abbrev ChowPn (n : ℕ) : Type := Polynomial ℤ ⧸ Ideal.span {(Polynomial.X : Polynomial ℤ) ^ (n + 1)}

/-- The hyperplane class `H` in the Chow ring of `P^n`. -/
noncomputable abbrev hyp (n : ℕ) : ChowPn n := Ideal.Quotient.mk _ Polynomial.X

theorem chowP1P1_vA_sq : vA * vA = 0 := by
  rw [← map_mul, Ideal.Quotient.eq_zero_iff_mem, ← sq]
  exact Ideal.subset_span (by simp)

#print axioms chowP1P1_vA_sq

theorem chowP1P1_hB_sq : hB * hB = 0 := by
  rw [← map_mul, Ideal.Quotient.eq_zero_iff_mem, ← sq]
  exact Ideal.subset_span (by simp)

#print axioms chowP1P1_hB_sq

theorem chowP1P1_coeff_eq_zero (p : MvPolynomial (Fin 2) ℤ)
    (hp : p ∈ Ideal.span {(X 0 : MvPolynomial (Fin 2) ℤ) ^ 2, X 1 ^ 2})
    (m : Fin 2 →₀ ℕ) (h0 : m 0 ≤ 1) (h1 : m 1 ≤ 1) : p.coeff m = 0 := by
  obtain ⟨f, g, rfl⟩ := Ideal.mem_span_pair.mp hp
  simp only [AddMonoidAlgebra.coeff_add, Finsupp.coe_add, Pi.add_apply] ; rw [ X_pow_eq_monomial, X_pow_eq_monomial, coeff_mul_monomial', coeff_mul_monomial']
  have a0 : ¬ Finsupp.single (0 : Fin 2) 2 ≤ m := fun h => by
    have := h 0; simp at this; omega
  have a1 : ¬ Finsupp.single (1 : Fin 2) 2 ≤ m := fun h => by
    have := h 1; simp at this; omega
  simp [a0, a1]

#print axioms chowP1P1_coeff_eq_zero

theorem chowP1P1_unique (c c' : ℤ × ℤ × ℤ × ℤ)
    (h : (c.1 : ChowP1P1) + c.2.1 • vA + c.2.2.1 • hB + c.2.2.2 • (vA * hB)
      = (c'.1 : ChowP1P1) + c'.2.1 • vA + c'.2.2.1 • hB + c'.2.2.2 • (vA * hB)) : c = c' := by
  obtain ⟨c0, c1, c2, c3⟩ := c
  obtain ⟨c0', c1', c2', c3'⟩ := c'
  simp only [zsmul_eq_mul] at h
  rw [← sub_eq_zero] at h
  have hP : (C (c0 - c0') + C (c1 - c1') * X 0 + C (c2 - c2') * X 1
      + C (c3 - c3') * (X 0 * X 1) : MvPolynomial (Fin 2) ℤ) = monomial 0 (c0 - c0') + monomial (Finsupp.single 0 1) (c1 - c1')
      + monomial (Finsupp.single 1 1) (c2 - c2')
      + monomial (Finsupp.single 0 1 + Finsupp.single 1 1) (c3 - c3') := by
    simp only [X, monomial_mul_monomial, mul_one, C_apply, zero_add]
  have key : Ideal.Quotient.mk _ (monomial 0 (c0 - c0') + monomial (Finsupp.single 0 1) (c1 - c1')
      + monomial (Finsupp.single 1 1) (c2 - c2')
      + monomial (Finsupp.single 0 1 + Finsupp.single 1 1) (c3 - c3')) = (0 : ChowP1P1) := by
    rw [← hP, ← h]; simp; ring
  rw [Ideal.Quotient.eq_zero_iff_mem] at key
  have n1 : (0 : Fin 2 →₀ ℕ) ≠ Finsupp.single 0 1 := fun h => by
    have := congrArg (· 0) h; simp at this
  have n2 : (0 : Fin 2 →₀ ℕ) ≠ Finsupp.single 1 1 := fun h => by
    have := congrArg (· 1) h; simp at this
  have n3 : (0 : Fin 2 →₀ ℕ) ≠ Finsupp.single 0 1 + Finsupp.single 1 1 := fun h => by
    have := congrArg (· 0) h; simp at this
  have n4 : Finsupp.single (0 : Fin 2) 1 ≠ Finsupp.single 1 1 := fun h => by
    have := congrArg (· 0) h; simp at this
  have n5 : Finsupp.single (0 : Fin 2) 1 ≠ Finsupp.single 0 1 + Finsupp.single 1 1 := fun h => by
    have := congrArg (· 1) h; simp at this
  have n6 : Finsupp.single (1 : Fin 2) 1 ≠ Finsupp.single 0 1 + Finsupp.single 1 1 := fun h => by
    have := congrArg (· 0) h; simp at this
  have e0 := chowP1P1_coeff_eq_zero _ key 0 (by simp) (by simp)
  have e1 := chowP1P1_coeff_eq_zero _ key (Finsupp.single 0 1) (by simp) (by simp)
  have e2 := chowP1P1_coeff_eq_zero _ key (Finsupp.single 1 1) (by simp) (by simp)
  have e3 := chowP1P1_coeff_eq_zero _ key (Finsupp.single 0 1 + Finsupp.single 1 1) (by simp) (by simp)
  simp only [AddMonoidAlgebra.coeff_add, Finsupp.coe_add, Pi.add_apply, coeff_monomial,
    n1, n2, n3, n4, n5, n6, n1.symm, n2.symm, n3.symm, n4.symm, n5.symm, n6.symm,
    ite_true, ite_false] at e0 e1 e2 e3
  simp only [Prod.mk.injEq]
  omega

#print axioms chowP1P1_unique

theorem chowPn_hyp_pow_succ (n : ℕ) : hyp n ^ (n + 1) = 0 := by
  rw [← map_pow, Ideal.Quotient.eq_zero_iff_mem]
  exact Ideal.subset_span (by simp)

#print axioms chowPn_hyp_pow_succ

theorem chowPn_smul_hyp_pow_eq_zero (n : ℕ) (k : ℤ) (h : k • hyp n ^ n = 0) : k = 0 := by
  have h' : Ideal.Quotient.mk (Ideal.span {(Polynomial.X : Polynomial ℤ) ^ (n + 1)})
      (Polynomial.C k * Polynomial.X ^ n) = 0 := by
    rw [← h]; simp [zsmul_eq_mul]
  rw [Ideal.Quotient.eq_zero_iff_mem, Ideal.mem_span_singleton] at h'
  obtain ⟨f, hf⟩ := h'
  have := congrArg (fun g => Polynomial.coeff g n) hf
  simp only [Polynomial.coeff_C_mul_X_pow, Polynomial.coeff_X_pow_mul'] at this
  simpa using this

#print axioms chowPn_smul_hyp_pow_eq_zero

/-- The card's product rule on `P^1 x P^1`: in `Z[a, b]/(a^2, b^2)`, curves of classes
`d1 a + e1 b` and `d2 a + e2 b` multiply to `N` times the point class `ab` exactly when
`N = d1 e2 + e1 d2`. So the meeting count is that whole number and no other (the point
class `ab` is not killed by any nonzero whole number). -/
theorem bidegree_product_counts_d1e2_plus_e1d2 (d₁ e₁ d₂ e₂ N : ℤ) :
    (d₁ • vA + e₁ • hB) * (d₂ • vA + e₂ • hB) = N • (vA * hB) ↔ N = d₁ * e₂ + e₁ * d₂ := by
  have key : (d₁ • vA + e₁ • hB) * (d₂ • vA + e₂ • hB) = (d₁ * e₂ + e₁ * d₂) • (vA * hB) := by
    simp only [zsmul_eq_mul]; push_cast
    linear_combination ((d₁ : ChowP1P1) * d₂) * chowP1P1_vA_sq + ((e₁ : ChowP1P1) * e₂) * chowP1P1_hB_sq
  rw [key]
  constructor
  · intro h
    have := chowP1P1_unique (0, 0, 0, N) (0, 0, 0, d₁ * e₂ + e₁ * d₂) (by simp only [Int.cast_zero, zero_smul, zero_add]; exact h.symm)
    simp only [Prod.mk.injEq] at this
    exact this.2.2.2
  · rintro rfl; rfl

/-- Bezout's theorem as a product in `Z[H]/(H^(n+1))`: `H^(n+1) = 0`, and when the
codimensions `p` and `q` add up to `n`, the classes `d H^p` and `e H^q` multiply to `N` times the
point class `H^n` exactly when `N = d e`. So `H^n` is one point and the count is `d e`. -/
theorem bezout_in_chow_ring_of_projective_space (n p q : ℕ) (hpq : p + q = n) (d e N : ℤ) :
    hyp n ^ (n + 1) = 0 ∧
      ((d • hyp n ^ p) * (e • hyp n ^ q) = N • hyp n ^ n ↔ N = d * e) := by
  refine ⟨chowPn_hyp_pow_succ n, ?_⟩
  have key : (d • hyp n ^ p) * (e • hyp n ^ q) = (d * e) • hyp n ^ n := by
    rw [smul_mul_smul_comm, ← pow_add, hpq]
  rw [key]
  constructor
  · intro h
    have := chowPn_smul_hyp_pow_eq_zero n (d * e - N) (by rw [sub_smul, h, sub_self])
    omega
  · rintro rfl; rfl

/-- The ring `Z[a, b]/(a^2, b^2)` has whole-number basis `1, a, b, ab`: every class is
`c0 + c1 a + c2 b + c3 ab` for exactly one choice of whole numbers. So `A^1 = Z a + Z b` and
`A^2 = Z ab`, and every top class is a whole-number multiple of one point. -/
theorem chow_p1p1_basis (x : ChowP1P1) :
    ∃! c : ℤ × ℤ × ℤ × ℤ,
      x = (c.1 : ChowP1P1) + c.2.1 • vA + c.2.2.1 • hB + c.2.2.2 • (vA * hB) := by
  suffices hex : ∃ c : ℤ × ℤ × ℤ × ℤ,
      x = (c.1 : ChowP1P1) + c.2.1 • vA + c.2.2.1 • hB + c.2.2.2 • (vA * hB) by
    obtain ⟨c, hc⟩ := hex
    exact ⟨c, hc, fun c' hc' => chowP1P1_unique _ _ (hc'.symm.trans hc)⟩
  obtain ⟨p, rfl⟩ := Ideal.Quotient.mk_surjective x
  induction p using MvPolynomial.induction_on with
  | C a => exact ⟨(a, 0, 0, 0), by simp⟩
  | add p q hp hq =>
    obtain ⟨c, hc⟩ := hp
    obtain ⟨c', hc'⟩ := hq
    refine ⟨(c.1 + c'.1, c.2.1 + c'.2.1, c.2.2.1 + c'.2.2.1, c.2.2.2 + c'.2.2.2), ?_⟩
    rw [map_add, hc, hc']
    simp only [zsmul_eq_mul]; push_cast; ring
  | mul_X p i hp =>
    obtain ⟨c, hc⟩ := hp
    rw [map_mul, hc]
    obtain rfl | rfl : i = 0 ∨ i = 1 := by omega
    · refine ⟨(0, c.1, 0, c.2.2.1), ?_⟩
      simp only [zsmul_eq_mul]; push_cast
      linear_combination ((c.2.1 : ChowP1P1) + c.2.2.2 * hB) * chowP1P1_vA_sq
    · refine ⟨(0, 0, c.1, c.2.1), ?_⟩
      simp only [zsmul_eq_mul]; push_cast
      linear_combination ((c.2.2.1 : ChowP1P1) + c.2.2.2 * vA) * chowP1P1_hB_sq

-- A(P^2): a conic times a cubic, 2H x 3H = 6H^2, six points; and H^3 = 0.
example : ((2 : ℤ) • hyp 2) * ((3 : ℤ) • hyp 2) = (6 : ℤ) • hyp 2 ^ 2 := by
  rw [smul_mul_smul_comm, ← sq]; norm_num
example : hyp 2 ^ 3 = 0 := by exact chowPn_hyp_pow_succ 2
-- A(P^1 x P^1): a^2 = 0, (a + b)^2 = 2ab, (2a + 3b)(a + b) = 5ab.
example : vA * vA = 0 := by exact chowP1P1_vA_sq
example : (vA + hB) ^ 2 = (2 : ℤ) • (vA * hB) := by
  simp only [zsmul_eq_mul]; push_cast
  linear_combination chowP1P1_vA_sq + chowP1P1_hB_sq
example : ((2 : ℤ) • vA + (3 : ℤ) • hB) * (vA + hB) = (5 : ℤ) • (vA * hB) := by
  simp only [zsmul_eq_mul]; push_cast
  linear_combination 2 * chowP1P1_vA_sq + 3 * chowP1P1_hB_sq
-- The counts as whole numbers: 2 x 3 = 6; 1*1 + 1*1 = 2; 2*1 + 3*1 = 5; Bezout in P^2 gives 2 x 2 = 4.
example : (2 : ℤ) * 3 = 6 ∧ 1 * 1 + 1 * 1 = 2 ∧ 2 * 1 + 3 * 1 = 5 ∧ 2 * 2 = 4 := by norm_num
-- Solving by hand: y = 2/x in the cubic D, in C', and in Q.
example (x : ℤ) : x ^ 6 - 21 * x ^ 4 + 84 * x ^ 2 - 64 = (x ^ 2 - 1) * (x ^ 2 - 4) * (x ^ 2 - 16) := by ring
example (x : ℤ) : x ^ 2 - x - 2 = (x - 2) * (x + 1) := by ring
example (x : ℤ) : x ^ 5 - 4 * x ^ 4 - 5 * x ^ 3 + 20 * x ^ 2 + 4 * x - 16
    = (x ^ 2 - 1) * (x ^ 2 - 4) * (x - 4) := by ring
-- xy = 2 and x + y = 1: x^2 - x + 2 has discriminant -7, so no real meeting point.
example : (-1 : ℤ) ^ 2 - 4 * 1 * 2 = -7 := by norm_num
-- The cone: H = 2L and H.H = 2 would need 4 (L.L) = 2, which no whole number solves.
example : ¬ ∃ k : ℤ, 2 * 2 * k = 2 := by omega

#print axioms bidegree_product_counts_d1e2_plus_e1d2
#print axioms bezout_in_chow_ring_of_projective_space
#print axioms chow_p1p1_basis
