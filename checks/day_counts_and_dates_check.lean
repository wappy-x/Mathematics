-- Day counts: the ordinal formula counts every calendar day between two dates exactly once, it rises by one each day, and all three year fractions add up when a period is split.
import Mathlib.Data.Set.Card
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Set.Finite.Basic

open Finset

/-! ## The Gregorian calendar, written as data -/

/-- A date: year `Y`, month `M` (1 to 12) and day number `d`. -/
structure Date where
  year : ℕ
  month : ℕ
  day : ℕ
  deriving DecidableEq

/-- The Gregorian leap rule: every fourth year, except every hundredth, except every
four-hundredth (2000 leap, 1900 not). -/
def leapYear (y : ℕ) : Bool := y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)

/-- Days in year `y`: 366 in a leap year, 365 otherwise. -/
def yearLen (y : ℕ) : ℕ := if leapYear y then 366 else 365

/-- Days in month `m` of year `y`; February has 29 days in a leap year. -/
def monthLen (y m : ℕ) : ℕ :=
  match m with
  | 1 => 31 | 2 => if leapYear y then 29 else 28 | 3 => 31 | 4 => 30
  | 5 => 31 | 6 => 30 | 7 => 31 | 8 => 31 | 9 => 30 | 10 => 31 | 11 => 30 | 12 => 31
  | _ => 0

/-- A real Gregorian date from year 1 on: month 1 to 12, day 1 to the month's length. -/
def Date.Valid (x : Date) : Prop :=
  1 ≤ x.year ∧ 1 ≤ x.month ∧ x.month ≤ 12 ∧ 1 ≤ x.day ∧ x.day ≤ monthLen x.year x.month

/-- Calendar order: `a` falls strictly before `b` (compare years, then months, then days). -/
def Date.Before (a b : Date) : Prop :=
  a.year < b.year ∨ (a.year = b.year ∧ (a.month < b.month ∨ (a.month = b.month ∧ a.day < b.day)))

/-- `a` falls on or before `b`. -/
def Date.OnOrBefore (a b : Date) : Prop := a = b ∨ a.Before b

/-- The actual day count `n`: how many real dates lie in the half-open period `[s, e)`,
start counted, end not. -/
noncomputable def actualDays (s e : Date) : ℕ :=
  Set.ncard {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before e}

/-- The card's ordinal `O`: days after 1 January of year 1,
`365(Y-1) + ⌊(Y-1)/4⌋ - ⌊(Y-1)/100⌋ + ⌊(Y-1)/400⌋ + C + d - 1`, where `C` is the days in
the months of `Y` before month `M`. (Terms are reordered so no natural-number subtraction
truncates on a valid date.) -/
def ordinal (x : Date) : ℕ :=
  365 * (x.year - 1) + (x.year - 1) / 4 + (x.year - 1) / 400 - (x.year - 1) / 100
    + (∑ k ∈ Ico 1 x.month, monthLen x.year k) + x.day - 1

/-- The next calendar day. -/
def Date.next (x : Date) : Date :=
  if x.day < monthLen x.year x.month then ⟨x.year, x.month, x.day + 1⟩
  else if x.month < 12 then ⟨x.year, x.month + 1, 1⟩
  else ⟨x.year + 1, 1, 1⟩

/-- Actual/360 year fraction: actual days over 360. -/
noncomputable def act360 (s e : Date) : ℚ := (actualDays s e : ℚ) / 360

/-- 30E/360 numerator (ISDA 2006, 4.16(g)): `360(Y₂-Y₁) + 30(M₂-M₁) + D₂ - D₁`
with `D = min(d, 30)`. -/
def thirtyENumerator (s e : Date) : ℤ :=
  360 * ((e.year : ℤ) - s.year) + 30 * ((e.month : ℤ) - s.month)
    + (min e.day 30 : ℕ) - (min s.day 30 : ℕ)

/-- 30E/360 year fraction. -/
def thirtyE360 (s e : Date) : ℚ := (thirtyENumerator s e : ℚ) / 360

/-- Days of `[s, e)` falling in calendar year `y`: the card's `n_y`. -/
noncomputable def daysInYear (s e : Date) (y : ℕ) : ℕ :=
  Set.ncard {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before e ∧ x.year = y}

/-- Actual/Actual ISDA year fraction: cut at every 1 January, divide each piece by its own
year's length, add: `Σ_y n_y / L_y`. -/
noncomputable def actActISDA (s e : Date) : ℚ :=
  ∑ y ∈ Icc s.year e.year, (daysInYear s e y : ℚ) / yearLen y

/-! ## Helper lemmas for the proofs -/

