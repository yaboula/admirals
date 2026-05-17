import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'motion/react'
import {
  AlertTriangle,
  Check,
  Coins,
  Copy,
  CreditCard,
  FileText,
  Landmark,
  PiggyBank,
  Send,
  Settings2,
  ShieldCheck,
  Trash2,
  Users,
  Wallet,
  X,
} from 'lucide-react'
import { Button, Card, CardEyebrow, CardTitle, Input, Spinner } from '@/components/ui'
import { accountMutationPayload, useCloseAccountMutation, useFreezeAccountMutation, useOpenAccountMutation, useRequestProfessionalAccountMutation, useSavingsTransferMutation, useUnfreezeAccountMutation } from '@/data/mutations'
import { JointOwnersPanel } from './accounts/JointOwnersPanel'
import { useBootstrap } from '@/data/queries'
import type { Account } from '@/data/contracts'
import { handleBankError } from '@/lib/bankError'
import { cn } from '@/lib/utils'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskIbanCompact, maskMoneyDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'
import { createBankOperationIds } from '@/lib/bankIdempotency'

type AccountProductClass = 'checking' | 'savings' | 'business_treasury' | 'shared'

export function Accounts() {
  const navigate = useNavigate()
  const { t } = useI18n()
  const { data, isLoading, isError, error } = useBootstrap()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [accountDialogOpen, setAccountDialogOpen] = useState(false)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const openAccount = useOpenAccountMutation()
  const requestProfessionalAccount = useRequestProfessionalAccountMutation()
  const freezeAccount = useFreezeAccountMutation()
  const unfreezeAccount = useUnfreezeAccountMutation()
  const closeAccount = useCloseAccountMutation()

  useEffect(() => {
    if (isError && error) handleBankError(error)
  }, [isError, error])

  const accounts = data?.accounts ?? []
  const selected = accounts.find((account) => account.account_id === selectedId) ?? accounts[0]
  const selectedIndex = selected ? Math.max(0, accounts.findIndex((account) => account.account_id === selected.account_id)) : 0

  useEffect(() => {
    if (!selectedId && accounts[0]) setSelectedId(accounts[0].account_id)
  }, [accounts, selectedId])

  const totals = useMemo(() => computeAccountTotals(accounts), [accounts])

  const handleOpenAccount = async (accountClass: AccountProductClass): Promise<void> => {
    try {
      if (accountClass === 'business_treasury') {
        const result = await requestProfessionalAccount.mutateAsync({ note: 'professional_account_request' })
        if (result.status === 'approved') {
          toast.success(t('accounts.accountOpenedTitle'), t('accounts.accountOpenedBody'))
          setAccountDialogOpen(false)
          return
        }
        toast.success('Solicitud enviada', 'Tu cuenta profesional queda pendiente de revisión')
        setAccountDialogOpen(false)
        return
      }
      await openAccount.mutateAsync({ initial_balance: 0, initial_savings: 0, owner_type: 'personal', account_class: accountClass })
      toast.success(t('accounts.accountOpenedTitle'), t('accounts.accountOpenedBody'))
      setAccountDialogOpen(false)
    } catch (err) {
      handleBankError(err)
    }
  }

  const handleDeleteAccount = async (): Promise<void> => {
    if (!selected) return
    try {
      const payload = accountMutationPayload({ iban: selected.iban, reason: 'self_service_close' })
      await closeAccount.mutateAsync(payload)
      toast.success(t('accounts.accountClosedTitle'), streamerMode ? maskIbanCompact(selected.iban) : revealIbanDisplay(selected.iban))
      setSelectedId(null)
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
        <div className="absolute left-[8%] top-[-10%] h-72 w-72 rounded-full bg-[rgba(255,255,255,0.055)] blur-[94px]" />
        <div className="absolute bottom-[0%] right-[9%] h-80 w-80 rounded-full bg-[rgba(82,205,134,0.10)] blur-[104px]" />
        <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(255,255,255,0.032),transparent_34%,rgba(255,255,255,0.02))]" />
      </div>
      <div
        className="relative h-full w-full mx-auto max-w-[1500px] gap-3"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1fr) minmax(296px, 0.34fr)',
          gridTemplateRows: '1fr',
        }}
      >
        <section className="min-h-0 flex flex-col gap-3 2xl:gap-4">
          <AccountsHero totals={totals} streamerMode={streamerMode} />
          <div className="min-h-0 grid grid-cols-[330px_minmax(0,1fr)] gap-3 2xl:gap-4 flex-1">
            <AccountList
              accounts={accounts}
              selectedId={selected?.account_id ?? null}
              streamerMode={streamerMode}
              onSelect={(account) => {
                setSelectedId(account.account_id)
                sfx.console_tap()
              }}
            />
            <AccountDetail
              account={selected}
              accountIndex={selectedIndex}
              streamerMode={streamerMode}
              onTransfer={() => navigate('/transferir')}
              onStatements={() => navigate('/transacciones')}
              onSettings={() => navigate('/ajustes')}
            />
          </div>
        </section>

        <aside className="min-h-0 flex flex-col gap-3 2xl:gap-4 overflow-y-auto scrollbar-thin -mr-1 pr-1">
          <SavingsPanel accounts={accounts} totals={totals} streamerMode={streamerMode} />
          <QuickActionsPanel
            accounts={accounts}
            selected={selected}
            busy={openAccount.isPending || requestProfessionalAccount.isPending || freezeAccount.isPending || unfreezeAccount.isPending || closeAccount.isPending}
            onTransfer={() => navigate('/transferir')}
            onCards={() => navigate('/tarjetas')}
            onCreateAccount={() => setAccountDialogOpen(true)}
            onToggleFreeze={handleToggleFreeze}
            onDeleteAccount={handleDeleteAccount}
          />
          <JointOwnersPanel
            account={selected}
            isPrimaryOwner={Boolean(selected && data && selected.owner_citizen_id === data.citizen_id)}
          />
          <VaultArchitecturePanel selected={selected} streamerMode={streamerMode} />
        </aside>
      </div>
      {accountDialogOpen ? (
        <AccountCreationDialog
          accounts={accounts}
          busy={openAccount.isPending || requestProfessionalAccount.isPending}
          onClose={() => setAccountDialogOpen(false)}
          onSubmit={handleOpenAccount}
        />
      ) : null}
    </motion.div>
  )
}

