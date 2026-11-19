-- Elimination: the basis members of a lex Grobner basis that avoid the first ℓ variables form a Grobner basis of the ideal's ℓ-th elimination ideal, a partial solution extends back one variable over ℂ when some leading coefficient is nonzero there, and every point of the folium's cubic has a parameter.
import Mathlib.RingTheory.MvPolynomial.MonomialOrder
import Mathlib.Data.Finsupp.MonomialOrder
import Mathlib.Algebra.MvPolynomial.Supported
import Mathlib.Algebra.MvPolynomial.Equiv
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.MvPolynomial.Division
import Mathlib.RingTheory.MvPolynomial.Groebner
import Mathlib.RingTheory.Polynomial.Resultant.Basic
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination

open MvPolynomial
open scoped MonomialOrder

theorem elim_mem_supported_iff {k : Type*} [CommSemiring k] {n ℓ : ℕ}
    (p : MvPolynomial (Fin n) k) :
    p ∈ supported k {i : Fin n | ℓ ≤ (i : ℕ)} ↔
      ∀ d ∈ p.support, ∀ i : Fin n, (i : ℕ) < ℓ → d i = 0 := by
  classical
  rw [mem_supported]
  constructor
  · intro h d hd i hi
    by_contra hne
    have hv : i ∈ p.vars := (mem_vars_iff_mem_support i).2 ⟨d, hd, Finsupp.mem_support_iff.2 hne⟩
    have := h (Finset.mem_coe.2 hv)
    simp only [Set.mem_ofPred_eq] at this
    omega
  · intro h i hi
    obtain ⟨d, hd, hid⟩ := (mem_vars_iff_mem_support i).1 (Finset.mem_coe.1 hi)
    simp only [Set.mem_ofPred_eq]
    by_contra hlt
    rw [not_le] at hlt
    exact Finsupp.mem_support_iff.1 hid (h d hd i hlt)

#print axioms elim_mem_supported_iff

theorem elim_lex_zero_of_le {n ℓ : ℕ} {d e : Fin n →₀ ℕ} (h : d ≼[MonomialOrder.lex] e)
    (he : ∀ i : Fin n, (i : ℕ) < ℓ → e i = 0) : ∀ i : Fin n, (i : ℕ) < ℓ → d i = 0 := by
  rw [MonomialOrder.lex_le_iff] at h
  rcases h.lt_or_eq with h | h
  · rw [Finsupp.Lex.lt_iff] at h
    obtain ⟨j, hj, hlt⟩ := h
    intro i hi
    have hj' : ℓ ≤ (j : ℕ) := by
      by_contra hc
      rw [not_le] at hc
      have h0 := he j hc
      change d j < e j at hlt
      omega
    have hij : i < j := by rw [Fin.lt_def]; omega
    have := hj i hij
    change d i = e i at this
    rw [this]
    exact he i hi
  · have : d = e := toLex.injective h
    subst this
    exact he

#print axioms elim_lex_zero_of_le

theorem elim_aeval_fix {k : Type*} [CommSemiring k] {n ℓ : ℕ} :
    let φ : MvPolynomial (Fin n) k →ₐ[k] MvPolynomial (Fin n) k :=
      aeval (fun i : Fin n => if ℓ ≤ (i : ℕ) then X i else 0)
    (∀ p ∈ supported k {i : Fin n | ℓ ≤ (i : ℕ)}, φ p = p) ∧
      (∀ p, φ p ∈ supported k {i : Fin n | ℓ ≤ (i : ℕ)}) := by
  intro φ
  constructor
  · intro p hp
    have hle : supported k {i : Fin n | ℓ ≤ (i : ℕ)} ≤ AlgHom.equalizer φ (AlgHom.id k _) := by
      rw [supported_eq_adjoin_X]
      apply Algebra.adjoin_le
      rintro _ ⟨i, hi, rfl⟩
      simp only [Set.mem_ofPred_eq] at hi
      simp [φ, hi]
    exact hle hp
  · intro p
    have hle : (aeval (fun i : Fin n => if ℓ ≤ (i : ℕ) then (X i : MvPolynomial (Fin n) k)
        else 0)).range ≤ supported k {i : Fin n | ℓ ≤ (i : ℕ)} := by
      rw [← Algebra.adjoin_range_eq_range_aeval]
      apply Algebra.adjoin_le
      rintro _ ⟨i, rfl⟩
      by_cases hi : ℓ ≤ (i : ℕ)
      · simp only [hi, ite_true]
        rw [supported_eq_adjoin_X]
        exact Algebra.subset_adjoin ⟨i, hi, rfl⟩
      · simp only [hi, ite_false]
        exact Subalgebra.zero_mem _
    exact hle ⟨p, rfl⟩

