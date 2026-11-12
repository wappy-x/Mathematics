-- Automatic differentiation: for every program built from addition, subtraction and multiplication, a forward run on dual numbers gives the exact directional slope, and one reverse sweep gives every exact partial derivative of the output for at most 5L operations, where L is the program's number of lines.
import Mathlib.Algebra.DualNumber
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Shift

namespace AutoDiff

/-- The three elementary operations a line may perform. -/
inductive Op
  | add
  | sub
  | mul

/-- An input to a line: an earlier value, by its index (inputs first, then lines),
or a real constant. -/
inductive Arg
  | var (i : ℕ)
  | const (c : ℝ)

/-- One line of a program: `v = a op b`. -/
structure Line where
  op : Op
  a : Arg
  b : Arg

/-- Apply an operation in any commutative real algebra (the reals, or the dual numbers). -/
def Op.apply {R : Type*} [CommRing R] : Op → R → R → R
  | .add, p, q => p + q
  | .sub, p, q => p - q
  | .mul, p, q => p * q

/-- The value an argument reads from the list of values computed so far. -/
def Arg.val {R : Type*} [CommRing R] [Algebra ℝ R] (vs : List R) : Arg → R
  | .var i => vs.getD i 0
  | .const c => algebraMap ℝ R c

/-- Run the program: start from the inputs and append each line's value in order. -/
def run {R : Type*} [CommRing R] [Algebra ℝ R] (P : List Line) (vs : List R) : List R :=
  P.foldl (fun vs l => vs ++ [l.op.apply (l.a.val vs) (l.b.val vs)]) vs

/-- The program's output: the value of its last line (with no lines, the last input). -/
def eval {R : Type*} [CommRing R] [Algebra ℝ R] {n : ℕ} (P : List Line) (x : Fin n → R) : R :=
  (run P (List.ofFn x)).getLastD 0

/-- `Arg.Below m a`: the argument is a constant or reads one of the first `m` values. -/
def Arg.Below (m : ℕ) : Arg → Prop
  | .var i => i < m
  | .const _ => True

/-- The card's programs: line `k` (counting from 0) reads only constants, the `n` inputs,
and the lines before it, so it reads values with index below `n + k`. -/
def WellFormed (n : ℕ) (P : List Line) : Prop :=
  ∀ k (hk : k < P.length), (P[k]'hk).a.Below (n + k) ∧ (P[k]'hk).b.Below (n + k)

/-- Forward mode: run the program on dual numbers `x + v ε` (with `ε² = 0`) and read the
`ε` part (the tangent) of the output. One run, one direction `v`. -/
def forwardMode {n : ℕ} (P : List Line) (x v : Fin n → ℝ) : ℝ :=
  TrivSqZeroExt.snd (eval (R := DualNumber ℝ) P
    (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i)))

/-- The local slopes of `p op q` against `p` and against `q`: no arithmetic needed. -/
def Op.slopes : Op → ℝ → ℝ → ℝ × ℝ
  | .add, _, _ => (1, 1)
  | .sub, _, _ => (1, -1)
  | .mul, p, q => (q, p)

/-- One edge of the sweep: if the argument is a value, add `adjoint × slope` to that value's
adjoint. This performs one multiplication and one addition, so the counter goes up by 2. -/
def sweepEdge (st : (ℕ → ℝ) × ℕ) (arg : Arg) (adj slope : ℝ) : (ℕ → ℝ) × ℕ :=
  match arg with
  | .var i => (Function.update st.1 i (st.1 i + adj * slope), st.2 + 2)
  | .const _ => st

/-- Sweep one line, number `k` in the value list: pass its adjoint back along its two edges. -/
def sweepLine (vs : List ℝ) (k : ℕ) (l : Line) (st : (ℕ → ℝ) × ℕ) : (ℕ → ℝ) × ℕ :=
  let s := l.op.slopes (l.a.val vs) (l.b.val vs)
  sweepEdge (sweepEdge st l.a (st.1 k) s.1) l.b (st.1 k) s.2