theorem monthLen_le (y m : ℕ) : monthLen y m ≤ 31 := by
  unfold monthLen; split <;> (try split_ifs) <;> norm_num

theorem monthLen_pos (y m : ℕ) (h1 : 1 ≤ m) (h2 : m ≤ 12) : 1 ≤ monthLen y m := by
  interval_cases m <;> simp only [monthLen] <;> (try split_ifs) <;> norm_num

theorem year_step (n : ℕ) :
    365 * (n + 1) + (n + 1) / 4 + (n + 1) / 400 - (n + 1) / 100 =
      365 * n + n / 4 + n / 400 - n / 100 + yearLen (n + 1) := by
  have h1 : n / 100 ≤ n / 4 := Nat.div_le_div_left (by norm_num) (by norm_num)
  have e4 := Nat.succ_div (a := n) (b := 4)
  have e100 := Nat.succ_div (a := n) (b := 100)
  have e400 := Nat.succ_div (a := n) (b := 400)
  rw [e4, e100, e400]
  simp only [yearLen, leapYear, Nat.dvd_iff_mod_eq_zero]
  generalize n / 4 = A at *
  generalize n / 100 = B at *
  generalize n / 400 = C at *
  split_ifs <;> simp_all <;> omega

theorem Date.onOrBefore_iff (a b : Date) : a.OnOrBefore b ↔
    (a.year < b.year ∨ (a.year = b.year ∧ (a.month < b.month ∨
      (a.month = b.month ∧ a.day ≤ b.day)))) := by
  obtain ⟨ay, am, ad⟩ := a
  obtain ⟨by', bm, bd⟩ := b
  simp only [Date.OnOrBefore, Date.Before, Date.mk.injEq]
  omega

theorem Date.before_next (x : Date) : x.Before x.next := by
  unfold Date.next Date.Before
  split_ifs <;> simp

theorem Date.next_onOrBefore (x y : Date) (hy : y.Valid) (h : x.Before y) :
    x.next.OnOrBefore y := by
  obtain ⟨hy1, hy2, hy3, hy4, hy5⟩ := hy
  rw [Date.onOrBefore_iff]
  unfold Date.next
  rcases h with h | ⟨h1, h | ⟨h2, h3⟩⟩
  · split_ifs <;> simp <;> omega
  · split_ifs <;> simp <;> omega
  · rw [← h1, ← h2] at hy5
    split_ifs <;> simp <;> omega

/-- A numeric key that orders dates with month at most 12 and day at most 31. -/
def Date.key (x : Date) : ℕ := x.year * 1000 + x.month * 40 + x.day

theorem Date.key_lt (a b : Date) (ha : a.Valid) (h : a.Before b) : a.key < b.key := by
  obtain ⟨_, _, ha3, _, ha5⟩ := ha
  have := monthLen_le a.year a.month
  unfold Date.key
  rcases h with h | ⟨h1, h | ⟨h2, h3⟩⟩
  · have : a.year * 1000 + 1000 ≤ b.year * 1000 := by nlinarith
    omega
  · rw [h1]; omega
  · rw [h1, h2]; omega

theorem Date.key_le (a b : Date) (ha : a.Valid) (h : a.OnOrBefore b) : a.key ≤ b.key := by
  rcases h with rfl | h
  · exact le_rfl
  · exact (Date.key_lt a b ha h).le

theorem finite_valid_le (N : ℕ) : {x : Date | x.Valid ∧ x.year ≤ N}.Finite := by
  have hsub : {x : Date | x.Valid ∧ x.year ≤ N} ⊆
      (fun t : ℕ × ℕ × ℕ => (⟨t.1, t.2.1, t.2.2⟩ : Date)) ''
        (Set.Iic N ×ˢ Set.Iic 12 ×ˢ Set.Iic 31) := by
    rintro ⟨y, m, d⟩ ⟨⟨h1, h2, h3, h4, h5⟩, hN⟩
    refine ⟨(y, m, d), ?_, rfl⟩
    have := monthLen_le y m
    simp only [Set.mem_prod, Set.mem_Iic]
    simp only at h1 h2 h3 h4 h5 hN this
    omega
  exact Set.Finite.subset
    (((Set.finite_Iic N).prod ((Set.finite_Iic 12).prod (Set.finite_Iic 31))).image _) hsub

theorem finite_period (s e : Date) :
    {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before e}.Finite := by
  refine (finite_valid_le e.year).subset ?_
  rintro x ⟨hv, _, h⟩
  refine ⟨hv, ?_⟩
  unfold Date.Before at h
  omega