interface AccountTotals {
  balanceMinor: number
  savingsMinor: number
  totalMinor: number
}

function AccountsHero({ totals, streamerMode }: { totals: AccountTotals; streamerMode: boolean }) {
  const { t, money } = useI18n()
  const protectedRatio = totals.totalMinor > 0 ? totals.savingsMinor / totals.totalMinor : 0
  const operationalRatio = totals.totalMinor > 0 ? totals.balanceMinor / totals.totalMinor : 0
  const displayProtectedRatio = streamerMode ? 0.56 : protectedRatio
  const displayOperationalRatio = streamerMode ? 0.44 : operationalRatio
  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden border-white/10 shrink-0 rounded-[1.75rem]">
      <div aria-hidden className="pointer-events-none absolute inset-0" style={{ background: 'radial-gradient(circle at 16% 0%, rgba(255,255,255,0.09), transparent 34%), radial-gradient(circle at 82% 20%, rgba(82,205,134,0.10), transparent 30%), linear-gradient(90deg, rgba(255,255,255,0.04), transparent 64%)' }} />
      <div className="relative grid grid-cols-[minmax(250px,310px)_minmax(0,1fr)] items-center gap-4 px-5 py-4">
        <div className="min-w-0">
          <div className="mb-1.5 flex items-center gap-2">
            <span className="inline-flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-white/[0.055] text-text-secondary"><Landmark size={15} strokeWidth={2} /></span>
            <span className="text-[10px] font-semibold uppercase tracking-[0.17em] text-text-tertiary">{t('accounts.eyebrow')}</span>
          </div>
          <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary">{t('accounts.totalVault')}</span>
          <span className="block text-5xl font-extralight leading-none tracking-[-0.075em] text-text-primary tactile-tabular-nums">
            {streamerMode ? maskMoneyDisplay() : money(totals.totalMinor / 100)}
          </span>
        </div>
        <div className="min-w-0 grid grid-cols-[minmax(0,1fr)_minmax(0,1fr)] gap-3">
          <HeroChip label={t('accounts.operationalBalance')} value={streamerMode ? maskMoneyDisplay() : money(totals.balanceMinor / 100)} />
          <HeroChip label={t('accounts.protectedReserveTitle')} value={streamerMode ? maskMoneyDisplay() : money(totals.savingsMinor / 100)} accent />
          <div className="col-span-2 min-w-0 rounded-2xl border border-white/10 bg-black/[0.16] px-3 py-2.5">
            <div className="mb-2 flex items-center justify-between gap-2">
              <span className="truncate text-[10px] font-semibold uppercase tracking-[0.13em] text-text-tertiary">{t('accounts.vaultComposition')}</span>
              <span className="shrink-0 text-xs font-semibold text-emerald-300/90 tactile-tabular-nums">{streamerMode ? '••%' : `${Math.round(protectedRatio * 100)}%`}</span>
            </div>
            <div className="flex h-2 overflow-hidden rounded-full bg-white/[0.07]">
              <span className="h-full bg-white/38 transition-all" style={{ width: `${Math.max(6, Math.round(displayOperationalRatio * 100))}%` }} />
              <span className="h-full bg-[rgb(82,205,134)]/62 transition-all" style={{ width: `${Math.max(6, Math.round(displayProtectedRatio * 100))}%` }} />
            </div>
          </div>
        </div>
      </div>
    </Card>
  )
}