/-- The reverse sweep over lines numbered `k, k+1, …`: the later lines are swept first,
so lines are visited last line first. -/
def sweep (vs : List ℝ) : ℕ → List Line → (ℕ → ℝ) × ℕ → (ℕ → ℝ) × ℕ
  | _, [], st => st
  | k, l :: ls, st => sweepLine vs k l (sweep vs (k + 1) ls st)

/-- Reverse mode: record the values (one operation per line, so the counter starts at `L`),
seed the output's adjoint with 1, sweep, and read off the adjoints of the inputs.
Returns the claimed gradient and the number of arithmetic operations performed. -/
def reverseMode {n : ℕ} (P : List Line) (x : Fin n → ℝ) : (Fin n → ℝ) × ℕ :=
  let vs := run P (List.ofFn x)
  let seed : ℕ → ℝ := fun i => if i = vs.length - 1 then 1 else 0
  let st := sweep vs n P (seed, P.length)
  (fun j => st.1 j, st.2)

end AutoDiff

open AutoDiff

namespace AutoDiff

theorem getD_append_single {α : Type*} (l : List α) (a d : α) (i : ℕ) :
    (l ++ [a]).getD i d = if i < l.length then l.getD i d else if i = l.length then a else d := by
  simp only [List.getD_eq_getElem?_getD]
  split_ifs with h1 h2
  · rw [List.getElem?_append_left h1]
  · subst h2; simp
  · rw [List.getElem?_append_right (by omega)]
    have : i - l.length ≠ 0 := by omega
    simp [this]

theorem run_cons {R : Type*} [CommRing R] [Algebra ℝ R] (l : Line) (P : List Line) (vs : List R) :
    run (l :: P) vs = run P (vs ++ [l.op.apply (l.a.val vs) (l.b.val vs)]) := rfl

theorem run_nil {R : Type*} [CommRing R] [Algebra ℝ R] (vs : List R) : run [] vs = vs := rfl

theorem run_prefix {R : Type*} [CommRing R] [Algebra ℝ R] (P : List Line) (vs : List R) :
    ∃ rest, run P vs = vs ++ rest := by
  induction P generalizing vs with
  | nil => exact ⟨[], by simp [run_nil]⟩
  | cons l P ih =>
    obtain ⟨rest, h⟩ := ih (vs ++ [l.op.apply (l.a.val vs) (l.b.val vs)])
    exact ⟨l.op.apply (l.a.val vs) (l.b.val vs) :: rest, by rw [run_cons, h]; simp⟩

theorem length_run {R : Type*} [CommRing R] [Algebra ℝ R] (P : List Line) (vs : List R) :
    (run P vs).length = vs.length + P.length := by
  induction P generalizing vs with
  | nil => simp [run_nil]
  | cons l P ih => rw [run_cons, ih]; simp; omega

theorem getD_run_of_lt {R : Type*} [CommRing R] [Algebra ℝ R] (P : List Line) (vs : List R)
    (i : ℕ) (hi : i < vs.length) : (run P vs).getD i 0 = vs.getD i 0 := by
  obtain ⟨rest, h⟩ := run_prefix P vs
  rw [h]
  simp only [List.getD_eq_getElem?_getD, List.getElem?_append_left hi]

theorem val_run_of_below {R : Type*} [CommRing R] [Algebra ℝ R] (P : List Line) (vs : List R)
    (a : Arg) (ha : a.Below vs.length) : a.val (run P vs) = a.val vs := by
  cases a with
  | var i => exact getD_run_of_lt P vs i ha
  | const c => rfl

theorem getLastD_eq_getD {α : Type*} (l : List α) (d : α) :
    l.getLastD d = l.getD (l.length - 1) d := by
  rw [List.getLastD_eq_getLast?, List.getLast?_eq_getElem?, List.getD_eq_getElem?_getD]

