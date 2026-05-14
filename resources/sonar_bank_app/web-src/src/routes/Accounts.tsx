import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'motion/react'
import {
  AlertTriangle,
  ArrowDownLeft,
  ArrowUpRight,
  Check,
  Coins,
  Copy,
  CreditCard,
  Landmark,
  PiggyBank,
  Send,
  ShieldCheck,
  Wallet,
} from 'lucide-react'
import { Button, Card, CardEyebrow, CardTitle, Input, Spinner } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { accountMutationPayload, kycSubmitPayload, useCloseAccountMutation, useFreezeAccountMutation, useOpenAccountMutation, useSavingsTransferMutation, useSubmitKycMutation, useUnfreezeAccountMutation } from '@/data/mutations'
import { useBootstrap } from '@/data/queries'
import type { Account, Transaction } from '@/data/contracts'
import { getMockAliasForIban } from '@/data/mock/seed'
import { handleBankError } from '@/lib/bankError'
import { cn } from '@/lib/utils'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskIbanCompact, maskIbanDisplay, maskMoneyDisplay, maskSignedMoneyDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'
import { createBankOperationIds } from '@/lib/bankIdempotency'

export function Accounts() {
  const navigate = useNavigate()
  const { t } = useI18n()
  const { data, isLoading, isError, error } = useBootstrap()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const openAccount = useOpenAccountMutation()
  const freezeAccount = useFreezeAccountMutation()
  const unfreezeAccount = useUnfreezeAccountMutation()
  const closeAccount = useCloseAccountMutation()
  const submitKyc = useSubmitKycMutation()

  useEffect(() => {
    if (isError && error) handleBankError(error)
  }, [isError, error])

  const accounts = data?.accounts ?? []
  const transactions = data?.recent_transactions ?? []
  const selected = accounts.find((account) => account.account_id === selectedId) ?? accounts[0]

  useEffect(() => {
    if (!selectedId && accounts[0]) setSelectedId(accounts[0].account_id)
  }, [accounts, selectedId])

  const accountTransactions = useMemo(
    () => selected ? filterTransactionsForAccount(transactions, selected.iban).slice(0, 8) : [],
    [selected, transactions],
  )

  const totals = useMemo(() => computeAccountTotals(accounts), [accounts])

  const handleOpenAccount = async (): Promise<void> => {
    try {
      await openAccount.mutateAsync({ initial_balance: 0, initial_savings: 0 })
      toast.success(t('accounts.accountOpenedTitle'), t('accounts.accountOpenedBody'))
    } catch (err) {
      handleBankError(err)
    }
  }

  const handleSubmitKyc = async (): Promise<void> => {
    try {
      await submitKyc.mutateAsync(kycSubmitPayload({ doc_count: 1 }))
      toast.success(t('accounts.kycSubmittedTitle'), t('accounts.kycSubmittedBody'))
    } catch (err) {
      handleBankError(err)
    }
  }

  const handleToggleFreeze = async (): Promise<void> => {
    if (!selected) return
    try {
      const payload = accountMutationPayload({ iban: selected.iban, reason: 'self_service_account_control' })
      if (selected.status === 'frozen' || selected.frozen_flag === true || selected.frozen_flag === 1) {
        await unfreezeAccount.mutateAsync(payload)
        toast.success(t('accounts.accountUnfrozenTitle'), streamerMode ? maskIbanCompact(selected.iban) : revealIbanDisplay(selected.iban))
      } else {
        await freezeAccount.mutateAsync(payload)
        toast.success(t('accounts.accountFrozenTitle'), streamerMode ? maskIbanCompact(selected.iban) : revealIbanDisplay(selected.iban))
      }
    } catch (err) {
      handleBankError(err)
    }
  }

  const handleCloseAccount = async (): Promise<void> => {
    if (!selected) return
    if (selected.balance_minor > 0 || selected.savings_minor > 0) {
      toast.warning(t('accounts.accountMustBeEmptyTitle'), t('accounts.accountMustBeEmptyBody'))
      return
    }
    try {
      await closeAccount.mutateAsync(accountMutationPayload({ iban: selected.iban, reason: 'self_service_close' }))
      toast.success(t('accounts.accountClosedTitle'), streamerMode ? maskIbanCompact(selected.iban) : revealIbanDisplay(selected.iban))
    } catch (err) {
      handleBankError(err)
    }
  }


  if (isLoading && accounts.length === 0) {
    return <AccountsLoading />
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="relative h-full w-full overflow-hidden"
    >
      <div aria-hidden className="pointer-events-none absolute inset-0 opacity-75">
        <div className="absolute left-[8%] top-[-10%] h-72 w-72 rounded-full bg-[oklch(0.65_0.22_40_/_0.09)] blur-[94px]" />
        <div className="absolute bottom-[0%] right-[9%] h-80 w-80 rounded-full bg-[rgba(82,205,134,0.10)] blur-[104px]" />
        <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(255,255,255,0.032),transparent_34%,rgba(255,255,255,0.02))]" />
      </div>
      <div
        className="relative h-full w-full mx-auto max-w-[1500px] gap-4 2xl:gap-5"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 0.92fr) minmax(360px, 0.48fr)',
          gridTemplateRows: '1fr',
        }}
      >
        <section className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <AccountsHero accounts={accounts} totals={totals} streamerMode={streamerMode} />
          <div className="min-h-0 grid grid-cols-[320px_minmax(0,1fr)] gap-4 2xl:gap-5 flex-1">
            <AccountList
              accounts={accounts}
              selectedId={selected?.account_id ?? null}
              streamerMode={streamerMode}
              onSelect={(account) => {
                setSelectedId(account.account_id)
                sfx.console_tap()
              }}
            />
            <AccountDetail account={selected} transactions={accountTransactions} streamerMode={streamerMode} />
          </div>
        </section>

        <aside className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <SavingsPanel accounts={accounts} selected={selected} totals={totals} streamerMode={streamerMode} />
          <QuickActionsPanel
            selected={selected}
            busy={openAccount.isPending || freezeAccount.isPending || unfreezeAccount.isPending || closeAccount.isPending || submitKyc.isPending}
            onTransfer={() => navigate('/transferir')}
            onCards={() => navigate('/tarjetas')}
            onOpenAccount={handleOpenAccount}
            onToggleFreeze={handleToggleFreeze}
            onCloseAccount={handleCloseAccount}
            onSubmitKyc={handleSubmitKyc}
          />
          <AccountActivity transactions={accountTransactions} ownIban={selected?.iban} streamerMode={streamerMode} />
        </aside>
      </div>
    </motion.div>
  )
}

