-- Regular expressions: a set of strings over a finite alphabet has a pattern exactly when a finite machine accepts it.
import Mathlib.Computability.RegularExpressions
import Mathlib.Computability.DFA
import Mathlib.Computability.MyhillNerode
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Abel
import Mathlib.Data.Set.Finite.Powerset
import Mathlib.Basic.Finite.Prod

open Computability

namespace KleeneProof

theorem mem_finset_sum {α ι : Type} (s : Finset ι) (f : ι → Language α) (w : List α) :
    w ∈ ∑ i ∈ s, f i ↔ ∃ i ∈ s, w ∈ f i := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert i s hi ih =>
    rw [Finset.sum_insert hi, Language.mem_add, ih]
    simp

theorem pat_add {α : Type} {L M : Language α} (h1 : ∃ R : RegularExpression α, R.matches' = L)
    (h2 : ∃ R : RegularExpression α, R.matches' = M) :
    ∃ R : RegularExpression α, R.matches' = L + M := by
  obtain ⟨R, rfl⟩ := h1
  obtain ⟨S, rfl⟩ := h2
  exact ⟨R + S, RegularExpression.matches'_add R S⟩

theorem pat_mul {α : Type} {L M : Language α} (h1 : ∃ R : RegularExpression α, R.matches' = L)
    (h2 : ∃ R : RegularExpression α, R.matches' = M) :
    ∃ R : RegularExpression α, R.matches' = L * M := by
  obtain ⟨R, rfl⟩ := h1
  obtain ⟨S, rfl⟩ := h2
  exact ⟨R * S, RegularExpression.matches'_mul R S⟩

theorem pat_star {α : Type} {L : Language α} (h1 : ∃ R : RegularExpression α, R.matches' = L) :
    ∃ R : RegularExpression α, R.matches' = L∗ := by
  obtain ⟨R, rfl⟩ := h1
  exact ⟨R.star, RegularExpression.matches'_star R⟩

theorem pat_sum {α ι : Type} (s : Finset ι) (f : ι → Language α)
    (h : ∀ i, ∃ R : RegularExpression α, R.matches' = f i) :
    ∃ R : RegularExpression α, R.matches' = ∑ i ∈ s, f i := by
  classical
  induction s using Finset.induction_on with
  | empty => exact ⟨0, by simp⟩
  | insert i s hi ih =>
    rw [Finset.sum_insert hi]
    exact pat_add (h i) ih

theorem sum_split {β ι : Type} [AddCommMonoid β] [Fintype ι] [DecidableEq ι] (f : ι → β)
    (k : ι) : ∑ j, f j = f k + ∑ j : {j : ι // j ≠ k}, f j.1 := by
  rw [← Finset.add_sum_erase _ _ (Finset.mem_univ k),
    Finset.sum_subtype (Finset.univ.erase k) (p := fun j => j ≠ k) (by simp)]

/-- Solving a finite system of language equations by eliminating one unknown at a time. -/
theorem pat_of_system {α : Type} (n : ℕ) : ∀ (ι : Type) [Fintype ι] [DecidableEq ι],
    Fintype.card ι = n →
    ∀ (X : ι → Language α) (A : ι → ι → Language α) (B : ι → Language α),
    (∀ i j, ∃ R : RegularExpression α, R.matches' = A i j) →
    (∀ i, ∃ R : RegularExpression α, R.matches' = B i) →
    (∀ i j, [] ∉ A i j) →
    (∀ i, X i = ∑ j, A i j * X j + B i) →
    ∀ i, ∃ R : RegularExpression α, R.matches' = X i := by
  induction n with
  | zero =>
    intro ι _ _ hc X A B _ _ _ _ i
    have : Nonempty ι := ⟨i⟩
    exact absurd hc Fintype.card_ne_zero
  | succ n ih =>
    intro ι _ _ hc X A B hA hB hε hX i₀
    let k := i₀
    let ι' := {j : ι // j ≠ k}
    have hc' : Fintype.card ι' = n := by
      simp [ι', Fintype.card_subtype_compl, hc]
    have hsplit : ∀ i, X i = A i k * X k + (∑ j : ι', A i j * X j + B i) := by
      intro i
      rw [hX i, sum_split _ k, add_assoc]
    have hk : X k = (A k k)∗ * (∑ j : ι', A k j * X j + B k) :=
      (Language.self_eq_mul_add_iff (hε k k)).mp (hsplit k)
    let A' : ι' → ι' → Language α := fun i j => A i j + A i k * (A k k)∗ * A k j
    let B' : ι' → Language α := fun i => B i + A i k * (A k k)∗ * B k
    have hX' : ∀ i : ι', X i = ∑ j, A' i j * X j + B' i := by
      intro i
      rw [hsplit i]
      conv_lhs => rw [hk]
      simp only [A', B', add_mul, Finset.sum_add_distrib, mul_add, Finset.mul_sum, mul_assoc]
      abel
    have hA' : ∀ i j, ∃ R : RegularExpression α, R.matches' = A' i j := fun i j =>
      pat_add (hA i j) (pat_mul (pat_mul (hA i k) (pat_star (hA k k))) (hA k j))
    have hB' : ∀ i, ∃ R : RegularExpression α, R.matches' = B' i := fun i =>
      pat_add (hB i) (pat_mul (pat_mul (hA i k) (pat_star (hA k k))) (hB k))
    have hε' : ∀ i j, [] ∉ A' i j := by
      intro i j h
      rcases (Language.mem_add _ _ _).mp h with h | h
      · exact hε i j h
      · obtain ⟨u, hu, v, -, huv⟩ := Language.mem_mul.mp h
        obtain ⟨u', hu', v', -, huv'⟩ := Language.mem_mul.mp hu
        rw [List.append_eq_nil_iff] at huv
        rw [huv.1, List.append_eq_nil_iff] at huv'
        exact hε i k (huv'.1 ▸ hu')
    have h' := ih ι' hc' (fun i => X i) A' B' hA' hB' hε' hX'
    show ∃ R : RegularExpression α, R.matches' = X k
    rw [hk]
    exact pat_mul (pat_star (hA k k)) (pat_add (pat_sum _ _ fun j => pat_mul (hA k j) (h' j)) (hB k))


theorem pat_of_isRegular {α : Type} [Fintype α] (L : Language α) (h : L.IsRegular) :
    ∃ R : RegularExpression α, R.matches' = L := by
  classical
  obtain ⟨σ, _, M, rfl⟩ := h
  let X : σ → Language α := fun q => {w | M.evalFrom q w ∈ M.accept}
  let A : σ → σ → Language α := fun p q =>
    ∑ a ∈ Finset.univ.filter (fun a => M.step p a = q), ({[a]} : Language α)
  let B : σ → Language α := fun p => if p ∈ M.accept then 1 else 0
  have memA : ∀ p q u, u ∈ A p q ↔ ∃ a, M.step p a = q ∧ u = [a] := by
    intro p q u
    simp only [A, mem_finset_sum, Finset.mem_filter, Finset.mem_univ, true_and]
    rfl
  have hA : ∀ p q, ∃ R : RegularExpression α, R.matches' = A p q := fun p q =>
    pat_sum _ _ fun a => ⟨RegularExpression.char a, RegularExpression.matches'_char a⟩
  have hB : ∀ p, ∃ R : RegularExpression α, R.matches' = B p := by
    intro p
    by_cases hp : p ∈ M.accept
    · exact ⟨1, by simp [B, hp]⟩
    · exact ⟨0, by simp [B, hp]⟩
  have hε : ∀ p q, [] ∉ A p q := by
    intro p q h
    obtain ⟨a, -, ha⟩ := (memA p q []).mp h
    exact absurd ha (by simp)
  have hX : ∀ p, X p = ∑ q, A p q * X q + B p := by
    intro p
    ext w
    rw [Language.mem_add, mem_finset_sum]
    simp only [Finset.mem_univ, true_and, Language.mem_mul, memA]
    cases w with
    | nil =>
      constructor
      · intro hw
        right
        have hp : p ∈ M.accept := hw
        simp [B, hp, Language.mem_one]
      · rintro (⟨q, u, ⟨a, -, rfl⟩, v, -, huv⟩ | hw)
        · simp at huv
        · by_cases hp : p ∈ M.accept
          · exact hp
          · simp [B, hp] at hw
    | cons a w =>
      constructor
      · intro hw
        left
        exact ⟨M.step p a, [a], ⟨a, rfl, rfl⟩, w, hw, rfl⟩
      · rintro (⟨q, u, ⟨b, hb, rfl⟩, v, hv, huv⟩ | hw)
        · simp only [List.singleton_append, List.cons.injEq] at huv
          obtain ⟨rfl, rfl⟩ := huv
          show M.evalFrom (M.step p b) v ∈ M.accept
          rw [hb]
          exact hv
        · by_cases hp : p ∈ M.accept
          · simp [B, hp, Language.mem_one] at hw
          · simp [B, hp] at hw
  exact pat_of_system _ σ rfl X A B hA hB hε hX M.start

theorem fin_zero {α : Type} : (Set.range (0 : Language α).leftQuotient).Finite := by
  apply (Set.finite_singleton (0 : Language α)).subset
  rintro _ ⟨u, rfl⟩
  ext w
  simp [Language.mem_leftQuotient]

theorem fin_one {α : Type} : (Set.range (1 : Language α).leftQuotient).Finite := by
  apply ((Set.finite_singleton (0 : Language α)).insert 1).subset
  rintro _ ⟨u, rfl⟩
  cases u with
  | nil => left; rfl
  | cons a u =>
    right
    ext w
    simp [Language.mem_leftQuotient, Language.mem_one]

theorem fin_char {α : Type} (a : α) :
    (Set.range ({[a]} : Language α).leftQuotient).Finite := by
  apply ((((Set.finite_singleton (0 : Language α)).insert 1)).insert {[a]}).subset
  rintro _ ⟨u, rfl⟩
  by_cases h0 : u = []
  · subst h0; left; rfl
  by_cases h1 : u = [a]
  · subst h1
    right; left
    ext w
    rw [Language.mem_leftQuotient, Language.mem_one]
    show [a] ++ w ∈ ({[a]} : Set (List α)) ↔ _
    simp
  · right; right
    ext w
    simp only [Language.mem_leftQuotient]
    constructor
    · intro h
      rcases List.append_eq_singleton_iff.mp h with h | h
      · exact absurd h.1 h0
      · exact absurd h.1 h1
    · intro h
      exact absurd h (Language.notMem_zero _)

theorem fin_add {α : Type} {L M : Language α} (h1 : (Set.range L.leftQuotient).Finite)
    (h2 : (Set.range M.leftQuotient).Finite) : (Set.range (L + M).leftQuotient).Finite := by
  apply (h1.image2 (· + ·) h2).subset
  rintro _ ⟨u, rfl⟩
  exact ⟨_, ⟨u, rfl⟩, _, ⟨u, rfl⟩, rfl⟩

theorem fin_mul {α : Type} {L M : Language α} (h1 : (Set.range L.leftQuotient).Finite)
    (h2 : (Set.range M.leftQuotient).Finite) : (Set.range (L * M).leftQuotient).Finite := by
  apply (h1.image2 (fun (q : Language α) (T : Set (Language α)) => q * M + ⨆ t : T, t.1)
    h2.finite_subsets).subset
  rintro _ ⟨u, rfl⟩
  refine ⟨L.leftQuotient u, ⟨u, rfl⟩,
    {t | ∃ v, (∃ p ∈ L, p ++ v = u) ∧ t = M.leftQuotient v}, ?_, ?_⟩
  · intro t ht
    obtain ⟨v, -, rfl⟩ := ht
    exact ⟨v, rfl⟩
  · ext w
    rw [Language.mem_add, Language.mem_iSup, Language.mem_leftQuotient, Language.mem_mul,
      Language.mem_mul]
    constructor
    · rintro (⟨t, ht, y, hy, rfl⟩ | ⟨⟨_, v, ⟨p, hp, rfl⟩, rfl⟩, hw⟩)
      · exact ⟨u ++ t, ht, y, hy, by simp⟩
      · exact ⟨p, hp, v ++ w, hw, by simp⟩
    · rintro ⟨x, hx, y, hy, hxy⟩
      rcases List.append_eq_append_iff.mp hxy with ⟨a', rfl, rfl⟩ | ⟨c', rfl, rfl⟩
      · exact Or.inr ⟨⟨_, a', ⟨x, hx, rfl⟩, rfl⟩, hy⟩
      · exact Or.inl ⟨c', hx, y, hy, rfl⟩

theorem append_mem_kstar {α : Type} {L : Language α} {x y : List α} (hx : x ∈ L∗)
    (hy : y ∈ L∗) : x ++ y ∈ L∗ := by
  obtain ⟨X, rfl, hX⟩ := Language.mem_kstar.mp hx
  obtain ⟨Y, rfl, hY⟩ := Language.mem_kstar.mp hy
  refine Language.mem_kstar.mpr ⟨X ++ Y, by simp, ?_⟩
  intro z hz
  rcases List.mem_append.mp hz with h | h
  exacts [hX z h, hY z h]

theorem mem_kstar_of_mem {α : Type} {L : Language α} {x : List α} (hx : x ∈ L) : x ∈ L∗ :=
  Language.mem_kstar.mpr ⟨[x], by simp, by simpa using hx⟩

theorem star_split {α : Type} (L : Language α) : ∀ ys : List (List α), (∀ y ∈ ys, y ∈ L) →
    ∀ u w : List α, u ++ w = ys.flatten → u ≠ [] →
    ∃ p v t s, p ∈ L∗ ∧ p ++ v = u ∧ v ++ t ∈ L ∧ s ∈ L∗ ∧ w = t ++ s
  | [], _, u, w, h, hu => by
    simp only [List.flatten_nil, List.append_eq_nil_iff] at h
    exact absurd h.1 hu
  | y :: ys, hy, u, w, h, hu => by
    have hy0 : y ∈ L := hy y (by simp)
    have hys : ys.flatten ∈ L∗ :=
      Language.join_mem_kstar fun z hz => hy z (List.mem_cons_of_mem _ hz)
    rw [List.flatten_cons] at h
    rcases List.append_eq_append_iff.mp h with ⟨a', rfl, rfl⟩ | ⟨c', rfl, h2⟩
    · exact ⟨[], u, a', ys.flatten, Language.nil_mem_kstar _, rfl, hy0, hys, rfl⟩
    · by_cases hc : c' = []
      · subst hc
        simp only [List.nil_append] at h2
        exact ⟨[], y, [], ys.flatten, Language.nil_mem_kstar _, by simp, by simpa using hy0,
          hys, by simp [h2]⟩
      · obtain ⟨p, v, t, s, hp, hpv, hvt, hs, hw⟩ :=
          star_split L ys (fun z hz => hy z (List.mem_cons_of_mem _ hz)) c' w h2.symm hc
        exact ⟨y ++ p, v, t, s, append_mem_kstar (mem_kstar_of_mem hy0) hp, by simp [hpv],
          hvt, hs, hw⟩

theorem fin_star {α : Type} {L : Language α} (h1 : (Set.range L.leftQuotient).Finite) :
    (Set.range (L∗).leftQuotient).Finite := by
  apply ((h1.finite_subsets.image
    (fun (T : Set (Language α)) => ⨆ t : T, t.1 * L∗)).insert (L∗)).subset
  rintro _ ⟨u, rfl⟩
  by_cases hu : u = []
  · subst hu; left; rfl
  right
  refine ⟨{t | ∃ v, (∃ p ∈ L∗, p ++ v = u) ∧ t = L.leftQuotient v}, ?_, ?_⟩
  · intro t ht
    obtain ⟨v, -, rfl⟩ := ht
    exact ⟨v, rfl⟩
  · ext w
    rw [Language.mem_iSup, Language.mem_leftQuotient]
    constructor
    · rintro ⟨⟨_, v, ⟨p, hp, rfl⟩, rfl⟩, hw⟩
      obtain ⟨t, ht, s, hs, rfl⟩ := Language.mem_mul.mp hw
      have : p ++ v ++ (t ++ s) = p ++ ((v ++ t) ++ s) := by simp
      rw [this]
      exact append_mem_kstar hp (append_mem_kstar (mem_kstar_of_mem ht) hs)
    · intro h
      obtain ⟨ys, hys, hy⟩ := Language.mem_kstar.mp h
      obtain ⟨p, v, t, s, hp, hpv, hvt, hs, rfl⟩ := star_split L ys hy u w hys hu
      exact ⟨⟨_, v, ⟨p, hp, hpv⟩, rfl⟩, Language.mem_mul.mpr ⟨t, hvt, s, hs, rfl⟩⟩

theorem fin_of_pattern {α : Type} (R : RegularExpression α) :
    (Set.range R.matches'.leftQuotient).Finite := by
  induction R with
  | zero => exact fin_zero
  | epsilon => exact fin_one
  | char a => exact fin_char a
  | plus P Q hP hQ => exact fin_add hP hQ
  | comp P Q hP hQ => exact fin_mul hP hQ
  | star P hP => exact fin_star hP

theorem replicate_halves {α : Type} {a b : α} (hab : a ≠ b) (m n : ℕ) (w : List α)
    (h : (List.replicate m a ++ [b]) ++ (List.replicate n a ++ [b]) = w ++ w) : m = n := by
  classical
  have hx : b ∉ List.replicate m a := by simp [List.mem_replicate, Ne.symm hab]
  have hy : b ∉ List.replicate n a := by simp [List.mem_replicate, Ne.symm hab]
  rcases List.eq_nil_or_concat w with rfl | ⟨w', c, rfl⟩
  · simp at h
  simp only [List.concat_eq_append] at h
  have h' : (List.replicate m a ++ b :: List.replicate n a) ++ [b] =
      (w' ++ c :: w') ++ [c] := by simpa using h
  obtain ⟨h3, h4⟩ := List.append_inj' h' rfl
  simp only [List.cons.injEq, and_true] at h4
  subst h4
  have hcount := congrArg (List.count b) h3
  simp only [List.count_append, List.count_cons_self, List.count_eq_zero.mpr hx,
    List.count_eq_zero.mpr hy] at hcount
  have hw' : b ∉ w' := List.count_eq_zero.mp (by omega)
  rcases List.append_eq_append_iff.mp h3 with ⟨as, h5, h6⟩ | ⟨bs, h5, h6⟩
  · cases as with
    | nil =>
      simp only [List.append_nil, List.nil_append, List.cons.injEq, true_and] at h5 h6
      have := congrArg List.length (h5.symm.trans h6.symm)
      simpa using this
    | cons c as =>
      simp only [List.cons_append, List.cons.injEq] at h6
      exact absurd (h5 ▸ List.mem_append_right _ (h6.1 ▸ List.mem_cons_self)) hw'
  · cases bs with
    | nil =>
      simp only [List.append_nil, List.nil_append, List.cons.injEq, true_and] at h5 h6
      have := congrArg List.length (h5.trans h6)
      simpa using this
    | cons c bs =>
      simp only [List.cons_append, List.cons.injEq] at h6
      exact absurd (h5 ▸ List.mem_append_right _ (h6.1 ▸ List.mem_cons_self)) hx

#print axioms mem_finset_sum
#print axioms pat_add
#print axioms pat_mul
#print axioms pat_star
#print axioms pat_sum
#print axioms sum_split
#print axioms pat_of_system
#print axioms pat_of_isRegular
#print axioms fin_zero
#print axioms fin_one
#print axioms fin_char
#print axioms fin_add
#print axioms fin_mul
#print axioms append_mem_kstar
#print axioms mem_kstar_of_mem
#print axioms star_split
#print axioms fin_star
#print axioms fin_of_pattern
#print axioms replicate_halves

end KleeneProof

/-- Kleene's theorem. Over a finite alphabet, a set of strings is named by some pattern
(built from symbols, the empty string, either, joining and star) exactly when some finite
automaton with finitely many states accepts it: patterns and machines describe the same sets. -/
theorem pattern_iff_finite_automaton {α : Type} [Fintype α] (L : Language α) :
    (∃ R : RegularExpression α, R.matches' = L) ↔ L.IsRegular := by
  constructor
  · rintro ⟨R, rfl⟩
    exact Language.IsRegular.of_finite_range_leftQuotient (KleeneProof.fin_of_pattern R)
  · exact KleeneProof.pat_of_isRegular L

/-- A backreference is not a pattern. Over an alphabet with two different symbols, the set of
strings made of two equal halves, `w` then `w` again, is accepted by no finite automaton. -/
theorem two_equal_halves_not_regular {α : Type} (a b : α) (hab : a ≠ b) :
    ¬ Language.IsRegular ({x | ∃ w : List α, x = w ++ w} : Language α) := by
  intro h
  replace h := Language.isRegular_iff_finite_range_leftQuotient.mp h
  have hinj : Function.Injective (fun n : ℕ =>
      Language.leftQuotient {x | ∃ w : List α, x = w ++ w} (List.replicate n a ++ [b])) := by
    intro m n hmn
    have hmem : (List.replicate n a ++ [b]) ∈
        Language.leftQuotient {x | ∃ w : List α, x = w ++ w} (List.replicate n a ++ [b]) :=
      ⟨_, rfl⟩
    have hmem' : (List.replicate n a ++ [b]) ∈
        Language.leftQuotient {x | ∃ w : List α, x = w ++ w} (List.replicate m a ++ [b]) :=
      cast (congrArg (fun L : Language α => List.replicate n a ++ [b] ∈ L) hmn).symm hmem
    obtain ⟨w, hw⟩ := hmem'
    exact KleeneProof.replicate_halves hab m n w hw
  apply Set.infinite_range_of_injective hinj
  apply h.subset
  rintro _ ⟨n, rfl⟩
  exact ⟨_, rfl⟩

/-- Reading back gives an equal pattern, not the same text. The pattern `S | R R* S` (go straight
to `S`, or take one `R`, then more, then `S`) names the same strings as `R* S`; with `R` a space
and `S` the digit D, this is `(D|__*D)` against `_*D`. -/
theorem read_back_same_strings {α : Type} (R S : RegularExpression α) :
    (S + R * R.star * S).matches' = (R.star * S).matches' := by
  simp only [RegularExpression.matches'_add, RegularExpression.matches'_mul,
    RegularExpression.matches'_star]
  conv_rhs => rw [← Language.one_add_self_mul_kstar_eq_kstar]
  rw [add_mul, one_mul]

/-! The card's postcode pattern `L(L|ε)D(L|D|ε)_*DLL` over the symbols L (letter), D (digit)
and `_` (space). -/

inductive Sym
  | L
  | D
  | sp
  deriving DecidableEq

open Sym RegularExpression

/-- The postcode pattern `L(L|ε)D(L|D|ε)_*DLL`. -/
def post : RegularExpression Sym :=
  char L * (char L + 1) * char D * (char L + char D + 1) * (char sp).star *
    char D * char L * char L

/-- Mistake 1: one space in place of `_*`. -/
def oneSpace : RegularExpression Sym :=
  char L * (char L + 1) * char D * (char L + char D + 1) * char sp *
    char D * char L * char L

-- SW1A 1AA reads LLDL_DLL: accept.
example : [L, L, D, L, sp, D, L, L] ∈ post.matches' := by decide
-- M1 1AE reads LD_DLL: accept.
example : [L, D, sp, D, L, L] ∈ post.matches' := by decide
-- SW1A1AA reads LLDLDLL: accept.
example : [L, L, D, L, D, L, L] ∈ post.matches' := by decide
-- SW1A 1A reads LLDL_DL: reject.
example : [L, L, D, L, sp, D, L] ∉ post.matches' := by decide
-- Mistake 1: one space in place of `_*` rejects SW1A1AA.
example : [L, L, D, L, D, L, L] ∉ oneSpace.matches' := by decide

/-- Every string of L, D and `_` of length exactly `n`. -/
def words : ℕ → List (List Sym)
  | 0 => [[]]
  | n + 1 => (words n).flatMap fun w => [L :: w, D :: w, sp :: w]

-- There are 29,524 strings of L, D and `_` up to length 9.
example : ((List.range 10).flatMap words).length = 29524 := by decide +kernel
-- Exactly 23 of them match the postcode pattern.
example : (((List.range 10).flatMap words).filter fun w => post.rmatch w).length = 23 := by
  decide +kernel

#print axioms pattern_iff_finite_automaton
#print axioms two_equal_halves_not_regular
#print axioms read_back_same_strings
