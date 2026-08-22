import { createSSRApp } from 'vue'

import App from './App.vue'
import { createAppPinia } from '@/stores'

export function createApp() {
  const app = createSSRApp(App)
  app.use(createAppPinia())

  return {
    app,
  }
}