interface AccountTotals {
  balanceMinor: number
  savingsMinor: number
  totalMinor: number
}

function AccountsHero({ accounts, totals, streamerMode }: { accounts: Account[]; totals: AccountTotals; streamerMode: boolean }) {
  const { t, money } = useI18n()
  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden rounded-[1.75rem] border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 14% 0%, rgba(246,75,0,0.12), transparent 34%), linear-gradient(180deg, rgba(255,255,255,0.04), transparent 56%)',
        }}
      />
      <div className="relative flex items-center justify-between gap-5 p-4 2xl:p-5">
        <div className="min-w-0 flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <Landmark size={11} strokeWidth={2.3} />
              {t('accounts.eyebrow')}
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-light tracking-[-0.055em] text-text-primary">{t('accounts.title')}</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              {t('accounts.description')}
            </p>
          </div>
        </div>
        <div className="shrink-0 grid grid-cols-3 gap-2 min-w-[420px]">
          <HeroMetric label={t('common.total')} value={streamerMode ? maskMoneyDisplay() : money(totals.totalMinor / 100)} />
          <HeroMetric label={t('common.balance')} value={streamerMode ? maskMoneyDisplay() : money(totals.balanceMinor / 100)} />
          <HeroMetric label={t('common.accounts')} value={String(accounts.length)} />
        </div>
      </div>
    </Card>
  )
}

function HeroMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.04] px-3 py-3 text-right min-w-0">
      <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary truncate">{label}</span>
      <span className="block text-sm font-semibold text-text-primary tactile-tabular-nums truncate">{value}</span>
    </div>
  )
}

function AccountList({
  accounts,
  selectedId,
  streamerMode,
  onSelect,
}: {
  accounts: Account[]
  selectedId: string | null
  streamerMode: boolean
  onSelect: (account: Account) => void
}) {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="md" className="min-h-0 border-white/10 flex flex-col gap-3">
      <div className="flex items-center justify-between gap-3 shrink-0">
        <div>
          <CardEyebrow>{t('accounts.wallet')}</CardEyebrow>
          <CardTitle className="text-base">{t('accounts.listTitle')}</CardTitle>
        </div>
        <span className="inline-flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-white/[0.045] text-text-secondary">
          <Wallet size={15} strokeWidth={2} />
        </span>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto -mx-1 px-1 space-y-2 scrollbar-thin">
        {accounts.length === 0 ? (
          <EmptyPanel title={t('accounts.emptyTitle')} description={t('accounts.emptyDescription')} />
        ) : accounts.map((account, index) => (
          <AccountButton
            key={account.account_id}
            account={account}
            index={index}
            active={account.account_id === selectedId}
            streamerMode={streamerMode}
            onClick={() => onSelect(account)}
          />
        ))}
      </div>
    </Card>
  )
}

function AccountButton({ account, index, active, streamerMode, onClick }: { account: Account; index: number; active: boolean; streamerMode: boolean; onClick: () => void }) {
  const { money, t } = useI18n()
  const name = accountName(account, index)
  const accountKind = getAccountKind(account, index)
  const ibanLabel = streamerMode ? maskIbanCompact(account.iban) : revealIbanDisplay(account.iban)
  const ibanTail = streamerMode ? '••••' : compactIban(account.iban).slice(-4)
  const amountLabel = streamerMode ? maskMoneyDisplay() : money((account.balance_minor + account.savings_minor) / 100)
  const totalMinor = account.balance_minor + account.savings_minor
  const savingsRatio = totalMinor > 0 ? account.savings_minor / totalMinor : 0
  const Icon = accountKind.icon
  const barWidth = streamerMode ? 48 : Math.round(savingsRatio * 100)

  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      aria-label={safeAriaLabel(`${name} · ${amountLabel} · ${ibanLabel}`)}
      className={cn(
        'group relative w-full overflow-hidden rounded-[1.35rem] border px-3.5 py-3.5 text-left transition-[background,border-color,box-shadow,transform] tactile-focus-ring',
        active ? 'border-white/18 bg-white/[0.085]' : 'border-border-subtle bg-white/[0.025] hover:bg-white/[0.055]',
      )}
      style={{
        boxShadow: active
          ? `inset 0 1px 0 rgba(255,255,255,0.1), 0 18px 34px -28px ${accountKind.glow}`
          : undefined,
      }}
    >
      <span
        aria-hidden
        className="absolute left-0 top-3 bottom-3 w-1 rounded-r-full transition-opacity"
        style={{ background: accountKind.accent, opacity: active ? 1 : 0.42 }}
      />
      <div className="flex items-start gap-3">
        <span
          className="inline-flex h-12 w-12 items-center justify-center rounded-2xl border shrink-0"
          style={{
            color: accountKind.accent,
            borderColor: withAlpha(accountKind.accent, 0.24),
            background: withAlpha(accountKind.accent, 0.08),
          }}
        >
          <Icon size={18} strokeWidth={2.2} />
        </span>
        <span className="min-w-0 flex-1 flex flex-col gap-1">
          <span className="flex items-center gap-2 min-w-0">
            <span className="text-sm font-semibold text-text-primary truncate">{name}</span>
            <span
              className="shrink-0 rounded-full border px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-[0.12em]"
              style={{
                color: accountKind.accent,
                borderColor: withAlpha(accountKind.accent, 0.22),
                background: withAlpha(accountKind.accent, 0.07),
              }}
            >
              {accountKind.label}
            </span>
          </span>
          <span className="flex items-center gap-2 min-w-0">
            <span className="text-[11px] text-text-tertiary tactile-tabular-nums truncate">{ibanLabel}</span>
            <span className="shrink-0 text-[10px] font-semibold text-text-secondary tactile-tabular-nums">#{ibanTail}</span>
          </span>
          <span className="mt-1 h-1.5 rounded-full bg-white/[0.06] overflow-hidden">
            <span
              className="block h-full rounded-full"
              style={{
                width: `${barWidth}%`,
                background: accountKind.accent,
                opacity: 0.72,
              }}
            />
          </span>
        </span>
        <span className="shrink-0 flex flex-col items-end gap-1">
          <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{amountLabel}</span>
          <span className="text-[9px] uppercase tracking-[0.12em] text-text-tertiary">{active ? t('accounts.active') : t('accounts.view')}</span>
        </span>
      </div>
    </button>
  )
}

