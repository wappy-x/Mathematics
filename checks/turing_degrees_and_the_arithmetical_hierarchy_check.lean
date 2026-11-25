-- Turing degrees and the arithmetical hierarchy: counting alternating quantifier blocks over a decidable relation matches what an oracle can do at the first two levels (Post's theorem with no oracle and with a HALT oracle), HALT sits at level one exactly, and TOT sits at level two, beyond any HALT oracle.
import Mathlib.Computability.Halting
import Mathlib.Computability.TuringDegree
import Mathlib.Tactic.NormNum

open Nat.Partrec (Code)
open scoped Computability

/-! ### The card's definitions

Programs are Mathlib's codes for partial recursive functions, numbered by `Denumerable.ofNat Code`.
Sets of whole numbers are predicates `ℕ → Prop`. -/

/-- The arithmetical hierarchy. `IsSigma k A`: `A` has a definition made of `k` alternating
quantifier blocks, the first one "there is", in front of a decidable relation. Level 0 is the
decidable sets. A block of several quantifiers of one kind is packed into one number with
`Nat.pair`, as the card's "When it holds" allows. -/
def IsSigma : ℕ → (ℕ → Prop) → Prop
  | 0, A => ComputablePred A
  | k + 1, A => ∃ R : ℕ → Prop, IsSigma k (fun y => ¬ R y) ∧ ∀ x, A x ↔ ∃ m, R (Nat.pair x m)

/-- `IsPi k A`: `A` has a definition of `k` alternating blocks, the first one "for every";
equivalently, the complement of `A` is at level `Σ_k`. -/
def IsPi (k : ℕ) (A : ℕ → Prop) : Prop := IsSigma k (fun x => ¬ A x)

/-- The oracle for a set `A`: asked about `x`, it answers 1 when `x ∈ A` and 0 otherwise,
always truly and in one step. -/
noncomputable def chi (A : ℕ → Prop) : ℕ →. ℕ := by
  classical exact fun x => Part.some (if A x then 1 else 0)

/-- `A` is semidecidable with oracle `g`: some machine `M^g`, which may ask `g` questions,
stops on input `x` exactly when `x ∈ A`. -/
def SemidecidableIn (g : ℕ →. ℕ) (A : ℕ → Prop) : Prop :=
  ∃ f : ℕ →. ℕ, RecursiveIn {g} f ∧ ∀ x, A x ↔ (f x).Dom

/-- HALT: program `e` stops when started on a blank row, that is, on input 0. -/
def HALT (e : ℕ) : Prop := ((Denumerable.ofNat Code e).eval 0).Dom

/-- TOT: program `e` stops on every input. -/
def TOT (e : ℕ) : Prop := ∀ n, ((Denumerable.ofNat Code e).eval n).Dom

/-! ### Helper lemmas -/

theorem ah_c_fst : Computable fun p : ℕ => p.unpair.1 :=
  (Primrec.fst.comp Primrec.unpair).to_comp

theorem ah_c_snd : Computable fun p : ℕ => p.unpair.2 :=
  (Primrec.snd.comp Primrec.unpair).to_comp

theorem ah_c_pair {f g : ℕ → ℕ} (hf : Computable f) (hg : Computable g) :
    Computable fun p => Nat.pair (f p) (g p) :=
  Primrec₂.natPair.to_comp.comp hf hg

theorem ah_cp_and {p q : ℕ → Prop} (hp : ComputablePred p) (hq : ComputablePred q) :
    ComputablePred fun a => p a ∧ q a := by
  obtain ⟨_, hp⟩ := hp
  obtain ⟨_, hq⟩ := hq
  exact Computable.computablePred ((Primrec.and.to_comp.comp hp hq).of_eq fun a => by simp)

theorem ah_cp_or {p q : ℕ → Prop} (hp : ComputablePred p) (hq : ComputablePred q) :
    ComputablePred fun a => p a ∨ q a := by
  obtain ⟨_, hp⟩ := hp
  obtain ⟨_, hq⟩ := hq
  exact Computable.computablePred ((Primrec.or.to_comp.comp hp hq).of_eq fun a => by simp)

theorem ah_cp_comp {p : ℕ → Prop} {g : ℕ → ℕ} (hp : ComputablePred p) (hg : Computable g) :
    ComputablePred fun a => p (g a) := by
  obtain ⟨_, hp⟩ := hp
  exact Computable.computablePred (hp.comp hg)

theorem ah_cp_eq {f g : ℕ → ℕ} (hf : Computable f) (hg : Computable g) :
    ComputablePred fun a => f a = g a :=
  Computable.computablePred (Primrec.eq.decide.to_comp.comp hf hg)

theorem ah_cp_lt {f g : ℕ → ℕ} (hf : Computable f) (hg : Computable g) :
    ComputablePred fun a => f a < g a :=
  Computable.computablePred (Primrec.nat_lt.decide.to_comp.comp hf hg)

theorem ah_s1_iff {A : ℕ → Prop} :
    IsSigma 1 A ↔ ∃ R : ℕ → Prop, ComputablePred R ∧ ∀ x, A x ↔ ∃ m, R (Nat.pair x m) := by
  constructor
  · rintro ⟨R, hR, h⟩
    exact ⟨R, (ComputablePred.not hR).of_eq fun y => not_not, h⟩
  · rintro ⟨R, hR, h⟩
    exact ⟨R, ComputablePred.not hR, h⟩

theorem ah_s1_of_iff {A B : ℕ → Prop} (h : IsSigma 1 B) (e : ∀ x, A x ↔ B x) : IsSigma 1 A := by
  have : A = B := funext fun x => propext (e x)
  exact this ▸ h

theorem ah_s1_of_cp {A : ℕ → Prop} (h : ComputablePred A) : IsSigma 1 A :=
  ah_s1_iff.2 ⟨fun p => A p.unpair.1, ah_cp_comp h ah_c_fst, fun x => by simp⟩

theorem ah_s1_comp {A Q : ℕ → Prop} {g : ℕ → ℕ} (hQ : IsSigma 1 Q) (hg : Computable g)
    (e : ∀ x, A x ↔ Q (g x)) : IsSigma 1 A := by
  obtain ⟨R, hR, h⟩ := ah_s1_iff.1 hQ
  refine ah_s1_iff.2 ⟨fun p => R (Nat.pair (g p.unpair.1) p.unpair.2),
    ah_cp_comp hR (ah_c_pair (hg.comp ah_c_fst) ah_c_snd), fun x => ?_⟩
  simp [e, h]

theorem ah_s1_and {A P Q : ℕ → Prop} (hP : IsSigma 1 P) (hQ : IsSigma 1 Q)
    (e : ∀ x, A x ↔ P x ∧ Q x) : IsSigma 1 A := by
  obtain ⟨R, hR, h⟩ := ah_s1_iff.1 hP
  obtain ⟨S, hS, h'⟩ := ah_s1_iff.1 hQ
  refine ah_s1_iff.2 ⟨fun p => R (Nat.pair p.unpair.1 p.unpair.2.unpair.1) ∧
    S (Nat.pair p.unpair.1 p.unpair.2.unpair.2),
    ah_cp_and (ah_cp_comp hR (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd)))
      (ah_cp_comp hS (ah_c_pair ah_c_fst (ah_c_snd.comp ah_c_snd))), fun x => ?_⟩
  simp only [e, h, h', Nat.unpair_pair]
  constructor
  · rintro ⟨⟨a, ha⟩, ⟨b, hb⟩⟩
    exact ⟨Nat.pair a b, by simpa using ha, by simpa using hb⟩
  · rintro ⟨m, h1, h2⟩
    exact ⟨⟨_, h1⟩, ⟨_, h2⟩⟩

theorem ah_s1_or {A P Q : ℕ → Prop} (hP : IsSigma 1 P) (hQ : IsSigma 1 Q)
    (e : ∀ x, A x ↔ P x ∨ Q x) : IsSigma 1 A := by
  obtain ⟨R, hR, h⟩ := ah_s1_iff.1 hP
  obtain ⟨S, hS, h'⟩ := ah_s1_iff.1 hQ
  refine ah_s1_iff.2 ⟨fun p => R (Nat.pair p.unpair.1 p.unpair.2.unpair.1) ∨
    S (Nat.pair p.unpair.1 p.unpair.2.unpair.2),
    ah_cp_or (ah_cp_comp hR (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd)))
      (ah_cp_comp hS (ah_c_pair ah_c_fst (ah_c_snd.comp ah_c_snd))), fun x => ?_⟩
  simp only [e, h, h', Nat.unpair_pair]
  constructor
  · rintro (⟨a, ha⟩ | ⟨b, hb⟩)
    · exact ⟨Nat.pair a 0, Or.inl (by simpa using ha)⟩
    · exact ⟨Nat.pair 0 b, Or.inr (by simpa using hb)⟩
  · rintro ⟨m, h1 | h2⟩
    · exact Or.inl ⟨_, h1⟩
    · exact Or.inr ⟨_, h2⟩

theorem ah_s1_exists {A Q : ℕ → Prop} (hQ : IsSigma 1 Q)
    (e : ∀ x, A x ↔ ∃ n, Q (Nat.pair x n)) : IsSigma 1 A := by
  obtain ⟨R, hR, h⟩ := ah_s1_iff.1 hQ
  refine ah_s1_iff.2 ⟨fun p => R (Nat.pair (Nat.pair p.unpair.1 p.unpair.2.unpair.1)
    p.unpair.2.unpair.2),
    ah_cp_comp hR (ah_c_pair (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd))
      (ah_c_snd.comp ah_c_snd)), fun x => ?_⟩
  simp only [e, h, Nat.unpair_pair]
  constructor
  · rintro ⟨n, k, hk⟩
    exact ⟨Nat.pair n k, by simpa using hk⟩
  · rintro ⟨m, hm⟩
    exact ⟨_, _, hm⟩

