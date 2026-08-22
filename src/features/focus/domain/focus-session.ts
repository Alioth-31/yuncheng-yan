export type FocusStatus = 'IDLE' | 'RUNNING'
export type FocusDomainErrorCode =
  | 'ALREADY_RUNNING'
  | 'NOT_RUNNING'
  | 'TIMESTAMP_BEFORE_START'

export class FocusDomainError extends Error {
  readonly code: FocusDomainErrorCode

  constructor(code: FocusDomainErrorCode, message: string) {
    super(message)
    this.name = 'FocusDomainError'
    this.code = code
  }
}

type FocusState =
  | Readonly<{ status: 'IDLE' }>
  | Readonly<{ status: 'RUNNING'; startedAt: number }>

const MINIMUM_RECORDED_DURATION_MS = 60_000

export interface FocusRecord {
  readonly startedAt: number
  readonly completedAt: number
  readonly durationMs: number
}

type DiscardedFocusEndResult = Readonly<{
  kind: 'DISCARDED_SHORT_SESSION'
  durationMs: number
}>

type CompletedFocusEndResult = Readonly<{
  kind: 'COMPLETED'
  record: FocusRecord
}>

export type FocusEndResult = DiscardedFocusEndResult | CompletedFocusEndResult

export class FocusSession {
  private state: FocusState = { status: 'IDLE' }

  get status(): FocusStatus {
    return this.state.status
  }

  start(startedAt: number): void {
    if (this.state.status === 'RUNNING') {
      throw new FocusDomainError('ALREADY_RUNNING', 'A focus session is already running.')
    }

    this.state = { status: 'RUNNING', startedAt }
  }

  elapsed(now: number): number {
    if (this.state.status === 'IDLE') {
      throw new FocusDomainError('NOT_RUNNING', 'No focus session is running.')
    }

    if (now < this.state.startedAt) {
      throw new FocusDomainError(
        'TIMESTAMP_BEFORE_START',
        'The supplied timestamp is before the focus session start.',
      )
    }

    return now - this.state.startedAt
  }

  end(completedAt: number): FocusEndResult {
    if (this.state.status === 'IDLE') {
      throw new FocusDomainError('NOT_RUNNING', 'No focus session is running.')
    }

    const startedAt = this.state.startedAt
    if (completedAt < startedAt) {
      throw new FocusDomainError(
        'TIMESTAMP_BEFORE_START',
        'The supplied timestamp is before the focus session start.',
      )
    }

    const durationMs = completedAt - startedAt
    this.state = { status: 'IDLE' }

    if (durationMs >= MINIMUM_RECORDED_DURATION_MS) {
      const record: FocusRecord = Object.freeze({
        startedAt,
        completedAt,
        durationMs,
      })

      return Object.freeze({
        kind: 'COMPLETED',
        record,
      })
    }

    return Object.freeze({
      kind: 'DISCARDED_SHORT_SESSION',
      durationMs,
    })
  }
}