/-- The tangent of an argument read from a dual-number list. -/
theorem fwd_arg (vs : ℝ → List ℝ) (D : List (DualNumber ℝ))
    (hfst : ∀ i, (D.getD i 0).fst = (vs 0).getD i 0)
    (hder : ∀ i, HasDerivAt (fun t => (vs t).getD i 0) (D.getD i 0).snd 0) (a : Arg) :
    (a.val D).fst = a.val (vs 0) ∧ HasDerivAt (fun t => a.val (vs t)) (a.val D).snd 0 := by
  cases a with
  | var i => exact ⟨hfst i, hder i⟩
  | const c =>
    simp only [Arg.val, TrivSqZeroExt.algebraMap_eq_inl, TrivSqZeroExt.fst_inl,
      TrivSqZeroExt.snd_inl, Algebra.algebraMap_self, RingHom.id_apply]
    exact ⟨trivial, hasDerivAt_const _ _⟩

theorem fwd_op (o : Op) (p q : DualNumber ℝ) (fp fq : ℝ → ℝ)
    (hp : p.fst = fp 0) (hq : q.fst = fq 0)
    (hdp : HasDerivAt fp p.snd 0) (hdq : HasDerivAt fq q.snd 0) :
    (o.apply p q).fst = o.apply (fp 0) (fq 0) ∧
      HasDerivAt (fun t => o.apply (fp t) (fq t)) (o.apply p q).snd 0 := by
  cases o with
  | add =>
    refine ⟨by simp [Op.apply, hp, hq], ?_⟩
    simp only [Op.apply, TrivSqZeroExt.snd_add]
    exact HasDerivAt.add hdp hdq
  | sub =>
    refine ⟨by simp [Op.apply, hp, hq], ?_⟩
    simp only [Op.apply, TrivSqZeroExt.snd_sub]
    exact HasDerivAt.sub hdp hdq
  | mul =>
    refine ⟨by simp [Op.apply, hp, hq], ?_⟩
    have := HasDerivAt.mul hdp hdq
    simp only [Op.apply, DualNumber.snd_mul, hp, hq]
    convert this using 1
    ring

theorem fwd_aux (P : List Line) (vs : ℝ → List ℝ) (D : List (DualNumber ℝ))
    (hlen : ∀ t, (vs t).length = D.length)
    (hfst : ∀ i, (D.getD i 0).fst = (vs 0).getD i 0)
    (hder : ∀ i, HasDerivAt (fun t => (vs t).getD i 0) (D.getD i 0).snd 0) :
    (∀ i, ((run P D).getD i 0).fst = (run P (vs 0)).getD i 0) ∧
      ∀ i, HasDerivAt (fun t => (run P (vs t)).getD i 0) ((run P D).getD i 0).snd 0 := by
  induction P generalizing vs D with
  | nil => exact ⟨hfst, hder⟩
  | cons l P ih =>
    simp only [run_cons]
    obtain ⟨ha1, ha2⟩ := fwd_arg vs D hfst hder l.a
    obtain ⟨hb1, hb2⟩ := fwd_arg vs D hfst hder l.b
    obtain ⟨ho1, ho2⟩ := fwd_op l.op _ _ _ _ ha1 hb1 ha2 hb2
    refine ih (fun t => vs t ++ [l.op.apply (l.a.val (vs t)) (l.b.val (vs t))]) _ ?_ ?_ ?_
    · intro t; simp [hlen t]
    · intro i
      rw [getD_append_single, getD_append_single, hlen 0]
      split_ifs
      · exact hfst i
      · exact ho1
      · simp
    · intro i
      have hfun : (fun t => ((vs t) ++ [l.op.apply (l.a.val (vs t)) (l.b.val (vs t))]).getD i 0)
          = fun t => if i < D.length then (vs t).getD i 0 else if i = D.length then
              l.op.apply (l.a.val (vs t)) (l.b.val (vs t)) else 0 := by
        funext t; rw [getD_append_single, hlen t]
      rw [hfun, getD_append_single]
      split_ifs
      · exact hder i
      · exact ho2
      · simpa using hasDerivAt_const (0 : ℝ) (0 : ℝ)


