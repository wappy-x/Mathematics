-- The exponential formula: when every structure is a set of connected pieces whose count depends only on their size, the structures' exponential generating function is e raised to the pieces' series and the logarithm turns it back, which counts involutions by e^(x + x^2/2) and connected graphs by the logarithm of the all-graphs series.
import Mathlib.Order.Partition.Finpartition
import Mathlib.RingTheory.PowerSeries.Exp
import Mathlib.RingTheory.PowerSeries.Log
import Mathlib.RingTheory.PowerSeries.Substitution
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Data.Nat.Choose.Cast
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.GroupTheory.Perm.Centralizer
import Mathlib.GroupTheory.Perm.Cycle.Type

open PowerSeries Nat

/-- The structures on the labels `Fin n` built from connected pieces: a set partition of the
labels into nonempty blocks (so each structure splits into pieces in exactly one way, on
separate labels), and on each block one of `c j` connected shapes, where `j` is the block's size
(so a piece's count depends only on how many labels it gets). Any set of blocks is allowed. -/
abbrev Structures (c : ℕ → ℕ) (n : ℕ) : Type :=
  Σ π : Finpartition (Finset.univ : Finset (Fin n)), ∀ B : π.parts, Fin (c (B : Finset (Fin n)).card)

/-- The exponential generating function of the structures: `A(x) = ∑ a_n x^n / n!`. -/
noncomputable abbrev structuresSeries (c : ℕ → ℕ) : PowerSeries ℚ :=
  PowerSeries.mk fun n => (Fintype.card (Structures c n) : ℚ) / n !

/-- The pieces' series: `C(x) = ∑ c_j x^j / j!` over `j ≥ 1` (pieces are never empty). -/
noncomputable abbrev piecesSeries (c : ℕ → ℕ) : PowerSeries ℚ :=
  PowerSeries.mk fun n => if n = 0 then 0 else (c n : ℚ) / n !

-- Helper lemmas for the proofs below.

def egfSeq (c : ℕ → ℕ) : ℕ → ℕ
  | 0 => 1
  | m + 1 => ∑ k : Fin (m + 1), m.choose k * c (k + 1) * egfSeq c (m - k)
decreasing_by omega

theorem egfSeq_zero (c : ℕ → ℕ) : egfSeq c 0 = 1 := by rw [egfSeq]

theorem egfSeq_succ (c : ℕ → ℕ) (m : ℕ) : egfSeq c (m + 1) =
    ∑ k ∈ Finset.range (m + 1), m.choose k * c (k + 1) * egfSeq c (m - k) := by
  rw [egfSeq, Fin.sum_univ_eq_sum_range (fun k => m.choose k * c (k + 1) * egfSeq c (m - k))]

def ef_F {α : Type*} [DecidableEq α] (c : ℕ → ℕ) (s : Finset α) : ℕ :=
  ∑ π : Finpartition s, ∏ B ∈ π.parts, c B.card

theorem ef_F_empty {α : Type*} [DecidableEq α] (c : ℕ → ℕ) : ef_F c (∅ : Finset α) = 1 := by
  have h : ∀ π : Finpartition (∅ : Finset α), π.parts = ∅ := fun π => π.parts_eq_empty_iff.mpr rfl
  unfold ef_F
  simp only [h, Finset.prod_empty, Finset.sum_const, Finset.card_univ, smul_eq_mul, mul_one]
  exact Fintype.card_eq_one_iff.mpr ⟨Finpartition.empty _, fun π => Finpartition.ext (by
    rw [h π]; rfl)⟩

theorem ef_F_insert {α : Type*} [DecidableEq α] (c : ℕ → ℕ) (a : α) (t : Finset α)
    (ha : a ∉ t) :
    ef_F c (insert a t) = ∑ u ∈ t.powerset, c (u.card + 1) * ef_F c (t \ u) := by
  unfold ef_F
  rw [← Finset.sum_fiberwise_of_maps_to (s := Finset.univ) (t := t.powerset)
      (g := fun π : Finpartition (insert a t) => (π.part a).erase a) ?maps]
  case maps =>
    intro π _
    simp only [Finset.mem_powerset]
    intro x hx
    have hx' := Finset.mem_of_mem_erase hx
    rcases Finset.mem_insert.mp (π.part_subset a hx') with h | h
    · exact absurd h (Finset.ne_of_mem_erase hx)
    · exact h
  apply Finset.sum_congr rfl
  intro u hu
  rw [Finset.mem_powerset] at hu
  have hau : a ∉ u := fun h => ha (hu h)
  have haI : a ∈ insert a t := Finset.mem_insert_self a t
  rw [Finset.mul_sum]
  have hdisj : Disjoint (t \ u) (insert a u) := by
    rw [Finset.disjoint_left]; intro x hx hx'
    rcases Finset.mem_insert.mp hx' with h | h
    · subst h; exact ha (Finset.mem_sdiff.mp hx).1
    · exact (Finset.mem_sdiff.mp hx).2 h
  have hsup : t \ u ⊔ insert a u = insert a t := by
    ext x
    simp only [Finset.sup_eq_union, Finset.mem_union, Finset.mem_sdiff, Finset.mem_insert]
    constructor
    · rintro (⟨h1, _⟩ | h | h)
      · exact Or.inr h1
      · exact Or.inl h
      · exact Or.inr (hu h)
    · rintro (h | h)
      · exact Or.inr (Or.inl h)
      · by_cases hxu : x ∈ u
        · exact Or.inr (Or.inr hxu)
        · exact Or.inl ⟨h, hxu⟩
  have hne : insert a u ≠ ⊥ := Finset.insert_ne_empty a u
  have key : ∀ π : Finpartition (insert a t), (π.part a).erase a = u → π.part a = insert a u := by
    intro π h
    rw [← h, Finset.insert_erase (π.mem_part_self.mpr haI)]
  have supE : ∀ π : Finpartition (insert a t), (π.part a).erase a = u →
      (π.parts.erase (π.part a)).sup id = t \ u := by
    intro π h
    have hp := key π h
    ext x
    rw [Finset.mem_sup]
    constructor
    · rintro ⟨B, hB, hxB⟩
      rw [Finset.mem_erase] at hB
      have hxs : x ∈ insert a t := π.subset hB.2 hxB
      have hxp : x ∉ insert a u := by
        intro hxp
        rw [← hp] at hxp
        exact hB.1 (π.eq_of_mem_parts hB.2 (π.part_mem.mpr haI) hxB hxp)
      rw [Finset.mem_sdiff]
      rcases Finset.mem_insert.mp hxs with h' | h'
      · exact absurd (h' ▸ Finset.mem_insert_self a u) hxp
      · exact ⟨h', fun hh => hxp (Finset.mem_insert_of_mem hh)⟩
    · intro hx
      rw [Finset.mem_sdiff] at hx
      have hxs : x ∈ insert a t := Finset.mem_insert_of_mem hx.1
      refine ⟨π.part x, Finset.mem_erase.mpr ⟨?_, π.part_mem.mpr hxs⟩, π.mem_part_self.mpr hxs⟩
      intro heq
      have : x ∈ π.part a := heq ▸ π.mem_part_self.mpr hxs
      rw [hp] at this
      rcases Finset.mem_insert.mp this with h' | h'
      · exact ha (h' ▸ hx.1)
      · exact hx.2 h'
  have partE : ∀ ρ : Finpartition (t \ u), (ρ.extend hne hdisj hsup).part a = insert a u :=
    fun ρ => Finpartition.part_eq_of_mem _ (Finset.mem_insert_self _ _) (Finset.mem_insert_self _ _)
  refine Finset.sum_bij'
    (fun π hπ => π.ofSubset (parts := π.parts.erase (π.part a)) (Finset.erase_subset _ _)
      (supE π (Finset.mem_filter.mp hπ).2))
    (fun ρ _ => ρ.extend hne hdisj hsup) ?hi ?hj ?li ?ri ?h
  · intro π _; exact Finset.mem_univ _
  · intro ρ _
    refine Finset.mem_filter.mpr ⟨Finset.mem_univ _, ?_⟩
    show ((ρ.extend hne hdisj hsup).part a).erase a = u
    rw [partE, Finset.erase_insert hau]
  · intro π hπ
    have h := (Finset.mem_filter.mp hπ).2
    apply Finpartition.ext
    show insert (insert a u) (π.parts.erase (π.part a)) = π.parts
    rw [← key π h, Finset.insert_erase (π.part_mem.mpr haI)]
  · intro ρ _
    apply Finpartition.ext
    show (insert (insert a u) ρ.parts).erase ((ρ.extend hne hdisj hsup).part a) = ρ.parts
    rw [partE, Finset.erase_insert]
    intro hm
    have := ρ.subset hm (Finset.mem_insert_self a u)
    exact ha (Finset.mem_sdiff.mp this).1
  · intro π hπ
    have h := (Finset.mem_filter.mp hπ).2
    show ∏ B ∈ π.parts, c B.card = c (u.card + 1) * ∏ B ∈ π.parts.erase (π.part a), c B.card
    rw [← Finset.mul_prod_erase π.parts _ (π.part_mem.mpr haI), key π h,
      Finset.card_insert_of_notMem hau]

theorem ef_F_eq {α : Type*} [DecidableEq α] (c : ℕ → ℕ) :
    ∀ n, ∀ s : Finset α, s.card = n → ef_F c s = egfSeq c n := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro s hs
    cases n with
    | zero =>
      rw [Finset.card_eq_zero] at hs
      subst hs
      rw [ef_F_empty, egfSeq_zero]
    | succ m =>
      obtain ⟨a, has⟩ : s.Nonempty := Finset.card_pos.mp (by omega)
      have hst : s = insert a (s.erase a) := (Finset.insert_erase has).symm
      have hcard : (s.erase a).card = m := by rw [Finset.card_erase_of_mem has]; omega
      rw [hst, ef_F_insert c a _ (Finset.notMem_erase a s), egfSeq_succ]
      have : ∀ u ∈ (s.erase a).powerset, c (u.card + 1) * ef_F c (s.erase a \ u) =
          c (u.card + 1) * egfSeq c (m - u.card) := by
        intro u hu
        rw [Finset.mem_powerset] at hu
        rw [ih (m - u.card) (by omega) _ (by rw [Finset.card_sdiff_of_subset hu, hcard])]
      rw [Finset.sum_congr rfl this,
        Finset.sum_powerset_apply_card (fun k => c (k + 1) * egfSeq c (m - k)), hcard]
      apply Finset.sum_congr rfl
      intro k _
      rw [smul_eq_mul, mul_assoc]

theorem ef_card_structures (c : ℕ → ℕ) (n : ℕ) :
    Fintype.card (Structures c n) = egfSeq c n := by
  rw [← ef_F_eq c n (Finset.univ : Finset (Fin n)) (by simp), Fintype.card_sigma, ef_F]
  apply Finset.sum_congr rfl
  intro π _
  rw [Fintype.card_pi]
  simp only [Fintype.card_fin]
  exact Finset.prod_coe_sort π.parts (fun B => c B.card)

theorem ef_ode_unique (P F G : ℚ⟦X⟧) (hF : d⁄dX F = P * F) (hG : d⁄dX G = P * G)
    (h0 : constantCoeff F = constantCoeff G) : F = G := by
  have hH : d⁄dX (F - G) = P * (F - G) := by rw [map_sub, hF, hG, mul_sub]
  suffices h : ∀ n, coeff n (F - G) = 0 by
    ext n; have := h n; rw [map_sub, sub_eq_zero] at this; exact this
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    cases n with
    | zero => simp [coeff_zero_eq_constantCoeff_apply, h0]
    | succ k =>
      have h1 := congrArg (coeff k) hH
      rw [coeff_derivative, coeff_mul, Finset.sum_eq_zero] at h1
      · have : (k:ℚ) + 1 ≠ 0 := by positivity
        exact (mul_eq_zero.mp h1).resolve_right this
      · intro x hx
        rw [ih x.2 (by have := Finset.mem_antidiagonal.mp hx; omega), mul_zero]

theorem ef_deriv_exp_subst (f : ℚ⟦X⟧) (hf : constantCoeff f = 0) :
    d⁄dX ((exp ℚ).subst f) = d⁄dX f * (exp ℚ).subst f := by
  rw [derivative_subst (HasSubst.of_constantCoeff_zero' hf), derivative_exp, mul_comm]

theorem ef_cc_exp_subst (f : ℚ⟦X⟧) (hf : constantCoeff f = 0) :
    constantCoeff ((exp ℚ).subst f) = 1 := by
  rw [constantCoeff_eq, constantCoeff_subst_of_constantCoeff_zero hf, constantCoeff_exp, map_one]

theorem ef_logOf_exp_subst (f : ℚ⟦X⟧) (hf : constantCoeff f = 0) :
    logOf ((exp ℚ).subst f) = f := by
  have hs : HasSubst f := HasSubst.of_constantCoeff_zero' hf
  have h1 : (exp ℚ).subst f - 1 = (exp ℚ - 1).subst f := by
    rw [subst_sub hs, ← coe_substAlgHom hs (R := ℚ), map_one]
  rw [logOf_eq, h1, ← subst_comp_subst_apply HasSubst.exp_sub_one hs, subst_log_exp_sub_one,
    subst_X hs]

theorem ef_egf_eq (c : ℕ → ℕ) :
    PowerSeries.mk (fun n => (egfSeq c n : ℚ) / n !) = (exp ℚ).subst (piecesSeries c) := by
  have hC : constantCoeff (piecesSeries c) = 0 := by
    simp [← coeff_zero_eq_constantCoeff_apply]
  apply ef_ode_unique (d⁄dX (piecesSeries c))
  · ext m
    rw [coeff_derivative, coeff_mk, coeff_mul,
      Finset.Nat.sum_antidiagonal_eq_sum_range_succ
        (fun i j => coeff i (d⁄dX (piecesSeries c)) * coeff j (PowerSeries.mk _)),
      egfSeq_succ]
    push_cast
    rw [Finset.sum_div, Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro k hk
    have hk' : k ≤ m := by simp at hk; omega
    simp only [coeff_derivative, coeff_mk]
    rw [ite_eq_right (by omega), Nat.cast_choose ℚ hk']
    push_cast [Nat.factorial_succ]
    field_simp
  · rw [ef_deriv_exp_subst _ hC]
  · rw [ef_cc_exp_subst _ hC]; simp [← coeff_zero_eq_constantCoeff_apply, egfSeq_zero]

theorem ef_invol_iff {α : Type*} [Fintype α] [DecidableEq α] (σ : Equiv.Perm α) :
    σ * σ = 1 ↔ ∀ k ∈ σ.cycleType, k = 2 := by
  rw [← pow_two, ← orderOf_dvd_iff_pow_eq_one, ← Equiv.Perm.lcm_cycleType, Multiset.lcm_dvd]
  refine forall₂_congr fun k hk => ⟨fun h => ?_, fun h => h ▸ dvd_rfl⟩
  exact le_antisymm (Nat.le_of_dvd two_pos h) (Equiv.Perm.two_le_of_mem_cycleType hk)

theorem ef_invol_fiber {α : Type*} [Fintype α] [DecidableEq α] (j : ℕ) (σ : Equiv.Perm α) :
    (σ * σ = 1 ∧ σ.support.card = j) ↔ (Even j ∧ σ.cycleType = Multiset.replicate (j / 2) 2) := by
  rw [ef_invol_iff, ← Multiset.eq_replicate_card, ← Equiv.Perm.sum_cycleType]
  constructor
  · rintro ⟨h1, h2⟩
    rw [h1, Multiset.sum_replicate, smul_eq_mul] at h2
    refine ⟨⟨σ.cycleType.card, by omega⟩, ?_⟩
    rw [h1]; congr 1; omega
  · rintro ⟨⟨r, hr⟩, h⟩
    rw [h, Multiset.card_replicate, Multiset.sum_replicate, smul_eq_mul]
    exact ⟨rfl, by omega⟩

theorem ef_card_cycleType_two {α : Type*} [Fintype α] [DecidableEq α] (k : ℕ)
    (hk : 2 * k ≤ Fintype.card α) :
    ((Finset.univ.filter fun σ : Equiv.Perm α => σ.cycleType = Multiset.replicate k 2).card : ℚ) *
      ((Fintype.card α - 2 * k)! * 2 ^ k * k !) = (Fintype.card α)! := by
  have h := Equiv.Perm.card_of_cycleType_mul_eq α (Multiset.replicate k 2)
  rw [ite_eq_left ⟨by rw [Multiset.sum_replicate, smul_eq_mul]; omega,
    fun a ha => (Multiset.eq_of_mem_replicate ha).symm ▸ le_rfl⟩] at h
  have hp : ∏ n ∈ (Multiset.replicate k 2).toFinset, ((Multiset.replicate k 2).count n)! = k ! := by
    rw [Finset.prod_subset (s₂ := {2})]
    · rw [Finset.prod_singleton, Multiset.count_replicate_self]
    · intro x hx
      rw [Multiset.mem_toFinset] at hx
      rw [Finset.mem_singleton, Multiset.eq_of_mem_replicate hx]
    · intro x _ hx
      rw [Multiset.mem_toFinset] at hx
      rw [Multiset.count_eq_zero_of_notMem hx, Nat.factorial_zero]
  rw [hp, Multiset.sum_replicate, Multiset.prod_replicate, smul_eq_mul, mul_comm k 2] at h
  exact_mod_cast h

noncomputable def ef_e (j : ℕ) : ℚ := if Even j then 1 / (2 ^ (j / 2) * (j / 2)! : ℚ) else 0

theorem ef_invol_count (n : ℕ) :
    (Fintype.card {σ : Equiv.Perm (Fin n) // σ * σ = 1} : ℚ) / n ! =
      ∑ p ∈ Finset.antidiagonal n, (1 / p.1 ! : ℚ) * ef_e p.2 := by
  rw [Fintype.card_subtype, Finset.card_eq_sum_card_fiberwise
    (f := fun σ : Equiv.Perm (Fin n) => (n - σ.support.card, σ.support.card))
    (t := Finset.antidiagonal n)]
  · push_cast
    rw [Finset.sum_div]
    apply Finset.sum_congr rfl
    rintro ⟨i, j⟩ hij
    rw [Finset.mem_antidiagonal] at hij
    rw [Finset.filter_filter]
    have hfe : (Finset.univ.filter fun σ : Equiv.Perm (Fin n) =>
        σ * σ = 1 ∧ (n - σ.support.card, σ.support.card) = (i, j)) =
        Finset.univ.filter fun σ : Equiv.Perm (Fin n) => σ * σ = 1 ∧ σ.support.card = j := by
      apply Finset.filter_congr
      intro σ _
      simp only [Prod.mk.injEq]
      constructor
      · rintro ⟨h1, _, h3⟩; exact ⟨h1, h3⟩
      · rintro ⟨h1, h3⟩; exact ⟨h1, by omega, h3⟩
    rw [hfe]
    simp only [ef_e]
    by_cases hj : Even j
    · have hfe2 : (Finset.univ.filter fun σ : Equiv.Perm (Fin n) =>
          σ * σ = 1 ∧ σ.support.card = j) =
          Finset.univ.filter fun σ : Equiv.Perm (Fin n) =>
            σ.cycleType = Multiset.replicate (j / 2) 2 := by
        apply Finset.filter_congr
        intro σ _
        rw [ef_invol_fiber]
        exact ⟨fun h => h.2, fun h => ⟨hj, h⟩⟩
      rw [hfe2, ite_eq_left hj]
      have h := ef_card_cycleType_two (α := Fin n) (j / 2) (by rw [Fintype.card_fin]; omega)
      rw [Fintype.card_fin] at h
      obtain ⟨r, hr⟩ := hj
      have hi : i = n - 2 * (j / 2) := by omega
      rw [hi]
      have h1 : ((n - 2 * (j / 2))! : ℚ) ≠ 0 := by positivity
      have h2 : ((j / 2)! : ℚ) ≠ 0 := by positivity
      have h3 : (n ! : ℚ) ≠ 0 := by positivity
      have h4 : ((Finset.univ.filter fun σ : Equiv.Perm (Fin n) =>
          σ.cycleType = Multiset.replicate (j / 2) 2).card : ℚ) ≠ 0 := by
        intro h0; rw [h0, zero_mul] at h; exact h3 h.symm
      rw [← h]
      field_simp
    · have hfe2 : (Finset.univ.filter fun σ : Equiv.Perm (Fin n) =>
          σ * σ = 1 ∧ σ.support.card = j) = ∅ := by
        apply Finset.filter_false_of_mem
        intro σ _ h
        exact hj ((ef_invol_fiber j σ).mp h).1
      rw [hfe2, ite_eq_right hj]
      simp
  · intro σ _
    simp only [Finset.mem_coe, Finset.mem_antidiagonal]
    have := σ.support.card_le_univ
    rw [Fintype.card_fin] at this
    omega

theorem ef_exp_invol :
    (exp ℚ).subst (X + (2⁻¹ : ℚ) • X ^ 2 : PowerSeries ℚ) = exp ℚ * PowerSeries.mk ef_e := by
  have hq : constantCoeff (X + (2⁻¹ : ℚ) • X ^ 2 : PowerSeries ℚ) = 0 := by simp
  have hdq : d⁄dX (X + (2⁻¹ : ℚ) • X ^ 2 : PowerSeries ℚ) = 1 + X := by
    ext n
    rw [coeff_derivative]
    rcases n with _ | _ | n <;> simp [coeff_X, coeff_X_pow]; norm_num
  have hde : d⁄dX (PowerSeries.mk ef_e) = X * PowerSeries.mk ef_e := by
    ext m
    rw [coeff_derivative, coeff_mk]
    rcases m with _ | k
    · simp [ef_e]
    · rw [coeff_succ_X_mul, coeff_mk]
      rcases Nat.even_or_odd k with ⟨i, rfl⟩ | ⟨i, rfl⟩
      · have he1 : Even (i + i + 1 + 1) := ⟨i + 1, by ring⟩
        have he2 : Even (i + i) := ⟨i, rfl⟩
        have hd1 : (i + i + 1 + 1) / 2 = i + 1 := by omega
        have hd2 : (i + i) / 2 = i := by omega
        simp only [ef_e, ite_eq_left he1, ite_eq_left he2, hd1, hd2]
        push_cast [Nat.factorial_succ, pow_succ]
        field_simp
        ring
      · have he1 : ¬ Even (2 * i + 1 + 1 + 1) := by
          rw [Nat.not_even_iff_odd]; exact ⟨i + 1, by ring⟩
        have he2 : ¬ Even (2 * i + 1) := by rw [Nat.not_even_iff_odd]; exact ⟨i, rfl⟩
        simp only [ef_e, ite_eq_right he1, ite_eq_right he2]
        simp
  apply ef_ode_unique (1 + X)
  · rw [ef_deriv_exp_subst _ hq, hdq]
  · rw [Derivation.leibniz, derivative_exp, hde, smul_eq_mul, smul_eq_mul]
    ring
  · rw [ef_cc_exp_subst _ hq, map_mul, constantCoeff_exp]
    simp [← coeff_zero_eq_constantCoeff_apply, ef_e]

theorem ef_card_graphs (V : Type*) [Fintype V] [DecidableEq V] :
    Nat.card (SimpleGraph V) = 2 ^ (Fintype.card V).choose 2 := by
  let e : SimpleGraph V ≃ Set {x : Sym2 V // ¬ x.IsDiag} :=
    { toFun := fun G => {x | x.1 ∈ G.edgeSet}
      invFun := fun s => SimpleGraph.fromEdgeSet (Subtype.val '' s)
      left_inv := fun G => by
        ext u v
        simp only [SimpleGraph.fromEdgeSet_adj, Set.mem_image, Set.mem_ofPred_eq, Subtype.exists,
          exists_and_right, exists_eq_right, SimpleGraph.mem_edgeSet]
        constructor
        · rintro ⟨⟨_, h⟩, _⟩; exact h
        · intro h; exact ⟨⟨by simpa using G.ne_of_adj h, h⟩, G.ne_of_adj h⟩
      right_inv := fun s => by
        ext ⟨x, hx⟩
        simp only [Set.mem_ofPred_eq, SimpleGraph.edgeSet_fromEdgeSet, Set.mem_sdiff,
          Set.mem_image, Subtype.exists, exists_and_right, exists_eq_right]
        constructor
        · rintro ⟨⟨_, h⟩, _⟩; exact h
        · intro h; exact ⟨⟨hx, h⟩, hx⟩ }
  rw [Nat.card_congr e, Nat.card_eq_fintype_card, Fintype.card_set, Sym2.card_subtype_not_diag]

theorem ef_card_conn {V : Type*} [Fintype V] [DecidableEq V] (B : Finset V) :
    Nat.card {H : SimpleGraph B // H.Connected} =
      Nat.card {G : SimpleGraph (Fin B.card) // G.Connected} := by
  let e := B.equivFin
  let f : SimpleGraph B ≃ SimpleGraph (Fin B.card) :=
    { toFun := fun H => H.comap e.symm
      invFun := fun G => G.comap e
      left_inv := fun H => by ext; simp
      right_inv := fun G => by ext; simp }
  apply Nat.card_congr
  refine f.subtypeEquiv ?_
  intro H
  exact (SimpleGraph.Iso.comap e.symm H).connected_iff.symm

noncomputable def ef_comp {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V) :
    Finpartition (Finset.univ : Finset V) := by
  classical exact Finpartition.ofSetoid G.reachableSetoid

theorem ef_mem_comp {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V) (a b : V) :
    b ∈ (ef_comp G).part a ↔ G.Reachable a b := by
  classical
  unfold ef_comp
  convert Finpartition.mem_part_ofSetoid_iff_rel (s := G.reachableSetoid) (a := a) (b := b)

theorem ef_fp_ext {V : Type*} [Fintype V] [DecidableEq V]
    (P Q : Finpartition (Finset.univ : Finset V))
    (h : ∀ a b, b ∈ P.part a ↔ b ∈ Q.part a) : P = Q := by
  have hp : ∀ a, P.part a = Q.part a := fun a => Finset.ext (h a)
  apply Finpartition.ext
  ext B
  constructor
  · intro hB
    obtain ⟨a, ha⟩ := P.nonempty_of_mem_parts hB
    rw [← P.part_eq_of_mem hB ha, hp]
    exact Q.part_mem.mpr (Finset.mem_univ a)
  · intro hB
    obtain ⟨a, ha⟩ := Q.nonempty_of_mem_parts hB
    rw [← Q.part_eq_of_mem hB ha, ← hp]
    exact P.part_mem.mpr (Finset.mem_univ a)

theorem ef_comp_eq_iff {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    (π : Finpartition (Finset.univ : Finset V)) :
    ef_comp G = π ↔ ∀ a b, G.Reachable a b ↔ b ∈ π.part a :=
  ⟨fun h a b => by rw [← h, ef_mem_comp],
    fun h => ef_fp_ext _ _ (fun a b => by rw [ef_mem_comp, h])⟩

theorem ef_lift {V : Type*} (G : SimpleGraph V) (S : Finset V)
    (hS : ∀ x y, x ∈ S → G.Adj x y → y ∈ S) {u v : V} (p : G.Walk u v) :
    ∀ (hu : u ∈ S) (hv : v ∈ S),
      (G.comap (Subtype.val : S → V)).Reachable ⟨u, hu⟩ ⟨v, hv⟩ := by
  induction p with
  | nil => intro hu hv; rfl
  | cons h p ih =>
    intro hu hv
    have hb := hS _ _ hu h
    have hadj : (G.comap (Subtype.val : S → V)).Adj ⟨_, hu⟩ ⟨_, hb⟩ := by simpa using h
    exact hadj.reachable.trans (ih hb hv)

theorem ef_comp_conn {V : Type*} [Fintype V] [DecidableEq V]
    (π : Finpartition (Finset.univ : Finset V)) (G : SimpleGraph V) (hG : ef_comp G = π)
    (B : π.parts) : (G.comap (Subtype.val : B.1 → V)).Connected := by
  rw [ef_comp_eq_iff] at hG
  have hpart : ∀ x ∈ B.1, π.part x = B.1 := fun x hx => π.part_eq_of_mem B.2 hx
  rw [SimpleGraph.connected_iff]
  refine ⟨fun x y => ?_, ?_⟩
  · obtain ⟨p⟩ := (hG x y).mpr (by rw [hpart x x.2]; exact y.2)
    refine ef_lift G B.1 (fun a b ha hab => ?_) p x.2 y.2
    rw [← hpart a ha, ← hG]; exact hab.reachable
  · obtain ⟨a, ha⟩ := π.nonempty_of_mem_parts B.2
    exact ⟨⟨a, ha⟩⟩

def ef_glue {V : Type*} [Fintype V] [DecidableEq V]
    (π : Finpartition (Finset.univ : Finset V))
    (Hs : ∀ B : π.parts, {H : SimpleGraph B.1 // H.Connected}) : SimpleGraph V where
  Adj x y := ∃ B : π.parts, ∃ (hx : x ∈ B.1) (hy : y ∈ B.1), (Hs B).1.Adj ⟨x, hx⟩ ⟨y, hy⟩
  symm := ⟨fun _ _ ⟨B, hx, hy, h⟩ => ⟨B, hy, hx, h.symm⟩⟩
  loopless := ⟨fun _ ⟨B, _, _, h⟩ => (Hs B).1.loopless.irrefl _ h⟩

theorem ef_glue_comp {V : Type*} [Fintype V] [DecidableEq V]
    (π : Finpartition (Finset.univ : Finset V))
    (Hs : ∀ B : π.parts, {H : SimpleGraph B.1 // H.Connected}) :
    ef_comp (ef_glue π Hs) = π := by
  rw [ef_comp_eq_iff]
  intro a b
  constructor
  · rintro ⟨p⟩
    induction p with
    | nil => exact π.mem_part_self.mpr (Finset.mem_univ _)
    | cons h p ih =>
      obtain ⟨B, hx, hy, _⟩ := h
      rw [π.part_eq_of_mem B.2 hx]
      rw [π.part_eq_of_mem B.2 hy] at ih
      exact ih
  · intro hb
    have hB : π.part a ∈ π.parts := π.part_mem.mpr (Finset.mem_univ a)
    let B : π.parts := ⟨π.part a, hB⟩
    have ha : a ∈ B.1 := π.mem_part_self.mpr (Finset.mem_univ a)
    have hr : (Hs B).1.Reachable ⟨a, ha⟩ ⟨b, hb⟩ := (Hs B).2.preconnected _ _
    let f : (Hs B).1 →g ef_glue π Hs := ⟨Subtype.val, fun {x y} h => ⟨B, x.2, y.2, h⟩⟩
    exact hr.map f

noncomputable def ef_fiberEquiv {V : Type*} [Fintype V] [DecidableEq V]
    (π : Finpartition (Finset.univ : Finset V)) :
    {G : SimpleGraph V // ef_comp G = π} ≃ ∀ B : π.parts, {H : SimpleGraph B.1 // H.Connected} where
  toFun G B := ⟨G.1.comap (Subtype.val : B.1 → V), ef_comp_conn π G.1 G.2 B⟩
  invFun Hs := ⟨ef_glue π Hs, ef_glue_comp π Hs⟩
  left_inv G := by
    obtain ⟨G, hG⟩ := G
    apply Subtype.ext
    ext x y
    show (∃ B : π.parts, ∃ (hx : x ∈ B.1) (hy : y ∈ B.1), G.Adj x y) ↔ G.Adj x y
    constructor
    · rintro ⟨_, _, _, h⟩; exact h
    · intro h
      have hB : π.part x ∈ π.parts := π.part_mem.mpr (Finset.mem_univ x)
      refine ⟨⟨π.part x, hB⟩, π.mem_part_self.mpr (Finset.mem_univ x), ?_, h⟩
      show y ∈ π.part x
      rw [← hG, ef_mem_comp]; exact h.reachable
  right_inv Hs := by
    funext B
    apply Subtype.ext
    ext x y
    show (∃ B' : π.parts, ∃ (hx : x.1 ∈ B'.1) (hy : y.1 ∈ B'.1), (Hs B').1.Adj ⟨x, hx⟩ ⟨y, hy⟩) ↔
      (Hs B).1.Adj x y
    constructor
    · rintro ⟨B', hx, hy, h⟩
      have : B' = B := Subtype.ext (π.eq_of_mem_parts B'.2 B.2 hx x.2)
      subst this
      exact h
    · intro h; exact ⟨B, x.2, y.2, h⟩

theorem ef_card_graph_structures (n : ℕ) :
    Nat.card (Structures (fun j => Nat.card {G : SimpleGraph (Fin j) // G.Connected}) n) =
      2 ^ (n * (n - 1) / 2) := by
  rw [← Nat.choose_two_right, ← Fintype.card_fin n, ← ef_card_graphs, Fintype.card_fin,
    Nat.card_congr ((Equiv.sigmaFiberEquiv (ef_comp (V := Fin n))).symm.trans
      (Equiv.sigmaCongrRight ef_fiberEquiv)), Nat.card_sigma, Nat.card_sigma]
  apply Finset.sum_congr rfl
  intro π _
  rw [Nat.card_pi, Nat.card_pi]
  apply Finset.prod_congr rfl
  intro B _
  rw [ef_card_conn, Nat.card_eq_fintype_card, Fintype.card_fin]

#print axioms egfSeq_zero
#print axioms egfSeq_succ
#print axioms ef_F_empty
#print axioms ef_F_insert
#print axioms ef_F_eq
#print axioms ef_card_structures
#print axioms ef_ode_unique
#print axioms ef_deriv_exp_subst
#print axioms ef_cc_exp_subst
#print axioms ef_logOf_exp_subst
#print axioms ef_egf_eq
#print axioms ef_invol_iff
#print axioms ef_invol_fiber
#print axioms ef_card_cycleType_two
#print axioms ef_invol_count
#print axioms ef_exp_invol
#print axioms ef_card_graphs
#print axioms ef_card_conn
#print axioms ef_mem_comp
#print axioms ef_fp_ext
#print axioms ef_comp_eq_iff
#print axioms ef_lift
#print axioms ef_comp_conn
#print axioms ef_glue_comp
#print axioms ef_card_graph_structures

/-- The exponential formula. Let `c j` count the connected pieces on `j` given labels, with
series `C(x) = ∑ c_j x^j / j!`, and let `a_n` count the whole structures on `n` labels, with
series `A(x) = ∑ a_n x^n / n!`. Then `A(x) = e^{C(x)}`, and the logarithm turns it back:
`C(x) = ln A(x) = (A - 1) - (A - 1)^2/2 + (A - 1)^3/3 - ⋯`. -/
theorem exponential_formula (c : ℕ → ℕ) :
    structuresSeries c = (exp ℚ).subst (piecesSeries c) ∧
      logOf (structuresSeries c) = piecesSeries c := by
  have hC : constantCoeff (piecesSeries c) = 0 := by
    simp [← coeff_zero_eq_constantCoeff_apply]
  have h1 : structuresSeries c = (exp ℚ).subst (piecesSeries c) := by
    rw [← ef_egf_eq]
    ext n
    rw [coeff_mk, coeff_mk, ef_card_structures]
  exact ⟨h1, by rw [h1, ef_logOf_exp_subst _ hC]⟩

/-- Involutions (shuffles that undo themselves: every label stays put or swaps with one partner)
have exponential generating function `e^(x + x^2/2)`. -/
theorem involutions_egf :
    PowerSeries.mk (fun n => (Fintype.card {σ : Equiv.Perm (Fin n) // σ * σ = 1} : ℚ) / n !) =
      (exp ℚ).subst (X + (2⁻¹ : ℚ) • X ^ 2 : PowerSeries ℚ) := by
  rw [ef_exp_invol]
  ext n
  rw [coeff_mk, ef_invol_count, coeff_mul]
  apply Finset.sum_congr rfl
  intro p _
  rw [coeff_exp, coeff_mk]
  simp

/-- Running the formula backwards on graphs: the logarithm of `∑ 2^(n(n-1)/2) x^n / n!`,
the series of all labelled graphs, is the series of the connected labelled graphs. -/
theorem connected_graphs_egf :
    PowerSeries.mk (fun n => (Nat.card {G : SimpleGraph (Fin n) // G.Connected} : ℚ) / n !) =
      logOf (PowerSeries.mk fun n => ((2 : ℚ) ^ (n * (n - 1) / 2)) / n !) := by
  have hS : structuresSeries (fun j => Nat.card {G : SimpleGraph (Fin j) // G.Connected}) =
      PowerSeries.mk fun n => ((2 : ℚ) ^ (n * (n - 1) / 2)) / n ! := by
    ext n
    rw [coeff_mk, coeff_mk, ← Nat.card_eq_fintype_card, ef_card_graph_structures]
    push_cast
    rfl
  have hP : piecesSeries (fun j => Nat.card {G : SimpleGraph (Fin j) // G.Connected}) =
      PowerSeries.mk (fun n => (Nat.card {G : SimpleGraph (Fin n) // G.Connected} : ℚ) / n !) := by
    ext n
    rw [coeff_mk, coeff_mk]
    split_ifs with h
    · subst h
      have h0 : Nat.card {G : SimpleGraph (Fin 0) // G.Connected} = 0 := by
        rw [Nat.card_eq_zero]
        left
        exact ⟨fun ⟨_, hG⟩ => hG.nonempty.some.elim0⟩
      rw [h0]
      simp
    · rfl
  rw [← hP, ← hS, (exponential_formula _).2]

-- involutions (self-undoing shuffles) on 0 to 5 letters: 1, 1, 2, 4, 10, 26
example : Fintype.card {σ : Equiv.Perm (Fin 0) // σ * σ = 1} = 1 ∧
    Fintype.card {σ : Equiv.Perm (Fin 1) // σ * σ = 1} = 1 ∧
    Fintype.card {σ : Equiv.Perm (Fin 2) // σ * σ = 1} = 2 ∧
    Fintype.card {σ : Equiv.Perm (Fin 3) // σ * σ = 1} = 4 ∧
    Fintype.card {σ : Equiv.Perm (Fin 4) // σ * σ = 1} = 10 ∧
    Fintype.card {σ : Equiv.Perm (Fin 5) // σ * σ = 1} = 26 := by decide
-- Five letters by number of pieces: rows of 3, 4, 5 pieces are 90, 240, 120; divided by k!
example : 90 / 3 ! = 15 ∧ 240 / 4 ! = 10 ∧ 120 / 5 ! = 1 := by decide
-- 1 + 10 + 15 = 26 plugboard settings on five letters
example : 1 + 10 + 15 = 26 := by norm_num
-- the x^5 coefficient of e^(x + x^2/2) is 13/60, and 5! times it is 26
example : (5 ! : ℚ) * (13 / 60) = 26 := by norm_num [Nat.factorial]
-- the newest-letter recurrence a_n = a_(n-1) + (n-1) a_(n-2) gives 1, 1, 2, 4, 10, 26
example : 1 + 0 * 1 = 1 ∧ 1 + 1 * 1 = 2 ∧ 2 + 2 * 1 = 4 ∧ 4 + 3 * 2 = 10 ∧ 10 + 4 * 4 = 26 := by
  norm_num
-- four computers: 2^6 = 64 networks, and 64 - (1·1·8 + 3·1·2 + 3·4·1) = 38 connected
example : 2 ^ (4 * 3 / 2) = 64 ∧ 64 - (1 * 1 * 8 + 3 * 1 * 2 + 3 * 4 * 1) = 38 := by norm_num
-- 26-letter plugboard with exactly 10 cables: 26! / (6! · 10! · 2^10) settings
example : 26 ! / (6 ! * 10 ! * 2 ^ 10) = 150738274937250 := by norm_num [Nat.factorial]

#print axioms exponential_formula
#print axioms involutions_egf
#print axioms connected_graphs_egf