function HeroChip({ label, value, accent }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className={cn('min-w-[172px] rounded-2xl border px-3 py-2.5 text-right shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]', accent ? 'border-emerald-300/15 bg-emerald-300/[0.05]' : 'border-white/10 bg-white/[0.04]')}>
      <span className="block whitespace-nowrap text-[10px] uppercase tracking-[0.11em] text-text-secondary/80">{label}</span>
      <span className="block whitespace-nowrap text-[22px] font-light leading-tight tracking-[-0.05em] text-text-primary tactile-tabular-nums">{value}</span>
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
  const name = accountName(account, index, t)
  const accountKind = getAccountKind(account, index, t)
  const ibanLabel = maskedIbanTail(account.iban)
  const amountLabel = streamerMode ? maskMoneyDisplay() : money(account.balance_minor / 100)
  const availableLabel = streamerMode ? maskMoneyDisplay() : money(account.balance_minor / 100)
  const Icon = accountKind.icon

  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      aria-label={safeAriaLabel(`${name} · ${amountLabel} · ${ibanLabel}`)}
      className={cn(
        'group relative w-full overflow-hidden rounded-[1.45rem] border px-3.5 py-3.5 text-left transition-[background,border-color,box-shadow,transform] tactile-focus-ring',
        active ? 'border-white/18 bg-white/[0.09]' : 'border-border-subtle bg-white/[0.025] hover:bg-white/[0.055]',
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
      <div className="flex flex-col gap-2">
        <span className="flex items-start gap-3">
        <span className="relative shrink-0">
          <span
            className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border"
            style={{
              color: accountKind.accent,
              borderColor: withAlpha(accountKind.accent, 0.24),
              background: withAlpha(accountKind.accent, 0.08),
            }}
          >
            <Icon size={18} strokeWidth={2.2} />
          </span>
          <span
            className="absolute -bottom-1 -right-1 rounded-full border px-1 py-0.5 text-[7px] font-bold uppercase tracking-[0.1em] leading-none"
            style={{
              color: accountKind.accent,
              borderColor: withAlpha(accountKind.accent, 0.3),
              background: `color-mix(in srgb, ${accountKind.accent} 14%, transparent)`,
            }}
          >
            {accountKind.label}
          </span>
        </span>
        <span className="min-w-0 flex-1 flex flex-col gap-1">
          <span className="flex items-center justify-between gap-2 min-w-0">
            <span className="text-sm font-semibold text-text-primary truncate">{name}</span>
            <span className="shrink-0 text-sm font-semibold text-text-primary tactile-tabular-nums">{amountLabel}</span>
          </span>
          <span className="flex items-center justify-between gap-2 min-w-0">
            <span className="text-[11px] text-text-secondary/80 tactile-tabular-nums truncate">{ibanLabel}</span>
            <span className="shrink-0 rounded-full border border-white/[0.08] bg-white/[0.045] px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-[0.12em] text-text-tertiary">{active ? t('accounts.active') : t('common.ready')}</span>
          </span>
        </span>
        </span>
        <span className="min-w-0 rounded-xl border border-white/[0.06] bg-black/[0.12] px-2 py-1.5 text-xs text-text-secondary/80">
          <span className="block uppercase tracking-[0.12em]">{t('accounts.availableShort')}</span>
          <b className="block font-semibold text-text-secondary tactile-tabular-nums whitespace-nowrap">{availableLabel}</b>
        </span>
      </div>
    </button>
  )
}

function AccountDetail({
  account,
  accountIndex,
  streamerMode,
  onTransfer,
  onStatements,
  onSettings,
}: {
  account: Account | undefined
  accountIndex: number
  streamerMode: boolean
  onTransfer: () => void
  onStatements: () => void
  onSettings: () => void
}) {
  const { t, money } = useI18n()
  if (!account) {
    return (
      <Card variant="glass" padding="md" className="border-white/10 flex items-center justify-center text-center">
        <EmptyPanel title={t('accounts.selectAccount')} description={t('accounts.selectAccountDescription')} />
      </Card>
    )
  }

  const displayIban = maskedIbanTail(account.iban)
  const name = accountName(account, accountIndex, t)

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
      <div className="relative h-full min-h-0 flex flex-col p-4 gap-3">
        <div className="flex items-start justify-between gap-4 shrink-0">
          <div className="min-w-0 flex flex-col gap-1.5">
            <CardEyebrow>{t('accounts.selectedAccount')}</CardEyebrow>
            <div>
              <h2 className="text-2xl font-light tracking-[-0.05em] text-text-primary">{name}</h2>
              <StatusBadge account={account} />
            </div>
          </div>
          <button
            type="button"
            onClick={copyIban}
            aria-label={safeAriaLabel(`${t('accounts.copyIban')} ${displayIban}`)}
            className="shrink-0 inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/[0.045] px-3 py-2 text-xs font-semibold text-text-secondary hover:text-text-primary hover:bg-white/[0.07] transition-colors shadow-[inset_0_1px_0_rgba(255,255,255,0.07)] tactile-focus-ring"
          >
            <Copy size={12} strokeWidth={2.2} />
            {t('accounts.copyIban')}
          </button>
        </div>

        <div className="min-h-0 flex-1 rounded-[1.65rem] border border-white/10 bg-white/[0.04] p-4 flex flex-col gap-3"
          style={{ background: 'linear-gradient(145deg, rgba(255,255,255,0.055) 0%, rgba(255,255,255,0.025) 100%)' }}
        >
          <div>
            <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary">{t('accounts.availableNow')}</span>
            <span className="mt-1.5 block max-w-full overflow-visible whitespace-nowrap text-4xl 2xl:text-5xl font-extralight tracking-[-0.07em] text-text-primary tactile-tabular-nums leading-none">
              {streamerMode ? maskMoneyDisplay() : money(account.balance_minor / 100)}
            </span>
          </div>
        </div>

        <div className="shrink-0 rounded-[1.35rem] border border-white/10 bg-black/[0.18] p-3.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
          <span className="block text-[10px] uppercase tracking-[0.14em] text-text-tertiary">IBAN</span>
          <span className="mt-1.5 block text-xs font-mono font-semibold tracking-wider text-text-primary tactile-tabular-nums break-all leading-relaxed">{displayIban}</span>
        </div>

        <div className="grid grid-cols-[1fr_0.72fr_0.72fr] gap-2 shrink-0">
          <Button
            variant="primary"
            size="sm"
            leftIcon={<Send size={14} />}
            onClick={onTransfer}
            className="justify-center shadow-[0_4px_14px_-4px_oklch(0.65_0.22_40/0.42),inset_0_1px_0_rgba(255,255,255,0.15)]"
          >
            {t('accounts.transferFunds')}
          </Button>
          <Button variant="secondary" size="sm" leftIcon={<FileText size={14} />} onClick={onStatements} className="justify-center shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]">
            {t('accounts.statement')}
          </Button>
          <Button variant="secondary" size="sm" leftIcon={<Settings2 size={14} />} onClick={onSettings} className="justify-center shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]">
            {t('accounts.settings')}
          </Button>
        </div>

      </div>
    </Card>
  )
}