#print axioms elim_aeval_fix

theorem ext_finSuccEquiv_rename_succ {n : ℕ} (r : MvPolynomial (Fin n) ℂ) :
    finSuccEquiv ℂ n (rename Fin.succ r) = Polynomial.C r := by
  induction r using MvPolynomial.induction_on with
  | C a =>
    rw [rename_C, finSuccEquiv_apply, eval₂Hom_C]
    rfl
  | add p q hp hq => rw [map_add, map_add, hp, hq, Polynomial.C_add]
  | mul_X p i hp => rw [map_mul, map_mul, hp, rename_X, finSuccEquiv_X_succ, Polynomial.C_mul]

#print axioms ext_finSuccEquiv_rename_succ

theorem ext_ideal_eq_top {s : ℕ} (g : Fin s → Polynomial ℂ)
    (H : ∀ z : ℂ, ∃ i, (g i).eval z ≠ 0) : (1 : Polynomial ℂ) ∈ Ideal.span (Set.range g) := by
  set J := Ideal.span (Set.range g)
  set h := Submodule.IsPrincipal.generator J
  have hJ : J = Ideal.span {h} := (Ideal.span_singleton_generator J).symm
  by_cases hdeg : h.degree = 0
  · have hu : IsUnit h := Polynomial.isUnit_iff_degree_eq_zero.2 hdeg
    rw [hJ, Ideal.span_singleton_eq_top.2 hu]
    exact Submodule.mem_top
  · obtain ⟨z, hz⟩ := IsAlgClosed.exists_root h hdeg
    obtain ⟨i, hi⟩ := H z
    exfalso
    apply hi
    have hgi : g i ∈ Ideal.span {h} := hJ ▸ Ideal.subset_span ⟨i, rfl⟩
    obtain ⟨c, hc⟩ := Ideal.mem_span_singleton.1 hgi
    rw [hc, Polynomial.eval_mul, hz.eq_zero, zero_mul]

#print axioms ext_ideal_eq_top

