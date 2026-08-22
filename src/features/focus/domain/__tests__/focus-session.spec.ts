import { describe, expect, it } from 'vitest'

import { FocusSession, type FocusRecord } from '../focus-session'

function assertFocusRecordIsReadonly(record: FocusRecord): void {
  // @ts-expect-error FocusRecord.startedAt is readonly.
  record.startedAt = 20_000
  // @ts-expect-error FocusRecord.completedAt is readonly.
  record.completedAt = 80_000
  // @ts-expect-error FocusRecord.durationMs is readonly.
  record.durationMs = 60_001
}

void assertFocusRecordIsReadonly

describe('FocusSession', () => {
  it('starts in IDLE and enters RUNNING when started', () => {
    const session = new FocusSession()

    expect(session.status).toBe('IDLE')

    session.start(1_000)

    expect(session.status).toBe('RUNNING')
  })

  it('rejects a repeated start and keeps the active session running', () => {
    const session = new FocusSession()
    session.start(1_000)

    let thrown: unknown
    try {
      session.start(2_000)
    }
    catch (error) {
      thrown = error
    }

    expect(thrown).toMatchObject({
      name: 'FocusDomainError',
      code: 'ALREADY_RUNNING',
    })
    expect(session.elapsed(2_500)).toBe(1_500)
    expect(session.status).toBe('RUNNING')
  })

  it('calculates elapsed from supplied timestamps without leaving RUNNING', () => {
    const session = new FocusSession()
    session.start(1_000)

    expect(session.elapsed(2_500)).toBe(1_500)
    expect(session.elapsed(3_001)).toBe(2_001)
    expect(session.status).toBe('RUNNING')
  })

  it('rejects an elapsed timestamp before startedAt as invalid domain input', () => {
    const session = new FocusSession()
    session.start(1_000)

    let thrown: unknown
    try {
      session.elapsed(999)
    }
    catch (error) {
      thrown = error
    }

    expect(thrown).toMatchObject({
      name: 'FocusDomainError',
      code: 'TIMESTAMP_BEFORE_START',
    })
    expect(session.status).toBe('RUNNING')
  })

  it('discards a 59999 ms session without generating a record', () => {
    const session = new FocusSession()
    session.start(1_000)

    const result = session.end(60_999)

    expect(result).toEqual({
      kind: 'DISCARDED_SHORT_SESSION',
      durationMs: 59_999,
    })
    expect('record' in result).toBe(false)
    expect(session.status).toBe('IDLE')
  })

  it.each([
    { durationMs: 60_000, completedAt: 70_000 },
    { durationMs: 60_001, completedAt: 70_001 },
  ])(
    'generates a record for a $durationMs ms session',
    ({ durationMs, completedAt }) => {
      const session = new FocusSession()
      session.start(10_000)

      expect(session.end(completedAt)).toEqual({
        kind: 'COMPLETED',
        record: {
          startedAt: 10_000,
          completedAt,
          durationMs,
        },
      })
      expect(session.status).toBe('IDLE')
    },
  )

  it('rejects completedAt before startedAt without ending the session', () => {
    const session = new FocusSession()
    session.start(1_000)

    let thrown: unknown
    try {
      session.end(999)
    }
    catch (error) {
      thrown = error
    }

    expect(thrown).toMatchObject({
      name: 'FocusDomainError',
      code: 'TIMESTAMP_BEFORE_START',
    })
    expect(session.status).toBe('RUNNING')
  })

  it('returns a runtime-frozen FocusRecord with readonly fields', () => {
    const session = new FocusSession()
    session.start(10_000)

    const result = session.end(70_000)

    expect(result.kind).toBe('COMPLETED')
    if (result.kind !== 'COMPLETED') {
      throw new Error('Expected a completed focus result.')
    }

    expect(Object.isFrozen(result.record)).toBe(true)
  })

  it.each([
    { action: 'read elapsed', invoke: (session: FocusSession) => session.elapsed(0) },
    { action: 'end', invoke: (session: FocusSession) => session.end(0) },
  ])('rejects $action while IDLE', ({ invoke }) => {
    const session = new FocusSession()

    let thrown: unknown
    try {
      invoke(session)
    }
    catch (error) {
      thrown = error
    }

    expect(thrown).toMatchObject({
      name: 'FocusDomainError',
      code: 'NOT_RUNNING',
    })
    expect(session.status).toBe('IDLE')
  })
})