theorem ah_s1_iff_code {A : ℕ → Prop} :
    IsSigma 1 A ↔ ∃ c : Code, ∀ x, A x ↔ (c.eval x).Dom := by
  rw [ah_s1_iff]
  constructor
  · rintro ⟨R, hR, h⟩
    obtain ⟨_, hR⟩ := hR
    have hp : Partrec fun x => Nat.rfind fun m => Part.some (decide (R (Nat.pair x m))) :=
      Partrec.rfind (hR.comp (Primrec₂.natPair.to_comp.comp Computable.fst Computable.snd)).partrec
    obtain ⟨c, hc⟩ := Nat.Partrec.Code.exists_code.1 (Partrec.nat_iff.1 hp)
    refine ⟨c, fun x => ?_⟩
    rw [hc, h]
    constructor
    · rintro ⟨m, hm⟩
      exact Nat.rfind_dom.2 ⟨m, by simpa using hm, fun _ => trivial⟩
    · intro hd
      obtain ⟨n, hn, -⟩ := Nat.rfind_dom.1 hd
      exact ⟨n, by simpa using hn⟩
  · rintro ⟨c, h⟩
    refine ⟨fun p => ((Nat.Partrec.Code.evaln p.unpair.2 c p.unpair.1).isSome : Prop),
      ComputablePred.computable_iff.2 ⟨_, ?_, rfl⟩, fun x => ?_⟩
    · exact (Primrec.option_isSome.comp (Nat.Partrec.Code.primrec_evaln.comp
        (Primrec.pair (Primrec.pair (Primrec.snd.comp Primrec.unpair) (Primrec.const c))
          (Primrec.fst.comp Primrec.unpair)))).to_comp
    · rw [h x, Part.dom_iff_mem]
      simp only [Nat.unpair_pair]
      constructor
      · rintro ⟨y, hy⟩
        obtain ⟨k, hk⟩ := Nat.Partrec.Code.evaln_complete.1 hy
        exact ⟨k, Option.isSome_iff_exists.2 ⟨y, hk⟩⟩
      · rintro ⟨k, hk⟩
        obtain ⟨y, hy⟩ := Option.isSome_iff_exists.1 hk
        exact ⟨y, Nat.Partrec.Code.evaln_sound hy⟩

theorem ah_p1_of_cp {A : ℕ → Prop} (h : ComputablePred A) : IsPi 1 A :=
  ah_s1_of_cp (ComputablePred.not h)

theorem ah_p1_comp {A Q : ℕ → Prop} {g : ℕ → ℕ} (hQ : IsPi 1 Q) (hg : Computable g)
    (e : ∀ x, A x ↔ Q (g x)) : IsPi 1 A :=
  ah_s1_comp hQ hg fun x => not_congr (e x)

theorem ah_p1_and {A P Q : ℕ → Prop} (hP : IsPi 1 P) (hQ : IsPi 1 Q)
    (e : ∀ x, A x ↔ P x ∧ Q x) : IsPi 1 A :=
  ah_s1_or hP hQ fun x => by rw [e x]; exact not_and_or

theorem ah_p1_or {A P Q : ℕ → Prop} (hP : IsPi 1 P) (hQ : IsPi 1 Q)
    (e : ∀ x, A x ↔ P x ∨ Q x) : IsPi 1 A :=
  ah_s1_and hP hQ fun x => by rw [e x]; exact not_or

theorem ah_p1_forall {A Q : ℕ → Prop} (hQ : IsPi 1 Q)
    (e : ∀ x, A x ↔ ∀ n, Q (Nat.pair x n)) : IsPi 1 A :=
  ah_s1_exists hQ fun x => by rw [e x]; exact not_forall

theorem ah_p1_ball {A Q : ℕ → Prop} {b : ℕ → ℕ} (hQ : IsPi 1 Q) (hb : Computable b)
    (e : ∀ x, A x ↔ ∀ i < b x, Q (Nat.pair x i)) : IsPi 1 A :=
  ah_p1_forall (Q := fun p => ¬ p.unpair.2 < b p.unpair.1 ∨ Q p)
    (ah_p1_or (ah_p1_of_cp (ComputablePred.not (ah_cp_lt ah_c_snd (hb.comp ah_c_fst)))) hQ
      fun _ => Iff.rfl)
    fun x => by rw [e x]; simp [imp_iff_not_or]