function AccountDetail({ account, transactions, streamerMode }: { account: Account | undefined; transactions: Transaction[]; streamerMode: boolean }) {
  const { t, money } = useI18n()
  if (!account) {
    return (
      <Card variant="glass" padding="md" className="border-white/10 flex items-center justify-center text-center">
        <EmptyPanel title={t('accounts.selectAccount')} description={t('accounts.selectAccountDescription')} />
      </Card>
    )
  }

  const totalMinor = account.balance_minor + account.savings_minor
  const displayIban = streamerMode ? maskIbanDisplay(account.iban) : revealIbanDisplay(account.iban)

  const copyIban = async (): Promise<void> => {
    try {
      await navigator.clipboard.writeText(compactIban(account.iban))
      sfx.coin_clink()
      toast.success(t('accounts.ibanCopied'), streamerMode ? maskIbanCompact(account.iban) : revealIbanDisplay(account.iban))
    } catch {
      toast.warning(t('accounts.clipboardDenied'), t('accounts.clipboardDenied'))
    }
  }

  return (
    <Card variant="glass" padding="none" className="relative min-h-0 overflow-hidden border-white/10 rounded-[1.75rem]">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 88% 0%, rgba(255,255,255,0.07), transparent 32%), linear-gradient(180deg, rgba(255,255,255,0.04), transparent 56%)',
        }}
      />
      <div className="relative h-full min-h-0 flex flex-col p-4 2xl:p-5">
        <div className="flex items-start justify-between gap-4 shrink-0">
          <div className="min-w-0 flex flex-col gap-2">
            <CardEyebrow>{t('accounts.detail')}</CardEyebrow>
            <div>
              <h2 className="text-2xl 2xl:text-3xl font-light tracking-[-0.055em] text-text-primary">{accountName(account, 0)}</h2>
              <StatusBadge account={account} />
            </div>
          </div>
          <button
            type="button"
            onClick={copyIban}
            aria-label={safeAriaLabel(`${t('accounts.copyIban')} ${displayIban}`)}
            className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/[0.045] px-3 py-2 text-xs font-semibold text-text-secondary hover:text-text-primary hover:bg-white/[0.075] transition-colors tactile-focus-ring"
          >
            <Copy size={13} strokeWidth={2.1} />
            {t('accounts.copyIban')}
          </button>
        </div>

        <div className="mt-5 rounded-[1.55rem] border border-white/10 bg-white/[0.045] p-4">
          <span className="block text-[11px] uppercase tracking-[0.14em] text-text-tertiary">IBAN</span>
          <span className="mt-1 block text-sm font-mono font-semibold tracking-wider text-text-primary tactile-tabular-nums truncate">{displayIban}</span>
        </div>

        <div className="mt-4 grid grid-cols-3 gap-3 shrink-0">
          <DetailMetric label={t('accounts.available')} value={streamerMode ? maskMoneyDisplay() : money(account.balance_minor / 100)} />
          <DetailMetric label={t('accounts.savings')} value={streamerMode ? maskMoneyDisplay() : money(account.savings_minor / 100)} />
          <DetailMetric label={t('accounts.total')} value={streamerMode ? maskMoneyDisplay() : money(totalMinor / 100)} strong />
        </div>

        <div className="mt-4 min-h-0 flex-1 rounded-[1.55rem] border border-white/10 bg-black/[0.12] p-3.5 flex flex-col">
          <div className="flex items-center justify-between gap-3 pb-3 shrink-0">
            <span className="text-[11px] uppercase tracking-[0.14em] text-text-tertiary font-semibold">{t('accounts.accountActivity')}</span>
            <span className="text-xs text-text-tertiary tactile-tabular-nums">{transactions.length}</span>
          </div>
          <div className="min-h-0 flex-1 overflow-y-auto space-y-1.5 scrollbar-thin">
            {transactions.length === 0 ? (
              <EmptyPanel title={t('accounts.noRecentActivity')} description={t('accounts.noRecentActivityDescription')} compact />
            ) : transactions.map((tx, index) => (
              <MiniTransaction key={tx.txn_id} tx={tx} ownIban={account.iban} index={index} streamerMode={streamerMode} />
            ))}
          </div>
        </div>
      </div>
    </Card>
  )
}

