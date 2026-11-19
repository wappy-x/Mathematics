-- Grobner bases: a list is a Grobner basis exactly when every S-polynomial of two members divides by the list with remainder zero, and then remainders are unique and decide ideal membership.
import Mathlib.RingTheory.MvPolynomial.MonomialOrder
import Mathlib.RingTheory.MvPolynomial.Groebner
import Mathlib.Algebra.MvPolynomial.Division
import Mathlib.RingTheory.Ideal.Span
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open MvPolynomial
open scoped MonomialOrder

/-- Helper: the leading term of a nonzero p divides any monomial of degree at least deg p. -/
theorem gb_lt_dvd_monomial_of_le {σ k : Type*} [Field k] (m : MonomialOrder σ)
    {p : MvPolynomial σ k} (hp : p ≠ 0) {d : σ →₀ ℕ} (hd : m.degree p ≤ d) (a : k) :
    m.leadingTerm p ∣ monomial d a := by
  rw [MonomialOrder.leadingTerm, monomial_dvd_monomial]
  exact ⟨Or.inr hd, (isUnit_iff_ne_zero.mpr (m.leadingCoeff_ne_zero_iff.mpr hp)).dvd⟩

/-- Helper: if LT(p) divides a monomial with nonzero coefficient, then p ≠ 0 and its degree is
below the monomial's exponent. -/
theorem gb_le_of_lt_dvd_monomial {σ k : Type*} [Field k] (m : MonomialOrder σ)
    {p : MvPolynomial σ k} {d : σ →₀ ℕ} {a : k} (ha : a ≠ 0)
    (h : m.leadingTerm p ∣ monomial d a) : p ≠ 0 ∧ m.degree p ≤ d := by
  rw [MonomialOrder.leadingTerm, monomial_dvd_monomial] at h
  obtain ⟨h1, h2⟩ := h
  refine ⟨?_, h1.resolve_left ha⟩
  rintro rfl
  rw [MonomialOrder.leadingCoeff_zero, zero_dvd_iff] at h2
  exact ha h2

/-- Helper: under the Grobner property, an ideal member with no term divisible by any LT(g i)
is zero. -/
theorem gb_eq_zero_of_mem {σ k : Type*} [Field k] (m : MonomialOrder σ) {t : ℕ}
    (g : Fin t → MvPolynomial σ k)
    (hG : ∀ h ∈ Ideal.span (Set.range g), h ≠ 0 → ∃ i, m.leadingTerm (g i) ∣ m.leadingTerm h)
    (r : MvPolynomial σ k) (hrI : r ∈ Ideal.span (Set.range g))
    (hr : ∀ c ∈ r.support, ∀ i, ¬ m.leadingTerm (g i) ∣ monomial c (r.coeff c)) : r = 0 := by
  by_contra h0
  obtain ⟨i, hi⟩ := hG r hrI h0
  exact hr _ (m.degree_mem_support h0) i hi

