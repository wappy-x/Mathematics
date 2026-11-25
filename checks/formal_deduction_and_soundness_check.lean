-- Formal proofs and soundness: every formula the card's seven natural-deduction rules derive from premises Γ is true in every non-empty structure, under every assignment, where all of Γ is true.
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Powerset
import Mathlib.Logic.Function.Basic
import Mathlib.Tactic.NormNum

/-! Mathlib's model theory has formulas and truth (`FirstOrder.Language.BoundedFormula.Realize`)
but no proof calculus, so this file writes out the card's own small logic: terms, formulas built
from atoms by `→`, `∀` and `∃`, structures with a non-empty domain, truth, capture-checking
substitution, and the seven rules of the card's checker. Variables, predicates and constants are
named by whole numbers: in the examples `x` is variable 0, `y` is variable 1, `P` is predicate 0,
`Q` is predicate 1 and `a` is constant 0. -/

namespace FormalDeduction

universe u

/-! ### Terms and formulas -/

/-- A term names an object: a variable or a constant. -/
inductive Term
  | var (x : ℕ)
  | const (c : ℕ)
  deriving DecidableEq

/-- Formulas: an atom (a predicate applied to terms), "if … then", "for all x" and "there is x". -/
inductive Formula
  | atom (p : ℕ) (ts : List Term)
  | imp (φ ψ : Formula)
  | all (x : ℕ) (φ : Formula)
  | ex (x : ℕ) (φ : Formula)
  deriving DecidableEq

namespace Formula

/-- The free names of a formula, as the card's `free`: its free variables and every constant
in it. A variable `x` is free in `φ` exactly when `Term.var x ∈ φ.free`. -/
def free : Formula → Finset Term
  | atom _ ts => ts.toFinset
  | imp φ ψ => φ.free ∪ ψ.free
  | all x φ => φ.free.erase (Term.var x)
  | ex x φ => φ.free.erase (Term.var x)

/-- Put the term `t` in for the variable `x` in one term. -/
def substTerm (x : ℕ) (t : Term) : Term → Term
  | Term.var y => if y = x then t else Term.var y
  | Term.const c => Term.const c

/-- `φ[t/x]`: `φ` with `t` put in for every free `x` (a quantifier on `x` stops it). -/
def subst (x : ℕ) (t : Term) : Formula → Formula
  | atom p ts => atom p (ts.map (substTerm x t))
  | imp φ ψ => imp (φ.subst x t) (ψ.subst x t)
  | all y φ => if y = x then all y φ else all y (φ.subst x t)
  | ex y φ => if y = x then ex y φ else ex y (φ.subst x t)

/-- `t` is free for `x` in `φ`: putting `t` in for `x` lets no quantifier capture `t`'s variable.
Under a quantifier on `y`, either `x` is not free there (nothing is put in), or `t` is not the
variable `y` and `t` is free for `x` inside. -/
def FreeFor (t : Term) (x : ℕ) : Formula → Prop
  | atom _ _ => True
  | imp φ ψ => FreeFor t x φ ∧ FreeFor t x ψ
  | all y φ => y = x ∨ Term.var x ∉ φ.free ∨ (t ≠ Term.var y ∧ FreeFor t x φ)
  | ex y φ => y = x ∨ Term.var x ∉ φ.free ∨ (t ≠ Term.var y ∧ FreeFor t x φ)

end Formula

open Formula

/-! ### Structures and truth -/

/-- A structure on the domain `D`: a meaning for each predicate (which lists of objects it holds
of) and an object for each constant. The domain is required to be non-empty where truth is used. -/
structure Model (D : Type u) where
  rel : ℕ → List D → Prop
  const : ℕ → D

/-- The object a term names, under the assignment `s` of values to variables. -/
def Term.eval {D : Type u} (M : Model D) (s : ℕ → D) : Term → D
  | Term.var x => s x
  | Term.const c => M.const c

/-- `M ⊨ φ[s]`: truth, defined part by part as on the card. -/
def Model.sat {D : Type u} (M : Model D) : (ℕ → D) → Formula → Prop
  | s, atom p ts => M.rel p (ts.map (Term.eval M s))
  | s, imp φ ψ => M.sat s φ → M.sat s ψ
  | s, all x φ => ∀ d : D, M.sat (Function.update s x d) φ
  | s, ex x φ => ∃ d : D, M.sat (Function.update s x d) φ