function DetailMetric({ label, value, strong }: { label: string; value: string; strong?: boolean }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.035] px-3 py-3 min-w-0">
      <span className="block text-[10px] uppercase tracking-[0.14em] text-text-tertiary truncate">{label}</span>
      <span className={cn('block truncate tactile-tabular-nums', strong ? 'text-lg font-semibold text-text-primary' : 'text-sm font-semibold text-text-secondary')}>{value}</span>
    </div>
  )
}

function SavingsPanel({ accounts, selected, totals, streamerMode }: { accounts: Account[]; selected: Account | undefined; totals: AccountTotals; streamerMode: boolean }) {
  const { money, t } = useI18n()
  const [amountText, setAmountText] = useState('')
  const [error, setError] = useState<string | null>(null)
  const savingsTransfer = useSavingsTransferMutation()
  const ratio = totals.totalMinor > 0 ? totals.savingsMinor / totals.totalMinor : 0
  const displayRatio = streamerMode ? 0.56 : ratio
  const amountMinor = parseAmountMinor(amountText)
  const canMove = Boolean(selected && amountMinor > 0 && !savingsTransfer.isPending)

  const moveSavings = async (direction: 'to_savings' | 'from_savings'): Promise<void> => {
    if (!selected) return
    if (amountMinor <= 0) {
      setError(t('accounts.savingsInvalidAmount'))
      return
    }
    if (direction === 'to_savings' && amountMinor > selected.balance_minor) {
      setError(t('accounts.savingsInsufficientAvailable'))
      return
    }
    if (direction === 'from_savings' && amountMinor > selected.savings_minor) {
      setError(t('accounts.savingsInsufficientSavings'))
      return
    }
    const ids = createBankOperationIds()
    try {
      await savingsTransfer.mutateAsync({
        iban: selected.iban,
        amount_minor: amountMinor,
        direction,
        idempotency_key: ids.idempotencyKey,
        correlation_id: ids.correlationId,
      })
      setAmountText('')
      setError(null)
      toast.success(direction === 'to_savings' ? t('accounts.savingsFundedTitle') : t('accounts.savingsWithdrawnTitle'), streamerMode ? maskMoneyDisplay() : money(amountMinor / 100))
    } catch (err) {
      handleBankError(err)
    }
  }

  return (
    <Card variant="glass" padding="md" className="relative overflow-hidden border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>{t('accounts.savings')}</CardEyebrow>
          <CardTitle className="text-base">{t('accounts.protectedReserveTitle')}</CardTitle>
        </div>
        <span className="inline-flex h-9 w-9 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.045] text-text-primary">
          <PiggyBank size={17} strokeWidth={2} />
        </span>
      </div>
      <div className="mt-4 flex items-end justify-between gap-3">
        <span className="text-3xl font-light tracking-[-0.055em] text-text-primary tactile-tabular-nums">
          {streamerMode ? maskMoneyDisplay() : money(totals.savingsMinor / 100)}
        </span>
        <span className="text-xs text-text-tertiary tactile-tabular-nums">{t('accounts.accountsCount').replace('{count}', String(accounts.length))}</span>
      </div>
      <div className="mt-4 h-2 rounded-full bg-white/[0.06] overflow-hidden">
        <div
          className="h-full rounded-full bg-white/45"
          style={{ width: `${Math.round(displayRatio * 100)}%` }}
        />
      </div>
      <div className="mt-4 flex flex-col gap-2">
        <Input
          aria-label={t('accounts.savingsTransferAmount')}
          value={amountText}
          onChange={(e) => setAmountText(e.target.value)}
          placeholder="0.00"
          inputSize="sm"
          error={error}
          leftAdornment={<Coins size={14} />}
          inputMode="decimal"
        />
        <div className="grid grid-cols-2 gap-2">
          <Button variant="secondary" size="sm" loading={savingsTransfer.isPending} disabled={!canMove} onClick={() => moveSavings('to_savings')}>{t('accounts.saveToSavings')}</Button>
          <Button variant="secondary" size="sm" loading={savingsTransfer.isPending} disabled={!canMove} onClick={() => moveSavings('from_savings')}>{t('accounts.withdrawFromSavings')}</Button>
        </div>
      </div>
      <p className="mt-3 text-xs text-text-tertiary leading-relaxed">
        {t('accounts.protectedReserveDescription')}
      </p>
    </Card>
  )
}
function QuickActionsPanel({ selected, busy, onTransfer, onCards, onOpenAccount, onToggleFreeze, onCloseAccount, onSubmitKyc }: { selected: Account | undefined; busy: boolean; onTransfer: () => void; onCards: () => void; onOpenAccount: () => void; onToggleFreeze: () => void; onCloseAccount: () => void; onSubmitKyc: () => void }) {
  const { t } = useI18n()
  const frozen = selected?.status === 'frozen' || selected?.frozen_flag === true || selected?.frozen_flag === 1
  const canClose = Boolean(selected && selected.balance_minor === 0 && selected.savings_minor === 0)
  return (
    <Card variant="glass" padding="md" className="border-white/10 shrink-0">
      <div className="flex items-center gap-2 text-text-secondary mb-3">
        <ShieldCheck size={15} strokeWidth={2} />
        <span className="text-sm font-semibold">{t('accounts.quickActions')}</span>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <Button variant="primary" size="sm" leftIcon={<Send size={14} />} onClick={onTransfer}>{t('accounts.transfer')}</Button>
        <Button variant="secondary" size="sm" leftIcon={<CreditCard size={14} />} onClick={onCards}>{t('accounts.cards')}</Button>
        <Button variant="secondary" size="sm" loading={busy} onClick={onOpenAccount}>{t('accounts.openAccount')}</Button>
        <Button variant="secondary" size="sm" loading={busy} onClick={onSubmitKyc}>{t('accounts.submitKyc')}</Button>
        <Button variant="secondary" size="sm" loading={busy} disabled={!selected} onClick={onToggleFreeze}>{frozen ? t('accounts.unfreezeAccount') : t('accounts.freezeAccount')}</Button>
        <Button variant="danger" size="sm" loading={busy} disabled={!canClose} onClick={onCloseAccount}>{t('accounts.closeAccount')}</Button>
      </div>
    </Card>
  )
}
function AccountActivity({ transactions, ownIban, streamerMode }: { transactions: Transaction[]; ownIban: string | undefined; streamerMode: boolean }) {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="md" className="border-white/10 min-h-0 flex-1 flex flex-col">
      <div className="flex items-center justify-between gap-3 shrink-0 mb-3">
        <div>
          <CardEyebrow>{t('accounts.latestMovements')}</CardEyebrow>
          <CardTitle className="text-base">{t('accounts.activity')}</CardTitle>
        </div>
        <span className="text-xs text-text-tertiary tactile-tabular-nums">{transactions.length}</span>
      </div>
      <div className="min-h-0 flex-1 overflow-y-auto space-y-1.5 scrollbar-thin">
        {!ownIban || transactions.length === 0 ? (
          <EmptyPanel title={t('accounts.noMovements')} description={t('accounts.noMovementsDescription')} compact />
        ) : transactions.map((tx, index) => (
          <MiniTransaction key={tx.txn_id} tx={tx} ownIban={ownIban} index={index} streamerMode={streamerMode} />
        ))}
      </div>
    </Card>
  )
}