function SavingsPanel({ accounts, totals, streamerMode }: { accounts: Account[]; totals: AccountTotals; streamerMode: boolean }) {
  const { money, t } = useI18n()
  const [amountText, setAmountText] = useState('')
  const [error, setError] = useState<string | null>(null)
  const savingsTransfer = useSavingsTransferMutation()
  const ratio = totals.totalMinor > 0 ? totals.savingsMinor / totals.totalMinor : 0
  const displayRatio = streamerMode ? 0.56 : ratio
  const amountMinor = parseAmountMinor(amountText)
  
  const personalAccount = accounts.find((acc, idx) => acc.account_class === 'checking' || (!acc.account_class && idx === 0))
  const savingsAccount = accounts.find((acc) => acc.account_class === 'savings')
  
  const canMoveToReserve = Boolean(personalAccount && savingsAccount && amountMinor > 0 && !savingsTransfer.isPending)
  const canMoveFromReserve = Boolean(personalAccount && savingsAccount && amountMinor > 0 && !savingsTransfer.isPending)
  const availableAfterSave = personalAccount ? Math.max(0, personalAccount.balance_minor - Math.max(0, amountMinor)) : 0
  const reserveAfterSave = savingsAccount ? savingsAccount.balance_minor + Math.max(0, amountMinor) : 0

  const moveSavings = async (direction: 'to_savings' | 'from_savings'): Promise<void> => {
    if (!personalAccount || !savingsAccount) {
      setError(t('accounts.savingsRequiresBothAccounts'))
      return
    }
    if (amountMinor <= 0) {
      setError(t('accounts.savingsInvalidAmount'))
      return
    }
    if (direction === 'to_savings' && amountMinor > personalAccount.balance_minor) {
      setError(t('accounts.savingsInsufficientAvailable'))
      return
    }
    if (direction === 'from_savings' && amountMinor > savingsAccount.balance_minor) {
      setError(t('accounts.savingsInsufficientSavings'))
      return
    }
    const ids = createBankOperationIds()
    try {
      await savingsTransfer.mutateAsync({
        iban: personalAccount.iban,
        savings_iban: savingsAccount.iban,
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
    <Card variant="glass" padding="none" className="relative overflow-hidden border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 88% 0%, rgba(82,205,134,0.12), transparent 36%), linear-gradient(180deg, rgba(255,255,255,0.035), transparent 54%)',
        }}
      />
      <div className="relative p-3">
        <div className="flex items-start justify-between gap-3">
          <div>
            <CardEyebrow className="text-[10px]">{t('accounts.savings')}</CardEyebrow>
            <CardTitle className="text-base">{t('accounts.protectedReserveTitle')}</CardTitle>
          </div>
          <span className="inline-flex h-8 w-8 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.045] text-text-primary">
            <PiggyBank size={16} strokeWidth={2} />
          </span>
        </div>
        <div className="mt-3 flex items-end justify-between gap-3">
          <span className="text-xl font-light tracking-[-0.05em] text-text-primary tactile-tabular-nums">
            {streamerMode ? maskMoneyDisplay() : money(totals.savingsMinor / 100)}
          </span>
          <span className="text-xs text-text-tertiary tactile-tabular-nums">{t('accounts.accountsCount').replace('{count}', String(accounts.length))}</span>
        </div>
        <div className="mt-3 h-1.5 rounded-full bg-white/[0.06] overflow-hidden">
          <div
            className="h-full rounded-full bg-[rgb(82,205,134)]/70"
            style={{ width: `${Math.round(displayRatio * 100)}%` }}
          />
        </div>
        {amountMinor > 0 && (
          <div className="mt-2 grid grid-cols-2 gap-2">
            <PreviewMetric label={t('accounts.afterSaveAvailable')} value={streamerMode ? maskMoneyDisplay() : money(availableAfterSave / 100)} />
            <PreviewMetric label={t('accounts.afterSaveReserve')} value={streamerMode ? maskMoneyDisplay() : money(reserveAfterSave / 100)} />
          </div>
        )}
        <div className="mt-3 flex flex-col gap-2">
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
            <Button variant="secondary" size="sm" loading={savingsTransfer.isPending} disabled={!canMoveToReserve} onClick={() => moveSavings('to_savings')}>{t('accounts.moveToReserve')}</Button>
            <Button variant="secondary" size="sm" loading={savingsTransfer.isPending} disabled={!canMoveFromReserve} onClick={() => moveSavings('from_savings')}>{t('accounts.returnToBalance')}</Button>
          </div>
        </div>
      </div>
    </Card>
  )
}

function PreviewMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-white/10 bg-black/[0.16] px-2.5 py-2">
      <span className="block text-[9px] uppercase tracking-[0.13em] text-text-tertiary truncate">{label}</span>
      <span className="block text-xs font-semibold text-text-secondary tactile-tabular-nums whitespace-nowrap">{value}</span>
    </div>
  )
}