/-- Helper: the main induction of Buchberger's criterion. If every S-polynomial has a standard
representation, then any representation h = sum c_l g_l with all parts of order at most δ
can be pushed down until the leading term of h is visibly divisible by some LT(g i). -/
theorem gb_main {σ k : Type*} [Field k] (m : MonomialOrder σ) {t : ℕ}
    (g : Fin t → MvPolynomial σ k)
    (hS : ∀ i j, ∃ q : Fin t → MvPolynomial σ k,
        m.sPolynomial (g i) (g j) = ∑ l, q l * g l ∧
          ∀ l, m.degree (q l * g l) ≼[m] m.degree (m.sPolynomial (g i) (g j)))
    (h : MvPolynomial σ k) (hh : h ≠ 0) :
    ∀ δ : m.syn, ∀ c : Fin t → MvPolynomial σ k, h = ∑ l, c l * g l →
      (∀ l, m.toSyn (m.degree (c l * g l)) ≤ δ) →
        ∃ i, m.leadingTerm (g i) ∣ m.leadingTerm h := by
  classical
  have hQ : ∀ a b, ∃ Q : Fin t → MvPolynomial σ k,
      m.sPolynomial (g a) (g b) = ∑ l, Q l * g l ∧
      ∀ l, Q l = 0 ∨
        m.toSyn (m.degree (Q l * g l)) < m.toSyn (m.degree (g a) ⊔ m.degree (g b)) := by
    intro a b
    by_cases hs : m.sPolynomial (g a) (g b) = 0
    · exact ⟨0, by simp [hs], fun l => Or.inl rfl⟩
    · obtain ⟨Q, hQ1, hQ2⟩ := hS a b
      exact ⟨Q, hQ1, fun l =>
        Or.inr (lt_of_le_of_lt (hQ2 l) (m.degree_sPolynomial_lt_sup_degree hs))⟩
  choose Q hQsum hQdeg using hQ
  intro δ
  induction δ using WellFoundedLT.induction with
  | _ δ ih =>
  intro c hc hδ
  by_cases hEq : m.toSyn (m.degree h) = δ
  · have hcoef : h.coeff (m.degree h) ≠ 0 := m.coeff_degree_ne_zero_iff.mpr hh
    have hsum : ∑ l, (c l * g l).coeff (m.degree h) ≠ 0 := by
      rw [← coeff_sum, ← hc]; exact hcoef
    obtain ⟨l, -, hl⟩ := Finset.exists_ne_zero_of_sum_ne_zero hsum
    have hle1 := m.le_degree (mem_support_iff.mpr hl)
    have hdeg : m.degree (c l * g l) = m.degree h := by
      apply m.toSyn.injective
      exact le_antisymm (hEq ▸ hδ l) hle1
    have hne : c l * g l ≠ 0 := by
      intro h0; rw [h0] at hl; simp at hl
    have hcl : c l ≠ 0 := left_ne_zero_of_mul hne
    have hgl : g l ≠ 0 := right_ne_zero_of_mul hne
    rw [m.degree_mul hcl hgl] at hdeg
    refine ⟨l, ?_⟩
    show _ ∣ monomial (m.degree h) (m.leadingCoeff h)
    exact gb_lt_dvd_monomial_of_le m hgl (hdeg ▸ le_add_self) _
  · have hle : m.toSyn (m.degree h) ≤ δ := by
      have : m.toSyn (m.degree (∑ l, c l * g l)) ≤ δ :=
        le_trans m.degree_sum_le (Finset.sup_le fun l _ => hδ l)
      rwa [← hc] at this
    have hδh : m.toSyn (m.degree h) < δ := lt_of_le_of_ne hle hEq
    have hbot : (⊥ : m.syn) < δ := lt_of_le_of_lt bot_le hδh
    have hzero : m.toSyn (m.degree (0 : MvPolynomial σ k)) < δ := by
      rw [MonomialOrder.degree_zero, map_zero, ← MonomialOrder.bot_eq_zero]; exact hbot
    obtain ⟨coef, hcoef⟩ : ∃ coef : Fin t → k, ∀ l, coef l =
        if m.toSyn (m.degree (c l * g l)) = δ then m.leadingCoeff (c l) else 0 :=
      ⟨_, fun _ => rfl⟩
    obtain ⟨a, ha⟩ : ∃ a : Fin t → MvPolynomial σ k, ∀ l,
        a l = monomial (m.degree (c l)) (coef l) := ⟨_, fun _ => rfl⟩
    obtain ⟨p, hp⟩ : ∃ p : Fin t → MvPolynomial σ k, ∀ l, p l = a l * g l := ⟨_, fun _ => rfl⟩
    obtain ⟨r, hr⟩ : ∃ r : Fin t → MvPolynomial σ k, ∀ l, r l = c l - a l := ⟨_, fun _ => rfl⟩
    have F1 : ∀ l, m.toSyn (m.degree (c l * g l)) = δ →
        c l ≠ 0 ∧ g l ≠ 0 ∧ a l = m.leadingTerm (c l) ∧
          m.degree (p l) = m.degree (c l) + m.degree (g l) ∧ m.toSyn (m.degree (p l)) = δ := by
      intro l hl
      have hne : c l * g l ≠ 0 := by
        intro h0; rw [h0] at hl; rw [← hl] at hzero; exact lt_irrefl _ hzero
      have hcl : c l ≠ 0 := left_ne_zero_of_mul hne
      have hgl : g l ≠ 0 := right_ne_zero_of_mul hne
      have hal : a l = m.leadingTerm (c l) := by
        rw [ha, hcoef]; simp only [hl, ↓reduceIte, MonomialOrder.leadingTerm]
      have hpd : m.degree (p l) = m.degree (c l * g l) := by
        rw [hp, hal, MonomialOrder.degree_leadingTerm_mul]
      refine ⟨hcl, hgl, hal, ?_, ?_⟩
      · rw [hpd, m.degree_mul hcl hgl]
      · rw [hpd, hl]
    have hcoef0 : ∀ l, ¬ m.toSyn (m.degree (c l * g l)) = δ → coef l = 0 := by
      intro l hl; rw [hcoef]; simp only [hl, ↓reduceIte]
    have ha0 : ∀ l, ¬ m.toSyn (m.degree (c l * g l)) = δ → a l = 0 := by
      intro l hl; rw [ha, hcoef0 l hl, monomial_zero]
    have F1' : ∀ l, ¬ m.toSyn (m.degree (c l * g l)) = δ → p l = 0 := by
      intro l hl
      rw [hp, ha0 l hl, zero_mul]
    have F2 : ∀ l, m.toSyn (m.degree (r l * g l)) < δ := by
      intro l
      by_cases hl : m.toSyn (m.degree (c l * g l)) = δ
      · obtain ⟨hcl, hgl, hal, -, -⟩ := F1 l hl
        have hrl : r l = c l - m.leadingTerm (c l) := by rw [hr, hal]
        by_cases hr0 : r l = 0
        · rw [hr0, zero_mul]; exact hzero
        · rw [hrl] at hr0 ⊢
          have hd0 := m.degree_ne_zero_of_sub_leadingTerm_ne_zero hr0
          have hlt := m.degree_sub_leadingTerm_lt_degree hd0
          rw [← m.degree_mul_lt_iff_left_lt_of_ne_zero hr0 hgl] at hlt
          rw [← hl]; exact hlt
      · have hrl : r l = c l := by rw [hr, ha0 l hl, sub_zero]
        rw [hrl]; exact lt_of_le_of_ne (hδ l) hl
    have hdecomp : ∑ l, p l = h - ∑ l, r l * g l := by
      rw [hc, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun l _ => ?_
      rw [hp, hr]; ring
    have F3 : m.toSyn (m.degree (∑ l ∈ Finset.univ, p l)) < δ := by
      rw [hdecomp]
      refine lt_of_le_of_lt m.degree_sub_le (max_lt hδh ?_)
      exact lt_of_le_of_lt m.degree_sum_le ((Finset.sup_lt_iff hbot).mpr fun l _ => F2 l)
    obtain ⟨κ, hκ⟩ := m.sPolynomial_decomposition' (B := Finset.univ) p (fun l _ => by
      by_cases hl : m.toSyn (m.degree (c l * g l)) = δ
      · exact Or.inl (F1 l hl).2.2.2.2
      · exact Or.inr (F1' l hl)) F3
    obtain ⟨E, hE⟩ : ∃ E : Fin t → Fin t → (σ →₀ ℕ), ∀ a' b', E a' b' =
        m.degree (p a') ⊔ m.degree (p b') - m.degree (g a') ⊔ m.degree (g b') :=
      ⟨_, fun _ _ => rfl⟩
    obtain ⟨μ, hμ⟩ : ∃ μ : Fin t → Fin t → MvPolynomial σ k, ∀ a' b', μ a' b' =
        monomial (E a' b') (coef a' * coef b') := ⟨_, fun _ _ => rfl⟩
    have F4 : ∀ a' b', m.sPolynomial (p a') (p b') = μ a' b' * m.sPolynomial (g a') (g b') := by
      intro a' b'
      rw [hμ, hE, hp a', hp b', ha a', ha b']
      exact m.sPolynomial_monomial_mul' _ _ _ _ _ _
    obtain ⟨c', hc'⟩ : ∃ c' : Fin t → MvPolynomial σ k, ∀ l, c' l =
        r l + ∑ a', ∑ b', C (κ a' b') * μ a' b' * Q a' b' l := ⟨_, fun _ => rfl⟩
    have hsum' : h = ∑ l, c' l * g l := by
      have e1 : ∑ l, c' l * g l = ∑ l, r l * g l +
          ∑ a', ∑ b', C (κ a' b') * μ a' b' * ∑ l, Q a' b' l * g l := by
        have s1 : ∀ l, c' l * g l = r l * g l +
            ∑ a', ∑ b', C (κ a' b') * μ a' b' * (Q a' b' l * g l) := by
          intro l
          rw [hc', add_mul, Finset.sum_mul]
          refine congrArg (fun x => r l * g l + x) (Finset.sum_congr rfl fun a' _ => ?_)
          rw [Finset.sum_mul]
          refine Finset.sum_congr rfl fun b' _ => ?_
          rw [mul_assoc]
        have s2 : ∑ l, ∑ a', ∑ b', C (κ a' b') * μ a' b' * (Q a' b' l * g l) =
            ∑ a', ∑ b', C (κ a' b') * μ a' b' * ∑ l, Q a' b' l * g l := by
          rw [Finset.sum_comm]
          refine Finset.sum_congr rfl fun a' _ => ?_
          rw [Finset.sum_comm]
          refine Finset.sum_congr rfl fun b' _ => ?_
          rw [Finset.mul_sum]
        rw [Finset.sum_congr rfl fun l _ => s1 l, Finset.sum_add_distrib, s2]
      have e2 : ∑ a', ∑ b', C (κ a' b') * μ a' b' * ∑ l, Q a' b' l * g l = ∑ l, p l := by
        rw [hκ]
        refine Finset.sum_congr rfl fun a' _ => Finset.sum_congr rfl fun b' _ => ?_
        rw [← hQsum, F4, smul_eq_C_mul, mul_assoc]
      rw [e1, e2, hdecomp, add_sub_cancel]
    have F5 : ∀ l, m.toSyn (m.degree (c' l * g l)) < δ := by
      intro l
      have e : c' l * g l = r l * g l +
          ∑ a', ∑ b', (C (κ a' b') * μ a' b') * (Q a' b' l * g l) := by
        rw [hc', add_mul, Finset.sum_mul]
        refine congrArg (fun x => r l * g l + x) (Finset.sum_congr rfl fun a' _ => ?_)
        rw [Finset.sum_mul]
        refine Finset.sum_congr rfl fun b' _ => ?_
        rw [mul_assoc]
      rw [e]
      refine lt_of_le_of_lt m.degree_add_le (max_lt (F2 l) ?_)
      refine lt_of_le_of_lt m.degree_sum_le ((Finset.sup_lt_iff hbot).mpr fun a' _ => ?_)
      refine lt_of_le_of_lt m.degree_sum_le ((Finset.sup_lt_iff hbot).mpr fun b' _ => ?_)
      by_cases hQ0 : Q a' b' l = 0
      · rw [hQ0, zero_mul, mul_zero]; exact hzero
      by_cases hca : m.toSyn (m.degree (c a' * g a')) = δ
      swap
      · rw [hμ, hcoef0 a' hca, zero_mul, monomial_zero, mul_zero, zero_mul]; exact hzero
      by_cases hcb : m.toSyn (m.degree (c b' * g b')) = δ
      swap
      · rw [hμ, hcoef0 b' hcb, mul_zero, monomial_zero, mul_zero, zero_mul]; exact hzero
      have hQlt := (hQdeg a' b' l).resolve_left hQ0
      obtain ⟨-, -, -, hpa, hpaδ⟩ := F1 a' hca
      obtain ⟨-, -, -, hpb, hpbδ⟩ := F1 b' hcb
      have hpab : m.degree (p a') = m.degree (p b') :=
        m.toSyn.injective (hpaδ.trans hpbδ.symm)
      have hsup : m.degree (g a') ⊔ m.degree (g b') ≤ m.degree (p a') ⊔ m.degree (p b') := by
        apply sup_le_sup
        · rw [hpa]; exact le_add_self
        · rw [hpb]; exact le_add_self
      have hμdeg : m.toSyn (m.degree (C (κ a' b') * μ a' b')) ≤ m.toSyn (E a' b') := by
        rw [hμ, C_mul_monomial]
        exact m.degree_monomial_le _
      calc m.toSyn (m.degree (C (κ a' b') * μ a' b' * (Q a' b' l * g l)))
          ≤ m.toSyn (m.degree (C (κ a' b') * μ a' b')) +
              m.toSyn (m.degree (Q a' b' l * g l)) := m.toSyn_degree_mul_le
        _ < m.toSyn (E a' b') + m.toSyn (m.degree (g a') ⊔ m.degree (g b')) :=
            add_lt_add_of_le_of_lt hμdeg hQlt
        _ = m.toSyn (m.degree (p a') ⊔ m.degree (p b')) := by
            rw [← map_add, hE, tsub_add_cancel_of_le hsup]
        _ = δ := by rw [← hpab, sup_idem, hpaδ]
    have hlt : (Finset.univ.sup fun l => m.toSyn (m.degree (c' l * g l))) < δ :=
      (Finset.sup_lt_iff hbot).mpr fun l _ => F5 l
    have hle' : ∀ l, m.toSyn (m.degree (c' l * g l)) ≤
        Finset.univ.sup fun l => m.toSyn (m.degree (c' l * g l)) := fun l =>
      Finset.le_sup (f := fun l => m.toSyn (m.degree (c' l * g l))) (Finset.mem_univ l)
    exact ih _ hlt c' hsum' hle'

/-- Buchberger's criterion. Over a field k, with one monomial order m fixed throughout, a finite
list g_1, ..., g_t is a Grobner basis of the ideal it generates (every nonzero h in the ideal has a
leading term divisible by the leading term of some g_i) exactly when, for every pair i, j, the
S-polynomial S(g_i, g_j) divides by the list with remainder zero: it equals a combination
q_1 g_1 + ... + q_t g_t in which no part q_l g_l leads above S(g_i, g_j), which is what division
with remainder 0 produces. Mathlib's `sPolynomial` is the card's S(f, g) multiplied by the nonzero
constant LC(f) LC(g), which does not change whether the remainder is zero. -/
theorem buchberger_criterion {σ k : Type*} [Field k] (m : MonomialOrder σ) {t : ℕ}
    (g : Fin t → MvPolynomial σ k) :
    (∀ h ∈ Ideal.span (Set.range g), h ≠ 0 → ∃ i, m.leadingTerm (g i) ∣ m.leadingTerm h) ↔
      ∀ i j, ∃ q : Fin t → MvPolynomial σ k,
        m.sPolynomial (g i) (g j) = ∑ l, q l * g l ∧
          ∀ l, m.degree (q l * g l) ≼[m] m.degree (m.sPolynomial (g i) (g j)) := by
  classical
  constructor
  · intro hG i j
    set S := m.sPolynomial (g i) (g j) with hS_def
    have hSmem : S ∈ Ideal.span (Set.range g) := by
      rw [hS_def, MonomialOrder.sPolynomial]
      apply Ideal.sub_mem <;> apply Ideal.mul_mem_left <;> exact Ideal.subset_span ⟨_, rfl⟩
    let b : {l : Fin t // g l ≠ 0} → MvPolynomial σ k := fun l => g l
    have hb : ∀ l, IsUnit (m.leadingCoeff (b l)) := fun l => m.isUnit_leadingCoeff.mpr l.2
    obtain ⟨G, r, hSG, hdeg, hr⟩ := m.div hb S
    set G' : Fin t → MvPolynomial σ k := fun l => if h : g l ≠ 0 then G ⟨l, h⟩ else 0
      with hG'_def
    have hlc : Finsupp.linearCombination (MvPolynomial σ k) b G = ∑ l, G' l * g l := by
      rw [Finsupp.linearCombination_apply, Finsupp.sum_fintype _ _ (by simp)]
      have e1 : ∀ x : {l : Fin t // g l ≠ 0}, G x • b x = G' x.1 * g x.1 := by
        intro x
        simp only [hG'_def, x.2, ne_eq, not_false_eq_true, dite_true, smul_eq_mul, b]
      simp only [e1]
      rw [← Finset.sum_subtype (Finset.univ.filter fun l => g l ≠ 0) (by simp)
        (fun l => G' l * g l)]
      apply Finset.sum_filter_of_ne
      intro l _ hl h0
      exact hl (by rw [h0, mul_zero])
    have hr0 : r = 0 := by
      by_contra h0
      have hrI : r ∈ Ideal.span (Set.range g) := by
        have : r = S - Finsupp.linearCombination (MvPolynomial σ k) b G := by
          rw [hSG]; ring
        rw [this, hlc]
        exact Ideal.sub_mem _ hSmem (Ideal.mem_span_range_iff_exists_fun.mpr ⟨_, rfl⟩)
      obtain ⟨l, hl⟩ := hG r hrI h0
      have hc := m.coeff_degree_ne_zero_iff.mpr h0
      obtain ⟨hgl, hle⟩ := gb_le_of_lt_dvd_monomial m hc hl
      exact hr _ (m.degree_mem_support h0) ⟨l, hgl⟩ hle
    refine ⟨G', ?_, ?_⟩
    · rw [hr0, add_zero] at hSG
      rw [← hlc]; exact hSG
    · intro l
      by_cases h : g l ≠ 0
      · have e : G' l = G ⟨l, h⟩ := by simp only [hG'_def, h, ne_eq, not_false_eq_true, dite_true]
        rw [e, mul_comm]
        exact hdeg ⟨l, h⟩
      · push Not at h
        rw [h, mul_zero, MonomialOrder.degree_zero, map_zero]
        exact bot_le
  · intro hS h hmem hh
    obtain ⟨c, hc⟩ := Ideal.mem_span_range_iff_exists_fun.mp hmem
    exact gb_main m g hS h hh _ c hc.symm
      (fun l => Finset.le_sup (f := fun l => m.toSyn (m.degree (c l * g l))) (Finset.mem_univ l))

/-- Step 1: a Grobner basis gives one remainder. If g_1, ..., g_t is a Grobner basis of the ideal it
generates and f divides by the list in two ways, f = sum q_i g_i + r and f = sum q'_i g_i + r',
where no term of r or of r' is divisible by any leading term LT(g_i), then r = r'. -/
theorem remainder_unique_of_grobner {σ k : Type*} [Field k] (m : MonomialOrder σ) {t : ℕ}
    (g : Fin t → MvPolynomial σ k)
    (hG : ∀ h ∈ Ideal.span (Set.range g), h ≠ 0 → ∃ i, m.leadingTerm (g i) ∣ m.leadingTerm h)
    (f r r' : MvPolynomial σ k) (q q' : Fin t → MvPolynomial σ k)
    (hf : f = ∑ i, q i * g i + r) (hf' : f = ∑ i, q' i * g i + r')
    (hr : ∀ c ∈ r.support, ∀ i, ¬ m.leadingTerm (g i) ∣ monomial c (r.coeff c))
    (hr' : ∀ c ∈ r'.support, ∀ i, ¬ m.leadingTerm (g i) ∣ monomial c (r'.coeff c)) :
    r = r' := by
  classical
  by_contra hne
  have h0 : r - r' ≠ 0 := sub_ne_zero.mpr hne
  have hmem : r - r' ∈ Ideal.span (Set.range g) := by
    have : r - r' = ∑ i, q' i * g i - ∑ i, q i * g i := by
      have := hf.symm.trans hf'
      linear_combination this
    rw [this]
    exact Ideal.sub_mem _ (Ideal.mem_span_range_iff_exists_fun.mpr ⟨q', rfl⟩)
      (Ideal.mem_span_range_iff_exists_fun.mpr ⟨q, rfl⟩)
  obtain ⟨i, hi⟩ := hG _ hmem h0
  have hc : (r - r').coeff (m.degree (r - r')) ≠ 0 := m.coeff_degree_ne_zero_iff.mpr h0
  have hi' : m.leadingTerm (g i) ∣
      monomial (m.degree (r - r')) ((r - r').coeff (m.degree (r - r'))) := hi
  obtain ⟨hgi, hle⟩ := gb_le_of_lt_dvd_monomial m hc hi'
  rw [coeff_sub] at hc
  by_cases hrd : r.coeff (m.degree (r - r')) = 0
  · have h2 : r'.coeff (m.degree (r - r')) ≠ 0 := by
      rw [hrd, zero_sub, neg_ne_zero] at hc; exact hc
    exact hr' _ (mem_support_iff.mpr h2) i (gb_lt_dvd_monomial_of_le m hgi hle _)
  · exact hr _ (mem_support_iff.mpr hrd) i (gb_lt_dvd_monomial_of_le m hgi hle _)

/-- Step 1, membership: if g_1, ..., g_t is a Grobner basis of the ideal I it generates and
f = sum q_i g_i + r with no term of r divisible by any LT(g_i), then f is in I exactly when r = 0. -/
theorem mem_ideal_iff_remainder_eq_zero {σ k : Type*} [Field k] (m : MonomialOrder σ) {t : ℕ}
    (g : Fin t → MvPolynomial σ k)
    (hG : ∀ h ∈ Ideal.span (Set.range g), h ≠ 0 → ∃ i, m.leadingTerm (g i) ∣ m.leadingTerm h)
    (f r : MvPolynomial σ k) (q : Fin t → MvPolynomial σ k)
    (hf : f = ∑ i, q i * g i + r)
    (hr : ∀ c ∈ r.support, ∀ i, ¬ m.leadingTerm (g i) ∣ monomial c (r.coeff c)) :
    f ∈ Ideal.span (Set.range g) ↔ r = 0 := by
  have hsum : ∑ i, q i * g i ∈ Ideal.span (Set.range g) :=
    Ideal.mem_span_range_iff_exists_fun.mpr ⟨q, rfl⟩
  constructor
  · intro hf'
    apply gb_eq_zero_of_mem m g hG r _ hr
    have : r = f - ∑ i, q i * g i := by rw [hf]; ring
    rw [this]
    exact Ideal.sub_mem _ hf' hsum
  · rintro rfl
    rw [hf, add_zero]
    exact hsum

-- The robot arm over ℚ, with x = X 0 and y = X 1: the shoulder circle f1, the target circle f2,
-- and the two members Buchberger adds, f3 = 8x - 21 and f4 = 64y^2 - 135.
-- f3 = f1 - f2, the S-polynomial of the first pair.
example : (8 * X 0 - 21 : MvPolynomial (Fin 2) ℚ) =
    (X 0 ^ 2 + X 1 ^ 2 - 9) - (X 0 ^ 2 - 8 * X 0 + X 1 ^ 2 + 12) := by ring
-- The target circle (x - 4)^2 + y^2 - 4 written out.
example : ((X 0 - 4) ^ 2 + X 1 ^ 2 - 4 : MvPolynomial (Fin 2) ℚ) =
    X 0 ^ 2 - 8 * X 0 + X 1 ^ 2 + 12 := by ring
-- f4 = (43 - 8x) f1 + (8x + 21) f2, so f4 lies in the ideal.
example : (64 * X 1 ^ 2 - 135 : MvPolynomial (Fin 2) ℚ) =
    (43 - 8 * X 0) * (X 0 ^ 2 + X 1 ^ 2 - 9) + (8 * X 0 + 21) * (X 0 ^ 2 - 8 * X 0 + X 1 ^ 2 + 12) := by
  ring
-- S(f1, f3) cleared of fractions: 8 f1 - x f3 = 21x + 8y^2 - 72, which is 8 times
-- f1 - (1/8) x f3 = (21/8) x + y^2 - 9.
example : (8 * (X 0 ^ 2 + X 1 ^ 2 - 9) - X 0 * (8 * X 0 - 21) : MvPolynomial (Fin 2) ℚ) =
    21 * X 0 + 8 * X 1 ^ 2 - 72 := by ring
-- Dividing by f3 clears the x term and leaves f4 = 64y^2 - 135, the new member.
example : (8 * (21 * X 0 + 8 * X 1 ^ 2 - 72) - 21 * (8 * X 0 - 21) : MvPolynomial (Fin 2) ℚ) =
    64 * X 1 ^ 2 - 135 := by ring
-- Pair (f2, f3): 8 f2 - x f3 = -43x + 8y^2 + 96; clearing x with f3 leaves exactly f4, so once
-- f4 is in the list the remainder is 0.
example : (8 * (X 0 ^ 2 - 8 * X 0 + X 1 ^ 2 + 12) - X 0 * (8 * X 0 - 21) : MvPolynomial (Fin 2) ℚ) =
    -43 * X 0 + 8 * X 1 ^ 2 + 96 := by ring
example : (8 * (-43 * X 0 + 8 * X 1 ^ 2 + 96) + 43 * (8 * X 0 - 21) : MvPolynomial (Fin 2) ℚ) =
    64 * X 1 ^ 2 - 135 := by ring
-- The elbow (21/8, y) with y^2 = 135/64 lies on both circles.
example : (21 / 8 : ℚ) ^ 2 + 135 / 64 = 9 ∧ (21 / 8 - 4 : ℚ) ^ 2 + 135 / 64 = 4 := by norm_num
-- Law of cosines gives the same x: (9 + 16 - 4) / (2 * 4) = 21/8.
example : ((9 + 16 - 4) / (2 * 4) : ℚ) = 21 / 8 := by norm_num
-- The textbook pair: the gap x - y between the two remainders is y(xy - 1) - x(y^2 - 1).
example : (X 0 - X 1 : MvPolynomial (Fin 2) ℚ) =
    X 1 * (X 0 * X 1 - 1) - X 0 * (X 1 ^ 2 - 1) := by ring
example : ((X 0 + X 1 + 1) - (2 * X 0 + 1) : MvPolynomial (Fin 2) ℚ) = -(X 0 - X 1) := by ring
-- Target 6 m away: f1 - f2 = 12x - 41, so x = 41/12 and y^2 = 9 - (41/12)^2 = -385/144.
example : ((X 0 ^ 2 + X 1 ^ 2 - 9) - ((X 0 - 6) ^ 2 + X 1 ^ 2 - 4) : MvPolynomial (Fin 2) ℚ) =
    12 * X 0 - 41 := by ring
example : (9 : ℚ) - (41 / 12) ^ 2 = -385 / 144 := by norm_num
-- No real elbow: no real y has y^2 = -385/144.
example : ¬ ∃ y : ℝ, y ^ 2 = -385 / 144 := by
  rintro ⟨y, hy⟩
  nlinarith [sq_nonneg y]

#print axioms gb_lt_dvd_monomial_of_le
#print axioms gb_le_of_lt_dvd_monomial
#print axioms gb_eq_zero_of_mem
#print axioms gb_main
#print axioms buchberger_criterion
#print axioms remainder_unique_of_grobner
#print axioms mem_ideal_iff_remainder_eq_zero