function MiniTransaction({ tx, ownIban, index, streamerMode }: { tx: Transaction; ownIban: string; index: number; streamerMode: boolean }) {
  const { money, relativeTime, t } = useI18n()
  const outgoing = isOutgoing(tx, ownIban)
  const counterpartIban = outgoing ? tx.to_iban : tx.from_iban
  const counterpartName = getMockAliasForIban(counterpartIban) ?? (outgoing ? t('accounts.beneficiary') : t('accounts.sender'))
  const displayName = streamerMode ? t('accounts.hiddenMovement') : counterpartName
  const reason = streamerMode ? t('accounts.hiddenDetail') : tx.reason ?? (outgoing ? t('accounts.transferSent') : t('accounts.transferReceived'))
  const amount = streamerMode ? maskSignedMoneyDisplay() : `${outgoing ? '−' : '+'}${money(tx.amount_minor / 100)}`
  const Icon = outgoing ? ArrowUpRight : ArrowDownLeft
  const statusColor = tx.status === 'committed' ? 'rgb(53, 193, 119)' : tx.status === 'failed' || tx.status === 'reverted' ? 'rgb(252, 88, 85)' : 'rgb(230, 173, 0)'

  return (
    <motion.div
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index, 8) * 0.02, duration: 0.22 }}
      className="flex items-center gap-3 rounded-2xl border border-white/[0.055] bg-white/[0.025] px-3 py-2.5"
    >
      <span className="relative shrink-0" aria-hidden>
        <BankAvatar name={displayName} size="md" />
        <span className="absolute -bottom-0.5 -right-0.5 inline-flex h-4 w-4 items-center justify-center rounded-full border border-white/10 bg-black/70" style={{ color: outgoing ? 'rgb(255, 130, 123)' : 'rgb(59, 223, 137)' }}>
          <Icon size={10} strokeWidth={2.4} />
        </span>
      </span>
      <span className="min-w-0 flex-1 flex flex-col leading-tight">
        <span className="text-sm font-semibold text-text-primary truncate">{displayName}</span>
        <span className="text-[11px] text-text-tertiary truncate">{reason} · {relativeTime(tx.timestamp_ms)}</span>
      </span>
      <span className="shrink-0 flex flex-col items-end gap-0.5">
        <span className="text-sm font-semibold tactile-tabular-nums" style={{ color: outgoing ? 'rgb(227, 228, 232)' : 'rgb(78, 213, 137)' }}>{amount}</span>
        <span className="inline-flex items-center gap-1 text-[9px] uppercase tracking-wider text-text-tertiary">
          {tx.status === 'committed' ? <Check size={9} style={{ color: statusColor }} /> : <AlertTriangle size={9} style={{ color: statusColor }} />}
          {statusLabel(tx.status, t)}
        </span>
      </span>
    </motion.div>
  )
}