function QuickActionsPanel({ selected, busy, onTransfer, onCards, onCreateAccount, onToggleFreeze, onDeleteAccount }: { accounts: Account[]; selected: Account | undefined; busy: boolean; onTransfer: () => void; onCards: () => void; onCreateAccount: () => void; onToggleFreeze: () => void; onDeleteAccount: () => void }) {
  const { t } = useI18n()
  const [deleteConfirm, setDeleteConfirm] = useState(false)
  const [deleteInput, setDeleteInput] = useState('')
  const frozen = selected?.status === 'frozen' || selected?.frozen_flag === true || selected?.frozen_flag === 1
  const confirmWord = t('accounts.deleteConfirmWord')
  const deleteReady = deleteInput.trim().toUpperCase() === confirmWord.toUpperCase()

  const handleConfirmDelete = () => {
    if (!deleteReady) return
    setDeleteConfirm(false)
    setDeleteInput('')
    onDeleteAccount()
  }

  const handleCancelDelete = () => {
    setDeleteConfirm(false)
    setDeleteInput('')
  }

  return (
    <Card variant="glass" padding="sm" className="border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-3 mb-2">
        <div>
          <CardEyebrow className="text-[10px]">{t('accounts.commandCenter')}</CardEyebrow>
          <CardTitle className="text-base">{t('accounts.secureActions')}</CardTitle>
        </div>
        <span className="inline-flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-white/[0.045] text-text-secondary">
          <ShieldCheck size={15} strokeWidth={2} />
        </span>
      </div>
      <div className="flex flex-col gap-2">
        <Button
          variant="primary"
          size="sm"
          leftIcon={<Send size={14} />}
          onClick={onTransfer}
          className="w-full justify-center shadow-[0_4px_14px_-4px_oklch(0.65_0.22_40/0.45),inset_0_1px_0_rgba(255,255,255,0.15)]"
        >
          {t('accounts.transfer')}
        </Button>
        <div className="grid grid-cols-2 gap-2">
          <Button variant="secondary" size="sm" leftIcon={<CreditCard size={14} />} onClick={onCards} className="shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]">{t('accounts.cards')}</Button>
          <Button variant="secondary" size="sm" loading={busy} onClick={onCreateAccount} className="shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]">{t('accounts.openAccount')}</Button>
        </div>
        <div className="rounded-2xl border border-white/[0.08] bg-black/[0.20] p-2.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]">
          <div className="mb-2 flex items-center justify-between gap-2">
            <span className="text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">{t('accounts.accountControls')}</span>
            <span className="rounded-full border border-white/[0.06] bg-white/[0.035] px-2 py-0.5 text-[9px] text-text-tertiary">{t('accounts.zeroBalanceRequired')}</span>
          </div>
          {deleteConfirm ? (
            <div className="flex flex-col gap-2">
              <p className="text-[10px] leading-tight text-red-400/90">{t('accounts.deleteConfirmWarning')}</p>
              <Input
                value={deleteInput}
                onChange={(e) => setDeleteInput(e.target.value)}
                placeholder={t('accounts.deleteConfirmPlaceholder')}
                inputSize="sm"
                autoFocus
              />
              <div className="grid grid-cols-2 gap-2">
                <Button variant="secondary" size="sm" onClick={handleCancelDelete} className="text-[11px]">{t('accounts.deleteCancel')}</Button>
                <Button
                  variant="secondary"
                  size="sm"
                  loading={busy}
                  disabled={!deleteReady}
                  onClick={handleConfirmDelete}
                  className="text-[11px] border-red-500/40 text-red-400 hover:bg-red-500/10 disabled:opacity-40"
                >
                  {t('accounts.deleteConfirmBtn')}
                </Button>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2">
              <Button
                variant="secondary"
                size="sm"
                loading={busy}
                disabled={!selected}
                onClick={() => setDeleteConfirm(true)}
                leftIcon={<Trash2 size={13} />}
                className="shadow-[inset_0_1px_0_rgba(255,255,255,0.08)] text-[11px] border-red-500/30 text-red-400/80 hover:bg-red-500/10 hover:text-red-300"
              >
                {t('accounts.deleteAccount')}
              </Button>
              <Button variant="secondary" size="sm" loading={busy} disabled={!selected} onClick={onToggleFreeze} className="shadow-[inset_0_1px_0_rgba(255,255,255,0.08)] text-[11px]">{frozen ? t('accounts.unfreezeAccount') : t('accounts.freezeAccount')}</Button>
            </div>
          )}
        </div>
      </div>
    </Card>
  )
}