theorem ah_c_W {f g : ℕ → ℕ} (hf : Computable f) (hg : Computable g) :
    Computable fun q => ((Encodable.decode (α := List ℕ) (f q)).getD []).getD (g q) 0 :=
  (Primrec.list_getD 0).to_comp.comp
    (Primrec.option_getD.to_comp.comp (Primrec.decode.to_comp.comp hf) (Computable.const [])) hg

theorem ah_s2_iff {A : ℕ → Prop} :
    IsSigma 2 A ↔ ∃ R : ℕ → Prop, IsPi 1 R ∧ ∀ x, A x ↔ ∃ m, R (Nat.pair x m) :=
  Iff.rfl

theorem ah_s2_of_iff {A B : ℕ → Prop} (h : IsSigma 2 B) (e : ∀ x, A x ↔ B x) : IsSigma 2 A := by
  have : A = B := funext fun x => propext (e x)
  exact this ▸ h

theorem ah_s2_of_p1 {A : ℕ → Prop} (h : IsPi 1 A) : IsSigma 2 A :=
  ah_s2_iff.2 ⟨fun p => A p.unpair.1, ah_p1_comp h ah_c_fst fun _ => Iff.rfl,
    fun x => by simp⟩

theorem ah_s2_of_cp {A : ℕ → Prop} (h : ComputablePred A) : IsSigma 2 A :=
  ah_s2_of_p1 (ah_p1_of_cp h)

theorem ah_s2_of_s1 {A : ℕ → Prop} (h : IsSigma 1 A) : IsSigma 2 A := by
  obtain ⟨R, hR, e⟩ := ah_s1_iff.1 h
  exact ah_s2_iff.2 ⟨R, ah_p1_of_cp hR, e⟩

theorem ah_s2_comp {A Q : ℕ → Prop} {g : ℕ → ℕ} (hQ : IsSigma 2 Q) (hg : Computable g)
    (e : ∀ x, A x ↔ Q (g x)) : IsSigma 2 A := by
  obtain ⟨R, hR, h⟩ := ah_s2_iff.1 hQ
  refine ah_s2_iff.2 ⟨fun p => R (Nat.pair (g p.unpair.1) p.unpair.2),
    ah_p1_comp hR (ah_c_pair (hg.comp ah_c_fst) ah_c_snd) fun _ => Iff.rfl, fun x => ?_⟩
  simp [e, h]

theorem ah_s2_and {A P Q : ℕ → Prop} (hP : IsSigma 2 P) (hQ : IsSigma 2 Q)
    (e : ∀ x, A x ↔ P x ∧ Q x) : IsSigma 2 A := by
  obtain ⟨R, hR, h⟩ := ah_s2_iff.1 hP
  obtain ⟨S, hS, h'⟩ := ah_s2_iff.1 hQ
  refine ah_s2_iff.2 ⟨fun p => R (Nat.pair p.unpair.1 p.unpair.2.unpair.1) ∧
    S (Nat.pair p.unpair.1 p.unpair.2.unpair.2),
    ah_p1_and (ah_p1_comp hR (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd)) fun _ => Iff.rfl)
      (ah_p1_comp hS (ah_c_pair ah_c_fst (ah_c_snd.comp ah_c_snd)) fun _ => Iff.rfl)
      fun _ => Iff.rfl, fun x => ?_⟩
  simp only [e, h, h', Nat.unpair_pair]
  constructor
  · rintro ⟨⟨a, ha⟩, ⟨b, hb⟩⟩
    exact ⟨Nat.pair a b, by simpa using ha, by simpa using hb⟩
  · rintro ⟨m, h1, h2⟩
    exact ⟨⟨_, h1⟩, ⟨_, h2⟩⟩

theorem ah_s2_or {A P Q : ℕ → Prop} (hP : IsSigma 2 P) (hQ : IsSigma 2 Q)
    (e : ∀ x, A x ↔ P x ∨ Q x) : IsSigma 2 A := by
  obtain ⟨R, hR, h⟩ := ah_s2_iff.1 hP
  obtain ⟨S, hS, h'⟩ := ah_s2_iff.1 hQ
  refine ah_s2_iff.2 ⟨fun p => R (Nat.pair p.unpair.1 p.unpair.2.unpair.1) ∨
    S (Nat.pair p.unpair.1 p.unpair.2.unpair.2),
    ah_p1_or (ah_p1_comp hR (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd)) fun _ => Iff.rfl)
      (ah_p1_comp hS (ah_c_pair ah_c_fst (ah_c_snd.comp ah_c_snd)) fun _ => Iff.rfl)
      fun _ => Iff.rfl, fun x => ?_⟩
  simp only [e, h, h', Nat.unpair_pair]
  constructor
  · rintro (⟨a, ha⟩ | ⟨b, hb⟩)
    · exact ⟨Nat.pair a 0, Or.inl (by simpa using ha)⟩
    · exact ⟨Nat.pair 0 b, Or.inr (by simpa using hb)⟩
  · rintro ⟨m, h1 | h2⟩
    · exact Or.inl ⟨_, h1⟩
    · exact Or.inr ⟨_, h2⟩

theorem ah_s2_exists {A Q : ℕ → Prop} (hQ : IsSigma 2 Q)
    (e : ∀ x, A x ↔ ∃ n, Q (Nat.pair x n)) : IsSigma 2 A := by
  obtain ⟨R, hR, h⟩ := ah_s2_iff.1 hQ
  refine ah_s2_iff.2 ⟨fun p => R (Nat.pair (Nat.pair p.unpair.1 p.unpair.2.unpair.1)
    p.unpair.2.unpair.2),
    ah_p1_comp hR (ah_c_pair (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd))
      (ah_c_snd.comp ah_c_snd)) fun _ => Iff.rfl, fun x => ?_⟩
  simp only [e, h, Nat.unpair_pair]
  constructor
  · rintro ⟨n, k, hk⟩
    exact ⟨Nat.pair n k, by simpa using hk⟩
  · rintro ⟨m, hm⟩
    exact ⟨_, _, hm⟩

theorem ah_s2_ball {A Q : ℕ → Prop} {b : ℕ → ℕ} (hQ : IsSigma 2 Q) (hb : Computable b)
    (e : ∀ x, A x ↔ ∀ i < b x, Q (Nat.pair x i)) : IsSigma 2 A := by
  obtain ⟨R, hR, h⟩ := ah_s2_iff.1 hQ
  refine ah_s2_iff.2 ⟨fun p => ∀ i < b p.unpair.1, R (Nat.pair (Nat.pair p.unpair.1 i)
      (((Encodable.decode (α := List ℕ) p.unpair.2).getD []).getD i 0)), ?_, fun x => ?_⟩
  · exact ah_p1_ball (Q := fun q => R (Nat.pair (Nat.pair q.unpair.1.unpair.1 q.unpair.2)
      (((Encodable.decode (α := List ℕ) q.unpair.1.unpair.2).getD []).getD q.unpair.2 0)))
      (ah_p1_comp hR (ah_c_pair (ah_c_pair (ah_c_fst.comp ah_c_fst) ah_c_snd)
        (ah_c_W (ah_c_snd.comp ah_c_fst) ah_c_snd)) fun _ => Iff.rfl)
      (hb.comp ah_c_fst) fun p => by simp
  · simp only [e, h, Nat.unpair_pair]
    constructor
    · intro H
      have H' : ∀ i, ∃ m, i < b x → R (Nat.pair (Nat.pair x i) m) := by
        intro i
        by_cases hi : i < b x
        · obtain ⟨m, hm⟩ := H i hi
          exact ⟨m, fun _ => hm⟩
        · exact ⟨0, fun h => absurd h hi⟩
      choose g hg using H'
      refine ⟨Encodable.encode ((List.range (b x)).map g), fun i hi => ?_⟩
      have : ((List.range (b x)).map g).getD i 0 = g i := by
        simp [List.getD_eq_getElem?_getD, hi]
      simp only [Encodable.encodek, Option.getD_some, this]
      exact hg i hi
    · rintro ⟨m, hm⟩ i hi
      exact ⟨_, hm i hi⟩

