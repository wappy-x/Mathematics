-- Classifying states: in a Markov chain with finitely many states, a state is recurrent exactly when its communicating class is closed, states that communicate share their period and their recurrence, and some class is always closed.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Topology.Algebra.InfiniteSum.ENNReal
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.SpecificLimits.Basic

open scoped ENNReal

variable {S : Type*} [Fintype S] [DecidableEq S]

/-- `i` leads to `j`: some number of turns `n ≥ 0`, possibly none, gives a positive chance of
going from `i` to `j`, that is `(P^n)_ij > 0`. -/
def Leads (P : Matrix S S ℝ≥0∞) (i j : S) : Prop := ∃ n : ℕ, 0 < (P ^ n) i j

/-- `i` and `j` communicate: each leads to the other. -/
def Communicate (P : Matrix S S ℝ≥0∞) (i j : S) : Prop := Leads P i j ∧ Leads P j i

/-- The communicating class of `i` is closed: no arrow leaves it. Whenever `j` is in the class
and `p_jk > 0`, then `k` is in the class too. -/
def ClassClosed (P : Matrix S S ℝ≥0∞) (i : S) : Prop :=
  ∀ j k : S, Communicate P i j → 0 < P j k → Communicate P i k

/-- The chain with every arrow into `i` removed: the one-turn chances of moving without
landing on `i`. -/
def avoid (P : Matrix S S ℝ≥0∞) (i : S) : Matrix S S ℝ≥0∞ :=
  Matrix.of fun k l => if l = i then 0 else P k l

/-- The return chance `f_i = P_i(T_i < ∞)`: summed over `n ≥ 0`, the chance that a token started
on `i` spends `n` turns off `i` and then steps back onto `i` at turn `n + 1`. -/
noncomputable def returnChance (P : Matrix S S ℝ≥0∞) (i : S) : ℝ≥0∞ :=
  ∑' n : ℕ, ((avoid P i ^ n) * P) i i

/-- `i` is recurrent when a token started there comes back with chance 1. -/
def Recurrent (P : Matrix S S ℝ≥0∞) (i : S) : Prop := returnChance P i = 1

/-- `d` divides every turn count `n ≥ 1` in which a return to `i` is possible. The period
`d(i)` is the greatest such `d`, so two states with the same such `d` have the same period. -/
def DividesReturns (P : Matrix S S ℝ≥0∞) (i : S) (d : ℕ) : Prop :=
  ∀ n : ℕ, 0 < n → 0 < (P ^ n) i i → d ∣ n

lemma cs_mul_pos {M N : Matrix S S ℝ≥0∞} {a b c : S} (h1 : 0 < M a b) (h2 : 0 < N b c) :
    0 < (M * N) a c := by
  rw [Matrix.mul_apply]
  calc (0:ℝ≥0∞) < M a b * N b c := ENNReal.mul_pos h1.ne' h2.ne'
    _ ≤ ∑ x, M a x * N x c :=
      Finset.single_le_sum (f := fun x => M a x * N x c) (fun _ _ => zero_le)
        (Finset.mem_univ b)

lemma cs_pow_add_pos {P : Matrix S S ℝ≥0∞} {m n : ℕ} {a b c : S} (h1 : 0 < (P ^ m) a b)
    (h2 : 0 < (P ^ n) b c) : 0 < (P ^ (m + n)) a c := by
  rw [pow_add]; exact cs_mul_pos h1 h2

lemma cs_exists_pos {f : S → ℝ≥0∞} (h : 0 < ∑ x, f x) : ∃ x, 0 < f x := by
  obtain ⟨x, -, hx⟩ := Finset.sum_pos_iff.mp h
  exact ⟨x, hx⟩

lemma cs_leads_refl (P : Matrix S S ℝ≥0∞) (i : S) : Leads P i i := ⟨0, by simp⟩