function AccountCreationDialog({ accounts, busy, onClose, onSubmit }: { accounts: Account[]; busy: boolean; onClose: () => void; onSubmit: (accountClass: AccountProductClass) => void }) {
  const { t } = useI18n()
  const [selectedProduct, setSelectedProduct] = useState<AccountProductClass>('checking')
  const products: Array<{ id: AccountProductClass; title: string; eyebrow: string; body: string; icon: ReactNode; action: string }> = [
    {
      id: 'checking',
      title: t('accounts.createDialog.personalTitle'),
      eyebrow: t('accounts.createDialog.personalEyebrow'),
      body: t('accounts.createDialog.personalBody'),
      icon: <Wallet size={18} strokeWidth={2} />,
      action: t('accounts.createDialog.personalAction'),
    },
    {
      id: 'savings',
      title: t('accounts.createDialog.savingsTitle'),
      eyebrow: t('accounts.createDialog.savingsEyebrow'),
      body: t('accounts.createDialog.savingsBody'),
      icon: <PiggyBank size={18} strokeWidth={2} />,
      action: t('accounts.createDialog.savingsAction'),
    },
    {
      id: 'business_treasury',
      title: t('accounts.createDialog.professionalTitle'),
      eyebrow: t('accounts.createDialog.professionalEyebrow'),
      body: t('accounts.createDialog.professionalBody'),
      icon: <Landmark size={18} strokeWidth={2} />,
      action: t('accounts.createDialog.professionalAction'),
    },
    {
      id: 'shared',
      title: t('accounts.createDialog.sharedTitle'),
      eyebrow: t('accounts.createDialog.sharedEyebrow'),
      body: t('accounts.createDialog.sharedBody'),
      icon: <Users size={18} strokeWidth={2} />,
      action: t('accounts.createDialog.sharedAction'),
    },
  ]
  const selected = products.find((product) => product.id === selectedProduct) ?? products[0]
  const existingFor = (accountClass: AccountProductClass) => accounts.find((account, index) => account.account_class === accountClass || (accountClass === 'checking' && !account.account_class && index === 0))
  const selectedExists = !!existingFor(selectedProduct)
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md">
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
        role="dialog"
        aria-modal="true"
        className="relative w-full max-w-4xl overflow-hidden rounded-[1.65rem] border border-white/10 bg-[var(--color-surface-card)] shadow-[inset_0_1px_0_rgba(255,255,255,0.05),0_36px_90px_-50px_rgba(0,0,0,0.95)]"
      >
        <div aria-hidden className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_12%_0%,rgba(255,255,255,0.08),transparent_34%),radial-gradient(circle_at_92%_10%,rgba(82,205,134,0.10),transparent_32%)]" />
        <div className="relative grid gap-0 lg:grid-cols-[minmax(0,1.08fr)_minmax(320px,0.92fr)]">
          <section className="border-b border-white/10 p-5 lg:border-b-0 lg:border-r lg:p-6">
            <header className="mb-5 flex items-start justify-between gap-3">
              <div>
                <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.045] px-3 py-1.5">
                  <Landmark size={13} strokeWidth={2} className="text-text-secondary" />
                  <span className="text-[9.5px] font-semibold uppercase tracking-[0.2em] text-text-tertiary">{t('accounts.createDialog.products')}</span>
                </div>
                <h2 className="text-[22px] font-semibold leading-[1.05] tracking-[-0.045em] text-text-primary">{t('accounts.createDialog.title')}</h2>
                <p className="mt-2 max-w-md text-sm leading-5 text-text-secondary">{t('accounts.createDialog.description')}</p>
              </div>
              <button type="button" onClick={onClose} className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-white/10 bg-black/45 text-text-tertiary transition-colors hover:text-text-primary">
                <X size={15} strokeWidth={2} />
              </button>
            </header>
            <div className="grid gap-2">
              {products.map((product) => {
                const active = selectedProduct === product.id
                const existing = existingFor(product.id)
                const unavailable = !!existing
                return (
                  <button
                    key={product.id}
                    type="button"
                    disabled={unavailable}
                    onClick={() => setSelectedProduct(product.id)}
                    className={cn(
                      'group flex items-center gap-3 rounded-2xl border p-3 text-left transition-all',
                      active ? 'border-white/20 bg-white/[0.08] shadow-[inset_0_1px_0_rgba(255,255,255,0.10)]' : 'border-white/10 bg-white/[0.025] hover:bg-white/[0.055]',
                      unavailable && 'cursor-not-allowed opacity-45',
                    )}
                  >
                    <span className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl border border-white/10 bg-black/[0.24] text-text-secondary">{product.icon}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-sm font-semibold text-text-primary">{product.title}</span>
                      <span className="mt-0.5 block text-xs text-text-tertiary">{existing ? maskedIbanTail(existing.iban) : product.body}</span>
                    </span>
                    <span className="shrink-0 rounded-full border border-white/10 bg-white/[0.035] px-2 py-1 text-[9px] font-semibold uppercase tracking-[0.12em] text-text-tertiary">{unavailable ? t('accounts.active') : product.eyebrow}</span>
                  </button>
                )
              })}
            </div>
          </section>
          <section className="flex flex-col justify-between gap-5 p-5 lg:p-6">
            <div className="rounded-[1.4rem] border border-white/10 bg-black/[0.20] p-4 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]">
              <div className="mb-4 flex items-center gap-3">
                <span className="inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.055] text-text-secondary">{selected.icon}</span>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">{selected.eyebrow}</p>
                  <h3 className="text-xl font-semibold tracking-[-0.04em] text-text-primary">{selected.title}</h3>
                </div>
              </div>
              <p className="text-sm leading-5 text-text-secondary">{selected.body}</p>
              <div className="mt-4 grid gap-2">
                <AccountDialogFact label={t('accounts.createDialog.limit')} value={t('accounts.createDialog.onePerType')} />
                <AccountDialogFact label={t('accounts.createDialog.loans')} value={selectedProduct === 'checking' || selectedProduct === 'business_treasury' ? t('accounts.createDialog.availableAsDestination') : t('accounts.createDialog.notAvailableAsDestination')} />
                <AccountDialogFact label={t('accounts.createDialog.status')} value={selectedExists ? t('accounts.createDialog.alreadyExists') : selectedProduct === 'business_treasury' ? t('accounts.createDialog.requiresRequest') : t('accounts.createDialog.readyToCreate')} />
              </div>
            </div>
            <div className="flex gap-3">
              <Button variant="secondary" size="md" onClick={onClose} className="flex-1">{t('accounts.createDialog.cancel')}</Button>
              <Button variant="primary" size="md" loading={busy} disabled={selectedExists} onClick={() => onSubmit(selectedProduct)} className="flex-1">{selectedExists ? t('accounts.createDialog.alreadyActive') : selected.action}</Button>
            </div>
          </section>
        </div>
      </motion.div>
    </div>
  )
}