theorem ah_prec_mem (f h : ℕ →. ℕ) (a : ℕ) : ∀ n y,
    y ∈ (Nat.rec (motive := fun _ => Part ℕ) (f a)
      (fun k IH => IH >>= fun i => h (Nat.pair a (Nat.pair k i))) n) ↔
    ∃ s : ℕ → ℕ, s 0 ∈ f a ∧ (∀ i < n, s (i + 1) ∈ h (Nat.pair a (Nat.pair i (s i)))) ∧
      s n = y := by
  intro n
  induction n with
  | zero =>
    intro y
    constructor
    · intro hy
      exact ⟨fun _ => y, hy, fun i hi => absurd hi (Nat.not_lt_zero _), rfl⟩
    · rintro ⟨s, hs, -, rfl⟩
      exact hs
  | succ n ih =>
    intro y
    simp only [Part.bind_eq_bind, Part.mem_bind_iff]
    constructor
    · rintro ⟨i, hi, hy⟩
      obtain ⟨s, h0, hs, rfl⟩ := (ih i).1 hi
      refine ⟨fun j => if j = n + 1 then y else s j, by simpa using h0, fun j hj => ?_, by simp⟩
      rcases Nat.lt_succ_iff_lt_or_eq.1 hj with hj | rfl
      · have h1 : j ≠ n + 1 := by omega
        have h3 : j ≠ n := by omega
        simpa [h1, h3] using hs j hj
      · simpa using hy
    · rintro ⟨s, h0, hs, rfl⟩
      exact ⟨s n, (ih (s n)).2 ⟨s, h0, fun i hi => hs i (Nat.lt_succ_of_lt hi), rfl⟩,
        hs n (Nat.lt_succ_self n)⟩

theorem ah_W_encode (s : ℕ → ℕ) (n i : ℕ) (hi : i < n) :
    ((Encodable.decode (α := List ℕ) (Encodable.encode ((List.range n).map s))).getD []).getD
      i 0 = s i := by
  simp only [Encodable.encodek, Option.getD_some]
  simp [List.getD_eq_getElem?_getD, hi]

theorem ah_mem_pair (u v : Part ℕ) (y : ℕ) :
    y ∈ (Nat.pair <$> u <*> v) ↔ y.unpair.1 ∈ u ∧ y.unpair.2 ∈ v := by
  simp only [Seq.seq]
  simp only [Part.map_eq_map, ← Part.bind_eq_bind]
  constructor
  · intro hy
    obtain ⟨g, hg, hy⟩ := Part.mem_bind_iff.1 hy
    obtain ⟨a, ha, rfl⟩ := (Part.mem_map_iff _).1 hg
    obtain ⟨b, hb, rfl⟩ := (Part.mem_map_iff _).1 hy
    simp [ha, hb]
  · rintro ⟨h1, h2⟩
    refine Part.mem_bind_iff.2 ⟨_, Part.mem_map Nat.pair h1, ?_⟩
    have := Part.mem_map (Nat.pair y.unpair.1) h2
    rwa [Nat.pair_unpair] at this

theorem ah_mem_rfind (F : ℕ → Part ℕ) (y : ℕ) :
    y ∈ Nat.rfind (fun n => (fun m => decide (m = 0)) <$> F n) ↔
      0 ∈ F y ∧ ∀ i < y, ∃ k ∈ F i, k ≠ 0 := by
  refine Nat.mem_rfind.trans ?_
  simp