lemma cs_leads_trans {P : Matrix S S ℝ≥0∞} {a b c : S} (h1 : Leads P a b) (h2 : Leads P b c) :
    Leads P a c := by
  obtain ⟨m, hm⟩ := h1
  obtain ⟨n, hn⟩ := h2
  exact ⟨m + n, cs_pow_add_pos hm hn⟩

lemma cs_leads_step {P : Matrix S S ℝ≥0∞} {a b c : S} (h1 : Leads P a b) (h2 : 0 < P b c) :
    Leads P a c :=
  cs_leads_trans h1 ⟨1, by simpa using h2⟩

lemma cs_comm_refl (P : Matrix S S ℝ≥0∞) (i : S) : Communicate P i i :=
  ⟨cs_leads_refl P i, cs_leads_refl P i⟩

lemma cs_comm_symm {P : Matrix S S ℝ≥0∞} {a b : S} (h : Communicate P a b) : Communicate P b a :=
  ⟨h.2, h.1⟩

lemma cs_comm_trans {P : Matrix S S ℝ≥0∞} {a b c : S} (h1 : Communicate P a b)
    (h2 : Communicate P b c) : Communicate P a c :=
  ⟨cs_leads_trans h1.1 h2.1, cs_leads_trans h2.2 h1.2⟩

lemma cs_closed_iff {P : Matrix S S ℝ≥0∞} {i j : S} (h : Communicate P i j) :
    ClassClosed P i ↔ ClassClosed P j := by
  have key : ∀ a, Communicate P i a ↔ Communicate P j a := fun a =>
    ⟨fun ha => cs_comm_trans (cs_comm_symm h) ha, fun ha => cs_comm_trans h ha⟩
  simp only [ClassClosed, key]

lemma cs_divides_of_comm {P : Matrix S S ℝ≥0∞} {i j : S} (h : Communicate P i j) {d : ℕ}
    (hd : DividesReturns P i d) : DividesReturns P j d := by
  obtain ⟨⟨a, ha⟩, ⟨b, hb⟩⟩ := h
  intro n hn hjj
  by_cases hab : a + b = 0
  · have ha0 : a = 0 := by omega
    subst ha0
    have hij : i = j := by
      by_contra hne
      simp [Matrix.one_apply_ne hne] at ha
    subst hij
    exact hd n hn hjj
  · have h1 : d ∣ a + b := hd _ (Nat.pos_of_ne_zero hab) (cs_pow_add_pos ha hb)
    have h2 : d ∣ a + n + b := hd _ (by omega) (cs_pow_add_pos (cs_pow_add_pos ha hjj) hb)
    have he : a + n + b = (a + b) + n := by ring
    rw [he] at h2
    exact (Nat.dvd_add_right h1).mp h2

lemma cs_avoid_le (P : Matrix S S ℝ≥0∞) (i k l : S) : avoid P i k l ≤ P k l := by
  unfold avoid
  simp only [Matrix.of_apply]
  split_ifs <;> simp

lemma cs_avoid_pow_le (P : Matrix S S ℝ≥0∞) (i : S) (n : ℕ) (k l : S) :
    (avoid P i ^ n) k l ≤ (P ^ n) k l := by
  induction n generalizing l with
  | zero => simp
  | succ n ih =>
    rw [pow_succ, pow_succ, Matrix.mul_apply, Matrix.mul_apply]
    exact Finset.sum_le_sum fun x _ => mul_le_mul' (ih x) (cs_avoid_le P i x l)

lemma cs_avoid_row (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i m : S) :
    ∑ l, avoid P i m l + P m i = 1 := by
  rw [← hP m]
  have hsplit : ∀ l, P m l = avoid P i m l + (if l = i then P m l else 0) := by
    intro l
    unfold avoid
    simp only [Matrix.of_apply]
    split_ifs <;> simp
  rw [Finset.sum_congr rfl (fun l _ => hsplit l), Finset.sum_add_distrib]
  simp