function AccountDialogFact({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-xl border border-white/10 bg-white/[0.035] px-3 py-2">
      <span className="text-[10px] font-semibold uppercase tracking-[0.13em] text-text-tertiary">{label}</span>
      <span className="text-xs font-semibold text-text-secondary">{value}</span>
    </div>
  )
}
function VaultArchitecturePanel({ selected, streamerMode }: { selected: Account | undefined; streamerMode: boolean }) {
  const { t, money } = useI18n()
  if (!selected) {
    return (
      <Card variant="glass" padding="sm" className="border-white/10 min-h-0 flex-1 flex items-center justify-center text-center">
        <EmptyPanel title={t('accounts.selectAccount')} description={t('accounts.selectAccountDescription')} compact />
      </Card>
    )
  }

  return (
    <Card variant="glass" padding="none" className="relative min-h-0 flex-1 overflow-hidden border-white/10">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            'radial-gradient(circle at 50% 8%, rgba(255,255,255,0.08), transparent 30%), radial-gradient(circle at 88% 82%, rgba(82,205,134,0.10), transparent 34%)',
        }}
      />
      <div className="relative flex h-full min-h-0 flex-col p-2.5">
        <div className="flex items-start justify-between gap-3 shrink-0">
          <div className="min-w-0">
            <CardEyebrow className="text-[10px]">{t('accounts.vaultArchitecture')}</CardEyebrow>
            <CardTitle className="text-base">{t('accounts.architectureTitle')}</CardTitle>
          </div>
          <span className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-white/10 bg-white/[0.045] px-2.5 py-1.5 text-[9px] font-semibold uppercase tracking-[0.1em] text-text-secondary">
            <ShieldCheck size={11} strokeWidth={2.2} />
            {t('accounts.flowControl')}
          </span>
        </div>

        <div className="relative mt-2 rounded-[1.35rem] border border-white/10 bg-white/[0.025] p-1.5">
          <div className="grid gap-2">
            <VaultNode icon={<Wallet size={14} strokeWidth={2.2} />} title={t('accounts.flowAvailable')} value={streamerMode ? maskMoneyDisplay() : money(selected.balance_minor / 100)} />
            <VaultNode icon={<PiggyBank size={14} strokeWidth={2.2} />} title={t('accounts.flowReserve')} value={streamerMode ? maskMoneyDisplay() : money(selected.savings_minor / 100)} accent />
          </div>
        </div>
        <div className="mt-1.5 rounded-2xl border border-white/[0.07] bg-black/[0.14] px-2.5 py-1.5 text-[9px] font-medium leading-tight text-text-tertiary">
          {t('accounts.flowControlValue')}
        </div>
      </div>
    </Card>
  )
}