theorem ah_graph {O : Set (ℕ →. ℕ)}
    (hO : ∀ g ∈ O, IsSigma 2 fun p => p.unpair.2 ∈ g p.unpair.1)
    {f : ℕ →. ℕ} (hf : Nat.RecursiveIn O f) : IsSigma 2 fun p => p.unpair.2 ∈ f p.unpair.1 := by
  induction hf with
  | zero =>
    exact ah_s2_of_iff (ah_s2_of_cp (ah_cp_eq ah_c_snd (Computable.const 0))) fun p =>
      Part.mem_some_iff
  | succ =>
    exact ah_s2_of_iff (ah_s2_of_cp (ah_cp_eq ah_c_snd (Computable.succ.comp ah_c_fst)))
      fun p => by simp
  | left =>
    exact ah_s2_of_iff (ah_s2_of_cp (ah_cp_eq ah_c_snd (ah_c_fst.comp ah_c_fst)))
      fun p => by simp
  | right =>
    exact ah_s2_of_iff (ah_s2_of_cp (ah_cp_eq ah_c_snd (ah_c_snd.comp ah_c_fst)))
      fun p => by simp
  | oracle g hg => exact hO g hg
  | @pair f h _ _ ihf ihh =>
    exact ah_s2_and (P := fun p => p.unpair.2.unpair.1 ∈ f p.unpair.1)
      (Q := fun p => p.unpair.2.unpair.2 ∈ h p.unpair.1)
      (ah_s2_comp ihf (ah_c_pair ah_c_fst (ah_c_fst.comp ah_c_snd)) fun q => by simp)
      (ah_s2_comp ihh (ah_c_pair ah_c_fst (ah_c_snd.comp ah_c_snd)) fun q => by simp)
      fun p => ah_mem_pair _ _ _
  | @comp f h _ _ ihf ihh =>
    refine ah_s2_exists (Q := fun q => q.unpair.2 ∈ h q.unpair.1.unpair.1 ∧
        q.unpair.1.unpair.2 ∈ f q.unpair.2)
      (ah_s2_and (ah_s2_comp ihh (ah_c_pair (ah_c_fst.comp ah_c_fst) ah_c_snd) fun q => by simp)
        (ah_s2_comp ihf (ah_c_pair ah_c_snd (ah_c_snd.comp ah_c_fst)) fun q => by simp)
        fun _ => Iff.rfl) ?_
    intro p
    simp only [Nat.unpair_pair]
    exact Part.mem_bind_iff
  | @prec f h _ _ ihf ihh =>
    refine ah_s2_exists (Q := fun q =>
      ((Encodable.decode (α := List ℕ) q.unpair.2).getD []).getD 0 0 ∈ f q.unpair.1.unpair.1.unpair.1 ∧
      (∀ i < q.unpair.1.unpair.1.unpair.2,
        ((Encodable.decode (α := List ℕ) q.unpair.2).getD []).getD (i + 1) 0 ∈
          h (Nat.pair q.unpair.1.unpair.1.unpair.1
            (Nat.pair i (((Encodable.decode (α := List ℕ) q.unpair.2).getD []).getD i 0)))) ∧
      ((Encodable.decode (α := List ℕ) q.unpair.2).getD []).getD q.unpair.1.unpair.1.unpair.2 0 = q.unpair.1.unpair.2) ?_ ?_
    · refine ah_s2_and
        (ah_s2_comp ihf (ah_c_pair (ah_c_fst.comp (ah_c_fst.comp ah_c_fst))
          (ah_c_W ah_c_snd (Computable.const 0))) fun q => by simp)
        (ah_s2_and
          (ah_s2_ball (b := fun q => q.unpair.1.unpair.1.unpair.2)
            (Q := fun r => ((Encodable.decode (α := List ℕ) r.unpair.1.unpair.2).getD []).getD (r.unpair.2 + 1) 0 ∈
              h (Nat.pair r.unpair.1.unpair.1.unpair.1.unpair.1
                (Nat.pair r.unpair.2 (((Encodable.decode (α := List ℕ) r.unpair.1.unpair.2).getD []).getD r.unpair.2 0))))
            (ah_s2_comp ihh (ah_c_pair
              (ah_c_pair (ah_c_fst.comp (ah_c_fst.comp (ah_c_fst.comp ah_c_fst)))
                (ah_c_pair ah_c_snd (ah_c_W (ah_c_snd.comp ah_c_fst) ah_c_snd)))
              (ah_c_W (ah_c_snd.comp ah_c_fst) (Computable.succ.comp ah_c_snd)))
              fun r => by simp)
            (ah_c_snd.comp (ah_c_fst.comp ah_c_fst)) fun q => by simp)
          (ah_s2_of_cp (ah_cp_eq (ah_c_W ah_c_snd (ah_c_snd.comp (ah_c_fst.comp ah_c_fst)))
            (ah_c_snd.comp ah_c_fst)))
          fun _ => Iff.rfl)
        fun _ => Iff.rfl
    · intro p
      obtain ⟨x, y, rfl⟩ : ∃ x y, p = Nat.pair x y := ⟨_, _, (Nat.pair_unpair p).symm⟩
      obtain ⟨a, n, rfl⟩ : ∃ a n, x = Nat.pair a n := ⟨_, _, (Nat.pair_unpair x).symm⟩
      simp only [Nat.unpair_pair]
      refine (ah_prec_mem f h a n y).trans ?_
      constructor
      · rintro ⟨s, h0, hs, rfl⟩
        refine ⟨Encodable.encode ((List.range (n + 1)).map s), ?_, fun i hi => ?_, ?_⟩
        · rw [ah_W_encode s (n + 1) 0 (by omega)]
          exact h0
        · rw [ah_W_encode s (n + 1) (i + 1) (by omega), ah_W_encode s (n + 1) i (by omega)]
          exact hs i hi
        · exact ah_W_encode s (n + 1) n (by omega)
      · rintro ⟨w, h0, hs, hn⟩
        exact ⟨fun i => ((Encodable.decode (α := List ℕ) w).getD []).getD i 0, h0, hs, hn⟩
  | @rfind f _ ihf =>
    refine ah_s2_and (P := fun p => 0 ∈ f (Nat.pair p.unpair.1 p.unpair.2))
      (Q := fun p => ∀ i < p.unpair.2, ∃ k, k ∈ f (Nat.pair p.unpair.1 i) ∧ k ≠ 0)
      (ah_s2_comp ihf (ah_c_pair (ah_c_pair ah_c_fst ah_c_snd) (Computable.const 0))
        fun p => by simp)
      (ah_s2_ball (Q := fun r => ∃ k, k ∈ f (Nat.pair r.unpair.1.unpair.1 r.unpair.2) ∧ k ≠ 0)
        (ah_s2_exists (Q := fun t => t.unpair.2 ∈ f (Nat.pair t.unpair.1.unpair.1.unpair.1
            t.unpair.1.unpair.2) ∧ t.unpair.2 ≠ 0)
          (ah_s2_and (ah_s2_comp ihf (ah_c_pair (ah_c_pair (ah_c_fst.comp (ah_c_fst.comp ah_c_fst))
              (ah_c_snd.comp ah_c_fst)) ah_c_snd) fun t => by simp)
            (ah_s2_of_cp (ComputablePred.not (ah_cp_eq ah_c_snd (Computable.const 0))))
            fun _ => Iff.rfl)
          fun r => by simp)
        ah_c_snd fun p => by simp) ?_
    intro p
    exact ah_mem_rfind (fun n => f (Nat.pair p.unpair.1 n)) _

theorem ah_chi_dom (B : ℕ → Prop) (y : ℕ) : (chi B y).Dom := by
  unfold chi
  exact trivial

theorem ah_mem_chi (B : ℕ → Prop) (y v : ℕ) :
    v ∈ chi B y ↔ (B y ∧ v = 1) ∨ (¬ B y ∧ v = 0) := by
  unfold chi
  by_cases h : B y <;> simp [h]

theorem ah_chi_some (B : ℕ → Prop) (y : ℕ) : ∃ c, chi B y = Part.some c := by
  unfold chi
  exact ⟨_, rfl⟩

theorem ah_s1_eval {g h : ℕ → ℕ} (hg : Computable g) (hh : Computable h) :
    IsSigma 1 fun p => ((Denumerable.ofNat Code (g p)).eval (h p)).Dom := by
  refine ah_s1_iff.2 ⟨fun q => ((Nat.Partrec.Code.evaln q.unpair.2
      (Denumerable.ofNat Code (g q.unpair.1)) (h q.unpair.1)).isSome : Prop),
    ComputablePred.computable_iff.2 ⟨_, ?_, rfl⟩, fun x => ?_⟩
  · exact Primrec.option_isSome.to_comp.comp (Nat.Partrec.Code.primrec_evaln.to_comp.comp
      (Computable.pair (Computable.pair ah_c_snd ((Primrec.ofNat Code).to_comp.comp
        (hg.comp ah_c_fst))) (hh.comp ah_c_fst)))
  · rw [Part.dom_iff_mem]
    simp only [Nat.unpair_pair]
    constructor
    · rintro ⟨y, hy⟩
      obtain ⟨k, hk⟩ := Nat.Partrec.Code.evaln_complete.1 hy
      exact ⟨k, Option.isSome_iff_exists.2 ⟨y, hk⟩⟩
    · rintro ⟨k, hk⟩
      obtain ⟨y, hy⟩ := Option.isSome_iff_exists.1 hk
      exact ⟨y, Nat.Partrec.Code.evaln_sound hy⟩

theorem ah_halt_s1 : IsSigma 1 HALT :=
  ah_s1_of_iff (ah_s1_eval Computable.id (Computable.const 0)) fun _ => Iff.rfl