/-- `Γ ⊨ φ`: every structure with a non-empty domain and every assignment that make all of `Γ`
true make `φ` true. -/
def Entails (Γ : Finset Formula) (φ : Formula) : Prop :=
  ∀ (D : Type u) [Nonempty D] (M : Model D) (s : ℕ → D),
    (∀ γ ∈ Γ, M.sat s γ) → M.sat s φ

/-! ### The seven rules -/

/-- `Derivation Δ φ`: a derivation, built by the card's seven rules, ends in `φ` with open
assumptions exactly `Δ`. Every substitution is required to be capture-free, and the two rules
that introduce a name require it to be new. -/
inductive Derivation : Finset Formula → Formula → Prop
  /-- assume: `φ`, with `φ` open. -/
  | assume (φ : Formula) : Derivation {φ} φ
  /-- →E: from `φ → ψ` and `φ`, conclude `ψ`. -/
  | impE {Δ₁ Δ₂ : Finset Formula} {φ ψ : Formula} :
      Derivation Δ₁ (imp φ ψ) → Derivation Δ₂ φ → Derivation (Δ₁ ∪ Δ₂) ψ
  /-- →I: from `ψ`, conclude `φ → ψ` and close the assumption `φ`. -/
  | impI {Δ : Finset Formula} {ψ : Formula} (φ : Formula) :
      Derivation Δ ψ → Derivation (Δ.erase φ) (imp φ ψ)
  /-- ∀E: from `∀x φ`, conclude `φ[t/x]`, with `t` free for `x`. -/
  | allE {Δ : Finset Formula} {x : ℕ} {φ : Formula} (t : Term) :
      Derivation Δ (all x φ) → FreeFor t x φ → Derivation Δ (φ.subst x t)
  /-- ∀I: from `φ`, conclude `∀x φ`, with `x` free in no open assumption. -/
  | allI {Δ : Finset Formula} {φ : Formula} (x : ℕ) :
      Derivation Δ φ → (∀ h ∈ Δ, Term.var x ∉ h.free) → Derivation Δ (all x φ)
  /-- ∃I: from `φ[t/x]`, conclude `∃x φ`, with `t` free for `x`. -/
  | exI {Δ : Finset Formula} {φ : Formula} (x : ℕ) (t : Term) :
      Derivation Δ (φ.subst x t) → FreeFor t x φ → Derivation Δ (ex x φ)
  /-- ∃E: from `∃x φ`, and `ψ` derived with `φ[w/x]` open, conclude `ψ` and close `φ[w/x]`.
  The witness name `w` (a variable or a constant) is new: not in `∃x φ`, not in `ψ`, and not in
  the other open assumptions; and `w` is free for `x` in `φ`. -/
  | exE {Δ₁ Δ₂ : Finset Formula} {x : ℕ} {φ ψ : Formula} (w : Term) :
      Derivation Δ₁ (ex x φ) → Derivation Δ₂ ψ → FreeFor w x φ →
      w ∉ (ex x φ).free → w ∉ ψ.free → (∀ h ∈ Δ₂.erase (φ.subst x w), w ∉ h.free) →
      Derivation (Δ₁ ∪ Δ₂.erase (φ.subst x w)) ψ

/-- `Γ ⊢ φ`: some derivation ends in `φ` with all its open assumptions in `Γ`. -/
def Provable (Γ : Finset Formula) (φ : Formula) : Prop :=
  ∃ Δ, Δ ⊆ Γ ∧ Derivation Δ φ

/-! ### Helper lemmas for soundness -/