function VaultNode({ icon, title, value, accent }: { icon: ReactNode; title: string; value: string; accent?: boolean }) {
  return (
    <div
      className={cn(
        'relative z-10 flex min-h-0 items-center gap-2.5 rounded-2xl border px-2.5 py-1.5',
        accent
          ? 'border-emerald-300/15 bg-emerald-300/[0.05] shadow-[inset_0_1px_0_rgba(82,205,134,0.12)]'
          : 'border-white/[0.07] bg-black/[0.16] shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]',
      )}
    >
      <span className={cn(
        'inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-xl border',
        accent
          ? 'border-emerald-300/25 bg-emerald-300/[0.10] text-emerald-200'
          : 'border-white/10 bg-white/[0.06] text-text-secondary',
      )}>
        {icon}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-[9px] font-semibold uppercase leading-tight tracking-[0.1em] text-text-tertiary">{title}</span>
        <span className={cn('block truncate text-xs font-semibold tactile-tabular-nums', accent ? 'text-emerald-200' : 'text-text-primary')}>{value}</span>
      </span>
    </div>
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

function accountName(account: Account, index: number, t: (key: TranslationKey) => string): string {
  if (account.account_class === 'checking' || (!account.account_class && index === 0)) return 'Cuenta personal'
  if (account.account_class === 'savings') return 'Cuenta de ahorro'
  if (account.account_class === 'business_treasury') return 'Cuenta profesional'
  if (account.account_class === 'shared') return 'Cuenta compartida'
  if (account.savings_minor > account.balance_minor && account.balance_minor === 0) return t('accounts.protectedSavings')
  if (index === 0) return t('accounts.primaryAccount')
  return String(t('accounts.accountNumber') ?? '').replace('{number}', String(index + 1))
}

function withAlpha(color: string, alpha: number): string {
  const m = String(color ?? '').match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/)
  if (m) return `rgba(${m[1]}, ${m[2]}, ${m[3]}, ${alpha})`
  return color
}

function getAccountKind(account: Account, index: number, t: (key: TranslationKey) => string): {
  label: string
  icon: typeof Landmark
  accent: string
  glow: string
} {
  if (account.account_class === 'savings' || (account.savings_minor > account.balance_minor && account.balance_minor === 0)) {
    return {
      label: t('accounts.reserveLabel'),
      icon: PiggyBank,
      accent: 'rgb(82, 205, 134)',
      glow: 'rgba(82,205,134,0.42)',
    }
  }
  if (account.account_class === 'business_treasury') {
    return {
      label: 'PRO',
      icon: Landmark,
      accent: 'rgb(167, 139, 250)',
      glow: 'rgba(167,139,250,0.34)',
    }
  }
  if (account.account_class === 'shared') {
    return {
      label: 'SHARED',
      icon: Users,
      accent: 'rgb(45, 212, 191)',
      glow: 'rgba(45,212,191,0.32)',
    }
  }
  if (account.account_class === 'checking' || index === 0) {
    return {
      label: t('accounts.dailyLabel'),
      icon: Wallet,
      accent: 'rgb(96, 165, 250)',
      glow: 'rgba(96,165,250,0.34)',
    }
  }
  return {
    label: t('accounts.extraLabel'),
    icon: CreditCard,
    accent: 'rgb(126, 154, 180)',
    glow: 'rgba(126,154,180,0.32)',
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
    (acc, account) => {
      const isSavingsAccount = account.account_class === 'savings'
      return {
        balanceMinor: acc.balanceMinor + (isSavingsAccount ? 0 : account.balance_minor),
        savingsMinor: acc.savingsMinor + (isSavingsAccount ? account.balance_minor : 0),
        totalMinor: acc.totalMinor + account.balance_minor,
      }
    },
    { balanceMinor: 0, savingsMinor: 0, totalMinor: 0 },
  )
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}

function maskedIbanTail(value: string | undefined | null): string {
  const compact = compactIban(value).toUpperCase()
  if (compact.length < 4) return '••••'
  return `•••• ${compact.slice(-4)}`
}