theorem ah_reduce_halt {P : ℕ → Prop} (hP : IsSigma 1 P) :
    ∃ r : ℕ → ℕ, Computable r ∧ ∀ y, P y ↔ HALT (r y) := by
  obtain ⟨c, hc⟩ := ah_s1_iff_code.1 (ah_s1_comp (A := fun p => P p.unpair.1) hP ah_c_fst
    fun _ => Iff.rfl)
  refine ⟨fun y => Encodable.encode (Nat.Partrec.Code.curry c y),
    (Primrec.encode.comp (Nat.Partrec.Code.primrec₂_curry.comp (Primrec.const c)
      Primrec.id)).to_comp, fun y => ?_⟩
  have := hc (Nat.pair y 0)
  simp only [Nat.unpair_pair] at this
  rw [this]
  simp [HALT, Nat.Partrec.Code.eval_curry]

theorem ah_rin_of_comp {O : Set (ℕ →. ℕ)} {g : ℕ → ℕ} (hg : Computable g) :
    Nat.RecursiveIn O fun n => Part.some (g n) :=
  Nat.Partrec.recursiveIn (Partrec.nat_iff.1 hg.partrec)

theorem ah_rin_oracle_comp {O : Set (ℕ →. ℕ)} {g : ℕ →. ℕ} (hg : g ∈ O) {r : ℕ → ℕ}
    (hr : Computable r) : Nat.RecursiveIn O fun n => g (r n) :=
  (Nat.RecursiveIn.comp (Nat.RecursiveIn.oracle g hg) (ah_rin_of_comp hr)).of_eq fun n =>
    Part.bind_some (r n) g

theorem ah_graph_halt : IsSigma 2 fun p => p.unpair.2 ∈ chi HALT p.unpair.1 :=
  ah_s2_or (P := fun p => HALT p.unpair.1 ∧ p.unpair.2 = 1)
    (Q := fun p => ¬ HALT p.unpair.1 ∧ p.unpair.2 = 0)
    (ah_s2_and (ah_s2_of_s1 (ah_s1_comp ah_halt_s1 ah_c_fst fun _ => Iff.rfl))
      (ah_s2_of_cp (ah_cp_eq ah_c_snd (Computable.const 1))) fun _ => Iff.rfl)
    (ah_s2_and (ah_s2_of_p1 (ah_s1_of_iff (ah_s1_comp ah_halt_s1 ah_c_fst fun _ => Iff.rfl)
        fun _ => not_not))
      (ah_s2_of_cp (ah_cp_eq ah_c_snd (Computable.const 0))) fun _ => Iff.rfl)
    fun _ => ah_mem_chi _ _ _

theorem ah_semidec_s2 {A : ℕ → Prop} (h : SemidecidableIn (chi HALT) A) : IsSigma 2 A := by
  obtain ⟨f, hf, e⟩ := h
  have hg := ah_graph (O := {chi HALT})
    (fun g hg => by rw [Set.mem_singleton_iff.1 hg]; exact ah_graph_halt)
    (RecursiveIn.iff_nat.1 hf)
  exact ah_s2_exists hg fun x => by rw [e x, Part.dom_iff_mem]; simp

