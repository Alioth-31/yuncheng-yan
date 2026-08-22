import { describe, expect, it } from 'vitest'

import { createAppPinia } from '@/stores'

describe('createAppPinia', () => {
  it('returns an independent Pinia instance for every app creation', () => {
    const firstPinia = createAppPinia()
    const secondPinia = createAppPinia()

    expect(firstPinia).not.toBe(secondPinia)
  })
})
