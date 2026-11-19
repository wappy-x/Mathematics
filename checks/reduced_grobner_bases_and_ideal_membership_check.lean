-- Normal forms: dividing by a Grobner basis leaves one remainder however the division runs, that remainder is zero exactly for the members of the ideal, and two systems have the same ideal exactly when their reduced Grobner bases match.
import Mathlib.RingTheory.MvPolynomial.Groebner
import Mathlib.Data.Finsupp.MonomialOrder
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

open MvPolynomial


variable {σ k : Type*} [Field k]

/-- `G` is a Grobner basis of the ideal `I` for the monomial order `m`: the finite list `G`
generates `I`, and every nonzero member `f` of `I` has its leading monomial divisible by the
leading monomial of some nonzero `g` in `G`. (On exponent vectors, `≤` is entrywise, which is
divisibility of monomials.) -/
def IsGrobnerBasis (m : MonomialOrder σ) (G : Finset (MvPolynomial σ k))
    (I : Ideal (MvPolynomial σ k)) : Prop :=
  Ideal.span (G : Set (MvPolynomial σ k)) = I ∧
    ∀ f ∈ I, f ≠ 0 → ∃ g ∈ G, g ≠ 0 ∧ m.degree g ≤ m.degree f

/-- `G` is a reduced Grobner basis of `I`: a Grobner basis in which every member has leading
coefficient 1, and no term of any member is divisible by the leading monomial of another member. -/
def IsReducedGrobnerBasis (m : MonomialOrder σ) (G : Finset (MvPolynomial σ k))
    (I : Ideal (MvPolynomial σ k)) : Prop :=
  IsGrobnerBasis m G I ∧ (∀ g ∈ G, m.Monic g) ∧
    ∀ g ∈ G, ∀ h ∈ G, h ≠ g → ∀ c ∈ g.support, ¬ m.degree h ≤ c

/-- `r` is a remainder of `f` on division by the list `G`: division writes
`f = ∑ q_g · g + r` with polynomial multipliers `q_g`, and no term of `r` is divisible by the
leading monomial of any nonzero `g` in `G`. The normal form `NF_G(f)` is such a remainder. -/
def IsRemainder (m : MonomialOrder σ) (G : Finset (MvPolynomial σ k))
    (f r : MvPolynomial σ k) : Prop :=
  (∃ q : MvPolynomial σ k → MvPolynomial σ k, f = ∑ g ∈ G, q g * g + r) ∧
    ∀ c ∈ r.support, ∀ g ∈ G, g ≠ 0 → ¬ m.degree g ≤ c

/-- Helper: a member of `I` with no term divisible by a leading monomial of `G` is zero. -/
theorem grobner_eq_zero_of_mem_of_reduced (m : MonomialOrder σ)
    {G : Finset (MvPolynomial σ k)} {I : Ideal (MvPolynomial σ k)} (hG : IsGrobnerBasis m G I)
    {r : MvPolynomial σ k} (hrI : r ∈ I)
    (hr : ∀ c ∈ r.support, ∀ g ∈ G, g ≠ 0 → ¬ m.degree g ≤ c) : r = 0 := by
  by_contra hne
  obtain ⟨g, hgG, hg0, hgle⟩ := hG.2 r hrI hne
  exact hr _ ((m.degree_mem_support_iff r).mpr hne) g hgG hg0 hgle

/-- Helper: `f - r` lies in the span of `G` when `r` is a remainder of `f`. -/
theorem grobner_sub_remainder_mem (m : MonomialOrder σ)
    {G : Finset (MvPolynomial σ k)} {I : Ideal (MvPolynomial σ k)} (hG : IsGrobnerBasis m G I)
    {f r : MvPolynomial σ k} (hr : IsRemainder m G f r) : f - r ∈ I := by
  obtain ⟨⟨q, hq⟩, -⟩ := hr
  rw [← hG.1, hq, add_sub_cancel_right]
  exact Ideal.sum_mem _ fun g hg => Ideal.mul_mem_left _ _ (Ideal.subset_span hg)