theorem ah_s2_semidec {A : ℕ → Prop} (h : IsSigma 2 A) : SemidecidableIn (chi HALT) A := by
  obtain ⟨R, hR, e⟩ := ah_s2_iff.1 h
  obtain ⟨r, hr, hr'⟩ := ah_reduce_halt hR
  have hF := ah_rin_oracle_comp (O := {chi HALT}) (Set.mem_singleton _) hr
  refine ⟨_, RecursiveIn.iff_nat.2 (Nat.RecursiveIn.rfind hF), fun x => ?_⟩
  rw [e x]
  constructor
  · rintro ⟨m, hm⟩
    refine Nat.rfind_dom.2 ⟨m, ?_, fun {m'} _ => ah_chi_dom HALT (r (Nat.pair x m'))⟩
    refine (Part.mem_map_iff _).2 ⟨0, (ah_mem_chi _ _ _).2 (Or.inr ⟨?_, rfl⟩), by simp⟩
    rw [← hr']
    exact not_not.2 hm
  · intro hd
    obtain ⟨m, hm, -⟩ := Nat.rfind_dom.1 hd
    obtain ⟨v, hv, hv0⟩ := (Part.mem_map_iff _).1 hm
    refine ⟨m, ?_⟩
    rcases (ah_mem_chi _ _ _).1 hv with ⟨-, rfl⟩ | ⟨h1, -⟩
    · simp at hv0
    · rw [← hr'] at h1
      exact not_not.1 h1

theorem ah_hO : ∀ g ∈ ({chi HALT} : Set (ℕ →. ℕ)),
    IsSigma 2 fun p => p.unpair.2 ∈ g p.unpair.1 := fun g hg => by
  rw [Set.mem_singleton_iff.1 hg]
  exact ah_graph_halt

theorem ah_delta2_rin {A : ℕ → Prop} (h1 : IsSigma 2 A) (h2 : IsSigma 2 fun x => ¬ A x) :
    Nat.RecursiveIn {chi HALT} (chi A) := by
  obtain ⟨R1, hR1, e1⟩ := ah_s2_iff.1 h1
  obtain ⟨R2, hR2, e2⟩ := ah_s2_iff.1 h2
  obtain ⟨r1, hr1, hr1'⟩ := ah_reduce_halt hR1
  obtain ⟨r, hr, hr'⟩ := ah_reduce_halt
    (ah_s1_and (A := fun y => ¬ R1 y ∧ ¬ R2 y) hR1 hR2 fun _ => Iff.rfl)
  have hO : chi HALT ∈ ({chi HALT} : Set (ℕ →. ℕ)) := Set.mem_singleton _
  have hF := ah_rin_oracle_comp hO hr
  have hF1 := ah_rin_oracle_comp hO hr1
  have hP := Nat.RecursiveIn.pair (ah_rin_of_comp (O := {chi HALT}) Computable.id)
    (Nat.RecursiveIn.rfind hF)
  have hite : Computable fun v : ℕ => if v = 0 then 1 else 0 :=
    ComputablePred.ite (Computable.const 1) (Computable.const 0)
      (ah_cp_eq Computable.id (Computable.const 0))
  have hOut := Nat.RecursiveIn.comp (ah_rin_of_comp (O := {chi HALT}) hite)
    (Nat.RecursiveIn.comp hF1 hP)
  refine hOut.of_eq fun x => ?_
  obtain ⟨c, hc⟩ := ah_chi_some A x
  rw [hc]
  refine Part.eq_some_iff.2 ?_
  have hex : ∃ m, ¬ HALT (r (Nat.pair x m)) := by
    by_cases hA : A x
    · obtain ⟨m, hm⟩ := (e1 x).1 hA
      exact ⟨m, fun hh => ((hr' _).2 hh).1 hm⟩
    · obtain ⟨m, hm⟩ := (e2 x).1 hA
      exact ⟨m, fun hh => ((hr' _).2 hh).2 hm⟩
  classical
  obtain ⟨m, hm, hmin⟩ : ∃ m, ¬ HALT (r (Nat.pair x m)) ∧ ∀ i < m, HALT (r (Nat.pair x i)) :=
    ⟨Nat.find hex, Nat.find_spec hex, fun i hi => not_not.1 (Nat.find_min hex hi)⟩
  have hmμ : m ∈ Nat.rfind fun n => (fun v => decide (v = 0)) <$> chi HALT (r (Nat.pair x n)) :=
    (ah_mem_rfind (fun n => chi HALT (r (Nat.pair x n))) m).2
      ⟨(ah_mem_chi _ _ _).2 (Or.inr ⟨hm, rfl⟩),
        fun i hi => ⟨1, (ah_mem_chi _ _ _).2 (Or.inl ⟨hmin i hi, rfl⟩), one_ne_zero⟩⟩
  have hPm : Nat.pair x m ∈ (Nat.pair <$> Part.some x <*>
      Nat.rfind fun n => (fun v => decide (v = 0)) <$> chi HALT (r (Nat.pair x n))) :=
    (ah_mem_pair _ _ _).2 ⟨by simp, by simpa using hmμ⟩
  have hc' := (ah_mem_chi A x c).1 (hc ▸ Part.mem_some c)
  by_cases hR : R1 (Nat.pair x m)
  · have hv : 0 ∈ chi HALT (r1 (Nat.pair x m)) :=
      (ah_mem_chi _ _ _).2 (Or.inr ⟨fun hh => (hr1' _).2 hh hR, rfl⟩)
    have hA : A x := (e1 x).2 ⟨m, hR⟩
    have hc1 : c = 1 := by
      rcases hc' with ⟨-, h⟩ | ⟨h, -⟩
      · exact h
      · exact absurd hA h
    subst hc1
    exact Part.mem_bind_iff.2 ⟨0, Part.mem_bind_iff.2 ⟨_, hPm, hv⟩, by simp⟩
  · have hv : 1 ∈ chi HALT (r1 (Nat.pair x m)) :=
      (ah_mem_chi _ _ _).2 (Or.inl ⟨(hr1' _).1 hR, rfl⟩)
    have hR2 : R2 (Nat.pair x m) := by
      by_contra hR2
      exact hm ((hr' _).1 ⟨hR, hR2⟩)
    have hA : ¬ A x := (e2 x).2 ⟨m, hR2⟩
    have hc0 : c = 0 := by
      rcases hc' with ⟨h, -⟩ | ⟨-, h⟩
      · exact absurd h hA
      · exact h
    subst hc0
    exact Part.mem_bind_iff.2 ⟨1, Part.mem_bind_iff.2 ⟨_, hPm, hv⟩, by simp⟩

theorem ah_delta2 {A : ℕ → Prop} : IsSigma 2 A ∧ IsPi 2 A ↔ chi A ≤ᵀ chi HALT := by
  constructor
  · rintro ⟨h1, h2⟩
    exact RecursiveIn.iff_nat.2 (ah_delta2_rin h1 h2)
  · intro h
    have hg := ah_graph ah_hO (RecursiveIn.iff_nat.1 h)
    refine ⟨ah_s2_comp hg (ah_c_pair Computable.id (Computable.const 1)) fun x => ?_,
      ah_s2_comp hg (ah_c_pair Computable.id (Computable.const 0)) fun x => ?_⟩
    · simp [ah_mem_chi]
    · simp [ah_mem_chi]

theorem ah_chi_false : chi (fun _ => False) = fun _ => Part.some 0 := by
  funext x
  unfold chi
  simp

theorem ah_s1_iff_semidec0 {A : ℕ → Prop} :
    IsSigma 1 A ↔ SemidecidableIn (chi fun _ => False) A := by
  rw [ah_s1_iff_code]
  unfold SemidecidableIn
  rw [ah_chi_false]
  constructor
  · rintro ⟨c, hc⟩
    exact ⟨c.eval, RecursiveIn.iff_nat.2
      (Nat.Partrec.recursiveIn (Nat.Partrec.Code.exists_code.2 ⟨c, rfl⟩)), hc⟩
  · rintro ⟨f, hf, e⟩
    obtain ⟨c, rfl⟩ :=
      Nat.Partrec.Code.exists_code.1 (Partrec.nat_iff.1 (RecursiveIn.partrec_of_const hf))
    exact ⟨c, e⟩

theorem ah_s1_re {B : ℕ → Prop} (h : IsSigma 1 B) : REPred B := by
  obtain ⟨c, hc⟩ := ah_s1_iff_code.1 h
  exact (Partrec.nat_iff.2 (Nat.Partrec.Code.exists_code.2 ⟨c, rfl⟩)).dom_re.of_eq
    fun a => (hc a).symm

theorem ah_partrec_chi {A : ℕ → Prop} : Partrec (chi A) ↔ ComputablePred A := by
  classical
  constructor
  · intro h
    have hv : Computable fun x => if A x then 1 else 0 := h
    exact Computable.computablePred
      ((Primrec.eq.decide.to_comp.comp hv (Computable.const 1)).of_eq fun x => by
        by_cases hx : A x <;> simp [hx])
  · intro h
    exact (ComputablePred.ite (Computable.const 1) (Computable.const 0) h).partrec

theorem ah_delta1 {A : ℕ → Prop} : IsSigma 1 A ∧ IsPi 1 A ↔ chi A ≤ᵀ chi fun _ => False := by
  have e1 : (chi A ≤ᵀ chi fun _ => False) ↔ Partrec (chi A) := by
    rw [ah_chi_false]
    exact ⟨fun h => RecursiveIn.partrec_of_const h, fun h => h.recursiveIn⟩
  rw [e1, ah_partrec_chi]
  constructor
  · rintro ⟨h1, h2⟩
    exact ComputablePred.computable_iff_re_compl_re'.2 ⟨ah_s1_re h1, ah_s1_re h2⟩
  · intro h
    exact ⟨ah_s1_of_cp h, ah_s1_of_cp h.not⟩

theorem ah_tot_not_s2 : ¬ IsSigma 2 TOT := by
  intro hT
  have hu : Nat.Partrec fun p => (Denumerable.ofNat Code p.unpair.1).eval p :=
    Partrec.nat_iff.1 (Nat.Partrec.Code.eval_part.comp
      ((Primrec.ofNat Code).to_comp.comp ah_c_fst) Computable.id)
  obtain ⟨u, hu⟩ := Nat.Partrec.Code.exists_code.1 hu
  have hD : IsSigma 2 fun x => TOT (Encodable.encode (Nat.Partrec.Code.curry u x)) :=
    ah_s2_comp hT (Primrec.encode.comp (Nat.Partrec.Code.primrec₂_curry.comp
      (Primrec.const u) Primrec.id)).to_comp fun _ => Iff.rfl
  have hD' : ∀ x, TOT (Encodable.encode (Nat.Partrec.Code.curry u x)) ↔
      ∀ m, ((Denumerable.ofNat Code x).eval (Nat.pair x m)).Dom := by
    intro x
    simp [TOT, Nat.Partrec.Code.eval_curry, hu]
  obtain ⟨R, hR, e⟩ := ah_s2_iff.1 hD
  obtain ⟨c, hc⟩ := ah_s1_iff_code.1 hR
  have key := (hD' (Encodable.encode c)).symm.trans (e (Encodable.encode c))
  simp only [Denumerable.ofNat_encode] at key
  by_cases hall : ∀ m, (c.eval (Nat.pair (Encodable.encode c) m)).Dom
  · obtain ⟨m, hm⟩ := key.1 hall
    exact (hc _).2 (hall m) hm
  · apply hall
    intro m
    exact (hc _).1 fun hm => hall (key.2 ⟨m, hm⟩)

/-! ### The card's claims -/

/-- **Post's theorem, first two levels.** With no oracle (the oracle for the empty set,
`∅⁽⁰⁾`), the `Σ₁` sets are exactly the semidecidable sets, and the sets at both `Σ₁` and `Π₁`
are exactly the decidable ones. With a HALT oracle (degree `0'`), the `Σ₂` sets are exactly the
sets a machine asking HALT can confirm, and the sets at both `Σ₂` and `Π₂` are exactly the sets
that HALT's answers decide. -/
theorem post_theorem_first_two_levels (A : ℕ → Prop) :
    (IsSigma 1 A ↔ SemidecidableIn (chi fun _ => False) A) ∧
    (IsSigma 1 A ∧ IsPi 1 A ↔ chi A ≤ᵀ chi fun _ => False) ∧
    (IsSigma 2 A ↔ SemidecidableIn (chi HALT) A) ∧
    (IsSigma 2 A ∧ IsPi 2 A ↔ chi A ≤ᵀ chi HALT) := by
  exact ⟨ah_s1_iff_semidec0, ah_delta1, ⟨ah_s2_semidec, ah_semidec_s2⟩, ah_delta2⟩

/-- **HALT is at level 1 exactly.** "There is a step at which `e` has stopped" puts HALT in
`Σ₁`, and no definition with one "for every" block exists, so HALT is not in `Π₁`. -/
theorem halt_sigma_one_not_pi_one : IsSigma 1 HALT ∧ ¬ IsPi 1 HALT := by
  refine ⟨ah_halt_s1, fun h => ?_⟩
  obtain ⟨c, hc⟩ := ah_s1_iff_code.1 h
  apply ComputablePred.halting_problem_not_re 0
  have hp : Partrec fun c' : Code => c.eval (Encodable.encode c') :=
    (Partrec.nat_iff.2 (Nat.Partrec.Code.exists_code.2 ⟨c, rfl⟩)).comp Computable.encode
  exact hp.dom_re.of_eq fun c' => by rw [← hc]; simp [HALT]

/-- **TOT is at level 2, beyond any HALT oracle.** "For every input there is a step" puts TOT in
`Π₂`; it is not in `Σ₂`; and no machine with a HALT oracle decides it. -/
theorem tot_pi_two_not_decidable_with_halt_oracle :
    IsPi 2 TOT ∧ ¬ IsSigma 2 TOT ∧ ¬ (chi TOT ≤ᵀ chi HALT) := by
  refine ⟨?_, ah_tot_not_s2, fun h => ah_tot_not_s2 (ah_delta2.2 h).1⟩
  exact ah_s2_iff.2 ⟨fun p => ¬ ((Denumerable.ofNat Code p.unpair.1).eval p.unpair.2).Dom,
    ah_s1_of_iff (ah_s1_eval ah_c_fst ah_c_snd) fun _ => not_not, fun x => by simp [TOT]⟩

/-! ### The card's worked numbers -/

-- `[-]` on input n halts at step 1 + 2n: inputs 0 to 9.
example : (List.range 10).map (fun n => 1 + 2 * n) = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] := by
  decide

-- `[-]-[]` on inputs 0 to 4: `[-]` takes 1 + 2n steps, then `-[]` halts on a blank row at step 2.
example : (List.range 5).map (fun n => 1 + 2 * n + 2) = [3, 5, 7, 9, 11] := by decide

-- A 100-step cap as the HALT oracle: question n is "n plus signs, then `[-]`", which halts at
-- step n + (1 + 2n). The first question past the cap is n = 34 (question 35), at step 103.
example : (List.range 200).find? (fun n => decide (100 < n + (1 + 2 * n))) = some 34 := by decide
example : 34 + (1 + 2 * 34) = 103 ∧ 33 + (1 + 2 * 33) = 100 := by norm_num

-- The reduction check runs over all 451 programs of 1 to 4 symbols from `+ - < > [ ]` whose
-- brackets match. Symbols 0 to 3 are `+ - < >`, 4 is `[` and 5 is `]`.
def words : ℕ → List (List (Fin 6))
  | 0 => [[]]
  | n + 1 => (words n).flatMap fun w => (List.finRange 6).map fun c => w ++ [c]

def bracketsMatch (w : List (Fin 6)) : Bool :=
  (w.foldl (fun (d : Option ℕ) c => d.bind fun d =>
      if c = 4 then some (d + 1) else if c = 5 then (if d = 0 then none else some (d - 1))
      else some d) (some 0)) == some 0

example : (((List.range 4).flatMap fun k => words (k + 1)).filter bracketsMatch).length = 451 := by
  decide +kernel

#print axioms ah_c_fst
#print axioms ah_c_snd
#print axioms ah_c_pair
#print axioms ah_cp_and
#print axioms ah_cp_or
#print axioms ah_cp_comp
#print axioms ah_cp_eq
#print axioms ah_cp_lt
#print axioms ah_s1_iff
#print axioms ah_s1_of_iff
#print axioms ah_s1_of_cp
#print axioms ah_s1_comp
#print axioms ah_s1_and
#print axioms ah_s1_or
#print axioms ah_s1_exists
#print axioms ah_s1_iff_code
#print axioms ah_p1_of_cp
#print axioms ah_p1_comp
#print axioms ah_p1_and
#print axioms ah_p1_or
#print axioms ah_p1_forall
#print axioms ah_p1_ball
#print axioms ah_c_W
#print axioms ah_s2_iff
#print axioms ah_s2_of_iff
#print axioms ah_s2_of_p1
#print axioms ah_s2_of_cp
#print axioms ah_s2_of_s1
#print axioms ah_s2_comp
#print axioms ah_s2_and
#print axioms ah_s2_or
#print axioms ah_s2_exists
#print axioms ah_s2_ball
#print axioms ah_prec_mem
#print axioms ah_W_encode
#print axioms ah_mem_pair
#print axioms ah_mem_rfind
#print axioms ah_graph
#print axioms ah_chi_dom
#print axioms ah_mem_chi
#print axioms ah_chi_some
#print axioms ah_s1_eval
#print axioms ah_halt_s1
#print axioms ah_reduce_halt
#print axioms ah_rin_of_comp
#print axioms ah_rin_oracle_comp
#print axioms ah_graph_halt
#print axioms ah_semidec_s2
#print axioms ah_s2_semidec
#print axioms ah_hO
#print axioms ah_delta2_rin
#print axioms ah_delta2
#print axioms ah_chi_false
#print axioms ah_s1_iff_semidec0
#print axioms ah_s1_re
#print axioms ah_partrec_chi
#print axioms ah_delta1
#print axioms ah_tot_not_s2
#print axioms post_theorem_first_two_levels
#print axioms halt_sigma_one_not_pi_one
#print axioms tot_pi_two_not_decidable_with_halt_oracle
