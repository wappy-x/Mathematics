-- Monomial orders: with a ranking of monomials that respects multiplication and puts 1 last, division by a list of polynomials over a field always ends with a remainder that no divisor's leading term divides.
import Mathlib.Algebra.MvPolynomial.CommRing
import Mathlib.Algebra.MvPolynomial.Eval
import Mathlib.Algebra.Field.Basic
import Mathlib.Order.WellFounded
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.RingTheory.MvPolynomial.Groebner
import Mathlib.Data.Finsupp.PWO
import Mathlib.Order.OrderIsoNat

open MvPolynomial

/-! A monomial `x^α` in the variables `σ` is its exponent list `α : σ →₀ ℕ`; multiplying
monomials adds exponent lists, `1` is the list `0`, and `x^β` divides `x^α` exactly when
`β ≤ α` (exponent by exponent). A ranking of monomials is a relation `lt`, where `lt β α`
means `x^β` ranks below `x^α`. -/

/-- `d` is the leading monomial of `p` for the ranking `lt`: a monomial of `p` that ranks above
every other monomial of `p`. Its term `coeff d p * x^d` is the leading term `LT(p)`. -/
def IsLeadingMonomial {σ k : Type*} [CommSemiring k] (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop)
    (p : MvPolynomial σ k) (d : σ →₀ ℕ) : Prop :=
  d ∈ p.support ∧ ∀ e ∈ p.support, e ≠ d → lt e d

/-- A monomial never ranks below a monomial that divides it. -/
theorem helper_not_lt_of_le {σ : Type*}
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) {α β : σ →₀ ℕ} (h : β ≤ α) : ¬ lt α β := by
  intro hab
  obtain ⟨γ, rfl⟩ : ∃ γ, α = β + γ := ⟨α - β, (add_tsub_cancel_of_le h).symm⟩
  by_cases hγ : γ = 0
  · subst hγ
    rw [add_zero] at hab
    exact irrefl _ hab
  · have h1 := mul_keeps γ 0 β (one_last γ hγ)
    rw [zero_add, add_comm] at h1
    exact asymm hab h1

/-- Dickson's lemma turns the three rules into well-foundedness. -/
theorem helper_wf {σ : Type*} [Finite σ]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) :
    WellFounded lt := by
  rw [RelEmbedding.wellFounded_iff_isEmpty]
  refine ⟨fun f => ?_⟩
  obtain ⟨m, n, hmn, hle⟩ := wellQuasiOrdered_le (fun k => f k)
  exact helper_not_lt_of_le lt mul_keeps one_last hle (f.map_rel_iff.2 hmn)

/-- The monomials, renamed so that they carry the ranking `lt` as their order. -/
def LtSyn {σ : Type*} (_lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) : Type _ := σ →₀ ℕ

noncomputable instance {σ : Type*} (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) :
    AddCommMonoid (LtSyn lt) := inferInstanceAs (AddCommMonoid (σ →₀ ℕ))

noncomputable instance {σ : Type*} (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop)
    [IsStrictTotalOrder (σ →₀ ℕ) lt] : LinearOrder (LtSyn lt) :=
  @linearOrderOfSTO (σ →₀ ℕ) lt _ (Classical.decRel _)

theorem helper_wf_syn {σ : Type*} [Finite σ]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) : WellFoundedLT (LtSyn lt) := by
  have e : (fun x y : LtSyn lt => x < y) = lt := rfl
  unfold WellFoundedLT
  rw [e]
  exact helper_wf lt mul_keeps one_last

/-- The ranking packaged as a Mathlib monomial order. -/
noncomputable def toMonomialOrder {σ : Type*} [Finite σ]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) : MonomialOrder σ :=
  { syn := LtSyn lt
    toSyn := { Equiv.refl _ with map_add' := fun _ _ => rfl }
    isOrderedAddMonoid_syn :=
      { add_le_add_left := fun a b h c => by
          rcases h with h | h
          · exact Or.inl (by rw [h])
          · exact Or.inr (mul_keeps b a c h) }
    toSyn_monotone := fun a b h => by
      rcases trichotomous_of lt a b with h' | h' | h'
      · exact Or.inr h'
      · exact Or.inl h'
      · exact absurd h' (helper_not_lt_of_le lt mul_keeps one_last h)
    wellFoundedLT_syn := helper_wf_syn lt mul_keeps one_last }

theorem helper_toSyn_lt {σ : Type*} [Finite σ]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) (a b : σ →₀ ℕ) :
    (toMonomialOrder lt mul_keeps one_last).toSyn a < (toMonomialOrder lt mul_keeps one_last).toSyn b
      ↔ lt a b := Iff.rfl