/-- Two structures with the same predicates, and two assignments, that give every free name of
`φ` the same object make `φ` equally true. -/
theorem sat_congr {D : Type u} (M M' : Model D) (hrel : M.rel = M'.rel) :
    ∀ (φ : Formula) (s s' : ℕ → D),
      (∀ τ ∈ φ.free, Term.eval M s τ = Term.eval M' s' τ) → (M.sat s φ ↔ M'.sat s' φ) := by
  intro φ
  induction φ with
  | atom p ts =>
    intro s s' h
    simp only [Model.sat]
    have : ts.map (Term.eval M s) = ts.map (Term.eval M' s') := by
      apply List.map_congr_left
      intro τ hτ
      exact h τ (by simpa [Formula.free] using hτ)
    rw [this, hrel]
  | imp φ ψ ihφ ihψ =>
    intro s s' h
    simp only [Model.sat]
    rw [ihφ s s' (fun τ hτ => h τ (by simp [Formula.free, hτ])),
      ihψ s s' (fun τ hτ => h τ (by simp [Formula.free, hτ]))]
  | all x φ ih =>
    intro s s' h
    simp only [Model.sat]
    refine forall_congr' fun d => ih _ _ fun τ hτ => ?_
    by_cases hx : τ = Term.var x
    · subst hx; simp [Term.eval]
    · have := h τ (by simp [Formula.free, hx, hτ])
      cases τ with
      | var y =>
        have hy : y ≠ x := fun e => hx (by rw [e])
        simpa [Term.eval, Function.update_of_ne hy] using this
      | const c => simpa [Term.eval] using this
  | ex x φ ih =>
    intro s s' h
    simp only [Model.sat]
    refine exists_congr fun d => ih _ _ fun τ hτ => ?_
    by_cases hx : τ = Term.var x
    · subst hx; simp [Term.eval]
    · have := h τ (by simp [Formula.free, hx, hτ])
      cases τ with
      | var y =>
        have hy : y ≠ x := fun e => hx (by rw [e])
        simpa [Term.eval, Function.update_of_ne hy] using this
      | const c => simpa [Term.eval] using this

/-- Putting a term in for a variable that is not free changes nothing. -/
theorem subst_of_not_free (x : ℕ) (t : Term) :
    ∀ φ : Formula, Term.var x ∉ φ.free → φ.subst x t = φ := by
  intro φ
  induction φ with
  | atom p ts =>
    intro h
    simp only [Formula.subst]
    congr 1
    conv_rhs => rw [← List.map_id ts]
    apply List.map_congr_left
    intro τ hτ
    cases τ with
    | var y =>
      have : y ≠ x := by
        rintro rfl; exact h (by simpa [Formula.free] using hτ)
      simp [Formula.substTerm, this]
    | const c => simp [Formula.substTerm]
  | imp φ ψ ihφ ihψ =>
    intro h
    simp only [Formula.free, Finset.mem_union, not_or] at h
    simp [Formula.subst, ihφ h.1, ihψ h.2]
  | all y φ ih =>
    intro h
    by_cases hy : y = x
    · simp [Formula.subst, hy]
    · have : Term.var x ∉ φ.free := by
        intro hm; apply h
        simp only [Formula.free, Finset.mem_erase]
        exact ⟨fun e => hy (by injection e with e; exact e.symm), hm⟩
      simp [Formula.subst, hy, ih this]
  | ex y φ ih =>
    intro h
    by_cases hy : y = x
    · simp [Formula.subst, hy]
    · have : Term.var x ∉ φ.free := by
        intro hm; apply h
        simp only [Formula.free, Finset.mem_erase]
        exact ⟨fun e => hy (by injection e with e; exact e.symm), hm⟩
      simp [Formula.subst, hy, ih this]

/-- Evaluating a term after a substitution is evaluating it under the updated assignment. -/
theorem eval_substTerm {D : Type u} (M : Model D) (s : ℕ → D) (x : ℕ) (t τ : Term) :
    Term.eval M s (Formula.substTerm x t τ) = Term.eval M (Function.update s x (Term.eval M s t)) τ := by
  cases τ with
  | var y =>
    by_cases hy : y = x
    · subst hy; simp [Formula.substTerm, Term.eval]
    · simp [Formula.substTerm, Term.eval, hy]
  | const c => simp [Formula.substTerm, Term.eval]

/-- **Substitution lemma.** When `t` is free for `x` in `φ`, `φ[t/x]` is true under `s` exactly
when `φ` is true with `x` sent to the object `t` names. -/
theorem sat_subst {D : Type u} (M : Model D) (x : ℕ) (t : Term) :
    ∀ (φ : Formula) (s : ℕ → D), FreeFor t x φ →
      (M.sat s (φ.subst x t) ↔ M.sat (Function.update s x (Term.eval M s t)) φ) := by
  intro φ
  induction φ with
  | atom p ts =>
    intro s _
    simp only [Formula.subst, Model.sat, List.map_map]
    have : (Term.eval M s ∘ Formula.substTerm x t) =
        Term.eval M (Function.update s x (Term.eval M s t)) := by
      funext τ; exact eval_substTerm M s x t τ
    rw [this]
  | imp φ ψ ihφ ihψ =>
    intro s h
    simp only [Formula.subst, Model.sat]
    rw [ihφ s h.1, ihψ s h.2]
  | all y φ ih =>
    intro s h
    by_cases hyx : y = x
    · subst hyx
      simp only [Formula.subst, ite_true, Model.sat, Function.update_idem]
    · rcases h with h | h | ⟨ht, h⟩
      · exact absurd h hyx
      · have hnf : Term.var x ∉ (Formula.all y φ).free := by
          simp only [Formula.free, Finset.mem_erase, not_and]
          intro _; exact h
        rw [subst_of_not_free x t _ hnf]
        apply sat_congr M M rfl
        intro τ hτ
        have : τ ≠ Term.var x := fun e => hnf (e ▸ hτ)
        cases τ with
        | var z =>
          have hz : z ≠ x := fun e => this (by rw [e])
          simp [Term.eval, Function.update_of_ne hz]
        | const c => simp [Term.eval]
      · simp only [Formula.subst, hyx, ite_false, Model.sat]
        refine forall_congr' fun d => ?_
        rw [ih _ h]
        have he : Term.eval M (Function.update s y d) t = Term.eval M s t := by
          cases t with
          | var z =>
            have hz : z ≠ y := fun e => ht (by rw [e])
            simp [Term.eval, Function.update_of_ne hz]
          | const c => simp [Term.eval]
        rw [he, Function.update_comm (Ne.symm hyx)]
  | ex y φ ih =>
    intro s h
    by_cases hyx : y = x
    · subst hyx
      simp only [Formula.subst, ite_true, Model.sat, Function.update_idem]
    · rcases h with h | h | ⟨ht, h⟩
      · exact absurd h hyx
      · have hnf : Term.var x ∉ (Formula.ex y φ).free := by
          simp only [Formula.free, Finset.mem_erase, not_and]
          intro _; exact h
        rw [subst_of_not_free x t _ hnf]
        apply sat_congr M M rfl
        intro τ hτ
        have : τ ≠ Term.var x := fun e => hnf (e ▸ hτ)
        cases τ with
        | var z =>
          have hz : z ≠ x := fun e => this (by rw [e])
          simp [Term.eval, Function.update_of_ne hz]
        | const c => simp [Term.eval]
      · simp only [Formula.subst, hyx, ite_false, Model.sat]
        refine exists_congr fun d => ?_
        rw [ih _ h]
        have he : Term.eval M (Function.update s y d) t = Term.eval M s t := by
          cases t with
          | var z =>
            have hz : z ≠ y := fun e => ht (by rw [e])
            simp [Term.eval, Function.update_of_ne hz]
          | const c => simp [Term.eval]
        rw [he, Function.update_comm (Ne.symm hyx)]

/-- A name `w` can be made to name any object `d` by changing only what `w` names: for a variable,
the assignment; for a constant, the structure. Every other term keeps its object. -/
theorem exists_reinterpret {D : Type u} (M : Model D) (s : ℕ → D) (w : Term) (d : D) :
    ∃ (M' : Model D) (s' : ℕ → D), M'.rel = M.rel ∧ Term.eval M' s' w = d ∧
      ∀ τ : Term, τ ≠ w → Term.eval M' s' τ = Term.eval M s τ := by
  cases w with
  | var v =>
    refine ⟨M, Function.update s v d, rfl, by simp [Term.eval], ?_⟩
    intro τ hτ
    cases τ with
    | var z =>
      have hz : z ≠ v := fun e => hτ (by rw [e])
      simp [Term.eval, Function.update_of_ne hz]
    | const c => simp [Term.eval]
  | const c =>
    refine ⟨⟨M.rel, Function.update M.const c d⟩, s, rfl, by simp [Term.eval], ?_⟩
    intro τ hτ
    cases τ with
    | var z => simp [Term.eval]
    | const e =>
      have he : e ≠ c := fun h => hτ (by rw [h])
      simp [Term.eval, Function.update_of_ne he]

/-- Every derivation is sound: its conclusion follows from its open assumptions. -/
theorem derivation_sound {Δ : Finset Formula} {φ : Formula} (h : Derivation Δ φ) :
    Entails.{u} Δ φ := by
  induction h with
  | assume φ =>
    intro D _ M s hΓ
    exact hΓ φ (Finset.mem_singleton_self φ)
  | impE _ _ ih₁ ih₂ =>
    intro D _ M s hΓ
    exact ih₁ D M s (fun γ hγ => hΓ γ (Finset.mem_union_left _ hγ))
      (ih₂ D M s (fun γ hγ => hΓ γ (Finset.mem_union_right _ hγ)))
  | impI φ _ ih =>
    intro D _ M s hΓ hφ
    apply ih D M s
    intro γ hγ
    by_cases e : γ = φ
    · subst e; exact hφ
    · exact hΓ γ (Finset.mem_erase.2 ⟨e, hγ⟩)
  | allE t _ hff ih =>
    intro D _ M s hΓ
    rw [sat_subst M _ t _ s hff]
    exact ih D M s hΓ _
  | allI x _ hx ih =>
    intro D _ M s hΓ d
    apply ih D M
    intro γ hγ
    have hc := sat_congr M M rfl γ s (Function.update s x d) (by
      intro τ hτ
      have : τ ≠ Term.var x := fun e => hx γ hγ (e ▸ hτ)
      cases τ with
      | var z =>
        have hz : z ≠ x := fun e => this (by rw [e])
        simp [Term.eval, Function.update_of_ne hz]
      | const c => simp [Term.eval])
    exact hc.1 (hΓ γ hγ)
  | exI x t _ hff ih =>
    intro D _ M s hΓ
    exact ⟨Term.eval M s t, (sat_subst M x t _ s hff).1 (ih D M s hΓ)⟩
  | @exE Δ₁ Δ₂ x φ ψ w _ _ hff hwex hwψ hwΔ ih₁ ih₂ =>
    intro D _ M s hΓ
    obtain ⟨d, hd⟩ := ih₁ D M s (fun γ hγ => hΓ γ (Finset.mem_union_left _ hγ))
    obtain ⟨M', s', hrel, hw, hother⟩ := exists_reinterpret M s w d
    have hfix : ∀ χ : Formula, w ∉ χ.free → (M'.sat s' χ ↔ M.sat s χ) := by
      intro χ hχ
      exact sat_congr M' M hrel χ s' s fun τ hτ => hother τ (fun e => hχ (e ▸ hτ))
    have hinst : M'.sat s' (φ.subst x w) := by
      rw [sat_subst M' x w φ s' hff, hw]
      refine (sat_congr M' M hrel φ _ _ ?_).2 hd
      intro τ hτ
      by_cases hτx : τ = Term.var x
      · subst hτx; simp [Term.eval]
      · have hτw : τ ≠ w := by
          intro e; apply hwex
          rw [← e]; simp [Formula.free, hτx, hτ]
        cases τ with
        | var z =>
          have hz : z ≠ x := fun e => hτx (by rw [e])
          simpa [Term.eval, Function.update_of_ne hz] using hother _ hτw
        | const c => simpa [Term.eval] using hother _ hτw
    have hψ : M'.sat s' ψ := by
      apply ih₂ D M' s'
      intro γ hγ
      by_cases e : γ = φ.subst x w
      · subst e; exact hinst
      · have hγ' : γ ∈ Δ₂.erase (φ.subst x w) := Finset.mem_erase.2 ⟨e, hγ⟩
        exact (hfix γ (hwΔ γ hγ')).2 (hΓ γ (Finset.mem_union_right _ hγ'))
    exact (hfix ψ hwψ).1 hψ

#print axioms sat_congr
#print axioms subst_of_not_free
#print axioms eval_substTerm
#print axioms sat_subst
#print axioms exists_reinterpret
#print axioms derivation_sound

/-! ### The theorems -/

/-- **Soundness.** If a derivation leads from the premises `Γ` to the formula `φ`, then `φ` is
true in every structure (with a non-empty domain), under every assignment, where all of `Γ` is
true: `Γ ⊢ φ ⟹ Γ ⊨ φ`. -/
theorem soundness {Γ : Finset Formula} {φ : Formula} (h : Provable Γ φ) :
    Entails.{u} Γ φ := by
  obtain ⟨Δ, hΔ, hd⟩ := h
  intro D _ M s hΓ
  exact derivation_sound hd D M s (fun γ hγ => hΓ γ (hΔ hγ))

/-- **The derivation D1.** "For all x, P(x) → Q(x)" and "P(a)" prove "Q(a)": for-all
elimination with `t = a`, then if-then elimination. -/
theorem d1_provable :
    Provable {all 0 (imp (atom 0 [Term.var 0]) (atom 1 [Term.var 0])), atom 0 [Term.const 0]}
      (atom 1 [Term.const 0]) := by
  have h1 := Derivation.allE (Term.const 0)
    (Derivation.assume (all 0 (imp (atom 0 [Term.var 0]) (atom 1 [Term.var 0]))))
    (⟨trivial, trivial⟩ : FreeFor (Term.const 0) 0 (imp (atom 0 [Term.var 0]) (atom 1 [Term.var 0])))
  have h2 := Derivation.impE (φ := atom 0 [Term.const 0]) (ψ := atom 1 [Term.const 0]) h1
    (Derivation.assume (atom 0 [Term.const 0]))
  refine ⟨_, ?_, h2⟩
  intro γ hγ
  simp only [Finset.mem_union, Finset.mem_singleton] at hγ
  rcases hγ with rfl | rfl <;> simp

/-- **Soundness used backwards.** "There is x with P(x)" does not prove "P(a)": no derivation of
any length exists, because the structure with domain {0, 1}, P = {0} and a = 1 makes the premise
true and the conclusion false. -/
theorem exists_P_not_provable_P_a :
    ¬ Provable {ex 0 (atom 0 [Term.var 0])} (atom 0 [Term.const 0]) := by
  intro h
  have := soundness.{0} h Bool ⟨fun _ l => l = [true], fun _ => false⟩ (fun _ => false)
    (by
      intro γ hγ
      rw [Finset.mem_singleton] at hγ
      subst hγ
      exact ⟨true, by simp [Model.sat, Term.eval]⟩)
  simp [Model.sat, Term.eval] at this

/-! ### The card's counts, checked by enumeration

A structure for the language P, Q, a on the domain `Fin n` is a value for `a` and a set for each
of `P` and `Q`. -/

-- Structures on 1 to 3 objects: 1·4 + 2·16 + 3·64 = 228.
example : 1 * 4 + 2 * 16 + 3 * 64 = 228 := by norm_num
example : Fintype.card (Fin 2 × Finset (Fin 2) × Finset (Fin 2)) = 2 * 16 := by decide

-- Both premises true (a in P, P inside Q): 1 + 2·3 + 3·9 = 34.
example : 1 + 2 * 3 + 3 * 9 = 34 := by norm_num
example : ((Finset.univ : Finset (Fin 2 × Finset (Fin 2) × Finset (Fin 2))).filter
    (fun m => m.1 ∈ m.2.1 ∧ m.2.1 ⊆ m.2.2)).card = 2 * 3 := by decide

-- Countermodels to "some x has P, so P(a)" (P not empty, a outside P): 0 + 2·1·4 + 3·3·8 = 80.
example : 0 + 2 * 1 * 4 + 3 * 3 * 8 = 80 := by norm_num
example : ((Finset.univ : Finset (Fin 2 × Finset (Fin 2) × Finset (Fin 2))).filter
    (fun m => m.2.1.Nonempty ∧ m.1 ∉ m.2.1)).card = 2 * 1 * 4 := by decide

#print axioms soundness
#print axioms d1_provable
#print axioms exists_P_not_provable_P_a

end FormalDeduction