theorem fwd_core (n : ℕ) (P : List Line) (x v : Fin n → ℝ) :
    (∀ i, ((run P (List.ofFn (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i) :
        Fin n → DualNumber ℝ))).getD i 0).fst = (run P (List.ofFn x)).getD i 0) ∧
    ∀ i, HasDerivAt (fun t : ℝ => (run P (List.ofFn (x + t • v))).getD i 0)
      ((run P (List.ofFn (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i) :
        Fin n → DualNumber ℝ))).getD i 0).snd 0 := by
  have h2 : ∀ i, ((List.ofFn (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i) :
      Fin n → DualNumber ℝ)).getD i 0).fst = (List.ofFn (x + (0 : ℝ) • v)).getD i 0 := by
    intro i
    by_cases h : i < n
    · simp [List.getD_eq_getElem?_getD, h]
    · simp [List.getD_eq_getElem?_getD, h]
  have h3 : ∀ i, HasDerivAt (fun t : ℝ => (List.ofFn (x + t • v)).getD i 0)
      ((List.ofFn (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i) :
        Fin n → DualNumber ℝ)).getD i 0).snd 0 := by
    intro i
    by_cases h : i < n
    · simp only [List.getD_eq_getElem?_getD, List.getElem?_ofFn, h, dite_true, Option.getD_some,
        Pi.add_apply, Pi.smul_apply, smul_eq_mul, TrivSqZeroExt.snd_add, TrivSqZeroExt.snd_inl,
        TrivSqZeroExt.snd_inr, zero_add]
      simpa using ((hasDerivAt_id (0 : ℝ)).mul_const (v ⟨i, h⟩)).const_add (x ⟨i, h⟩)
    · simp only [List.getD_eq_getElem?_getD, List.getElem?_ofFn, h, dite_false, Option.getD_none]
      simpa using hasDerivAt_const (0 : ℝ) (0 : ℝ)
  obtain ⟨a, b⟩ := fwd_aux P (fun t => List.ofFn (x + t • v))
    (List.ofFn (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i) : Fin n → DualNumber ℝ))
    (by intro t; simp) h2 h3
  refine ⟨fun i => ?_, b⟩
  have := a i
  simp only [zero_smul, add_zero] at this
  exact this

theorem forward_eq (n : ℕ) (P : List Line) (x v : Fin n → ℝ) :
    HasDerivAt (fun t : ℝ => eval P (x + t • v)) (forwardMode P x v) 0 := by
  have h := (fwd_core n P x v).2 (n + P.length - 1)
  have e1 : (fun t : ℝ => eval P (x + t • v)) =
      fun t : ℝ => (run P (List.ofFn (x + t • v))).getD (n + P.length - 1) 0 := by
    funext t
    rw [eval, getLastD_eq_getD, length_run, List.length_ofFn]
  rw [e1]
  convert h using 1
  rw [forwardMode, eval, getLastD_eq_getD, length_run, List.length_ofFn]