theorem helper_degree_eq {σ k : Type*} [Finite σ] [Field k]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) {p : MvPolynomial σ k} {d : σ →₀ ℕ}
    (hd : IsLeadingMonomial lt p d) : (toMonomialOrder lt mul_keeps one_last).degree p = d := by
  set m := toMonomialOrder lt mul_keeps one_last
  have hp : p ≠ 0 := by
    rintro rfl
    have h0 := hd.1
    simp at h0
  by_contra hne
  have h1 := hd.2 _ (m.degree_mem_support hp) hne
  have h2 := m.le_degree (f := p) hd.1
  exact absurd ((helper_toSyn_lt lt mul_keeps one_last _ _).2 h1) (not_lt.2 h2)

/-- Division by a list. Take finitely many variables, a field `k`, and a monomial order: a ranking
of all monomials in which (1) of two different monomials one is bigger, (2) multiplying both by
the same monomial keeps the winner, and (3) `1` ranks below every other monomial. Then any
polynomial `f` divided by any list `f_1, ..., f_s` gives quotients `a_1, ..., a_s` and a remainder
`r` with `f = a_1 f_1 + ... + a_s f_s + r`, where no term of `r` is divisible by the leading term
of any `f_i`. -/
theorem division_by_list_has_remainder {σ k : Type*} [Fintype σ] [Field k]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α)
    {s : ℕ} (fs : Fin s → MvPolynomial σ k) (f : MvPolynomial σ k) :
    ∃ (a : Fin s → MvPolynomial σ k) (r : MvPolynomial σ k),
      f = (∑ i, a i * fs i) + r ∧
      ∀ c ∈ r.support, ∀ i, ∀ d, IsLeadingMonomial lt (fs i) d → ¬ d ≤ c := by
  classical
  set m := toMonomialOrder lt mul_keeps one_last
  obtain ⟨g, r, hf, -, hr⟩ := m.div (b := fun i : {i : Fin s // fs i ≠ 0} => fs i)
    (fun i => (m.leadingCoeff_ne_zero_iff.2 i.2).isUnit) f
  refine ⟨fun i => if h : fs i ≠ 0 then g ⟨i, h⟩ else 0, r, ?_, ?_⟩
  · rw [hf, Finsupp.linearCombination_apply, Finsupp.sum_fintype _ _ (by simp)]
    congr 1
    rw [← Finset.sum_filter_of_ne (p := fun i => fs i ≠ 0) (s := Finset.univ)
      (fun i _ h hi => h (by rw [hi, mul_zero]))]
    rw [Finset.sum_subtype (p := fun i => fs i ≠ 0) _ (by simp)]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp [i.2, smul_eq_mul, mul_comm]
  · intro c hc i d hd
    have hne : fs i ≠ 0 := by
      rintro h
      have h0 := hd.1
      rw [h] at h0
      simp at h0
    have := hr c hc ⟨i, hne⟩
    rwa [helper_degree_eq lt mul_keeps one_last hd] at this

/-- Division stops. In finitely many variables, a ranking that obeys rules (1), (2) and (3) has
no endless falling chain of monomials: every nonempty set of monomials has a lowest one. Each
division step lowers the leading monomial, so division always ends. -/
theorem monomial_order_no_endless_fall {σ : Type*} [Fintype σ]
    (lt : (σ →₀ ℕ) → (σ →₀ ℕ) → Prop) [IsStrictTotalOrder (σ →₀ ℕ) lt]
    (mul_keeps : ∀ α β γ : σ →₀ ℕ, lt β α → lt (β + γ) (α + γ))
    (one_last : ∀ α : σ →₀ ℕ, α ≠ 0 → lt 0 α) :
    WellFounded lt := by
  exact helper_wf lt mul_keeps one_last

/-- The remainder is a correct rewrite. If `f = a_1 f_1 + ... + a_s f_s + r`, then `f` and `r`
take the same value at every point where all the divisors `f_i` are zero. -/
theorem remainder_agrees_on_common_zeros {σ k : Type*} [Field k] {s : ℕ}
    (fs : Fin s → MvPolynomial σ k) (a : Fin s → MvPolynomial σ k) (f r : MvPolynomial σ k)
    (hdiv : f = (∑ i, a i * fs i) + r) (pt : σ → k) (hzero : ∀ i, eval pt (fs i) = 0) :
    eval pt f = eval pt r := by
  simp [hdiv, hzero]

/-! The card's worked examples, with `x = X 0` and `y = X 1` in `ℚ[x, y]`. -/

-- The desk's formula: x²y + x = x · (xy − 1) + 2x.
example : (X 0 ^ 2 * X 1 + X 0 : MvPolynomial (Fin 2) ℚ) = X 0 * (X 0 * X 1 - 1) + 2 * X 0 := by
  ring

-- At today's rates x = 4/5, y = 5/4 (so xy = 1), the formula and its remainder 2x are both 8/5.
example : ((4 : ℚ) / 5) * (5 / 4) = 1 ∧ ((4 : ℚ) / 5) ^ 2 * (5 / 4) + 4 / 5 = 8 / 5 ∧
    2 * ((4 : ℚ) / 5) = 8 / 5 := by
  norm_num

-- x²y + xy² + y² by (xy − 1, y² − 1) in lex: quotients x + y and 1, remainder x + y + 1.
example : (X 0 ^ 2 * X 1 + X 0 * X 1 ^ 2 + X 1 ^ 2 : MvPolynomial (Fin 2) ℚ) =
    (X 0 + X 1) * (X 0 * X 1 - 1) + 1 * (X 1 ^ 2 - 1) + (X 0 + X 1 + 1) := by
  ring

-- The same f by (y² − 1, xy − 1) in lex: quotients x + 1 and x, remainder 2x + 1.
example : (X 0 ^ 2 * X 1 + X 0 * X 1 ^ 2 + X 1 ^ 2 : MvPolynomial (Fin 2) ℚ) =
    (X 0 + 1) * (X 1 ^ 2 - 1) + X 0 * (X 0 * X 1 - 1) + (2 * X 0 + 1) := by
  ring

-- The two remainders differ by −x + y = x(y² − 1) − y(xy − 1).
example : ((X 0 + X 1 + 1) - (2 * X 0 + 1) : MvPolynomial (Fin 2) ℚ) =
    X 0 * (X 1 ^ 2 - 1) - X 1 * (X 0 * X 1 - 1) := by
  ring

-- At the common zeros (1, 1) and (−1, −1), f and x + y + 1 are 3 and −1, and so is 2x + 1.
example : (1 : ℤ) ^ 2 * 1 + 1 * 1 ^ 2 + 1 ^ 2 = 3 ∧ (1 : ℤ) + 1 + 1 = 3 ∧ 2 * (1 : ℤ) + 1 = 3 ∧
    (-1 : ℤ) ^ 2 * (-1) + (-1) * (-1) ^ 2 + (-1) ^ 2 = -1 ∧ (-1 : ℤ) + (-1) + 1 = -1 ∧
    2 * (-1 : ℤ) + 1 = -1 := by
  decide

-- x² by x − y² in lex leaves y⁴: x² = (x + y²)(x − y²) + y⁴; at x = 9, y = 3 both are 81.
example : (X 0 ^ 2 : MvPolynomial (Fin 2) ℚ) = (X 0 + X 1 ^ 2) * (X 0 - X 1 ^ 2) + X 1 ^ 4 := by
  ring

example : (9 : ℕ) ^ 2 = 81 ∧ (3 : ℕ) ^ 4 = 81 := by decide

-- With 1 ranked highest, 10 steps of 1 by 1 − x leave x¹⁰: 1 = (1 + x + ... + x⁹)(1 − x) + x¹⁰.
example : (1 : MvPolynomial (Fin 2) ℚ) =
    (∑ j ∈ Finset.range 10, X 0 ^ j) * (1 - X 0) + X 0 ^ 10 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  ring

#print axioms helper_not_lt_of_le
#print axioms helper_wf
#print axioms helper_wf_syn
#print axioms helper_toSyn_lt
#print axioms helper_degree_eq
#print axioms division_by_list_has_remainder
#print axioms monomial_order_no_endless_fall
#print axioms remainder_agrees_on_common_zeros
