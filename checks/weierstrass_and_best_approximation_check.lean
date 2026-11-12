-- Weierstrass and the minimax fit: every continuous function on a closed interval is uniformly within any tolerance of a polynomial, and a polynomial whose error reaches its full height n + 2 times with alternating signs has the smallest worst error among polynomials of degree at most n.
import Mathlib.Topology.ContinuousMap.Weierstrass
import Mathlib.RingTheory.Polynomial.Bernstein
import Mathlib.Order.Interval.Set.Basic

open Polynomial Set

/-- A nonzero-at-the-nodes polynomial of degree at most n cannot change sign between
n + 2 consecutive increasing points: it would have n + 1 distinct roots. -/
lemma alt_sign_poly_absurd (n : ℕ) (r : ℝ[X]) (hr : r.natDegree ≤ n)
    (x : Fin (n + 2) → ℝ) (hx : StrictMono x)
    (hneg : ∀ i : Fin (n + 1), r.eval (x i.castSucc) * r.eval (x i.succ) < 0) : False := by
  have hroot : ∀ i : Fin (n + 1), ∃ z, x i.castSucc ≤ z ∧ z < x i.succ ∧ r.eval z = 0 := by
    intro i
    have hlt : x i.castSucc < x i.succ := hx (Fin.castSucc_lt_succ (i := i))
    have hcont : ContinuousOn (fun t => r.eval t) (Icc (x i.castSucc) (x i.succ)) :=
      r.continuous.continuousOn
    have hmem : (0 : ℝ) ∈ (fun t => r.eval t) '' Icc (x i.castSucc) (x i.succ) := by
      rcases mul_neg_iff.mp (hneg i) with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · exact intermediate_value_Icc' hlt.le hcont ⟨h2.le, h1.le⟩
      · exact intermediate_value_Icc hlt.le hcont ⟨h1.le, h2.le⟩
    obtain ⟨z, ⟨hz1, hz2⟩, hz⟩ := hmem
    refine ⟨z, hz1, lt_of_le_of_ne hz2 ?_, hz⟩
    rintro rfl
    have := hneg i
    simp only at hz
    rw [hz, mul_zero] at this
    exact lt_irrefl _ this
  choose z hz1 hz2 hz3 using hroot
  have hmono : StrictMono z := by
    intro i j hij
    have hle : i.succ ≤ j.castSucc := by
      rw [Fin.le_iff_val_le_val]
      simp only [Fin.val_succ, Fin.val_castSucc]
      exact hij
    exact lt_of_lt_of_le (hz2 i) (le_trans (hx.monotone hle) (hz1 j))
  have h0 : r = 0 :=
    Polynomial.eq_zero_of_natDegree_lt_card_of_eval_eq_zero r hmono.injective hz3
      (by simp only [Fintype.card_fin]; omega)
  have := hneg 0
  rw [h0] at this
  simp at this

/-- Core of de la Vallée Poussin's bound, stated as a helper so both theorems can use it. -/
lemma dlvp_core (a b : ℝ) (f : ℝ → ℝ) (hf : ContinuousOn f (Icc a b))
    (n : ℕ) (p : ℝ[X]) (hp : p.natDegree ≤ n)
    (x : Fin (n + 2) → ℝ) (hx : StrictMono x) (hxI : ∀ i, x i ∈ Icc a b)
    (σ : ℝ) (hσ : σ = 1 ∨ σ = -1) (m : ℝ)
    (halt : ∀ i : Fin (n + 2), m ≤ σ * (-1) ^ (i : ℕ) * (f (x i) - p.eval (x i))) :
    ∀ q : ℝ[X], q.natDegree ≤ n → m ≤ ⨆ y : Icc a b, |f y - q.eval (y : ℝ)| := by
  intro q hq
  have hbdd : BddAbove (range fun y : Icc a b => |f y - q.eval (y : ℝ)|) := by
    have hc : ContinuousOn (fun y => |f y - q.eval y|) (Icc a b) :=
      (hf.sub q.continuous.continuousOn).abs
    obtain ⟨M, hM⟩ := isCompact_Icc.bddAbove_image hc
    refine ⟨M, ?_⟩
    rintro _ ⟨y, rfl⟩
    exact hM ⟨y, y.2, rfl⟩
  by_contra hlt
  push Not at hlt
  have hsmall : ∀ i, |f (x i) - q.eval (x i)| < m := fun i =>
    lt_of_le_of_lt (le_ciSup hbdd (⟨x i, hxI i⟩ : Icc a b)) hlt
  apply alt_sign_poly_absurd n (q - p) ((natDegree_sub_le q p).trans (max_le hq hp)) x hx
  intro i
  have h1 := halt i.castSucc
  have h2 := halt i.succ
  have s1 := abs_lt.mp (hsmall i.castSucc)
  have s2 := abs_lt.mp (hsmall i.succ)
  simp only [Fin.val_castSucc, Fin.val_succ, pow_succ] at h1 h2
  simp only [eval_sub]
  rcases hσ with rfl | rfl <;> rcases neg_one_pow_eq_or ℝ (i : ℕ) with h | h <;>
    rw [h] at h1 h2 <;> norm_num at h1 h2
  · exact mul_neg_of_pos_of_neg (by linarith) (by linarith)
  · exact mul_neg_of_neg_of_pos (by linarith) (by linarith)
  · exact mul_neg_of_neg_of_pos (by linarith) (by linarith)
  · exact mul_neg_of_pos_of_neg (by linarith) (by linarith)