theorem ordinal_next_aux (x : Date) (hx : x.Valid) :
    x.next.Valid ∧ ordinal x.next = ordinal x + 1 := by
  obtain ⟨Y, M, d⟩ := x
  obtain ⟨h1, h2, h3, h4, h5⟩ := hx
  simp only at h1 h2 h3 h4 h5
  unfold Date.next
  simp only
  split_ifs with ha hb
  · refine ⟨?_, ?_⟩
    · simp only [Date.Valid]; omega
    · simp only [ordinal]; omega
  · have hpos := monthLen_pos Y (M + 1) (by omega) (by omega)
    have hd : d = monthLen Y M := by omega
    refine ⟨?_, ?_⟩
    · simp only [Date.Valid]; omega
    · simp only [ordinal]
      rw [Finset.sum_Ico_succ_top h2]
      omega
  · have hM : M = 12 := by omega
    subst hM
    have hd : d = 31 := by simp [monthLen] at h5 ha; omega
    subst hd
    refine ⟨?_, ?_⟩
    · simp only [Date.Valid, monthLen]; omega
    obtain ⟨n, rfl⟩ : ∃ n, Y = n + 1 := ⟨Y - 1, by omega⟩
    have hstep := year_step n
    simp only [ordinal]
    simp only [Finset.sum_Ico_eq_sum_range, Finset.sum_range_succ, Finset.sum_range_zero,
      monthLen, Nat.add_sub_cancel, Nat.reduceSub, 
      Finset.Ico_self, Finset.sum_empty]
    simp only [yearLen] at hstep
    split_ifs at hstep ⊢ <;> omega