lemma cs_surv_step (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i k : S) (n : ℕ) :
    ∑ l, (avoid P i ^ (n + 1)) k l + ((avoid P i ^ n) * P) k i =
      ∑ l, (avoid P i ^ n) k l := by
  rw [pow_succ]
  simp only [Matrix.mul_apply]
  rw [Finset.sum_comm, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun m _ => ?_
  rw [← Finset.mul_sum, ← mul_add, cs_avoid_row P hP i m, mul_one]

lemma cs_partial (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i k : S) (n : ℕ) :
    ∑ m ∈ Finset.range n, ((avoid P i ^ m) * P) k i + ∑ l, (avoid P i ^ n) k l = 1 := by
  induction n with
  | zero => simp [Matrix.one_apply]
  | succ n ih =>
    rw [Finset.sum_range_succ, add_assoc, add_comm (((avoid P i ^ n) * P) k i),
      cs_surv_step P hP i k n, ih]

lemma cs_surv_add (Q : Matrix S S ℝ≥0∞) (a b : ℕ) (k : S) :
    ∑ m, (Q ^ (a + b)) k m = ∑ l, (Q ^ a) k l * ∑ m, (Q ^ b) l m := by
  simp only [pow_add, Matrix.mul_apply, Finset.mul_sum]
  exact Finset.sum_comm

lemma cs_avoid_path (P : Matrix S S ℝ≥0∞) (i : S) :
    ∀ (n : ℕ) (k : S), 0 < (P ^ n) i k → ∃ a, 0 < (avoid P i ^ a) i k := by
  intro n
  induction n with
  | zero => intro k hk; exact ⟨0, by simpa using hk⟩
  | succ n ih =>
    intro k hk
    rw [pow_succ, Matrix.mul_apply] at hk
    obtain ⟨m, hm⟩ := cs_exists_pos hk
    obtain ⟨h1, h2⟩ := ENNReal.mul_pos_iff.mp hm
    by_cases hki : k = i
    · rw [hki]; exact ⟨0, by simp⟩
    · obtain ⟨a, ha⟩ := ih m h1
      refine ⟨a + 1, ?_⟩
      rw [pow_succ]
      apply cs_mul_pos ha
      simpa [avoid, hki] using h2

lemma cs_first_hit (P : Matrix S S ℝ≥0∞) (i : S) :
    ∀ (n : ℕ) (k : S), 0 < (P ^ (n + 1)) k i → ∃ m, 0 < ((avoid P i ^ m) * P) k i := by
  intro n
  induction n with
  | zero => intro k hk; exact ⟨0, by simpa using hk⟩
  | succ n ih =>
    intro k hk
    rw [pow_succ', Matrix.mul_apply] at hk
    obtain ⟨l, hl⟩ := cs_exists_pos hk
    obtain ⟨h1, h2⟩ := ENNReal.mul_pos_iff.mp hl
    by_cases hli : l = i
    · rw [hli] at h1; exact ⟨0, by simpa using h1⟩
    · obtain ⟨m, hm⟩ := ih l h2
      refine ⟨m + 1, ?_⟩
      rw [pow_succ', Matrix.mul_assoc]
      apply cs_mul_pos _ hm
      simpa [avoid, hli] using h1

lemma cs_return_le_one (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i : S) :
    returnChance P i ≤ 1 := by
  unfold returnChance
  rw [ENNReal.tsum_eq_iSup_nat]
  refine iSup_le fun n => ?_
  calc _ ≤ _ := le_self_add
    _ = 1 := cs_partial P hP i i n

/-- Transient direction: an exit from the class keeps the return chance below 1. -/
lemma cs_return_lt_one (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i k : S)
    (hik : Leads P i k) (hki : ¬ Leads P k i) : returnChance P i < 1 := by
  obtain ⟨n0, hn0⟩ := hik
  obtain ⟨a, ha⟩ := cs_avoid_path P i n0 k hn0
  set δ := (avoid P i ^ a) i k with hδ
  -- from k the chain never hits i
  have hzero : ∀ m, ((avoid P i ^ m) * P) k i = 0 := by
    intro m
    have hle : ((avoid P i ^ m) * P) k i ≤ (P ^ (m + 1)) k i := by
      rw [pow_succ, Matrix.mul_apply, Matrix.mul_apply]
      exact Finset.sum_le_sum fun x _ => mul_le_mul' (cs_avoid_pow_le P i m k x) le_rfl
    have h0 : (P ^ (m + 1)) k i = 0 := by
      by_contra hne
      exact hki ⟨m + 1, pos_iff_ne_zero.mpr hne⟩
    exact le_antisymm (h0 ▸ hle) (zero_le)
  have hsurvk : ∀ t, ∑ l, (avoid P i ^ t) k l = 1 := by
    intro t
    have := cs_partial P hP i k t
    simpa [hzero] using this
  have hsurv : ∀ t, δ ≤ ∑ l, (avoid P i ^ (a + t)) i l := by
    intro t
    rw [cs_surv_add]
    calc δ = (avoid P i ^ a) i k * ∑ m, (avoid P i ^ t) k m := by rw [hsurvk, mul_one]
      _ ≤ _ := Finset.single_le_sum (f := fun l => (avoid P i ^ a) i l * ∑ m, (avoid P i ^ t) l m)
          (fun _ _ => zero_le) (Finset.mem_univ k)
  have hδtop : δ ≠ ⊤ := by
    have h1 : δ ≤ 1 := by
      calc δ ≤ _ := hsurv 0
        _ ≤ _ := le_add_self
        _ = 1 := cs_partial P hP i i (a + 0)
    exact ne_top_of_le_ne_top ENNReal.one_ne_top h1
  have hbound : returnChance P i ≤ 1 - δ := by
    unfold returnChance
    rw [ENNReal.tsum_eq_iSup_nat]
    refine iSup_le fun n => ?_
    have hmono : ∑ m ∈ Finset.range n, ((avoid P i ^ m) * P) i i ≤
        ∑ m ∈ Finset.range (a + n), ((avoid P i ^ m) * P) i i :=
      Finset.sum_le_sum_of_subset (Finset.range_mono (by omega))
    refine le_trans hmono (ENNReal.le_sub_of_add_le_right hδtop ?_)
    calc _ ≤ ∑ m ∈ Finset.range (a + n), ((avoid P i ^ m) * P) i i +
          ∑ l, (avoid P i ^ (a + n)) i l := add_le_add le_rfl (hsurv n)
      _ = 1 := cs_partial P hP i i (a + n)
  calc returnChance P i ≤ 1 - δ := hbound
    _ < 1 := ENNReal.sub_lt_self ENNReal.one_ne_top one_ne_zero ha.ne'

/-- Recurrent direction: in a closed class the return chance is 1. -/
lemma cs_return_eq_one (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i : S)
    (hc : ClassClosed P i) : returnChance P i = 1 := by
  classical
  -- every state reachable from i is in the class
  have hsupp : ∀ n l, 0 < (P ^ n) i l → Communicate P i l := by
    intro n
    induction n with
    | zero =>
      intro l hl
      have hil : i = l := by
        by_contra hne
        simp [Matrix.one_apply_ne hne] at hl
      rw [← hil]; exact cs_comm_refl P i
    | succ n ih =>
      intro l hl
      rw [pow_succ, Matrix.mul_apply] at hl
      obtain ⟨m, hm⟩ := cs_exists_pos hl
      obtain ⟨h1, h2⟩ := ENNReal.mul_pos_iff.mp hm
      exact hc m l (ih m h1) h2
  have hsuppQ : ∀ n l, 0 < (avoid P i ^ n) i l → Communicate P i l := fun n l h =>
    hsupp n l (lt_of_lt_of_le h (cs_avoid_pow_le P i n i l))
  -- every state of the class hits i at some positive time
  have hhit : ∀ l, Communicate P i l → ∃ m, 0 < ((avoid P i ^ m) * P) l i := by
    intro l hl
    have hrow : 0 < ∑ j, P l j := by rw [hP l]; exact zero_lt_one
    obtain ⟨j, hj⟩ := cs_exists_pos hrow
    obtain ⟨n', hn'⟩ := (hc l j hl hj).2
    apply cs_first_hit P i n' l
    rw [pow_succ']
    exact cs_mul_pos hj hn'
  choose! mf hmf using hhit
  set N := Finset.univ.sup mf + 1 with hN
  let r : S → ℝ≥0∞ := fun l => ∑ x, (avoid P i ^ N) l x
  have hr_lt : ∀ l, Communicate P i l → r l < 1 := by
    intro l hl
    have hpos : 0 < ∑ m ∈ Finset.range N, ((avoid P i ^ m) * P) l i := by
      have hlt : mf l < N := by
        have := Finset.le_sup (f := mf) (Finset.mem_univ l)
        omega
      calc (0 : ℝ≥0∞) < ((avoid P i ^ (mf l)) * P) l i := hmf l hl
        _ ≤ _ := Finset.single_le_sum (f := fun m => ((avoid P i ^ m) * P) l i)
            (fun _ _ => zero_le) (Finset.mem_range.mpr hlt)
    have hsum := cs_partial P hP i l N
    have hstop : ∑ m ∈ Finset.range N, ((avoid P i ^ m) * P) l i ≠ ⊤ := by
      refine ne_top_of_le_ne_top ENNReal.one_ne_top ?_
      rw [← hsum]; exact le_self_add
    have heq : r l = 1 - ∑ m ∈ Finset.range N, ((avoid P i ^ m) * P) l i :=
      ENNReal.eq_sub_of_add_eq hstop (by rw [add_comm]; exact hsum)
    rw [heq]
    exact ENNReal.sub_lt_self ENNReal.one_ne_top one_ne_zero hpos.ne'
  set ρ := Finset.univ.sup (fun l => if Communicate P i l then r l else 0) with hρ
  have hρlt : ρ < 1 := by
    rw [hρ, Finset.sup_lt_iff (by simp)]
    intro l _
    split_ifs with hl
    · exact hr_lt l hl
    · exact zero_lt_one
  have hrρ : ∀ l, Communicate P i l → r l ≤ ρ := by
    intro l hl
    have := Finset.le_sup (f := fun l => if Communicate P i l then r l else 0) (Finset.mem_univ l)
    simpa [hl] using this
  have hdecay : ∀ t : ℕ, ∑ x, (avoid P i ^ (t * N)) i x ≤ ρ ^ t := by
    intro t
    induction t with
    | zero => simp [Matrix.one_apply]
    | succ t ih =>
      rw [Nat.succ_mul, cs_surv_add]
      calc ∑ l, (avoid P i ^ (t * N)) i l * ∑ m, (avoid P i ^ N) l m
          ≤ ∑ l, (avoid P i ^ (t * N)) i l * ρ := by
            refine Finset.sum_le_sum fun l _ => ?_
            by_cases hz : (avoid P i ^ (t * N)) i l = 0
            · simp [hz]
            · exact mul_le_mul' le_rfl (hrρ l (hsuppQ _ l (pos_iff_ne_zero.mpr hz)))
        _ = (∑ l, (avoid P i ^ (t * N)) i l) * ρ := by rw [Finset.sum_mul]
        _ ≤ ρ ^ t * ρ := mul_le_mul' ih le_rfl
        _ = ρ ^ (t + 1) := (pow_succ ρ t).symm
  have hlow : ∀ t : ℕ, 1 ≤ returnChance P i + ρ ^ t := by
    intro t
    rw [← cs_partial P hP i i (t * N)]
    refine add_le_add ?_ (hdecay t)
    exact sum_le_tsum _
  have hlim : Filter.Tendsto (fun t : ℕ => returnChance P i + ρ ^ t) Filter.atTop
      (nhds (returnChance P i + 0)) :=
    tendsto_const_nhds.add (ENNReal.tendsto_pow_atTop_nhds_zero_of_lt_one hρlt)
  have h1 : 1 ≤ returnChance P i + 0 := ge_of_tendsto' hlim hlow
  rw [add_zero] at h1
  exact le_antisymm (cs_return_le_one P hP i) h1

#print axioms cs_mul_pos
#print axioms cs_pow_add_pos
#print axioms cs_exists_pos
#print axioms cs_leads_refl
#print axioms cs_leads_trans
#print axioms cs_leads_step
#print axioms cs_comm_refl
#print axioms cs_comm_symm
#print axioms cs_comm_trans
#print axioms cs_closed_iff
#print axioms cs_divides_of_comm
#print axioms cs_avoid_le
#print axioms cs_avoid_pow_le
#print axioms cs_avoid_row
#print axioms cs_surv_step
#print axioms cs_partial
#print axioms cs_surv_add
#print axioms cs_avoid_path
#print axioms cs_first_hit
#print axioms cs_return_le_one
#print axioms cs_return_lt_one
#print axioms cs_return_eq_one

/-- In a Markov chain with finitely many states (each row of chances adds to 1), a state is
recurrent, revisited with chance 1, exactly when its communicating class is closed, with no
arrow leaving it. -/
theorem recurrent_iff_class_closed (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) (i : S) :
    Recurrent P i ↔ ClassClosed P i := by
  constructor
  · intro hrec
    by_contra hnot
    simp only [ClassClosed, not_forall] at hnot
    obtain ⟨j, k, hij, hjk, hik⟩ := hnot
    have hlead : Leads P i k := cs_leads_step hij.1 hjk
    have hki : ¬ Leads P k i := fun h => hik ⟨hlead, h⟩
    have := cs_return_lt_one P hP i k hlead hki
    rw [Recurrent] at hrec
    rw [hrec] at this
    exact lt_irrefl _ this
  · intro hc
    exact cs_return_eq_one P hP i hc

/-- In a Markov chain with finitely many states, two states that communicate have the same
period (the same common divisors of their possible return lengths, so the same greatest one),
and are both recurrent or both transient. -/
theorem communicate_same_period_and_recurrence (P : Matrix S S ℝ≥0∞)
    (hP : ∀ i, ∑ j, P i j = 1) (i j : S) (hij : Communicate P i j) :
    (∀ d : ℕ, DividesReturns P i d ↔ DividesReturns P j d) ∧ (Recurrent P i ↔ Recurrent P j) := by
  refine ⟨fun d => ⟨cs_divides_of_comm hij, cs_divides_of_comm (cs_comm_symm hij)⟩, ?_⟩
  rw [recurrent_iff_class_closed P hP i, recurrent_iff_class_closed P hP j]
  exact cs_closed_iff hij

/-- A Markov chain with finitely many states (at least one) has at least one closed class. -/
theorem exists_closed_class [Nonempty S] (P : Matrix S S ℝ≥0∞) (hP : ∀ i, ∑ j, P i j = 1) :
    ∃ i : S, ClassClosed P i := by
  classical
  let R : S → Finset S := fun a => Finset.univ.filter (fun b => Leads P a b)
  obtain ⟨i, -, hmin⟩ := Finset.exists_min_image Finset.univ (fun a => (R a).card)
    Finset.univ_nonempty
  refine ⟨i, fun j k hij hjk => ?_⟩
  have hik : Leads P i k := cs_leads_step hij.1 hjk
  have hsub : R k ⊆ R i := by
    intro b hb
    simp only [R, Finset.mem_filter, Finset.mem_univ, true_and] at hb ⊢
    exact cs_leads_trans hik hb
  have heq : R k = R i := Finset.eq_of_subset_of_card_le hsub (hmin k (Finset.mem_univ k))
  have hii : i ∈ R k := by
    rw [heq]
    simp only [R, Finset.mem_filter, Finset.mem_univ, true_and]
    exact cs_leads_refl P i
  simp only [R, Finset.mem_filter, Finset.mem_univ, true_and] at hii
  exact ⟨hik, hii⟩


/-! The board's arrows, squares numbered S = 0, A = 1, B = 2, C = 3, J = 4.
An entry is 1 where the one-turn chance is positive and 0 where it is zero. -/

/-- Jail rule "doubles": S stays or goes to A; the coin moves A, B, C one square either way, with
D replaced by J; J stays or goes to A. -/
def board : Matrix (Fin 5) (Fin 5) ℕ :=
  !![1, 1, 0, 0, 0;
     0, 0, 1, 0, 1;
     0, 1, 0, 1, 0;
     0, 0, 1, 0, 1;
     0, 1, 0, 0, 1]

/-- Jail rule "at once": J always goes straight to A. -/
def boardAtOnce : Matrix (Fin 5) (Fin 5) ℕ :=
  !![1, 1, 0, 0, 0;
     0, 0, 1, 0, 1;
     0, 1, 0, 1, 0;
     0, 0, 1, 0, 1;
     0, 1, 0, 0, 0]

/-- Jail rule "no key": J only ever stays. -/
def boardNoKey : Matrix (Fin 5) (Fin 5) ℕ :=
  !![1, 1, 0, 0, 0;
     0, 0, 1, 0, 1;
     0, 1, 0, 1, 0;
     0, 0, 1, 0, 1;
     0, 0, 0, 0, 1]

-- Nothing leads into S except its own loop, so S is a class by itself. The same fact says no
-- arrow leaves {A, B, C, J}: every arrow out of A, B, C or J lands in A, B, C or J, so that
-- class is closed.
example : ∀ k : Fin 5, k ≠ 0 → board k 0 = 0 := by decide
-- S → A is an arrow, so the class {S} is open.
example : 0 < board 0 1 := by decide
-- The round trip A → B → C → J → A: A, B, C and J communicate.
example : 0 < board 1 2 ∧ 0 < board 2 3 ∧ 0 < board 3 4 ∧ 0 < board 4 1 := by decide
-- Returns to A in 2 turns (A → B → A) and in 3 turns (A → J → J → A); gcd(2, 3) = 1.
example : 0 < (board ^ 2) 1 1 := by decide
example : 0 < (board ^ 3) 1 1 := by decide
example : Nat.gcd 2 3 = 1 := by decide
-- Release at once: returns to A only after an even number of turns (2, 4, 6, 8 up to 8).
example : (boardAtOnce ^ 1) 1 1 = 0 ∧ (boardAtOnce ^ 3) 1 1 = 0 ∧
    (boardAtOnce ^ 5) 1 1 = 0 ∧ (boardAtOnce ^ 7) 1 1 = 0 := by decide
example : 0 < (boardAtOnce ^ 2) 1 1 ∧ 0 < (boardAtOnce ^ 8) 1 1 := by decide
-- No key: J's only arrow is its loop, so {J} is closed, and {A, B, C} has an exit to J.
example : ∀ k : Fin 5, k ≠ 4 → boardNoKey 4 k = 0 := by decide
example : 0 < boardNoKey 1 4 := by decide
-- Return chance at S is 5/6, so the average number of turns on S is 1 / (1 - 5/6) = 6.
example : (1 : ℚ) / (1 - 5 / 6) = 6 := by norm_num
-- No key: reaching A from B is 2/3 (it solves h = 1/2 + 1/2 * (h / 2)), from C 1/3,
-- so f_A = 1/2 * 2/3 + 1/2 * 0 = 1/3 and A is visited 1 / (1 - 1/3) = 3/2 times on average.
example : (2 / 3 : ℚ) = 1 / 2 + 1 / 2 * ((2 / 3) / 2) := by norm_num
example : (1 / 2 : ℚ) * (2 / 3) + 1 / 2 * 0 = 1 / 3 := by norm_num
example : (1 : ℚ) / (1 - 1 / 3) = 3 / 2 := by norm_num

#print axioms recurrent_iff_class_closed
#print axioms communicate_same_period_and_recurrence
#print axioms exists_closed_class