open Classical in
/-- The elimination theorem. Over any field k, with variables x_1 > x_2 > ... > x_n (here
`X 0 > X 1 > ... > X (n-1)`, which is Mathlib's lex order `MonomialOrder.lex` on `Fin n`), let G be
a Grobner basis of the ideal I for lex order: G lies in I, and the leading term of every nonzero
member of I is divisible by the leading term of some member of G. Then for every ℓ from 0 to n,
the members of G that avoid the first ℓ variables, G_ℓ = G ∩ k[x_{ℓ+1}, ..., x_n], form a Grobner
basis of the ℓ-th elimination ideal I_ℓ = I ∩ k[x_{ℓ+1}, ..., x_n]: they lie in I_ℓ, their leading
terms catch the leading term of every nonzero member of I_ℓ, and every member of I_ℓ is a
combination of them with multipliers in k[x_{ℓ+1}, ..., x_n]. -/
theorem elimination_theorem {k : Type*} [Field k] {n : ℕ} (I : Ideal (MvPolynomial (Fin n) k))
    (G : Finset (MvPolynomial (Fin n) k))
    (hGI : ∀ g ∈ G, g ∈ I)
    (hG : ∀ f ∈ I, f ≠ 0 →
      ∃ g ∈ G, MonomialOrder.lex.leadingTerm g ∣ MonomialOrder.lex.leadingTerm f)
    (ℓ : ℕ) (hℓ : ℓ ≤ n) :
    let A := supported k {i : Fin n | ℓ ≤ (i : ℕ)}
    let Gℓ := G.filter (· ∈ A)
    (∀ g ∈ Gℓ, g ∈ I ∧ g ∈ A) ∧
    (∀ f ∈ I, f ∈ A → f ≠ 0 →
      ∃ g ∈ Gℓ, MonomialOrder.lex.leadingTerm g ∣ MonomialOrder.lex.leadingTerm f) ∧
    (∀ f ∈ I, f ∈ A →
      ∃ h : MvPolynomial (Fin n) k → MvPolynomial (Fin n) k,
        (∀ g ∈ Gℓ, h g ∈ A) ∧ f = ∑ g ∈ Gℓ, h g * g) := by
  intro A Gℓ
  set m := (MonomialOrder.lex : MonomialOrder (Fin n)) with hm
  have part1 : ∀ g ∈ Gℓ, g ∈ I ∧ g ∈ A := by
    intro g hg
    rw [Finset.mem_filter] at hg
    exact ⟨hGI g hg.1, hg.2⟩
  -- key step: a divisor's leading term pins the divisor into `A`
  have part2' : ∀ f ∈ I, f ∈ A → f ≠ 0 →
      ∃ g ∈ Gℓ, g ≠ 0 ∧ m.degree g ≤ m.degree f ∧
        m.leadingTerm g ∣ m.leadingTerm f := by
    intro f hfI hfA hf0
    obtain ⟨g, hgG, hdvd⟩ := hG f hfI hf0
    have hlcf : m.leadingCoeff f ≠ 0 := m.leadingCoeff_ne_zero_iff.2 hf0
    have hdvd' := hdvd
    unfold MonomialOrder.leadingTerm at hdvd'
    rw [monomial_dvd_monomial] at hdvd'
    have hdeg : m.degree g ≤ m.degree f := hdvd'.1.resolve_left hlcf
    have hg0 : g ≠ 0 := by
      rintro rfl
      rw [MonomialOrder.leadingCoeff_zero, zero_dvd_iff] at hdvd'
      exact hlcf hdvd'.2
    have hfdeg : ∀ i : Fin n, (i : ℕ) < ℓ → m.degree f i = 0 :=
      (elim_mem_supported_iff f).1 hfA _ (m.degree_mem_support hf0)
    have hgdeg : ∀ i : Fin n, (i : ℕ) < ℓ → m.degree g i = 0 := by
      intro i hi
      have := hdeg i
      rw [hfdeg i hi] at this
      omega
    have hgA : g ∈ A := by
      rw [elim_mem_supported_iff]
      intro d hd
      exact elim_lex_zero_of_le (m.le_degree hd) hgdeg
    exact ⟨g, Finset.mem_filter.2 ⟨hgG, hgA⟩, hg0, hdeg, hdvd⟩
  have part2 : ∀ f ∈ I, f ∈ A → f ≠ 0 →
      ∃ g ∈ Gℓ, m.leadingTerm g ∣ m.leadingTerm f := by
    intro f hfI hfA hf0
    obtain ⟨g, hg, -, -, hdvd⟩ := part2' f hfI hfA hf0
    exact ⟨g, hg, hdvd⟩
  -- every member of `I ∩ A` lies in the ideal spanned by `Gℓ`
  have hspan : ∀ f, f ∈ I → f ∈ A → f ∈ Ideal.span (Gℓ : Set (MvPolynomial (Fin n) k)) := by
    intro f
    induction hd : m.toSyn (m.degree f) using WellFoundedLT.induction generalizing f with
    | ind d IH =>
      intro hfI hfA
      by_cases hf0 : f = 0
      · rw [hf0]; exact Ideal.zero_mem _
      obtain ⟨g, hg, hg0, hdeg, -⟩ := part2' f hfI hfA hf0
      have hgspan : g ∈ Ideal.span (Gℓ : Set (MvPolynomial (Fin n) k)) :=
        Ideal.subset_span (Finset.mem_coe.2 hg)
      have hlcg : IsUnit (m.leadingCoeff g) :=
        (m.leadingCoeff_ne_zero_iff.2 hg0).isUnit
      by_cases hdf : m.degree f = 0
      · have hdg : m.degree g = 0 := by
          ext i
          have := hdeg i
          rw [hdf] at this
          simp only [Finsupp.coe_zero, Pi.zero_apply] at this ⊢
          omega
        have hgC := m.eq_C_of_degree_eq_zero hdg
        have hunit : IsUnit g := by
          rw [hgC]
          exact (hlcg.map C)
        rw [Ideal.eq_top_of_isUnit_mem _ hgspan hunit]
        exact Submodule.mem_top
      · set q := monomial (m.degree f - m.degree g) (hlcg.unit⁻¹ * m.leadingCoeff f) with hq
        have hred : m.reduce hlcg f = f - q * g := rfl
        have hlt := MonomialOrder.degree_reduce_lt hlcg hdeg hdf
        have hqA : q ∈ A := by
          rw [elim_mem_supported_iff]
          intro e he i hi
          have hfdeg : ∀ i : Fin n, (i : ℕ) < ℓ → m.degree f i = 0 :=
            (elim_mem_supported_iff f).1 hfA _ (m.degree_mem_support hf0)
          rw [hq] at he
          have := Finset.mem_singleton.1 (support_monomial_subset he)
          rw [this, Finsupp.tsub_apply, hfdeg i hi]
          simp
        have hgA : g ∈ A := (Finset.mem_filter.1 hg).2
        have hf'I : f - q * g ∈ I :=
          I.sub_mem hfI (I.mul_mem_left q (hGI g (Finset.mem_filter.1 hg).1))
        have hf'A : f - q * g ∈ A := A.sub_mem hfA (A.mul_mem hqA hgA)
        have IH' := IH (m.toSyn (m.degree (f - q * g))) (by rw [← hd, ← hred]; exact hlt)
          (f - q * g) rfl hf'I hf'A
        have : f = (f - q * g) + q * g := by ring
        rw [this]
        exact Ideal.add_mem _ IH' (Ideal.mul_mem_left _ q hgspan)
  refine ⟨part1, part2, ?_⟩
  intro f hfI hfA
  obtain ⟨φfix, φmem⟩ := elim_aeval_fix (k := k) (n := n) (ℓ := ℓ)
  have hf := hspan f hfI hfA
  rw [Ideal.span, Submodule.mem_span_finset] at hf
  obtain ⟨c, -, hc⟩ := hf
  refine ⟨fun g => aeval (fun i : Fin n => if ℓ ≤ (i : ℕ) then X i else 0) (c g),
    fun g _ => φmem _, ?_⟩
  have := congrArg (aeval (fun i : Fin n => if ℓ ≤ (i : ℕ) then
    (X i : MvPolynomial (Fin n) k) else 0)) hc
  rw [φfix f hfA, map_sum] at this
  rw [← this]
  refine Finset.sum_congr rfl fun g hg => ?_
  rw [smul_eq_mul, map_mul, φfix g (Finset.mem_filter.1 hg).2]

/-- The extension theorem. Work over ℂ with variables x_1, x_2, ..., x_{n+1} (here `X 0` is x_1,
the variable being restored, and `X i.succ` is x_{i+2}). Let I = ⟨f_1, ..., f_s⟩ and write each
f_i = c_i x_1^{N_i} + (terms with lower powers of x_1), where the leading coefficient c_i is a
polynomial in the other variables (Mathlib's `finSuccEquiv` rewrites f_i as a polynomial in x_1
with coefficients in those variables). The first elimination ideal I_1 is the set of members of I
with no x_1, read as polynomials in the other variables. If the partial solution
(a_2, ..., a_{n+1}) is a common zero of I_1 and some c_i is nonzero there, then some a_1 in ℂ
makes (a_1, a_2, ..., a_{n+1}) a common zero of every f_i, so a point of V(I). -/
theorem extension_theorem {n s : ℕ} (f : Fin s → MvPolynomial (Fin (n + 1)) ℂ)
    (a : Fin n → ℂ)
    (ha : ∀ p ∈ (Ideal.span (Set.range f)).comap (rename Fin.succ : MvPolynomial (Fin n) ℂ →ₐ[ℂ]
        MvPolynomial (Fin (n + 1)) ℂ), eval a p = 0)
    (hc : ∃ i, eval a (finSuccEquiv ℂ n (f i)).leadingCoeff ≠ 0) :
    ∃ a₁ : ℂ, ∀ i, eval (Fin.cons a₁ a) (f i) = 0 := by
  set e := finSuccEquiv ℂ n
  set ψ : MvPolynomial (Fin n) ℂ →+* ℂ := eval a
  set K := Ideal.span (Set.range fun i => e (f i))
  -- membership in `K` comes back to the original ideal
  have hback : ∀ r : MvPolynomial (Fin n) ℂ, Polynomial.C r ∈ K → ψ r = 0 := by
    intro r hr
    apply ha
    rw [Ideal.mem_comap]
    obtain ⟨w, hw⟩ := Ideal.mem_span_range_iff_exists_fun.1 hr
    have : (rename Fin.succ r : MvPolynomial (Fin (n + 1)) ℂ) =
        ∑ i, e.symm (w i) * f i := by
      apply e.injective
      rw [ext_finSuccEquiv_rename_succ, ← hw, map_sum]
      simp
    rw [this]
    exact Ideal.sum_mem _ fun i _ => Ideal.mul_mem_left _ _ (Ideal.subset_span ⟨i, rfl⟩)
  by_contra Hno
  push Not at Hno
  have H : ∀ z : ℂ, ∃ i, ((e (f i)).map ψ).eval z ≠ 0 := by
    intro z
    obtain ⟨i, hi⟩ := Hno z
    refine ⟨i, ?_⟩
    rwa [eval_eq_eval_mv_eval'] at hi
  have h1 := ext_ideal_eq_top _ H
  obtain ⟨u, hu⟩ := Ideal.mem_span_range_iff_exists_fun.1 h1
  have hψs : Function.Surjective ψ := fun z => ⟨C z, eval_C z⟩
  choose U hU using fun i => Polynomial.map_surjective ψ hψs (u i)
  set P := ∑ i, U i * e (f i)
  have hPK : P ∈ K := Ideal.sum_mem _ fun i _ => Ideal.mul_mem_left _ _ (Ideal.subset_span ⟨i, rfl⟩)
  have hP1 : P.map ψ = Polynomial.C 1 := by
    rw [Polynomial.C_1, ← hu]
    simp only [P, Polynomial.map_sum, Polynomial.map_mul, hU]
  obtain ⟨i0, hi0⟩ := hc
  set F := e (f i0)
  have hFK : F ∈ K := Ideal.subset_span ⟨i0, rfl⟩
  have hN : F.natDegree ≠ 0 := by
    intro hN
    apply hi0
    apply hback
    rw [Polynomial.leadingCoeff, hN, ← Polynomial.eq_C_of_natDegree_eq_zero hN]
    exact hFK
  obtain ⟨p, q, -, -, hpq⟩ := Polynomial.exists_mul_add_mul_eq_C_resultant F P
    (m := F.natDegree) (n := P.natDegree) le_rfl le_rfl (Or.inl hN)
  have hres : ψ (F.resultant P F.natDegree P.natDegree) = 0 := by
    apply hback
    rw [← hpq]
    exact K.add_mem (K.mul_mem_right _ hFK) (K.mul_mem_right _ hPK)
  rw [← Polynomial.resultant_map_map, hP1, Polynomial.resultant_C_right, Polynomial.coeff_map,
    one_pow, mul_one] at hres
  exact pow_ne_zero _ hi0 hres

/-- Step 4: the folium's parametrisation reaches every point of its cubic. Over a field of
characteristic zero (the card uses ℝ and ℂ), a point (x, y) satisfies x^3 - 3xy + y^3 = 0 exactly
when x = 3t/(1 + t^3) and y = 3t^2/(1 + t^3) for some t with 1 + t^3 ≠ 0; the node (0, 0) comes
from t = 0. -/
theorem folium_cubic_iff_parametrised {K : Type*} [Field K] [CharZero K] (x y : K) :
    x ^ 3 - 3 * x * y + y ^ 3 = 0 ↔
      ∃ t : K, 1 + t ^ 3 ≠ 0 ∧ x = 3 * t / (1 + t ^ 3) ∧ y = 3 * t ^ 2 / (1 + t ^ 3) := by
  constructor
  · intro h
    by_cases hx : x = 0
    · have hy : y = 0 := by
        subst hx
        have : y ^ 3 = 0 := by linear_combination h
        exact pow_eq_zero_iff (by norm_num) |>.1 this
      refine ⟨0, by norm_num, ?_, ?_⟩ <;> simp [hx, hy]
    · have hy : y ≠ 0 := by
        rintro rfl
        have : x ^ 3 = 0 := by linear_combination h
        exact hx (pow_eq_zero_iff (by norm_num) |>.1 this)
      have key : 1 + (y / x) ^ 3 = 3 * y / x ^ 2 := by
        field_simp
        linear_combination h
      have h3 : (3 : K) ≠ 0 := by norm_num
      refine ⟨y / x, ?_, ?_, ?_⟩
      · rw [key]
        exact div_ne_zero (mul_ne_zero h3 hy) (pow_ne_zero _ hx)
      · rw [key]
        field_simp
      · rw [key]
        field_simp
  · rintro ⟨t, ht, rfl, rfl⟩
    field_simp
    ring

-- t = 2: 3t = 6, 3t^2 = 12, D = 1 + t^3 = 9, so (x, y) = (6/9, 12/9) = (2/3, 4/3).
example : (3 * 2 / (1 + 2 ^ 3) : ℚ) = 2 / 3 ∧ (3 * 2 ^ 2 / (1 + 2 ^ 3) : ℚ) = 4 / 3 := by norm_num
-- (2/3, 4/3) is on the folium: x^3 + y^3 = 8/27 + 64/27 = 8/3 and 3xy = 8/3.
example : ((2 : ℚ) / 3) ^ 3 + (4 / 3) ^ 3 = 8 / 3 ∧ 3 * ((2 : ℚ) / 3) * (4 / 3) = 8 / 3 := by
  norm_num
-- t comes back from t*x - y = 0: (4/3) / (2/3) = 2.
example : ((4 : ℚ) / 3) / (2 / 3) = 2 := by norm_num
-- t = 1: (x, y) = (3/2, 3/2), and both sides of the cubic are 27/4.
example : (3 * 1 / (1 + 1 ^ 3) : ℚ) = 3 / 2 ∧ ((3 : ℚ) / 2) ^ 3 + (3 / 2) ^ 3 = 27 / 4 ∧
    3 * ((3 : ℚ) / 2) * (3 / 2) = 27 / 4 := by norm_num
-- A point off the curve: F(1, 1) = 1 + 1 - 3 = -1.
example : (1 : ℤ) ^ 3 - 3 * 1 * 1 + 1 ^ 3 = -1 := by norm_num
-- Denominators dropped: x^2 - 3y at (2/3, 4/3) is -32/9, not 0.
example : ((2 : ℚ) / 3) ^ 2 - 3 * (4 / 3) = -32 / 9 := by norm_num
-- Top of the loop: the eliminant factors as y^5 - 4y^2 = y^2 (y^3 - 4).
example : (X 0 ^ 5 - 4 * X 0 ^ 2 : MvPolynomial (Fin 1) ℚ) = X 0 ^ 2 * (X 0 ^ 3 - 4) := by ring
-- The robot arm, elbow (a, b) with links 3 m and 2 m and hand at (4, 0): a = 21/8 and
-- b^2 = 135/64 put the elbow on both circles.
example : (21 / 8 : ℚ) ^ 2 + 135 / 64 = 9 ∧ (21 / 8 - 4 : ℚ) ^ 2 + 135 / 64 = 4 := by norm_num

#print axioms elimination_theorem
#print axioms extension_theorem
#print axioms folium_cubic_iff_parametrised