theorem count_aux (e : Date) (he : e.Valid) : ∀ n : ℕ, ∀ s : Date, s.Valid → s.OnOrBefore e →
    e.key - s.key = n →
    (Set.ncard {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before e} : ℤ) =
      (ordinal e : ℤ) - ordinal s := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro s hs hse hn
  rcases hse with rfl | hlt
  · have hempty : {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before s} = ∅ := by
      ext x
      simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
      rintro ⟨_, h1, h2⟩
      rw [Date.onOrBefore_iff] at h1
      unfold Date.Before at h2
      omega
    simp [hempty]
  · have hnv := ordinal_next_aux s hs
    have hle := Date.next_onOrBefore s e he hlt
    have hk1 := Date.key_lt s s.next hs (Date.before_next s)
    have hk2 := Date.key_le s.next e hnv.1 hle
    have ih' := ih (e.key - s.next.key) (by omega) s.next hnv.1 hle rfl
    have hset : {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before e} =
        insert s {x : Date | x.Valid ∧ s.next.OnOrBefore x ∧ x.Before e} := by
      ext x
      simp only [Set.mem_insert_iff, Set.mem_ofPred_eq]
      constructor
      · rintro ⟨hv, h1 | h1, h2⟩
        · exact Or.inl h1.symm
        · exact Or.inr ⟨hv, Date.next_onOrBefore s x hv h1, h2⟩
      · rintro (rfl | ⟨hv, h1, h2⟩)
        · exact ⟨hs, Or.inl rfl, hlt⟩
        · refine ⟨hv, Or.inr ?_, h2⟩
          have h0 := Date.before_next s
          rw [Date.onOrBefore_iff] at h1
          unfold Date.Before at h0 ⊢
          omega
    have hnot : s ∉ {x : Date | x.Valid ∧ s.next.OnOrBefore x ∧ x.Before e} := by
      rintro ⟨_, h1, _⟩
      have h0 := Date.before_next s
      rw [Date.onOrBefore_iff] at h1
      unfold Date.Before at h0
      omega
    rw [hset, Set.ncard_insert_of_notMem hnot (finite_period _ _)]
    push_cast
    rw [ih', hnv.2]
    push_cast
    ring


theorem days_split (s m e : Date) (hsm : s.OnOrBefore m) (hme : m.OnOrBefore e) (y : ℕ) :
    daysInYear s e y = daysInYear s m y + daysInYear m e y := by
  unfold daysInYear
  rw [Date.onOrBefore_iff] at hsm hme
  have hset : {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before e ∧ x.year = y} =
      {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before m ∧ x.year = y} ∪
      {x : Date | x.Valid ∧ m.OnOrBefore x ∧ x.Before e ∧ x.year = y} := by
    ext x
    simp only [Set.mem_union, Set.mem_ofPred_eq, Date.onOrBefore_iff, Date.Before]
    constructor
    · rintro ⟨hv, h1, h2, hy⟩
      by_cases hxm : x.year < m.year ∨ (x.year = m.year ∧ (x.month < m.month ∨
          (x.month = m.month ∧ x.day < m.day)))
      · exact Or.inl ⟨hv, h1, hxm, hy⟩
      · exact Or.inr ⟨hv, by omega, h2, hy⟩
    · rintro (⟨hv, h1, h2, hy⟩ | ⟨hv, h1, h2, hy⟩)
      · exact ⟨hv, h1, by omega, hy⟩
      · exact ⟨hv, by omega, h2, hy⟩
  have hdisj : Disjoint {x : Date | x.Valid ∧ s.OnOrBefore x ∧ x.Before m ∧ x.year = y}
      {x : Date | x.Valid ∧ m.OnOrBefore x ∧ x.Before e ∧ x.year = y} := by
    refine Set.disjoint_left.mpr ?_
    rintro x ⟨_, _, h1, _⟩ ⟨_, h2, _, _⟩
    rw [Date.onOrBefore_iff] at h2
    unfold Date.Before at h1
    omega
  rw [hset, Set.ncard_union_eq hdisj
    ((finite_period s m).subset (fun x hx => ⟨hx.1, hx.2.1, hx.2.2.1⟩))
    ((finite_period m e).subset (fun x hx => ⟨hx.1, hx.2.1, hx.2.2.1⟩))]

theorem days_zero (a b : Date) (y : ℕ) (hy : y ∉ Icc a.year b.year) :
    daysInYear a b y = 0 := by
  rw [Finset.mem_Icc] at hy
  unfold daysInYear
  have hempty : {x : Date | x.Valid ∧ a.OnOrBefore x ∧ x.Before b ∧ x.year = y} = ∅ := by
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
    rintro ⟨_, h1, h2, rfl⟩
    rw [Date.onOrBefore_iff] at h1
    unfold Date.Before at h2
    omega
  rw [hempty, Set.ncard_empty]

/-! ## The card's claims -/

/-- The day count is one subtraction. For real Gregorian dates `s` and `e` with `e` on or after
`s`, the number of calendar days in `[s, e)` (start counted, end not) is `O(e) - O(s)`. -/
theorem actual_days_eq_ordinal_sub (s e : Date) (hs : s.Valid) (he : e.Valid)
    (hse : s.OnOrBefore e) :
    (actualDays s e : ℤ) = (ordinal e : ℤ) - ordinal s := by
  exact count_aux e he _ s hs hse rfl

/-- The ordinal formula counts each calendar day exactly once: moving any real date forward
by one calendar day, inside a month, across a month end or across a year end, raises `O`
by exactly 1 (and the next day is again a real date). -/
theorem ordinal_next_day (x : Date) (hx : x.Valid) :
    x.next.Valid ∧ ordinal x.next = ordinal x + 1 := by
  exact ordinal_next_aux x hx

/-- Splitting a period and adding the pieces gives the whole: for real dates `s`, `m`, `e` in
order, Actual/360, 30E/360 and Actual/Actual ISDA each satisfy
`α(s, m) + α(m, e) = α(s, e)`. -/
theorem year_fractions_additive (s m e : Date) (hs : s.Valid) (hm : m.Valid) (he : e.Valid)
    (hsm : s.OnOrBefore m) (hme : m.OnOrBefore e) :
    act360 s m + act360 m e = act360 s e ∧
    thirtyE360 s m + thirtyE360 m e = thirtyE360 s e ∧
    actActISDA s m + actActISDA m e = actActISDA s e := by
  have hse : s.OnOrBefore e := by
    rw [Date.onOrBefore_iff] at hsm hme ⊢
    omega
  have h1 := actual_days_eq_ordinal_sub s m hs hm hsm
  have h2 := actual_days_eq_ordinal_sub m e hm he hme
  have h3 := actual_days_eq_ordinal_sub s e hs he hse
  have hn : actualDays s m + actualDays m e = actualDays s e := by omega
  refine ⟨?_, ?_, ?_⟩
  · unfold act360
    rw [← add_div, ← Nat.cast_add, hn]
  · unfold thirtyE360 thirtyENumerator
    rw [← add_div]
    congr 1
    push_cast
    ring
  · have hy1 : s.year ≤ m.year := by
      rw [Date.onOrBefore_iff] at hsm
      omega
    have hy2 : m.year ≤ e.year := by
      rw [Date.onOrBefore_iff] at hme
      omega
    unfold actActISDA
    rw [Finset.sum_subset (Finset.Icc_subset_Icc le_rfl hy2)
        (fun y _ hy => by rw [days_zero s m y hy]; simp),
      Finset.sum_subset (Finset.Icc_subset_Icc hy1 le_rfl)
        (fun y _ hy => by rw [days_zero m e y hy]; simp),
      ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl (fun y _ => ?_)
    rw [days_split s m e hsm hme y]
    push_cast
    ring

/-! ## The card's worked numbers, exactly -/

-- the note's first period, 15 January to 1 March 2007: 45 actual days by ordinals
example : ordinal ⟨2007, 3, 1⟩ - ordinal ⟨2007, 1, 15⟩ = 45 := by decide
-- split at 1 February: 17 + 28 actual days, 16 + 30 under 30E/360
example : ordinal ⟨2007, 2, 1⟩ - ordinal ⟨2007, 1, 15⟩ = 17 ∧
    ordinal ⟨2007, 3, 1⟩ - ordinal ⟨2007, 2, 1⟩ = 28 := by decide
example : thirtyENumerator ⟨2007, 1, 15⟩ ⟨2007, 2, 1⟩ = 16 ∧
    thirtyENumerator ⟨2007, 2, 1⟩ ⟨2007, 3, 1⟩ = 30 ∧
    thirtyENumerator ⟨2007, 1, 15⟩ ⟨2007, 3, 1⟩ = 46 := by decide
-- the three coupons on $3,600.00 at 10 percent (360 dollars a year): $46.00, $45.00, 3240/73
example : (360 : ℚ) * (46 / 360) = 46 ∧ (360 : ℚ) * (45 / 360) = 45 ∧
    (360 : ℚ) * (45 / 365) = 3240 / 73 := by norm_num
-- second period, 1 September 2007 to 1 March 2008: 182 days, 122 in 2007 and 60 in 2008,
-- 30E/360 reads 180
example : ordinal ⟨2008, 3, 1⟩ - ordinal ⟨2007, 9, 1⟩ = 182 ∧
    ordinal ⟨2008, 1, 1⟩ - ordinal ⟨2007, 9, 1⟩ = 122 ∧
    ordinal ⟨2008, 3, 1⟩ - ordinal ⟨2008, 1, 1⟩ = 60 ∧
    yearLen 2007 = 365 ∧ yearLen 2008 = 366 ∧
    thirtyENumerator ⟨2007, 9, 1⟩ ⟨2008, 3, 1⟩ = 180 := by decide
-- final stub, 1 March to 31 May 2008: 91 actual days, 30E/360 reads 89;
-- accruing to the rolled date 30 May gives 90
example : ordinal ⟨2008, 5, 31⟩ - ordinal ⟨2008, 3, 1⟩ = 91 ∧
    thirtyENumerator ⟨2008, 3, 1⟩ ⟨2008, 5, 31⟩ = 89 ∧
    ordinal ⟨2008, 5, 30⟩ - ordinal ⟨2008, 3, 1⟩ = 90 := by decide
-- 30E/360 is not elapsed time: 30 to 31 January reads 0 where the calendar reads 1;
-- 28 February to 31 March 2007 reads 32 clipped, 33 unclipped
example : thirtyENumerator ⟨2007, 1, 30⟩ ⟨2007, 1, 31⟩ = 0 ∧
    ordinal ⟨2007, 1, 31⟩ - ordinal ⟨2007, 1, 30⟩ = 1 ∧
    thirtyENumerator ⟨2007, 2, 28⟩ ⟨2007, 3, 31⟩ = 32 := by decide
-- the leap rule: 2000 leap, 1900 not
example : leapYear 2000 = true ∧ leapYear 1900 = false := by decide
-- weekdays from the ordinal (0 = Monday, since 1 January of year 1 was a Monday):
-- 1 March 2007 a Thursday; 1 September 2007, 1 March 2008, 31 May 2008 Saturdays
example : ordinal ⟨2007, 3, 1⟩ % 7 = 3 ∧ ordinal ⟨2007, 9, 1⟩ % 7 = 5 ∧
    ordinal ⟨2008, 3, 1⟩ % 7 = 5 ∧ ordinal ⟨2008, 5, 31⟩ % 7 = 5 := by decide

#print axioms monthLen_le
#print axioms monthLen_pos
#print axioms year_step
#print axioms Date.onOrBefore_iff
#print axioms Date.before_next
#print axioms Date.next_onOrBefore
#print axioms Date.key_lt
#print axioms Date.key_le
#print axioms finite_valid_le
#print axioms finite_period
#print axioms ordinal_next_aux
#print axioms count_aux
#print axioms days_split
#print axioms days_zero
#print axioms actual_days_eq_ordinal_sub
#print axioms ordinal_next_day
#print axioms year_fractions_additive