/-- One edge of the sweep, measured against the tangents `T i = snd (Dd.getD i 0)`. -/
theorem sweepEdge_sum (Dd : List (DualNumber ℝ)) (st : (ℕ → ℝ) × ℕ) (a : Arg) (adj s : ℝ)
    (k : ℕ) (ha : a.Below k) :
    ∑ i ∈ Finset.range k, (sweepEdge st a adj s).1 i * (Dd.getD i 0).snd =
      ∑ i ∈ Finset.range k, st.1 i * (Dd.getD i 0).snd + adj * s * (a.val Dd).snd := by
  cases a with
  | const c =>
    simp [sweepEdge, Arg.val, TrivSqZeroExt.algebraMap_eq_inl]
  | var j =>
    have hj : j < k := ha
    simp only [sweepEdge, Arg.val]
    have hterm : ∀ r, Function.update st.1 j (st.1 j + adj * s) r * (Dd.getD r 0).snd =
        st.1 r * (Dd.getD r 0).snd + if r = j then adj * s * (Dd.getD j 0).snd else 0 := by
      intro r
      by_cases h : r = j
      · subst h; simp; ring
      · simp [h]
    simp only [hterm, Finset.sum_add_distrib, Finset.sum_ite_eq', Finset.mem_range, hj, ite_true]

theorem sweepEdge_count (st : (ℕ → ℝ) × ℕ) (a : Arg) (adj s : ℝ) :
    (sweepEdge st a adj s).2 ≤ st.2 + 2 := by
  cases a <;> simp [sweepEdge]

theorem fst_val (Dd : List (DualNumber ℝ)) (Vr : List ℝ)
    (hfst : ∀ i, (Dd.getD i 0).fst = Vr.getD i 0) (a : Arg) : (a.val Dd).fst = a.val Vr := by
  cases a with
  | var i => exact hfst i
  | const c => simp [Arg.val, TrivSqZeroExt.algebraMap_eq_inl]

theorem slopes_snd (o : Op) (p q : DualNumber ℝ) :
    (o.slopes p.fst q.fst).1 * p.snd + (o.slopes p.fst q.fst).2 * q.snd = (o.apply p q).snd := by
  cases o <;> simp [Op.slopes, Op.apply] <;> ring

theorem sweepLine_sum (Dd : List (DualNumber ℝ)) (Vr : List ℝ)
    (hfst : ∀ i, (Dd.getD i 0).fst = Vr.getD i 0) (k : ℕ) (l : Line) (st : (ℕ → ℝ) × ℕ)
    (ha : l.a.Below k) (hb : l.b.Below k)
    (hk : (Dd.getD k 0).snd = (l.op.apply (l.a.val Dd) (l.b.val Dd)).snd) :
    ∑ i ∈ Finset.range k, (sweepLine Vr k l st).1 i * (Dd.getD i 0).snd =
      ∑ i ∈ Finset.range (k + 1), st.1 i * (Dd.getD i 0).snd := by
  simp only [sweepLine]
  rw [sweepEdge_sum Dd _ l.b _ _ k hb, sweepEdge_sum Dd _ l.a _ _ k ha, Finset.sum_range_succ, hk,
    ← slopes_snd, fst_val Dd Vr hfst, fst_val Dd Vr hfst]
  ring

theorem sweep_sum (Dd : List (DualNumber ℝ)) (Vr : List ℝ)
    (hfst : ∀ i, (Dd.getD i 0).fst = Vr.getD i 0) (ls : List Line) (W : List (DualNumber ℝ))
    (st : (ℕ → ℝ) × ℕ) (hrun : run ls W = Dd)
    (hwf : ∀ q (hq : q < ls.length),
      (ls[q]'hq).a.Below (W.length + q) ∧ (ls[q]'hq).b.Below (W.length + q)) :
    ∑ i ∈ Finset.range W.length, (sweep Vr W.length ls st).1 i * (Dd.getD i 0).snd =
      ∑ i ∈ Finset.range (W.length + ls.length), st.1 i * (Dd.getD i 0).snd := by
  induction ls generalizing W with
  | nil => rfl
  | cons l ls ih =>
    have h0 := hwf 0 (by simp)
    simp only [List.getElem_cons_zero, add_zero] at h0
    set W' := W ++ [l.op.apply (l.a.val W) (l.b.val W)] with hW'
    have hlen : W'.length = W.length + 1 := by simp [hW']
    have hrun' : run ls W' = Dd := by rw [← hrun, run_cons]
    have hwf' : ∀ q (hq : q < ls.length),
        (ls[q]'hq).a.Below (W'.length + q) ∧ (ls[q]'hq).b.Below (W'.length + q) := by
      intro q hq
      have := hwf (q + 1) (by simp; omega)
      simp only [List.getElem_cons_succ] at this
      rw [hlen]
      simpa [Nat.add_assoc, Nat.add_comm 1 q] using this
    have ih' := ih W' hrun' hwf'
    rw [hlen] at ih'
    show ∑ i ∈ Finset.range W.length,
        (sweepLine Vr W.length l (sweep Vr (W.length + 1) ls st)).1 i * (Dd.getD i 0).snd = _
    rw [sweepLine_sum Dd Vr hfst W.length l _ h0.1 h0.2, ih']
    · simp only [List.length_cons]; ring_nf
    · have hval : ∀ a : Arg, a.Below W.length → a.val Dd = a.val W := by
        intro a ha
        rw [← hrun]
        exact val_run_of_below (l :: ls) W a ha
      rw [hval _ h0.1, hval _ h0.2, ← hrun', getD_run_of_lt ls W' W.length (by simp [hW']),
        hW', getD_append_single]
      simp

theorem sweep_count (Vr : List ℝ) (k : ℕ) (ls : List Line) (st : (ℕ → ℝ) × ℕ) :
    (sweep Vr k ls st).2 ≤ st.2 + 4 * ls.length := by
  induction ls generalizing k with
  | nil => simp [sweep]
  | cons l ls ih =>
    simp only [sweep, sweepLine]
    have h1 := sweepEdge_count (sweep Vr (k + 1) ls st) l.a
      ((sweep Vr (k + 1) ls st).1 k) (l.op.slopes (l.a.val Vr) (l.b.val Vr)).1
    have h2 := sweepEdge_count (sweepEdge (sweep Vr (k + 1) ls st) l.a
      ((sweep Vr (k + 1) ls st).1 k) (l.op.slopes (l.a.val Vr) (l.b.val Vr)).1) l.b
      ((sweep Vr (k + 1) ls st).1 k) (l.op.slopes (l.a.val Vr) (l.b.val Vr)).2
    have h3 := ih (k + 1)
    simp only [List.length_cons]
    omega

theorem reverse_eq_forward (n : ℕ) (P : List Line) (hP : WellFormed n P) (x : Fin n → ℝ)
    (j : Fin n) : (reverseMode P x).1 j = forwardMode P x (Pi.single j 1) := by
  set v : Fin n → ℝ := Pi.single j 1 with hv
  set D0 : List (DualNumber ℝ) := List.ofFn
    (fun i => TrivSqZeroExt.inl (x i) + TrivSqZeroExt.inr (v i) : Fin n → DualNumber ℝ) with hD0
  have hfst := (fwd_core n P x v).1
  have hlenD : D0.length = n := by simp [hD0]
  have hlenV : (run P (List.ofFn x)).length = n + P.length := by simp [length_run]
  have hS := sweep_sum (run P D0) (run P (List.ofFn x)) hfst P D0
    ((fun i => if i = (run P (List.ofFn x)).length - 1 then 1 else 0), P.length) rfl
    (by rw [hlenD]; exact hP)
  rw [hlenD] at hS
  have hin : ∀ i, i < n → ((run P D0).getD i 0).snd = if i = (j : ℕ) then 1 else 0 := by
    intro i hi
    rw [getD_run_of_lt P D0 i (by rw [hlenD]; exact hi), hD0]
    simp only [List.getD_eq_getElem?_getD, List.getElem?_ofFn, hi, dite_true, Option.getD_some,
      TrivSqZeroExt.snd_add, TrivSqZeroExt.snd_inl, TrivSqZeroExt.snd_inr, zero_add, hv]
    by_cases h : i = (j : ℕ)
    · subst h; simp
    · have : (⟨i, hi⟩ : Fin n) ≠ j := fun e => h (by rw [← e])
      simp [h, this]
  have hnL : 1 ≤ n + P.length := by have := j.2; omega
  calc (reverseMode P x).1 j
      = (sweep (run P (List.ofFn x)) n P
          ((fun i => if i = (run P (List.ofFn x)).length - 1 then 1 else 0), P.length)).1 j := rfl
    _ = ∑ i ∈ Finset.range n, (sweep (run P (List.ofFn x)) n P
          ((fun i => if i = (run P (List.ofFn x)).length - 1 then 1 else 0), P.length)).1 i *
            ((run P D0).getD i 0).snd := by
        rw [Finset.sum_eq_single_of_mem (j : ℕ) (by simp)]
        · rw [hin j j.2]; simp
        · intro i hi hij
          rw [hin i (Finset.mem_range.1 hi)]; simp [hij]
    _ = ∑ i ∈ Finset.range (n + P.length),
          (if i = (run P (List.ofFn x)).length - 1 then (1 : ℝ) else 0) *
            ((run P D0).getD i 0).snd := hS
    _ = ((run P D0).getD (n + P.length - 1) 0).snd := by
        rw [hlenV, Finset.sum_eq_single_of_mem (n + P.length - 1) (by simp; omega)]
        · simp
        · intro i _ hi
          simp [hi]
    _ = forwardMode P x v := by
        rw [forwardMode, eval, getLastD_eq_getD, length_run, hD0, List.length_ofFn]

end AutoDiff

#print axioms getD_append_single
#print axioms run_cons
#print axioms run_nil
#print axioms run_prefix
#print axioms length_run
#print axioms getD_run_of_lt
#print axioms val_run_of_below
#print axioms getLastD_eq_getD
#print axioms fwd_arg
#print axioms fwd_op
#print axioms fwd_aux
#print axioms fwd_core
#print axioms forward_eq
#print axioms sweepEdge_sum
#print axioms sweepEdge_count
#print axioms fst_val
#print axioms slopes_snd
#print axioms sweepLine_sum
#print axioms sweep_sum
#print axioms sweep_count
#print axioms reverse_eq_forward

/-- **Reverse mode: every partial derivative for at most five evaluations.** For every program
with `n` inputs and `L` lines, each line an addition, subtraction or multiplication of earlier
values or constants, and every input point `x`: the reverse sweep's adjoint of each input `j`
is exactly the partial derivative of the output against `x_j` (the other inputs held still),
and the whole computation (recording plus sweep) takes at most `5L` operations, a bound that
does not depend on `n`. -/
theorem reverse_mode_gives_every_partial_within_five_evaluations
    (n : ℕ) (P : List Line) (hP : WellFormed n P) (x : Fin n → ℝ) :
    (∀ j : Fin n, HasDerivAt (fun t : ℝ => eval P (Function.update x j t))
        ((reverseMode P x).1 j) (x j)) ∧
      (reverseMode P x).2 ≤ 5 * P.length := by
  refine ⟨fun j => ?_, ?_⟩
  · rw [AutoDiff.reverse_eq_forward n P hP x j]
    have h := AutoDiff.forward_eq n P x (Pi.single j 1)
    have hfun : (fun t : ℝ => eval P (Function.update x j t)) =
        fun t : ℝ => (fun s : ℝ => eval P (x + s • Pi.single j (1 : ℝ))) (t - x j) := by
      funext t
      congr 1
      funext i
      by_cases hi : i = j
      · subst hi; simp
      · simp [hi]
    rw [hfun]
    exact HasDerivAt.comp_sub_const (f := fun s : ℝ => eval P (x + s • Pi.single j (1 : ℝ)))
      (x j) (x j) (by rw [sub_self]; exact h)
  · simp only [reverseMode]
    refine le_trans (AutoDiff.sweep_count _ _ _ _) ?_
    simp only
    omega

/-- **Forward mode: one directional slope per run.** For every program built from addition,
subtraction and multiplication, every point `x` and every direction `v`, running the program
on dual numbers `x + v ε` gives in its `ε` part exactly the slope of the output along `v`:
the derivative of `t ↦ f(x + t v)` at `t = 0`. -/
theorem forward_mode_gives_directional_slope
    (n : ℕ) (P : List Line) (hP : WellFormed n P) (x v : Fin n → ℝ) :
    HasDerivAt (fun t : ℝ => eval P (x + t • v)) (forwardMode P x v) 0 := by
  exact AutoDiff.forward_eq n P x v

/-- The card's 2-D valley as a program: inputs `x` (index 0) and `y` (index 1), then the seven
lines `s = x·x`, `d = y − s`, `c = 1 − x`, `dd = d·d`, `t = 100·dd`, `u = c·c`, `f = t + u`. -/
def rosen2 : List Line :=
  [⟨.mul, .var 0, .var 0⟩, ⟨.sub, .var 1, .var 2⟩, ⟨.sub, .const 1, .var 0⟩,
   ⟨.mul, .var 3, .var 3⟩, ⟨.mul, .const 100, .var 5⟩, ⟨.mul, .var 4, .var 4⟩,
   ⟨.add, .var 6, .var 7⟩]

-- At the start (x, y) = (−1.2, 1) = (−6/5, 1) the program's height is 24.2 = 121/5.
example : eval rosen2 ![(-6/5 : ℝ), 1] = 121 / 5 := by
  simp [eval, run, rosen2, Op.apply, Arg.val, List.ofFn_succ]
  norm_num

-- The reverse sweep's gradient there is (−215.6, −88) = (−1078/5, −88).
example : (reverseMode rosen2 ![(-6/5 : ℝ), 1]).1 = ![-1078 / 5, -88] := by
  ext j
  fin_cases j <;>
  simp [reverseMode, run, rosen2, Op.apply, Arg.val, List.ofFn_succ, sweep, sweepLine, sweepEdge,
    Op.slopes, Function.update] <;>
  norm_num

-- The hand formula agrees: −400x(y − x²) − 2(1 − x) = −215.6 and 200(y − x²) = −88.
example : -400 * (-6/5 : ℚ) * (1 - (-6/5) ^ 2) - 2 * (1 - (-6/5)) = -1078 / 5 ∧
    200 * (1 - (-6/5 : ℚ) ^ 2) = -88 := by
  norm_num

-- Seeding both tangents at once gives ∂f/∂x + ∂f/∂y = −215.6 − 88 = −303.6, not a gradient.
example : (-1078 / 5 : ℚ) + (-88) = -1518 / 5 := by norm_num

-- The 50-variable valley at (−1.2, 1, −1.2, 1, …): 49 linked bananas, height exactly 12,221.
example : (∑ i ∈ Finset.range 49,
    (100 * ((if (i + 1) % 2 = 0 then (-6/5 : ℚ) else 1) -
      (if i % 2 = 0 then (-6/5 : ℚ) else 1) ^ 2) ^ 2 +
     (1 - (if i % 2 = 0 then (-6/5 : ℚ) else 1)) ^ 2)) = 12221 := by
  norm_num [Finset.sum_range_succ]

-- Partials 2 and 3 of the 50-variable valley, by the hand formula
-- 200(x_i − x_{i−1}²) − 400 x_i (x_{i+1} − x_i²) − 2(1 − x_i): 792 and −655.6 = −3278/5.
example : 200 * (1 - (-6/5 : ℚ) ^ 2) - 400 * 1 * (-6/5 - 1 ^ 2) - 2 * (1 - 1) = 792 ∧
    200 * (-6/5 - (1 : ℚ) ^ 2) - 400 * (-6/5) * (1 - (-6/5) ^ 2) - 2 * (1 - (-6/5)) = -3278 / 5 := by
  norm_num

-- Operation counts: one evaluation at n = 50 is 8·49 − 1 = 391 operations; reverse mode is
-- 5 × 391 = 1,955; central differences 2 × 50 × 391 = 39,100. At n = 2: 7 operations,
-- reverse 35, central 28, so reverse mode is not cheaper there.
example : 8 * (50 - 1) - 1 = 391 ∧ 5 * 391 = 1955 ∧ 2 * 50 * 391 = 39100 ∧
    8 * (2 - 1) - 1 = 7 ∧ 5 * 7 = 35 ∧ 2 * 2 * 7 = 28 ∧ 28 < 35 := by
  decide

#print axioms reverse_mode_gives_every_partial_within_five_evaluations
#print axioms forward_mode_gives_directional_slope