function StatusBadge({ account }: { account: Account }) {
  const { t } = useI18n()
  const active = account.status === 'active' && !account.frozen_flag
  return (
    <span
      className="mt-1 inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.13em]"
      style={{
        color: active ? 'rgb(53, 193, 119)' : 'rgb(230, 173, 0)',
        borderColor: active ? 'rgba(53,193,119,0.22)' : 'rgba(230,173,0,0.22)',
        background: active ? 'rgba(53,193,119,0.07)' : 'rgba(230,173,0,0.07)',
      }}
    >
      {active ? <Check size={10} strokeWidth={2.5} /> : <AlertTriangle size={10} strokeWidth={2.5} />}
      {active ? t('accounts.activeStatus') : account.status}
    </span>
  )
}

function EmptyPanel({ title, description, compact }: { title: string; description: string; compact?: boolean }) {
  return (
    <div className={cn('flex flex-col items-center justify-center text-center rounded-2xl border border-white/[0.06] bg-white/[0.025]', compact ? 'px-4 py-5' : 'h-full min-h-[140px] px-5 py-8')}>
      <Landmark size={compact ? 16 : 22} className="text-text-tertiary mb-2" strokeWidth={1.7} />
      <p className="text-sm font-semibold text-text-primary">{title}</p>
      <p className="text-xs text-text-tertiary max-w-[28ch] leading-relaxed">{description}</p>
    </div>
  )
}