/-- Weierstrass's theorem: if f is continuous on the closed interval [a, b], then for every
tolerance ε > 0 there is a polynomial p whose error |f(x) - p(x)| is below ε at every x
in [a, b]. -/
theorem weierstrass_approximation (a b : ℝ) (f : ℝ → ℝ) (hf : ContinuousOn f (Icc a b))
    (ε : ℝ) (hε : 0 < ε) :
    ∃ p : ℝ[X], ∀ x ∈ Icc a b, |f x - p.eval x| < ε := by
  obtain ⟨p, hp⟩ := exists_polynomial_near_of_continuousOn a b f hf ε hε
  exact ⟨p, fun x hx => by rw [abs_sub_comm]; exact hp x hx⟩

/-- Equioscillation means best (Chebyshev): let f be continuous on [a, b] and p a polynomial
of degree at most n. If its error f - p reaches its worst size E = max |f - p| on [a, b] at
n + 2 points x₀ < x₁ < ... < x_{n+1} of [a, b], with signs σ(-1)^i alternating, then no
polynomial q of degree at most n has a smaller worst error on [a, b]. -/
theorem equioscillation_implies_minimax (a b : ℝ) (f : ℝ → ℝ) (hf : ContinuousOn f (Icc a b))
    (n : ℕ) (p : ℝ[X]) (hp : p.natDegree ≤ n)
    (x : Fin (n + 2) → ℝ) (hx : StrictMono x) (hxI : ∀ i, x i ∈ Icc a b)
    (σ : ℝ) (hσ : σ = 1 ∨ σ = -1)
    (heq : ∀ i : Fin (n + 2),
      f (x i) - p.eval (x i) = σ * (-1) ^ (i : ℕ) * ⨆ y : Icc a b, |f y - p.eval (y : ℝ)|) :
    ∀ q : ℝ[X], q.natDegree ≤ n →
      (⨆ y : Icc a b, |f y - p.eval (y : ℝ)|) ≤ ⨆ y : Icc a b, |f y - q.eval (y : ℝ)| := by
  refine dlvp_core a b f hf n p hp x hx hxI σ hσ _ ?_
  intro i
  rw [heq i]
  have hs : σ * σ = 1 := by rcases hσ with rfl | rfl <;> norm_num
  have ht : ((-1 : ℝ) ^ (i : ℕ)) * (-1) ^ (i : ℕ) = 1 := by
    rw [← pow_add, ← two_mul, pow_mul]; norm_num
  apply le_of_eq
  linear_combination (-(⨆ y : Icc a b, |f y - p.eval (y : ℝ)|)) * ((-1 : ℝ) ^ (i : ℕ) * (-1) ^ (i : ℕ)) * hs - (⨆ y : Icc a b, |f y - p.eval (y : ℝ)|) * ht

/-- De la Vallée Poussin's lower bound: let f be continuous on [a, b] and p a polynomial of
degree at most n. If the error f - p alternates in sign at n + 2 points x₀ < ... < x_{n+1}
of [a, b], each time with size at least m, then every polynomial q of degree at most n has
worst error at least m on [a, b], so E_n(f) ≥ m. -/
theorem de_la_vallee_poussin_lower_bound (a b : ℝ) (f : ℝ → ℝ) (hf : ContinuousOn f (Icc a b))
    (n : ℕ) (p : ℝ[X]) (hp : p.natDegree ≤ n)
    (x : Fin (n + 2) → ℝ) (hx : StrictMono x) (hxI : ∀ i, x i ∈ Icc a b)
    (σ : ℝ) (hσ : σ = 1 ∨ σ = -1) (m : ℝ)
    (halt : ∀ i : Fin (n + 2), m ≤ σ * (-1) ^ (i : ℕ) * (f (x i) - p.eval (x i))) :
    ∀ q : ℝ[X], q.natDegree ≤ n → m ≤ ⨆ y : Icc a b, |f y - q.eval (y : ℝ)| := by
  exact dlvp_core a b f hf n p hp x hx hxI σ hσ m halt

/-- The card's check of the third moment fact: B₁₀ applied to x² at x = 0.3 is
x² + x(1 - x)/n = 0.09 + 0.021 = 0.111. -/
example :
    ∑ k ∈ Finset.range 11, ((k : ℚ) / 10) ^ 2 * (bernsteinPolynomial ℚ 10 k).eval (3 / 10)
      = 111 / 1000 := by
  simp [Finset.sum_range_succ, bernsteinPolynomial, Nat.choose]
  norm_num

/-- The same value from the formula x² + x(1 - x)/n with x = 3/10, n = 10. -/
example : ((3 : ℚ) / 10) ^ 2 + (3 / 10) * (1 - 3 / 10) / 10 = 111 / 1000 := by norm_num

#print axioms alt_sign_poly_absurd
#print axioms dlvp_core
#print axioms weierstrass_approximation
#print axioms equioscillation_implies_minimax
#print axioms de_la_vallee_poussin_lower_bound