/-- Helper: pointwise `≤` of exponents implies `≼[m]`. -/
theorem grobner_toSyn_le_of_le (m : MonomialOrder σ) {a b : σ →₀ ℕ} (h : a ≤ b) :
    m.toSyn a ≤ m.toSyn b := m.toSyn_monotone h

/-- Helper: in a reduced Grobner basis, a member `g` of `G₁` lies in any reduced Grobner basis
`G₂` of the same ideal. -/
theorem grobner_reduced_subset (m : MonomialOrder σ)
    {G₁ G₂ : Finset (MvPolynomial σ k)} {I : Ideal (MvPolynomial σ k)}
    (h₁ : IsReducedGrobnerBasis m G₁ I) (h₂ : IsReducedGrobnerBasis m G₂ I) : G₁ ⊆ G₂ := by
  classical
  intro g hg
  have hgI : g ∈ I := h₁.1.1 ▸ Ideal.subset_span hg
  have hg0 : g ≠ 0 := (h₁.2.1 g hg).ne_zero
  obtain ⟨g', hg'G, hg'0, hg'le⟩ := h₂.1.2 g hgI hg0
  have hg'I : g' ∈ I := h₂.1.1 ▸ Ideal.subset_span hg'G
  obtain ⟨g'', hg''G, hg''0, hg''le⟩ := h₁.1.2 g' hg'I hg'0
  have hgg'' : g'' = g := by
    by_contra hne
    exact h₁.2.2 g hg g'' hg''G hne _ ((m.degree_mem_support_iff g).mpr hg0)
      (hg''le.trans hg'le)
  subst hgg''
  have hdeg : m.degree g' = m.degree g'' := le_antisymm hg'le hg''le
  have hcoef : (g'' - g').coeff (m.degree g'') = 0 := by
    have a1 : g''.coeff (m.degree g'') = 1 := h₁.2.1 _ hg
    have a2 : g'.coeff (m.degree g') = 1 := h₂.2.1 _ hg'G
    rw [coeff_sub, a1, ← hdeg, a2, sub_self]
  have key : g'' - g' = 0 := by
    by_contra hne
    set c := m.degree (g'' - g') with hc
    have hcs : c ∈ (g'' - g').support := (m.degree_mem_support_iff _).mpr hne
    have hcne : c ≠ m.degree g'' := by
      intro h
      rw [mem_support_iff, h] at hcs
      exact hcs hcoef
    have hsubI : g'' - g' ∈ I := I.sub_mem hgI hg'I
    have hcs' : c ∈ g''.support ∨ c ∈ g'.support := by
      rw [← Finset.mem_union]
      exact MvPolynomial.support_sub σ g'' g' hcs
    rcases hcs' with hc1 | hc2
    · obtain ⟨h, hhG, hh0, hhle⟩ := h₁.1.2 _ hsubI hne
      by_cases hh : h = g''
      · subst hh
        apply hcne
        apply m.toSyn.injective
        exact le_antisymm (m.le_degree hc1) (grobner_toSyn_le_of_le m hhle)
      · exact h₁.2.2 g'' hg h hhG hh c hc1 hhle
    · obtain ⟨h, hhG, hh0, hhle⟩ := h₂.1.2 _ hsubI hne
      by_cases hh : h = g'
      · subst hh
        apply hcne
        rw [← hdeg]
        apply m.toSyn.injective
        exact le_antisymm (m.le_degree hc2) (grobner_toSyn_le_of_le m hhle)
      · exact h₂.2.2 g' hg'G h hhG hh c hc2 hhle
  rw [sub_eq_zero] at key
  exact key ▸ hg'G

/-- The membership test. Over a field, with finitely many variables, one fixed monomial order
and a Grobner basis `G` of the ideal `I`: a polynomial `f` is a consequence of the system
(a member of `I`) exactly when its remainder on division by `G` is zero, `f ∈ I ↔ NF_G(f) = 0`. -/
theorem mem_ideal_iff_normal_form_eq_zero [Finite σ] (m : MonomialOrder σ)
    {G : Finset (MvPolynomial σ k)} {I : Ideal (MvPolynomial σ k)} (hG : IsGrobnerBasis m G I)
    {f r : MvPolynomial σ k} (hr : IsRemainder m G f r) :
    f ∈ I ↔ r = 0 := by
  have hsub := grobner_sub_remainder_mem m hG hr
  constructor
  · intro hf
    exact grobner_eq_zero_of_mem_of_reduced m hG (by simpa using I.sub_mem hf hsub) hr.2
  · rintro rfl
    simpa using hsub

/-- The remainder does not depend on how the division is done: two remainders of the same
polynomial on division by a Grobner basis are equal, so the normal form `NF_G(f)` is well
defined. -/
theorem normal_form_unique [Finite σ] (m : MonomialOrder σ)
    {G : Finset (MvPolynomial σ k)} {I : Ideal (MvPolynomial σ k)} (hG : IsGrobnerBasis m G I)
    {f r₁ r₂ : MvPolynomial σ k} (h₁ : IsRemainder m G f r₁) (h₂ : IsRemainder m G f r₂) :
    r₁ = r₂ := by
  classical
  have hd : r₁ - r₂ ∈ I := by
    have := I.sub_mem (grobner_sub_remainder_mem m hG h₂) (grobner_sub_remainder_mem m hG h₁)
    simpa using this
  have := grobner_eq_zero_of_mem_of_reduced m hG hd (by
    intro c hc g hg hg0
    rcases Finset.mem_union.mp (MvPolynomial.support_sub σ r₁ r₂ hc) with h | h
    · exact h₁.2 c h g hg hg0
    · exact h₂.2 c h g hg hg0)
  exact sub_eq_zero.mp this

/-- Two systems, one test. Under one fixed monomial order, let `G₁` be a reduced Grobner basis
of the system `F₁` and `G₂` one of the system `F₂`. The two systems have the same consequences
(equal ideals) exactly when their reduced Grobner bases are equal. In particular the reduced
Grobner basis of an ideal is unique. -/
theorem same_ideal_iff_reduced_bases_eq [Finite σ] (m : MonomialOrder σ)
    {F₁ F₂ G₁ G₂ : Finset (MvPolynomial σ k)}
    (h₁ : IsReducedGrobnerBasis m G₁ (Ideal.span (F₁ : Set (MvPolynomial σ k))))
    (h₂ : IsReducedGrobnerBasis m G₂ (Ideal.span (F₂ : Set (MvPolynomial σ k)))) :
    Ideal.span (F₁ : Set (MvPolynomial σ k)) = Ideal.span (F₂ : Set (MvPolynomial σ k)) ↔
      G₁ = G₂ := by
  constructor
  · intro hI
    rw [hI] at h₁
    exact Finset.Subset.antisymm (grobner_reduced_subset m h₁ h₂) (grobner_reduced_subset m h₂ h₁)
  · rintro rfl
    rw [← h₁.1.1, h₂.1.1]


/-! The beacon example over ℚ, with `x = X 0` and `y = X 1` (lex order, `x > y`):
`f₁ = x² + y² − 25` (beacon A), `f₂ = x² + y² − 8x − 8y − 17` (beacon B),
`f₃ = x² + y² + 6x + 6y − 31` (beacon C), reduced basis `x + y − 1`, `y² − y − 12`. -/

section Beacons

open MvPolynomial

-- Certificate for the lane: x + y − 1 = (1/8) f₁ − (1/8) f₂, cleared of the 8.
example : (8 : MvPolynomial (Fin 2) ℚ) * (X 0 + X 1 - 1) =
    (X 0 ^ 2 + X 1 ^ 2 - 25) - (X 0 ^ 2 + X 1 ^ 2 - 8 * X 0 - 8 * X 1 - 17) := by
  ring

-- Certificate for xy + 12 = ((x + y + 1)/16)(f₁ − f₂) − (1/2) f₁, cleared of the 16.
example : (16 : MvPolynomial (Fin 2) ℚ) * (X 0 * X 1 + 12) =
    (X 0 + X 1 + 1) * ((X 0 ^ 2 + X 1 ^ 2 - 25) - (X 0 ^ 2 + X 1 ^ 2 - 8 * X 0 - 8 * X 1 - 17))
      - 8 * (X 0 ^ 2 + X 1 ^ 2 - 25) := by
  ring

-- The reduced basis lies in the beacons' ideal and generates it:
-- f₁ = (x − y + 1)(x + y − 1) + 2(y² − y − 12) and f₂ = f₁ − 8(x + y − 1).
example : (X 0 ^ 2 + X 1 ^ 2 - 25 : MvPolynomial (Fin 2) ℚ) =
    (X 0 - X 1 + 1) * (X 0 + X 1 - 1) + 2 * (X 1 ^ 2 - X 1 - 12) := by
  ring
example : (X 0 ^ 2 + X 1 ^ 2 - 8 * X 0 - 8 * X 1 - 17 : MvPolynomial (Fin 2) ℚ) =
    (X 0 ^ 2 + X 1 ^ 2 - 25) - 8 * (X 0 + X 1 - 1) := by
  ring
-- Beacon C's circle is in the same ideal: f₃ = f₁ + 6(x + y − 1).
example : (X 0 ^ 2 + X 1 ^ 2 + 6 * X 0 + 6 * X 1 - 31 : MvPolynomial (Fin 2) ℚ) =
    (X 0 ^ 2 + X 1 ^ 2 - 25) + 6 * (X 0 + X 1 - 1) := by
  ring

-- The divisions on the card: NF(x²) = −y + 13, NF(xy + 12) = 0, NF(x − y − 7) = −2y − 6.
example : (X 0 ^ 2 : MvPolynomial (Fin 2) ℚ) =
    (X 0 - X 1 + 1) * (X 0 + X 1 - 1) + 1 * (X 1 ^ 2 - X 1 - 12) + (-X 1 + 13) := by
  ring
example : (X 0 * X 1 + 12 : MvPolynomial (Fin 2) ℚ) =
    X 1 * (X 0 + X 1 - 1) + (-1) * (X 1 ^ 2 - X 1 - 12) := by
  ring
example : (X 0 - X 1 - 7 : MvPolynomial (Fin 2) ℚ) =
    1 * (X 0 + X 1 - 1) + (-2 * X 1 - 6) := by
  ring

-- The two fixes (4, −3) and (−3, 4) lie on all three circles and on the lane.
example : (4 : ℤ) ^ 2 + (-3) ^ 2 - 25 = 0 ∧ (-3 : ℤ) ^ 2 + 4 ^ 2 - 25 = 0 := by norm_num
example : (4 : ℤ) ^ 2 + (-3) ^ 2 - 8 * 4 - 8 * (-3) - 17 = 0 ∧
    (-3 : ℤ) ^ 2 + 4 ^ 2 - 8 * (-3) - 8 * 4 - 17 = 0 := by norm_num
example : (4 : ℤ) ^ 2 + (-3) ^ 2 + 6 * 4 + 6 * (-3) - 31 = 0 ∧
    (-3 : ℤ) ^ 2 + 4 ^ 2 + 6 * (-3) + 6 * 4 - 31 = 0 := by norm_num
example : (4 : ℤ) + (-3) - 1 = 0 ∧ (-3 : ℤ) + 4 - 1 = 0 := by norm_num

-- The remainder agrees with the polynomial at each fix: x² is 16 and 9, and −y + 13 is 16 and 9;
-- x − y − 7 is −14 at (−3, 4), and so is −2y − 6.
example : (4 : ℤ) ^ 2 = -(-3) + 13 ∧ (-3 : ℤ) ^ 2 = -4 + 13 := by norm_num
example : (-3 : ℤ) - 4 - 7 = -14 ∧ -2 * (4 : ℤ) - 6 = -14 := by norm_num

-- The house arm's reduced basis x − 21/8, y² − 135/64 lies on the 3 m circle: (21/8)² + 135/64 = 9.
example : (21 / 8 : ℚ) ^ 2 + 135 / 64 = 9 := by norm_num

end Beacons

#print axioms grobner_eq_zero_of_mem_of_reduced
#print axioms grobner_sub_remainder_mem
#print axioms grobner_toSyn_le_of_le
#print axioms grobner_reduced_subset
#print axioms mem_ideal_iff_normal_form_eq_zero
#print axioms normal_form_unique
#print axioms same_ideal_iff_reduced_bases_eq