function AccountsLoading() {
  const { t } = useI18n()
  return (
    <div className="h-full w-full flex items-center justify-center text-text-tertiary">
      <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.035] px-5 py-4">
        <Spinner size="sm" />
        <span className="text-sm font-medium">{t('accounts.loading')}</span>
      </div>
    </div>
  )
}

function accountName(account: Account, index: number): string {
  const { t } = useI18n()
  if (account.savings_minor > account.balance_minor && account.balance_minor === 0) return t('accounts.protectedSavings')
  if (index === 0) return t('accounts.primaryAccount')
  return String(t('accounts.accountNumber') ?? '').replace('{number}', String(index + 1))
}

function withAlpha(color: string, alpha: number): string {
  const m = String(color ?? '').match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/)
  if (m) return `rgba(${m[1]}, ${m[2]}, ${m[3]}, ${alpha})`
  return color
}

function getAccountKind(account: Account, index: number): {
  label: string
  icon: typeof Landmark
  accent: string
  glow: string
} {
  const { t } = useI18n()
  if (account.savings_minor > account.balance_minor && account.balance_minor === 0) {
    return {
      label: t('accounts.reserveLabel'),
      icon: PiggyBank,
      accent: 'rgb(82, 205, 134)',
      glow: 'rgba(82,205,134,0.42)',
    }
  }
  if (index === 0) {
    return {
      label: t('accounts.dailyLabel'),
      icon: Wallet,
      accent: 'var(--color-brand-signal-orange)',
      glow: 'var(--color-brand-signal-orange-glow)',
    }
  }
  return {
    label: t('accounts.extraLabel'),
    icon: CreditCard,
    accent: 'rgb(230, 173, 0)',
    glow: 'rgba(230,173,0,0.42)',
  }
}

function parseAmountMinor(value: string): number {
  const normalized = value.replace(',', '.').trim()
  if (!normalized) return 0
  const amount = Number(normalized)
  if (!Number.isFinite(amount) || amount <= 0) return 0
  return Math.round(amount * 100)
}
function computeAccountTotals(accounts: Account[]): AccountTotals {
  return accounts.reduce<AccountTotals>(
    (acc, account) => ({
      balanceMinor: acc.balanceMinor + account.balance_minor,
      savingsMinor: acc.savingsMinor + account.savings_minor,
      totalMinor: acc.totalMinor + account.balance_minor + account.savings_minor,
    }),
    { balanceMinor: 0, savingsMinor: 0, totalMinor: 0 },
  )
}

function filterTransactionsForAccount(transactions: Transaction[], iban: string | undefined | null): Transaction[] {
  const compact = compactIban(iban)
  if (!compact) return []
  return transactions.filter((tx) => compactIban(tx.from_iban) === compact || compactIban(tx.to_iban) === compact)
}

function isOutgoing(tx: Transaction, ownIban: string): boolean {
  const own = compactIban(ownIban)
  return compactIban(tx.from_iban) === own && compactIban(tx.to_iban) !== own
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}

function statusLabel(status: Transaction['status'], t: (key: TranslationKey) => string): string {
  switch (status) {
    case 'committed':
      return t('transactions.confirmed')
    case 'pending':
      return t('common.pending')
    case 'reconciling':
      return t('transactions.reconciling')
    case 'reverted':
      return t('transactions.reverted')
    case 'failed':
      return t('transactions.failed')
  }
}
